local core = require("openmw.core")
local player = require("openmw.self")
local storage = require("openmw.storage")
local vfs = require("openmw.vfs")

local commonData = require("scripts.quest_guider_lite.common")


---@class questGuider.dataHandler.player
local this = {}

---@type questGuiderLite.event.dataReady.data
this.data = {
    ---@type questDataGenerator.quests
    quests = {},
    ---@type table<string, questDataGenerator.objectInfo>
    questObjects = {},
    ---@type questDataGenerator.localVariableByQuestId
    localVariablesByScriptId = {},
    ---@type questDataGenerator.dialogueTopicData
    dialogueTopics = {},
    ---@type questDataGenerator.mapImageInfo?
    mapInfo = nil,
    info = {version = 0, files = {}, time = 0, format = "yaml"},
    isReady = false,
}


function this.init()
    local stor = storage.playerSection(commonData.dataStorageName)
    if not stor then return end

    local isReady = stor:get("isReady")
    if isReady then
        local dt = stor:asTable() or {}

        ---@type questGuiderLite.event.dataReady.data
        this.data = {
            quests = dt.quests or {},
            questObjects = dt.questObjects or {},
            localVariablesByScriptId = dt.localVariablesByScriptId or {},
            dialogueTopics = dt.dialogueTopics or {},
            mapInfo = dt.mapInfo,
            info = dt.info,
            isReady = isReady,
        }

        core.sendGlobalEvent("QGL:Interop:DataReady", this.data)
        player:sendEvent("QGL:Interop:DataReady", this.data)
    end
end


function this.isMapImageExists()
    if this.data.mapInfo and this.data.mapInfo.file then
        local mapImagePath = "questData/"..this.data.mapInfo.file
        return vfs.fileExists(mapImagePath)
    end
    return false
end


return this