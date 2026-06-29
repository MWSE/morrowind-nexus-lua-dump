-- interactions/lectures/audience.lua
---@omw-context none
-- Lecture-specific audience gather/release rules for lectern interactions.

local audience = require('scripts/sitDownPlease/interactions/audience')
local lectureEligibility = require('scripts/sitDownPlease/interactions/lectures/eligibility')
local lectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')

local M = {}
local loggedInteriorApproximationBySlot = {}
local NORMAL_AUDIENCE_LIMIT = 8
local SHORTCUT_AUDIENCE_LIMIT = 32
local NORMAL_IDLE_TARGET_AFTER_SEATED = 4
local INTERIOR_IDLE_AUDIENCE_RADIUS = 900

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function valid(ctx, obj)
    if ctx and ctx.isObjValid then return ctx.isObjValid(obj) == true end
    return obj ~= nil and obj.position ~= nil
end

local function actorLabel(npc)
    return npc and (npc.recordId or npc.id) or "<npc>"
end

local function distanceToStation(npc, stationData)
    if npc and npc.position and stationData and stationData.object and stationData.object.position then
        return (npc.position - stationData.object.position):length()
    end
    return math.huge
end

local function isSameCell(npc, stationData)
    return npc and npc.cell and stationData and stationData.object and stationData.object.cell and npc.cell == stationData.object.cell
end

local function followerBlock(ctx, npc)
    if ctx and ctx.followerBlockReason then return ctx.followerBlockReason(npc) end
    return nil
end

local function actorDead(ctx, npc)
    if ctx and ctx.actorDeadReason then return ctx.actorDeadReason(npc) end
    return false, nil
end

local function eligibleForSitting(ctx, npc)
    return lectureEligibility.eligibleAudienceMember(npc, ctx)
end

local function shouldConsiderStation(stationData, ctx, force)
    if not (stationData and valid(ctx, stationData.object) and stationData.position) then return false end
    if force == true then return true end
    local assignments = ctx and ctx.stationAssignments or nil
    if assignments and assignments.shouldRebalanceAudience then
        return assignments.shouldRebalanceAudience(stationData.slotKey, ctx.now and ctx.now() or 0) == true
    end
    return true
end

local function noteInteriorApproximation(stationData, ctx, interior)
    if interior ~= true then return end
    local key = tostring(stationData.slotKey or stationData.objectId or "station")
    if loggedInteriorApproximationBySlot[key] then return end
    loggedInteriorApproximationBySlot[key] = true
    debugLog(ctx, "lecture audience interior path visibility approximation", "station", tostring(stationData.objectId), "reason", "global gather cannot prove full path los")
end

local function audienceOriginFromAssignment(npc, data)
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

local function queueAudienceMember(ctx, stationData, npc, source, fromExistingSeat, index, interior, existingData)
    if not (ctx and ctx.pendingSittingReassignments and npc and npc.id) then return false end
    local originPosition, originRotation, originSource = audienceOriginFromAssignment(npc, existingData)
    local delay = audience.joinDelay(ctx, npc, stationData.slotKey, {
        initialPlacement = stationData.initialPlacement == true,
        fromExistingSeat = fromExistingSeat == true,
        index = index,
    })
    if ctx.lectureAudienceTeleport == true then
        delay = math.min(delay, 0.15 + math.max(0, (tonumber(index) or 1) - 1) * 0.18)
    elseif ctx.lectureAudienceShortcut == true then
        delay = math.min(delay, 0.4 + math.max(0, (tonumber(index) or 1) - 1) * 1.5)
    end
    if fromExistingSeat == true and ctx.lectureAudienceTeleport ~= true then
        -- Give the existing sitting release/stand-exit handoff time to complete
        -- before sending the actor back into audience seating. Without this,
        -- wrong-facing bench sitters can appear to snap directly from sitting to
        -- standing and immediately back into a new audience target.
        delay = math.max(delay, ctx.lectureAudienceShortcut == true and 0.8 or 2.0)
    end
    ctx.pendingSittingReassignments[npc.id] = {
        npc = npc,
        due = (ctx.now and ctx.now() or 0) + delay,
        source = source,
        lectureAudienceOriginPosition = originPosition,
        lectureAudienceOriginRotation = originRotation,
        lectureAudienceOriginSource = originSource,
        preferLecternAudience = true,
        lecternObject = stationData.object,
        lecternPosition = stationData.object and stationData.object.position or nil,
        stationPosition = stationData.position,
        stationFacingDirection = stationData.facingDirection,
        audienceHeadFocusPosition = stationData.position or (stationData.object and stationData.object.position) or nil,
        lectureSessionId = stationData.lectureSessionId,
        stationSlotKey = stationData.slotKey,
        interiorLecternAudience = interior == true,
        audienceSource = source,
        lectureAudienceShortcut = ctx.lectureAudienceShortcut == true,
        lectureAudienceTeleport = ctx.lectureAudienceTeleport == true,
    }
    debugLog(
        ctx,
        source .. " queued",
        actorLabel(npc),
        "station", tostring(stationData.objectId),
        "delay", tostring(delay),
        "originSource", tostring(originSource),
        "interiorDistanceLimit", tostring(interior and "path_or_focus" or "radius")
    )
    return true
