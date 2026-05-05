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
local questLib = require("scripts.quest_guider_lite.questBase")
local configLib = require("scripts.quest_guider_lite.configLib")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local dateLib = require("scripts.quest_guider_lite.utils.date")
local timeLib = require("scripts.quest_guider_lite.timeLocal")

local menuMode = require("scripts.quest_guider_lite.ui.menuMode")
local menuHandler = require("scripts.quest_guider_lite.menuHandler")

local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local advWMapIntegration = require("scripts.quest_guider_lite.map.advWMapIntegration")

local realTimer = require("scripts.quest_guider_lite.realTimer")

local controllerScrollTimer = require("scripts.quest_guider_lite.input.controllerScroll")

local mapWidget = require("scripts.quest_guider_lite.ui.mapWidget")
local createQuestMenu = require("scripts.quest_guider_lite.ui.customJournal.base")
local createTopicMenu = require("scripts.quest_guider_lite.ui.topicMenu")
local createTrackingMenu = require("scripts.quest_guider_lite.ui.trackingMenu").createMenu
local createFirstInitMenu = require("scripts.quest_guider_lite.ui.firstInitMenu").new
local nextStagesBlock = require("scripts.quest_guider_lite.ui.customJournal.nextStagesBlock")
local simpleMap = require("scripts.quest_guider_lite.ui.mapMenu")
local messageBox = require("scripts.quest_guider_lite.ui.messageBox")

local l10n = core.l10n(commonData.l10nKey)


local questBoxUpdateQueue = {}
local questBoxUpdateTimer = nil

pcall(function ()
    if not ui.layers.indexOf(commonData.messageLayer) then
        ui.layers.insertBefore("DragAndDrop", commonData.messageLayer, { interactive = true })
    end
end)
if not ui.layers.indexOf(commonData.mainMenuLayer) then
    ui.layers.insertAfter("Windows", commonData.mainMenuLayer, { interactive = true })
end
if not ui.layers.indexOf(commonData.topicMenuLayer) then
    ui.layers.insertAfter(commonData.mainMenuLayer, commonData.topicMenuLayer, { interactive = true })
end
-- Tracking menu uses the same layer as topic menu, so no need to add it
-- if not ui.layers.indexOf(commonData.trackingMenuLayer) then
--     ui.layers.insertAfter(commonData.topicMenuLayer, commonData.trackingMenuLayer, { interactive = true })
-- end


core.sendGlobalEvent("QGL:setScaledScreenSize", uiUtils.getScaledScreenSize())


