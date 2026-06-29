-- assignment/candidateSelector.lua
---@omw-context none
-- Chooses the best already-built interaction candidate for an NPC.

local M = {}

local function settingsFrom(ctx)
    if type(ctx.settings) == "function" then return ctx.settings() end
    return ctx.settings or {}
end

local function sleepBedtimePressure(context)
    if not context then return false end
    if context.initialPlacement == true or context.phase == "force_in_bed" then return true end

    local nowDelta = tonumber(context.nowDelta)
    local actorBedtimeDelta = tonumber(context.actorBedtimeDelta)
    return nowDelta ~= nil and actorBedtimeDelta ~= nil and nowDelta >= actorBedtimeDelta
end

local function occupiedSlots(ctx)
    if type(ctx.occupiedSlots) == "function" then return ctx.occupiedSlots() end
    return ctx.occupiedSlots
end

local function assignedActors(ctx)
    if type(ctx.assignedActors) == "function" then return ctx.assignedActors() end
    return ctx.assignedActors
end

local function lockedRouteDoorAccess(ctx, npc, candidate)
    local routeAssist = ctx and ctx.routeAssist
    local cell = npc and npc.cell
    local target = candidate and (candidate.position or (candidate.object and candidate.object.position))
    if not (routeAssist and cell and cell.getAll and npc and npc.position and target and ctx.types and ctx.types.Door) then
        return nil
    end

    local okList, doors = pcall(function() return cell:getAll(ctx.types.Door) end)
    if not (okList and doors) then return nil end

    local best
    local bestDistance
    for _, door in ipairs(doors) do
        if door and door.position
            and routeAssist.isNonTeleportDoor(door)
            and routeAssist.isDoorLocked(door)
            and routeAssist.doorOnRouteSegment(door, npc.position, target, {
                maxVertical = 180,
                maxLineDistance = 190,
                maxActorDistance = 1200,
                maxTargetDistance = 1200,
            })
        then
            local distance = (door.position - npc.position):length()
            if not bestDistance or distance < bestDistance then
                best = door
                bestDistance = distance
            end
        end
    end

    if not best then return nil end
    local hasKey, keyId, keyReason = routeAssist.actorHasDoorKey(npc, best)
    if hasKey == true then
        return "keyed_locked_route_door", best, keyId
    end
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        return "locked_route_door_unknown_key", best, keyId
    end
    return "locked_route_door_missing_key", best, keyId
end

local availableSleepSlotsForObject

local function ignoreStandingSleepSlotBlock(candidate, candidates, context)
    return context
        and context.initialPlacement == true
        and candidate
        and candidate.object
        and availableSleepSlotsForObject(candidates, candidate.object) > 1
end

local function nearbyUnassignedNpcAtSleepSlot(ctx, npc, candidate, candidates, context)
    if not (ctx and npc and npc.cell and npc.cell.getAll and candidate and candidate.position and ctx.types and ctx.types.NPC) then
        return false, nil, nil
    end
    if ignoreStandingSleepSlotBlock(candidate, candidates, context) then
        return false, nil, nil
    end
    local okList, npcs = pcall(function() return npc.cell:getAll(ctx.types.NPC) end)
    if not (okList and npcs) then return false, nil, nil end
    local assignments = assignedActors(ctx)
    for _, other in ipairs(npcs) do
        local validForAssignment = ctx.isNpcObjectValidForAssignment
        local validOther = type(validForAssignment) ~= "function" or validForAssignment(other) == true
        if validOther and other and other.id and other.position and other.id ~= npc.id then
            local active = assignments and assignments[other.id] or nil
            if not (active and active.interactionType == "sleeping") then
                local rejectedForOther = type(ctx.sleepRouteRejectCooldownActive) == "function"
                    and ctx.sleepRouteRejectCooldownActive(other, candidate.slotKey) == true
                if not rejectedForOther then
                    local delta = other.position - candidate.position
                    local flat = math.sqrt(((delta.x or 0) * (delta.x or 0)) + ((delta.y or 0) * (delta.y or 0)))
                    local vertical = math.abs(delta.z or 0)
                    if flat <= 115 and vertical <= 120 then
                        return true, other, flat
                    end
                end
            end
        end
    end
    return false, nil, nil
end

