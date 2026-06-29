-- FurnitureRegistry.lua
-- Universal slot registry for sittable/sleepable furniture.
-- Generalises SittingGlobal's assignedStools/pendingStools tables into a
-- shared registry that SittingGlobal (Phase 2) and SleepManager (Phase 3)
-- both write to.
--
-- Slot definitions are optional: beds and benches supply {pos, facing} pairs
-- upfront (computed from orientation raycasts); stools register with a plain
-- count and let the NPC-local script return the exact position via
-- PC_StoolCheckResult, filling pos/facing in later via claimSlot.
--
-- Key API:
--   register(obj, slotsOrCount)       register furniture; slotsOrCount may be
--                                     a number or a list of {pos,facing} defs
--   claimSlot(obj, npcId)             claim first free slot; returns slot table
--                                     or nil when full
--   fillSlot(obj, npcId, pos, facing) set position/facing on an already-claimed
--                                     slot (used by stool flow after raycast)
--   releaseSlot(obj, npcId)           free the slot held by npcId
--   isOccupied(obj)                   true if all slots are taken
--   isRegistered(obj)                 true if obj is in the registry
--   findByNpc(npcId)                  returns {obj, slot} for the NPC's current
--                                     furniture, or nil
--   scanCell(cell, filterFn)          collect all objects in cell passing filterFn
--   getOrientation(obj)               raycast long axis; returns axis,length,zLevel,width
--   unregister(obj)                   remove furniture (also called on stand/wake)
--   reset()                           wipe everything (cell change)

-- nearby is only available in NPC/player local scripts, not in global scripts.
-- Lazy-loaded inside getOrientation; all other registry functions work without it.
local util = require('openmw.util')

local FurnitureRegistry = {}

-- =============================================================================
-- Internal storage
-- =============================================================================
-- registry[objId] = {
--     obj      = <object>,
--     slots    = { [1] = { npcId=nil, pos=nil, facing=nil }, ... },
-- }
-- npcIndex[npcId] = { objId = ..., slotIndex = ... }   (reverse lookup)
local registry = {}
local npcIndex = {}

-- =============================================================================
-- Private helpers
-- =============================================================================

local function makeSlots(slotsOrCount)
    local slots = {}
    if type(slotsOrCount) == "number" then
        for i = 1, slotsOrCount do
            slots[i] = { npcId = nil, pos = nil, facing = nil, exitPos = nil, exitRot = nil }
        end
    elseif type(slotsOrCount) == "table" then
        for i, def in ipairs(slotsOrCount) do
            slots[i] = {
                npcId = nil,
                pos = def.pos,
                facing = def.facing,
                isOverride = def.isOverride,
                exitPos = nil,
                exitRot = nil,
                profileId = def.profileId,
                slotId = def.slotId,
                interactionType = def.interactionType,
                approachPos = def.approachPos,
                approachFacing = def.approachFacing,
                accessScore = def.accessScore,
                accessReason = def.accessReason,
                flags = def.flags,
                source = def.source,
            }
        end
    end
    return slots
end

local function objId(obj)
    -- Use the object's unique id string as key.
    local ok, id = pcall(function() return tostring(obj.id) end)
    return ok and id or nil
end

-- =============================================================================
-- Registration
-- =============================================================================

--- Register furniture with the registry.
-- @param obj          The world object (stool, bench, bed, …)
-- @param slotsOrCount number -> N empty slots; table -> list of {pos,facing} defs
function FurnitureRegistry.register(obj, slotsOrCount)
    local id = objId(obj)
    if not id then return end
    registry[id] = {
        obj   = obj,
        slots = makeSlots(slotsOrCount or 1),
    }
end

--- Remove furniture from the registry (releases any held NPC bindings).
function FurnitureRegistry.unregister(obj)
    local id = objId(obj)
    if not id then return end
    local entry = registry[id]
    if entry then
        for _, slot in ipairs(entry.slots) do
            if slot.npcId then npcIndex[slot.npcId] = nil end
        end
    end
    registry[id] = nil
end

--- Returns true if obj is currently registered.
function FurnitureRegistry.isRegistered(obj)
    local id = objId(obj)
    return id ~= nil and registry[id] ~= nil
end

-- =============================================================================
-- Slot management
-- =============================================================================

--- Index of the first unclaimed slot, or nil if full (does not reserve).
function FurnitureRegistry.peekFreeSlotIndex(obj)
    local id = objId(obj)
    if not id then return nil end
    local entry = registry[id]
    if not entry then return nil end
    for i, slot in ipairs(entry.slots) do
        if not slot.npcId then return i end
    end
    return nil
end

