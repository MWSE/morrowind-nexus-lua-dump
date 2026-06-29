-- interactions/sleeping/routeRejection.lua
---@omw-context none
local M = {}

local COOLDOWN_SECONDS = 90

local ROUTE_REJECT_REASONS = {
    no_path_to_bed = true,
    wrong_floor_or_unreachable = true,
    blocked_by_wall = true,
    route_too_indirect = true,
    approach_too_far_from_navmesh = true,
    approach_navmesh_behind_collision = true,
    visible_sleep_route_incomplete = true,
    sleep_route_incomplete = true,
    sleep_entry_rejected = true,
    no_safe_sleep_stand_exit = true,
    public_bed_requires_door_assist = true,
    locked_route_door = true,
    blocked_route_door = true,
    trapped_route_door = true,
}

function M.isRouteRejectReason(reason)
    return ROUTE_REJECT_REASONS[tostring(reason or "")] == true
end

local function cooldownKey(npc, slotKey)
    if not (npc and slotKey) then return nil end
    return tostring(npc.id or npc.recordId or "<npc>") .. "::" .. tostring(slotKey)
end

function M.cooldownActive(state, now, npc, slotKey)
    local key = cooldownKey(npc, slotKey)
    if not key then return false end

    local untilTime = state and state[key] or nil
    if not untilTime then return false end
    if (tonumber(now) or 0) < untilTime then return true end

    state[key] = nil
    return false
end

function M.markCooldown(state, now, npc, slotKey, reason, debugLogFn)
    local key = cooldownKey(npc, slotKey)
    if not key then return end

    state[key] = (tonumber(now) or 0) + COOLDOWN_SECONDS
    if debugLogFn then
        debugLogFn(
            "sleep_route_reject_cooldown_from_local",
            npc and (npc.recordId or npc.id),
            "slot", tostring(slotKey),
            "reason", tostring(reason),
            "seconds", tostring(COOLDOWN_SECONDS)
        )
    end
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function explicitRetryAllowed(ev)
    return ev
        and (
            ev.initialPlacement == true
            or ev.manualAssign == true
            or ev.manualAssignOverrideTesting == true
            or ev.calibrationAction == true
            or ev.calibrationFill == true
            or ev.calibrationFillSource ~= nil
            or ev.calibrationFillLabel ~= nil
            or ev.calibrationTestNpc == true
            or ev.debugForced == true
        )
end

local function routeFailureTiming(ev)
    if ev.initialPlacement == true then
        return {
            npc = ev.npc,
            initialPlacement = true,
            ignoreTimeGate = true,
        }
    end

    if explicitRetryAllowed(ev) then
        return {
            npc = ev.npc,
            ignoreTimeGate = true,
            manualAssign = ev.manualAssign == true,
            manualAssignOverrideTesting = ev.manualAssignOverrideTesting == true,
            calibrationAction = ev.calibrationAction == true,
            calibrationFill = ev.calibrationFill == true,
            calibrationFillSource = ev.calibrationFillSource,
            calibrationFillLabel = ev.calibrationFillLabel,
            calibrationFillRole = ev.calibrationFillRole,
            calibrationFillIndex = ev.calibrationFillIndex,
            calibrationFillSessionId = ev.calibrationFillSessionId,
            calibrationTestNpc = ev.calibrationTestNpc == true,
            debugForce = ev.debugForced == true,
        }
    end
    return nil
end

