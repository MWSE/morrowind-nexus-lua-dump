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
local hbSettings = storage.playerSection("Horizontal_Compass_Settings_HB")
local fbSettings = storage.playerSection("Horizontal_Compass_Settings_FB")
local mbSettings = storage.playerSection("Horizontal_Compass_Settings_MB")

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
-- CONSTANTS (shared)
-- =====================================================
local OVERLAY_COLOR = util.color.rgb(1, 0.8, 0.4)
local LAG_BAR_COLOR = util.color.rgb(1, 1, 1)

local HB_COLOR = util.color.rgb(0.75, 0.05, 0.15)  -- red   (health)
local FB_COLOR = util.color.rgb(0.15, 0.65, 0.15)  -- green (fatigue)
local MB_COLOR = util.color.rgb(0.20, 0.35, 0.85)  -- blue  (magicka)

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

-- =====================================================
-- BAR FACTORY
-- Creates a self-contained bar set (background + lag bars + fill bars + frame).
-- Returns a table holding the container, all child widgets, the dimensions used
-- to build them, and a `lagWidth` field used by the update loop's lerp.
-- =====================================================
local function createBarSet(scalePct, posXPct, posYPct, barColor)
    local scale = (scalePct or 100) / 100

    local BAR_WIDTH       = 285 * scale
    local BAR_HEIGHT      = 9   * scale
    local OVERLAY_WIDTH   = 340 * scale
    local OVERLAY_HEIGHT  = 34  * scale
    local SIDE_IMAGE_SIZE = util.vector2(32 * scale, 32 * scale)
    local SIDE_IMAGE_OFFSET = 5 * scale

    local posX = (posXPct or 50) / 100
    local posY = (posYPct or 0)  / 100

    local container = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(600, 100),
            relativePosition = util.vector2(posX, posY),
            anchor = util.vector2(0.5, -0.45),
            alpha = 0,
            mouseTransparent = true,
        },
        content = ui.content {}
    }

    local background = ui.create {
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

    local barLeft = ui.create {
        type = ui.TYPE.Image,
        props = {
            resource = getTexture("textures/Horizontal_Compass/health_bar.png"),
            size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
            position = util.vector2(300, 40),
            anchor = util.vector2(1, 0.3),
            color = barColor,
        }
    }

    local barRight = ui.create {
        type = ui.TYPE.Image,
        props = {
            resource = getTexture("textures/Horizontal_Compass/health_bar.png"),
            size = util.vector2(BAR_WIDTH / 2, BAR_HEIGHT),
            position = util.vector2(300, 40),
            anchor = util.vector2(0, 0.3),
            color = barColor,
        }
    }

    local overlay = ui.create {
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

    container.layout.content:add(background)
    container.layout.content:add(lagBarLeft)
    container.layout.content:add(lagBarRight)
    container.layout.content:add(barLeft)
    container.layout.content:add(barRight)
    container.layout.content:add(overlay)

    return {
        container        = container,
        background       = background,
        lagBarLeft       = lagBarLeft,
        lagBarRight      = lagBarRight,
        barLeft          = barLeft,
        barRight         = barRight,
        overlay          = overlay,
        scale            = scale,
        BAR_WIDTH        = BAR_WIDTH,
        BAR_HEIGHT       = BAR_HEIGHT,
        OVERLAY_WIDTH    = OVERLAY_WIDTH,
        OVERLAY_HEIGHT   = OVERLAY_HEIGHT,
        SIDE_IMAGE_SIZE  = SIDE_IMAGE_SIZE,
        SIDE_IMAGE_OFFSET = SIDE_IMAGE_OFFSET,
        lagWidth         = 0,
    }
end

-- Update the displayed widths for a bar set, matching the original health bar
-- logic: when the actor is dead, all widths collapse to zero; otherwise the
-- fill bars snap to the new ratio and the lag bars lerp toward it.
local function updateBarWidths(bar, dynamicStat, isDead, dt)
    if isDead then
        bar.lagWidth = 0
        bar.barLeft.layout.props.size     = util.vector2(0, bar.BAR_HEIGHT)
        bar.barRight.layout.props.size    = util.vector2(0, bar.BAR_HEIGHT)
        bar.lagBarLeft.layout.props.size  = util.vector2(0, bar.BAR_HEIGHT)
        bar.lagBarRight.layout.props.size = util.vector2(0, bar.BAR_HEIGHT)
        return
    end

    local ratio = 0
    if dynamicStat and dynamicStat.base and dynamicStat.base > 0 then
        ratio = math.max(0, math.min(1, dynamicStat.current / dynamicStat.base))
    end
    local targetWidth = (bar.BAR_WIDTH / 2) * ratio

    bar.barLeft.layout.props.size  = util.vector2(targetWidth, bar.BAR_HEIGHT)
    bar.barRight.layout.props.size = util.vector2(targetWidth, bar.BAR_HEIGHT)

    bar.lagWidth = lerp(bar.lagWidth, targetWidth, dt, LAG_SPEED)
    bar.lagBarLeft.layout.props.size  = util.vector2(bar.lagWidth, bar.BAR_HEIGHT)
    bar.lagBarRight.layout.props.size = util.vector2(bar.lagWidth, bar.BAR_HEIGHT)
end

local function pushBarUpdates(bar)
    bar.container:update()
    bar.background:update()
    bar.lagBarLeft:update()
    bar.lagBarRight:update()
    bar.barLeft:update()
    bar.barRight:update()
    bar.overlay:update()
end

-- =====================================================
-- CREATE THE THREE BAR SETS
-- =====================================================
local hbBar = createBarSet(
    hbSettings:get("hbScale"),
    hbSettings:get("hbPosX"),
    hbSettings:get("hbPosY"),
    HB_COLOR
)

local fbBar = createBarSet(
    fbSettings:get("fbScale"),
    fbSettings:get("fbPosX"),
    fbSettings:get("fbPosY"),
    FB_COLOR
)

local mbBar = createBarSet(
    mbSettings:get("mbScale"),
    mbSettings:get("mbPosX"),
    mbSettings:get("mbPosY"),
    MB_COLOR
)

-- =====================================================
-- HEALTH BAR EXTRAS (name, level, class icon, side art)
-- These live on the health bar container only.
-- =====================================================
local HB_SCALE_FACTOR = hbBar.scale

local leftIcon = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = getTexture("textures/Horizontal_Compass/left_art.png"),
        size = hbBar.SIDE_IMAGE_SIZE,
        position = util.vector2(
            300 - (hbBar.OVERLAY_WIDTH / 2) - hbBar.SIDE_IMAGE_OFFSET,
            40 + (hbBar.BAR_HEIGHT / 2)
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
        size = hbBar.SIDE_IMAGE_SIZE,
        position = util.vector2(
            300 + (hbBar.OVERLAY_WIDTH / 2) + hbBar.SIDE_IMAGE_OFFSET,
            40 + (hbBar.BAR_HEIGHT / 2)
        ),
        anchor = util.vector2(0.85, 0.3),
        color = OVERLAY_COLOR,
        zOrder = 110,
    }
}

-- Name vertical offset: slider 0..100, default 50 = current behavior.
-- Each unit shifts the anchor by 0.04, so the slider spans roughly +-2 anchor
-- units around the default -2.6 (lower slider = higher on screen).
local namePosYSetting = hbSettings:get("namePosY") or 50
local NAME_ANCHOR_Y = -2.6 + (namePosYSetting - 50) / 25

local nameElement = ui.create {
    type = ui.TYPE.Text,
    props = {
        text = "",
        textSize = 20 * HB_SCALE_FACTOR,
        textShadow = true,
        textColor = util.color.rgb(0.95, 0.95, 0.9),
        position = util.vector2(300, 0),
        anchor = util.vector2(0.5, NAME_ANCHOR_Y),
    }
}

local levelElement = ui.create {
    type = ui.TYPE.Text,
    props = {
        text = "",
        textSize = 22 * HB_SCALE_FACTOR,
        textShadow = true,
        textColor = util.color.rgb(0.95, 0.95, 0.9),
        position = util.vector2(300 - (hbBar.OVERLAY_WIDTH / 2) - hbBar.SIDE_IMAGE_OFFSET, 40 + (hbBar.BAR_HEIGHT / 2)),
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
            300 + (hbBar.OVERLAY_WIDTH / 2) + hbBar.SIDE_IMAGE_OFFSET,
            40 + (hbBar.BAR_HEIGHT / 2)
        ),
        anchor = util.vector2(0.85, 0.3),
        alpha = 1,
        color = util.color.rgb(1, 0.95, 0.85),
        zOrder = 120,
    }
}

