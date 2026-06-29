-- interactions/sleeping/localDoorAssist.lua
---@omw-context none
-- NPC-local sleep route door assist and post-door waypoint handling.

local M = {}

local TICK_SECONDS = 0.25
local DOOR_USE_TOLERANCE = 14
local DOOR_STAGE_TRAVEL_TOLERANCE = 14
local DOOR_STAGE_REISSUE_SECONDS = 0.45
local DOOR_STAGE_NO_PROGRESS_SECONDS = 1.35
local DOOR_STAGE_PROGRESS_EPSILON = 12
local DOOR_STAGE_TIMEOUT_SECONDS = 4.0
local ROUTE_DOOR_PREOPEN_DISTANCE = 145
local ROUTE_DOOR_PREOPEN_TOLERANCE = 38
local ROUTE_DOOR_REREQUEST_SECONDS = 0.9

local function settings(ctx)
    if ctx and type(ctx.settings) == "function" then return ctx.settings() end
    return ctx and ctx.settings or {}
end

local function actor(ctx)
    if ctx and type(ctx.actor) == "function" then return ctx.actor() end
    return ctx and ctx.actor or nil
end

local function doors(ctx)
    if ctx and type(ctx.doors) == "function" then return ctx.doors() end
    return ctx and ctx.doors or nil
end

local function interactionState(ctx)
    if ctx and type(ctx.interactionState) == "function" then return ctx.interactionState() end
    return {}
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function vectorLength2d(ctx, value)
    if ctx and ctx.vectorLength2d then return ctx.vectorLength2d(value) end
    if not value then return math.huge end
    local x = value.x or 0
    local y = value.y or 0
    return math.sqrt((x * x) + (y * y))
end

local function distanceToSegment2d(ctx, p, a, b)
    if ctx and ctx.distanceToSegment2d then return ctx.distanceToSegment2d(p, a, b) end
    return nil, nil
end

local function segmentProjection2d(ctx, p, a, b)
    if ctx and ctx.routeAssist and ctx.routeAssist.segmentProjection2d then
        return ctx.routeAssist.segmentProjection2d(p, a, b)
    end
    return nil
end

local function routeDoorIsOpenNonTeleport(ctx, door)
    if ctx and ctx.routeAssist and ctx.routeAssist.isOpenNonTeleport then
        return ctx.routeAssist.isOpenNonTeleport(door)
    end
    return false
end

local function openDoorBlocksCurrentRoute(ctx, door, actorPos, targetPos)
    if ctx and ctx.openDoorBlocksRoute then
        return ctx.openDoorBlocksRoute(door, actorPos, targetPos) == true
    end
    return false
end

local function routeDoorBlocksCurrentRoute(ctx, door, actorPos, targetPos)
    if ctx and ctx.openDoorBlocksRoute then
        return ctx.openDoorBlocksRoute(door, actorPos, targetPos) == true
    end
    return true
end

local function pathReachable(ctx, dest)
    local nearby = ctx and ctx.nearby
    if not (nearby and nearby.NAVIGATOR_FLAGS and ctx.pathStatusWithFlags and ctx.pathStatusIsSuccess and dest) then return true end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    if not walk then return true end
    local status = ctx.pathStatusWithFlags(dest, walk + (flags.UsePathgrid or 0))
    return ctx.pathStatusIsSuccess(status) == true
end

local function preOpenApproachPoint(ctx, door, actorPos, targetPos)
    if not (ctx and ctx.routeAssist and ctx.routeAssist.sameSideDoorPoint and door and actorPos and targetPos) then return nil end
    local point = ctx.routeAssist.sameSideDoorPoint(door, actorPos, targetPos, ROUTE_DOOR_PREOPEN_DISTANCE, actorPos.z)
    if not point then return nil end
    if not pathReachable(ctx, point) then return nil end
    if openDoorBlocksCurrentRoute(ctx, door, actorPos, point) then return nil end
    return point
end

