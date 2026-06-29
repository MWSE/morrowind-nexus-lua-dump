-- Relocator.lua  (Phase 1 — Disable/Enable Queuing)
-- Transport engine for the ProceduralChatter NPC Scheduling System.
-- Global script context.
--
-- Phase 1: no walking.  dispatch() immediately disables the NPC in the exterior
-- and queues them in graceTable.  When the player enters the destination cell,
-- onPlayerEnteredCell() enables and teleports each matching NPC into their slot.
-- clearAll() drops all queued state on cell change.
--
-- The walk path (pendingWalkers, schedule_npc.lua, PC_ScheduleWalkTo) has been
-- removed.  The original full implementation is backed up as Relocator.lua.bak.
--
-- Called by:
--   Scheduler.tick()     -> Relocator.dispatch(npc, dest, moduleName)
--   global.lua onUpdate  -> Relocator.onUpdate(dt)
--   global.lua events    -> Relocator.onPlayerEnteredCell(cellName, prevCellName, isExterior)
--                        -> Relocator.clearAll()

local core    = require('openmw.core')
local world   = require('openmw.world')
local types   = require('openmw.types')
local util    = require('openmw.util')
local nearby  = nil
pcall(function() nearby = require('openmw.nearby') end)

local Config           = require('scripts.ProceduralChatter.data.ScheduleConfig')
local NPCState         = require('scripts.ProceduralChatter.NPCState')
local OccupancyTracker = require('scripts.ProceduralChatter.schedule.OccupancyTracker')
local SittingGlobal    = require('scripts.ProceduralChatter.SittingGlobal')
-- Scheduler is required lazily inside functions to avoid circular dependency.

local Relocator = {}

-- =============================================================================
-- Internal state
-- =============================================================================

-- graceTable[npcId] = {
--   npc        = object,
--   dest       = dest_table,   -- full dest from DestinationResolver / module
--   moduleName = string,
--   slotIndex  = number,       -- which OccupancyTracker grid slot this NPC owns
-- }
-- Phase 1: no graceExpiry — NPCs stay queued until the player enters their cell
-- or clearAll() is called.
local graceTable = {}
local pendingNavmeshRequests = {} -- [requestId] = { npcId, entry, slotPos }
local navmeshRequestSeq = 0

-- activeDepartures[npcId] = {
--   npc        = object,
--   mode       = "dispatch" | "queueReturn",
--   timeout    = number,  (seconds remaining)
--   -- for "dispatch":
--   dest       = dest_table,
--   moduleName = string,
--   slotIndex  = number,
--   -- for "queueReturn":
--   cellName   = string,
--   pos        = vector3,
--   rot        = transform,
-- }
-- Populated by dispatchSmooth / queueReturnSmooth; consumed by onDepartureReachedDoor.
local activeDepartures = {}

-- arrivingNpcs[npcId] = { moduleName = string, targetPos = vector3?, createdAt = number? }
-- Populated when an NPC is spawned at a door for smooth arrival walk.
-- Consumed by onArrivalComplete, which fires Scheduler.onArrivedDoor.
local arrivingNpcs = {}

-- pendingArrivalWalks[npcId] = { npc = object, slotPos = vector3, moduleName = string, createdAt = number }
-- Populated by materialiseNpc for cross-cell teleports (interior->exterior return).
-- The NPC's local script restarts when it crosses cells, so PC_ArrivalWalk sent
-- immediately after teleport would be dropped.  onActorActive fires when the
-- new script instance is ready and delivers the event then.
local pendingArrivalWalks = {}
local pendingExteriorReturns = {}
local pendingInstantArrivals = {}

-- activeTransitions[npcId] = {
--   npc        = object,
--   targetPos  = vector3,      -- the entrance door of the NEXT interior
--   dest       = dest_table,   -- the destination interior for the NEXT shift
--   moduleName = string,
--   slotIndex  = number,
--   timeout    = number,
-- }
-- Tracks NPCs walking from one door to another in the exterior.
local activeTransitions = {}

local DEPARTURE_TIMEOUT  = 45  -- seconds before forced instant teleport (allows time for sit/sleep teardown)
local TRANSITION_TIMEOUT = 120 -- increased to allow for long cross-exterior walks
local ARRIVAL_TIMEOUT    = 60  -- seconds before forced completion of a door->slot/native walk
local ESTIMATED_WALK_SPEED = 230 -- units per second (roughly Speed 50 walk)
local TEARDOWN_BUFFER      = 5.0 -- buffer for sitting/sleeping NPCs to get ready
local PENDING_HANDOFF_TIMEOUT = 10.0 -- seconds to wait for onActorActive after a successful cross-cell teleport
local NATIVE_PLACEMENT_DIST   = 192  -- door→native walk/teleport if farther than this from target

local DEBUG = Config.DEBUG_MODE

local function dbg(msg)
    if DEBUG then print("[Relocator] " .. tostring(msg)) end
end

local function nowSeconds()
    local ok, now = pcall(core.getSimulationTime)
    if ok and now then return now end
    return 0
end

-- =============================================================================
-- Helpers
-- =============================================================================

--- Estimate the walk duration in seconds from current NPC position to destination.
local function estimateWalkTime(npc, dest, finalPos)
    if not npc or not dest then return 0 end
    local totalDist = 0
    local currentPos = npc.position
    local npcIsInterior = (npc.cell ~= nil and not npc.cell.isExterior)

    if npcIsInterior then
        -- Step 1: Distance to exit door inside current cell
        local DestRes = nil
        pcall(function() DestRes = require("scripts.ProceduralChatter.schedule.DestinationResolver") end)
        if DestRes then
            local doorPos = nil
            pcall(function() doorPos = DestRes.findExitDoor(npc) end)
            if doorPos then
                totalDist = totalDist + (currentPos - doorPos):length()
            end
        end
    end

    -- Step 2: Exterior movement (if applicable)
    local isTransition = (npcIsInterior and dest.doorExteriorPos ~= nil)
    local isExteriorReturn = (not npcIsInterior and dest.isReturn)
    
    if isTransition then
        -- Interior A -> Exterior -> Interior B
        local DestRes = nil
        pcall(function() DestRes = require("scripts.ProceduralChatter.schedule.DestinationResolver") end)
        if DestRes then
            local _, extDoorPos = nil, nil
            pcall(function() _, extDoorPos = DestRes.findExitDoor(npc) end)
            if extDoorPos then
                totalDist = totalDist + (extDoorPos - dest.doorExteriorPos):length()
            end
        end
    elseif isExteriorReturn then
        -- Exterior -> Origin Location
        totalDist = totalDist + (currentPos - finalPos):length()
    elseif not npcIsInterior and dest.doorExteriorPos then
        -- Exterior -> Interior Entrance
        totalDist = totalDist + (currentPos - dest.doorExteriorPos):length()
    end

    -- Step 3: Destination interior walk (if interior)
    if dest.doorInsidePos and finalPos then
        totalDist = totalDist + (dest.doorInsidePos - finalPos):length()
    end

    local time = totalDist / ESTIMATED_WALK_SPEED
    if npcIsInterior then time = time + TEARDOWN_BUFFER end
    
    return math.max(0, time)
end

local function setReturnCooldown(npcId, seconds)
    NPCState.setArrivalCooldown(npcId, math.max(5.0, seconds or 0))
end

local function getScheduler()
    local ok, result = pcall(require, "scripts.ProceduralChatter.schedule.Scheduler")
    if ok then return result end
    dbg("Could not require Scheduler: " .. tostring(result))
    return nil
end

--- Safely set npc.enabled; returns true on success.
local function safeSetEnabled(npc, value)
    local ok, err = pcall(function() npc.enabled = value end)
    if not ok then
        dbg("safeSetEnabled error for npc=" .. tostring(npc.id) .. ": " .. tostring(err))
    end
    return ok
end

--- Safely teleport an NPC; returns true on success.
--- Retries once if the NPC is still locked by another teleport.
local function safeTeleport(npc, cellName, pos, opts)
    pcall(function()
        npc:sendEvent("PC_ClearMovementState", { preserveSchedule = true })
    end)
    pcall(function()
        core.sendGlobalEvent("PC_SetBusy", { npc = npc, npcId = npc.id, busy = false })
    end)
    pcall(function() npc:sendEvent("PC_Stop", {}) end)
    local ok, err = pcall(function() npc:teleport(cellName, pos, opts) end)
    if not ok then
        local errStr = tostring(err)
        dbg("safeTeleport error for npc=" .. tostring(npc.id) .. ": " .. errStr)
        -- Retry once if another system (e.g. SittingGlobal) had a teleport in flight
        if errStr:lower():find("already in the process of teleporting") then
            dbg("safeTeleport retrying npc=" .. tostring(npc.id))
            ok, err = pcall(function() npc:teleport(cellName, pos, opts) end)
            if not ok then
                dbg("safeTeleport retry failed for npc=" .. tostring(npc.id) .. ": " .. tostring(err))
            end
        end
    end
    return ok
end

--- Best-effort navmesh snap for interior spawn targets.
-- Returns the original position when navmesh query fails.
-- Z radius is kept tight (128) so we don't snap to a different floor.
local function snapToNavMesh(pos)
    if not pos then return pos end
    if not nearby then return pos end
    local snapped = nil
    pcall(function()
        snapped = nearby.findNearestNavMeshPosition(pos, {
            searchAreaHalfExtents = util.vector3(1500, 1500, 128),
        })
    end)
    return snapped or pos
end

local function nextNavmeshRequestId(npcId)
    navmeshRequestSeq = navmeshRequestSeq + 1
    return string.format("%s:%d", tostring(npcId), navmeshRequestSeq)
end

local function cancelPendingNavmeshForNpc(npcId)
    if not npcId then return end
    for reqId, req in pairs(pendingNavmeshRequests) do
        if req and req.npcId == npcId then
            pendingNavmeshRequests[reqId] = nil
        end
    end
end

local function playerIsInCell(cellName)
    local ok, playerCellName = pcall(function()
        local player = world.players[1]
        return player and player.cell and player.cell.name or ""
    end)
    return ok
        and playerCellName ~= ""
        and cellName
        and string.lower(playerCellName) == string.lower(cellName)
end

--- Check whether an NPC object is still valid (not garbage-collected or unloaded).
local function isValidNpc(npc)
    if not npc then return false end
    local ok = pcall(function() local _ = npc.id end)
    return ok
end

local doorSoundCooldowns = {}

local function playDoorSound(door)
    if not Config.ENABLE_DOOR_SOUNDS then return end
    if not door then return end
    local ok = pcall(function() local _ = door.id end)
    if not ok then return end

    local doorId = door.id
    if doorSoundCooldowns[doorId] then return end

    local doorRec = nil
    pcall(function() doorRec = types.Door.record(door) end)
    if not (doorRec and doorRec.openSound and doorRec.openSound ~= '') then return end

    pcall(function() core.sound.playSound3d(doorRec.openSound, door) end)
    doorSoundCooldowns[doorId] = true

    local async = require('openmw.async')
    async:newUnsavableSimulationTimer(Config.DOOR_SOUND_COOLDOWN, function()
        doorSoundCooldowns[doorId] = nil
    end)

    dbg(string.format("Door sound '%s' played for door: %s", doorRec.openSound, tostring(doorId)))
end

local function findDoorNearPos(cell, pos)
    if not cell or not pos then return nil end
    local ok, all = pcall(function() return cell:getAll() end)
    if not ok or not all then return nil end

    local bestDoor = nil
    local bestDist = 200 -- Only doors within 200 units
    for _, obj in ipairs(all) do
        local isDoor = false
        pcall(function() isDoor = types.Door.objectIsInstance(obj) end)
        if isDoor then
            local dist = (obj.position - pos):length()
            if dist < bestDist then
                bestDist = dist
                bestDoor = obj
            end
        end
    end
    return bestDoor
end

