local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local mwui = require('scripts.omw.mwui.constants')
local v2 = util.vector2

local Templates = {}
local buttonBorderSize = 4
local buttonBorderSidePattern = 'textures/menu_button_frame_%s.dds'
local buttonBorderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'
local buttonBorderParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local buttonCornerParts = {
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1),
}

Templates.colors = {
    normal = mwui.normalColor,
    header = mwui.headerColor,
    disabled = util.color.rgb(0.45, 0.40, 0.32),
    background = util.color.rgb(0, 0, 0),
}

Templates.invisibleBorders = auxUi.deepLayoutCopy(I.MWUI.templates.borders)
for _, part in pairs(Templates.invisibleBorders.content) do
    if not part.external then
        part.template = nil
    end
end

local function textureResource(path)
    return ui.texture { path = path }
end

function Templates.buttonFrameContent()
    local content = ui.content {}
    for key, anchor in pairs(buttonBorderParts) do
        local horizontal = key == 'top' or key == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        content:add {
            type = ui.TYPE.Image,
            props = {
                resource = textureResource(buttonBorderSidePattern:format(key)),
                position = (direction - anchor) * buttonBorderSize,
                relativePosition = anchor,
                size = (v2(1, 1) - direction * 3) * buttonBorderSize,
                relativeSize = direction,
                tileH = horizontal,
                tileV = not horizontal,
            },
        }
    end
    for key, anchor in pairs(buttonCornerParts) do
        content:add {
            type = ui.TYPE.Image,
            props = {
                resource = textureResource(buttonBorderCornerPattern:format(key)),
                position = -anchor * buttonBorderSize,
                relativePosition = anchor,
                size = v2(buttonBorderSize, buttonBorderSize),
            },
        }
    end
    return content
end

function Templates.gmst(key, fallback)
    local value = core.getGMST(key)
    if value == nil or value == '' then
        return fallback
    end
    return value
end

function Templates.text(text, size, alignH, color)
    return {
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            textColor = color or Templates.colors.normal,
            size = size,
            autoSize = size == nil,
            textAlignH = alignH or ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
end

function Templates.effectIcon(effectId, size)
    size = size or v2(16, 16)
    local effect = core.magic.effects.records[effectId]
    local props = {
        size = size,
    }

    if not effect or not effect.icon or effect.icon == '' then
        return {
            props = props,
        }
    end
    props.resource = ui.texture { path = effect.icon }
    return {
        type = ui.TYPE.Image,
        props = props,
    }
end

function Templates.padding(size)
    size = v2(1, 1) * size
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = size,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = size,
                    relativeSize = v2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = v2(1, 1),
                    size = size,
                },
            },
        },
    }
end

function Templates.tooltip(padding, content, name)
    return {
        layer = 'Notification',
        name = name,
        template = I.MWUI.templates.boxSolid,
        props = {},
        content = ui.content {
            {
                name = 'padding',
                template = Templates.padding(padding),
                content = content or ui.content {},
            },
        },
    }
end

function Templates.button(text, size, onClick, options)
    options = options or {}
    local normalColor = options.disabled and Templates.colors.disabled
        or options.normalColor
        or Templates.colors.normal
    local hoverColor = options.disabled and Templates.colors.disabled
        or options.hoverColor
        or Templates.colors.header
    local content = Templates.buttonFrameContent()
    content:add {
        name = 'label',
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            textColor = normalColor,
            position = v2(0, 0),
            size = size,
            autoSize = false,
            textAlignH = options.alignH or ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }

    local button = {
        type = ui.TYPE.Widget,
        props = {
            size = size,
        },
        content = content,
        events = {},
        userData = {
            disabled = options.disabled == true,
        },
    }

    if not options.disabled and onClick then
        local function setHovered(layout, hovered)
            layout.content.label.props.textColor = hovered and hoverColor or normalColor
            if options.onHover then
                options.onHover(layout, hovered)
            end
            if options.update then
                options.update()
            end
        end

        button.events.focusGain = async:callback(function(_, layout)
            setHovered(layout, true)
            return true
        end)
        button.events.focusLoss = async:callback(function(_, layout)
            setHovered(layout, false)
            return true
        end)
        button.events.mouseMove = async:callback(function(_, layout)
            setHovered(layout, true)
            return true
        end)
        button.events.mousePress = async:callback(function(e)
            if e.button == 1 then
                ambient.playSound('menu click')
            end
            return true
        end)
        button.events.mouseRelease = async:callback(function(e)
            if e.button == 1 then
                onClick()
            end
            return true
        end)
    end

    return button
end

