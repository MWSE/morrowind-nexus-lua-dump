local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local input = require("openmw.input")
local ambient = require("openmw.ambient")

-- We go up two levels to avoid a circular require
local dir = (...):match("(.+)%.[^.]+%.[^.]+$")

local VirtualList = require(dir)

---@type ListState
local ListState = require(dir .. ".extras.list_state")

---@type FontColors
local FontColors = require(dir .. ".extras.font_color")

--- Parameters for `VirtualListExt.create`.
---
---@class VirtualListExtCreateParams
---@field viewportSize Vector2
---@field itemSize Vector2
---@field itemCount number
---@field itemLayout ExtendedItemLayoutFn
---@field style table?

--- Parameters for `VirtualListExt:createItemLayout`.
---
---@class createItemLayoutParams
---@field index number
---@field props { text: string, textSize?: number }
---@field onMousePress fun(e: table, layout: Layout)?
---@field getTextLayout (fun(i: number?): Layout?)?

--- Parameters for `VirtualListExt:createSearchBox`.
---
---@class createSearchBoxParams
---@field text string?
---@field textSize number?
---@field onTextChanged fun(string, Layout)
---@field onTextCleared fun(Element, Layout)


-- We're in the opinionated "extras" module. I'm going to hardcode these. :)
local TEXT_SIZE = 16
local PAD_SIZE = 4

--- An extended API layer over VirtualList with opinionated UI factory
--- methods for common list patterns.
---
---@class VirtualListExt : VirtualList, ListState
---@field private element VirtualListElement
local VirtualListExt = {}
VirtualListExt.__index = VirtualListExt


--- Convenience method to cast a variable to a virtual list.
---
---@param element VirtualListElement
---@return VirtualListExt
function VirtualListExt.from(element)
    local userData = element.layout.userData
    if userData.extendedData == nil then
        userData.extendedData = setmetatable({ element = element }, VirtualListExt)
    end
    return userData.extendedData --[[@as VirtualListExt]]
end


---@alias ExtendedItemLayoutFn fun(index: number, list: VirtualListExt, oldLayout: Layout?): Layout


--- Create a new VirtualListExt instance.
---
---@param params VirtualListExtCreateParams
---@return VirtualListExt
function VirtualListExt.create(params)
    local userItemLayout = params.itemLayout
    local capturedExt = nil

    local wrappedParams = {
        viewportSize = params.viewportSize,
        itemSize     = params.itemSize,
        itemCount    = params.itemCount,
        style        = params.style,
        itemLayout   = function(index, baseList, oldLayout)
            local ext = capturedExt or VirtualListExt.from(baseList:getElement())
            return userItemLayout(index, ext, oldLayout)
        end,
    }

    local baseList = VirtualList.create(wrappedParams)
    capturedExt = VirtualListExt.from(baseList:getElement())
    return capturedExt
end


--- Create a basic text layout that supports mouse selection.
---
---@param params createItemLayoutParams
---@return Layout
function VirtualListExt:createItemLayout(params)
    local index = params.index
    local text = params.props.text
    local textSize = params.props.textSize or TEXT_SIZE
    local onMousePress = params.onMousePress
    local getTextLayout = params.getTextLayout

    local textLayout = {
        type = ui.TYPE.Text,
        props = {
            text = text,
            textSize = textSize,
            textColor = self:getColor(index),
            position = util.vector2(PAD_SIZE, 0),
        },
    }

    local itemSize = self:getItemSize()

    -- The wrapper is needed so mouse events aren't isolated to just the text pixels.
    return {
        type = ui.TYPE.Widget,
        props = {
            size = itemSize,
        },
        events = {
            mouseMove = async:callback(function()
                if self:getPressedIndex() == nil then
                    self:updateOverColor(textLayout, index)
                end
            end),
            focusLoss = async:callback(function()
                if self:getPressedIndex() == nil then
                    self:updateColor(textLayout, index)
                end
            end),
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    ambient.playSound("menu click")
                    self:setPressedIndex(index)
                    self:changeSelection(index, getTextLayout)
                end
                if onMousePress then
                    onMousePress(e, textLayout)
                end
            end),
            mouseRelease = async:callback(function(e)
                if e.button ~= 1 then return end
                self:setPressedIndex(nil)
                self:updateColor(textLayout, index)
            end),
        },
        content = ui.content({ textLayout }),
    }
end


