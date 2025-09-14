local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
local onNextSecond = nil
local step = 1

onFrame = function(dt)
	if onNextSecond then
		local now = core.getRealTime()
		if now > onNextSecond then
			if step == 1 then
				onNextSecond = nil
				for _, item in pairs(types.Player.inventory(self):getAll()) do
					if types.Miscellaneous.objectIsInstance(item) then
						if types.Item.itemData(item).soul and item.recordId ~= "misc_soulgem_Azura" and types.Miscellaneous.records[item.recordId.."_worthless"] then
							--print("send",types.Item.itemData(item).soul)
							core.sendGlobalEvent("worthless_soulgems_replaceGem", {self,item})
							onNextSecond = now+0.15
							step = 2
						end
					end
				end
			else
				if I.UI.getMode() == "Interface" then
					I.UI.setMode()
					I.UI.setMode('Interface')
				end
				step = 1
				onNextSecond = nil
			end
		end
	end
end

--I.SkillProgression.addSkillUsedHandler(function(skillid, params)
--	if skillid == "enchant" and params.useType == 3 then
--		print("used enchanted weapon")
--		onNextSecond = 0.5
--	end
--end)

local function UiModeChanged(data)
	if data.newMode == "Interface" then
		step = 1
		onNextSecond = core.getRealTime()+0.08
	end
end


return {
	engineHandlers = { 
		onFrame = onFrame,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
	}
}