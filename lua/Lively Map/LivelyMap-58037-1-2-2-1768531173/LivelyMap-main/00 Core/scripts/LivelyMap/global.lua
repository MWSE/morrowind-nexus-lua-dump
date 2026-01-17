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
local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local aux_util = require('openmw_aux.util')
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local json = require('scripts.LivelyMap.json.json')
local mutil = require('scripts.LivelyMap.mutil')
local localization = core.l10n(MOD_NAME)
local storage = require('openmw.storage')
local mapData = storage.globalSection(MOD_NAME .. "_mapData")

-- persist is saved to disk
local persist = {
    -- map id to static record id
    -- these are created dynamically, but should be re-used
    -- this needs to be persisted in the save
    idToRecordId = {},
    -- activeMaps is a table of player -> id -> object
    -- that are currently active.
    activeMaps = {},
    skyBowlRecordId = nil,
}

local function getSkyBowlRecord()
    if not persist.skyBowlRecordId then
        local recordFields = {
            model = "meshes\\livelymap\\sky_bowl.nif",
        }
        local draftRecord = types.Activator.createRecordDraft(recordFields)
        -- createRecord can't be used until the game is actually started.
        local record = world.createRecord(draftRecord)
        persist.skyBowlRecordId = record.id
        print("New activator record for sky bowl: " .. record.id)
    end
    return persist.skyBowlRecordId
end

-- getMapRecord gets or creates an activator with the given mesh name.
local function getMapRecord(id)
    id = tostring(id)
    if not persist.idToRecordId[id] then
        local recordFields = {
            model = "meshes\\livelymap\\world_" .. id .. ".nif",
        }
        local draftRecord = types.Activator.createRecordDraft(recordFields)
        -- createRecord can't be used until the game is actually started.
        local record = world.createRecord(draftRecord)
        persist.idToRecordId[id] = record.id
        print("New activator record for " .. id .. ": " .. record.id)
    end
    return persist.idToRecordId[id]
end

---@class GloballyAnnotatedMapData : StoredMapData
---@field player userdata The player that owns this instance.
---@field object userdata The map mesh static object instance.
---@field skyBowlObject userdata The sky bowl mesh static object instance.
---@field swapped boolean? Indicates the swap-in or swap-out state of the map.
---@field callbackId number? Optional event receipt.

---Returns immutable map metadata.
---@param data string | number | HasID
---@param player userdata
---@return GloballyAnnotatedMapData?
local function newMapObject(data, player)
    local map = mutil.getMap(data)

    local record = getMapRecord(map.ID)
    if not record then
        error("No record for map " .. map.ID)
        return nil
    end

    -- actually make the map object
    local new = world.createObject(record, 1)
    new:addScript("scripts\\LivelyMap\\mapnif.lua", map)

    -- make the sky bowl
    local skyBowlRecord = getSkyBowlRecord()
    local newSkyBowl = world.createObject(skyBowlRecord, 1)

    local extra = {
        player = player,
        object = new,
        skyBowlObject = newSkyBowl,
    }

    -- scale the object
    new:setScale(mutil.getScale(map))
    newSkyBowl:setScale(mutil.getScale(map))

    return mutil.shallowMerge(map, extra)
end

local function onSave()
    return persist
end

local function start(data)
    -- load persist
    if data ~= nil then
        persist = data
    end
end

