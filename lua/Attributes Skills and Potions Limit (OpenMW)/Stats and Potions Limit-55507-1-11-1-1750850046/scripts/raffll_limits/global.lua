local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')

interfaces.ItemUsage.addHandlerForType(types.Potion, function(potion, player)
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