local function actorOpenedRouteDoorPassable(ctx, door)
    if not door then return false, "invalid" end
    if ctx and ctx.routeAssist and ctx.routeAssist.isOpenNonTeleport then
        if ctx.routeAssist.isOpenNonTeleport(door) ~= true then return false, "not_open_route_door" end
    end
    return true, "actor_opened"
end

local function routeDoorOpenability(ctx, door, npc)
    if ctx and ctx.routeAssist and ctx.routeAssist.openability then
        return ctx.routeAssist.openability(door, npc, {
            debugLog = ctx.debugLog,
            logPrefix = "route_door_assist",
        })
    end
    return false, "route_door_openability_unavailable"
end

local function doorKey(door)
    return tostring(door and (door.id or door.recordId) or door)
end

local function requestAge(state, key)
    local requestedAt = state and state.requested and state.requested[key]
    if type(requestedAt) == "number" then return (state.now or 0) - requestedAt end
    if requestedAt then return 0 end
    return math.huge
end

local function routeDoorRequestSuppressed(state, key)
    if not (state and key) then return true end
    if state.rejected and state.rejected[key] then return true end
    if state.requested["blocked:" .. key] then return true end
    return requestAge(state, key) < ROUTE_DOOR_REREQUEST_SECONDS
end

local function doorRequestSuppressed(state, door)
    if not (state and door) then return true end
    if routeDoorRequestSuppressed(state, doorKey(door)) then return true end
    if door.recordId and routeDoorRequestSuppressed(state, tostring(door.recordId)) then return true end
    if door.id and routeDoorRequestSuppressed(state, tostring(door.id)) then return true end
    return false
end

local function closedRouteDoorOnTravelSegment(ctx, nearbyDoors, actorPos, targetPos, npc, toTargetLength)
    if not (ctx and ctx.routeAssist and ctx.routeAssist.isClosedNonTeleport and ctx.routeAssist.doorOnRouteSegment and nearbyDoors and actorPos and targetPos) then
        return nil, nil, nil, nil
    end

    local bestDoor, bestWaypoint, bestCanOpen, bestReason, bestScore = nil, nil, nil, nil, nil
    for _, door in ipairs(nearbyDoors) do
        if ctx.routeAssist.isClosedNonTeleport(door) then
            local onRoute = ctx.routeAssist.doorOnRouteSegment(door, actorPos, targetPos, {
                maxVertical = 170,
                maxLineDistance = 135,
                maxActorDistance = 520,
                maxTargetDistance = math.max(360, (tonumber(toTargetLength) or 0) + 220),
                minSegmentT = 0.02,
                maxSegmentT = 0.98,
            })
            if onRoute and routeDoorBlocksCurrentRoute(ctx, door, actorPos, targetPos) then
                local actorDist = (door.position - actorPos):length()
                local lineDist = distanceToSegment2d(ctx, door.position, actorPos, targetPos) or 0
                local score = actorDist + lineDist * 1.5
                if not bestScore or score < bestScore then
                    local canOpen, reason = routeDoorOpenability(ctx, door, npc)
                    local waypoint = nil
                    if canOpen == true then
                        if ctx.routeAssist.waypointPastDoor then
                            waypoint = ctx.routeAssist.waypointPastDoor(door, actorPos, targetPos, 170)
                        else
                            local dir = ctx.normalizeDirection3 and ctx.normalizeDirection3(targetPos - actorPos) or nil
                            waypoint = dir and (door.position + dir * 170) or nil
                        end
                    end
                    bestDoor, bestWaypoint, bestCanOpen, bestReason, bestScore = door, waypoint, canOpen, reason, score
                end
            end
        end
    end

    return bestDoor, bestWaypoint, bestCanOpen, bestReason
end

