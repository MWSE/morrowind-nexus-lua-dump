local core = require("openmw.core")
local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local playerRef = require("openmw.self")
local I = require("openmw.interfaces")

local config = require("scripts.quest_guider_lite.configLib")
local commonData = require("scripts.quest_guider_lite.common")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local tracking = require("scripts.quest_guider_lite.trackingLocal")
local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")
local menuHandler = require("scripts.quest_guider_lite.menuHandler")
local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local getObject = require("scripts.quest_guider_lite.core.getObject")
local realTimer = require("scripts.quest_guider_lite.realTimer")

local templates = require("scripts.quest_guider_lite.ui.templates")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")
local mapMenu = require("scripts.quest_guider_lite.ui.mapMenu")
local borders = require("scripts.quest_guider_lite.ui.borders")

local l10n = core.l10n(commonData.l10nKey)

local this = {}

local typeLabel = "Object_Tracking_Layout"


---@class questGuider.ui.addObjectPositionInfo.params
---@field diaId string?
---@field diaIndex string?
---@field reqs questGuider.quest.getDescriptionDataFromBlock.returnArr[]?
---@field objPoss table<string, questGuider.quest.getRequirementPositionData.returnData>
---@field questDiaLinks table<string, table<string, any>>? by objectId, by quest dialogue id
---@field width number
---@field fontSize number
---@field updateFunc function
---@field parentScrollBoxUserData table
---@field hideTrackButtons boolean?
---@field parentContent table
---@field addMissingTrackingObjects boolean?
---@field questName string? -- required for addMissingTrackingObjects

