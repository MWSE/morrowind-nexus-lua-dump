-- Morrowind-style window with move/resize handling
-- Provides a reusable window frame with drag and resize support

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local BORDER_SIZE = 4
local INNER_BORDER_SIZE = 4  -- bordersThick template adds another 4px border
local CORNER_HIT_SIZE = 10  -- Larger hit area for corner resize handles
local HEADER_HEIGHT = 20
local MIN_WIDTH = 200
local MIN_HEIGHT = 200
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 300

local textures = {
    border = {
        left = ui.texture { path = 'textures/menu_thick_border_left.dds' },
        right = ui.texture { path = 'textures/menu_thick_border_right.dds' },
        top = ui.texture { path = 'textures/menu_thick_border_top.dds' },
        bottom = ui.texture { path = 'textures/menu_thick_border_bottom.dds' },
        topLeft = ui.texture { path = 'textures/menu_thick_border_top_left_corner.dds' },
        topRight = ui.texture { path = 'textures/menu_thick_border_top_right_corner.dds' },
        bottomLeft = ui.texture { path = 'textures/menu_thick_border_bottom_left_corner.dds' },
        bottomRight = ui.texture { path = 'textures/menu_thick_border_bottom_right_corner.dds' },
    },
    header = {
        ui.texture { path = 'textures/menu_head_block_top_left_corner.dds' },
        ui.texture { path = 'textures/menu_head_block_top.dds' },
        ui.texture { path = 'textures/menu_head_block_top_right_corner.dds' },
        ui.texture { path = 'textures/menu_head_block_left.dds' },
        ui.texture { path = 'textures/menu_head_block_middle.dds' },
        ui.texture { path = 'textures/menu_head_block_right.dds' },
        ui.texture { path = 'textures/menu_head_block_bottom_left_corner.dds' },
        ui.texture { path = 'textures/menu_head_block_bottom.dds' },
        ui.texture { path = 'textures/menu_head_block_bottom_right_corner.dds' },
    },
    pinButtonUp = {
        topLeft = ui.texture { path = 'textures/menu_rightbuttonup_top_left.dds' },
        top = ui.texture { path = 'textures/menu_rightbuttonup_top.dds' },
        topRight = ui.texture { path = 'textures/menu_rightbuttonup_top_right.dds' },
        left = ui.texture { path = 'textures/menu_rightbuttonup_left.dds' },
        center = ui.texture { path = 'textures/menu_rightbuttonup_center.dds' },
        right = ui.texture { path = 'textures/menu_rightbuttonup_right.dds' },
        bottomLeft = ui.texture { path = 'textures/menu_rightbuttonup_bottom_left.dds' },
        bottom = ui.texture { path = 'textures/menu_rightbuttonup_bottom.dds' },
        bottomRight = ui.texture { path = 'textures/menu_rightbuttonup_bottom_right.dds' },
    },
    pinButtonDown = {
        topLeft = ui.texture { path = 'textures/menu_rightbuttondown_top_left.dds' },
        top = ui.texture { path = 'textures/menu_rightbuttondown_top.dds' },
        topRight = ui.texture { path = 'textures/menu_rightbuttondown_top_right.dds' },
        left = ui.texture { path = 'textures/menu_rightbuttondown_left.dds' },
        center = ui.texture { path = 'textures/menu_rightbuttondown_center.dds' },
        right = ui.texture { path = 'textures/menu_rightbuttondown_right.dds' },
        bottomLeft = ui.texture { path = 'textures/menu_rightbuttondown_bottom_left.dds' },
        bottom = ui.texture { path = 'textures/menu_rightbuttondown_bottom.dds' },
        bottomRight = ui.texture { path = 'textures/menu_rightbuttondown_bottom_right.dds' },
    },
    black = ui.texture { path = 'white' },
}

-- Drag types
local DRAG = {
    None = 0,
    Move = 1,
    ResizeL = 2,
    ResizeR = 3,
    ResizeT = 4,
    ResizeB = 5,
    ResizeTL = 6,
    ResizeTR = 7,
    ResizeBL = 8,
    ResizeBR = 9,
    Content = 10,  -- Content-specific drag (e.g., panning)
}

