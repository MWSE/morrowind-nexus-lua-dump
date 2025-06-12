-- projection.lua: World-to-screen projection utilities for Interactable Highlight mod
-- Handles converting 3D world positions to 2D screen coordinates

local ui = require('openmw.ui')
local util = require('openmw.util')
local camera = require('openmw.camera')

local M = {}

-- Cache screen size to avoid repeated lookups
local screenSize = ui.screenSize()

-- Logger for debugging
local logger = require('scripts.TwentyTwentyObjects.util.logger')

-- Update cached screen size (call on resolution change)
function M.updateScreenSize()
    -- Force update from UI
    screenSize = ui.screenSize()
    -- Check if debug mode is enabled
    local storage = require('scripts.TwentyTwentyObjects.util.storage')
    local generalSettings = storage.get('general', { debug = false })
    if generalSettings.debug then
        logger.debug(string.format('Screen size updated: %dx%d', screenSize.x, screenSize.y))
    end
end

-- Convert world position to screen coordinates
-- Returns vector2 or nil if position is behind camera
function M.worldToScreen(worldPos)
    -- First do a simple check if object is behind camera
    -- This prevents objects behind us from being projected to screen coordinates in front
    local camPos = camera.getPosition()
    local toObject = worldPos - camPos
    
    -- Get camera forward direction from yaw and pitch
    local yaw = camera.getYaw() + camera.getExtraYaw()
    local pitch = camera.getPitch() + camera.getExtraPitch()
    
    -- Calculate forward vector
    local camForward = util.vector3(
        math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
    
    -- Check if object is in front hemisphere (dot product > 0)
    local dot = toObject:dot(camForward)
    if dot <= 0 then
        -- Object is behind camera
        return nil
    end
    
    -- Use OpenMW's camera projection function
    local viewportPos = camera.worldToViewportVector(worldPos)
    
    -- Check if debug mode is enabled
    local storage = require('scripts.TwentyTwentyObjects.util.storage')
    local generalSettings = storage.get('general', { debug = false })
    
    -- The z component is the distance from camera to object
    -- If it's negative or very small, the object is behind or at the camera
    if viewportPos.z <= 1 then
        -- logger.debug('Object behind camera (z <= 1)')
        return nil
    end
    
    -- Update screen size if needed
    if not screenSize or screenSize.x == 0 then
        M.updateScreenSize()
    end
    
    -- The viewport coordinates are already in screen pixels
    local screenX = viewportPos.x
    local screenY = viewportPos.y
    
    -- WORKAROUND: At ultrawide resolutions, OpenMW sometimes returns incorrect viewport coordinates
    -- If the coordinates are way outside reasonable bounds, try to correct them
    if math.abs(screenX) > screenSize.x * 3 then
        if generalSettings.debug then
            logger.debug(string.format('Correcting extreme X coordinate: %.1f -> clamped', screenX))
        end
        -- This object is likely at the edge of the screen, clamp it
        screenX = screenX > 0 and (screenSize.x + 100) or -100
    end
    
    if math.abs(screenY) > screenSize.y * 3 then
        if generalSettings.debug then
            logger.debug(string.format('Correcting extreme Y coordinate: %.1f -> clamped', screenY))
        end
        screenY = screenY > 0 and (screenSize.y + 100) or -100
    end
    
    -- Create screen position vector
    local screenPos = util.vector2(screenX, screenY)
    
    -- Log suspicious coordinates
    if generalSettings.debug and (math.abs(screenX) > screenSize.x * 2 or math.abs(screenY) > screenSize.y * 2) then
        logger.debug(string.format('Suspicious viewport coordinates: viewport=(%.1f, %.1f, %.1f), screen size=%dx%d', 
            viewportPos.x, viewportPos.y, viewportPos.z, screenSize.x, screenSize.y))
        logger.debug(string.format('Camera pos: %s, Object pos: %s, Distance: %.1f', 
            tostring(camPos), tostring(worldPos), toObject:length()))
    end
    
    -- Be more lenient with bounds checking - objects slightly off-screen might still have visible labels
    local margin = 200  -- Increased margin
    if not M.isOnScreen(screenPos, margin) then
        -- Only log for extreme cases to reduce spam
        if math.abs(screenX) > 5000 or math.abs(screenY) > 5000 then
            logger.debug(string.format('worldToScreen: pos=%s, viewport=%s (z=%.2f)', 
                tostring(worldPos), tostring(viewportPos), viewportPos.z))
            logger.debug(string.format('Object far outside screen bounds: (%.1f, %.1f)', screenX, screenY))
        end
        return nil
    end
    
    return screenPos
end

-- Get the top-center position of an object's bounding box
function M.getObjectLabelPosition(object)
    local pos = object.position
    
    -- Try to get bounding box if the method exists
    local bbox = nil
    local success, result = pcall(function() return object:getBoundingBox() end)
    if success then
        bbox = result
    end
    
    if bbox and bbox.max and bbox.max.z then
        -- Use top of bounding box with minimal clearance
        return util.vector3(
            pos.x,
            pos.y,
            pos.z + bbox.max.z  -- No extra clearance, let jitter solver handle offset
        )
    else
        -- Fallback: use object position plus minimal offset
        -- The jitter solver will handle the actual label placement
        local offset = 0  -- Start at object center
        
        -- Try to determine object type for better offset
        if object.type then
            local types = require('openmw.types')
            if object.type == types.NPC or object.type == types.Creature then
                offset = 100  -- Head height for actors (was 50)
            elseif object.type == types.Container then
                offset = 0   -- Use center for containers
            elseif object.type == types.Door then
                offset = 50  -- Center-ish height for doors (was 40)
            end
        end
        
        return pos + util.vector3(0, 0, offset)
    end
end

-- Check if screen position is within visible bounds
function M.isOnScreen(screenPos, margin)
    margin = margin or 0
    return screenPos.x >= -margin and 
           screenPos.x <= screenSize.x + margin and
           screenPos.y >= -margin and 
           screenPos.y <= screenSize.y + margin
end

-- Clamp screen position to stay within bounds
function M.clampToScreen(screenPos, margin)
    margin = margin or 10
    return util.vector2(
        math.max(margin, math.min(screenSize.x - margin, screenPos.x)),
        math.max(margin, math.min(screenSize.y - margin, screenPos.y))
    )
end

-- Get distance-based scale factor for labels
function M.getDistanceScale(distance, minDist, maxDist)
    minDist = minDist or 100
    maxDist = maxDist or 2000
    
    -- Clamp distance to range
    distance = math.max(minDist, math.min(maxDist, distance))
    
    -- Linear interpolation (could use other curves)
    local t = (distance - minDist) / (maxDist - minDist)
    return 1.0 - (t * 0.5)  -- Scale from 100% to 50%
end

return M