---@param params questGuider.ui.addObjectPositionInfo.params
function this.addObjectPositionInfo(content, params)

    local hasStartedMarkersUpdateTimer = nil

    ---@type table<string, {id : string, name : string, descr : string, descrBackward : string, diaId : string?, diaInd : string?, positions : questGuider.quest.getRequirementPositionData.positionData[]?}>
    local objectPosInfo = {}

    ---@param positionData questGuider.quest.getRequirementPositionData.returnData
    local function addPosInfo(objId, positionData)
        ---@param pos questGuider.quest.getRequirementPositionData.positionData
        for _, pos in pairs(tableLib.getFirst(positionData.positions, 1)) do
            local descr, descrBck = stringLib.getPathToPosition(pos)

            objectPosInfo[positionData.name or objId] = {
                id = objId,
                descr = descr or "",
                descrBackward = descrBck or descr or "",
                name = positionData.name or "???",
                positions = positionData.positions,
                parentObject = positionData.parentObject,
            }
        end
    end

    if not params.reqs then
        for objId, positionData in pairs(params.objPoss) do
            addPosInfo(objId, positionData)
        end
    else
        for _, req in pairs(params.reqs or {}) do
            for objId, posDt in pairs(req.positionData or {}) do
                if commonData.forbiddenForTracking[posDt.reqType or ""] then goto continue end

                local positionData = params.objPoss[objId]
                if not positionData then goto continue end

                addPosInfo(objId, positionData)

                ::continue::
            end
        end
    end

    if params.addMissingTrackingObjects and params.questName then
        local qData = playerQuests.getQuestDataByName(params.questName)
        if qData then
            local trackedObjects = {}
            local diaIds = tableLib.keys(qData.records)
            for _, diaId in pairs(diaIds) do
                local objects = tracking.getDiaTrackedObjects(diaId)
                for objId, _ in pairs(objects or {}) do
                    trackedObjects[objId] = diaId
                end
            end

            for objId, diaId in pairs(trackedObjects) do
                local obj = getObject(objId)
                local name = obj and obj.name or objId

                local objTrackingData = tracking.getTrackedObjectData(objId)

                if not objectPosInfo[name] and objTrackingData then
                    local markerData = objTrackingData.markers[diaId]

                    if markerData then
                        objectPosInfo[name] = {
                            id = objId,
                            name = name,
                            diaId = diaId,
                            diaInd = markerData.index,
                        }
                    end
                end
            end
        end
    end


    objectPosInfo = tableLib.values(objectPosInfo, function (a, b)
        return a.name < b.name
    end)

    for _, objData in pairs(objectPosInfo) do
        local objId = objData.id

        local hasDiaId = params.diaId ~= nil
        local diaId = params.diaId or objData.diaId
        local diaIndex = params.diaIndex or objData.diaInd
        if (not diaId or not diaIndex) and params.questDiaLinks then
            local objDt = params.questDiaLinks[objData.parentObject or objId]
            local dId, dIndexes = next(objDt or {})
            if dId then
                local ind = next(dIndexes)
                if ind then
                    diaId = dId
                    diaIndex = ind
                end
            end
        end

        local trackingData = tracking.markerByObjectId[objId]

        local objectColor = config.data.ui.defaultColor
        if trackingData then
            if trackingData.color then
                objectColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
            end
        end

        local function isObjectTracked()
            return tracking.isObjectTracked{diaId = hasDiaId and diaId or nil, objectId = objId}
        end

        local function getDisabledState()
            return tracking.getDisabledState{objectId = objId, questId = hasDiaId and diaId or nil}
        end

        local header

        local trackBtnLayout = button{
            updateFunc = params.updateFunc,
            text = isObjectTracked() and l10n("untrack") or l10n("track"),
            textSize = (params.fontSize or 18) * 0.8,
            visible = tracking.initialized and not params.hideTrackButtons and diaId and diaIndex and true or false,
            anchor = util.vector2(0, 0.5),
            parentScrollBoxUserData = params.parentScrollBoxUserData,
            event = function (layout)
                local trackedState = isObjectTracked()
                if trackedState then
                    tracking.removeMarker{objectId = objId, questId = hasDiaId and diaId or nil}
                    tracking.updateMarkers()
                    playerRef:sendEvent("QGL:updateQuestMenu", {})
                else
                    tracking.trackObject{diaId = diaId, objectId = objId, index = diaIndex}
                end

                if not hasStartedMarkersUpdateTimer then
                    hasStartedMarkersUpdateTimer = true
                    async:newUnsavableSimulationTimer(0.1, function ()
                        hasStartedMarkersUpdateTimer = nil
                        tracking.updateTemporaryMarkers()
                    end)
                end

                realTimer.newTimer(0.25, function ()
                    this.updateObjectTrackingElements(params.parentContent)
                    params.updateFunc()
                end)
            end
        }

        local hideBtnLayout = button{
            updateFunc = params.updateFunc,
            text = getDisabledState() and l10n("show") or l10n("hide"),
            textSize = (params.fontSize or 18) * 0.8,
            visible = tracking.initialized and not params.hideTrackButtons and isObjectTracked() or false,
            anchor = util.vector2(0, 0.5),
            parentScrollBoxUserData = params.parentScrollBoxUserData,
            event = function (layout)
                local disabledState = getDisabledState()
                disabledState = not disabledState

                tracking.setDisableMarkerState{
                    objectId = objId,
                    questId = hasDiaId and diaId or nil,
                    value = disabledState,
                    isUserDisabled = true,
                }
                tracking.updateTemporaryMarkers()
                tracking.updateMarkers()

                realTimer.newTimer(0.25, function ()
                    this.updateObjectTrackingElements(params.parentContent)
                    params.updateFunc()
                end)
            end
        }

        header = {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(params.width - params.fontSize, params.fontSize * 1.2 + 2)
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = commonData.whiteTexture,
                        relativeSize = util.vector2(1, 1),
                        color = config.data.ui.defaultColor,
                        alpha = 0.1,
                    }
                },
                {
                    type = ui.TYPE.Container,
                    template = templates.underlineBoxThin,
                    props = {
                        anchor = util.vector2(0, 1),
                        relativePosition = util.vector2(0, 1),
                    },
                    content = ui.content{
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = objData.name,
                                autoSize = true,
                                textSize = params.fontSize * 1.2,
                                multiline = false,
                                wordWrap = false,
                                textColor = getDisabledState() and config.data.ui.disabledColor or objectColor,
                            },
                        },
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = true,
                        anchor = util.vector2(1, 1),
                        position = util.vector2(params.width - config.data.ui.scrollArrowSize - 8, 0),
                        relativePosition = util.vector2(0, 1),
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        trackBtnLayout,
                        interval((params.fontSize or 18), 0),
                        hideBtnLayout,
                        interval((params.fontSize or 18), 0),
                        -- {
                        --     type = ui.TYPE.Text,
                        --     props = {
                        --         text = l10n("closestColon"),
                        --         textColor = config.data.ui.defaultColor,
                        --         autoSize = true,
                        --         textSize = (params.fontSize or 18) * 0.8,
                        --         anchor = util.vector2(0, 0.5),
                        --         textAlignH = ui.ALIGNMENT.End,
                        --         multiline = false,
                        --         wordWrap = false,
                        --     },
                        -- },
                    }
                },
            }
        }

        if objData.positions and next(objData.positions) and mapMenu.isValidMapPositionsExist(objData.positions) and
                (playerDataHandler.isMapImageExists() or I.AdvancedWorldMap and I.AdvancedWorldMap.vesion >= 12) then
            header.content[3].content:insert(5, button{
                updateFunc = params.updateFunc,
                text = l10n("map"),
                textSize = (params.fontSize or 18) * 0.8,
                anchor = util.vector2(0, 0.5),
                parentScrollBoxUserData = params.parentScrollBoxUserData,
                event = function (layout)
                    playerRef:sendEvent("QGL:showSimpleMap", {objectId = objId, positions = objData.positions})
                end
            })
            header.content[3].content:insert(6, interval((params.fontSize or 18), 0))
        end

        local positionLay
        if objData.descr then
            local posTextOffset = params.fontSize / 2
            local posHeight = uiUtils.getTextHeight(objData.descr, params.fontSize, params.width - posTextOffset, config.data.journal.textHeightMulRecord)
            positionLay = {
                type = ui.TYPE.Text,
                props = {
                    text = objData.descr,
                    textColor = config.data.ui.defaultColor,
                    autoSize = false,
                    textSize = params.fontSize or 18,
                    size = util.vector2(
                        params.width,
                        posHeight
                    ),
                    multiline = true,
                    wordWrap = true,
                },
            }
        else
            positionLay = {}
        end

        content:add{
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = false,
            },
            userData = {
                type = typeLabel,
                objectId = objId,
                diaId = diaId,
                useDiaId = hasDiaId,
                trackBtnLayout = trackBtnLayout,
                hideBtnLayout = hideBtnLayout,
                -- positions = objData.positions,
            },
            content = ui.content {
                header,
                interval(params.fontSize / 2),
                positionLay,
            }
        }
        content:add(interval(0, math.floor(params.fontSize / 2)))
    end
