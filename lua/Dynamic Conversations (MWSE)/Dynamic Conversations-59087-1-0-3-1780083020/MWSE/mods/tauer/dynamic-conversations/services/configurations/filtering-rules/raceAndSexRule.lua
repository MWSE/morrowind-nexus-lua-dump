local npcClassifier = require("tauer.dynamic-conversations.services.npcs.npcClassifier")
local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")
local npcFilterer = require("tauer.dynamic-conversations.services.npcs.npcFilterer")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@type conversationFilteringRule
return {
	name = "Race and Sex",
	isMet = function(npcs, configuration)
		local raceAndSexCondition = configuration.conditions and configuration.conditions.raceAndSex
		if not raceAndSexCondition then
			return true
		end

		local filteredNpcs = npcFilterer.filter(npcs, configuration)

		local counter = 0
		for _, npc in ipairs(filteredNpcs) do
			local raceAndSex = string.format("%s %s", npc.baseObject.race.id:lower(), npcClassifier.getSex(npc))
			if arrays.contains(raceAndSexCondition, raceAndSex) then
				counter = counter + 1
				if counter >= 2 then
					return true
				end
			end
		end

		return false
	end,
}
