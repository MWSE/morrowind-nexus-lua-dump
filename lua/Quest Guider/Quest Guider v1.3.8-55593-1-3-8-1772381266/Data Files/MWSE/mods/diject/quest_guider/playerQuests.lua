local this = {}

---@class questGuider.playerQuest.data
---@field index integer
---@field record tes3dialogue
---@field text table<integer, string> cached text

---@type table<string, questGuider.playerQuest.data>
this.questData = {}

---@type table<string, tes3quest>
this.finished = {}

local initialized = false

function this.init()
    if initialized then return end

    this.finished = {}

    for _, dialogue in pairs(tes3.dataHandler.nonDynamicData.dialogues) do
        if dialogue.type ~= tes3.dialogueType.journal or dialogue.deleted or not dialogue.id then goto continue end

        local dialogueId = dialogue.id:lower()

        if not this.questData[dialogueId] then
            this.questData[dialogueId] = {} ---@diagnostic disable-line: missing-fields
        end

        local data = this.questData[dialogueId]

        data.index = dialogue.journalIndex or 0
        data.record = dialogue
        data.text = {}

        ::continue::
    end

    for _, quest in pairs(tes3.worldController.quests) do
        if quest.isFinished then
            for _, dia in pairs(quest.dialogue) do
                this.finished[dia.id:lower()] = quest
            end
        end
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

---@param quest string|questGuider.playerQuest.data should be lowercase
---@param index integer?
---@return string?
function this.getJournalText(quest, index)
    local data = type(quest) == "string" and this.questData[quest] or quest
    if not data then return end
    local journalInfo = data.record:getJournalInfo(index)
    if not journalInfo then return end

    if not index then index = data.index end

    local text
    if data.text[index] then
        text = data.text[index]
    else
        data.text[index] = journalInfo.text
        text = data.text[index]
    end
    return text
end

---@param questId string should be lowercase
---@param index integer
function this.updateIndex(questId, index)
    local data = this.questData[questId]
    if not data then return end

    data.index = index
end

---@param dialogue tes3dialogue
function this.addFinished(dialogue)
    if not dialogue then return end

    local quest = tes3.findQuest{ journal = dialogue }
    if not quest then return end

    for _, dia in pairs(quest.dialogue) do
        this.finished[dia.id:lower()] = quest
    end
end

---@param dialogueId string lowercase
---@return tes3quest?
function this.isFinished(dialogueId)
    return this.finished[dialogueId]
end

---@param quest tes3dialogue|string
---@return integer|nil
function this.getCurrentIndex(quest)
    return tes3.getJournalIndex{ id = quest }
end

return this