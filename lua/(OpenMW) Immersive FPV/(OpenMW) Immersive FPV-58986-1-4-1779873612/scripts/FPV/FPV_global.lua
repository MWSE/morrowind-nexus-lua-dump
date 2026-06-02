local world = require('openmw.world')
local types = require('openmw.types')

return {
    eventHandlers = {
        FPV_AddInvisHelm = function(data)
            local player = world.players[1]
            if not player then return end
            local helm = world.createObject("invis_helm", 1)
            helm:moveInto(types.Actor.inventory(player))
        end,

        FPV_RemoveInvisHelm = function(data)
            local player = world.players[1]
            if not player then return end
            local inv = types.Actor.inventory(player)
            for _, item in ipairs(inv:getAll()) do
                if item.recordId == "invis_helm" then
                    item:remove()
                    return
                end
            end
        end,
    },
}