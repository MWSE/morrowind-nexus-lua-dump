local world = require('openmw.world')

local function processDiedCreature(creature)
    world.players[1]:sendEvent('processDiedCreature', creature)
end

local function removeEquipment(equipment)
    equipment:remove()
end

return {
    eventHandlers = {
        processDiedCreature = processDiedCreature,
        removeEquipment = removeEquipment
    }
}
