local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local storage = require('openmw.storage')
local nearby = require("openmw.nearby")

local log = require("scripts.quest_guider_lite.utils.log")

local commonData = require("scripts.quest_guider_lite.common")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local cacheLib  = require("scripts.quest_guider_lite.utils.cache")

local config = require("scripts.quest_guider_lite.configLib")

local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local questLib = require("scripts.quest_guider_lite.questBase")
local configLib = require("scripts.quest_guider_lite.configLib")
local killCounter = require("scripts.quest_guider_lite.killCounter")
local dialogueTime = require("scripts.quest_guider_lite.dialogueTime")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local dateLib = require("scripts.quest_guider_lite.utils.date")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local keysModule = require("scripts.quest_guider_lite.input.keys")

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
    dialogueTime.init()
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
    dialogueTime.init()
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

    local journalMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
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

        if questBox.requestId ~= params.requestId then return end

        questBox.questInfo = params.data
        questBox:addTrackButtons()

        local objectPosData = {}
        local objectQuestDialogues = {}

        ---@type questGuider.ui.scrollBox
        local scrollBox = questBox:getScrollBox().userData.scrollBoxMeta

        local scrollBoxContent = scrollBox:getContent()

        for contentIndex, dt in pairs(params.data) do
            for objId, objDt in pairs(dt.objectPositions or {}) do
                objectPosData[objId] = objDt

                local objDiaDt = objectQuestDialogues[objId] or {}
                local diaDt = objDiaDt[dt.diaId] or {}
                diaDt[dt.diaIndex] = true
                objDiaDt[dt.diaId] = diaDt
                objectQuestDialogues[objId] = objDiaDt
            end

            if contentIndex >= 1000 then goto continue end

            local success, element = pcall(function() return scrollBoxContent[contentIndex] end)
            if not success or not element or not element.userData or not element.userData.detailsContent then goto continue end

            local isCurrentIndex = playerQuests.getCurrentIndex(dt.diaId, self) == dt.diaIndex
            local isValid = element.userData.isQuestList or isCurrentIndex

            if isValid and dt.next and next(dt.next) then
                element.userData.detailsContent:add(
                    nextStagesBlock.create{
                        data = dt,
                        size = scrollBox.innnerSize,
                        fontSize = config.data.ui.fontSize,
                        hideTrackButtons = false,
                        isQuestListMode = params.menuId ~= commonData.journalMenuId,
                        hideLinkedButtons = false,
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
                element.userData.detailsBtn.props.visible = true
            end

            ::continue::
        end

        if next(objectPosData) then
            questBox:addQuestObjectsLayout(objectPosData, objectQuestDialogues)
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


local function buildMainQuestMenu(nearbyMode)
    ---@type questGuider.ui.customJournal.params
    local params = {
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
    if nearbyMode then
        local dialogues = {}
        for qName, dt in pairs(playerQuests.questData) do
            for diaId, _ in pairs(dt.records) do
                table.insert(dialogues, diaId)
            end
        end

        params.headerName = l10n("nearby")
        params.menuId = commonData.allQuestsMenuId
        params.questList = dialogues
        params.isQuestList = true
        params.showReqsForAll = false
        params.showReqDiaEntryText = true
        params.allQuestsMode = true
        params.nearbyModeDefault = true
        params.allEntriesDefault = false
        params.hideStageText = true
        params.showOnlyMainDia = true
    end

    return createQuestMenu(params)
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
        showReqDiaEntryText = true,
        allQuestsMode = true,
        hideJournalBtn = true,
        nearbyModeDefault = false,
        allEntriesDefault = true,
    }
end


local function toggleMenu(withoutMenuMode)
    if menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId) then
        menuHandler.destroyMenu(commonData.journalMenuId)
        menuHandler.destroyMenu(commonData.allQuestsMenuId)
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
    menuHandler.destroyMenu(commonData.journalMenuId)
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


if config.data.journal.overrideJournal then
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
end


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

    local hasNonTrackedQuest = false
    for _, diaId in pairs(userData.diaIds or {}) do
        if not tracking.trackedObjectsByDiaId[diaId] then
            hasNonTrackedQuest = true
            break
        end
    end

    if hasNonTrackedQuest then
        menuHandler.registerMenu(commonData.allQuestsMenuId, createQuestMenu{
            fontSize = config.data.ui.fontSize,
            sizeProportional = util.vector2(config.data.journal.widthProportional * 0.01, config.data.journal.heightProportional * 0.01),
            relativePosition = util.vector2(config.data.journal.position.x * 0.01, config.data.journal.position.y * 0.01),
            menuId = commonData.allQuestsMenuId,
            headerName = objName,
            questList = userData.diaIds,
            isQuestList = true,
            showReqsForAll = true,
            showOnlyMainDia = true,
            hideStageText = true,
            showReqDiaEntryText = true,
            allQuestsMode = true,
            nearbyModeDefault = false,
            allEntriesDefault = false,
            hideJournalBtn = true,
        })
    end
end


I.DijectKeyBindings.action.register(commonData.toggleMarkersTriggerId, function()
    tracking.setMarkersVisibility{toggle = true, includeQuestGivers = true}
    if menuHandler.getMenu(commonData.journalMenuId) then
        menuHandler.getMenu(commonData.journalMenuId):updateMarkersDisabledMessage()
    end
end)


local function closeTopMenu()
    local closed = false
    if menuHandler.getMenu(commonData.trackingMenuId) then
        closed = true
        menuHandler.destroyMenu(commonData.trackingMenuId)
    end
    if menuHandler.getMenu(commonData.topicsMenuId) then
        closed = true
        menuHandler.destroyMenu(commonData.topicsMenuId)
    end

    if closed then
        if menuHandler.hasActiveMenus() then
            menuHandler.activateMenuMode()
        end

        return
    end
    menuHandler.destroyAllMenus()
end


local function onKeyPress(key)
    keysModule.isGamepad = false
    if key.code == input.KEY.Escape then
        closeTopMenu()
    end
end

local function onControllerButtonPress(button)
    keysModule.isGamepad = true
    if button == input.CONTROLLER_BUTTON.B then
        closeTopMenu()
    end
end


local function handleTracking()
    if not tracking.initialized then return end
    local updateMarkers = false
    updateMarkers = tracking.handleTrackedRequirements()

    if updateMarkers then
        tracking.updateMarkers()
    end
end


-- Input
do
    local function selectNextPrev(val)
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return false
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if topicMenu then
            topicMenu:selectNextPreviousInList(val)
        else
            local mainMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
            if mainMenu then
                mainMenu:selectNextPreviousInList(val)
            end
        end
        return true
    end

    local nextPrevTimer
    local keyHoldCount = 0
    local function nextPrev(val, trigger)
        if nextPrevTimer then
            nextPrevTimer()
            nextPrevTimer = nil
            keyHoldCount = 0
        end

        local res = selectNextPrev(val)
        if res and I.DijectKeyBindings.version >= 4 then
            local function timerFunc()
                keyHoldCount = keyHoldCount + 1

                if I.DijectKeyBindings.action.isPressed(trigger) then
                    if keyHoldCount > 10 then
                        selectNextPrev(val)
                    end
                else
                    nextPrevTimer = nil
                    keyHoldCount = 0
                    return
                end

                nextPrevTimer = realTimer.newTimer(0.05, timerFunc)
            end
            nextPrevTimer = realTimer.newTimer(0.05, timerFunc)
        end
    end


    local function prevQ()
        nextPrev(-1, commonData.previousQuestTriggerId)
    end

    local function nextQ()
        nextPrev(1, commonData.nextQuestTriggerId)
    end

    local function toggleTrackObjects()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleTrackObjects()
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

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
        if mainMenu then
            mainMenu:toggleTopTopics()
        end
    end

    local function toggleTopicMenuLocal()
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if topicMenu then
            menuHandler.destroyMenu(commonData.topicsMenuId)
            return
        end

        menuHandler.registerMenu(commonData.topicsMenuId, buildTopicMenu())
    end

    local function toggleNearbyMenuLocal()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local nearbyMenu = menuHandler.getMenu(commonData.allQuestsMenuId)
        if nearbyMenu then
            menuHandler.registerMenu(commonData.journalMenuId, buildMainQuestMenu())
            menuHandler.destroyMenu(commonData.allQuestsMenuId)
            return
        end

        local journalMenu = menuHandler.getMenu(commonData.journalMenuId)
        if journalMenu then
            menuHandler.registerMenu(commonData.allQuestsMenuId, buildMainQuestMenu(true))
            menuHandler.destroyMenu(commonData.journalMenuId)
            return
        end
    end

    local function toggleFinishedHiddenJournal()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) or
                menuHandler.getMenu(commonData.allQuestsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if not mainMenu then return end

        mainMenu:toggleTopCheckboxes()
    end

    local function toggleFinishedHiddenNearby()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) or
                menuHandler.getMenu(commonData.journalMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleTopCheckboxes()
    end

    local function toggleNearbyMode()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) or
                menuHandler.getMenu(commonData.journalMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleNearbyCheckbox()
    end

    local function toggleAllEntriesMode()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) or
                menuHandler.getMenu(commonData.journalMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleAllEntriesCheckbox()
    end

    local function toggleTrackingBtnInfo()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleQuestObjectsBtn()
    end

    local function toggleAlphabeticalMode()
        if menuHandler.getMenu(commonData.trackingMenuId) then
            return
        end

        local topicMenu = menuHandler.getMenu(commonData.topicsMenuId)
        if not topicMenu then return end

        topicMenu:toggleAlphabeticalCheckbox()
    end

    local function toggleQuestPinned()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId)
        if not mainMenu then return end

        mainMenu:toggleQuestPinnedCheckbox()
    end

    local function toggleQuestHidden()
        if menuHandler.getMenu(commonData.trackingMenuId) or menuHandler.getMenu(commonData.topicsMenuId) then
            return
        end

        local mainMenu = menuHandler.getMenu(commonData.journalMenuId) or menuHandler.getMenu(commonData.allQuestsMenuId)
        if not mainMenu then return end

        mainMenu:toggleQuestHiddenCheckbox()
    end

    menuHandler.onMenuModeActivated = function ()
        I.DijectKeyBindings.action.register(commonData.nextQuestTriggerId, nextQ)
        I.DijectKeyBindings.action.register(commonData.previousQuestTriggerId, prevQ)
        I.DijectKeyBindings.action.register(commonData.toggleTrackObjectsTriggerId, toggleTrackObjects)
        I.DijectKeyBindings.action.register(commonData.toggleTopTopicsTriggerId, toggleTopTopics)
        I.DijectKeyBindings.action.register(commonData.topicMenuLocalTriggerId, toggleTopicMenuLocal)
        I.DijectKeyBindings.action.register(commonData.nearbyMenuLocalTriggerId, toggleNearbyMenuLocal)
        I.DijectKeyBindings.action.register(commonData.toggleFinishedHiddenTriggerId, toggleFinishedHiddenJournal)
        I.DijectKeyBindings.action.register(commonData.toggleStartedHiddenTriggerId, toggleFinishedHiddenNearby)
        I.DijectKeyBindings.action.register(commonData.toggleQuestHiddenTriggerId, toggleQuestHidden)
        I.DijectKeyBindings.action.register(commonData.toggleQuestPinnedTriggerId, toggleQuestPinned)
        I.DijectKeyBindings.action.register(commonData.toggleNearbyTriggerId, toggleNearbyMode)
        I.DijectKeyBindings.action.register(commonData.toggleAllEntriesTriggerId, toggleAllEntriesMode)
        I.DijectKeyBindings.action.register(commonData.toggleTrackingTriggerId, toggleTrackingBtnInfo)
        I.DijectKeyBindings.action.register(commonData.toggleAlphabeticalTriggerId, toggleAlphabeticalMode)
        gamepadJournalScrollEnabled = config.data.input.gamepadJournalScroll
    end

    menuHandler.onMenuModeDeactivated = function ()
        I.DijectKeyBindings.action.unregister(commonData.nextQuestTriggerId, nextQ)
        I.DijectKeyBindings.action.unregister(commonData.previousQuestTriggerId, prevQ)
        I.DijectKeyBindings.action.unregister(commonData.toggleTrackObjectsTriggerId, toggleTrackObjects)
        I.DijectKeyBindings.action.unregister(commonData.toggleTopTopicsTriggerId, toggleTopTopics)
        I.DijectKeyBindings.action.unregister(commonData.topicMenuLocalTriggerId, toggleTopicMenuLocal)
        I.DijectKeyBindings.action.unregister(commonData.nearbyMenuLocalTriggerId, toggleNearbyMenuLocal)
        I.DijectKeyBindings.action.unregister(commonData.toggleFinishedHiddenTriggerId, toggleFinishedHiddenJournal)
        I.DijectKeyBindings.action.unregister(commonData.toggleStartedHiddenTriggerId, toggleFinishedHiddenNearby)
        I.DijectKeyBindings.action.unregister(commonData.toggleQuestHiddenTriggerId, toggleQuestHidden)
        I.DijectKeyBindings.action.unregister(commonData.toggleQuestPinnedTriggerId, toggleQuestPinned)
        I.DijectKeyBindings.action.unregister(commonData.toggleNearbyTriggerId, toggleNearbyMode)
        I.DijectKeyBindings.action.unregister(commonData.toggleAllEntriesTriggerId, toggleAllEntriesMode)
        I.DijectKeyBindings.action.unregister(commonData.toggleTrackingTriggerId, toggleTrackingBtnInfo)
        I.DijectKeyBindings.action.unregister(commonData.toggleAlphabeticalTriggerId, toggleAlphabeticalMode)
        gamepadJournalScrollEnabled = false
    end
