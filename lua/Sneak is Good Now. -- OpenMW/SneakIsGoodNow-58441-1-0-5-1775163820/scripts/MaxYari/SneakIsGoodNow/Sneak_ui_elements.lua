local mp = "scripts/MaxYari/SneakIsGoodNow/"

local ui = require("openmw.ui")
local util = require("openmw.util")
local camera = require("openmw.camera")

local gutils = require(mp .. 'utils/gutils')
local Tweener = require(mp .. 'utils/tweener')
local s = require(mp .. "settings")

-- DetectionMarker class
local DetectionMarker = {}
DetectionMarker.__index = DetectionMarker

-- Config
local markerSizeScale = 1.0
local markerBgColor = util.color.hex("0f0f1f")
local markerFillColor = util.color.hex("efc36b")
local markerFillDangerColor = util.color.hex("c01c28") -- Saturated red for danger
local markerGrayColor = util.color.hex("808080") -- Gray for non-aggressive

local markerSize= util.vector2(50, 50) * markerSizeScale -- Size of the detection marker UI element
local disapearAnimSize = markerSize * 1.5 -- Size to scale to when disappearing

-- Constructor that creates a new UI element upon instantiation
function DetectionMarker:new()
    local instance = setmetatable({}, DetectionMarker)

    -- Initialize tweeners dictionary
    instance.tweeners = {}

    -- Initialize aggressive state
    instance.isAggressive = false

    -- Create the UI element with a cropping wrapper and fill image
    instance.element = ui.create({
        layer = 'HUD',
        type = ui.TYPE.Widget,
        name = "detectionMarkerWrapper",
        props = {
            size = markerSize,
            alpha = 0, -- Start with alpha 0 for appear animation
            position = util.vector2(0, 0), -- Will be set by setWorldPos
            anchor = util.vector2(0.5, 1),
        },
        content = ui.content {
            {
                name = "detectionMarkerBg",
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    color = markerBgColor,
                    alpha = 0.5,
                    resource = ui.texture { path = mp .. "textures/detection_marker_bg.png" }
                }
            },
            {
                name = "detectionMarkerGlow",
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    color = markerFillColor,
                    alpha = 0.5,
                    resource = ui.texture { path = mp .. "textures/detection_marker_glow.png" }
                }
            },
            {
                name = "detectionFillWrapper",
                type = ui.TYPE.Widget,
                props = {
                    relativeSize = util.vector2(1, 0), -- Will be updated by setProgress
                    relativePosition = util.vector2(0.5, 1), -- Anchored at bottom center
                    anchor = util.vector2(0.5, 1), -- Anchor at bottom center
                    alpha = 1.0,
                },
                content = ui.content {
                    {
                        name = "detectionFill",
                        type = ui.TYPE.Image,
                        props = {
                            alpha = 0.8,
                            size = markerSize, -- Same as parent to fill when relativeSize is 1,1
                            color = markerFillColor,
                            relativePosition = util.vector2(0.5, 1),
                            anchor = util.vector2(0.5, 1),
                            resource = ui.texture { path = mp .. "textures/detection_marker_fill.png" }
                        }
                    }
                }
            }
        }
    })

    -- Automatically trigger appear animation upon instantiation
    instance:appear()

    return instance
end

-- Method to set the detection progress
function DetectionMarker:setProgress(progress)
    -- Clamp progress between 0 and 1
    progress = util.clamp(progress, 0, 1)
    local fillProgress = util.remap(progress, 0, 1, 0.2, 0.8)
    local fillAlpha = gutils.lerp(0.33, 0.8, progress)
    local glowAlpha = gutils.lerp(0.1, 1, progress)

    -- Determine colors based on aggressive state and progress
    local fillColor, glowColor
    if not self.isAggressive then
        -- Non-aggressive: always gray
        fillColor = markerGrayColor
        glowColor = markerGrayColor
    else
        -- Aggressive: lerp from yellow to red starting at 66% progress
        if progress < 0.66 then
            -- Below 66%: use original yellow color
            fillColor = markerFillColor
            glowColor = markerFillColor
        else
            -- At or above 66%: lerp from yellow to red
            local lerpT = util.remap(progress, 0.66, 1.0, 0, 1)
            lerpT = util.clamp(lerpT, 0, 1)
            local color = gutils.lerpColor(markerFillColor, markerFillDangerColor, lerpT)
            fillColor = color
            glowColor = color
        end
    end

    -- Update the relative height of the wrapper to reveal more of the image
    self.element.layout.content["detectionFillWrapper"].props.relativeSize = util.vector2(1, fillProgress)
    self.element.layout.content["detectionFillWrapper"].content["detectionFill"].props.alpha = fillAlpha
    self.element.layout.content["detectionFillWrapper"].content["detectionFill"].props.color = fillColor
    self.element.layout.content["detectionMarkerGlow"].props.alpha = glowAlpha
    self.element.layout.content["detectionMarkerGlow"].props.color = glowColor

    self.element:update()
end