-- Create a single header decoration column (3 rows: top corner, middle, bottom corner)
local function createHeaderColumn(topTex, midTex, botTex, width, tile)
    return {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(width, HEADER_HEIGHT),
        },
        content = ui.content {
            { type = ui.TYPE.Image, props = { resource = topTex, size = util.vector2(width, 2), tileH = tile } },
            { type = ui.TYPE.Image, props = { resource = midTex, size = util.vector2(width, 16), tileH = tile } },
            { type = ui.TYPE.Image, props = { resource = botTex, size = util.vector2(width, 2), tileH = tile } },
        },
    }
end

-- Create a decorative header section (stretches to fill available space)
local function createHeaderSection()
    local t = textures.header
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        external = { grow = 1, stretch = 1 },
        content = ui.content {
            createHeaderColumn(t[1], t[4], t[7], 2, false),
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = util.vector2(0, HEADER_HEIGHT) },
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                    { type = ui.TYPE.Image, props = { resource = t[2], size = util.vector2(0, 2), relativeSize = util.vector2(1, 0), tileH = true } },
                    { type = ui.TYPE.Image, props = { resource = t[5], size = util.vector2(0, 16), relativeSize = util.vector2(1, 0), tileH = true } },
                    { type = ui.TYPE.Image, props = { resource = t[8], size = util.vector2(0, 2), relativeSize = util.vector2(1, 0), tileH = true } },
                },
            },
            createHeaderColumn(t[3], t[6], t[9], 2, false),
        },
    }
end

-- Pin button constants (based on texture sizes: corners 2x2, edges 2x16/16x2, center 16x16).
-- However, native pin buttons seem to be 19x19 rather than 20x20.
local PIN_BUTTON_SIZE = 19
local PIN_BUTTON_EDGE = 2

-- Create a 9-piece pin button
local function createPinButton(buttonTextures)
    local edge = PIN_BUTTON_EDGE
    local center = PIN_BUTTON_SIZE - edge * 2
    return {
        name = 'pinButton',
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(PIN_BUTTON_SIZE, PIN_BUTTON_SIZE),
            -- Position in top-right, accounting for border
            relativePosition = util.vector2(1, 0),
            position = util.vector2(-BORDER_SIZE - PIN_BUTTON_SIZE - 1, BORDER_SIZE),
            pointer = 'arrow',
        },
        content = ui.content {
            -- Top row
            { type = ui.TYPE.Image, props = { resource = buttonTextures.topLeft, position = util.vector2(0, 0), size = util.vector2(edge, edge) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.top, position = util.vector2(edge, 0), size = util.vector2(center, edge) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.topRight, position = util.vector2(edge + center, 0), size = util.vector2(edge, edge) } },
            -- Middle row
            { type = ui.TYPE.Image, props = { resource = buttonTextures.left, position = util.vector2(0, edge), size = util.vector2(edge, center) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.center, position = util.vector2(edge, edge), size = util.vector2(center, center) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.right, position = util.vector2(edge + center, edge), size = util.vector2(edge, center) } },
            -- Bottom row
            { type = ui.TYPE.Image, props = { resource = buttonTextures.bottomLeft, position = util.vector2(0, edge + center), size = util.vector2(edge, edge) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.bottom, position = util.vector2(edge, edge + center), size = util.vector2(center, edge) } },
            { type = ui.TYPE.Image, props = { resource = buttonTextures.bottomRight, position = util.vector2(edge + center, edge + center), size = util.vector2(edge, edge) } },
        },
    }
end

