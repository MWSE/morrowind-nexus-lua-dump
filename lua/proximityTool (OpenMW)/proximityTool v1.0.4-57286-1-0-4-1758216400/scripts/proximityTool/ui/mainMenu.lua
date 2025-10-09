local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local playerObj = require('openmw.self')
local camera = require('openmw.camera')
local vfs = require('openmw.vfs')
local UI = require('openmw.interfaces').UI
local input = require('openmw.input')

local commonData = require("scripts.proximityTool.common")

local config = require("scripts.proximityTool.config")

local uniqueId = require("scripts.proximityTool.uniqueId")
local tableLib = require("scripts.proximityTool.utils.table")

local uiUtils = require("scripts.proximityTool.ui.utils")

local log = require("scripts.proximityTool.utils.log")

local icons = require("scripts.proximityTool.icons")

local activeObjects = require("scripts.proximityTool.activeObjects")
local activeMarkers = require("scripts.proximityTool.activeMarkers")
local cellLib = require("scripts.proximityTool.cell")

local safeContainers = require("scripts.proximityTool.ui.safeContainer")

local tooltip = require("scripts.proximityTool.ui.tooltip")
local tooltipFuncs = require("scripts.proximityTool.ui.mainMenuTooltip")

local addButton = require("scripts.proximityTool.ui.button")
local addInterval = require("scripts.proximityTool.ui.interval")

local l10n = core.l10n(commonData.l10nKey)


local this = {}

local elementRelPos = util.vector2(config.data.ui.positionInMenu.x / 100, config.data.ui.positionInMenu.y / 100)

this.hiddenGroupElement = {
    userData = {
        groupName = commonData.hiddenGroupId,
    },
    content = ui.content{}
}

this.element = nil
---@type proximityTool.elementSafeContainer
this.tooltip = nil
---@type {content : any}
this.markerElementsData = nil
this.maxLines = math.huge

local mainMenuSafeContainer = safeContainers.new("mainMenu")
local markerParentElement = nil


local function getNexUpdateTimestamp(val)
    return val + config.data.objectPosUpdateInterval * (1 + (math.random() - 0.5) * 0.5)
end


local function getMainFlex()
    if not this.element or not this.element.layout then return end

    if markerParentElement then
        return markerParentElement
    else
        markerParentElement = this.element.layout.content[1].content[2].content[1]
        return markerParentElement
    end
end


local function getMarkerParentElement(groupName)
    if not this.element or not this.element.layout then return end

    if markerParentElement and not groupName then
        return this.markerElementsData
    elseif groupName == commonData.hiddenGroupId then
        return this.hiddenGroupElement
    elseif groupName then
        local parent = this.markerElementsData
        if not parent then return end

        local index = parent.content:indexOf(groupName)
        if not index then return end

        return parent.content[index].content[2]
    else
        return this.markerElementsData
    end
end


local function onMouseWheelCallback(layout, value)
    if not layout.userData or not layout.userData.inFocus then return end
    local scrollEvents = this.element.layout.userData.scrollEvents

    if value > 0 then
        scrollEvents:scrollUp(config.data.ui.mouseScrollAmount)
    elseif value < 0 then
        scrollEvents:scrollDown(config.data.ui.mouseScrollAmount)
    end
end


---@param groupName string
---@param params {priority : number?, protected : boolean?}?
local function createGroup(groupName, params)
    if not params then params = {} end

    if groupName == commonData.hiddenGroupId then
        this.hiddenGroupElement.content = ui.content{}
        return
    end

    local parent = getMarkerParentElement()
    if not parent or not parent.content then return end

    local parentContent = parent.content

    local parentIndex = parentContent:indexOf(groupName)
    if parentIndex then return end

    local groupNameText = groupName
    local groupNameFontSize = config.data.ui.fontSize * 1.1
    local strLen = utf8.len(groupName) or string.len(groupName)
    if strLen > 0 and string.sub(groupName, 1, 1) == "~"
            or groupNameText == commonData.hiddenGroupId or groupNameText == commonData.defaultGroupId then
        groupNameText = ""
        groupNameFontSize = 1
    end

    local uiData = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            autoSize = true,
            arrange = uiUtils.convertAlign(config.data.ui.align),
            alpha = 0,
            visible = true,
        },
        userData = {
            isGroupParent = true,
            isProtected = params.protected,
            priority = params.priority or 0,
            orderIndex = 0,
            orderCounter = 0,
            alpha = config.data.ui.maxAlpha * 0.01,
            groupName = groupName,
        },
        name = groupName,
        content = ui.content{
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text = groupNameText,
                    textSize = groupNameFontSize,
                    textColor = config.data.ui.defaultColor,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = uiUtils.convertAlign(config.data.ui.align),
                    textShadow = true,
                    textShadowColor = util.color.rgb(0, 0, 0),
                },
                userData = {

                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    position = util.vector2(0, 0),
                    autoSize = true,
                    horizontal = false,
                    arrange = uiUtils.convertAlign(config.data.ui.align),
                },
                userData = {
                    groupName = groupName,
                },
                content = ui.content {

                },
            },
            addInterval(8, config.data.ui.fontSize),
        },
    }

    parentContent:add(uiData)