local function isExteriorReturnCell(cellName, exteriorCellName)
    if not cellName or cellName == "" then return true end
    if exteriorCellName and exteriorCellName ~= "" then
        return string.lower(cellName) == string.lower(exteriorCellName)
    end
    return false
end

-- Best-effort refresh of a stale NPC object reference by runtime id.
-- Searches active actors first, then all loaded cells (catches disabled NPCs
-- whose cell is still loaded but who are excluded from activeActors).
local function findNpcById(npcId)
    if not npcId then return nil end

    -- 1. Active actors (enabled NPCs in loaded cells)
    local ok, actors = pcall(function() return world.activeActors end)
    if ok and actors then
        for _, actor in ipairs(actors) do
            local same = false
            pcall(function() same = (actor.id == npcId) end)
            if same then
                local isNpc = false
                pcall(function() isNpc = types.NPC.objectIsInstance(actor) end)
                if isNpc then
                    print(string.format("[Relocator] findNpcById npc=%s FOUND in activeActors", tostring(npcId)))
                    return actor
                end
            end
        end
    end

    -- 2. All loaded cells (disabled NPCs are in cell:getAll but not activeActors)
    local ok2, cells = pcall(function() return world.cells end)
    if ok2 and cells then
        for _, cell in ipairs(cells) do
            local ok3, npcs = pcall(function() return cell:getAll(types.NPC) end)
            if ok3 and npcs then
                for _, npc in ipairs(npcs) do
                    local same = false
                    pcall(function() same = (npc.id == npcId) end)
                    if same then
                        local isNpc = false
                        pcall(function() isNpc = types.NPC.objectIsInstance(npc) end)
                        if isNpc then
                            local cellName = ""
                            pcall(function() cellName = npc.cell and npc.cell.name or "?" end)
                            print(string.format("[Relocator] findNpcById npc=%s FOUND in cell='%s' enabled=%s",
                                tostring(npcId), cellName, tostring(npc.enabled)))
                            return npc
                        end
                    end
                end
            end
        end
    end

    print(string.format("[Relocator] findNpcById npc=%s NOT FOUND", tostring(npcId)))
    return nil
end

local function deliverPendingArrivalWalk(npcId, actor, reason)
    local pending = pendingArrivalWalks[npcId]
    if not pending then return false end
    actor = actor or findNpcById(npcId) or pending.npc
    if not isValidNpc(actor) then return false end

    local ok = pcall(function()
        actor:sendEvent("PC_ArrivalWalk", { slotPos = pending.slotPos })
    end)
    if not ok then return false end

    pendingArrivalWalks[npcId] = nil
    arrivingNpcs[npcId] = {
        moduleName = pending.moduleName,
        targetPos  = pending.slotPos,
        createdAt  = nowSeconds(),
    }
    print(string.format("[Relocator] delivered pending arrival walk npc=%s reason=%s slotPos=%s",
        tostring(npcId), tostring(reason or "unknown"), tostring(pending.slotPos)))
    return true
end

local function finalizeInstantArrival(npcId, actor, pending)
    if not pending then return false end
    actor = actor or findNpcById(npcId)
    if not isValidNpc(actor) then return false end

    local enabled = safeSetEnabled(actor, true)
    if not enabled then return false end

    pendingInstantArrivals[npcId] = nil
    local Scheduler = getScheduler()
    if Scheduler then
        if pending.moduleName and pending.dest and Scheduler.getAssignment
                and not Scheduler.getAssignment(npcId)
                and Scheduler.registerAssignment then
            Scheduler.registerAssignment(npcId, pending.moduleName, pending.dest, actor)
        end
        Scheduler.onArrivedDoor({ npc = actor, moduleName = pending.moduleName })
    end
    print(string.format("[Relocator] finalized instant arrival npc=%s", tostring(npcId)))
    return true
end

--- If the NPC is currently in an interior cell, teleport them to their origin
-- exterior position before disabling.  The exterior is always loaded so the
-- object reference stays valid after the interior cell unloads.
-- No-op if NPC is already in the exterior or origin data is unavailable.
-- Returns true if the NPC is now in the exterior (or was already there).
local function anchorToExterior(npc)
    local isInterior = false
    pcall(function()
        isInterior = npc.cell ~= nil and not npc.cell.isExterior
    end)
    if not isInterior then return true end

    local NPCStateM = require("scripts.ProceduralChatter.NPCState")
    local originCell, originPos, originRot = NPCStateM.loadNativeHome(npc)
    if originCell and originCell ~= "" and originPos then
        local tpOk = safeTeleport(npc, originCell, originPos, { rotation = originRot })
        if tpOk then
            print(string.format("[Relocator] anchorToExterior: moved npc=%s to exterior cell='%s'",
                tostring(npc.id), originCell))
            return true
        else
            print(string.format("[Relocator] anchorToExterior: TELEPORT FAILED npc=%s; trying refresh", tostring(npc.id)))
            -- Teleport may have failed due to handle staleness after a previous teleport.
            -- Try to refresh the handle and teleport once more.
            local refreshed = findNpcById(npc.id)
            if refreshed then
                tpOk = safeTeleport(refreshed, originCell, originPos, { rotation = originRot })
                if tpOk then
                    print(string.format("[Relocator] anchorToExterior: refresh teleport OK npc=%s", tostring(npc.id)))
                    return true
                end
            end
            print(string.format("[Relocator] anchorToExterior: ABORT npc=%s still in interior after retry", tostring(npc.id)))
            return false
        end
    else
        print(string.format("[Relocator] anchorToExterior: no origin data npc=%s", tostring(npc.id)))
        return false
    end
end

-- Clear any sitting ownership/animation immediately before relocation.
-- Uses direct module call to avoid event ordering races where the NPC gets
-- disabled before global seat-cancel events are processed.
local function clearSittingForRelocation(npc, reason)
    if not npc then return end
    pcall(function() npc:sendEvent("PC_CancelTravelToSeat", {}) end)
    -- Synchronous release to stop SittingGlobal's per-frame seat teleport.
    -- Keep the local sitting state intact here; PC_PrepareForDeparture owns the
    -- local stand-up request and waits for PC_StandUpFinished before door travel.
    if SittingGlobal.forceStandForDeparture then
        pcall(function() SittingGlobal.forceStandForDeparture(npc.id) end)
    else
        pcall(function() SittingGlobal.forceRelease(npc.id) end)
    end
end

local function clearArrivalHandoffState(npcId, npc, reason)
    if not npcId then return end
    if arrivingNpcs[npcId] or pendingArrivalWalks[npcId] or pendingExteriorReturns[npcId]
            or pendingInstantArrivals[npcId] then
        print(string.format("[Relocator] clearing arrival handoff npc=%s reason=%s",
            tostring(npcId), tostring(reason or "unknown")))
    end
    arrivingNpcs[npcId] = nil
    pendingArrivalWalks[npcId] = nil
    pendingExteriorReturns[npcId] = nil
    pendingInstantArrivals[npcId] = nil

    local state = NPCState.get(npcId)
    if state == "arriving" or state == "returning" or state == "transitioning"
            or state == "traveling_home" then
        NPCState.clear(npcId)
    end

    if isValidNpc(npc) then
        pcall(function() npc:sendEvent("PC_DepartureAbort", { reason = reason or "schedule_override" }) end)
    end
end

-- =============================================================================
-- finishScheduleArrival — clear transit state (local; used by materialiseNpc)
-- =============================================================================

local function finishScheduleArrival(npcId, npc, opts)
    if not npcId then return end
    arrivingNpcs[npcId] = nil
    pendingArrivalWalks[npcId] = nil
    pendingExteriorReturns[npcId] = nil
    setReturnCooldown(npcId, 5.0)

    local s = NPCState.get(npcId)
    if s == "arriving" or s == "departing" or s == "transitioning"
            or s == "returning" or s == "traveling_to_destination"
            or s == "traveling_home" then
        NPCState.clear(npcId)
    end

    if opts and opts.startWander and isValidNpc(npc) and not NPCState.isHostile(npcId) then
        pcall(function() npc:sendEvent("PC_StartWander", {}) end)
    end
end

Relocator.finishScheduleArrival = finishScheduleArrival

-- =============================================================================
-- materialiseNpc — shared finalise helper (Phase B: smooth arrivals)
-- =============================================================================

