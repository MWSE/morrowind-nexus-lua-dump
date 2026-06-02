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
]]
local interfaces = require("openmw.interfaces")
local storage = require("openmw.storage")
local MOD_NAME = require("scripts.ErnBurglary.ns")

local mainGroupKey = "SettingsGameplay" .. MOD_NAME
local uiGroupKey = "SettingsUI" .. MOD_NAME

local iconOptions = { "sneaking", "never", "always" }

local function initGlobal()
    interfaces.Settings.registerGroup {
        key = mainGroupKey,
        l10n = MOD_NAME,
        name = "modSettingsGameplayTitle",
        description = "modSettingsGameplayDesc",
        page = MOD_NAME,
        permanentStorage = true,
        settings = { {
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
            default = 10,
            renderer = "number",
            argument = {
                integer = true,
                min = 0,
                max = 1000
            }
        }, {
            key = "sneakXPScale",
            name = "sneakXPScale_name",
            description = "sneakXPScale_description",
            default = 0.1,
            renderer = "number",
            argument = {
                integer = false,
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
        }, {
            key = "disableDetection",
            name = "disableDetection_name",
            description = "disableDetection_description",
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
end

local function initPlayer()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }
    interfaces.Settings.registerGroup {
        key = uiGroupKey,
        l10n = MOD_NAME,
        name = "modSettingsUITitle",
        description = "modSettingsUIDesc",
        page = MOD_NAME,
        permanentStorage = true,
        settings = { {
            key = "drain",
            name = "drain_name",
            description = "drain_description",
            default = true,
            renderer = "checkbox"
        }, {
            key = "quietMode",
            name = "quietMode_name",
            description = "quietMode_description",
            default = true,
            renderer = "checkbox"
        }, {
            key = "lockIcon",
            name = "lockIcon_name",
            description = "lockIcon_description",
            default = true,
            renderer = "checkbox"
        }, {
            key = "showIcon",
            name = "showIcon_name",
            description = "showIcon_description",
            argument = { items = iconOptions, l10n = MOD_NAME },
            default = iconOptions[1],
            renderer = "select",
        }, {
            key = "iconX",
            name = "iconX_name",
            default = 0.1314,
            renderer = "number",
            argument = {
                integer = false,
                min = 0,
                max = 1
            }
        }, {
            key = "iconY",
            name = "iconY_name",
            default = 0.9624,
            renderer = "number",
            argument = {
                integer = false,
                min = 0,
                max = 1
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
        } }
    }
end

local lookupFuncTable = {
    __index = function(table, key)
        if key == "subscribe" then
            return function(callback)
                print("Subscribed to " .. tostring(table.groupKey) .. ".")
                return table.section.subscribe(table.section, callback)
            end
        elseif key == "section" then
            return table.section
        elseif key == "groupKey" then
            return table.groupKey
        end
        -- fall through to settings section
        local val = table.section:get(key)
        if val ~= nil then
            return val
        else
            error("unknown setting " .. tostring(key))
        end
    end,
}

local mainContainer = nil

local function mainContainerCtor()
    if mainContainer then
        return mainContainer
    end
    mainContainer = {
        groupKey = mainGroupKey,
        section = storage.globalSection(mainGroupKey)
    }
    setmetatable(mainContainer, lookupFuncTable)
    return mainContainer
end

local uiContainer = nil
local function uiContainerCtor()
    if uiContainer then
        return uiContainer
    end
    uiContainer = {
        groupKey = uiGroupKey,
        section = storage.playerSection(uiGroupKey)
    }
    setmetatable(uiContainer, lookupFuncTable)
    return uiContainer
end

local function debugPrint(str, ...)
    if mainContainerCtor().debugMode then
        local arg = { ... }
        if arg ~= nil then
            print(string.format("DEBUG: " .. str, unpack(arg)))
        else
            print("DEBUG: " .. str)
        end
    end
end

---@alias SettingContainer table

---@class Settings
---@field initGlobal fun()
---@field main fun(): SettingContainer
---@field ui fun(): SettingContainer

---@type Settings
return {
    initGlobal = initGlobal,
    initPlayer = initPlayer,
    main = mainContainerCtor,
    ui = uiContainerCtor,
    debugPrint = debugPrint,
}
