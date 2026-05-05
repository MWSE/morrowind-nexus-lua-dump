local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local input = require("openmw.input")
local ambient = require("openmw.ambient")

local I = require("openmw.interfaces")

local styles = require(... .. ".styles") --[[@as Styles]]


-- The currently focused virtual list, which will receive scroll wheel events.
-- This means we only support scrolls from one element at a time. That's fine.
local focusedElement = nil


-- Scroll directions for button presses. Using numbers here so multiply works.
local DIRECTION = { UP = -1, DOWN = 1 }


---@alias Range { start: number, stop: number }
---@alias ItemLayoutFn fun(index: number, list: VirtualList, oldLayout: Layout?): Layout


---@class VirtualList
---@field element VirtualListElement
---@field private itemWidth number The width of individual items.
---@field private itemHeight number The height of individual items.
---@field private itemCount number The total number of items.
---@field private itemLayout ItemLayoutFn Function that creates the layout for the item at a given index.
---@field private currentY number The current (normalized) scroll position.
---@field private visibleRange Range The currently visible range of item indices.
---@field style table Resolved style values (from styles.resolve).
local VirtualList = {}
VirtualList.__index = VirtualList


---@package
---@param element Element
---@param itemWidth number
---@param itemHeight number
---@param itemCount number
---@param itemLayout ItemLayoutFn
function VirtualList.new(element, itemWidth, itemHeight, itemCount, itemLayout, style)
    return setmetatable({
        element = element,
        itemWidth = itemWidth,
        itemHeight = itemHeight,
        itemCount = itemCount,
        itemLayout = itemLayout,
        currentY = 0,
        style = style,
    }, VirtualList)
end


--- Convenience method to cast a variable to a virtual list.
---
---@param element any
---@return VirtualList
function VirtualList.from(element)
    local scrollData = assert(element.layout.userData.scrollData)
    assert(getmetatable(scrollData) == VirtualList)
    return scrollData
end


--
-- Content accessors
--

--- Get the root element of the virtual list.
---
---@return Element
function VirtualList:getElement()
    return self.element
end


--- Get the content container layout, which is the parent layout of the list items.
---
---@package
---@return Layout
function VirtualList:getContentContainer()
    return self.element.layout.content["contentContainer"]
end


--- Get the content list. (i.e. the actual list containing the user-created content)
---
---@package
---@return Content
function VirtualList:getContent()
    return self:getContentContainer().content
end


--- Get the scrollbar layout.
---
---@package
---@return Layout?
function VirtualList:getScrollbar()
    -- The scrollbar may not exist if there are too few items and autohide is enabled.
    local content = self.element.layout.content
    local container = content and content["scrollbarContainer"]
    local scrollbar = container and container.content["scrollbar"]
    return scrollbar
end


--
-- Item Geometry
--

--- Get item dimensions as a Vector2.
---
---@return Vector2
function VirtualList:getItemSize()
    return util.vector2(self.itemWidth, self.itemHeight)
end


--- Get the top pixel offset of the item at the given index.
---
---@param index number
---@return number
function VirtualList:getItemTop(index)
    return (index - 1) * self.itemHeight
end


--- Get the bottom pixel offset of the item at the given index.
---
---@param index number
---@return number
function VirtualList:getItemBottom(index)
    return index * self.itemHeight
end


--- Returns the pixel offset of the given item from the top of the viewport.
---
---@param index number
---@return number
function VirtualList:getItemViewportOffset(index)
    local contentContainer = self:getContentContainer()
    return self:getItemTop(index) + contentContainer.props.position.y
end


--
-- Viewport & index bounds
--

--- Get the visible height in pixels.
---
---@return number
function VirtualList:getVisibleHeight()
    return self.element.layout.props.size.y - styles.VIEWPORT_INSET
end


--- Get the first valid item index.
---
---@return number
function VirtualList:getFirstIndex()
    return 1
end


--- Get the last valid item index.
---
---@return number
function VirtualList:getLastIndex()
    return self.itemCount
end


