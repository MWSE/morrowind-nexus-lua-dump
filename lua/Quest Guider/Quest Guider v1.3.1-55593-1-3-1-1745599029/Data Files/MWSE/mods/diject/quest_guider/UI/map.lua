local log = include("diject.quest_guider.utils.log")

local questLib = include("diject.quest_guider.quest")
local trackingLib = include("diject.quest_guider.tracking")
local tooltipLib = include("diject.quest_guider.UI.tooltipSys")
local stringLib = include("diject.quest_guider.utils.string")
local journalUI = include("diject.quest_guider.UI.journal")
local menuContainer = include("diject.quest_guider.UI.menuContainer")

local config = include("diject.quest_guider.config")

local playerQuests = include("diject.quest_guider.playerQuests")

local mapAddon = {
    buttonBlock = "qGuider_mapAddon_buttonBlock",
    showHideBtn = "qGuider_mapAddon_showHideBtn",
    removeAllBtn = "qGuider_mapAddon_removeAllBtn",
    scrollPane = "qGuider_mapAddon_scrollPane",
    trackingBlock = "qGuider_mapAddon_trackingBlock",
    questNameLabel = "qGuider_mapAddon_questNameLabel",
    questPartLabel = "qGuider_mapAddon_questPartLabel",
    questObjLabel = "qGuider_mapAddon_questObjLabel",
}

local this = {}

