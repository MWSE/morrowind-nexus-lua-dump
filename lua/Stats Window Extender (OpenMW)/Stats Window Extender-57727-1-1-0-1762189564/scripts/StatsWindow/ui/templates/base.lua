local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local ambient = require('openmw.ambient')

local omwConstants = require('scripts.omw.mwui.constants')

local helpers = require('scripts.StatsWindow.util.helpers')
local constants = require('scripts.StatsWindow.util.constants')

local configPlayer = require('scripts.StatsWindow.config.player')

local intRe = configPlayer.modIntegration.b_InterfaceReimagined

local SCROLL_BAR_OUTER_WIDTH = 16
local SCROLL_BAR_INNER_WIDTH = 14
local BORDER_THICKNESS = omwConstants.border

local MENU_TRANSPARENCY = ui._getMenuTransparency()

local l10n = core.l10n('StatsWindow')

local Templates = {}

Templates.TEXT_SIZE = configPlayer.window.i_FontSize

local headerTextures = {
    [1] = ui.texture { path = 'textures/menu_head_block_top_left_corner.dds', },
    [2] = ui.texture { path = 'textures/menu_head_block_top.dds', },
    [3] = ui.texture { path = 'textures/menu_head_block_top_right_corner.dds', },
    [4] = ui.texture { path = 'textures/menu_head_block_left.dds', },
    [5] = ui.texture { path = 'textures/menu_head_block_middle.dds', },
    [6] = ui.texture { path = 'textures/menu_head_block_right.dds', },
    [7] = ui.texture { path = 'textures/menu_head_block_bottom_left_corner.dds', },
    [8] = ui.texture { path = 'textures/menu_head_block_bottom.dds', },
    [9] = ui.texture { path = 'textures/menu_head_block_bottom_right_corner.dds', },
}

local function headerImage(i, tile, size)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = headerTextures[i],
            size = size or util.vector2(0, 0),
            tileH = tile,
            tileV = false,
        },
        external = {
            grow = 1,
            stretch = 1,
        }
    }
end

local headerSection = {
    type = ui.TYPE.Flex,
    props = {
        horizontal = true,
    },
    external = {
        grow = 1,
        stretch = 1,
    },
    content = ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, 20),
            },
            content = ui.content {
                headerImage(1, false, util.vector2(2, 2)),
                headerImage(4, false, util.vector2(2, 16)),
                headerImage(7, false, util.vector2(2, 2)),
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(0, 20),
            },
            content = ui.content {
                headerImage(2, true, util.vector2(0, 2)),
                headerImage(5, true, util.vector2(0, 16)),
                headerImage(8, true, util.vector2(0, 2)),
            },
            external = {
                grow = 1,
                stretch = 1,
            }
        },
        {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(2, 20),
            },
            content = ui.content {
                headerImage(3, false, util.vector2(2, 2)),
                headerImage(6, false, util.vector2(2, 16)),
                headerImage(9, false, util.vector2(2, 2)),
            }
        }
    }
}

Templates.padding = function(size)
    size = util.vector2(1, 1) * size
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
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = util.vector2(1, 1),
                    size = size,
                },
            },
        }
    }
end

Templates.intervalH = function(size)
    return {
        props = {
            size = util.vector2(size, 0),
        },
    }
end

Templates.intervalV = function(size)
    return {
        props = {
            size = util.vector2(0, size),
        },
    }
end

Templates.textNormal = helpers.deepCopy(I.MWUI.templates.textNormal)
Templates.textHeader = helpers.deepCopy(I.MWUI.templates.textHeader)
Templates.textParagraph = helpers.deepCopy(I.MWUI.templates.textParagraph)
Templates.textNormal.props.textColor = constants.Colors.DEFAULT
Templates.textHeader.props.textColor = constants.Colors.DEFAULT_LIGHT
Templates.textParagraph.props.textColor = constants.Colors.DEFAULT
Templates.textNormal.props.textSize = Templates.TEXT_SIZE
Templates.textHeader.props.textSize = Templates.TEXT_SIZE
Templates.textParagraph.props.textSize = Templates.TEXT_SIZE

local v2 = util.vector2
local buttonBorderSize = 4
local borderSideParts = {
    left = v2(0, 0),
    right = v2(1, 0),
    top = v2(0, 0),
    bottom = v2(0, 1),
}
local borderCornerParts = {
    top_left_corner = v2(0, 0),
    top_right_corner = v2(1, 0),
    bottom_left_corner = v2(0, 1),
    bottom_right_corner = v2(1, 1),
}
local buttonBorderPattern = 'textures/menu_button_frame_%s.dds'

