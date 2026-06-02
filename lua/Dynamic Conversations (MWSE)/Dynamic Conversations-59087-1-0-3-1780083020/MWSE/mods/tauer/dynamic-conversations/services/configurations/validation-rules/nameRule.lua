---@type conversationValidationRule
return {
	isMet = function(configuration)
		if not configuration.name then
			return false, "conversation must have a name"
		end
		return true, nil
	end,
}
