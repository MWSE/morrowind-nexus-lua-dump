local world = require'openmw.world'

local PlayerNoClothes = require'scripts.styxd.bdc.event.PlayerNoClothes'
local PlayerSomeClothes = require'scripts.styxd.bdc.event.PlayerSomeClothes'

return {
    eventHandlers = {
        [PlayerNoClothes.eventName] = function(eventData)
			world.mwscript.getGlobalVariables(eventData.player).SxD_BDC_IsPlayerNaked = 1
        end,

        [PlayerSomeClothes.eventName] = function(eventData)
			world.mwscript.getGlobalVariables(eventData.player).SxD_BDC_IsPlayerNaked = 0
        end
    }
}
