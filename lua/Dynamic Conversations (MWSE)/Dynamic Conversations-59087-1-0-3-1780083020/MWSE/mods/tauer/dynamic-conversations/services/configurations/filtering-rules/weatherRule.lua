local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

---@type conversationFilteringRule
return {
	isMet = function(_, configuration)
		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		local currentWeather = tes3.getCurrentWeather()

		local blacklistedWeathers = conditions.blacklistWeathers
		if blacklistedWeathers then
			return not arrays.contains(blacklistedWeathers, currentWeather.name)
		end

		local whitelistedWeathers = conditions.whitelistWeathers
		if whitelistedWeathers then
			return arrays.contains(whitelistedWeathers, currentWeather.name)
		end

		return true
	end,
}
