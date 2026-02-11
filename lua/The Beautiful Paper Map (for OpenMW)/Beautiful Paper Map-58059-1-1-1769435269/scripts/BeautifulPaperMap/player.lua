-- The Beautiful Paper Map for OpenMW
-- Displays a hand-drawn paper map alongside the native map in Windows mode

local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local window = require('scripts.BeautifulPaperMap.window')
local deform = require('scripts.BeautifulPaperMap.deform')
local mapData = require('scripts.BeautifulPaperMap.map_data')
local texture = require('scripts.BeautifulPaperMap.texture')

-- Storage keys
local MOD_ID = 'BeautifulPaperMap'
local SETTINGS_PLAYER = 'Settings/BeautifulPaperMap/Player'
local SETTINGS_ZOOM = 'Settings/BeautifulPaperMap/Zoom'
local SETTINGS_DEBUG = 'Settings/BeautifulPaperMap/Debug'
local STATE_KEY = 'State/BeautifulPaperMap'

-- Register settings page
I.Settings.registerPage({
    key = MOD_ID,
    l10n = MOD_ID,
    name = 'main.page_name',
    description = 'main.page_description',
})

-- General settings group
I.Settings.registerGroup({
    key = SETTINGS_PLAYER,
    page = MOD_ID,
    l10n = MOD_ID,
    name = 'follow.group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'follow_player',
            renderer = 'checkbox',
            name = 'follow_player.setting_name',
            description = 'follow_player.setting_description',
            default = true,
        },
        {
            key = 'show_player_position',
            renderer = 'checkbox',
            name = 'show_player_position.setting_name',
            description = 'show_player_position.setting_description',
            default = false,
        },
    },
})

-- Zoom settings group
I.Settings.registerGroup({
    key = SETTINGS_ZOOM,
    page = MOD_ID,
    l10n = MOD_ID,
    name = 'zoom.group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'max_zoom',
            renderer = 'number',
            name = 'max_zoom.setting_name',
            description = 'max_zoom.setting_description',
            default = 2.0,
            argument = {
                min = 1.0,
                max = 10.0,
            },
        },
        {
            key = 'zoom_speed',
            renderer = 'number',
            name = 'zoom_speed.setting_name',
            description = 'zoom_speed.setting_description',
            default = 0.08,
            argument = {
                min = 0.01,
                max = 0.5,
            },
        },
        {
            key = 'pan_friction',
            renderer = 'number',
            name = 'pan_friction.setting_name',
            description = 'pan_friction.setting_description',
            default = 0.95,
            argument = {
                min = 0.5,
                max = 0.99,
            },
        },
    },
})

-- Debug settings group
I.Settings.registerGroup({
    key = SETTINGS_DEBUG,
    page = MOD_ID,
    l10n = MOD_ID,
    name = 'debug.group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'show_mesh_points',
            renderer = 'checkbox',
            name = 'show_mesh_points.setting_name',
            description = 'show_mesh_points.setting_description',
            default = false,
        },
    },
})

-- Storage sections
local playerSettings = storage.playerSection(SETTINGS_PLAYER)
local zoomSettings = storage.playerSection(SETTINGS_ZOOM)
local debugSettings = storage.playerSection(SETTINGS_DEBUG)
local state = storage.playerSection(STATE_KEY)

-- Supported texture paths (in order of preference)
local TEXTURE_PATHS = {
    'textures/vvardenfell.dds',
    'textures/vvardenfell.tga',
    'textures/vvardenfell.jpg',
}

-- Texture dimensions (detected at load time)
local texturePath = nil
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

-- Player marker constants
local MARKER_SIZE = 64        -- Display size of the compass marker in pixels

-- Compass textures for 24 directions (every 15 degrees)
-- Textures are pre-rotated since OpenMW UI doesn't support image rotation
local COMPASS_STEP = 15  -- degrees per texture
local COMPASS_COUNT = 24
local compassTextures = {}
for i = 0, COMPASS_COUNT - 1 do
    local angle = i * COMPASS_STEP
    compassTextures[angle] = ui.texture({ path = 'textures/sta/compass_' .. angle .. '.dds' })
end

-- Debug mesh point marker textures and constants
local MESH_MARKER_SIZE = 16   -- Display size of mesh point markers in pixels
local meshMarkerActive = ui.texture({ path = 'textures/sta/map_marker_active.dds' })
local meshMarkerInactive = ui.texture({ path = 'textures/sta/map_marker_inactive.dds' })