--- Claim the first free slot for npcId.
-- Returns the slot table {npcId, pos, facing, index} or nil if all slots are full.
function FurnitureRegistry.claimSlot(obj, npcId)
    local id = objId(obj)
    if not id then return nil end
    local entry = registry[id]
    if not entry then return nil end

    -- Release any existing claim this NPC holds on this furniture.
    FurnitureRegistry.releaseSlot(obj, npcId)

    for i, slot in ipairs(entry.slots) do
        if not slot.npcId then
            slot.npcId = npcId
            npcIndex[npcId] = { objId = id, slotIndex = i }
            return {
                npcId = npcId,
                pos = slot.pos,
                facing = slot.facing,
                index = i,
                isOverride = slot.isOverride,
                profileId = slot.profileId,
                slotId = slot.slotId,
                interactionType = slot.interactionType,
                approachPos = slot.approachPos,
                approachFacing = slot.approachFacing,
                accessScore = slot.accessScore,
                accessReason = slot.accessReason,
                flags = slot.flags,
                source = slot.source,
            }
        end
    end
    return nil  -- all slots occupied
end

--- Record the floor position the NPC was standing at just before snapping onto
--- this furniture.  Persists across releases so future deep-night assignments
--- can teleport directly with a known-safe exit position.
function FurnitureRegistry.recordExitPos(obj, npcId, pos, rot)
    local id = objId(obj)
    if not id then return end
    local entry = registry[id]
    if not entry then return end
    local ref = npcIndex[npcId]
    if not ref or ref.objId ~= id then return end
    local slot = entry.slots[ref.slotIndex]
    if slot then
        slot.exitPos = pos
        slot.exitRot = rot
    end
end

--- Returns exitPos, exitRot for the slot this NPC currently holds, or nil, nil.
function FurnitureRegistry.getExitPos(obj, npcId)
    local id = objId(obj)
    if not id then return nil, nil end
    local entry = registry[id]
    if not entry then return nil, nil end
    local ref = npcIndex[npcId]
    if not ref or ref.objId ~= id then return nil, nil end
    local slot = entry.slots[ref.slotIndex]
    if not slot then return nil, nil end
    return slot.exitPos, slot.exitRot
end

--- Returns the exitPos/exitRot stored on the first free slot of obj, regardless
--- of current occupancy.  Used by SleepManager before claimSlot is called.
function FurnitureRegistry.peekExitPos(obj)
    local id = objId(obj)
    if not id then return nil, nil end
    local entry = registry[id]
    if not entry then return nil, nil end
    for _, slot in ipairs(entry.slots) do
        if not slot.npcId and slot.exitPos then
            return slot.exitPos, slot.exitRot
        end
    end
    return nil, nil
end

--- After a stool raycast returns the real position/facing, store them on the
--- already-claimed slot so later callers (e.g. SleepManager) can read them.
function FurnitureRegistry.fillSlot(obj, npcId, pos, facing)
    local id = objId(obj)
    if not id then return end
    local entry = registry[id]
    if not entry then return end
    local ref = npcIndex[npcId]
    if not ref or ref.objId ~= id then return end
    local slot = entry.slots[ref.slotIndex]
    if slot then
        slot.pos    = pos
        slot.facing = facing
    end
end

--- Free the slot held by npcId on obj.
function FurnitureRegistry.releaseSlot(obj, npcId)
    local id = objId(obj)
    if not id then return end
    local entry = registry[id]
    if not entry then return end
    local ref = npcIndex[npcId]
    if not ref or ref.objId ~= id then return end
    local slot = entry.slots[ref.slotIndex]
    if slot then
        slot.npcId = nil
        -- Preserve pos/facing for override slots — their positions are fixed and
        -- must survive release so re-assignment on a later night still works.
        if not slot.isOverride then
            slot.pos    = nil
            slot.facing = nil
        end
        -- exitPos/exitRot always survive release — they're a permanent record of a
        -- known-safe floor position beside this bed, learned on first walk-snap.
    end
    npcIndex[npcId] = nil
end

--- Release whatever furniture npcId is currently using (furniture-agnostic).
function FurnitureRegistry.releaseByNpc(npcId)
    local ref = npcIndex[npcId]
    if not ref then return end
    local entry = registry[ref.objId]
    if entry then
        local slot = entry.slots[ref.slotIndex]
        if slot then
            slot.npcId = nil
            if not slot.isOverride then
                slot.pos    = nil
                slot.facing = nil
            end
        end
    end
    npcIndex[npcId] = nil
end

--- Returns true if all slots on obj are occupied.
function FurnitureRegistry.isOccupied(obj)
    local id = objId(obj)
    if not id then return true end
    local entry = registry[id]
    if not entry then return true end
    for _, slot in ipairs(entry.slots) do
        if not slot.npcId then return false end
    end
    return true
end

--- Returns the number of free slots remaining on obj.
function FurnitureRegistry.freeSlots(obj)
    local id = objId(obj)
    if not id then return 0 end
    local entry = registry[id]
    if not entry then return 0 end
    local count = 0
    for _, slot in ipairs(entry.slots) do
        if not slot.npcId then count = count + 1 end
    end
    return count
end