-- Window template with borders, title bar, and content slot
local template = {
    type = ui.TYPE.Widget,
    content = ui.content {
        -- Semi-transparent black background
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.black,
                color = util.color.rgb(0, 0, 0),
                alpha = 0.8,
                relativeSize = util.vector2(1, 1),
            },
        },
        -- Borders with resize cursors
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.left,
                position = util.vector2(0, BORDER_SIZE),
                size = util.vector2(BORDER_SIZE, -BORDER_SIZE * 2),
                relativeSize = util.vector2(0, 1),
                tileV = true,
                pointer = 'hresize',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.right,
                relativePosition = util.vector2(1, 0),
                position = util.vector2(-BORDER_SIZE, BORDER_SIZE),
                size = util.vector2(BORDER_SIZE, -BORDER_SIZE * 2),
                relativeSize = util.vector2(0, 1),
                tileV = true,
                pointer = 'hresize',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.top,
                position = util.vector2(BORDER_SIZE, 0),
                size = util.vector2(-BORDER_SIZE * 2, BORDER_SIZE),
                relativeSize = util.vector2(1, 0),
                tileH = true,
                pointer = 'vresize',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.bottom,
                relativePosition = util.vector2(0, 1),
                position = util.vector2(BORDER_SIZE, -BORDER_SIZE),
                size = util.vector2(-BORDER_SIZE * 2, BORDER_SIZE),
                relativeSize = util.vector2(1, 0),
                tileH = true,
                pointer = 'vresize',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.topLeft,
                size = util.vector2(BORDER_SIZE, BORDER_SIZE),
                pointer = 'dresize',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.topRight,
                relativePosition = util.vector2(1, 0),
                position = util.vector2(-BORDER_SIZE, 0),
                size = util.vector2(BORDER_SIZE, BORDER_SIZE),
                pointer = 'dresize2',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.bottomLeft,
                relativePosition = util.vector2(0, 1),
                position = util.vector2(0, -BORDER_SIZE),
                size = util.vector2(BORDER_SIZE, BORDER_SIZE),
                pointer = 'dresize2',
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textures.border.bottomRight,
                relativePosition = util.vector2(1, 1),
                position = util.vector2(-BORDER_SIZE, -BORDER_SIZE),
                size = util.vector2(BORDER_SIZE, BORDER_SIZE),
                pointer = 'dresize',
            }
        },
        -- Title bar
        {
            name = 'titleBar',
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                position = util.vector2(BORDER_SIZE, BORDER_SIZE),
                size = util.vector2(-BORDER_SIZE * 2, HEADER_HEIGHT),
                relativeSize = util.vector2(1, 0),
            },
            content = ui.content {
                createHeaderSection(),
                { props = { size = util.vector2(8, 0) } },
                {
                    name = 'titleContainer',
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(0, HEADER_HEIGHT),
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            name = 'titleText',
                            type = ui.TYPE.Text,
                            template = I.MWUI.templates.textHeader,
                            props = { text = 'Map' },
                        },
                    },
                },
                { props = { size = util.vector2(8, 0) } },
                createHeaderSection(),
            },
        },
        -- Pin button (superimposed over title bar)
        createPinButton(textures.pinButtonUp),
        -- Inner border (wraps content area, below header)
        {
            template = I.MWUI.templates.bordersThick,
            props = {
                position = util.vector2(BORDER_SIZE, BORDER_SIZE + HEADER_HEIGHT),
                size = util.vector2(-BORDER_SIZE * 2, -BORDER_SIZE * 2 - HEADER_HEIGHT),
                relativeSize = util.vector2(1, 1),
            },
            content = ui.content {
                -- Content slot (inside inner border)
                {
                    external = { slot = true },
                    props = {
                        relativeSize = util.vector2(1, 1),
                    },
                },
            },
        },
    },
}

-- Helper to update all 9 pin button images with new textures
local function updatePinButtonTextures(pinButton, buttonTextures)
    local images = pinButton.content
    images[1].props.resource = buttonTextures.topLeft
    images[2].props.resource = buttonTextures.top
    images[3].props.resource = buttonTextures.topRight
    images[4].props.resource = buttonTextures.left
    images[5].props.resource = buttonTextures.center
    images[6].props.resource = buttonTextures.right
    images[7].props.resource = buttonTextures.bottomLeft
    images[8].props.resource = buttonTextures.bottom
    images[9].props.resource = buttonTextures.bottomRight
end

-- Clamp window position to keep it within the viewport
local function clampToViewport(position, size)
    local screen = ui.screenSize()
    return util.vector2(
        math.max(0, math.min(position.x, screen.x - size.x)),
        math.max(0, math.min(position.y, screen.y - size.y))
    )
end