--- Teleport, enable, and either send PC_ArrivalWalk (smooth) or fire
-- Scheduler.onArrivedDoor immediately (instant fallback / isReturn path).
-- Used by both onPlayerEnteredCell and onNavmeshSnapResolved so the logic
-- is never duplicated.
--
-- @param npc      object   — the NPC actor
-- @param npcId    any      — npc.id
-- @param entry    table    — graceTable entry
-- @param finalPos vector3  — target grid-slot position (or exact return pos)
local function materialiseNpc(npc, npcId, entry, finalPos)
    print(string.format("[Relocator] materialiseNpc START npc=%s finalPos=%s destCell='%s'",
        tostring(npcId), tostring(finalPos), tostring(entry.dest.destCellName)))

    -- Phase B: normal scheduled admits materialize directly at their reserved
    -- slot, then JSONScheduleModule.onArrived lets PostArrivalCoordinator choose
    -- sleep/sit/wander. PC_ArrivalWalk is reserved for visible return-to-origin
    -- walks from an exterior doorway back to the native spot.
    local useSmoothArrival = false
    local spawnPos = finalPos

    if entry.dest.doorInsidePos and not entry.dest.isReturn then
        spawnPos = finalPos
        useSmoothArrival = false
    elseif entry.dest.isReturn and entry.dest.doorExteriorPos then
        -- Return to exterior origin: spawn at the exterior side of the doorway
        spawnPos = entry.dest.doorExteriorPos
        useSmoothArrival = true
    end

    local destCell = entry.dest.destCellName
    local teleportCell = destCell
    if entry.dest.isReturn and entry.dest.exterior then
        teleportCell = ""
    end
    print(string.format("[Relocator] materialiseNpc spawnPos=%s useSmoothArrival=%s isReturn=%s npc=%s",
        tostring(spawnPos), tostring(useSmoothArrival), tostring(entry.dest.isReturn or false), tostring(npcId)))

    -- Enable first, then teleport. When a disabled NPC is teleported across cell
    -- types (interior -> exterior) in OpenMW, the engine invalidates the object
    -- handle during the same frame, making a subsequent safeSetEnabled fail with
    -- "Object is removed". Enabling the actor first keeps the handle valid.
    local enOk = safeSetEnabled(npc, true)
    print(string.format("[Relocator] materialiseNpc first enable=%s npc=%s", tostring(enOk), tostring(npcId)))
    if not enOk then
        -- Stale handle: re-acquire by id and retry enable once before giving up.
        local refreshed = findNpcById(npcId)
        if refreshed then
            entry.npc = refreshed
            npc = refreshed
            enOk = safeSetEnabled(npc, true)
            print(string.format("[Relocator] materialiseNpc refreshed enable=%s npc=%s", tostring(enOk), tostring(npcId)))
        else
            print(string.format("[Relocator] materialiseNpc enable FAIL, no refresh found npc=%s", tostring(npcId)))
        end
    end

    local tpOk = false
    if enOk then
        -- Refresh handle after enable: cross-cell enable can invalidate the object
        -- reference, especially interior -> exterior transitions.
        local refreshed = findNpcById(npcId)
        if refreshed then
            npc = refreshed
            entry.npc = refreshed
        end
        tpOk = safeTeleport(npc, teleportCell, spawnPos, {
            rotation = entry.dest.doorInsideRot,
        })
        if tpOk then
            -- Teleport can invalidate the handle or leave the refreshed cell copy
            -- disabled. For normal admits, require an enabled final reference.
            -- Return teleports can finish later when the actor becomes active.
            refreshed = findNpcById(npcId)
            if refreshed then
                npc = refreshed
                entry.npc = refreshed
                local postEnableOk = safeSetEnabled(npc, true)
                print(string.format("[Relocator] materialiseNpc post-teleport enable=%s npc=%s",
                    tostring(postEnableOk), tostring(npcId)))
                if not postEnableOk then
                    if entry.dest.isReturn then
                        if not useSmoothArrival then pendingExteriorReturns[npcId] = { createdAt = nowSeconds() } end
                    else
                        pendingInstantArrivals[npcId] = {
                            moduleName = entry.moduleName,
                            dest       = entry.dest,
                            createdAt  = nowSeconds(),
                        }
                    end
                    print(string.format("[Relocator] materialiseNpc post-teleport enable pending npc=%s",
                        tostring(npcId)))
                end
            elseif entry.dest.isReturn then
                -- Cross-cell returns can restart the local script and make the
                -- new handle unavailable until onActorActive.
                if not useSmoothArrival then pendingExteriorReturns[npcId] = { createdAt = nowSeconds() } end
                print(string.format("[Relocator] materialiseNpc post-teleport handle pending npc=%s",
                    tostring(npcId)))
            else
                -- Interior admits hit the same handle gap: OpenMW accepts the
                -- teleport, reloads npc.lua, then exposes the actor shortly
                -- after. Finish the schedule arrival from onActorActive.
                pendingInstantArrivals[npcId] = {
                    moduleName = entry.moduleName,
                    dest       = entry.dest,
                    createdAt  = nowSeconds(),
                }
                print(string.format("[Relocator] materialiseNpc post-teleport handle pending npc=%s",
                    tostring(npcId)))
            end
        end
        print(string.format("[Relocator] materialiseNpc teleport ok=%s npc=%s", tostring(tpOk), tostring(npcId)))
    else
        print(string.format("[Relocator] materialiseNpc teleport SKIPPED (enable failed) npc=%s", tostring(npcId)))
    end

    print(string.format("[Relocator] materialise npc=%s cell='%s' spawnPos=%s enable=%s tp=%s smooth=%s return=%s",
        tostring(npcId), tostring(destCell), tostring(spawnPos),
        tostring(enOk), tostring(tpOk), tostring(useSmoothArrival),
        tostring(entry.dest.isReturn or false)))

    if not enOk or not tpOk then
        -- Keep queued so a later reconcile/cell event can retry.
        print(string.format("[Relocator] materialiseNpc INCOMPLETE npc=%s en=%s tp=%s; keeping queued", tostring(npcId), tostring(enOk), tostring(tpOk)))
        if not entry.dest.isReturn then
            OccupancyTracker.release(entry.dest.destCellName, npcId)
        end
        -- Disable again so the NPC doesn't ghost in their current cell.
        if enOk and not tpOk then
            safeSetEnabled(npc, false)
        end
        return false
    end

    if tpOk then
        pcall(function()
            local searchPos = entry.dest.doorInsidePos or spawnPos
            local arriveDoor = findDoorNearPos(npc.cell, searchPos)
            if arriveDoor then
                playDoorSound(arriveDoor)
            end
        end)

        if not entry.dest.isReturn then
            if useSmoothArrival then
                -- NPC appears at the door; walk them to their target position.
                arrivingNpcs[npcId] = {
                    moduleName = entry.moduleName,
                    targetPos  = finalPos,
                    createdAt  = nowSeconds(),
                }
                local evOk = pcall(function()
                    npc:sendEvent("PC_ArrivalWalk", { slotPos = finalPos })
                end)
                print(string.format("[Relocator] materialiseNpc sent PC_ArrivalWalk ok=%s npc=%s", tostring(evOk), tostring(npcId)))
            elseif pendingInstantArrivals[npcId] then
                print(string.format("[Relocator] materialiseNpc queued pending instant arrival npc=%s", tostring(npcId)))
            else
                -- No door data — old instant-notify path.
                print(string.format("[Relocator] materialiseNpc instant notify npc=%s", tostring(npcId)))
                local Scheduler = getScheduler()
                if Scheduler then
                    Scheduler.onArrivedDoor({ npc = npc, moduleName = entry.moduleName })
                end
            end
        else
            -- Origin return
            if useSmoothArrival then
                -- NPC has been teleported from an interior to the exterior door.
                -- Their local script restarts when the new cell loads (can take
                -- hundreds of ms).  Sending PC_ArrivalWalk now would target the
                -- old (being-torn-down) script instance and be dropped.
                -- Instead, queue the walk; onActorActive fires when the new
                -- script instance is ready and delivers the event safely.
                pendingArrivalWalks[npcId] = {
                    npc        = npc,
                    slotPos    = finalPos,
                    moduleName = "return_to_origin",
                    createdAt  = nowSeconds(),
                }
                print(string.format("[Relocator] materialiseNpc queued pendingArrivalWalks npc=%s", tostring(npcId)))
            else
                -- Instant return fallback (no door→home walk)
                print(string.format("[Relocator] materialiseNpc instant return wander npc=%s", tostring(npcId)))
                finishScheduleArrival(npcId, npc, { startWander = true })
            end
        end
    else
        -- Teleport failed; release occupancy slot if one was reserved.
        print(string.format("[Relocator] materialiseNpc teleport failed, releasing occupancy npc=%s", tostring(npcId)))
        if not entry.dest.isReturn then
            OccupancyTracker.release(entry.dest.destCellName, npcId)
        end
    end
    print(string.format("[Relocator] materialiseNpc SUCCESS npc=%s", tostring(npcId)))
    return true
end

-- =============================================================================
-- Public API
-- =============================================================================

--- Queue an NPC for deferred placement when the player enters their destination.
-- Immediately disables the NPC in the exterior (no walking).
-- They will be enabled and teleported to their grid slot by onPlayerEnteredCell.
--
-- Dest table shape (from DestinationResolver or module):
--   { destCellName, doorInsidePos?, doorInsideRot?, label? }
--
-- @param npc        object  — the NPC actor
-- @param dest       table   — dest table (must have destCellName)
-- @param moduleName string  — owning module id (for callbacks)
function Relocator.dispatch(npc, dest, moduleName)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not npc or not dest then
        print("[Relocator] dispatch ABORT nil npc or dest")
        return
    end

    local npcId = npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] dispatch SKIP hostile npc=%s", tostring(npcId)))
        return
    end
    local destCellLo = string.lower(dest.destCellName or "")
    print(string.format("[Relocator] dispatch START npc=%s dest='%s' module=%s",
        tostring(npcId), tostring(dest.destCellName), tostring(moduleName)))
    cancelPendingNavmeshForNpc(npcId)
    clearArrivalHandoffState(npcId, npc, "dispatch")
    setReturnCooldown(npcId, 10.0)

    -- Already in target cell: do not force relocation through exterior.
    -- This avoids teleport races ("already in process of teleporting") and
    -- preserve current local behavior (sit/sleep/etc.) for in-place admits.
    local alreadyInDest = false
    pcall(function()
        local npcCellName = string.lower(npc.cell and npc.cell.name or "")
        alreadyInDest = (destCellLo ~= "" and npcCellName == destCellLo)
    end)
    if alreadyInDest then
        print(string.format("[Relocator] dispatch alreadyInDest npc=%s; marking arrived in place", tostring(npcId)))
        local Scheduler = getScheduler()
        if Scheduler and Scheduler.registerAssignment then
            Scheduler.registerAssignment(npcId, moduleName, dest, npc)
            Scheduler.onArrivedDoor({ npc = npc, moduleName = moduleName })
        end
        return
    end

    -- -------------------------------------------------------------------------
    -- 1. Reserve occupancy slot
    --    Modules pre-reserve in shouldEngage (idempotent); this confirms.
    -- -------------------------------------------------------------------------
    local reserved = OccupancyTracker.reserve(dest.destCellName, npcId)
    if not reserved then
        print(string.format("[Relocator] dispatch ABORT occupancy full cell='%s' npc=%s",
            tostring(dest.destCellName), tostring(npcId)))
        local Scheduler = getScheduler()
        if Scheduler then Scheduler.releaseAssignment(npcId, "occupancy_full") end
        return
    end
    print(string.format("[Relocator] dispatch reserved occupancy cell='%s' npc=%s", tostring(dest.destCellName), tostring(npcId)))

    -- -------------------------------------------------------------------------
    -- 2. Get the slot index assigned to this NPC at reservation time.
    -- -------------------------------------------------------------------------
    local slotIndex = OccupancyTracker.getSlot(dest.destCellName, npcId)
    print(string.format("[Relocator] dispatch slotIndex=%d npc=%s", slotIndex, tostring(npcId)))

    -- -------------------------------------------------------------------------
    -- 3. Clear sit/activity state and relocate before disabling.
    -- -------------------------------------------------------------------------
    clearSittingForRelocation(npc, "schedule_dispatch")
    pcall(function() npc:sendEvent("PC_ClearForSchedule", {}) end)

    -- Determine whether this is a cross-cell dispatch.
    local isCrossCell = false
    pcall(function()
        local currentCell = npc.cell and npc.cell.name or ""
        isCrossCell = (destCellLo ~= "" and string.lower(currentCell) ~= destCellLo)
    end)
    print(string.format("[Relocator] dispatch isCrossCell=%s npc=%s currentCell='%s'",
        tostring(isCrossCell), tostring(npcId), tostring(npc.cell and npc.cell.name or "?")))

    local anchored = false
    if isCrossCell then
        -- Teleport to destination BEFORE disabling.
        local prePos = dest.doorInsidePos or npc.position
        local preRot = dest.doorInsideRot
        print(string.format("[Relocator] dispatch pre-teleport npc=%s to '%s' pos=%s",
            tostring(npcId), tostring(dest.destCellName), tostring(prePos)))
        local preTpOk = safeTeleport(npc, dest.destCellName, prePos, { rotation = preRot })
        if preTpOk then
            -- Refresh handle: cross-cell teleport may invalidate the Lua reference.
            local refreshed = findNpcById(npcId)
            if refreshed then
                npc = refreshed
                print(string.format("[Relocator] dispatch refreshed handle after teleport npc=%s", tostring(npcId)))
            else
                print(string.format("[Relocator] dispatch WARNING could not refresh handle after teleport npc=%s", tostring(npcId)))
            end
            anchored = true
        else
            print(string.format("[Relocator] dispatch pre-teleport FAILED npc=%s; falling back to anchorToExterior", tostring(npcId)))
            anchored = anchorToExterior(npc)
        end
    else
        anchored = anchorToExterior(npc)
    end

    if not anchored then
        print(string.format("[Relocator] dispatch ABORT could not anchor npc=%s to exterior", tostring(npcId)))
        OccupancyTracker.release(dest.destCellName, npcId)
        local Scheduler = getScheduler()
        if Scheduler then Scheduler.releaseAssignment(npcId, "anchor_failed") end
        return
    end

    -- Refresh handle after anchor/teleport.
    local refreshed = findNpcById(npcId)
    if refreshed then npc = refreshed end

    local disableOk = safeSetEnabled(npc, false)
    print(string.format("[Relocator] dispatch disableOk=%s npc=%s", tostring(disableOk), tostring(npcId)))
    if not disableOk then
        print(string.format("[Relocator] dispatch ABORT disable failed npc=%s", tostring(npcId)))
        OccupancyTracker.release(dest.destCellName, npcId)
        local Scheduler = getScheduler()
        if Scheduler then Scheduler.releaseAssignment(npcId, "disable_failed") end
        return
    end

    -- -------------------------------------------------------------------------
    -- 4. Enqueue in graceTable
    -- -------------------------------------------------------------------------
    graceTable[npcId] = {
        npc         = npc,
        dest        = dest,
        moduleName  = moduleName,
        slotIndex   = slotIndex,
    }

    NPCState.set(npcId, "at_destination")

    print(string.format("[Relocator] dispatch QUEUED npc=%s dest='%s' slot=%d handleValid=%s",
        tostring(npcId), tostring(dest.destCellName), slotIndex, tostring(isValidNpc(npc))))

    -- -------------------------------------------------------------------------
    -- 5. If the player is already inside the destination cell, materialise now
    -- -------------------------------------------------------------------------
    local ok, playerCell = pcall(function() return world.players[1].cell end)
    if ok and playerCell then
        local okName, pName = pcall(function() return playerCell.name or '' end)
        if okName and string.lower(pName) == string.lower(dest.destCellName or '') then
            print(string.format("[Relocator] dispatch player already in dest '%s', materialising npc=%s immediately",
                tostring(dest.destCellName), tostring(npcId)))
            local matOk = Relocator.materialiseSingleNpc(npcId, dest.destCellName)
            print(string.format("[Relocator] dispatch immediate materialise result=%s npc=%s", tostring(matOk), tostring(npcId)))
        else
            print(string.format("[Relocator] dispatch player in '%s', dest is '%s', deferring npc=%s",
                tostring(pName), tostring(dest.destCellName), tostring(npcId)))
        end
    end
