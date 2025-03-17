local log = include("diject.quest_guider.utils.log")

local questLib = include("diject.quest_guider.quest")
local trackingLib = include("diject.quest_guider.tracking")
local tooltipLib = include("diject.quest_guider.UI.tooltipSys")

local config = include("diject.quest_guider.config")

local playerQuests = include("diject.quest_guider.playerQuests")

local mapAddon = {
    buttonBlock = "qGuider_mapAddon_buttonBlock",
    showHideBtn = "qGuider_mapAddon_showHideBtn",
    removeAllBtn = "qGuider_mapAddon_removeAllBtn",
    scrollPane = "qGuider_mapAddon_scrollPane",
    trackingBlock = "qGuider_mapAddon_trackingBlock",
    questNameLabel = "qGuider_mapAddon_questNameLabel",
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
    local function createTrackingBlock(parent, questId, trackingData)
        local questData = questLib.getQuestData(questId)
        if not questData then return end

        local block = parent:createBlock{ id = mapAddon.trackingBlock }
        block.autoHeight = true
        block.widthProportional = 1
        block.flowDirection = tes3.flowDirection.topToBottom
        block.borderBottom = 16

        local qNameLabel = block:createLabel{ id = mapAddon.questNameLabel, text = questData.name or "???" }
        qNameLabel.widthProportional = 1
        qNameLabel.wrapText = true
        qNameLabel.borderLeft = 10

        qNameLabel:register(tes3.uiEvent.mouseClick, function (e)
            if tes3.worldController.inputController:isShiftDown() and trackingLib.mapMarkerLibVersion >= 3 then
                local _, randObjId = table.choice(trackingData.objects)
                if randObjId then
                    local randObjDisState = trackingLib.getDisabledState{ questId = questId, objectId = randObjId}
                    trackingLib.setDisableMarkerState{ value = not randObjDisState, questId = questId }
                end
                trackingLib.updateMarkers(true)
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
                        qNameLabel:getTopLevelMenu():updateLayout()
                    end
                end,
            }
        end)

        if config.data.main.helpLabels then
            local tooltip = tooltipLib.new{parent = qNameLabel}
            if config.data.main.helpLabels then
                local text = "Click to remove."
                if trackingLib.mapMarkerLibVersion >= 3 then
                    text = text.." Shift+Click to enable/disable."
                end
                tooltip:add{name = text}
            end
        end

        if config.data.map.showJournalTextTooltip then
            local qData = playerQuests.getQuestData(questId)
            if qData then
                local journalInfo = qData.record:getJournalInfo()
                if journalInfo then
                    local tooltip = tooltipLib.new{ parent = qNameLabel }
                    local text
                    if qData.text then
                        text = qData.text
                    else
                        qData.text = journalInfo.text
                        text = qData.text
                    end
                    tooltip:add{ name = questData.name, description = questLib.removeSpecialCharactersFromJournalText(text) }
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
            end

            local lastDisabledState = disabledState
            qDescrLabel:register(tes3.uiEvent.mouseOver, function (e)
                local color = {1, 1, 1}
                qDescrLabel.color = color

                trackingLib.changeObjectMarkerColor(objId, color, 100)
                if trackingLib.mapMarkerLibVersion >= 3 then
                    lastDisabledState = trackingLib.getDisabledState{ objectId = objId, questId = questId }
                    trackingLib.setDisableMarkerState{ value = false,  objectId = objId, questId = questId }
                end
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseLeave, function (e)
                qDescrLabel.color = markerColor
                trackingLib.changeObjectMarkerColor(objId, markerColor, 0)
                if trackingLib.mapMarkerLibVersion >= 3 then
                    trackingLib.setDisableMarkerState{ value = lastDisabledState,  objectId = objId, questId = questId }
                end
                trackingLib.updateMarkers(false)
                qDescrLabel:getTopLevelMenu():updateLayout()
            end)

            qDescrLabel:register(tes3.uiEvent.mouseClick, function (e)
                if tes3.worldController.inputController:isShiftDown() and trackingLib.mapMarkerLibVersion >= 3 then
                    trackingLib.setDisableMarkerState{ value = not lastDisabledState, objectId = objId, questId = questId }
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
        for questId, trackingData in pairs(trackingLib.trackedObjectsByQuestId) do
            createTrackingBlock(questPane, questId, trackingData)
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