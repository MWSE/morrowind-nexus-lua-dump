-- DestinationResolver.lua
-- Door/cell lookup helper for the ProceduralChatter NPC Scheduling System.
-- GLOBAL script context — runs inside the global schedule manager, not attached to
-- individual NPCs.
--
-- Resolves which door an NPC should walk to and the corresponding interior entry
-- position. Called by destination modules to produce a `dest` table.
--
-- Dest table shape:
--   {
--     door            = object,         -- the door object
--     destCellName    = string,         -- name of the destination interior cell
--     doorExteriorPos = util.vector3,   -- raw exterior position of the door (no navmesh snap)
--     doorInsidePos   = util.vector3,   -- raw interior teleport position (no navmesh snap)
--     doorInsideRot   = transform,      -- door's interior rotation
--   }
--
-- NOTE: Positions are NOT snapped to the navmesh here. The local script
-- (schedule_npc.lua) is responsible for snapping before issuing a Travel action.

local types = require("openmw.types")
local world = require("openmw.world")
local util  = require("openmw.util")

local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local Blacklist      = require("scripts.ProceduralChatter.Blacklist")

local SCAN_RANGE_DOORS = ScheduleConfig.SCAN_RANGE_DOORS

-- =============================================================================
-- Internal helpers
-- =============================================================================

--- Collect all Door objects in the NPC's current cell.
-- Uses pcall guards so a bad cell reference never crashes the scheduler.
-- @param npc  Actor object
-- @return list of door objects (may be empty)
local function getDoorsInCell(npc)
    local doors = {}
    local ok, all = pcall(function() return npc.cell:getAll() end)
    if not ok or not all then return doors end
    local totalObjs = 0
    for _, obj in ipairs(all) do
        totalObjs = totalObjs + 1
        local isDoor = false
        pcall(function() isDoor = types.Door.objectIsInstance(obj) end)
        if isDoor then
            table.insert(doors, obj)
        end
    end
    -- count returned via caller for diag purposes
    return doors, totalObjs
end

