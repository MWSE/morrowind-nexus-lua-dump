-- JSONScheduleModule.lua
-- Primary destination module for the ProceduralChatter NPC Scheduling System.
-- GLOBAL script context — registered with Scheduler and evaluated each tick.
--
-- Active window: ALWAYS (priority 100; no TimeWindow trigger).
--   JSON schedules are authoritative 24/7 for any NPC with an entry in ScheduleData.json.
--
-- Responsibilities:
--   • Query JSONScheduleManager each tick for candidates in the player's cell.
--   • Reserve OccupancyTracker slots BEFORE DynamicFallback runs (priority ordering).
--   • Teleport NPCs to their scheduled interior cell via Relocator.
--   • Detect mid-session schedule transitions (onUpdate) and move/return NPCs.
--   • On schedule gap or exterior block: return NPC to native position.
--
-- Registration: Scheduler.registerModule(JSONScheduleModule) at bottom of file.
-- JSONScheduleModule.onUpdate(dt, hour) must be wired in global.lua.

local core   = require('openmw.core')
local world  = require('openmw.world')
local types  = require('openmw.types')

local Config             = require('scripts.ProceduralChatter.data.ScheduleConfig')
local NPCState           = require('scripts.ProceduralChatter.NPCState')
local Blacklist          = require('scripts.ProceduralChatter.Blacklist')
local OccupancyTracker   = require('scripts.ProceduralChatter.schedule.OccupancyTracker')
local DestinationResolver = require('scripts.ProceduralChatter.schedule.DestinationResolver')
local JSONScheduleManager = require('scripts.ProceduralChatter.schedule.JSONScheduleManager')
local GeneratedScheduleManager = require('scripts.ProceduralChatter.schedule.GeneratedScheduleManager')
local TimeService        = require('scripts.ProceduralChatter.TimeService')
local Utils              = require('scripts.ProceduralChatter.Utils')
local PostArrivalCoordinator = require('scripts.ProceduralChatter.PostArrivalCoordinator')
local ConversationManager = require('scripts.ProceduralChatter.ConversationManager')
-- Scheduler required lazily inside onUpdate (circular dep avoidance)

-- =============================================================================
-- Module declaration
-- =============================================================================

local JSONScheduleModule = {
    id               = "JSONSchedule",
    priority         = 100,   -- highest; always pre-empts DynamicFallback
    -- Only requires player to be in a whitelisted city cell.
    -- No TimeWindow trigger — JSON schedules are active 24/7.
    requiredTriggers = { "PlayerCell:Whitelist" },
}

-- =============================================================================
-- Internal state
-- =============================================================================

-- Track what each NPC is currently scheduled for (so we can detect transitions).
-- activeAssignments[npcId] = {
--   recordId  = string,      -- lowercase NPC record ID
--   cellName  = string,      -- cell they are currently assigned to
-- }
local activeAssignments = {}

-- NPCs in working/conversation state deferred to next tick
local pendingNpcs = {}

-- Known NPC object references: knownNpcs[npcId] = npcObject
-- Populated whenever we observe an NPC in shouldEngage or onArrived.
-- Lets reconcileCell find NPCs that are now in inactive cells.
local knownNpcs = {}

