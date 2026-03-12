local ui = require("openmw.ui")
local util = require("openmw.util")
local self = require("openmw.self")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local input = require("openmw.input")
local async = require("openmw.async")
local v2 = util.vector2

MODNAME = "HorizontalCompass"

local northMarkers = require('scripts.Horizontal_Compass.HC_northmarkerDB')

-- sizes from the original mod
local BASE_COMPASS_WIDTH, BASE_COMPASS_HEIGHT = 420, 28
local TEXTURE_WIDTH_PX = 2048
local BASE_OVERLAY_WIDTH, BASE_OVERLAY_HEIGHT = 520, 66

local LETTER_COLOR = util.color.rgb(1, 1, 1)
local FRAME_COLOR  = util.color.rgb(0.6117, 0.5412, 0.3882)

require('scripts.horizontal_compass.HC_settings')

compassHud = nil          -- top-level ui element
compassBgImage = nil      -- background image props
compassFrameImage = nil   -- frame overlay props
local strip = nil         -- the scrolling compass strip element
local viewport = nil      -- clipped viewport element
local currentUiMode = nil
local interiorHidden = false  -- true when hidden due to interior cell rules
local compassUserToggled = true  -- toggled via keybind, not persisted

-- register toggle keybind
input.registerAction({
    key = "hcToggleCompass",
    type = input.ACTION_TYPE.Boolean,
    l10n = "none",
    name = "Toggle Horizontal Compass",
    description = "Show/hide the horizontal compass",
    defaultValue = false,
})

input.registerActionHandler('hcToggleCompass', async:callback(function(down)
	if currentUiMode == nil then
		if down then
			compassUserToggled = not compassUserToggled
			refreshCompassVisibility()
		end
	end
end))

-- dimensions
local COMPASS_WIDTH, COMPASS_HEIGHT
local OVERLAY_WIDTH, OVERLAY_HEIGHT
local STRIP_DRAW_WIDTH

local function computeDimensions(scale)
    COMPASS_WIDTH  = math.floor(BASE_COMPASS_WIDTH  * scale + 0.5)
    COMPASS_HEIGHT = math.floor(BASE_COMPASS_HEIGHT * scale + 0.5)
    OVERLAY_WIDTH  = math.floor(BASE_OVERLAY_WIDTH  * scale + 0.5)
    OVERLAY_HEIGHT = math.floor(BASE_OVERLAY_HEIGHT * scale + 0.5)
    STRIP_DRAW_WIDTH = math.floor(TEXTURE_WIDTH_PX * scale + 0.5)
end

-- position
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size

local function clampPosition(pos)
    local minVisible = 20
    return v2(
        math.max(-OVERLAY_WIDTH + minVisible, math.min(pos.x, hudLayerSize.x - minVisible)),
        math.max(-OVERLAY_HEIGHT + minVisible, math.min(pos.y, hudLayerSize.y - minVisible))
    )
end

-- visibility
function refreshCompassVisibility()
    if not compassHud then return end

    local shouldShow = false

    if I.UI.isHudVisible() and compassUserToggled then
        -- interior visibility rules
        local cell = self.cell
        if cell and not cell.isExterior and cell.id then
            local offset = northMarkers[cell.id]
            if SHOW_IN_INTERIORS == "Always" then
                interiorHidden = false
            elseif SHOW_IN_INTERIORS == "If certain" then
                interiorHidden = (offset == nil) and not cell:hasTag("QuasiExterior")
            else -- "Never"
                interiorHidden = not cell:hasTag("QuasiExterior")
            end
        else
            interiorHidden = false
        end

        if interiorHidden then
            shouldShow = false
        elseif HUD_DISPLAY == "Always" then
            shouldShow = true
        elseif HUD_DISPLAY == "Never" then
            shouldShow = false
        elseif HUD_DISPLAY == "Interface Only" then
            shouldShow = currentUiMode ~= nil
        elseif HUD_DISPLAY == "Hide on Interface" then
            shouldShow = currentUiMode == nil
        else -- "Hide on Dialogue Only"
            shouldShow = currentUiMode ~= "Dialogue" and currentUiMode ~= "Barter"
        end
    end

    if compassHud.layout.props.visible ~= shouldShow then
        compassHud.layout.props.visible = shouldShow
        compassHud:update()
    end