local buttonBorderResources = {}
local buttonBorderPieces = {}

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderPattern:format(k) }
    local horizontal = (k == 'top' or k == 'bottom')
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
            tileH = horizontal,
            tileV = not horizontal,
        }
    }
end

for k in pairs(borderCornerParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderPattern:format(k) }
    buttonBorderPieces[k] = {
        type = ui.TYPE.Image,
        props = {
            resource = buttonBorderResources[k],
        }
    }
end

Templates.pinButton = function(pinned, onPinChanged)
    local textures = {
        pinned = function(part, pos, size)
            return {
                type = ui.TYPE.Image,
                props = {
                    position = pos,
                    size = size,
                    resource = ui.texture { path = 'textures/menu_rightbuttondown_' .. part .. '.dds' } 
                }
            }
        end,
        unpinned = function(part, pos, size)
            return {
                type = ui.TYPE.Image,
                props = {
                    position = pos,
                    size = size,
                    resource = ui.texture { path = 'textures/menu_rightbuttonup_' .. part .. '.dds' } 
                }
            }
        end,
    }

    local function updateTextures(element)
        local state = element.layout.userData.pinned and 'pinned' or 'unpinned'
        local content = ui.content {}
        content:add(textures[state]('top_left', v2(0, 0), v2(2, 2)))
        content:add(textures[state]('top', v2(2, 0), v2(15, 2)))
        content:add(textures[state]('top_right', v2(17, 0), v2(2, 2)))
        content:add(textures[state]('left', v2(0, 2), v2(2, 15)))
        content:add(textures[state]('center', v2(2, 2), v2(15, 15)))
        content:add(textures[state]('right', v2(17, 2), v2(2, 15)))
        content:add(textures[state]('bottom_left', v2(0, 17), v2(2, 2)))
        content:add(textures[state]('bottom', v2(2, 17), v2(15, 2)))
        content:add(textures[state]('bottom_right', v2(17, 17), v2(2, 2)))
        element.layout.content = content
        element:update()
    end

    local element = ui.create {
        name = 'pinButton',
        props = {
            size = v2(20, 20),
            propagateEvents = false,
        },
        content = ui.content {},
        userData = {
            pinned = pinned,
        },
        events = {
        },
    }

    element.layout.events.mousePress = async:callback(function(e, layout)
        if e.button ~= 1 then return end
        ambient.playSound('menu click')
        layout.userData.pinned = not layout.userData.pinned
        if onPinChanged then
            onPinChanged(layout.userData.pinned)
        end
        updateTextures(element)
    end)

    updateTextures(element)

    return element
end

Templates.buttonBorders = function(borderSize)
    local buttonBorderSize = borderSize or buttonBorderSize
    local template = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction - v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * buttonBorderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = -v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            }
        }
    end
    template.content:add {
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            size = v2(buttonBorderSize * -2, buttonBorderSize * -2),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

Templates.buttonBox = function()
    local template = {
        type = ui.TYPE.Container,
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = (k == 'top' or k == 'bottom')
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = (direction + v) * buttonBorderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction) * buttonBorderSize,
                relativeSize = direction,
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        template.content:add {
            template = buttonBorderPieces[k],
            props = {
                position = v * buttonBorderSize,
                relativePosition = v,
                size = v2(buttonBorderSize, buttonBorderSize),
            }
        }
    end
    template.content:add {
        external = { slot = true },
        props = {
            position = v2(buttonBorderSize, buttonBorderSize),
            relativeSize = v2(1, 1),
        }
    }
    return template
end

Templates.buttonBoxBgr = function(bgrAlpha)
    local template = auxUi.deepLayoutCopy(Templates.buttonBox())
    template.content:insert(1, {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            color = constants.Colors.BLACK,
            alpha = bgrAlpha or 0,
            relativeSize = v2(1, 1),
            size = v2(buttonBorderSize * 2, buttonBorderSize * 2),
        }
    })
    return template
end