local function requestRouteDoor(ctx, state, npc, door, reason, postDoorWaypoint, usePoint)
    if not (ctx and ctx.sendGlobalEvent and npc and door) then return false end
    ctx.sendGlobalEvent('SitDownPleaseOpenSleepRouteDoor', {
        npc = npc,
        door = door,
        reason = reason or "sleep_route_assist",
        postDoorWaypoint = postDoorWaypoint,
        usePoint = usePoint,
    })
    return true
end

local function chooseOpenRouteDoorOnTravelSegment(ctx, nearbyDoors, actorPos, targetPos, npc)
    if not (ctx and ctx.routeAssist and ctx.routeAssist.isOpenNonTeleport and nearbyDoors and actorPos and targetPos) then
        return nil, nil
    end

    local toTargetLength = vectorLength2d(ctx, targetPos - actorPos)
    local bestDoor, bestWaypoint, bestScore = nil, nil, nil
    for _, door in ipairs(nearbyDoors) do
        if ctx.routeAssist.isOpenNonTeleport(door) and door.position then
            local actorDist = (door.position - actorPos):length()
            local targetDist = (door.position - targetPos):length()
            local lineDist, t = distanceToSegment2d(ctx, door.position, actorPos, targetPos)
            local rawT = segmentProjection2d(ctx, door.position, actorPos, targetPos) or t
            local vertical = math.abs((door.position.z or 0) - (actorPos.z or 0))
            if actorDist <= 360
                and targetDist <= math.max(430, toTargetLength + 260)
                and lineDist and lineDist <= 190
                and rawT and rawT >= -0.04 and rawT <= 1.04
                and vertical <= 220
            then
                local passable = actorOpenedRouteDoorPassable(ctx, door)
                if passable == true then
                    local waypoint = nil
                    if ctx.routeAssist.waypointPastDoor then
                        waypoint = ctx.routeAssist.waypointPastDoor(door, actorPos, targetPos, 170)
                    end
                    local blocks = openDoorBlocksCurrentRoute(ctx, door, actorPos, targetPos)
                    local score = actorDist + lineDist * 1.5 + (blocks and -180 or 0)
                    if not bestScore or score < bestScore then
                        bestDoor, bestWaypoint, bestScore = door, waypoint, score
                    end
                end
            end
        end
    end
    return bestDoor, bestWaypoint
end

local function routeDoorRejectReason(detail)
    local text = tostring(detail or "")
    if text:find("trapped_route_door", 1, true) then return "trapped_route_door" end
    if text:find("locked_route_door", 1, true) then return "locked_route_door" end
    return "blocked_route_door"
end

local function rejectRouteDoor(ctx, state, npc, door, detail, logReason)
    if not (ctx and state and door) then return false end
    local blockedKey = "blocked:" .. doorKey(door)
    if state.requested[blockedKey] then return true end
    state.requested[blockedKey] = true
    local reason = routeDoorRejectReason(detail)
    debugLog(ctx, "route_door_assist", logReason or "local_route_door_rejected", tostring(door.recordId or door.id), "actor", tostring(npc and (npc.recordId or npc.id)), "reason", tostring(reason), "detail", tostring(detail))
    if ctx.rejectRouteDoor then ctx.rejectRouteDoor(reason, door, detail) end
    return true
end