local function onShowMap(data)
    if not data then
        error("onShowMap has nil data parameter.")
    end
    if not data.cellID then
        error("onShowMap data parameter has nil cellID field.")
        return
    end
    if not data.player then
        error("onShowMap data parameter has nil player field.")
        return
    end
    if type(data.player) == "string" then
        error("onShowMap data parameter has a string player field.")
        return
    end

    if (not data.ID) and (not data.position) then
        -- One of these two are required.
        -- position is world position.
        -- ID is the map ID in maps.json.
        error("onShowMap data parameter has nil ID and nil position field.")
        return
    end

    -- Find ID or startWorldPosition based on the other one.
    if not data.startWorldPosition and not data.ID then
        if data.startWorldPosition then
            local cellPos = mutil.worldPosToCellPos(data.startWorldPosition)
            data.ID = mutil.getClosestMap(math.floor(cellPos.x), math.floor(cellPos.y))
        else
            local mapdata = mutil.getMap(data)
            data.startWorldPosition = util.vector3(mapdata.CenterX * mutil.CELL_SIZE, mapdata.CenterY * mutil.CELL_SIZE,
                0)
        end
    end

    local centerCell = function(n)
        return (math.floor(n / mutil.CELL_SIZE) + 0.5) * mutil.CELL_SIZE
    end
    local mapPosition = data.mapPosition or
        util.vector3(
            centerCell(data.player.position.x),
            centerCell(data.player.position.y),
            data.player.position.z + 5 * mutil.CELL_SIZE)

    local playerID = data.player.id
    if persist.activeMaps[playerID] == nil then
        persist.activeMaps[playerID] = {}
    end
    print("Showing map " .. tostring(data.ID))

    local activeMap = nil
    if persist.activeMaps[playerID][data.ID] == nil then
        -- enable the new map etc
        activeMap = newMapObject(data.ID, data.player)
        if activeMap == nil then
            error("Unknown map ID: " .. data.ID)
        end
        print("Showing new map " .. tostring(data.ID))
        persist.activeMaps[playerID][data.ID] = activeMap
    else
        -- get the existing map
        print("Moving existing map" .. tostring(data.ID))
        activeMap = persist.activeMaps[playerID][data.ID]
    end

    -- we should only show one map per player, so clean up everything else
    local swapped = false
    local toDelete = {}
    for k, v in pairs(persist.activeMaps[playerID]) do
        if k ~= data.ID then
            swapped = true
            print("Deleting map " .. tostring(v.ID))
            -- swapped means the map is being replaced with a different one.
            v.player:sendEvent(MOD_NAME .. "onMapHidden",
                mutil.shallowMerge(v, {
                    swapped = swapped,
                    callbackId = data.callbackId,
                }))
            v.object:remove()
            v.skyBowlObject:remove()
            table.insert(toDelete, k)
        end
    end
    for _, k in ipairs(toDelete) do
        persist.activeMaps[playerID][k] = nil
    end

    -- attach the rendered object to the data
    data.object = activeMap.object
    data.skyBowlObject = activeMap.skyBowlObject

    -- teleport enables the object for free
    activeMap.object:teleport(world.getCellById(data.cellID),
        mapPosition,
        nil)
    activeMap.skyBowlObject:teleport(world.getCellById(data.cellID),
        mapPosition,
        nil)
    -- notify the map that it moved.
    -- the map is responsible for telling the player.
    activeMap.object:sendEvent(MOD_NAME .. "onMapMoved",
        mutil.shallowMerge(data, { swapped = swapped, callbackId = data.callbackId }))
end

local function onHideMap(data)
    if not data then
        error("onShowMap has nil data parameter.")
    end
    if not data.player then
        error("onShowMap data parameter has nil player field.")
        return
    end

    local playerID = data.player.id
    if persist.activeMaps[playerID] == nil then
        persist.activeMaps[playerID] = {}
    end

    local toDelete = {}
    for k, v in pairs(persist.activeMaps[playerID]) do
        print("Deleting map " .. tostring(v.ID) .. ": " .. aux_util.deepToString(v, 3))
        v.player:sendEvent(MOD_NAME .. "onMapHidden",
            mutil.shallowMerge(v, { swapped = false, callbackId = data.callbackId }))
        v.object:remove()
        v.skyBowlObject:remove()
        table.insert(toDelete, k)
    end
    for _, k in ipairs(toDelete) do
        persist.activeMaps[playerID][k] = nil
    end
end

---@class DoorInfo
---@field recordId string
---@field model string

