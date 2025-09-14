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

local tableLib = require("scripts.quest_guider_lite.utils.table")

local playerQuests = require('scripts.quest_guider_lite.playerQuests')
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local log = require("scripts.quest_guider_lite.utils.log")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")

local l10n = core.l10n(consts.l10nKey)


local this = {}


---@class questGuider.ui.nextStagesMeta
local nextStagesMeta = {}
nextStagesMeta.__index = nextStagesMeta

nextStagesMeta.type = consts.elementMetatableTypes.nextStages


function nextStagesMeta.getRequirementsFlex(self)
    return self:getLayout().content[3]
end

function nextStagesMeta.getRequirementsHeader(self)
    return self:getLayout().content[1]
end

function nextStagesMeta.getObjectsFlex(self)
    return self:getLayout().content[2]
end

function nextStagesMeta.getHeaderNextBtnsFlex(self)
    return self:getRequirementsHeader().content[1].content[2]
end

function nextStagesMeta.getHeaderVariantBtnsFlex(self)
    return self:getRequirementsHeader().content[3]
end

function nextStagesMeta.updateObjectElements(self)
    local flex = self:getObjectsFlex()

    for _, elem in pairs(flex.content) do
        if not elem.userData or not elem.userData.diaId or not elem.userData.objectId then goto continue end

        local disabledState = tracking.getDisabledState{objectId = elem.userData.objectId, questId = elem.userData.diaId}
        local trackedState = tracking.isObjectTracked{diaId = elem.userData.diaId, objectId = elem.userData.objectId}
        local trackingData = tracking.markerByObjectId[elem.userData.objectId]

        local textElem = elem.content[1].content[1].content[1]
        if not trackedState or not trackingData then
            textElem.props.textColor = config.data.ui.defaultColor
        elseif not disabledState then
            textElem.props.textColor = trackingData.color and util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                or config.data.ui.defaultColor
        elseif disabledState then
            textElem.props.textColor = config.data.ui.disabledColor
        end

        ::continue::
    end
end