Templates.button = function(text, onClick, name, bgrAlpha)
    local element = ui.create {
        name = name,
        template = Templates.buttonBoxBgr(bgrAlpha),
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = Templates.textNormal,
                        props = {
                            text = text,
                            textColor = constants.Colors.DEFAULT,
                        },
                    }
                },
            },
        },
        events = {},
    }
    element.layout.events.focusGain = async:callback(function()
        element.layout.content[1].content[1].props.textColor = constants.Colors.DEFAULT_LIGHT
        element:update()
    end)
    element.layout.events.focusLoss = async:callback(function()
        element.layout.content[1].content[1].props.textColor = constants.Colors.DEFAULT
        element:update()
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click')
    end)
    element.layout.events.mouseRelease = async:callback(function()
        if onClick then
            onClick()
        end
    end)
    return element
end

Templates.imageButton = function(path, size, onClick, name, bgrAlpha)
    local element = ui.create {
        name = name,
        template = Templates.buttonBoxBgr(bgrAlpha),
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = path },
                            size = size,
                            color = constants.Colors.DEFAULT,
                        }
                    },
                }
            },
        },
        events = {},
    }
    element.layout.events.focusGain = async:callback(function()
        element.layout.content[1].content[1].props.color = constants.Colors.DEFAULT_LIGHT
        element:update()
    end)
    element.layout.events.focusLoss = async:callback(function()
        element.layout.content[1].content[1].props.color = constants.Colors.DEFAULT
        element:update()
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click')
    end)
    element.layout.events.mouseRelease = async:callback(function()
        if onClick then
            onClick()
        end
    end)
    return element
end

Templates.box = function(content)
    return {
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                template = Templates.padding(16),
                content = ui.content { content },
            }
        },
    }
end

Templates.boxWithHeader = function(title, content)
    return {
        template = I.MWUI.templates.boxTransparentThick,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                        },
                        external = {
                            grow = 1,
                            stretch = 1,
                        },
                        content = ui.content { 
                            headerSection, 
                            Templates.intervalH(8),
                            {
                                name = 'title',
                                template = Templates.textNormal,
                                props = {
                                    text = title,
                                }
                            },
                            Templates.intervalH(8),
                            headerSection,
                        },
                    },
                    {
                        template = I.MWUI.templates.boxThick,
                        content = ui.content {
                            {
                                template = Templates.padding(16),
                                content = ui.content { content },
                            }
                        },
                    },
                }
            }
        },
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
        }
    } 
end

local emptyHeaderSection = {
    props = {
        size = util.vector2(0, 20),
    },
    external = {
        grow = 1,
        stretch = 1,
    }
}

Templates.bordersInvisible = auxUi.deepLayoutCopy(I.MWUI.templates.borders)
for _, part in pairs(Templates.bordersInvisible.content) do
    if not part.external then
        part.template = nil
    end
end

Templates.containerWithHeader = function(title, content)
    return {
        template = I.MWUI.templates.bordersThick,
        props = {},
        content = ui.content {
            {
                name = 'background',
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'black' },
                    relativeSize = util.vector2(1, 1),
                    alpha = MENU_TRANSPARENCY,
                }
            },
            {
                name = 'foreground',
                type = ui.TYPE.Flex,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
                content = ui.content {
                    {
                        name = 'header',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                        },
                        external = {
                            stretch = 1,
                        },
                        content = ui.content { 
                            intRe and emptyHeaderSection or headerSection, 
                            Templates.intervalH(8),
                            {
                                name = 'title',
                                template = intRe and Templates.textHeader or Templates.textNormal,
                                props = {
                                    text = title,
                                }
                            },
                            Templates.intervalH(8),
                            intRe and emptyHeaderSection or headerSection,
                        },
                    },
                    {
                        name = 'body',
                        template = not intRe and I.MWUI.templates.bordersThick,
                        external = {
                            grow = 1,
                            stretch = 1,
                        },
                        content = ui.content(content),
                    },
                }
            }
        }
    }
end

