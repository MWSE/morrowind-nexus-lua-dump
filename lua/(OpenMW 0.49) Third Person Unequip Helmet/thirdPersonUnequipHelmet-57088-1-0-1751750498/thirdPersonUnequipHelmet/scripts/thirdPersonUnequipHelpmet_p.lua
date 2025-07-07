local types = require('openmw.types')
local self = require('openmw.self')
local self = require('openmw.self')
local camera = require('openmw.camera')
local firstPerson= false
local unequippedHelmet = nil

local function onFrame(dt)
	local nowFirstPerson = camera.getMode() == camera.MODE.FirstPerson
	if nowFirstPerson ~=firstPerson then
		local equipment = types.Actor.getEquipment(self)
		if nowFirstPerson and unequippedHelmet then
			equipment[types.Actor.EQUIPMENT_SLOT.Helmet] = unequippedHelmet
			types.Actor.setEquipment(self, equipment)
			--eq helmet
		elseif not nowFirstPerson then
			unequippedHelmet = equipment[types.Actor.EQUIPMENT_SLOT.Helmet]
			equipment[types.Actor.EQUIPMENT_SLOT.Helmet] = nil
			types.Actor.setEquipment(self, equipment)
			-- find helmet and uneq
		end
		firstPerson = nowFirstPerson
	end
end
return {
	engineHandlers = { 
		onFrame = onFrame,
	},
}