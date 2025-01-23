local component = require("component")
local McuClient = require("McuClient")
local ser = require("serialization")

local C = {}

function C.new(address)
  local self = {}
  local m = {
    client = McuClient.new(address)
  }

  function self.init()
    m.client.init()
  end

  function self.info()
    return m.client.id
  end

  function self.scan(x, z, y, w, d, h) -- table
    local request = string.format("return {data=components.geolyzer().scan(%d,%d,%d,%d,%d,%d), energy={computer.energy(), computer.maxEnergy()}}", x, z, y, w, d, h)
    local response = m.client.send(request)
  
    local result = {
      energy = response.energy,
      data = {},
    }
    for i = 1, w * d * h do
      table.insert(result.data, response.data[i])
    end
    return result
  end

  function self.check() -- boolean | nil
    return m.client.send("return {canSeeSky=components.geolyzer().canSeeSky(), energy={computer.energy(), computer.maxEnergy()}}")
  end

  function self.canSeeSky() -- boolean | nil
    return m.client.send("return components.geolyzer().canSeeSky()")
  end

  return self
end

return C
