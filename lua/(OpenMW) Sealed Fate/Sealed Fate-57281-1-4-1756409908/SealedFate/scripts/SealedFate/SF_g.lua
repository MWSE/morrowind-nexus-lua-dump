local types = require('openmw.types')


local function onObjectActive(object)
	if types.Actor.objectIsInstance(object) then
		--print("+",object)
		object:addScript("scripts/SealedFate/SF_a2.lua")
	end
end


local function unhookActor(object)
	--print("-",object)
	object:removeScript("scripts/SealedFate/SF_a2.lua")
end


return {
	engineHandlers = { 
		onObjectActive = onObjectActive,
	},
	eventHandlers = {
		SealedFate_unhookActor = unhookActor,
	}
} 