end

--- Internal helper to materialise a specific NPC from the graceTable.
-- Used by onPlayerEnteredCell (looping) and redirectToCell/dispatch (targeted).
-- @param npcId        any     - target NPC's instance ID
-- @param currentCell  string  - the current cell name (for validation)
function Relocator.materialiseSingleNpc(npcId, currentCell)
    print(string.format("[Relocator] materialiseSingleNpc START npc=%s currentCell='%s'", tostring(npcId), tostring(currentCell)))
    local entry = graceTable[npcId]
    if not entry then
        print(string.format("[Relocator] materialiseSingleNpc ABORT no graceTable entry npc=%s", tostring(npcId)))
        return false
    end

    local lo = string.lower(currentCell or "")
    local entryDestLo = string.lower(entry.dest.destCellName or "")
    if entryDestLo ~= lo then
        print(string.format("[Relocator] materialiseSingleNpc SKIP dest mismatch npc=%s entryDest='%s' current='%s'",
            tostring(npcId), entryDestLo, lo))
        return false
    end

    -- Refresh handle to prevent "Object is removed" during rapid state changes.
    local npc = findNpcById(npcId) or entry.npc
    local valid = isValidNpc(npc)
    print(string.format("[Relocator] materialiseSingleNpc findNpcById valid=%s npc=%s", tostring(valid), tostring(npcId)))

    if not valid then
        print(string.format("[Relocator] materialiseSingleNpc DEFER npc=%s not found in loaded cells", tostring(npcId)))
        return false
    end

    -- Update entry with potentially refreshed handle
    entry.npc = npc

    -- Compute target position.
    local slotPos
    if entry.dest.isReturn then
        slotPos = entry.dest.doorInsidePos
        print(string.format("[Relocator] materialiseSingleNpc slotPos=doorInsidePos (return) npc=%s pos=%s", tostring(npcId), tostring(slotPos)))
    elseif entry.dest.doorInsidePos and entry.dest.doorInsideRot then
        slotPos = OccupancyTracker.getGridSlot(
            entry.dest.destCellName,
            entry.dest.doorInsidePos,
            entry.dest.doorInsideRot,
            entry.slotIndex
        )
        print(string.format("[Relocator] materialiseSingleNpc slotPos=gridSlot npc=%s pos=%s", tostring(npcId), tostring(slotPos)))
    else
        local basePos = nil
        pcall(function()
            local p = world.players[1]
            if p and p.cell and string.lower(p.cell.name or "") == lo then
                basePos = p.position
            end
        end)
        if basePos then
            local col = ((entry.slotIndex - 1) % 4) - 1.5
            local row = math.floor((entry.slotIndex - 1) / 4)
            slotPos = util.vector3(basePos.x + col * 64, basePos.y + row * 64, basePos.z)
            print(string.format("[Relocator] materialiseSingleNpc slotPos=playerGrid npc=%s pos=%s", tostring(npcId), tostring(slotPos)))
        else
            slotPos = util.vector3(0, 0, 0)
            print(string.format("[Relocator] materialiseSingleNpc slotPos=ORIGIN npc=%s (no basePos)", tostring(npcId)))
        end
    end

    local didMaterialise = false
    if entry.dest.isReturn then
        didMaterialise = materialiseNpc(npc, npcId, entry, slotPos)
    elseif nearby then
        didMaterialise = materialiseNpc(npc, npcId, entry, snapToNavMesh(slotPos))
    else
        if entry._navmeshRequestId and not pendingNavmeshRequests[entry._navmeshRequestId] then
            entry._navmeshRequestId = nil
        end
        if not entry._navmeshRequestId then
            local reqId = nextNavmeshRequestId(npcId)
            entry._navmeshRequestId = reqId
            pendingNavmeshRequests[reqId] = {
                npcId = npcId,
                entry = entry,
                slotPos = slotPos,
                destCellName = entry.dest.destCellName,
            }
            pcall(function()
                local player = world.players[1]
                if player then
                    player:sendEvent("PC_RequestNavmeshSnap", {
                        requestId = reqId,
                        position = slotPos,
                    })
                end
            end)
            print(string.format("[Relocator] materialiseSingleNpc DEFER navmesh npc=%s reqId=%s", tostring(npcId), tostring(reqId)))
        end
        return false -- in progress
    end

    print(string.format("[Relocator] materialiseSingleNpc result=%s npc=%s", tostring(didMaterialise), tostring(npcId)))
    if didMaterialise then
        graceTable[npcId] = nil
        return true
    end
    return false
end

function Relocator.materialiseActiveForCell(cellName)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return 0
    end
    if not cellName or cellName == '' then return 0 end
    local lo = string.lower(cellName)
    local count = 0

    for npcId, trans in pairs(activeTransitions) do
        if trans.dest and string.lower(trans.dest.destCellName or '') == lo then
            dbg("materialiseActiveForCell: forcing transition door handoff npc=" .. tostring(npcId))
            local npc = findNpcById(npcId) or trans.npc
            if isValidNpc(npc) then
                trans.npc = npc
                pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                Relocator.onTransitionComplete({ npc = npc })
                count = count + 1
            end
        end
    end

    for npcId, dep in pairs(activeDepartures) do
        if dep.mode == "dispatch" and dep.dest and string.lower(dep.dest.destCellName or '') == lo then
            dbg("materialiseActiveForCell: forcing departure door handoff npc=" .. tostring(npcId))
            local npc = findNpcById(npcId) or dep.npc
            if isValidNpc(npc) then
                dep.npc = npc
                pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                Relocator.onDepartureReachedDoor({ npc = npc, _dep = dep })
                count = count + 1
            end
        end
    end

    return count
end

function Relocator.dematerialiseActiveAwayFromCell(cellName, isExterior)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return 0
    end
    if not cellName or cellName == '' then return 0 end
    if isExterior then return 0 end
    local lo = string.lower(cellName)
    local count = 0

    for npcId, trans in pairs(activeTransitions) do
        local destName = trans.dest and trans.dest.destCellName or ""
        if string.lower(destName) ~= lo then
            print(string.format("[Relocator] dematerialiseActiveAway transition npc=%s dest='%s' current='%s'",
                tostring(npcId), tostring(destName), tostring(cellName)))
            local npc = findNpcById(npcId) or trans.npc
            if isValidNpc(npc) then
                trans.npc = npc
                pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                Relocator.onTransitionComplete({ npc = npc })
                count = count + 1
            end
        end
    end

    for npcId, dep in pairs(activeDepartures) do
        if dep.mode == "dispatch" and dep.dest then
            local destName = dep.dest.destCellName or ""
            if destName == "" or string.lower(destName) ~= lo then
                print(string.format("[Relocator] dematerialiseActiveAway departure npc=%s mode=%s dest='%s' current='%s'",
                    tostring(npcId), tostring(dep.mode), tostring(destName), tostring(cellName)))
                local npc = findNpcById(npcId) or dep.npc
                if isValidNpc(npc) then
                    dep.npc = npc
                    pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                    Relocator.onDepartureReachedDoor({ npc = npc, _dep = dep })
                    count = count + 1
                end
            end
        end
    end

    return count
end

--- Called when the player enters a new cell (fired from player.lua via PC_PlayerEnteredCell).
-- Materialises any disabled NPC waiting for this interior cell:
--   • teleport them to their reserved grid slot
--   • re-enable them
--   • notify Scheduler (onArrivedDoor -> module.onArrived)
--
-- @param cellName     string  — name of the cell the player just entered
-- @param prevCellName string  — name of the cell the player just left (may be '')
-- @param isExterior   bool    — whether the new cell is an exterior cell
function Relocator.onPlayerEnteredCell(cellName, prevCellName, isExterior)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not cellName or cellName == '' then return end
    local lo = string.lower(cellName)

    -- Diagnostic: dump grace table contents.
    local graceCount = 0
    print(string.format(
        "[Relocator] onPlayerEnteredCell cell='%s' prev='%s' exterior=%s",
        cellName, tostring(prevCellName), tostring(isExterior)))
    print("[Relocator] === graceTable dump ===")
    for npcId, entry in pairs(graceTable) do
        graceCount = graceCount + 1
        local destName = entry.dest and entry.dest.destCellName or "nil"
        local matches = string.lower(destName or "") == lo
        print(string.format("  [grace] npc=%s dest='%s' match=%s handleValid=%s module=%s",
            tostring(npcId), destName, tostring(matches), tostring(isValidNpc(entry.npc)), tostring(entry.moduleName)))
    end
    print(string.format("[Relocator] === graceTable count=%d ===", graceCount))

    Relocator.dematerialiseActiveAwayFromCell(cellName, isExterior)

    -- Materialise all graceTable NPCs destined for this cell.
    for npcId, _ in pairs(graceTable) do
        Relocator.materialiseSingleNpc(npcId, cellName)
    end

    Relocator.materialiseActiveForCell(cellName)
end

--- Called by global.lua when player.lua returns a navmesh snap result.
function Relocator.onNavmeshSnapResolved(ev)
    if not ev or not ev.requestId then return end
    local request = pendingNavmeshRequests[ev.requestId]
    if not request then return end
    pendingNavmeshRequests[ev.requestId] = nil

    local npcId = request.npcId
    local entry = request.entry
    if not entry then return end
    local currentEntry = graceTable[npcId]
    if currentEntry ~= entry or entry._navmeshRequestId ~= ev.requestId then
        dbg("onNavmeshSnapResolved: ignoring stale request req=" .. tostring(ev.requestId)
            .. " npc=" .. tostring(npcId))
        return
    end
    entry._navmeshRequestId = nil

    local destCellName = request.destCellName or (entry.dest and entry.dest.destCellName)
    if not playerIsInCell(destCellName) then
        print(string.format("[Relocator] onNavmeshSnapResolved DEFER npc=%s req=%s player left dest='%s'",
            tostring(npcId), tostring(ev.requestId), tostring(destCellName)))
        return
    end

    local npc = findNpcById(npcId) or entry.npc
    if not isValidNpc(npc) then
        -- Cell unloaded; keep queued for retry when the cell reloads.
        dbg("onNavmeshSnapResolved: npc=" .. tostring(npcId)
            .. " not in loaded cells; deferring materialisation")
        return
    end

    local finalPos = ev.snappedPosition or request.slotPos
    print(string.format("[Relocator] deferred materialise npc=%s req=%s",
        tostring(npcId), tostring(ev.requestId)))
    local didMaterialise = materialiseNpc(npc, npcId, entry, finalPos)
    if didMaterialise then
        graceTable[npcId] = nil
    end
end