end


---@param activeMarker proximityTool.activeMarker
function this.registerMarker(activeMarker)
    if not activeMarker or not this.element then return end

    local elementId = activeMarker.markerId or uniqueId.get()

    activeMarker.markerId = elementId

    ---@type proximityTool.activeMarkerData
    local topRecord = activeMarker.topMarker

    local scrollEvents = this.element.layout.userData.scrollEvents

    local unitedEvents = {
        mouseMove = async:callback(function(e, layout)
            tooltipFuncs.tooltipMoveOrCreate(e, layout)
            scrollEvents:mouseMove(e)
        end),

        focusLoss = async:callback(function(e, layout)
            tooltipFuncs.tooltipDestroy(layout)
            scrollEvents:focusLoss(e)

            if layout.userData then
                layout.userData.mouseClicked = nil
            end
        end),

        mousePress = async:callback(function(e, layout)
            scrollEvents:mousePress(e)

            if layout.userData then
                layout.userData.mouseClicked = true
            end
        end),

        mouseRelease = async:callback(function(e, layout)
            scrollEvents:mouseRelease(e)

            if not layout.userData or not layout.userData.data
                    or scrollEvents.lastMovedDistance >= 30 or not layout.userData.mouseClicked
                    or input.isAltPressed() then
                return
            end
            local activeM = layout.userData.data
            activeM:triggerEvent("MouseClick", e)
        end),
    }


    local eventsForRecord = {
        mouseMove = async:callback(function(e, layout)
            tooltipFuncs.tooltipMoveOrCreate(e, layout, true)
            scrollEvents:mouseMove(e)
        end),

        focusLoss = async:callback(function(e, layout)
            tooltipFuncs.tooltipDestroy(layout)
            scrollEvents:focusLoss(e)

            if layout.userData then
                layout.userData.mouseClicked = nil
            end
        end),

        mousePress = async:callback(function(e, layout)
            scrollEvents:mousePress(e)

            if layout.userData then
                layout.userData.mouseClicked = true
            end
        end),

        mouseRelease = async:callback(function(e, layout)
            scrollEvents:mouseRelease(e)

            if not layout.userData or not layout.userData.aMarkerData
                or scrollEvents.lastMovedDistance >= 30
                or input.isAltPressed() then
                    return
            end
            activeMarkers.triggerEventForMarkerData(layout.userData.aMarkerData, "MouseClick", e)
        end),
    }

    local nameColorData = topRecord.record.nameColor
    local nameColor = nameColorData and util.color.rgb(nameColorData[1] or 1, nameColorData[2] or 1, nameColorData[3] or 1) or config.data.ui.defaultColor

    local mainLine = {
        {
            template = I.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                text = "",
                textSize = config.data.ui.fontSize,
                textColor = config.data.ui.defaultColor,
                multiline = false,
                wordWrap = false,
                textAlignH = ui.ALIGNMENT.End,
                textAlignV = ui.ALIGNMENT.Start,
                visible = activeMarker.type ~= 16,
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
            },
            userData = {
                data = activeMarker,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = icons.arrowIcons[1],
                size = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize),
                color = config.data.ui.defaultColor,
                visible = activeMarker.type ~= 16,
            },
            userData = {
                data = activeMarker,
            },
        },
        {
            template = I.MWUI.templates.interval,
            userData = {
                data = activeMarker,
                visible = activeMarker.type ~= 16,
            },
        },
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            userData = {
                data = activeMarker,
            },
            content = ui.content {}
        },
        {
            template = I.MWUI.templates.interval,
            userData = {
                data = activeMarker,
            },
        },
        {
            type = ui.TYPE.Text,
            userData = {
                data = activeMarker,
            },
            props = {
                text = topRecord.name,
                textSize = config.data.ui.fontSize,
                multiline = false,
                wordWrap = false,
                textAlignH = ui.ALIGNMENT.End,
                textColor = nameColor,
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
            },
        },
    }

    local content = {
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = uiUtils.convertAlign(config.data.ui.align),
                alpha = 1,
                propagateEvents = false,
            },
            userData = {
                data = activeMarker,
                distanceIndex = 1,
                directionIconIndex = 2,
                textIndex = 6,
                onMouseWheel = onMouseWheelCallback,
            },
            events = unitedEvents,
            content = nil
        },
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = uiUtils.convertAlign(config.data.ui.align),
                alpha = 1,
            },
            content = ui.content{},
        }
    }

    ---@type proximityTool.activeMarkerData[]
    local sortedRecords = tableLib.values(activeMarker.markers, function (a, b)
        return (a.record.priority or 0) > (b.record.priority or 0)
    end)

    for _, rDt in ipairs(sortedRecords) do
        local rec = rDt.record

        local noteContent

        if rec.note and rec.alpha ~= 0 then
            rDt.noteId = uniqueId.get()

            local noteColor = rec.noteColor and
                util.color.rgb(rec.noteColor[1] or 1, rec.noteColor[2] or 1, rec.noteColor[3] or 1) or config.data.ui.defaultColor

            noteContent = ui.content {}

            noteContent:add {
                type = ui.TYPE.Text,
                name = rDt.noteId,
                props = {
                    text = tostring(rec.note):sub(1, 50),
                    textColor = noteColor,
                    textSize = config.data.ui.fontSize,
                    multiline = false,
                    wordWrap = false,
                    visible = true,
                    textAlignH = ui.ALIGNMENT.End,
                    propagateEvents = false,
                },
                events = eventsForRecord,
                userData = {
                    recordId = rDt.recordId,
                    record = rDt.record,
                    aMarkerData = rDt,
                    data = activeMarker,
                    onMouseWheel = onMouseWheelCallback,
                },
            }

            content[2].content:add{
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    propagateEvents = false,
                },
                userData = {
                    recordId = rDt.recordId,
                    record = rDt.record,
                    aMarkerData = rDt,
                    onMouseWheel = onMouseWheelCallback,
                },
                events = eventsForRecord,
                content = noteContent,
            }
        end

        if rec.icon and vfs.fileExists(rec.icon) then
            local texture = ui.texture{path = rec.icon}
            local iconColor = rec.iconColor and util.color.rgb(rec.iconColor[1] or 1, rec.iconColor[2] or 1, rec.iconColor[3] or 1) or nil
            local name = rec.icon..tostring(iconColor)

            local size = {config.data.ui.fontSize, config.data.ui.fontSize}
            local iconRatio = rec.iconRatio or 1
            if iconRatio > 1 then
                size[1] = size[1] / iconRatio
            else
                size[2] = size[2] * iconRatio
            end

            local iconSize = util.vector2(math.floor(size[1]), math.floor(size[2]))

            local iconContent = {
                type = ui.TYPE.Image,
                props = {
                    resource = texture,
                    size = iconSize,
                    color = iconColor,
                    propagateEvents = false,
                },
                name = name,
                events = eventsForRecord,
                userData = {
                    recordId = rDt.recordId,
                    record = rDt.record,
                    aMarkerData = rDt,
                    data = activeMarker,
                },
            }

            if noteContent and (not rec.options or rec.options.showNoteIcon ~= false) then
                noteContent:add(iconContent)
                noteContent:add{
                    template = I.MWUI.templates.interval,
                    props = {
                        propagateEvents = false,
                    },
                    events = eventsForRecord,
                }
            end

            if (not rec.options or rec.options.showGroupIcon ~= false) and #mainLine[4].content < 6 then
                local index = mainLine[4].content:indexOf(name)
                if index then
                    local elem = mainLine[4].content[index]
                    ---@type proximityTool.markerRecord
                    local record = elem.userData.record
                    if record and (record.priority or 0) < (rec.priority or 0) then
                        elem.userData.record = rec
                        elem.userData.recordId = rDt.recordId
                        elem.userData.aMarkerData = rDt
                        elem.props.resource = texture
                    end
                else
                    mainLine[4].content:add(iconContent)
                end
            end
        end
    end

    if config.data.ui.orderH == "Right to left" then
        mainLine = tableLib.invertIndexes(mainLine)
        content[1].userData.distanceIndex = 6
        content[1].userData.directionIconIndex = 5
    end
    content[1].content = ui.content(mainLine)

    local uiData = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = uiUtils.convertAlign(config.data.ui.align),
            alpha = 0,
            visible = true,
        },
        userData = {
            data = activeMarker,
        },
        name = elementId,
        content = ui.content(content),
    }

    local function updateInGroupIfExists(grName)
        local grContent = (getMarkerParentElement(grName) or {}).content
        if not grContent then return end

        local grIndex = grContent:indexOf(elementId)
        if grIndex then
            grContent[grIndex] = uiData
            return grIndex
        end
    end

    local groupName = activeMarker.groupName

    if not updateInGroupIfExists(groupName) and not updateInGroupIfExists(commonData.hiddenGroupId) then
        createGroup(groupName)
        local parentContent = (getMarkerParentElement(groupName) or {}).content
        if not parentContent then return end

        parentContent:add(uiData)
    end
