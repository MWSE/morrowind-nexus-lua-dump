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
local MOD_NAME   = require("scripts.LivelyMap.ns")
local storage    = require('openmw.storage')
local util       = require('openmw.util')
local mutil      = require("scripts.LivelyMap.mutil")
local core       = require("openmw.core")
local pself      = require("openmw.self")
local aux_util   = require('openmw_aux.util')
local camera     = require("openmw.camera")
local ui         = require("openmw.ui")
local settings   = require("scripts.LivelyMap.settings")
local async      = require("openmw.async")
local interfaces = require('openmw.interfaces')
local heightData = storage.globalSection(MOD_NAME .. "_heightData")
local h3cam      = require("scripts.LivelyMap.h3.cam")


---This is a world-space position, but x and y are divided by CELL_LENGTH.
---@alias CellPos util.vector3

---X and Y are between 0 and 1, and are the relative locations on the mesh.
---@alias RelativeMeshPos util.vector2

---World space coordinate.
---@alias WorldSpacePos util.vector3

--- cellPosToRelativeMeshPos return mapPos, but shifted by the current map Extents
--- so the bottom left becomes 0,0 and top right becomes 1,1.
--- @param currentMapData MeshAnnotatedMapData
--- @param cellPos CellPos
--- @param allowOutOfBounds boolean?
--- @return RelativeMeshPos?
local function cellPosToRelativeMeshPos(currentMapData, cellPos, allowOutOfBounds)
    if currentMapData == nil then
        error("missing mapObject")
        return nil
    end
    if cellPos == nil then
        error("mapPos is nil")
    end
    if currentMapData.Extents == nil then
        error("mapPos.Extents is nil")
    end
    if (not allowOutOfBounds) and (cellPos.x < currentMapData.Extents.Left or cellPos.x > currentMapData.Extents.Right) then
        --[[print("cellPosToRelativeMeshPos: x position (" ..
            tostring(cellPos.x) ..
            ") is outside extents [" .. currentMapData.Extents.Left .. " to " .. currentMapData.Extents.Right .. "]")]]
        return nil
    end
    if (not allowOutOfBounds) and (cellPos.y < currentMapData.Extents.Bottom or cellPos.y > currentMapData.Extents.Top) then
        --[[print("cellPosToRelativeMeshPos: y position (" ..
            tostring(cellPos.y) ..
            ")  is outside extents [" .. currentMapData.Extents.Bottom .. " to " .. currentMapData.Extents.Top .. "]")]]
        return nil
    end
    local x = util.remap(cellPos.x, currentMapData.Extents.Left, currentMapData.Extents.Right + 1, 0.0, 1.0)
    local y = util.remap(cellPos.y, currentMapData.Extents.Bottom, currentMapData.Extents.Top + 1, 0.0, 1.0)
    return util.vector2(x, y)
end


-- relativeMeshPosToCellPos converts a relative [0,1) map position
-- back into an absolute cell position.
--- @param currentMapData MeshAnnotatedMapData
--- @param relMeshPos RelativeMeshPos
--- @return CellPos?
local function relativeMeshPosToCellPos(currentMapData, relMeshPos)
    if currentMapData == nil then
        error("missing mapObject")
    end
    if relMeshPos == nil then
        error("relCellPos is nil")
    end
    if currentMapData.Extents == nil then
        error("mapPos.Extents is nil")
    end

    local x = util.remap(
        relMeshPos.x,
        0.0, 1.0,
        currentMapData.Extents.Left,
        currentMapData.Extents.Right + 1
    )

    local y = util.remap(
        relMeshPos.y,
        0.0, 1.0,
        currentMapData.Extents.Bottom,
        currentMapData.Extents.Top + 1
    )

    -- We can't recover Z; lossy.
    return util.vector3(x, y, 0)
end


--- Absolute point on the mesh to corresponding world position.
--- @param currentMapData MeshAnnotatedMapData
--- @param worldPos WorldSpacePos
--- @return RelativeMeshPos? util.vector2 or nil if degenerate
local function mapPosToRelativeCellPos(currentMapData, worldPos)
    if not currentMapData then
        error("missing map data")
    end
    if not currentMapData.bounds then
        error("missing map bounds")
    end
    if not worldPos then
        error("worldPos is nil")
    end

    local bl = currentMapData.bounds.bottomLeft
    local br = currentMapData.bounds.bottomRight
    local tl = currentMapData.bounds.topLeft

    -- Basis vectors of the map
    local u = br - bl -- X axis
    local v = tl - bl -- Y axis
    local w = worldPos - bl

    -- Precompute dot products
    local uu = u:dot(u)
    local uv = u:dot(v)
    local vv = v:dot(v)
    local wu = w:dot(u)
    local wv = w:dot(v)

    local denom = uu * vv - uv * uv
    if math.abs(denom) < 1e-8 then
        return nil -- Degenerate map
    end

    -- Solve for barycentric-style coordinates
    local x = (wu * vv - wv * uv) / denom
    local y = (wv * uu - wu * uv) / denom

    --[[
    -- TODO: add these checks back where needed
    if x < 0 or x > 1 or y < 0 or y > 1 then
        -- outside bounds
        print("mapPosToRelativeCellPos outside bounds. worldPos: " ..
            tostring(worldPos) .. ", output: " .. tostring(util.vector2(x, y)))
        return nil
    else
        print("mapPosToRelativeCellPos inside bounds. worldPos: " ..
            tostring(worldPos) .. ", output: " .. tostring(util.vector2(x, y)))
    end
    ]]

    return util.vector2(x, y)
