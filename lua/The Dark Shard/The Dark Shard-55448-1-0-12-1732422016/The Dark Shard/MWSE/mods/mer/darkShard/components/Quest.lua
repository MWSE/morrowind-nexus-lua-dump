
local common = require("mer.darkShard.common")
local logger = common.createLogger("Quest")

---@class DarkShard.QuestData
---@field id string --Quest ID
---@field stages table<string, number> --Table of stages indexed by Id

---@class DarkShard.Quest : DarkShard.QuestData
---@field finalIndex number --The highest index in the stages table
---@field indexedStages table<number, string> --Table of stages indexed by their index
local Quest = {
    registeredQuests = {}
}

---@class Quest.quests
Quest.quests = setmetatable({}, {
    __index = function(t, key)
        return Quest.get(key)
    end
})

local defaultQuestData = {
    id = "",
    stages = {},
}

---@param stages table<string, number>
---@return number highest index in the stages table
local function getFinalStageIndex(stages)
    local highestFirstSort = function(a, b) return a >= b end
    return table.values(stages, highestFirstSort)[1]
end

---@param data DarkShard.QuestData
function Quest.register(data)
    local quest = Quest:new(data)
    Quest.registeredQuests[quest.id] = quest
    return quest
end




---@return DarkShard.Quest
function Quest.get(id)
    return Quest.registeredQuests[id]
end

---@param data DarkShard.QuestData
---@return DarkShard.Quest
function Quest:new(data)
    local self = table.copy(data)
    table.copymissing(self, defaultQuestData)
    logger:debug("New Quest: %s", self.id)
    --print stages
    for stage, index in pairs(self.stages) do
        logger:debug("Stage %s: %s", stage, index)
    end

    self.finalIndex = getFinalStageIndex(self.stages)
    self.indexedStages = table.invert(table.copy(self.stages))

    table.sort(self.indexedStages)
    setmetatable(self, { __index = Quest })
    return self
end

---Get the current index of the quest in the journal
---@return number
function Quest:getIndex()
    return tes3.getJournalIndex{ id = self.id }
end

function Quest:getStage()
    return self.indexedStages[self:getIndex()]
end

---Check if the quest is active (started but not finished)
---@return boolean
function Quest:isActive()
    return self:hasStarted() and not self:isFinished()
end

---Check if the quest started
---This will return true even if the quest is complete,
---To check if the quest is started and not finished, use Quest:isActive()
---@return boolean true if the quest has started
function Quest:hasStarted()
    return self:getIndex() > 0
end

---Check if the quest is finished
---@return boolean true if the quest is finished
function Quest:isFinished()
    return self:getIndex() >= self.finalIndex
end

---Check if the quest is at a specific stage
---@param index number
---@return boolean true if the quest is at the specified stage
function Quest:isAtIndex(index)
    return self:getIndex() == index
end

---Check if the quest is within the specified stage range
---Inclusive of the start stage, exclusive of the end stage
---@param startIndex number
---@param endIndex number
---@return boolean true if the quest is between the specified stages
function Quest:isBetween(startIndex, endIndex)
    return self:isBefore(endIndex) and self:isAfter(startIndex)
end

---Check if the quest is before a specific stage
---Exclusive of the specified stage
---@param index number
---@return boolean true if the quest is before the specified stage
function Quest:isBefore(index)
    return self:getIndex() < index
end

---Check if the quest is after a specific stage
---Inclusive of the specified stage
---@param index number
---@return boolean true if the quest is after the specified stage
function Quest:isAfter(index)
    return self:getIndex() >= index
end

---Update a quest to a specific stage
---@param index number
function Quest:setStage(index)
    logger:debug("Setting quest %s to stage %s", self.id, self.indexedStages[index])
    tes3.updateJournal{
        id = self.id,
        index = index
    }
end

---Update a quest to a specific index
---@param index number
function Quest:setIndex(index)
    logger:debug("Setting quest %s to index %s", self.id, index)

    --warn if not a valid stage
    if not self.indexedStages[index] then
        logger:error("Index %s is not a valid stage for quest %s", index, self.id)
    end

    tes3.updateJournal{
        id = self.id,
        index = index
    }
end

---Advance to a specific stage, if it is after the current stage
---@param index number
function Quest:advanceToStage(index)
    if self:isBefore(index) then
        self:setStage(index)
    else
        logger:warn("Cannot advance to stage %s, already at or past that stage", self.indexedStages[index])
    end
end

---Advance to the next stage in the quest
function Quest:advance()
    local currentIndex = self:getIndex()
    for index in ipairs(self.indexedStages) do
        if index > currentIndex then
            self:setStage(index)
            return
        end
    end
end

---Get the progress of the quest as a number between 0 and 1
---@return number
function Quest:getProgress()
    return math.remap(self:getIndex(), 0, self.finalIndex, 0, 1)
end

return Quest