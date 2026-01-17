local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local interfaces = require('openmw.interfaces')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

local function achievementSync()
    
    local questList = types.Player.quests(self.object)

    for i = 1, #achievements do

        --- Sync for achievement type "single_quest"
        if achievements[i].type == "single_quest" then
            if achievements[i].operator(achievements[i], questList[achievements[i].journalID].stage) then
                local data = sk00maUtils.achievementToData(achievements[i])
                self.object:sendEvent('gettingAchievement', data)
            end
        end

        --- Sync for achievement type "multi_quest"
        if achievements[i].type == "multi_quest" then

            local currentQuestStageTable = {}
            local multiQuestJournalIds = achievements[i].journalID

            for k = 1, #multiQuestJournalIds do
                table.insert(currentQuestStageTable, questList[multiQuestJournalIds[k]].stage)
            end

            if achievements[i].operator(achievements[i], currentQuestStageTable) then
                local data = sk00maUtils.achievementToData(achievements[i])
                self.object:sendEvent('gettingAchievement', data)
            end
        end

    end

end

local function onLoad()

    types.Player.sendMenuEvent(self.object, 'requireCurrentSaveDir')
    achievementSync()

end

local function clearStorage()

    local macData = interfaces.storageUtils.getStorage("achievements")
    local macDataTable = interfaces.storageUtils.getStorage("achievements"):asTable()

    for k, v in pairs(macDataTable) do
        if v == true then
            macData:set(k, false)
        end
    end

end

return {
    engineHandlers = {
        onLoad = onLoad
    },
    eventHandlers = {
        clearStorage = clearStorage
    }
}