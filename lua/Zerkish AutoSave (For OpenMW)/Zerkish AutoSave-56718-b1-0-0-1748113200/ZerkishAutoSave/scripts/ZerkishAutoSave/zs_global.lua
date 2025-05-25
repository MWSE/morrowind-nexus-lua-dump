-- ZerkishAutoSave - zs_global.lua
-- Author: Zerkish (2025)
-- All this script does is forwards events to the local player.

local world = require('openmw.world')

local function getLocalPlayer()
    if #world.players > 0 then
        return world.players[1]
    end
    return nil
end

return {
    eventHandlers = {
        ZSave_onSaveResultEvent = function(result)
            print('ZSGlobal ZSave_onSaveResultEvent')

            local player = getLocalPlayer()
            assert(player)
            player:sendEvent('ZSave_onSaveResultEvent', result)
        end,
    }
}