end




--- relativeMapPosToWorldPos turns a relative map position to a 3D world position,
--- which is the position on the map mesh.
--- @param currentMapData MeshAnnotatedMapData
--- @param relCellPos RelativeMeshPos
--- @return WorldSpacePos?
local function relativeMeshPosToAbsoluteMeshPos(currentMapData, relCellPos)
    if currentMapData == nil then
        error("no current map")
    end
    if currentMapData.object == nil then
        error("missing object")
    end
    if relCellPos == nil then
        error("relCellPos is nil")
    end
    if currentMapData.bounds == nil then
        error("currentMapData.bounds is nil")
    end
    -- interpolate along X at bottom and top edges
    local bottomPos = mutil.lerpVec3(currentMapData.bounds.bottomLeft, currentMapData.bounds.bottomRight, relCellPos.x)
    local topPos    = mutil.lerpVec3(currentMapData.bounds.topLeft, currentMapData.bounds.topRight, relCellPos.x)

    -- interpolate along Y between bottom and top
    local worldPos  = mutil.lerpVec3(bottomPos, topPos, relCellPos.y)

    local out       = util.vector3(worldPos.x, worldPos.y, currentMapData.bounds.bottomRight.z)

    --[[
    local inverse   = mapPosToRelativeCellPos(currentMapData, out)

    print("expected relCellPos: " ..
        tostring(relCellPos) .. "\ninput: " ..
        tostring(out) .. "\n actual relCellPos: " .. tostring(inverse))
    ]]
    return out
end


---@class PsoSettings
---@field psoPushdownOnly boolean
---@field psoDepth number

---@class ViewportData
---@field viewportPos ViewportPosResult
---@field  mapWorldPos util.vector3?
---@field  viewportFacing util.vector3?

--- realPosToViewportPos turns a world space coordinate into the corresponding coordinate for the map mesh on the viewport.
--- @param currentMapData MeshAnnotatedMapData
--- @param psoSettings PsoSettings
--- @param pos WorldSpacePos
--- @param facingWorldDir util.vector2 | util.vector3 | nil
--- @return ViewportData?
local function realPosToNormalizedViewportPos(currentMapData, psoSettings, pos, facingWorldDir)
    -- this works ok, but fails when the camera gets too close.
    if not currentMapData then
        error("no current map")
    end

    local cellPos = mutil.worldPosToCellPos(pos)
    local rel = cellPosToRelativeMeshPos(currentMapData, cellPos)
    if not rel then
        return
    end

    local mapWorldPos = relativeMeshPosToAbsoluteMeshPos(currentMapData, rel)

    -- POM: Calculate vertical offset so the icon appears glued
    -- to the surface of the map, which has been distorted according
    -- to the parallax shader.
    local maxHeight = heightData:get("MaxHeight")
    local height = util.clamp(cellPos.z * mutil.CELL_SIZE, 0, maxHeight)
    local heightMax = 0.5
    if psoSettings.psoPushdownOnly then
        heightMax = 1.0
    end
    local heightRatio = heightMax - (height / maxHeight)
    local camPos = camera.getPosition()
    local viewDir = (camPos - mapWorldPos):normalize()
    --local safeZ = math.max(math.abs(viewDir.z), 0.1)
    local safeZ = 1
    local parallaxWorldOffset =
        util.vector3(
            viewDir.x / safeZ,
            viewDir.y / safeZ,
            0
        ) * (psoSettings.psoDepth * heightRatio)
    -- POM Distance fade
    local maxPOMDistance = 1000
    local dist = (camPos - mapWorldPos):length()
    local fade = 1.0 - util.clamp(dist / maxPOMDistance, 0, 1)

    parallaxWorldOffset = parallaxWorldOffset * fade

    -- Extra calcs if we need facing
    local viewportFacing = nil
    if facingWorldDir then
        --print("facingWorldDir: " .. tostring(facingWorldDir))
        facingWorldDir = util.vector3(2000 * facingWorldDir.x, 2000 * facingWorldDir.y, 0)
        local relFacing = cellPosToRelativeMeshPos(currentMapData, mutil.worldPosToCellPos(pos + facingWorldDir))

        if relFacing then
            local mapWorldFacingPos = relativeMeshPosToAbsoluteMeshPos(currentMapData, relFacing)
            local s0 = h3cam.worldPosToNormalizedViewportPos(mapWorldPos)
            local s1 = h3cam.worldPosToNormalizedViewportPos(mapWorldFacingPos)
            if s0 and s1 and s0.pos and s1.pos then
                viewportFacing = (s1.pos - s0.pos):normalize()
            end
        end
    end


    return {
        viewportPos = h3cam.worldPosToNormalizedViewportPos(mapWorldPos + parallaxWorldOffset),
        mapWorldPos = mapWorldPos,
        viewportFacing = viewportFacing,
    }
