-- interactions/sleeping/entryGate.lua
---@omw-context none
-- Sleep entry and blocked-approach fallback policy.

local M = {}

local DEFAULT_DIRECT_BED_ENTRY_DISTANCE = 300
local DEFAULT_DIRECT_BED_ENTRY_VERTICAL = 95

local function settingsFrom(ctx)
    if type(ctx.settings) == "function" then return ctx.settings() end
    return ctx.settings or {}
end

function M.profileAllowsBlockedApproach(profile)
    return profile and (profile.allowBlockedApproachTeleport == true or profile.allowBlockedApproachTransition == true)
end

function M.settingAllowsBlockedApproach(ctx)
    local settings = settingsFrom(ctx)
    return settings and settings.allowBlockedApproachTeleport == true
end

function M.nearEnoughForBlockedApproachFallback(npc, data)
    if not npc or not data then return false end

    local maxFinalDistance = data.profile.approachForceTransitionDistance or 240
    local maxObjectDistance = data.profile.approachForceObjectDistance or 260

    if data.finalPosition and (npc.position - data.finalPosition):length() <= maxFinalDistance then
        return true
    end

    if data.object and data.object.position and (npc.position - data.object.position):length() <= maxObjectDistance then
        return true
    end

    return false
end

function M.directlyBesideReservedBed(ctx, npc, data)
    if not (npc and data and data.interactionType == "sleeping" and data.object and data.object.position) then return false, "missing" end
    local reservations = ctx.sleepReservations
    local reservationSlotKey = reservations and reservations.reservedSlotForNpc and reservations.reservedSlotForNpc(npc) or nil
    local reservation = reservationSlotKey and ctx.sleepReservationForCandidate({ slotKey = reservationSlotKey }) or nil
    if reservation and reservation.slotKey ~= data.slotKey then return false, "different_reservation" end
    local objectDistance = (npc.position - data.object.position):length()
    local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or objectDistance
    local approachVertical = data.approachPos and math.abs((npc.position.z or 0) - (data.approachPos.z or 0)) or 0
    local objectVertical = math.abs((npc.position.z or 0) - (data.object.position.z or 0))
    local maxDist = tonumber(data.profile and data.profile.sleepDirectEntryDistance or ctx.directEntryDistance or DEFAULT_DIRECT_BED_ENTRY_DISTANCE) or DEFAULT_DIRECT_BED_ENTRY_DISTANCE
    local maxVertical = tonumber(data.profile and data.profile.sleepDirectEntryVertical or ctx.directEntryVertical or DEFAULT_DIRECT_BED_ENTRY_VERTICAL) or DEFAULT_DIRECT_BED_ENTRY_VERTICAL
    local maxApproach = math.max(maxDist * 1.35, maxDist + 35)
    if data.sleepRouteStatus == "path_reachable" and data.reachedValidSleepApproach ~= true then
        return false, "walkable_route_requires_approach", approachDistance, math.max(approachVertical, objectVertical)
    end
    if data.sleepRouteNeedsDoorAssist == true and data.reachedValidSleepApproach ~= true then
        return false, "door_assist_requires_approach", approachDistance, math.max(approachVertical, objectVertical)
    end
    if objectDistance <= maxDist
        and approachDistance <= maxApproach
        and objectVertical <= maxVertical + 45
        and (approachVertical <= maxVertical or objectVertical <= maxVertical) then
        return true, "directly_beside_bed", math.max(objectDistance, approachDistance), math.max(approachVertical, objectVertical)
    end
    if objectDistance <= maxDist and approachDistance > maxApproach then
        return false, "beside_bed_wrong_entry_side", approachDistance, math.max(approachVertical, objectVertical)
    end
    return false, "not_directly_beside_bed", objectDistance, math.max(approachVertical, objectVertical)
end

function M.evaluate(ctx, npc, data, reason)
    if not (npc and data and data.interactionType == "sleeping") then return true, "not_sleep" end
    if data.initialPlacement == true then return true, "initial_placement" end

    local settings = settingsFrom(ctx)
    local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or math.huge
    local vertical = data.approachPos and math.abs((npc.position.z or 0) - (data.approachPos.z or 0)) or math.huge
    local transitionDistance = data.profile and (data.profile.transitionDistance or settings.transitionDistance) or settings.transitionDistance or 100
    local fallbackReason = reason == "blocked_approach_fallback"
        or reason == "approach_hard_timeout_fallback"
        or reason == "manual_assign_no_progress_fallback"
        or reason == "manual_assign_hard_timeout_fallback"

    if fallbackReason and data.manualSleepEntryOverride == true then
        return true, "manual_sleep_entry_override", approachDistance, vertical
    end

    if reason == "reached_approach" or data.reachedValidSleepApproach == true then
        return true, "reached_valid_sleep_approach", approachDistance, vertical
    end

    if fallbackReason then
        local nearApproach = approachDistance <= math.max(transitionDistance * 1.35, transitionDistance + 24)
        if nearApproach and vertical <= 60 then
            return true, "bed_edge_blocked_approach", approachDistance, vertical
        end
        local besideBed, besideReason, bedDistance, bedVertical = M.directlyBesideReservedBed(ctx, npc, data)
        if besideBed then
            return true, besideReason, bedDistance or approachDistance, bedVertical or vertical
        end
        if vertical > 90 then
            return false, "wrong_floor_or_unreachable", approachDistance, vertical
        end
        return false, besideReason == "not_directly_beside_bed" and "blocked_by_wall" or "no_path_to_bed", approachDistance, vertical
    end

    return false, "no_path_to_bed", approachDistance, vertical
end

function M.snapRouteIncomplete(ctx, npc, data, reason)
    if not (npc and data and data.interactionType == "sleeping" and data.profile and data.finalPosition) then
        return false, nil, nil
    end
    if data.initialPlacement == true or data.manualSleepEntryOverride == true or reason == "reached_approach" then
        return false, nil, nil
    end

    local settings = settingsFrom(ctx)
    local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or 0
    local objectDistance = data.object and (npc.position - data.object.position):length() or 0
    local maxApproach = (data.profile.transitionDistance or settings.transitionDistance or 100) * 2.25
    local maxObject = data.profile.approachForceObjectDistance or 320
    return approachDistance > maxApproach and objectDistance > maxObject, approachDistance, objectDistance
end

function M.blockedFallbackAllowed(ctx, profile)
    return M.settingAllowsBlockedApproach(ctx) or M.profileAllowsBlockedApproach(profile)
end

function M.directBedEntryAllowed(ctx, npc, data)
    return M.directlyBesideReservedBed(ctx, npc, data) == true
end

return M
