local journalController = require("tauer.dynamic-conversations.services.journal.journalController")

---@type conversationCallback
return {
	execute = function(data)
		local configuration = data.conversation.configuration

		local journalEntry = configuration.onCompletion and configuration.onCompletion.journalEntry
		if not journalEntry then
			return
		end

		journalController.updateJournal(journalEntry)
	end,
}