--- Returns {obj, slot} for the furniture npcId currently holds, or nil.
function FurnitureRegistry.findByNpc(npcId)
    local ref = npcIndex[npcId]
    if not ref then return nil end
    local entry = registry[ref.objId]
    if not entry then return nil end
    local slot = entry.slots[ref.slotIndex]
    return { obj = entry.obj, slot = slot }
end

-- =============================================================================
-- Cell scanning
-- =============================================================================

--- Collect all objects in `cell` that pass `filterFn(obj) -> bool`.
-- @param cell      A cell object (e.g. world.getCellByName or self.cell)
-- @param filterFn  Predicate; receives each object, returns true to include it
-- @return table    Array of matching objects
function FurnitureRegistry.scanCell(cell, filterFn)
    local results = {}
    if not cell then return results end
    local ok, objs = pcall(function() return cell:getAll() end)
    if not ok or not objs then return results end
    for _, obj in ipairs(objs) do
        local pass = false
        local pok = pcall(function() pass = filterFn(obj) end)
        if pok and pass then
            table.insert(results, obj)
        end
    end
    return results
end

-- =============================================================================
-- Orientation raycasting  (extracted from SittingLogic.determineBenchOrientationAndLength)
-- =============================================================================

--- Raycast the long axis of a furniture piece.
-- Casts a grid of vertical rays along X and Y to find which axis the mesh
-- occupies more.  Also measures approximate width on the short axis so
-- callers (SleepManager) can decide how many slots a bed supports.
--
-- @param obj   World object
-- @return axis ("x"|"y"), length, zLevel, width
--         axis   = the *long* axis of the furniture
--         length = extent along the long axis (units)
--         zLevel = surface height found by the raycasts
--         width  = extent along the short axis
function FurnitureRegistry.getOrientation(obj)
    -- nearby is unavailable in global script context; return a neutral default so
    -- registration still succeeds.  SleepLogic (local context) provides the real
    -- surface position via PC_BedCheckResult.hitPos.
    local nearby
    pcall(function() nearby = require('openmw.nearby') end)
    if not nearby then
        return "y", 100, obj.position.z, 50
    end

    local center = obj.position
    local xHits, yHits = 0, 0
    local xLength, yLength = 0, 0
    local zLevel = center.z

    -- Cast 11 vertical rays at 10-unit intervals along each axis.
    for i = -5, 5 do
        local xFrom = center + util.vector3(i * 10, 0, 100)
        local xTo   = center + util.vector3(i * 10, 0, 0)
        local xRes  = nearby.castRay(xFrom, xTo, { collisionType = nearby.COLLISION_TYPE.World })
        if xRes.hit and xRes.hitObject == obj then
            xHits   = xHits + 1
            xLength = xLength + 10
            zLevel  = xRes.hitPos.z
        end

        local yFrom = center + util.vector3(0, i * 10, 100)
        local yTo   = center + util.vector3(0, i * 10, 0)
        local yRes  = nearby.castRay(yFrom, yTo, { collisionType = nearby.COLLISION_TYPE.World })
        if yRes.hit and yRes.hitObject == obj then
            yHits   = yHits + 1
            yLength = yLength + 10
            zLevel  = yRes.hitPos.z
        end
    end

    local axis, length, width
    if xHits >= yHits then
        axis   = "x"
        length = math.max(xLength, 10)
        width  = math.max(yLength, 10)
    else
        axis   = "y"
        length = math.max(yLength, 10)
        width  = math.max(xLength, 10)
    end

    return axis, length, zLevel, width
end

--- Compute evenly-spaced slot positions along the long axis of a furniture
--- piece.  Convenience wrapper used by SleepManager when assigning bed slots.
--
-- @param obj      World object
-- @param count    Number of slots to generate (1 or 2)
-- @return table   Array of util.vector3 positions
function FurnitureRegistry.getSlotPositions(obj, count)
    local axis, length, zLevel = FurnitureRegistry.getOrientation(obj)
    local center  = obj.position
    local half    = length / 2
    count = count or 1

    if count == 1 then
        return { util.vector3(center.x, center.y, zLevel) }
    end

    -- Two slots: offset ±half/2 along the long axis.
    local offset = half / 2
    if axis == "x" then
        return {
            util.vector3(center.x - offset, center.y, zLevel),
            util.vector3(center.x + offset, center.y, zLevel),
        }
    else
        return {
            util.vector3(center.x, center.y - offset, zLevel),
            util.vector3(center.x, center.y + offset, zLevel),
        }
    end
end

-- =============================================================================
-- Bulk helpers
-- =============================================================================

--- Remove all registry entries whose object IDs are not in liveIds.
-- @param liveIds  Set table: { [objId string] = true }
function FurnitureRegistry.flush(liveIds)
    for id, entry in pairs(registry) do
        if not liveIds[id] then
            for _, slot in ipairs(entry.slots) do
                if slot.npcId then npcIndex[slot.npcId] = nil end
            end
            registry[id] = nil
        end
    end
end

--- Wipe all state (e.g. on full cell change).
function FurnitureRegistry.reset()
    registry = {}
    npcIndex = {}
end

return FurnitureRegistry