-- Create a window with move/resize handling
-- opts: { position, size, content, onResize, onMove, onContentDrag, onContentDragStart, onContentDragEnd, onMouseMove, onPinToggle, onTitleDoubleClick, onContentDoubleClick }
local function create(opts)
    local element = nil
    local dragging = false
    local dragType = DRAG.None
    local dragStartPos = nil
    local dragStartSize = nil
    local dragStartMousePos = nil
    local isPinned = false

    -- Calculate content size from window size (accounts for outer border, header, and inner border)
    local function getContentSize(windowSize)
        local totalBorder = BORDER_SIZE + INNER_BORDER_SIZE
        return util.vector2(
            windowSize.x - totalBorder * 2,
            windowSize.y - totalBorder * 2 - HEADER_HEIGHT
        )
    end

    -- Determine drag type based on cursor position
    local function getDragType(offset, size)
        local headerHeight = BORDER_SIZE + HEADER_HEIGHT
        -- Use larger hit area for corners
        local inCornerTop = offset.y < CORNER_HIT_SIZE
        local inCornerBottom = offset.y > size.y - CORNER_HIT_SIZE
        local inCornerLeft = offset.x < CORNER_HIT_SIZE
        local inCornerRight = offset.x > size.x - CORNER_HIT_SIZE
        -- Standard edge detection for non-corner edges
        local topEdge = offset.y < BORDER_SIZE
        local bottomEdge = offset.y > size.y - BORDER_SIZE
        local leftEdge = offset.x < BORDER_SIZE
        local rightEdge = offset.x > size.x - BORDER_SIZE
        local inHeader = offset.y < headerHeight

        -- Check corners first (using larger hit area)
        if inCornerTop and inCornerLeft then return DRAG.ResizeTL
        elseif inCornerTop and inCornerRight then return DRAG.ResizeTR
        elseif inCornerBottom and inCornerLeft then return DRAG.ResizeBL
        elseif inCornerBottom and inCornerRight then return DRAG.ResizeBR
        -- Then check edges (using border size)
        elseif leftEdge then return DRAG.ResizeL
        elseif rightEdge then return DRAG.ResizeR
        elseif topEdge then return DRAG.ResizeT
        elseif bottomEdge then return DRAG.ResizeB
        elseif inHeader then return DRAG.Move
        else return DRAG.Content
        end
    end

    -- Handle resize drag
    local function handleResize(layout, delta)
        local newW, newH = dragStartSize.x, dragStartSize.y
        local newX, newY = dragStartPos.x, dragStartPos.y

        if dragType == DRAG.ResizeR then
            newW = math.max(MIN_WIDTH, dragStartSize.x + delta.x)
        elseif dragType == DRAG.ResizeB then
            newH = math.max(MIN_HEIGHT, dragStartSize.y + delta.y)
        elseif dragType == DRAG.ResizeBR then
            newW = math.max(MIN_WIDTH, dragStartSize.x + delta.x)
            newH = math.max(MIN_HEIGHT, dragStartSize.y + delta.y)
        elseif dragType == DRAG.ResizeL then
            newW = math.max(MIN_WIDTH, dragStartSize.x - delta.x)
            newX = dragStartPos.x + (dragStartSize.x - newW)
        elseif dragType == DRAG.ResizeT then
            newH = math.max(MIN_HEIGHT, dragStartSize.y - delta.y)
            newY = dragStartPos.y + (dragStartSize.y - newH)
        elseif dragType == DRAG.ResizeTL then
            newW = math.max(MIN_WIDTH, dragStartSize.x - delta.x)
            newH = math.max(MIN_HEIGHT, dragStartSize.y - delta.y)
            newX = dragStartPos.x + (dragStartSize.x - newW)
            newY = dragStartPos.y + (dragStartSize.y - newH)
        elseif dragType == DRAG.ResizeTR then
            newW = math.max(MIN_WIDTH, dragStartSize.x + delta.x)
            newH = math.max(MIN_HEIGHT, dragStartSize.y - delta.y)
            newY = dragStartPos.y + (dragStartSize.y - newH)
        elseif dragType == DRAG.ResizeBL then
            newW = math.max(MIN_WIDTH, dragStartSize.x - delta.x)
            newH = math.max(MIN_HEIGHT, dragStartSize.y + delta.y)
            newX = dragStartPos.x + (dragStartSize.x - newW)
        end

        local newSize = util.vector2(newW, newH)
        local newPos = clampToViewport(util.vector2(newX, newY), newSize)
        layout.props.size = newSize
        layout.props.position = newPos

        if opts.onResize then
            opts.onResize(getContentSize(newSize))
        end

        element:update()
    end

    -- Get the pin button from the template
    local function getPinButton()
        return element.layout.template.content.pinButton
    end

    -- Toggle pin state and update button appearance
    local function togglePin()
        isPinned = not isPinned
        local pinButton = getPinButton()
        local buttonTextures = isPinned and textures.pinButtonDown or textures.pinButtonUp
        updatePinButtonTextures(pinButton, buttonTextures)
        element:update()
        if opts.onPinToggle then
            opts.onPinToggle(isPinned)
        end
    end

    element = ui.create {
        layer = 'Windows',
        template = template,
        props = {
            visible = false,
            position = opts.position or util.vector2(400, 100),
            size = opts.size or util.vector2(DEFAULT_WIDTH, DEFAULT_HEIGHT),
        },
        content = opts.content,
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end

                -- Calculate drag type from click position (can't rely on mouseMove
                -- since child widgets like title text may block mouseMove events)
                dragType = getDragType(e.offset, layout.props.size)
                if dragType == DRAG.None then return end

                dragging = true
                dragStartMousePos = e.position
                dragStartPos = layout.props.position
                dragStartSize = layout.props.size

                if dragType == DRAG.Content and opts.onContentDragStart then
                    opts.onContentDragStart(e)
                end
            end),
            mouseRelease = async:callback(function(e)
                if e.button ~= 1 then return end
                if dragging and dragType == DRAG.Content and opts.onContentDragEnd then
                    opts.onContentDragEnd()
                end
                dragging = false
            end),
            mouseMove = async:callback(function(e, layout)
                if dragging then
                    local delta = e.position - dragStartMousePos

                    if dragType == DRAG.Move then
                        local newPos = clampToViewport(dragStartPos + delta, layout.props.size)
                        layout.props.position = newPos
                        element:update()
                        if opts.onMove then
                            opts.onMove(newPos)
                        end
                    elseif dragType == DRAG.Content then
                        if opts.onContentDrag then
                            opts.onContentDrag(e, delta)
                        end
                    else
                        handleResize(layout, delta)
                    end
                else
                    dragType = getDragType(e.offset, layout.props.size)

                    if opts.onMouseMove then
                        opts.onMouseMove(e)
                    end
                end
            end),
            focusLoss = async:callback(function()
                if dragging and dragType == DRAG.Content and opts.onContentDragEnd then
                    opts.onContentDragEnd()
                end
                dragging = false
                dragType = DRAG.None
            end),
        },
    }

    -- Wire up pin button click event
    local pinButton = getPinButton()
    pinButton.events = {
        mouseClick = async:callback(function()
            togglePin()
        end),
    }

    -- Wire up title double-click event
    if opts.onTitleDoubleClick then
        local titleBar = element.layout.template.content.titleBar
        local titleContainer = titleBar.content.titleContainer
        titleContainer.events = {
            mouseDoubleClick = async:callback(function()
                opts.onTitleDoubleClick()
            end),
        }
    end

    -- Wire up content double-click event
    -- Note: mouseDoubleClick receives nil (no MouseEvent), so we use lastMouseOffset tracked from mouseMove
    if opts.onContentDoubleClick then
        local lastMouseOffset = nil
        local originalMouseMove = element.layout.events.mouseMove

        -- Wrap mouseMove to track position for double-click
        element.layout.events.mouseMove = async:callback(function(e, layout)
            lastMouseOffset = e.offset
            -- Call original handler if it exists (it does, from mouseMove above)
            if originalMouseMove then
                originalMouseMove(e, layout)
            end
        end)

        element.layout.events.mouseDoubleClick = async:callback(function(_, layout)
            -- Only fire for content area (not header/borders)
            if lastMouseOffset then
                local contentDragType = getDragType(lastMouseOffset, layout.props.size)
                if contentDragType == DRAG.Content then
                    opts.onContentDoubleClick(lastMouseOffset)
                end
            end
        end)
    end

    return {
        element = element,
        show = function()
            element.layout.props.visible = true
            element:update()
        end,
        hide = function()
            element.layout.props.visible = false
            element:update()
        end,
        getContentSize = function()
            return getContentSize(element.layout.props.size)
        end,
        isPinned = function()
            return isPinned
        end,
        setPinned = function(pinned)
            if pinned ~= isPinned then
                togglePin()
            end
        end,
        setTitle = function(title)
            local titleBar = element.layout.template.content.titleBar
            local titleText = titleBar.content.titleContainer.content.titleText
            titleText.props.text = title or 'Map'
            element:update()
        end,
    }
end

return {
    BORDER_SIZE = BORDER_SIZE,
    INNER_BORDER_SIZE = INNER_BORDER_SIZE,
    HEADER_HEIGHT = HEADER_HEIGHT,
    DEFAULT_WIDTH = DEFAULT_WIDTH,
    DEFAULT_HEIGHT = DEFAULT_HEIGHT,
    template = template,
    create = create,
}
