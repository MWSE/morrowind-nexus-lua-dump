local I = require('openmw.interfaces')
local camera = require('openmw.camera')
local input = require('openmw.input')
local core = require('openmw.core')
local storage = require('openmw.storage')

-- Mod identity (must match folder name)
local MOD_NAME = "ZoomToSee"  -- v1.1

-- State variables
local zoomActive = false
local zoomToggled = false
local defaultFOV = camera.getFieldOfView()
local currentFOV = defaultFOV
local lastAppliedFOV = defaultFOV
local wasKeyPressed = false
local timeSinceLastFOVCheck = 0
local lastKnownGoodFOV = defaultFOV
local wasMousePressed = false
local lastZoomState = false       -- Tracks previous frame's zoom state

-- Settings storage
local settings = storage.playerSection("Settings" .. MOD_NAME)

-- Conversion functions
local function degreesToRadians(deg)
    return deg * 0.0174533
end

local function radiansToDegrees(rad)
    return rad * 57.2958
end

-- Register settings page and group
I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Zoom To See",
    description = "Configurable zoom functionality\nZ key to toggle, Middle Mouse to hold"
}

I.Settings.registerGroup {
    key = "Settings" .. MOD_NAME,
    page = MOD_NAME,
    l10n = MOD_NAME,
    name = "Configuration",
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            name = 'Enable Mod',
            description = 'Toggle the entire zoom functionality',
            renderer = 'checkbox',
            default = true
        },
        {
            key = 'zoom_fov_degrees',
            name = 'Zoom FOV (degrees)',
            description = 'Field of view when zoomed (in degrees, default 42 degrees)',
            renderer = 'number',
            argument = {
                min = 5,
                max = 120,
                step = 0.1
            },
            default = radiansToDegrees(0.733) -- Convert default radians to degrees
        },
        {
            key = 'zoom_speed',
            name = 'Zoom Speed',
            description = 'How fast the transition between normal and zoomed view occurs, default 6',
            renderer = 'number',
            argument = {
                min = 0.1,
                max = 20,
                step = 0.1
            },
            default = 6.0
        },
        {
            key = 'lock_fov',
            name = 'Lock FOV',
            description = 'Prevent other mods from changing FOV while zoomed',
            renderer = 'checkbox',
            default = true
        },
        {
            key = 'fov_check_interval',
            name = 'FOV Check Interval',
            description = 'How often the mod checks if default FOV was changed (in seconds)',
            renderer = 'number',
            argument = {
                min = 0.1,
                max = 5,
                step = 0.1
            },
            default = 0.5
        }
    }
}

-- Update FOV smoothly
local function updateZoom(dt)
    if not settings then return end
    
    -- Calculate target FOV (convert degrees to radians)
    local targetFOV = zoomActive and degreesToRadians(settings:get("zoom_fov_degrees")) or defaultFOV
    
    -- Smooth transition
    if math.abs(currentFOV - targetFOV) > 0.001 then
        currentFOV = currentFOV + (targetFOV - currentFOV) * settings:get("zoom_speed") * dt
    else
        currentFOV = targetFOV
    end
    
    -- Apply FOV changes
    if settings:get("lock_fov") or math.abs(camera.getFieldOfView() - currentFOV) > 0.001 then
        camera.setFieldOfView(currentFOV)
        lastAppliedFOV = currentFOV
    end
    
    -- Emergency recovery if FOV gets overwritten
    if settings:get("lock_fov") and zoomActive and math.abs(camera.getFieldOfView() - lastAppliedFOV) > 0.01 then
        camera.setFieldOfView(currentFOV)
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            if not settings or not settings:get("enabled") then return end
            
            -- Track time for periodic FOV checks
            timeSinceLastFOVCheck = timeSinceLastFOVCheck + dt

            -- Periodically verify default FOV hasn't changed
            if timeSinceLastFOVCheck >= settings:get("fov_check_interval") then
                timeSinceLastFOVCheck = 0
                
                -- Only update default FOV if not currently zoomed
                if not zoomActive then
                    local currentGameFOV = camera.getFieldOfView()
                    
                    -- If FOV changed significantly and we're not zooming
                    if math.abs(currentGameFOV - lastKnownGoodFOV) > 0.01 then
                        defaultFOV = currentGameFOV
                        lastKnownGoodFOV = defaultFOV
                        currentFOV = defaultFOV  -- Immediately match new FOV
                    end
                end
            end

            -- Handle mouse hold-to-zoom (2 = middle mouse)
            local mouseHeld = input.isMouseButtonPressed(2)
            
            -- Handle mouse press to cancel toggle zoom
            if mouseHeld then
                if not wasMousePressed and zoomToggled then
                    -- Only cancel the toggle if it was active and this is a new press
                    zoomToggled = false
                end
                wasMousePressed = true
            else
                wasMousePressed = false
            end
            
            -- Handle key toggle (Z key)
            if input.isKeyPressed(input.KEY.Z) then
                if not wasKeyPressed then  -- Only toggle on new press
                    zoomToggled = not zoomToggled
                    -- Update default FOV when first pressing zoom
                    if not zoomToggled then  -- On zoom release
                        defaultFOV = camera.getFieldOfView()
                        lastKnownGoodFOV = defaultFOV
                    end
                end
                wasKeyPressed = true
            else
                wasKeyPressed = false
            end
            
            -- Combined zoom state
            zoomActive = zoomToggled or mouseHeld
            
            -- Update default FOV when completely exiting zoom
            if not zoomActive and lastZoomState then
                defaultFOV = camera.getFieldOfView()
                lastKnownGoodFOV = defaultFOV
            end
            lastZoomState = zoomActive
            
            -- Update FOV
            updateZoom(dt)
        end,
        
        onInit = function()
            settings = storage.playerSection("Settings" .. MOD_NAME)
        end,
        
        onLoad = function()
            defaultFOV = camera.getFieldOfView()
            lastKnownGoodFOV = defaultFOV
            currentFOV = defaultFOV
            zoomActive = false
            zoomToggled = false
            wasMousePressed = false
            camera.setFieldOfView(defaultFOV)
        end,
        
        onKeyPress = function(key)
            if key.symbol == input.KEY.Escape and zoomActive then
                zoomActive = false
                zoomToggled = false
                currentFOV = defaultFOV
                camera.setFieldOfView(defaultFOV)
            end
        end
    }
}