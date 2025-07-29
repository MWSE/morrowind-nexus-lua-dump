--[[
ErnBurglary for OpenMW.
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
]] local interfaces = require("openmw.interfaces")
local storage = require("openmw.storage")
local types = require("openmw.types")

local MOD_NAME = "ErnBurglary"

local SettingsGameplay = storage.globalSection("SettingsGameplay" .. MOD_NAME)
local SettingsUI = storage.globalSection("SettingsUI" .. MOD_NAME)

local function debugMode()
    return SettingsUI:get("debugMode")
end

local function revertBounties()
    return SettingsGameplay:get("revertBounties")
end

local function quietMode()
    return SettingsUI:get("quietMode")
end

local function bountyScale()
    return SettingsGameplay:get("bountyScale")
end

local function trespassFine()
    return SettingsGameplay:get("trespassFine")
end

local function lenientFactions()
    return SettingsGameplay:get("lenientFactions")
end

local iconOptions = {"sneaking", "never", "always"}

local function icon()
    return {
        ["showIcon"] = SettingsUI:get("showIcon"),
        ["iconOffsetX"] = SettingsUI:get("iconOffsetX"),
        ["iconOffsetY"] = SettingsUI:get("iconOffsetY"),
        ["iconSize"] = SettingsUI:get("iconSize")
    }
end

local function debugPrint(str, ...)
    if debugMode() then
        local arg = {...}
        if arg ~= nil then
            print(string.format("DEBUG: " .. str, unpack(arg)))
        else
            print("DEBUG: " .. str)
        end
    end
end

local function registerPage()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }
end

local function onUISettingsChange(fn)
    local async = require("openmw.async")
    local ui = require('openmw.ui')

    local group = storage.globalSection("SettingsUI" .. MOD_NAME)
    group:subscribe(async:callback(function(_, key)
        debugPrint("Reloading UI...")
        fn()
        ui.updateAll()
    end))
end

local function initSettings()
    interfaces.Settings.registerGroup {
        key = "SettingsGameplay" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsGameplayTitle",
        description = "modSettingsGameplayDesc",
        page = MOD_NAME,
        permanentStorage = false,
        settings = {{
            key = "bountyScale",
            name = "bountyScale_name",
            description = "bountyScale_description",
            default = 1,
            renderer = "number",
            argument = {
                integer = false,
                min = 0,
                max = 100
            }
        }, {
            key = "trespassFine",
            name = "trespassFine_name",
            description = "trespassFine_description",
            default = 0,
            renderer = "number",
            argument = {
                integer = true,
                min = 0,
                max = 1000
            }
        }, {
            key = "revertBounties",
            name = "revertBounties_name",
            description = "revertBounties_description",
            default = true,
            renderer = "checkbox"
        }, {
            key = "lenientFactions",
            name = "lenientFactions_name",
            description = "lenientFactions_description",
            default = true,
            renderer = "checkbox"
        }}
    }

    interfaces.Settings.registerGroup {
        key = "SettingsUI" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsUITitle",
        description = "modSettingsUIDesc",
        page = MOD_NAME,
        permanentStorage = false,
        settings = {{
            key = "quietMode",
            name = "quietMode_name",
            description = "quietMode_description",
            default = true,
            renderer = "checkbox"
        }, {
            key = "showIcon",
            name = "showIcon_name",
            description = "showIcon_description",
            argument = {items = iconOptions, l10n = MOD_NAME},
            default = iconOptions[1],
            renderer = "select",
            --default = true,
            --renderer = "checkbox"
        }, {
            key = "iconOffsetX",
            name = "iconOffsetX_name",
            default = 0,
            renderer = "number",
            argument = {
                integer = true,
                min = -50000,
                max = 50000
            }
        }, {
            key = "iconOffsetY",
            name = "iconOffsetY_name",
            default = 0,
            renderer = "number",
            argument = {
                integer = true,
                min = -50000,
                max = 50000
            }
        }, {
            key = "iconSize",
            name = "iconSize_name",
            default = 32,
            renderer = "number",
            argument = {
                integer = true,
                min = 8,
                max = 256
            }
        }, {
            key = "debugMode",
            name = "debugMode_name",
            description = "debugMode_description",
            default = false,
            renderer = "checkbox"
        }}
    }

    print("init settings")
end

local function onNewGame()
    SettingsGameplay:set("trespassFine", 10)
end

return {
    initSettings = initSettings,
    MOD_NAME = MOD_NAME,

    registerPage = registerPage,
    onUISettingsChange = onUISettingsChange,
    onNewGame = onNewGame,

    revertBounties = revertBounties,
    bountyScale = bountyScale,
    trespassFine = trespassFine,
    lenientFactions = lenientFactions,

    quietMode = quietMode,
    icon=icon,
    debugMode = debugMode,
    debugPrint = debugPrint
}