function M.retryCandidate(ctx, ev)
    if not (ev and ev.interactionType == "sleeping" and M.isRouteRejectReason(ev.reason)) then
        return false, nil
    end

    debugLog(
        ctx,
        "sleep_route_rejected_feedback_received",
        ev.npc and (ev.npc.recordId or ev.npc.id),
        "object", tostring(ev.objectId),
        "slot", tostring(ev.slotName),
        "reason", tostring(ev.reason),
        "approach", tostring(ev.sleepRouteApproachName),
        "approachPos", tostring(ev.sleepRouteApproachPos),
        "navPos", tostring(ev.sleepRouteNavPos),
        "navReason", tostring(ev.sleepRouteNavReason),
        "navDelta", tostring(ev.sleepRouteNavDelta),
        "pathLength", tostring(ev.sleepRoutePathLength)
    )

    if ctx.markSleepRouteRejected then ctx.markSleepRouteRejected(ev.npc, ev.slotKey, ev.reason) end
    if not explicitRetryAllowed(ev) then
        debugLog(
            ctx,
            "sleep route rejection retry deferred",
            ev.npc and (ev.npc.recordId or ev.npc.id),
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName),
            "reason", tostring(ev.reason),
            "approach", tostring(ev.sleepRouteApproachName),
            "approachPos", tostring(ev.sleepRouteApproachPos),
            "navReason", tostring(ev.sleepRouteNavReason),
            "navDelta", tostring(ev.sleepRouteNavDelta),
            "pathLength", tostring(ev.sleepRoutePathLength)
        )
        return true, nil
    end

    local sleepTiming = routeFailureTiming(ev)
    if not sleepTiming then return true, nil end
    sleepTiming.avoidSlotKey = ev.slotKey

    local candidates = ctx.buildCandidateSlots and ctx.buildCandidateSlots(ev.npc.cell, "sleeping", sleepTiming) or nil
    local candidate = candidates and ctx.chooseCandidateForNpc and ctx.chooseCandidateForNpc(ev.npc, candidates, "sleeping", sleepTiming) or nil
    if not candidate then return true, nil end

    candidate.initialPlacement = ev.initialPlacement == true
    candidate.ignoreTimeGate = sleepTiming.ignoreTimeGate == true
    candidate.sleepPhase = sleepTiming.phase
    candidate.actorBedtime = sleepTiming.actorBedtime
    candidate.actorWakeTime = sleepTiming.actorWakeTime
    candidate.sleepWakeBias = sleepTiming.wakeBias
    candidate.observedPlayerOverride = sleepTiming.observedPlayerOverride
    candidate.manualAssign = sleepTiming.manualAssign == true
    candidate.manualAssignOverrideTesting = sleepTiming.manualAssignOverrideTesting == true
    candidate.calibrationAction = sleepTiming.calibrationAction == true
    candidate.calibrationFill = sleepTiming.calibrationFill == true
    candidate.calibrationFillSource = sleepTiming.calibrationFillSource
    candidate.calibrationFillLabel = sleepTiming.calibrationFillLabel
    candidate.calibrationFillRole = sleepTiming.calibrationFillRole
    candidate.calibrationFillIndex = sleepTiming.calibrationFillIndex
    candidate.calibrationFillSessionId = sleepTiming.calibrationFillSessionId
    candidate.calibrationTestNpc = sleepTiming.calibrationTestNpc == true
    candidate.debugForced = sleepTiming.debugForce == true
    return true, candidate
end

function M.retryAfterStopped(ctx, npc, data, reason)
    if not (npc and data and data.interactionType == "sleeping") then return false, "not_sleeping" end
    if not M.isRouteRejectReason(reason) then return false, "not_route_reject" end

    local _, candidate = M.retryCandidate(ctx, {
        npc = npc,
        interactionType = "sleeping",
        reason = reason,
        objectId = data.objectId,
        object = data.object,
        objectPosition = data.object and data.object.position or nil,
        finalPosition = data.finalPosition,
        slotName = data.slotName,
        slotKey = data.slotKey,
        initialPlacement = data.initialPlacement == true,
        manualAssign = data.manualAssign == true,
        manualAssignOverrideTesting = data.manualAssignOverrideTesting == true,
        calibrationAction = data.calibrationAction == true,
        calibrationFill = data.calibrationFill == true,
        calibrationFillSource = data.calibrationFillSource,
        calibrationFillLabel = data.calibrationFillLabel,
        calibrationFillRole = data.calibrationFillRole,
        calibrationFillIndex = data.calibrationFillIndex,
        calibrationFillSessionId = data.calibrationFillSessionId,
        calibrationTestNpc = data.calibrationTestNpc == true,
        debugForced = data.debugForced == true,
    })
    if not candidate then return false, "no_candidate" end

    if ctx.debugLog then
        ctx.debugLog(
            "sleep_route_failure_immediate_reassign",
            npc.recordId or npc.id,
            "fromObject", tostring(data.objectId),
            "toObject", tostring(candidate.objectId),
            "slot", tostring(candidate.slotName),
            "reason", tostring(reason)
        )
    end
    if ctx.sendConsiderInteraction then
        local sent, sendReason = ctx.sendConsiderInteraction(npc, candidate)
        if sent == true then return true, "reassigned" end
        return false, sendReason or "send_failed"
    end
    return false, "send_unavailable"
end

function M.returnHomeAfterFailedRoute(ctx, npc, data, reason)
    if not (ctx and ctx.sendReturnHomeAfterFailedRoute and npc and data and data.interactionType == "sleeping") then return false end
    if not M.isRouteRejectReason(reason) then return false end
    if data.usedSleepEntrySnap == true then return false end
    if data.state == "interacting" or data.state == "transitioning" then return false end
    return ctx.sendReturnHomeAfterFailedRoute(npc, data, reason) == true
end

return M
