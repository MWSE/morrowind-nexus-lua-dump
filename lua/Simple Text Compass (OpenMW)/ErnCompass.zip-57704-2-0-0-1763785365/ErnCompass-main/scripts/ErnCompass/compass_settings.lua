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

local I = require('openmw.interfaces')
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size
local screenres = ui.screenSize()
local uiScale = screenres.x / hudLayerSize.x

MODNAME = "compassHud"

local settingTemplate = {
    key = 'Settings' .. MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "HUD_LOCK",
            name = "Lock Position",
            description = "",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "HUD_X_POS",
            name = "X Position",
            description = "",
            renderer = "number",
            integer = true,
            default = 12,
        },
        {
            key = "HUD_Y_POS",
            name = "Y Position",
            description = "",
            renderer = "number",
            integer = true,
            default = math.floor(hudLayerSize.y - (105)),
        },
        {
            key = "HUD_DISPLAY",
            name = "HUD Display",
            description = "When to display the HUD/widget element. Interface = when menus are pulled up",
            default = "Always",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "none",
                items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
            },
        },
        {
            key = "FONT_SIZE",
            name = "Font Size",
            description = "Increase or decrease font size.\nDefault is 23",
            renderer = "number",
            default = 23,
            argument = {
                min = 5,
                max = 100000,
            },
        },
        {
            key = "TEXT_COLOR",
            name = "Text Color",
            description = "Change the color of the text.\nDefaults are typically: caa560 ; dfc99f\nBlue: 81CDED (blue)",
            disabled = false,
            renderer = "color",
            default = getColorFromGameSettings("FontColor_color_normal"),
        },
        {
            key = "BACKGROUND_ALPHA",
            name = "Background Opacity",
            description = "Increase or decrease background opacity.\n0-1, default is 0.5",
            renderer = "number",
            default = 0.5,
            argument = {
                min = 0,
                max = 1,
            },
        },
    }
}

I.Settings.registerGroup(settingTemplate)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = "Ern Compass",
    description = "Displays the text for the compass/minimap.\n- Hover and click + mousewheel to change size.\n- Click and drag to move the position.\n- Click and Shift+mousewheel to change bg opacity while in-game."
}

function readAllSettings()
    --print("caching settings")
    for i, entry in pairs(settingTemplate.settings) do
        --print(entry.key.." = "..tostring(settingsSection:get(entry.key)))
        _G[entry.key] = settingsSection:get(entry.key)
    end
end

readAllSettings()

local updateSettings = function(_, setting)
    --print(setting.." changed to "..settingsSection:get(setting))
    readAllSettings()

    if compassHud then
        compassHud.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
        compassHudBackground.props.alpha = BACKGROUND_ALPHA
        compassText.props.textSize = FONT_SIZE
        compassText.props.textColor = TEXT_COLOR

        if setting == "HUD_X_POS" or setting == "HUD_Y_POS" then
            compassHud.layout.props.position = v2(HUD_X_POS, HUD_Y_POS)
        end

        if updateCompassDisplay then
            updateCompassDisplay(true)
        end

        if UiModeChanged then
            data = {
                newMode = I.UI.getMode(),
            }
            UiModeChanged(data)
        end
    end
end

settingsSection:subscribe(async:callback(updateSettings))
