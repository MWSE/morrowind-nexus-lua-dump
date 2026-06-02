---@type conversationFilteringRule
return {
	name = "Interiors only",
	isMet = function(_, configuration)
		local conditions = configuration.conditions
		if not conditions or not conditions.interiorsOnly then
			return true
		end

		local currentCell = tes3.getPlayerCell()
		return currentCell.isInterior
	end,
}
