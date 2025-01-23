-- Client for /usr/share/mcu/epprom

local component = require("component")
local event = require("event")
local ser = require("serialization")

local C = {}

function C.new(address, timeout, logEnabled)
  local self = {
    id = nil,
    logEnabled = not not logEnabled,
    timeout = timeout or 5,
  }
  local m = {
    modem = component.proxy(address),
  }

  function m.log(...)
    if self.logEnabled then
      print("[McuClient]", ...)
    end
  end

  function self.init()
    local request = string.format("return id('%s', 1)", m.modem.address)
    m.log(">broadcast", 1, request)
    m.modem.broadcast(1, request)
    local name, _, from, port, _, message = event.pull(self.timeout, "modem_message")
    assert(name ~= nil, "MCU did not respond")
    m.log("<response", message)
    local id = ser.unserialize(message)
    id.address = from
    self.id = id
  end

  function m.modem_filter(name, localAddress, remoteAddress, port, distance, ...)
    return name == "modem_message" and self.id.address == remoteAddress and port == self.id.port
  end

  function self.send(request)
    m.modem.open(self.id.port)
    m.log(">send", self.id.address, self.id.port, request)
    m.modem.send(self.id.address, self.id.port, request)
    local name, _, _, _, _, response = event.pullFiltered(self.timeout, m.modem_filter)
    if name == nil then
      m.log(">response", 'TIMEOUT')
      return nil
    end
    m.modem.close(self.id.port)
    m.log(">response", self.id.address, self.id.port, response)
    return ser.unserialize(response)
  end

  return self
end

return C
