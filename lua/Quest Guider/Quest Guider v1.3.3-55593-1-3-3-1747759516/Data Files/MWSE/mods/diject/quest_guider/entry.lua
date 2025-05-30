local dataHandler = include("diject.quest_guider.dataHandler")
local config = include("diject.quest_guider.config")
local questLib = include("diject.quest_guider.quest")
local log = include("diject.quest_guider.utils.log")
local storage = include("diject.quest_guider.storage.localStorage")
local tracking = include("diject.quest_guider.tracking")
local playerQuests = include("diject.quest_guider.playerQuests")
local tooltipUI = include("diject.quest_guider.UI.tooltips")
local journalUI = include("diject.quest_guider.UI.journal")
local mapUI = include("diject.quest_guider.UI.map")
local dataGeneratoUI = include("diject.quest_guider.UI.dataGenerator")
local quickInitMenu = include("diject.quest_guider.UI.quickInitMenu")
local mapInfo = include("diject.quest_guider.mapInfo")


--- @param e uiActivatedEventData
local function uiJournalActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.main.enabled or not config.data.journal.enabled then return end

    if e.newlyCreated then
        journalUI.addAllQuestsButton()
        journalUI.updateJournalMenu()
        e.element:updateLayout()

        e.element:registerBefore(tes3.uiEvent.update, function (ei)
            journalUI.updateJournalMenu()
        end)
    end
end

--- @param e uiActivatedEventData
local function uiMapActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.main.enabled or not config.data.map.enabled then return end

    if e.newlyCreated then
        mapUI.updateMapMenu()
    end
end

--- @param e journalEventData
local function journalCallback(e)
    if not dataHandler.isReady() or not config.data.main.enabled then return end

    local topic = e.topic
    if topic.type ~= tes3.dialogueType.journal then return end

    local questId = e.topic.id:lower()

    playerQuests.updateIndex(questId, e.index)
    if e.info and e.info.isQuestFinished then
        playerQuests.addFinished(e.topic)
    end

    if config.data.tracking.giver.enabled and e.new then
        tracking.updateQuestGiverMarkers()
    end

    if config.data.tracking.quest.enabled then
        tracking.trackQuestFromCallback(questId, e)
    end

    if tracking.handleTrackingRequirements() then
        tracking.updateMarkers(true)
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if not e.object and not e.reference then return end
    if not dataHandler.isReady() or not config.data.main.enabled then return end

    local shouldUpdate = false

    if e.reference and e.object.objectType == tes3.objectType.door then
        if config.data.tooltip.door.enabled then
            shouldUpdate = shouldUpdate or tooltipUI.drawDoorTooltip(e.tooltip, e.reference)
        end
    else
        if config.data.tooltip.object.enabled then
            shouldUpdate = shouldUpdate or tooltipUI.drawObjectTooltip(e.tooltip, e.reference and e.reference.baseObject.id or e.object.id)
        end
        if config.data.tooltip.object.changeTitleForTracked then
            tracking.changeObjectTooltipTitle(e.tooltip, e.reference and e.reference.baseObject.id or e.object.id)
        end
    end

    if shouldUpdate then
        e.tooltip:getTopLevelMenu():updateLayout()
    end
end

--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if not dataHandler.isReady() or not config.data.main.enabled then return end

    playerQuests.init()
    tracking.isInit()

    if config.data.tracking.quest.enabled then
        tracking.addMarkersForInteriorCell(e.cell)
    end

    if config.data.tracking.giver.enabled then
        tracking.createQuestGiverMarkers(e.cell)
    end
end

local cellBeforeLoad

--- @param e loadEventData
local function loadCallback(e)
    storage.reset()
    tracking.reset()
    playerQuests.reset()

    if tes3.player then
        cellBeforeLoad = tes3.player.cell.editorName
    else
        cellBeforeLoad = nil
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    if not storage.isPlayerStorageReady() then
        storage.initPlayerStorage()
    end
    tracking.isInit()
    playerQuests.init()

    if cellBeforeLoad then
        local cells
        if tes3.player.cell.isInterior then
            cells = {}
            table.insert(cells, {cell = tes3.player.cell})
        else
            cells = tes3.dataHandler.exteriorCells
        end
        for _, dt in pairs(cells) do
            cellActivatedCallback({cell = dt.cell}) ---@diagnostic disable-line: missing-fields
        end
    end
