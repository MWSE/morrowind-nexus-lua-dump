local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core          = require("openmw.core")
local world         = require("openmw.world")
local storage       = require("openmw.storage")
local SittingGlobal = require("scripts.ProceduralChatter.SittingGlobal")
local SleepManager  = require("scripts.ProceduralChatter.SleepManager")
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local TimeService   = require("scripts.ProceduralChatter.TimeService")
local NPCState      = require("scripts.ProceduralChatter.NPCState")
local Blacklist     = require("scripts.ProceduralChatter.Blacklist")
local types         = require("openmw.types")
local Scheduler     = require("scripts.ProceduralChatter.schedule.Scheduler")
local TriggerRegistry = require("scripts.ProceduralChatter.schedule.TriggerRegistry")
local Relocator     = require("scripts.ProceduralChatter.schedule.Relocator")
local GeneratedScheduleManager = require("scripts.ProceduralChatter.schedule.GeneratedScheduleManager")
local ActivityManager = require("scripts.ProceduralChatter.ActivityManager")
local ConversationManager = require("scripts.ProceduralChatter.ConversationManager")
local Utils = require("scripts.ProceduralChatter.Utils")

-- Direct settings access: global script reads player settings every frame instead
-- of relying on event delivery from player.lua, which has proven unreliable.
local settingsDebug = storage.globalSection("03_Settings_Chatter_Debug")
local settingsGeneral = storage.globalSection("01_Settings_Chatter_General")

-- Phase 1 schedule module (JSON-driven).
-- Self-registers with Scheduler on require.
local PostArrivalCoordinator = require("scripts.ProceduralChatter.PostArrivalCoordinator")
local JSONScheduleModule = require("scripts.ProceduralChatter.schedule.modules.JSONScheduleModule")

-- DynamicFallback temporarily disabled while rebuilding the schedule system.
-- local DynamicFallback = require("scripts.ProceduralChatter.schedule.modules.DynamicFallback")

-- Register only the trigger that JSONScheduleModule needs.
Scheduler.registerTrigger(TriggerRegistry.PLAYER_CELL)

-- Track which cells have been reconciled this hour so we don't re-reconcile
-- them on every cell entry. Key = cell identifier, value = last reconciled hour.
local lastReconcileHourByCell = {}
local MAX_RECONCILE_CACHE = 50  -- cap to prevent unbounded growth
local activeConversationHeartbeats = {}
local STALE_CONVERSATION_TIMEOUT = 45.0

local function getCellKey(cell)
    if not cell then return nil end
    local ok, isExt = pcall(function() return cell.isExterior end)
    if ok and isExt then
        local gx, gy = 0, 0
        pcall(function() gx = cell.gridX; gy = cell.gridY end)
        return string.format("exterior_%d_%d", gx, gy)
    else
        local name = ""
        pcall(function() name = cell.name or "" end)
        return name ~= "" and name or nil
    end
end

local function reconcileCellIfNeeded(cell, dayIndex, hour, hourInt, force)
    local cellKey = getCellKey(cell)
    if not cellKey then return end
    if not force and lastReconcileHourByCell[cellKey] == hourInt then
        local cname = ""
        pcall(function() cname = cell.name or "?" end)
        Utils.log("[global] reconcile SKIP cell='%s' (already reconciled hour=%d)", cname, hourInt)
        return
    end
    lastReconcileHourByCell[cellKey] = hourInt
    -- Cap cache size to prevent unbounded growth on long playthroughs.
    local cacheSize = 0
    for _ in pairs(lastReconcileHourByCell) do
        cacheSize = cacheSize + 1
    end
    if cacheSize > MAX_RECONCILE_CACHE then
        -- Wipe oldest half of entries (simplest LRU approximation).
        local wipeCount = 0
        for key in pairs(lastReconcileHourByCell) do
            lastReconcileHourByCell[key] = nil
            wipeCount = wipeCount + 1
            if wipeCount >= math.floor(MAX_RECONCILE_CACHE / 2) then break end
        end
    end
    local cname = ""
    pcall(function() cname = cell.name or "?" end)
    Utils.log("[global] reconcile cell='%s' hour=%.1f day=%d", cname, hour, dayIndex)
    JSONScheduleModule.reconcileCell(cell, dayIndex, hour)
