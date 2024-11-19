local world = require('openmw.world')

-- Add an item at a given position, in an actor's cell
local function testPosition(data)
    world.createObject(data.item, 1):teleport(data.actor.cell.name, data.pos)
    -- Example in local scripts:
    --core.sendGlobalEvent("testPosition", { actor = actor, pos = position, item = "glass_helm" })
end

return {
    eventHandlers = {
        testPosition = testPosition,
    }
}