end

-- create compass
local function createCompass()
    -- clean up existing
    if compassHud then
        compassHud:destroy()
        compassHud = nil
        strip = nil
        viewport = nil
        compassBgImage = nil
        compassFrameImage = nil
    end

    computeDimensions(COMPASS_SCALE)

    -- background image
    compassBgImage = {
        type = ui.TYPE.Image,
        name = "compassBackground",
        props = {
            resource = ui.texture { path = "textures/Horizontal_Compass/compass_background.png" },
            size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT),
        },
    }

    -- compass strip
    strip = {
        type = ui.TYPE.Widget,
        name = "compassStrip",
        props = { size = v2(STRIP_DRAW_WIDTH * 3, COMPASS_HEIGHT) },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                    color = LETTER_COLOR,
                    size = v2(STRIP_DRAW_WIDTH + (2 * COMPASS_SCALE), COMPASS_HEIGHT),
                    position = v2(0, 0),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                    color = LETTER_COLOR,
                    size = v2(STRIP_DRAW_WIDTH + (2 * COMPASS_SCALE), COMPASS_HEIGHT),
                    position = v2(STRIP_DRAW_WIDTH - (1 * COMPASS_SCALE), 0),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = "textures/Horizontal_Compass/compass.png" },
                    color = LETTER_COLOR,
                    size = v2(STRIP_DRAW_WIDTH + (2 * COMPASS_SCALE), COMPASS_HEIGHT),
                    position = v2((STRIP_DRAW_WIDTH * 2) - (2 * COMPASS_SCALE), 0),
                },
            },
        },
    }

    -- clipped viewport
    viewport = {
        type = ui.TYPE.Widget,
        name = "compassViewport",
        props = {
            size = v2(COMPASS_WIDTH, COMPASS_HEIGHT),
            position = v2(
                (OVERLAY_WIDTH - COMPASS_WIDTH) / 2,
                (OVERLAY_HEIGHT - COMPASS_HEIGHT) / 2
            ),
            clip = true,
        },
        content = ui.content { strip },
    }

    -- frame overlay
    compassFrameImage = {
        type = ui.TYPE.Image,
        name = "compassFrame",
        props = {
            resource = ui.texture { path = "textures/Horizontal_Compass/compass_overlay.png" },
            color = FRAME_COLOR,
            size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT),
        },
    }

    -- clamp saved position
    local pos = clampPosition(v2(HUD_X_POS, HUD_Y_POS))

    -- create the top-level compass element
    compassHud = ui.create({
        type = ui.TYPE.Widget,
		-- modal can receive mouse events for clicking + dragging
		-- scene layer can't receive mouse events which "locks" it
        layer = HUD_LOCK and 'Scene' or 'Modal',
        name = "compassHud",
        props = {
            size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT),
            position = pos,
            visible = true,
        },
        userData = {
            windowStartPosition = pos,
        },
        content = ui.content {
            compassBgImage,
            viewport,
            compassFrameImage,
        },
    })

    -- drag + drop events
    compassHud.layout.events = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then -- left mouse button
                if not elem.userData then
                    elem.userData = {}
                end
                elem.userData.isDragging = true
                elem.userData.dragStartPosition = data.position
                elem.userData.windowStartPosition = compassHud.layout.props.position or v2(0, 0)
            end
            compassHud:update()
        end),

        mouseRelease = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                elem.userData.isDragging = false
            end
            compassHud:update()
        end),

        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                local deltaX = data.position.x - elem.userData.dragStartPosition.x
                local deltaY = data.position.y - elem.userData.dragStartPosition.y
                local newPosition = clampPosition(v2(
                    elem.userData.windowStartPosition.x + deltaX,
                    elem.userData.windowStartPosition.y + deltaY
                ))
                compassUiSection:set("HUD_X_POS", math.floor(newPosition.x))
                compassUiSection:set("HUD_Y_POS", math.floor(newPosition.y))
                compassHud.layout.props.position = newPosition
                compassHud:update()
            end
        end),
    }

    refreshCompassVisibility()
