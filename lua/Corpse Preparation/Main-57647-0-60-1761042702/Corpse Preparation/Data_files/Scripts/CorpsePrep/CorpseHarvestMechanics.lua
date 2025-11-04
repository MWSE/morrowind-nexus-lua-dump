local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')

local function HarvestCorpse(data)
	print("EHRE")
	local money
	local TorsoDropped = false
	for i=0,math.floor(types.NPC.stats.skills.restoration(data.Player).modified/10+0.5) do
		local RandomValue=math.random(6)
		if RandomValue==1 then
			money = world.createObject('KSN_Misc_BoneSkelArmR', 1)
			money:moveInto(types.Actor.inventory(data.Actor))	
		elseif RandomValue==2 then
			money = world.createObject('KSN_Misc_BoneSkelPelvis', 1)
			money:moveInto(types.Actor.inventory(data.Actor))	
		elseif RandomValue==3 then
			money = world.createObject('KSN_flesh', 1)
			money:moveInto(types.Actor.inventory(data.Actor))	
		elseif RandomValue==4 then
			money = world.createObject('KSN_Misc_BoneSkelSkullUpper', 1)
			money:moveInto(types.Actor.inventory(data.Actor))	
		elseif RandomValue==5 then
			money = world.createObject('KSN_Misc_BoneSkelTorso', 1)
			money:moveInto(types.Actor.inventory(data.Actor))
			TorsoDropped = true		
		elseif RandomValue==6 then
			money = world.createObject('KSN_Misc_Leg', 1)
			money:moveInto(types.Actor.inventory(data.Actor))	
		end
	end

	data.Player:sendEvent("OpenHarvestingContainer", {Actor=data.Actor})
end

return {
    eventHandlers = { HarvestCorpse = HarvestCorpse,},
}


