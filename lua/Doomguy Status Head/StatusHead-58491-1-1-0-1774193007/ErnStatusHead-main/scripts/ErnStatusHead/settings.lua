--[[
ErnStatusHead for OpenMW.
Copyright (C) 2026 Erin Pentecost

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
local interfaces   = require("openmw.interfaces")
local storage      = require("openmw.storage")
local MOD_NAME     = require("scripts.ErnStatusHead.ns")

local mainGroupKey = "Settings/" .. MOD_NAME

local function init()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description",
    }

    interfaces.Settings.registerGroup {
        key = mainGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "mainSettings",
        permanentStorage = true,
        order = 10,
        settings = {
            {
                key = "fatigueWarning",
                name = "fatigueWarningName",
                default = 0.5,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 1
                }
            },
            {
                key = "positionX",
                name = "positionXName",
                default = 0.5,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 1
                }
            },
            {
                key = "positionY",
                name = "positionYName",
                default = 0.9,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 1
                }
            },
            {
                key = "scale",
                name = "scaleName",
                default = 2,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 10
                }
            },
            {
                key = "lock",
                name = "lockName",
                description = "lockDescription",
                renderer = "checkbox",
                default = false,
            }
        }
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

local mainContainer = {
    groupKey = mainGroupKey,
    section = storage.playerSection(mainGroupKey)
}
setmetatable(mainContainer, lookupFuncTable)

local function debugPrint(str, ...)
    if mainContainer.debugMode then
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
---@field init fun()
---@field main SettingContainer

---@type Settings
return {
    init = init,
    main = mainContainer,
    debugPrint = debugPrint,
}