local function stageToDoorUsePoint(ctx, state, npc, key, usePoint, postDoorWaypoint, logStage, timeoutDetail, arrivalTolerance, travelTolerance)
    if not (ctx and state and npc and npc.position and key and usePoint) then return false end
    local now = state.now or 0
    local distanceToUse = vectorLength2d(ctx, usePoint - npc.position)
    local arrivedDistance = tonumber(arrivalTolerance) or DOOR_USE_TOLERANCE
    local staged = state.staged[key]
    if not staged then
        staged = {
            usePoint = usePoint,
            postDoorWaypoint = postDoorWaypoint,
            startedAt = now,
            lastIssuedAt = -math.huge,
            bestDistance = distanceToUse,
            lastProgressAt = now,
        }
        state.staged[key] = staged
    else
        staged.usePoint = staged.usePoint or usePoint
        staged.postDoorWaypoint = staged.postDoorWaypoint or postDoorWaypoint
        if distanceToUse + DOOR_STAGE_PROGRESS_EPSILON < (staged.bestDistance or math.huge) then
            staged.bestDistance = distanceToUse
            staged.lastProgressAt = now
        end
    end

    if distanceToUse <= arrivedDistance then
        state.staged[key] = nil
        debugLog(ctx, "route_door_assist", "stage_arrived", tostring(key), "actor", tostring(npc.recordId or npc.id), "usePoint", tostring(staged.usePoint), "distance", tostring(distanceToUse))
        return true, nil, true
    end

    if now - (staged.startedAt or now) > DOOR_STAGE_TIMEOUT_SECONDS then
        state.staged[key] = nil
        debugLog(ctx, "route_door_assist", "stage_timeout", tostring(key), "actor", tostring(npc.recordId or npc.id), "usePoint", tostring(staged.usePoint))
        return false, timeoutDetail or "door_use_point_unreachable"
    end
    if now - (staged.lastProgressAt or staged.startedAt or now) > DOOR_STAGE_NO_PROGRESS_SECONDS then
        state.staged[key] = nil
        debugLog(
            ctx,
            "route_door_assist",
            "stage_no_progress",
            tostring(key),
            "actor", tostring(npc.recordId or npc.id),
            "usePoint", tostring(staged.usePoint),
            "distance", tostring(distanceToUse),
            "bestDistance", tostring(staged.bestDistance)
        )
        return false, timeoutDetail or "door_use_point_no_progress"
    end

    if now - (staged.lastIssuedAt or -math.huge) >= DOOR_STAGE_REISSUE_SECONDS then
        staged.lastIssuedAt = now
        ctx.startAIPackage({
            type = "Travel",
            destPosition = staged.usePoint,
            isRepeat = false,
            cancelOther = true,
            destinationTolerance = tonumber(travelTolerance) or DOOR_STAGE_TRAVEL_TOLERANCE,
        })
        debugLog(ctx, "route_door_assist", logStage or "staging_to_use_point", tostring(key), "actor", tostring(npc.recordId or npc.id), "usePoint", tostring(staged.usePoint), "postDoorWaypoint", tostring(staged.postDoorWaypoint))
    end
    return true
end

local function stageOrRequestRouteDoor(ctx, state, npc, door, targetPos, reason, fallbackPostDoorWaypoint)
    if not (ctx and state and npc and npc.position and door and targetPos) then return false end
    local doorKeyValue = doorKey(door)
    if routeDoorRequestSuppressed(state, doorKeyValue) then return true end
    local canOpen, openReason = routeDoorOpenability(ctx, door, npc)
    if canOpen ~= true then
        return rejectRouteDoor(ctx, state, npc, door, openReason, "local_route_door_rejected")
    end
    local approachPoint = preOpenApproachPoint(ctx, door, npc.position, targetPos)
    if approachPoint then
        local stagedOk, stagedReason, arrived = stageToDoorUsePoint(ctx, state, npc, doorKeyValue, approachPoint, fallbackPostDoorWaypoint, "staging_to_preopen_point", "door_preopen_point_unreachable", ROUTE_DOOR_PREOPEN_TOLERANCE, ROUTE_DOOR_PREOPEN_TOLERANCE)
        if not stagedOk then
            debugLog(ctx, "route_door_assist", "preopen_stage_failed", tostring(door.recordId or door.id), "actor", tostring(npc.recordId or npc.id), "reason", tostring(stagedReason))
        elseif arrived ~= true then
            return true
        end
    end
    state.staged[doorKeyValue] = nil
    state.requested[doorKeyValue] = state.now or 0
    requestRouteDoor(ctx, state, npc, door, reason or "sleep_route_assist", fallbackPostDoorWaypoint, nil)
    debugLog(ctx, "route_door_assist", approachPoint and "requested_after_preopen_stage" or "requested_no_stage", tostring(door.recordId or door.id), "preOpenPoint", tostring(approachPoint), "postDoorWaypoint", tostring(fallbackPostDoorWaypoint))
    return true
