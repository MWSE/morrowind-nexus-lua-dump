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
local MOD_NAME = require("scripts.LivelyMap.ns")
local mutil = require("scripts.LivelyMap.mutil")
local aux_util = require('openmw_aux.util')
local util = require('openmw.util')
local pself = require("openmw.self")

-- This script is attached to the 3d floating map objects.

---@class MeshAnnotatedMapData : GloballyAnnotatedMapData
---@field bounds Bounds The actual bounds of the map mesh in world space.
---@field safeBounds Bounds The safe bounds of the map mesh in world space, where the edge cells are removed.

--- mapData holds read-only map metadata for this instance.
---@type MeshAnnotatedMapData
local mapData = nil

local function onStart(initData)
    if initData ~= nil then
        mapData = initData
    end
end
local function onSave()
    return mapData
end

---@class Bounds
---@field bottomLeft util.vector3
---@field bottomRight util.vector3
---@field topLeft util.vector3
---@field topRight util.vector3

---@return Bounds
local function getBounds()
    -- this is called on the map object
    local verts = pself:getBoundingBox().vertices

    local minX, maxX = verts[1].x, verts[1].x
    local minY, maxY = verts[1].y, verts[1].y
    local minZ, maxZ = verts[1].z, verts[1].z

    for i = 2, #verts do
        local v = verts[i]
        minX = math.min(minX, v.x)
        maxX = math.max(maxX, v.x)
        minY = math.min(minY, v.y)
        maxY = math.max(maxY, v.y)
        minZ = math.min(minZ, v.z)
        maxZ = math.max(maxZ, v.z)
    end

    return {
        bottomLeft  = util.vector3(minX, minY, minZ),
        bottomRight = util.vector3(maxX, minY, minZ),
        topLeft     = util.vector3(minX, maxY, minZ),
        topRight    = util.vector3(maxX, maxY, minZ),
    }
end

---Determine the safe bounds of the map mesh in world space,
---which is the mesh minus the equivalent of one cell length
---on each edge.
---@param extents Extents
---@param realBounds Bounds
---@return Bounds
local function getSafeBounds(extents, realBounds)
    local meshCellLength = math.abs((realBounds.bottomRight - realBounds.bottomLeft).x / (extents.Right - extents.Left))
    return {
        bottomLeft  = util.vector3(
            realBounds.bottomLeft.x + meshCellLength,
            realBounds.bottomLeft.y + meshCellLength,
            realBounds.bottomLeft.z
        ),
        bottomRight = util.vector3(
            realBounds.bottomRight.x - meshCellLength,
            realBounds.bottomRight.y + meshCellLength,
            realBounds.bottomRight.z
        ),
        topLeft     = util.vector3(
            realBounds.topLeft.x + meshCellLength,
            realBounds.topLeft.y - meshCellLength,
            realBounds.topLeft.z
        ),
        topRight    = util.vector3(
            realBounds.topRight.x - meshCellLength,
            realBounds.topRight.y - meshCellLength,
            realBounds.topRight.z
        )
    }
end


---@param data GloballyAnnotatedMapData
local function onMapMoved(data)
    if data == nil then
        error("onTeleported data is nil")
    end

    local bounds = getBounds()
    mapData = mutil.shallowMerge(data, {
        bounds = bounds,
        safeBounds = getSafeBounds(data.Extents, bounds)
    })

    print("onTeleported")

    mapData.player:sendEvent(MOD_NAME .. "onMapMoved", mapData)
end

return {
    eventHandlers = {
        [MOD_NAME .. "onMapMoved"] = onMapMoved,
    },
    engineHandlers = {
        onInit = onStart,
    }
}