-- Mesh marker UI elements (created dynamically based on control point count)
local meshMarkerElements = nil

-- Get compass texture angle from yaw
-- Yaw is in radians, 0 = North, positive = clockwise when viewed from above
local function getCompassAngle(yaw)
    -- Convert to degrees and normalize to 0..360
    local degrees = math.deg(yaw) % 360
    if degrees < 0 then degrees = degrees + 360 end

    -- Round to nearest step (with half-step offset for centering)
    local index = math.floor((degrees + COMPASS_STEP / 2) / COMPASS_STEP) % COMPASS_COUNT
    return index * COMPASS_STEP
end

-- Pan/zoom constants
-- Zoom is absolute: displayed pixel size = original pixel size * zoom
local ZOOM_INERTIA = 0.1      -- How quickly zoom catches up (0-1, higher = faster)
local PAN_INERTIA = 0.05      -- How quickly pan catches up for smooth centering (0-1, higher = faster)
local PAN_MIN_VELOCITY = 0.1  -- Stop panning when velocity drops below this
local PAN_VELOCITY_SCALE = 3  -- Multiplier for initial velocity

-- Configurable settings (read from zoomSettings)
local function getMaxZoom() return zoomSettings:get('max_zoom') end
local function getZoomSpeed() return zoomSettings:get('zoom_speed') end
local function getPanFriction() return zoomSettings:get('pan_friction') end

-- Pan/zoom state
-- Zoom is defined as: displayed image height / original image height
-- This makes zoom independent of container size
local mapZoom = 0.5          -- Current zoom level (0.5, 1 screen pixel = 2 source pixels)
local targetZoom = 0.5       -- Target zoom level (for smooth interpolation)
local mapPanX = 0             -- Pan offset X (in pixels, at current zoom)
local mapPanY = 0             -- Pan offset Y (in pixels, at current zoom)
local targetPanX = 0          -- Target pan for smooth interpolation (recenter animation)
local targetPanY = 0
local panStartOffset = nil    -- Pan offset when pan started
local lastMouseOffset = nil   -- Last mouse position relative to window (for zoom-to-cursor)
local panVelocityX = 0        -- Pan velocity for momentum scrolling
local panVelocityY = 0
local isDragging = false      -- Whether user is currently dragging
local recentDeltas = {}       -- Recent drag deltas for velocity calculation
local MAX_RECENT_DELTAS = 4   -- Number of recent deltas to average
local hasPanned = false       -- Whether user has panned (disables following until re-centered)

-- When follow_player is enabled, reset hasPanned to resume following
playerSettings:subscribe(async:callback(function(_, key)
    if key == 'follow_player' and playerSettings:get('follow_player') then
        hasPanned = false
        -- targetPanX/Y will be set by centerOnPlayer on next frame
    end
end))

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

    -- Update player marker position and orientation
    local marker = container.content.playerMarker
    if playerSettings:get('show_player_position') then
        local normalizedX, normalizedY = getPlayerNormalizedPosition()
        local markerX = offsetX + normalizedX * imageW - MARKER_SIZE / 2
        local markerY = offsetY + normalizedY * imageH - MARKER_SIZE / 2
        marker.props.position = util.vector2(markerX, markerY)

        -- Update compass direction based on player facing
        local _, yaw = self.rotation:getAnglesXZ()
        local angle = getCompassAngle(yaw)
        marker.props.resource = compassTextures[angle]

        marker.props.visible = true
    else
        marker.props.visible = false
    end

    -- Update mesh point markers (debug visualization)
    if meshMarkerElements and debugSettings:get('show_mesh_points') then
        -- Get current triangle indices to highlight
        local worldX, worldY
        if isInExterior() then
            local pos = self.position
            worldX, worldY = pos.x, pos.y
        elseif lastExteriorPos then
            worldX, worldY = lastExteriorPos.x, lastExteriorPos.y
        end

        local currentTriIndices, extrapolationTriIndices = nil, nil
        if worldX then
            currentTriIndices, extrapolationTriIndices = deform.getCurrentTriangleIndices(worldX, worldY)
        end

        -- Build a set of active triangle point indices
        local activeIndices = {}
        local triIndices = currentTriIndices or extrapolationTriIndices
        if triIndices then
            for _, idx in ipairs(triIndices) do
                activeIndices[idx] = true
            end
        end

        -- Update each marker's position and color
        local controlPoints = deform.getControlPoints()
        for i, markerLayout in ipairs(meshMarkerElements) do
            local point = controlPoints[i]
            if point then
                local paperX, paperY = point.paper[1], point.paper[2]
                local markerX = offsetX + paperX * imageW - MESH_MARKER_SIZE / 2
                local markerY = offsetY + paperY * imageH - MESH_MARKER_SIZE / 2
                markerLayout.props.position = util.vector2(markerX, markerY)
                markerLayout.props.resource = activeIndices[i] and meshMarkerActive or meshMarkerInactive
                markerLayout.props.visible = true
            end
        end
    elseif meshMarkerElements then
        -- Hide all markers when setting is disabled
        for _, markerLayout in ipairs(meshMarkerElements) do
            markerLayout.props.visible = false
        end
    end

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