---@param doorObj any
---@return DoorInfo?
local function getDoorInfo(doorObj)
    local rec = types.Door.record(doorObj)
    if not rec then
        return nil
    end
    return {
        recordId = rec.id,
        model = rec.model,
    }
end


---@class AugmentedPos
---@field pos util.vector3
---@field exteriorCellId string? id for the exterior cell
---@field doorInfos DoorInfo[] door meshes in the cell


---@param cell any cell
---@return AugmentedPos
local function getRepresentiveForCell(cell)
    local doorInfos = {}
    local doors = cell:getAll(types.Door)

    for _, d in pairs(doors) do
        local info = getDoorInfo(d)
        if info then
            table.insert(doorInfos, info)
        end
    end

    local center = mutil.averageVector3s(doors, function(e)
        return e and e.position
    end)
    if center then
        return { pos = center, exteriorCellId = cell.id, doorInfos = doorInfos }
    end

    center = mutil.averageVector3s(cell:getAll(types.Static), function(e)
        return e and e.position
    end)
    if center then
        return { pos = center, exteriorCellId = cell.id, doorInfos = doorInfos }
    end

    return {
        pos = util.vector3(
            (cell.gridX + 0.5) * mutil.CELL_SIZE,
            (cell.gridY + 0.5) * mutil.CELL_SIZE,
            0
        ),
        exteriorCellId = cell.id,
        doorInfos = doorInfos,
    }
end

--- cache of interior cell id to exterior position
---@type {[string]: AugmentedPos}
local cachedPos = {}

--- Find the player's exterior location.
--- If they are in an interior, find a door to an exit and use that position.
---@param data any player or cell
---@return AugmentedPos?
local function getExteriorLocation(data)
    local inputCell = data.cell or data
    if inputCell.isExterior then
        if data.position then
            --- don't cache the easy case.
            return { pos = data.position, exteriorCellId = inputCell.id }
        elseif cachedPos[inputCell.id] then
            -- return previously-cached computed position
            return cachedPos[inputCell.id]
        else
            --- we were passed in an exterior cell, which doesn't have a high-def
            --- world position
            cachedPos[inputCell.id] = getRepresentiveForCell(inputCell)
            return cachedPos[inputCell.id]
        end
    end
    if cachedPos[inputCell.id] then
        return cachedPos[inputCell.id]
    end
    -- we need to recurse out until we find the exit door
    local seenCells = {}
    ---@type fun(cell : any): AugmentedPos?
    local searchForDoor
    searchForDoor = function(cell)
        if not cell then
            return nil
        end
        if seenCells[cell.id] then
            return nil
        end
        seenCells[cell.id] = true
        for _, door in ipairs(cell:getAll(types.Door)) do
            local destCell = types.Door.destCell(door)
            if destCell then
                -- If this door leads directly outside, we're done
                if destCell.isExterior then
                    --- we actually need to get all doors or we will
                    --- mess up the cache when a player uses a
                    --- mage guild guide.
                    local tmp = getRepresentiveForCell(destCell)

                    return {
                        pos = types.Door.destPosition(door),
                        exteriorCellId = types.Door.destCell(door).id,
                        doorInfos = tmp.doorInfos,
                    }
                end

                -- Otherwise, recurse
                local result = searchForDoor(destCell)
                if result then
                    return result
                end
            end
        end
        return nil
    end
    cachedPos[inputCell.id] = searchForDoor(inputCell)
    return cachedPos[inputCell.id]
end

--- Special marker handling
local function broadcastMarker(data)
    for _, player in ipairs(world.players) do
        player:sendEvent(MOD_NAME .. "onMarkerActivated", data)
    end
