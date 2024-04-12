local world = require("openmw.world")
local util = require("openmw.util")
local function createObjectAtPlayer(objectId)
  local pos = world.players[1].position
  local newPos = util.vector3(pos.x,pos.y,pos.z - 10000)
    local newObject = world.createObject(objectId):teleport(world.players[1].cell, newPos)
  if newObject then
    newObject.enabled = false
  end
end

return { eventHandlers = { createObjectAtPlayer = createObjectAtPlayer } }