end


local function updateQuestGivers()
    core.sendGlobalEvent("QGL:updateQuestGiverMarkers", {player = self.object})
    advWMapIntegration.updateGiversMarker()
end


time.runRepeatedly(function()
    tracking.handleTrackedRequirementsStep()
end, 0.75)

local onQuestUpdateTimerStarted = false
local dialogueMenuActor = nil

return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            timeLib.requestTimeUpdate()
            playerQuests.update(questId, stage)
            realTimer.newTimer(1, function ()
                advWMapIntegration.updateDoorMarkers()
            end)
            core.sendGlobalEvent("QGL:clearCache")
            cacheLib.clear()

            if not tracking.initialized then return end
            if config.data.tracking.autoTrack then
                local name = playerQuests.getQuestNameByDiaId(questId)
                if name and name ~= "" then
                    if playerQuests.isHidden(name) then
                        tracking.removeMarker{ questId = questId, removeLinked = true }
                    else
                        realTimer.newTimer(0.01, function ()
                            tracking.trackQuest(questId, stage)
                        end)
                    end
                end
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
        end,
        onMouseWheel = onMouseWheel,
        onMouseButtonRelease = onMouseButtonRelease,
    },
    eventHandlers = {
        UiModeChanged = function (e)
            timeLib.requestTimeUpdate()
            if e.oldMode == "Dialogue" then
                handleTracking()
                updateQuestGivers()

                if dialogueMenuActor then
                    dialogueMenuActor:sendEvent("QGL:checkFollowingPlayer", {player = self.object, requestUpdate = true})
                    dialogueMenuActor = nil
                end
            elseif e.newMode == "Dialogue" then
                dialogueMenuActor = e.arg
            elseif e.oldMode == "Container" or e.newMode == "Loading" or e.oldMode == "Interface" then
                handleTracking()
            end

            if e.oldMode == "Loading" then
                advWMapIntegration.removeInvalidDoorGiverMarkers()
            end
        end,

        DialogueResponse = function(e)
            if e.type ~= "topic" then return end
            dialogueTime.updateDialogue(e.recordId)
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
                if data.type == "object" then
                    data.recordData.description = {stringLib.getValueEnumString(
                        data.questNames,
                        config.data.journal.objectNames,
                        l10n("starts").." %s"), l10n("clickForInfo")
                    }
                    data.recordData.proximity = config.data.tracking.questGiverProximity * 69.99
                elseif data.type == "door" then
                    data.recordData.description = {stringLib.getValueEnumString(
                        data.questNames,
                        config.data.journal.objectNames,
                        l10n("doorGiverMessage")), l10n("clickForInfo")
                    }
                end

                recordId, markerId, markerGroupId = tracking.addTrackingMarker(data.recordData, data.markerData)
                if tracking.storageData.hideAllMarkers and recordId then
                    tracking.setProximityMarkerVisibility{recordId = recordId, value = false}
                end
            end

            local hudMarkerId
            if data.hudMarkerData and createHUDMarkers then
                data.hudMarkerData.params.raytracing = config.data.tracking.hudMarkers.rayTracing
                data.hudMarkerData.params.range = config.data.tracking.hudMarkers.range * 3.2808
                data.hudMarkerData.params.opacity = config.data.tracking.hudMarkers.opacity * 0.01
                data.hudMarkerData.params.color = commonData.colorToArray(config.data.ui.defaultColor)

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
            menu:updateQuestListTrackedColors()
            menu:update()
        end,

        ["QGL:registerActorDeath"] = function (data)
            killCounter.registerKill(data.object)
            if tracking.handleObjectRequirements(data.object.recordId) then
                handleTracking()
            end
        end,

        ["QGL:createMarkersForDoor"] = function (ref)
            tracking.createMarkersForExteriorDoor(ref)
        end,

        ["QGL:updateMapMarkerForQuestGivers"] = function (data)
            advWMapIntegration.createDoorGiversMarker(data.ref, data.questNames)
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
            if advWMapIntegration.markObjectTemp(data.objectId, data.positions) then
                return
            end

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

        ["QGL:followingPlayerChanged"] = function (data)
            local actorRecId = data.actor.recordId
            local obj = data.actor.type.record(actorRecId)
            local scriptId = obj and obj.mwscript

            local changed
            if data.isFollowing then
                changed = tracking.disableDoorMarkersForObject(actorRecId)
                if scriptId then
                    changed = tracking.disableDoorMarkersForObject(scriptId) or changed
                end
            else
                changed = tracking.enableDoorMarkersForObject(actorRecId)
                if scriptId then
                    changed = tracking.disableDoorMarkersForObject(scriptId) or changed
                end
            end

            if changed then
                tracking.updateTemporaryMarkers()
                tracking.updateMarkers()
            end

            if data.requestUpdate then
                for _, actor in pairs(nearby.actors) do
                    if actor.recordId ~= actorRecId then
                        actor:sendEvent("QGL:checkFollowingPlayer", {player = self.object})
                    end
                end
            end
        end,

        ["QGL:questsNearby"] = function (data)
            local menuId = data.menuId
            if not menuId then return end

            ---@type questGuider.ui.customJournal
            local menu = menuHandler.getMenu(data.menuId)
            if not menu then return end

            menu:loadQuestList(data.diaIds)
            local selectedQuest = menu:getQuestListSelectedFladValue()
            if selectedQuest then
                menu:selectQuest(selectedQuest)
            else
                menu:selectNextPreviousInList(1)
            end
            menu:update()
        end
    },
}