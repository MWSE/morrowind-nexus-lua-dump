local core = require('openmw.core')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local playerRef = require('openmw.self')
local templates = require('openmw.interfaces').MWUI.templates
local I = require("openmw.interfaces")

local config = require("scripts.quest_guider_lite.configLib")
local commonUtils = require("scripts.quest_guider_lite.utils.common")
local consts = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local playerQuests = require('scripts.quest_guider_lite.playerQuests')
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local log = require("scripts.quest_guider_lite.utils.log")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")
local mapMenu = require("scripts.quest_guider_lite.ui.mapMenu")

local l10n = core.l10n(consts.l10nKey)

local COLOR_GOLD = util.color.rgb(0.79, 0.65, 0.38)
local COLOR_GOLD_BRIGHT = util.color.rgb(0.9, 0.78, 0.5)
local COLOR_GOLD_DIM = util.color.rgb(0.55, 0.45, 0.25)
local COLOR_GRAY = util.color.rgb(0.45, 0.45, 0.45)
local COLOR_WHITE = util.color.rgb(1, 1, 1)

local borderTexTop = ui.texture{ path = "textures/menu_thin_border_top.dds" }

local this = {}


---@class questGuider.ui.nextStagesMeta
local nextStagesMeta = {}
nextStagesMeta.__index = nextStagesMeta

nextStagesMeta.type = consts.elementMetatableTypes.nextStages


function nextStagesMeta:getObjectsFlex()
    return self:getLayout().content[1]
end

function nextStagesMeta:getRequirementsFlex()
    return self:getLayout().content[2]
end

function nextStagesMeta:getRequirementsHeader()
    return self:getLayout()
end

function nextStagesMeta:getHeaderNextBtnsFlex()
    return self:getLayout()
end

function nextStagesMeta:getHeaderVariantBtnsFlex()
    return self:getLayout()
end

function nextStagesMeta:getObjectCount()
    return #(self._objectEntries or {})
end

function nextStagesMeta:getCursorIndex()
    return self._cursorIndex or 0
end

function nextStagesMeta:setCursorIndex(index)
    self._cursorIndex = index
    self:_refreshCursor()
end

function nextStagesMeta:navigateObjective(direction)
    local count = self:getObjectCount()
    if count == 0 then return false end
    local cur = self._cursorIndex or 0
    local next = cur + direction
    if next < 1 then next = 1 end
    if next > count then next = count end
    if next == cur then return false end
    self._cursorIndex = next
    self:_refreshCursor()
    return true
end

function nextStagesMeta:_refreshCursor()
    for i, entry in ipairs(self._objectEntries or {}) do
        if i == self._cursorIndex then
            entry.cursorElem.props.text = ">>"
            entry.cursorElem.props.textColor = COLOR_WHITE
            if entry.nameElem then
                entry.nameElem.props.textColor = COLOR_WHITE
            end
        else
            entry.cursorElem.props.text = " "
            entry.cursorElem.props.textColor = COLOR_GOLD_DIM
            if entry.nameElem then
                local objId = entry.objectId
                local diaId = entry.diaId
                local trackedState = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                local disabledState = tracking.getDisabledState{objectId = objId, questId = diaId}
                local trackingData = tracking.markerByObjectId[objId]
                if disabledState then
                    entry.nameElem.props.textColor = COLOR_GRAY
                elseif trackedState and trackingData and trackingData.color then
                    entry.nameElem.props.textColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                elseif trackedState then
                    entry.nameElem.props.textColor = COLOR_GOLD_BRIGHT
                else
                    entry.nameElem.props.textColor = COLOR_GOLD
                end
            end
        end
    end
end

function nextStagesMeta:toggleSelectedTracking()
    local entry = (self._objectEntries or {})[self._cursorIndex]
    if not entry then return end

    local objId = entry.objectId
    local diaId = entry.diaId
    local diaIndex = entry.diaIndex
    local wasTracked = tracking.isObjectTracked{diaId = diaId, objectId = objId}

    if wasTracked then
        tracking.removeMarker{objectId = objId, questId = diaId}
        tracking.updateMarkers()
        playerRef:sendEvent("QGL:updateQuestMenu", {})
    else
        tracking.trackObject{diaId = diaId, objectId = objId, index = diaIndex}
    end

    async:newUnsavableSimulationTimer(0.1, function()
        tracking.updateTemporaryMarkers()
    end)

    if entry.trackBtnLayout and entry.trackBtnLayout.userData and entry.trackBtnLayout.userData.meta then
        local btn = entry.trackBtnLayout.userData.meta:getButtonTextElement()
        if btn then
            btn.props.text = wasTracked and l10n("track") or l10n("untrack")
        end
    end

    self:updateObjectElements()
    self:update()
