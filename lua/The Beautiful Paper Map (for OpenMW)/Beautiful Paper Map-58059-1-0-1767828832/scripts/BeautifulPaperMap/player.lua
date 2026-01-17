-- The Beautiful Paper Map for OpenMW
-- Displays a hand-drawn paper map alongside the native map in Windows mode

local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require('openmw.storage')

local window = require('scripts.BeautifulPaperMap.window')
local deform = require('scripts.BeautifulPaperMap.deform')
local mapData = require('scripts.BeautifulPaperMap.map_data')
local texture = require('scripts.BeautifulPaperMap.texture')

-- Settings storage
local settings = storage.playerSection('Settings/PaperMap')

-- Supported texture paths (in order of preference)
local TEXTURE_PATHS = {
    'textures/vvardenfell.dds',
    'textures/vvardenfell.tga',
    'textures/vvardenfell.jpg',
}

-- Texture dimensions (detected at load time)
local texturePath = nil
local textureWidth = nil   -- Full texture size (e.g., 8192x8192 for DDS)
local textureHeight = nil
local contentWidth = nil   -- Actual map content size (may differ if texture is padded)
local contentHeight = nil  -- For square textures, we assume right-side padding

-- State
local mapVisible = false
local mapWindow = nil
local lastCellName = nil
local lastExteriorPos = nil  -- Last known position in exterior cell (world coords)

-- Current map content size (updated on resize)
local currentMapWidth = window.DEFAULT_WIDTH
local currentMapHeight = window.DEFAULT_HEIGHT

-- Pan/zoom constants
-- Zoom is absolute: displayed pixel size = original pixel size * zoom
local MAX_ZOOM = 2.0          -- Maximum zoom (200% of original size)
local ZOOM_SPEED = 0.08       -- Zoom speed multiplier (scales with current zoom)
local ZOOM_INERTIA = 0.1      -- How quickly zoom catches up (0-1, higher = faster)
local PAN_INERTIA = 0.05      -- How quickly pan catches up for smooth centering (0-1, higher = faster)
local PAN_FRICTION = 0.95     -- Pan velocity decay per frame (0-1, higher = more drift)
local PAN_MIN_VELOCITY = 0.1  -- Stop panning when velocity drops below this
local PAN_VELOCITY_SCALE = 3  -- Multiplier for initial velocity
local DOUBLE_CLICK_ZOOM_FACTOR = 2.0 -- Zoom multiplier for double-click (2x current zoom)

-- Pan/zoom state
-- Zoom is defined as: displayed image height / original image height
-- This makes zoom independent of container size
local mapZoom = 0.5          -- Current zoom level (0.5, 1 screen pixel = 2 source pixels)
local targetZoom = 0.5       -- Target zoom level (for smooth interpolation)
local mapPanX = 0             -- Pan offset X (in pixels, at current zoom)
local mapPanY = 0             -- Pan offset Y (in pixels, at current zoom)
local panStartOffset = nil    -- Pan offset when pan started
local lastMouseOffset = nil   -- Last mouse position relative to window (for zoom-to-cursor)
local playerOffsetX = nil     -- Offset from centered view (nil = not initialized, center on player)
local playerOffsetY = nil
local targetOffsetX = 0       -- Target offset for smooth pan interpolation
local targetOffsetY = 0
local panVelocityX = 0        -- Pan velocity for momentum scrolling
local panVelocityY = 0
local isDragging = false      -- Whether user is currently dragging
local recentDeltas = {}       -- Recent drag deltas for velocity calculation
local MAX_RECENT_DELTAS = 4   -- Number of recent deltas to average


-- Calculate minimum zoom needed to cover container (no vignettes)
-- Zoom is defined as: displayed image height / content height
local function getMinZoomForContainer(containerWidth, containerHeight)
    local minZoomForHeight = containerHeight / contentHeight
    local minZoomForWidth = containerWidth / contentWidth
    return math.max(minZoomForHeight, minZoomForWidth)
end

-- Calculate map image size based on zoom level
-- Zoom is absolute: displayed size = content size * zoom
-- Image always covers the container (no vignettes)
local function calculateMapImageSize(containerWidth, containerHeight)
    local minZoom = getMinZoomForContainer(containerWidth, containerHeight)
    local effectiveZoom = math.max(minZoom, mapZoom)

    local imageWidth = contentWidth * effectiveZoom
    local imageHeight = contentHeight * effectiveZoom

    return imageWidth, imageHeight
end

