---@type conversationFilteringRule
return {
	isMet = function(_, configuration)
		local timeOfDayCondition = configuration.conditions and configuration.conditions.timeOfDay
		if not timeOfDayCondition then
			return true
		end

		local now = tes3.worldController.hour.value
		local from = timeOfDayCondition.from
		local to = timeOfDayCondition.to

		if from < to then
			return now >= from and now <= to
		end

		return now >= from or now <= to
	end,
}