-- Cached record IDs for NPCs we've seen.  Survives handle invalidation
-- (e.g. when a disabled NPC's cell unloads) so ADMIT can still check
-- their schedule and detect graceTable / in-transit states.
local knownNpcRecordIds = {}

-- Last integer hour we ran a reconcile pass, to avoid firing every frame.
local lastReconcileHour = -1

-- Smooth relocations deferred until an active player-side conversation plays Goodbye.
-- pendingRelocationAfterConversation[requestId] = { kind, npcId, npc, dest, ... }
local pendingRelocationAfterConversation = {}
local relocationRequestSeq = 0
local PENDING_RELOCATION_TIMEOUT = 45.0

local function getSimulationTime()
    local ok, t = pcall(core.getSimulationTime)
    return (ok and t) or 0
end

-- Log gate
local function dbg(msg)
    if Config.DEBUG_MODE then
        print("[JSONScheduleModule] " .. tostring(msg))
    end
end

-- =============================================================================
-- Helpers
-- =============================================================================

--- Returns true if npc is a valid, accessible actor object.
local function isObjValid(npc)
    if not npc then return false end
    local ok = pcall(function() local _ = npc.recordId end)
    return ok
end

local function getNpcCellName(npc)
    local name = nil
    pcall(function() name = npc.cell and (npc.cell.name or "") or nil end)
    return name
end

local function isNpcEnabled(npc)
    local enabled = false
    pcall(function() enabled = npc.enabled end)
    return enabled
end

local function refreshNpcById(npcId)
    if not npcId then return nil end

    local okA, activeActors = pcall(function() return world.activeActors end)
    if okA and activeActors then
        for _, actor in ipairs(activeActors) do
            local same = false
            pcall(function() same = actor.id == npcId end)
            if same and isObjValid(actor) then return actor end
        end
    end

    local okC, cells = pcall(function() return world.cells end)
    if okC and cells then
        for _, cell in ipairs(cells) do
            local okN, npcs = pcall(function() return cell:getAll(types.NPC) end)
            if okN and npcs then
                for _, npc in ipairs(npcs) do
                    local same = false
                    pcall(function() same = npc.id == npcId end)
                    if same and isObjValid(npc) then return npc end
                end
            end
        end
    end

    return nil
end

--- Get the lowercase record ID for an NPC. Returns nil on failure.
local function getRecordId(npc)
    local id = nil
    pcall(function() id = string.lower(npc.recordId) end)
    return id
end

--- Lazy-require Scheduler to avoid circular dependency at load time.
local function getScheduler()
    local ok, result = pcall(require, "scripts.ProceduralChatter.schedule.Scheduler")
    if ok then return result end
    return nil
end

local function recoverDisabledScheduledNpc(npc, recordId, targetCell, reason)
    if not isObjValid(npc) or not targetCell then return false end

    local npcId = npc.id
    local ok = pcall(function() npc.enabled = true end)
    if not ok then
        print(string.format("[JSONScheduleModule] RECOVER failed enable npc=%s (%s) reason=%s",
            tostring(npcId), tostring(recordId), tostring(reason)))
        return false
    end

    local Scheduler = getScheduler()
    if Scheduler and Scheduler.registerAssignment and not Scheduler.getAssignment(npcId) then
        Scheduler.registerAssignment(npcId, "JSONSchedule", {
            destCellName = targetCell,
            label = "JSON Reconcile Recovery",
        }, npc)
    end
    local assignment = Scheduler and Scheduler.getAssignment and Scheduler.getAssignment(npcId)
    if assignment then
        assignment.phase = "at_destination"
        assignment.npc = npc
    end

    NPCState.set(npcId, "at_destination")
    knownNpcs[npcId] = npc
    knownNpcRecordIds[npcId] = recordId
    activeAssignments[npcId] = {
        recordId = recordId,
        cellName = targetCell,
    }

    print(string.format("[JSONScheduleModule] RECOVER enabled scheduled npc=%s (%s) in '%s' reason=%s",
        tostring(npcId), tostring(recordId), tostring(targetCell), tostring(reason)))
    return true
end

local function clearNpcMovementForSchedule(npc, reason)
    if not isObjValid(npc) then return end
    dbg("Clearing movement for npc=" .. tostring(npc.id) .. " (" .. tostring(reason) .. ")")
    local npcId = npc.id
    local stale = NPCState.get(npcId)
    if stale == "returning" or stale == "activity" or stale == "walking" then
        NPCState.set(npcId, "idle")
    end
    pcall(function() npc:sendEvent("PC_ClearMovementState", {}) end)
    pcall(function() npc:sendEvent("PC_Stop", {}) end)
    pcall(function() npc:sendEvent("PC_StopActivity", { silent = true, forceClearAll = true }) end)
    pcall(function() npc:sendEvent("PC_StopWander", {}) end)
    core.sendGlobalEvent("PC_ActivityFinished", { npc = npc })
end

local function preemptNpcForSchedule(npc, reason)
    if not isObjValid(npc) then return end
    dbg("Preempting npc=" .. tostring(npc.id) .. " for schedule (" .. tostring(reason) .. ")")
    local okPlayer, player = pcall(function() return world.players[1] end)
    if okPlayer and player then
        pcall(function()
            player:sendEvent("PC_CancelAllConversations", { reason = reason or "schedule_preempt" })
        end)
    end
    clearNpcMovementForSchedule(npc, reason)
end

local function getExteriorNativeTarget(npc, recordId)
    local originCell, originPos, originRot = NPCState.loadNativeHome(npc)
    local targetPos = originPos or JSONScheduleManager.getBaseExteriorPos(recordId)
    return originCell, targetPos, originRot
end

local function buildInteriorDest(npc, targetCell, label, doorScanner)
    local dest = { destCellName = targetCell, label = label or "JSON Reconcile" }
    local scanner = doorScanner or npc
    pcall(function()
        DestinationResolver.primeDoorCacheFromNpcCell(scanner)
        local d = DestinationResolver.findDoorByDestCell(scanner, targetCell)
        if d then
            dest = d
            dest.label = label or "JSON Reconcile"
        end
    end)
    return dest
end

local function buildExteriorReturnDest(npc, recordId, playerCell, dayIndex, hour, doorScanner)
    if not isObjValid(npc) then return nil end
    local scanner = doorScanner or npc

    local originCell, targetPos, originRot = getExteriorNativeTarget(npc, recordId)
    if not targetPos then return nil end

    local targetCellName = originCell or ""
    pcall(function()
        if targetCellName == "" then
            targetCellName = playerCell and (playerCell.name or "") or ""
        end
    end)

    local dest = {
        destCellName = targetCellName,
        isReturn = true,
        exterior = true,
        doorInsidePos = targetPos,
        doorInsideRot = originRot,
        originCellName = originCell,
    }

    local source = JSONScheduleManager.getLastEndedInteriorAssignment(recordId, dayIndex, hour)
    if source then
        dest.sourceCellName = source.cellName
        dest.sourceTimeBlock = source.timeBlock
    end

    if source and source.isFreshEndHour and source.cellName then
        local sourceDest = nil
        pcall(function()
            DestinationResolver.primeDoorCacheFromNpcCell(scanner)
            sourceDest = DestinationResolver.findDoorByDestCell(scanner, source.cellName)
        end)
        if sourceDest and sourceDest.doorExteriorPos then
            dest.doorExteriorPos = sourceDest.doorExteriorPos
            dest.exteriorCellName = sourceDest.exteriorCellName
        end
    end

    print(string.format(
        "[JSONScheduleModule] exterior return dest npc=%s (%s) targetCell='%s' source='%s' block=%s fresh=%s doorExteriorPos=%s targetPos=%s",
        tostring(npc.id), tostring(recordId), tostring(targetCellName),
        tostring(source and source.cellName or "nil"),
        tostring(source and source.timeBlock or "nil"),
        tostring(source and source.isFreshEndHour or false),
        tostring(dest.doorExteriorPos), tostring(targetPos)))

    return dest
end

local function retargetQueuedNpcForCurrentSchedule(npcId, npcRef, recordId, playerCell, dayIndex, hour, targetCell, targetType, Relocator)
    if not Relocator or not Relocator.isQueued or not Relocator.isQueued(npcId) then return false end
    local hasLiveNpc = isObjValid(npcRef)
    local doorScanner = npcRef
    if not hasLiveNpc then
        pcall(function() doorScanner = world.players[1] end)
    end
    if not hasLiveNpc then
        npcRef = { id = npcId, recordId = recordId }
    end

    local Scheduler = getScheduler()
    if targetCell and targetType == "interior" then
        OccupancyTracker.reserve(targetCell, npcId)
        local dest = buildInteriorDest(npcRef, targetCell, "JSON Reconcile Queued Retarget", doorScanner)
        if Scheduler and Scheduler.registerAssignment then
            Scheduler.registerAssignment(npcId, "JSONSchedule", dest, hasLiveNpc and npcRef or nil)
        end
        print(string.format("[JSONScheduleModule] queued retarget npc=%s (%s) -> interior '%s'",
            tostring(npcId), tostring(recordId), tostring(targetCell)))
        Relocator.redirectToCell(npcId, dest)
        return true
    end

    local exteriorDest = buildExteriorReturnDest(npcRef, recordId, playerCell, dayIndex, hour, doorScanner)
    if not exteriorDest then
        print(string.format("[JSONScheduleModule] queued retarget FAIL npc=%s (%s) exterior return has no native target",
            tostring(npcId), tostring(recordId)))
        return true
    end

    if Scheduler and Scheduler.getAssignment and Scheduler.getAssignment(npcId)
            and Scheduler.clearAssignment then
        Scheduler.clearAssignment(npcId, "queued_exterior_return")
    end
    NPCState.set(npcId, "traveling_home")
    print(string.format("[JSONScheduleModule] queued retarget npc=%s (%s) -> exterior '%s'",
        tostring(npcId), tostring(recordId), tostring(exteriorDest.destCellName)))
    Relocator.redirectToCell(npcId, exteriorDest)
    return true
end

--- Cancel a stale visible departure, but never reposition a present exterior NPC.
-- Once the actor is enabled in the player's exterior, their walk/wander is
-- already part of the visible world. Reconcile should only materialize missing
-- NPCs, not leash enabled ones back to native at hour boundaries.
local function redirectExteriorDepartureIfStale(npcRef, recordId)
    if not isObjValid(npcRef) or not isNpcEnabled(npcRef) then return end
    local _, targetPos, originRot = getExteriorNativeTarget(npcRef, recordId)
    if not targetPos then return end

    local Relocator = nil
    pcall(function()
        Relocator = require("scripts.ProceduralChatter.schedule.Relocator")
    end)
    if not Relocator then return end

    local npcId = npcRef.id
    if Relocator.isDeparting and Relocator.isDeparting(npcId)
            and Relocator.redirectDepartureToExteriorReturn then
        local redirected = Relocator.redirectDepartureToExteriorReturn(npcRef, targetPos)
        if redirected then
            print(string.format("[JSONScheduleModule] redirected active departure to native npc=%s (%s)",
                tostring(npcId), tostring(recordId)))
            return
        end
    end
end

local function executeInteriorEvictDispatch(npc, npcId, dest, allowSmooth)
    local Scheduler = getScheduler()
    if Scheduler and Scheduler.registerAssignment then
        Scheduler.registerAssignment(npcId, "JSONSchedule", dest, npc)
    end
    local Relocator = nil
    pcall(function() Relocator = require("scripts.ProceduralChatter.schedule.Relocator") end)
    if not Relocator then
        print(string.format("[JSONScheduleModule] executeInteriorEvictDispatch ABORT npc=%s (Relocator unavailable)",
            tostring(npcId)))
        return
    end
    if allowSmooth then
        Relocator.dispatchSmooth(npc, dest, "JSONSchedule")
    else
        Relocator.dispatch(npc, dest, "JSONSchedule")
    end
end

--- Ask the player script to play Goodbye for any active conversation involving npcId,
--- then run the queued relocation when PC_ScheduleInterruptComplete fires.
function JSONScheduleModule.deferRelocationForConversation(npc, npcId, plan)
    relocationRequestSeq = relocationRequestSeq + 1
    local requestId = string.format("reloc:%s:%d", tostring(npcId), relocationRequestSeq)
    plan.npcId = npcId
    plan.npc = npc
    plan.deadline = getSimulationTime() + PENDING_RELOCATION_TIMEOUT
    pendingRelocationAfterConversation[requestId] = plan

    -- Player-side ConversationManager lives on the player script. sendGlobalEvent
    -- from this global module does not reach player eventHandlers; use sendEvent.
    local okPlayer, player = pcall(function() return world.players[1] end)
    if okPlayer and player then
        local okSend = pcall(function()
            player:sendEvent("PC_ScheduleInterruptConversation", {
                npcId = npcId,
                requestId = requestId,
            })
        end)
        if okSend then
            print(string.format("[JSONScheduleModule] deferred relocation npc=%s (%s) request=%s (player event)",
                tostring(npcId), tostring(plan.recordId or "?"), requestId))
            return requestId
        end
    end

    print(string.format("[JSONScheduleModule] deferred relocation FALLBACK immediate npc=%s request=%s",
        tostring(npcId), requestId))
    JSONScheduleModule.onScheduleInterruptComplete({
        requestId = requestId,
        npcId = npcId,
        immediate = true,
    })
    return requestId
end

--- Flush relocations that never received PC_ScheduleInterruptComplete (safety net).
function JSONScheduleModule.tickPendingRelocations(_dt)
    local now = getSimulationTime()
    local toFlush = {}
    for requestId, plan in pairs(pendingRelocationAfterConversation) do
        if plan.deadline and now >= plan.deadline then
            toFlush[#toFlush + 1] = { requestId = requestId, npcId = plan.npcId }
        end
    end
    for _, entry in ipairs(toFlush) do
        print(string.format("[JSONScheduleModule] pending relocation TIMEOUT request=%s npc=%s",
            tostring(entry.requestId), tostring(entry.npcId)))
        JSONScheduleModule.onScheduleInterruptComplete({
            requestId = entry.requestId,
            npcId = entry.npcId,
            timedOut = true,
        })
    end
end

function JSONScheduleModule.onScheduleInterruptComplete(ev)
    if not ev or not ev.requestId then return end
    local plan = pendingRelocationAfterConversation[ev.requestId]
    if not plan then return end
    pendingRelocationAfterConversation[ev.requestId] = nil

    local npcId = plan.npcId
    local npc = plan.npc
    if not isObjValid(npc) then
        npc = knownNpcs[npcId]
    end
    if not isObjValid(npc) then
        print(string.format("[JSONScheduleModule] schedule interrupt complete: npc invalid %s", tostring(npcId)))
        return
    end

    print(string.format("[JSONScheduleModule] schedule interrupt complete npc=%s request=%s kind=%s",
        tostring(npcId), tostring(ev.requestId), tostring(plan.kind)))

    clearNpcMovementForSchedule(npc, "schedule_goodbye_complete")

    if plan.kind == "interior_evict" then
        executeInteriorEvictDispatch(npc, npcId, plan.dest, plan.allowSmooth)
    end
end

local function collectCellNpcs(cell)
    return Utils.collectCellNpcs(cell)
end

-- =============================================================================
-- resolveDestination (used by Scheduler handoff system)
-- =============================================================================

--- Resolve the current scheduled destination for an NPC.
-- Returns a dest table for the Scheduler/Relocator, or nil if no assignment.
-- @param npc  Actor object
-- @return dest table or nil
function JSONScheduleModule.resolveDestination(npc)
    if not isObjValid(npc) then return nil end

    local recordId = getRecordId(npc)
    if not recordId then return nil end

    local dayIndex = TimeService.getDayIndex()
    local hour     = TimeService.getHour()

    local cellName, cellType = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, hour)
    if not cellName or cellType == "exterior" then return nil end

    -- Try to find the actual door for proper interior positioning.
    -- If NPC is in a loaded cell, scan doors; otherwise return cell-name-only dest.
    local dest = nil
    local ok = pcall(function()
        if npc.cell and not npc.cell.isExterior then
            -- NPC already inside — can't door-scan from here for a different cell
            dest = { destCellName = cellName, label = "JSON Schedule" }
        else
            dest = DestinationResolver.findDoorByDestCell(npc, cellName)
            if not dest then
                dest = { destCellName = cellName, label = "JSON Schedule" }
            end
        end
    end)
    if not ok or not dest then
        dest = { destCellName = cellName, label = "JSON Schedule" }
    end

    return dest
end

-- =============================================================================
-- shouldEngage
-- =============================================================================

--- Evaluate which candidates should be dispatched this tick.
-- Only proposes NPCs that have a JSON schedule entry for the current time.
--
-- @param  triggerState  map of { [triggerId] = bool }
-- @param  candidates    array of NPC objects (pre-filtered by Scheduler)
-- @return array of { npc = object, dest = table } proposals
function JSONScheduleModule.shouldEngage(triggerState, candidates)
    local proposals = {}
    local dayIndex  = TimeService.getDayIndex()
    local hour      = TimeService.getHour()

    -- ------------------------------------------------------------------
    -- 1. Retry pending NPCs from previous tick(s)
    -- ------------------------------------------------------------------
    for npcId, npc in pairs(pendingNpcs) do
        if not isObjValid(npc) then
            pendingNpcs[npcId] = nil
        else
            local state = NPCState.get(npcId)
            if NPCState.canActivity(npcId) then
                pendingNpcs[npcId] = nil
                table.insert(candidates, npc)
            end
            -- If still working/conversation, leave for next tick
        end
    end

    -- ------------------------------------------------------------------
    -- 2. Prime door cache once for the player's cell
    -- ------------------------------------------------------------------
    if #candidates > 0 then
        pcall(function() DestinationResolver.primeDoorCacheFromNpcCell(candidates[1]) end)
    end

    -- ------------------------------------------------------------------
    -- 3. Evaluate each candidate
    -- ------------------------------------------------------------------
    for _, npc in ipairs(candidates) do
        if not isObjValid(npc) then goto continue end

        local recordId = getRecordId(npc)
        if not recordId then goto continue end

        local player = world.players[1]
        GeneratedScheduleManager.ensureGeneratedForActor(npc, player)

        -- Only handle NPCs in the JSON/generated schedule
        if not JSONScheduleManager.hasSchedule(recordId) then goto continue end

        if Blacklist.isScheduleBlacklisted(npc, player) then goto continue end
        if NPCState.isHostile(npc.id) then goto continue end

        -- State eligibility
        local state = NPCState.get(npc.id)
        if state == "activity" or state == "conversation" then
            if not NPCState.isInTransit(npc.id) and not NPCState.isScheduled(npc.id) then
                preemptNpcForSchedule(npc, "shouldEngage")
            end
        elseif not NPCState.canActivity(npc.id) then
            goto continue
        end

        -- Query schedule
        local cellName, cellType = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, hour)

        -- No schedule block or exterior placeholder: leave NPC at native position
        if not cellName or cellType == "exterior" then goto continue end

        -- Reserve occupancy NOW — JSON NPCs have first claim on slots
        if not OccupancyTracker.reserve(cellName, npc.id) then
            print(string.format("[JSONScheduleModule] shouldEngage occupancy full npc=%s (%s) -> %s", tostring(npc.id), recordId, cellName))
            goto continue
        end

        -- Build dest table: try to find the door for proper inside-pos data
        local dest = nil
        pcall(function()
            DestinationResolver.primeDoorCacheFromNpcCell(npc)
            dest = DestinationResolver.findDoorByDestCell(npc, cellName)
        end)
        if not dest then
            dest = { destCellName = cellName, label = "JSON Schedule" }
        else
            dest.label = "JSON Schedule"
        end

        -- Track object reference for reconcileCell lookups
        knownNpcs[npc.id] = npc
        knownNpcRecordIds[npc.id] = recordId

        print(string.format("[JSONScheduleModule] shouldEngage PROPOSAL npc=%s (%s) -> '%s' doorInsidePos=%s",
            tostring(npc.id), recordId, cellName, tostring(dest.doorInsidePos)))
        table.insert(proposals, { npc = npc, dest = dest })

        ::continue::
    end

    if #proposals > 0 then
        print(string.format("[JSONScheduleModule] shouldEngage END proposals=%d", #proposals))
    end
    return proposals
end

-- =============================================================================
-- onArrived
-- =============================================================================

--- Called by Scheduler when an NPC arrives at their scheduled destination.
-- @param npc   Actor object
-- @param dest  dest table from resolveDestination / shouldEngage
function JSONScheduleModule.onArrived(npc, dest)
    if not isObjValid(npc) then
        print("[JSONScheduleModule] onArrived ABORT invalid npc")
        return
    end

    local recordId = getRecordId(npc)
    print(string.format("[JSONScheduleModule] onArrived npc=%s (%s) cell='%s'",
        tostring(npc.id), tostring(recordId), tostring(dest and dest.destCellName or "?")))

    NPCState.set(npc.id, "at_destination")
    NPCState.setArrivalCooldown(npc.id)

    -- Track object reference for reconcileCell lookups
    knownNpcs[npc.id] = npc
    knownNpcRecordIds[npc.id] = recordId

    -- Track for transition detection in onUpdate
    activeAssignments[npc.id] = {
        recordId = recordId,
        cellName = dest and dest.destCellName or nil,
    }

    -- Let the coordinator decide post-arrival behavior instead of blindly starting wander.
    PostArrivalCoordinator.evaluate(npc, "materialized")
    print(string.format("[JSONScheduleModule] onArrived coordinator evaluated npc=%s", tostring(npc.id)))
end

-- =============================================================================
-- onDepart
-- =============================================================================

--- Called by Scheduler when this module releases an NPC.
-- Releases occupancy, teleports NPC back to their native exterior position,
-- and restores their original wander behavior.
--
-- @param npc         Actor object
-- @param assignment  The assignment record from Scheduler
function JSONScheduleModule.onDepart(npc, assignment)
    local dest = assignment and assignment.dest
    local npcId = isObjValid(npc) and npc.id or "INVALID"
    print(string.format("[JSONScheduleModule] onDepart START npc=%s dest='%s'", tostring(npcId), tostring(dest and dest.destCellName or "nil")))

    -- Release occupancy slot
    if dest and dest.destCellName then
        if isObjValid(npc) then
            OccupancyTracker.release(dest.destCellName, npc.id)
            print(string.format("[JSONScheduleModule] onDepart released occupancy '%s' npc=%s", dest.destCellName, tostring(npc.id)))
        end
    end

    -- Remove from transition tracking
    if isObjValid(npc) then
        activeAssignments[npc.id] = nil
    end

    -- Return NPC to their exterior home position.
    if isObjValid(npc) then
        local Relocator = nil
        pcall(function()
            Relocator = require("scripts.ProceduralChatter.schedule.Relocator")
        end)
        if not Relocator then
            print(string.format("[JSONScheduleModule] onDepart ABORT no Relocator npc=%s", tostring(npc.id)))
            pcall(function() npc.enabled = false end)
            NPCState.clear(npc.id)
            return
        end

        local recordId = string.lower(npc.recordId)
        local originCellD, originPosD, originRotD = getExteriorNativeTarget(npc, recordId)
        local extPos = JSONScheduleManager.getBaseExteriorPos(recordId)
        print(string.format("[JSONScheduleModule] onDepart npc=%s originCell='%s' originPos=%s baseExtPos=%s",
            tostring(npc.id), tostring(originCellD), tostring(originPosD), tostring(extPos)))
        if originPosD then
            Relocator.queueReturnSmooth(npc, originCellD or "", originPosD, originRotD, { exterior = true })
        else
            -- No persisted native home; fall back to schedule BaseExterior grid point.
            if extPos then
                Relocator.queueReturnSmooth(npc, "", extPos, nil, { exterior = true })
            else
                print(string.format("[JSONScheduleModule] onDepart no origin, disabling npc=%s", tostring(npc.id)))
                pcall(function() npc.enabled = false end)
                NPCState.clear(npc.id)
            end
        end
    else
        print("[JSONScheduleModule] onDepart SKIP invalid npc handle")
    end
    print(string.format("[JSONScheduleModule] onDepart END npc=%s", tostring(npcId)))
end

-- =============================================================================
-- Debug roster dump
-- =============================================================================

local function dumpCellRoster(playerCell, dayIndex, hour)
    if not Config.DEBUG_MODE then return end
    local cellName = ""
    pcall(function() cellName = playerCell.name or "" end)
    local cellIsExterior = false
    pcall(function() cellIsExterior = playerCell.isExterior end)
    local loCellName = string.lower(cellName)
    print(string.format("\n[JSONScheduleModule] ===== ROSTER for '%s' (exterior=%s) hour=%.1f =====", cellName, tostring(cellIsExterior), hour))

    local Relocator = nil
    pcall(function() Relocator = require("scripts.ProceduralChatter.schedule.Relocator") end)

    local scheduled = {}
    for npcId, recordId in pairs(knownNpcRecordIds) do
        if JSONScheduleManager.hasSchedule(recordId) then
            local targetCell, targetType, assignDetails = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, hour)
            local shouldBeHere = false
            if cellIsExterior then
                shouldBeHere = not (targetCell and targetType == "interior")
            else
                shouldBeHere = targetCell and targetType == "interior" and string.lower(targetCell) == loCellName
            end

            local npcRef = knownNpcs[npcId]
            local valid = isObjValid(npcRef)
            local enabled = false
            if valid then
                pcall(function() enabled = npcRef.enabled end)
            end
            local state = NPCState.get(npcId)

            local location = "UNKNOWN"
            if valid then
                pcall(function() location = npcRef.cell and npcRef.cell.name or "?" end)
            else
                location = "STALE_HANDLE"
            end

            local inGrace = false
            local inTransit = false
            local departing = false
            if Relocator then
                pcall(function() inGrace = Relocator.isQueued(npcId) end)
                pcall(function() inTransit = Relocator.isInTransit(npcId) end)
                pcall(function() departing = Relocator.isDeparting(npcId) end)
            end

            table.insert(scheduled, {
                npcId = npcId,
                recordId = recordId,
                targetCell = targetCell or "nil",
                targetType = targetType or "nil",
                shouldBeHere = shouldBeHere,
                valid = valid,
                enabled = enabled,
                state = state or "nil",
                location = location,
                inGrace = inGrace,
                inTransit = inTransit,
                departing = departing,
            })
        end
    end

    for _, info in ipairs(scheduled) do
        local presence = info.valid and (info.enabled and "PRESENT_ENABLED" or "PRESENT_DISABLED") or "NO_HANDLE"
        print(string.format("[ROSTER] %s (%s) -> target='%s' (%s) shouldBeHere=%s | %s | state=%s | loc='%s' | grace=%s transit=%s depart=%s",
            info.npcId, info.recordId, info.targetCell, info.targetType,
            tostring(info.shouldBeHere), presence, tostring(info.state), info.location,
            tostring(info.inGrace), tostring(info.inTransit), tostring(info.departing)))
    end
    print(string.format("[JSONScheduleModule] ===== END ROSTER (%d scheduled) =====\n", #scheduled))
end

-- =============================================================================
-- reconcileCell — authoritative schedule check for a cell
-- =============================================================================

--- Check every JSON-scheduled NPC against the current schedule for a given cell.
-- Called on cell entry and whenever the integer hour changes.
--
-- Evict: disable any NPC in the cell that shouldn't be there per schedule.
--        Queue them (via graceTable) for their correct destination or origin.
--
-- Admit: for any NPC that SHOULD be in this cell but isn't:
--        • redirect if they're already queued in graceTable for the wrong cell,
--        • or dispatch them from wherever they currently are.
--
-- @param playerCell  cell object   — the cell the player is currently in
-- @param dayIndex    number        — 0-6
-- @param hour        number        — fractional game hour
function JSONScheduleModule.reconcileCell(playerCell, dayIndex, hour)
    if not playerCell then return end
    local cellName = ""
    local ok = pcall(function() cellName = playerCell.name or "" end)
    if not ok or cellName == "" then return end
    local loCellName = string.lower(cellName)

    if not Config.SCHEDULE_ENABLED then
        if Config.DEBUG_MODE then
            print(string.format("[JSONScheduleModule] reconcileCell SKIP (schedules disabled) cell='%s'", cellName))
        end
        return
    end
    if not Config.SCHEDULE_MOVEMENT_ENABLED then
        if Config.DEBUG_MODE then
            print(string.format("[JSONScheduleModule] reconcileCell SKIP (schedule movement disabled) cell='%s'", cellName))
        end
        return
    end

    -- Is the current cell an exterior?
    local cellIsExterior = false
    pcall(function() cellIsExterior = playerCell.isExterior end)

    print(string.format("[JSONScheduleModule] reconcileCell START cell='%s' exterior=%s hour=%.1f day=%d",
        cellName, tostring(cellIsExterior), hour, dayIndex))

    dumpCellRoster(playerCell, dayIndex, hour)

    local Relocator = nil
    pcall(function() Relocator = require("scripts.ProceduralChatter.schedule.Relocator") end)
    if not Relocator then return end

    -- -------------------------------------------------------------------------
    -- 1. EVICT — remove NPCs that are in this cell but shouldn't be
    --
    -- Eviction rules:
    --   In an EXTERIOR cell: only evict if the NPC has an active INTERIOR
    --     assignment elsewhere.  nil/gap/exterior means the NPC naturally
    --     belongs in the exterior — do not touch them.
    --   In an INTERIOR cell: evict if the schedule says a different interior OR
    --     nil/gap/exterior (they need to return to their origin exterior).
    -- -------------------------------------------------------------------------
    local actors = collectCellNpcs(playerCell)
    local inCell = {}  -- npcId -> npc, for admission check below
    local jsonSeen = 0
    local player = world and world.players and world.players[1]
    dbg("reconcileCell: npcCountInCell=" .. tostring(#actors))
    for _, npc in ipairs(actors) do
        local npcId = npc.id
        -- [Diagnostic] Only consider enabled NPCs as "Present" in the cell.
        -- If they are disabled, they are invisible and we want the ADMIT pass
        -- to try and materialise them properly.
        if npc.enabled then
            inCell[npcId] = npc
        end
        knownNpcs[npcId] = npc  -- keep reference fresh

        local recordId = getRecordId(npc)
        if recordId then knownNpcRecordIds[npcId] = recordId end
        if not recordId then goto nextEvict end
        if NPCState.isHostile(npcId) then
            print(string.format("[JSONScheduleModule] EVICT skip hostile npc=%s (%s)", tostring(npcId), recordId))
            goto nextEvict
        end
        GeneratedScheduleManager.ensureGeneratedForActor(npc, player)
        if not JSONScheduleManager.hasSchedule(recordId) then goto nextEvict end
        jsonSeen = jsonSeen + 1

        local targetCell, targetType, assignDetails = JSONScheduleManager.getCurrentAssignment(
            recordId, dayIndex, hour)
            -- Determine whether this NPC belongs in the current cell right now.
            local shouldBeHere
            if cellIsExterior then
                -- Exterior: NPC belongs here when they have no interior assignment.
                -- Only evict if they have a specific interior they should be in.
                shouldBeHere = not (targetCell and targetType == "interior")
            else
                -- Interior: NPC belongs here only if the schedule names THIS cell.
                shouldBeHere = targetCell
                    and targetType == "interior"
                    and string.lower(targetCell) == loCellName
            end

            dbg("RECON npc=" .. tostring(npcId)
                .. " (" .. tostring(recordId) .. ")"
                .. " state=" .. tostring(NPCState.get(npcId))
                .. " targetCell='" .. tostring(targetCell) .. "'"
                .. " targetType=" .. tostring(targetType)
                .. " shouldBeHere=" .. tostring(shouldBeHere)
                .. " startHour=" .. tostring(assignDetails and assignDetails.isStartHour or false)
                .. " block=" .. tostring(assignDetails and assignDetails.timeBlock or "nil"))

        -- Guard: skip NPCs already in transit (graceTable = disabled and queued,
        -- or activeDepartures = walking to exit door). Both states mean the NPC
        -- is already being handled; evicting them now would cause a double-dispatch.
        -- Note: dispatch() anchors disabled NPCs to the exterior cell before
        -- disabling them, so collectCellNpcs() can still see them here even though
        -- they are invisible and scheduled for a different destination.
        -- Only skip true in-transit NPCs that are not visibly present in this
        -- reconciled cell. This avoids stale transit flags (e.g. missed
        -- arrival-complete cleanup) blocking normal reconcile decisions.
        if (Relocator.isInTransit(npcId) or Relocator.isQueued(npcId))
                and not inCell[npcId] then
            local why = "in_transit"
            if Relocator.getTransitReason then
                why = Relocator.getTransitReason(npcId)
            end
            dbg("RECON skip (in transit) npc=" .. tostring(npcId) .. " reason=" .. tostring(why))
            goto nextEvict
        end

        if not shouldBeHere then
                -- If this NPC is already assigned/traveling to the exact target
                -- interior, do not let reconcile yank it back mid-dispatch.
                local Scheduler = getScheduler()
                local assignment = Scheduler and Scheduler.getAssignment(npcId)
                local assignmentMatchesTarget = false
                if assignment and assignment.dest and targetCell and targetType == "interior" then
                    assignmentMatchesTarget = string.lower(assignment.dest.destCellName or "") == string.lower(targetCell)
                end
                if assignmentMatchesTarget
                        and (Relocator.isInTransit(npcId) or NPCState.get(npcId) == "departing") then
                    print(string.format("[JSONScheduleModule] EVICT HOLD npc=%s (already traveling to current target)", tostring(npcId)))
                    goto nextEvict
                end

                print(string.format("[JSONScheduleModule] EVICT npc=%s (%s) from '%s' -> should be '%s'",
                    tostring(npcId), recordId, cellName, tostring(targetCell)))

                local Scheduler = getScheduler()
                local existingAssignment = Scheduler and Scheduler.getAssignment(npcId)
                if existingAssignment and not (targetCell and targetType == "interior") then
                    -- Let the module's onDepart handle cleanup + queueReturn
                    print(string.format("[JSONScheduleModule] EVICT releaseAssignment npc=%s", tostring(npcId)))
                    Scheduler.releaseAssignment(npcId, "reconcile_evict")
                else
                    if existingAssignment and Scheduler.clearAssignment then
                        print(string.format("[JSONScheduleModule] EVICT replacing stale assignment npc=%s old='%s' new='%s'",
                            tostring(npcId),
                            tostring(existingAssignment.dest and existingAssignment.dest.destCellName or "nil"),
                            tostring(targetCell)))
                        if existingAssignment.dest and existingAssignment.dest.destCellName then
                            OccupancyTracker.release(existingAssignment.dest.destCellName, npcId)
                        end
                        Scheduler.clearAssignment(npcId, "reconcile_replace_assignment")
                    end
                    -- Stranded NPC (no Scheduler assignment): route manually
                    print(string.format("[JSONScheduleModule] EVICT manual route npc=%s targetCell='%s' targetType='%s'",
                        tostring(npcId), tostring(targetCell), tostring(targetType)))
                    -- Clear sitting/activity state so the NPC can be teleported.
                    pcall(function() npc:sendEvent("PC_CancelTravelToSeat", {}) end)
                    pcall(function() npc:sendEvent("PC_StandUpPlease", {}) end)
                    core.sendGlobalEvent("PC_CancelSittingForNpc", { npc = npc, reason = "reconcile_evict" })
                    if targetCell and targetType == "interior" then
                        -- Should be in a specific interior.
                        -- Fresh block start hour: allow immersive route.
                        -- Older block hour: snap/fallback route.
                        OccupancyTracker.reserve(targetCell, npcId)
                        local dest = { destCellName = targetCell, label = "JSON Reconcile" }
                        pcall(function()
                            DestinationResolver.primeDoorCacheFromNpcCell(npc)
                            local d = DestinationResolver.findDoorByDestCell(npc, targetCell)
                            if d then dest = d; dest.label = "JSON Reconcile" end
                        end)
                        print(string.format("[JSONScheduleModule] EVICT dispatch npc=%s dest='%s' doorInsidePos=%s",
                            tostring(npcId), tostring(dest.destCellName), tostring(dest.doorInsidePos)))
                        local allowSmooth = assignDetails and assignDetails.isStartHour
                        if ConversationManager and ConversationManager.isActive(npc) then
                            JSONScheduleModule.deferRelocationForConversation(npc, npcId, {
                                kind = "interior_evict",
                                recordId = recordId,
                                dest = dest,
                                allowSmooth = allowSmooth,
                            })
                        else
                            preemptNpcForSchedule(npc, "reconcile_evict")
                            executeInteriorEvictDispatch(npc, npcId, dest, allowSmooth)
                        end
                    else
                        -- Gap or exterior schedule: return to origin exterior.
                        local originCell, originPos, originRot = NPCState.loadNativeHome(npc)
                        print(string.format("[JSONScheduleModule] EVICT return home npc=%s originCell='%s' originPos=%s",
                            tostring(npcId), tostring(originCell), tostring(originPos)))
                        if originCell and originPos then
                            Relocator.queueReturnSmooth(npc, originCell, originPos, originRot, { exterior = true })
                        else
                            -- No saved origin (old format or first session).
                            -- Fall back to BaseExterior grid coordinates from ScheduleData.
                            -- Empty cellName = exterior world; teleported directly since
                            -- the exterior is always loaded.
                            local extPos = JSONScheduleManager.getBaseExteriorPos(recordId)
                            if extPos then
                                print(string.format("[JSONScheduleModule] EVICT base exterior fallback npc=%s pos=%s",
                                    tostring(npcId), tostring(extPos)))
                                Relocator.queueReturnSmooth(npc, "", extPos, nil, { exterior = true })
                            else
                                -- No data at all: just disable and release.
                                print(string.format("[JSONScheduleModule] EVICT no origin data npc=%s; disabling", tostring(npcId)))
                                local Scheduler = getScheduler()
                                if Scheduler and Scheduler.getAssignment(npcId) then
                                    Scheduler.releaseAssignment(npcId, "reconcile_evict_no_origin")
                                else
                                    pcall(function() npc.enabled = false end)
                                    NPCState.clear(npcId)
                                end
                            end
                        end
                    end
                end
        else
            if not isNpcEnabled(npc) then
                recoverDisabledScheduledNpc(npc, recordId, targetCell or cellName, "evict_keep_disabled")
                inCell[npcId] = npc
            elseif shouldBeHere and cellIsExterior and targetType ~= "interior" then
                redirectExteriorDepartureIfStale(npc, recordId)
            end
            print(string.format("[JSONScheduleModule] EVICT KEEP npc=%s (%s) shouldBeHere=%s",
                tostring(npcId), recordId, tostring(shouldBeHere)))
        end
        ::nextEvict::
    end
    print(string.format("[JSONScheduleModule] EVICT pass done: jsonSeen=%d", jsonSeen))

    -- -------------------------------------------------------------------------
    local loCellName = string.lower(cellName)

    -- [Diagnostic] Track NPCs that should be here but aren't found in inCell.
    local admitCandidates = {}
    local missingScheduled = {}

    -- 2. ADMIT — bring in NPCs that should be in this cell but aren't.
    -- For interiors: use existing admit behavior.
    -- For exteriors: also pull scheduled-exterior NPCs out of interiors via Relocator.
    -- -------------------------------------------------------------------------
    -- Iterate all NPC references we've seen and any active actors in the world
    -- to find NPCs scheduled for this cell that haven't materialised yet.

    -- Also scan world.activeActors so we can catch NPCs we haven't seen before
    local okW, activeAll = pcall(function() return world.activeActors end)
    if okW and activeAll then
        for _, actor in ipairs(activeAll) do
            if types.NPC.objectIsInstance(actor) then
                knownNpcs[actor.id] = actor
                local rid = getRecordId(actor)
                if rid then knownNpcRecordIds[actor.id] = rid end
            end
        end
    end

    -- Schedule-driven scan: query the JSON data directly for NPCs scheduled
    -- for this cell. Exterior reconciliation asks for every NPC whose current
    -- assignment is exterior/gap so observed interior visitors can be pulled
    -- home even if the known-NPC cache was cold.
    local scheduledRecordIds = {}
    if cellIsExterior and JSONScheduleManager.getExteriorScheduledNpcs then
        scheduledRecordIds = JSONScheduleManager.getExteriorScheduledNpcs(dayIndex, hour)
    else
        scheduledRecordIds = JSONScheduleManager.getNpcsForCell(cellName, dayIndex, hour)
    end
    if #scheduledRecordIds > 0 then
        -- Build set of recordIds that have a live handle or are already queued.
        -- Stale, unqueued handles must not suppress loaded-cell discovery.
        local knownRecordIds = {}
        for knownNpcId, rid in pairs(knownNpcRecordIds) do
            if isObjValid(knownNpcs[knownNpcId]) or Relocator.isQueued(knownNpcId) then
                knownRecordIds[rid] = true
            end
        end
        for _, rid in ipairs(scheduledRecordIds) do
            if not knownRecordIds[rid] then
                -- Try to find this NPC in active actors first
                local found = false
                if okW and activeAll then
                    for _, actor in ipairs(activeAll) do
                        if types.NPC.objectIsInstance(actor) then
                            local arid = nil
                            pcall(function() arid = string.lower(actor.recordId) end)
                            if arid == rid then
                                knownNpcs[actor.id] = actor
                                knownNpcRecordIds[actor.id] = rid
                                print(string.format("[JSONScheduleModule] ADMIT DISCOVER npc=%s (%s) in activeActors", tostring(actor.id), rid))
                                found = true
                                break
                            end
                        end
                    end
                end
                -- If not in activeActors, scan loaded cells
                if not found then
                    local okC, cells = pcall(function() return world.cells end)
                    if okC and cells then
                        for _, cell in ipairs(cells) do
                            local okN, npcs = pcall(function() return cell:getAll(types.NPC) end)
                            if okN and npcs then
                                for _, npc in ipairs(npcs) do
                                    local nrid = nil
                                    pcall(function() nrid = string.lower(npc.recordId) end)
                                    if nrid == rid then
                                        knownNpcs[npc.id] = npc
                                        knownNpcRecordIds[npc.id] = rid
                                        print(string.format("[JSONScheduleModule] ADMIT DISCOVER npc=%s (%s) in cell='%s'", tostring(npc.id), rid, tostring(cell.name or "?")))
                                        found = true
                                        break
                                    end
                                end
                            end
                            if found then break end
                        end
                    end
                end
                if not found then
                    print(string.format("[JSONScheduleModule] ADMIT MISSING scheduled recordId=%s for '%s' (not in any loaded cell)", rid, cellName))
                end
            end
        end
    end

    -- Build a merged set of all NPC IDs we've ever seen (handles + cached recordIds).
    -- This lets ADMIT catch scheduled NPCs even after their handle was purged.
    local allNpcIds = {}
    for npcId, _ in pairs(knownNpcs) do allNpcIds[npcId] = true end
    for npcId, _ in pairs(knownNpcRecordIds) do allNpcIds[npcId] = true end

    local allNpcIdsCount = 0
    for _ in pairs(allNpcIds) do allNpcIdsCount = allNpcIdsCount + 1 end
    local inCellCount = 0
    for _ in pairs(inCell) do inCellCount = inCellCount + 1 end
    print(string.format("[JSONScheduleModule] ADMIT pass start: allNpcIds=%d inCell=%d", allNpcIdsCount, inCellCount))

    for npcId, _ in pairs(allNpcIds) do
        local npcRef = knownNpcs[npcId]
        local recordId = nil

        if isObjValid(npcRef) then
            recordId = getRecordId(npcRef)
            if recordId then knownNpcRecordIds[npcId] = recordId end
        else
            -- Stale handle (cell unloaded).  Use cached recordId if we have one.
            recordId = knownNpcRecordIds[npcId]
            if not recordId then
                knownNpcs[npcId] = nil
                knownNpcRecordIds[npcId] = nil
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (no recordId, purged)", tostring(npcId)))
                goto nextAdmit
            end
            if Relocator.isQueued(npcId) then
                print(string.format("[JSONScheduleModule] ADMIT queued npc=%s has stale handle; retargeting from cached recordId", tostring(npcId)))
                npcRef = { id = npcId, recordId = recordId }
            else
                -- Not queued and no handle — genuinely lost.  Log and skip.
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (stale handle, NOT QUEUED — cannot dispatch)", tostring(npcId)))
                goto nextAdmit
            end
        end

        if not recordId then
            print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (no recordId)", tostring(npcId)))
            goto nextAdmit
        end
        if NPCState.isHostile(npcId) then
            print(string.format("[JSONScheduleModule] ADMIT skip hostile npc=%s (%s)", tostring(npcId), recordId))
            goto nextAdmit
        end
        if not JSONScheduleManager.hasSchedule(recordId) then
            print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (no schedule)", tostring(npcId), recordId))
            goto nextAdmit
        end

        local targetCell, targetType, assignDetails = JSONScheduleManager.getCurrentAssignment(
            recordId, dayIndex, hour)

        if Relocator.isQueued(npcId) then
            retargetQueuedNpcForCurrentSchedule(
                npcId, npcRef, recordId, playerCell, dayIndex, hour,
                targetCell, targetType, Relocator)
            goto nextAdmit
        end

        -- Cell-target filtering by player cell type.
        if cellIsExterior then
            -- In exterior reconcile, we only care about NPCs whose active schedule
            -- is not interior (explicit exterior OR schedule gap). These NPCs may
            -- currently still be inside interiors and need to be pulled out.
            if targetType == "interior" then
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (exterior reconcile, target is interior '%s')",
                    tostring(npcId), recordId, tostring(targetCell)))
                goto nextAdmit
            end
        else
            -- Interior reconcile keeps existing rule: target must match this interior.
            if not targetCell or targetType ~= "interior" then
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (interior reconcile, target not interior: '%s'/%s)",
                    tostring(npcId), recordId, tostring(targetCell), tostring(targetType)))
                goto nextAdmit
            end
            if string.lower(targetCell) ~= loCellName then
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (interior reconcile, target '%s' != '%s')",
                    tostring(npcId), recordId, tostring(targetCell), loCellName))
                goto nextAdmit
            end
        end

        -- Already in this cell?
        if inCell[npcId] then
            if cellIsExterior and targetType ~= "interior" then
                redirectExteriorDepartureIfStale(npcRef, recordId)
            end
            print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (already in cell, enabled)", tostring(npcId), recordId))
            goto nextAdmit
        end

        local npcCellName = getNpcCellName(npcRef)
        if npcCellName and string.lower(npcCellName) == loCellName
                and not isNpcEnabled(npcRef)
                and not Relocator.isQueued(npcId)
                and not Relocator.isInTransit(npcId) then
            recoverDisabledScheduledNpc(npcRef, recordId, targetCell or cellName, "admit_present_disabled")
            inCell[npcId] = npcRef
            goto nextAdmit
        end

        local state = NPCState.get(npcId)
        local isSleepingOrWaking = NPCState.isSleeping(npcId) or state == "waking"
        -- Skip NPCs actively being moved by the Relocator, but allow queued
        -- grace-table NPCs to fall through to the redirect path below. Reconcile
        -- must be able to retarget them when their schedule changes.
        --
        -- Transit guard is ONLY for same-cell aesthetic walks: if the player is
        -- watching the NPC walk to a door we don't want to teleport them mid-step.
        -- If the NPC is not in the current cell, the transit state is stale and
        -- must not block materialisation elsewhere.
        if Relocator.isInTransit(npcId) and not Relocator.isQueued(npcId) then
            local npcIsInCurrentCell = inCell[npcId] ~= nil
            if not npcIsInCurrentCell and isObjValid(npcRef) then
                local npcCell = getNpcCellName(npcRef)
                npcIsInCurrentCell = npcCell and string.lower(npcCell) == loCellName
            end

            if not npcIsInCurrentCell then
                if Relocator.isFinishingArrival and Relocator.isFinishingArrival(npcId) then
                    print(string.format("[JSONScheduleModule] ADMIT hold finishing return npc=%s (%s) reason=%s",
                        tostring(npcId), recordId,
                        tostring(Relocator.getTransitReason and Relocator.getTransitReason(npcId) or "finishing_arrival")))
                    goto nextAdmit
                end
                if Relocator.isInTransitToCell and Relocator.isInTransitToCell(npcId, cellName) then
                    print(string.format("[JSONScheduleModule] ADMIT hold en-route npc=%s (%s) -> current cell '%s'",
                        tostring(npcId), recordId, tostring(cellName)))
                    goto nextAdmit
                end
                print(string.format("[JSONScheduleModule] ADMIT override transit npc=%s (%s) not in current cell, clearing transit",
                    tostring(npcId), recordId))
                Relocator.releaseNpc(npcId)
                NPCState.clear(npcId)
            else
                local canOverrideArrival = Relocator.isFinishingArrival
                    and Relocator.isFinishingArrival(npcId)
                    and isNpcEnabled(npcRef)
                    and targetCell
                    and targetType == "interior"
                if canOverrideArrival then
                    print(string.format("[JSONScheduleModule] ADMIT override arrival-return npc=%s (%s) -> '%s'",
                        tostring(npcId), recordId, tostring(targetCell)))
                else
                    print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (in transit, same cell)",
                        tostring(npcId), recordId))
                    goto nextAdmit
                end
            end
        end

        -- Stale schedule / mirror state with no backing Relocator state: clear it so
        -- reconcile and wander/activity assignment can proceed.
        local staleTransit = not Relocator.isInTransit(npcId)
            and (NPCState.isScheduled(npcId) or NPCState.isInTransit(npcId))
        if not Relocator.isQueued(npcId) and staleTransit then
            print(string.format("[JSONScheduleModule] ADMIT clearing stale state '%s' for npc=%s (%s)",
                tostring(state), tostring(npcId), recordId))
            NPCState.clear(npcId)
        end

        -- Already assigned to this cell by Scheduler?
        local Scheduler = getScheduler()
        local assignment = Scheduler and Scheduler.getAssignment(npcId)
        if assignment and assignment.dest
                and string.lower(assignment.dest.destCellName or "") == loCellName
                and not Relocator.isQueued(npcId) then
            print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) (already assigned to this cell)", tostring(npcId), recordId))
            goto nextAdmit
        end

        -- [Diagnostic] Record as missing candidate
        admitCandidates[#admitCandidates + 1] = string.format("%s (%s)", tostring(npcId), recordId)
        
        -- Identify why they are missing
        local missingReason = "Not In Cell"
        if knownNpcs[npcId] and not knownNpcs[npcId].enabled then
            missingReason = "Disabled/Invisible"
        end
        if Relocator.isQueued(npcId) then
            missingReason = "Queued in GraceTable"
            if Relocator.isArrivalDelayed(npcId) then
                missingReason = "Waiting for Arrival Timer"
            end
        elseif Relocator.isDeparting(npcId) then
            missingReason = "Departing/Transitioning"
        end
        
        missingScheduled[#missingScheduled + 1] = {
            id      = npcId,
            record  = recordId,
            reason  = missingReason,
            npc     = npcRef
        }

        print(string.format("[JSONScheduleModule] ADMIT CANDIDATE npc=%s (%s) into '%s' startHour=%s block=%s missingReason=%s",
            tostring(npcId), recordId, cellName,
            tostring(assignDetails and assignDetails.isStartHour or false),
            tostring(assignDetails and assignDetails.timeBlock or "nil"), missingReason))

        -- Not queued — dispatch/return from current position.
        -- Sleeping/waking does not block admit; schedule relocation clears it
        -- before handing the actor to Relocator.
        if isSleepingOrWaking then
            local SleepManager = nil
            pcall(function()
                SleepManager = require("scripts.ProceduralChatter.SleepManager")
            end)
            if SleepManager and SleepManager.clearForScheduleRelocation then
                pcall(function() SleepManager.clearForScheduleRelocation(npcId, npcRef) end)
            else
                pcall(function()
                    npcRef:sendEvent("PC_WakeUpPlease", { immediate = true, skipLerp = true })
                end)
                NPCState.clear(npcId)
            end
            npcRef = refreshNpcById(npcId) or npcRef
            knownNpcs[npcId] = npcRef
            state = NPCState.get(npcId)
            print(string.format("[JSONScheduleModule] ADMIT cleared sleep for schedule takeover npc=%s (%s)",
                tostring(npcId), recordId))
        end

        if state == "activity" or state == "conversation" then
            if not NPCState.isInTransit(npcId) and not NPCState.isScheduled(npcId) then
                preemptNpcForSchedule(npcRef, "reconcileAdmit")
            end
        end

        if cellIsExterior then
            -- Exterior schedule admit:
            -- Use Relocator return path to extract NPC from interior and materialise
            -- them into their native exterior (door-emerge when possible).
            local originCellA, fallbackPos, originRot = getExteriorNativeTarget(npcRef, recordId)
            print(string.format("[JSM] ADMIT dispatch npc=%s originCell='%s' originPos=%s fallbackPos=%s targetCell='%s'",
                tostring(npcId), tostring(originCellA), tostring(fallbackPos), tostring(fallbackPos), tostring(cellName)))
            if originCellA and originCellA ~= "" and string.lower(originCellA) ~= loCellName then
                print(string.format("[JSONScheduleModule] ADMIT skip npc=%s (%s) native exterior '%s' != current '%s'",
                    tostring(npcId), recordId, tostring(originCellA), tostring(cellName)))
                goto nextAdmit
            end
            if fallbackPos then
                Relocator.queueReturnSmooth(npcRef, originCellA or cellName, fallbackPos, originRot, { exterior = true })
            else
                print(string.format("[JSONScheduleModule] ADMIT FAIL npc=%s (%s) exterior admit: no fallbackPos", tostring(npcId), recordId))
            end
        else
            OccupancyTracker.reserve(targetCell, npcId)
            local dest = { destCellName = targetCell, label = "JSON Reconcile Admit" }
            pcall(function()
                DestinationResolver.primeDoorCacheFromNpcCell(npcRef)
                local d = DestinationResolver.findDoorByDestCell(npcRef, targetCell)
                if d then dest = d; dest.label = "JSON Reconcile Admit" end
            end)
            print(string.format("[JSONScheduleModule] ADMIT dispatch npc=%s (%s) dest='%s' doorInsidePos=%s doorExteriorPos=%s",
                tostring(npcId), recordId, tostring(dest.destCellName), tostring(dest.doorInsidePos), tostring(dest.doorExteriorPos)))
            -- Register with Scheduler BEFORE dispatch so onArrivedDoor can find
            -- the assignment and route the callback to onArrived.
            if Scheduler and Scheduler.registerAssignment then
                print(string.format("[JSONScheduleModule] ADMIT registerAssignment npc=%s (%s)", tostring(npcId), recordId))
                Scheduler.registerAssignment(npcId, "JSONSchedule", dest, npcRef)
            else
                print(string.format("[JSONScheduleModule] ADMIT WARNING npc=%s (%s) Scheduler or registerAssignment missing", tostring(npcId), recordId))
            end
            if assignDetails and assignDetails.isStartHour then
                print(string.format("[JSONScheduleModule] ADMIT dispatchSmooth npc=%s (%s)", tostring(npcId), recordId))
                Relocator.dispatchSmooth(npcRef, dest, "JSONSchedule")
            else
                print(string.format("[JSONScheduleModule] ADMIT dispatch npc=%s (%s) (off start hour)", tostring(npcId), recordId))
                Relocator.dispatch(npcRef, dest, "JSONSchedule")
            end
        end

        ::nextAdmit::
    end

    -- [Diagnostic] Print the ADMIT pass findings
    if #missingScheduled > 0 then
        print(string.format("[JSONScheduleModule] Reconcile Summary for '%s':", cellName))
        for _, m in ipairs(missingScheduled) do
            print(string.format("  - MISSING: %s (%s) | Reason: %s", tostring(m.id), m.record, m.reason))
        end
    else
        print(string.format("[JSONScheduleModule] ADMIT pass: no missing scheduled NPCs for '%s'", cellName))
    end
    print(string.format("[JSONScheduleModule] reconcileCell END cell='%s'", cellName))
end

-- =============================================================================
-- onUpdate — hour-crossing detection -> reconcileCell
-- =============================================================================

--- Called from global.lua every frame.
-- Fires reconcileCell whenever the integer hour changes.
--
-- @param dt        frame delta time in seconds
-- @param gameHour  current in-game hour (0-23, fractional)
function JSONScheduleModule.onUpdate(dt, gameHour)
    local hourInt  = math.floor(gameHour) % 24
    if hourInt == lastReconcileHour then return end
    lastReconcileHour = hourInt

    -- Hour just ticked — reconcile the player's current cell.
    -- Distant loaded cells are handled by global.lua's PC_PlayerEnteredCell
    -- with lastReconcileHourByCell tracking to avoid redundant work.
    local dayIndex = TimeService.getDayIndex()
    local ok, playerCell = pcall(function() return world.players[1].cell end)
    if ok and playerCell then
        print(string.format("[JSONScheduleModule] HOUR CROSSED -> %d; reconciling player cell", hourInt))
        JSONScheduleModule.reconcileCell(playerCell, dayIndex, gameHour)
    else
        print(string.format("[JSONScheduleModule] HOUR CROSSED -> %d; SKIP no player cell", hourInt))
    end
end

-- =============================================================================
-- Registration
-- =============================================================================

local ok, Scheduler = pcall(require, 'scripts.ProceduralChatter.schedule.Scheduler')
if ok and Scheduler then
    Scheduler.registerModule(JSONScheduleModule)
else
    print("[JSONScheduleModule] ERROR: could not require Scheduler: " .. tostring(Scheduler))
end

-- JSONScheduleModule.onUpdate(dt, gameHour) must be wired in global.lua

return JSONScheduleModule
