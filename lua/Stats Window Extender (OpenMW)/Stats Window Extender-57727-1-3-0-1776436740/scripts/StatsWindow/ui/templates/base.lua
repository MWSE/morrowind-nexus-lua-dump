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

local HEADER_HEIGHT = 20
local SCROLL_BAR_OUTER_WIDTH = 16
local SCROLL_BAR_INNER_WIDTH = 14
local BORDER_THICKNESS = omwConstants.border
local BORDER_THICKNESS_THICK = omwConstants.thickBorder

local l10n = core.l10n('StatsWindow')

local Templates = {}

Templates.TEXT_SIZE = configPlayer.window.i_TextSizeOverride > 0 and configPlayer.window.i_TextSizeOverride or omwConstants.textNormalSize or 16

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
    top_left = v2(0, 0),
    top_right = v2(1, 0),
    bottom_left = v2(0, 1),
    bottom_right = v2(1, 1),
}

local borderSidePattern = 'textures/menu_%s_border_%s.dds'
local borderCornerPattern = 'textures/menu_%s_border_%s_corner.dds'

local borderResources = {}
local borderPieces = {}

for _, thickness in ipairs{'thin', 'thick'} do
    borderResources[thickness] = {}
    for k in pairs(borderSideParts) do
        borderResources[thickness][k] = ui.texture{ path = borderSidePattern:format(thickness, k) }
    end
    for k in pairs(borderCornerParts) do
        borderResources[thickness][k] = ui.texture{ path = borderCornerPattern:format(thickness, k) }
    end

    borderPieces[thickness] = {}
    for k in pairs(borderSideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        borderPieces[thickness][k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
                tileH = horizontal,
                tileV = not horizontal,
            },
        }
    end
    for k in pairs(borderCornerParts) do
        borderPieces[thickness][k] = {
            type = ui.TYPE.Image,
            props = {
                resource = borderResources[thickness][k],
            },
        }
    end
end

local function borderTemplates(thickness)
    local borderSize = (thickness == 'thin') and omwConstants.border or omwConstants.thickBorder
    local borderV = v2(1, 1) * borderSize
    local result = {}

    result.bordersDraggable = {
        content = ui.content {},
    }
    for k, v in pairs(borderSideParts) do
        local horizontal = k == 'top' or k == 'bottom'
        local direction = horizontal and v2(1, 0) or v2(0, 1)
        result.bordersDraggable.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = (direction - v) * borderSize,
                relativePosition = v,
                size = (v2(1, 1) - direction * 3) * borderSize,
                relativeSize = direction,
            },
            userData = {
                dragType = k
            }
        }
    end
    for k, v in pairs(borderCornerParts) do
        result.bordersDraggable.content:add {
            template = borderPieces[thickness][k],
            props = {
                position = -v * borderSize,
                relativePosition = v,
                size = borderV,
            },
            userData = {
                dragType = k
            }
        }
    end
    result.bordersDraggable.content:add {
        external = { slot = true },
        props = {
            position = borderV,
            size = borderV * -2,
            relativeSize = v2(1, 1),
        }
    }

    return result
end

Templates.bordersDraggable = borderTemplates('thin').bordersDraggable
Templates.bordersDraggableThick = borderTemplates('thick').bordersDraggable

local buttonBorderSidePattern = 'textures/menu_button_frame_%s.dds'
local buttonBorderCornerPattern = 'textures/menu_button_frame_%s_corner.dds'

local buttonBorderResources = {}
local buttonBorderPieces = {}

for k in pairs(borderSideParts) do
    buttonBorderResources[k] = ui.texture { path = buttonBorderSidePattern:format(k) }
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
    buttonBorderResources[k] = ui.texture { path = buttonBorderCornerPattern:format(k) }
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

    element.layout.userData.update = function()
        updateTextures(element)
    end

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

--- @deprecated
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

--- @deprecated
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

Templates.boxSolid = auxUi.deepLayoutCopy(I.MWUI.templates.boxSolid)
Templates.boxSolid.content[1].props.color = constants.Colors.BACKGROUND

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