function nextStagesMeta._fill(self, nextBtnsFlexContent)
    local params = self.params

    local nextStageData = self.data

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local objectPositions = nextStageData.objectPositions

    ---@param data  questGuider.quest.getRequirementPositionData.positionData
    ---@return string?
    ---@return string?
    local function getDescription(data)
        local descr
        local descrBack
        if not data.description then
            if data.pathFromPlayer then
                for _, cellName in ipairs(data.pathFromPlayer) do
                    descr = descr and string.format("%s => \"%s\"", descr, cellName) or
                        string.format("\"%s\"", cellName)
                    descrBack = descrBack and string.format("\"%s\" <= %s", cellName, descrBack) or
                        string.format("\"%s\"", cellName)
                end

            elseif data.cellPath then
                for i = #data.cellPath, 1, -1 do
                    descr = descr and string.format("%s => \"%s\"", descr, data.cellPath[i].name) or
                        string.format("\"%s\"", data.cellPath[i].name)
                    descrBack = descrBack and string.format("\"%s\" <= %s", data.cellPath[i].name, descrBack) or
                        string.format("\"%s\"", data.cellPath[i].name)
                end

            elseif data.id then
                descr = string.format("\"%s\"", data.id)
                descrBack = descr

            else
                descr = "???"
                descrBack = "???"
            end
        else
            descr = data.description
        end

        return descr, descrBack
    end

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addObjectPositionInfo(content, requirements, diaId, diaIndex)
        ---@type table<string, {id : string, name : string, descr : string, descrBackward : string, positions : questGuider.quest.getRequirementPositionData.positionData[]}>
        local objectPosInfo = {}
        for _, req in pairs(requirements) do
            for objId, posDt in pairs(req.positionData or {}) do
                if objectPosInfo[objId] or consts.forbiddenForTracking[posDt.reqType or ""] then goto continue end

                local positionData = objectPositions[objId]
                if not positionData then goto continue end

                ---@param pos questGuider.quest.getRequirementPositionData.positionData
                for _, pos in pairs(tableLib.getFirst(positionData.positions, 1)) do
                    local descr, descrBck = getDescription(pos)

                    objectPosInfo[objId] = {
                        id = objId,
                        descr = descr or "",
                        descrBackward = descrBck or descr or "",
                        name = positionData.name or "???",
                        positions = positionData.positions,
                    }
                end

                ::continue::
            end
        end

        objectPosInfo = tableLib.values(objectPosInfo, function (a, b)
            return a.name < b.name
        end)

        for _, objData in pairs(objectPosInfo) do
            local objId = objData.id
            local trackingData = tracking.markerByObjectId[objId]

            local objectColor = config.data.ui.defaultColor
            if trackingData then
                if trackingData.color then
                    objectColor = util.color.rgb(trackingData.color[1], trackingData.color[2], trackingData.color[3])
                end
            end

            local header
            header = {
                type = ui.TYPE.Widget,
                props = {
                    autoSize = false,
                    size = util.vector2(self.params.size.x, params.fontSize * 1.2)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(0, 0),
                        },
                        content = ui.content {
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = objData.name,
                                    autoSize = true,
                                    textSize = (self.params.fontSize or 18) * 1.2,
                                    multiline = false,
                                    wordWrap = false,
                                    textColor = tracking.getDisabledState{objectId = objId, questId = diaId} and config.data.ui.disabledColor or objectColor,
                                },
                            },
                        }
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true,
                            horizontal = true,
                            anchor = util.vector2(1, 0),
                            position = util.vector2(self.params.size.x - config.data.ui.scrollArrowSize - 8, 0),
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            button{
                                updateFunc = self.update,
                                text = tracking.isObjectTracked{diaId = diaId, objectId = objId} and l10n("untrack") or l10n("track"),
                                textSize = (self.params.fontSize or 18) * 0.8,
                                visible = tracking.initialized and not params.hideTrackButtons,
                                anchor = util.vector2(0, 0.5),
                                parentScrollBoxUserData = self.params.parentScrollBoxUserData,
                                event = function (layout)
                                    local trackedState = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                                    if trackedState then
                                        tracking.removeMarker{objectId = objId, questId = diaId}
                                        playerRef:sendEvent("QGL:updateQuestMenu", {})
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
                                                    local showHideBtn = header.content[2].content[3]
                                                    ---@type questGuider.ui.buttonMeta
                                                    local showHideBtnMeta = showHideBtn.userData.meta
                                                    local btn = showHideBtnMeta:getButtonTextElement()
                                                    ---@diagnostic disable-next-line: need-check-nil
                                                    btn.props.text = tracking.getDisabledState{objectId = objId, questId = diaId} and l10n("show") or l10n("hide")
                                                    ---@diagnostic disable-next-line: need-check-nil
                                                    showHideBtn.props.visible = tracking.isObjectTracked{diaId = diaId, objectId = objId}
                                                    self:updateObjectElements()
                                                    self:update()
                                                end)
                                            end)
                                        end
                                    end
                                    self:updateObjectElements()
                                end
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            button{
                                updateFunc = self.update,
                                text = tracking.getDisabledState{objectId = objId, questId = diaId} and l10n("show") or l10n("hide"),
                                textSize = (self.params.fontSize or 18) * 0.8,
                                visible = tracking.initialized and not params.hideTrackButtons and tracking.isObjectTracked{diaId = diaId, objectId = objId},
                                anchor = util.vector2(0, 0.5),
                                parentScrollBoxUserData = self.params.parentScrollBoxUserData,
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

                                    self:updateObjectElements()
                                end
                            },
                            interval((self.params.fontSize or 18) * 2, 0),
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = l10n("closestColon"),
                                    textColor = config.data.ui.defaultColor,
                                    autoSize = true,
                                    textSize = (self.params.fontSize or 18) * 0.8,
                                    anchor = util.vector2(0, 0.5),
                                    textAlignH = ui.ALIGNMENT.End,
                                    multiline = false,
                                    wordWrap = false,
                                },
                            },
                        }
                    },
                }
            }

            local posTextShift = self.params.fontSize / 2
            local posHeight = uiUtils.getTextHeight(objData.descr, self.params.fontSize, self.params.size.x - posTextShift, config.data.journal.textHeightMulRecord)
            local position = {
                template = templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = objData.descr,
                    textColor = config.data.ui.defaultColor,
                    autoSize = false,
                    textSize = self.params.fontSize or 18,
                    size = util.vector2(
                        self.params.size.x,
                        posHeight
                    ),
                    multiline = true,
                    wordWrap = true,
                },
            }

            content:add{
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = false,
                },
                userData = {
                    objectId = objId,
                    diaId = diaId,
                    -- positions = objData.positions,
                },
                content = ui.content {
                    header,
                    interval(self.params.fontSize / 2),
                    position,
                }
            }
            content:add(interval(0, math.floor(self.params.fontSize / 2)))
        end
    end

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addRequirements(content, requirements)
        local text = ""
        for _, req in ipairs(requirements) do
            text = string.format("%s  %s\n", text, req.str)
        end
        local textHeight = uiUtils.getTextHeight(text, params.fontSize or 18, self.params.size.x, config.data.journal.textHeightMulRecord, 1)
        content:add{
            template = templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = text,
                textColor = config.data.ui.defaultColor,
                autoSize = false,
                size = util.vector2(self.params.size.x, textHeight),
                textSize = params.fontSize or 18,
                multiline = true,
                wordWrap = true,
            },
        }
    end

    local function resetColorOfButtons(flex)
        for _, elem in pairs(flex.content) do
            ---@type questGuider.ui.buttonMeta
            local meta = elem.userData and elem.userData.meta
            if meta then
                local textElem = meta:getButtonTextElement()
                if textElem then
                    textElem.props.textColor = config.data.ui.defaultColor
                end
            end
        end
    end

    local function addNextStageButtons(dt, format)
        for diaId, diaData in pairs(dt or {}) do

            local curentIndex = playerQuests.getCurrentIndex(diaId) or 0
            for _, nextData in ipairs(diaData) do
                if not params.isQuestListMode and curentIndex >= nextData.index then goto continue end

                nextBtnsFlexContent:add(interval(12, 0))
                nextBtnsFlexContent:add(
                    button{
                        text = string.format(format, tostring(nextData.index)),
                        textSize = params.fontSize,
                        parentScrollBoxUserData = self.params.parentScrollBoxUserData,
                        updateFunc = params.updateFunc,
                        tooltipContent = ui.content{
                            {
                                template = templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                    text = string.format(l10n("idIndexShort"), diaId, nextData.index),
                                    textColor = config.data.ui.defaultColor,
                                    autoSize = true,
                                    textSize = params.fontSize or 18,
                                    multiline = false,
                                    wordWrap = false,
                                },
                            },
                        },
                        event = function (layout)
                            local variantBtnFlex = self:getHeaderVariantBtnsFlex()
                            variantBtnFlex.content = ui.content{
                                {
                                    template = templates.textNormal,
                                    type = ui.TYPE.Text,
                                    props = {
                                        text = l10n("variantsColon"),
                                        textColor = config.data.ui.defaultColor,
                                        autoSize = true,
                                        textSize = params.fontSize or 18,
                                        multiline = false,
                                        wordWrap = false,
                                    },
                                },
                            }
                            local reqFlex = self:getRequirementsFlex()
                            reqFlex.content = ui.content{}
                            local posFlex = self:getObjectsFlex()
                            posFlex.content = ui.content{}

                            ---@type questGuider.ui.buttonMeta
                            local btnMeta = layout.userData.meta
                            local btn = btnMeta:getButtonTextElement()
                            if btn then
                                resetColorOfButtons(self:getHeaderNextBtnsFlex())
                                btn.props.textColor = config.data.ui.selectionColor
                            end

                            for i, reqs in ipairs(nextData.requirements) do
                                variantBtnFlex.content:add(interval(12, 0))
                                variantBtnFlex.content:add(
                                    button{
                                        text = string.format("-%d-", i),
                                        textSize = params.fontSize,
                                        parentScrollBoxUserData = self.params.parentScrollBoxUserData,
                                        updateFunc = params.updateFunc,
                                        event = function (layout)
                                            local reqFlex = self:getRequirementsFlex()
                                            reqFlex.content = ui.content{
                                                interval(0, self.params.fontSize / 2)
                                            }
                                            local posFlex = self:getObjectsFlex()
                                            posFlex.content = ui.content{
                                                interval(0, self.params.fontSize / 2)
                                            }

                                            ---@type questGuider.ui.buttonMeta
                                            local btnMeta = layout.userData.meta
                                            local btn = btnMeta:getButtonTextElement()
                                            if btn then
                                                resetColorOfButtons(self:getHeaderVariantBtnsFlex())
                                                btn.props.textColor = config.data.ui.selectionColor
                                            end

                                            addObjectPositionInfo(posFlex.content, reqs, diaId, nextData.index)
                                            addRequirements(reqFlex.content, reqs)

                                            params.updateHeightFunc()
                                        end,
                                    }
                                )
                            end

                            params.updateHeightFunc()
                            self:update()
                        end,
                    }
                )

                ::continue::
            end
        end
    end

    addNextStageButtons(nextStageData.next, "-%d-")
    addNextStageButtons(nextStageData.linked, "(%d)")

    self.params.updateHeightFunc()
