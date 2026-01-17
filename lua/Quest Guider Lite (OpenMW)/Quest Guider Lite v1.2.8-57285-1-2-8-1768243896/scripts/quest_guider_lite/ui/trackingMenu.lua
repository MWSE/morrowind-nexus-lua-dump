local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local templates = require('openmw.interfaces').MWUI.templates
local customTemplates = require("scripts.quest_guider_lite.ui.templates")

local playerRef = require("openmw.self")

local config = require("scripts.quest_guider_lite.configLib")
local commonData = require("scripts.quest_guider_lite.common")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")

local stringLib = require("scripts.quest_guider_lite.utils.string")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local log = require("scripts.quest_guider_lite.utils.log")

local getObject = require("scripts.quest_guider_lite.core.getObject")

local button = require("scripts.quest_guider_lite.ui.button")
local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local checkBox = require("scripts.quest_guider_lite.ui.checkBox")
local mapWidget = require("scripts.quest_guider_lite.ui.mapWidget")

local questBox = require("scripts.quest_guider_lite.ui.customJournal.questBox")

local l10n = core.l10n(commonData.l10nKey)


---@class questGuider.ui.trackingMenuMeta
local topicMenuMeta = {}
topicMenuMeta.__index = topicMenuMeta

topicMenuMeta.menu = nil


topicMenuMeta.getTrackingList = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[3]
end

topicMenuMeta.getSearchBar = function (self)
    return self.menu.layout.content[2].content[1].content[1].content[1]
end

topicMenuMeta.getMain = function (self)
    return self.menu.layout.content[2].content[1]
end

topicMenuMeta.getTrackingInfoScrollBox = function (self)
    return self:getMain().content[2]
end

topicMenuMeta.resetListColors = function (self)
    local topicList = self:getTrackingList()

    ---@type questGuider.ui.scrollBox
    local topicBoxMeta = topicList.userData.scrollBoxMeta
    local layout = topicBoxMeta:getMainFlex()

    for _, elem in ipairs(layout.content) do
        elem.content[1].props.textShadow = false
    end
end

topicMenuMeta.setTextFilter = function (self, value)
    local searchBar = self:getSearchBar()
    self.textFilter = value or ""
    searchBar.content[1].content[1].props.text = self.textFilter
end

topicMenuMeta.setListSelectedFlad = function (self, value)
    self:getTrackingList().userData.selected = value
end

topicMenuMeta.getQuestListSelectedFladValue = function (self)
    return self:getTrackingList().userData.selected
end

topicMenuMeta.resetListSelection = function (self)
    self:resetListColors()
    self:setListSelectedFlad(nil)
end

topicMenuMeta.updateListElements = function (self)
    local list = self:getTrackingList()
    if not list then return end

    ---@type questGuider.ui.scrollBox
    local listSBMeta = list.userData.scrollBoxMeta

    for _, elem in pairs(listSBMeta:getMainFlex().content) do
        if not elem.userData or not elem.userData.trackingData or not elem.userData.objectId then goto continue end

        ---@type questGuider.tracking.objectRecord
        local trackingData = elem.userData.trackingData
        local objId = elem.userData.objectId
        local qName = elem.userData.qName

        local trackedState
        if qName then
            local state = false
            local qData = playerQuests.getQuestDataByName(qName)
            if qData then
                for diaId, _ in pairs(qData.records) do
                    state = state or tracking.isObjectTracked{diaId = diaId, objectId = objId}
                end
            end

            trackedState = state
        else
            trackedState = tracking.isObjectTracked{objectId = objId}
        end

        local disabledState = false
        if trackedState then
            if qName then
                local state = true
                local qData = playerQuests.getQuestDataByName(qName)

                if qData then
                    for diaId, _ in pairs(qData.records) do
                        if tracking.isObjectTracked{objectId = objId, diaId = diaId} then
                            state = state and tracking.getDisabledState{objectId = objId, questId = diaId}
                        end
                    end
                end

                disabledState = state
            else
                disabledState = tracking.getDisabledState{objectId = objId}
            end
        end

        local textElem = elem.content[1]
        if not trackedState or not trackingData then
            textElem.props.textColor = config.data.ui.defaultColor
        elseif not disabledState then
            textElem.props.textColor = trackingData.color and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                or config.data.ui.defaultColor
            textElem.props.alpha = 1
        elseif disabledState then
            textElem.props.alpha = 0.4
        end

        ::continue::
    end
end