-- Clamp pan values to keep map visible
local function clampPan(imageWidth, imageHeight, containerWidth, containerHeight)
    local maxPanX = math.max(0, (imageWidth - containerWidth) / 2)
    local maxPanY = math.max(0, (imageHeight - containerHeight) / 2)
    mapPanX = math.max(-maxPanX, math.min(maxPanX, mapPanX))
    mapPanY = math.max(-maxPanY, math.min(maxPanY, mapPanY))
end

-- Check if player is in an exterior cell
local function isInExterior()
    local cell = self.cell
    return cell and cell.isExterior
end

-- Get player's position on the hand-drawn map (0-1 range)
-- Uses deformation data to map from world coords to paper map coords
-- For interior cells, returns the last known exterior position
local function getPlayerNormalizedPosition()
    if isInExterior() then
        -- In exterior: use current position and remember it
        local pos = self.position
        lastExteriorPos = { x = pos.x, y = pos.y }
        return deform.transform(pos.x, pos.y)
    elseif lastExteriorPos then
        -- In interior: use last known exterior position
        return deform.transform(lastExteriorPos.x, lastExteriorPos.y)
    else
        -- No exterior position known yet, return map center
        return 0.5, 0.5
    end
end

-- Update map image display (size and position based on zoom/pan)
local function updateMapDisplay()
    if not mapWindow then return end

    local container = mapWindow.element.layout.content.mapContainer
    local containerSize = container.props.size

    -- Calculate zoomed image size
    local imageW, imageH = calculateMapImageSize(containerSize.x, containerSize.y)

    -- Clamp pan to valid bounds
    clampPan(imageW, imageH, containerSize.x, containerSize.y)

    -- Center the image plus pan offset
    local offsetX = (containerSize.x - imageW) / 2 + mapPanX
    local offsetY = (containerSize.y - imageH) / 2 + mapPanY

    -- Update map image
    container.content.mapImage.props.size = util.vector2(imageW, imageH)
    container.content.mapImage.props.position = util.vector2(offsetX, offsetY)

    mapWindow.element:update()
end

-- Get the current cell's display name for the window title
local function getCellDisplayName()
    local cell = self.cell
    if not cell then return 'Map' end
    -- Use cell name if available, otherwise fall back to region
    local name = cell.name
    if name and name ~= '' then return name end
    if cell.region and cell.region ~= '' then return cell.region end
    return 'Map'
end

-- Update the window title with the current cell name
local function updateTitle()
    if not mapWindow then return end
    local cellName = getCellDisplayName()
    if cellName ~= lastCellName then
        lastCellName = cellName
        mapWindow.setTitle(cellName)
    end
end

-- Center the map view on the player's position, plus any user offset
local function centerOnPlayer(containerWidth, containerHeight)
    local imageW, imageH = calculateMapImageSize(containerWidth, containerHeight)
    local normalizedX, normalizedY = getPlayerNormalizedPosition()

    local playerOnImageX = normalizedX * imageW
    local playerOnImageY = normalizedY * imageH

    local baseOffsetX = (containerWidth - imageW) / 2
    local baseOffsetY = (containerHeight - imageH) / 2

    -- Center on player, then apply user's pan offset
    mapPanX = (containerWidth / 2) - playerOnImageX - baseOffsetX + playerOffsetX
    mapPanY = (containerHeight / 2) - playerOnImageY - baseOffsetY + playerOffsetY

    clampPan(imageW, imageH, containerWidth, containerHeight)
end

