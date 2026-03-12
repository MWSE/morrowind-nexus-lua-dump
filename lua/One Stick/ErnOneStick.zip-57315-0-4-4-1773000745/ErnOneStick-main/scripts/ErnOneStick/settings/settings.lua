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
local interfaces          = require("openmw.interfaces")
local storage             = require("openmw.storage")
local MOD_NAME            = require("scripts.ErnOneStick.ns")
local aux_util            = require('openmw_aux.util')
local input               = require('openmw.input')
local async               = require("openmw.async")

local minFatigue          = { "0%", "25%", "50%", "75%" }
local cameraModes         = { "first", "third" }

local lockActionName      = MOD_NAME .. "LockAction"
local uniToggleActionName = MOD_NAME .. "ToggleAction"

local function groupKey(groupName)
    return 'Settings/' .. MOD_NAME .. '/' .. groupName
end

local adminGroupKey = groupKey("Admin")
local dpadGroupKey = groupKey("DPAD")
local inputGroupKey = groupKey("Input")

local function init()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description"
    }

    input.registerAction {
        key = lockActionName,
        type = input.ACTION_TYPE.Boolean,
        l10n = MOD_NAME,
        defaultValue = false,
    }

    input.registerAction {
        key = uniToggleActionName,
        type = input.ACTION_TYPE.Boolean,
        l10n = MOD_NAME,
        defaultValue = false,
    }

    interfaces.Settings.registerGroup {
        key = adminGroupKey,
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
        key = dpadGroupKey,
        l10n = MOD_NAME,
        name = "modSettingsDPADTitle",
        description = "modSettingsDPADDesc",
        page = MOD_NAME,
        permanentStorage = true,
        order = 5,
        settings = {
            {
                key = "runWhileLockedOn",
                name = "runWhileLockedOn_name",
                description = "runWhileLockedOn_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "runMinimumFatigue",
                name = "runMinimumFatigue_name",
                description = "runMinimumFatigue_description",
                argument = { items = minFatigue, l10n = MOD_NAME },
                default = minFatigue[1],
                renderer = "select",
            },
            {
                key = "runWhenReadied",
                name = "runWhenReadied_name",
                description = "runWhenReadied_description",
                default = false,
                renderer = "checkbox",
            }
        }
    }

    interfaces.Settings.registerGroup {
        key = inputGroupKey,
        l10n = MOD_NAME,
        name = "modSettingsInputTitle",
        description = "modSettingsInputDesc",
        page = MOD_NAME,
        permanentStorage = true,
        settings = { {
            key = "lockButton",
            name = "lockButton_name",
            description = "lockButton_description",
            default = "None6",
            renderer = "inputBinding",
            argument = {
                key = lockActionName,
                type = "action"
            },
        }, {
            key = "twoStickMode",
            name = "twoStickMode_name",
            description = "twoStickMode_description",
            default = false,
            renderer = "checkbox",
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
            key = "enableShaders",
            name = "enableShaders_name",
            description = "enableShaders_description",
            default = false,
            renderer = "checkbox",
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
            key = "speedUpStanceSwitching",
            name = "speedUpStanceSwitching_name",
            description = "speedUpStanceSwitching_description",
            default = true,
            renderer = "checkbox",
        }, {
            key = "toggleButton",
            name = "toggleButton_name",
            description = "toggleButton_description",
            default = "None7",
            renderer = "inputBinding",
            argument = {
                key = uniToggleActionName,
                type = "action"
            },
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

local adminContainer = newContainer(adminGroupKey)
local dpadContainer = newContainer(dpadGroupKey)
local inputContainer = newContainer(inputGroupKey)


local function debugPrint(str, ...)
    if adminContainer.debugMode then
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
---@field admin SettingContainer
---@field dpad SettingContainer
---@field input SettingContainer

---@type Settings
return {
    init = init,
    admin = adminContainer,
    dpad = dpadContainer,
    input = inputContainer,
    debugPrint = debugPrint,
    lockActionName = lockActionName,
    uniToggleActionName = uniToggleActionName,
}