function Templates.textRowButton(text, size, onClick, options)
    options = options or {}
    local icon = options.icon
    local iconLayoutSize = options.iconSize
        or (icon and icon.props and icon.props.size)
        or v2(16, 16)
    local iconLeftPadding = icon and (options.iconLeftPadding or 0) or 0
    local iconGap = options.iconGap or 4
    local labelOffset = icon and (iconLeftPadding + iconLayoutSize.x + iconGap) or 0
    local labelSize = v2(math.max(0, size.x - labelOffset), size.y)
    local disabledColor = options.disabledColor or Templates.colors.disabled
    local normalColor = options.disabled and disabledColor
        or options.normalColor
        or Templates.colors.normal
    local hoverColor = options.disabled and disabledColor
        or options.hoverColor
        or Templates.colors.header
    local content = ui.content {}

    if icon then
        icon.props = icon.props or {}
        icon.props.position = icon.props.position
            or v2(iconLeftPadding, math.floor((size.y - iconLayoutSize.y) / 2))
        content:add(icon)
    end

    content:add({
        name = 'label',
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            textColor = normalColor,
            position = v2(labelOffset, 0),
            size = labelSize,
            autoSize = false,
            textAlignH = options.alignH or ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
        },
    })

    local row = {
        type = ui.TYPE.Container,
        props = {
            size = size,
        },
        content = content,
        events = {},
        userData = {
            disabled = options.disabled == true,
            disabledColor = disabledColor,
            normalColor = normalColor,
            hoverColor = hoverColor,
        },
    }

    if (not options.disabled and onClick)
        or options.onFocusGain
        or options.onFocusLoss
        or options.onMouseMove then
        row.events.focusGain = async:callback(function(_, layout)
            layout.content.label.props.textColor = hoverColor
            if options.onFocusGain then
                options.onFocusGain(layout)
            end
            if options.update then
                options.update()
            end
            return true
        end)
        row.events.focusLoss = async:callback(function(_, layout)
            layout.content.label.props.textColor = normalColor
            if options.onFocusLoss then
                options.onFocusLoss(layout)
            end
            if options.update then
                options.update()
            end
            return true
        end)
        row.events.mouseMove = async:callback(function(e, layout)
            if options.onMouseMove then
                options.onMouseMove(e, layout)
            end
            return true
        end)
    end

    if not options.disabled and onClick then
        row.events.mousePress = async:callback(function(e)
            if e.button == 1 then
                ambient.playSound('menu click')
            end
            return true
        end)
        row.events.mouseRelease = async:callback(function(e)
            if e.button == 1 then
                onClick()
            end
            return true
        end)
    end

    return row
end

