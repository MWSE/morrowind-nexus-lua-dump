-- ui/initialPlacementOverlayController.lua
---@omw-context player
-- Player-side black-cover state machine for hidden initial placement.

local M = {}

local INITIAL_PLACEMENT_DYNAMIC_TICK_SECONDS = 0.35
local INITIAL_PLACEMENT_LOAD_BRIDGE_FAILSAFE_SECONDS = 10.0
local INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS = 5.0
local INITIAL_PLACEMENT_INITIAL_LOAD_POST_POSE_HOLD_SECONDS = 0.65
local INITIAL_PLACEMENT_CELL_POST_POSE_HOLD_SECONDS = 0.65
local STATION_WAIT_PRECOVER_FAILSAFE_SECONDS = 2.0

local function settingsFrom(env)
    if env and type(env.settings) == "function" then return env.settings() end
    return env and env.settings or {}
end

local function now(env)
    if env and env.realTime then return env.realTime() end
    return 0
end

local function debugLog(env, ...)
    if env and env.debugLog then env.debugLog(...) end
end

local function boolCall(fn, ...)
    if not fn then return false end
    local ok, value = pcall(fn, ...)
    return ok and value == true
end

local function currentCellIsExterior(env)
    local cell = env and env.playerCell and env.playerCell() or nil
    if not cell then return false end
    if env and env.cellIsExterior then return boolCall(env.cellIsExterior, cell) end
    if cell.isExterior ~= nil then return cell.isExterior == true end
    return cell.hasSky == true
end

