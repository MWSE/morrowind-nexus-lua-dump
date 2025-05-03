local ui = require('openmw.ui')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local interfaces = require('openmw.interfaces')

local v2 = util.vector2

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function gettingAchievementEvent(data)
    self.object:sendEvent('gettingAchievement', data)
end

local function onQuestUpdate(questId, stage)

    local macData = interfaces.storageUtils.getStorage("counters")
    local omwaData = interfaces.storageUtils.getStorage("achievements")

    for i = 1, #achievements do

        --- Check for single_quest
        if achievements[i].type == "single_quest" then
            if questId == string.lower(achievements[i].journalID) then
                if omwaData:get(achievements[i].id) == false then
                    if achievements[i].operator(achievements[i], stage) then
                        local achievement = achievements[i]
                        achievement.operator = nil
                        gettingAchievementEvent(achievement)
                    end
                end
            end
        end

        --- Check for multi_quest
        if achievements[i].type == "multi_quest" then

            local questAmount = #achievements[i].journalID
            local allCompleted = true
            local multiQuestJournalIds = achievements[i].journalID
            local multiQuestStages = achievements[i].stage
            local currentQuestStageTable = {}

            for q, str in ipairs(multiQuestJournalIds) do
                multiQuestJournalIds[q] = string.lower(str)
            end

            for k = 1, questAmount do
                if questId == multiQuestJournalIds[k] then
                    for j = 1, questAmount do
                        local currentQuestStage = types.Player.quests(self.object)[multiQuestJournalIds[j]].stage
                        table.insert(currentQuestStageTable, currentQuestStage)
                    end

                    if achievements[i].operator(achievements[i], currentQuestStageTable) then
                        local achievement = achievements[i]
                        achievement.operator = nil
                        gettingAchievementEvent(achievement)
                    end

                end
            end

        end

        --- Check for unique achievements
        if achievements[i].type == "unique" then

            --- Check #2 for unique achievement "Tribunal's Judgment"
            if achievements[i].id == "killtribunal_01" and questId == "tr_sothasil" and stage >= 100 then
                if macData:get("vivecIsDead") then
                    self.object:sendEvent('gettingAchievement', {
                        name = achievements[i].name,
                        description = achievements[i].description,
                        icon = achievements[i].icon,
                        id = achievements[i].id,
                        bgColor = achievements[i].bgColor
                    })
                end
            end

            --- Check for unique achievement "N'wah and Proud Of It"
            if achievements[i].id == "beast_nerevarine_01" and questId == "c3_destroydagoth" and stage >= 20 then
                if types.NPC.record(self.object).race == "khajiit" or types.NPC.record(self.object).race == "argonian" then
                    self.object:sendEvent('gettingAchievement', {
                        name = achievements[i].name,
                        description = achievements[i].description,
                        icon = achievements[i].icon,
                        id = achievements[i].id,
                        bgColor = achievements[i].bgColor
                    })
                end
            end

        end

    end 
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate
    }
}