end

local planeNormal = util.vector3(0, 0, 1)
local function viewportPosToRelativeMeshPos(currentMapData, viewportPos, ignoreBounds, normalizedViewportPos)
    if not currentMapData or not currentMapData.bounds then
        error("missing map data")
    end

    -- 1. Ray from viewport
    local rayOrigin = camera.getPosition()
    local rayDir = nil
    if viewportPos then
        rayDir = h3cam.viewportPosToWorldRay(viewportPos)
        if not rayDir then
            print("no rayDir")
            return nil
        end
    elseif normalizedViewportPos then
        local dir = camera.viewportToWorldVector(normalizedViewportPos)
        if not dir then
            print("no normalized rayDir")
            return nil
        end
        rayDir = dir:normalize()
    end

    -- 2. Intersect ray with map plane
    local bl = currentMapData.bounds.bottomLeft
    local br = currentMapData.bounds.bottomRight
    local tl = currentMapData.bounds.topLeft

    --local planeNormal = (br - bl):cross(tl - bl):normalize()
    --local planeNormal = util.vector3(0, 0, 1)
    local denom = planeNormal:dot(rayDir)
    if math.abs(denom) < 1e-6 then
        print("denom is near 0")
        return nil
    end

    -- t is the distance from the camera to the intersecting point
    -- on the mesh plane
    local t = planeNormal:dot(bl - rayOrigin) / denom
    if t < 0 then
        print("t is less than 0")
        return nil
    end

    local hitPos = rayOrigin + rayDir * t

    -- 3. Map-world → relative mesh
    local rel = mapPosToRelativeCellPos(currentMapData, hitPos)
    if not rel or ((not ignoreBounds) and (rel.x < 0 or rel.x > 1 or rel.y < 0 or rel.y > 1)) then
        print("rel is bad. hitPos: " ..
            tostring(hitPos) .. ", rayOrigin: " .. tostring(rayOrigin) .. ", rayDir: " ..
            tostring(rayDir) .. ", t:" .. tostring(t))
        return nil
    end

    --[[print("rel is ok! hitPos: " ..
        tostring(hitPos) .. ", rayOrigin: " .. tostring(rayOrigin) .. ", rayDir: " ..
        tostring(rayDir) .. ", t:" .. tostring(t))]]
    return rel
end

local function viewportPosToRealPos(currentMapData, viewportPos)
    if not currentMapData or not currentMapData.bounds then
        error("missing map data")
    end

    local rel = viewportPosToRelativeMeshPos(currentMapData, viewportPos, true)
    if not rel then
        return nil
    end

    -- 4. Relative mesh → cell
    local cellPos = relativeMeshPosToCellPos(currentMapData, rel)
    if not cellPos then
        print("cellPos is nil")
        return nil
    end
    --[[print("viewportPosToRealPos intermediate variables: cellPos: " ..
    tostring(cellPos) .. ", rel: " .. tostring(rel) .. ", denom: " .. tostring(denom) .. ", t: " .. tostring(t))]]
    -- 5. Cell → world
    return mutil.cellPosToWorldPos(cellPos)
end



return {
    cellPosToRelativeMeshPos = cellPosToRelativeMeshPos,
    relativeMeshPosToAbsoluteMeshPos = relativeMeshPosToAbsoluteMeshPos,
    relativeMeshPosToCellPos = relativeMeshPosToCellPos,
    mapPosToRelativeCellPos = mapPosToRelativeCellPos,
    realPosToNormalizedViewportPos = realPosToNormalizedViewportPos,
    viewportPosToRealPos = viewportPosToRealPos,
    viewportPosToRelativeMeshPos = viewportPosToRelativeMeshPos,
}