end

function nextStagesMeta:updateObjectElements()
    local flex = self:getObjectsFlex()

    for _, elem in pairs(flex.content) do
        if not elem.userData or not elem.userData.diaId or not elem.userData.objectId then goto continue end

        local objId = elem.userData.objectId
        local diaId = elem.userData.diaId
        local disabledState = tracking.getDisabledState{objectId = objId, questId = diaId}
        local trackedState = tracking.isObjectTracked{diaId = diaId, objectId = objId}
        local trackingData = tracking.markerByObjectId[objId]

        if elem.userData.nameElem then
            if not trackedState or not trackingData then
                elem.userData.nameElem.props.textColor = COLOR_GOLD
            elseif not disabledState then
                elem.userData.nameElem.props.textColor = trackingData.color
                    and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                    or COLOR_GOLD_BRIGHT
            else
                elem.userData.nameElem.props.textColor = COLOR_GRAY
            end
        end

        if elem.userData.indicatorElem then
            if trackedState then
                elem.userData.indicatorElem.props.text = "*"
                elem.userData.indicatorElem.props.textColor = COLOR_GOLD_BRIGHT
            else
                elem.userData.indicatorElem.props.text = "-"
                elem.userData.indicatorElem.props.textColor = COLOR_GOLD_DIM
            end
        end

        ::continue::
    end
end


