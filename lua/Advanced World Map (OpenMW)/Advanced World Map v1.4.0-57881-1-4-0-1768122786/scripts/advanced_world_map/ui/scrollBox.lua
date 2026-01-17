local ui = require('openmw.ui')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local I = require('openmw.interfaces')
local templates = require("scripts.advanced_world_map.ui.templates")
local async = require('openmw.async')

local realTimer = require("scripts.advanced_world_map.realTimer")

local config = require("scripts.advanced_world_map.config.config")

local tableLib = require("scripts.advanced_world_map.utils.table")

local button = require("scripts.advanced_world_map.ui.button")

local iconUp = "textures/omw_menu_scroll_up.dds"
local iconDown = "textures/omw_menu_scroll_down.dds"

local whiteTexture = ui.texture { path = "white" }

---@class advancedWorldMap.ui.scrollBox
local scrollBoxMeta = {}
scrollBoxMeta.__index = scrollBoxMeta

scrollBoxMeta.getMainFlex = function (self)
    return self:getLayout().content[1]
end

scrollBoxMeta.scrollUp = function(self, val)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    fl.props.position = util.vector2(self.params.leftOffset, math.min(self.params.maxNegativeShift or (config.data.ui.scrollArrowSize * 2) or 32, pos.y + val))

    self:updateScrollPosition()

    self:update()
end

scrollBoxMeta.scrollDown = function(self, val)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    fl.props.position = util.vector2(self.params.leftOffset, pos.y - val)

    self:updateScrollPosition()

    self:update()
end

scrollBoxMeta.getSize = function(self)
    return self.innnerSize
end

scrollBoxMeta.getScrollPosition = function(self)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    return -pos.y
end

---@param height number
scrollBoxMeta.setScrollPosition = function(self, height)
    self:moveScrollPanel(height)
    self:updateScrollPosition()

    self:update()
end

---@param height number
scrollBoxMeta.moveScrollPanel = function(self, height)
    local fl = self:getMainFlex()
    local pos = fl.props.position
    if not pos then return end

    fl.props.position = util.vector2(self.params.leftOffset, math.min(self.params.maxNegativeShift or (config.data.ui.scrollArrowSize * 2) or 32, -height))
end

---@param value number [0, 1]
scrollBoxMeta.moveScrollPanelPercent = function(self, value)
    if not self.params.contentHeight then return end
    value = util.clamp(value, 0, 1)
    local fl = self:getMainFlex()
    local pos = fl.props.position

    local heightPersent = (self.params.contentHeight - self.innnerSize.y) * value

    fl.props.position = util.vector2(self.params.leftOffset, math.min(self.params.maxNegativeShift or (config.data.ui.scrollArrowSize * 2) or 32, -heightPersent))
end


scrollBoxMeta.clearContent = function (self)
    local mainFlex = self:getMainFlex()
    mainFlex.content = ui.content{}
end


---@param value number [0, 1]
scrollBoxMeta.moveScrollBar = function (self, value)
    value = util.clamp(value, 0, 1)
    local scrollBar = self.scrollBarElement

    scrollBar.props.position = util.vector2(
        scrollBar.props.position.x,
        self.scrollBarMinMax[1] + value * self.scrollBarMinMax[3]
    )
end

scrollBoxMeta.updateScrollPosition = function (self)
    if not self.params.contentHeight then return end
    local fl = self:getMainFlex()
    local pos = fl.props.position

    self:moveScrollBar(-fl.props.position.y / (self.params.contentHeight - self.innnerSize.y))
end

---@return number
scrollBoxMeta.getScrollBarPositionPercent = function (self)
    local scrollBar = self.scrollBarElement

    return (scrollBar.props.position.y - self.scrollBarMinMax[1]) / self.scrollBarMinMax[3]
end


---@param value number
scrollBoxMeta.setContentHeight = function (self, value)
    self.params.contentHeight = value
    self:updateScrollBarVisibility()
    self:updateScrollPosition()
end


scrollBoxMeta.lastMovedDistance = 0

scrollBoxMeta.mousePress = function (self, e)
    if e.button ~= 1 then return end
    local layout = self:getLayout()
    layout.userData.lastMousePos = util.vector2(e.position.x, e.position.y)
    self.lastMovedDistance = 0
end

scrollBoxMeta.mouseRelease = function (self, e)
    if e.button ~= 1 then return end
    local layout = self:getLayout()
    layout.userData.lastMousePos = nil
end

scrollBoxMeta.focusLoss = function (self, e)
    local layout = self:getLayout()
    layout.userData.lastMousePos = nil
    layout.userData.inFocus = false
    self.lastMovedDistance = 0
end

scrollBoxMeta.mouseMove = function (self, e)
    local layout = self:getLayout()
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


---@class advancedWorldMap.ui.scrollBox.params
---@field name string?
---@field size any -- util.vector2
---@field position any -- util.vector2
---@field scrollAmount integer?
---@field maxNegativeShift integer?
---@field leftOffset integer?
---@field content any
---@field contentHeight number?
---@field minHeightForScroll number?
---@field updateFunc fun()
---@field arrange any?
---@field userData table?


