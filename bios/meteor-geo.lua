assert(xpcall(function()

  local component = requre('component')
  local function getComponent(name)
    local address = component.list(name)()
    return address and component.proxy(address)
  end
  
  local geolizer = getComponent('geolizer')
  local modem = getComponent('modem')
  local eeprom = getComponent('eeprom')

  local INIT_PORT = 1
  local com_port = 2
  local auto_scan = {}

  local function dump(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
    else
      return tostring(o)
    end
  end
  -- modem.setWakeMessage('meteor-geo')

  local ACTIONS = {
    [INIT_PORT] = {
      id = function(address, port)
        modem.send(address, port, "port(" .. com_port .. ")")
      end,
    },
    [com_port] = {
      scan = function(...)
        local result = geolizer.scan(...)
        return dump(result)
      end, 
    },
  }

  modem.open(INIT_PORT)
  modem.open(com_port)

  while true do
    local event, receiverAddress, senderAddress, port, dist, msg = computer.pullSignal()
    if event == "modem_message" and type(msg) == "string" then
      local action = ACTIONS[port]
      if action then
        if msg then
          local func, err = load(msg, nil, nil, setmetatable({},{__index=action}))
          if func then
            msg, err = xpcall(func, debug.traceback)
          end
          if err ~= nil then
            modem.send(senderAddress, com_port, dump(err))
          end
        end
      end
    end
  end

end, debug.traceback))
