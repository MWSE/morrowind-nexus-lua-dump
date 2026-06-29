-- OccupancyTracker.lua
-- Reservation and grid-slot manager for the ProceduralChatter NPC Scheduling System.
-- Global script context.
--
-- Prevents too many NPCs from routing to the same interior cell (tavern/inn),
-- and assigns non-overlapping spawn positions inside interiors.
--
-- Dependencies:
--   scripts.ProceduralChatter.data.ScheduleConfig  (SAFE_PLACE_MAX_OCCUPANCY, GRID_SPACING)
--   openmw.util                                     (vector math)

local config = require("scripts.ProceduralChatter.data.ScheduleConfig")
local util   = require("openmw.util")

local SAFE_PLACE_MAX_OCCUPANCY = config.SAFE_PLACE_MAX_OCCUPANCY
local GRID_SPACING    = config.GRID_SPACING

-- reservations[cellName] = { [npcId] = slotIndex, count = number, nextSlot = number }
-- slotIndex is assigned at reservation time so that pre-reservations in shouldEngage
-- give each NPC a stable, unique grid position regardless of dispatch order.
local reservations = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Return the canonical key used for all cell lookups.
local function cellKey(name)
    return string.lower(name)
end

--- Return (or lazily create) the reservation table for a cell.
local function getEntry(key)
    if not reservations[key] then
        reservations[key] = { count = 0, nextSlot = 1 }
    end
    return reservations[key]
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

local OccupancyTracker = {}

--- Attempt to reserve a slot for npcId in destCellName.
-- Returns true on success, false if at SAFE_PLACE_MAX_OCCUPANCY.
-- Idempotent: reserving the same npcId twice is a no-op (returns true).
-- The slot index is assigned at reservation time and retrievable via getSlot().
function OccupancyTracker.reserve(destCellName, npcId)
    local key   = cellKey(destCellName)
    local entry = getEntry(key)

    -- Already reserved — idempotent success.
    if entry[npcId] then
        return true
    end

    -- At capacity — deny.
    if entry.count >= SAFE_PLACE_MAX_OCCUPANCY then
        return false
    end

    -- Assign a stable slot index at reservation time.
    entry[npcId]    = entry.nextSlot
    entry.nextSlot  = entry.nextSlot + 1
    entry.count     = entry.count + 1
    return true
end

--- Return the slot index assigned to npcId in destCellName (1-based).
-- Returns 1 as a safe fallback if no reservation exists.
function OccupancyTracker.getSlot(destCellName, npcId)
    local key   = cellKey(destCellName)
    local entry = reservations[key]
    if not entry then return 1 end
    local slot = entry[npcId]
    -- entry[npcId] is now a number (slot index), not a boolean
    if type(slot) == "number" then return slot end
    return 1
end

--- Release the reservation for npcId from destCellName.
-- Safe to call even if no reservation exists.
function OccupancyTracker.release(destCellName, npcId)
    local key   = cellKey(destCellName)
    local entry = reservations[key]

    if not entry then return end
    if not entry[npcId] then return end

    entry[npcId] = nil
    entry.count  = entry.count - 1

    -- Clean up empty entry to avoid unbounded table growth.
    if entry.count <= 0 then
        reservations[key] = nil
    end
end

--- Returns current reservation count for a cell.
function OccupancyTracker.count(destCellName)
    local key   = cellKey(destCellName)
    local entry = reservations[key]
    if not entry then return 0 end
    return entry.count
end

--- Returns true if cellName is at or above SAFE_PLACE_MAX_OCCUPANCY.
function OccupancyTracker.isFull(destCellName)
    return OccupancyTracker.count(destCellName) >= SAFE_PLACE_MAX_OCCUPANCY
end

--- Compute a grid spawn position for NPC index inside an interior.
--
-- doorInsidePos : util.vector3  — the door's interior-side position
-- doorInsideRot : rotation      — the door's rotation (used to derive forward vector)
-- index         : integer       — 1-based index (which NPC is this in the group)
--
-- Grid layout (4 columns, N rows):
--   col = ((index-1) % 4) - 1.5   (-1.5, -0.5, +0.5, +1.5)
--   row = math.floor((index-1) / 4)
--   offset = forward * (row * GRID_SPACING) + right * (col * GRID_SPACING)
--   result = doorInsidePos + offset + forward * GRID_SPACING
--
-- Wraps all vector ops in pcall; falls back to doorInsidePos on any error.
function OccupancyTracker.getGridSlot(destCellName, doorInsidePos, doorInsideRot, index)
    local ok, result = pcall(function()
        -- Derive forward vector from rotation applied to local Y axis.
        local localY   = util.vector3(0, 1, 0)
        local forward  = doorInsideRot * localY
        -- Normalize forward (guard against zero-length).
        local fLen = forward:length()
        if fLen > 0 then
            forward = forward / fLen
        else
            forward = util.vector3(0, 1, 0)
        end

        -- Derive right vector as cross(forward, worldUp), normalized.
        local worldUp = util.vector3(0, 0, 1)
        local right   = util.vector3(
            forward.y * worldUp.z - forward.z * worldUp.y,
            forward.z * worldUp.x - forward.x * worldUp.z,
            forward.x * worldUp.y - forward.y * worldUp.x
        )
        local rLen = right:length()
        if rLen > 0 then
            right = right / rLen
        else
            right = util.vector3(1, 0, 0)
        end

        -- Compute grid column and row from 1-based index.
        local idx = index - 1  -- 0-based
        local col = (idx % 4) - 1.5
        local row = math.floor(idx / 4)

        -- Build offset: one extra GRID_SPACING step forward to clear the doorway.
        local colOffset = right   * (col * GRID_SPACING)
        local rowOffset = forward * (row * GRID_SPACING)
        local doorStep  = forward * GRID_SPACING

        return doorInsidePos + doorStep + rowOffset + colOffset
    end)

    if ok then
        return result
    else
        -- Fallback: return the door position unchanged.
        return doorInsidePos
    end
end

--- Release ALL reservations for a cell (e.g. on cell change or morning reset).
function OccupancyTracker.releaseAll(destCellName)
    local key = cellKey(destCellName)
    reservations[key] = nil
end

--- Release all reservations for a specific NPC across all cells
-- (e.g. on assignment release or NPC death).
function OccupancyTracker.releaseNpc(npcId)
    for key, entry in pairs(reservations) do
        if entry[npcId] then
            entry[npcId] = nil
            entry.count  = entry.count - 1
            if entry.count <= 0 then
                reservations[key] = nil
            end
        end
    end
end

return OccupancyTracker
