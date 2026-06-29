---@omw-context none
-- Builds calibration-only HUD marker events for seated/sleeping NPCs whose
-- accepted assignment carries visible placement-blocker context.

local M = {}

M.blockedEvent = "SitDownPleaseCalibrationBlockerMarker"
M.clearEvent = "SitDownPleaseCalibrationBlockerMarkerClear"

local SURFACE_REASONS = {
    seat_surface_blocked_by_item = true,
    sleep_surface_blocked_by_item = true,
    soft_seat_clutter_surface = true,
    initial_sleep_surface_not_ready = true,
    sleep_surface_untrusted = true,
    sleep_bunk_slot_untrusted = true,
    sleep_final_position_invalid = true,
}

local CLEARANCE_REASONS = {
    tight_table_or_counter_rejected = true,
    clearance_blocked_by_object = true,
}

local STAND_EXIT_REASONS = {
    no_safe_sitting_stand_exit = true,
    no_safe_sleep_stand_exit = true,
    no_safe_stand_exit = true,
    sleep_exit_destination_too_far = true,
    sleep_exit_destination_too_low = true,
    wake_exit_walk_destination_too_low = true,
    no_valid_destinations = true,
}

local ROUTE_REASONS = {
    approach_too_far_from_navmesh = true,
    approach_navmesh_behind_collision = true,
    no_nearest_navmesh = true,
    no_path_to_bed = true,
    blocked_by_wall = true,
    route_too_indirect = true,
    wrong_floor_or_unreachable = true,
    sleep_entry_rejected = true,
    visible_sleep_route_incomplete = true,
    public_bed_requires_door_assist = true,
    blocked_route_door = true,
    trapped_route_door = true,
}

local LOCKED_SLEEP_EXIT_REASONS = {
    locked_route_door = true,
    locked_route_door_missing_key = true,
    locked_route_door_unknown_key = true,
}

local function normalized(value)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    return value
end

local function actorId(actor)
    return actor and actor.id or nil
end

local function recordId(actor)
    return actor and actor.recordId or nil
end

local function classifyReason(reason)
    reason = normalized(reason)
    if not reason then return nil, nil end
    if SURFACE_REASONS[reason] then return "surface", reason end
    if CLEARANCE_REASONS[reason] then return "clearance", reason end
    if STAND_EXIT_REASONS[reason] then return "stand_exit", reason end
    if ROUTE_REASONS[reason] then return "stand_exit", reason end
    return nil, nil
end

local function hasPositionList(list)
    return type(list) == "table" and list[1] ~= nil
end

local function calibrationPlacedActor(ev)
    if not ev then return false end
    return ev.calibrationAction == true
        or ev.calibrationTestNpc == true
        or ev.calibrationFill == true
        or ev.explicitFillOverride == true
        or ev.manualAssignOverrideTesting == true
        or ev.calibrationFillSource ~= nil
        or ev.calibrationFillLabel ~= nil
        or ev.calibrationFillSessionId ~= nil
end

local function markerEligible(ev)
    if not ev or not ev.npc then return false end
    local interactionType = tostring(ev.interactionType or "")
    if interactionType ~= "sitting" and interactionType ~= "sleeping" then return false end
    if tostring(ev.state or "") == "interacting" then return true end
    return calibrationPlacedActor(ev) == true
end

local function classifiedFields()
    return {
        "reason",
        "hardBlockerReason",
        "sleepSafetyReason",
        "sleepAccessOverrideReason",
        "sleepCalibrationWarningReason",
        "manualAssignOverrideReason",
        "manualAssignOverrideReasons",
        "surfaceBlockerReason",
        "surfaceBlockerOverrideReason",
        "softBlockerReason",
        "sleepRouteReason",
        "sleepRouteNavReason",
    }
end

local function hasUnsafeStandExitState(ev)
    if not markerEligible(ev) then return false, nil end
    local interactionType = tostring(ev.interactionType or "")
    if interactionType == "sitting" then
        if ev.sittingStandExitValidated == true and hasPositionList(ev.sittingStandExitPositions) then
            return false, nil
        end
        return true, "no_safe_sitting_stand_exit"
    end
    if interactionType == "sleeping" then
        if hasPositionList(ev.exitPositions) then
            return false, nil
        end
        return true, "no_safe_sleep_stand_exit"
    end
    return false, nil