--- Per-frame update.
-- Cleans up invalid grace-table entries and ticks departure timeouts.
function Relocator.onUpdate(dt)
    -- Grace-table: refresh stale handles, but do NOT remove entries just
    -- because the cached handle is invalid.  Disabled NPCs may still be in a
    -- loaded cell (findNpcById now searches world.cells) and can be
    -- materialised later when the player enters the destination cell.
    for npcId, entry in pairs(graceTable) do
        if not isValidNpc(entry.npc) then
            local refreshed = findNpcById(npcId)
            if refreshed then
                entry.npc = refreshed
                dbg("onUpdate: refreshed stale handle npc=" .. tostring(npcId))
            else
                -- Cell is currently unloaded; keep the entry alive so we can
                -- retry when the cell reloads (e.g. player returns to exterior).
                dbg("onUpdate: handle stale but keeping queued npc=" .. tostring(npcId))
            end
        end
    end

    -- Smooth-departure timeout. Local scripts normally send
    -- PC_DepartureReachedDoor when the actor reaches the exit, but Travel can
    -- stop just short of the exact target or a stale local state can drop the
    -- handoff. Force the same handoff here so activeDepartures cannot strand.
    for npcId, dep in pairs(activeDepartures) do
        dep.timeout = (dep.timeout or DEPARTURE_TIMEOUT) - dt
        if dep.timeout <= 0 then
            local state = NPCState.get(npcId)
            if state ~= "departing" then
                if dep.mode == "dispatch" and dep.dest and dep.dest.destCellName then
                    OccupancyTracker.release(dep.dest.destCellName, npcId)
                end
                activeDepartures[npcId] = nil
                print(string.format("[Relocator] departure timeout drop stale npc=%s state=%s mode=%s",
                    tostring(npcId), tostring(state), tostring(dep.mode)))
            else
                dbg("departure timeout npc=" .. tostring(npcId) .. "; forcing door handoff")
                local npc = findNpcById(npcId) or dep.npc
                if isValidNpc(npc) then
                    dep.npc = npc
                    pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                    Relocator.onDepartureReachedDoor({ npc = npc, _dep = dep })
                else
                    dbg("departure timeout npc=" .. tostring(npcId) .. "; stale handle, keeping departure active")
                    dep.timeout = 5.0
                end
            end
        end
    end

    -- Smooth-transition timeout
    for npcId, trans in pairs(activeTransitions) do
        trans.timeout = trans.timeout - dt
        if trans.timeout <= 0 then
            dbg("transition timeout npc=" .. tostring(npcId) .. "; forcing door handoff")
            local npc = findNpcById(npcId) or trans.npc
            if isValidNpc(npc) then
                trans.npc = npc
                pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)
                Relocator.onTransitionComplete({ npc = npc })
            else
                dbg("transition timeout npc=" .. tostring(npcId) .. "; stale handle, keeping transition active")
                trans.timeout = 5.0
            end
        end
    end

    local now = nowSeconds()

    -- Arrival timeout. Local scripts normally send PC_ArrivalComplete when a
    -- door->slot/native Travel finishes. Cross-cell returns can restart npc.lua
    -- and lose that local arrival state, so force a final placement instead of
    -- leaving the actor parked at the exterior door forever.
    for npcId, arrival in pairs(arrivingNpcs) do
        local createdAt = type(arrival) == "table" and arrival.createdAt or nil
        if not createdAt then
            arrivingNpcs[npcId] = {
                moduleName = type(arrival) == "table" and arrival.moduleName or nil,
                targetPos = type(arrival) == "table" and arrival.targetPos or nil,
                createdAt = now,
            }
        elseif now - createdAt >= ARRIVAL_TIMEOUT then
            local actor = findNpcById(npcId)
            local targetPos = arrival.targetPos
            local moduleName = arrival.moduleName
            arrivingNpcs[npcId] = nil
            if isValidNpc(actor) and targetPos then
                -- Route all arrival timeouts through onArrivalFailed so failures
                -- teleport to native and wander, not freeze at the door.
                Relocator.onArrivalFailed({ npc = actor })
                print(string.format("[Relocator] arrival timeout routed to onArrivalFailed npc=%s", tostring(npcId)))
            else
                NPCState.clear(npcId)
                print(string.format("[Relocator] arrival timeout cleared npc=%s", tostring(npcId)))
            end
        end
    end

    for npcId, pending in pairs(pendingExteriorReturns) do
        local createdAt = type(pending) == "table" and pending.createdAt or nil
        if not createdAt then
            pendingExteriorReturns[npcId] = { createdAt = now }
        elseif now - createdAt >= PENDING_HANDOFF_TIMEOUT then
            local actor = findNpcById(npcId)
            if isValidNpc(actor) then
                pendingExteriorReturns[npcId] = nil
                safeSetEnabled(actor, true)
                NPCState.clear(npcId)
                pcall(function() actor:sendEvent("PC_StartWander", {}) end)
                print(string.format("[Relocator] pending exterior return timeout finalized npc=%s", tostring(npcId)))
            else
                pendingExteriorReturns[npcId] = nil
                NPCState.clear(npcId)
                print(string.format("[Relocator] pending exterior return timeout cleared npc=%s", tostring(npcId)))
            end
        end
    end

    for npcId, pending in pairs(pendingArrivalWalks) do
        local createdAt = type(pending) == "table" and pending.createdAt or nil
        if not createdAt then
            pending.createdAt = now
        else
            local actor = findNpcById(npcId) or pending.npc
            if isValidNpc(actor) and deliverPendingArrivalWalk(npcId, actor, "update") then
                -- delivered
            elseif now - createdAt >= PENDING_HANDOFF_TIMEOUT then
                pendingArrivalWalks[npcId] = nil
                NPCState.clear(npcId)
                print(string.format("[Relocator] pending arrival walk timeout cleared npc=%s", tostring(npcId)))
            end
        end
    end

    for npcId, pending in pairs(pendingInstantArrivals) do
        finalizeInstantArrival(npcId, nil, pending)
    end

end

--- Called by global.lua's onActorActive handler when any NPC enters an active cell.
-- Delivers deferred PC_ArrivalWalk events that were queued in pendingArrivalWalks
-- when the NPC was teleported across cell boundaries (causing a script restart).
-- The walk event is safe to send now because the local script has fully initialised.
--
-- @param actor  object  — the actor that just became active
function Relocator.onActorActive(actor)
    if not actor then return end
    local npcId = actor.id

    -- Door→native walks must run before pendingExteriorReturns, which only
    -- finalizes instant same-frame teleports when enable lags after a cross-cell tp.
    local pending = pendingArrivalWalks[npcId]
    if pending then
        if not deliverPendingArrivalWalk(npcId, actor, "actor_active") then
            dbg("onActorActive: stale pending walk for npc=" .. tostring(npcId) .. "; dropping")
            pendingArrivalWalks[npcId] = nil
            NPCState.clear(npcId)
        end
        return
    end

    if pendingExteriorReturns[npcId] then
        pendingExteriorReturns[npcId] = nil
        safeSetEnabled(actor, true)
        Relocator.finishScheduleArrival(npcId, actor, { startWander = true })
        print(string.format("[Relocator] onActorActive: finalized exterior return npc=%s", tostring(npcId)))
        return
    end

    local instantArrival = pendingInstantArrivals[npcId]
    if instantArrival then
        finalizeInstantArrival(npcId, actor, instantArrival)
        return
    end

end

--- True when a deferred door→slot walk is waiting for onActorActive.
function Relocator.hasPendingArrivalWalk(npcId)
    return pendingArrivalWalks[npcId] ~= nil
end

--- True when schedule materialisation still owns a door→native (or slot) walk.
function Relocator.isFinishingArrival(npcId)
    return arrivingNpcs[npcId] ~= nil or pendingArrivalWalks[npcId] ~= nil
end

--- Walk an exterior NPC from their current position to a native/home spot.
-- Registers return_to_origin so PC_ArrivalComplete restores wander.
function Relocator.requestExteriorNativeWalk(npc, targetPos)
    if not npc or not targetPos then return false end
    local npcId = npc.id
    cancelPendingNavmeshForNpc(npcId)
    activeDepartures[npcId] = nil
    activeTransitions[npcId] = nil
    pendingExteriorReturns[npcId] = nil
    arrivingNpcs[npcId] = {
        moduleName = "return_to_origin",
        targetPos  = targetPos,
        createdAt  = nowSeconds(),
    }
    NPCState.set(npcId, "traveling_home")
    setReturnCooldown(npcId, estimateWalkTime(npc, { isReturn = true }, targetPos) + 5.0)
    local ok = pcall(function()
        npc:sendEvent("PC_ArrivalWalk", { slotPos = targetPos })
    end)
    print(string.format("[Relocator] requestExteriorNativeWalk npc=%s ok=%s target=%s",
        tostring(npcId), tostring(ok), tostring(targetPos)))
    return ok
end

--- Cancel a smooth departure that has become stale and walk the visible NPC
-- back to its native exterior position instead.
function Relocator.redirectDepartureToExteriorReturn(npc, targetPos)
    if not npc or not targetPos then return false end
    local npcId = npc.id
    local dep = activeDepartures[npcId]
    local trans = activeTransitions[npcId]
    if not dep and not trans then return false end

    if dep and dep.mode == "dispatch" and dep.dest and dep.dest.destCellName then
        OccupancyTracker.release(dep.dest.destCellName, npcId)
    elseif trans and trans.dest and trans.dest.destCellName then
        OccupancyTracker.release(trans.dest.destCellName, npcId)
    end

    activeDepartures[npcId] = nil
    activeTransitions[npcId] = nil
    pcall(function() npc:sendEvent("PC_DepartureAbort", {}) end)

    print(string.format("[Relocator] redirectDepartureToExteriorReturn npc=%s target=%s",
        tostring(npcId), tostring(targetPos)))
    return Relocator.requestExteriorNativeWalk(npc, targetPos)
end

--- If an exterior NPC is far from their native position, finish placement.
-- allowSmooth: walk when the player is watching; otherwise snap via queueReturn.
function Relocator.ensureExteriorNativePlacement(npc, targetPos, originRot, allowSmooth, playerCell)
    if not npc or not targetPos then return false end
    if not isValidNpc(npc) then return false end

    local npcId = npc.id
    if pendingArrivalWalks[npcId] or pendingExteriorReturns[npcId] then
        return false
    end

    local dist = 999999
    pcall(function() dist = (npc.position - targetPos):length() end)
    if dist < NATIVE_PLACEMENT_DIST then
        return false
    end

    local playerWatching = false
    if allowSmooth and playerCell and npc.cell then
        pcall(function()
            local pLo = string.lower(playerCell.name or "")
            local nLo = string.lower(npc.cell.name or "")
            playerWatching = (pLo ~= "" and pLo == nLo and npc.enabled)
        end)
    end

    if playerWatching then
        return Relocator.requestExteriorNativeWalk(npc, targetPos)
    end

    local originCell = ""
    pcall(function()
        if npc.cell and not npc.cell.isExterior then
            originCell = npc.cell.name or ""
        elseif npc.cell and npc.cell.name then
            originCell = npc.cell.name
        end
    end)
    Relocator.queueReturn(npc, originCell, targetPos, originRot, { exterior = true })
    return true
end

--- Returns true if the NPC is currently in any "in-transit" state (walking, queued, or materialising).
function Relocator.isInTransit(npcId)
    return graceTable[npcId]         ~= nil
        or activeDepartures[npcId]   ~= nil
        or activeTransitions[npcId]  ~= nil
        or arrivingNpcs[npcId]       ~= nil
        or pendingInstantArrivals[npcId] ~= nil
        or pendingArrivalWalks[npcId] ~= nil
        or pendingExteriorReturns[npcId] ~= nil
end