I.Settings.registerGroup{
    key = commonData.settingStorageToRemoveId,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "removeAllGroup",
    permanentStorage = false,
    order = 5,
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
timeLib.requestTimeUpdate()


-- for cases when the load order is incorrect
async:newUnsavableSimulationTimer(0.001, function ()
    tracking.init()
    advWMapIntegration.init()
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
    menuHandler.onMouseWheelCallback(vertical)
end


controllerScrollTimer.callback = function (axisVal)
    axisVal = -axisVal
    if axisVal > 0.5 then
        onMouseWheel(1)
    elseif axisVal < -0.5 then
        onMouseWheel(-1)
    end
end


local gamepadJournalScrollEnabled = false
local function gamepadJournalScroll(lTr, rTr)
    if not gamepadJournalScrollEnabled then return end
    lTr = lTr < 0.5 and 0 or lTr
    rTr = rTr < 0.5 and 0 or rTr

    if menuHandler.getMenu(commonData.trackingMenuId) then
        return
    end

    local v = rTr - lTr
    if math.abs(v) < 0.5 then return end

    local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
    if topicMenu then
        topicMenu:scrollInfo(v)
        return
    end

    local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
    if journalMenu then
        journalMenu:scrollInfo(v)
        return
    end

    local firstInitMenu = menuHandler.getMenu(commonData.firstInitMenuId)
    if firstInitMenu then
        firstInitMenu:scrollInfo(v)
        return
    end
end

controllerScrollTimer.triggerCallback = gamepadJournalScroll


local function onMouseButtonRelease(buttonId)
    menuHandler.onMouseReleaseCallback(buttonId)
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
        if not menuHandler.getMenu(params.menuId) then return end
        ---@class questGuider.ui.questBoxMeta
        local questBox = menuHandler.getMenu(params.menuId):getQuestScrollBox().userData.questBoxMeta

        questBox.questInfo = params.data
        questBox:addTrackButtons()

        ---@type questGuider.ui.scrollBox
        local scrollBox = questBox:getScrollBox().userData.scrollBoxMeta

        local scrollBoxContent = scrollBox:getContent()

        for contentIndex, dt in pairs(params.data) do
            local element = scrollBoxContent[contentIndex]
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
                        scrollBox:calcContentHeight()
                        scrollBox:updateContent()
                    end,
                    updateFunc = function ()
                        menuHandler.getMenu(params.menuId):update()
                    end,
                    thisElementInContent = function ()
                        return scrollBox:getContent()[contentIndex].content[#element.content]
                    end
                }
            )

            ::continue::
        end

        scrollBox:calcContentHeight()
        scrollBox:updateContent()

        menuHandler.getMenu(params.menuId):update()
    end

    -- For safety, the menu is updated once per frame, since I had issues with updating in other places
    questBoxUpdateQueue[func] = true
    if not questBoxUpdateTimer then
        questBoxUpdateTimer = realTimer.newTimer(0, questBoxUpdateTimerCallback)
    end
end


local function buildTopicMenu()
    return createTopicMenu{
        fontSize = config.data.ui.fontSize,
        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01 - 0.1, config.data.journal.heightProportional * 0.01 - 0.1),
        relativePosition = util.vector2(config.data.journal.position.x * 0.01 + 0.05, config.data.journal.position.y * 0.01 + 0.05),
    }
end


local function buildTrackingMenu()
    return createTrackingMenu{
        fontSize = config.data.ui.fontSize,
        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01 - 0.1, config.data.journal.heightProportional * 0.01 - 0.1),
        relativePosition = util.vector2(config.data.journal.position.x * 0.01 + 0.05, config.data.journal.position.y * 0.01 + 0.05),
    }
end


local function buildMainQuestMenu()
    return createQuestMenu{
        fontSize = config.data.ui.fontSize,
        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
        relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
        createTopicMenuFunc = function ()
            menuHandler.destroyMenu(commonData.topicsMenuId)

            menuHandler.registerMenu(commonData.topicsMenuId, buildTopicMenu())
        end,
        createTrackingMenuFunc = function ()
            menuHandler.destroyMenu(commonData.trackingMenuId)

            menuHandler.registerMenu(commonData.trackingMenuId, buildTrackingMenu())
        end,
    }
end


local function buildAllQuestsMenu()
    local dialogues = {}
    for qName, dt in pairs(playerQuests.questData) do
        for diaId, _ in pairs(dt.records) do
            table.insert(dialogues, diaId)
        end
    end

    return createQuestMenu{
        fontSize = config.data.ui.fontSize,
        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
        relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
        headerName = l10n("quests"),
        menuId = commonData.allQuestsMenuId,
        questList = dialogues,
        isQuestList = true,
        showReqsForAll = true,
    }
end


local function toggleMenu(withoutMenuMode)
    if menuHandler.getMenu(commonData.journalMenuId) then
        menuHandler.destroyMenu(commonData.journalMenuId)
    elseif menuHandler.getMenu(commonData.firstInitMenuId) then
        menuHandler.destroyMenu(commonData.firstInitMenuId)
    else
        if not withoutMenuMode then
            menuHandler.activateMenuMode()
        end

        if configLib.data.journal.firstInitMenu and playerDataHandler.data.isReady then
            menuHandler.registerMenu(commonData.firstInitMenuId, createFirstInitMenu{
                yesCallback = function ()
                    configLib.setValue("journal.firstInitMenu", false)
                    menuHandler.registerMenu(commonData.journalMenuId, buildMainQuestMenu())
                end
            })
        else
            menuHandler.registerMenu(commonData.journalMenuId, buildMainQuestMenu())
        end
    end