end

function M.prepareInitialStage(ctx, details, targetPos)
    if not (details and details.needsDoorAssist == true) then
        return { ok = true, needsDoorAssist = false }
    end

    local npc = actor(ctx)
    local door = details.routeDoor
    local postDoorWaypoint = details.routeWaypoint
    local reason = details.routeDoorReason
    if not door and ctx and ctx.firstClosedRouteDoorOnPath then
        local pathDoor, pathWaypoint, pathCanOpen, pathReason = ctx.firstClosedRouteDoorOnPath(targetPos, true)
        if pathDoor then
            door = pathDoor
            postDoorWaypoint = pathWaypoint
            reason = pathReason
            if pathCanOpen ~= true then
                door = pathDoor
            end
        end
    end
    if not door then
        return {
            ok = false,
            needsDoorAssist = true,
            rejectReason = "blocked_route_door",
            detail = "missing_route_door",
            door = nil,
        }
    end

    local canOpen, canOpenReason = routeDoorOpenability(ctx, door, npc)
    if canOpen ~= true then
        reason = canOpenReason or reason or "blocked_route_door"
        local reasonText = tostring(reason or "blocked_route_door")
        return {
            ok = false,
            needsDoorAssist = true,
            rejectReason = reasonText:find("locked_route_door", 1, true) and "locked_route_door" or "blocked_route_door",
            detail = reasonText,
            door = door,
        }
    end

    return {
        ok = true,
        needsDoorAssist = true,
        postDoorWaypoint = postDoorWaypoint,
        door = door,
        reason = reason or canOpenReason or "route_door_assist",
    }
end

