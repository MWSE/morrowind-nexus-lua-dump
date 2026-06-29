-- interactions/lectures/assignmentController.lua
---@omw-context none
-- Assignment-side station and lecture orchestration.

local M = {}

local function stationAssignments(env)
    return env and env.stationAssignments or nil
end

local function runtimeContext(env, dt, forceScan, initialPlacement, targetStationObject)
    if env and env.runtimeContext then
        return env.runtimeContext(dt, forceScan, initialPlacement, targetStationObject)
    end
    return {}
end

local function audienceContext(env)
    if env and env.audienceContext then return env.audienceContext() end
    return {}
end

local function trace(env, tag, ...)
    if env and env.lectureTrace and env.lectureTrace.log then
        return env.lectureTrace.log(env.debugLog, tag, ...)
    end
    if env and env.debugLog then env.debugLog(tag, ...) end
end

local function debugLog(env, ...)
    if env and env.debugLog then env.debugLog(...) end
end

local function lastCell(env)
    if env and type(env.lastCell) == "function" then return env.lastCell() end
    return env and env.lastCell or nil
end

local function settleInitialPlacement(env, reason, actorId)
    if not (env and env.settleInitialPlacementOverlay) then return end
    local pending = env.pendingInitialHandoffs and env.pendingInitialHandoffs() or nil
    if pending and actorId then pending[actorId] = nil end
    env.settleInitialPlacementOverlay(reason, actorId)
end