--- Get the index of the item that is on the next page from the given index.
---
---@param from number The index from which to calculate the next page index.
---@param mode string Either "top" or "bottom", the direction in which to page.
function VirtualList:getNextPageIndex(from, mode)
    local range = self:getVisibleRange()

    local numVisibleItems = range.stop - range.start

    if mode == "top" then
        return math.max(self:getFirstIndex(), from - numVisibleItems + 1)
    end

    if mode == "bottom" then
        return math.min(self:getLastIndex(), from + numVisibleItems - 1)
    end

    error("Invalid page mode: " .. tostring(mode))
end


--
-- Scroll position
--


--- Get the current scroll offset in pixels.
---
---@return number
function VirtualList:getScrollOffset()
    return self.currentY * self:getMaxScrollDistance()
end


--- Returns the maximum logical scroll distance in pixels. Zero (or negative)
--  when all content fits in the viewport.
---
---@return number
function VirtualList:getMaxScrollDistance()
    return self.itemCount * self.itemHeight - self:getVisibleHeight()
end


--
-- Visibility queries
--

--- Get the index of the first visible item based on the current scroll position.
---
---@return number
function VirtualList:getFirstVisibleIndex()
    local threshold = self.itemHeight * 0.5
    local scrollOffset = self:getScrollOffset()
    local firstVisible = math.ceil(1 + (scrollOffset - threshold) / self.itemHeight)
    return math.max(1, firstVisible)
end


--- Get the index of the last visible item based on the current scroll position.
---
---@return number
function VirtualList:getLastVisibleIndex()
    local threshold = self.itemHeight * 0.5
    local scrollOffset = self:getScrollOffset()
    local visibleHeight = self:getVisibleHeight()
    local lastVisible = math.floor((scrollOffset + visibleHeight + threshold) / self.itemHeight)
    return math.min(self.itemCount, lastVisible)
end


--- Check whether the item at the given index is fully within the viewport.
---
---@param index number
---@return boolean
function VirtualList:isItemFullyVisible(index)
    local scrollOffset = self:getScrollOffset()
    local viewBottom = scrollOffset + self:getVisibleHeight()
    return self:getItemTop(index) >= scrollOffset and self:getItemBottom(index) <= viewBottom
end


--- Calculate visible range based on current scroll Y.
---
---@package
---@return Range
function VirtualList:calcVisibleRange()
    if self.itemCount == 0 then
        return { start = 1, stop = 0 } -- Empty range sentinel.
    end

    -- Just don't fuck with any of this math. It is perfect I promise.
    -- Rounding floats to pixels is pain. 1-based indexing is not fun.
    -- And the range size must be constant, if it's not the math dies.

    local itemCount = self.itemCount
    local itemHeight = self.itemHeight
    local totalHeight = itemHeight * itemCount

    local numVisibleItems = math.ceil(self:getVisibleHeight() / itemHeight)
    local visibleItemsHeight = itemHeight * numVisibleItems

    local emptyHeight = math.max(totalHeight - visibleItemsHeight, 0)

    -- The pixel offset within the container to the top of the visible area.
    local visibleStart = emptyHeight * self.currentY

    -- The +1 is needed to cover partially visible items between boundaries.
    local numSlots = numVisibleItems + 1

    local startIndex = 1 + math.floor(visibleStart / itemHeight)
    local stopIndex = startIndex + numSlots - 1

    if stopIndex > itemCount then
        stopIndex = itemCount
        startIndex = math.max(1, stopIndex - numSlots + 1)
    end

    return { start = startIndex, stop = stopIndex }
end


--- Get the currently visible range of item indices.
---
---@package
---@return Range
function VirtualList:getVisibleRange()
    if self.visibleRange == nil then
        self.visibleRange = self:calcVisibleRange()
    end
    return self.visibleRange
end


--
-- Item content (layout slot management)
--

--- Evaluate the item index in the slot of the range.
---
---@package
---@param slot number
---@param range Range
---@return number
function VirtualList:getIndexForSlot(slot, range)
    local start, stop = range.start, range.stop
    local len = stop - start + 1
    if len == 0 then
        return 1
    else
        return start + (len - ((start - 1) % len) + slot - 1) % len
    end
end


--- Applies size and position propertiess on the user-provided item layout.
---
---@package
---@param layout Layout
---@param index number
function VirtualList:applyItemProps(layout, index)
    layout.props.size = util.vector2(self.itemWidth, self.itemHeight)
    layout.props.position = util.vector2(0, self:getItemTop(index))