function M.create(ctx)
    ctx = ctx or {}
    local state = {
        elapsed = 0,
        requested = {},
        rejected = {},
        staged = {},
        routeNeedsDoorAssist = false,
    }
    local controller = { state = state }

    function controller.reset()
        state.elapsed = 0
        state.requested = {}
        state.rejected = {}
        state.staged = {}
        state.routeNeedsDoorAssist = false
    end

    function controller.noteRejectedDoor(key, reason)
        if not key then return false end
        key = tostring(key)
        state.rejected[key] = reason or true
        state.requested["blocked:" .. key] = true
        state.staged[key] = nil
        debugLog(ctx, "route_door_assist", "local_route_door_blacklisted", tostring(key), "reason", tostring(reason))
        return true
    end

    function controller.setNeedsDoorAssist(value)
        state.routeNeedsDoorAssist = value == true
    end

    function controller.adoptActorOpenedDoor(reason)
        local status = interactionState(ctx)
        local targetPos = status.targetPos
        if status.currentInteractionType ~= "sleeping" or not status.interactionAssigned or status.isInteracting then return false end
        if not (targetPos and ctx.sendGlobalEvent) then return false end

        local npc = actor(ctx)
        local nearbyDoors = doors(ctx)
        if not (npc and npc.position and nearbyDoors) then return false end

        if ctx.now then state.now = ctx.now() or state.now or 0 end
        local door, waypoint = chooseOpenRouteDoorOnTravelSegment(ctx, nearbyDoors, npc.position, targetPos, npc)
        if not door then return false end

        local key = "actor_open:" .. doorKey(door)
        if routeDoorRequestSuppressed(state, key) then return true end
        state.requested[key] = state.now or 0
        requestRouteDoor(ctx, state, npc, door, reason or "actor_opened_sleep_route_door", waypoint, nil)
        debugLog(ctx, "route_door_assist", "actor_opened_route_door_adopt_requested", tostring(door.recordId or door.id), "actor", tostring(npc.recordId or npc.id), "target", tostring(targetPos), "postDoorWaypoint", tostring(waypoint))
        return true
    end

    function controller.routeProbablyNeedsDoor(dest)
        if state.routeNeedsDoorAssist == true then return true end
        local nearby = ctx.nearby
        if not (nearby and nearby.NAVIGATOR_FLAGS and nearby.findPath and dest) then return false end
        local flags = nearby.NAVIGATOR_FLAGS
        local walk = flags.Walk
        local openDoor = flags.OpenDoor
        if not (walk and openDoor and ctx.pathStatusWithFlags and ctx.pathStatusIsSuccess) then return false end
        local baseFlags = walk + (flags.UsePathgrid or 0)
        local closedStatus = ctx.pathStatusWithFlags(dest, baseFlags)
        local openStatus = ctx.pathStatusWithFlags(dest, baseFlags + openDoor)
        if ctx.pathStatusIsSuccess(openStatus) and not ctx.pathStatusIsSuccess(closedStatus) then return true end
        return false
    end

    function controller.process(dt)
        local opts = settings(ctx)
        if opts.sleepSmartDoorAssist == false then return end

        local status = interactionState(ctx)
        local targetPos = status.targetPos
        if status.currentInteractionType ~= "sleeping" or not status.interactionAssigned or status.isInteracting then return end
        if not targetPos then return end
        if not (ctx.sendGlobalEvent and ctx.startAIPackage) then return end

        local npc = actor(ctx)
        local nearbyDoors = doors(ctx)
        if not (npc and npc.position and nearbyDoors) then return end

        state.elapsed = state.elapsed + (tonumber(dt) or 0)
        if state.elapsed < TICK_SECONDS then return end
        state.elapsed = 0
        state.now = (state.now or 0) + TICK_SECONDS

        local actorPos = npc.position
        local toTarget = targetPos - actorPos
        local toTargetLength = vectorLength2d(ctx, toTarget)
        if toTargetLength < 80 then return end

        local pathNeedsDoor = state.routeNeedsDoorAssist == true or controller.routeProbablyNeedsDoor(targetPos) == true
        local segmentDoor, segmentWaypoint, segmentCanOpen, segmentReason = nil, nil, nil, nil
        if pathNeedsDoor then
            segmentDoor, segmentWaypoint, segmentCanOpen, segmentReason = closedRouteDoorOnTravelSegment(ctx, nearbyDoors, actorPos, targetPos, npc, toTargetLength)
        end
        if segmentDoor and segmentCanOpen ~= true then
            if doorRequestSuppressed(state, segmentDoor) then return end
            local blockedKey = "blocked:" .. doorKey(segmentDoor)
            if not state.requested[blockedKey] then
                state.requested[blockedKey] = true
                local reason = routeDoorRejectReason(segmentReason)
                debugLog(ctx, "route_door_assist", "local_route_door_rejected", tostring(segmentDoor.recordId or segmentDoor.id), "reason", tostring(reason), "detail", tostring(segmentReason))
                if ctx.rejectRouteDoor then ctx.rejectRouteDoor(reason, segmentDoor, segmentReason) end
            end
            return
        end

        local routeNeedsDoor = pathNeedsDoor or segmentDoor ~= nil
        if not routeNeedsDoor then
            local openDoor, openScore = nil, nil
            for _, door in ipairs(nearbyDoors) do
                if routeDoorIsOpenNonTeleport(ctx, door) then
                    local normalDoorKey = doorKey(door)
                    local openDoorKey = "open:" .. normalDoorKey
                    if not routeDoorRequestSuppressed(state, normalDoorKey) and not routeDoorRequestSuppressed(state, openDoorKey) then
                        local actorDist = (door.position - actorPos):length()
                        local targetDist = (door.position - targetPos):length()
                        local lineDist, t = distanceToSegment2d(ctx, door.position, actorPos, targetPos)
                        local rawT = segmentProjection2d(ctx, door.position, actorPos, targetPos) or t
                        local vertical = math.abs((door.position.z or 0) - (actorPos.z or 0))
                        if actorDist <= 340 and targetDist <= math.max(380, toTargetLength + 220) and lineDist and lineDist <= 155 and rawT and rawT > 0.01 and rawT < 0.99 and vertical <= 210 and openDoorBlocksCurrentRoute(ctx, door, actorPos, targetPos) then
                            local passable, passReason = actorOpenedRouteDoorPassable(ctx, door)
                            if passable ~= true then
                                state.requested[openDoorKey] = true
                                local reason = routeDoorRejectReason(passReason)
                                debugLog(ctx, "route_door_assist", "local_open_route_door_rejected", tostring(door.recordId or door.id), "reason", tostring(reason), "detail", tostring(passReason))
                                if ctx.rejectRouteDoor then ctx.rejectRouteDoor(reason, door, passReason) end
                                return
                            else
                                local score = actorDist + lineDist * 1.5
                                if not openScore or score < openScore then
                                    openDoor, openScore = door, score
                                end
                            end
                        end
                    end
                end
            end
            if openDoor then
                local normalDoorKey = doorKey(openDoor)
                local openDoorKey = "open:" .. normalDoorKey
                state.staged[normalDoorKey] = nil
                state.requested[openDoorKey] = state.now or 0
                local waypoint = ctx.routeAssist and ctx.routeAssist.waypointPastDoor and ctx.routeAssist.waypointPastDoor(openDoor, actorPos, targetPos, 170) or nil
                debugLog(ctx, "door_already_open", tostring(openDoor.recordId or openDoor.id), "actor", tostring(npc and (npc.recordId or npc.id)))
                debugLog(ctx, "door_collision_suspected", tostring(openDoor.recordId or openDoor.id), "actorDistance", tostring((openDoor.position - actorPos):length()), "target", tostring(targetPos), "postDoorWaypoint", tostring(waypoint))
                requestRouteDoor(ctx, state, npc, openDoor, "actor_opened_sleep_route_door", waypoint, nil)
                debugLog(ctx, "door_route_retry", tostring(openDoor.recordId or openDoor.id), "stage", "adopt_actor_opened", "target", tostring(waypoint or targetPos))
            end
            return
        end

        local bestDoor, bestScore, bestWaypoint = nil, nil, nil
        local pathDoor, pathWaypoint, pathCanOpen, pathReason = nil, nil, nil, nil
        if segmentDoor and segmentCanOpen == true then
            local segmentDoorKey = doorKey(segmentDoor)
            if not routeDoorRequestSuppressed(state, segmentDoorKey) then
                bestDoor = segmentDoor
                bestScore = (segmentDoor.position - actorPos):length()
                bestWaypoint = segmentWaypoint
            end
        end
        if state.routeNeedsDoorAssist == true and ctx.firstClosedRouteDoorOnPath then
            pathDoor, pathWaypoint, pathCanOpen, pathReason = ctx.firstClosedRouteDoorOnPath(targetPos, true)
        end
        if pathDoor and doorRequestSuppressed(state, pathDoor) then
            pathDoor, pathWaypoint, pathCanOpen, pathReason = nil, nil, nil, nil
        end
        if pathDoor and pathCanOpen ~= true then
            rejectRouteDoor(ctx, state, npc, pathDoor, pathReason, "local_route_door_rejected")
            return
        end
        if pathDoor then
            local pathDoorKey = doorKey(pathDoor)
            local actorDist = (pathDoor.position - actorPos):length()
            local targetDist = (pathDoor.position - targetPos):length()
            if not routeDoorRequestSuppressed(state, pathDoorKey) and actorDist <= 340 and targetDist <= math.max(260, toTargetLength + 180) then
                bestDoor = pathDoor
                bestScore = actorDist
                bestWaypoint = pathWaypoint
            end
        end

        if bestDoor then
            stageOrRequestRouteDoor(ctx, state, npc, bestDoor, targetPos, "sleep_route_assist", bestWaypoint)
        end
    end

    return controller
end

return M
