local world = require('openmw.world')

local function DiedCreature(creature)
    world.players[1]:sendEvent('processDiedCreature', creature)
end

local function removeEquipment(data)
    data.equipment:remove(data.count)
end

return {
    eventHandlers = {
        DiedCreature = DiedCreature,
        removeEquipment = removeEquipment
    }
}