end


--- Get the layout of the item at the given index.
---
--- Returns nil if the index is not in the visible range.
---
---@param index number?
---@return Layout?
function VirtualList:getItemLayout(index)
    if index == nil then
        return
    end

    local range = self:getVisibleRange()
    if (index < range.start) or (index > range.stop) then
        return
    end

    local len = range.stop - range.start + 1
    if len <= 0 then
        return
    end

    local slot = (index - 1) % len + 1
    local content = self:getContent()
    return content[slot]
end


--
-- Scroll actions
--


--- Rebuild the list while preserving the viewport position of a selected item.
---
---@param newCount number
---@param oldIndex number?
---@param newIndex number?
function VirtualList:rebuildAndScroll(newCount, oldIndex, newIndex)
    local offset = oldIndex and self:getItemViewportOffset(oldIndex)

    self:rebuild(newCount)

    if newIndex then
        self:scrollToIndex(newIndex, offset or "center")
    end

    return newIndex
end


--- Scroll the given index into view, aligning it according to `mode`.
---
--- Modes:
---     "top" : Align the item to the top of the viewport.
---  "bottom" : Align the item to the bottom of the viewport.
---  "center" : Align the item to the center of the viewport.
---    number : Align the item to the given pixel offset.
---
---
---@param index number
---@param mode string|number
function VirtualList:scrollToIndex(index, mode)
    if index < 1 or index > self.itemCount then
        return
    end

    local maxScrollDistance = self:getMaxScrollDistance()
    if maxScrollDistance <= 0 then
        return
    end

    -- Early exit if fully visible and not using pixel offset.
    if type(mode) ~= "number" and self:isItemFullyVisible(index) then
        return
    end

    local itemTop = self:getItemTop(index)
    local targetY

    if mode == "top" then
        targetY = itemTop
    elseif mode == "bottom" then
        targetY = self:getItemBottom(index) - self:getVisibleHeight()
    elseif mode == "center" then
        targetY = itemTop + self.itemHeight / 2 - self:getVisibleHeight() / 2
    elseif type(mode) == "number" then
        targetY = itemTop - mode
    else
        error("Invalid scroll mode: " .. tostring(mode))
        return
    end

    self.currentY = util.clamp(targetY / maxScrollDistance, 0, 1)

    self:applyScrollPosition()
end


--- Applies the current scroll position to the content container and scrollbar handle,
--- then triggers a visible-items refresh.
---
---@package
function VirtualList:applyScrollPosition()
    local contentContainer = self:getContentContainer()
    contentContainer.props.position = util.vector2(0, -math.floor(self:getScrollOffset() + 0.5))

    local handleMaxY, handle = self:getScrollbarContext()
    if handle then
        handle.props.position = util.vector2(0, self.currentY * handleMaxY)
    end

    self:syncVisibleItems()
    self.element:update()
end


--- Handles scroll events, updating the visible items as necessary.
---
---@package
function VirtualList:syncVisibleItems()
    local oldRange = self:getVisibleRange()
    if oldRange.start > oldRange.stop then
        return
    end

    local newRange = self:calcVisibleRange()
    if newRange.start == oldRange.start
        and newRange.stop == oldRange.stop
    then
        return
    end

    self.visibleRange = newRange

    local contentsParent = self:getContent()
    local len = oldRange.stop - oldRange.start + 1

    for i = 1, len do
        local oldIndex = self:getIndexForSlot(i, oldRange)
        local newIndex = self:getIndexForSlot(i, newRange)
        if oldIndex ~= newIndex then
            local oldContent = contentsParent[i]
            local newContent = self.itemLayout(newIndex, self, oldContent)
            self:applyItemProps(newContent, newIndex)
            if newContent ~= oldContent then
                contentsParent[i] = newContent
            end
        end
    end
end


