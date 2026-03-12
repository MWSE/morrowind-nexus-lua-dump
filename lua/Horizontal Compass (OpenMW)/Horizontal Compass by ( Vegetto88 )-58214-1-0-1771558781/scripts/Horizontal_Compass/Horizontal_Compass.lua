-- OpenMW 50 --
-- Horizontal Compass --

local ui = require("openmw.ui")
local util = require("openmw.util")
local self = require("openmw.self")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local input = require("openmw.input")

-- =====================
-- CONFIG
-- =====================
local SCALE = 0.4 -- your chosen scale

-- Base (unscaled) sizes from the original mod
local BASE_COMPASS_WIDTH, BASE_COMPASS_HEIGHT = 420, 28
local TEXTURE_WIDTH_PX = 2048 -- compass.png represents 360 degrees across this width
local BASE_OVERLAY_WIDTH, BASE_OVERLAY_HEIGHT = 520, 66

-- Scaled draw sizes
local COMPASS_WIDTH  = math.floor(BASE_COMPASS_WIDTH  * SCALE + 0.5)
local COMPASS_HEIGHT = math.floor(BASE_COMPASS_HEIGHT * SCALE + 0.5)
local OVERLAY_WIDTH  = math.floor(BASE_OVERLAY_WIDTH  * SCALE + 0.5)
local OVERLAY_HEIGHT = math.floor(BASE_OVERLAY_HEIGHT * SCALE + 0.5)

-- The compass strip is drawn scaled; offsets must use the drawn width (not the source pixel width)
local STRIP_DRAW_WIDTH = math.floor(TEXTURE_WIDTH_PX * SCALE + 0.5)

local LETTER_COLOR = util.color.rgb(1, 1, 1)
local FRAME_COLOR  = util.color.rgb(0.6117, 0.5412, 0.3882)

-- =====================
-- STATE
-- =====================
local settings = storage.playerSection("Settings_MyCompass_HUD")

-- F11 HUD toggle support
local hudVisible = true

local function syncHudVisibleFromEngine()
    if I and I.UI and I.UI.isHudVisible then
        hudVisible = I.UI.isHudVisible()
    end
end

local function onToggleHud()
    -- If the engine exposes a real HUD-visible flag, use it.
    if I and I.UI and I.UI.isHudVisible then
        hudVisible = I.UI.isHudVisible()
    else
        -- Fallback: just toggle locally
        hudVisible = not hudVisible
    end
end

-- Try to hook both APIs (different OpenMW builds expose different names)
pcall(function()
    if input.registerActionHandler then
        input.registerActionHandler("ToggleHUD", onToggleHud)
    end
end)

pcall(function()
    if input.registerTriggerHandler then
        input.registerTriggerHandler("ToggleHUD", onToggleHud)
    end
end)

-- =====================
-- UI CREATION
-- =====================
local root = ui.create {
    layer = "HUD",
    type = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1), mouseTransparent = true },
    content = ui.content {}
}

local mainContainer = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT),

        -- Your placement
        relativePosition = util.vector2(0.064, 0.0),
        anchor = util.vector2(0.0, -0.25),
        position = util.vector2(0, 0),

        visible = true,
        mouseTransparent = true,
    },
    content = ui.content {}
}

-- 1) Background
mainContainer.layout.content:add(ui.create {
    type = ui.TYPE.Image,
    props = {
        mouseTransparent = true,
        resource = ui.texture { path = "textures/Horizontal_Compass/compass_background.png" },
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT)
    }
})

-- 2) Compass viewport (clipped)
local viewport = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size = util.vector2(COMPASS_WIDTH, COMPASS_HEIGHT),
        position = util.vector2((OVERLAY_WIDTH - COMPASS_WIDTH) / 2, (OVERLAY_HEIGHT - COMPASS_HEIGHT) / 2),
        clip = true
    },
    content = ui.content {}
}

local strip = ui.create {
    type = ui.TYPE.Widget,
    props = { size = util.vector2(STRIP_DRAW_WIDTH * 3, COMPASS_HEIGHT) },
    content = ui.content {
        ui.create {
            type = ui.TYPE.Image,
            props = {
        mouseTransparent = true,
                resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                color = LETTER_COLOR,
                size = util.vector2(STRIP_DRAW_WIDTH + (2 * SCALE), COMPASS_HEIGHT),
                position = util.vector2(0, 0)
            }
        },
        ui.create {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                color = LETTER_COLOR,
                size = util.vector2(STRIP_DRAW_WIDTH + (2 * SCALE), COMPASS_HEIGHT),
                position = util.vector2(STRIP_DRAW_WIDTH - (1 * SCALE), 0)
            }
        },
        ui.create {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                color = LETTER_COLOR,
                size = util.vector2(STRIP_DRAW_WIDTH + (2 * SCALE), COMPASS_HEIGHT),
                position = util.vector2((STRIP_DRAW_WIDTH * 2) - (2 * SCALE), 0)
            }
        }
    }
}

viewport.layout.content:add(strip)
mainContainer.layout.content:add(viewport)

-- 3) Frame overlay
mainContainer.layout.content:add(ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = ui.texture { path = "textures/Horizontal_Compass/compass_overlay.png" },
        color = FRAME_COLOR,
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT)
    }
})

root.layout.content:add(mainContainer)

-- =====================
-- UPDATE FUNCTION
-- =====================
local function onFrame()
    local isEnabled = settings:get("enabled")
    if isEnabled == nil then isEnabled = true end

    -- Keep synced if engine supports it
    syncHudVisibleFromEngine()

    local currentMode = I.UI.getMode()
    local shouldShow = isEnabled and hudVisible and (not currentMode)

    if mainContainer.layout.props.visible ~= shouldShow then
        mainContainer.layout.props.visible = shouldShow
        mainContainer:update()
    end

    if not shouldShow then return end

    local yaw = self.rotation:getYaw()
    if not yaw then return end

    -- yaw is radians, 2*pi is full turn
    local t = (yaw / 6.283185) % 1

    -- Offset uses the *drawn* strip width (scaled), otherwise it will look static.
    local xOffset = -(t * STRIP_DRAW_WIDTH) - STRIP_DRAW_WIDTH + (COMPASS_WIDTH * 0.5)

    strip.layout.props.position = util.vector2(xOffset, 0)
    strip:update()
end

return { engineHandlers = { onFrame = onFrame } }