Templates.scrollBar = function(scrollable)
    local upButton = {
        template = not intRe and I.MWUI.templates.borders or I.MWUI.templates.bordersInvisible,
        props = {
            size = util.vector2(SCROLL_BAR_INNER_WIDTH, SCROLL_BAR_INNER_WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture {
                        path = 'textures/omw_menu_scroll_up.dds',
                    },
                    size = util.vector2(SCROLL_BAR_INNER_WIDTH-4, SCROLL_BAR_INNER_WIDTH-4),
                }
            }
        },
        events = {
            mousePress = async:callback(function(e)
                if e.button ~= 1 then return end
                ambient.playSound('menu click')
                scrollable.layout.content[1].props.position = scrollable.layout.content[1].props.position + util.vector2(0, scrollable.layout.userData.scrollStep)
                scrollable.layout.content[1].props.position = util.vector2(0, util.clamp(scrollable.layout.content[1].props.position.y, -scrollable.layout.userData.scrollLimit, 0))
                scrollable.layout.userData.onScroll()
            end),
        }
    }

    local downButton = {
        template = not intRe and I.MWUI.templates.borders or I.MWUI.templates.bordersInvisible,
        props = {
            size = util.vector2(SCROLL_BAR_INNER_WIDTH, SCROLL_BAR_INNER_WIDTH),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture {
                        path = 'textures/omw_menu_scroll_down.dds',
                    },
                    size = util.vector2(SCROLL_BAR_INNER_WIDTH-4, SCROLL_BAR_INNER_WIDTH-4),
                }
            }
        },
        events = {
            mousePress = async:callback(function(e)
                if e.button ~= 1 then return end
                ambient.playSound('menu click')
                scrollable.layout.content[1].props.position = scrollable.layout.content[1].props.position - util.vector2(0, scrollable.layout.userData.scrollStep)
                scrollable.layout.content[1].props.position = util.vector2(0, util.clamp(scrollable.layout.content[1].props.position.y, -scrollable.layout.userData.scrollLimit, 0))
                scrollable.layout.userData.onScroll()
            end),
        }
    }

    local function calcScrollBarSize()
        return util.vector2(SCROLL_BAR_INNER_WIDTH, scrollable.layout.props.size.y - (SCROLL_BAR_INNER_WIDTH * 2))
    end
    local function calcHandleSize()
        return math.max((scrollable.layout.props.size.y / (scrollable.layout.userData.scrollLimit + scrollable.layout.props.size.y)) * (scrollable.layout.props.size.y - (SCROLL_BAR_INNER_WIDTH * 2)), SCROLL_BAR_INNER_WIDTH)
    end
    
    local function handlePosToScrollPos(y)
        local scrollBarSize = calcScrollBarSize()
        local handleSize = calcHandleSize()

        y = util.clamp(y - (handleSize / 2), 0, scrollBarSize.y - handleSize)
        local progress = y / (scrollBarSize.y - handleSize)
        return -progress * scrollable.layout.userData.scrollLimit
    end

    local scrollBar = {
        template = not intRe and I.MWUI.templates.borders or I.MWUI.templates.bordersInvisible,
        name = 'scrollBar',
        props = {
            size = calcScrollBarSize(),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = 'handle',
                props = {
                    resource = ui.texture {
                        path = 'textures/omw_menu_scroll_center_v.dds',
                    },
                    size = util.vector2(SCROLL_BAR_INNER_WIDTH - 4, calcHandleSize()),
                    --relativeSize = util.vector2(1, 0),
                    tileV = true,
                    propagateEvents = true,
                },
                events = {
                    mousePress = async:callback(function(e, layout)
                        ambient.playSound('menu click')
                        layout.userData.dragOffset = e.offset.y
                        return false
                    end),
                    mouseRelease = async:callback(function(e, layout)
                        layout.userData.dragOffset = nil
                        return false
                    end),
                },
                userData = {
                    dragOffset = nil,
                }
            }
        },
        events = {
            mouseMove = async:callback(function(e, layout)
                if e.button == 1 then
                    local adjustedY = e.offset.y - (layout.content[1].userData.dragOffset or (calcHandleSize() / 2)) + (calcHandleSize() / 2)
                    scrollable.layout.content[1].props.position = util.vector2(0, handlePosToScrollPos(adjustedY))
                    scrollable.layout.content[1].props.position = util.vector2(0, util.clamp(scrollable.layout.content[1].props.position.y, -scrollable.layout.userData.scrollLimit, 0))
                    scrollable.layout.userData.onScroll()
                end
            end),
            mousePress = async:callback(function(e)
                if e.button == 1 then
                    ambient.playSound('menu click')
                    scrollable.layout.content[1].props.position = util.vector2(0, handlePosToScrollPos(e.offset.y))
                    scrollable.layout.content[1].props.position = util.vector2(0, util.clamp(scrollable.layout.content[1].props.position.y, -scrollable.layout.userData.scrollLimit, 0))
                    scrollable.layout.userData.onScroll()
                end
            end),
        }
    }

    local barWrapper = {
        type = ui.TYPE.Flex,
        name = 'scrollBarWrapper',
        props = {
            position = util.vector2(-SCROLL_BAR_OUTER_WIDTH + (SCROLL_BAR_OUTER_WIDTH - SCROLL_BAR_INNER_WIDTH) / 2 - 2, 0),
            relativePosition = util.vector2(1, 0),
        },
        content = ui.content {
            upButton,
            scrollBar,
            downButton,
        }
    }

    return barWrapper