--- Handles scroll button presses, updating the scroll position accordingly.
---
---@package
---@param direction number
---@param mode string?
function VirtualList:applyScrollStep(direction, mode)
    if (direction == DIRECTION.UP and self.currentY <= 0.0)
        or (direction == DIRECTION.DOWN and self.currentY >= 1.0)
    then
        return
    end

    local maxScrollDistance = self:getMaxScrollDistance()
    if maxScrollDistance <= 0 then
        return
    end

    local step = self.itemHeight
    if mode == "wheel" then
        step = step * styles.SCROLL_WHEEL_STEP_MULT
    elseif mode == "page" then
        local range = self:getVisibleRange()
        local numVisibleItems = range.stop - range.start - 1
        step = step * numVisibleItems
    end

    local stepNormalized = (step / maxScrollDistance) * direction
    self.currentY = util.clamp(self.currentY + stepNormalized, 0, 1)

    self:applyScrollPosition()
end


--
-- Scrollbar
--


---@package
---@return Vector2
function VirtualList:calcScrollbarSize()
    -- The scrollbar size is the size of the list minus the up/down buttons and their padding.
    local borderPadding = self.style.edgePadding * 2
    local buttonsHeight = styles.SCROLL_BAR_BUTTON_SIZE.y * 2
    local buttonGaps = self.style.buttonPaddingSize.y * 2
    local combinedHeight = borderPadding + buttonsHeight + buttonGaps + styles.SCROLL_BAR_BOTTOM_PAD
    local listHeight = self.element.layout.props.size.y
    return util.vector2(styles.SCROLL_BAR_TRACK_WIDTH, listHeight - combinedHeight)
end


---@package
---@return Vector2
function VirtualList:calcScrollbarHandleSize(scrollbarHeight)
    local totalHeight = self.itemCount * self.itemHeight
    -- floor to integer so size/position round consistently
    local handleHeight = math.floor(scrollbarHeight * self:getVisibleHeight() / totalHeight)
    local maxHandleHeight = scrollbarHeight - styles.SCROLL_BAR_HANDLE_CLEARANCE
    local clampedHeight = util.clamp(handleHeight, styles.SCROLL_HANDLE_MIN_HEIGHT, maxHandleHeight)
    return util.vector2(styles.SCROLL_BAR_HANDLE_WIDTH, clampedHeight)
end


--- Get scrollbar context: the travel limit, handle element, and scrollbar element.
---
---@package
---@return number? limit  pixel range the handle can move
---@return Layout? handle
---@return Layout? scrollbar
function VirtualList:getScrollbarContext()
    local scrollbar = self:getScrollbar()
    if scrollbar == nil then
        return
    end

    local scrollbarHeight = scrollbar.props.size.y

    local handle = scrollbar.content["handle"]
    local handleHeight = handle.props.size.y
    local handleMaxY = scrollbarHeight - handleHeight - styles.SCROLL_BAR_HANDLE_CLEARANCE

    return handleMaxY, handle, scrollbar
end


---@package
---@param element Layout?
function VirtualList:setScrollbarContainer(element)
    local content = assert(self.element.layout.content)
    -- Uses pcall because there's no nice way to check if content exists by name.
    local success = pcall(function() content["scrollbarContainer"] = element end)
    if element and not success then
        content:add(element)
    end
end


--- Handles a shift-click on the scrollbar track, jumping to the clicked position.
---
---@package
---@param offsetY number  click y relative to the scrollbar element
function VirtualList:onScrollbarJump(offsetY)
    local handleMaxY, handle = self:getScrollbarContext()
    if not (handle and handleMaxY) then
        return
    end

    local handleHeight = handle.props.size.y
    local handleY = util.clamp(offsetY - handleHeight / 2, 0, handleMaxY)
    self.currentY = handleY / handleMaxY

    self:applyScrollPosition()
end


--- Handles a mouse-drag on the scrollbar handle, moving it by `delta` pixels.
---
---@package
---@param delta number Movement delta in pixels.
---@return boolean Indicates whether the scroll position was updated.
function VirtualList:onScrollbarDrag(delta)
    local handleMaxY, handle = self:getScrollbarContext()
    if not (handle and handleMaxY) then
        return false
    end

    if self:getMaxScrollDistance() <= 0 then
        return false
    end

    local handleY = handle.props.position.y
    if (delta < 0) and (handleY <= 0) then
        return false
    end

    if (delta > 0) and (handleY >= handleMaxY) then
        return false
    end

    local newHandleY = util.clamp(handleY + delta, 0, handleMaxY)
    self.currentY = util.clamp(newHandleY / handleMaxY, 0, 1)
    self:applyScrollPosition()

    return true
