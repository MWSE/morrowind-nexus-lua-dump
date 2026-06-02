local conversationHistoryController =
	require("tauer.dynamic-conversations.services.conversations.conversationHistoryController")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

---@type conversationFilteringRule
return {
	name = "Repeatable conversations",
	isMet = function(_, configuration)
		if not conversationHistoryController.exists(configuration.id) then
			return true
		end
		return configuration.repeatable
	end,
}
