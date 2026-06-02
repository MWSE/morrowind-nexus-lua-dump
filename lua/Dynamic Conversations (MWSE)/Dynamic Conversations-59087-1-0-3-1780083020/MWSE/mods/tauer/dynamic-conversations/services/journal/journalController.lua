local fileHelper = require("tauer.dynamic-conversations.services.files.fileHelper")
local FILE_TYPE = require("tauer.dynamic-conversations.services.files.enums.FILE_TYPE")

--- Encapsulates for updating the in-game journal
---@class journalController
local this = {}

--- Adds the specified text as a new journal entry
---@public
---@param text string The text to add as a journal entry
function this.updateJournal(text)
	tes3.addJournalEntry({ text = text, showMessage = false })
	tes3.messageBox(tes3.findGMST(tes3.gmst.sJournalEntry).value)
	this.playJournalSound()
end

--- Updates the specified quest to the given index
---@public
---@param questId questId The ID of the quest to update
---@param index questIndex The index to update the quest to
function this.updateQuest(questId, index)
	tes3.updateJournal({ id = questId, index = index })
	tes3.messageBox(tes3.findGMST(tes3.gmst.sJournalEntry).value)
	this.playJournalSound()
end

-- Plays a random Journal sound from CSO (Character Sound Overhaul) if the mod is installed
---@private
function this.playJournalSound()
	local sounds = fileHelper.getAllFilesInDirectory("data files\\sound\\Anu\\Misc\\Journal\\Update", FILE_TYPE.wav)
	if sounds then
		local file = table.choice(sounds) --[[@as string]]
		tes3.playSound({ soundPath = string.format("Anu\\Misc\\Journal\\Update\\%s", file) })
	end
end

return this