function M.rebalanceLecternAudience(env, newlyClaimed, options)
    if not newlyClaimed or #newlyClaimed == 0 then return end
    options = options or {}
    trace(
        env,
        "audience_gather_requested_global",
        "stations", tostring(#newlyClaimed),
        "force", tostring(options.force == true),
        "shortcut", tostring(options.debugShortcut == true),
        "teleport", tostring(options.teleportAudience == true),
        "source", tostring(options.source)
    )
    local audience = env and env.lectureAudience or nil
    if not (audience and audience.queueForStations) then return 0 end
    return audience.queueForStations(newlyClaimed, audienceContext(env), options)
end

function M.processStationAssignments(env, cell, dt, forceScan, initialPlacement, targetStationObject)
    local assignments = stationAssignments(env)
    if not (cell and assignments and assignments.process) then return end
    local newlyClaimed = assignments.process(cell, runtimeContext(env, dt, forceScan, initialPlacement, targetStationObject))
    if newlyClaimed and #newlyClaimed > 0 then
        local audienceClaimed = {}
        for _, data in ipairs(newlyClaimed) do
            if initialPlacement == true or data.testingOverride ~= true or data.lectureStartRequested == true then
                audienceClaimed[#audienceClaimed + 1] = data
            else
                trace(
                    env,
                    "audience_gather_skipped",
                    "station", tostring(data and data.objectId),
                    "slot", tostring(data and data.slotName),
                    "reason", "manual_presenter_claim_waiting_for_start_lecture"
                )
                debugLog(
                    env,
                    "lecture audience gather skipped",
                    "station", tostring(data and data.objectId),
                    "reason", "manual_presenter_claim_waiting_for_start_lecture"
                )
            end
        end

        local lectureRequested = false
        local teleportAudience = false
        local debugShortcut = false
        for _, data in ipairs(audienceClaimed) do
            lectureRequested = lectureRequested or data.lectureStartRequested == true
            teleportAudience = teleportAudience or data.lectureTeleportAudience == true
            debugShortcut = debugShortcut or data.lectureDebugShortcut == true
        end
        M.rebalanceLecternAudience(env, audienceClaimed, {
            force = initialPlacement == true or lectureRequested == true,
            source = initialPlacement == true and "initial_placement" or (lectureRequested == true and "developer_start_lecture_pending_presenter" or "station_lifecycle"),
            debugShortcut = debugShortcut == true,
            teleportAudience = teleportAudience == true,
        })
    end

    if initialPlacement == true and assignments.takePendingInitialActorIds then
        for _, actorId in ipairs(assignments.takePendingInitialActorIds()) do
            settleInitialPlacement(env, "station_initial_placement_done", actorId)
        end
    end
end

function M.triggerStationLecture(env, session, options)
    options = options or {}
    local assignments = stationAssignments(env)
    trace(
        env,
        "session_start_refresh_called",
        "path", "triggerStationLecture",
        "object", tostring(session and session.objectRecordId),
        "slot", tostring(session and session.slotKey),
        "debugShortcut", tostring(options.debugShortcut == true),
        "teleport", tostring(options.teleportAudience == true)
    )
    trace(
        env,
        "debug_shortcut_requested",
        "shortcut", tostring(options.debugShortcut == true),
        "teleport", tostring(options.teleportAudience == true)
    )
    local obj = session and session.object or nil
    local cell = obj and obj.cell or lastCell(env)
    if not (assignments and obj and cell) then
        trace(env, "session_start_refresh_result", "path", "triggerStationLecture", "started", "false", "reason", "missing_station_target")
        return false
    end

    local profile = env.profiles and env.profiles.stationProfileForObject and env.profiles.stationProfileForObject(obj, env.settings)
    if not profile then
        trace(env, "session_start_refresh_result", "path", "triggerStationLecture", "started", "false", "reason", "missing_station_profile", "object", tostring(obj.recordId))
        return false
    end

    local slotKey = env.stationSlotKey(obj, profile)
    local refreshed, _, data = assignments.refreshLecture(slotKey, runtimeContext(env, 0, true, false, obj), "developer_start_lecture")
    if refreshed and data then
        M.rebalanceLecternAudience(env, { data }, { force = true, source = "developer_start_lecture", debugShortcut = options.debugShortcut == true, teleportAudience = options.teleportAudience == true })
        trace(env, "session_start_refresh_result", "path", "triggerStationLecture_refresh", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
        return true
    end

    if session.actor and env.isObjValid and env.isObjValid(session.actor) then
        local ctx = runtimeContext(env, 0, true, false, obj)
        local _, pending = assignments.stationSlotOccupied(slotKey)
        if pending == true and options.teleportAudience ~= true then
            local marked = assignments.markPendingLectureStart(slotKey, {
                debugShortcut = options.debugShortcut == true,
                teleportAudience = options.teleportAudience == true,
                source = "developer_start_lecture",
            }, ctx)
            if marked == true then
                trace(env, "session_start_refresh_result", "path", "triggerStationLecture_pending_presenter", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
                return true
            end
        end
        local ok, reason = assignments.claimWithNpc(obj, session.actor, ctx, {
            testingOverride = true,
            calibrationAction = true,
            immediatePlacement = options.teleportAudience == true,
            forcePathing = options.teleportAudience ~= true,
            forcePathingImmediateRadius = 6,
            replaceExisting = true,
            ignoreChance = true,
            lectureStartRequested = true,
            lectureDebugShortcut = options.debugShortcut == true,
            lectureTeleportAudience = options.teleportAudience == true,
            lectureSource = "developer_start_lecture",
        })
        if not ok then
            debugLog(env, "station lecture selected actor claim failed", session.actor.recordId or session.actor.id, "object", tostring(obj.recordId), "reason", tostring(reason))
            trace(env, "session_start_refresh_result", "path", "triggerStationLecture_selected_actor", "started", "false", "reason", tostring(reason))
            return false
        end
        if reason == "pathing" then
            trace(env, "session_start_refresh_result", "path", "triggerStationLecture_selected_actor_pathing", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
            return true
        end
        data = assignments.claimedStationData(slotKey)
        if data then
            M.rebalanceLecternAudience(env, { data }, { force = true, source = "developer_start_lecture", debugShortcut = options.debugShortcut == true, teleportAudience = options.teleportAudience == true })
            trace(env, "session_start_refresh_result", "path", "triggerStationLecture_selected_actor", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
            return true
        end
    end

    local ctx = runtimeContext(env, 0, true, false, obj)
    local ok, reason = assignments.claimNearestPresenterForStation(obj, ctx, {
        testingOverride = true,
        calibrationAction = true,
        immediatePlacement = options.teleportAudience == true,
        forcePathing = options.teleportAudience ~= true,
        forcePathingImmediateRadius = 6,
        replaceExisting = true,
        ignoreChance = true,
        lectureStartRequested = true,
        lectureDebugShortcut = options.debugShortcut == true,
        lectureTeleportAudience = options.teleportAudience == true,
        lectureSource = "developer_start_lecture",
    })
    if ok and reason == "pathing" then
        trace(env, "session_start_refresh_result", "path", "triggerStationLecture_nearest_presenter_pathing", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
        return true
    end
    data = ok and assignments.claimedStationData(slotKey) or nil
    if data then
        assignments.refreshLecture(slotKey, runtimeContext(env, 0, true, false, obj), "developer_start_lecture")
        M.rebalanceLecternAudience(env, { data }, { force = true, source = "developer_start_lecture", debugShortcut = options.debugShortcut == true, teleportAudience = options.teleportAudience == true })
        trace(env, "session_start_refresh_result", "path", "triggerStationLecture_nearest_presenter", "started", "true", "object", tostring(obj.recordId), "slot", tostring(slotKey))
        return true
    end
    trace(env, "session_start_refresh_result", "path", "triggerStationLecture", "started", "false", "reason", tostring(reason or "no_claimed_presenter"), "object", tostring(obj.recordId), "slot", tostring(slotKey))
    return false
end

function M.claimStationWithNpc(env, sessionOrObject, npc, options)
    local assignments = stationAssignments(env)
    local obj = sessionOrObject and sessionOrObject.object or sessionOrObject
    if not (assignments and obj and npc) then return false, "missing_station_or_actor" end
    local ok, reason = assignments.claimWithNpc(obj, npc, runtimeContext(env, 0, true, false, obj), options or {})
    if ok then
        local profile = env.profiles and env.profiles.stationProfileForObject and env.profiles.stationProfileForObject(obj, env.settings)
        local slotKey = profile and env.stationSlotKey(obj, profile) or nil
        local data = slotKey and assignments.claimedStationData(slotKey) or nil
        if data and not (options and options.suppressAudience == true) then
            M.rebalanceLecternAudience(env, { data }, { force = true, source = "manual_station_claim" })
        end
    end
    return ok, reason
end

function M.releaseStationForNpc(env, npc, reason)
    local assignments = stationAssignments(env)
    if not (assignments and npc) then return false end
    return assignments.releaseForNpc(npc, reason or "developer_station_cleanup", runtimeContext(env, 0, true, false, nil))
end

function M.stationDataForNpc(env, npc)
    local assignments = stationAssignments(env)
    return assignments and assignments.stationDataForNpc and assignments.stationDataForNpc(npc) or nil
end

function M.stationSlotOccupied(env, slotKey)
    local assignments = stationAssignments(env)
    if not (assignments and assignments.stationSlotOccupied) then return false, false end
    return assignments.stationSlotOccupied(slotKey)
end

function M.claimedStationData(env, slotKey)
    local assignments = stationAssignments(env)
    return assignments and assignments.claimedStationData and assignments.claimedStationData(slotKey) or nil
end

function M.applyStationCalibration(env, session)
    local assignments = stationAssignments(env)
    if not (assignments and assignments.applyCalibration) then return false, "station_calibration_unavailable" end
    return assignments.applyCalibration(session, runtimeContext(env, 0, true, false, session and session.object or nil))
end

function M.onStationPoseRequest(env, ev)
    local npc = ev and ev.npc or nil
    if env.isNpcValid and not env.isNpcValid(npc) then return end
    if not (npc and npc.cell) then return end
    local assignments = stationAssignments(env)
    if not assignments then return end
    local npcLabel = npc.recordId or npc.id
    local slotKey = ev and ev.slotKey or nil
    local stationData = slotKey and assignments.claimedStationData(slotKey) or assignments.stationDataForNpc(npc)
    if not (stationData and stationData.npc == npc) then
        debugLog(env, "station pose request rejected", npcLabel, "reason", "station_claim_mismatch", "object", tostring(ev and ev.objectId), "slot", tostring(slotKey))
        return
    end
    local pos = ev and ev.finalPosition or stationData.position
    local yaw = ev and ev.finalRotation or stationData.finalRotation
    if not pos then return end

    local smoothReason = ev and ev.reason or nil
    if smoothReason == "station_dialogue_facing_restore"
        and env.smoothMoveActive
        and env.smoothMoveActive(npc.id) then
        debugLog(env, "station pose smooth skipped", npcLabel, "object", tostring(stationData.objectId or ev.objectId), "slot", tostring(stationData.slotName), "reason", tostring(smoothReason), "state", "already_smoothing")
        return
    end
    if smoothReason == "station_presenter_entry"
        or smoothReason == "station_dialogue_facing_restore"
        or tonumber(ev and ev.smoothDuration) ~= nil then
        local queued = env.smoothMove and env.smoothMove(npc, stationData, pos, yaw, smoothReason or "station_pose_restore", smoothReason or "station_pose_restore", {
            duration = tonumber(ev.smoothDuration) or (smoothReason == "station_dialogue_facing_restore" and 1.15 or 0.65),
            skipStateCheck = true,
            isActive = function(activeNpc, activeData)
                return activeNpc == npc
                    and activeData == stationData
                    and slotKey ~= nil
                    and assignments.claimedStationData(slotKey) == stationData
            end,
        })
        if queued then
            debugLog(env, "station pose smooth queued", npcLabel, "object", tostring(stationData.objectId or ev.objectId), "slot", tostring(stationData.slotName), "duration", tostring(ev.smoothDuration), "reason", tostring(smoothReason))
            return
        end
        if smoothReason == "station_dialogue_facing_restore" then
            debugLog(env, "station pose smooth deferred", npcLabel, "object", tostring(stationData.objectId or ev.objectId), "slot", tostring(stationData.slotName), "reason", tostring(smoothReason), "state", "queue_rejected")
            return
        end
    end

    local ok, err = env.tryTeleport(npc, npc.cell, pos, {
        rotation = env.rotationFromYaw(yaw, npc.rotation),
    })
    if ok then
        debugLog(env, "station pose request applied", npcLabel, "object", tostring(stationData.objectId or (ev and ev.objectId)), "slot", tostring(stationData.slotName), "reason", tostring(ev and ev.reason))
    else
        debugLog(env, "station pose request failed", npcLabel, "object", tostring(stationData.objectId or (ev and ev.objectId)), "slot", tostring(stationData.slotName), "reason", tostring(ev and ev.reason), tostring(err))
    end
end

return M