end


I.DijectKeyBindings.action.register(commonData.journalMenuTriggerId, function()
    toggleMenu()
end)


I.DijectKeyBindings.action.register(commonData.allQuestsTriggerId, function()
    menuHandler.destroyMenu(commonData.allQuestsMenuId)
    menuHandler.activateMenuMode()

    menuHandler.registerMenu(commonData.allQuestsMenuId, buildAllQuestsMenu())
end)


I.DijectKeyBindings.action.register(commonData.topicMenuTriggerId, function()
    if menuHandler.getMenu(commonData.topicsMenuId) then
        menuHandler.destroyMenu(commonData.topicsMenuId)
    else
        menuHandler.registerMenu(commonData.topicsMenuId, buildTopicMenu())
    end
end)


I.DijectKeyBindings.action.register(commonData.trackingMenuTriggerId, function()
    if menuHandler.getMenu(commonData.trackingMenuId) then
        menuHandler.destroyMenu(commonData.trackingMenuId)
    else
        menuHandler.registerMenu(commonData.trackingMenuId, buildTrackingMenu())
    end
end)


I.UI.registerWindow("Journal",
    function()
        toggleMenu(true)
        menuMode.setActivatedFlag(true)
    end,
    function ()
        realTimer.newTimer(0.1, function ()
            menuHandler.destroyMenu(commonData.journalMenuId)
        end)
    end)


local function markerClick(userData)
    if not userData then return end

    if userData.type == "tracking" and userData.questName then ---@diagnostic disable-line: need-check-nil
        if not menuHandler.getMenu(commonData.journalMenuId) then
            menuHandler.registerMenu(commonData.journalMenuId, createQuestMenu{
                fontSize = config.data.ui.fontSize,
                sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
                relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
            })
        end
        menuHandler.getMenu(commonData.journalMenuId):selectQuest(userData.questName) ---@diagnostic disable-line: need-check-nil
    end
end


local function giverMarkerClick(userData)
    if not userData or (userData.type ~= "questGiver" and userData.type ~= "doorQuestGiver") then
        return
    end

    local objName = userData.objName or ""
    menuHandler.destroyMenu(objName)

    menuHandler.registerMenu(objName, createQuestMenu{
        fontSize = config.data.ui.fontSize,
        sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
        relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
        headerName = objName,
        questList = userData.diaIds,
        isQuestList = true,
        showReqsForAll = true,
        showOnlyFirst = true,
        hideStageText = true,
    })
end


I.DijectKeyBindings.action.register(commonData.toggleMarkersTriggerId, function()
    tracking.setMarkersVisibility{toggle = true, includeQuestGivers = true}
    if menuHandler.getMenu(commonData.journalMenuId) then
        menuHandler.getMenu(commonData.journalMenuId):updateMarkersDisabledMessage()
    end
end)


local function onKeyPress(key)
    if key.code == input.KEY.Escape then
        menuHandler.destroyAllMenus()
        return
    end

    if menuHandler.getMenu(commonData.trackingMenuId) then return end

    local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
    local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
    local activeMenu = topicMenu or journalMenu

    if not activeMenu then return end

    if key.code == input.KEY.UpArrow then
        if journalMenu and not topicMenu and journalMenu._focusPanel == "detail" then
            journalMenu:navigateDetailObjective(-1)
        else
            activeMenu:selectNextPreviousInList(-1)
        end
    elseif key.code == input.KEY.DownArrow then
        if journalMenu and not topicMenu and journalMenu._focusPanel == "detail" then
            journalMenu:navigateDetailObjective(1)
        else
            activeMenu:selectNextPreviousInList(1)
        end
    elseif key.code == input.KEY.LeftArrow and journalMenu and not topicMenu then
        journalMenu:resetDetailCursor()
        journalMenu:setFocusPanel("list")
    elseif key.code == input.KEY.RightArrow and journalMenu and not topicMenu then
        journalMenu:setFocusPanel("detail")
        journalMenu:initDetailCursor()
    elseif key.code == input.KEY.Enter and journalMenu and not topicMenu then
        if journalMenu._focusPanel == "detail" then
            journalMenu:toggleDetailObjective()
        else
            journalMenu:toggleTrackObjects()
        end
    end
