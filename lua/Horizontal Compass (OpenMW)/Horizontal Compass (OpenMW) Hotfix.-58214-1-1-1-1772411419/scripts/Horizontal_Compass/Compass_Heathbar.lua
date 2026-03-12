-- OpenMW 50 --
-- Horizontal Compass Heathbar --

local ui = require("openmw.ui")
local util = require("openmw.util")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local camera = require("openmw.camera")
local core = require("openmw.core")
local interfaces = require("openmw.interfaces")

local ROLE_INDEX = require("scripts.Horizontal_Compass.lib.role_index")

local storage = require("openmw.storage")
local settings = storage.playerSection("Horizontal_Compass_Settings_HB")

-- =====================================================
-- TEXTURE CACHE
-- =====================================================
local textureCache = {}

local function getTexture(path)
    if not path then return nil end
    if not textureCache[path] then
        textureCache[path] = ui.texture { path = path }
    end
    return textureCache[path]
end

-- =====================================================
-- CONFIG
-- =====================
local rawHbScale = settings:get("hbScale") or 100
local HB_SCALE_FACTOR = rawHbScale / 100

local BAR_WIDTH, BAR_HEIGHT = 285 * HB_SCALE_FACTOR, 9 * HB_SCALE_FACTOR
local OVERLAY_WIDTH, OVERLAY_HEIGHT = 340 * HB_SCALE_FACTOR, 34 * HB_SCALE_FACTOR
local SIDE_IMAGE_SIZE = util.vector2(32 * HB_SCALE_FACTOR, 32 * HB_SCALE_FACTOR)
local SIDE_IMAGE_OFFSET = 5 * HB_SCALE_FACTOR

local OVERLAY_COLOR = util.color.rgb(1, 0.8, 0.4 )
local LAG_BAR_COLOR = util.color.rgb(1, 1, 1)

local hbPosX = (settings:get("hbPosX") or 50) / 100
local hbPosY = (settings:get("hbPosY") or 0) / 100

local MAX_DISTANCE = 700
local FADE_SPEED = 4
local LAG_SPEED = 0.6

local COMBAT_HOLD_TIME = 60.0
local DEATH_HOLD_TIME = 0.6
local NEUTRAL_HOLD_TIME = 1.6

local SHOW_DURING_DIALOG = true



local function lerp(a, b, dt, speed)
    return a + (b - a) * math.min(1, dt * speed)
end

-- =====================================================
-- STATE
-- =====================================================
local currentTarget = nil
local cachedProfile = nil
local currentAlpha = 0
local currentLagWidth = 0
local holdTimer = 0

-- =====================================================
-- UI ROOT
-- =====================================================
local root = ui.create {
    layer = "HUD",
    type = ui.TYPE.Widget,
    props = {
        relativeSize = util.vector2(1, 1),
        mouseTransparent = true
    },
    content = ui.content {}
}

local targetContainer = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size = util.vector2(600, 100),
        relativePosition = util.vector2(hbPosX, hbPosY),
        anchor = util.vector2(0.5, -0.45),
        alpha = 0,
        mouseTransparent = true,
    },
    content = ui.content {}
}

-- =====================================================
-- UI ELEMENTS
-- =====================================================
local hbBackground = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/background.png"),
        size = util.vector2(BAR_WIDTH, BAR_HEIGHT),
        position = util.vector2(300, 40 + (BAR_HEIGHT / 2)),
        anchor = util.vector2(0.5, 0.5),
        zOrder = -10,
    }
}

local lagBarLeft = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/lag_bar.png"),
        size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
        position = util.vector2(300, 40),
        anchor = util.vector2(1, 0.3),
        color = LAG_BAR_COLOR,
    }
}

local lagBarRight = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/lag_bar.png"),
        size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
        position = util.vector2(300, 40),
        anchor = util.vector2(0, 0.3),
        color = LAG_BAR_COLOR,
    }
}

local hbBarLeft = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/health_bar.png"),
        size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
        position = util.vector2(300, 40),
        anchor = util.vector2(1, 0.3),
        color = util.color.rgb(0.75, 0.05, 0.15),
    }
}

local hbBarRight = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/health_bar.png"),
        size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
        position = util.vector2(300, 40),
        anchor = util.vector2(0, 0.3),
        color = util.color.rgb(0.75, 0.05, 0.15),
    }
}

