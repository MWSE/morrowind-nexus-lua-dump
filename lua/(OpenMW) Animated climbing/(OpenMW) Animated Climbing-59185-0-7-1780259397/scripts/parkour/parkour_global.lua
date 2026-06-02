local world = require('openmw.world')

return {
    eventHandlers = {
        ParkourLedgeGrab = function(data)
            local player = world.players[1]
            if player then
                player:teleport(player.cell, data.pos, player.rotation)
            end
        end,
    },
}