---@param params questGuider.ui.nextStages.params
function this.create(params)

    ---@class questGuider.ui.nextStagesMeta
    local meta = setmetatable({}, nextStagesMeta)

    meta.update = function(self)
        params.updateFunc()
    end

    meta.data = params.data
    meta.params = params

    local nextStageData = meta.data
    local objectPositions = nextStageData.objectPositions or {}
    local fontSize = params.fontSize or 18

    local objectsFlex = {
        type = ui.TYPE.Flex,
        props = { autoSize = true, horizontal = false },
        content = ui.content{}
    }

    local requirementsFlex = {
        type = ui.TYPE.Flex,
        props = { autoSize = true, horizontal = false },
        content = ui.content{}
    }

    local allObjects = {}
    local seenObjects = {}

    local function collectObjects(stageData)
        for diaId, diaData in pairs(stageData or {}) do
            local currentIndex = playerQuests.getCurrentIndex(diaId) or 0
            for _, nextData in ipairs(diaData) do
                if not params.isQuestListMode and currentIndex >= nextData.index then goto stgContinue end
                for _, reqVariants in ipairs(nextData.requirements or {}) do
                    for _, req in pairs(reqVariants) do
                        for objId, posDt in pairs(req.positionData or {}) do
                            if seenObjects[objId] or consts.forbiddenForTracking[posDt.reqType or ""] then goto objContinue end
                            local positionData = objectPositions[objId]
                            if not positionData then goto objContinue end
                            local descr = ""
                            for _, pos in pairs(tableLib.getFirst(positionData.positions or {}, 1)) do
                                descr = stringLib.getPathToPosition(pos) or ""
                            end
                            seenObjects[objId] = true
                            table.insert(allObjects, {
                                id = objId,
                                name = positionData.name or "???",
                                descr = descr,
                                diaId = diaId,
                                diaIndex = nextData.index,
                                positions = positionData.positions,
                            })
                            ::objContinue::
                        end
                    end
                    break
                end
                ::stgContinue::
            end
        end
    end

    collectObjects(nextStageData.next)
    collectObjects(nextStageData.linked)
    table.sort(allObjects, function(a, b) return a.name < b.name end)

    meta._objectEntries = {}
    meta._cursorIndex = 0

    if #allObjects > 0 then
        objectsFlex.content:add(interval(0, fontSize * 0.3))
        objectsFlex.content:add({
            type = ui.TYPE.Image,
            props = {
                resource = borderTexTop,
                tileH = true,
                size = util.vector2(params.size.x * 0.6, 2),
            },
        })
        objectsFlex.content:add(interval(0, fontSize * 0.5))
    end

    for _, objData in ipairs(allObjects) do
        local objId = objData.id
        local diaId = objData.diaId
        local diaIndex = objData.diaIndex
        local trackingData = tracking.markerByObjectId[objId]
        local isTracked = tracking.isObjectTracked{diaId = diaId, objectId = objId}
        local isDisabled = tracking.getDisabledState{objectId = objId, questId = diaId}

        local cursorElem = {
            type = ui.TYPE.Text,
            props = {
                text = " ",
                textSize = fontSize,
                textColor = COLOR_GOLD_DIM,
                autoSize = true,
            },
        }

        local cursorWrapper = {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(fontSize * 1.4, fontSize) },
            content = ui.content{ cursorElem },
        }

        local indicatorElem = {
            type = ui.TYPE.Text,
            props = {
                text = isTracked and "*" or "-",
                textSize = fontSize,
                textColor = isTracked and COLOR_GOLD_BRIGHT or COLOR_GOLD_DIM,
                autoSize = true,
            },
        }

        local nameColor = COLOR_GOLD
        if isTracked and trackingData and trackingData.color then
            nameColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
        elseif isTracked then
            nameColor = COLOR_GOLD_BRIGHT
        end
        if isDisabled then nameColor = COLOR_GRAY end

        local nameElem = {
            type = ui.TYPE.Text,
            props = {
                text = objData.name,
                textSize = fontSize,
                textColor = nameColor,
                autoSize = true,
                multiline = false,
                wordWrap = false,
            },
        }

        local trackBtn = button{
            updateFunc = function() params.updateFunc() end,
            text = isTracked and l10n("untrack") or l10n("track"),
            textSize = fontSize * 0.7,
            visible = tracking.initialized and not params.hideTrackButtons,
            anchor = util.vector2(0, 0.5),
            parentScrollBoxUserData = params.parentScrollBoxUserData,
            event = function(layout)
                local wasTracked = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                if wasTracked then
                    tracking.removeMarker{objectId = objId, questId = diaId}
                    tracking.updateMarkers()
                    playerRef:sendEvent("QGL:updateQuestMenu", {})
                else
                    tracking.trackObject{diaId = diaId, objectId = objId, index = diaIndex}
                end
                async:newUnsavableSimulationTimer(0.1, function()
                    tracking.updateTemporaryMarkers()
                end)
                local btnMeta = layout.userData.meta
                local btn = btnMeta:getButtonTextElement()
                if btn then
                    btn.props.text = not wasTracked and l10n("untrack") or l10n("track")
                end
                meta:updateObjectElements()
                meta:update()
            end
        }

        local nameLine = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content{
                cursorWrapper,
                indicatorElem,
                interval(fontSize * 0.4, 0),
                nameElem,
                interval(fontSize * 0.8, 0),
                trackBtn,
            }
        }

        local locationLine = {
            type = ui.TYPE.Text,
            props = {
                text = "    " .. objData.descr,
                textSize = fontSize * 0.8,
                textColor = COLOR_GOLD_DIM,
                autoSize = true,
                multiline = false,
                wordWrap = false,
            },
        }

        local entry = {
            type = ui.TYPE.Flex,
            props = { autoSize = true, horizontal = false },
            userData = {
                objectId = objId,
                diaId = diaId,
                nameElem = nameElem,
                indicatorElem = indicatorElem,
            },
            content = ui.content{
                nameLine,
                locationLine,
                interval(0, fontSize * 0.4),
            }
        }

        objectsFlex.content:add(entry)

        table.insert(meta._objectEntries, {
            cursorElem = cursorElem,
            indicatorElem = indicatorElem,
            nameElem = nameElem,
            objectId = objId,
            diaId = diaId,
            diaIndex = diaIndex,
            trackBtnLayout = trackBtn,
        })
    end

    local mainFlex = {
        type = ui.TYPE.Flex,
        props = { autoSize = true, horizontal = false },
        userData = { meta = meta },
        content = ui.content{
            objectsFlex,
            requirementsFlex,
        }
    }

    meta.getLayout = function(self) return mainFlex end
    meta.data = nil

    return mainFlex
end


return this
