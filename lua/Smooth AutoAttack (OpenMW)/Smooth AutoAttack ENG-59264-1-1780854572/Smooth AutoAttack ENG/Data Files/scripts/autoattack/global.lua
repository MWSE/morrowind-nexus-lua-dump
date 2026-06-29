local world = require('openmw.world')

return {
    eventHandlers = {
        AutoAttackMenuWaiting = function(data)
            for _, player in ipairs(world.players) do
                player:sendEvent('AutoAttackMenuWaiting', data)
            end
        end,
    }
}