end

function rebuildCompass()
    createCompass()
end

function updateCompassScale()
    if not compassHud then return end

    computeDimensions(COMPASS_SCALE)

    -- top-level size
    compassHud.layout.props.size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT)

    -- background
    compassBgImage.props.size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT)

    -- frame overlay
    compassFrameImage.props.size = v2(OVERLAY_WIDTH, OVERLAY_HEIGHT)

    -- viewport size + centered position
    viewport.props.size = v2(COMPASS_WIDTH, COMPASS_HEIGHT)
    viewport.props.position = v2(
        (OVERLAY_WIDTH - COMPASS_WIDTH) / 2,
        (OVERLAY_HEIGHT - COMPASS_HEIGHT) / 2
    )

    -- strip container
    strip.props.size = v2(STRIP_DRAW_WIDTH * 3, COMPASS_HEIGHT)

    -- the 3 tiled strip images
    local imgs = strip.content
    local tileW = STRIP_DRAW_WIDTH + (2 * COMPASS_SCALE)
    imgs[1].props.size = v2(tileW, COMPASS_HEIGHT)
    imgs[1].props.position = v2(0, 0)
    imgs[2].props.size = v2(tileW, COMPASS_HEIGHT)
    imgs[2].props.position = v2(STRIP_DRAW_WIDTH - (1 * COMPASS_SCALE), 0)
    imgs[3].props.size = v2(tileW, COMPASS_HEIGHT)
    imgs[3].props.position = v2((STRIP_DRAW_WIDTH * 2) - (2 * COMPASS_SCALE), 0)

    compassHud:update()
end

local mouseWheelRegisteredByUs = false
if not input.triggers["MenuMouseWheelUp"] then
    input.registerTrigger({
        key = "MenuMouseWheelUp",
        l10n = "none",
        name = "MenuMouseWheelUp",
        description = "",
    })
    input.registerTrigger({
        key = "MenuMouseWheelDown",
        l10n = "none",
        name = "MenuMouseWheelDown",
        description = "",
    })
    mouseWheelRegisteredByUs = true
end

local function onMouseWheel(direction)
    if mouseWheelRegisteredByUs then
        if direction > 0 then
            input.activateTrigger("MenuMouseWheelUp")
        else
            input.activateTrigger("MenuMouseWheelDown")
        end
    end
end

-- mousewheel handlers for scale adjustment while dragging
if input.triggers and input.triggers["MenuMouseWheelUp"] then
    input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
        if compassHud and compassHud.layout.userData and compassHud.layout.userData.isDragging then
            local newScale = math.min(2.0, COMPASS_SCALE + 0.01)
            newScale = math.floor(newScale * 100 + 0.1) / 100 -- round to 2 decimals
            compassUiSection:set("COMPASS_SCALE", newScale)
        end
    end))
end

if input.triggers and input.triggers["MenuMouseWheelDown"] then
    input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
        if compassHud and compassHud.layout.userData and compassHud.layout.userData.isDragging then
            local newScale = math.max(0.1, COMPASS_SCALE - 0.01)
            newScale = math.floor(newScale * 100 + 0.1) / 100
            compassUiSection:set("COMPASS_SCALE", newScale)
        end
    end))
end

-- f11 and keybind visibility
pcall(function()
    if input.registerTriggerHandler then
        input.registerTriggerHandler("ToggleHUD", async:callback(function()
            if compassHud then
                refreshCompassVisibility()
            end
        end))
    end
end)

