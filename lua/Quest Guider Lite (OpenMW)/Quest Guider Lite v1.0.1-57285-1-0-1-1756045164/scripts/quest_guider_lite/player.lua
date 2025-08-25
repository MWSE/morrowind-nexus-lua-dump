local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local storage = require('openmw.storage')

local log = require("scripts.quest_guider_lite.utils.log")

local commonData = require("scripts.quest_guider_lite.common")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local config = require("scripts.quest_guider_lite.configLib")

local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local configLib = require("scripts.quest_guider_lite.configLib")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")

local timeLib = require("scripts.quest_guider_lite.timeLocal")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local createQuestMenu = require("scripts.quest_guider_lite.ui.customJournal.base")
local nextStagesBlock = require("scripts.quest_guider_lite.ui.customJournal.nextStagesBlock")

local l10n = core.l10n(commonData.l10nKey)


---@type table<string, questGuider.ui.customJournal>
local activeMenus = {}

local questBoxUpdateQueue = {}
local questBoxUpdateTimer = nil


core.sendGlobalEvent("QGL:setScaledScreenSize", uiUtils.getScaledScreenSize())


I.Settings.registerGroup{
    key = commonData.settingStorageToRemoveId,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "removeAllGroup",
    permanentStorage = false,
    order = 4,
    settings = {
        {
            key = "removeAll",
            renderer = "checkbox",
            name = "removeAllMarkers",
            description = "removeAllMarkersDescription",
            default = false,
        }
    },
}

local isStorageTimerRunning = false
local storageToRemove = storage.playerSection(commonData.settingStorageToRemoveId)
storageToRemove:subscribe(async:callback(function(section, key)
    local remove = storageToRemove:get("removeAll")
    if remove == true and not isStorageTimerRunning then
        isStorageTimerRunning = true
        async:newUnsavableSimulationTimer(0.1, function ()
            isStorageTimerRunning = false
            if storageToRemove:get("removeAll") then
                tracking.removeAll()
                tracking.updateMarkers()
                storageToRemove:set("removeAll", false)
            end
        end)
    end
end))


playerDataHandler.init()


-- for cases when the load order is incorrect
async:newUnsavableSimulationTimer(0.001, function ()
    tracking.init()
end)

local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    killCounter.initByStorageData(localStorage.data)
    tracking.init()
    playerQuests.init()
end


local function teleportedCallback()
    local newCell = self.cell
    if not newCell.isExterior then
        tracking.addMarkersForInteriorCell(newCell)
    end
end


local function onLoad(data)
    localStorage.initPlayerStorage(data)
    killCounter.initByStorageData(localStorage.data)
    tracking.init()
    playerQuests.init()
    async:newUnsavableSimulationTimer(0.1, function ()
        teleportedCallback()
    end)
end


local function onSave()
    local data = {}
    localStorage.save(data)
    return data
end


local function questBoxUpdateTimerCallback()
    for func, _ in pairs(questBoxUpdateQueue) do
        func()
        questBoxUpdateQueue[func] = nil
        break;
    end
    if next(questBoxUpdateQueue) then
        questBoxUpdateTimer = realTimer.newTimer(0, questBoxUpdateTimerCallback)
    else
        questBoxUpdateTimer = nil
    end
end


