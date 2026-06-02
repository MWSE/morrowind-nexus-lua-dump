--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost and hyacinth

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local camera  = require('openmw.camera')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')
local ui      = require('openmw.ui')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local input   = require('openmw.input')
local self_   = require('openmw.self')
local core    = require('openmw.core')
local types   = require('openmw.types')

local v2 = util.vector2

local MODNAME = "compassHud"

local north = util.vector3(0, 1, 0)
local west  = util.vector3(1, 0, 0)

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

local settingsSection = storage.playerSection('Settings' .. MODNAME)

local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    if not result then
        return util.color.rgb(1, 1, 1)
    end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local layerId      = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size

local settingTemplate = {
    key = 'Settings' .. MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "",
    permanentStorage = true,
    settings = {
        {
            key      = "HUD_LOCK",
            name     = "Lock Position",
            description = "",
            renderer = "checkbox",
            default  = false,
        },
        {
            key      = "HUD_X_POS",
            name     = "X Position",
            description = "",
            renderer = "number",
            integer  = true,
            default  = 12,
        },
        {
            key      = "HUD_Y_POS",
            name     = "Y Position",
            description = "",
            renderer = "number",
            integer  = true,
            default  = math.floor(hudLayerSize.y - 105),
        },
        {
            key      = "HUD_DISPLAY",
            name     = "HUD Display",
            description = "When to display the HUD/widget element. Interface = when menus are pulled up",
            default  = "Always",
            renderer = "select",
            argument = {
                disabled = false,
                l10n     = "none",
                items    = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
            },
        },
        {
            key      = "FONT_SIZE",
            name     = "Font Size",
            description = "Increase or decrease font size.\nDefault is 23",
            renderer = "number",
            default  = 23,
            argument = { min = 5, max = 100000 },
        },
        {
            key      = "TEXT_COLOR",
            name     = "Text Color",
            description = "Change the color of the text.\nDefaults are typically: caa560 ; dfc99f\nBlue: 81CDED",
            disabled = false,
            renderer = "color",
            default  = getColorFromGameSettings("FontColor_color_normal"),
        },
        {
            key      = "BACKGROUND_ALPHA",
            name     = "Background Opacity",
            description = "Increase or decrease background opacity.\n0-1, default is 0.5",
            renderer = "number",
            default  = 0.5,
            argument = { min = 0, max = 1 },
        },
    }
}

I.Settings.registerPage {
    key         = MODNAME,
    l10n        = "none",
    name        = "Ern Compass",
    description = "Displays the text for the compass/minimap.\n" ..
                  "- Hover and click + mousewheel to change size.\n" ..
                  "- Click and drag to move the position.\n" ..
                  "- Click and Shift+mousewheel to change bg opacity while in-game."
}

I.Settings.registerGroup(settingTemplate)

-- Current settings values, refreshed whenever a setting changes.
local settings = {}

local function readAllSettings()
    for _, entry in ipairs(settingTemplate.settings) do
        settings[entry.key] = settingsSection:get(entry.key)
    end
end

readAllSettings()

-- ---------------------------------------------------------------------------
-- UI state
-- ---------------------------------------------------------------------------

local compassHud        = nil
local compassText       = nil
local compassHudBackground = nil

local saveData               = {}
local currentUiMode          = nil
local shouldRefreshUiVisibility = nil

-- Forward declarations
local refreshUiVisibility

-- ---------------------------------------------------------------------------
-- Facing helpers
-- ---------------------------------------------------------------------------

local function getFacing()
    local facing = camera.viewportToWorldVector(v2(0.5, 0.5)):normalize()
    -- dot product: 0 = 90°, 1 = codirectional, -1 = opposite
    return {
        northSouth = facing:dot(north),
        eastWest   = facing:dot(west),
    }
end

local function facingAs16wind(facing)
    -- atan2(y, x): 0 at east, π/2 at north.
    local angle = math.atan2(facing.northSouth, facing.eastWest)
    local deg   = math.deg(angle)
    if deg < 0 then deg = deg + 360 end

    -- 16-wind labels, one every 22.5°, starting at East.
    local directions = {
        "E", "ENE", "NE", "NNE",
        "N", "NNW", "NW", "WNW",
        "W", "WSW", "SW", "SSW",
        "S", "SSE", "SE", "ESE",
    }
    -- Offset by half a sector so 0° centres on "E".
    local index = math.floor((deg + 11.25) / 22.5) % 16 + 1
    return directions[index]