end

local function cleanupStaleStates(cell)
    if not cell then return end
    local isNight = TimeService.getPeriod() == "night"
    local now = core.getSimulationTime()

    -- Collect NPCs from the player's cell (includes disabled) AND from
    -- world.activeActors so exterior cells (which stay loaded while the
    -- player is in an interior) are also scanned for stale states.
    local seen = {}
    local actors = {}
    pcall(function()
        for _, npc in ipairs(cell:getAll(types.NPC)) do
            if npc and npc.id and not seen[npc.id] then
                seen[npc.id] = true
                actors[#actors + 1] = npc
            end
        end
    end)
    pcall(function()
        if world.activeActors then
            for _, actor in ipairs(world.activeActors) do
                if types.NPC.objectIsInstance(actor) and actor.id and not seen[actor.id] then
                    seen[actor.id] = true
                    actors[#actors + 1] = actor
                end
            end
        end
    end)

    for _, npc in ipairs(actors) do
        local npcId = npc.id
        local state = NPCState.get(npcId)

        -- Assignment-based states
        if (state == "traveling_to_destination" or state == "at_destination"
            or state == "traveling_home" or state == "at_home") then
            local assignment = Scheduler.getAssignment(npcId)
            if not assignment then
                Utils.log("[global] cleanupStaleStates: clearing stale schedule state '%s' for %s", state, npc.recordId)
                NPCState.clear(npcId)
            end
        end

        -- Activity state validation
        if state == "activity" then
            if ActivityManager.isActive and not ActivityManager.isActive(npcId) then
                Utils.log("[global] cleanupStaleStates: clearing stale 'activity' for %s", npc.recordId)
                NPCState.clear(npcId)
            end
        end

        -- Conversation state validation. Player-side conversation updates are
        -- intentionally frozen during dialogue, so heartbeats pause too.
        if not dialogueMenuActive and state == "conversation" then
            local lastHeartbeat = activeConversationHeartbeats[npcId]
            local heartbeatFresh = lastHeartbeat and (now - lastHeartbeat) <= STALE_CONVERSATION_TIMEOUT
            if not heartbeatFresh and not ConversationManager.isActive(npc) then
                Utils.log("[global] cleanupStaleStates: clearing stale 'conversation' for %s", npc.recordId)
                NPCState.clear(npcId)
            end
        end

        if not dialogueMenuActive and state == "pending_conversation" then
            if not ConversationManager.isActive(npc) then
                Utils.log("[global] cleanupStaleStates: clearing stale 'pending_conversation' for %s", npc.recordId)
                NPCState.clear(npcId)
            end
        end

        -- Sitting state validation
        if state == "sitting" then
            if not SittingGlobal.isSitting(npc) then
                Utils.log("[global] cleanupStaleStates: clearing stale 'sitting' for %s", npc.recordId)
                NPCState.clear(npcId)
            end
        end

        -- traveling_to_seat state validation (now persisted; must clean up if stale)
        -- SittingGlobal.isSeatingInProgress covers both assignedNpcs and pendingOffers.
        if state == "traveling_to_seat" then
            if not SittingGlobal.isSeatingInProgress(npcId) then
                Utils.log("[global] cleanupStaleStates: clearing stale 'traveling_to_seat' for %s", npc.recordId)
                NPCState.clear(npcId)
            end
        end

        if state == "arriving" or state == "departing"
                or state == "transitioning" or state == "returning" then
            if not Relocator.isInTransit(npcId) then
                Utils.log("[global] cleanupStaleStates: clearing stale '%s' for %s",
                    state, tostring(npc.recordId))
                NPCState.clear(npcId)
            end
        end

        -- Sleep state validation
        if state == "sleeping" then
            if not SleepManager.isInBed(npcId) and not isNight then
                Utils.log("[global] cleanupStaleStates: clearing stale 'sleeping' for %s", npc.recordId)
                NPCState.clear(npcId)
                pcall(function() npc:sendEvent("PC_CancelTravelToBed", {}) end)
                pcall(function() npc:sendEvent("PC_StandUpPlease", {}) end)
            end
        end

    end
end

local function onPlayVoice(data)
    -- data: { file = string, actor = object }
    if data.file and data.actor then
        core.sound.say(data.file, data.actor, data.text)
    end
end

local function cleanupNpcFlavorState(npc, npcId, reason)
    npcId = npcId or (npc and npc.id)
    if not npcId then return end

    ConversationManager.forceEndForNpcId(npcId, npc, reason or "cleanup")
    core.sendGlobalEvent("PC_ClearActivityForNpc", {
        npc = npc,
        npcId = npcId,
        reason = reason or "cleanup",
    })

    local state = NPCState.get(npcId)
    if state == "conversation" or state == "activity" then
        NPCState.clear(npcId)
    end
end

local function resolveActorHandle(actor, npcId)
    if Utils.isObjValid(actor) then return actor end
    if not (world and world.getObjectByEntityId and npcId) then return nil end
    local ok, resolved = pcall(world.getObjectByEntityId, npcId)
    if ok and Utils.isObjValid(resolved) then return resolved end
    return nil
end

-- =============================================================================
-- Centralized Hostility Preemption Handler
-- =============================================================================

local function onHostilityStarted(ev)
    if not ev then return end
    local actor = ev.actor
    local npcId = ev.npcId or (actor and actor.id)
    if not npcId then return end
    actor = resolveActorHandle(actor, npcId) or actor

    Utils.log("[global] onHostilityStarted npc=%s id=%s",
        tostring(actor and actor.recordId), tostring(npcId))

    -- Mark hostile immediately, then re-assert it after teardown because some
    -- cleanup paths legitimately write intermediate states like waking/idle.
    NPCState.set(npcId, "hostile")

    if ConversationManager.abortHostile then
        pcall(function() ConversationManager.abortHostile(actor, npcId) end)
    end

    if ActivityManager.clearForNpc then
        pcall(function() ActivityManager.clearForNpc(actor or npcId, "hostility") end)
    end

    -- Request stand-up before forceRelease so SittingGlobal still has the
    -- assigned seat's exit position available for the stand teleport.
    if actor and SittingGlobal.onCancelSittingForNpc then
        pcall(function() SittingGlobal.onCancelSittingForNpc({ npc = actor, reason = "hostility" }) end)
    end
    if SittingGlobal.forceRelease then
        pcall(function() SittingGlobal.forceRelease(npcId) end)
    end

    if SleepManager.forceWake then
        pcall(function() SleepManager.forceWake(npcId) end)
    end

    if SleepManager.clearPendingForNpc then
        pcall(function() SleepManager.clearPendingForNpc(npcId) end)
    end

    NPCState.set(npcId, "hostile")
end

local function onHostilityCleared(ev)
    if not ev then return end
    local actor = ev.actor
    local npcId = ev.npcId or (actor and actor.id)
    if not npcId then return end
    actor = resolveActorHandle(actor, npcId) or actor

    Utils.log("[global] onHostilityCleared npc=%s id=%s",
        tostring(actor and actor.recordId), tostring(npcId))

    -- Only clear if still hostile
    if NPCState.get(npcId) == "hostile" then
        NPCState.clear(npcId)
    end

    -- Evaluate post-arrival so systems can resume naturally
    if actor and PostArrivalCoordinator.evaluate then
        pcall(function() PostArrivalCoordinator.evaluate(actor, "hostility_cleared") end)
    end
end

local _staleCleanupTimer = 0
local STALE_CLEANUP_INTERVAL = 30.0  -- seconds
local waitMenuActive = false
local dialogueMenuActive = false

local function onUpdate(dt)
    -- Read debug toggles directly from player settings storage every frame.
    -- This is the authoritative source; event-based sync is kept as fallback.
    local sit = settingsDebug:get("02_SittingEnabled")
    local sleep = settingsDebug:get("01_SleepEnabled")
    local act = settingsDebug:get("03_ActivitiesEnabled")
    local move = settingsDebug:get("04_ScheduleMovementEnabled")
    if sit ~= nil then ScheduleConfig.SITTING_GLOBAL_ENABLED = sit end
    if sleep ~= nil then ScheduleConfig.SLEEP_MANAGER_ENABLED = sleep end
    if act ~= nil then ScheduleConfig.ACTIVITY_MANAGER_ENABLED = act end
    if move ~= nil then
        ScheduleConfig.SCHEDULE_ENABLED = move
        ScheduleConfig.SCHEDULE_MOVEMENT_ENABLED = move
    end

    if settingsGeneral then
        local enableDoor = settingsGeneral:get("14_EnableDoorSounds")
        local cooldownDoor = settingsGeneral:get("15_DoorSoundCooldown")
        if enableDoor ~= nil then ScheduleConfig.ENABLE_DOOR_SOUNDS = enableDoor end
        if cooldownDoor ~= nil then ScheduleConfig.DOOR_SOUND_COOLDOWN = cooldownDoor end
    end

    SleepManager.onUpdate(dt)
    local paused = waitMenuActive or dialogueMenuActive
    SittingGlobal.onUpdate(dt, paused)
    local player = world and world.players and world.players[1]
    if player then
        local hour = TimeService.getHour()
        -- Scheduler.tick() removed: reconcileCell is the sole dispatcher.
        -- It runs on hour changes (via JSONScheduleModule.onUpdate) and cell entry.
        if ScheduleConfig.SCHEDULE_ENABLED then
            JSONScheduleModule.onUpdate(dt, hour)  -- hour-crossing reconcile
            if JSONScheduleModule.tickPendingRelocations then
                JSONScheduleModule.tickPendingRelocations(dt)
            end
        end
        Relocator.onUpdate(dt)                 -- cleanup invalid grace entries

        -- Throttled stale-state cleanup (1.4): also run while player stays in cell.
        _staleCleanupTimer = _staleCleanupTimer + dt
        if _staleCleanupTimer >= STALE_CLEANUP_INTERVAL then
            _staleCleanupTimer = 0
            if player.cell then
                cleanupStaleStates(player.cell)
            end
        end
    end
end

--- Called by the engine when any actor becomes active in a loaded cell.
-- Saves the NPC's native home position (write-once) before any schedule
-- displacement can move them.  Also delivers any deferred arrival-walk events
-- that were queued when the NPC was teleported across cell boundaries.
local function onActorActive(actor)
    if types.NPC.objectIsInstance(actor) then
        if Blacklist.isHostileByDefault(actor) then return end
        pcall(NPCState.saveNativeHome, actor)
        pcall(GeneratedScheduleManager.ensureGeneratedForActor, actor, world and world.players and world.players[1])
        pcall(Relocator.onActorActive, actor)
    end
end

local function onConversationHeartbeat(ev)
    if not ev then return end
    local now = core.getSimulationTime()
    if ev.initiatorId then activeConversationHeartbeats[ev.initiatorId] = now end
    if ev.targetId then activeConversationHeartbeats[ev.targetId] = now end
end

local function onConversationEnded(ev)
    if not ev then return end
    local now = core.getSimulationTime()
    -- Leave a short grace mark so normal PC_Return/idle transitions can land
    -- before stale-state cleanup judges the just-ended conversation.
    if ev.initiatorId then activeConversationHeartbeats[ev.initiatorId] = now end
    if ev.targetId then activeConversationHeartbeats[ev.targetId] = now end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActorActive = onActorActive,
    },
    interfaceName = "ProceduralChatter",
    interface = {
        dumpGeneratedSchedules = function()
            GeneratedScheduleManager.dumpAllSchedulesToLog()
        end,
        clearGeneratedSchedules = function()
            GeneratedScheduleManager.clearGeneratedSchedules()
            print("[ProceduralChatter] Cleared generated schedules")
        end,
        clearGeneratedScheduleRejections = function()
            GeneratedScheduleManager.clearRejectedCache()
            print("[ProceduralChatter] Cleared generated schedule rejections")
        end,
    },
    eventHandlers = {
        PC_PlayVoice           = onPlayVoice,
        PC_NpcDisabledCleanup  = function(ev)
            if ev then
                cleanupNpcFlavorState(ev.npc, ev.npcId, ev.reason or "disabled")
            end
        end,

        -- Debug
        PC_ClearNativeHomes    = function(_) NPCState.clearAllNativeHomes() end,
        PC_ClearGeneratedSchedules = function(_) GeneratedScheduleManager.clearGeneratedSchedules() end,
        PC_ClearGeneratedScheduleRejections = function(_) GeneratedScheduleManager.clearRejectedCache() end,
        PC_DumpGeneratedSchedules = function(_) GeneratedScheduleManager.dumpAllSchedulesToLog() end,
        PC_PersistNativeWander = function(ev)
            if ev and ev.npc and Blacklist.isHostileByDefault(ev.npc) then return end
            local ok, err = pcall(NPCState.persistNativeWander, ev)
            if not ok then
                Utils.log("[global] PC_PersistNativeWander failed: %s", tostring(err))
            end
        end,
        PC_TargetedTravelNudge = function(ev)
            if not ev or not ev.position then return end
            local actor = resolveActorHandle(ev.actor, ev.npcId)
            local ok, err = false, "invalid_actor"
            local npcId = ev.npcId or (actor and actor.id)
            if actor then
                local cell, rotation = nil, nil
                pcall(function() cell = actor.cell end)
                pcall(function() rotation = actor.rotation end)
                ok, err = Utils.tryTeleport(actor, cell, ev.position, { rotation = rotation })
            end
            actor = resolveActorHandle(actor, npcId)
            if actor then
                pcall(function()
                    actor:sendEvent("PC_TargetedTravelNudgeResult", {
                        requestId = ev.requestId,
                        ok = ok == true,
                        reason = ok and nil or tostring(err),
                        target = ev.target,
                        label = ev.label,
                    })
                end)
            end
        end,

        -- Sitting
        PC_SetSitCooldown     = function(ev)
            if not ev then return end
            local npcId = ev.npcId or (ev.npc and ev.npc.id)
            if npcId then
                NPCState.setSitCooldown(npcId, ev.seconds or 60)
            end
        end,
        PC_StoolCheckResult    = SittingGlobal.onStoolCheckResult,
        PC_StoolFacingResult   = SittingGlobal.onStoolFacingResult,
        PC_CancelSittingForNpc = SittingGlobal.onCancelSittingForNpc,
        PC_ConversationRotate  = SittingGlobal.onConversationRotate,
        PC_ConversationReset   = SittingGlobal.onConversationReset,
        PC_ConversationHeartbeat = onConversationHeartbeat,
        PC_ConversationEnded   = onConversationEnded,
        PC_ConversationWalkRejected = function(ev)
            local player = world and world.players and world.players[1]
            if player then
                pcall(function() player:sendEvent("PC_ConversationWalkRejected", ev or {}) end)
            end
            if ConversationManager.onConversationWalkRejected then
                ConversationManager.onConversationWalkRejected(ev)
            end
        end,
        PC_ClearConversationState = function(ev)
            if not ev or not ev.npcId then return end
            local s = NPCState.get(ev.npcId)
            if s == "conversation" or s == "pending_conversation" then
                NPCState.clear(ev.npcId)
            end
        end,
        PC_ScheduleInterruptComplete = function(ev)
            if JSONScheduleModule.onScheduleInterruptComplete then
                JSONScheduleModule.onScheduleInterruptComplete(ev)
            end
        end,
        PC_WaitMenuState       = function(ev)
            waitMenuActive = ev and ev.active == true
        end,
        PC_DialogueMenuState   = function(ev)
            dialogueMenuActive = ev and ev.active == true
            if SleepManager.setDialogueMenuActive then
                SleepManager.setDialogueMenuActive(dialogueMenuActive)
            end
        end,
        PC_WaitTimeElapsed     = function(_ev)
            if ActivityManager.wrapUpInstantForWait then
                ActivityManager.wrapUpInstantForWait()
            end
            local player = world and world.players and world.players[1]
            if player and player.cell then
                local hour     = TimeService.getHour()
                local hourInt  = math.floor(hour) % 24
                local dayIndex = TimeService.getDayIndex()
                Utils.log("[global] PC_WaitTimeElapsed reconcile cell hour=%.1f day=%d", hour, dayIndex)
                reconcileCellIfNeeded(player.cell, dayIndex, hour, hourInt, true)
            end
        end,
        PC_RegisterSitState    = SittingGlobal.onRegisterSitState,
        PC_Arrived             = SittingGlobal.onArrived,

        -- Sleep
        PC_BedCheckResult      = SleepManager.onBedCheckResult,
        PC_SleepWakeComplete   = SleepManager.onSleepWakeComplete,
        PC_CombatStarted       = function(ev)
            SleepManager.onCombatStarted(ev)
            onHostilityStarted(ev)
        end,
        PC_HostilityStarted    = onHostilityStarted,
        PC_HostilityCleared    = onHostilityCleared,
        PC_WakeMeUp            = function(ev) if ev.npc then SleepManager.forceWake(ev.npc.id, true) end end,
        PC_WakeForDialogue     = SleepManager.onWakeForDialogue,
        PC_WakePositionFound   = SleepManager.onWakePositionFound,
        PC_ForceStandForDeparture = function(ev)
            if ev and ev.npc then
                SittingGlobal.forceStandForDeparture(ev.npc.id)
            end
        end,

        -- Schedule — player cell tracking
        PC_PlayerEnteredCell    = function(ev)
            if not ev or not ev.cellName then return end
            Utils.log("[global] PC_PlayerEnteredCell cell='%s' prev='%s' exterior=%s",
                tostring(ev.cellName), tostring(ev.prevCellName), tostring(ev.isExterior))
            -- 1. Materialise active en-route NPCs for this destination before
            --    reconcile can treat their off-cell transit as stale.
            -- 2. Reconcile before materialising grace-table NPCs. This lets
            --    stale queued destinations (for example, tavern entries skipped
            --    over by Wait/Rest) retarget to the current schedule first.
            -- 3. Materialise any remaining NPCs queued for this cell.
            -- 4. Reconcile the player's cell only.
            --    (Batch reconciling ALL loaded cells was causing game freezes
            --     due to heavy per-cell actor iteration + ADMIT scans.)
            local player = world and world.players and world.players[1]
            if player and player.cell then
                local hour     = TimeService.getHour()
                local hourInt  = math.floor(hour) % 24
                local dayIndex = TimeService.getDayIndex()
                if Relocator.dematerialiseActiveAwayFromCell then
                    Relocator.dematerialiseActiveAwayFromCell(ev.cellName, ev.isExterior or false)
                end
                if Relocator.materialiseActiveForCell then
                    Relocator.materialiseActiveForCell(ev.cellName)
                end
                reconcileCellIfNeeded(player.cell, dayIndex, hour, hourInt, true)
                Relocator.onPlayerEnteredCell(ev.cellName, ev.prevCellName or '', ev.isExterior or false)
                cleanupStaleStates(player.cell)
            else
                Utils.log("[global] PC_PlayerEnteredCell SKIP no player or player.cell")
                Relocator.onPlayerEnteredCell(ev.cellName, ev.prevCellName or '', ev.isExterior or false)
            end
        end,
        PC_NavmeshSnapResolved  = function(ev)
            Relocator.onNavmeshSnapResolved(ev)
        end,

        -- Smooth Departure (Phase A): NPC local script signals it reached the exit door.
        PC_DepartureReachedDoor = function(ev)
            Relocator.onDepartureReachedDoor(ev)
        end,

        -- Smooth Arrival (Phase B): NPC local script signals it walked from the door
        -- to its reserved slot; fires Scheduler.onArrivedDoor to start the module's
        -- onArrived callback (sitting, wandering, etc.).
        PC_ArrivalComplete = function(ev)
            Relocator.onArrivalComplete(ev)
        end,
        PC_ArrivalFailed = function(ev)
            Relocator.onArrivalFailed(ev)
        end,
        PC_TransitionComplete = function(ev)
            Relocator.onTransitionComplete(ev)
        end,
        PC_CellChange           = function(ev)
            if ev and ev.cell then
                NPCState.snapshotCell(ev.cell)
            end
            Relocator.clearAll()
            -- Clear cell reconcile tracking so the new area gets fully refreshed.
            lastReconcileHourByCell = {}
        end,

        -- Debug toggles
        PC_UpdateDebugToggles = function(data)
            if data.sleepEnabled      ~= nil then ScheduleConfig.SLEEP_MANAGER_ENABLED    = data.sleepEnabled      end
            if data.sittingEnabled    ~= nil then ScheduleConfig.SITTING_GLOBAL_ENABLED   = data.sittingEnabled    end
            if data.activitiesEnabled ~= nil then ScheduleConfig.ACTIVITY_MANAGER_ENABLED = data.activitiesEnabled end
            if data.scheduleEnabled   ~= nil then ScheduleConfig.SCHEDULE_ENABLED         = data.scheduleEnabled   end
            if data.scheduleMovementEnabled ~= nil then ScheduleConfig.SCHEDULE_MOVEMENT_ENABLED = data.scheduleMovementEnabled end
        end,

        -- Quest update: invalidate the quest-lock cache
        PC_NpcStateReleased = function(ev)
            if ev and ev.npc then
                PostArrivalCoordinator.evaluate(ev.npc, ev.context or "unknown")
            end
        end,

        PC_QuestUpdated = function(ev)
            if ev and ev.npcId then
                Blacklist.invalidateQuestLock(ev.npcId)
            else
                Blacklist.invalidateAllQuestLocks()
            end
        end,

        -- Local→Global state mirroring (Phase 0)
        PC_StateChanged = function(data)
            if data and data.npcId and data.state then
                local current = NPCState.get(data.npcId)
                if current == "hostile" and data.state ~= "hostile" then
                    Utils.log("[global] Ignoring PC_StateChanged(%s) for npcId=%s because currently hostile",
                        data.state, tostring(data.npcId))
                    return
                end
                -- Once SleepManager has placed an NPC in bed, ignore stale local
                -- signals (e.g. from a cancelled stool approach) that would
                -- overwrite the sleeping state.
                if current == "sleeping" and data.state ~= "sleeping" and data.state ~= "waking" then
                    Utils.log("[global] Ignoring PC_StateChanged(%s) for npcId=%s because currently sleeping",
                        data.state, tostring(data.npcId))
                    return
                end
                -- Block chatter/activity idle only while Relocator movement tables still
                -- own this NPC. A stale global "arriving" label must not block idle
                -- after the local walk has finished.
                local scheduleTransit = current == "departing" or current == "transitioning"
                    or current == "arriving" or current == "returning"
                    or current == "traveling_to_destination" or current == "traveling_home"
                local chatterOverwrite = data.state == "idle" or data.state == "pending_conversation"
                    or data.state == "conversation" or data.state == "activity"
                if scheduleTransit and chatterOverwrite
                        and Relocator.isInTransit and Relocator.isInTransit(data.npcId) then
                    Utils.log("[global] Ignoring PC_StateChanged(%s) for npcId=%s (schedule transit, was %s)",
                        data.state, tostring(data.npcId), current)
                    return
                end
                -- Scheduled NPCs may start a normal Wander package immediately after
                -- arrival. The local state machine returns to idle for that package,
                -- but the global schedule state must remain at_destination/at_home so
                -- downstream guards do not mistake Wander's internal Travel legs for
                -- unrelated external movement.
                local scheduleStationary = current == "at_destination" or current == "at_home"
                if scheduleStationary and data.state == "idle" then
                    Utils.log("[global] Ignoring PC_StateChanged(idle) for npcId=%s (schedule stationary, was %s)",
                        tostring(data.npcId), current)
                    return
                end
                NPCState.set(data.npcId, data.state)
            end
        end,
    }
}