local dragTypePointers = {
    [constants.DragType.ResizeL] = 'hresize',
    [constants.DragType.ResizeR] = 'hresize',
    [constants.DragType.ResizeT] = 'vresize',
    [constants.DragType.ResizeB] = 'vresize',
    [constants.DragType.ResizeTL] = 'dresize',
    [constants.DragType.ResizeTR] = 'dresize2',
    [constants.DragType.ResizeBL] = 'dresize2',
    [constants.DragType.ResizeBR] = 'dresize',
    [constants.DragType.Move] = 'arrow',
}

local function makeDraggable(borderTemplate, onDragTypeChanged)
    local template = auxUi.deepLayoutCopy(borderTemplate)
    local content = template.content

    local function setDragType(index)
        local borderPiece = content[index]
        if borderPiece.userData and borderPiece.userData.dragType then
            borderPiece.props.pointer = dragTypePointers[borderPiece.userData.dragType] or 'arrow'
            borderPiece.events = {
                focusGain = async:callback(function(e, layout)
                    if onDragTypeChanged then
                        onDragTypeChanged(layout.userData.dragType)
                    end
                end),
                focusLoss = async:callback(function(e, layout)
                    if onDragTypeChanged then
                        onDragTypeChanged(nil)
                    end
                end),
            }
        end
    end

    for i = 1, 8 do
        setDragType(i)
    end

    return template
end