function M.create(env)
    env = env or {}
    local state = {
        overlay = nil,
        overlayTop = nil,
        overlayText = nil,
        untilTime = 0,
        visibleSensitive = false,
        minUntil = 0,
        lastHoldLogAt = -100,
        lastReleaseLogAt = -100,
        loadBridgeUntil = 0,
        awaitingAssignmentScan = false,
        localResultsPending = 0,
        pendingActorIds = {},
        scanSource = nil,
        fadeSeconds = 0.35,
        suppressFreshPostCoverUntil = 0,
        failSafeUntil = 0,
        lastStationWaitPrecoverAt = -100,
        pendingTeleportPrecover = false,
        pendingTeleportPrecoverReason = nil,
        pendingTeleportPrecoverCell = nil,
        lastTeleportPrecoverAt = -100,
    }

    local controller = { state = state }

    local function countPendingActors()
        local count = 0
        for _ in pairs(state.pendingActorIds or {}) do count = count + 1 end
        return count
    end

    local function syncPendingCount()
        local actorCount = countPendingActors()
        if actorCount > 0 then
            state.localResultsPending = actorCount
        else
            state.localResultsPending = math.max(0, tonumber(state.localResultsPending or 0) or 0)
        end
        return state.localResultsPending
    end

    local function hasPendingState()
        return state.awaitingAssignmentScan == true
            or ((tonumber(state.localResultsPending) or 0) > 0)
            or countPendingActors() > 0
            or ((tonumber(state.failSafeUntil) or 0) > 0)
    end

    local function clearPending(reason)
        local hadPending = hasPendingState()
        state.awaitingAssignmentScan = false
        state.localResultsPending = 0
        state.pendingActorIds = {}
        state.scanSource = nil
        state.failSafeUntil = 0
        if hadPending then
            debugLog(env, "initial placement overlay pending state cleared", tostring(reason or "clear"))
        end
        return hadPending
    end

    local function completeActor(actorId, reason)
        if actorId == nil then return false end
        actorId = tostring(actorId)
        if actorId == "" then return false end
        local had = state.pendingActorIds and state.pendingActorIds[actorId] ~= nil
        if had then
            state.pendingActorIds[actorId] = nil
            state.localResultsPending = countPendingActors()
            debugLog(env, "initial placement overlay actor result received", actorId, tostring(reason or "result"), "pending", tostring(state.localResultsPending))
            return true
        end
        return false
    end

    local function layerEnv()
        return env.layerEnv and env.layerEnv() or {}
    end

    local function destroyOverlay()
        local overlayLayers = env.overlayLayers
        if overlayLayers and overlayLayers.destroyPair then
            overlayLayers.destroyPair(state.overlay, state.overlayTop, state.overlayText)
        end
        state.overlay = nil
        state.overlayTop = nil
        state.overlayText = nil
        state.visibleSensitive = false
        state.minUntil = 0
        state.failSafeUntil = 0
        state.lastHoldLogAt = -100
        state.lastReleaseLogAt = -100
    end

    local function setAlpha(alpha)
        if not state.overlay then return end
        local overlayLayers = env.overlayLayers
        if overlayLayers and overlayLayers.setAlpha then
            overlayLayers.setAlpha(state.overlay, state.overlayTop, state.overlayText, alpha)
        end
    end

    local function releaseSoon(reason, holdDuration)
        local hadPending = clearPending(reason or "release")
        local t = now(env)
        if state.overlay then
            local hold = tonumber(holdDuration or 0.08) or 0.08
            state.untilTime = math.min(math.max(state.untilTime or 0, t + 0.02), t + hold)
            if hadPending or t - (state.lastReleaseLogAt or -100) >= 0.5 then
                state.lastReleaseLogAt = t
                debugLog(env, "initial placement overlay release armed", tostring(reason or "release"), "hold", tostring(hold), "until", tostring(state.untilTime - t))
            end
        end
    end

    function controller.resetDynamicState(reason, keepOverlay)
        local hadPending = state.awaitingAssignmentScan == true or ((tonumber(state.localResultsPending) or 0) > 0) or countPendingActors() > 0
        state.awaitingAssignmentScan = false
        state.localResultsPending = 0
        state.pendingActorIds = {}
        state.scanSource = nil
        state.failSafeUntil = 0
        state.loadBridgeUntil = 0
        if hadPending then
            debugLog(env, "initial placement overlay stale pending cleared", tostring(reason or "reset"))
        end
        if state.overlay and keepOverlay ~= true then
            state.untilTime = math.min(state.untilTime or 0, now(env) + 0.08)
        end
    end

    function controller.updateFade()
        if not state.overlay then return end
        local t = now(env)
        local pendingCount = syncPendingCount()
        local dynamicPending = state.awaitingAssignmentScan == true or pendingCount > 0
        if dynamicPending then
            local failSafeUntil = tonumber(state.failSafeUntil or 0) or 0
            if failSafeUntil <= 0 then
                debugLog(env, "initial placement overlay dynamic stale release no failsafe", "awaitingScan", tostring(state.awaitingAssignmentScan), "pending", tostring(pendingCount))
                releaseSoon("stale_pending_no_failsafe", 0.10)
            elseif t >= failSafeUntil then
                debugLog(env, "initial placement overlay dynamic failsafe release", "awaitingScan", tostring(state.awaitingAssignmentScan), "pending", tostring(pendingCount))
                releaseSoon("dynamic_failsafe", 0.12)
            else
                state.untilTime = t + INITIAL_PLACEMENT_DYNAMIC_TICK_SECONDS
                setAlpha(1.0)
                if t - (state.lastHoldLogAt or -100) >= 0.5 then
                    state.lastHoldLogAt = t
                    debugLog(env, "initial placement overlay dynamic hold pending events", "awaitingScan", tostring(state.awaitingAssignmentScan), "pending", tostring(pendingCount), "failsafeRemaining", tostring(failSafeUntil - t))
                end
                return
            end
        end
        local remaining = (state.untilTime or 0) - t
        if remaining <= 0 then
            destroyOverlay()
            return
        end
        local fade = tonumber(state.fadeSeconds or 0.35) or 0.35
        if fade > 0 and remaining < fade then
            setAlpha(remaining / fade)
        else
            setAlpha(1.0)
        end
    end

    function controller.show(data)
        local settings = settingsFrom(env)
        if settings.disguiseInitialPlacement ~= true then return end
        if data and data.interactionType == "sitting" then
            debugLog(env, "initial placement overlay skipped", "sitting", tostring(data.reason or "initial_placement"), "visibility", "sitting_no_black_cover")
            return
        end
        if data and data.reason == "sleep_initial_placement" and not state.overlay then
            if now(env) < (state.suppressFreshPostCoverUntil or 0) then
                debugLog(env, "initial placement overlay skipped post-settle fresh show", tostring(data.reason))
                return
            end
            debugLog(env, "initial placement overlay skipped post-placement without active cover", tostring(data.reason))
            return
        end
        if data and data.reason == "initial_placement_pending" and now(env) < (state.suppressFreshPostCoverUntil or 0) then
            debugLog(env, "initial placement overlay skipped stale pending after settle", tostring(data.reason))
            return
        end
        if data and data.reason == "initial_placement_pending" and not state.overlay and currentCellIsExterior(env) then
            debugLog(env, "initial placement overlay skipped exterior pending without active cover", tostring(data.reason))
            return
        end
        local visible = false
        local visibleReason = "not_checked"
        if data and data.precover == true then
            if data.bridge == true then
                visible, visibleReason = true, tostring(data.visibilityReason or "load_bridge")
            elseif data.early == true then
                visible, visibleReason = boolCall(env.playerCellLikelyHasInitialPlacement), "early_likely_initial_placement"
            else
                visible, visibleReason = boolCall(env.playerCellLikelyHasVisibleInitialPlacement), "precover_probe"
            end
        elseif data and data.reason == "initial_placement_pending" then
            visible, visibleReason = true, "initial_placement_pending"
        else
            local checkedVisible, checkedReason = env.objectOrPositionVisible(data and data.actor or nil, data and data.targetPosition or nil, 2400)
            visible, visibleReason = checkedVisible == true, checkedReason or "visibility_unknown"
            if not visible then
                checkedVisible, checkedReason = env.objectOrPositionVisible(data and data.object or nil, data and data.targetPosition or nil, 2400)
                visible, visibleReason = checkedVisible == true, checkedReason or "visibility_unknown"
            end
        end
        if visible ~= true then
            debugLog(env, "initial placement overlay skipped", tostring(data and data.interactionType), tostring(data and data.reason), "visibility", tostring(visibleReason))
            return
        end
        if state.overlay and data then
            debugLog(env, "initial placement overlay duplicate show suppressed", tostring(data.reason), "visibility", tostring(visibleReason))
            debugLog(env, "initial placement overlay prevented show_settle_show", tostring(data.reason))
        end
        if data and (data.reason == "player_cell_entry_precover" or data.reason == "player_teleported_precover" or data.precover == true) then
            debugLog(env, "initial placement overlay shown real_initial_candidates", tostring(data.reason), "visibility", tostring(visibleReason))
        end

        local duration = tonumber(data and data.duration or 0.65) or 0.65
        if duration <= 0 then return end
        local maxDuration = (data and data.bridge == true) and 1.2 or 2.4
        local clampedDuration = math.min(math.max(duration, 0.2), maxDuration)
        local untilTime = now(env) + clampedDuration
        if data and data.bridge == true then
            local failSafeDuration = tonumber(data.failSafeDuration or 0) or 0
            if failSafeDuration > 0 then
                state.failSafeUntil = math.max(state.failSafeUntil or 0, now(env) + failSafeDuration)
            end
            debugLog(env, "initial placement overlay dynamic timing armed", tostring(data.reason), "displayTick", tostring(clampedDuration), "failsafe", tostring(failSafeDuration))
        end
        local holdDuration = tonumber(data and data.holdDuration or 0) or 0
        local minUntil = holdDuration > 0 and (now(env) + holdDuration) or untilTime
        state.visibleSensitive = true
        state.minUntil = math.max(state.minUntil or 0, minUntil)
        debugLog(env, "initial placement overlay visible state before cell render", "existing", tostring(state.overlay ~= nil), "reason", tostring(data and data.reason), "visibility", tostring(visibleReason))

        local overlayLayers = env.overlayLayers
        if state.overlay then
            state.untilTime = math.max(state.untilTime or 0, untilTime)
            if not state.overlayTop and overlayLayers and overlayLayers.ensureCompanion then
                state.overlayTop, state.overlayText = overlayLayers.ensureCompanion(layerEnv(), state.overlayTop, state.overlayText)
                if state.overlayTop then debugLog(env, "initial placement overlay top companion restored", tostring(data and data.reason), "layer", tostring(env.companionLayer or "Windows")) end
            end
            setAlpha(1.0)
            debugLog(env, "initial placement overlay reused existing cover", tostring(data and data.interactionType), tostring(data and data.reason), "duration", tostring(clampedDuration), "visibility", tostring(visibleReason), "layer", tostring(env.mainLayer or "Notification") .. "+" .. tostring(env.companionLayer or "Windows"))
            if data and data.bridge == true then
                debugLog(env, "initial placement overlay continuous load bridge", tostring(data.reason), "until", tostring(state.untilTime - now(env)))
            end
            return
        end

        state.untilTime = untilTime
        if overlayLayers and overlayLayers.createPair then
            state.overlay, state.overlayTop, state.overlayText = overlayLayers.createPair(layerEnv())
        end
        if not state.overlay and not state.overlayTop then
            state.untilTime = 0
            debugLog(env, "initial placement overlay failed", "all_layers")
            return
        end
        if not state.overlay then state.overlay = state.overlayTop end
        debugLog(env, "initial placement overlay", tostring(data and data.interactionType), tostring(data and data.reason), "duration", tostring(clampedDuration), "visibility", tostring(visibleReason), "layer", tostring(env.mainLayer or "Notification") .. "+" .. tostring(env.companionLayer or "Windows"))
    end

    function controller.settle(data)
        local reason = tostring(data and data.reason or "settled")
        local actorId = data and (data.actorId or data.npcId)
        if actorId then completeActor(actorId, reason) end

        if reason == "initial_handoff_timeout" or reason == "pending_local_invalid" or reason == "pending_local_released" then
            releaseSoon(reason, tonumber(data and data.holdDuration or 0.10) or 0.10)
            return
        end

        if state.awaitingAssignmentScan == true then
            debugLog(env, "initial placement overlay not settled pending local results", reason, "pending", tostring(syncPendingCount()), "scan", "awaiting")
            return
        end

        local pendingCount = syncPendingCount()
        if actorId == nil and (reason == "sleep_initial_placement_done" or reason == "initial_placement_rejected" or reason == "sleep_initial_placement_rejected" or reason == "sleep_initial_placement_failed" or reason == "dead_actor") then
            if pendingCount > 0 then
                debugLog(env, "initial placement overlay aggregate settle ignored pending actor results", reason, "pending", tostring(pendingCount))
                return
            end
        end

        if pendingCount > 0 then
            debugLog(env, "initial placement overlay not settled pending local results", reason, "pending", tostring(pendingCount))
            return
        end

        if state.overlay then
            local holdDuration = tonumber(data and data.holdDuration or 0) or 0
            if reason == "sleep_initial_placement_done" then
                local source = tostring(state.scanSource or "")
                local postPoseHold = (source == "initial_load") and INITIAL_PLACEMENT_INITIAL_LOAD_POST_POSE_HOLD_SECONDS or INITIAL_PLACEMENT_CELL_POST_POSE_HOLD_SECONDS
                if holdDuration < postPoseHold then holdDuration = postPoseHold end
                debugLog(env, "initial placement overlay post animation settle hold", "source", tostring(source), "hold", tostring(holdDuration))
            end
            local settleUntil = now(env) + (holdDuration > 0 and holdDuration or 0.08)
            if state.visibleSensitive then
                settleUntil = math.max(settleUntil, state.minUntil or 0)
            end
            state.awaitingAssignmentScan = false
            state.untilTime = settleUntil
            state.failSafeUntil = 0
            state.suppressFreshPostCoverUntil = now(env) + math.max(0.9, holdDuration + 0.3)
            debugLog(env, "initial placement overlay final settle after all initial candidates resolved", reason, "hold", tostring(holdDuration), "until", tostring(state.untilTime - now(env)), "dynamicRelease", "true")
        else
            clearPending("settled_without_overlay")
        end
    end

    function controller.scanComplete(data)
        state.awaitingAssignmentScan = false
        state.scanSource = data and data.source or nil
        state.pendingActorIds = {}
        local actorIds = data and data.initialSleepActorIds or nil
        local actorIdCount = 0
        if type(actorIds) == "table" then
            for _, actorId in ipairs(actorIds) do
                if actorId ~= nil then
                    state.pendingActorIds[tostring(actorId)] = true
                    actorIdCount = actorIdCount + 1
                end
            end
        end
        if actorIdCount > 0 then
            state.localResultsPending = actorIdCount
        else
            state.localResultsPending = tonumber(data and data.initialSleepSentConsider or 0) or 0
        end
        debugLog(env, "initial placement overlay scan complete", "pending", tostring(state.localResultsPending), "actorIds", tostring(actorIdCount), "source", tostring(data and data.source))
        if state.localResultsPending <= 0 then
            debugLog(env, "initial placement overlay released after scan no candidates")
            controller.settle({ reason = "released_after_scan_no_candidates", holdDuration = 0.08 })
        elseif state.overlay then
            debugLog(env, "initial placement overlay continuous load bridge", "assignment_scan_candidates", "sent", tostring(state.localResultsPending))
            debugLog(env, "initial placement overlay not settled pending local results", "assignment_scan_candidates", "pending", tostring(state.localResultsPending))
        end
    end

    function controller.maybeStartLoadCover(reason, transitionReason)
        local settings = settingsFrom(env)
        if settings.disguiseInitialPlacement ~= true then return end
        local t = now(env)
        local existingCover = state.overlay ~= nil

        local insideSleepWindow, timeKnown, currentHour, sleepWindowReason = env.currentSleepWindowState()
        local loadBridge = reason == "player_load_precover" or reason == "player_init_precover"
        local uncertainSleepWindow = timeKnown ~= true
        local sleepWindowAllowsCover = insideSleepWindow == true or uncertainSleepWindow == true

        if timeKnown == true and insideSleepWindow ~= true then
            debugLog(env, "initial placement precover skipped", tostring(reason or "player_load_precover"), "likely", "false", "transition", tostring(transitionReason), "sleepWindow", tostring(sleepWindowReason), "hour", tostring(currentHour))
            return
        end

        if loadBridge and sleepWindowAllowsCover then
            local duration = 0.85
            local failSafeDuration = INITIAL_PLACEMENT_LOAD_BRIDGE_FAILSAFE_SECONDS
            local holdDuration = uncertainSleepWindow and 0.25 or 0.45
            state.awaitingAssignmentScan = true
            state.failSafeUntil = math.max(state.failSafeUntil or 0, t + failSafeDuration)
            state.loadBridgeUntil = math.max(state.loadBridgeUntil or 0, t + failSafeDuration)
            controller.show({
                interactionType = "scan",
                reason = reason or "player_load_precover",
                duration = duration,
                holdDuration = holdDuration,
                failSafeDuration = failSafeDuration,
                precover = true,
                early = true,
                bridge = true,
                visibilityReason = uncertainSleepWindow and "load_bridge_unknown_sleep_window" or "load_bridge_sleep_window",
            })
            debugLog(env, "initial placement load bridge precover", tostring(reason or "player_load_precover"), "hour", tostring(currentHour), "sleepWindow", tostring(sleepWindowReason), "dynamic", "true", "duration", tostring(duration), "failsafe", tostring(failSafeDuration))
            return
        end

        local cellEntrySleepObjects = boolCall(env.playerCellHasSleepRelevantObjects)
        if not cellEntrySleepObjects and existingCover then
            state.loadBridgeUntil = math.max(state.loadBridgeUntil or 0, t + 0.34)
            controller.show({
                interactionType = "scan",
                reason = reason or "player_cell_entry_precover",
                duration = 0.34,
                holdDuration = 0.12,
                precover = true,
                early = true,
                bridge = true,
                visibilityReason = "existing_cover_no_candidates",
            })
            debugLog(env, "initial placement overlay skipped no_candidates_existing_cover", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
            return
        end

        local currentCell = env.playerCell and env.playerCell() or nil
        local speculativeInteriorCover = not cellEntrySleepObjects
            and transitionReason == "load_or_teleport_cell_change"
            and currentCell ~= nil
            and env.cellIsExterior(currentCell) ~= true
            and sleepWindowAllowsCover == true
        if speculativeInteriorCover then
            local duration = 0.55
            local failSafeDuration = INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS
            state.awaitingAssignmentScan = true
            state.failSafeUntil = math.max(state.failSafeUntil or 0, t + failSafeDuration)
            state.loadBridgeUntil = math.max(state.loadBridgeUntil or 0, t + failSafeDuration)
            controller.show({
                interactionType = "scan",
                reason = reason or "player_cell_entry_precover",
                duration = duration,
                holdDuration = 0.18,
                failSafeDuration = failSafeDuration,
                precover = true,
                early = true,
                bridge = true,
                visibilityReason = "interior_sleep_window_scan_pending",
            })
            debugLog(env, "initial placement overlay speculative interior precover", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false", "dynamic", "true", "duration", tostring(duration), "failsafe", tostring(failSafeDuration))
            return
        end
        if not cellEntrySleepObjects and reason == "player_teleported_precover" then
            debugLog(env, "initial placement overlay skipped fast_transition_no_candidates", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
            return
        end
        if not cellEntrySleepObjects and transitionReason == "load_or_teleport_cell_change" then
            debugLog(env, "initial placement overlay skipped no_sleep_objects", tostring(reason), "transition", tostring(transitionReason), "sleepObjects", "false")
            return
        end
        local cellEntryCover = (reason == "player_cell_entry_precover" or reason == "player_teleported_precover")
            and transitionReason ~= "exterior_streaming"
            and sleepWindowAllowsCover
            and cellEntrySleepObjects
        if cellEntryCover then
            local teleportedPrecover = reason == "player_teleported_precover"
            local duration = teleportedPrecover and 0.54 or (uncertainSleepWindow and 0.26 or 0.42)
            local failSafeDuration = INITIAL_PLACEMENT_CELL_BRIDGE_FAILSAFE_SECONDS
            local holdDuration = teleportedPrecover and 0.12 or (uncertainSleepWindow and 0.06 or 0.12)
            state.failSafeUntil = math.max(state.failSafeUntil or 0, t + failSafeDuration)
            state.loadBridgeUntil = math.max(state.loadBridgeUntil or 0, t + failSafeDuration)
            controller.show({
                interactionType = "scan",
                reason = reason or "player_cell_entry_precover",
                duration = duration,
                holdDuration = holdDuration,
                failSafeDuration = failSafeDuration,
                precover = true,
                early = true,
                bridge = true,
                visibilityReason = "cell_entry_sleep_objects",
            })
            debugLog(env, "initial placement cell-entry precover", tostring(reason or "player_cell_entry_precover"), "transition", tostring(transitionReason), "sleepObjects", tostring(cellEntrySleepObjects), "hour", tostring(currentHour), "sleepWindow", tostring(sleepWindowReason), "duration", tostring(duration))
            return
        end

        if insideSleepWindow == true and boolCall(env.playerCellLikelyHasInitialPlacement) then
            controller.show({
                interactionType = "scan",
                reason = reason or "player_load_precover",
                duration = 0.68,
                holdDuration = 0.22,
                precover = true,
                early = true,
            })
        else
            debugLog(env, "initial placement precover skipped", tostring(reason or "player_load_precover"), "likely", "false", "transition", tostring(transitionReason), "sleepWindow", tostring(sleepWindowReason), "hour", tostring(currentHour))
        end
    end

    function controller.maybeStartStationWaitPrecover(deltaGameTime)
        local settings = settingsFrom(env)
        if settings.disguiseInitialPlacement ~= true then return end
        if settings.stationLecternEnabled == false then return end
        if not boolCall(env.playerCellHasStationRelevantObjects) then return end
        local t = now(env)
        if t - (state.lastStationWaitPrecoverAt or -100) < 0.8 then return end
        state.lastStationWaitPrecoverAt = t
        state.failSafeUntil = math.max(state.failSafeUntil or 0, t + STATION_WAIT_PRECOVER_FAILSAFE_SECONDS)
        state.loadBridgeUntil = math.max(state.loadBridgeUntil or 0, t + STATION_WAIT_PRECOVER_FAILSAFE_SECONDS)
        controller.show({
            interactionType = "station",
            reason = "station_wait_time_advance_precover",
            duration = 0.85,
            holdDuration = 0.18,
            failSafeDuration = STATION_WAIT_PRECOVER_FAILSAFE_SECONDS,
            precover = true,
            early = true,
            bridge = true,
            visibilityReason = "station_wait_time_advance",
        })
        debugLog(env, "station wait precover armed", "deltaGameTime", tostring(deltaGameTime), "failsafe", tostring(STATION_WAIT_PRECOVER_FAILSAFE_SECONDS))
    end

    function controller.queueTeleportPrecover(reason)
        local t = now(env)
        if t - (state.lastTeleportPrecoverAt or -100) < 0.18 then return end
        state.pendingTeleportPrecover = true
        state.pendingTeleportPrecoverReason = reason or "player_teleported_precover"
        state.pendingTeleportPrecoverCell = env.playerCell and env.playerCell() or nil
    end

    function controller.processQueuedTeleportPrecover(currentCell)
        if not (state.pendingTeleportPrecover and currentCell) then return end
        local queuedCell = state.pendingTeleportPrecoverCell
        local reason = state.pendingTeleportPrecoverReason or "player_teleported_precover"
        state.pendingTeleportPrecover = false
        state.pendingTeleportPrecoverCell = nil
        state.lastTeleportPrecoverAt = now(env)
        if queuedCell ~= nil and queuedCell == currentCell then
            debugLog(env, "initial placement precover skipped", tostring(reason), "transition", "same_cell_teleport")
        elseif env.cellIsExterior(currentCell) and not boolCall(env.playerCellHasSleepRelevantObjects) then
            debugLog(env, "initial placement precover skipped", tostring(reason), "transition", "teleport_to_exterior_no_sleep_objects")
        else
            controller.maybeStartLoadCover(reason, "load_or_teleport_cell_change")
        end
    end

    function controller.settleNoLikelyInitialCandidates()
        local okLikely, likelyPlacement = pcall(env.playerCellLikelyHasInitialPlacement)
        if okLikely and likelyPlacement == false then
            if state.awaitingAssignmentScan == true then
                debugLog(env, "initial placement overlay held awaiting assignment scan", "player_no_likely_initial_candidates")
            elseif now(env) >= (state.loadBridgeUntil or 0) then
                controller.settle({ reason = "player_no_likely_initial_candidates" })
            else
                debugLog(env, "initial placement settle deferred", "player_no_likely_initial_candidates", "bridgeUntil", tostring((state.loadBridgeUntil or 0) - now(env)))
            end
        elseif not okLikely then
            debugLog(env, "initial placement precover probe failed", tostring(likelyPlacement))
        end
    end

    return controller
end

return M
