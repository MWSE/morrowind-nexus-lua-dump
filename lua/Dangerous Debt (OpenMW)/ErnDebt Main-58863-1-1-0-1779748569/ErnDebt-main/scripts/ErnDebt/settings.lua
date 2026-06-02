--[[
ErnDebt for OpenMW.
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
local MOD_NAME     = require("scripts.ErnDebt.ns")
local util         = require('openmw.util')
local async        = require("openmw.async")

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
        name = "settings",
        permanentStorage = true,
        settings = {
            {
                key = "startDebt",
                name = "startDebtName",
                description = "startDebtDescription",
                default = 50000,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                }
            },
            {
                key = "interest",
                name = "interestName",
                description = "interestDescription",
                default = 0.01,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 10,
                }
            },
            {
                key = "debug",
                name = "debugName",
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
        -- fall through to cached settings section
        local val = table.cached[key]
        if val ~= nil then
            return val
        else
            --print("cached settings: " .. aux_util.deepToString(table.cached, 3))
            --print("current settings: " .. aux_util.deepToString(table.section:asTable(), 3))
            error("unknown setting: " .. tostring(table.groupKey) .. " - " .. tostring(key))
            return nil
        end
    end,
}

---@param groupKeyParam string
---@return table
local function newContainer(groupKeyParam)
    local container = {
        groupKey = groupKeyParam,
        section = storage.playerSection(groupKeyParam),
        cached = {}
    }
    container.cached = container.section:asTable()

    setmetatable(container, lookupFuncTable)

    container.subscribe(async:callback(function(_, key)
        container.cached[key] = container.section:get(key)
    end))

    return container
end

local mainContainer = newContainer(mainGroupKey)

local function debugPrint(str, ...)
    if mainContainer.debug then
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
    debugPrint = debugPrint
}