end

--- @param e itemTileUpdatedEventData
local function itemTileUpdatedCallback(e)
    if tracking.handlePlayerInventory() then
        tracking.updateMarkers(true)
    end
end

--- @param e deathEventData
local function deathCallback(e)
    if tracking.handleDeath(e.mobile.reference.baseObject.id) then
        tracking.updateMarkers(true)
    end
end

--- @param e enterFrameEventData
local function afterInitCallback(e)
    if config.data.main.enabled and not config.data.init.ignoreDataChanges and dataHandler.compareGameFileData() then
        local isDataEmpty = dataHandler.isGameFileDataEmpty()
        local isVersionChanged = dataHandler.isVersionChanged()
        dataGeneratoUI.createMenu{ dataChangedMessage = not isDataEmpty, dataNotExistsMessage = isDataEmpty,
            versionChangedMessage = isVersionChanged and not isDataEmpty }
    elseif config.firstInit then
        quickInitMenu.show()
    end
    event.unregister(tes3.event.enterFrame, afterInitCallback)
end

local function initIntegrations()
    if config.data.integration.questLogMenu.enabled and tes3.isLuaModActive("herbert100.quest log menu") then
        log("Found herbert's \"Quest Log Menu\"")
        include("diject.quest_guider.integration.questLogMenu").init()
    end
end

local function mapMarkerLib_tooltipPreRecordRegistered(e)
    if not e.record.userData or type(e.record.userData) ~= "table" then return end
    local rec = e.record
    local uData = rec.userData
    if not uData.action or type(uData.action) ~= "string" or
        uData.action ~= "jText" or type(rec.description) ~= "table" or
        not uData.questId or not uData.index then return end

    rec.description[2] = ""
    if tes3.worldController.inputController:isControlDown() then
        local journalText = playerQuests.getJournalText(uData.questId, uData.index)
        if journalText then
            rec.description[2] = questLib.removeSpecialCharactersFromJournalText(journalText)
        end
    elseif ((not tes3.worldController.inputController:isShiftDown() and config.data.tracking.showJournalTextOnMarker) or
            (tes3.worldController.inputController:isShiftDown() and not config.data.tracking.showJournalTextOnMarker)) then
        local plData = playerQuests.getQuestData(uData.questId)
        if plData.index > 0 then
            local journalText = playerQuests.getJournalText(plData, plData.index)
            if journalText then
                rec.description[2] = questLib.removeSpecialCharactersFromJournalText(journalText)
            end
        end
    end
end

--- @param e postInfoResponseEventData
local function postInfoResponseCallback(e)
    if tracking.handleTrackingRequirements() then
        tracking.updateMarkers(true)
    end
end

local function initCallbacks()
    event.register(tes3.event.load, loadCallback)
    event.register(tes3.event.loaded, loadedCallback)
    event.register(tes3.event.uiActivated, uiJournalActivatedCallback, {filter = "MenuJournal"})
    event.register(tes3.event.uiActivated, uiMapActivatedCallback, {filter = "MenuMap", priority = -278})
    event.register(tes3.event.journal, journalCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    event.register(tes3.event.cellActivated, cellActivatedCallback)
    event.register(tes3.event.enterFrame, afterInitCallback, {priority = -278})
    event.register(tes3.event.itemTileUpdated, itemTileUpdatedCallback)
    event.register(tes3.event.death, deathCallback)
    event.register(tes3.event.postInfoResponse, postInfoResponseCallback)
    event.register("mapMarkerLib:tooltipPreRecordRegistered", mapMarkerLib_tooltipPreRecordRegistered)
end

--- @param e initializedEventData
local function initializedCallback(e)
    mapInfo.init()
    dataHandler.init()
    journalUI.init()
    initCallbacks()
    initIntegrations()

    -- include("diject.quest_guider.testing.tests").descriptionLines()
end
event.register(tes3.event.initialized, initializedCallback, {priority = -278})

local this = {}

function this.initialize()
    initializedCallback() ---@diagnostic disable-line: missing-parameter
end

return this