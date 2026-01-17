--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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
local MOD_NAME     = require("scripts.LivelyMap.ns")
local mutil        = require("scripts.LivelyMap.mutil")
local putil        = require("scripts.LivelyMap.putil")
local core         = require("openmw.core")
local util         = require("openmw.util")
local pself        = require("openmw.self")
local aux_util     = require('openmw_aux.util')
local camera       = require("openmw.camera")
local ui           = require("openmw.ui")
local settings     = require("scripts.LivelyMap.settings")
local async        = require("openmw.async")
local interfaces   = require('openmw.interfaces')
local storage      = require('openmw.storage')
local input        = require('openmw.input')
local heightData   = storage.globalSection(MOD_NAME .. "_heightData")
local keytrack     = require("scripts.LivelyMap.keytrack")
local uiInterface  = require("openmw.interfaces").UI
local localization = core.l10n(MOD_NAME)

--- This file places markers on "Markers":
--- Temple Markers
--- Divine Markers
--- Prison Markers


local settingCache = {
    autoMarkTemplesAndCults = settings.automatic.autoMarkTemplesAndCults,
    autoMarkPrisons = settings.automatic.autoMarkPrisons,
}

print("settings.automatic: " .. aux_util.deepToString(settings.automatic, 4))

settings.automatic.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.automatic[key]
end))

---@class MarkerTemplate
---@field iconName string Basename of the stamp.
---@field nameRecord string
---@field color number This corresponds to the pallete color number.
---@field allowed fun():boolean

---@type {[string]: MarkerTemplate}
local markerBasicInfo = {
    templemarker = {
        iconName = "monument",
        nameRecord = "markerTemple",
        color = 3,
        allowed = function()
            return settingCache.autoMarkTemplesAndCults
        end
    },
    divinemarker = {
        iconName = "diamond",
        nameRecord = "markerImperialCult",
        color = 3,
        allowed = function()
            return settingCache.autoMarkTemplesAndCults
        end
    },
    prisonmarker = {
        iconName = "castle",
        nameRecord = "markerPrison",
        color = 4,
        allowed = function()
            return settingCache.autoMarkPrisons
        end
    },
}


local function onMarkerActivated(data)
    local template = markerBasicInfo[data.recordId]
    if not template then
        return
    end
    if not template.allowed() then
        return
    end

    local id = data.cell.id .. "_" .. data.recordId

    local exists = interfaces.LivelyMapMarker.getMarkerByID(id)
    if exists then
        return
    end

    ---@type MarkerData
    local markerInfo = {
        id = id,
        note = localization(template.nameRecord, { name = data.cell.name }),
        iconName = template.iconName,
        color = template.color,
        worldPos = data.position,
        hidden = false,
    }
    interfaces.LivelyMapMarker.upsertMarkerIcon(markerInfo)
end



return {
    eventHandlers = {
        [MOD_NAME .. "onMarkerActivated"] = onMarkerActivated,
    },
    engineHandlers = {}
}