topicMenuMeta.clearTrackingInfo = function (self)
    local sb = self:getTrackingInfoScrollBox()
    sb.content = ui.content{}
    sb.userData = {}
end


---@param positionData questGuider.quest.getRequirementPositionData.positionData[]
topicMenuMeta.drawPositionInfo = function (self, positionData)
    local sb = self:getTrackingInfoScrollBox()

    if sb and sb.userData and sb.userData.drawPositionInfo then
        sb.userData.drawPositionInfo(positionData)
        self:update()
    end
end


topicMenuMeta.showMainMap = function (self)
    self:resetListSelection()
    self:clearTrackingInfo()

    local mainFlex = self:getMain()
    local content = ui.content{}
    mainFlex.content[2].content = content

    content:add{
        type = ui.TYPE.Widget,
        props = {
            size = self.trackingInfoPanelSize,
        },
        content = ui.content {

        }
    }

    local mapElement, mapMeta = mapWidget.new{
        updateFunc = function ()
            self:update()
        end,
        fontSize = self.params.fontSize,
        size = self.trackingInfoPanelSize,
    }

    if not mapMeta or not self.positions then return false end

    mapMeta:setZoom(0)

    local posData = {}

    for id, positions in pairs(self.positions) do
        posData[id] = {}
        local objDt = posData[id]
        for _, posDt in pairs(positions) do
            if posDt.exitPos and posDt.isExitEx or (not posDt.id and posDt.position) then
                local pos = posDt.exitPos or posDt.position

                local hash = string.format("%d_%d_%d", pos.x, pos.y, pos.z) ---@diagnostic disable-line: need-check-nil

                if not objDt[hash] then
                    objDt[hash] = {pos, stringLib.getPathToPosition(posDt), id}
                end
            end
        end
    end

    local screenSize = uiUtils.getScaledScreenSize()

    for id, objPoss in pairs(posData) do
        if tableLib.count(objPoss) > config.data.tracking.maxPos then goto continue end

        local trackingData = tracking.getTrackedObjectData(id)
        if not trackingData then goto continue end

        local object = getObject(id)

        local objectColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
            or commonData.defaultColor

        local diaIds = tableLib.keys(trackingData.markers)
        local qNames = ""
        for _, diaId in pairs(diaIds) do
            qNames = qNames..(playerQuests.getQuestNameByDiaId(diaId) or diaId)..", "
        end
        qNames = qNames:sub(1, -3)

        for _, posDt in pairs(objPoss) do
            local positionElem
            if posDt[2] then
                local text = string.format("%s\n\n%s\n%s", qNames, object and object.name or id, posDt[2])
                local height = uiUtils.getTextHeight(text, self.params.fontSize, screenSize.x / 3, config.data.journal.textHeightMulRecord)
                positionElem = {
                    type = ui.TYPE.Text,
                    props = {
                        text = text,
                        textColor = config.data.ui.defaultColor,
                        autoSize = false,
                        textSize = self.params.fontSize,
                        size = util.vector2(screenSize.x / 3, height),
                        multiline = true,
                        wordWrap = true,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                }
            end

            local events = {
                mouseRelease = async:callback(function(e, layout)
                    if layout.userData and layout.userData.pressed then
                        local _, diaId = next(diaIds)
                        if diaId then
                            local qName = playerQuests.getQuestNameByDiaId(diaId)
                            if qName then
                                playerRef:sendEvent("QGL:journalMenuSelectQuest", {qName = qName})
                            end
                        end
                    end
                end),
            }

            local markerLayout = mapMeta:createMarker(posDt[1], objectColor, events, positionElem and ui.content{
                positionElem
            })
            markerLayout.props.alpha = tracking.getDisabledState{objectId = posDt[3]} and 0.2 or 1
        end

        ::continue::
    end

    content[1].content:add(mapElement)
    self:update()
    return true
end


---@param trackedId string
topicMenuMeta.selectTracked = function (self, trackedId)
    local params = self.params

    ---@type questGuider.tracking.objectRecord
    local trackingData = trackedId and tracking.getTrackedObjectData(trackedId)
    if trackingData == nil then
        self:resetListSelection()
        self:clearTrackingInfo()
        return
    end

    local object = getObject(trackedId)
    local objectName = object and object.name or trackedId
    local objectColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])

    ---@type questGuider.ui.scrollBox
    local topicListSBMeta = self:getTrackingList().userData.scrollBoxMeta
    local qListLayout = topicListSBMeta:getMainFlex()

    local qMainLay = self:getMain()

    local succ, selectedLayout = pcall(function() return qListLayout.content[trackedId] end)
    if not succ or not selectedLayout then
        self:clearTrackingInfo()
        self:setListSelectedFlad(nil)
        return
    end

    if (selectedLayout.userData.heightInList or 0) < topicListSBMeta:getScrollPosition()
            or (selectedLayout.userData.heightInList or 0) > (topicListSBMeta:getScrollPosition() + topicListSBMeta:getSize().y) then
        topicListSBMeta:setScrollPosition((selectedLayout.userData.heightInList or 0) - topicListSBMeta:getSize().y / 2)
    end

    local function applyTextShadow()
        selectedLayout.content[1].props.textShadow = true
        selectedLayout.content[1].props.textShadowColor = config.data.ui.shadowColor
    end

    if self:getTrackingInfoScrollBox() and self:getTrackingInfoScrollBox().name == trackedId then
        applyTextShadow()
        return
    end

    local objectData = playerDataHandler.data.questObjects[trackedId]

    local elementContent = ui.content{
        interval(0, params.fontSize),
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
            },
            content = ui.content{

            },
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
            },
            content = ui.content{

            },
        }
    }


    local function updateContent(elemContent)
        ---@type questGuider.ui.scrollBox
        local topicSBMeta = self:getTrackingInfoScrollBox().userData.scrollBoxMeta

        if not elemContent then
            elemContent = topicSBMeta:getMainFlex().content
            if not elemContent then return end
        end

        local sbSize = topicSBMeta:getSize()

        local headerElem = elemContent[1]
        if not headerElem then return end
        elemContent[2].content = ui.content{}
        local mainElemFlexContent = elemContent[2].content

        local diaIds = tableLib.keys(trackingData.markers)

        table.sort(diaIds, function (a, b)
            return (playerQuests.getQuestNameByDiaId(a) or "") < (playerQuests.getQuestNameByDiaId(b) or "")
        end)

        for _, diaId in pairs(diaIds) do
            local qName = playerQuests.getQuestNameByDiaId(diaId)

            local diaData = trackingData.markers[diaId]

            if not diaData then goto continue end

            local diaIndex = diaData.index


            mainElemFlexContent:add({
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                },
                content = ui.content{
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = uiUtils.colorize(qName, self.textFilter,
                                "#"..config.data.ui.selectionColor:asHex(), "#"..config.data.ui.defaultColor:asHex()),
                            autoSize = true,
                            textSize = params.fontSize * 1.2,
                            multiline = false,
                            wordWrap = false,
                            textColor = config.data.ui.defaultColor,
                        },
                    },
                    interval(params.fontSize, 0),
                    button{
                        updateFunc = function ()
                            self:update()
                        end,
                        text = l10n("showQuestByTrackingMenuBtn"),
                        event = function (layout)
                            playerRef:sendEvent("QGL:journalMenuSelectQuest", {qName = qName})
                        end
                    }
                }
            })
            mainElemFlexContent:add(interval(0, params.fontSize))

            local objId = trackedId
            local objName = objectName

            local objInfoContent
            objInfoContent = {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = util.vector2(sbSize.x, params.fontSize * 1.5),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(0, 0.5),
                            position = util.vector2(0, params.fontSize * 0.75),
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = uiUtils.colorize(objName, self.textFilter,
                                        "#"..config.data.ui.selectionColor:asHex(), "#"..objectColor:asHex()),
                                    autoSize = true,
                                    textSize = (self.params.fontSize or 18) * 1.2,
                                    multiline = false,
                                    wordWrap = false,
                                    anchor = util.vector2(0, 0.5),
                                    textColor = tracking.getDisabledState{objectId = objId, questId = diaId} and config.data.ui.disabledColor or objectColor,
                                },
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            button{
                                updateFunc = function ()
                                    self:update()
                                end,
                                text = tracking.isObjectTracked{diaId = diaId, objectId = objId} and l10n("untrack") or l10n("track"),
                                textSize = params.fontSize * 0.8,
                                visible = tracking.initialized,
                                anchor = util.vector2(0, 0.5),
                                parentScrollBoxUserData = self:getTrackingInfoScrollBox().userData,
                                event = function (layout)
                                    local trackedState = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                                    if trackedState then
                                        tracking.removeMarker{objectId = objId, questId = diaId}
                                        playerRef:sendEvent("QGL:updateQuestMenu", {})
                                        tracking.updateMarkers()
                                    else
                                        tracking.trackObject{diaId = diaId, objectId = objId, index = diaIndex}
                                    end
                                    async:newUnsavableSimulationTimer(0.1, function ()
                                        tracking.updateTemporaryMarkers()
                                    end)

                                    ---@type questGuider.ui.buttonMeta
                                    local btnMeta = layout.userData.meta
                                    local btn = btnMeta:getButtonTextElement()
                                    if btn then
                                        btn.props.text = not trackedState and l10n("untrack") or l10n("track")
                                        if I.proximityTool then
                                            I.proximityTool.newRealTimer(0.25, function ()
                                                pcall(function ()
                                                    local showHideBtn = objInfoContent.content[1].content[5]
                                                    ---@type questGuider.ui.buttonMeta
                                                    local showHideBtnMeta = showHideBtn.userData.meta
                                                    local btn = showHideBtnMeta:getButtonTextElement()
                                                    ---@diagnostic disable-next-line: need-check-nil
                                                    btn.props.text = tracking.getDisabledState{objectId = objId, questId = diaId} and l10n("show") or l10n("hide")
                                                    ---@diagnostic disable-next-line: need-check-nil
                                                    showHideBtn.props.visible = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                                                    self:updateListElements()
                                                    self:update()
                                                end)
                                            end)
                                        end
                                    end
                                    self:updateListElements()
                                end
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            button{
                                updateFunc = function ()
                                    self:update()
                                end,
                                text = tracking.getDisabledState{objectId = objId, questId = diaId} and l10n("show") or l10n("hide"),
                                textSize = params.fontSize * 0.8,
                                visible = tracking.initialized and tracking.isObjectTracked{diaId = diaId, objectId = objId},
                                anchor = util.vector2(0, 0.5),
                                parentScrollBoxUserData = self:getTrackingInfoScrollBox().userData,
                                event = function (layout)
                                    local disabledState = tracking.getDisabledState{objectId = objId, questId = diaId}
                                    disabledState = not disabledState

                                    tracking.setDisableMarkerState{
                                        objectId = objId,
                                        questId = diaId,
                                        value = disabledState,
                                        isUserDisabled = true,
                                    }
                                    tracking.updateTemporaryMarkers()
                                    tracking.updateMarkers()

                                    ---@type questGuider.ui.buttonMeta
                                    local btnMeta = layout.userData.meta
                                    local btn = btnMeta:getButtonTextElement()
                                    if btn then
                                        btn.props.text = disabledState and l10n("show") or l10n("hide")
                                    end

                                    self:updateListElements()
                                end
                            },
                        }
                    },
                }
            }

            mainElemFlexContent:add(objInfoContent)

            mainElemFlexContent:add(interval(0, params.fontSize))

            ::continue::
        end

        topicSBMeta:setContentHeight(uiUtils.getContentHeight(elementContent))
    end


    ---@param positions questGuider.quest.getRequirementPositionData.positionData[]
    local function drawPositionInfo(positions)
        local sb = self:getTrackingInfoScrollBox()
        if not sb then return end

        ---@type questGuider.ui.scrollBox
        local topicSBMeta = sb.userData.scrollBoxMeta
        local flexElement = topicSBMeta:getMainFlex().content[3]
        if not flexElement then return end

        local content = ui.content{}
        flexElement.content = content

        if not positions or not next(positions) then return end

        local sbSize = topicSBMeta:getSize()
        local mapSize = util.vector2(sbSize.x * 0.7, sbSize.y * 0.8)

        local mapElement, mapMeta = mapWidget.new{
            updateFunc = function ()
                self:update()
            end,
            fontSize = params.fontSize,
            size = mapSize,
            anchor = util.vector2(0.5, 0),
            position = util.vector2(sbSize.x * 0.5, params.fontSize * 2),
        }

        local text = ""
        local count = 0
        local exits = {}
        local doFocus = true
        for _, posDt in ipairs(positions) do

            local descr = stringLib.getPathToPosition(posDt)
            if config.data.journal.maxPosDescrInTracking > count then
                if descr then
                    text = text..descr.."\n\n"
                end
            end
            count = count + 1

            if (posDt.exitPos and posDt.isExitEx) or (not posDt.id and posDt.position) then
                local pos = posDt.exitPos or posDt.position
                exits[string.format("%d_%d_%d", pos.x, pos.y, pos.z)] = {pos, descr} ---@diagnostic disable-line: need-check-nil
                if doFocus and mapMeta then
                    mapMeta:focusOnWorldPosition(pos)
                    doFocus = false
                end
            end

        end

        local screenSize = uiUtils.getScaledScreenSize()

        if mapMeta then
            local valid = false
            for hashId, dt in pairs(exits) do

                local positionElem
                if dt[2] then
                    local height = uiUtils.getTextHeight(dt[2], params.fontSize, screenSize.x / 3, config.data.journal.textHeightMulRecord)
                    positionElem = {
                        type = ui.TYPE.Text,
                        props = {
                            text = dt[2],
                            textColor = config.data.ui.defaultColor,
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(screenSize.x / 3, height),
                            multiline = true,
                            wordWrap = true,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                    }
                end

                mapMeta:createMarker(dt[1], objectColor, nil, positionElem and ui.content{
                    positionElem
                })
                valid = true
            end

            if not valid then
                mapElement = nil
            end
        end

        if count > config.data.journal.maxPosDescrInTracking then
            text = text..l10n("ellipsis").."\n\n"
        end

        local posTextShift = params.fontSize / 3
        local posHeight = uiUtils.getTextHeight(text, params.fontSize, sbSize.x - posTextShift, config.data.journal.textHeightMulRecord)
        local positionElem = {
            type = ui.TYPE.Text,
            props = {
                text = text,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                textSize = params.fontSize,
                size = util.vector2(sbSize.x, posHeight),
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }

        content:add(positionElem)

        if mapElement then
            mapElement.props.visible = false

            content:add{
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(sbSize.x, mapSize.y + params.fontSize * 2),
                },
                content = ui.content {
                    button{
                        updateFunc = function ()
                            self:update()
                        end,
                        text = l10n("map"),
                        textSize = params.fontSize,
                        position = util.vector2(sbSize.x / 2, 0),
                        anchor = util.vector2(0.5, 0),
                        event = function (layout)
                            mapElement.props.visible = not mapElement.props.visible
                        end
                    },
                    mapElement,
                }
            }
        end

        topicSBMeta:setContentHeight(uiUtils.getContentHeight(elementContent))
    end


    qMainLay.content[2] = scrollBox{
        updateFunc = function ()
            self.menu:update()
        end,
        size = self.trackingInfoPanelSize,
        scrollAmount = self.params.size.y / 5,
        userData = {
            updateText = updateContent,
            drawPositionInfo = drawPositionInfo,
        },
        content = elementContent,
        contentHeight = 0,
        leftOffset = params.fontSize / 3,
    }

    updateContent(elementContent)

    drawPositionInfo(self.positions and self.positions[trackedId])

    qMainLay.content[2].userData.scrollBoxMeta:setContentHeight(uiUtils.getContentHeight(elementContent))

    self:resetListSelection()
    self:setListSelectedFlad(trackedId)
    applyTextShadow()

    self:update()
end


topicMenuMeta.update = function(self)
    self.menu:update()
end


function topicMenuMeta.fillTrackingListContent(self)
    local params = self.params

    local qList = self:getTrackingList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta
    sBoxMeta:clearContent()

    local content = sBoxMeta:getMainFlex().content

    ---@type table<string, table<string, {list :string[], diaId : string}>>
    local trackingObjectsByQId = {}
    ---@type table<string, {list :string[], diaId : string}>
    local trackingObjects = {}
    for diaId, dt in pairs(tracking.trackedObjectsByDiaId) do
        local qName = playerQuests.getQuestNameByDiaId(diaId)
        if not qName or qName == "" then qName = l10n("miscellaneous") end

        if not trackingObjectsByQId[qName] then trackingObjectsByQId[qName] = {} end
        for objId, list in pairs(dt.objects) do
            trackingObjectsByQId[qName][objId] = {list, diaId = diaId}
            trackingObjects[objId] = {list = list, diaId = diaId}
        end
    end

    ---@type {name : string, id : string?, objects : string[]?, qName : string?, diaId : string?}[]
    local recordList = {}
    if localStorage.data.trackingListCheckBox then
        for objId, listData in pairs(trackingObjects) do
            local record = getObject(objId)
            local objName = record and record.name or objId or "???"
            table.insert(recordList, {name = objName, id = objId, objects = listData.list, diaId = listData.diaId})
        end

        table.sort(recordList, function (a, b)
            return (stringLib.utf8_lower(a.name or "") < stringLib.utf8_lower(b.name or ""))
        end)
    else
        local qNames = tableLib.keys(trackingObjectsByQId)
        table.sort(qNames, function (a, b)
            return (stringLib.utf8_lower(a) < stringLib.utf8_lower(b))
        end)

        for _, qName in ipairs(qNames) do
            local valid = self.textFilter == ""
            if not valid then
                valid = stringLib.utf8_lower(qName):find(self.textFilter, 1, true)
            end

            local objects = {}
            for objId, listData in pairs(trackingObjectsByQId[qName]) do
                local record = getObject(objId)
                local objName = record and record.name or ""

                if valid or self.textFilter == "" or stringLib.utf8_lower(objName):find(self.textFilter, 1, true) then
                    table.insert(objects, {name = objName, id = objId, objects = listData.list, qName = qName, diaId = listData.diaId})
                    valid = true
                end
            end

            if not valid then goto continue end

            table.sort(objects, function (a, b)
                return (stringLib.utf8_lower(a.name or "") < stringLib.utf8_lower(b.name or ""))
            end)

            table.insert(recordList, {name = qName})
            for _, dt in ipairs(objects) do
                table.insert(recordList, dt)
            end
            table.insert(recordList, {name = ""})

            ::continue::
        end
    end


    local heightInList = 0
    for _, dt in pairs(recordList) do

        local trackingListSB = self:getTrackingList()
        ---@type questGuider.ui.scrollBox
        local topicListSBMeta = trackingListSB.userData.scrollBoxMeta

        local trackingData = dt.id and tracking.getTrackedObjectData(dt.id)

        local textColor = trackingData and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
            or config.data.ui.defaultColor

        local text = dt.name == "" and dt.id and string.format("(%s)", dt.id) or dt.name or "???"
        text = trackingData and "\t\t"..text or text

        local contentData
        contentData = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
                propagateEvents = false,
                alpha = tracking.getDisabledState{objectId = dt.id} and 0.4 or 1
            },
            name = dt.id,
            userData = {
                trackingData = trackingData,
                objectId = dt.id,
                diaId = dt.diaId,
                qName = dt.qName,
                heightInList = heightInList,
            },
            events = {
                mousePress = async:callback(function(e, layout)
                    topicListSBMeta:mousePress(e)
                end),

                focusLoss = async:callback(function(e, layout)
                    topicListSBMeta:focusLoss(e)
                end),

                mouseMove = async:callback(function(e, layout)
                    topicListSBMeta:mouseMove(e)
                end),

                mouseRelease = async:callback(function(e, layout)
                    if e.button ~= 1 then return end

                    topicListSBMeta:mouseRelease(e)

                    if topicListSBMeta.lastMovedDistance < 30 and trackingData then
                        self:fillTrackingListContent()
                        self:selectTracked(dt.id)
                    end
                end),
            },
            content = ui.content {
                {
                    template = templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        text = uiUtils.colorize(text, self.textFilter, "#"..config.data.ui.selectionColor:asHex(), "#"..textColor:asHex()),
                        textSize = params.fontSize or 18,
                        textColor = textColor,
                        multiline = false,
                        wordWrap = false,
                        textAlignH = ui.ALIGNMENT.Start,
                    },
                }
            }
        }

        content:add(contentData)

        heightInList = heightInList + params.fontSize

        ::continue::
    end

    local height = #content * (params.fontSize or 18)
    sBoxMeta:setContentHeight(height)
    local scrollPos = sBoxMeta:getScrollPosition()
    local scrollElemHeight = sBoxMeta.params.size.y
    if scrollPos > height then
        sBoxMeta:setScrollPosition(math.max(0, height - scrollElemHeight))
    end