pcall(function()
    if input.registerActionHandler then
        input.registerActionHandler("ToggleHUD", function()
            if compassHud then
                refreshCompassVisibility()
            end
        end)
    end
end)

-- update compass rotation
local shouldRefreshVisibility = nil
local frameCounter = 0

local function onFrame()
    frameCounter = frameCounter + 1

    -- visibility refresh
    if shouldRefreshVisibility then
        shouldRefreshVisibility = shouldRefreshVisibility - 1
        if shouldRefreshVisibility == 0 then
            shouldRefreshVisibility = nil
            refreshCompassVisibility()
        end
    elseif frameCounter >= 10 then
        -- refresh to detect cell changes
        frameCounter = 0
        refreshCompassVisibility()
    end

    if not compassHud then return end
    if not compassHud.layout.props.visible then return end

    local yaw = self.rotation:getYaw()
    if not yaw then return end

    -- apply north marker for interior cells
    local cell = self.cell
    if cell and not cell.isExterior and cell.id then
        local offset = northMarkers[cell.id]
        if SHOW_IN_INTERIORS == "Always" then
            offset = offset or 0
        end
        if offset then
            yaw = yaw - offset
        end
    end

    -- yaw is radians, 2*pi = full turn
    local t = (yaw / 6.283185) % 1
    local xOffset = -(t * STRIP_DRAW_WIDTH) - STRIP_DRAW_WIDTH + (COMPASS_WIDTH * 0.5)

    strip.props.position = v2(xOffset, 0)
    compassHud:update()
end

local function UiModeChanged(data)
    if not compassHud then return end
    currentUiMode = data.newMode
    refreshCompassVisibility()
    shouldRefreshVisibility = 3
end

local function onLoad(data)
    computeDimensions(COMPASS_SCALE)

    -- clamp position to screen bounds on load
    local pos = clampPosition(v2(HUD_X_POS, HUD_Y_POS))
    if math.floor(pos.x) ~= HUD_X_POS or math.floor(pos.y) ~= HUD_Y_POS then
        compassUiSection:set("HUD_X_POS", math.floor(pos.x))
        compassUiSection:set("HUD_Y_POS", math.floor(pos.y))
    end

    createCompass()
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    },
}

-- Ui Layers
-- 1    UiLayer(Scene)
-- 2    UiLayer(FadeToBlack)
-- 3    UiLayer(HitOverlay)
-- 4    UiLayer(HUD)
-- 5    UiLayer(JournalBooks)
-- 6    UiLayer(Windows)
-- 7    UiLayer(DragAndDrop)
-- 8    UiLayer(DrowningBar)
-- 9    UiLayer(MainMenuBackground)
-- 10    UiLayer(MainMenu)
-- 11    UiLayer(Settings)
-- 12    UiLayer(ControllerButtons)
-- 13    UiLayer(LoadingScreenBackground)
-- 14    UiLayer(LoadingScreen)
-- 15    UiLayer(Debug)
-- 16    UiLayer(Console)
-- 17    UiLayer(Modal)
-- 18    UiLayer(Popup)
-- 19    UiLayer(Notification)
-- 20    UiLayer(Video)
-- 21    UiLayer(InputBlocker)
-- 22    UiLayer(Pointer)

-- List of UI modes
-- Recharge
-- Training
-- Rest
-- LevelUp
-- Repair
-- ChargenRace
-- ChargenBirth
-- ChargenClass
-- ChargenClassGenerate
-- Scroll
-- ChargenClassCreate
-- Book
-- QuickKeysMenu
-- Interface
-- Journal
-- Jail
-- LoadingWallpaper
-- Loading
-- ChargenClassReview
-- Container
-- ChargenClassPick
-- ChargenName
-- MerchantRepair
-- Companion
-- MainMenu
-- Alchemy
-- Dialogue
-- Barter
-- SpellBuying
-- Travel
-- SpellCreation
-- Enchanting