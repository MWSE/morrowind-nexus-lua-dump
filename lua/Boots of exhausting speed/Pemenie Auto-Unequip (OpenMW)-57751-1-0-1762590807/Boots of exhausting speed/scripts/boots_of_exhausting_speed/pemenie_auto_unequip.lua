local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')

local record = types.NPC.record(self)

if record.id ~= 'pemenie' then
	-- Only for Pemenie
	return {}
else
	local scriptVersion = 1

	function chooseEquipment()
		local fatigueRatio = types.Actor.stats.dynamic.fatigue(self).current / types.Actor.stats.dynamic.fatigue(self).base
		if fatigueRatio < 0.15 then
			local current = types.Actor.getEquipment(self)
			if current[types.Actor.EQUIPMENT_SLOT.Boots] ~= nil then
				if current[types.Actor.EQUIPMENT_SLOT.Boots].recordId == 'boots of blinding speed[unique]' then
					current[types.Actor.EQUIPMENT_SLOT.Boots] = nil
					types.Actor.setEquipment(self, current)
				end
			end
			if current[types.Actor.EQUIPMENT_SLOT.Pants] ~= nil then
				if current[types.Actor.EQUIPMENT_SLOT.Pants].recordId == 'aawcpants_of_exhausting_speed' then
					current[types.Actor.EQUIPMENT_SLOT.Pants] = nil
					types.Actor.setEquipment(self, current)
				end
			end
		elseif fatigueRatio > 0.85 then
			local current = types.Actor.getEquipment(self)
			local inventory = types.Actor.inventory(self)
			if current[types.Actor.EQUIPMENT_SLOT.Boots] == nil or current[types.Actor.EQUIPMENT_SLOT.Pants] == nil then
				local boots = inventory:find('boots of blinding speed[unique]')
				if boots ~= nil then
					current[types.Actor.EQUIPMENT_SLOT.Boots] = boots
					types.Actor.setEquipment(self, current)
				else
					local pants = inventory:find('aaWCpants_of_exhausting_speed')
					if pants ~= nil then
						current[types.Actor.EQUIPMENT_SLOT.Pants] = pants
						types.Actor.setEquipment(self, current)
					end
				end
			end
		end

	end

	local function onInit()
		local inventory = types.Actor.inventory(self)
		local boots = inventory:find('boots of blinding speed[unique]')
		local pants = inventory:find('aaWCpants_of_exhausting_speed')
		if boots ~= nil or pants ~= nil then
			time.runRepeatedly(chooseEquipment, 1)	
		end
	end

	local function onSave()
		return {
			version = scriptVersion,
		}
	end

	local function onLoad(data)
		local inventory = types.Actor.inventory(self)
		local boots = inventory:find('boots of blinding speed[unique]')
		local pants = inventory:find('aaWCpants_of_exhausting_speed')
		if boots ~= nil or pants ~= nil then
			time.runRepeatedly(chooseEquipment, 1)	
		end
	end

	return {
		engineHandlers = {
			onInit = onInit,
			onLoad = onLoad,
			onSave = onSave,
		}
	}
end

