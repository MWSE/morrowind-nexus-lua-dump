--[[
ErnGlider for OpenMW.
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
local interfaces     = require("openmw.interfaces")
local storage        = require("openmw.storage")
local MOD_NAME       = require("scripts.ErnGlider.ns")
local util           = require('openmw.util')

local mainGroupKey   = "Settings/" .. MOD_NAME
local gliderGroupKey = "Settings/" .. MOD_NAME .. "/glider"
local surfGroupKey   = "Settings/" .. MOD_NAME .. "/surf"

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
                key = "deadzone",
                name = "deadzoneName",
                description = "deadzoneDescription",
                default = 0.1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 1
                }
            },
            {
                key = "volume",
                name = "volumeName",
                description = "volumeDescription",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 5
                }
            },
            {
                key = "shaders",
                name = "shadersName",
                description = "shadersDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "debugMode",
                name = "debugName",
                default = false,
                renderer = "checkbox",
            },
        }
    }

    interfaces.Settings.registerGroup {
        key = gliderGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "gliderSettings",
        description = "gliderDescription",
        permanentStorage = true,
        order = 1,
        settings = {
            {
                key = "enable",
                name = "enableName",
                description = "enableDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "fatigueCost",
                name = "fatigueCostName",
                description = "fatigueCostDescription",
                default = 5,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 100
                }
            },
        }
    }

    interfaces.Settings.registerGroup {
        key = surfGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "surfSettings",
        description = "surfDescription",
        permanentStorage = true,
        order = 2,
        settings = {
            {
                key = "enable",
                name = "enableName",
                description = "enableDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "conditionCost",
                name = "conditionCostName",
                description = "conditionCostDescription",
                default = 2,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 100
                }
            },
            {
                key = "fallCost",
                name = "fallCostName",
                description = "fallCostDescription",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 100
                }
            },
            {
                key = "chimTricky",
                name = "chimTrickyName",
                description = "chimTrickyDescription",
                default = false,
                renderer = "checkbox",
            },
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

local gliderContainer = {
    groupKey = gliderGroupKey,
    section = storage.playerSection(gliderGroupKey)
}
setmetatable(gliderContainer, lookupFuncTable)

local surfContainer = {
    groupKey = surfGroupKey,
    section = storage.playerSection(surfGroupKey)
}
setmetatable(surfContainer, lookupFuncTable)

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
    surf = surfContainer,
    glider = gliderContainer,
    debugPrint = debugPrint,
}