function Templates.scrollbar(scrollable)
    local buttonSize = 14
    local scrollbarWidth = 16
    local scrollbarVerticalMargin = 2
    local scrollbarHeight = scrollable.layout.props.size.y - scrollbarVerticalMargin * 2
    local handleBottomPadding = 2

    local function maxHandleTravel(scrollbar)
        local track = scrollbar.content.track
        local handle = track.content.handle
        return math.max(0, track.props.size.y - handle.props.size.y - handleBottomPadding)
    end

    local function syncHandle()
        local layout = scrollable.layout
        if not layout or not layout.content.scrollbar then
            return
        end
        local scrollbar = layout.content.scrollbar
        local track = scrollbar.content.track
        local handle = track.content.handle
        local limit = layout.userData.scrollLimit
        if limit <= 0 then
            handle.props.visible = false
            handle.props.position = v2(0, 0)
        else
            handle.props.visible = true
            local progress = -layout.content.rows.props.position.y / limit
            handle.props.position = v2(0, maxHandleTravel(scrollbar) * progress)
        end
    end

    local function scrollBy(delta)
        local layout = scrollable.layout
        if not layout then
            return
        end
        local y = util.clamp(layout.content.rows.props.position.y + delta, -layout.userData.scrollLimit, 0)
        layout.content.rows.props.position = v2(0, y)
        syncHandle()
        scrollable:update()
    end

    local function scrollToTrackOffset(offsetY)
        local layout = scrollable.layout
        if not layout or layout.userData.scrollLimit <= 0 then
            return
        end
        local scrollbar = layout.content.scrollbar
        local track = scrollbar.content.track
        local handle = track.content.handle
        local travel = maxHandleTravel(scrollbar)
        if travel <= 0 then
            return
        end

        local y = util.clamp(offsetY - handle.props.size.y / 2, 0, travel)
        layout.content.rows.props.position = v2(0, -layout.userData.scrollLimit * (y / travel))
        syncHandle()
        scrollable:update()
    end

    local arrow = function(texture, direction)
        return {
            template = I.MWUI.templates.borders,
            props = {
                size = v2(buttonSize, buttonSize),
            },
            content = ui.content {{
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = texture },
                    size = v2(buttonSize - 4, buttonSize - 4),
                },
            }},
            events = {
                mousePress = async:callback(function(e)
                    if e.button == 1 then
                        ambient.playSound('menu click')
                        scrollBy(direction * scrollable.layout.userData.scrollStep)
                    end
                    return true
                end),
            },
        }
    end

    return {
        name = 'scrollbar',
        type = ui.TYPE.Flex,
        props = {
            position = v2(-scrollbarWidth, scrollbarVerticalMargin),
            relativePosition = v2(1, 0),
            size = v2(scrollbarWidth, scrollbarHeight),
        },
        userData = {
            syncHandle = syncHandle,
        },
        content = ui.content {
            arrow('textures/omw_menu_scroll_up.dds', 1),
            {
                name = 'track',
                template = I.MWUI.templates.borders,
                props = {
                    size = v2(buttonSize, scrollbarHeight - buttonSize * 2),
                },
                content = ui.content {{
                    name = 'handle',
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'textures/omw_menu_scroll_center_v.dds' },
                        size = v2(buttonSize - 4, math.max(buttonSize, scrollable.layout.userData.handleHeight)),
                        tileV = true,
                    },
                    events = {
                        mousePress = async:callback(function(e)
                            if e.button ~= 1 then
                                return true
                            end
                            ambient.playSound('menu click')
                            scrollable.layout.userData.draggingScrollbar = true
                            scrollable.layout.userData.scrollbarDragOffset = e.offset.y
                            return true
                        end),
                        mouseRelease = async:callback(function(e)
                            if e.button == 1 then
                                scrollable.layout.userData.draggingScrollbar = false
                                scrollable.layout.userData.scrollbarDragOffset = nil
                            end
                            return true
                        end),
                    },
                }},
                events = {
                    mousePress = async:callback(function(e)
                        if e.button ~= 1 then
                            return true
                        end
                        ambient.playSound('menu click')
                        scrollable.layout.userData.draggingScrollbar = true
                        scrollable.layout.userData.scrollbarDragOffset = nil
                        scrollToTrackOffset(e.offset.y)
                        return true
                    end),
                    mouseMove = async:callback(function(e)
                        if e.button == 1 or scrollable.layout.userData.draggingScrollbar then
                            local dragOffset = scrollable.layout.userData.scrollbarDragOffset
                            if dragOffset then
                                local handle = scrollable.layout.content.scrollbar.content.track.content.handle
                                scrollToTrackOffset(e.offset.y - dragOffset + handle.props.size.y / 2)
                            else
                                scrollToTrackOffset(e.offset.y)
                            end
                        end
                        return true
                    end),
                    mouseRelease = async:callback(function(e)
                        if e.button == 1 then
                            scrollable.layout.userData.draggingScrollbar = false
                            scrollable.layout.userData.scrollbarDragOffset = nil
                        end
                        return true
                    end),
                },
            },
            arrow('textures/omw_menu_scroll_down.dds', -1),
        },
    }
end

function Templates.scrollable(
    size, rowsContent, contentHeight, rowHeight, onFocusGain, onFocusLoss, startScroll, onMouseMove)
    local scrollLimit = math.max(0, contentHeight - size.y)
    local handleHeight = size.y
    if scrollLimit > 0 then
        handleHeight = math.max(14, (size.y / (scrollLimit + size.y)) * (size.y - 28))
    end

    local element = ui.create {
        name = 'spellList',
        props = {
            size = size,
        },
        content = ui.content {
            {
                name = 'rows',
                type = ui.TYPE.Flex,
                props = {
                    size = v2(size.x - 18, contentHeight),
                    autoSize = false,
                    position = v2(0, -util.clamp(startScroll or 0, 0, scrollLimit)),
                },
                content = rowsContent,
            },
        },
        userData = {
            scrollLimit = scrollLimit,
            scrollStep = rowHeight * 2,
            handleHeight = handleHeight,
            getScrollPos = function(layout)
                return -layout.content.rows.props.position.y
            end,
            scrollBy = function(layout, delta)
                layout.content.rows.props.position = v2(
                    0,
                    util.clamp(layout.content.rows.props.position.y + delta, -layout.userData.scrollLimit, 0))
                if layout.content.scrollbar then
                    layout.content.scrollbar.userData.syncHandle()
                end
            end,
        },
        events = {
            focusGain = async:callback(function(_, layout)
                if onFocusGain then
                    onFocusGain(layout)
                end
                return true
            end),
            focusLoss = async:callback(function(_, layout)
                if onFocusLoss then
                    onFocusLoss(layout)
                end
                return true
            end),
            mouseMove = async:callback(function(e, layout)
                if onMouseMove then
                    onMouseMove(e.offset, layout, e.position)
                end
                return true
            end),
        },
    }

    local scrollbar = Templates.scrollbar(element)
    scrollbar.props.visible = scrollLimit > 0
    element.layout.content:add(scrollbar)
    if element.layout.content.scrollbar then
        element.layout.content.scrollbar.userData.syncHandle()
    end

    return element
end

return Templates
