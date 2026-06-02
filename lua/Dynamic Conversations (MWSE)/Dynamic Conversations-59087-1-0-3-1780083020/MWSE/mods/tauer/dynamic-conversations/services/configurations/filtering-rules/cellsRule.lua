local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")
local mcm = require("tauer.dynamic-conversations.services.mcm.mcmSettings").mcm

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@type conversationFilteringRule
return {
	name = "Cells",
	isMet = function(_, configuration)
		local currentCell = tes3.getPlayerCell()

		if mcm.blacklistedCells[currentCell.id:lower()] then
			return false
		end

		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		local whitelistedCells = conditions.whitelistCells
		if whitelistedCells then
			return arrays.contains(whitelistedCells, currentCell.id)
		end

		local blacklistedCells = conditions.blacklistCells
		if blacklistedCells then
			return not arrays.contains(blacklistedCells, currentCell.id)
		end
		return true
	end,
}
