local component = require("component")
local event = require("event")
local ser = require("serialization")
local holo = component.hologram

package.loaded.McuClient = nil
package.loaded.McuMeteorGeo = nil

local client = require("McuMeteorGeo").new(component.list("modem", true)())
client.init()


local function scan(x, z, y, dx, dz, dy)
  holo.clear()
  for _x = 1, dx do
    for _z = 1, dz  do
      local response = client.scan(_x + x - 1, _z + z - 1, y, 1, 1, dy)
      print(_x, _z, response.energy[1].."/"..response.energy[2])
      local data = response.data
      for _y = 1, dy do
        holo.set(_x - x + 1, _y, _z - z + 1, data[_y] > 0)
      end
    end 
  end
end

-- local result = scan_request(0, 0, -4, 1, 1, 10)
-- print(ser.serialize(result))
holo.setScale(1)
for i=1, 10 do
  print("check", ser.serialize(client.check()))
  -- scan(0, 0, -16, 1, 1, 32)
  os.sleep(1)
end
-- print("check", ser.serialize(client.check()))
-- scan(0, 0, -16, 1, 1, 32)
-- scan(-10, -10, -16, 20, 20, 32)
print("done")

--local data = scan_request(0,0,-32,1,1,64)
--for i = 1, 64 do
--  local k = i
--  local v = data[i]

--  if type(k) ~= "number" then k = """..k..""" end
--  print(k, type(k), v, type(v))
--end

--modem.broadcast(2, "return scan(0,0,0,1,1,5)")
--while true do
--  print(computer.pullSignal())
--end