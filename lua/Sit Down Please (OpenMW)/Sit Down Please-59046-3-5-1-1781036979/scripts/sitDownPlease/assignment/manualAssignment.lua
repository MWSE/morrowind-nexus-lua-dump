-- assignment/manualAssignment.lua
---@omw-context none
-- Developer/manual reassignment cleanup helpers. Kept separate so calibration/actionController.lua
-- can stay small and interactionAssignment.lua does not gain local pressure.

local M = {}

local MAX_MANUAL_SLEEP_FALLBACK_VERTICAL = 220
local MAX_MANUAL_SLEEP_FALLBACK_DISTANCE = 900

local function noopLog(...)
end

function M.cleanupBeforeReassign(ctx, actor, candidate, reason)
    if not (ctx and actor and actor.id) then return false end
    local infoLog = ctx.infoLog or noopLog
    local debugLog = ctx.debugLog or noopLog
    local assignedActors = ctx.getAssignedActors and ctx.getAssignedActors() or {}
    local data = assignedActors and assignedActors[actor.id] or nil
    local label = actor.recordId or actor.id
    local why = reason or "manual_reassign"

    infoLog("reassign_begin", label, "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidate.slotName), "reason", tostring(why))
    if not data then
        debugLog("reassign_no_existing_claim", label, "reason", tostring(why))
        return false
    end

    infoLog("old_claim_released", label, "type", tostring(data.interactionType), "object", tostring(data.objectId), "slot", tostring(data.slotName))
    pcall(function()
        actor:sendEvent("StopInteractionObject", {
            reason = why,
            interactionType = data.interactionType,
            forceClearSleepAnimation = true,
        })
    end)
    pcall(function()
        actor:sendEvent("SitDownPleaseClearBriefTravel", { reason = why })
    end)
    infoLog("old_interaction_stopped", label, "type", tostring(data.interactionType), "reason", tostring(why))

    local stopInteractionForNpc = ctx.stopInteractionForNpc and ctx.stopInteractionForNpc() or nil
    if stopInteractionForNpc then
        pcall(function() stopInteractionForNpc(actor, why) end)
    end

    if data.interactionType == "sleeping" then
        infoLog("safe_exit_started", label, "type", "sleeping", "reason", tostring(why))
    else
        infoLog("safe_exit_completed", label, "type", tostring(data.interactionType), "reason", tostring(why))
    end
    return true
end

function M.logRouteStarted(infoLog, actor, candidate)
    if type(infoLog) ~= "function" then return end
    infoLog("reassign_route_started", actor and (actor.recordId or actor.id), "type", tostring(candidate and candidate.interactionType), "object", tostring(candidate and candidate.objectId), "slot", tostring(candidate and candidate.slotName))
end

function M.isManualReassignReason(reason)
    local text = tostring(reason or "")
    return text:find("manual_assign_retarget", 1, true) ~= nil
        or text == "manual_reassign"
        or text == "manual_assign_no_progress_fallback"
        or text == "manual_assign_hard_timeout_fallback"
end

function M.testingOverrideActive(data)
    return data and (
        data.manualAssignOverrideTesting == true
        or data.calibrationAction == true
        or data.calibrationFill == true
        or data.explicitFillOverride == true
    ) or false
end

function M.noteTestingOverride(data, reason)
    if not M.testingOverrideActive(data) then return false end
    data.manualAssignOverrideApplied = true
    data.manualAssignOverrideReasons = data.manualAssignOverrideReasons or {}
    data.manualAssignOverrideReasons[#data.manualAssignOverrideReasons + 1] = tostring(reason or "override")
    return true
end

function M.canBypassLocalBlock(data, reason)
    if not M.testingOverrideActive(data) then return false end
    reason = tostring(reason or "")
    local teleportDoorRoute = reason == "teleport_door_route_required"
        or reason == "locked_teleport_door_route"
        or reason == "key_unknown_teleport_door_route"
    if teleportDoorRoute then
        if data and data.calibrationTestNpc == true then
            M.noteTestingOverride(data, "spawned_test_actor_reachability_override")
            return true
        end
        return false
    end
    local hardReject = reason == "dead_actor"
        or reason == "invalid_actor"
        or reason == "disabled_actor"
        or reason == "missing_object"
        or reason == "object_invalid"
        or reason == "missing_transform"
        or reason == "no_valid_transform"
        or reason == "external_animation_npc"
        or reason == "external_control_script"
        or reason == "external_control_movement"
        or reason == "external_control_side_movement"
        or reason == "external_control_jump"
        or reason == "external_control_use"
        or reason == "active_follow_or_escort_package"
        or reason == "escort_or_follow_package"
    if hardReject then return false end
    M.noteTestingOverride(data, reason ~= "" and reason or "manual_testing_override")
    return true
end

function M.bypassLocalRejection(ctx, data, reason, bypass)
    if not M.noteTestingOverride(data, reason) then return false end
    local debugLog = ctx and ctx.debugLog or noopLog
    local object = ctx and ctx.object or nil
    debugLog(
        "nearest_manual_assign_override",
        "reason", tostring(reason),
        "object", tostring(object and object.recordId),
        "slot", tostring(ctx and ctx.slotName),
        "bypass", tostring(bypass or "local_rejection")
    )
    return true
end

function M.tryManualRouteFallback(ctx, npc, data, distance, stuckTimedOut, hardTimedOut)
    if not (ctx and npc and data and data.manualAssignOverrideTesting == true) then return false end
    if not (stuckTimedOut == true or hardTimedOut == true) then return false end
    local dest = data.approachPos or data.finalPosition or data.position
    if not (dest and npc.cell) then return false end

    local reason = hardTimedOut and "manual_assign_hard_timeout_fallback" or "manual_assign_no_progress_fallback"
    local infoLog = ctx.infoLog or noopLog
    local debugLog = ctx.debugLog or noopLog
    if data.manualRouteFallbackUsed == true then
        if data.manualRouteFallbackRepeatLogged ~= true then
            debugLog("manual route fallback repeat suppressed", npc.recordId or npc.id, tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName))
            data.manualRouteFallbackRepeatLogged = true
        end
        return true
    end
    infoLog("actor_no_progress_near_door", npc.recordId or npc.id, "type", tostring(data.interactionType), "object", tostring(data.objectId), "distance", tostring(distance), "reason", tostring(reason))

    if data.interactionType == "sleeping" and npc.position then
        local vertical = math.abs((npc.position.z or 0) - (dest.z or 0))
        local directDistance = (npc.position - dest):length()
        if vertical > 90 then
            if data.calibrationAction ~= true and (vertical > MAX_MANUAL_SLEEP_FALLBACK_VERTICAL or directDistance > MAX_MANUAL_SLEEP_FALLBACK_DISTANCE) then
                data.manualRouteFallbackUsed = true
                infoLog(
                    "manual_route_fallback_sleep_rejected",
                    npc.recordId or npc.id,
                    "object", tostring(data.objectId),
                    "slot", tostring(data.slotName),
                    "reason", "manual_sleep_wrong_floor_or_room",
                    "distance", tostring(directDistance),
                    "vertical", tostring(vertical),
                    "fallbackReason", tostring(reason)
                )
                if ctx.sendStatus then
                    ctx.sendStatus("Manual sleep fallback rejected: selected bed is on another floor or room.", data.interactionType, nil)
                end
                pcall(function()
                    npc:sendEvent("StopInteractionObject", {
                        reason = "manual_sleep_wrong_floor_or_room",
                        interactionType = data.interactionType,
                        forceClearSleepAnimation = true,
                    })
                end)
                pcall(function()
                    npc:sendEvent("SitDownPleaseClearBriefTravel", { reason = "manual_sleep_wrong_floor_or_room" })
                end)
                if ctx.stopInteractionForNpc then
                    pcall(function() ctx.stopInteractionForNpc(npc, "manual_sleep_wrong_floor_or_room") end)
                end
                return true
            end
            M.noteTestingOverride(data, "manual_sleep_wrong_floor_or_room")
            data.manualRouteFallbackUsed = true
            infoLog(
                "manual_route_fallback_sleep_override",
                npc.recordId or npc.id,
                "object", tostring(data.objectId),
                "slot", tostring(data.slotName),
                "reason", tostring(reason),
                "distance", tostring(directDistance),
                "vertical", tostring(vertical)
            )
            data.manualSleepEntryOverride = true
            if ctx.sendStatus then
                ctx.sendStatus("Manual sleep override: entering selected bed.", data.interactionType, nil)
            end
            if ctx.beginTransition then
                ctx.beginTransition(npc, data, reason)
                return true
            end
            return false
        end
    end

    local rotation = nil
    if ctx.rotationFromYaw and ctx.targetYawForData then
        rotation = ctx.rotationFromYaw(ctx.targetYawForData(npc, data), npc.rotation)
    end
    local ok, err
    if ctx.tryTeleport then
        ok, err = ctx.tryTeleport(npc, npc.cell, dest, { rotation = rotation or npc.rotation, onGround = true })
    else
        ok, err = false, "tryTeleport_unavailable"
    end
    if not ok then
        data.manualRouteFallbackUsed = true
        debugLog("manual route fallback teleport failed", npc.recordId or npc.id, tostring(reason), tostring(err))
        return false
    end

    data.manualRouteFallbackUsed = true
    infoLog("door_route_fallback_teleport", npc.recordId or npc.id, "type", tostring(data.interactionType), "object", tostring(data.objectId), "slot", tostring(data.slotName), "reason", tostring(reason), "dest", tostring(dest))
    if ctx.sendStatus then
        ctx.sendStatus("Manual route fallback used after no progress.", data.interactionType, nil)
    end
    if ctx.beginTransition then
        if data.interactionType == "sleeping" then
            data.reachedValidSleepApproach = true
            ctx.beginTransition(npc, data, "reached_approach")
        else
            ctx.beginTransition(npc, data, reason)
        end
    end
    return true
end

return M