end

local function lockedSleepExitReason(ev)
    if not markerEligible(ev) then return nil end
    if tostring(ev.interactionType or "") ~= "sleeping" then return nil end
    if calibrationPlacedActor(ev) then return nil end
    for _, field in ipairs({
        "reason",
        "hardBlockerReason",
        "sleepSafetyReason",
        "sleepAccessOverrideReason",
        "sleepCalibrationWarningReason",
        "routeDoorReason",
    }) do
        local reason = normalized(ev[field])
        if LOCKED_SLEEP_EXIT_REASONS[reason] then return reason end
    end
    return nil
end

function M.classify(ev)
    if not ev then return nil, nil end
    for _, field in ipairs(classifiedFields()) do
        local kind, reason = classifyReason(ev[field])
        if kind then return kind, reason end
        if field == "reason" and normalized(ev.reason) then return nil, nil end
    end

    return nil, nil
end

function M.classifyAll(ev)
    local out = {}
    local seen = {}
    local function add(kind, reason)
        if not kind then return end
        if seen[kind] then return end
        seen[kind] = true
        out[#out + 1] = {
            kind = kind,
            reason = reason,
        }
    end

    for _, field in ipairs(classifiedFields()) do
        local kind, reason = classifyReason(ev and ev[field])
        add(kind, reason)
    end

    local unsafe, standReason = hasUnsafeStandExitState(ev)
    if unsafe then add("stand_exit", standReason) end

    local lockedExitReason = lockedSleepExitReason(ev)
    if lockedExitReason then add("stand_exit", lockedExitReason) end

    return out
end

function M.blockedPayload(ev)
    if not markerEligible(ev) then return nil end
    local kind, reason = M.classify(ev)
    if not (kind and ev and ev.npc and actorId(ev.npc)) then return nil end
    return {
        actor = ev.npc,
        actorId = actorId(ev.npc),
        recordId = recordId(ev.npc),
        kind = kind,
        reason = reason,
        rejectionReason = ev.reason,
        interactionType = ev.interactionType,
        object = ev.object,
        objectId = ev.objectId,
        slotKey = ev.slotKey,
        slotName = ev.slotName,
        profileId = ev.profileId,
        surfaceBlockerReason = ev.surfaceBlockerReason,
        surfaceBlockerOverrideReason = ev.surfaceBlockerOverrideReason,
        surfaceBlockerKind = ev.surfaceBlockerKind,
        surfaceBlockerObjectId = ev.surfaceBlockerObjectId,
        surfaceBlockerDistance = ev.surfaceBlockerDistance,
        surfaceBlockerVertical = ev.surfaceBlockerVertical,
        surfaceBlockerLocalReason = ev.surfaceBlockerLocalReason,
        softBlockerReason = ev.softBlockerReason,
        hardBlockerReason = ev.hardBlockerReason,
        sleepSafetyReason = ev.sleepSafetyReason,
        sleepSafetyDelta = ev.sleepSafetyDelta,
        sleepSafetyLimit = ev.sleepSafetyLimit,
        sleepAccessOverrideReason = ev.sleepAccessOverrideReason,
        manualAssignOverrideReason = ev.manualAssignOverrideReason,
        manualAssignOverrideReasons = ev.manualAssignOverrideReasons,
        sleepRouteReason = ev.sleepRouteReason,
        sleepRouteApproachName = ev.sleepRouteApproachName,
        sleepRouteApproachPos = ev.sleepRouteApproachPos,
        sleepRouteNavPos = ev.sleepRouteNavPos,
        sleepRouteNavReason = ev.sleepRouteNavReason,
        sleepRouteNavDelta = ev.sleepRouteNavDelta,
        sleepRoutePathLength = ev.sleepRoutePathLength,
    }
end