--- Build a dest table for a door that has already been validated.
-- Positions are raw (not navmesh-snapped); snapping is the caller's responsibility.
-- @param door      door object
-- @param destCell  cell object from types.Door.destCell(door)
-- @return dest table
local function buildDest(door, destCell)
    -- Exterior-side position (the door's location in the cell the NPC is in).
    local exteriorPos = door.position

    -- Interior-side position and rotation (the teleport landing spot inside
    -- the destination cell). Use the type's static functions — same pattern
    -- as types.Door.destCell(door) which is confirmed working.
    local insidePos, insideRot

    local okP, p = pcall(types.Door.destPosition, door)
    if okP and p then insidePos = p end

    local okR, r = pcall(types.Door.destRotation, door)
    if okR and r then insideRot = r end

    if not insidePos then insidePos = door.position end
    if not insideRot then insideRot = door.rotation end

    return {
        door            = door,
        destCellName    = destCell.name,
        doorExteriorPos = exteriorPos,
        doorInsidePos   = insidePos,
        doorInsideRot   = insideRot,
    }
end

-- =============================================================================
-- Module
-- =============================================================================

local DestinationResolver = {}
local doorCacheByDestCell = {} -- [lowerDestCellName] = dest table

-- One-shot diagnostic flag: set to false to re-trigger the door dump
local _diagDone = false

local function cloneDest(dest)
    if not dest then return nil end
    return {
        door            = dest.door,
        destCellName    = dest.destCellName,
        doorExteriorPos = dest.doorExteriorPos,
        doorInsidePos   = dest.doorInsidePos,
        doorInsideRot   = dest.doorInsideRot,
    }
end

local function cacheDest(dest)
    if not dest or not dest.destCellName or dest.destCellName == "" then return end
    local key = string.lower(dest.destCellName)
    doorCacheByDestCell[key] = cloneDest(dest)
end

--- Scan doors in the NPC's cell for a safe-place destination (inn, tavern,
-- cornerclub, etc.) within SCAN_RANGE_DOORS of the NPC's position.
-- @param npc  Actor object
-- @return dest table, or nil if no valid door found
function DestinationResolver.findSafePlace(npc)
    local bestDoor     = nil
    local bestDestCell = nil
    local bestDist     = math.huge
    local allDoors, totalObjs = getDoorsInCell(npc)
    local diag = not _diagDone
    if diag then
        _diagDone = true
        print(string.format("[DestinationResolver] === door scan for npc '%s' (%d objects, %d doors) ===",
            tostring(npc.recordId), totalObjs or 0, #allDoors))
    end

    for _, door in ipairs(allDoors) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        local dist = (door.position - npc.position):length()

        if diag then
            print(string.format("[DestinationResolver] door '%s' isTeleport=%s dist=%.0f",
                tostring(door.recordId), tostring(isTeleport), dist))
        end

        if not isTeleport then
            if diag then
                local ok2, dc2 = pcall(types.Door.destCell, door)
                if ok2 and dc2 and not dc2.isExterior then
                    print(string.format("[DestinationResolver] WARN: non-teleport door '%s' has interior destCell '%s'",
                        tostring(door.recordId), tostring(dc2.name)))
                end
            end
            goto skipDoor
        end
        if dist > SCAN_RANGE_DOORS then goto skipDoor end

        -- Skip locked doors for safe-place destinations.  NPCs shouldn't queue
        -- outside a locked inn; they'll find another safe place instead.
        do
            local isLocked = false
            pcall(function() isLocked = types.Lockable.isLocked(door) end)
            if isLocked then goto skipDoor end
        end

        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell then goto skipDoor end
        if destCell.isExterior then goto skipDoor end

        local name = destCell.name or ""
        if Blacklist.isDestinationBlacklisted(name, "safe") then goto skipDoor end
        if diag then
            print(string.format("[DestinationResolver] => interior '%s' (dist=%.0f, safe=%s)",
                name, dist, tostring(Blacklist.isSafePlaceDestination(name))))
        end
        if Blacklist.isSafePlaceDestination(name) then
            if dist < bestDist then
                bestDist     = dist
                bestDoor     = door
                bestDestCell = destCell
            end
        end

        ::skipDoor::
    end

    if bestDoor then
        print("[DestinationResolver] findSafePlace -> " .. tostring(bestDestCell.name))
        local d = buildDest(bestDoor, bestDestCell)
        d.isSafePlace = true
        return d
    end
    if diag then print("[DestinationResolver] findSafePlace -> nil") end
    return nil
end

--- Scan doors in the NPC's cell for a religious hub destination (temple, chapel, etc.)
-- within SCAN_RANGE_DOORS of the NPC's position.
function DestinationResolver.findReligiousHub(npc)
    local bestDoor     = nil
    local bestDestCell = nil
    local bestDist     = math.huge
    local allDoors, _ = getDoorsInCell(npc)

    for _, door in ipairs(allDoors) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        if not isTeleport then goto skipDoor end

        local dist = (door.position - npc.position):length()
        if dist > SCAN_RANGE_DOORS then goto skipDoor end

        local isLocked = false
        pcall(function() isLocked = types.Lockable.isLocked(door) end)
        if isLocked then goto skipDoor end

        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell or destCell.isExterior then goto skipDoor end

        local name = destCell.name or ""
        if Blacklist.isDestinationBlacklisted(name, "religious") then goto skipDoor end
        if Blacklist.isReligiousDestination(name) then
            if dist < bestDist then
                bestDist     = dist
                bestDoor     = door
                bestDestCell = destCell
            end
        end

        ::skipDoor::
    end

    if bestDoor then
        return buildDest(bestDoor, bestDestCell)
    end
    return nil
end

--- Scan doors in the NPC's cell for a military location (barracks, garrison, fort)
-- within SCAN_RANGE_DOORS of the NPC's position.
-- @param npc  Actor object
-- @return dest table, or nil if no valid door found
function DestinationResolver.findMilitaryLocation(npc)
    local bestDoor     = nil
    local bestDestCell = nil
    local bestDist     = math.huge
    local allDoors, _ = getDoorsInCell(npc)

    for _, door in ipairs(allDoors) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        if not isTeleport then goto skipDoor end

        local dist = (door.position - npc.position):length()
        if dist > SCAN_RANGE_DOORS then goto skipDoor end

        local isLocked = false
        pcall(function() isLocked = types.Lockable.isLocked(door) end)
        if isLocked then goto skipDoor end

        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell or destCell.isExterior then goto skipDoor end

        local name = destCell.name or ""
        if Blacklist.isDestinationBlacklisted(name, "military") then goto skipDoor end
        if Blacklist.isMilitaryDestination(name) then
            if dist < bestDist then
                bestDist     = dist
                bestDoor     = door
                bestDestCell = destCell
            end
        end

        ::skipDoor::
    end

    if bestDoor then
        return buildDest(bestDoor, bestDestCell)
    end
    return nil
end

--- Find the door whose destination cell exactly matches targetCellName.
-- Used by JSONScheduleModule to resolve door data (inside pos/rot) for a
-- cell name taken directly from ScheduleData.json.
-- The NPC must be in a loaded exterior cell for door scanning to work.
-- @param npc            Actor object
-- @param targetCellName string  exact interior cell name (case-insensitive)
-- @return dest table, or nil if no matching door found
function DestinationResolver.findDoorByDestCell(npc, targetCellName)
    if not targetCellName or targetCellName == "" then return nil end
    local targetLower = targetCellName:lower()
    local allDoors = getDoorsInCell(npc)

    for _, door in ipairs(allDoors) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        if not isTeleport then goto skipDoor end

        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell or destCell.isExterior then goto skipDoor end

        if Blacklist.isDestinationBlacklisted(destCell.name or "", "exact") then goto skipDoor end
        if (destCell.name or ""):lower() == targetLower then
            local resolved = buildDest(door, destCell)
            cacheDest(resolved)
            return resolved
        end

        ::skipDoor::
    end
    -- Fallback: return a previously discovered door mapping for this interior.
    local cached = doorCacheByDestCell[targetLower]
    if cached then
        return cloneDest(cached)
    end
    return nil
end

--- Prime door cache with all teleport interior doors in npc's current cell.
-- Useful when schedule resolution happens in an interior and direct door scan
-- for a different target would otherwise fail.
function DestinationResolver.primeDoorCacheFromNpcCell(npc)
    if not npc then return end
    for _, door in ipairs(getDoorsInCell(npc)) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        if not isTeleport then goto skipDoor end

        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell or destCell.isExterior then goto skipDoor end

        if Blacklist.isDestinationBlacklisted(destCell.name or "", "cache") then goto skipDoor end
        cacheDest(buildDest(door, destCell))
        ::skipDoor::
    end
end

--- Scan doors in the NPC's cell for one whose destination cell matches the NPC's
-- own home using tokenized record-ID matching (GoHome logic).
-- @param npc       Actor object
-- @param recordId  string  the NPC's record ID (e.g. "arrille", "tr_m1_fasile")
-- @return dest table, or nil if no valid door found
function DestinationResolver.findPersonalHome(npc, recordId)
    if not recordId or recordId == "" then return nil end

    -- -------------------------------------------------------------------------
    -- Step 1: Tokenize the record ID
    -- -------------------------------------------------------------------------

    -- Strip leading mod prefixes
    local stripped = recordId:lower()
    stripped = stripped:gsub("^tr_m%d+_", "")
    stripped = stripped:gsub("^tr_", "")
    stripped = stripped:gsub("^pc_m%d+_", "")
    stripped = stripped:gsub("^pc_", "")
    stripped = stripped:gsub("^slf_", "")
    stripped = stripped:gsub("^ab_", "")

    local STOP_WORDS = {
        ["the"] = true, ["and"] = true, ["for"] = true, ["out"] = true,
        ["boy"] = true, ["guy"] = true, ["old"] = true, ["new"] = true
    }

    -- Split on '_' and '-', collect tokens of length >= 3
    local tokens = {}
    for tok in stripped:gmatch("[^_%-%s]+") do
        if #tok >= 3 and not STOP_WORDS[tok] then
            tokens[#tokens + 1] = tok
        end
    end

    local token1 = tokens[1]  -- may be nil if stripped was very short
    local token2 = tokens[2]  -- may be nil

    -- Exclusion patterns — prevents false positives such as the token "ian"
    -- (from "argonian") matching "Argonian Mission".
    local EXCLUSION_LIST = {
        "argonian mission",
        "temple",
        "guild",
        "barracks",
        "canton",
        "prison",
        "tomb",
        "cave",
        "ruin",
        "mine",
        "citadel",
    }

    -- -------------------------------------------------------------------------
    -- Step 2: Scan doors
    -- -------------------------------------------------------------------------

    local bestDoor     = nil
    local bestDestCell = nil
    local bestDist     = math.huge

    for _, door in ipairs(getDoorsInCell(npc)) do
        local dist = (door.position - npc.position):length()
        if dist <= SCAN_RANGE_DOORS then

            local ok, destCell = pcall(types.Door.destCell, door)
            if ok and destCell then

                if not destCell.isExterior then
                    local cellLower = destCell.name:lower()
                    if Blacklist.isDestinationBlacklisted(cellLower, "home") then goto nextDoor end

                    -- Check exclusion list first
                    local excluded = false
                    for _, excl in ipairs(EXCLUSION_LIST) do
                        if cellLower:find(excl, 1, true) then
                            excluded = true
                            break
                        end
                    end

                    if not excluded then
                        -- Match against the full stripped id, first token, or second token
                        local matched = false

                        if stripped ~= "" and cellLower:find(stripped, 1, true) then
                            matched = true
                        elseif token1 and cellLower:find(token1, 1, true) then
                            matched = true
                        elseif token2 and cellLower:find(token2, 1, true) then
                            matched = true
                        end

                        if matched and dist < bestDist then
                            bestDist     = dist
                            bestDoor     = door
                            bestDestCell = destCell
                        end
                    end
                end
            end
        end
        ::nextDoor::
    end

    if bestDoor then
        local d = buildDest(bestDoor, bestDestCell)
        d.isSafePlace = false
        return d
    end
    return nil
end

--- Find the nearest teleport door in the NPC's current interior cell that leads
-- to the exterior. Used by Relocator.dispatchSmooth / queueReturnSmooth to find
-- the door the NPC should walk to before being disabled.
-- Returns nil if the NPC is in an exterior cell, or no exterior-leading teleport
-- door is found.
-- @param npc  Actor object (global context)
-- @return doorPos (vector3 — position of the door in the NPC's current cell), or nil
function DestinationResolver.findExitDoor(npc)
    if not npc then return nil end

    -- Only relevant when the NPC is inside an interior cell.
    local isInterior = false
    pcall(function() isInterior = npc.cell ~= nil and not npc.cell.isExterior end)
    if not isInterior then return nil end

    local allDoors = getDoorsInCell(npc)
    local bestDoor = nil
    local bestDist = math.huge

    for _, door in ipairs(allDoors) do
        local isTeleport = false
        pcall(function() isTeleport = types.Door.isTeleport(door) end)
        if not isTeleport then goto skipDoor end

        -- Only consider doors that lead back to the exterior world.
        local ok, destCell = pcall(types.Door.destCell, door)
        if not ok or not destCell or not destCell.isExterior then goto skipDoor end

        local dist = (door.position - npc.position):length()
        if dist < bestDist then
            bestDist = dist
            bestDoor = door
        end

        ::skipDoor::
    end

    if bestDoor then
        local ok, dc = pcall(types.Door.destCell, bestDoor)
        if ok and dc then
            local data = buildDest(bestDoor, dc)
            return bestDoor.position, data.doorInsidePos, data.destCellName, bestDoor
        end
        return bestDoor.position, nil, nil, bestDoor
    end
    return nil
end

return DestinationResolver
