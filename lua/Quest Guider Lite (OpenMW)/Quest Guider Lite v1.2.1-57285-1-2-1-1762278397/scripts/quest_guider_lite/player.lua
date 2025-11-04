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

local mapWidget = require("scripts.quest_guider_lite.ui.mapWidget")
local createQuestMenu = require("scripts.quest_guider_lite.ui.customJournal.base")
local createTopicMenu = require("scripts.quest_guider_lite.ui.topicMenu")
local createTrackingMenu = require("scripts.quest_guider_lite.ui.trackingMenu")
local nextStagesBlock = require("scripts.quest_guider_lite.ui.customJournal.nextStagesBlock")
local simpleMap = require("scripts.quest_guider_lite.ui.mapMenu")
local messageBox = require("scripts.quest_guider_lite.ui.messageBox")

local l10n = core.l10n(commonData.l10nKey)


---@type table<string, questGuider.ui.customJournal|questGuider.ui.topicMenuMeta|questGuider.ui.trackingMenuMeta>
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


local function onMouseWheel(vertical)
    for _, menu in pairs(activeMenus) do
        if menu.onMouseWheel then
            menu:onMouseWheel(vertical)
        end
    end
end


local function onMouseButtonRelease(buttonId)
    for _, menu in pairs(activeMenus) do
        if menu.onMouseClick then
            menu:onMouseClick(buttonId)
        end
    end
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

        local scrollBoxElement = scrollBox:getMainFlex()

        for contentIndex, dt in pairs(params.data) do
            local element = scrollBoxElement.content[contentIndex]
            if not element then goto continue end

            element.content:add(
                nextStagesBlock.create{
                    data = dt,
                    size = scrollBox.innnerSize,
                    fontSize = config.data.ui.fontSize,
                    hideTrackButtons = params.menuId ~= commonData.journalMenuId,
                    isQuestListMode = params.menuId ~= commonData.journalMenuId,
                    parentScrollBoxUserData = questBox:getScrollBox().userData,
                    updateHeightFunc = function ()
                        scrollBox:setContentHeight(uiUtils.getContentHeight(scrollBoxElement.content))
                    end,
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

        scrollBox:setContentHeight(uiUtils.getContentHeight(scrollBoxElement.content))

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
        if not next(activeMenus) then
            I.UI.removeMode("Journal")
        end
    else
        I.UI.setMode("Journal", { windows = {} })
        activeMenus[commonData.journalMenuId] = createQuestMenu{
            fontSize = config.data.ui.fontSize,
            sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
            relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
            createTopicMenuFunc = function ()
                if activeMenus[commonData.topicsMenuId] then
                    activeMenus[commonData.topicsMenuId].menu:destroy()
                    activeMenus[commonData.topicsMenuId] = nil
                end

                activeMenus[commonData.topicsMenuId] = createTopicMenu{
                    fontSize = config.data.ui.fontSize,
                    sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01 - 0.1, config.data.journal.heightProportional * 0.01 - 0.1),
                    relativePosition = util.vector2(config.data.journal.position.x * 0.01 + 0.05, config.data.journal.position.y * 0.01 + 0.05),
                    onClose = function ()
                        activeMenus[commonData.topicsMenuId] = nil
                        if not next(activeMenus) then
                            I.UI.removeMode("Journal")
                        end
                    end
                }
            end,
            createTrackingMenuFunc = function ()
                if activeMenus[commonData.trackingMenuId] then
                    activeMenus[commonData.trackingMenuId].menu:destroy()
                    activeMenus[commonData.trackingMenuId] = nil
                end

                activeMenus[commonData.trackingMenuId] = createTrackingMenu{
                    fontSize = config.data.ui.fontSize,
                    sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01 - 0.1, config.data.journal.heightProportional * 0.01 - 0.1),
                    relativePosition = util.vector2(config.data.journal.position.x * 0.01 + 0.05, config.data.journal.position.y * 0.01 + 0.05),
                    onClose = function ()
                        activeMenus[commonData.trackingMenuId] = nil
                        if not next(activeMenus) then
                            I.UI.removeMode("Journal")
                        end
                    end
                }
            end,
            onClose = function ()
                activeMenus[commonData.journalMenuId] = nil
                if not next(activeMenus) then
                    I.UI.removeMode("Journal")
                end
            end
        }
    end
end


input.registerTriggerHandler(commonData.journalMenuTriggerId, async:callback(function()
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
                if not next(activeMenus) then
                    I.UI.removeMode("Journal")
                end
            end
        }
    elseif input.isShiftPressed() and config.data.tracking.toggleVisibilityByJournalKey then
        tracking.setMarkersVisibility{toggle = true, includeQuestGivers = true}
        if activeMenus[commonData.journalMenuId] then
            activeMenus[commonData.journalMenuId]:updateMarkersDisabledMessage()
        end
    else
        toggleMenu()
    end
end))

if config.data.journal.overrideJournal then
    I.UI.registerWindow("Journal", function() toggleMenu() end, function () toggleMenu() end)
end


input.registerTriggerHandler(commonData.toggleMarkersTriggerId, async:callback(function()
    tracking.setMarkersVisibility{toggle = true, includeQuestGivers = true}
    if activeMenus[commonData.journalMenuId] then
        activeMenus[commonData.journalMenuId]:updateMarkersDisabledMessage()
    end
end))


