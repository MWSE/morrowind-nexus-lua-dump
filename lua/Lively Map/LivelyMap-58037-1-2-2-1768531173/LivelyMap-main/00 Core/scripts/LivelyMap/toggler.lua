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
local MOD_NAME          = require("scripts.LivelyMap.ns")
local mutil             = require("scripts.LivelyMap.mutil")
local putil             = require("scripts.LivelyMap.putil")
local core              = require("openmw.core")
local util              = require("openmw.util")
local pself             = require("openmw.self")
local aux_util          = require('openmw_aux.util')
local myui              = require('scripts.LivelyMap.pcp.myui')
local camera            = require("openmw.camera")
local ui                = require("openmw.ui")
local settings          = require("scripts.LivelyMap.settings")
local async             = require("openmw.async")
local interfaces        = require('openmw.interfaces')
local storage           = require('openmw.storage')
local h3cam             = require("scripts.LivelyMap.h3.cam")
local overlapfinder     = require("scripts.LivelyMap.overlapfinder")
local callbackcontainer = require("scripts.LivelyMap.callbackcontainer")

---@type MeshAnnotatedMapData?
local currentMapData    = nil

local toggleCallbacks = callbackcontainer.NewCallbackContainer()

---@type fun(data :MeshAnnotatedMapData)[]
local onMapMovedHandlers = {}
---@type fun(data :MeshAnnotatedMapData)[]
local onMapHiddenHandlers = {}

---Don't process these events immediately, since their origin may be
---from a delayed action. Delayed actions can't be nested.
---@type {fn: fun(data : MeshAnnotatedMapData), data : MeshAnnotatedMapData}[]
local pendingMapChangeEvents = {}

---@param data MeshAnnotatedMapData
local function doOnMapMoved(data)
    print("doOnMapMoved: " .. aux_util.deepToString(data, 3))
    currentMapData = data

    for _, fn in ipairs(onMapMovedHandlers) do
        local status, err = pcall(function() fn(data) end)
        if not status then
            print("OnMapMoved(" .. aux_util.deepToString(data) .. ") callback error: " .. tostring(err))
        end
    end

    toggleCallbacks:invoke(data.callbackId)
end

---@param data MeshAnnotatedMapData
local function onMapMoved(data)
    table.insert(pendingMapChangeEvents, { fn = doOnMapMoved, data = data })
end

local function doOnMapHidden(data)
    print("doOnMapHidden: " .. aux_util.deepToString(data, 3))
    currentMapData = nil

    for _, fn in ipairs(onMapHiddenHandlers) do
        local status, err = pcall(function() fn(data) end)
        if not status then
            print("OnMapHidden(" .. aux_util.deepToString(data) .. ") callback error: " .. tostring(err))
        end
    end

    toggleCallbacks:invoke(data.callbackId)
end

---@param data MeshAnnotatedMapData
local function onMapHidden(data)
    table.insert(pendingMapChangeEvents, { fn = doOnMapHidden, data = data })
end

---
---@return boolean true if an event was processed.
local function processPendingMapEvent()
    local event = table.remove(pendingMapChangeEvents, 1)
    if event then
        print("Processing map change event: "..aux_util.deepToString(event.data, 3))
        event.fn(event.data)
        return true
    end
    return false
end

--local lastCameraPos = nil
local function onUpdate(dt)
    processPendingMapEvent()
end

local function addHandler(fn, list)
    if type(fn) ~= "function" then
        error("addHandler fn must be a function, not a " .. type(fn))
    end
    print("Added new handler: "..aux_util.deepToString(fn, 3))
    table.insert(list, fn)
end

local function summonMap(callbackId)
    local mapData = mutil.getClosestMap(pself.cell.gridX, pself.cell.gridY)

    local pos = interfaces.LivelyMapPlayer.getExteriorPositionAndFacing().pos
    local showData = mutil.shallowMerge(mapData, {
        cellID = pself.cell.id,
        player = pself,
        startWorldPosition = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
        },
        callbackId = callbackId,
    })
    print("sendGlobalEvent: "..aux_util.deepToString(showData, 3))
    core.sendGlobalEvent(MOD_NAME .. "onShowMap", showData)
end

local enabled = true

local function setEnabled(status)
    print("Map Toggle enabled: " .. tostring(status))
    enabled = status
end

---@param open boolean? Nil to toggle. Otherwise, boolean indicating desired state.
---@param callback fun()? Called once the toggle is processed. This can take multiple frames, so this is the only way to know when it's done.
local function toggleMap(open, callback)
    if open == nil then
        open = currentMapData == nil
    end

    if not enabled then
        print("Map toggle disabled.")
        return
    end

    if open then
        print("Opening map...")
        interfaces.LivelyMapPlayer.renewExteriorPositionAndFacing()
    else
        print("Closing map...")
    end

    local callbackId = nil
    if callback then
        callbackId = toggleCallbacks:add(callback)
    end

    if open and currentMapData == nil and interfaces.UI.getMode() == nil then
        if callbackId then print("Toggle on receipt ID: " .. callbackId) end
        summonMap(callbackId)
    elseif (not open) and (currentMapData ~= nil) then
        if callbackId then print("Toggle off receipt ID: " .. callbackId) end
        core.sendGlobalEvent(MOD_NAME .. "onHideMap", { player = pself, callbackId = callbackId })
        interfaces.LivelyMapMarker.editMarkerWindow(nil)
    elseif callback then
        -- no change, so do callback
        toggleCallbacks:invoke(callbackId)
    end
end


return {
    interfaceName = MOD_NAME .. "Toggler",
    interface = {
        version = 1,
        onMapMoved = function(fn)
            return addHandler(fn, onMapMovedHandlers)
        end,
        onMapHidden = function(fn)
            return addHandler(fn, onMapHiddenHandlers)
        end,
        toggleMap = toggleMap,
        setEnabled = setEnabled,
    },
    eventHandlers = {
        [MOD_NAME .. "onMapMoved"] = onMapMoved,
        [MOD_NAME .. "onMapHidden"] = onMapHidden,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
