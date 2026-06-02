---@type conversationFilteringRule
return {
	name = "Exteriors only",
	isMet = function(_, configuration)
		local conditions = configuration.conditions
		if not conditions or not conditions.exteriorsOnly then
			return true
		end

		local currentCell = tes3.getPlayerCell()
		return not currentCell.isInterior
	end,
}
