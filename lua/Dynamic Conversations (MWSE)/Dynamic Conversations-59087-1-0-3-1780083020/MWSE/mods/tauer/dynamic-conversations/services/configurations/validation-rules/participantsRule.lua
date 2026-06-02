---@type conversationValidationRule
return {
	isMet = function(configuration)
		local participants = configuration.participants
		if participants and table.size(participants) ~= 2 then
			return false, "can only have 2 participants in a conversation"
		end

		local raceAndSexCondition = configuration.conditions and configuration.conditions.raceAndSex
		if not raceAndSexCondition then
			return true
		end

		if raceAndSexCondition and participants then
			return false, "cannot define both race/sex and specific participants in the same conversation"
		end

		if not raceAndSexCondition and not participants then
			return false, "must define either race/sex or specific participants in a conversation"
		end

		return true, nil
	end,
}