local hbOverlay = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/frame.png"),
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT),
        position = util.vector2(300, 40 + (BAR_HEIGHT / 2)),
        anchor = util.vector2(0.5, 0.5),
        color = OVERLAY_COLOR,
        zOrder = 100,
    }
}

local leftIcon = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/left_art.png"),
        size = SIDE_IMAGE_SIZE,
        position = util.vector2(
            300 - (OVERLAY_WIDTH / 2) - SIDE_IMAGE_OFFSET,
            40 + (BAR_HEIGHT / 2)
        ),
        anchor = util.vector2(0.1, 0.3),
        color = OVERLAY_COLOR,
        zOrder = 110,
    }
}

local rightIcon = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/right_art.png"),
        size = SIDE_IMAGE_SIZE,
        position = util.vector2(
            300 + (OVERLAY_WIDTH / 2) + SIDE_IMAGE_OFFSET,
            40 + (BAR_HEIGHT / 2)
        ),
        anchor = util.vector2(0.85, 0.3),
        color = OVERLAY_COLOR,
        zOrder = 110,
    }
}

local nameElement = ui.create {
    type = ui.TYPE.Text,
    props = {
        text = "",
        textSize = 20 * HB_SCALE_FACTOR,
        textShadow = true,
        textColor = util.color.rgb(0.95, 0.95, 0.9),
        position = util.vector2(300, 0),
        anchor = util.vector2(0.5, -2.6),
    }
}

local levelElement = ui.create {
    type = ui.TYPE.Text,
    props = {
        text = "",
        textSize = 22 * HB_SCALE_FACTOR,
        textShadow = true,
        textColor = util.color.rgb(0.95, 0.95, 0.9),
        position = util.vector2(300 - (OVERLAY_WIDTH / 2) - SIDE_IMAGE_OFFSET, 40 + (BAR_HEIGHT / 2)),
        anchor = util.vector2(-0.1, 0.3),
        zOrder = 120,
    }
}


local classElement = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/roles/unknown.png"),
        size = util.vector2(30 * HB_SCALE_FACTOR, 30 * HB_SCALE_FACTOR),
        position = util.vector2(
            300 + (OVERLAY_WIDTH / 2) + SIDE_IMAGE_OFFSET, 
            40 + (BAR_HEIGHT / 2)
        ),
        anchor = util.vector2(0.85, 0.3),
        alpha = 1,
        color = util.color.rgb(1, 0.95, 0.85),
        zOrder = 120,
    }
}

-- =====================================================
-- ASSEMBLE
-- =====================================================
targetContainer.layout.content:add(hbBackground)
targetContainer.layout.content:add(lagBarLeft)
targetContainer.layout.content:add(lagBarRight)
targetContainer.layout.content:add(hbBarLeft)
targetContainer.layout.content:add(hbBarRight)
targetContainer.layout.content:add(hbOverlay)
targetContainer.layout.content:add(leftIcon)
targetContainer.layout.content:add(rightIcon)
targetContainer.layout.content:add(nameElement)
targetContainer.layout.content:add(levelElement)
targetContainer.layout.content:add(classElement)

root.layout.content:add(targetContainer)