---@param params advancedWorldMap.ui.scrollBox.params
return function(params)
    if not params then return end

    ---@class advancedWorldMap.ui.scrollBox
    local meta = setmetatable({}, scrollBoxMeta)

    if not params.leftOffset then params.leftOffset = 2 end

    local flex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = false,
            size = params.size,
            position = util.vector2(params.leftOffset, 0),
            arrange = params.arrange,
        },
        content = params.content,
    }

    meta.update = function (self)
        params.updateFunc()
    end

    meta.innnerSize = util.vector2(params.size.x - 2 - params.leftOffset, params.size.y - 4)
    params.minHeightForScroll = params.minHeightForScroll or meta.innnerSize.y

    meta.params = params

    local lockEvent = false
    local timer
    local function stopScrollTimer()
        if timer then
            timer()
            timer = nil
        end
    end

    local function startScrollTimer(type, value)
        stopScrollTimer()

        local func
        func = function ()
            if type == 0 then
                meta:scrollUp(value)
            else
                meta:scrollDown(value)
            end
            lockEvent = true
            timer = realTimer.newTimer(0.2, func)
        end
        timer = realTimer.newTimer(1, func)
    end

    meta.scrollBarMinMax = {
        14 + config.data.ui.scrollArrowSize,
        meta.innnerSize.y - (10 + 4 * config.data.ui.scrollArrowSize),
    }
    meta.scrollBarMinMax[3] = meta.scrollBarMinMax[2] - meta.scrollBarMinMax[1]

    local contentData

    local scroll = {
        type = ui.TYPE.Image,
        props = {
            resource = whiteTexture,
            size = util.vector2(config.data.ui.scrollArrowSize, config.data.ui.scrollArrowSize * 3),
            anchor = util.vector2(1, 0),
            position = util.vector2(params.size.x - 8, meta.scrollBarMinMax[1]),
            alpha = 0.4,
            color = config.data.ui.defaultColor,
            visible = false,
        },
        userData = {

        },
        events = {
            mousePress = async:callback(function(e, layout)
                layout.userData.doDrag = true
                layout.userData.lastMousePos = e.position
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
            end),

            mouseMove = async:callback(function(e, layout)
                contentData.userData.inFocus = true
                if not layout.userData.lastMousePos then return end

                local props = layout.props
                local pos = e.position

                props.position = util.vector2(
                    props.position.x,
                    util.clamp(props.position.y - (layout.userData.lastMousePos.y - e.position.y), meta.scrollBarMinMax[1], meta.scrollBarMinMax[2])
                )
                meta:moveScrollPanelPercent(meta:getScrollBarPositionPercent())

                meta:update()

                layout.userData.lastMousePos = e.position
            end),
        },
    }

    meta.scrollBarElement = scroll
    meta.updateScrollBarVisibility = function (self)
        if not self.params.contentHeight or self.params.contentHeight < self.params.minHeightForScroll then
            self.scrollBarElement.props.visible = false
        else
            self.scrollBarElement.props.visible = true
        end
    end

    meta:updateScrollBarVisibility()

    contentData = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = params.size,
            position = params.position,
        },
        name = params.name,
        events = {
            mousePress = async:callback(function(e, layout)
                meta:mousePress(e)
            end),

            mouseRelease = async:callback(function(e, layout)
                meta:mouseRelease(e)
            end),

            focusLoss = async:callback(function(e, layout)
                meta:focusLoss(e)
            end),

            mouseMove = async:callback(function(e, layout)
                meta:mouseMove(e)
            end),
        },
        userData = {
            scrollBoxMeta = meta,
            movedDistance = 0,
            inFocus = false,
            onMouseWheel = function (vertical)
                if not contentData.userData.inFocus then return end

                if vertical > 0 then
                    meta:scrollUp(config.data.ui.mouseScrollAmount)
                elseif vertical < 0 then
                    meta:scrollDown(config.data.ui.mouseScrollAmount)
                end
            end,
        },
        content = ui.content {
            flex,
            scroll,
        },
    }

    contentData.content:add(button{
        position = util.vector2(params.size.x - 4, 4),
        anchor = util.vector2(1, 0),
        icon = iconUp,
        iconSize = util.vector2(config.data.ui.scrollArrowSize, config.data.ui.scrollArrowSize),
        alpha = 0.8,
        parentScrollBoxUserData = contentData.userData,
        updateFunc = params.updateFunc,
        event = function (layout)
            if not lockEvent then
                meta:scrollUp(meta.params.scrollAmount or 24)
            end
        end,
        mousePress = function (layout)
            lockEvent = false
            startScrollTimer(0, meta.params.scrollAmount / 5 or 12)
        end,
        mouseRelease = function (layout)
            stopScrollTimer()
        end
    })

    contentData.content:add(button{
        position = util.vector2(params.size.x - 4, params.size.y - 4),
        anchor = util.vector2(1, 1),
        icon = iconDown,
        iconSize = util.vector2(config.data.ui.scrollArrowSize, config.data.ui.scrollArrowSize),
        alpha = 0.8,
        parentScrollBoxUserData = contentData.userData,
        updateFunc = params.updateFunc,
        event = function (layout)
            if not lockEvent then
                meta:scrollDown(meta.params.scrollAmount or 24)
            end
        end,
        mousePress = function (layout)
            lockEvent = false
            startScrollTimer(1, meta.params.scrollAmount / 5 or 12)
        end,
        mouseRelease = function (layout)
            stopScrollTimer()
        end
    })

    if params.userData then
        tableLib.copy(params.userData, contentData.userData)
    end

    meta.getLayout = function (self)
        return contentData
    end

    return contentData
end