end


local function mainWindowBox(content, showBorder, userData)
    return {
        template = showBorder and I.MWUI.templates.boxSolid or nil,
        type = not showBorder and ui.TYPE.Flex or nil,
        props = {
            autoSize = true,
            inheritAlpha = false,
        },
        userData = userData,
        content = ui.content(content),
    }
end


local function setMainBoxVisibility(state)
    if not this.element then return end

    this.element.layout.props.alpha = state and 1 or 0
end


function this.create(params)
    if not params then params = {} end
    if this.element then
        markerParentElement = nil
        this.element:destroy()
        mainMenuSafeContainer.element = nil
        this.markerElementsData = nil
    end

    if config.data.ui.hideHUD and not params.showBorder then return end
    if config.data.ui.hideWindow and params.showBorder then return end

    local screenSize = uiUtils.getScaledScreenSize()

    local mainContent

    local scrollEvents = {}
    scrollEvents.__index = scrollEvents

    function scrollEvents.scrollUp(self, val)
        local pos = mainContent.content[1].props.position
        if not pos then return end

        mainContent.content[1].props.position = util.vector2(0, math.min(0, pos.y + val))
        this.element:update()
    end

    function scrollEvents.scrollDown(self, val)
        local pos = mainContent.content[1].props.position
        if not pos then return end

        mainContent.content[1].props.position = util.vector2(0, pos.y - val)
        this.element:update()
    end

    scrollEvents.lastMovedDistance = 0

    scrollEvents.mousePress = function (self, e)
        if e.button ~= 1 then return end
        local layout = mainContent.content[1]
        layout.userData.lastMousePos = util.vector2(e.position.x, e.position.y)
        self.lastMovedDistance = 0
    end

    scrollEvents.mouseRelease = function (self, e)
        if e.button ~= 1 then return end
        local layout = mainContent.content[1]
        layout.userData.lastMousePos = nil
    end

    scrollEvents.focusLoss = function (self, e)
        local layout = mainContent.content[1]
        layout.userData.lastMousePos = nil
        layout.userData.inFocus = false
        self.lastMovedDistance = 0
    end

    scrollEvents.mouseMove = function (self, e)
        local layout = mainContent.content[1]
        layout.userData.inFocus = true
        if not layout.userData.lastMousePos then return end

        local posDIff = e.position - layout.userData.lastMousePos

        if posDIff.y > 0 then
            self:scrollUp(posDIff.y)
        elseif posDIff.y < 0 then
            self:scrollDown(-posDIff.y)
        end

        layout.userData.lastMousePos = e.position

        self.lastMovedDistance = self.lastMovedDistance + math.abs(posDIff.x) + math.abs(posDIff.y) ---@diagnostic disable-line: need-check-nil
    end

    scrollEvents = setmetatable({}, scrollEvents)


    local function getScrollEvents()
        return {
            mousePress = async:callback(function(e, layout)
                scrollEvents:mousePress(e)
            end),

            mouseRelease = async:callback(function(e, layout)
                scrollEvents:mouseRelease(e)
            end),

            focusLoss = async:callback(function(e, layout)
                scrollEvents:focusLoss(e)
            end),

            mouseMove = async:callback(function(e, layout)
                scrollEvents:mouseMove(e)
            end),
        }
    end


    mainContent = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    position = util.vector2(0, 0),
                    autoSize = true,
                    horizontal = false,
                    arrange = uiUtils.convertAlign(config.data.ui.align),
                },
                userData = {
                    onMouseWheel = onMouseWheelCallback,
                },
                events = getScrollEvents(),
                content = ui.content {

                },
            }
        },
    }

    local isMainHidden = params.showBorder and config.data.ui.minimizeToAnchor or false

    local parentContent

    local headerHeight = config.data.ui.fontSize * 1.2 + 6

    local trackingLabelText = l10n("trackingAnchor")
    trackingLabelText = config.data.ui.orderH == "Right to left" and " "..trackingLabelText or trackingLabelText.." "

    local headerContentArr

    local function setHeaderContentVisibility(isVisible)
        for _, elem in pairs(headerContentArr or {}) do
            if elem.props and (not elem.userData or not elem.userData.isHeader) then
                elem.props.visible = isVisible
            end
        end
    end

    headerContentArr = {
        addButton{menu = this, textSize = config.data.ui.fontSize, text = "P", textColor = config.data.ui.defaultColor,
            event = function (layout)
                local position = this.element.layout.props.relativePosition
                config.setValue("ui.position.x", position.x * 100)
                config.setValue("ui.position.y", position.y * 100)
            end,
            tooltipContent = config.data.ui.helpTooltips and ui.content {
                {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = l10n("setPosition"),
                        textSize = config.data.ui.fontSize,
                        textColor = config.data.ui.defaultColor,
                    },
                }
            }
        },
        addInterval(config.data.ui.fontSize / 2, config.data.ui.fontSize / 2),
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
            },
            content = ui.content{
                -- addButton{menu = this, textSize = config.data.ui.fontSize, text = "|<", textColor = config.data.ui.defaultColor,
                --     event = function (layout)
                --         local pos = mainContent.content[1].props.position
                --         if not pos then return end

                --         mainContent.content[1].props.position = util.vector2(0, 0)
                --         this.element:update()
                --     end,
                --     tooltipContent = config.data.ui.helpTooltips and ui.content {
                --         {
                --             template = I.MWUI.templates.textNormal,
                --             props = {
                --                 text = l10n("scrollToStart"),
                --                 textSize = config.data.ui.fontSize,
                --                 textColor = config.data.ui.defaultColor,
                --             },
                --         }
                --     }
                -- },
                -- addInterval(config.data.ui.fontSize / 2, config.data.ui.fontSize / 2),
                addButton{menu = this, textSize = config.data.ui.fontSize, text = "<<", textColor = config.data.ui.defaultColor,
                    event = function (layout)
                        scrollEvents:scrollUp(config.data.ui.fontSize * 2)
                    end,
                    intervalEvent = function (layout)
                        scrollEvents:scrollUp(config.data.ui.fontSize)
                    end,
                    tooltipContent = config.data.ui.helpTooltips and ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n("scrollUp"),
                                textSize = config.data.ui.fontSize,
                                textColor = config.data.ui.defaultColor,
                            },
                        }
                    }
                },
                addInterval(config.data.ui.fontSize / 2, config.data.ui.fontSize / 2),
                addButton{menu = this, textSize = config.data.ui.fontSize, text = ">>", textColor = config.data.ui.defaultColor,
                    event = function (layout)
                        scrollEvents:scrollDown(config.data.ui.fontSize * 2)
                    end,
                    intervalEvent = function (layout)
                        scrollEvents:scrollDown(config.data.ui.fontSize)
                    end,
                    tooltipContent = config.data.ui.helpTooltips and ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = l10n("scrollDown"),
                                textSize = config.data.ui.fontSize,
                                textColor = config.data.ui.defaultColor,
                            },
                        }
                    }
                },
            },
        },
        addInterval(config.data.ui.fontSize, config.data.ui.fontSize),
        mainWindowBox({
            {
                template = I.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                props = {
                    text = trackingLabelText,
                    textSize = config.data.ui.fontSize * 1.2,
                    textColor = config.data.ui.defaultColor,
                    multiline = false,
                    wordWrap = false,
                    textAlignH = uiUtils.convertAlign(config.data.ui.align),
                    textShadow = true,
                    textShadowColor = util.color.rgb(0, 0, 0),
                },
                userData = {
                    lastMousePos = nil,
                    lastMousePropPos = nil,
                    movedDistance = 0
                },
                events = {
                    mousePress = async:callback(function(coord, layout)
                        layout.userData.doDrag = false
                        local screenSize = uiUtils.getScaledScreenSize()
                        layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
                        layout.userData.lastMousePos = util.vector2(coord.position.x, coord.position.y)
                        layout.userData.lastMousePropPos = layout.userData.lastMousePos:ediv(screenSize)
                        layout.userData.movedDistance = 0
                    end),

                    mouseRelease = async:callback(function(_, layout)
                        layout.userData.lastMousePos = nil
                        layout.userData.lastMousePropPos = nil
                        if not layout.userData.doDrag or layout.userData.movedDistance < 30 then
                            if isMainHidden then
                                parentContent[1].props.size = util.vector2(screenSize.x * config.data.ui.size.x / 100, screenSize.y * config.data.ui.size.y / 100)
                            else
                                parentContent[1].props.size = util.vector2(screenSize.x * config.data.ui.size.x / 100, headerHeight)
                            end

                            setMainBoxVisibility(isMainHidden)
                            setHeaderContentVisibility(isMainHidden)
                            isMainHidden = not isMainHidden
                            config.setLocal("ui.minimizeToAnchor", isMainHidden)
                            this.element:update()
                        end
                        layout.userData.doDrag = false
                        layout.userData.movedDistance = 0
                    end),

                    mouseMove = async:callback(function(coord, layout)
                        if config.data.ui.helpTooltips then
                            tooltip.createOrMove(coord, layout, ui.content {
                                {
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = l10n("trackingAnchorTooltip"),
                                        textSize = config.data.ui.fontSize,
                                        textColor = config.data.ui.defaultColor,
                                    },
                                }
                            })
                        end

                        if not layout.userData.lastMousePos then return end

                        local diff = coord.position - layout.userData.lastMousePos
                        layout.userData.movedDistance = layout.userData.movedDistance + math.abs(diff.x) + math.abs(diff.y)
                        layout.userData.lastMousePos = coord.position

                        if layout.userData.movedDistance < 30 then return end

                        layout.userData.doDrag = true

                        local screenSize = uiUtils.getScaledScreenSize()
                        local props = this.element.layout.props
                        local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

                        props.relativePosition = props.relativePosition - (layout.userData.lastMousePropPos - relativePos)
                        elementRelPos = props.relativePosition
                        config.setLocal("ui.positionInMenu.x", elementRelPos.x * 100)
                        config.setLocal("ui.positionInMenu.y", elementRelPos.y * 100)

                        this.element:update()

                        layout.userData.lastMousePropPos = relativePos
                    end),

                    focusLoss = async:callback(function(e, layout)
                        tooltip.destroy(layout)
                    end),
                },
            }
        }, params.showBorder, {isHeader = true}),
    }

    setHeaderContentVisibility(not isMainHidden)

    if config.data.ui.orderH == "Right to left" then
        headerContentArr = tableLib.invertIndexes(headerContentArr)
    end

    local header = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            visible = config.data.ui.showHeader or params.showBorder,
            propagateEvents = false,
        },
        content = ui.content(headerContentArr)
    }

    local parantContentHeight
    if isMainHidden then
        parantContentHeight = util.vector2(screenSize.x * config.data.ui.size.x / 100, headerHeight)
    else
        parantContentHeight = util.vector2(screenSize.x * config.data.ui.size.x / 100, screenSize.y * config.data.ui.size.y / 100)
    end
    parentContent = {
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = parantContentHeight,
                horizontal = false,
                arrange = uiUtils.convertAlign(config.data.ui.align),
            },
            userData = {
                onMouseWheel = onMouseWheelCallback,
            },
            events = getScrollEvents(),
            content = ui.content {
                header,
                mainContent,
            },
        },
    }

    local position
    if params.showBorder and elementRelPos then
        position = elementRelPos
    else
        position = util.vector2(config.data.ui.position.x / 100, config.data.ui.position.y / 100)
    end

    local base = mainWindowBox(parentContent, params.showBorder, {})
    base.props = {
        autoSize = true,
        horizontal = false,
        arrange = uiUtils.convertAlign(config.data.ui.align),
        relativePosition = position,
        anchor = util.vector2(1, 0),
        alpha = isMainHidden and 0 or 1,
        visible = params.showBorder or UI.isHudVisible(),
    }
    base.layer = params.showBorder and "Windows" or "HUD"
    base.userData.scrollEvents = scrollEvents

    this.maxLines = not params.showBorder and math.ceil(screenSize.y * config.data.ui.size.y / 100 / config.data.ui.fontSize) or 999

    this.element = ui.create(base)
    this.markerElementsData = {content = ui.content {}}

    mainMenuSafeContainer.element = this.element

    createGroup(commonData.defaultGroupId)
    createGroup(commonData.hiddenGroupId, {priority = -math.huge, protected = true})

    for _, activeMarker in pairs(activeMarkers.data) do
        this.registerMarker(activeMarker)
    end
