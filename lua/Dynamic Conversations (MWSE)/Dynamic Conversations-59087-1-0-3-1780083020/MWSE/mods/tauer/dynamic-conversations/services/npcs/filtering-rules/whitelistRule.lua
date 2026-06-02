local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

---@type npcFilteringRule
return {
	name = "Whitelist",
	isMet = function(npc, configuration)
		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		local whitelistedNpcs = conditions.whitelistNpcs
		if whitelistedNpcs and not arrays.contains(whitelistedNpcs, npc.baseObject.id) then
			return false
		end

		local faction = npc.baseObject.faction
		local whitelistedFactions = conditions.whitelistFactions
		if faction and whitelistedFactions and not arrays.contains(whitelistedFactions, faction.id) then
			return false
		end

		local class = npc.baseObject.class
		local whitelistedClasses = conditions.whitelistClass
		if class and whitelistedClasses and not arrays.contains(whitelistedClasses, class.id) then
			return false
		end

		return true
	end,
}