--- Returns a comma-delimited string describing which transit tables currently
-- contain this NPC. Useful for reconcile diagnostics.
function Relocator.getTransitReason(npcId)
    if not npcId then return "none" end
    local reasons = {}
    if graceTable[npcId] ~= nil then reasons[#reasons + 1] = "grace" end
    if activeDepartures[npcId] ~= nil then reasons[#reasons + 1] = "departing" end
    if activeTransitions[npcId] ~= nil then reasons[#reasons + 1] = "transition" end
    if arrivingNpcs[npcId] ~= nil then reasons[#reasons + 1] = "arriving" end
    if pendingInstantArrivals[npcId] ~= nil then reasons[#reasons + 1] = "pending_arrival" end
    if pendingArrivalWalks[npcId] ~= nil then reasons[#reasons + 1] = "pending_walk" end
    if pendingExteriorReturns[npcId] ~= nil then reasons[#reasons + 1] = "pending_ext_return" end
    if #reasons == 0 then return "none" end
    return table.concat(reasons, ",")
end

--- Returns true if the NPC is currently in the graceTable (disabled, queued).
function Relocator.isQueued(npcId)
    return graceTable[npcId] ~= nil
end

--- Returns true if the NPC is currently in activeDepartures (walking to the exit door).
function Relocator.isDeparting(npcId)
    return activeDepartures[npcId] ~= nil or activeTransitions[npcId] ~= nil
end

function Relocator.isInTransitToCell(npcId, cellName)
    if not npcId or not cellName or cellName == "" then return false end
    local lo = string.lower(cellName)
    local queued = graceTable[npcId]
    if queued and queued.dest and string.lower(queued.dest.destCellName or "") == lo then
        return true
    end
    local dep = activeDepartures[npcId]
    if dep and dep.mode == "dispatch" and dep.dest
            and string.lower(dep.dest.destCellName or "") == lo then
        return true
    end
    local trans = activeTransitions[npcId]
    if trans and trans.dest and string.lower(trans.dest.destCellName or "") == lo then
        return true
    end
    local pending = pendingInstantArrivals[npcId]
    if pending and pending.dest and string.lower(pending.dest.destCellName or "") == lo then
        return true
    end
    return false
end

--- Returns true if the materialisation is waiting on a staggered arrival timer.
function Relocator.isArrivalDelayed(npcId)
    -- Temporarily disabled for debugging; always return false.
    -- local entry = graceTable[npcId] or activeTransitions[npcId] or activeDepartures[npcId]
    -- return entry and entry.arrivalTimer and entry.arrivalTimer > 0
    return false
end

--- Redirect a queued NPC to a new destination.
-- If the NPC is in the graceTable (disabled, waiting for a cell), swaps their
-- destination to newDest and materialises immediately if the player is already
-- in that cell.  Returns true if the NPC was found and redirected.
-- Returns false if the NPC is not currently in the graceTable.
--
-- @param npcId   any     — the NPC's instance id
-- @param newDest table   — dest table (must have destCellName; isReturn optional)
function Relocator.redirectToCell(npcId, newDest)
    if not npcId or not newDest or not newDest.destCellName then return false end

    local entry = graceTable[npcId]
    if not entry then
        print(string.format("[Relocator] redirectToCell FAIL no entry npc=%s", tostring(npcId)))
        return false
    end

    local oldDestName = entry.dest and entry.dest.destCellName or "nil"
    print(string.format("[Relocator] redirectToCell npc=%s old='%s' -> new='%s'",
        tostring(npcId), oldDestName, tostring(newDest.destCellName)))
    local oldDest = entry.dest or {}
    local sameDest = string.lower(oldDest.destCellName or "") == string.lower(newDest.destCellName or "")

    -- Release occupancy for old destination if it had a slot.
    if not sameDest then
        cancelPendingNavmeshForNpc(npcId)
    end
    if not sameDest and not oldDest.isReturn and oldDest.destCellName then
        OccupancyTracker.release(oldDest.destCellName, npcId)
    end

    -- Preserve rich resolver data only for same-destination refreshes. Cross-
    -- destination redirects are schedule-authoritative and must not inherit
    -- stale route fields (e.g. a tavern door after an overnight home redirect).
    local canInheritRoute = sameDest and newDest.exterior ~= true
    if canInheritRoute and not newDest.doorInsidePos and oldDest.doorInsidePos then
        newDest.doorInsidePos = oldDest.doorInsidePos
    end
    if canInheritRoute and not newDest.doorInsideRot and oldDest.doorInsideRot then
        newDest.doorInsideRot = oldDest.doorInsideRot
    end
    if canInheritRoute and not newDest.doorExteriorPos and oldDest.doorExteriorPos then
        newDest.doorExteriorPos = oldDest.doorExteriorPos
    end
    if canInheritRoute and not newDest.exteriorCellName and oldDest.exteriorCellName then
        newDest.exteriorCellName = oldDest.exteriorCellName
    end

    -- Update the graceTable entry.
    entry.dest      = newDest
    entry.slotIndex = not newDest.isReturn and OccupancyTracker.getSlot(newDest.destCellName, npcId) or nil

    -- Materialise immediately if player is already in the new target cell.
    local ok, playerCell = pcall(function() return world.players[1].cell end)
    if ok and playerCell then
        local okName, pName = pcall(function() return playerCell.name or '' end)
        if okName and string.lower(pName) == string.lower(newDest.destCellName) then
            print(string.format("[Relocator] redirectToCell player already in '%s', materialising npc=%s",
                tostring(newDest.destCellName), tostring(npcId)))
            Relocator.materialiseSingleNpc(npcId, newDest.destCellName)
        end
    end

    return true
end

--- Queue an NPC to return to their origin cell without an occupancy slot.
-- Used when a schedule ends: the NPC is disabled in place and will be
-- re-enabled at their origin position when the player enters that cell.
-- Unlike dispatch(), this does NOT reserve an OccupancyTracker slot.
--
-- @param npc      object  — the NPC actor
-- @param cellName string  — the cell name to return them to (origin cell)
-- @param pos      vector3 — position inside that cell
-- @param rot      transform — rotation (optional)
-- cellName may be "" to mean "exterior world" (grid-coordinate destination).
-- Exterior is always loaded so those NPCs are teleported directly; no graceTable entry.
function Relocator.queueReturn(npc, cellName, pos, rot, opts)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not npc then
        print("[Relocator] queueReturn ABORT missing npc")
        return
    end

    local npcId = npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] queueReturn SKIP hostile npc=%s", tostring(npcId)))
        return
    end
    print(string.format("[Relocator] queueReturn START npc=%s cellName='%s' pos=%s",
        tostring(npcId), tostring(cellName), tostring(pos)))
    cancelPendingNavmeshForNpc(npcId)

    -- Clear sitting/activity state so npc.lua's onInactive won't reset position.
    clearSittingForRelocation(npc, "schedule_return")
    pcall(function() npc:sendEvent("PC_ClearForSchedule", {}) end)

    -- Exterior destination: exterior is always loaded, teleport directly. Named
    -- exterior homes are marked explicitly by the schedule reconciler because
    -- OpenMW stores exterior cell names like "Seyda Neen" as non-empty strings.
    if (opts and opts.exterior) or not cellName or cellName == "" then
        NPCState.set(npcId, "traveling_home")
        setReturnCooldown(npcId, 15.0)
        local enOk = safeSetEnabled(npc, true)
        local tpOk = false
        if pos then
            tpOk = safeTeleport(npc, "", pos, { rotation = rot })
            local refreshed = findNpcById(npcId)
            if refreshed then npc = refreshed end
            if tpOk then
                enOk = safeSetEnabled(npc, true)
            end
        end
        if tpOk and enOk then
            pendingExteriorReturns[npcId] = nil
            Relocator.finishScheduleArrival(npcId, npc, { startWander = true })
        elseif tpOk and not enOk then
            -- Cross-cell teleport succeeded but enable needs onActorActive handoff.
            pendingExteriorReturns[npcId] = { createdAt = nowSeconds() }
        elseif not tpOk then
            pendingExteriorReturns[npcId] = nil
            NPCState.clear(npcId)
        end
        print(string.format("[Relocator] queueReturn exterior direct npc=%s enable=%s tp=%s",
            tostring(npcId), tostring(enOk), tostring(tpOk)))
        return
    end

    -- Interior destination: anchor to exterior first so the reference stays valid
    -- after the interior cell unloads, then queue in graceTable.
    local anchored = anchorToExterior(npc)
    if not anchored then
        -- NPC is still in the interior and we can't move them.  Do NOT disable
        -- them here — leaving them disabled inside an interior means they'll
        -- ghost and the sitting system may re-target them.  Instead, send a
        -- stand-up event and defer the return until next reconcile tick.
        print(string.format("[Relocator] queueReturn DEFER npc=%s (anchor failed)", tostring(npcId)))
        NPCState.set(npcId, "departing")
        pcall(function() SittingGlobal.forceStandForDeparture(npcId) end)
        pcall(function() npc:sendEvent("PC_StandUpPlease", {}) end)
        return
    end

    -- Refresh handle after cross-cell teleport.
    local refreshed = findNpcById(npcId)
    if refreshed then npc = refreshed end

    local disableOk = safeSetEnabled(npc, false)
    print(string.format("[Relocator] queueReturn anchored+disabled ok=%s npc=%s", tostring(disableOk), tostring(npcId)))

    local dest = {
        destCellName  = cellName,
        doorInsidePos = pos,
        doorInsideRot = rot,
        isReturn      = true,
    }

    graceTable[npcId] = {
        npc        = npc,
        dest       = dest,
        moduleName = nil,
        slotIndex  = nil,
    }

    NPCState.set(npcId, "traveling_home")

    print(string.format("[Relocator] queueReturn QUEUED npc=%s -> cell='%s'", tostring(npcId), tostring(cellName)))

    -- Materialise immediately if player is already in that cell.
    local ok, playerCell = pcall(function() return world.players[1].cell end)
    if ok and playerCell then
        local okName, pName = pcall(function() return playerCell.name or '' end)
        if okName and string.lower(pName) == string.lower(cellName) then
            print(string.format("[Relocator] queueReturn player already in '%s', materialising npc=%s", cellName, tostring(npcId)))
            Relocator.materialiseSingleNpc(npcId, cellName)
        end
    end
end

--- Drop Relocator state held for a specific NPC.
-- Called from module.onDepart so a released NPC doesn't get materialised later.

function Relocator.releaseNpc(npcId)
    if not npcId then return end
    cancelPendingNavmeshForNpc(npcId)
    local entry = graceTable[npcId]
    if entry then
        if entry.dest and entry.dest.destCellName then
            OccupancyTracker.release(entry.dest.destCellName, npcId)
        end
    end
    graceTable[npcId] = nil
    activeDepartures[npcId] = nil
    activeTransitions[npcId] = nil
    arrivingNpcs[npcId] = nil
    pendingArrivalWalks[npcId] = nil
    pendingExteriorReturns[npcId] = nil
    pendingInstantArrivals[npcId] = nil
    dbg("releaseNpc: cleared all state for npc=" .. tostring(npcId))
end

-- =============================================================================
-- Smooth Departure — Phase A
-- =============================================================================

--- Like dispatch(), but when the player is in the same cell as the NPC the NPC
-- walks to the exit door first before being disabled and queued in graceTable.
-- Falls back to instant dispatch() whenever the smooth path cannot be used
-- (player not present, no exit door found, etc.).
--
-- Called by JSONScheduleModule.reconcileCell EVICT instead of dispatch().
function Relocator.dispatchSmooth(npc, dest, moduleName)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not npc or not dest then
        print("[Relocator] dispatchSmooth ABORT nil npc or dest")
        return
    end

    local npcId = npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] dispatchSmooth SKIP hostile npc=%s", tostring(npcId)))
        return
    end
    print(string.format("[Relocator] dispatchSmooth START npc=%s dest='%s' module=%s",
        tostring(npcId), tostring(dest.destCellName), tostring(moduleName)))
    cancelPendingNavmeshForNpc(npcId)
    clearArrivalHandoffState(npcId, npc, "dispatchSmooth")

    -- Already in target cell: in-place arrival (same as dispatch fast path).
    local alreadyInDest = false
    pcall(function()
        local npcCellName = string.lower(npc.cell and npc.cell.name or "")
        local destLo = string.lower(dest.destCellName or "")
        alreadyInDest = (destLo ~= "" and npcCellName == destLo)
    end)
    if alreadyInDest then
        print(string.format("[Relocator] dispatchSmooth alreadyInDest npc=%s", tostring(npcId)))
        local Scheduler = getScheduler()
        if Scheduler and Scheduler.registerAssignment then
            Scheduler.registerAssignment(npcId, moduleName, dest, npc)
            Scheduler.onArrivedDoor({ npc = npc, moduleName = moduleName })
        end
        return
    end

    -- Determine whether the player is watching this NPC right now.
    local playerObserving = false
    pcall(function()
        local player = world.players[1]
        if player and player.cell and npc.cell then
            local pCellLo = string.lower(player.cell.name or "")
            local nCellLo = string.lower(npc.cell.name or "")
            playerObserving = (pCellLo ~= "" and pCellLo == nCellLo and npc.enabled)
        end
    end)
    print(string.format("[Relocator] dispatchSmooth playerObserving=%s npc=%s", tostring(playerObserving), tostring(npcId)))

    if not playerObserving then
        print(string.format("[Relocator] dispatchSmooth fallback to dispatch npc=%s (player not observing)", tostring(npcId)))
        Relocator.dispatch(npc, dest, moduleName)
        return
    end

    -- Determine the walk target:
    --   • Exterior NPC -> walk to the destination door's exterior approach position.
    --     dest.doorExteriorPos is the door's position on the exterior side, already
    --     resolved by findDoorByDestCell / buildDest.
    --   • Interior NPC -> walk to the nearest exit door in the current interior.
    local npcIsInterior = false
    pcall(function() npcIsInterior = npc.cell ~= nil and not npc.cell.isExterior end)

    local doorPos = nil
    local exteriorDoorPos = nil
    local exitDoorObj = nil
    if npcIsInterior then
        local DestRes = nil
        pcall(function() DestRes = require("scripts.ProceduralChatter.schedule.DestinationResolver") end)
        if DestRes then
            pcall(function()
                doorPos, exteriorDoorPos, _, exitDoorObj = DestRes.findExitDoor(npc)
            end)
        end
    elseif dest.doorExteriorPos then
        -- Exterior NPC: approach the destination door from outside.
        doorPos = dest.doorExteriorPos
        exitDoorObj = dest.door
    end

    if not doorPos then
        dbg("dispatchSmooth: no door walk target; using instant dispatch")
        Relocator.dispatch(npc, dest, moduleName)
        return
    end

    -- Reserve occupancy slot up front (mirrors dispatch behaviour).
    local reserved = OccupancyTracker.reserve(dest.destCellName, npcId)
    if not reserved then
        dbg("dispatchSmooth: occupancy full for npc=" .. tostring(npcId))
        local Scheduler = getScheduler()
        if Scheduler then Scheduler.releaseAssignment(npcId, "occupancy_full") end
        return
    end
    local slotIndex = OccupancyTracker.getSlot(dest.destCellName, npcId)
    local walkTime  = estimateWalkTime(npc, dest, dest.finalPos or npc.position)

    activeDepartures[npcId] = {
        npc             = npc,
        mode            = "dispatch",
        dest            = dest,
        moduleName      = moduleName,
        slotIndex       = slotIndex,
        timeout         = DEPARTURE_TIMEOUT,
        exteriorDoorPos = exteriorDoorPos,
        arrivalTimer    = walkTime,
        exitDoor        = exitDoorObj,
    }

    NPCState.set(npcId, "departing")
    setReturnCooldown(npcId, DEPARTURE_TIMEOUT + walkTime + 5.0)
    clearSittingForRelocation(npc, "smooth_depart")

    pcall(function()
        npc:sendEvent("PC_PrepareForDeparture", {
            doorPos = doorPos,
            timeout = DEPARTURE_TIMEOUT,
        })
    end)

    dbg("dispatchSmooth: started smooth depart npc=" .. tostring(npcId)
        .. " -> '" .. tostring(dest.destCellName) .. "'"
        .. " doorPos=" .. tostring(doorPos))
end

--- Like queueReturn(), but when the player is in the same cell the NPC walks to
-- the exit door before being disabled.
-- Called by JSONScheduleModule.onDepart and reconcileCell instead of queueReturn().
function Relocator.queueReturnSmooth(npc, cellName, pos, rot, opts)
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not npc then
        dbg("queueReturnSmooth: missing npc, aborting")
        return
    end

    local npcId = npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] queueReturnSmooth SKIP hostile npc=%s", tostring(npcId)))
        return
    end
    print(string.format("[Relocator] queueReturnSmooth npc=%s cellName='%s' pos=%s",
        tostring(npc.id), tostring(cellName), tostring(pos)))
    cancelPendingNavmeshForNpc(npcId)

    -- Smooth departure only makes sense for interior NPCs: they walk to the exit
    -- door before being disabled.  Exterior NPCs have no door to walk to — use
    -- the instant path immediately.
    local npcIsInterior = false
    pcall(function() npcIsInterior = npc.cell ~= nil and not npc.cell.isExterior end)
    if not npcIsInterior then
        -- Exterior NPC: walk back to the Origin Location if the player is watching.
        local extPlayerObserving = false
        pcall(function()
            local player = world.players[1]
            if player and player.cell and npc.cell then
                local pCellLo = string.lower(player.cell.name or "")
                local nCellLo = string.lower(npc.cell.name or "")
                extPlayerObserving = (pCellLo == nCellLo and npc.enabled)
            end
        end)
        if extPlayerObserving then
            local walkTime = estimateWalkTime(npc, { isReturn = true }, pos)
            dbg("queueReturnSmooth: exterior return walk npc=" .. tostring(npcId) .. " (timer=" .. tostring(walkTime) .. ")")
            activeDepartures[npcId] = {
                npc          = npc,
                mode         = "queueReturn",
                pos          = pos,
                rot          = rot,
                timeout      = DEPARTURE_TIMEOUT,
                arrivalTimer = walkTime,
            }
            setReturnCooldown(npcId, walkTime + 5.0)
            pcall(function()
                npc:sendEvent("PC_PrepareForDeparture", {
                    doorPos = pos,
                    timeout = DEPARTURE_TIMEOUT,
                })
            end)
            NPCState.set(npcId, "departing")
            clearSittingForRelocation(npc, "smooth_return")
            return
        end
        Relocator.queueReturn(npc, cellName, pos, rot, opts)
        return
    end

    -- Find exit door of the current interior.
    local DestRes = nil
    pcall(function() DestRes = require("scripts.ProceduralChatter.schedule.DestinationResolver") end)
    local doorPos, exteriorDoorPos, exteriorCellName, exitDoorObj = nil, nil, nil, nil
    if DestRes then 
        pcall(function() 
            local dPos, ePos, eCell, eDoor = DestRes.findExitDoor(npc)
            doorPos = dPos
            exteriorDoorPos = ePos
            exteriorCellName = eCell
            exitDoorObj = eDoor
        end)
    end

    if not doorPos then
        dbg("queueReturnSmooth: no exit door; using instant queueReturn")
        Relocator.queueReturn(npc, cellName, pos, rot, opts)
        return
    end

    -- Determine whether the player is watching this departure.
    -- We distinguish:
    --   1) sameInterior: player shares NPC's current interior (do interior walk-to-door).
    --   2) watchingExteriorExit: player is in the exterior cell this door exits to
    --      (skip interior walk; emerge directly at exterior door).
    local playerObserving = false
    local sameInterior = false
    local watchingExteriorExit = false
    pcall(function()
        local player = world.players[1]
        if not player or not player.cell or not npc.cell then return end

        local pCellLo = string.lower(player.cell.name or "")
        local nCellLo = string.lower(npc.cell.name or "")
        local eCellLo = string.lower(exteriorCellName or "")

        sameInterior = (pCellLo ~= "" and pCellLo == nCellLo and npc.enabled)
        watchingExteriorExit = (pCellLo ~= "" and eCellLo ~= "" and pCellLo == eCellLo and npc.enabled)
        playerObserving = sameInterior or watchingExteriorExit
    end)

    if not playerObserving then
        dbg("queueReturnSmooth: player not present in source/exit cell; using instant queueReturn")
        Relocator.queueReturn(npc, cellName, pos, rot, opts)
        return
    end

    -- Player is in the destination exterior: do NOT run an interior walk-to-door.
    -- Instead, complete departure immediately via the exterior door proxy and let
    -- grace/materialise handle visible exterior emergence + walk to origin spot.
    if watchingExteriorExit then
        local dep = {
            npc              = npc,
            mode             = "queueReturn",
            cellName         = cellName,
            pos              = pos,
            rot              = rot,
            exteriorDoorPos  = exteriorDoorPos,
            exteriorCellName = exteriorCellName,
            forceExteriorReturn = opts and opts.exterior or false,
            timeout          = DEPARTURE_TIMEOUT,
            arrivalTimer     = estimateWalkTime(npc, { isReturn = true }, pos),
            exitDoor         = exitDoorObj,
        }
        Relocator.onDepartureReachedDoor({ npc = npc, _dep = dep })
        dbg("queueReturnSmooth: exterior-observed return; skipped interior walk npc=" .. tostring(npcId))
        return
    end

    activeDepartures[npcId] = {
        npc              = npc,
        mode             = "queueReturn",
        cellName         = cellName,
        pos              = pos,
        rot              = rot,
        exteriorDoorPos  = exteriorDoorPos,
        exteriorCellName = exteriorCellName,
        forceExteriorReturn = opts and opts.exterior or false,
        timeout          = DEPARTURE_TIMEOUT,
        exitDoor         = exitDoorObj,
    }
    setReturnCooldown(npcId, estimateWalkTime(npc, { isReturn = true }, pos) + 5.0)

    NPCState.set(npcId, "departing")

    pcall(function()
        npc:sendEvent("PC_PrepareForDeparture", {
            doorPos = doorPos,
            timeout = DEPARTURE_TIMEOUT,
        })
    end)

    dbg("queueReturnSmooth: started smooth return npc=" .. tostring(npcId)
        .. " doorPos=" .. tostring(doorPos))
end

--- Called (via global.lua event handler) when an NPC's local script confirms the
-- NPC has reached the exit door.  Also called internally when the departure
-- timeout fires.  Runs the appropriate graceTable / disable sequence.
--
-- ev.npc  — the NPC actor
-- ev._dep — optional pre-fetched departure record (used by timeout path to avoid
--           a second activeDepartures lookup after the record was already removed)
function Relocator.onDepartureReachedDoor(ev)
    if not ev or not ev.npc then
        print("[Relocator] onDepartureReachedDoor ABORT no npc")
        return
    end
    local npc   = ev.npc
    local npcId = npc.id

    -- Abort if NPC became hostile mid-departure
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] onDepartureReachedDoor ABORT hostile npc=%s", tostring(npcId)))
        activeDepartures[npcId] = nil
        return
    end

    -- Retrieve departure record (already removed by timeout caller if applicable).
    local dep = ev._dep or activeDepartures[npcId]
    if not dep then
        print(string.format("[Relocator] onDepartureReachedDoor ABORT no departure record npc=%s", tostring(npcId)))
        return
    end
    activeDepartures[npcId] = nil   -- idempotent

    if dep.exitDoor then
        playDoorSound(dep.exitDoor)
    end

    print(string.format("[Relocator] onDepartureReachedDoor npc=%s mode=%s", tostring(npcId), tostring(dep.mode)))

    if dep.mode == "dispatch" then
        pcall(function() npc:sendEvent("PC_ClearForSchedule", {}) end)

        -- Transition Check: Interior -> Exterior -> Interior
        local isTransition = (dep.exteriorDoorPos ~= nil and dep.dest.doorExteriorPos ~= nil)
        
        if isTransition then
            dbg("onDepartureReachedDoor: starting cross-exterior transition Door A -> Door B")
            -- Teleport to Door A (exterior side)
            safeTeleport(npc, "", dep.exteriorDoorPos)
            safeSetEnabled(npc, true)
            
            activeTransitions[npcId] = {
                npc          = npc,
                targetPos    = dep.dest.doorExteriorPos,
                dest         = dep.dest,
                moduleName   = dep.moduleName,
                slotIndex    = dep.slotIndex,
                timeout      = TRANSITION_TIMEOUT,
                arrivalTimer = dep.arrivalTimer,
            }
            
            pcall(function()
                npc:sendEvent("PC_TransitionWalk", { doorPos = dep.dest.doorExteriorPos })
            end)
            return
        end

        -- Standard dispatch path (Interior -> Exterior Disable)
        -- Improved: If we have an exterior door, move there instead of snapping home.
        local anchored = false
        if dep.exteriorDoorPos then
             print(string.format("[Relocator] onDepartureReachedDoor: using exterior door proxy npc=%s", tostring(npcId)))
             local tpOk = safeTeleport(npc, "", dep.exteriorDoorPos)
             if tpOk then
                 anchored = true
             else
                 print(string.format("[Relocator] onDepartureReachedDoor: door proxy teleport failed npc=%s", tostring(npcId)))
                 anchored = anchorToExterior(npc)
             end
        else
             anchored = anchorToExterior(npc)
        end
        if not anchored then
            print(string.format("[Relocator] onDepartureReachedDoor: ABORT anchor failed npc=%s", tostring(npcId)))
            return
        end
        safeSetEnabled(npc, false)

        graceTable[npcId] = {
            npc          = npc,
            dest         = dep.dest,
            moduleName   = dep.moduleName,
            slotIndex    = dep.slotIndex,
            arrivalTimer = dep.arrivalTimer,
        }
        NPCState.set(npcId, "at_destination")

        -- Materialise immediately if player is already in dest cell.
        local ok, playerCell = pcall(function() return world.players[1].cell end)
        if ok and playerCell then
            local okN, pN = pcall(function() return playerCell.name or '' end)
            if okN and string.lower(pN) == string.lower(dep.dest.destCellName or '') then
                Relocator.onPlayerEnteredCell(dep.dest.destCellName, '', false)
            end
        end

    elseif dep.mode == "queueReturn" then
        pcall(function() npc:sendEvent("PC_ClearForSchedule", {}) end)

        -- Exterior destination: exterior is always loaded, so bypass graceTable
        -- and handle directly. Native homes in named exterior cells (e.g.
        -- "Seyda Neen") arrive here with cellName set to that exterior name,
        -- not the empty exterior-world marker.
        if dep.forceExteriorReturn or isExteriorReturnCell(dep.cellName, dep.exteriorCellName) then
            NPCState.set(npcId, "traveling_home")
            -- Exterior destination: place NPC at the exterior door and walk to origin.
            if dep.exteriorDoorPos then
                local enOk = safeSetEnabled(npc, true)
                local tpOk = false
                if dep.pos then
                    pendingArrivalWalks[npcId] = {
                        npc        = npc,
                        slotPos    = dep.pos,
                        moduleName = "return_to_origin",
                        createdAt  = nowSeconds(),
                    }
                end
                if enOk then
                    tpOk = safeTeleport(npc, "", dep.exteriorDoorPos)
                end
                if dep.pos and not tpOk and enOk then
                    pendingArrivalWalks[npcId] = nil
                    tpOk = safeTeleport(npc, "", dep.pos, { rotation = dep.rot })
                    if tpOk then
                        Relocator.finishScheduleArrival(npcId, npc, { startWander = true })
                        print(string.format("[Relocator] onDepartureReachedDoor: exterior return (direct fallback) npc=%s", tostring(npcId)))
                        return
                    end
                end
                if dep.pos and tpOk then
                    NPCState.set(npcId, "traveling_home")
                    setReturnCooldown(npcId, (dep.arrivalTimer or 0) + 5.0)
                    local refreshed = findNpcById(npcId)
                    if refreshed and pendingArrivalWalks[npcId] then
                        safeSetEnabled(refreshed, true)
                        pendingArrivalWalks[npcId].npc = refreshed
                        deliverPendingArrivalWalk(npcId, refreshed, "exterior_return")
                    end
                    print(string.format("[Relocator] onDepartureReachedDoor: exterior return (door+walk) npc=%s", tostring(npcId)))
                else
                    pendingArrivalWalks[npcId] = nil
                    if tpOk then
                        Relocator.finishScheduleArrival(npcId, npc, { startWander = true })
                    elseif enOk then
                        safeSetEnabled(npc, false)
                    end
                    print(string.format("[Relocator] onDepartureReachedDoor: exterior return (door fallback) npc=%s en=%s tp=%s",
                        tostring(npcId), tostring(enOk), tostring(tpOk)))
                end
            else
                -- No door data: teleport directly to origin.
                if dep.pos then
                    safeTeleport(npc, "", dep.pos, { rotation = dep.rot })
                end
                safeSetEnabled(npc, true)
                Relocator.finishScheduleArrival(npcId, npc, { startWander = true })
                print(string.format("[Relocator] onDepartureReachedDoor: exterior return (instant) npc=%s", tostring(npcId)))
            end
            return
        end

        -- Interior destination: queue in graceTable for materialisation when
        -- the player enters that cell.
        safeSetEnabled(npc, false)

        local dest = {
            destCellName    = dep.cellName,
            doorExteriorPos = dep.exteriorDoorPos,
            exteriorCellName = dep.exteriorCellName,
            doorInsidePos   = dep.pos, -- The home spot (to walk to)
            doorInsideRot   = dep.rot,
            isReturn        = true,
        }

        graceTable[npcId] = {
            npc         = npc,
            dest        = dest,
            moduleName  = "return_to_origin",
            slotIndex   = nil,
        }

        NPCState.set(npcId, "at_destination")
        dbg("onDepartureReachedDoor: return npc=" .. tostring(npcId) .. " queued in graceTable")

        -- Immediate materialisation check (if player is already in that interior)
        local ok, playerCell = pcall(function() return world.players[1].cell end)
        if ok and playerCell then
            local okN, pN = pcall(function() return playerCell.name or '' end)
            local targetCell = dest.destCellName
            if okN and pN ~= '' and string.lower(pN) == string.lower(targetCell) then
                Relocator.onPlayerEnteredCell(targetCell, '', false)
            end
        end
        return
    end
end

-- =============================================================================
-- Smooth Arrival — Phase B
-- =============================================================================

--- Called (via global.lua event handler) when an NPC's local script confirms the
-- NPC has walked from the door to their slot.  Fires Scheduler.onArrivedDoor so
-- the owning module's onArrived callback runs.
--
-- ev.npc — the NPC actor
function Relocator.onArrivalComplete(ev)
    if not ev or not ev.npc then
        print("[Relocator] onArrivalComplete ABORT no npc")
        return
    end
    local npcId = ev.npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] onArrivalComplete ABORT hostile npc=%s", tostring(npcId)))
        arrivingNpcs[npcId] = nil
        pendingArrivalWalks[npcId] = nil
        return
    end
    local arrival = arrivingNpcs[npcId]

    if not arrival then
        print(string.format("[Relocator] onArrivalComplete stale completion npc=%s", tostring(npcId)))
        Relocator.finishScheduleArrival(npcId, ev.npc, { startWander = true })
        return
    end

    print(string.format("[Relocator] onArrivalComplete npc=%s module=%s", tostring(npcId), tostring(arrival.moduleName)))
    arrivingNpcs[npcId] = nil
    pendingArrivalWalks[npcId] = nil

    local Scheduler = getScheduler()
    if arrival.moduleName == "return_to_origin" then
        Relocator.finishScheduleArrival(npcId, ev.npc, { startWander = true })
    elseif Scheduler then
        Relocator.finishScheduleArrival(npcId, ev.npc, {})
        Scheduler.onArrivedDoor({ npc = ev.npc, moduleName = arrival.moduleName })
    else
        Relocator.finishScheduleArrival(npcId, ev.npc, { startWander = true })
    end