end

Templates.scrollable = function(size, content, flexSize, scrollStep, alwaysShowBar, onFocusGain, onFocusLoss, startScrollPos, name)
    local scrollWidget = ui.create {
        name = name or 'scrollable',
        props = { size = size },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = flexSize,
                    relativeSize = util.vector2(1, 0),
                    position = util.vector2(0, 0),
                },
                content = content or ui.content{},
            }
        },
        userData = {
            scrollLimit = math.max(flexSize.y - size.y, 0),
            canScroll = flexSize.y > size.y,
            scrollStep = scrollStep,
        },
    }
    scrollWidget.layout.events = {
        focusGain = async:callback(function() onFocusGain(scrollWidget) end),
        focusLoss = async:callback(function() onFocusLoss(scrollWidget) end),
    }

    local scrollBar = Templates.scrollBar(scrollWidget)
    scrollBar.content.scrollBar.props.anchor = util.vector2(1, 0)
    scrollWidget.layout.content:add(scrollBar)

    scrollWidget.layout.userData.onScroll = function()
        scrollWidget.layout.content[1].props.position = util.vector2(0, util.clamp(scrollWidget.layout.content[1].props.position.y, -scrollWidget.layout.userData.scrollLimit, 0))
        local handle = scrollBar.content.scrollBar.content.handle
        local scrollProgress = -scrollWidget.layout.content[1].props.position.y / scrollWidget.layout.userData.scrollLimit
        local handleProgress = (scrollWidget.layout.props.size.y - (SCROLL_BAR_OUTER_WIDTH * 2) - handle.props.size.y - 4) * scrollProgress
        handle.props.position = util.vector2(0, handleProgress)
        scrollWidget:update()
    end

    if startScrollPos then
        scrollWidget.layout.content[1].props.position = util.vector2(0, util.clamp(startScrollPos, -scrollWidget.layout.userData.scrollLimit, 0))
    end

    scrollWidget.layout.userData.update = function(outerSize, innerSize)
        outerSize = outerSize or scrollWidget.layout.props.size
        innerSize = innerSize or scrollWidget.layout.content[1].props.size

        local scrollLimit = math.max(innerSize.y - outerSize.y, 0)
        local canScroll = scrollLimit > 0

        scrollWidget.layout.props.size = outerSize
        scrollWidget.layout.content[1].props.size = innerSize
        scrollWidget.layout.userData.scrollLimit = scrollLimit
        scrollWidget.layout.userData.canScroll = canScroll

        scrollBar.content.scrollBar.props.size = util.vector2(
            SCROLL_BAR_INNER_WIDTH,
            scrollWidget.layout.props.size.y - (SCROLL_BAR_OUTER_WIDTH * 2)
        )
        if canScroll then
            scrollBar.content.scrollBar.content.handle.props.size = util.vector2(
                SCROLL_BAR_INNER_WIDTH - BORDER_THICKNESS * 2 - 1,
                math.max((scrollWidget.layout.props.size.y / (scrollWidget.layout.userData.scrollLimit + scrollWidget.layout.props.size.y)) * (scrollWidget.layout.props.size.y - (SCROLL_BAR_OUTER_WIDTH * 2)), SCROLL_BAR_INNER_WIDTH)
            )
        else
            scrollBar.content.scrollBar.content.handle.props.size = util.vector2(0, 0)
        end
        if canScroll or alwaysShowBar then
            scrollWidget.layout.content[1].props.size = util.vector2(-SCROLL_BAR_OUTER_WIDTH - BORDER_THICKNESS * 2, scrollWidget.layout.content[1].props.size.y)
            scrollBar.props.visible = true
        else
            scrollWidget.layout.content[1].props.size = util.vector2(0, scrollWidget.layout.content[1].props.size.y)
            scrollBar.props.visible = false
        end
        scrollWidget.layout.userData.onScroll()
    end

    scrollWidget.layout.userData.update(size, flexSize)
    
    return scrollWidget
end

Templates.wrapper = {
    layer = 'Windows',
    props = {
        relativeSize = util.vector2(1, 1),
    },
    content = ui.content {}
}

return Templates