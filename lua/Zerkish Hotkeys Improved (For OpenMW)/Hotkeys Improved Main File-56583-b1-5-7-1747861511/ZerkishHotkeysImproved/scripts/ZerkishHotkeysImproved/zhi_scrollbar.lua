-- Zerkish Improved Hotkeys - zhi_scrollbar.lua
-- scrollbar implementation
-- makes use of layout.userData, but it's safe to replace userData for any layout returned by a function

local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local constants = require('scripts.omw.mwui.constants')

local ZHIUtil = require('scripts.ZerkishHotkeysImproved.zhi_util')

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
        if layout.userData.callback then
            assert(layout.userData._root ~= nil)
            layout.userData.callback(mEvent, layout.userData._root)
        end

        --setInnerContentPositionFromScrollbarPosition()
        I.ZHI.updateUI()
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

local function onScrollbarAreaMousePress(mEvent, layout)
    if not layout then return false end
    local handle = ZHIUtil.findLayoutByNameRecursive(layout.content, 'scrollbar_handle')
    if handle then
        local newY = mEvent.offset.y - handle.userData.barHeight * 0.5
        newY = math.max(0, math.min(newY, handle.userData.height - handle.userData.barHeight))
        handle.props.position = util.vector2(handle.props.position.x, newY)
        if handle.userData.callback then
            handle.userData.callback(mEvent, handle.userData._root)
        end
        I.ZHI.updateUI()
    end
    
end

local function createScrollbarArea(iconPath, width, height, barSize, rootLayout, callback)

    local content = ui.content({
        {
            type = ui.TYPE.Widget,
            name = 'scrollbar_bg',
            props = {
                size = util.vector2(width - constants.border * 2, height),
                autoSize = false,
            },
    
            content = ui.content({
                {
                    type = ui.TYPE.Image,
                    name = 'scrollbar_handle',
                    props = {
                        propagateEvents = false,
                        size = util.vector2(width,  barSize),
                        position = util.vector2(0, 0),
                        tileV = true,
                        resource = ZHIUtil.getCachedTexture({--ui.texture({
                            path = 'textures/omw_menu_scroll_center_v.dds',
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
                        _root = rootLayout,
                    },
                },
            }),

            events = {
                mousePress = async:callback(onScrollbarAreaMousePress),
            }
        }
    })

    return {
        -- This is just to give the scrollbar a border
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        userData = {
            scrollbarHandle = ZHIUtil.findLayoutByNameRecursive(content, 'scrollbar_handle'),
        },
        props = {
                
        },
        content = content,
    }
    
end

local function getScrollbarHandleFromLayout(layout)
    if (not layout) or (not layout.content) or (not layout.content[1]) then
        return nil
    end

    if (not layout.content[1].userData) then return nil end
    
    assert(layout.content[1].userData.scrollbarHandle ~= nil)

    return layout.content[1].userData.scrollbarHandle
end

return {

    getScrollbarHandleSize = function(layout)
        local handle = getScrollbarHandleFromLayout(layout)
        if (handle and handle.userData) then
            return handle.userData.barHeight
        end
        return nil
    end,

    getScrollbarHandleData = function(layout)
        local handle = getScrollbarHandleFromLayout(layout)
        if (handle) then
            return handle.userData
        end
    end,

    getScrollbarHandlePosition = function(layout)
        local handle = getScrollbarHandleFromLayout(layout)
        if (handle) then
            return handle.props.position.y
        end
        return nil
    end,

    setScrollbarHandlePosition = function(layout, position)
        local handle = getScrollbarHandleFromLayout(layout)
        if (handle) then
            handle.props.position = util.vector2(handle.props.position.x, position)
        end
    end,

    createScrollbarV = function(width, height, barSize, dragCallback)
        local scrollbar = {
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
        }

        scrollbar.content = ui.content({
            createScrollbarArea('textures/omw_menu_scroll_center_v.dds', width, height, barSize, scrollbar, dragCallback),
        })

        return scrollbar
    end,
}