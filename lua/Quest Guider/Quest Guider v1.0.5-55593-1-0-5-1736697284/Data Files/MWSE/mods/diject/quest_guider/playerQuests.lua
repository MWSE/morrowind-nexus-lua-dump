local this = {}

---@class questGuider.playerQuest.data
---@field index integer
---@field record tes3dialogue
---@field text string?

---@type table<string, questGuider.playerQuest.data>
this.questData = {}

local initialized = false

function this.init()
    if initialized then return end

    for _, dialogue in pairs(tes3.dataHandler.nonDynamicData.dialogues) do
        if dialogue.type ~= tes3.dialogueType.journal then goto continue end

        local dialogueId = dialogue.id:lower()

        if not this.questData[dialogueId] then
            this.questData[dialogueId] = {} ---@diagnostic disable-line: missing-fields
        end

        local data = this.questData[dialogueId]

        data.index = dialogue.journalIndex or 0
        data.record = dialogue

        ::continue::
    end

    initialized = true
end

function this.reset()
    initialized = false
    this.questData = {}
end

function this.isInitialized()
    return initialized
end

---@param questId string should be lowercase
function this.getQuestData(questId)
    return this.questData[questId]
end

---@param questId string should be lowercase
---@param index integer
function this.updateIndex(questId, index)
    local data = this.questData[questId]
    if not data then return end

    data.index = index
    data.text = nil
end

---@param quest tes3dialogue|string
---@return integer|nil
function this.getCurrentIndex(quest)
    return tes3.getJournalIndex{ id = quest }
end

return this