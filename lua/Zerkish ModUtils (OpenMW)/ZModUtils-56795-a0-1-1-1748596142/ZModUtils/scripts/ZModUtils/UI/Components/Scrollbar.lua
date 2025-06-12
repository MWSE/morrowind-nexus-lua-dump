-- ZModUtils - Scrollbar.lua
-- Author: Zerkish (2025)

local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local constants = require('scripts.omw.mwui.constants')


local ZUIConstants = require('scripts.ZModUtils.UI.Constants')



local function onScrollbarMouseMove(mEvent, layout)
    -- layout will be scrollbar_handle_image
    assert(layout ~= nil)
    assert(layout.userData ~= nil)

    if layout.userData._isPressed then
        local move = mEvent.position.y - layout.userData._gripOffset
        local newY = layout.userData._startY + move

        local maxBarPosition = layout.userData.height - layout.userData.barHeight

        if newY < 0 then newY = 0 end
        if newY > maxBarPosition then newY = maxBarPosition end

        layout.props.position = util.vector2(layout.props.position.x, newY)

        -- we need the topmost level here
        local area = layout.userData._parent
        assert(area, 'invalid scrollbar area')
        local root = area.userData._parent
        assert(root, 'invalid scrollbar root')

        if layout.userData.callback then
            layout.userData.callback(mEvent, layout, area.userData._element)
        end

        assert(area.userData._element, 'invalid scrollbar element')
        area.userData._element:update()

        --setInnerContentPositionFromScrollbarPosition()
    end
end

local function onScrollbarMousePress(mEvent, layout)
    assert(layout ~= nil)
    assert(layout.userData ~= nil)

    -- layout will be scrollbar_handle_image
    if layout.userData ~= nil then
        layout.userData._gripOffset = mEvent.position.y
        layout.userData._startY = layout.props.position.y
        layout.userData._isPressed = true
    end
end

local function onScrollbarMouseRelease(mEvent, layout)
    assert(layout ~= nil)
    assert(layout.userData ~= nil)
    -- layout will be scrollbar_handle_image
    if layout.userData then
        layout.userData._isPressed = false
        layout.userData._gripOffset = 0
        layout.userData._startY = 0
    end
end

local function onScrollbarAreaMousePress(mEvent, areaLayout)
    if not areaLayout then return false end
    assert(areaLayout.userData and areaLayout.userData._handle, 'no userdata for layout')

    local handle = areaLayout.userData._handle

    if handle then
        local newY = mEvent.offset.y - handle.userData.barHeight * 0.5
        newY = math.max(0, math.min(newY, handle.userData.height - handle.userData.barHeight))
        handle.props.position = util.vector2(handle.props.position.x, newY)
        if handle.userData.callback then
            handle.userData.callback(mEvent, areaLayout, areaLayout.userData._element)
        end
        assert(areaLayout.userData._element, 'layout.userData._element is nil')
        areaLayout.userData._element:update()
    end
    
end

local function createVScrollbarLayout(width, height, barSize, callback)

    local areaLayout = {
        type = ui.TYPE.Widget,
        --name = 'scrollbar_bg',
        props = {
            size = util.vector2(width - constants.border * 2, height),
            autoSize = false,
        },

        events = {
            mousePress = async:callback(onScrollbarAreaMousePress),
        }
    }

    local handleLayout = {
        type = ui.TYPE.Image,
        --name = 'scrollbar_handle',
        props = {
            propagateEvents = false,
            size = util.vector2(width,  barSize),
            position = util.vector2(0, 0),
            tileV = true,
            resource = ui.texture({
                path = ZUIConstants.ScrollBarHandleTexturePath,
            })
        },

        events = {
            mouseMove = async:callback(onScrollbarMouseMove),
            mousePress = async:callback(onScrollbarMousePress),
            mouseRelease = async:callback(onScrollbarMouseRelease),
        },

        userData = {
            height = height,
            barHeight = barSize,
            callback = callback,
            
            -- these variables are used by the scrollbar for eventCallbacks
            _gripOffset = 0,
            _startPosition = 0,
            _isPressed = false,
            _parent = areaLayout,
        },
    }

    areaLayout.content = ui.content({ handleLayout })
    areaLayout.userData = {
        _handle = handleLayout,
    }

    return areaLayout
end

local function getScrollbarHandleFromScrollbar(scrollbar)
    if not scrollbar then return nil end
    assert(scrollbar.layout and scrollbar.layout.content and #scrollbar.layout.content > 0)
    
    --scrollbar.layout => rootLayout (user)
    --scrollbar.layout.content[1] => areaLayout (internal)
    local area = scrollbar.layout.content[1]
    assert(area, 'area is nil')
    assert(area.userData and area.userData._element == scrollbar, 'invalid scrollbar')        
    
    local handle = area.userData._handle
    assert(handle, 'no handle set')
    
    return handle
end

-- params
-- table with
-- size : util.vector2
-- handleSize : number between 0.0 and size.y
-- callback : callback to be called when the scrollbar is moved.
local function createVerticalScrollbar(params)
    if not params then return nil end

    local width = 0
    local height = 0
    if params.size then 
        width = params.size.x and params.size.x or 0
        height = params.size.y and params.size.y or 0
    end

    local rootLayout = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {
            propagateEvents = false,
            -- align = ui.ALIGNMENT.Center,
            -- arrange = ui.ALIGNMENT.Center,
        },
    }

    local barHeight = params.handleSize and params.handleSize or height

    local area = createVScrollbarLayout(width, height, barHeight, params.callback)
    rootLayout.content = ui.content({ area })


    --local element = ui.create(area)
    local element = ui.create(rootLayout)
    area.userData._parent = rootLayout
    area.userData._element = element
    
    return element
end

return {

    createVScrollbar = createVerticalScrollbar,

    -- scrollbar is element returned from createXScrollbar
    getScrollbarHandleSize = function(scrollbar)
        local handle = getScrollbarHandleFromScrollbar(scrollbar)
        if (handle) then
            return handle.userData.barHeight
        end
        return nil
    end,

    getScrollbarHandleMaxPosition = function(scrollbar)
        local handle = getScrollbarHandleFromScrollbar(scrollbar)
        if (handle) then
            return handle.userData.height - handle.userData.barHeight
        end
        return nil
    end,

    -- Returns position in the dimension of the scrollbar, ie y for vertical 
    -- returns number or nil
    getScrollbarHandlePosition = function(scrollbar)
        local handle = getScrollbarHandleFromScrollbar(scrollbar)
        if (handle) then
            return handle.props.position.y
        end
        return nil
    end,

    -- Set the scrollbar position in the dimension of the scrollbar, ie y for vertical
    -- position is a number
    setScrollbarHandlePosition = function(scrollbar, position)
        local handle = getScrollbarHandleFromScrollbar(scrollbar)
        if (handle) then
            handle.props.position = util.vector2(handle.props.position.x, position)
        end
    end,

    setScrollbarHandleSize = function(scrollbar, size)
        local handle = getScrollbarHandleFromScrollbar(scrollbar)
        if (handle) then
            handle.userData.barHeight = size
            handle.props.size = util.vector2(handle.props.size.x, handle.userData.barHeight)
        end
    end,
}
