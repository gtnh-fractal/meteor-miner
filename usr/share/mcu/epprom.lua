local function getComponent(name)
  local address = component.list(name)()
  return address and component.proxy(address)
end

local modem = getComponent("modem")
local eeprom = getComponent("eeprom")

local INIT_PORT = 1
local com_port = 2

-- Simple dump to JSON
local function dump(o)
  if type(o) == "table" then
    local s = "{"
    for k,v in pairs(o) do
      if type(k) ~= "number" then k = "'"..k.."'" end
      s = s .. "["..k.."]=" .. dump(v) .. ","
    end
    return s .. "}"
  elseif type(o) == "string" then
    return "'"..o.."'"
  elseif type(o) == "function" then
    return "'function(...)'"
  else
    return tostring(o)
  end
end

function componentsByType()
  local c = {}
  for address, type in component.list() do
    if not c[type] then
      c[type] = {address}
    else
      table.insert(c[type], address)
    end
  end
  return c
end

local function actions()
  local cc = componentsByType()

  local com_handler = {
    proxy = function(address)
      return component.proxy(address)
    end,
    computer = computer,
    components = {},
  }

  for t,addr in pairs(cc) do
    com_handler.components[t] = function()
      return component.proxy(addr[1])
    end
  end

  local ID = {
    version = eeprom.getLabel(),
    port = com_port,
    components = cc,
    com_handler = com_handler,
  }

  return {
    [INIT_PORT] = {
      id = function(address, port)
        return ID
      end,
    },
    [com_port] = com_handler,
  }
end

modem.setWakeMessage("meteor-geo")

modem.open(INIT_PORT)
modem.open(com_port)

local ACTIONS = actions()
while true do
  local event, receiverAddress, senderAddress, port, dist, msg = computer.pullSignal()
  if event == "modem_message" and type(msg) == "string" then
    local action = ACTIONS[port]
    if action and msg then
      local func, err = load(msg, "=modem_message", "t", setmetatable({},{__index=action}))
      if func then
        status, result = xpcall(func, debug.traceback)
      end
      if status then
        modem.send(senderAddress, port, dump(result))
      else
        modem.send(senderAddress, port, "ERROR: "..dump(result))
      end
    end
  end
end