function this.updateMapMenu()
    if not trackingLib.isInit() then return end

    local menu = tes3ui.findMenu("MenuMap")
    if not menu then return end

    local menuWorld = menu:findChild("MenuMap_world")
    local menuLocal = menu:findChild("MenuMap_local")
    if not menuWorld or not menuLocal then return end

    local dragMenu = menu:findChild("PartDragMenu_main")
    if not dragMenu then return end

    local flowDirection = dragMenu.flowDirection

    local uiexpElement = dragMenu:findChild("UIEXP:MapControls")

    local btnBlock = dragMenu:createBlock{ id = mapAddon.buttonBlock }
    btnBlock.autoHeight = true
    btnBlock.autoWidth = true
    btnBlock.absolutePosAlignX = 0
    btnBlock.absolutePosAlignY = 0
    btnBlock.flowDirection = tes3.flowDirection.leftToRight

    local trackedBtn = btnBlock:createButton{ id = mapAddon.showHideBtn, text = ">" }

    local questPane = dragMenu:createVerticalScrollPane{ id = mapAddon.scrollPane }
    questPane.heightProportional = 1
    questPane.widthProportional = 0.75
    questPane.visible = false
    questPane.widget.scrollbarVisible = true

    if uiexpElement then
        questPane.heightProportional = nil
        questPane.height = dragMenu.height - uiexpElement.height - 2
        menu:registerAfter(tes3.uiEvent.preUpdate, function (e)
            questPane.height = math.max(0, dragMenu.height - uiexpElement.height - 5)
        end)
    end

    dragMenu:reorderChildren(dragMenu.children[1], questPane, -1)

    ---@param parent tes3uiElement
    ---@param questId string
    ---@param questData questDataGenerator.questData
    ---@param trackingData table<string, { objects: table<string, string[]> }>
    ---@param showHeader boolean
    local function createTrackingBlock(parent, questId, questData, trackingData, showHeader)
        local block = parent:createBlock{ id = mapAddon.trackingBlock }
        block.autoHeight = true
        block.widthProportional = 1
        block.flowDirection = tes3.flowDirection.topToBottom
        block.borderBottom = 6

        if showHeader then
            local bl = block:createBlock{ id = mapAddon.trackingBlock }
            bl.autoHeight = true
            bl.widthProportional = 1
            bl.childAlignX = 0.5

            local qBlockHeader = bl:createLabel{ id = mapAddon.questPartLabel, text = "<----->" }
            qBlockHeader.wrapText = true
            qBlockHeader.borderLeft = 0

            qBlockHeader:register(tes3.uiEvent.mouseClick, function (e)
                if tes3.worldController.inputController:isShiftDown() and trackingLib.mapMarkerLibVersion >= 3 then
                    local _, randObjId = table.choice(trackingData.objects)
                    if randObjId then
                        local randObjDisState = trackingLib.getDisabledState{ questId = questId, objectId = randObjId}
                        trackingLib.setDisableMarkerState{ value = not randObjDisState, questId = questId, isUserDisabled = true }
                    end
                    trackingLib.updateMarkers(true)
                    return
                elseif tes3.worldController.inputController:isControlDown() then
                    local function createContainerButtons(menuEl, buttonBlock)
                        journalUI.createContainerButtons(nil, menuEl, buttonBlock, {})
                    end

                    local el, buttonBlock = menuContainer.draw("Requirements", createContainerButtons)

                    if not el or not buttonBlock then return end

                    if not journalUI.drawRequirementMenu(el, questId, nil, questData) then
                        el:destroy()
                        return
                    end
                    menuContainer.centerToCursor(el)
                    return
                end
                tes3.messageBox{
                    message = "Remove markers for this quest?",
                    buttons = { "Yes", "No" },
                    showInDialog = false,
                    callback = function (e1)
                        if e1.button == 0 then
                            trackingLib.removeMarker{ questId = questId }
                            trackingLib.updateMarkers(true)
                            qBlockHeader:getTopLevelMenu():updateLayout()
                        end
                    end,
                }
            end)

            if config.data.map.showJournalTextTooltip then
                local qData = playerQuests.getQuestData(questId)
                if qData and qData.index > 0 then
                    local journalText = playerQuests.getJournalText(qData)
                    if journalText then
                        local tooltip = tooltipLib.new{ parent = qBlockHeader }
                        tooltip:add{ description = questLib.removeSpecialCharactersFromJournalText(journalText) }
                    end
                end
            end

            if config.data.main.helpLabels then
                local tooltip = tooltipLib.new{parent = qBlockHeader, maxWidth = 450}
                if config.data.main.helpLabels then
                    local text = "Click to remove."
                    if trackingLib.mapMarkerLibVersion >= 3 then
                        text = text.." Shift+Click to enable/disable."
                    end
                    text = text.." Ctrl+Click for info."
                    tooltip:add{name = text}
                end
            end
        end

        for objId, _ in pairs(trackingData.objects) do
            local object = tes3.getObject(objId)
            local objName = object and object.name or objId

            local objectMarkerData = trackingLib.markerByObjectId[objId]
            if not objectMarkerData then goto continue end

            local disabledState = false
            local markerRecordData = objectMarkerData.markers[questId] and objectMarkerData.markers[questId].data
            if markerRecordData then
                disabledState = markerRecordData.disabled or false
            end

            local markerColor = table.copy(disabledState and tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor) or objectMarkerData.color)

            local qDescrLabel = block:createLabel{ id = mapAddon.questObjLabel, text = objName }
            qDescrLabel.widthProportional = 1
            qDescrLabel.wrapText = true
            qDescrLabel.borderLeft = 20
            qDescrLabel.color = markerColor

            if config.data.main.helpLabels then
                local tooltip = tooltipLib.new{parent = qDescrLabel}
                if config.data.main.helpLabels then
                    local text = "Click to remove."
                    if trackingLib.mapMarkerLibVersion >= 3 then
                        text = text.." Shift+Click to enable/disable."
                    end
                    tooltip:add{name = text}
                end
                local objData = questLib.getObjectData(objId)
                if objData and objData.positions then
                    local positionDescrs = questLib.getObjectPositionDescription(objData, config.data.journal.objectNames)
                    table.shuffle(positionDescrs)
                    tooltip:add{name = "Location:", description = stringLib.getValueEnumString(positionDescrs, config.data.journal.objectNames)}
                end
            end

            local lastDisabledState = disabledState
            qDescrLabel:register(tes3.uiEvent.mouseOver, function (e)
                local color = {1, 1, 1}
                qDescrLabel.color = color

                trackingLib.changeObjectMarkerColor(objId, color, 100)
                if trackingLib.mapMarkerLibVersion >= 3 then
                    lastDisabledState = trackingLib.getDisabledState{ objectId = objId, questId = questId }
                    trackingLib.setDisableMarkerState{ value = false,  objectId = objId, questId = questId, temporary = true }
                end
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseLeave, function (e)
                qDescrLabel.color = markerColor
                trackingLib.changeObjectMarkerColor(objId, objectMarkerData.color, 0)
                if trackingLib.mapMarkerLibVersion >= 3 then
                    trackingLib.setDisableMarkerState{ value = lastDisabledState,  objectId = objId, questId = questId, temporary = true }
                end
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseClick, function (e)
                if tes3.worldController.inputController:isShiftDown() and trackingLib.mapMarkerLibVersion >= 3 then
                    trackingLib.setDisableMarkerState{ value = not lastDisabledState, objectId = objId, questId = questId, isUserDisabled = true }
                    trackingLib.updateMarkers(true)
                    return
                end

                tes3.messageBox{
                    message = "Remove the marker?",
                    buttons = { "Yes", "No" },
                    showInDialog = false,
                    callback = function (e1)
                        if e1.button == 0 then
                            trackingLib.removeMarker{ objectId = objId, questId = questId }
                            trackingLib.updateMarkers(true)
                            qDescrLabel:getTopLevelMenu():updateLayout()
                        end
                    end,
                }
            end)

            ::continue::
        end
    end

    local function fillQuestPane()
        questPane:getContentElement():destroyChildren()
        ---@type table<string, table<string, { trackingData: table<string, { objects: table<string, string[]> }>, qData : questDataGenerator.questData }>>
        local qDataByQName = {}
        for questId, trackingData in pairs(trackingLib.trackedObjectsByQuestId) do
            local qData = questLib.getQuestData(questId)
            if not qData then goto continue end

            local qName = qData.name or "???"
            qDataByQName[qName] = qDataByQName[qName] or {}
            qDataByQName[qName][questId] = {qData = qData, trackingData = trackingData}

            ::continue::
        end

        for qName, diaData in pairs(qDataByQName) do
            local block = questPane:createBlock{ id = mapAddon.trackingBlock }
            block.autoHeight = true
            block.widthProportional = 1
            block.flowDirection = tes3.flowDirection.topToBottom
            block.borderBottom = 8

            local qNameLabel = block:createLabel{ id = mapAddon.questNameLabel, text = qName }
            qNameLabel.widthProportional = 1
            qNameLabel.wrapText = true
            qNameLabel.borderBottom = 2

            local showHeader = table.size(diaData) > 1

            qNameLabel:register(tes3.uiEvent.mouseClick, function (e)
                if tes3.worldController.inputController:isShiftDown() and trackingLib.mapMarkerLibVersion >= 3 then
                    local trackingData
                    local randQId
                    for qId, qData in pairs(diaData) do
                        trackingData = qData.trackingData
                        randQId = qId
                        break
                    end
                    if not trackingData then return end
                    local _, randObjId = table.choice(trackingData.objects)
                    if randObjId then
                        local randObjDisState = trackingLib.getDisabledState{ questId = randQId, objectId = randObjId}
                        for qId, qData in pairs(diaData) do
                            trackingLib.setDisableMarkerState{ value = not randObjDisState, questId = qId, isUserDisabled = true }
                        end
                    end
                    trackingLib.updateMarkers(true)
                    return
                elseif not showHeader and tes3.worldController.inputController:isControlDown() then
                    local function createContainerButtons(menuEl, buttonBlock)
                        journalUI.createContainerButtons(nil, menuEl, buttonBlock, {})
                    end

                    local el, buttonBlock = menuContainer.draw("Requirements", createContainerButtons)

                    if not el or not buttonBlock then return end

                    local questData
                    local questId
                    for qId, qData in pairs(diaData) do
                        questId = qId
                        questData = qData.qData
                        break
                    end

                    if not questId or not questData or not journalUI.drawRequirementMenu(el, questId, nil, questData) then
                        el:destroy()
                        return
                    end
                    menuContainer.centerToCursor(el)
                    return
                end
                tes3.messageBox{
                    message = "Remove markers for this quest?",
                    buttons = { "Yes", "No" },
                    showInDialog = false,
                    callback = function (e1)
                        if e1.button == 0 then
                            for qId, qData in pairs(diaData) do
                                trackingLib.removeMarker{ questId = qId, removeLinked = true }
                            end
                            trackingLib.updateMarkers(true)
                            qNameLabel:getTopLevelMenu():updateLayout()
                        end
                    end,
                }
            end)

            if config.data.map.showJournalTextTooltip then
                local tooltip = tooltipLib.new{ parent = qNameLabel, maxWidth = 470 }
                tooltip:add{ name = qName }
                for qId, dt in pairs(diaData) do
                    local qData = playerQuests.getQuestData(qId)
                    if qData and qData.index > 0 then
                        local journalText = playerQuests.getJournalText(qData)
                        if journalText then
                            tooltip:add{ description = questLib.removeSpecialCharactersFromJournalText(journalText) }
                        end
                    end
                end
            end

            if config.data.main.helpLabels then
                local tooltip = tooltipLib.new{ parent = qNameLabel, maxWidth = 470 }
                if config.data.main.helpLabels then
                    local text = "Click to remove."
                    if trackingLib.mapMarkerLibVersion >= 3 then
                        text = text.." Shift+Click to enable/disable."
                    end
                    if not showHeader then
                        text = text.." Ctrl+Click for info."
                    end
                    text = text.." Hold Shift over a marker to show/hide its journal entry."
                    tooltip:add{name = text}
                end
            end

            for qId, qData in pairs(diaData) do
                createTrackingBlock(block, qId, qData.qData, qData.trackingData, showHeader)
            end
        end


        local removeAllBtn = questPane:createButton{ id = mapAddon.removeAllBtn, text = "Remove all" }
        removeAllBtn.absolutePosAlignX = 0.5
        removeAllBtn:register(tes3.uiEvent.mouseClick, function (e)
            trackingLib.removeMarkers()
            trackingLib.updateMarkers(true)
        end)

        local emptyBlock = questPane:createBlock{}
        emptyBlock.height = 40
        emptyBlock.width = 1

        menu:updateLayout()
        questPane.widget:contentsChanged()
    end

    trackedBtn:register(tes3.uiEvent.mouseClick, function (e)
        questPane.visible = not questPane.visible
        trackedBtn.text = questPane.visible and "<" or ">"
        btnBlock.absolutePosAlignX = questPane.visible and 0.395 or 0

        if questPane.visible then
            menuLocal.widthProportional = 2 - questPane.widthProportional
            menuWorld.widthProportional = 2 - questPane.widthProportional
            dragMenu.flowDirection = tes3.flowDirection.leftToRight
        else
            menuLocal.widthProportional = 1
            menuWorld.widthProportional = 1
            dragMenu.flowDirection = flowDirection
        end

        menu:updateLayout()
        questPane.widget:contentsChanged()
    end)

    trackingLib.callbackToUpdateMapMenu = fillQuestPane

    fillQuestPane()
end

return this