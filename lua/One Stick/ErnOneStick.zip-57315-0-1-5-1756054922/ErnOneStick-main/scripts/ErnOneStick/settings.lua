--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost

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
local interfaces = require("openmw.interfaces")
local storage = require("openmw.storage")
local MOD_NAME = "ErnOneStick"

local SettingsInput = storage.globalSection("SettingsInput" .. MOD_NAME)
local SettingsAdmin = storage.globalSection("SettingsAdmin" .. MOD_NAME)

local function debugMode()
    return SettingsAdmin:get("debugMode")
end

local function debugPrint(str, ...)
    if debugMode() then
        local arg = { ... }
        if arg ~= nil then
            print(string.format("DEBUG: " .. str, unpack(arg)))
        else
            print("DEBUG: " .. str)
        end
    end
end

local function disable()
    return SettingsAdmin:get("disable")
end

local function registerPage()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }
end

local cameraModes = { "first", "third" }

local function initSettings()
    interfaces.Settings.registerGroup {
        key = "SettingsAdmin" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsAdminTitle",
        description = "modSettingsAdminDesc",
        page = MOD_NAME,
        permanentStorage = true,
        order = 10,
        settings = { {
            key = "disable",
            name = "disable_name",
            description = "disable_description",
            default = false,
            renderer = "checkbox"
        }, {
            key = "debugMode",
            name = "debugMode_name",
            description = "debugMode_description",
            default = false,
            renderer = "checkbox"
        } }
    }

    interfaces.Settings.registerGroup {
        key = "SettingsInput" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsInputTitle",
        description = "modSettingsInputDesc",
        page = MOD_NAME,
        permanentStorage = true,
        settings = { {
            key = "lockButton",
            name = "lockButton_name",
            description = "lockButton_description",
            -- the toggle POV gamepad button is MWInput::A_TogglePOV - SDL_CONTROLLER_BUTTON_RIGHTSTICK - RightStick
            default = "RightStick",
            -- this doesn't actually work
            renderer = "inputBinding",
            argument = {
                key = MOD_NAME .. "LockButton",
                type = "action"
            },
        }, {
            key = "lookSensitivityHorizontal",
            name = "lookSensitivityHorizontal_name",
            default = 3,
            renderer = "number",
            argument = {
                integer = false,
                min = 0.01,
                max = 100
            }
        }, {
            key = "lookSensitivityVertical",
            name = "lookSensitivityVertical_name",
            default = 3,
            renderer = "number",
            argument = {
                integer = false,
                min = 0.01,
                max = 100
            }
        }, {
            key = "invertLookVertical",
            name = "invertLookVertical_name",
            default = false,
            renderer = "checkbox"
        }, {
            key = "freeLookZoom",
            name = "freeLookZoom_name",
            default = 1.2,
            renderer = "number",
            argument = {
                integer = false,
                min = 1,
                max = 10,
            }
        }, {
            key = "volume",
            name = "volume_name",
            default = 1,
            renderer = "number",
            argument = {
                integer = false,
                min = 0,
                max = 1,
            }
        }, {
            key = "dynamicPitch",
            name = "dynamicPitch_name",
            description = "dynamicPitch_description",
            default = true,
            renderer = "checkbox",
        }, {
            key = "autoLockon",
            name = "autoLockon_name",
            description = "autoLockon_description",
            default = true,
            renderer = "checkbox",
        }, {
            key = "travelcam",
            name = "travelcam_name",
            description = "travelcam_description",
            argument = { items = cameraModes, l10n = MOD_NAME },
            default = cameraModes[1],
            renderer = "select",
        }, {
            key = "lockedoncam",
            name = "lockedoncam_name",
            description = "lockedoncam_description",
            argument = { items = cameraModes, l10n = MOD_NAME },
            default = cameraModes[1],
            renderer = "select",
        }, {
            key = "runWhileLockedOn",
            name = "runWhileLockedOn_name",
            description = "runWhileLockedOn_description",
            default = true,
            renderer = "checkbox",
        }, {
            key = "runMinimumFatigue",
            name = "runMinimumFatigue_name",
            description = "runMinimumFatigue_description",
            default = 0,
            renderer = "number",
            argument = {
                integer = true,
                min = 0,
                max = 100
            }
        } }
    }

    print("init settings")
end

local function onNewGame()
    -- this works, but we've already read the value and set the camera.
    SettingsInput:set("travelcam", cameraModes[1])
    SettingsInput:set("lockedoncam", cameraModes[1])
end

local lookupFuncTable = {
    __index = function(table, key)
        local inputSetting = SettingsInput:get(key)
        if inputSetting ~= nil then
            return inputSetting
        end

        local adminSetting = SettingsAdmin:get(key)
        if adminSetting ~= nil then
            return adminSetting
        end

        error("no field '" .. key .. "' in settings")
    end,
}

local settingsContainer = {
    initSettings = initSettings,
    MOD_NAME = MOD_NAME,

    registerPage = registerPage,

    debugMode = debugMode,
    debugPrint = debugPrint,
    disable = disable,

    SettingsInput = SettingsInput,
    onNewGame = onNewGame,
}
setmetatable(settingsContainer, lookupFuncTable)

return settingsContainer
