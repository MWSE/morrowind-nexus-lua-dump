--[[
ErnGearRandomizer for OpenMW.
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
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local MOD_NAME = "ErnGearRandomizer"

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
    I.Settings.registerGroup {
        key = "SettingsGlobal" .. MOD_NAME,
        l10n = MOD_NAME,
        name = "modSettingsTitle",
        description = "modSettingsDesc",
        page = MOD_NAME,
        permanentStorage = false,
        settings = {
            {
                key = "chance",
                name = "chance_name",
                description = "chance_description",
                default = 10,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 100
                }
            },
            {
                key = "clothes",
                name = "clothes_name",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "armor",
                name = "armor_name",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "weapons",
                name = "weapons_name",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "enchanted",
                name = "enchanted_name",
                description = "enchanted_description",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "extraRandom",
                name = "extraRandom_name",
                description = "extraRandom_description",
                default = false,
                renderer = "checkbox"
            },
            {
                key = 'itemBan',
                name = 'itemBan_name',
                description = 'itemBan_description',
                default = 'indoril.*,t_nor_.*',
                renderer = 'textLine',
            },
            {
                key = 'classBan',
                name = 'classBan_name',
                description = 'classBan_description',
                default = '',
                renderer = 'textLine',
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

    debugPrint("init settings done")
end


local function chance()
    return settingsStore:get("chance")
end

local function clothes()
    return settingsStore:get("clothes")
end

local function armor()
    return settingsStore:get("armor")
end

local function weapons()
    return settingsStore:get("weapons")
end

local function enchanted()
    return settingsStore:get("enchanted")
end

local function extraRandom()
    return settingsStore:get("extraRandom")
end

local function itemBan()
    return string.gmatch(settingsStore:get("itemBan"), "[^,]+")
end

local function classBan()
    return string.gmatch(settingsStore:get("classBan"), "[^,]+")
end

local function debugMode()
    return settingsStore:get("debugMode")
end

return {
    initSettings = initSettings,
    settingsStore = settingsStore,
    MOD_NAME = MOD_NAME,
    debugPrint = debugPrint,

    chance = chance,
    clothes = clothes,
    armor = armor,
    weapons = weapons,
    enchanted = enchanted,
    extraRandom = extraRandom,
    itemBan = itemBan,
    classBan = classBan,
    debugMode = debugMode,
}