end




local function getAdditionalPriorityByDistance(distance)
    local res = 0
    if distance < 200 then
        res = 200
    elseif distance < 8000 then
        res = math.floor((10000 - distance) / 2000) * 30
    elseif distance > 10000 then
        res = -math.floor(distance / 10000) * 20
    end

    return res
end



---@class objectTrackingBD.mainMenu.update.params
---@field force boolean?

---@param params objectTrackingBD.mainMenu.update.params?
function this.update(params)
    if not this.element then return end
    if not params then params = {} end

    local visible = this.element.layout.layer ~= "HUD" or UI.isHudVisible()
    if visible ~= this.element.layout.props.visible then
        this.element.layout.props.visible = visible
        this.element:update()
        return
    end

    local parentElement = getMarkerParentElement()
    local hiddenGroupElement = getMarkerParentElement(commonData.hiddenGroupId)
    if not parentElement or not hiddenGroupElement then return end

    local timestamp = core.getRealTime()

    local player = playerObj.object
    local playerPos = player.position
    local cameraPos = camera.getPosition()
    local cameraYaw = camera.getYaw() + camera.getExtraYaw()

    local doUpdate = params.force or false

    local alphaAdditiveVal = params.force and 1 or config.data.updateInterval / 1500
    local alphaAdditiveValAlt = params.force and 1 or alphaAdditiveVal * 1.5

    local halfAlpha = params.force and 1 or config.data.ui.maxAlpha * 0.005

    local function orderAndOpacity(parent)
        local sortedData = {}
        for i, element in ipairs(parent.content) do
            local priority = element.userData.priority or 0
            table.insert(sortedData, {element = element, priority = priority})
        end
        table.sort(sortedData, function (a, b)
            return a.priority > b.priority
        end)

        for i = #parent.content, 1, -1 do
            local element = parent.content[i]
            if not element or not element.userData or not element.userData then goto continue end

            local disabled = element.userData.disabled

            if disabled then
                if element.props.visible then
                    element.props.alpha = params.force and 0 or element.props.alpha - alphaAdditiveVal
                    doUpdate = true
                    if element.props.alpha <= 0 then
                        element.userData.locked = true
                        element.props.alpha = 0
                        element.props.visible = false

                        uiUtils.removeFromContent(parent.content, i)
                        hiddenGroupElement.content:add(element)
                        goto continue
                    end
                end
            else
                local orderElemData = sortedData[i]

                if orderElemData then
                    local elem2 = orderElemData.element
                    local index = parent.content:indexOf(elem2)
                    if not index or math.floor(element.userData.priority or 0) == math.floor(elem2.userData.priority or 0) or
                        element.userData.disabled or elem2.userData.disabled then
                            goto nextAction
                    end

                    local alpha1 = element.props.alpha
                    if alpha1 > halfAlpha then
                        alpha1 = params.force and halfAlpha or math.max(0, alpha1 - alphaAdditiveValAlt)
                        element.props.alpha = alpha1
                        doUpdate = true
                    end

                    local alpha2 = elem2.props.alpha
                    if alpha2 > halfAlpha then
                        alpha2 = params.force and halfAlpha or math.max(0, alpha2 - alphaAdditiveValAlt)
                        elem2.props.alpha = alpha2
                        doUpdate = true
                    end

                    if alpha1 <= halfAlpha and alpha2 <= halfAlpha then
                        parent.content.__nameIndex[element.name], parent.content.__nameIndex[elem2.name] =
                            parent.content.__nameIndex[elem2.name], parent.content.__nameIndex[element.name]
                        parent.content[index], parent.content[i] = element, elem2
                        doUpdate = true
                    end

                    goto continue
                end

                ::nextAction::

                if element.userData.alpha then
                    if element.props.alpha < element.userData.alpha then
                        element.props.alpha = params.force and 1 or math.min(element.props.alpha + alphaAdditiveVal, element.userData.alpha)
                        doUpdate = true
                    elseif element.props.alpha > element.userData.alpha then
                        element.props.alpha = params.force and 0 or math.max(element.props.alpha - alphaAdditiveVal, element.userData.alpha)
                        doUpdate = true
                    end
                end

                if not element.props.visible then
                    element.props.visible = true
                    doUpdate = true
                end

                if parent.userData and parent.userData.groupName and parent.userData.groupName == commonData.hiddenGroupId then
                    local groupElement = getMarkerParentElement(element.userData.data.groupName)
                    if not groupElement then
                        createGroup(element.userData.data.groupName)
                        groupElement = getMarkerParentElement(element.userData.data.groupName)
                    end

                    if groupElement then
                        uiUtils.removeFromContent(parent.content, i)
                        groupElement.content:add(element)
                        doUpdate = true
                        goto continue
                    end
                end
            end

            ::continue::
        end
    end


    local function processGroup(contentOwner, parent)
        if not contentOwner then return end

        for i = #contentOwner.content, 1, -1 do
            local elem = contentOwner.content[i]
            if not elem or not elem.props or not elem.userData or not elem.userData.data then goto continue end

            elem.userData.locked = false

            ---@type proximityTool.activeMarker
            local trackingData = elem.userData.data

            if not trackingData.isValid then
                uiUtils.removeFromContent(contentOwner.content, i)
                doUpdate = true
                goto continue
            end

            ---@type proximityTool.activeMarkerData?
            local topMarkerRecord = trackingData.topMarker
            if not topMarkerRecord then
                uiUtils.removeFromContent(contentOwner.content, i)
                doUpdate = true
                goto continue
            end

            local trackingPos
            ---@type {object: any, position : any, dif : number?}[]
            local trackingPositionsData = {}

            if trackingData.nextUpdate < timestamp or not trackingData.lastTrackedObject then

                for _, markerRecord in pairs(trackingData.markers) do

                    local markerRecordData = markerRecord.marker
                    local filterDead = markerRecord.record.options and markerRecord.record.options.hideDead

                    local foundPos = false
                    local trackAllTypes = markerRecord.record.options and markerRecord.record.options.trackAllTypesTogether

                    if markerRecordData.object then
                        local objectRef = markerRecordData.object
                        local posData = activeObjects.getObjectPositionData(objectRef, nil, markerRecordData.itemId, filterDead)
                        if posData then
                            table.insert(trackingPositionsData, posData)
                            foundPos = true
                        end
                    end

                    if markerRecordData.objects then
                        local posData = activeObjects.getClosestReferencePosition(markerRecordData.objects, player, markerRecordData.itemId, filterDead)
                        if posData then
                            table.insert(trackingPositionsData, posData)
                            foundPos = true
                        end
                    end

                    if markerRecordData.objectId and (not foundPos or trackAllTypes) then
                        local trackedObjPosition = activeObjects.getClosestObjectPosition(markerRecordData.objectId, player, markerRecordData.itemId, filterDead)
                        if trackedObjPosition then
                            table.insert(trackingPositionsData, trackedObjPosition)
                            foundPos = true
                        end
                    end

                    if markerRecordData.objectIds and (not foundPos or trackAllTypes) then
                        local trackedObjPositions = activeObjects.getClosestObjectPositionsByGroupName(markerRecordData.id, player, markerRecordData.itemId, filterDead)
                        if trackedObjPositions and next(trackingPositionsData) then
                            table.sort(trackedObjPositions, function (a, b)
                                return (a.dif or math.huge) < (b.dif or math.huge)
                            end)
                        end

                        local pos = trackedObjPositions and trackedObjPositions[1]
                        if pos then
                            table.insert(trackingPositionsData, pos)
                            foundPos = true
                        end
                    end

                    if markerRecordData.positions and (not foundPos or trackAllTypes) then
                        local pos, distance = cellLib.getClosestPosition(markerRecordData.positions)

                        if pos then
                            table.insert(trackingPositionsData, {dif = distance, object = {position = pos}})
                            foundPos = true
                        end
                    end
                end

                if topMarkerRecord.type == 16 then
                    elem.userData.priority = trackingData.priority
                    local textIndex = elem.content[1].userData.textIndex
                    if elem.content[1].content[textIndex or 6].props.text ~= topMarkerRecord.record.name then
                        elem.content[1].content[textIndex or 6].props.text = topMarkerRecord.record.name
                        doUpdate = true
                    end
                    elem.userData.distance = 0
                    elem.userData.distance2D = 0
                    elem.userData.heightDiff = 0
                    elem.userData.alpha = params.force and 1 or math.min(trackingData.alpha, config.data.ui.maxAlpha * 0.01)
                    goto continue

                elseif not next(trackingPositionsData) then
                    uiUtils.removeFromContent(contentOwner.content, i)
                    doUpdate = true
                    goto continue
                end


                table.sort(trackingPositionsData, function (a, b)
                    return (a.dif or math.huge) < (b.dif or math.huge)
                end)
                local closest = trackingPositionsData[1]
                trackingPos = closest.object.position
                trackingData.lastTrackedObject = closest.object
                trackingData.nextUpdate = getNexUpdateTimestamp(timestamp)

            else
                trackingPos = trackingData.lastTrackedObject.position
            end

            if not trackingPos then
                uiUtils.removeFromContent(contentOwner.content, i)
                doUpdate = true
                goto continue
            end


            local distance = (playerPos - trackingPos):length()
            local distance2D = math.sqrt((playerPos.x - trackingPos.x)^2 + (playerPos.y - trackingPos.y)^2)
            local heightDiff = playerPos.z - trackingPos.z

            elem.userData.distance = distance
            elem.userData.distance2D = distance2D
            elem.userData.heightDiff = heightDiff
            elem.userData.alpha = params.force and 1 or math.min(trackingData.alpha, config.data.ui.maxAlpha * 0.01)

            local hide = (distance > trackingData.proximity) or (trackingData.alpha <= 0) or trackingData.hidden
            if elem.userData.disabled ~= hide then
                doUpdate = true
            end
            elem.userData.disabled = hide
            if not elem.props.visible and hide then
                goto continue
            end

            -- for ordering
            local priorityByDistance = getAdditionalPriorityByDistance(distance)

            elem.userData.priority = trackingData.priority + priorityByDistance
            if parent and not parent.userData.isProtected then
                parent.userData.priority = math.max(elem.userData.priority, parent.userData.priority)
            end

            local arrowImageIndex
            local iconImage

            if  distance2D < 200 then
                if heightDiff > 200 then
                    iconImage = icons.arrowIcons_P[3]
                elseif heightDiff < -200 then
                    iconImage = icons.arrowIcons_P[2]
                else
                    iconImage = icons.arrowIcons_P[1]
                end
            else
                local imageArr
                if heightDiff > 200 then
                    imageArr = icons.arrowIcons_B
                elseif heightDiff < -200 then
                    imageArr = icons.arrowIcons_A
                else
                    imageArr = icons.arrowIcons
                end

                local angle = util.normalizeAngle(cameraYaw - math.atan2(cameraPos.x - trackingPos.x, cameraPos.y - trackingPos.y) + math.pi * 1/16) ---@diagnostic disable-line: deprecated
                arrowImageIndex = 1 + util.round((math.pi + angle) / (2 * math.pi) * 7)
                iconImage = imageArr[arrowImageIndex]
            end

            local distanceIndex = elem.content[1].userData.distanceIndex
            local directionIndex = elem.content[1].userData.directionIconIndex
            local newText = config.data.ui.imperialUnits and string.format("%.0fft", distance / 21.33)
                    or string.format("%.0fm", distance / 69.99)
            if elem.content[1].content[distanceIndex or 1].props.text ~= newText then
                elem.content[1].content[distanceIndex or 1].props.text = newText
                doUpdate = true
            end
            if elem.content[1].content[directionIndex or 2].props.resource ~= iconImage then
                elem.content[1].content[directionIndex or 2].props.resource = iconImage
                doUpdate = true
            end

            ::continue::
        end

        orderAndOpacity(contentOwner)
    end


    for i = #parentElement.content, 1, -1 do
        local elem = parentElement.content[i]
        if not elem or not elem.userData or not elem.userData.groupName then goto continue end

        elem.userData.priority = -math.huge

        local contentElement = getMarkerParentElement(elem.userData.groupName)
        if not contentElement then goto continue end

        if not elem.userData.isProtected and #contentElement.content == 0 then
            uiUtils.removeFromContent(parentElement.content, i)
            doUpdate = true
            goto continue
        end

        processGroup(contentElement, elem)

        ::continue::
    end

    processGroup(hiddenGroupElement)

    orderAndOpacity(parentElement)

    if doUpdate then
        local mainFlex = getMainFlex()
        if mainFlex then
            mainFlex.content = ui.content{}
            local maxLines = this.maxLines or 999
            for i, groupData in ipairs(this.markerElementsData.content) do
                local group = tableLib.copy(groupData)
                group.content = ui.content{}
                for _, elem in ipairs(groupData.content) do
                    group.content:add(tableLib.copy(elem))
                end

                local content = ui.content{}
                group.content[2].content = content

                mainFlex.content:add(group)

                maxLines = maxLines - 1
                for i, elem in ipairs(groupData.content[2].content) do
                    if maxLines > 0 then
                        maxLines = maxLines - 1
                        content:add(elem)
                    else
                        goto endLabel
                    end
                end
                if maxLines <= 0 then goto endLabel end
            end

            ::endLabel::
        end
        this.element:update()
    end
end


function this.destroy()
    if this.element then
        markerParentElement = nil
        this.element:destroy()
        this.element = nil
        mainMenuSafeContainer.element = nil
    end
end


return this