end


---@package
function VirtualList:createScrollbar()
    if self.style.autoHideScrollBar and (self:getMaxScrollDistance() <= 0) then
        self:setScrollbarContainer(nil)
        return
    end

    local scrollbarSize = self:calcScrollbarSize()

    local scrollbar = {
        template = I.MWUI.templates.borders,
        name = "scrollbar",
        props = {
            size = scrollbarSize,
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                name = "handle",
                props = {
                    resource = styles.SCROLL_CENTER_TEXTURE,
                    position = util.vector2(0, 0),
                    size = self:calcScrollbarHandleSize(scrollbarSize.y),
                    tileV = true,
                    propagateEvents = true,
                },
                events = {
                    mousePress = async:callback(function(e, layout)
                        ambient.playSound("menu click")
                        layout.userData.prevPosition = e.position.y
                    end),
                    mouseRelease = async:callback(function(_, layout)
                        layout.userData.prevPosition = nil
                    end),
                },
                userData = {
                    -- We track previous position manually because we are only
                    -- concerned with movement within the scrollbar bounds.
                    prevPosition = nil,
                },
            },
        }),
        events = {
            mousePress = async:callback(function(e, layout)
                local handle = layout.content["handle"]
                local handleY = handle.props.position.y
                local handleHeight = handle.props.size.y

                if e.offset.y >= handleY
                    and e.offset.y <= (handleY + handleHeight)
                then
                    return
                end

                ambient.playSound("menu click")

                local scrollData = VirtualList.from(self.element)

                if input.isShiftPressed() then
                    scrollData:onScrollbarJump(e.offset.y)
                    handle.userData.prevPosition = e.position.y
                else
                    local direction = (e.offset.y < handleY) and DIRECTION.UP or DIRECTION.DOWN
                    scrollData:applyScrollStep(direction, "page")
                    handle.userData.prevPosition = nil
                end
            end),
            mouseMove = async:callback(function(e, layout)
                if e.button ~= 1 then return end

                local scrollData = VirtualList.from(self.element)
                local handle = layout.content["handle"]
                local previous = handle.userData.prevPosition
                local delta = previous and (e.position.y - previous) or 0
                if math.abs(delta) < 1e-6 then
                    return
                end

                if scrollData:onScrollbarDrag(delta) then
                    handle.userData.prevPosition = e.position.y
                end
            end),
        },
    }

    local upButton = {
        template = I.MWUI.templates.borders,
        props = {
            size = styles.SCROLL_BAR_BUTTON_SIZE,
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = styles.SCROLL_UP_TEXTURE,
                    size = styles.SCROLL_BUTTON_ICON_SIZE,
                },
            },
        }),
        events = {
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    self:applyScrollStep(DIRECTION.UP)
                    ambient.playSound("menu click")
                end
            end),
        },
    }

    local downButton = {
        template = I.MWUI.templates.borders,
        props = {
            size = styles.SCROLL_BAR_BUTTON_SIZE,
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = styles.SCROLL_DOWN_TEXTURE,
                    size = styles.SCROLL_BUTTON_ICON_SIZE,
                },
            },
        }),
        events = {
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    self:applyScrollStep(DIRECTION.DOWN)
                    ambient.playSound("menu click")
                end
            end),
        },
    }

    local padding = { props = { size = self.style.buttonPaddingSize } }

    local scrollbarContainer = {
        type = ui.TYPE.Flex,
        name = "scrollbarContainer",
        props = {
            position = self.style.scrollBarPosition,
            relativePosition = util.vector2(1, 0),
        },
        content = ui.content({
            upButton,
            padding,
            scrollbar,
            padding,
            downButton,
        }),
    }

    self:setScrollbarContainer(scrollbarContainer)
end


--
-- Rebuild
--