end

-- ---------------------------------------------------------------------------
-- Compass update
-- ---------------------------------------------------------------------------

local function updateCompass()
    if not compassText then return end
    if not compassHud then return end

    local facing   = facingAs16wind(getFacing())
    local textNode = compassHud.layout.content.compassFlex.content.compassText
    if textNode.props.text ~= facing then
        textNode.props.text = facing
        compassHud:update()
    end

    refreshUiVisibility()
end

-- ---------------------------------------------------------------------------
-- HUD creation
-- ---------------------------------------------------------------------------

local function createCompassHud()
    if compassHud then
        compassHud:destroy()
        compassHud         = nil
        compassText        = nil
        compassHudBackground = nil
    end

    local template = { content = ui.content {} }

    compassHudBackground = {
        type  = ui.TYPE.Image,
        name  = "compassHudBackground",
        props = {
            resource     = ui.texture { path = 'black' },
            relativeSize = v2(1, 1),
            alpha        = settings.BACKGROUND_ALPHA,
        }
    }
    template.content:add(compassHudBackground)

    compassHud = ui.create({
        type     = ui.TYPE.Container,
        layer    = settings.HUD_LOCK and 'Scene' or 'Modal',
        name     = "compassHud",
        template = template,
        props    = {
            position = v2(settings.HUD_X_POS, settings.HUD_Y_POS),
            anchor   = v2(0.5, 0.5),
        },
        content  = ui.content {},
        userData = {
            windowStartPosition = v2(settings.HUD_X_POS, settings.HUD_Y_POS),
        }
    })

    compassHud.layout.events = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then
                if not elem.userData then elem.userData = {} end
                elem.userData.isDragging          = true
                elem.userData.dragStartPosition   = data.position
                elem.userData.windowStartPosition = compassHud.layout.props.position or v2(0, 0)
            end
            compassHud:update()
        end),

        mouseRelease = async:callback(function(data, elem)
            if elem.userData then
                elem.userData.isDragging = false
            end
            compassHud:update()
        end),

        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                local delta       = data.position - elem.userData.dragStartPosition
                local newPosition = v2(
                    elem.userData.windowStartPosition.x + delta.x,
                    elem.userData.windowStartPosition.y + delta.y
                )
                settingsSection:set("HUD_X_POS", math.floor(newPosition.x))
                settingsSection:set("HUD_Y_POS", math.floor(newPosition.y))
                compassHud.layout.props.position = newPosition
                compassHud:update()
            end
        end),
    }

    local compassFlex = {
        type  = ui.TYPE.Flex,
        name  = "compassFlex",
        props = {
            horizontal = false,
            autoSize   = true,
            size       = v2(1, 1),
            arrange    = ui.ALIGNMENT.Start,
        },
        content = ui.content {}
    }
    compassHud.layout.content:add(compassFlex)

    compassText = {
        type  = ui.TYPE.Text,
        name  = "compassText",
        props = {
            text            = "---",
            textColor       = settings.TEXT_COLOR,
            textShadow      = true,
            textShadowColor = util.color.rgba(0, 0, 0, 0.9),
            textAlignV      = ui.ALIGNMENT.Start,
            textAlignH      = ui.ALIGNMENT.Start,
            textSize        = settings.FONT_SIZE,
        },
    }
    compassFlex.content:add(compassText)

    updateCompass()
end

-- ---------------------------------------------------------------------------
-- Settings change handler
-- ---------------------------------------------------------------------------

