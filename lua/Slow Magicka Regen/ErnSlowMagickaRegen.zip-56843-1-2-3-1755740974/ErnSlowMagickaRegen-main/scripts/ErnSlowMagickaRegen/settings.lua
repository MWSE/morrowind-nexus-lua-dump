--[[
ErnSlowMagickaRegen for OpenMW.
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

local MOD_NAME = "ErnSlowMagickaRegen"

local settingsStore = storage.globalSection("SettingsGlobal" .. MOD_NAME)

local function debugPrint(str, ...)
    if settingsStore:get("debugMode") then
        local arg = {...}
        if arg ~= nil then
            print(string.format(MOD_NAME .. ": " .. str, unpack(arg)))
        else
            print(MOD_NAME .. ": " .. str)
        end
    end
end

local function initSettings()
    print("init settings start")
    interfaces.Settings.registerGroup {
        key = "SettingsGlobal" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsTitle",
        description = "modSettingsDesc",
        page = MOD_NAME,
        permanentStorage = false,
        settings = {
            {
                key = "scale",
                name = "scale_name",
                description = "scale_description",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 50,
                }
            },
            {
                key = "npcScale",
                name = "npcScale_name",
                description = "npcScale_description",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 50,
                }
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                description = "debugMode_description",
                default = false,
                renderer = "checkbox"
            }
        }
    }
    print("init settings done")
    debugPrint("init settings done")
end

local function scale(actor)
    if actor.type ~= types.Player then
        return settingsStore:get("npcScale")
    else
        return settingsStore:get("scale")
    end
end

local function debugMode()
    return settingsStore:get("debugMode")
end

return {
    initSettings = initSettings,
    settingsStore = settingsStore,
    MOD_NAME = MOD_NAME,
    scale = scale,
    debugPrint = debugPrint,
}