---@param params questGuider.main.fillQuestBoxQuestInfo.return
local function fillQuestBoxQuestInfo(params)
    local func = function ()
        if not activeMenus[params.menuId] then return end
        ---@class questGuider.ui.questBoxMeta
        local questBox = activeMenus[params.menuId]:getQuestScrollBox().userData.questBoxMeta

        questBox.questInfo = params.data
        questBox:addTrackButtons()

        ---@type questGuider.ui.scrollBox
        local scrollBox = questBox:getScrollBox().userData.scrollBoxMeta

        local scrollBoxContent = scrollBox:getMainFlex()

        for contentIndex, dt in pairs(params.data) do
            local element = scrollBoxContent.content[contentIndex]
            if not element then goto continue end

            element.content:add(
                nextStagesBlock.create{
                    data = dt,
                    size = scrollBox.innnerSize,
                    fontSize = config.data.ui.fontSize,
                    hideTrackButtons = params.menuId ~= commonData.journalMenuId,
                    isQuestListMode = params.menuId ~= commonData.journalMenuId,
                    updateFunc = function ()
                        activeMenus[params.menuId]:update()
                    end,
                    thisElementInContent = function ()
                        return scrollBox:getMainFlex().content[contentIndex].content[#element.content]
                    end
                }
            )

            ::continue::
        end
        activeMenus[params.menuId]:update()
    end

    -- For safety, the menu is updated once per frame, since I had issues with updating in other places
    questBoxUpdateQueue[func] = true
    if not questBoxUpdateTimer then
        questBoxUpdateTimer = realTimer.newTimer(0, questBoxUpdateTimerCallback)
    end
end


local function toggleMenu()
    if activeMenus[commonData.journalMenuId] then
        activeMenus[commonData.journalMenuId].menu:destroy()
        activeMenus[commonData.journalMenuId] = nil
        I.UI.removeMode("Journal")
    else
        I.UI.setMode("Journal", { windows = {} })
        activeMenus[commonData.journalMenuId] = createQuestMenu{
            fontSize = config.data.ui.fontSize,
            sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
            relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
            onClose = function ()
                activeMenus[commonData.journalMenuId] = nil
                I.UI.removeMode("Journal")
            end
        }
    end
end


input.registerTriggerHandler("QGL:journal.menuKey", async:callback(function()
    if input.isCtrlPressed() and input.isShiftPressed() then
        if activeMenus[commonData.allQuestsMenuId] then
            activeMenus[commonData.allQuestsMenuId].menu:destroy()
            activeMenus[commonData.allQuestsMenuId] = nil
        end
        I.UI.setMode("Journal", { windows = {} })

        local dialogues = {}
        for qName, dt in pairs(playerQuests.questData) do
            for diaId, _ in pairs(dt.records) do
                table.insert(dialogues, diaId)
            end
        end

        activeMenus[commonData.allQuestsMenuId] = createQuestMenu{
            fontSize = config.data.ui.fontSize,
            sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
            relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
            headerName = l10n("quests"),
            menuId = commonData.allQuestsMenuId,
            questList = dialogues,
            isQuestList = true,
            showReqsForAll = true,
            onClose = function ()
                activeMenus[commonData.allQuestsMenuId] = nil
                I.UI.removeMode("Journal")
            end
        }
    else
        toggleMenu()
    end
end))

if config.data.journal.overrideJournal then
    I.UI.registerWindow("Journal", function() toggleMenu() end, function () toggleMenu() end)
end

local function onKeyRelease(key)
    if not core.isWorldPaused() then
        for _, menuHandler in pairs(activeMenus) do
            menuHandler.menu:destroy()
        end
        activeMenus[commonData.journalMenuId] = nil
    end
end


local function handleTracking()
    if not tracking.initialized then return end
    local updateMarkers = false
    updateMarkers = tracking.handlePlayerInventory()

    if updateMarkers then
        tracking.updateMarkers()
    end
end


time.runRepeatedly(function()
    handleTracking()
end, 5 * time.second + math.random())

local onQuestUpdateTimerStarted = false

return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            playerQuests.update(questId, stage)

            if not tracking.initialized then return end
            if config.data.tracking.autoTrack then
                tracking.trackQuest(questId, stage)
            end
            if not onQuestUpdateTimerStarted then
                onQuestUpdateTimerStarted = true
                async:newUnsavableSimulationTimer(0.05, function()
                    handleTracking()
                    core.sendGlobalEvent("QGL:updateQuestGiverMarkers", {})
                    tracking.updateTemporaryMarkers()
                    onQuestUpdateTimerStarted = false
                end)
            end
        end,
        onTeleported = function ()
            async:newUnsavableSimulationTimer(0.1, function () -- delay for the player cell data to be updated
                teleportedCallback()
            end)
        end,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
        onKeyRelease = onKeyRelease,
        onFrame = function(dt)
            realTimer.updateTimers()
        end,
    },
    eventHandlers = {
        ["QGL:addMarker"] = function(data)
            tracking.addMarker(data)
        end,

        ["QGL:showTrackingMessage"] = function (data)
            if not data.message then return end
            ui.showMessage(data.message)
        end,

        ["QGL:addMarkerForQuestGivers"] = function (data)
            if not tracking.init() or not config.data.tracking.questGivers then return end
            local valid = false
            for _, qName in pairs(data.questNames or {}) do
                if not playerQuests.getQuestStorageData(qName) then
                    valid = true
                    break
                end
            end
            if not valid then return end

            local recordId, markerId, markerGroupId = tracking.addTrackingMarker(data.recordData, data.markerData)
            local hudMarkerId
            if data.hudMarkerData then
                hudMarkerId = tracking.addHUDMarker(data.hudMarkerData)
            end

            tracking.updateMarkers()

            if data.objectRecordId then
                core.sendGlobalEvent("QGL:questGiverMarkerCallback", {
                    record = recordId,
                    hudMarkerId = hudMarkerId,
                    inputData = data,
                })
            end
        end,

        ["QGL:updateMarkers"] = function ()
            tracking.updateMarkers()
        end,

        ["QGL:removeProximityRecord"] = function (data)
            local recordId = data.recordId
            tracking.removeProximityRecord(recordId)
            tracking.updateMarkers()
        end,

        ["QGL:removeProximityMarker"] = function (data)
            local id = data.id
            local groupId = data.groupId
            tracking.removeProximityMarker(id, groupId)
            tracking.updateMarkers()
        end,

        ["QGL:removeHUDMarker"] = function (data)
            local id = data.id
            tracking.removeHUDMarker(id)
            tracking.updateMarkers()
        end,

        ["QGL:addMarkerForInteriorCellTracking"] = function (data)
            tracking.addMarkerForInteriorCellFromGlobal(data)
            tracking.updateMarkers()
        end,

        ["QGL:updateTime"] = function (data)
            timeLib.time = data.time
        end,

        ["QGL:fillQuestBoxQuestInfo"] = fillQuestBoxQuestInfo,

        ["QGL:updateQuestMenu"] = function (data)
            if not activeMenus[commonData.journalMenuId] then return end

            activeMenus[commonData.journalMenuId]:updateNextStageBlocks()
            activeMenus[commonData.journalMenuId]:updateQuestListTrackedColors()
            activeMenus[commonData.journalMenuId]:update()
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
            tracking.handleDeath(data.object.recordId)
        end,

        ["QGL:createMarkersForDoor"] = function (ref)
            tracking.createMarkersForExteriorDoor(ref)
        end,

        ---@param data proximityTool.event.callbackParams
        ["QGL:proximityMarkerCallback"] = function (data)
            if not data.recordData or not data.recordData.userData
                    or data.eventArgument.button ~= 1 then
                return
            end
            local userData = data.recordData.userData

            if userData.type == "tracking" and userData.questName then ---@diagnostic disable-line: need-check-nil
                if not activeMenus[commonData.journalMenuId] then
                    I.UI.setMode("Journal", { windows = {} })
                    activeMenus[commonData.journalMenuId] = createQuestMenu{
                        fontSize = config.data.ui.fontSize,
                        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
                        relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
                        onClose = function ()
                            activeMenus[commonData.journalMenuId] = nil
                            I.UI.removeMode("Journal")
                        end
                    }
                end
                activeMenus[commonData.journalMenuId]:selectQuest(userData.questName) ---@diagnostic disable-line: need-check-nil
            end
        end,

        ---@param data proximityTool.event.callbackParams
        ["QGL:questGiverMarkerCallback"] = function (data)
            if not data.recordData or not data.recordData.userData
                    or (data.recordData.userData.type ~= "questGiver" and data.recordData.userData.type ~= "doorQuestGiver") then
                return
            end

            local objName = data.recordData.userData.objName or ""
            if activeMenus[objName] then
                activeMenus[objName].menu:destroy()
                activeMenus[objName] = nil
            end

            activeMenus[objName] = createQuestMenu{
                fontSize = config.data.ui.fontSize,
                sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
                relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
                headerName = objName,
                questList = data.recordData.userData.diaIds,
                isQuestList = true,
                showReqsForAll = true,
                showOnlyFirst = true,
                hideStageText = true,
                onClose = function ()
                    activeMenus[objName] = nil
                end
            }
        end,
    },
}