function M.blockedPayloads(ev)
    if not markerEligible(ev) then return nil end
    if not (ev and ev.npc and actorId(ev.npc)) then return nil end
    local classifications = M.classifyAll(ev)
    if #classifications == 0 then return nil end
    local payloads = {}
    for _, item in ipairs(classifications) do
        payloads[#payloads + 1] = {
            actor = ev.npc,
            actorId = actorId(ev.npc),
            recordId = recordId(ev.npc),
            kind = item.kind,
            reason = item.reason,
            rejectionReason = ev.reason,
            interactionType = ev.interactionType,
            object = ev.object,
            objectId = ev.objectId,
            slotKey = ev.slotKey,
            slotName = ev.slotName,
            profileId = ev.profileId,
            surfaceBlockerReason = ev.surfaceBlockerReason,
            surfaceBlockerOverrideReason = ev.surfaceBlockerOverrideReason,
            surfaceBlockerKind = ev.surfaceBlockerKind,
            surfaceBlockerObjectId = ev.surfaceBlockerObjectId,
            surfaceBlockerDistance = ev.surfaceBlockerDistance,
            surfaceBlockerVertical = ev.surfaceBlockerVertical,
            surfaceBlockerLocalReason = ev.surfaceBlockerLocalReason,
            softBlockerReason = ev.softBlockerReason,
            hardBlockerReason = ev.hardBlockerReason,
            sleepSafetyReason = ev.sleepSafetyReason,
            sleepSafetyDelta = ev.sleepSafetyDelta,
            sleepSafetyLimit = ev.sleepSafetyLimit,
            sleepAccessOverrideReason = ev.sleepAccessOverrideReason,
            manualAssignOverrideReason = ev.manualAssignOverrideReason,
            manualAssignOverrideReasons = ev.manualAssignOverrideReasons,
            sleepRouteReason = ev.sleepRouteReason,
            sleepRouteApproachName = ev.sleepRouteApproachName,
            sleepRouteApproachPos = ev.sleepRouteApproachPos,
            sleepRouteNavPos = ev.sleepRouteNavPos,
            sleepRouteNavReason = ev.sleepRouteNavReason,
            sleepRouteNavDelta = ev.sleepRouteNavDelta,
            sleepRoutePathLength = ev.sleepRoutePathLength,
        }
    end
    return payloads
end

function M.clearPayload(ev, reason)
    if not (ev and ev.npc and actorId(ev.npc)) then return nil end
    return {
        actor = ev.npc,
        actorId = actorId(ev.npc),
        recordId = recordId(ev.npc),
        reason = reason or ev.reason or "clear",
    }
end

function M.clearAllPayload(reason)
    return {
        all = true,
        reason = reason or "clear_all",
    }
end

local function send(players, eventName, payload)
    if not (payload and players) then return false end
    local sent = false
    for _, player in ipairs(players or {}) do
        pcall(function()
            player:sendEvent(eventName, payload)
            sent = true
        end)
    end
    return sent
end

function M.sendBlocked(players, ev)
    local payloads = M.blockedPayloads(ev)
    if not (payloads and #payloads > 0) then return false end
    send(players, M.clearEvent, M.clearPayload(ev, "replace_markers"))
    local sent = false
    for _, payload in ipairs(payloads) do
        sent = send(players, M.blockedEvent, payload) == true or sent
    end
    return sent
end

function M.sendRejectedBlocked(players, ev)
    if M.sendBlocked(players, ev) then return true end
    return M.sendCleared(players, ev, "rejected_not_seated")
end

function M.sendCleared(players, ev, reason)
    return send(players, M.clearEvent, M.clearPayload(ev, reason))
end

function M.sendAllCleared(players, reason)
    return send(players, M.clearEvent, M.clearAllPayload(reason))
end

function M.syncAssignment(players, ev, now)
    if not (ev and ev.npc and actorId(ev.npc)) then return false end
    now = tonumber(now) or 0
    local nextAt = tonumber(ev.blockerMarkerNextSyncAt) or 0
    if nextAt > now then return false end
    ev.blockerMarkerNextSyncAt = now + 0.75

    if M.sendBlocked(players, ev) then return true end
    return M.sendCleared(players, ev, markerEligible(ev) and "no_blocker_marker" or "not_seated_marker")
end

return M