--- Rebuild the list content, optionally with a new item count and item height.
---
---@param newItemCount number?
---@param newItemHeight number?
function VirtualList:rebuild(newItemCount, newItemHeight)
    if newItemCount then
        self.itemCount = newItemCount
    end
    if newItemHeight then
        self.itemHeight = newItemHeight
    end

    local contentContainer = self:getContentContainer()
    local totalSize = util.vector2(contentContainer.props.size.x, self.itemCount * self.itemHeight)
    contentContainer.props.size = totalSize
    contentContainer.props.position = util.vector2(0, 0)

    self.currentY = 0
    self.visibleRange = self:calcVisibleRange()

    local start = self.visibleRange.start
    local stop = self.visibleRange.stop

    local content = self:getContent()
    local oldLen = #content
    local newLen = (self.itemCount ~= 0) and (stop - start + 1) or 0

    -- Reuse slots that exist in both old and new content.
    local reuseCount = math.min(oldLen, newLen)
    for i = 1, reuseCount do
        local index = start + i - 1
        local oldLayout = content[i]
        local newLayout = self.itemLayout(index, self, oldLayout)
        self:applyItemProps(newLayout, index)
        if newLayout ~= oldLayout then
            content[i] = newLayout
        end
    end

    -- Remove slots that no longer exist.
    for i = oldLen, reuseCount + 1, -1 do
        content[i] = nil
    end

    -- Add new slots (nothing to recycle).
    for i = reuseCount + 1, newLen do
        local index = start + i - 1
        local layout = self.itemLayout(index, self)
        self:applyItemProps(layout, index)
        content:add(layout)
    end

    self:createScrollbar()
    self:scrollToIndex(1, "top")
    self.element:update()
end


-- We need to embed the types for the whole Element->Layout->UserData chain so
-- that LLS understands it.

---@class VirtualListUserData
---@field scrollData VirtualList

---@class VirtualListLayout
---@field userData VirtualListUserData

---@class VirtualListElement : Element
---@field layout Layout | VirtualListLayout


---@class VirtualListParams
---@field viewportSize Vector2 The visible size of the list.
---@field itemSize Vector2 The size of each item in the list.
---@field itemCount number The total number of items in the list.
---@field itemLayout ItemLayoutFn Function which creates the item layout for a given index.
---@field style table? Style configuration table (defaults to styles.STYLES.Compact).


--- Creates a new virtual list controller and its backing UI element.
---
---@param params VirtualListParams
---@return VirtualList
function VirtualList.create(params)
    local visibleSize = params.viewportSize
    local visibleWidth = visibleSize.x
    local itemWidth = params.itemSize.x
    local itemHeight = params.itemSize.y
    local itemCount = params.itemCount
    local itemLayout = params.itemLayout
    local style = styles.resolve(params.style or styles.STYLES.Compact)

    local list = ui.create({
        type = ui.TYPE.Widget,
        name = "virtualList",
        props = {
            size = visibleSize,
        },
        content = ui.content({
            {
                name = "contentContainer",
                props = {
                    position = util.vector2(0, 0),
                    size = util.vector2(visibleWidth, itemCount * itemHeight),
                },
                content = ui.content({}),
            },
        }),
        userData = {},
    })

    -- We track the focus in outer scope so the onMouseWheel event can access it.
    list.layout.events = {
        focusGain = async:callback(function()
            focusedElement = list
        end),
        focusLoss = async:callback(function()
            if focusedElement == list then
                focusedElement = nil
            end
        end),
    }

    list.layout.userData.scrollData = VirtualList.new(
        list,
        itemWidth,
        itemHeight,
        itemCount,
        itemLayout,
        style
    )

    ---@cast list VirtualListElement
    ---@type VirtualList
    local scrollData = list.layout.userData.scrollData

    scrollData:rebuild()

    return scrollData
end


--- Returns a `onMouseWheel` event handler function that implements mouse wheel
--  scrolling.
---
---@return fun(vertical: number, horizontal: number)
function VirtualList.getMouseWheelHandler()
    return function(vertical, horizontal)
        if (focusedElement ~= nil) and (vertical ~= 0) then
            local direction = (vertical > 0) and DIRECTION.UP or DIRECTION.DOWN
            VirtualList.from(focusedElement)
                :applyScrollStep(direction, "wheel")
        end
    end
end


return VirtualList