end


---@class questGuider.ui.nextStages.params
---@field size any util.vector2
---@field fontSize integer
---@field data questGuider.main.fillQuestBoxQuestInfo.returnBlock
---@field isQuestListMode boolean?
---@field hideTrackButtons boolean?
---@field parentScrollBoxUserData table?
---@field updateFunc function
---@field updateHeightFunc function


---@param params questGuider.ui.nextStages.params
function this.create(params)

    ---@class questGuider.ui.nextStagesMeta
    local meta = setmetatable({}, nextStagesMeta)

    meta.update = function (self)
        params.updateFunc()
    end

    meta.data = params.data
    meta.params = params

    local nextBtnsFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
        content = ui.content{}
    }
    meta:_fill(nextBtnsFlex.content)

    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content {
                    {
                        template = templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                            text = params.isQuestListMode and l10n("requirementsColon") or l10n("nextColon"),
                            textColor = config.data.ui.defaultColor,
                            autoSize = true,
                            textSize = params.fontSize or 18,
                            multiline = false,
                            wordWrap = false,
                        },
                    },
                    nextBtnsFlex,
                }
            },
            interval(0, 4),
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = true,
                    horizontal = true,
                },
                content = ui.content{}
            }
        }
    }

    local requirementFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {

        }
    }

    local objectsFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {

        }
    }

    local mainFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
        },
        content = ui.content {
            header,
            objectsFlex,
            requirementFlex,
        }
    }

    meta.getLayout = function (self)
        return mainFlex
    end

    meta.data = nil

    return mainFlex
end


return this