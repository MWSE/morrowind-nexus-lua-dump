local self = require("openmw.self")
local ui = require("openmw.ui")
local storage = require("openmw.storage")

require("scripts.MeritsOfService.utils.consts")
require("scripts.MeritsOfService.logic.quests")
require("scripts.MeritsOfService.logic.statRewards")
require("scripts.MeritsOfService.logic.rewards")
local rewardPool = require("scripts.MeritsOfService.utils.factionParser")

local sectionRewards = storage.playerSection("SettingsMeritsOfService_rewards")

local rewardMap = {
    attributes = {
        weightGetter       = function()
            return sectionRewards:get("attributeRewardWeight")
        end,
        rewardAmountPicker = AttrAmountPicker,
        rewardGiver        = GrantAttributes,
        condition          = AttrCapChecker,
    },
    skills = {
        weightGetter       = function()
            return sectionRewards:get("skillRewardWeight")
        end,
        rewardAmountPicker = SkillAmountPicker,
        rewardGiver        = GrantSkills,
        condition          = SkillCapChecker,
    }
}

local function onQuestUpdate(questId, stage)
    local factionName = GetFactionName(rewardPool, questId)
    local factionQuests = CompletedQuests[factionName]

    -- init faction if it's a new one
    if factionName and not factionQuests then
        factionQuests = {
            count = 0,
            quests = {}
        }
    end

    if not factionName
        or not QuestFinished(questId, self)
        or factionQuests.quests[questId]
    then
        return
    end

    AddCompletedQuest(CompletedQuests, factionName, questId, self)

    local questsUntilReward = factionQuests.count % sectionRewards:get("questsPerReward")
    -- if it's too early to give rewards
    if questsUntilReward ~= 0 then return end

    local rewardType = PickRewardType(rewardPool[factionName], rewardMap)
    -- if cap on all rewards is reached
    if not rewardType then return end

    local settings = rewardMap[rewardType]
    local rewardAmount = settings.rewardAmountPicker()
    settings.rewardGiver(rewardPool[factionName], rewardAmount)
end

local function onSave()
    return CompletedQuests
end

local function onLoad(saveData)
    CompletedQuests = saveData
end

local function onConsoleCommand(mode, command, selectedObject)
    if string.lower(command) == "lua meritmyservice" then
        -- retoractive update
        for questId, _ in pairs(self.type.quests(self)) do
            print(questId)
            onQuestUpdate(questId, nil)
        end

        ui.printToConsole("[Merits of Service] Rewards granted.", ui.CONSOLE_COLOR.Success)
    end
end

---@class RegisterRewardOptions
---@field rewardKey string        -- must match rewardKey provided to addRewardToFactionPool()
---@field weightGetter fun(): number
---@field rewardAmountPicker fun(): number
-- takes the same rewardList as provided in addRewardToFactionPool() as parameter
---@field rewardGiver fun(rewardList: table<any>, rewardAmount: number)
---@diagnostic disable-next-line: undefined-doc-name
-- returns true if reward CAN be granted
-- takes the same rewardList as provided in addRewardToFactionPool() as parameter
---@field condition fun(rewardList: table<any>): boolean

---@param o RegisterRewardOptions
local function registerNewReward(o)
    rewardMap[o.rewardKey] = {
        weightGetter       = o.weightGetter,
        rewardAmountPicker = o.rewardAmountPicker,
        rewardGiver        = o.rewardGiver,
        condition          = o.condition,
    }
end

---@class AddRewardToFactionPoolOptions
---@field factionName string      -- case sensitive, needs to match quest names
---@field rewardKey string        -- must match rewardKey provided to registerNewReward()
---@field rewardList table<any>

---@param o AddRewardToFactionPoolOptions
local function addRewardToFactionPool(o)
    rewardPool[o.factionName][o.rewardKey] = o.rewardList
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onConsoleCommand = onConsoleCommand,
    },
    interfaceName = "MeritsOfService",
    interface = {
        version = 3.0,
        registerNewReward = registerNewReward,
        addRewardToFactionPool = addRewardToFactionPool,
    }
}