function DetectionMarker:setWorldPos(worldPos)
    local screenSize = ui.screenSize()
    local center = util.vector2(screenSize.x * 0.5, screenSize.y * 0.5)

    -- Projected screen position (for on-screen case)
    local proj = camera.worldToViewportVector(worldPos)
    local screenPos = util.vector2(proj.x, proj.y)

    -- Get camera-space coordinates
    local camSpace = camera.getViewTransform():apply(worldPos)
    local xCam, yCam, zCam = camSpace.x, camSpace.y, camSpace.z
    local screenSideFlipper = zCam/math.abs(zCam)

    -- Check if target is visible on-screen (in front and within screen bounds)
    local isVisible =
        zCam < 0 and
        screenPos.x >= 0 and screenPos.x <= screenSize.x and
        screenPos.y >= 0 and screenPos.y <= screenSize.y

    if isVisible then
        -- On-screen: use projection directly
        local relScreenPos = util.vector2(screenPos.x/screenSize.x, screenPos.y/screenSize.y)        
        self.element.layout.props.relativePosition = relScreenPos
        self.element:update()
        return
    end

    -- Off-screen or behind camera: compute stable 2D direction from camera space
    local dir = util.vector2(xCam, yCam)

    -- If target is directly on the camera forward axis, pick default direction
    if dir.x == 0 and dir.y == 0 then
        dir = util.vector2(0, 1)
    end

    -- Normalize direction
    local len = math.sqrt(dir.x * dir.x + dir.y * dir.y)
    dir = util.vector2(screenSideFlipper * dir.x / len, -screenSideFlipper * dir.y / len)

    -- If target is behind the camera, invert direction
    if zCam < 0 then
        dir = -dir
    end

    -- Intersect ray with screen rectangle
    local scaleX = math.abs(dir.x) > 0 and ((screenSize.x * 0.5) / math.abs(dir.x)) or math.huge
    local scaleY = math.abs(dir.y) > 0 and ((screenSize.y * 0.5) / math.abs(dir.y)) or math.huge
    local scale = math.min(scaleX, scaleY)

    local edgePos = center + dir * scale

    -- Account for marker size
    -- This assumes that marker anchor is (0.5, 1) (bottom center)
    local elementSize = self.element.layout.props.size
    edgePos = util.vector2(
        util.clamp(edgePos.x, elementSize.x * 0.5, screenSize.x - elementSize.x * 0.5),
        util.clamp(edgePos.y, 0 + elementSize.y, screenSize.y)
    )

    -- Apply position
    local relScreenPos = util.vector2(edgePos.x/screenSize.x, edgePos.y/screenSize.y) 
    self.element.layout.props.relativePosition = relScreenPos
    self.element:update()
end

function DetectionMarker:setAggressive(aggressive)
    self.isAggressive = aggressive or false
    self.element:update()
end




-- Method to create appearance animation
function DetectionMarker:appear()
    -- Check if an appear animation is already running
    if self.tweeners["appear"] and self.tweeners["appear"].playing then
        return -- Animation already running, don't start another
    end

    -- Create a new tweener instance for this animation
    local tweener = Tweener:new()

    -- Add the alpha animation from 0 to 1 with callback
    tweener:add(
        0.3, -- Duration in seconds
        Tweener.easings.easeOutQuad, -- Easing function
        function(value)
            self.element.layout.props.alpha = value * s.settings["MarkersAlpha"]
            self.element:update()
        end
    )

    -- Store the tweener directly
    self.tweeners["appear"] = tweener

    return "appear"
end

-- Method to create disappearance animation
function DetectionMarker:disappear(wasSuccessful, autoDestroy)
    if self.destroyed then
        return
    end

    if wasSuccessful == nil then
        wasSuccessful = false
    end
    if autoDestroy == nil then
        autoDestroy = true
    end

    -- Check if a disappear animation is already running
    if self.tweeners["disappear"] and self.tweeners["disappear"].playing then
        return -- Animation already running, don't start another
    end

    -- Stop and remove the appear animation if it's still running
    if self.tweeners["appear"] and self.tweeners["appear"].playing then
        self.tweeners["appear"] = nil
    end

    -- Create a new tweener instance for this animation
    local tweener = Tweener:new()

    -- Store initial values for the animation
    -- Use fixed alpha = 1 to ensure marker is visible during disappear animation
    local initialSize = self.element.layout.props.size
    local initialAlpha = s.settings["MarkersAlpha"]    

    -- Add the size animation from current size to disappear size with cleanup callback
    tweener:add(
        0.5, -- Duration in seconds
        Tweener.easings.easeOutQuad, -- Easing function
        function(value)
            -- Interpolate between current size and disappear size using gutils.lerp
            if wasSuccessful == true then
                local newSize = gutils.lerp(initialSize, disapearAnimSize, value)            
                self.element.layout.props.size = newSize
                self.element.layout.content["detectionFillWrapper"].content["detectionFill"].props.size = newSize
            end

            -- Interpolate alpha from current alpha to 0 using gutils.lerp            
            local newAlpha = gutils.lerp(initialAlpha, 0, value)
            self.element.layout.props.alpha = newAlpha

            self.element:update()
        end,
        function(value)
            -- Callback to execute after animation completes
            if autoDestroy then
                self:destroy()
            end
        end
    )

    -- Store the tweener directly
    self.tweeners["disappear"] = tweener

    return "disappear"
end

function DetectionMarker:destroy()
    self.element:destroy()
    self.destroyed = true
end

-- Method to update all active tweeners
function DetectionMarker:updateTweeners(dt)
    for id, tweener in pairs(self.tweeners) do
        tweener:tick(dt)

        -- If the animation is complete, remove the tweener from the dictionary
        -- The callback is handled internally by the Tweener class
        if #tweener.animations == 0 and not tweener.playing then
            self.tweeners[id] = nil
        end
    end
end

return DetectionMarker
