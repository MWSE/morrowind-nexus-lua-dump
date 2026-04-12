local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local storage = require('openmw.storage')

interfaces.ItemUsage.addHandlerForType(types.Potion, function(potion, player)
	if not types.Player.objectIsInstance(player) then
		--print(string.format("npcDrink: %s", types.NPC.record(player).name))
		return false
	end
	if world.mwscript.getGlobalVariables(player).r_active == 1 then
		world.mwscript.getGlobalVariables(player).r_drinkMsg2 = 1
		return false
	elseif world.mwscript.getGlobalVariables(player).r_drinkCount >= world.mwscript.getGlobalVariables(player).r_drinkOverdose then
		world.mwscript.getGlobalVariables(player).r_drinkMsg = 1;
		return false
	end
end)

interfaces.ItemUsage.addHandlerForType(types.Apparatus, function(apparatus, player)
	if world.mwscript.getGlobalVariables(player).r_active == 1 then
		world.mwscript.getGlobalVariables(player).r_apparatusMsg = 1
		return false
	end
end)

interfaces.ItemUsage.addHandlerForType(types.Repair, function(repair, player)
	if world.mwscript.getGlobalVariables(player).r_active == 1 then
		world.mwscript.getGlobalVariables(player).r_repairMsg = 1
		return false
	end
end)

interfaces.ItemUsage.addHandlerForType(types.Miscellaneous, function(miscellaneous, player)
	if world.mwscript.getGlobalVariables(player).r_active == 1 then
		world.mwscript.getGlobalVariables(player).r_miscellaneousMsg = 1
		return false
	end
end)

return {
	engineHandlers = {
		onUpdate = function(dt)
			local player = world.players[1]
			local vals = world.mwscript.getGlobalVariables(player)
			local drinkCount = vals.r_drinkCount == 90 and vals.r_maxCount or vals.r_drinkCount
			drinkCount = vals.r_drinkCount == 100 and vals.r_maxCount + 1 or drinkCount
			storage.globalSection('raffll_limits'):set('countdown', vals.r_countdown)
			storage.globalSection('raffll_limits'):set('maxCount', vals.r_maxCount)
			storage.globalSection('raffll_limits'):set('drinkCount', drinkCount)
		end
	}
}