end

local function onControllerButtonPress(button)
    if button == input.CONTROLLER_BUTTON.B then
        menuHandler.destroyAllMenus()
        return
    end

    if menuHandler.getMenu(commonData.trackingMenuId) then return end

    local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
    local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
    local activeMenu = topicMenu or journalMenu

    if not activeMenu then return end

    if button == input.CONTROLLER_BUTTON.LeftShoulder and journalMenu and not topicMenu then
        journalMenu:resetDetailCursor()
        journalMenu:setFocusPanel("list")
        return
    elseif button == input.CONTROLLER_BUTTON.RightShoulder and journalMenu and not topicMenu then
        journalMenu:setFocusPanel("detail")
        journalMenu:initDetailCursor()
        return
    end

    if button == input.CONTROLLER_BUTTON.DPadUp then
        if journalMenu and not topicMenu and journalMenu._focusPanel == "detail" then
            journalMenu:navigateDetailObjective(-1)
        else
            activeMenu:selectNextPreviousInList(-1)
        end
    elseif button == input.CONTROLLER_BUTTON.DPadDown then
        if journalMenu and not topicMenu and journalMenu._focusPanel == "detail" then
            journalMenu:navigateDetailObjective(1)
        else
            activeMenu:selectNextPreviousInList(1)
        end
    elseif button == input.CONTROLLER_BUTTON.A and journalMenu and not topicMenu then
        if journalMenu._focusPanel == "detail" then
            journalMenu:toggleDetailObjective()
        else
            journalMenu:toggleTrackObjects()
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


-- Input
do
    local nextQTimer
    local function nextQ()
        local hasTimer = nextQTimer ~= nil
        if nextQTimer then
            nextQTimer()
            nextQTimer = nil
        end
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if topicMenu then
            topicMenu:selectNextPreviousInList(1)
        else
            local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
            if mainMenu then
                mainMenu:setFocusPanel("detail")
                return
            end
        end

        if I.DijectKeyBindings.version >= 4 then
            nextQTimer = realTimer.newTimer(hasTimer and 0.15 or 0.75, function ()
                if I.DijectKeyBindings.action.isPressed(commonData.nextQuestTriggerId) then
                    nextQ()
                else
                    nextQTimer = nil
                end
            end)
        end
    end

    local prevQTimer
    local function prevQ()
        local hasTimer = prevQTimer ~= nil
        if prevQTimer then
            prevQTimer()
            prevQTimer = nil
        end
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if topicMenu then
            topicMenu:selectNextPreviousInList(-1)
        else
            local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
            if mainMenu then
                mainMenu:setFocusPanel("list")
                return
            end
        end

        if I.DijectKeyBindings.version >= 4 then
            prevQTimer = realTimer.newTimer(hasTimer and 0.15 or 0.75, function ()
                if I.DijectKeyBindings.action.isPressed(commonData.previousQuestTriggerId) then
                    prevQ()
                else
                    prevQTimer = nil
                end
            end)
        end
    end

    local function toggleTrackObjects()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if not mainMenu then return end

        if mainMenu._focusPanel == "detail" then
            mainMenu:toggleDetailObjective()
        else
            mainMenu:toggleTrackObjects()
        end
    end

    local function trackObjects()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if not mainMenu then return end

        mainMenu:trackObjects()
    end

    local function untrackObjects()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if not mainMenu then return end

        mainMenu:untrackObjects()
    end

    local function toggleTopTopics()
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if topicMenu then
            topicMenu:loadMoreEntries()
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if mainMenu then
            mainMenu:toggleTopTopics()
        end
    end

    menuHandler.onMenuModeActivated = function ()
        I.DijectKeyBindings.action.register(commonData.nextQuestTriggerId, nextQ)
        I.DijectKeyBindings.action.register(commonData.previousQuestTriggerId, prevQ)
        I.DijectKeyBindings.action.register(commonData.trackObjectsTriggerId, trackObjects)
        I.DijectKeyBindings.action.register(commonData.untrackObjectsTriggerId, untrackObjects)
        I.DijectKeyBindings.action.register(commonData.toggleTrackObjectsTriggerId, toggleTrackObjects)
        I.DijectKeyBindings.action.register(commonData.toggleTopTopicsTriggerId, toggleTopTopics)
        gamepadJournalScrollEnabled = config.data.input.gamepadJournalScroll
        pcall(function()
            if I.GamepadControls then
                I.GamepadControls.setGamepadCursorActive(true)
            end
        end)
    end

    menuHandler.onMenuModeDeactivated = function ()
        I.DijectKeyBindings.action.unregister(commonData.nextQuestTriggerId, nextQ)
        I.DijectKeyBindings.action.unregister(commonData.previousQuestTriggerId, prevQ)
        I.DijectKeyBindings.action.unregister(commonData.trackObjectsTriggerId, trackObjects)
        I.DijectKeyBindings.action.unregister(commonData.untrackObjectsTriggerId, untrackObjects)
        I.DijectKeyBindings.action.unregister(commonData.toggleTrackObjectsTriggerId, toggleTrackObjects)
        I.DijectKeyBindings.action.unregister(commonData.toggleTopTopicsTriggerId, toggleTopTopics)
        gamepadJournalScrollEnabled = false
        pcall(function()
            if I.GamepadControls then
                I.GamepadControls.setGamepadCursorActive(false)
            end
        end)
    end
