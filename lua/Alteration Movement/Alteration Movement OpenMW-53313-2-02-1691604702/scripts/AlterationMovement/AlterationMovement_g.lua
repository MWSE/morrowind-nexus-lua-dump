local world = require("openmw.world")

local function createObjectAtPlayer(objectId)
    world.createObject(objectId):teleport(world.players[1].cell, world.players[1].position)
end

return { eventHandlers = { createObjectAtPlayer = createObjectAtPlayer } }
