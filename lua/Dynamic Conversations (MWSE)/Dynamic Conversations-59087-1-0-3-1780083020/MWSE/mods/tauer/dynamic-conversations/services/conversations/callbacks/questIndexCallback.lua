local journalController = require("tauer.dynamic-conversations.services.journal.journalController")

---@type conversationCallback
return {
	execute = function(data)
		local configuration = data.conversation.configuration

		local questIndex = configuration.onCompletion and configuration.onCompletion.questIndex
		if not questIndex then
			return
		end

		for questId, index in pairs(questIndex) do
			journalController.updateQuest(questId, index)
		end
	end,
}