hbBar.container.layout.content:add(leftIcon)
hbBar.container.layout.content:add(rightIcon)
hbBar.container.layout.content:add(nameElement)
hbBar.container.layout.content:add(levelElement)
hbBar.container.layout.content:add(classElement)

-- =====================================================
-- MOUNT ALL CONTAINERS ON THE ROOT
-- =====================================================
root.layout.content:add(hbBar.container)
root.layout.content:add(fbBar.container)
root.layout.content:add(mbBar.container)

-- =====================================================
-- STATE
-- =====================================================
local currentTarget = nil
local cachedProfile = nil
local currentAlpha = 0
local holdTimer = 0

-- =====================================================
-- UPDATE LOOP
-- =====================================================
local function onFrame(dt)
    if not SHOW_DURING_DIALOG then
        if interfaces.UI.getMode() ~= nil or core.isWorldPaused() then
            currentAlpha = math.max(0, currentAlpha - dt * FADE_SPEED)
            hbBar.container.layout.props.alpha = currentAlpha
            fbBar.container.layout.props.alpha = currentAlpha
            mbBar.container.layout.props.alpha = currentAlpha
            hbBar.container:update()
            fbBar.container:update()
            mbBar.container:update()
            return
        end
    end

    local showHealthBar = hbSettings:get("showHealthBar")
    if showHealthBar == nil then showHealthBar = true end
    local showFatigueBar = fbSettings:get("showFatigueBar")
    if showFatigueBar == nil then showFatigueBar = false end
    local showMagickaBar = mbSettings:get("showMagickaBar")
    if showMagickaBar == nil then showMagickaBar = false end

    local anyEnabled = showHealthBar or showFatigueBar or showMagickaBar
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

    local shouldShow = currentTarget and holdTimer > 0 and isHudVisible and anyEnabled

    if shouldShow then
        currentAlpha = math.min(1, currentAlpha + dt * FADE_SPEED)
        local isDead = types.Actor.isDead(currentTarget)

        -- ============ HEALTH BAR ============
        if showHealthBar then
            local showLevelSetting = hbSettings:get("showLevel")
            if showLevelSetting == nil then showLevelSetting = true end

            local showClassSetting = hbSettings:get("showClassIcon")
            if showClassSetting == nil then showClassSetting = true end

            local showNameSetting = hbSettings:get("showTargetName")
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
            updateBarWidths(hbBar, health, isDead, dt)
            hbBar.container.layout.props.alpha = currentAlpha
            hbBar.container.layout.props.visible = currentAlpha > 0
        else
            hbBar.container.layout.props.alpha = 0
            hbBar.container.layout.props.visible = false
        end

        -- ============ FATIGUE BAR ============
        if showFatigueBar then
            local fatigue = types.Actor.stats.dynamic.fatigue(currentTarget)
            updateBarWidths(fbBar, fatigue, isDead, dt)
            fbBar.container.layout.props.alpha = currentAlpha
            fbBar.container.layout.props.visible = currentAlpha > 0
        else
            fbBar.container.layout.props.alpha = 0
            fbBar.container.layout.props.visible = false
        end

        -- ============ MAGICKA BAR ============
        if showMagickaBar then
            local magicka = types.Actor.stats.dynamic.magicka(currentTarget)
            updateBarWidths(mbBar, magicka, isDead, dt)
            mbBar.container.layout.props.alpha = currentAlpha
            mbBar.container.layout.props.visible = currentAlpha > 0
        else
            mbBar.container.layout.props.alpha = 0
            mbBar.container.layout.props.visible = false
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
        hbBar.container.layout.props.alpha = currentAlpha
        hbBar.container.layout.props.visible = currentAlpha > 0
        fbBar.container.layout.props.alpha = currentAlpha
        fbBar.container.layout.props.visible = currentAlpha > 0
        mbBar.container.layout.props.alpha = currentAlpha
        mbBar.container.layout.props.visible = currentAlpha > 0
    end

    pushBarUpdates(hbBar)
    pushBarUpdates(fbBar)
    pushBarUpdates(mbBar)
    leftIcon:update()
    rightIcon:update()
    classElement:update()
    levelElement:update()
    nameElement:update()
end

return { engineHandlers = { onFrame = onFrame } }
