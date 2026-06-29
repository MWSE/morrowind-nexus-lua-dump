-- interactions/lectures/audienceTransition.lua
---@omw-context none
-- Small data-shaping helper for converting an already seated actor into a
-- lecture audience member without tearing down the sitting assignment first.

local M = {}

local function label(npc)
    return npc and (npc.recordId or npc.id) or "<npc>"
end

local function captureOrigin(npc, data)
    if data and data.lectureAudienceOriginPosition then
        return data.lectureAudienceOriginPosition, data.lectureAudienceOriginRotation, data.lectureAudienceOriginSource or "existing_audience_origin"
    end
    if data and data.preInteractionPos then
        return data.preInteractionPos, data.preInteractionRot, "pre_interaction_origin"
    end
    if data and data.npcStandingPos then
        return data.npcStandingPos, data.npcStandingRot, "standing_exit_origin"
    end
    return npc and npc.position or nil, npc and npc.rotation or nil, "current_actor_position"
end

local function audienceDetails(data)
    return {
        originPosition = data and data.lectureAudienceOriginPosition or nil,
        originRotation = data and data.lectureAudienceOriginRotation or nil,
        returnMode = data and data.lectureAudienceReturnMode or nil,
        wasAlreadySitting = data and data.lectureAudienceWasAlreadySitting == true,
        originalAnimation = data and (data.lectureAudienceOriginalAnimation or data.animationName or (data.profile and data.profile.animation)) or nil,
    }
end

function M.apply(data, stationData, options)
    options = options or {}
    if not data then return false, "missing_assignment" end
    if data.interactionType ~= "sitting" then return false, "not_sitting" end
    if not (stationData and stationData.slotKey) then return false, "missing_station" end

    local originPosition, originRotation, originSource = captureOrigin(data.npc, data)
    data.lectureAudienceOriginPosition = originPosition
    data.lectureAudienceOriginRotation = originRotation
    data.lectureAudienceOriginSource = originSource
    data.lectureAudienceTarget = true
    data.lectureAudienceShortcut = options.debugShortcut == true
    data.lectureAudienceTeleport = false
    data.lectureAudienceTransitionedInPlace = true
    data.lectureAudienceWasAlreadySitting = true
    data.lectureAudienceReturnMode = "normal_sitting"
    data.lectureAudienceOriginalAnimation = data.lectureAudienceOriginalAnimation
        or data.animationName
        or (data.profile and data.profile.animation)
    data.lecternPosition = stationData.object and stationData.object.position or data.lecternPosition
    data.stationPosition = stationData.position or data.stationPosition
    data.audienceHeadFocusPosition = stationData.position or data.lecternPosition or data.audienceHeadFocusPosition
    data.lectureSessionId = stationData.lectureSessionId or data.lectureSessionId
    data.stationSlotKey = stationData.slotKey
    data.audienceSource = options.source or data.audienceSource or "lecture_audience_transition"
    return true, "transitioned"
end

function M.clear(data)
    if not data then return end
    data.lectureAudienceTarget = false
    data.lectureAudienceShortcut = false
    data.lectureAudienceTeleport = false
    data.lectureAudienceTransitionedInPlace = nil
    data.lectureAudienceWasAlreadySitting = nil
    data.lectureAudienceReturnMode = nil
    data.lectureAudienceOriginalAnimation = nil
    data.lectureAudienceOriginPosition = nil
    data.lectureAudienceOriginRotation = nil
    data.lectureAudienceOriginSource = nil
    data.lectureSessionId = nil
    data.stationSlotKey = nil
    data.audienceSource = nil
    data.audienceHeadFocusPosition = nil
end

function M.transitionSeated(npc, data, stationData, ctx, options)
    options = options or {}
    if not (npc and npc.id and data and stationData) then return false, "missing_actor_or_station" end
    if ctx and ctx.assignedActors and ctx.assignedActors[npc.id] ~= data then return false, "assignment_changed" end
    if data.interactionType ~= "sitting" then return false, "not_sitting" end
    if ctx and ctx.interactingState and ctx.transitioningState then
        if data.state ~= ctx.interactingState and data.state ~= ctx.transitioningState then
            return false, "not_currently_seated"
        end
    end
    if ctx and ctx.slotClaimedByOther and ctx.slotClaimedByOther(data.slotKey, npc) then
        return false, "seat_claimed_by_other"
    end
    local ok, reason = M.apply(data, stationData, {
        source = options.source or "lecture_audience_rebalance",
        debugShortcut = options.debugShortcut == true,
    })
    if not ok then return false, reason end
    if ctx and ctx.claimOccupiedSlot and data.slotKey then
        local claimOk, claimReason = ctx.claimOccupiedSlot(data.slotKey, npc)
        if not claimOk then
            M.clear(data)
            return false, claimReason or "seat_claim_failed"
        end
    end
    if ctx and ctx.scheduleLifecycle then ctx.scheduleLifecycle(data, "lecture_audience_transition") end
    if ctx and ctx.noteAudienceMember then ctx.noteAudienceMember(data.stationSlotKey, npc, audienceDetails(data)) end
    if ctx and ctx.trace then
        ctx.trace(
            "audience_origin_captured",
            "actor", tostring(label(npc)),
            "station", tostring(stationData.objectId),
            "seat", tostring(data.objectId),
            "slot", tostring(data.slotName),
            "source", tostring(data.lectureAudienceOriginSource),
            "origin", tostring(data.lectureAudienceOriginPosition)
        )
        ctx.trace(
            "audience_transition_in_place",
            "actor", tostring(label(npc)),
            "station", tostring(stationData.objectId),
            "seat", tostring(data.objectId),
            "slot", tostring(data.slotName),
            "source", tostring(options.source),
            "shortcut", tostring(options.debugShortcut == true)
        )
    end
    if ctx and ctx.sendTransitionEvent then
        ctx.sendTransitionEvent(npc, {
            reason = options.source or "lecture_audience_rebalance",
            lectureSessionId = data.lectureSessionId,
            stationSlotKey = data.stationSlotKey,
            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
            animation = data.lectureAudienceOriginalAnimation or data.animationName or (data.profile and data.profile.animation),
            forceReplay = options.debugShortcut == true,
        })
    end
    return true, "transitioned"
end

return M