end


function this.updateObjectTrackingElements(content)
    for menuId, meta in pairs(menuHandler.getMenus()) do
        if meta.updateQuestListTrackedColors then
            meta:updateQuestListTrackedColors()
        end
    end

    for _, elem in pairs(content) do
        if elem.userData then

            if elem.userData.type == typeLabel and elem.userData.objectId then
                local useDiaId = elem.userData.useDiaId
                local disabledState = tracking.getDisabledState{objectId = elem.userData.objectId, questId = useDiaId and elem.userData.diaId or nil}
                local trackedState = tracking.isObjectTracked{diaId = useDiaId and elem.userData.diaId or nil, objectId = elem.userData.objectId}
                local trackingData = tracking.markerByObjectId[elem.userData.objectId]

                local textElem = elem.content[1].content[2].content[1]
                if not trackedState or not trackingData then
                    textElem.props.textColor = config.data.ui.defaultColor
                elseif not disabledState then
                    textElem.props.textColor = trackingData.color and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                        or config.data.ui.defaultColor
                elseif disabledState then
                    textElem.props.textColor = config.data.ui.disabledColor
                end

                local trackBtnMeta = elem.userData.trackBtnLayout.userData.meta
                trackBtnMeta:getButtonTextElement().props.text = trackedState and l10n("untrack") or l10n("track")
                local showHideBtn = elem.userData.hideBtnLayout
                if trackedState then
                    showHideBtn.props.visible = true
                    local showHideBtnMeta = showHideBtn.userData.meta
                    local btn = showHideBtnMeta:getButtonTextElement()
                    ---@diagnostic disable-next-line: need-check-nil
                    btn.props.text = disabledState and l10n("show") or l10n("hide")
                else
                    showHideBtn.props.visible = false
                end

            elseif elem.userData.objectsFlexContent then
                this.updateObjectTrackingElements(elem.userData.objectsFlexContent)
            elseif elem.userData.detailsContent then
                this.updateObjectTrackingElements(elem.userData.detailsContent)
            end

        elseif elem.content then
            this.updateObjectTrackingElements(elem.content)
        end
    end
end


return this