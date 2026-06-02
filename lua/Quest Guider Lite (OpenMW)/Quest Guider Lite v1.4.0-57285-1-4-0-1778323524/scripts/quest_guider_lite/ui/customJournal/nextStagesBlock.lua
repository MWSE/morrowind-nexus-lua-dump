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

local playerQuests = require("scripts.quest_guider_lite.playerQuests")
local tracking = require("scripts.quest_guider_lite.trackingLocal")

local log = require("scripts.quest_guider_lite.utils.log")

local trackingElementLib = require("scripts.quest_guider_lite.ui.customJournal.objectTrackingElem")

local scrollBox = require("scripts.quest_guider_lite.ui.scrollBox")
local interval = require("scripts.quest_guider_lite.ui.interval")
local button = require("scripts.quest_guider_lite.ui.button")
local buttonBlock = require("scripts.quest_guider_lite.ui.buttonBlock")
local mapMenu = require("scripts.quest_guider_lite.ui.mapMenu")

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


---@param nextBtnsMeta questGuider.ui.buttonBlockMeta
function nextStagesMeta._fill(self, nextBtnsMeta)
    local params = self.params

    local nextStageData = self.data

    ---@type table<string, questGuider.quest.getRequirementPositionData.returnData>
    local objectPositions = nextStageData.objectPositions

    ---@param requirements questGuider.quest.getDescriptionDataFromBlock.returnArr[]
    local function addRequirements(content, requirements)
        local text = ""
        for _, req in ipairs(requirements) do
            text = string.format("%s  %s\n", text, req.str)
        end
        local textHeight = uiUtils.getTextHeight(text, params.fontSize or 18, self.params.size.x, config.data.journal.textHeightMulRecord, 1)
        content:add{
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
        local meta = flex.userData.meta

        for _, elem in pairs(meta.buttons) do
            ---@type questGuider.ui.buttonMeta
            local m = elem.userData and elem.userData.meta
            if m then
                local textElem = m:getButtonTextElement()
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

                nextBtnsMeta:add{
                    text = string.format(format, tostring(nextData.index)),
                    textSize = params.fontSize,
                    parentScrollBoxUserData = self.params.parentScrollBoxUserData,
                    updateFunc = params.updateFunc,
                    tooltipContent = ui.content{
                        {
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

                        local variantBtnBlockFlex = buttonBlock.new{
                            width = params.size.x - stringLib.length(l10n("variantsColon")) * config.data.journal.textHeightMulRecord * config.data.ui.fontSize,
                            anchor = util.vector2(0, 0),
                            customWidthMul = 0.5,
                            updateFunc = params.updateFunc,
                        }
                        local variantBtnBlockMeta = variantBtnBlockFlex.userData.meta

                        variantBtnFlex.content = ui.content{
                            {
                                type = ui.TYPE.Text,
                                props = {
                                    text = l10n("variantsColon"),
                                    textColor = config.data.ui.defaultColor,
                                    autoSize = true,
                                    textSize = params.fontSize or 18,
                                    anchor = util.vector2(0, 0.5),
                                    multiline = false,
                                    wordWrap = false,
                                },
                            },
                            variantBtnBlockFlex,
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
                            variantBtnBlockMeta:add{
                                text = string.format("-%d-", i),
                                textSize = params.fontSize,
                                anchor = util.vector2(0, 0.5),
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
                                        resetColorOfButtons(self:getHeaderVariantBtnsFlex().content[2])
                                        btn.props.textColor = config.data.ui.selectionColor
                                    end

                                    trackingElementLib.addObjectPositionInfo(posFlex.content, {
                                        diaId = diaId,
                                        diaIndex = nextData.index,
                                        reqs = reqs,
                                        objPoss = nextStageData.objectPositions,
                                        width = self.params.size.x,
                                        fontSize = config.data.ui.fontSize,
                                        parentScrollBoxUserData = self.params.parentScrollBoxUserData,
                                        hideTrackButtons = self.params.hideTrackButtons,
                                        parentContent = self:getLayout().content,
                                        updateFunc = self.update
                                    })

                                    addRequirements(reqFlex.content, reqs)

                                    params.updateHeightFunc()
                                end,
                            }
                        end

                        params.updateHeightFunc()
                        self:update()
                    end
                }

                ::continue::
            end
        end
    end

    addNextStageButtons(nextStageData.next, "-%d-")
    if not self.params.hideLinkedButtons then
        addNextStageButtons(nextStageData.linked, "(%d)")
    end

    self.params.updateHeightFunc()
end


---@class questGuider.ui.nextStages.params
---@field size any util.vector2
---@field fontSize integer
---@field data questGuider.main.fillQuestBoxQuestInfo.returnBlock
---@field isQuestListMode boolean?
---@field hideTrackButtons boolean?
---@field hideLinkedButtons boolean?
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

    local nextBtnsFlex = buttonBlock.new{
        width = params.size.x - stringLib.length(l10n("nextColon")) * config.data.journal.textHeightMulRecord * config.data.ui.fontSize,
        anchor = util.vector2(0, 0),
        customWidthMul = 0.5,
        updateFunc = params.updateFunc,
    }
    local nextBtnsMeta = nextBtnsFlex.userData.meta

    meta:_fill(nextBtnsMeta)

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
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
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
                    arrange = ui.ALIGNMENT.Center,
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