end


local function actorForwardDotToStation(npc, stationData)
    if not (npc and npc.position and npc.rotation and stationData and stationData.position) then return nil end
    local dx = (stationData.position.x or 0) - (npc.position.x or 0)
    local dy = (stationData.position.y or 0) - (npc.position.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    local ok, yaw = pcall(function() return npc.rotation:getYaw() end)
    if not (ok and type(yaw) == "number") then return nil end
    local fx = math.sin(yaw)
    local fy = math.cos(yaw)
    return fx * (dx / len) + fy * (dy / len)
end

local function seatedActorCanTransitionInPlace(npc, data, stationData)
    if data and data.facingKind == "lectern" then return true, "already_lectern_facing" end
    local dot = actorForwardDotToStation(npc, stationData)
    if dot and dot >= 0.28 then return true, "actor_facing_station" end
    return false, "seat_not_facing_station"
end

local function collectSeatedAudience(ctx, stationData, interior)
    local result = {}
    for npcId, data in pairs(ctx.assignedActors or {}) do
        local npc = data and data.npc or nil
        local nearEnough = interior == true
            or (data and data.object and stationData.object and data.object.position and stationData.object.position and (data.object.position - stationData.object.position):length() <= 2200)
        local alreadyLectureAudience = data and data.facingKind == "lectern" and data.lectureAudienceTarget == true
        local allowActiveLectureAudience = alreadyLectureAudience
            and (ctx.lectureAudienceShortcut == true or ctx.lectureAudienceTeleport == true)
        if data and data.interactionType == "sitting"
            and valid(ctx, npc)
            and npc ~= stationData.npc
            and isSameCell(npc, stationData)
            and nearEnough
            and (not alreadyLectureAudience or allowActiveLectureAudience)
            and not followerBlock(ctx, npc) then
            local okChance = ctx.lectureAudienceShortcut == true
                or ctx.lectureAudienceTeleport == true
                or audience.chanceAllows(ctx, npc, stationData.slotKey, "stationLecternAudienceChance", "lecture_audience")
            if okChance then
                result[#result + 1] = { npcId = npcId, npc = npc, data = data, distance = distanceToStation(npc, stationData) }
            end
        end
    end
    table.sort(result, function(a, b) return (a.distance or math.huge) < (b.distance or math.huge) end)
    return result
end

local function collectIdleAudience(ctx, stationData, maxResults, interior)
    local result = {}
    local skipped = {
        scanned = 0,
        assigned = 0,
        follower = 0,
        dead = 0,
        ineligible = 0,
        chance = 0,
        distance = 0,
    }
    result.skipped = skipped
    local cell = stationData and stationData.object and stationData.object.cell or nil
    if not (cell and cell.getAll and ctx and ctx.types and ctx.types.NPC) then return result end
    local okNpcs, npcs = pcall(function() return cell:getAll(ctx.types.NPC) end)
    if not (okNpcs and npcs) then return result end
    local limit = tonumber(maxResults) or math.huge
    for _, npc in ipairs(npcs) do
        if #result >= limit then
            skipped.capped = true
            break
        end
        if npc and npc.id and npc ~= stationData.npc and valid(ctx, npc) then
            skipped.scanned = skipped.scanned + 1
            if (ctx.assignedActors and ctx.assignedActors[npc.id])
                or (ctx.pendingSittingReassignments and ctx.pendingSittingReassignments[npc.id]) then
                skipped.assigned = skipped.assigned + 1
            else
            local distance = distanceToStation(npc, stationData)
            local tooFarInterior = interior == true
                and ctx.lectureAudienceShortcut ~= true
                and ctx.lectureAudienceTeleport ~= true
                and distance > INTERIOR_IDLE_AUDIENCE_RADIUS
            local followerReason = followerBlock(ctx, npc)
            local dead, deadReason = actorDead(ctx, npc)
            local eligible, reason = eligibleForSitting(ctx, npc)
            local okChance = ctx.lectureAudienceShortcut == true
                or ctx.lectureAudienceTeleport == true
                or audience.chanceAllows(ctx, npc, stationData.slotKey, "stationLecternAudienceChance", "lecture_audience")
            if tooFarInterior then
                skipped.distance = skipped.distance + 1
                debugLog(ctx, "lecture audience gather skipped", actorLabel(npc), "reason", "interior_idle_distance_limit", "distance", tostring(distance), "limit", tostring(INTERIOR_IDLE_AUDIENCE_RADIUS))
            elseif followerReason then
                skipped.follower = skipped.follower + 1
                debugLog(ctx, "lecture audience gather skipped", actorLabel(npc), "reason", tostring(followerReason))
            elseif dead then
                skipped.dead = skipped.dead + 1
                debugLog(ctx, "lecture audience gather skipped", actorLabel(npc), "reason", tostring(deadReason or "dead_actor"))
            elseif eligible ~= true then
                skipped.ineligible = skipped.ineligible + 1
                debugLog(ctx, "lecture audience gather skipped", actorLabel(npc), "reason", tostring(reason or "not_sitting_eligible"))
            elseif okChance then
                result[#result + 1] = { npc = npc, distance = distance }
            else
                skipped.chance = skipped.chance + 1
            end
            end
        end
    end
    table.sort(result, function(a, b) return (a.distance or math.huge) < (b.distance or math.huge) end)
    return result
end

function M.queueForStations(stations, ctx, options)
    options = options or {}
    if not stations or #stations == 0 then return 0 end
    if ctx then
        ctx.lectureAudienceShortcut = options.debugShortcut == true
        ctx.lectureAudienceTeleport = options.teleportAudience == true
    end
    lectureTrace.ctx(
        ctx,
        "audience_gather_requested",
        "stations", tostring(#stations),
        "force", tostring(options.force == true),
        "debugShortcut", tostring(options.debugShortcut == true),
        "teleport", tostring(options.teleportAudience == true),
        "source", tostring(options.source)
    )
    local queued = 0
    for _, stationData in ipairs(stations) do
        if shouldConsiderStation(stationData, ctx, options.force == true) then
            local stationQueued = 0
            local stationLimit = options.teleportAudience == true and SHORTCUT_AUDIENCE_LIMIT or NORMAL_AUDIENCE_LIMIT
            local interior = ctx and ctx.cellIsInterior and ctx.cellIsInterior(stationData.object and stationData.object.cell) == true
            noteInteriorApproximation(stationData, ctx, interior)
            local seated = collectSeatedAudience(ctx, stationData, interior)
            for index, item in ipairs(seated) do
                if stationQueued >= stationLimit then break end
                if valid(ctx, item.npc) and ctx.assignedActors and ctx.assignedActors[item.npcId] == item.data then
                    local transitioned = false
                    local transitionReason = "transition_unavailable"
                    local alreadyLectureFacing = item.data and item.data.facingKind == "lectern"
                    local alreadyLectureAudience = alreadyLectureFacing == true and item.data.lectureAudienceTarget == true
                    local canTransitionInPlace, transitionBasis = seatedActorCanTransitionInPlace(item.npc, item.data, stationData)
                    if canTransitionInPlace and ctx.transitionSeatedAudienceMember then
                        transitioned, transitionReason = ctx.transitionSeatedAudienceMember(item.npc, item.data, stationData, {
                            source = "lecture_audience_rebalance",
                            debugShortcut = options.debugShortcut == true,
                            teleportAudience = options.teleportAudience == true,
                            index = stationQueued + 1,
                            transitionBasis = transitionBasis,
                        })
                    end
                    if transitioned then
                        queued = queued + 1
                        stationQueued = stationQueued + 1
                    elseif not alreadyLectureAudience and ctx.stopInteractionForNpc
                        and queueAudienceMember(ctx, stationData, item.npc, "lecture_audience_reseat", true, stationQueued + 1, interior, item.data) then
                        ctx.stopInteractionForNpc(item.npc, "lecture_audience_reseat")
                        queued = queued + 1
                        stationQueued = stationQueued + 1
                        lectureTrace.ctx(
                            ctx,
                            "audience_reseat_requested",
                            "actor", actorLabel(item.npc),
                            "station", tostring(stationData.objectId),
                            "seat", tostring(item.data and item.data.objectId),
                            "slot", tostring(item.data and item.data.slotName),
                            "reason", tostring(transitionReason or "existing_seat_not_lectern_audience")
                        )
                    else
                        lectureTrace.ctx(
                            ctx,
                            "audience_transition_skipped",
                            "actor", actorLabel(item.npc),
                            "station", tostring(stationData.objectId),
                            "slot", tostring(item.data and item.data.slotName),
                            "reason", tostring(transitionReason)
                        )
                    end
                end
            end
            local idleSlots = math.max(0, stationLimit - stationQueued)
            if options.teleportAudience ~= true and options.debugShortcut ~= true then
                idleSlots = math.min(idleSlots, math.max(0, NORMAL_IDLE_TARGET_AFTER_SEATED - stationQueued))
            end
            local idle = idleSlots > 0 and collectIdleAudience(ctx, stationData, idleSlots, interior) or { skipped = { scanned = 0 } }
            local skipped = idle.skipped or {}
            lectureTrace.ctx(
                ctx,
                "audience_candidates_scanned",
                "station", tostring(stationData and stationData.objectId),
                "slot", tostring(stationData and stationData.slotName),
                "seatedCandidates", tostring(#seated),
                "idleCandidates", tostring(#idle),
                "idleScanned", tostring(skipped.scanned or 0),
                "skipAssigned", tostring(skipped.assigned or 0),
                "skipFollower", tostring(skipped.follower or 0),
                "skipDead", tostring(skipped.dead or 0),
                "skipIneligible", tostring(skipped.ineligible or 0),
                "skipDistance", tostring(skipped.distance or 0),
                "skipChance", tostring(skipped.chance or 0),
                "capped", tostring(skipped.capped == true)
            )
            for _, item in ipairs(idle) do
                if stationQueued >= stationLimit then break end
                if queueAudienceMember(ctx, stationData, item.npc, "lecture_audience_gather", false, stationQueued + 1, interior) then
                    queued = queued + 1
                    stationQueued = stationQueued + 1
                end
            end
            if stationQueued == 0 and ctx and ctx.infoLog then
                local reason = (#seated == 0 and #idle == 0) and "no_eligible_audience_actor" or "no_audience_member_queued"
                lectureTrace.ctx(
                    ctx,
                    "audience_assignments_queued",
                    "station", tostring(stationData and stationData.objectId),
                    "slot", tostring(stationData and stationData.slotName),
                    "queued", "0",
                    "reason", tostring(reason),
                    "debugShortcut", tostring(options.debugShortcut == true),
                    "teleport", tostring(options.teleportAudience == true)
                )
                ctx.infoLog(
                    "lecture audience gather skipped",
                    "station", tostring(stationData and stationData.objectId),
                    "slot", tostring(stationData and stationData.slotName),
                    "reason", reason,
                    "seatedCandidates", tostring(#seated),
                    "idleCandidates", tostring(#idle),
                    "idleScanned", tostring(skipped.scanned or 0),
                    "skipAssigned", tostring(skipped.assigned or 0),
                    "skipFollower", tostring(skipped.follower or 0),
                    "skipDead", tostring(skipped.dead or 0),
                    "skipIneligible", tostring(skipped.ineligible or 0),
                    "skipChance", tostring(skipped.chance or 0),
                    "shortcut", tostring(options.debugShortcut == true),
                    "teleport", tostring(options.teleportAudience == true)
                )
            elseif stationQueued > 0 and ctx and ctx.infoLog then
                lectureTrace.ctx(
                    ctx,
                    "audience_assignments_queued",
                    "station", tostring(stationData and stationData.objectId),
                    "slot", tostring(stationData and stationData.slotName),
                    "queued", tostring(stationQueued),
                    "limit", tostring(stationLimit),
                    "debugShortcut", tostring(options.debugShortcut == true),
                    "teleport", tostring(options.teleportAudience == true)
                )
                ctx.infoLog(
                    "lecture audience gather queued",
                    "station", tostring(stationData and stationData.objectId),
                    "slot", tostring(stationData and stationData.slotName),
                    "queued", tostring(stationQueued),
                    "limit", tostring(stationLimit),
                    "idleScanned", tostring(skipped.scanned or 0),
                    "skipFollower", tostring(skipped.follower or 0),
                    "skipIneligible", tostring(skipped.ineligible or 0),
                    "skipChance", tostring(skipped.chance or 0),
                    "shortcut", tostring(options.debugShortcut == true),
                    "teleport", tostring(options.teleportAudience == true)
                )
            end
        else
            lectureTrace.ctx(
                ctx,
                "audience_gather_skipped",
                "station", tostring(stationData and stationData.objectId),
                "slot", tostring(stationData and stationData.slotName),
                "reason", "rebalance_debounced"
            )
            debugLog(ctx, "lecture audience gather skipped", "station", tostring(stationData and stationData.objectId), "reason", "rebalance_debounced")
        end
    end
    return queued
end

function M.releaseDelay(ctx, npc, slotKey, index)
    return audience.releaseDelay(ctx, npc, slotKey, index)
end

return M