end


local function updateQuestGivers()
    core.sendGlobalEvent("QGL:updateQuestGiverMarkers")
    advWMapIntegration.updateGiversMarker()
end


time.runRepeatedly(function()
    handleTracking()
end, 5 * time.second + math.random())

local onQuestUpdateTimerStarted = false

return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            timeLib.requestTimeUpdate()
            playerQuests.update(questId, stage)
            realTimer.newTimer(1, function ()
                advWMapIntegration.updateDoorMarkers()
            end)
            core.sendGlobalEvent("QGL:clearCache")

            if not tracking.initialized then return end
            if config.data.tracking.autoTrack then
                tracking.trackQuest(questId, stage)
            end
            if not onQuestUpdateTimerStarted then
                onQuestUpdateTimerStarted = true
                async:newUnsavableSimulationTimer(0.05, function()
                    handleTracking()
                    updateQuestGivers()
                    tracking.updateTemporaryMarkers()
                    onQuestUpdateTimerStarted = false
                end)
            end
        end,
        onTeleported = function ()
            async:newUnsavableSimulationTimer(0.1, function () -- delay for the player cell data to be updated
                updateQuestGivers()
                teleportedCallback()
            end)
        end,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
        onFrame = function(dt)
            realTimer.updateTimers()
            local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
            local gamepadCursorActive = I.GamepadControls and I.GamepadControls.isGamepadCursorActive()
            if journalMenu and journalMenu._focusPanel == "detail"
                    and not gamepadCursorActive
                    and not menuHandler.getMenu(commonData.trackingMenuId)
                    and not menuHandler.getMenu(commonData.topicsMenuId) then
                local leftY = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
                if math.abs(leftY) > 0.2 then
                    journalMenu:scrollInfo(leftY * dt * 10)
                    journalMenu:update()
                end
            end
        end,
        onMouseWheel = onMouseWheel,
        onMouseButtonRelease = onMouseButtonRelease,
    },
    eventHandlers = {
        UiModeChanged = function (e)
            timeLib.requestTimeUpdate()
            if e.oldMode == "Dialogue" then
                updateQuestGivers()
            end
        end,

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
            local createAdvWMapMarkers = config.data.tracking.advWMapMarkers.enabled and config.data.tracking.advWMapMarkers.details.givers

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

            if createAdvWMapMarkers and data.type == "door" then
                advWMapIntegration.createDoorGiversMarker(data.ref, data.questNames)
            end

            tracking.updateMarkers()

            core.sendGlobalEvent("QGL:questGiverMarkerCallback", {
                record = recordId,
                hudMarkerId = hudMarkerId,
                inputData = data,
                player = self.object,
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

        ["QGL:fillQuestBoxQuestInfo"] = fillQuestBoxQuestInfo,

        ["QGL:updateQuestMenu"] = function (data)
            local menu = menuHandler.getMenu(commonData.journalMenuId)
            if not menu then return end

            menu:updateNextStageBlocks()
            local selectedQuest = menu:getQuestListSelectedFladValue()
            menu:fillQuestsContent()
            if selectedQuest then
                menu:selectQuest(selectedQuest)
            end
            menu:update()
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

            markerClick(userData)
        end,

        ---@param data AdvWMap_tracking.onClickCallbackParams
        [commonData.advWMapMarkerCallback] = function (data)
            if data.button ~= 1 or not data.template.userData then return end

            markerClick(data.template.userData)
        end,

        ---@param data proximityTool.event.callbackParams
        ["QGL:questGiverMarkerCallback"] = function (data)
            if not data.recordData or not data.recordData.userData then
                return
            end

            giverMarkerClick(data.recordData.userData)
        end,

        ---@param data AdvWMap_tracking.onClickCallbackParams
        [commonData.advWMapGiverCallback] = function (data)
            if data.button ~= 1 or not data.object or not data.template.userData then return end

            local giverQuests = questLib.getGiverQuests(data.object)
            if not giverQuests then return end

            local recordId = data.object.recordId
            local record = data.object.type.record(recordId)

            local tb = tableLib.copy(data.template.userData)
            tb.diaIds = tableLib.keys(giverQuests)
            tb.objName = (record or {}).name or l10n("questGiverU")

            giverMarkerClick(tb)
        end,

        ["QGL:getPositionsForTrackingMenu"] = function (data)
            if not data.positions then return end

            if data.menuId then
                ---@type questGuider.ui.trackingMenuMeta
                local menu = menuHandler.getMenu(data.menuId)
                if not menu then return end

                menu.positions = data.positions

                if configLib.data.journal.mapByDefault then
                    menu:showMainMap()
                end
            elseif data.advWMapMode then
                advWMapIntegration.addPosDataToWidget(data.positions)
            end
        end,

        ["QGL:updateCityInfo"] = function (data)
            mapWidget.cityInfo = data
        end,

        ["QGL:showSimpleMap"] = function (data)
            menuHandler.destroyMenu(commonData.simpleMapMenuId)

            local menu = simpleMap.new{}

            if not menu then return end

            if data.positions then
                if not menu:mark(data.positions) then
                    menu:close()
                end
            end

            menuHandler.registerMenu(commonData.simpleMapMenuId, menu)
        end,

        ["QGL:removeAllTrackedMessageBox"] = function ()
            menuHandler.destroyMenu(commonData.messageBoxMenuId)

            menuHandler.registerMenu(commonData.messageBoxMenuId, messageBox.newSimple{
                message = l10n("removeTrackingFromListedMessageBox"),
                relativeSize = util.vector2(0.25, 0.2),
                yesCallback = function ()
                    local trackingMenuMeta = menuHandler.getMenu(commonData.trackingMenuId)
                    if not trackingMenuMeta then return end
                    trackingMenuMeta:removeListed()
                    trackingMenuMeta:fillTrackingListContent()
                    trackingMenuMeta:clearTrackingInfo()
                    trackingMenuMeta:resetListSelection()
                    trackingMenuMeta:update()
                end,
            })
        end,

        ["QGL:journalMenuSelectQuest"] = function (data)
            if not data or not data.qName then return end
            local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
            if not journalMenu then return end

            journalMenu:selectQuest(data.qName)
        end,

        ["QGL:journalMenuUpdateTrackedButtonVisibility"] = function ()
            local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
            if not journalMenu then return end

            if journalMenu:updateTrackedButtonVisibility() then
                journalMenu:update()
            end
        end,

        ["QGL:requestTimeUpdate"] = function (data)
            timeLib.setGlobalTime(data.day, data.month, data.year)
        end,
    },
}