local function onKeyRelease(key)
    if key.code == input.KEY.Escape then
        for id, menuHandler in pairs(activeMenus) do
            menuHandler.menu:destroy()
            activeMenus[id] = nil
        end
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
                core.sendGlobalEvent("QGL:updateQuestGiverMarkers", {})
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
        onMouseWheel = onMouseWheel,
        onMouseButtonRelease = onMouseButtonRelease,
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

            local createProximityMarkers = config.data.tracking.proximityMarkers.enabled and config.data.tracking.proximityMarkers.details.givers
            local createHUDMarkers = config.data.tracking.hudMarkers.enabled and config.data.tracking.hudMarkers.details.givers

            local recordId, markerId, markerGroupId
            if createProximityMarkers then
                recordId, markerId, markerGroupId = tracking.addTrackingMarker(data.recordData, data.markerData)
                if tracking.storageData.hideAllMarkers and recordId then
                    tracking.setProximityMarkerVisibility{recordId = recordId, value = false}
                end
            end

            local hudMarkerId
            if data.hudMarkerData and createHUDMarkers then
                hudMarkerId = tracking.addHUDMarker(data.hudMarkerData)
                if tracking.storageData.hideAllMarkers and hudMarkerId then
                    tracking.setHUDMarkerVisibility{markerId = hudMarkerId, value = false}
                end
            end

            tracking.updateMarkers()

            core.sendGlobalEvent("QGL:questGiverMarkerCallback", {
                record = recordId,
                hudMarkerId = hudMarkerId,
                inputData = data,
            })
        end,

        ["QGL:updateMarkers"] = function ()
            tracking.updateMarkers()
        end,

        ["QGL:removeProximityRecord"] = function (data)
            local recordId = data.recordId
            if not recordId then return end
            tracking.removeProximityRecord(recordId)
            tracking.updateMarkers()
        end,

        ["QGL:removeProximityMarker"] = function (data)
            local id = data.id
            local groupId = data.groupId
            if not id then return end
            tracking.removeProximityMarker(id, groupId)
            tracking.updateMarkers()
        end,

        ["QGL:removeHUDMarker"] = function (data)
            local id = data.id
            if not id then return end
            tracking.removeHUDMarker(id)
            tracking.updateMarkers()
        end,

        ["QGL:updateProximityMarkerVisibility"] = function (data)
            if data.recordId then
                tracking.setProximityMarkerVisibility{
                    recordId = data.recordId,
                    value = not tracking.storageData.hideAllMarkers
                }
                tracking.updateProximityMarkers()
            end
        end,

        ["QGL:updateHUDMarkerVisibility"] = function (data)
            if not data.id then return end

            tracking.setHUDMarkerVisibility{
                markerId = data.id,
                value = not tracking.storageData.hideAllMarkers
            }
            tracking.updateHUDM()
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
                            if not next(activeMenus) then
                                I.UI.removeMode("Journal")
                            end
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
                    if not next(activeMenus) then
                        I.UI.removeMode("Journal")
                    end
                end
            }
        end,

        ["QGL:getPositionsForTrackingMenu"] = function (data)
            if not data.menuId or not data.positions then return end

            ---@type questGuider.ui.trackingMenuMeta
            local menu = activeMenus[data.menuId]
            if not menu then return end

            menu.positions = data.positions

            if configLib.data.journal.mapByDefault then
                menu:showMainMap()
            end
        end,

        ["QGL:updateCityInfo"] = function (data)
            mapWidget.cityInfo = data
        end,

        ["QGL:showSimpleMap"] = function (data)
            if activeMenus[commonData.simpleMapMenuId] then
                activeMenus[commonData.simpleMapMenuId].menu:destroy()
                activeMenus[commonData.simpleMapMenuId] = nil
            end

            local menu = simpleMap.new{
                onClose = function ()
                    activeMenus[commonData.simpleMapMenuId] = nil
                    if not next(activeMenus) then
                        I.UI.removeMode("Journal")
                    end
                end
            }

            if not menu then return end

            if data.positions then
                if not menu:mark(data.positions) then
                    menu:close()
                end
            end

            activeMenus[commonData.simpleMapMenuId] = menu
        end,

        ["QGL:removeAllTrackedMessageBox"] = function ()
            if activeMenus[commonData.messageBoxMenuId] then
                activeMenus[commonData.messageBoxMenuId].menu:destroy()
                activeMenus[commonData.messageBoxMenuId] = nil
            end

            activeMenus[commonData.messageBoxMenuId] = messageBox.newSimple{
                message = l10n("removeTrackingFromListedMessageBox"),
                relativeSize = util.vector2(0.25, 0.2),
                yesCallback = function ()
                    local trackingMenuMeta = activeMenus[commonData.trackingMenuId]
                    if not trackingMenuMeta then return end
                    trackingMenuMeta:removeListed()
                    trackingMenuMeta:fillTrackingListContent()
                    trackingMenuMeta:clearTrackingInfo()
                    trackingMenuMeta:resetListSelection()
                    trackingMenuMeta:update()
                end,
                onClose = function ()
                    activeMenus[commonData.messageBoxMenuId] = nil
                end
            }
        end,

        ["QGL:journalMenuSelectQuest"] = function (data)
            if not data or not data.qName then return end
            local journalMenu = activeMenus[commonData.journalMenuId]
            if not journalMenu then return end

            journalMenu:selectQuest(data.qName)
        end,
    },
}