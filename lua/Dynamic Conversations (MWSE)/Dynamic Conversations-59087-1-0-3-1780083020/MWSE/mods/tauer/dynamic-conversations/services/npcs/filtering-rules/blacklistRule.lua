local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm

---@type npcFilteringRule
return {
	name = "Blacklist",
	isMet = function(npc, configuration)
		if mcm.blacklistedNpcs[npc.baseObject.id] then
			return false
		end

		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		local blacklistedNpcs = conditions.blacklistNpcs
		if blacklistedNpcs and arrays.contains(blacklistedNpcs, npc.baseObject.id) then
			return false
		end

		local faction = npc.baseObject.faction
		local blacklistedFactions = conditions.blacklistFactions
		if faction and blacklistedFactions and arrays.contains(blacklistedFactions, faction.id) then
			return false
		end

		local class = npc.baseObject.class
		local blacklistedClasses = conditions.blacklistClass
		if class and blacklistedClasses and arrays.contains(blacklistedClasses, class.id) then
			return false
		end

		return true
	end,
}