-- Calculate the pan position that centers on the player
local function getPlayerCenteredPan(containerWidth, containerHeight)
    local imageW, imageH = calculateMapImageSize(containerWidth, containerHeight)
    local normalizedX, normalizedY = getPlayerNormalizedPosition()

    local playerOnImageX = normalizedX * imageW
    local playerOnImageY = normalizedY * imageH

    local baseOffsetX = (containerWidth - imageW) / 2
    local baseOffsetY = (containerHeight - imageH) / 2

    local panX = (containerWidth / 2) - playerOnImageX - baseOffsetX
    local panY = (containerHeight / 2) - playerOnImageY - baseOffsetY

    return panX, panY
end

-- Center the map view on the player's position
local function centerOnPlayer(containerWidth, containerHeight)
    mapPanX, mapPanY = getPlayerCenteredPan(containerWidth, containerHeight)
    targetPanX, targetPanY = mapPanX, mapPanY

    local imageW, imageH = calculateMapImageSize(containerWidth, containerHeight)
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
    local windowX = state:get('windowX')
    local windowY = state:get('windowY')
    local windowWidth = state:get('windowWidth')
    local windowHeight = state:get('windowHeight')

    -- Update current content size from stored window size (if any)
    local totalBorder = window.BORDER_SIZE + window.INNER_BORDER_SIZE
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
                    {
                        name = 'playerMarker',
                        type = ui.TYPE.Image,
                        props = {
                            resource = compassTextures[0],
                            size = util.vector2(MARKER_SIZE, MARKER_SIZE),
                            position = util.vector2(0, 0),
                            visible = false,
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
            local winWidth = contentSize.x + totalBorder * 2
            local winHeight = contentSize.y + totalBorder * 2 + window.HEADER_HEIGHT
            state:set('windowWidth', winWidth)
            state:set('windowHeight', winHeight)
            updateMapDisplay()
        end,
        onMove = function(position)
            state:set('windowX', position.x)
            state:set('windowY', position.y)
        end,
        onContentDragStart = function()
            panStartOffset = util.vector2(mapPanX, mapPanY)
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

            -- Update pan position directly
            mapPanX = panStartOffset.x + delta.x
            mapPanY = panStartOffset.y + delta.y
            targetPanX = mapPanX  -- Keep target in sync (no animation back)
            targetPanY = mapPanY
            hasPanned = true  -- Mark that user has panned (disables following)
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
        onFocusLoss = function()
            lastMouseOffset = nil
        end,
        onPinToggle = function(pinned)
            state:set('pinned', pinned)
        end,
        onTitleDoubleClick = function()
            -- Smoothly recenter on player
            targetPanX, targetPanY = getPlayerCenteredPan(currentMapWidth, currentMapHeight)
            panVelocityX = 0
            panVelocityY = 0
            hasPanned = false  -- Resume following if enabled
        end,
    }

    -- Create mesh point marker elements (one for each control point)
    local controlPoints = deform.getControlPoints()
    meshMarkerElements = {}
    local mapContainer = mapWindow.element.layout.content.mapContainer
    for i = 1, #controlPoints do
        local markerLayout = {
            name = 'meshMarker' .. i,
            type = ui.TYPE.Image,
            props = {
                resource = meshMarkerInactive,
                size = util.vector2(MESH_MARKER_SIZE, MESH_MARKER_SIZE),
                position = util.vector2(0, 0),
                visible = false,
            },
        }
        -- Add to UI content
        mapContainer.content:add(markerLayout)
        -- Keep reference for updating
        meshMarkerElements[i] = mapContainer.content['meshMarker' .. i]
    end
end

-- Show the paper map
local function showMap()
    createMapUI()
    mapVisible = true
    if mapWindow then
        -- Sync pin button state with stored value
        mapWindow.setPinned(state:get('pinned') or false)
        -- If follow mode is enabled and user hasn't panned, center on player
        if playerSettings:get('follow_player') and not hasPanned then
            centerOnPlayer(currentMapWidth, currentMapHeight)
        end
        updateMapDisplay()
        updateTitle()
        mapWindow.show()
    end
end

-- Hide the paper map (respects pinned state)
local function hideMap()
    -- If pinned, don't hide when the game requests it
    if state:get('pinned') then
        return
    end
    mapVisible = false
    if mapWindow then
        mapWindow.hide()
    end
end

return {
    interfaceName = 'BeautifulPaperMap',
    interface = {
        version = 1,
        show = showMap,
        hide = hideMap,
    },

    engineHandlers = {
        onActive = function()
            -- Find and load texture (returns both texture and content dimensions)
            local textureWidth, textureHeight
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
            -- Always track exterior position, even when map is hidden
            -- This ensures the map shows the correct location if the player
            -- enters/exits multiple interiors without opening the map
            if isInExterior() then
                local pos = self.position
                lastExteriorPos = { x = pos.x, y = pos.y }
            end

            if not mapVisible then return end

            local needsUpdate = false

            -- Apply pan momentum when not dragging
            if not isDragging and (math.abs(panVelocityX) > PAN_MIN_VELOCITY or math.abs(panVelocityY) > PAN_MIN_VELOCITY) then
                mapPanX = mapPanX + panVelocityX
                mapPanY = mapPanY + panVelocityY
                targetPanX = mapPanX  -- Keep target in sync (no animation back)
                targetPanY = mapPanY
                panVelocityX = panVelocityX * getPanFriction()
                panVelocityY = panVelocityY * getPanFriction()

                -- Stop when velocity is negligible
                if math.abs(panVelocityX) <= PAN_MIN_VELOCITY then panVelocityX = 0 end
                if math.abs(panVelocityY) <= PAN_MIN_VELOCITY then panVelocityY = 0 end

                needsUpdate = true
            end

            -- Smooth pan interpolation (for double-click recenter)
            if not isDragging and math.abs(panVelocityX) <= PAN_MIN_VELOCITY and math.abs(panVelocityY) <= PAN_MIN_VELOCITY then
                local dx = targetPanX - mapPanX
                local dy = targetPanY - mapPanY
                if math.abs(dx) > 0.5 or math.abs(dy) > 0.5 then
                    mapPanX = mapPanX + dx * PAN_INERTIA
                    mapPanY = mapPanY + dy * PAN_INERTIA

                    -- Snap to target when very close
                    if math.abs(dx) < 0.5 then mapPanX = targetPanX end
                    if math.abs(dy) < 0.5 then mapPanY = targetPanY end

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
                    mapPanX = cursorInContainerX - newCursorOnImageX - newOffsetXWithoutPan
                    mapPanY = cursorInContainerY - newCursorOnImageY - newOffsetYWithoutPan
                    targetPanX = mapPanX
                    targetPanY = mapPanY
                end

                needsUpdate = true
            end

            -- Update when pinned: follow player if enabled, always update marker position
            if state:get('pinned') then
                local shouldFollow = playerSettings:get('follow_player') and not hasPanned
                if shouldFollow then
                    -- Update target to player position (smooth interpolation will animate)
                    targetPanX, targetPanY = getPlayerCenteredPan(currentMapWidth, currentMapHeight)
                end
                updateTitle()  -- Update title when player moves to a new cell
                needsUpdate = true  -- Always update to refresh marker position
            end

            if needsUpdate then
                updateMapDisplay()
            end
        end,

        onMouseWheel = function(vertical, _horizontal)
            if not mapVisible then return end
            if not lastMouseOffset then return end

            -- Multiplicative zoom: speed scales with current zoom for natural feel
            local zoomFactor = 1 + vertical * getZoomSpeed()
            local minZoom = getMinZoomForContainer(currentMapWidth, currentMapHeight)
            targetZoom = math.max(minZoom, math.min(getMaxZoom(), targetZoom * zoomFactor))
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