local NEARBY_SLEEP_CLAIM_RADIUS = 420
local NEARBY_SLEEP_CLAIM_VERTICAL = 180

local function horizontalDistance(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end

local function candidateAvailableForNpc(ctx, npc, candidate)
    if not (ctx and npc and candidate and candidate.slotKey) then return false end
    if candidate.hardBlockerReason then return false end
    if ctx.slotOwnership
        and ctx.slotOwnership.claimedByOther
        and ctx.slotOwnership.claimedByOther(candidate.slotKey, npc, occupiedSlots(ctx), assignedActors(ctx))
    then
        return false
    end
    if ctx.sleepCandidateReservedByOther then
        local reserved = ctx.sleepCandidateReservedByOther(npc, candidate)
        if reserved then return false end
    end
    if ctx.sleepRouteRejectCooldownActive and ctx.sleepRouteRejectCooldownActive(npc, candidate.slotKey) then
        return false
    end
    return true
end

local function candidateIsNearestSleepSlotForNpc(ctx, npc, candidate, candidates)
    if not (npc and npc.position and candidate and candidate.object and candidate.slotKey) then return false end
    local candidateDist = horizontalDistance(npc.position, candidate.position or candidate.object.position)
    local bestDist = candidateDist
    local bestKey = tostring(candidate.slotKey)

    for _, otherCandidate in ipairs(candidates or {}) do
        if otherCandidate
            and otherCandidate.slotKey
            and otherCandidate.interactionType == "sleeping"
            and candidateAvailableForNpc(ctx, npc, otherCandidate)
        then
            local dist = horizontalDistance(npc.position, otherCandidate.position or otherCandidate.object.position)
            local key = tostring(otherCandidate.slotKey)
            if dist < bestDist - 8 or (math.abs(dist - bestDist) <= 8 and key < bestKey) then
                bestDist = dist
                bestKey = key
            end
        end
    end

    return tostring(candidate.slotKey) == bestKey, candidateDist
end

availableSleepSlotsForObject = function(candidates, object)
    if not object then return 0 end
    local count = 0
    for _, item in ipairs(candidates or {}) do
        if item and item.object == object then count = count + 1 end
    end
    return count
end

local function nearbyNpcShouldKeepSleepSlot(ctx, npc, candidate, candidates)
    if not (ctx and npc and npc.cell and npc.cell.getAll and candidate and candidate.object and candidate.object.position and ctx.types and ctx.types.NPC) then
        return false, nil, nil
    end
    local okList, npcs = pcall(function() return npc.cell:getAll(ctx.types.NPC) end)
    if not (okList and npcs) then return false, nil, nil end

    local assignments = assignedActors(ctx)
    for _, other in ipairs(npcs) do
        local validForAssignment = ctx.isNpcObjectValidForAssignment
        local validOther = type(validForAssignment) ~= "function" or validForAssignment(other) == true
        if validOther and other and other.id and other.position and other.id ~= npc.id then
            local active = assignments and assignments[other.id] or nil
            if not (active and active.interactionType == "sleeping") then
                local rejectedForOther = type(ctx.sleepRouteRejectCooldownActive) == "function"
                    and ctx.sleepRouteRejectCooldownActive(other, candidate.slotKey) == true
                if not rejectedForOther then
                    local slotPos = candidate.position or candidate.object.position
                    local flat = horizontalDistance(other.position, slotPos)
                    local vertical = math.abs((other.position.z or 0) - (slotPos.z or 0))
                    local nearestForOther = candidateIsNearestSleepSlotForNpc(ctx, other, candidate, candidates)
                    if flat <= NEARBY_SLEEP_CLAIM_RADIUS
                        and vertical <= NEARBY_SLEEP_CLAIM_VERTICAL
                        and nearestForOther
                    then
                        return true, other, flat
                    end
                end
            end
        end
    end
    return false, nil, nil
end

local function claimRejectCache(ctx)
    if type(ctx.claimRejectLogCache) == "function" then return ctx.claimRejectLogCache() end
    return ctx.claimRejectLogCache
end

function M.flatForwardDot(fromPos, toPos, facing)
    if not (fromPos and toPos and facing) then return nil end
    local dx = (toPos.x or 0) - (fromPos.x or 0)
    local dy = (toPos.y or 0) - (fromPos.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    local fx = tonumber(facing.x) or 0
    local fy = tonumber(facing.y) or 0
    local flen = math.sqrt(fx * fx + fy * fy)
    if flen <= 0.001 then return nil end
    return (fx / flen) * (dx / len) + (fy / flen) * (dy / len)
end

function M.lecternAudienceBehindPresenter(candidate, context)
    if not (context and context.preferLecternAudience == true and candidate) then return false, nil end
    local stationPos = context.stationPosition or context.lecternPosition
    local candidatePos = candidate.position or (candidate.object and candidate.object.position)
    local dot = M.flatForwardDot(stationPos, candidatePos, context.stationFacingDirection)
    if dot ~= nil and dot < -0.18 then
        return true, dot
    end
    return false, dot
end

function M.searchRadius(ctx, interactionType, candidate, context)
    local settings = settingsFrom(ctx)
    local profiles = ctx.profiles
    if context and context.debugForce == true then
        return settings.sleepInitialPlacementSearchRadius or settings.sleepSearchRadius or settings.maxSearchRadius or 5000
    end

    if interactionType == "sleeping" then
        local radius
        local bedtimePressure = sleepBedtimePressure(context)
        if bedtimePressure then
            radius = settings.sleepInitialPlacementSearchRadius or 5000
        elseif candidate and candidate.profile and candidate.profile.sleepSearchRadius then
            radius = candidate.profile.sleepSearchRadius
        else
            radius = settings.sleepSearchRadius or settings.maxSearchRadius or 700
        end

        local serviceRec = context and context.npc and ctx.servicePolicy.record(context.npc, ctx.types) or nil
        if not bedtimePressure and ctx.servicePolicy.hasTravelService(serviceRec) then
            radius = math.min(radius, 650)
        elseif not bedtimePressure and ctx.servicePolicy.offHoursServiceRecordReason(
            serviceRec,
            settings,
            profiles,
            profiles.getGameHour(),
            ctx.actorRoles.isFactionLeader(context.npc, ctx.types, ctx.core)
        ) then
            radius = math.min(radius, settings.serviceNpcOffHoursSleepRadius or radius)
        end

        local originPreferredDist = context and context.npc and candidate and ctx.sleepOriginPreferredDistance(context.npc, candidate) or nil
        local bedAccessBlockReason = context and context.npc and candidate and ctx.sleepBedAccess.normalAssignmentBlockReason({
            cell = context.npc.cell,
            candidate = candidate,
            originPreferred = originPreferredDist ~= nil,
            initialPlacement = context.initialPlacement == true,
            debugForce = context.debugForce == true,
            helpers = {
                objectModelPath = profiles.objectModelPath,
                objectName = ctx.objectNameForFocus,
                types = ctx.types,
            },
        }) or nil
        if bedAccessBlockReason then
            if settings.debug then
                ctx.debugLog(
                    "sleep bed access radius blocked",
                    context.npc.recordId or context.npc.id,
                    "object", tostring(candidate.objectId),
                    "slot", tostring(candidate.slotName),
                    "reason", tostring(bedAccessBlockReason)
                )
            end
            radius = 0
        end

        if context and context.npc and candidate and ctx.sleepBedAccess.shouldRestrictDoorAssist(context.npc.cell, originPreferredDist ~= nil, context.debugForce == true) then
            if not bedtimePressure then
                radius = math.min(radius, 260)
            end
        end
        return radius
    end

    if interactionType == "sitting" and context and context.npc then
        local serviceRec = ctx.servicePolicy.record(context.npc, ctx.types)
        if ctx.servicePolicy.offHoursServiceRecordReason(
            serviceRec,
            settings,
            profiles,
            profiles.getGameHour(),
            ctx.actorRoles.isFactionLeader(context.npc, ctx.types, ctx.core)
        ) then
            return math.min(settings.maxSearchRadius or 700, settings.serviceNpcOffHoursSittingRadius or 650)
        end
        if ctx.servicePolicy.offHoursSittingAllowed(
            context.npc,
            serviceRec,
            settings,
            profiles,
            profiles.getGameHour(),
            ctx.actorRoles.isFactionLeader(context.npc, ctx.types, ctx.core)
        ) then
            return math.min(settings.maxSearchRadius or 700, settings.serviceNpcOffHoursSittingRadius or 650)
        end
        if settings.sittingAllowServiceNpcs == true and ctx.servicePolicy.usesNearPostSittingRule(serviceRec) then
            local serviceRadius = math.max(tonumber(settings.sittingServiceNpcRadius or 450) or 450, 450)
            return math.min(settings.maxSearchRadius or 700, serviceRadius, 500)
        end
    end

    return settings.maxSearchRadius or 700
end

function M.choose(ctx, npc, candidates, interactionType, context)
    local settings = settingsFrom(ctx)
    local profiles = ctx.profiles
    context = context or {}
    context.npc = npc
    if not ctx.isNpcObjectValidForAssignment(npc) then return nil end

    local bestIndex = nil
    local bestDist = nil
    local bestRadius = nil
    local nearestCandidate = nil
    local nearestDist = nil
    local nearestRadius = nil
    local preferredIndex = nil
    local preferredDist = nil
    local preferredRadius = nil
    local preferredRouteBlocked = false
    local preferredRouteBlockedObject = nil
    local preferredRouteBlockedDist = nil

    ctx.pruneSleepReservations("choose_candidate")

    for i, candidate in ipairs(candidates) do
        local localSittingRejectActive = candidate
            and (interactionType or candidate.interactionType) == "sitting"
            and ctx.sittingLocalRejectCooldownActive
            and ctx.sittingLocalRejectCooldownActive(npc, candidate.slotKey)
        if candidate and candidate.object
            and not ctx.slotOwnership.claimedByOther(candidate.slotKey, npc, occupiedSlots(ctx), assignedActors(ctx))
            and candidate.slotKey ~= context.avoidSlotKey
            and not localSittingRejectActive then
            local candidateType = interactionType or candidate.interactionType
            local physicallyClaimed, claimReason, claimingNpc = ctx.candidatePhysicallyClaimedByExternalNpc(npc, candidate)
            local stationedBehindCounter = ctx.candidatePullsStationedNpcFromCounter(npc, candidate)
            if physicallyClaimed then
                if settings.debug then
                    local claimKey = tostring(candidateType) .. "|" .. tostring(npc and npc.id) .. "|" .. tostring(candidate.objectId) .. "|" .. tostring(claimingNpc and claimingNpc.id)
                    ctx.debugLogOnce(
                        claimRejectCache(ctx),
                        claimKey,
                        "reject object physically claimed",
                        npc.recordId or npc.id,
                        "type", tostring(candidateType),
                        "object", tostring(candidate.objectId),
                        "by", tostring(claimingNpc and (claimingNpc.recordId or claimingNpc.id)),
                        "reason", tostring(claimReason)
                    )
                end
            elseif stationedBehindCounter then
                if settings.debug then
                    ctx.debugLog(
                        "reject stationed behind counter",
                        npc.recordId or npc.id,
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName),
                        "reason", "station_side_protection"
                    )
                end
            elseif candidateType == "sleeping" and ctx.sleepRouteRejectCooldownActive(npc, candidate.slotKey) then
                local originPreferredDist = ctx.sleepOriginPreferredDistance(npc, candidate)
                if originPreferredDist then
                    preferredRouteBlocked = true
                    preferredRouteBlockedObject = candidate.objectId
                    if not preferredRouteBlockedDist or originPreferredDist < preferredRouteBlockedDist then
                        preferredRouteBlockedDist = originPreferredDist
                    end
                end
                if settings.debug then
                    ctx.debugLog(
                        "reject sleep route cooldown",
                        npc.recordId or npc.id,
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName)
                    )
                end
            else
                local reservedByOther, reservation = false, nil
                if candidateType == "sleeping" then
                    reservedByOther, reservation = ctx.sleepCandidateReservedByOther(npc, candidate)
                end
                local crowdedSleepSlot, claimNpc, claimDist, claimReason = false, nil, nil, nil
                if candidateType == "sleeping" and not reservedByOther then
                    crowdedSleepSlot, claimNpc, claimDist = nearbyUnassignedNpcAtSleepSlot(ctx, npc, candidate, candidates, context)
                    if crowdedSleepSlot then claimReason = "nearby_unassigned_at_slot" end
                    if not crowdedSleepSlot then
                        crowdedSleepSlot, claimNpc, claimDist = nearbyNpcShouldKeepSleepSlot(ctx, npc, candidate, candidates)
                        if crowdedSleepSlot then claimReason = "nearby_actor_nearest_slot" end
                    end
                end
                if reservedByOther then
                    if settings.debug then
                        ctx.debugLog(
                            "reject sleep bed reserved",
                            npc.recordId or npc.id,
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidate.slotName),
                            "owner", ctx.sleepReservationOwnerLabel(reservation)
                        )
                    end
                elseif crowdedSleepSlot then
                    if settings.debug then
                        ctx.debugLog(
                            "sleep slot deferred nearby actor nearest slot",
                            npc.recordId or npc.id,
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidate.slotName),
                            "claimNpc", tostring(claimNpc and (claimNpc.recordId or claimNpc.id)),
                            "claimDistance", tostring(claimDist),
                            "claimReason", tostring(claimReason)
                        )
                    end
                else
                    local originPreferredDist = candidateType == "sleeping" and ctx.sleepOriginPreferredDistance(npc, candidate) or nil
                    local lockedDoorAccess, lockedDoor, lockedDoorKey = nil, nil, nil
                    if candidateType == "sleeping" then
                        lockedDoorAccess, lockedDoor, lockedDoorKey = lockedRouteDoorAccess(ctx, npc, candidate)
                    end
                    local sleepAccessBlockReason = candidateType == "sleeping" and ctx.sleepBedAccess.normalAssignmentBlockReason({
                        cell = npc.cell,
                        candidate = candidate,
                        originPreferred = originPreferredDist ~= nil,
                        initialPlacement = context.initialPlacement == true,
                        debugForce = context.debugForce == true,
                        helpers = {
                            objectModelPath = profiles.objectModelPath,
                            objectName = ctx.objectNameForFocus,
                            types = ctx.types,
                        },
                    }) or nil
                    if lockedDoorAccess == "keyed_locked_route_door" then
                        sleepAccessBlockReason = nil
                    elseif lockedDoorAccess then
                        sleepAccessBlockReason = lockedDoorAccess
                    end
                    local distanceTarget = candidateType == "sleeping" and candidate.position or candidate.object.position
                    local dist = (npc.position - (distanceTarget or candidate.object.position)):length()
                    if lockedDoorAccess == "keyed_locked_route_door" then
                        dist = math.max(0, dist - 900)
                    end
                    if candidateType == "sitting" and context.preferLecternAudience == true then
                        local stationPos = context.lecternPosition or context.stationPosition
                        local stationDist = stationPos and candidate.object and candidate.object.position and (candidate.object.position - stationPos):length() or math.huge
                        local maxStationDist = context.interiorLecternAudience == true and math.huge or 1350
                        local behindPresenter, sideDot = M.lecternAudienceBehindPresenter(candidate, context)
                        if behindPresenter then
                            dist = math.huge
                            if settings.debug then
                                ctx.debugLog(
                                    "reject lectern audience behind presenter",
                                    npc.recordId or npc.id,
                                    "object", tostring(candidate.objectId),
                                    "slot", tostring(candidate.slotName),
                                    "stationDot", tostring(sideDot)
                                )
                            end
                        elseif candidate.facingKind ~= "lectern" or stationDist > maxStationDist then
                            dist = math.huge
                        else
                            dist = math.max(0, stationDist - 180)
                        end
                    end
                    local radius = M.searchRadius(ctx, candidateType, candidate, context)

                    if not nearestDist or dist < nearestDist then
                        nearestCandidate = candidate
                        nearestDist = dist
                        nearestRadius = radius
                    end

                    if sleepAccessBlockReason then
                        if settings.debug then
                            ctx.debugLog(
                                "reject sleep bed access",
                                npc.recordId or npc.id,
                                "object", tostring(candidate.objectId),
                                "slot", tostring(candidate.slotName),
                                "reason", tostring(sleepAccessBlockReason),
                                "door", tostring(lockedDoor and (lockedDoor.recordId or lockedDoor.id)),
                                "key", tostring(lockedDoorKey)
                            )
                        end
                    elseif candidateType == "sleeping" then
                        if lockedDoorAccess == "keyed_locked_route_door" and settings.debug then
                            ctx.debugLog(
                                "sleep keyed locked-door bed preferred",
                                npc.recordId or npc.id,
                                "object", tostring(candidate.objectId),
                                "slot", tostring(candidate.slotName),
                                "door", tostring(lockedDoor and (lockedDoor.recordId or lockedDoor.id)),
                                "key", tostring(lockedDoorKey)
                            )
                        end
                        if originPreferredDist and dist <= radius and (not preferredDist or originPreferredDist < preferredDist) then
                            preferredIndex = i
                            preferredDist = originPreferredDist
                            preferredRadius = radius
                        end

                        if dist <= radius and (not bestDist or dist < bestDist) then
                            bestIndex = i
                            bestDist = dist
                            bestRadius = radius
                        end
                    else
                        if dist <= radius and (not bestDist or dist < bestDist) then
                            bestIndex = i
                            bestDist = dist
                            bestRadius = radius
                        end
                    end
                end
            end
        elseif localSittingRejectActive and settings.debug then
            ctx.debugLog(
                "reject sitting local cooldown",
                npc.recordId or npc.id,
                "object", tostring(candidate.objectId),
                "slot", tostring(candidate.slotName)
            )
        end
    end

    if preferredIndex then
        if preferredRouteBlocked
            and preferredRouteBlockedDist
            and preferredDist
            and preferredDist > preferredRouteBlockedDist + 96 then
            if settings.debug then
                local preferredCandidate = candidates[preferredIndex]
                ctx.debugLog(
                    "sleep origin preferred alternate allowed after failed closer route",
                    npc.recordId or npc.id,
                    "blockedObject", tostring(preferredRouteBlockedObject),
                    "alternateObject", tostring(preferredCandidate and preferredCandidate.objectId),
                    "blockedDistance", tostring(preferredRouteBlockedDist),
                    "alternateDistance", tostring(preferredDist)
                )
            end
        end
        bestIndex = preferredIndex
        bestDist = preferredDist
        bestRadius = preferredRadius
        if settings.debug then
            local preferredCandidate = candidates[preferredIndex]
            ctx.debugLog(
                "sleep origin preferred bed",
                npc.recordId or npc.id,
                "object", tostring(preferredCandidate and preferredCandidate.objectId),
                "distance", tostring(preferredDist)
            )
        end
    elseif preferredRouteBlocked then
        if settings.debug then
            ctx.debugLog(
                "sleep origin preferred blocked by route cooldown",
                npc.recordId or npc.id,
                "object", tostring(preferredRouteBlockedObject)
            )
        end
    end

    if not bestIndex then
        if settings.debug and nearestCandidate then
            ctx.debugLog(
                "no candidate within radius",
                npc.recordId or npc.id,
                "type", tostring(interactionType or nearestCandidate.interactionType),
                "nearestObject", tostring(nearestCandidate.objectId),
                "model", tostring(nearestCandidate.model),
                "distance", tostring(nearestDist),
                "radius", tostring(nearestRadius)
            )
        end
        return nil
    end

    local candidate = candidates[bestIndex]
    if candidate and candidate.interactionType == "sleeping"
        and candidate.debugForced ~= true
        and not sleepBedtimePressure(context)
        and not (context and context.debugForce == true)
        and ctx.sleepBedAccess.shouldRestrictDoorAssist(npc.cell, ctx.sleepOriginPreferredDistance(npc, candidate) ~= nil, context and context.debugForce == true) then
        candidate.disallowSleepDoorAssist = true
        if settings.debug then
            ctx.debugLog(
                "public sleep bed door-assist restricted",
                npc.recordId or npc.id,
                "object", tostring(candidate.objectId),
                "slot", tostring(candidate.slotName),
                "cell", ctx.cellName(npc.cell)
            )
        end
    end
    table.remove(candidates, bestIndex)
    if settings.debug then
        ctx.debugLog(
            "candidate within radius",
            npc.recordId or npc.id,
            "type", tostring(interactionType or candidate.interactionType),
            "object", tostring(candidate.objectId),
            "distance", tostring(bestDist),
            "radius", tostring(bestRadius)
        )
    end
    return candidate, bestDist
end

return M