local function onSettingChanged(_, setting)
    readAllSettings()

    if not compassHud then return end

    compassHud.layout.layer           = settings.HUD_LOCK and 'Scene' or 'Modal'
    if compassHudBackground then
    compassHudBackground.props.alpha  = settings.BACKGROUND_ALPHA
    end
    if compassText then
    compassText.props.textSize        = settings.FONT_SIZE
    compassText.props.textColor       = settings.TEXT_COLOR
    end

    if setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
        compassHud.layout.props.position = v2(settings.HUD_X_POS, settings.HUD_Y_POS)
    end

    updateCompass()

    local data = { newMode = I.UI.getMode() }
    if not compassHud then return end
    currentUiMode = data.newMode
    refreshUiVisibility()
    shouldRefreshUiVisibility = 3
end

settingsSection:subscribe(async:callback(onSettingChanged))

-- ---------------------------------------------------------------------------
-- Input handlers
-- ---------------------------------------------------------------------------

local function onMouseWheel(vertical)
    if compassHud and compassHud.layout.userData and compassHud.layout.userData.isDragging then
        if input.isShiftPressed() then
            settingsSection:set("BACKGROUND_ALPHA",
                math.min(1, math.max(0, settings.BACKGROUND_ALPHA + vertical / 10)))
        else
            settingsSection:set("FONT_SIZE", math.max(5, settings.FONT_SIZE + vertical))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Chargen guard
-- ---------------------------------------------------------------------------

local function chargenFinished()
    if saveData.chargenFinished then return true end

    if types.Player.getBirthSign(self_) ~= "" then
        saveData.chargenFinished = true
        return true
    end
    if types.Player.isCharGenFinished(self_) then
        saveData.chargenFinished = true
        return true
    end

    local playerItems = types.Container.inventory(self_):getAll()
    for _, item in pairs(playerItems) do
        if item.recordId == "chargen statssheet" then
            saveData.chargenFinished = true
            return true
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Visibility
-- ---------------------------------------------------------------------------

refreshUiVisibility = function()
    if not compassHud then return end

    local hudVisible = I.UI.isHudVisible() and chargenFinished() and self_.cell.isExterior
    local visible

    if settings.HUD_DISPLAY == "Always" then
        visible = hudVisible
    elseif settings.HUD_DISPLAY == "Never" then
        visible = false
    elseif settings.HUD_DISPLAY == "Interface Only" then
        visible = currentUiMode == "Interface" and hudVisible
    elseif settings.HUD_DISPLAY == "Hide on Interface" then
        visible = currentUiMode == nil and hudVisible
    else -- "Hide on Dialogue Only"
        visible = currentUiMode ~= "Dialogue" and hudVisible
    end

    compassHud.layout.props.visible = visible
    compassHud:update()
end

-- ---------------------------------------------------------------------------
-- Load / save
-- ---------------------------------------------------------------------------

local function onLoad(data)
    saveData = data or {}

    local hudLayer = ui.layers[ui.layers.indexOf("HUD")]

    settingsSection:set("HUD_X_POS",
        math.floor(math.max(0, math.min(settings.HUD_X_POS, hudLayer.size.x - settings.FONT_SIZE * 2))))
    settingsSection:set("HUD_Y_POS",
        math.floor(math.max(0, math.min(settings.HUD_Y_POS, hudLayer.size.y - settings.FONT_SIZE))))

    createCompassHud()
end

local function onSave()
    return saveData
end

-- ---------------------------------------------------------------------------
-- Event / frame handlers
-- ---------------------------------------------------------------------------

input.registerTriggerHandler("ToggleHUD", async:callback(function()
    if compassHud then
    compassHud.layout.props.visible = I.UI.isHudVisible()
    compassHud:update()
    end
end))

local function UiModeChanged(data)
    if not compassHud then return end
    currentUiMode = data.newMode
    refreshUiVisibility()
    shouldRefreshUiVisibility = 3
end

local function onFrame()
    if shouldRefreshUiVisibility then
        shouldRefreshUiVisibility = shouldRefreshUiVisibility - 1
        if shouldRefreshUiVisibility == 0 then
            shouldRefreshUiVisibility = nil
            refreshUiVisibility()
        end
    end
    updateCompass()
end

-- ---------------------------------------------------------------------------

return {
    engineHandlers = {
        onInit       = onLoad,
        onLoad       = onLoad,
        onSave       = onSave,
        onMouseWheel = onMouseWheel,
        onFrame      = onFrame,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