end

-- Called by npc.lua when a door→slot/native walk has genuinely failed (timeout
-- or exhausted re-issues).  Teleport the NPC straight to the target and start
-- wandering immediately, identical to the reconciler’s >1h instant path.
function Relocator.onArrivalFailed(ev)
    if not ev or not ev.npc then
        print("[Relocator] onArrivalFailed ABORT no npc")
        return
    end
    local npcId = ev.npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] onArrivalFailed ABORT hostile npc=%s", tostring(npcId)))
        arrivingNpcs[npcId] = nil
        pendingArrivalWalks[npcId] = nil
        return
    end
    local arrival = arrivingNpcs[npcId]
    local targetPos = (arrival and arrival.targetPos) or (ev and ev.targetPos) or nil

    print(string.format("[Relocator] onArrivalFailed npc=%s targetPos=%s", tostring(npcId), tostring(targetPos)))
    arrivingNpcs[npcId] = nil
    pendingArrivalWalks[npcId] = nil

    if isValidNpc(ev.npc) and targetPos then
        safeSetEnabled(ev.npc, true)
        safeTeleport(ev.npc, "", targetPos)
        local refreshed = findNpcById(npcId) or ev.npc
        Relocator.finishScheduleArrival(npcId, refreshed, { startWander = true })
        print(string.format("[Relocator] onArrivalFailed teleport+wander npc=%s", tostring(npcId)))
    else
        Relocator.finishScheduleArrival(npcId, ev.npc, { startWander = true })
        print(string.format("[Relocator] onArrivalFailed finish only npc=%s", tostring(npcId)))
    end
