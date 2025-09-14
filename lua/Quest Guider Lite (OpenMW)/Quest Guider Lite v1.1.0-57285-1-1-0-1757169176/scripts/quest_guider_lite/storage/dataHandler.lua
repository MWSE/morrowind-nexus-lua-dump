local markup = require('openmw.markup')
local core = require('openmw.core')
local storage = require('openmw.storage')
local async = require('openmw.async')

local common = require("scripts.quest_guider_lite.common")

local l10n = core.l10n(common.l10nKey)

local tableLib = require("scripts.quest_guider_lite.utils.table")

---@class questGuider.dataHandler.global
local this = {}

this.version = 7

---@type questDataGenerator.quests
this.quests = {}
---@type table<string, questDataGenerator.objectInfo>
this.questObjects = {}
---@type questDataGenerator.localVariableByQuestId
this.localVariablesByScriptId = {}

local defaultInfo = {version = 0, files = {}, time = 0}
this.info = tableLib.deepcopy(defaultInfo)

local isReady = false
local versionChanged = false
local gameFileDataEmpty = false

---@return boolean
function this.initStorage()
    isReady = false

    local settingsStorage = storage.playerSection(common.configQuestDataSectionName)
    local miscStorage = storage.playerSection(common.miscPalyerStorage)

    local stor = storage.playerSection(common.dataStorageName)

    if settingsStorage:get("disabled") then
        stor:setLifeTime(storage.LIFE_TIME.Temporary)
        settingsStorage:set("statusMessage", l10n("questDataDisabled"))
        return false
    end

    local infoSuccess, infoErr = pcall(function ()
        this.info = markup.loadYaml("questData/info.yaml")
    end)

    local loadedFromStorage = false
    local successfullyLoaded = false

    if infoSuccess then
        local storageInfoData = stor:get("info")
        if storageInfoData and storageInfoData.time and this.info.time and storageInfoData.time == this.info.time then
            loadedFromStorage = true
        end
    else
        local res, err = pcall(function ()
            local info = markup.loadYaml("info.yaml")
            if not (info.version and info.time and info.files and info.format) then
                error("")
            end
        end)

        if not miscStorage:get("incorrectFolderErrorMessageCount") then
            miscStorage:set("incorrectFolderErrorMessageCount", 2)
        end

        local errorMessageCount = miscStorage:get("incorrectFolderErrorMessageCount")

        if res and (errorMessageCount or 0) > 0 then
            pcall(function ()
                local ui = require("openmw.ui")
                ui.showMessage(l10n("questDataIncorrectFolderError"))
            end)
            miscStorage:set("incorrectFolderErrorMessageCount", errorMessageCount - 1)
        end

        stor:setLifeTime(storage.LIFE_TIME.Temporary)

        settingsStorage:set("statusMessage", l10n("questDataIncorrectFolder"))

        return false
    end

    if not loadedFromStorage then
        local res, err = pcall(function ()
            this.info = markup.loadYaml("questData/info.yaml")
            local quests = markup.loadYaml("questData/quests.yaml")
            local questObjects = markup.loadYaml("questData/questObjects.yaml")
            local localVariablesByScriptId = markup.loadYaml("questData/localVariables.yaml")
            stor:set("quests", quests)
            stor:set("questObjects", questObjects)
            stor:set("localVariablesByScriptId", localVariablesByScriptId)
            stor:set("info", this.info)
        end)
        loadedFromStorage = false
        successfullyLoaded = res
    else
        successfullyLoaded = true
    end

    if successfullyLoaded and this.version >= this.info.version then
        isReady = true
        versionChanged = false
        gameFileDataEmpty = #this.info.files == 0
    else
        print("Failed to load quest data")
        gameFileDataEmpty = this.info == nil or #this.info.files == 0
        this.info = tableLib.deepcopy(defaultInfo)
        if this.version ~= this.info.version then
            versionChanged = true
        end
    end

    stor:set("isReady", isReady)

    if isReady then
        settingsStorage:set("statusMessage", l10n("questDataReady"))
        miscStorage:set("incorrectFolderErrorMessageCount", 2)
    else
        settingsStorage:set("statusMessage", l10n("questDataNotFound"))
    end

    return isReady
end


---@param data questGuiderLite.event.dataReady.data
---@param isGlobalScope boolean?
function this.load(data, isGlobalScope)
    this.info = data.info or tableLib.deepcopy(defaultInfo)
    this.quests = data.quests or {}
    this.questObjects = data.questObjects or {}
    this.localVariablesByScriptId = data.localVariablesByScriptId or {}
    isReady = data.isReady
end


---@return boolean
function this.isReady()
    return isReady
end


---@return boolean ret returns true if the data changed
function this.compareGameFileData()
    if not isReady then return true end

    local activeFiles = core.contentFiles.list
    local files = this.info.files

    if #activeFiles ~= #files then return true end

    for i, activeFile in ipairs(activeFiles) do
        if activeFile ~= files[i] then
            return true
        end
    end

    return false
end

function this.isGameFileDataEmpty()
    return gameFileDataEmpty
end

function this.isVersionChanged()
    return versionChanged
end

return this