-- =====================================================
-- UPDATE LOOP
-- =====================================================
local function onFrame(dt)
    if not SHOW_DURING_DIALOG then
        if interfaces.UI.getMode() ~= nil or core.isWorldPaused() then
            currentAlpha = math.max(0, currentAlpha - dt * FADE_SPEED)
            targetContainer.layout.props.alpha = currentAlpha
            targetContainer:update()
            return
        end
    end
	
    local isEnabled = settings:get("showHealthBar")
    if isEnabled == nil then isEnabled = true end
    local isHudVisible = interfaces.UI.isHudVisible()

    local rayStart = camera.getPosition()
    local rayDir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    local rayEnd = rayStart + rayDir * MAX_DISTANCE
    local res = nearby.castRenderingRay(rayStart, rayEnd, {ignore = self, collisionType = nearby.COLLISION_TYPE.Actor})
    local scanTarget = res.hitObject

    if scanTarget and scanTarget:isValid() and types.Actor.objectIsInstance(scanTarget) then
        if currentTarget ~= scanTarget then
            currentTarget = scanTarget
            cachedProfile = ROLE_INDEX.getVisualProfile(currentTarget)
            if cachedProfile then
                classElement.layout.props.resource = getTexture(cachedProfile.icon)
            end
        end

        if types.Actor.isDead(currentTarget) then
            holdTimer = NEUTRAL_HOLD_TIME
        else
            local hostile = currentTarget.type == types.Creature or (currentTarget.type == types.NPC and types.NPC.getDisposition(currentTarget, self.object) < 30)
            holdTimer = hostile and COMBAT_HOLD_TIME or NEUTRAL_HOLD_TIME
        end
    else
        holdTimer = math.max(0, holdTimer - dt)
    end

    local shouldShow = currentTarget and holdTimer > 0 and isHudVisible and isEnabled

    if shouldShow then
        currentAlpha = math.min(1, currentAlpha + dt * FADE_SPEED)

        local showLevelSetting = settings:get("showLevel")
        if showLevelSetting == nil then showLevelSetting = true end

        local showClassSetting = settings:get("showClassIcon")
        if showClassSetting == nil then showClassSetting = true end
	
        local showNameSetting = settings:get("showTargetName")
        if showNameSetting == nil then showNameSetting = true end

        -- Level & Left Wing logic
        if showLevelSetting then
            local level = types.Actor.stats.level(currentTarget).current
            levelElement.layout.props.text = tostring(level)
            levelElement.layout.props.alpha = currentAlpha
            leftIcon.layout.props.alpha = currentAlpha
        else
            levelElement.layout.props.alpha = 0
            leftIcon.layout.props.alpha = 0
        end

        -- Class & Right Wing logic
        if showClassSetting then
            classElement.layout.props.alpha = currentAlpha
            rightIcon.layout.props.alpha = currentAlpha
        else
            classElement.layout.props.alpha = 0
            rightIcon.layout.props.alpha = 0
        end
	
        -- Name logic
        if showNameSetting then
            local displayName = (currentTarget.type == types.NPC) and types.NPC.record(currentTarget).name or types.Creature.record(currentTarget).name
            nameElement.layout.props.text = displayName
            nameElement.layout.props.alpha = currentAlpha
        else
            nameElement.layout.props.alpha = 0
        end

        local health = types.Actor.stats.dynamic.health(currentTarget)
        if health then
            if types.Actor.isDead(currentTarget) then
                currentLagWidth = 0
                hbBarLeft.layout.props.size = util.vector2(0, BAR_HEIGHT)
                hbBarRight.layout.props.size = util.vector2(0, BAR_HEIGHT)
                lagBarLeft.layout.props.size = util.vector2(0, BAR_HEIGHT)
                lagBarRight.layout.props.size = util.vector2(0, BAR_HEIGHT)
            else
                local ratio = math.max(0, math.min(1, health.current / health.base))
                local targetWidth = (BAR_WIDTH / 2) * ratio
                hbBarLeft.layout.props.size = util.vector2(targetWidth, BAR_HEIGHT)
                hbBarRight.layout.props.size = util.vector2(targetWidth, BAR_HEIGHT)
                currentLagWidth = lerp(currentLagWidth, targetWidth, dt, LAG_SPEED)
                lagBarLeft.layout.props.size = util.vector2(currentLagWidth, BAR_HEIGHT)
                lagBarRight.layout.props.size = util.vector2(currentLagWidth, BAR_HEIGHT)
            end
        end
    else
        currentAlpha = math.max(0, currentAlpha - dt * FADE_SPEED)
        if currentAlpha <= 0 then
            currentTarget = nil
            cachedProfile = nil
            classElement.layout.props.alpha = 0
            levelElement.layout.props.text = ""
            nameElement.layout.props.text = ""
            nameElement.layout.props.alpha = 0
            leftIcon.layout.props.alpha = 0
            rightIcon.layout.props.alpha = 0
        end
    end

    targetContainer.layout.props.alpha = currentAlpha
    targetContainer.layout.props.visible = currentAlpha > 0
    targetContainer:update()
    hbBackground:update()
    lagBarLeft:update()
    lagBarRight:update()
    hbBarLeft:update()
    hbBarRight:update()
    hbOverlay:update()
    leftIcon:update()
    rightIcon:update()
    classElement:update()
    levelElement:update()
    nameElement:update()
end

return { engineHandlers = { onFrame = function(dt) 
local Enabled = settings:get("showHealthBar") 
if Enabled == true then 
onFrame(dt) 
end 
end} }