--- Create a basic search box with placeholder text integration.
---
---@param params createSearchBoxParams
---@return Element
function VirtualListExt:createSearchBox(params)
    local placeholder = params.text or ""
    local textSize = params.textSize or TEXT_SIZE
    local onTextChanged = params.onTextChanged
    local onTextCleared = params.onTextCleared

    local itemSize = self:getItemSize()

    -- Offset the text edit with padding, so it's not right on the border.
    local position = util.vector2(PAD_SIZE, PAD_SIZE)

    -- Subtract X padding from size so the offset won't expand the border.
    -- Add vertical padding to size in both directions so we get symmetry.
    local size = util.vector2(itemSize.x - PAD_SIZE, textSize + PAD_SIZE * 2)

    local element = nil
    local lastText = ""

    element = ui.create({
        type = ui.TYPE.TextEdit,
        props = {
            position = position,
            size = size,
            text = placeholder,
            textSize = 16,
            textColor = FontColors.getDisabledColor(),
        },
        events = {
            focusGain = async:callback(function(_, layout)
                if lastText == "" then
                    -- Clear the placeholder text.
                    layout.props.text = ""
                    layout.props.textColor = FontColors.getNormalColor()
                    pcall(function() assert(element):update() end)
                end
            end),
            focusLoss = async:callback(function(_, layout)
                if lastText == "" then
                    -- Reset the placeholder text.
                    layout.props.text = placeholder
                    layout.props.textColor = FontColors.getDisabledColor()
                    pcall(function() assert(element):update() end)
                    onTextCleared(element, layout)
                end
            end),
            textChanged = async:callback(function(text, layout)
                -- The `textChanged` event triggers even when the text hasn't changed.
                -- Easy reproduction: Press backspace while the text is already empty.
                if lastText ~= text then
                    lastText = text
                    onTextChanged(text, layout)
                end
            end),
        },
    })

    onTextCleared(element)

    return element
end


--- Creates a simple read-only placeholder text layout.
---
---@param params { text: string, textSize?: number }
---@return Layout
function VirtualListExt:createPlaceholder(params)
    return {
        type = ui.TYPE.Widget,
        props = {},
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = params.text,
                    textSize = params.textSize or TEXT_SIZE,
                    textColor = FontColors.getDisabledColor(),
                    position = util.vector2(PAD_SIZE, 0),
                },
            },
        },
    }
end


---@class setKeyPressHandlerParams
---@field getSelectedIndex (fun(): number?)?
---@field setSelectedIndex fun(index: number)


--- Creates a generic `keyPress` event handler for the list.
---
--- Currently includes basic implementations for the following keys:
--- ```
--- input.KEY.Home
--- input.KEY.End
--- input.KEY.PageUp
--- input.KEY.PageDown
--- input.KEY.UpArrow
--- input.KEY.DownArrow
--- ```
---
---@param params setKeyPressHandlerParams
function VirtualListExt:setKeyPressHandler(params)
    local list = self.element

    local getSelectedIndex = params.getSelectedIndex or function()
        return self:getSelectedIndex()
    end
    local setSelectedIndex = params.setSelectedIndex

    list.layout.events.keyPress = async:callback(function(e, layout)
        -- For sanity keyboard navigation drops the "pressed" state.
        self:setPressedIndex(nil)

        ---@type VirtualList
        local scrollData = layout.userData.scrollData

        if e.code == input.KEY.Home then
            local i = scrollData:getFirstIndex()
            setSelectedIndex(i)
            scrollData:scrollToIndex(i, "top")
            return
        end

        if e.code == input.KEY.End then
            local i = scrollData:getLastIndex()
            setSelectedIndex(i)
            scrollData:scrollToIndex(i, "bottom")
            return
        end

        if e.code == input.KEY.PageUp then
            local oldIndex = getSelectedIndex()
            local newIndex = scrollData:getFirstVisibleIndex()
            if oldIndex == newIndex then
                newIndex = scrollData:getNextPageIndex(newIndex, "top")
            end
            setSelectedIndex(newIndex)
            scrollData:scrollToIndex(newIndex, "top")
            return
        end

        if e.code == input.KEY.PageDown then
            local oldIndex = getSelectedIndex()
            local newIndex = scrollData:getLastVisibleIndex()
            if oldIndex == newIndex then
                newIndex = scrollData:getNextPageIndex(newIndex, "bottom")
            end
            setSelectedIndex(newIndex)
            scrollData:scrollToIndex(newIndex, "bottom")
            return
        end

        if e.code == input.KEY.UpArrow then
            local i = getSelectedIndex()
            if i ~= scrollData:getFirstIndex() then
                i = i - 1
                setSelectedIndex(i)
                scrollData:scrollToIndex(i, "top")
            end
            return
        end

        if e.code == input.KEY.DownArrow then
            local i = getSelectedIndex()
            if i ~= scrollData:getLastIndex() then
                i = i + 1
                setSelectedIndex(i)
                scrollData:scrollToIndex(i, "bottom")
            end
            return
        end
    end)
end


VirtualListExt.__index = function(_, key)
    local value = rawget(VirtualListExt, key)
    if value then
        return value
    end
    -- Delegate to VirtualList
    local listMethod = VirtualList[key]
    if listMethod then
        return function(self, ...)
            return listMethod(VirtualList.from(self.element), ...)
        end
    end
    -- Delegate to ListState
    local stateMethod = ListState[key]
    if stateMethod then
        return function(self, ...)
            return stateMethod(ListState.from(self.element), ...)
        end
    end
end


--- Convenience access to the getMouseWheelHandler callback.
---
VirtualListExt.getMouseWheelHandler = VirtualList.getMouseWheelHandler


return VirtualListExt