Templates.window = function(title, content, draggable, onDrag, onDragStop, pinnable, pinned, onPinChanged, ctx)
    local baseTemplate = I.MWUI.templates.bordersThick
    local userData = {}
    if draggable then
        baseTemplate = makeDraggable(Templates.bordersDraggableThick, function(dragType)
            userData.dragType = dragType
        end)
    end
    local window = {
        layer = 'Windows',
        template = baseTemplate,
        props = {},
        content = ui.content {
            {
                name = 'background',
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'transparent' },
                    color = constants.Colors.BACKGROUND,
                    relativeSize = util.vector2(1, 1),
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
                            arrange = ui.ALIGNMENT.Center,
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
                        template = not intRe and baseTemplate,
                        external = {
                            grow = 1,
                            stretch = 1,
                        },
                        content = ui.content(content),
                    },
                }
            },
            {
                name = 'headerBlocker',
                props = {
                    relativeSize = util.vector2(1, 0),
                    size = util.vector2(0, HEADER_HEIGHT),
                },
                events = {
                    focusGain = async:callback(function()
                        if draggable then
                            userData.dragType = constants.DragType.Move
                        end
                    end),
                    focusLoss = async:callback(function()
                        if draggable then
                            userData.dragType = nil
                        end
                    end),
                }
            }
        },
        events = {},
        userData = userData,
    }

    if pinnable ~= nil then
        userData.pinnable = pinnable
    else
        userData.pinnable = false
    end
    userData.pinned = pinned
    local pinButton = Templates.pinButton(userData.pinned, function(newPinned)
        userData.pinned = newPinned
        if onPinChanged then
            onPinChanged(newPinned)
        end
    end)
    pinButton.layout.props.anchor = v2(1, 0)
    pinButton.layout.props.relativePosition = v2(1, 0)
    pinButton.layout.props.visible = userData.pinnable
    window.content:add(pinButton)

    window = ui.create(window)
    
    if draggable then
        local minWidth = 200
        local minHeight = 60
        userData.dragging = false
        userData.dragStartAbs = nil
        userData.dragStartSize = nil
        userData.dragStartPos = nil
        
        window.layout.events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                if userData.dragType == nil then return end
                userData.dragging = true
                userData.dragStartAbs = e.position
                userData.dragStartSize = layout.props.size
                userData.dragStartPos = layout.props.position
                if userData.dragType == constants.DragType.Move then
                    ambient.playSound('menu click')
                end
            end),
            mouseMove = async:callback(function(e, layout)
                minWidth = layout.userData.minWidth or minWidth
                minHeight = layout.userData.minHeight or minHeight
                if ctx then
                    ctx.lastCursorPos = e.position
                    if ctx.cursorAttachedIcon then
                        ctx.cursorAttachedIcon.layout.props.visible = true
                        ctx.cursorAttachedIcon.layout.props.position = e.position
                        ctx.cursorAttachedIcon:update() 
                    end
                end
                if userData.dragging and userData.dragStartAbs and userData.dragStartSize and userData.dragStartPos then
                    local delta = e.position - userData.dragStartAbs
                    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
                    local newSize = userData.dragStartSize
                    local newPos = userData.dragStartPos
                    local dX, dY, w, h

                    -- Horizontal resizing
                    if userData.dragType == constants.DragType.ResizeL or userData.dragType == constants.DragType.ResizeTL or userData.dragType == constants.DragType.ResizeBL then
                        local maxDeltaX = userData.dragStartSize.x - minWidth
                        dX = util.clamp(delta.x, -userData.dragStartPos.x, maxDeltaX)
                        newSize = util.vector2(userData.dragStartSize.x - dX, newSize.y)
                        newPos = util.vector2(userData.dragStartPos.x + dX, newPos.y)
                    elseif userData.dragType == constants.DragType.ResizeR or userData.dragType == constants.DragType.ResizeTR or userData.dragType == constants.DragType.ResizeBR then
                        local maxWidth = layerSize.x - userData.dragStartPos.x
                        w = util.clamp(userData.dragStartSize.x + delta.x, minWidth, maxWidth)
                        newSize = util.vector2(w, newSize.y)
                    end

                    -- Vertical resizing
                    if userData.dragType == constants.DragType.ResizeT or userData.dragType == constants.DragType.ResizeTL or userData.dragType == constants.DragType.ResizeTR then
                        local maxDeltaY = userData.dragStartSize.y - minHeight
                        dY = util.clamp(delta.y, -userData.dragStartPos.y, maxDeltaY)
                        newSize = util.vector2(newSize.x, userData.dragStartSize.y - dY)
                        newPos = util.vector2(newPos.x, userData.dragStartPos.y + dY)
                    elseif userData.dragType == constants.DragType.ResizeB or userData.dragType == constants.DragType.ResizeBL or userData.dragType == constants.DragType.ResizeBR then
                        local maxHeight = layerSize.y - userData.dragStartPos.y
                        h = util.clamp(userData.dragStartSize.y + delta.y, minHeight, maxHeight)
                        newSize = util.vector2(newSize.x, h)
                    end
                    
                    -- Moving
                    if userData.dragType == constants.DragType.Move then
                        newPos = userData.dragStartPos + delta
                        newPos = util.vector2(
                            util.clamp(newPos.x, 0, layerSize.x - newSize.x),
                            util.clamp(newPos.y, 0, layerSize.y - newSize.y)
                        )
                    end

                    layout.props.size = newSize
                    layout.props.position = newPos

                    window:update()

                    if onDrag then
                        onDrag(window.layout, userData.dragType)
                    end
                end
            end),
            focusGain = async:callback(function()
                window.layout.userData.focused = true
            end),
            focusLoss = async:callback(function()
                if ctx then
                    if ctx.cursorAttachedIcon then
                        ctx.cursorAttachedIcon.layout.props.visible = false
                        ctx.updateQueue[ctx.cursorAttachedIcon] = true
                    end
                end
                window.layout.userData.focused = false
            end),
            mouseRelease = async:callback(function(e)
                if e.button ~= 1 then return end
                userData.dragging = false
                if onDragStop then
                    onDragStop(window.layout, userData.dragType)
                end
            end),
        } 
    end

    userData.getInnerSize = function()
        local size = window.layout.props.size
        local borderMult = intRe and 2 or 4
        return util.vector2(
            size.x - BORDER_THICKNESS_THICK * borderMult,
            size.y - BORDER_THICKNESS_THICK * borderMult - HEADER_HEIGHT
        )
    end

    userData.getTitle = function()
        return window.layout.content[2].content[1].content[3].props.text
    end

    userData.setTitle = function(newTitle)
        window.layout.content[2].content[1].content[3].props.text = newTitle
        window:update()
    end

    userData.setPinnable = function(pinnable)
        userData.pinnable = pinnable
        if pinnable then
            pinButton.layout.props.visible = true
            pinButton.layout.userData.update()
        else
            pinButton.layout.props.visible = false
            pinButton.layout.userData.update()
        end
    end

    userData.setPinned = function(pinned)
        userData.pinned = pinned
        pinButton.layout.userData.pinned = pinned
        pinButton.layout.userData.update()
    end
    return window
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