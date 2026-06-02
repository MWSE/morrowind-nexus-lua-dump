local conversationHistoryController =
	require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@type conversationFilteringRule
return {
	name = "Depends on",
	isMet = function(_, configuration)
		local dependsOn = configuration.conditions and configuration.conditions.dependsOn
		if not dependsOn then
			return true
		end

		for _, configurationId in pairs(dependsOn) do
			if not conversationHistoryController.exists(configurationId) then
				return false
			end
		end

		return true
	end,
}
