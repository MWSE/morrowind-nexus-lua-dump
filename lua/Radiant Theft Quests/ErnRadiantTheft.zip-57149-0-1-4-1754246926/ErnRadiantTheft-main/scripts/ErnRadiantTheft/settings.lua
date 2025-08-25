--[[
ErnRadiantTheft for OpenMW.
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
local types = require("openmw.types")
local async = require('openmw.async')

local MOD_NAME = "ErnRadiantTheft"

local SettingsGameplay = storage.globalSection("SettingsGameplay" .. MOD_NAME)

local function debugMode()
    return SettingsGameplay:get("debugMode")
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

local function maxDistance()
    return SettingsGameplay:get("maxDistance")
end

local function registerPage()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }
end

local function initSettings()
    interfaces.Settings.registerGroup {
        key = "SettingsGameplay" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsGameplayTitle",
        description = "modSettingsGameplayDesc",
        page = MOD_NAME,
        permanentStorage = false,
        settings = { {
            key = "maxDistance",
            name = "maxDistance_name",
            description = "maxDistance_description",
            default = 20,
            renderer = "number",
            argument = {
                integer = false,
                min = 3,
                max = 1000
            }
        }, {
            key = "resetData",
            name = "resetData_name",
            description = "resetData_description",
            default = false,
            renderer = "checkbox",
            trueLabel = "reset",
            falseLabel = "reset",
        }, {
            key = "debugMode",
            name = "debugMode_name",
            description = "debugMode_description",
            default = false,
            renderer = "checkbox"
        } }
    }

    print("init settings")
end

local function onReset(fn)
    SettingsGameplay:subscribe(async:callback(function(section, key)
        if key == "resetData" then
            fn()
        end
    end))
end

return {
    initSettings = initSettings,
    MOD_NAME = MOD_NAME,

    registerPage = registerPage,

    maxDistance = maxDistance,
    onReset = onReset,

    debugMode = debugMode,
    debugPrint = debugPrint
}
