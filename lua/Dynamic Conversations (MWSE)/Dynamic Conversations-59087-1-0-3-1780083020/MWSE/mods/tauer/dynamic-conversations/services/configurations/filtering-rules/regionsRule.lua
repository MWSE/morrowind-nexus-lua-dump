local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@type conversationFilteringRule
return {
	name = "Regions",
	isMet = function(_, configuration)
		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		local currentRegion = tes3.getPlayerCell().region
		if not currentRegion then
			return true
		end

		local whitelistedRegions = conditions.whitelistRegions
		if whitelistedRegions then
			return arrays.contains(whitelistedRegions, currentRegion.id)
		end

		local blacklistedRegions = conditions.blacklistRegions
		if blacklistedRegions then
			return not arrays.contains(blacklistedRegions, currentRegion.id)
		end

		return true
	end,
}
