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
local MOD_NAME = require("scripts.ErnOneStick.ns")
local interfaces = require("openmw.interfaces")

local minFatigue = { "0%", "25%", "50%", "75%" }
local cameraModes = { "first", "third" }

local function groupKey(groupName)
    return 'SettingsGlobal' .. MOD_NAME .. groupName
end

interfaces.Settings.registerGroup {
    key = groupKey("Admin"),
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
    }, {
        key = "firstRun",
        name = "firstRun_name",
        default = true,
        renderer = "checkbox",
    } }
}

interfaces.Settings.registerGroup {
    key = groupKey("DPAD"),
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
    key = groupKey("Input"),
    l10n = MOD_NAME,
    name = "modSettingsInputTitle",
    description = "modSettingsInputDesc",
    page = MOD_NAME,
    permanentStorage = true,
    settings = { {
        key = "lockButton",
        name = "lockButton_name",
        description = "lockButton_description",
        default = "Controller Y",
        renderer = "inputBinding",
        argument = {
            key = MOD_NAME .. "LockButton",
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
        key = "toggleButton",
        name = "toggleButton_name",
        description = "toggleButton_description",
        default = "Controller X",
        renderer = "inputBinding",
        argument = {
            key = MOD_NAME .. "ToggleButton",
            type = "action"
        },
    } }
}