end


function topicMenuMeta:removeListed()
    local qList = self:getTrackingList()
    ---@type questGuider.ui.scrollBox
    local sBoxMeta = qList.userData.scrollBoxMeta

    local content = sBoxMeta:getMainFlex().content

    for _, el in pairs(content) do
        if not el.userData or not el.userData.diaId then goto continue end

        tracking.removeMarker{
            objectId = el.userData.objectId,
            questId = el.userData.diaId
        }

        ::continue::
    end
end



---@class questGuider.ui.trackingMenu.params
---@field menuId string?
---@field size any
---@field sizeProportional any
---@field fontSize integer?
---@field relativePosition any?
---@field headerName string?
---@field onClose function?

---@param params questGuider.ui.trackingMenu.params
local function create(params)

    params.fontSize = params.fontSize or 18

    ---@class questGuider.ui.trackingMenuMeta
    local meta = setmetatable({}, topicMenuMeta)

    local function updateFunc()
        if not meta.menu then return end
        meta:update()
    end

    if not params.size then
        local scaledScreenSize = uiUtils.getScaledScreenSize()
        params.size = util.vector2(scaledScreenSize.x * params.sizeProportional.x, scaledScreenSize.y * params.sizeProportional.y)
    end

    if not params.menuId then
        params.menuId = commonData.trackingMenuId
    end

    meta.params = params

    meta.textFilter = ""

    ---@type table<string, questGuider.quest.getRequirementPositionData.positionData[]>
    meta.positions = {}


    local trackingInfoSize = util.vector2(params.size.x * (1 - config.data.journal.listRelativeSize * 0.01), params.size.y)
    meta.trackingInfoPanelSize = trackingInfoSize
    local topicInfo = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = trackingInfoSize,
        },
        userData = {
            size = trackingInfoSize,
        },
        content = ui.content {

        }
    }

    local mainHeader = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(params.size.x + 6, params.fontSize * 1.5),
        },
        userData = {},
        events = {
            mousePress = async:callback(function(coord, layout)
                local screenSize = uiUtils.getScaledScreenSize()
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
                meta:update()
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end

                local screenSize = uiUtils.getScaledScreenSize()
                local props = meta.menu.layout.props
                local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

                props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
                meta:update()

                layout.userData.lastMousePos = relativePos
            end),
        },
        content = ui.content{
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                    alpha = config.data.ui.headerBackgroundAlpha / 100,
                }
            },
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = params.headerName and params.headerName or l10n("tracking"),
                    textSize = params.fontSize * 1.5,
                    autoSize = true,
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                },
            },
            {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = l10n("close"),
                    textSize = params.fontSize * 1.25,
                    autoSize = true,
                    anchor = util.vector2(1, 1),
                    relativePosition = util.vector2(1, 1),
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                    propagateEvents = false,
                },
                userData = {},
                events = {
                    mouseRelease = async:callback(function(_, layout)
                        if params.onClose then params.onClose() end
                        meta.menu:destroy()
                    end),
                }
            },
        },
    }

    local trackingListSize = util.vector2(params.size.x * config.data.journal.listRelativeSize * 0.01, params.size.y)
    local searchBar
    searchBar = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(trackingListSize.x, params.fontSize + 10)
        },
        content = ui.content {
            {
                template = templates.box,
                props = {
                    position = util.vector2(2, (params.fontSize + 10) / 2),
                    anchor = util.vector2(0, 0.5),
                },
                content = ui.content {
                    {
                        template = templates.textEditLine,
                        props = {
                            autoSize = false,
                            textSize = params.fontSize,
                            size = util.vector2(params.size.x * 0.2, params.fontSize + 4),
                            textColor = config.data.ui.defaultColor,
                        },
                        events = {
                            textChanged = async:callback(function(text, layout)
                                meta.textFilter = text
                            end),
                            keyRelease = async:callback(function(e, layout)
                                if e.code == input.KEY.Enter then
                                    local selectedQuest = meta:getQuestListSelectedFladValue()
                                    meta:fillTrackingListContent()
                                    meta:selectTracked(selectedQuest)
                                    searchBar.content[1].content[1].props.text = meta.textFilter

                                    local qBox = meta:getTrackingInfoScrollBox()
                                    if qBox and qBox.userData and qBox.userData.updateText then
                                        qBox.userData.updateText()
                                    end

                                    updateFunc()
                                end
                            end),
                            focusLoss = async:callback(function(layout)
                                searchBar.content[1].content[1].props.text = meta.textFilter
                            end),
                        },
                    },
                }
            },
            button{
                updateFunc = updateFunc,
                text = l10n("filter"),
                textSize = params.fontSize,
                position = util.vector2(trackingListSize.x - 2, (params.fontSize + 10) / 2),
                anchor = util.vector2(1, 0.5),
                event = function (layout)
                    local selectedQuest = meta:getQuestListSelectedFladValue()
                    meta:fillTrackingListContent()
                    meta:selectTracked(selectedQuest)

                    local qBox = meta:getTrackingInfoScrollBox()
                    if qBox and qBox.userData and qBox.userData.updateText then
                        qBox.userData.updateText()
                    end
                end
            },
        }
    }

    local mapBtnBlock = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = util.vector2(trackingListSize.x, params.fontSize * 2)
        },
        content = ui.content {
            checkBox{
                updateFunc = function ()
                    meta:update()
                end,
                checked = localStorage.data.trackingListCheckBox and true or false,
                text = l10n("llist"),
                textSize = params.fontSize,
                anchor = util.vector2(0, 0.5),
                relativePosition = util.vector2(0.05, 0.5),
                event = function (checked, layout)
                    localStorage.data.trackingListCheckBox = checked
                    meta:fillTrackingListContent()
                end
            },
            button{
                updateFunc = function ()
                    meta:update()
                end,
                text = l10n("map"),
                textSize = params.fontSize,
                anchor = util.vector2(1, 0.5),
                relativePosition = util.vector2(0.95, 0.5),
                event = function (layout)
                    if not meta:showMainMap() then
                        ui.showMessage(l10n("mapUpdateQuestDataMessage"))
                    end
                end
            }
        }
    }

    local isHide = true
    local bottomBtnsSize = util.vector2(trackingListSize.x - 2, params.fontSize * 2)
    local bottomBtns = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            horizontal = true,
            size = bottomBtnsSize,
        },
        content = ui.content {
            button{
                updateFunc = updateFunc,
                textSize = meta.params.fontSize * 0.8,
                anchor = util.vector2(0, 0.5),
                position = util.vector2(8, bottomBtnsSize.y / 2),
                text = l10n("hideShowAll"),
                event = function (layout)
                    local qList = meta:getTrackingList()
                    ---@type questGuider.ui.scrollBox
                    local sBoxMeta = qList.userData.scrollBoxMeta

                    local content = sBoxMeta:getMainFlex().content

                    for _, el in pairs(content) do
                        if not el.userData or not el.userData.diaId then goto continue end

                        tracking.setDisableMarkerState{
                            objectId = el.userData.objectId,
                            questId = el.userData.diaId,
                            value = isHide,
                            isUserDisabled = true,
                        }

                        ::continue::
                    end
                    isHide = not isHide
                    meta:fillTrackingListContent()
                    meta:clearTrackingInfo()
                    meta:resetListSelection()
                end
            },
            button{
                updateFunc = updateFunc,
                textSize = meta.params.fontSize * 0.8,
                anchor = util.vector2(1, 0.5),
                position = util.vector2(bottomBtnsSize.x - 6, bottomBtnsSize.y / 2),
                text = l10n("removeAll"),
                event = function (layout)
                    playerRef:sendEvent("QGL:removeAllTrackedMessageBox")
                end
            }
        }
    }

    local trackingContent = ui.content{}

    local trackingListBox = scrollBox{
        updateFunc = updateFunc,
        size = util.vector2(trackingListSize.x - 2, trackingListSize.y - params.fontSize * 5 - 10),
        scrollAmount = params.size.y / 5,
        content = trackingContent,
        contentHeight = 0,
        withoutBorders = true,
    }

    local trackingList = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            horizontal = false,
            size = trackingListSize
        },
        content = ui.content {
            searchBar,
            mapBtnBlock,
            trackingListBox,
            bottomBtns,
        }
    }


    local mainWindow = {
        template = customTemplates.boxSolidThick,
        props = {

        },
        events = {
            focusLoss = async:callback(function(e, layout)
                meta.inFocus = false
            end),

            mouseMove = async:callback(function(e, layout)
                meta.inFocus = true
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    trackingList,
                    topicInfo
                }
            }
        }
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        layer = "Windows",
        props = {
            autoSize = true,
            horizontal = false,
            align = ui.ALIGNMENT.Center,
            relativePosition = params.relativePosition or util.vector2(0, 0)
        },
        userData = {

        },
        content = ui.content {
            mainHeader,
            mainWindow,
        }
    }

    meta.menu = ui.create(mainFlex)

    meta:fillTrackingListContent()

    local function onMouseWheelCallback(content, value)
        for _, dt in pairs(content) do
            if not type(dt) == "table" then goto continue end
            if dt.userData and dt.userData.onMouseWheel then
                dt.userData.onMouseWheel(value)
            end

            if dt.content then
                onMouseWheelCallback(dt.content, value)
            end

            ::continue::
        end
    end

    meta.onMouseWheel = function (self, vertical)
        local layout = meta.menu.layout
        onMouseWheelCallback(layout.content, vertical)
    end


    local objectIds = tableLib.keys(tracking.markerByObjectId)
    core.sendGlobalEvent("QGL:getPositionsForTrackingMenu", {
        objectIds = objectIds,
        menuId = meta.params.menuId,
    })


    return meta
end


return create