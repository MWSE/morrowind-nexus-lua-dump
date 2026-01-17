--[[
ErnPerkFramework for OpenMW.
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
local settings        = require("scripts.LivelyMap.settings")
local storage         = require('openmw.storage')
local ui              = require('openmw.ui')
local async           = require("openmw.async")
local interfaces      = require('openmw.interfaces')
local input           = require('openmw.input')
local MOD_NAME        = require("scripts.LivelyMap.ns")
local core            = require("openmw.core")
local util            = require("openmw.util")
local aux_util        = require('openmw_aux.util')
local pself           = require("openmw.self")
local cameraInterface = require("openmw.interfaces").Camera
local settings        = require("scripts.LivelyMap.settings")

local function splitString(str)
    local out = {}
    for item in str:gmatch("([^,%s]+)") do
        table.insert(out, item)
    end
    return out
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function onConsoleCommand(mode, command, selectedObject)
    local function getSuffixForCmd(prefix)
        if string.sub(command:lower(), 1, string.len(prefix)) == prefix then
            return string.sub(command, string.len(prefix) + 1)
        else
            return nil
        end
    end

    local showMap = getSuffixForCmd("lua map")
    if showMap ~= nil then
        interfaces.LivelyMapToggler.toggleMap(true)
    end

    local editMarker = getSuffixForCmd("lua marker")
    if editMarker ~= nil then
        local id = splitString(editMarker)
        print("Edit Marker: " .. aux_util.deepToString(id, 3))
        if #id == 0 then
            interfaces.LivelyMapMarker.editMarkerWindow({ id = "custom_" .. tostring(pself.cell.id) })
        else
            interfaces.LivelyMapMarker.editMarkerWindow({ id = tostring(id) })
        end
    end

    local markArea = getSuffixForCmd("lua markarea")
    if markArea ~= nil then
        local trimmed = trim(markArea)
        print("Mark Area: " .. trimmed)
        interfaces.LivelyMapAreaMarker.markArea(trimmed)
    end

    local unstuck = getSuffixForCmd("lua unstuck")
    if unstuck ~= nil then
        print("Please report your bug in the Discord along with the logs.")
        cameraInterface.enableModeControl(MOD_NAME)
        for k, v in pairs(pself.type.CONTROL_SWITCH) do
            local old = pself.type.getControlSwitch(pself, v)
            print("Changing " .. tostring(k) .. " from " .. tostring(old) .. " to true.")
            pself.type.setControlSwitch(pself, v, true)
        end
    end
end

--- Calls to input.registerActionHandler should all be done in this function!
local function init()
    local actionName = MOD_NAME .. "_ToggleMapWindow"

    local actionCallback = async:callback(function(e)
        if e then
            interfaces.LivelyMapToggler.toggleMap()
        end
    end)
    input.registerActionHandler(actionName, actionCallback)

    -- Exit the map when one of these triggers goes off:
    for _, exitTrigger in ipairs { "GameMenu", "Journal", "Inventory" } do
        input.registerTriggerHandler(exitTrigger, async:callback(function()
            interfaces.LivelyMapToggler.toggleMap(false,
                function()
                    print("Trigger: Closed map because " .. exitTrigger .. " triggered.")
                end)
        end))
    end

    --- Drop the map if the player is hit
    interfaces.Combat.addOnHitHandler(function(attackInfo)
        if attackInfo ~= nil then
            interfaces.LivelyMapToggler.toggleMap(false)
        end
    end)
end


return {
    engineHandlers = {
        onInit = init,
        onLoad = init,
        onConsoleCommand = onConsoleCommand,
    },
}