end

--- Called when an NPC confirms they reached the target door in the exterior.
function Relocator.onTransitionComplete(ev)
    if not ev or not ev.npc then
        print("[Relocator] onTransitionComplete ABORT no npc")
        return
    end
    local npcId = ev.npc.id
    if NPCState.isHostile(npcId) then
        print(string.format("[Relocator] onTransitionComplete ABORT hostile npc=%s", tostring(npcId)))
        activeTransitions[npcId] = nil
        return
    end
    local trans = activeTransitions[npcId]
    if not trans then
        print(string.format("[Relocator] onTransitionComplete SKIP no transition record npc=%s", tostring(npcId)))
        return
    end
    activeTransitions[npcId] = nil

    print(string.format("[Relocator] onTransitionComplete npc=%s", tostring(npcId)))

    -- Disable and queue in graceTable for the final destination interior.
    local anchored = anchorToExterior(trans.npc)
    if not anchored then
        print(string.format("[Relocator] onTransitionComplete: ABORT anchor failed npc=%s", tostring(npcId)))
        return
    end
    safeSetEnabled(trans.npc, false)

    graceTable[npcId] = {
        npc          = trans.npc,
        dest         = trans.dest,
        moduleName   = trans.moduleName,
        slotIndex    = trans.slotIndex,
        arrivalTimer = trans.arrivalTimer,
    }
    NPCState.set(npcId, "at_destination")

    -- Materialise immediately if player in dest cell.
    local ok, playerCell = pcall(function() return world.players[1].cell end)
    if ok and playerCell then
        local okN, pN = pcall(function() return playerCell.name or '' end)
        if okN and string.lower(pN) == string.lower(trans.dest.destCellName or '') then
            Relocator.onPlayerEnteredCell(trans.dest.destCellName, '', false)
        end
    end
end

--- Release all grace-table entries and their OccupancyTracker slots.
-- Called on cell change to prevent stale state from accumulating.
function Relocator.clearAll()
    for reqId in pairs(pendingNavmeshRequests) do
        pendingNavmeshRequests[reqId] = nil
    end
    local count = 0
    for npcId, entry in pairs(graceTable) do
        OccupancyTracker.release(entry.dest.destCellName, npcId)
        count = count + 1
    end
    dbg("clearAll: released " .. tostring(count) .. " grace entries")
    graceTable = {}
    -- Also clear smooth-transition tables so stale callbacks don't fire.
    activeDepartures     = {}
    arrivingNpcs         = {}
    activeTransitions    = {}
    pendingArrivalWalks  = {}
    pendingExteriorReturns = {}
    pendingInstantArrivals = {}
end

-- =============================================================================

return Relocator
