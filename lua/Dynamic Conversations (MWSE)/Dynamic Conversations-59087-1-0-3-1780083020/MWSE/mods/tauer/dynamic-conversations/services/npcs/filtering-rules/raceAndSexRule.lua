local npcClassifier = require("tauer.dynamic-conversations.services.npcs.npcClassifier")
local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

---@type npcFilteringRule
return {
	name = "Race and sex",
	isMet = function(npc, configuration)
		local raceAndSexCondition = configuration.conditions and configuration.conditions.raceAndSex
		if not raceAndSexCondition then
			return true
		end

		local raceAndSex = string.format("%s %s", npc.baseObject.race.id:lower(), npcClassifier.getSex(npc))
		if arrays.contains(raceAndSexCondition, raceAndSex) then
			return true
		end

		return false
	end,
}