-- Create the map UI
local function createMapUI()
    if mapWindow then return end
    if not texturePath then return end  -- No texture found

    -- Create texture resource, cropping to content area if padded
    local mapTexture = ui.texture {
        path = texturePath,
        offset = util.vector2(0, 0),  -- Content is left-aligned (no offset)
        size = util.vector2(contentWidth, contentHeight),  -- Crop to content area
    }

    -- Use stored position/size or defaults
    local totalBorder = window.BORDER_SIZE + window.INNER_BORDER_SIZE
    local windowX = settings:get('windowX')
    local windowY = settings:get('windowY')
    local windowWidth = settings:get('windowWidth')
    local windowHeight = settings:get('windowHeight')

    -- Update current content size from stored window size (if any)
    if windowWidth and windowHeight then
        currentMapWidth = windowWidth - totalBorder * 2
        currentMapHeight = windowHeight - totalBorder * 2 - window.HEADER_HEIGHT
    end

    mapWindow = window.create {
        position = windowX and windowY and util.vector2(windowX, windowY) or nil,
        size = windowWidth and windowHeight and util.vector2(windowWidth, windowHeight) or nil,
        content = ui.content {
            {
                name = 'mapContainer',
                props = {
                    size = util.vector2(currentMapWidth, currentMapHeight),
                },
                content = ui.content {
                    {
                        name = 'mapImage',
                        type = ui.TYPE.Image,
                        props = {
                            resource = mapTexture,
                            size = util.vector2(currentMapWidth, currentMapHeight),
                        },
                    },
                },
            },
        },
        onResize = function(contentSize)
            currentMapWidth = contentSize.x
            currentMapHeight = contentSize.y
            mapWindow.element.layout.content.mapContainer.props.size = contentSize
            -- Save window size (add back border/header to get full window size)
            local totalBorder = window.BORDER_SIZE + window.INNER_BORDER_SIZE
            local winWidth = contentSize.x + totalBorder * 2
            local winHeight = contentSize.y + totalBorder * 2 + window.HEADER_HEIGHT
            settings:set('windowWidth', winWidth)
            settings:set('windowHeight', winHeight)
            updateMapDisplay()
        end,
        onMove = function(position)
            settings:set('windowX', position.x)
            settings:set('windowY', position.y)
        end,
        onContentDragStart = function()
            panStartOffset = util.vector2(playerOffsetX, playerOffsetY)
            isDragging = true
            panVelocityX = 0
            panVelocityY = 0
            recentDeltas = {}
        end,
        onContentDrag = function(_, delta)
            -- Track recent deltas for velocity calculation
            table.insert(recentDeltas, { x = delta.x, y = delta.y })
            if #recentDeltas > MAX_RECENT_DELTAS then
                table.remove(recentDeltas, 1)
            end

            -- Update the player offset based on drag delta
            playerOffsetX = panStartOffset.x + delta.x
            playerOffsetY = panStartOffset.y + delta.y
            targetOffsetX = playerOffsetX  -- Keep target in sync during drag
            targetOffsetY = playerOffsetY
            centerOnPlayer(currentMapWidth, currentMapHeight)
            updateMapDisplay()
        end,
        onContentDragEnd = function()
            isDragging = false

            -- Calculate velocity from recent deltas (difference between last and first)
            if #recentDeltas >= 2 then
                local first = recentDeltas[1]
                local last = recentDeltas[#recentDeltas]
                local frames = #recentDeltas - 1
                panVelocityX = (last.x - first.x) / frames * PAN_VELOCITY_SCALE
                panVelocityY = (last.y - first.y) / frames * PAN_VELOCITY_SCALE
            end
        end,
        onMouseMove = function(e)
            lastMouseOffset = e.offset
        end,
        onPinToggle = function(pinned)
            settings:set('pinned', pinned)
        end,
        onTitleDoubleClick = function()
            -- Smoothly recenter on player by setting target offset to zero
            targetOffsetX = 0
            targetOffsetY = 0
            panVelocityX = 0
            panVelocityY = 0
        end,
        onContentDoubleClick = function(offset)
            -- Zoom into the clicked location
            local totalBorder = window.BORDER_SIZE + window.INNER_BORDER_SIZE

            -- Calculate cursor position relative to map container
            local cursorInContainerX = offset.x - totalBorder
            local cursorInContainerY = offset.y - totalBorder - window.HEADER_HEIGHT

            -- Get current image size and position
            local imageW, imageH = calculateMapImageSize(currentMapWidth, currentMapHeight)
            local offsetX = (currentMapWidth - imageW) / 2 + mapPanX
            local offsetY = (currentMapHeight - imageH) / 2 + mapPanY

            -- Position on current image that cursor is over (normalized 0-1)
            local cursorOnImageX = (cursorInContainerX - offsetX) / imageW
            local cursorOnImageY = (cursorInContainerY - offsetY) / imageH

            -- Set target zoom (2x current zoom, clamped to valid range)
            local minZoom = getMinZoomForContainer(currentMapWidth, currentMapHeight)
            targetZoom = math.max(minZoom, math.min(MAX_ZOOM, mapZoom * DOUBLE_CLICK_ZOOM_FACTOR))

            -- Calculate new image size at target zoom
            local newImageW = contentWidth * targetZoom
            local newImageH = contentHeight * targetZoom

            -- Calculate playerOffset needed to center the clicked point
            local normalizedX, normalizedY = getPlayerNormalizedPosition()
            local playerOnImageX = normalizedX * newImageW
            local playerOnImageY = normalizedY * newImageH
            local baseOffsetX = (currentMapWidth - newImageW) / 2
            local baseOffsetY = (currentMapHeight - newImageH) / 2

            -- Target pan centers the clicked point
            local clickedOnNewImageX = cursorOnImageX * newImageW
            local clickedOnNewImageY = cursorOnImageY * newImageH
            local targetPanX = (currentMapWidth / 2) - clickedOnNewImageX - baseOffsetX
            local targetPanY = (currentMapHeight / 2) - clickedOnNewImageY - baseOffsetY

            -- playerOffset is the difference between target and player-centered
            local centeredPanX = (currentMapWidth / 2) - playerOnImageX - baseOffsetX
            local centeredPanY = (currentMapHeight / 2) - playerOnImageY - baseOffsetY
            targetOffsetX = targetPanX - centeredPanX
            targetOffsetY = targetPanY - centeredPanY

            -- Stop any momentum
            panVelocityX = 0
            panVelocityY = 0
        end,
    }
end

-- Show the paper map
local function showMap()
    createMapUI()
    mapVisible = true
    if mapWindow then
        -- Sync pin button state with stored value
        mapWindow.setPinned(settings:get('pinned') or false)
        -- Center on player only on first open (when offset is nil)
        if playerOffsetX == nil then
            playerOffsetX = 0
            playerOffsetY = 0
            targetOffsetX = 0
            targetOffsetY = 0
            mapZoom = 0.5
            targetZoom = 0.5
        end
        centerOnPlayer(currentMapWidth, currentMapHeight)
        updateMapDisplay()
        updateTitle()
        mapWindow.show()
    end
end

-- Hide the paper map (respects pinned state)
local function hideMap()
    -- If pinned, don't hide when the game requests it
    if settings:get('pinned') then
        return
    end
    mapVisible = false
    if mapWindow then
        mapWindow.hide()
    end
end

return {
    interfaceName = 'PaperMap',
    interface = {
        version = 1,
        show = showMap,
        hide = hideMap,
    },

    engineHandlers = {
        onActive = function()
            -- Find and load texture (returns both texture and content dimensions)
            texturePath, textureWidth, textureHeight, contentWidth, contentHeight = texture.findTexture(TEXTURE_PATHS)
            if not texturePath then
                print('Paper Map: ERROR - No map texture found!')
                print('Paper Map: Please install a map texture as textures/vvardenfell.dds (or .tga, .jpg)')
                return
            end

            -- Load deformation data
            deform.loadPoints(mapData)
            local info = deform.getDebugInfo()

            -- Log texture info (note if using .dims file for content dimensions)
            if contentWidth ~= textureWidth or contentHeight ~= textureHeight then
                print(string.format('Paper Map mod loaded! (%s, %dx%d texture, %dx%d content, %d control points, %d triangles)',
                    texturePath, textureWidth, textureHeight, contentWidth, contentHeight, info.numPoints, info.numTriangles))
            else
                print(string.format('Paper Map mod loaded! (%s, %dx%d, %d control points, %d triangles)',
                    texturePath, textureWidth, textureHeight, info.numPoints, info.numTriangles))
            end
        end,

        onFrame = function()
            if not mapVisible then return end

            local needsUpdate = false

            -- Apply pan momentum when not dragging
            if not isDragging and (math.abs(panVelocityX) > PAN_MIN_VELOCITY or math.abs(panVelocityY) > PAN_MIN_VELOCITY) then
                playerOffsetX = playerOffsetX + panVelocityX
                playerOffsetY = playerOffsetY + panVelocityY
                targetOffsetX = playerOffsetX  -- Keep target in sync during momentum
                targetOffsetY = playerOffsetY
                panVelocityX = panVelocityX * PAN_FRICTION
                panVelocityY = panVelocityY * PAN_FRICTION

                -- Stop when velocity is negligible
                if math.abs(panVelocityX) <= PAN_MIN_VELOCITY then panVelocityX = 0 end
                if math.abs(panVelocityY) <= PAN_MIN_VELOCITY then panVelocityY = 0 end

                needsUpdate = true
            end

            -- Smooth pan interpolation (for double-click recenter)
            if not isDragging and math.abs(panVelocityX) <= PAN_MIN_VELOCITY and math.abs(panVelocityY) <= PAN_MIN_VELOCITY then
                local dx = targetOffsetX - playerOffsetX
                local dy = targetOffsetY - playerOffsetY
                if math.abs(dx) > 0.5 or math.abs(dy) > 0.5 then
                    playerOffsetX = playerOffsetX + dx * PAN_INERTIA
                    playerOffsetY = playerOffsetY + dy * PAN_INERTIA

                    -- Snap to target when very close
                    if math.abs(dx) < 0.5 then playerOffsetX = targetOffsetX end
                    if math.abs(dy) < 0.5 then playerOffsetY = targetOffsetY end

                    needsUpdate = true
                end
            end

            -- Smooth zoom interpolation
            if math.abs(targetZoom - mapZoom) > 0.002 then
                local oldZoom = mapZoom
                mapZoom = mapZoom + (targetZoom - mapZoom) * ZOOM_INERTIA

                -- Snap to target when very close
                if math.abs(targetZoom - mapZoom) < 0.002 then
                    mapZoom = targetZoom
                end

                -- Zoom toward cursor position
                if lastMouseOffset and oldZoom ~= mapZoom then
                    local totalBorder = window.BORDER_SIZE + window.INNER_BORDER_SIZE
                    local zoomRatio = mapZoom / oldZoom

                    -- Calculate cursor position relative to map container
                    local cursorInContainerX = lastMouseOffset.x - totalBorder
                    local cursorInContainerY = lastMouseOffset.y - totalBorder - window.HEADER_HEIGHT

                    -- Get old image size
                    local savedZoom = mapZoom
                    mapZoom = oldZoom
                    local oldImageW, oldImageH = calculateMapImageSize(currentMapWidth, currentMapHeight)
                    mapZoom = savedZoom

                    -- Get new image size
                    local newImageW, newImageH = calculateMapImageSize(currentMapWidth, currentMapHeight)

                    -- Calculate old image offset (includes current playerOffset via mapPanX)
                    local oldOffsetX = (currentMapWidth - oldImageW) / 2 + mapPanX
                    local oldOffsetY = (currentMapHeight - oldImageH) / 2 + mapPanY

                    -- Position on old image that cursor was over
                    local cursorOnImageX = cursorInContainerX - oldOffsetX
                    local cursorOnImageY = cursorInContainerY - oldOffsetY

                    -- Scale that position to new image size
                    local newCursorOnImageX = cursorOnImageX * zoomRatio
                    local newCursorOnImageY = cursorOnImageY * zoomRatio

                    -- Calculate what mapPanX/Y should be to keep cursor over same map point
                    local newOffsetXWithoutPan = (currentMapWidth - newImageW) / 2
                    local newOffsetYWithoutPan = (currentMapHeight - newImageH) / 2
                    local targetPanX = cursorInContainerX - newCursorOnImageX - newOffsetXWithoutPan
                    local targetPanY = cursorInContainerY - newCursorOnImageY - newOffsetYWithoutPan

                    -- Calculate what centerOnPlayer would produce WITHOUT playerOffset
                    local normalizedX, normalizedY = getPlayerNormalizedPosition()
                    local playerOnImageX = normalizedX * newImageW
                    local playerOnImageY = normalizedY * newImageH
                    local baseOffsetX = (currentMapWidth - newImageW) / 2
                    local baseOffsetY = (currentMapHeight - newImageH) / 2
                    local centeredPanX = (currentMapWidth / 2) - playerOnImageX - baseOffsetX
                    local centeredPanY = (currentMapHeight / 2) - playerOnImageY - baseOffsetY

                    -- playerOffset is the difference between target and centered
                    playerOffsetX = targetPanX - centeredPanX
                    playerOffsetY = targetPanY - centeredPanY
                    targetOffsetX = playerOffsetX  -- Keep target in sync during zoom
                    targetOffsetY = playerOffsetY
                end

                needsUpdate = true
            end

            -- Always track player position when pinned (offset is applied inside centerOnPlayer)
            if settings:get('pinned') then
                centerOnPlayer(currentMapWidth, currentMapHeight)
                updateTitle()  -- Update title when player moves to a new cell
                needsUpdate = true
            end

            if needsUpdate then
                centerOnPlayer(currentMapWidth, currentMapHeight)
                updateMapDisplay()
            end
        end,

        onMouseWheel = function(vertical, horizontal)
            if not mapVisible then return end
            if not lastMouseOffset then return end

            -- Multiplicative zoom: speed scales with current zoom for natural feel
            local zoomFactor = 1 + vertical * ZOOM_SPEED
            local minZoom = getMinZoomForContainer(currentMapWidth, currentMapHeight)
            targetZoom = math.max(minZoom, math.min(MAX_ZOOM, targetZoom * zoomFactor))
        end,

        onSave = function()
            return {
                lastExteriorPos = lastExteriorPos,
            }
        end,

        onLoad = function(data)
            if data then
                lastExteriorPos = data.lastExteriorPos
            end
        end,
    },

    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == 'Interface' then
                showMap()
            elseif data.oldMode == 'Interface' then
                -- Hide when leaving Interface mode (whether to nil or another mode like Alchemy)
                hideMap()
            end
        end,
    },
}