end
local cachedMarkers = {}
local markerRecords = {
    northmarker = true,
    templemarker = true,
    divinemarker = true,
    prisonmarker = true,
    travelmarker = true,
}
local function onObjectActive(object)
    if (not object.type) or (markerRecords[object.recordId]) then
        -- openmw hack to get a NorthMarker reference.
        -- NorthMarkers aren't available with cell:getAll().
        -- Thanks S3ctor for the workaround. :)
        if not cachedMarkers[object.cell.id] then
            cachedMarkers[object.cell.id] = {}
        end
        table.insert(cachedMarkers[object.cell.id], object)
        broadcastMarker(object)
    end
end
local function getMarkers(cell)
    if cachedMarkers[cell.id] then
        return cachedMarkers[cell.id]
    else
        return {}
    end
end

local exteriorNorth = util.transform.identity
local function getFacing(player)
    if not player.rotation then
        print("no rotation for " .. tostring(player) .. ", assuming default " .. tostring(exteriorNorth))
        return exteriorNorth
    end
    -- Player forward vector
    local forward = player.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
    local northMarker = exteriorNorth
    for _, o in ipairs(getMarkers(player.cell)) do
        --print(o)
        --print(o.recordId)
        if o.recordId == "northmarker" then
            northMarker = o.rotation:inverse()
        end
    end

    -- Rotate into cardinal space
    local cardinal = northMarker * forward
    --print("northMarker: " .. aux_util.deepToString(northMarker, 3) .. ", forward: " .. tostring(forward))

    -- Project to 2D
    local v = util.vector2(cardinal.x, cardinal.y)
    return v:length() > 0 and v:normalize() or v
end

local function onRotate(data)
    -- populate with Transform:getAnglesZYX()
    if not data or not data.object or not data.rotation then
        error("onRotate bad params")
    end
    print("rotating " .. aux_util.deepToString(data, 3))
    local rot = util.transform.rotateZ(data.rotation.z) * util.transform.rotateX(data.rotation.x) *
        util.transform.rotateY(data.rotation.y)
    data.object:teleport(data.object.cell, data.object.position, rot)
end


---@class ExteriorLocationResult
---@field pos {x: number, y: number, z: number}?
---@field exteriorCellId string?
---@field facing {x: number, y: number}?
---@field doorInfos DoorInfo[]
---@field args any

--- This is a helper to get cell information for the player,
--- since cell:getAll isn't available on local scripts.
--- This function does too many things, but it's all smashed together
--- to reduce the number of events needing to be passed (which each have
--- a delay of one frame).
---@see ExteriorLocationResult
local function onGetExteriorLocation(data)
    --- special handling if we're only doing a cell reference.
    local object = data.object
    if not object then
        if data.cellName then
            object = world.getCellByName(data.cellName)
        elseif data.cellId then
            object = world.getCellById(data.cellId)
        else
            error("onGetExteriorLocation bad args: " .. aux_util.deepToString(data, 3))
            return
        end
    end

    if not object then
        print("Failed to find object: " .. aux_util.deepToString(data))
        return
    end

    local posObj = getExteriorLocation(object)
    local facing = getFacing(object)

    ---@type ExteriorLocationResult
    local payload = {
        pos = posObj and posObj.pos and { x = posObj.pos.x, y = posObj.pos.y, z = posObj.pos.z },
        exteriorCellId = posObj and posObj.exteriorCellId,
        facing = { x = facing.x, y = facing.y, z = facing.z },
        doorInfos = posObj and posObj.doorInfos or {},
        args = data,
    }

    --print("sendEvent(" .. MOD_NAME .. "onReceiveExteriorLocation, " .. aux_util.deepToString(payload, 4) .. ")")

    data.callbackObject:sendEvent(MOD_NAME .. "onReceiveExteriorLocation", payload)
end

return {
    eventHandlers = {
        [MOD_NAME .. "onShowMap"] = onShowMap,
        [MOD_NAME .. "onHideMap"] = onHideMap,
        [MOD_NAME .. "onGetExteriorLocation"] = onGetExteriorLocation,
        [MOD_NAME .. "onRotate"] = onRotate,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = start,
        onInit = start,
        onObjectActive = onObjectActive,
    }
}
