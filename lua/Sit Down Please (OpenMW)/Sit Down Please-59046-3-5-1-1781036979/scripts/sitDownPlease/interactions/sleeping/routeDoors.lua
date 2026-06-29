-- interactions/sleeping/routeDoors.lua
---@omw-context global
---@diagnostic disable: assign-type-mismatch
-- Runtime-only same-cell door assist for sleep routing.
-- Kept out of interactionAssignment.lua because door probing/repath/cleanup is
-- independent from candidate selection and was contributing to the global script
-- becoming too large.

local core = require('openmw.core')
local types = require('openmw.types')
local routeAssist = require('scripts/sitDownPlease/assignment/routeAssist')

local M = {}

local ctx = {}
local sleepRouteDoorsByNpc = {}

local CLOSE_DEFER_SECONDS = 0.22
local ROUTE_DOOR_CLOSE_AFTER_SECONDS = 1.0
local ADOPTED_OPEN_DOOR_CLOSE_AFTER_SECONDS = 0.9
local SHARED_DOOR_CLOSE_AFTER_SECONDS = 0.8
local PASSED_DOOR_CLOSE_DELAY_SECONDS = 0.04
local PASSED_DOOR_SAFE_DISTANCE = 32
local WAKE_RETURN_PASSED_DOOR_CLOSE_DELAY_SECONDS = 0.02
local WAKE_RETURN_PASSED_DOOR_SAFE_DISTANCE = 18
local ABANDONED_DOOR_CLOSE_DELAY_SECONDS = 0.05
local ACTOR_IN_PATH_RETRY_SECONDS = 0.25
local ROUTE_RESTART_DELAY_SECONDS = 0.12
local ROUTE_DOOR_POST_OPEN_REPATH_DELAY_SECONDS = 1.35
local OPEN_DOOR_STUCK_SECONDS = 1.35
local OPEN_DOOR_STUCK_PROGRESS_EPSILON = 12
local OPEN_DOOR_STUCK_MAX_DISTANCE = 165
local OPEN_DOOR_RESET_CLEAR_DISTANCE = 110
local OPEN_DOOR_RESET_APPROACH_DISTANCE = 95
local OPEN_DOOR_RESET_CLEAR_WAIT_SECONDS = 0.35
local WAKE_RETURN_DOOR_WATCH_SECONDS = 8.0
local REJECTED_ROUTE_DOOR_WATCH_SECONDS = 6.0
local TRACKED_APPROACH_CLOSE_DEFER_EXTRA = 18
local ASSIGNED_APPROACH_CLOSE_DEFER_EXTRA = 25
-- Wake-return origins and failed-route origins are often close to the
-- doorway itself in tight interiors. Keep the door probe conservative, but do
-- not reject useful doors just because the final idle point is close to them.
local WAKE_RETURN_MIN_TARGET_BEYOND_DOOR_DISTANCE = 70
local WAKE_RETURN_MAX_SEGMENT_T = 0.97
local WAKE_RETURN_MIN_SEGMENT_T = 0.03
local WAKE_RETURN_MAX_LINE_DISTANCE = 130
local POST_DOOR_FINAL_FALLBACK_ATTEMPTS = 2
local POST_DOOR_FINAL_FALLBACK_NO_PROGRESS = 2
local POST_DOOR_PROGRESS_EPSILON = OPEN_DOOR_STUCK_PROGRESS_EPSILON

function M.configure(newCtx)
    ctx = newCtx or {}
end

local function debugLog(...)
    if ctx.debugLog then ctx.debugLog(...) end
end

local function infoLog(...)
    if ctx.infoLog then ctx.infoLog(...) end
end

local function assignedActors()
    if type(ctx.assignedActors) == "function" then return ctx.assignedActors() or {} end
    return ctx.assignedActors or {}
end

local function isObjValid(obj)
    return ctx.isObjValid and ctx.isObjValid(obj) or false
end

local function doorObjectId(door)
    return routeAssist.doorObjectId(door)
end

local function wakeReturnDoorUseful(door, fromPos, target, waypoint)
    if not (door and door.position and fromPos and target) then return false end
    local routeFlat = routeAssist.vectorLength2d(target - fromPos)
    if routeFlat < 1 then return false end
    local lineDist, rawT = routeAssist.distanceToSegment2d(door.position, fromPos, target)
    local maxLineDistance = math.min(WAKE_RETURN_MAX_LINE_DISTANCE, math.max(45, routeFlat * 0.18))
    if lineDist > maxLineDistance then return false end
    if rawT and (rawT < WAKE_RETURN_MIN_SEGMENT_T or rawT > WAKE_RETURN_MAX_SEGMENT_T) then return false end
    local targetDist = (door.position - target):length()
    if targetDist < WAKE_RETURN_MIN_TARGET_BEYOND_DOOR_DISTANCE then return false end
    if waypoint then
        local waypointTargetDist = (waypoint - target):length()
        if waypointTargetDist >= targetDist then return false end
    end
    return true
end

function M.isHardWakeReturnReject(reason)
    local text = tostring(reason or "")
    return text:find("locked_route_door", 1, true) ~= nil
        or text:find("trapped_route_door", 1, true) ~= nil
        or text:find("blocked_route_door", 1, true) ~= nil
end

local function doorBetweenActorAndBed(door, npc, data)
    if not (door and door.position and npc and npc.position and data) then return false, "missing_route_context" end
    if data.interactionType ~= "sleeping" then return false, "not_sleep_route" end
    if ctx.sleepReservationExistsForNpc and ctx.sleepReservationExistsForNpc(npc) ~= true then return false, "no_sleep_reservation" end
    local target = data.approachPos or data.finalPosition or (data.object and data.object.position)
    if not target then return false, "missing_sleep_target" end
    local ok, reason = routeAssist.doorOnRouteSegment(door, npc.position, target, {
        maxVertical = 135,
        maxLineDistance = 150,
        maxActorDistance = 850,
        maxTargetDistance = 850,
    })
    if reason == "door_not_between_actor_and_target" then return false, "door_not_between_actor_and_bed" end
    return ok, reason
end

local function isDoorLocked(door)
    return routeAssist.isDoorLocked(door)
end

local function doorLockLevel(door)
    return routeAssist.doorLockLevel(door)
end

local function npcCanOpenDoor(door, npc)
    return routeAssist.npcCanOpenDoor(door, npc, {
        debugLog = debugLog,
        logPrefix = "route_door_assist",
    })
end

function M.isNonTeleportDoor(door)
    return routeAssist.isNonTeleportDoor(door)
end

function M.isClosedNonTeleport(door)
    return routeAssist.isClosedNonTeleport(door)
end

function M.isOpenNonTeleport(door)
    return routeAssist.isOpenNonTeleport(door)
end

function M.openability(door, npc)
    return routeAssist.openability(door, npc, {
        debugLog = debugLog,
        logPrefix = "route_door_assist",
    })
end

function M.isClosedOpenableNonTeleport(door, npc)
    local ok = M.openability(door, npc)
    return ok == true
end

local function isNonTeleportRouteDoor(door, npc, data)
    if not (isObjValid(door) and isObjValid(npc) and types and types.Door and types.Door.objectIsInstance) then return false, "invalid" end
    if not M.isNonTeleportDoor(door) then return false, "not_route_door" end
    if door.cell and npc.cell and door.cell ~= npc.cell then return false, "different_cell" end
    local betweenOk, betweenReason = doorBetweenActorAndBed(door, npc, data)
    if not betweenOk then return false, betweenReason end
    return true, "route_door"
end

local function isActorOpenedSleepRouteDoor(door, npc, data)
    if not (isObjValid(door) and isObjValid(npc) and door.position and npc.position and data) then return false, "invalid" end
    if data.interactionType ~= "sleeping" then return false, "not_sleep_route" end
    if ctx.sleepReservationExistsForNpc and ctx.sleepReservationExistsForNpc(npc) ~= true then return false, "no_sleep_reservation" end
    if not M.isNonTeleportDoor(door) then return false, "not_route_door" end
    if door.cell and npc.cell and door.cell ~= npc.cell then return false, "different_cell" end
    local target = data.approachPos or data.finalPosition or (data.object and data.object.position)
    if not target then return false, "missing_sleep_target" end
    local ok, reason = routeAssist.doorOnRouteSegment(door, npc.position, target, {
        maxVertical = 220,
        maxLineDistance = 210,
        maxActorDistance = 900,
        maxTargetDistance = 1200,
        minSegmentT = -0.08,
        maxSegmentT = 1.08,
    })
    if not ok then return false, reason end
    return true, "actor_opened"
end

local function canOpenRouteDoor(door, npc, data)
    local ok, reason = isNonTeleportRouteDoor(door, npc, data)
    if not ok then return false, reason end
    local okClosed, closed = pcall(types.Door.isClosed, door)
    if not (okClosed and closed == true) then return false, "not_closed" end
    local canOpen, openReason = npcCanOpenDoor(door, npc)
    if canOpen ~= true then return false, openReason end
    return true, openReason
end

local function scheduleRouteRestart(npcId, npc, postDoorWaypoint, delay, finalTarget, reason, wakeReturn, options)
    if not npcId then return end
    options = options or {}
    local pending = sleepRouteDoorsByNpc.__pendingRestarts or {}
    sleepRouteDoorsByNpc.__pendingRestarts = pending
    pending[npcId] = {
        npc = npc,
        due = (core.getSimulationTime() or 0) + (tonumber(delay) or ROUTE_RESTART_DELAY_SECONDS),
        count = 0,
        stage = options.clearanceWaypoint and "clearance" or options.directFinal == true and "approach" or postDoorWaypoint and "post_door" or "approach",
        directFinal = options.directFinal == true,
        clearanceWaypoint = options.clearanceWaypoint,
        postDoorWaypoint = postDoorWaypoint,
        finalTarget = finalTarget,
        reason = reason,
        wakeReturn = wakeReturn == true,
        postDoorAttempts = 0,
        postDoorNoProgress = 0,
        postDoorBestDistance = nil,
    }
end

local function notifyLocalRouteDoorRejected(npc, door, reason, data)
    if not (isObjValid(npc) and npc.sendEvent and door) then return end
    npc:sendEvent("SitDownPleaseSleepRouteDoorRejected", {
        doorKey = doorObjectId(door),
        doorRecordId = door.recordId,
        reason = reason,
        resumeTarget = data and data.approachPos or nil,
    })
end

local function sameTrackedDoor(entry, door, doorId)
    if not (entry and door) then return false end
    if entry.door == door then return true end
    return doorId ~= nil and entry.doorId == doorId
end

local function findTrackedDoorEntry(door)
    local doorId = doorObjectId(door)
    for npcId, list in pairs(sleepRouteDoorsByNpc) do
        if npcId ~= "__pendingRestarts" and type(list) == "table" then
            for _, entry in ipairs(list) do
                if sameTrackedDoor(entry, door, doorId) then return entry, npcId end
            end
        end
    end
    return nil, nil
end

local function maxOpenSeconds(entry, fallback)
    return tonumber(entry and entry.maxOpenSeconds) or tonumber(fallback) or 45
end

local function passedDoorCloseDelay(entry)
    if entry and entry.wakeReturn == true then return WAKE_RETURN_PASSED_DOOR_CLOSE_DELAY_SECONDS end
    return PASSED_DOOR_CLOSE_DELAY_SECONDS
end

local function passedDoorSafeDistance(entry)
    if entry and entry.wakeReturn == true then return WAKE_RETURN_PASSED_DOOR_SAFE_DISTANCE end
    return PASSED_DOOR_SAFE_DISTANCE
end

local function markEntryPassed(entry, now, reason)
    if not entry then return end
    entry.passedDoor = true
    entry.safeCloseDistance = math.min(tonumber(entry.safeCloseDistance or 230) or 230, passedDoorSafeDistance(entry))
    entry.closeAfter = math.min(entry.closeAfter or (now + passedDoorCloseDelay(entry)), now + passedDoorCloseDelay(entry))
    entry.closeReason = reason or entry.closeReason or "post_door_waypoint"
end

local actorPastPostDoorSide
local canCheckPostDoorSide

local function sameSideDoorClearancePoint(entry, npc, target)
    local door = entry and entry.door
    if not (door and door.position and npc and npc.position and target) then return nil end
    local clearDistance = tonumber(entry and entry.resetClearDistance) or OPEN_DOOR_RESET_CLEAR_DISTANCE
    return routeAssist.sameSideDoorPoint(door, npc.position, target, clearDistance, npc.position.z or door.position.z or 0)
end

local function routeProgressTarget(entry, data)
    if entry and entry.directFinalAfterOpen == true and data and data.approachPos then return data.approachPos end
    if entry and entry.postDoorWaypoint then return entry.postDoorWaypoint end
    return data and data.approachPos or nil
end

local function resetOpenDoorForStuckActor(npcId, entry, npc, data, now)
    local door = entry and entry.door
    if entry.resetClosedOpenDoor == true then return false end
    if entry.passedDoor == true then return false end
    if not (isObjValid(door) and isObjValid(npc) and npc.position and door.position) then return false end
    if not (types and types.Door and types.Door.isOpen and types.Door.activateDoor) then return false end
    if canCheckPostDoorSide(entry) and actorPastPostDoorSide(entry, npc) then return false end

    local target = routeProgressTarget(entry, data)
    if not target then return false end
    local actorDistance = (npc.position - door.position):length()
    if actorDistance > OPEN_DOOR_STUCK_MAX_DISTANCE then return false end

    local distanceToTarget = (npc.position - target):length()
    if not entry.openDoorProgress or entry.openDoorProgressTarget ~= tostring(target) then
        entry.openDoorProgress = {
            bestDistance = distanceToTarget,
            lastProgressAt = now,
        }
        entry.openDoorProgressTarget = tostring(target)
        return false
    end

    local progress = entry.openDoorProgress
    if distanceToTarget + OPEN_DOOR_STUCK_PROGRESS_EPSILON < (progress.bestDistance or math.huge) then
        progress.bestDistance = distanceToTarget
        progress.lastProgressAt = now
        return false
    end
    if now - (progress.lastProgressAt or now) < OPEN_DOOR_STUCK_SECONDS then return false end

    local okOpen, isOpen = pcall(types.Door.isOpen, door)
    if not (okOpen and isOpen == true) then return false end
    local okClose, closeErr = pcall(types.Door.activateDoor, door, false)
    if not okClose then
        debugLog("route_door_assist", "open_door_stuck_reset_close_failed", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), tostring(closeErr))
        return false
    end

    entry.resetClosedOpenDoor = true
    entry.openedAt = now
    entry.closeAfter = nil
    entry.passedDoor = false
    entry.closeReason = entry.closeReason or "open_door_stuck_reset"
    local clearanceWaypoint = sameSideDoorClearancePoint(entry, npc, target)
    scheduleRouteRestart(npcId, npc, nil, ROUTE_RESTART_DELAY_SECONDS, data and data.approachPos or target, "open_door_stuck_reset", false, {
        clearanceWaypoint = clearanceWaypoint,
    })
    debugLog("route_door_assist", "open_door_stuck_reset_closed", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "target", tostring(target), "clearance", tostring(clearanceWaypoint), "distance", tostring(distanceToTarget), "bestDistance", tostring(progress.bestDistance))
    infoLog("door_open_blocker_reset_closed", npc and (npc.recordId or npc.id), tostring(entry.doorRecordId or door.recordId or door.id), "reason", "open_door_stuck_reset")
    return true
end

local function routeForward2d(fromPos, toPos)
    if not (fromPos and toPos) then return nil end
    local dx = (toPos.x or 0) - (fromPos.x or 0)
    local dy = (toPos.y or 0) - (fromPos.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    return { x = dx / len, y = dy / len }
end

local function dotAlongRoute(point, doorPos, forward)
    if not (point and doorPos and forward) then return nil end
    return ((point.x or 0) - (doorPos.x or 0)) * forward.x
        + ((point.y or 0) - (doorPos.y or 0)) * forward.y
end

actorPastPostDoorSide = function(entry, npc)
    local door = entry and entry.door
    local postDoorWaypoint = entry and entry.postDoorWaypoint
    local startPosition = entry and (entry.startPosition or entry.usePoint)
    if not (door and door.position and postDoorWaypoint and startPosition and isObjValid(npc) and npc.position) then return true end
    local forward = routeForward2d(startPosition, postDoorWaypoint)
    if not forward then return true end

    local postSide = dotAlongRoute(postDoorWaypoint, door.position, forward)
    local actorSide = dotAlongRoute(npc.position, door.position, forward)
    if not (postSide and actorSide) then return true end
    if math.abs(postSide) < 35 then return true end

    if postSide > 0 then
        return actorSide >= math.min(postSide - 35, 35)
    end
    return actorSide <= math.max(postSide + 35, -35)
end

canCheckPostDoorSide = function(entry)
    return entry
        and entry.door
        and entry.door.position
        and entry.postDoorWaypoint
        and (entry.startPosition or entry.usePoint)
end

local function otherPendingDoorUser(npcId, entry, now)
    local door = entry and entry.door
    local doorId = entry and entry.doorId or doorObjectId(door)
    if not (door and door.position) then return nil end
    for otherNpcId, list in pairs(sleepRouteDoorsByNpc) do
        if otherNpcId ~= "__pendingRestarts" and tostring(otherNpcId) ~= tostring(npcId) and type(list) == "table" then
            for _, other in ipairs(list) do
                if sameTrackedDoor(other, door, doorId)
                    and other.passedDoor ~= true
                    and other.abandonedRoute ~= true
                    and now < ((other.openedAt or now) + maxOpenSeconds(other, maxOpenSeconds(entry)))
                    and (not other.closeAfter or now < other.closeAfter)
                then
                    local npc = other.npc
                    local clearDistance = math.min(tonumber(other.safeCloseDistance or entry.safeCloseDistance or 130) or 130, 130)
                    if isObjValid(npc) and npc.position then
                        local distance = (npc.position - door.position):length()
                        if distance <= clearDistance + TRACKED_APPROACH_CLOSE_DEFER_EXTRA then
                            return otherNpcId, distance
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function trackedActorNearDoor(npcId, entry, now)
    local door = entry and entry.door
    local doorId = entry and entry.doorId or doorObjectId(door)
    if not (door and door.position) then return nil, nil end
    for otherNpcId, list in pairs(sleepRouteDoorsByNpc) do
        if otherNpcId ~= "__pendingRestarts" and type(list) == "table" then
            for _, other in ipairs(list) do
                if sameTrackedDoor(other, door, doorId) and other.abandonedRoute ~= true then
                    if other.passedDoor ~= true then
                        local npc = other.npc
                        local clearDistance = math.min(tonumber(other.safeCloseDistance or entry.safeCloseDistance or 130) or 130, 130)
                        if isObjValid(npc) and npc.position and (npc.position - door.position):length() <= clearDistance and now < ((other.openedAt or entry.openedAt or now) + maxOpenSeconds(other, maxOpenSeconds(entry))) then
                            return otherNpcId or npcId, (npc.position - door.position):length()
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function trackedActorApproachingDoor(npcId, entry, now)
    local door = entry and entry.door
    local doorId = entry and entry.doorId or doorObjectId(door)
    if not (door and door.position) then return nil, nil end
    for otherNpcId, list in pairs(sleepRouteDoorsByNpc) do
        if otherNpcId ~= "__pendingRestarts" and tostring(otherNpcId) ~= tostring(npcId) and type(list) == "table" then
            for _, other in ipairs(list) do
                if sameTrackedDoor(other, door, doorId) and other.passedDoor ~= true and other.abandonedRoute ~= true then
                    local npc = other.npc
                    local clearDistance = math.min(tonumber(other.safeCloseDistance or entry.safeCloseDistance or 130) or 130, 130)
                    if isObjValid(npc) and npc.position and now < ((other.openedAt or entry.openedAt or now) + maxOpenSeconds(other, maxOpenSeconds(entry))) then
                        local distance = (npc.position - door.position):length()
                        if distance <= clearDistance + TRACKED_APPROACH_CLOSE_DEFER_EXTRA then return otherNpcId, distance end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function assignedSleeperApproachingDoor(npcId, entry)
    local door = entry and entry.door
    local assignments = assignedActors()
    if not (door and door.position and assignments) then return nil, nil end
    local clearDistance = math.min(tonumber(entry.safeCloseDistance or 130) or 130, 130)
    local interactingState = ctx.states and ctx.states.interacting
    for otherNpcId, data in pairs(assignments) do
        if tostring(otherNpcId) ~= tostring(npcId)
            and data
            and data.interactionType == "sleeping"
            and data.state ~= interactingState
        then
            local otherNpc = data.npc
            if isObjValid(otherNpc) and otherNpc.position then
                local distance = (otherNpc.position - door.position):length()
                if distance <= clearDistance then return otherNpcId, distance end
                local target = data.approachPos or data.finalPosition or (data.object and data.object.position)
                if target then
                    local onRoute = routeAssist.doorOnRouteSegment(door, otherNpc.position, target, {
                        maxVertical = 180,
                        maxLineDistance = 180,
                        maxActorDistance = 650,
                        maxTargetDistance = 1400,
                    })
                    if onRoute and distance <= clearDistance + ASSIGNED_APPROACH_CLOSE_DEFER_EXTRA then return otherNpcId, distance end
                end
            end
        end
    end
    return nil, nil
end

local function npcCanShareLockedDoor(entry, npc)
    if not (entry and entry.wasLocked == true) then return true, nil, nil end
    local hasKey, keyId, keyReason = routeAssist.actorHasDoorKey(npc, entry.door)
    if hasKey == true then return true, "locked_route_door_actor_has_key", keyId end
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        return false, "locked_route_door_unknown_key", keyId
    end
    return false, "locked_route_door_missing_key", keyId
end

local function trackSharedDoorUse(npcId, npc, door, sourceEntry, postDoorWaypoint)
    if not (npcId and npc and door and sourceEntry) then return false end
    local now = core.getSimulationTime() or 0
    local doorId = doorObjectId(door)
    local list = sleepRouteDoorsByNpc[npcId] or {}
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then
            entry.npc = npc
            if entry.sharedRouteDoor == true then
                entry.closeAfter = nil
            else
                entry.closeAfter = math.min(entry.closeAfter or (now + SHARED_DOOR_CLOSE_AFTER_SECONDS), now + SHARED_DOOR_CLOSE_AFTER_SECONDS)
            end
            entry.postDoorWaypoint = postDoorWaypoint or entry.postDoorWaypoint
            entry.startPosition = entry.startPosition or npc.position
            return true
        end
    end
    table.insert(list, {
        door = door,
        doorId = doorId,
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = sourceEntry.openedAt or now,
        closeAfter = nil,
        wasClosedBeforeAssist = true,
        wasLocked = sourceEntry.wasLocked == true,
        lockLevel = sourceEntry.lockLevel,
        postDoorWaypoint = postDoorWaypoint,
        startPosition = npc.position,
        sharedRouteDoor = true,
    })
    sleepRouteDoorsByNpc[npcId] = list
    return true
end

local function trackAdoptedOpenDoorUse(npcId, npc, door, postDoorWaypoint)
    if not (npcId and npc and door) then return false end
    local now = core.getSimulationTime() or 0
    local doorId = doorObjectId(door)
    local list = sleepRouteDoorsByNpc[npcId] or {}
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then
            entry.npc = npc
            entry.postDoorWaypoint = postDoorWaypoint or entry.postDoorWaypoint
            entry.startPosition = entry.startPosition or npc.position
            return true
        end
    end
    table.insert(list, {
        door = door,
        doorId = doorId,
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = now,
        closeAfter = nil,
        wasClosedBeforeAssist = false,
        wasLocked = false,
        postDoorWaypoint = postDoorWaypoint,
        startPosition = npc.position,
        sharedRouteDoor = true,
        sdpAdoptedAlreadyOpen = true,
        safeCloseDistance = 135,
        maxOpenSeconds = 20,
    })
    sleepRouteDoorsByNpc[npcId] = list
    return true
end

local function trackWakeReturnDoorWatch(npcId, npc, door, postDoorWaypoint, target, reason)
    if not (npcId and npc and door and target) then return false end
    local now = core.getSimulationTime() or 0
    local doorId = doorObjectId(door)
    local list = sleepRouteDoorsByNpc[npcId] or {}
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then
            entry.npc = npc
            entry.postDoorWaypoint = postDoorWaypoint or entry.postDoorWaypoint
            entry.finalTarget = target
            entry.startPosition = entry.startPosition or npc.position
            entry.wakeReturn = true
            entry.watchOpenByActor = true
            entry.watchExpiresAt = math.max(tonumber(entry.watchExpiresAt or 0) or 0, now + WAKE_RETURN_DOOR_WATCH_SECONDS)
            return true
        end
    end
    table.insert(list, {
        door = door,
        doorId = doorId,
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = now,
        closeAfter = nil,
        wasClosedBeforeAssist = false,
        wasLocked = isDoorLocked(door) == true,
        lockLevel = doorLockLevel(door),
        postDoorWaypoint = postDoorWaypoint,
        finalTarget = target,
        startPosition = npc.position,
        wakeReturn = true,
        sharedRouteDoor = true,
        watchOpenByActor = true,
        watchExpiresAt = now + WAKE_RETURN_DOOR_WATCH_SECONDS,
        safeCloseDistance = 45,
        maxOpenSeconds = WAKE_RETURN_DOOR_WATCH_SECONDS + 6,
        closeReason = "wake_return_actor_opened_route_door",
        watchReason = reason,
    })
    sleepRouteDoorsByNpc[npcId] = list
    infoLog("wake_return_door_watch_started", npc.recordId or npc.id, tostring(door.recordId or door.id), "reason", tostring(reason))
    return true
end

local function trackRejectedRouteDoor(npc, door, reason)
    local npcId = npc and npc.id
    if not (npcId and npc and door) then return false end
    local now = core.getSimulationTime() or 0
    local doorId = doorObjectId(door)
    local list = sleepRouteDoorsByNpc[npcId] or {}
    local isOpen = M.isOpenNonTeleport(door)
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then
            entry.npc = npc
            entry.rejectedRouteDoor = true
            entry.watchOpenByActor = not isOpen
            entry.watchExpiresAt = isOpen and nil or math.max(tonumber(entry.watchExpiresAt or 0) or 0, now + REJECTED_ROUTE_DOOR_WATCH_SECONDS)
            entry.openedAt = isOpen and now or entry.openedAt or now
            entry.closeAfter = isOpen and math.min(entry.closeAfter or (now + CLOSE_DEFER_SECONDS), now + CLOSE_DEFER_SECONDS) or entry.closeAfter
            entry.closeReason = reason or entry.closeReason or "rejected_route_door"
            entry.safeCloseDistance = math.min(tonumber(entry.safeCloseDistance or 90) or 90, 90)
            return true
        end
    end
    table.insert(list, {
        door = door,
        doorId = doorId,
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = now,
        closeAfter = isOpen and (now + CLOSE_DEFER_SECONDS) or nil,
        wasClosedBeforeAssist = false,
        wasLocked = isDoorLocked(door) == true,
        lockLevel = doorLockLevel(door),
        rejectedRouteDoor = true,
        sharedRouteDoor = true,
        watchOpenByActor = not isOpen,
        watchExpiresAt = isOpen and nil or (now + REJECTED_ROUTE_DOOR_WATCH_SECONDS),
        safeCloseDistance = 90,
        maxOpenSeconds = REJECTED_ROUTE_DOOR_WATCH_SECONDS + 8,
        closeReason = reason or "rejected_route_door",
        watchReason = reason,
    })
    sleepRouteDoorsByNpc[npcId] = list
    infoLog("rejected_route_door_tracked", npc.recordId or npc.id, tostring(door.recordId or door.id), "open", tostring(isOpen == true), "reason", tostring(reason))
    return true
end

local function trackResetClosedDoorWatch(npcId, npc, door, postDoorWaypoint, finalTarget, reason)
    if not (npcId and npc and door) then return false end
    local now = core.getSimulationTime() or 0
    local doorId = doorObjectId(door)
    local list = sleepRouteDoorsByNpc[npcId] or {}
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then
            entry.npc = npc
            entry.postDoorWaypoint = postDoorWaypoint or entry.postDoorWaypoint
            entry.finalTarget = finalTarget or entry.finalTarget
            entry.startPosition = entry.startPosition or npc.position
            entry.watchOpenByActor = true
            entry.watchExpiresAt = math.max(tonumber(entry.watchExpiresAt or 0) or 0, now + REJECTED_ROUTE_DOOR_WATCH_SECONDS)
            entry.closeReason = reason or entry.closeReason or "already_open_collision_reset"
            entry.watchReason = reason or entry.watchReason
            return true
        end
    end
    table.insert(list, {
        door = door,
        doorId = doorId,
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = now,
        closeAfter = nil,
        wasClosedBeforeAssist = false,
        wasLocked = isDoorLocked(door) == true,
        lockLevel = doorLockLevel(door),
        postDoorWaypoint = postDoorWaypoint,
        finalTarget = finalTarget,
        startPosition = npc.position,
        watchOpenByActor = true,
        watchExpiresAt = now + REJECTED_ROUTE_DOOR_WATCH_SECONDS,
        safeCloseDistance = 135,
        maxOpenSeconds = 20,
        closeReason = reason or "already_open_collision_reset",
        watchReason = reason,
    })
    sleepRouteDoorsByNpc[npcId] = list
    infoLog(
        "door_reset_reopen_watch_started",
        npc.recordId or npc.id,
        tostring(door.recordId or door.id),
        "reason", tostring(reason),
        "postDoor", tostring(postDoorWaypoint),
        "final", tostring(finalTarget)
    )
    return true
end

local function closeRouteDoorEntry(npcId, entry, reason)
    local door = entry and entry.door
    if not isObjValid(door) then return true end
    if not (types and types.Door and types.Door.activateDoor) then return true end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    if okTeleport and isTeleport == true then return true end
    local okOpen, isOpen = pcall(types.Door.isOpen, door)
    if okOpen and isOpen ~= true then return true end
    local npc = entry and entry.npc
    local now = core.getSimulationTime() or 0
    local pendingNpcId = otherPendingDoorUser(npcId, entry, now)
    if pendingNpcId then
        entry.closeAfter = now + CLOSE_DEFER_SECONDS
        debugLog("sleep route door close deferred shared_user", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(pendingNpcId), "reason", tostring(reason or "route_done"))
        infoLog("door_close_delayed_shared_user", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(pendingNpcId), "reason", tostring(reason or "route_done"))
        return false
    end
    local abandonedRoute = entry and entry.abandonedRoute == true
    local approachingTrackedNpcId, approachingTrackedDistance = trackedActorApproachingDoor(npcId, entry, now)
    if approachingTrackedNpcId then
        entry.closeAfter = now + CLOSE_DEFER_SECONDS
        debugLog("sleep route door close deferred tracked_actor_approaching_door", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(approachingTrackedNpcId), "distance", tostring(approachingTrackedDistance), "reason", tostring(reason or "route_done"))
        infoLog("door_close_delayed_tracked_actor_approaching", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(approachingTrackedNpcId), "reason", tostring(reason or "route_done"))
        return false
    end
    local approachingNpcId, approachingDistance = nil, nil
    local maxOpenExpired = now >= ((entry.openedAt or now) + maxOpenSeconds(entry))
    if not abandonedRoute and not maxOpenExpired then
        approachingNpcId, approachingDistance = assignedSleeperApproachingDoor(npcId, entry)
    end
    if approachingNpcId then
        entry.closeAfter = now + CLOSE_DEFER_SECONDS
        debugLog("sleep route door close deferred assigned_sleeper_near_door", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(approachingNpcId), "distance", tostring(approachingDistance), "reason", tostring(reason or "route_done"))
        infoLog("door_close_delayed_assigned_sleeper_near", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "other", tostring(approachingNpcId), "reason", tostring(reason or "route_done"))
        return false
    end
    local nearNpcId, nearDistance = nil, nil
    if not abandonedRoute then
        nearNpcId, nearDistance = trackedActorNearDoor(npcId, entry, now)
    end
    if nearNpcId then
        entry.closeAfter = now + CLOSE_DEFER_SECONDS
        debugLog("sleep route door close deferred tracked_actor_near_door", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "near", tostring(nearNpcId), "distance", tostring(nearDistance), "reason", tostring(reason or "route_done"))
        infoLog("door_close_delayed_actor_near", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "near", tostring(nearNpcId), "reason", tostring(reason or "route_done"))
        return false
    end
    if not abandonedRoute and entry.passedDoor ~= true and isObjValid(npc) and npc.position and door.position then
        local clearDistance = math.min(tonumber(entry.safeCloseDistance or 130) or 130, 130)
        if (npc.position - door.position):length() <= clearDistance and now < ((entry.openedAt or now) + maxOpenSeconds(entry)) then
            entry.closeAfter = now + CLOSE_DEFER_SECONDS
            debugLog("sleep route door close deferred actor_near_door", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "distance", tostring((npc.position - door.position):length()), "reason", tostring(reason or "route_done"))
            infoLog("door_close_delayed_actor_near", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
            return false
        end
    end
    local ok, err = pcall(types.Door.activateDoor, door, false)
    if ok then
        if entry.wasLocked == true then
            local lockable = routeAssist.lockableApi()
            if lockable and lockable.lock then
                local okLock, lockErr = pcall(lockable.lock, door, entry.lockLevel or 1)
                if okLock then
                    debugLog("sleep route door relocked", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "level", tostring(entry.lockLevel or 1))
                else
                    debugLog("sleep route door relock failed", tostring(entry.doorRecordId or door.recordId or door.id), tostring(lockErr))
                end
            end
        end
        debugLog("sleep route door close", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
        infoLog("door_close_completed", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
        return true
    end
    debugLog("sleep route door close failed", tostring(entry.doorRecordId or door.recordId or door.id), tostring(err))
    return false
end

local function closeReasonImpliesPassedDoor(reason)
    reason = tostring(reason or "")
    return reason == "sleep_entry"
        or reason == "calibration_fill"
        or reason == "sleep_initial_placement"
        or reason == "reached_approach"
        or reason == "wake_return_post_door_waypoint"
        or reason == "sleep_post_door_waypoint"
end

local function closeReasonAbandonsRoute(reason)
    reason = tostring(reason or "")
    return reason == "sleep_route_incomplete"
        or reason == "visible_sleep_route_incomplete"
        or reason == "no_path_to_bed"
        or reason == "wrong_floor_or_unreachable"
        or reason == "blocked_by_wall"
        or reason == "route_too_indirect"
        or reason == "approach_too_far_from_navmesh"
        or reason == "approach_navmesh_behind_collision"
        or reason == "locked_route_door"
        or reason == "blocked_route_door"
        or reason == "trapped_route_door"
        or reason == "public_bed_requires_door_assist"
        or reason == "sleep_initial_placement_rejected"
end

function M.closeForNpc(npcId, reason)
    if not npcId then return end
    local list = sleepRouteDoorsByNpc[npcId]
    if not list then return end
    local now = core.getSimulationTime() or 0
    local passedDoor = closeReasonImpliesPassedDoor(reason)
    local abandonedRoute = closeReasonAbandonsRoute(reason)
    for _, entry in ipairs(list) do
        if abandonedRoute then
            entry.abandonedRoute = true
            entry.passedDoor = true
            entry.safeCloseDistance = 0
            entry.closeAfter = math.min(entry.closeAfter or (now + ABANDONED_DOOR_CLOSE_DELAY_SECONDS), now + ABANDONED_DOOR_CLOSE_DELAY_SECONDS)
        elseif passedDoor then
            local npc = entry.npc
            if actorPastPostDoorSide(entry, npc) then
                markEntryPassed(entry, now, reason)
            else
                entry.closeAfter = math.min(entry.closeAfter or (now + CLOSE_DEFER_SECONDS), now + CLOSE_DEFER_SECONDS)
                debugLog("route_door_assist", "close_deferred_not_past_side", tostring(entry.doorRecordId or (entry.door and (entry.door.recordId or entry.door.id))), "npc", tostring(npcId), "reason", tostring(reason))
            end
        else
            entry.closeAfter = math.min(entry.closeAfter or (now + CLOSE_DEFER_SECONDS), now + CLOSE_DEFER_SECONDS)
        end
        entry.closeReason = reason or entry.closeReason or "route_done"
    end
end

function M.closeRejectedDoor(npc, door, reason)
    if not (isObjValid(npc) and isObjValid(door) and npc.position and door.position) then return false end
    if not (types and types.Door and types.Door.activateDoor) then return false end
    trackRejectedRouteDoor(npc, door, reason)
    if not M.isOpenNonTeleport(door) then return false end
    if (npc.position - door.position):length() > 380 then
        debugLog("route_door_assist", "rejected_route_door_close_deferred_far", tostring(door.recordId or door.id), "npc", tostring(npc.recordId or npc.id), "reason", tostring(reason))
        return false
    end
    local trackedEntry, ownerNpcId = findTrackedDoorEntry(door)
    if trackedEntry and tostring(ownerNpcId) ~= tostring(npc.id) then
        debugLog("route_door_assist", "rejected_route_door_close_skipped_shared", tostring(door.recordId or door.id), "npc", tostring(npc.recordId or npc.id), "owner", tostring(ownerNpcId), "reason", tostring(reason))
        return false
    end
    local ok, err = pcall(types.Door.activateDoor, door, false)
    if ok then
        infoLog("rejected_route_door_closed", npc.recordId or npc.id, tostring(door.recordId or door.id), "reason", tostring(reason))
        debugLog("route_door_assist", npc.recordId or npc.id, "rejected_route_door_closed", tostring(door.recordId or door.id), "reason", tostring(reason))
        return true
    end
    debugLog("route_door_assist", npc.recordId or npc.id, "rejected_route_door_close_failed", tostring(door.recordId or door.id), tostring(err))
    return false
end

local function markNpcPassedDoor(npcId, reason, npc)
    if not npcId then return end
    local list = sleepRouteDoorsByNpc[npcId]
    if type(list) ~= "table" then return end
    local now = core.getSimulationTime() or 0
    local marked = false
    for _, entry in ipairs(list) do
        if actorPastPostDoorSide(entry, npc) then
            markEntryPassed(entry, now, reason)
            marked = true
        else
            entry.closeAfter = now + ACTOR_IN_PATH_RETRY_SECONDS
            debugLog("route_door_assist", "post_door_wait_actor_not_past_side", tostring(entry.doorRecordId or (entry.door and (entry.door.recordId or entry.door.id))), "npc", tostring(npcId), "actor", tostring(npc and (npc.recordId or npc.id)), "postDoorWaypoint", tostring(entry.postDoorWaypoint))
        end
    end
    return marked
end

local function trackedRouteDoorPassed(npcId, npc, reason)
    if not npcId then return false end
    local list = sleepRouteDoorsByNpc[npcId]
    if type(list) ~= "table" then return false end
    local now = core.getSimulationTime() or 0
    local passed = false
    for _, entry in ipairs(list) do
        if entry and entry.passedDoor == true then
            passed = true
        elseif canCheckPostDoorSide(entry) and actorPastPostDoorSide(entry, npc) then
            markEntryPassed(entry, now, reason or "actor_passed_door_side")
            passed = true
        end
    end
    return passed
end

function M.clearPendingRestarts()
    sleepRouteDoorsByNpc.__pendingRestarts = nil
end

function M.reset(reason)
    for npcId, list in pairs(sleepRouteDoorsByNpc) do
        if npcId ~= "__pendingRestarts" and type(list) == "table" then
            for _, entry in ipairs(list) do closeRouteDoorEntry(npcId, entry, reason or "reset") end
        end
    end
    sleepRouteDoorsByNpc = {}
end

function M.process()
    local now = core.getSimulationTime() or 0
    for npcId, list in pairs(sleepRouteDoorsByNpc) do
        if npcId ~= "__pendingRestarts" then
            local data = assignedActors()[npcId]
            local keep = {}
            for _, entry in ipairs(list) do
                local door = entry and entry.door
                local npc = (data and data.npc) or entry.npc
                local shouldClose = false
                local keepEntry = true
                local skipEntryProcessing = false
                if not isObjValid(door) then
                    shouldClose = true
                else
                    if entry.watchOpenByActor == true then
                        local okOpen, isOpen = pcall(types.Door.isOpen, door)
                        if okOpen and isOpen == true then
                            entry.watchOpenByActor = false
                            entry.openedAt = now
                            entry.closeAfter = now + ROUTE_DOOR_CLOSE_AFTER_SECONDS
                            entry.closeReason = entry.closeReason or (entry.rejectedRouteDoor == true and "rejected_route_door_opened" or "wake_return_actor_opened_route_door")
                            infoLog(entry.rejectedRouteDoor == true and "rejected_route_door_watch_adopted_open" or "wake_return_door_watch_adopted_open", entry.npc and (entry.npc.recordId or entry.npc.id) or tostring(npcId), tostring(entry.doorRecordId or door.recordId or door.id), "reason", tostring(entry.watchReason))
                        elseif entry.watchExpiresAt and now >= entry.watchExpiresAt then
                            shouldClose = true
                            keepEntry = false
                            debugLog("route_door_assist", entry.rejectedRouteDoor == true and "rejected_route_door_watch_expired" or "wake_return_door_watch_expired", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(entry.watchReason))
                        else
                            table.insert(keep, entry)
                            keepEntry = false
                            skipEntryProcessing = true
                        end
                    end
                    if not skipEntryProcessing then
                        if entry.passedDoor ~= true and canCheckPostDoorSide(entry) and actorPastPostDoorSide(entry, npc) then
                            markEntryPassed(entry, now, "actor_passed_door_side")
                        end
                        if resetOpenDoorForStuckActor(npcId, entry, npc, data, now) then
                            keepEntry = true
                        else
                            local shouldAttemptClose = false
                            if entry.closeAfter and now >= entry.closeAfter then
                                shouldAttemptClose = true
                            elseif not data or data.interactionType ~= "sleeping" or data.state == (ctx.states and ctx.states.interacting) then
                                entry.closeAfter = entry.closeAfter or (now + CLOSE_DEFER_SECONDS)
                            end

                            if shouldAttemptClose then
                                local closeDistance = tonumber(entry.safeCloseDistance or 230) or 230
                                local actorDistance = isObjValid(npc) and npc.position and door.position and (npc.position - door.position):length() or nil
                                if entry.abandonedRoute == true
                                    or not isObjValid(npc)
                                    or not npc.position
                                    or not door.position
                                    or now >= ((entry.openedAt or now) + maxOpenSeconds(entry))
                                    or (entry.passedDoor == true and actorDistance and actorDistance > closeDistance)
                                then
                                    shouldClose = true
                                else
                                    entry.closeAfter = now + ACTOR_IN_PATH_RETRY_SECONDS
                                    if data and data.approachPos and (not entry.nextClearNudgeAt or now >= entry.nextClearNudgeAt) then
                                        entry.nextClearNudgeAt = now + 1.0
                                        npc:sendEvent('SitDownPleaseStartAIPackage', {
                                            type = "Travel",
                                            destPosition = data.approachPos,
                                            isRepeat = false,
                                            cancelOther = true,
                                            destinationTolerance = 70,
                                        })
                                        debugLog("sleep route door close delayed actor_in_path_nudged", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "target", tostring(data.approachPos))
                                    else
                                        debugLog("sleep route door close delayed actor_in_path", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId))
                                    end
                                end
                            end
                        end
                    end
                end

                if shouldClose then
                    if not closeRouteDoorEntry(npcId, entry, entry.closeReason or (data and "sleep_route_settled" or "sleep_route_cancelled")) then
                        table.insert(keep, entry)
                        shouldClose = false
                        keepEntry = false
                    end
                elseif keepEntry then
                    table.insert(keep, entry)
                end
            end
            if #keep > 0 then sleepRouteDoorsByNpc[npcId] = keep else sleepRouteDoorsByNpc[npcId] = nil end
        end
    end

    local pending = sleepRouteDoorsByNpc.__pendingRestarts
    if pending then
        for npcId, entry in pairs(pending) do
            local data = assignedActors()[npcId]
            local npc = entry and entry.npc
            local finalTarget = data and data.approachPos or entry and entry.finalTarget
            local wakeReturn = entry and entry.wakeReturn == true
            if not entry or (entry.due and now < entry.due) then
                -- not due yet
            elseif not wakeReturn and (not data or data.interactionType ~= "sleeping" or data.state == (ctx.states and ctx.states.interacting)) then
                pending[npcId] = nil
            elseif wakeReturn and data and data.interactionType == "sleeping" then
                pending[npcId] = nil
            elseif not isObjValid(npc) or not finalTarget then
                pending[npcId] = nil
            else
                local stage = entry.stage or "post_door"
                local dest = finalTarget
                local tolerance = wakeReturn and 90 or 70
                if stage == "clearance" and entry.clearanceWaypoint then
                    dest = entry.clearanceWaypoint
                    tolerance = 45
                    entry.stage = "clearance_wait"
                    entry.due = now + OPEN_DOOR_RESET_CLEAR_WAIT_SECONDS
                elseif stage == "clearance_wait" and entry.clearanceWaypoint then
                    if npc.position and (npc.position - entry.clearanceWaypoint):length() > 75 and (entry.count or 0) < 3 then
                        dest = entry.clearanceWaypoint
                        tolerance = 45
                        entry.stage = "clearance_wait"
                        entry.due = now + 0.5
                    else
                        dest = finalTarget
                        tolerance = wakeReturn and 90 or 70
                        entry.stage = "done"
                    end
                elseif stage == "post_door" and entry.postDoorWaypoint then
                    dest = entry.postDoorWaypoint
                    tolerance = 90
                    entry.stage = "approach"
                    entry.due = now + 0.45
                else
                    if entry.directFinal == true then
                        dest = finalTarget
                        tolerance = wakeReturn and 90 or 70
                        entry.stage = "done"
                    elseif stage == "approach"
                        and entry.postDoorWaypoint
                        and npc.position
                    then
                        local postDoorDistance = (npc.position - entry.postDoorWaypoint):length()
                        local pastDoor = trackedRouteDoorPassed(npcId, npc, wakeReturn and "wake_return_post_door_side" or "sleep_post_door_side")
                        local nearPostDoor = postDoorDistance <= 140
                        if nearPostDoor and markNpcPassedDoor(npcId, wakeReturn and "wake_return_post_door_waypoint" or "sleep_post_door_waypoint", npc) then
                            pastDoor = true
                        end
                        if entry.postDoorBestDistance == nil or postDoorDistance + POST_DOOR_PROGRESS_EPSILON < entry.postDoorBestDistance then
                            entry.postDoorBestDistance = postDoorDistance
                            entry.postDoorNoProgress = 0
                        else
                            entry.postDoorNoProgress = (entry.postDoorNoProgress or 0) + 1
                        end
                        entry.postDoorAttempts = (entry.postDoorAttempts or 0) + 1
                        if pastDoor
                            or nearPostDoor
                            or entry.postDoorAttempts >= POST_DOOR_FINAL_FALLBACK_ATTEMPTS
                            or entry.postDoorNoProgress >= POST_DOOR_FINAL_FALLBACK_NO_PROGRESS
                        then
                            dest = finalTarget
                            tolerance = wakeReturn and 90 or 70
                            entry.stage = "done"
                            debugLog("route_door_assist", npc.recordId or npc.id, "post_door_final_fallback", "pastDoor", tostring(pastDoor), "nearPostDoor", tostring(nearPostDoor), "attempts", tostring(entry.postDoorAttempts), "noProgress", tostring(entry.postDoorNoProgress), "postDoorDistance", tostring(postDoorDistance), "target", tostring(dest))
                        else
                            dest = entry.postDoorWaypoint
                            tolerance = 90
                            entry.stage = "approach"
                            entry.due = now + 0.45
                        end
                    end
                    if entry.stage ~= "approach" then entry.stage = "done" end
                end

                npc:sendEvent('SitDownPleaseStartAIPackage', {
                    type = "Travel",
                    destPosition = dest,
                    isRepeat = false,
                    cancelOther = true,
                    destinationTolerance = tolerance,
                })
                entry.count = (entry.count or 0) + 1
                if entry.stage == "done" or entry.count >= 5 then
                    pending[npcId] = nil
                end
                debugLog("route_door_assist", npc.recordId or npc.id, "delayed_repath", "stage", tostring(stage), "count", tostring(entry.count), "target", tostring(dest), "finalApproach", tostring(finalTarget))
                infoLog("door_route_retry", npc.recordId or npc.id, "stage", tostring(stage), "count", tostring(entry.count), "target", tostring(dest))
            end
        end
    end
end

local function trackedDoorForNpc(npcId, door)
    if not (npcId and door) then return nil end
    local list = sleepRouteDoorsByNpc[npcId]
    if type(list) ~= "table" then return nil end
    local doorId = doorObjectId(door)
    for _, entry in ipairs(list) do
        if sameTrackedDoor(entry, door, doorId) then return entry end
    end
    return nil
end

local function chooseWakeReturnDoor(npc, target)
    if not (isObjValid(npc) and npc.cell and npc.position and target and types and types.Door) then return nil end
    local okDoors, doors = pcall(function() return npc.cell:getAll(types.Door) end)
    if not (okDoors and doors) then return nil end

    local bestDoor, bestWaypoint, bestReason, bestScore
    local bestHardRejectReason, bestHardRejectScore
    for _, door in ipairs(doors) do
        if isObjValid(door) and door.cell == npc.cell and M.isClosedNonTeleport(door) then
            local okRoute, routeReason = routeAssist.doorOnRouteSegment(door, npc.position, target, {
                maxVertical = 160,
                maxLineDistance = WAKE_RETURN_MAX_LINE_DISTANCE,
                maxActorDistance = 900,
                maxTargetDistance = 1400,
                -- Wake returns have a concrete final origin. A door just past
                -- that origin should not create a waypoint behind the door.
                minSegmentT = WAKE_RETURN_MIN_SEGMENT_T,
                maxSegmentT = WAKE_RETURN_MAX_SEGMENT_T,
            })
            if okRoute then
                local waypoint = routeAssist.waypointPastDoor(door, npc.position, target, 155)
                local lineDist = routeAssist.distanceToSegment2d(door.position, npc.position, target)
                local actorDist = (door.position - npc.position):length()
                local targetDist = (door.position - target):length()
                local score = actorDist + (lineDist or 0) * 1.5 + targetDist * 0.05
                if wakeReturnDoorUseful(door, npc.position, target, waypoint) then
                    local canOpen, openReason = npcCanOpenDoor(door, npc)
                    if canOpen == true and (not bestScore or score < bestScore) then
                        bestDoor = door
                        bestWaypoint = waypoint
                        bestReason = openReason or routeReason
                        bestScore = score
                    elseif canOpen ~= true and M.isHardWakeReturnReject(openReason) and (not bestHardRejectScore or score < bestHardRejectScore) then
                        bestHardRejectReason = openReason
                        bestHardRejectScore = score
                    end
                end
            end
        end
    end
    if bestDoor then return bestDoor, bestWaypoint, bestReason, false end

    for _, door in ipairs(doors) do
        if isObjValid(door) and door.cell == npc.cell and M.isOpenNonTeleport(door) then
            local okRoute = routeAssist.doorOnRouteSegment(door, npc.position, target, {
                maxVertical = 180,
                maxLineDistance = WAKE_RETURN_MAX_LINE_DISTANCE,
                maxActorDistance = 900,
                maxTargetDistance = 1400,
                -- Match the closed-door pass: already-open doors beyond the
                -- final origin are not part of the wake-return route.
                minSegmentT = WAKE_RETURN_MIN_SEGMENT_T,
                maxSegmentT = WAKE_RETURN_MAX_SEGMENT_T,
            })
            if okRoute then
                local waypoint = routeAssist.waypointPastDoor(door, npc.position, target, 155)
                local lineDist = routeAssist.distanceToSegment2d(door.position, npc.position, target)
                local actorDist = (door.position - npc.position):length()
                local targetDist = (door.position - target):length()
                local score = actorDist + (lineDist or 0) * 1.5 + targetDist * 0.05
                if wakeReturnDoorUseful(door, npc.position, target, waypoint) and (not bestScore or score < bestScore) then
                    bestDoor = door
                    bestWaypoint = waypoint
                    bestReason = "wake_return_open_route_door"
                    bestScore = score
                end
            end
        end
    end
    if bestDoor then return bestDoor, bestWaypoint, bestReason, true end
    if bestHardRejectReason then return nil, nil, bestHardRejectReason, false end
    return nil, nil, nil, false
end

local function chooseWakeReturnWatchDoor(npc, target)
    if not (isObjValid(npc) and npc.cell and npc.position and target and types and types.Door) then return nil end
    local okDoors, doors = pcall(function() return npc.cell:getAll(types.Door) end)
    if not (okDoors and doors) then return nil end

    local bestDoor, bestWaypoint, bestReason, bestScore
    for _, door in ipairs(doors) do
        if isObjValid(door) and door.cell == npc.cell and M.isNonTeleportDoor(door) then
            local okRoute, routeReason = routeAssist.doorOnRouteSegment(door, npc.position, target, {
                maxVertical = 180,
                maxLineDistance = WAKE_RETURN_MAX_LINE_DISTANCE,
                maxActorDistance = 900,
                maxTargetDistance = 1400,
                minSegmentT = WAKE_RETURN_MIN_SEGMENT_T,
                maxSegmentT = WAKE_RETURN_MAX_SEGMENT_T,
            })
            if okRoute then
                local waypoint = routeAssist.waypointPastDoor(door, npc.position, target, 155)
                local lineDist = routeAssist.distanceToSegment2d(door.position, npc.position, target)
                local actorDist = (door.position - npc.position):length()
                local targetDist = (door.position - target):length()
                local score = actorDist + (lineDist or 0) * 1.5 + targetDist * 0.05
                if wakeReturnDoorUseful(door, npc.position, target, waypoint) and (not bestScore or score < bestScore) then
                    bestDoor = door
                    bestWaypoint = waypoint
                    bestReason = routeReason or "wake_return_route_door_watch"
                    bestScore = score
                end
            end
        end
    end
    return bestDoor, bestWaypoint, bestReason
end

function M.assistWakeReturn(npc, target, reason)
    if not (isObjValid(npc) and npc.id and npc.position and target) then return false, "missing_wake_return_context" end
    if (target - npc.position):length() < 100 then return false, "wake_return_target_near" end

    local npcId = npc.id
    local door, postDoorWaypoint, openReason, alreadyOpen = chooseWakeReturnDoor(npc, target)
    if not door then
        local watchDoor, watchWaypoint, watchReason = chooseWakeReturnWatchDoor(npc, target)
        if watchDoor then
            trackWakeReturnDoorWatch(npcId, npc, watchDoor, watchWaypoint, target, openReason or watchReason or reason or "wake_return_route_door_watch")
        end
        return false, openReason or "no_wake_return_route_door"
    end

    local now = core.getSimulationTime() or 0
    local existing = trackedDoorForNpc(npcId, door)
    if existing then
        existing.npc = npc
        existing.closeAfter = math.min(existing.closeAfter or (now + SHARED_DOOR_CLOSE_AFTER_SECONDS), now + SHARED_DOOR_CLOSE_AFTER_SECONDS)
        existing.postDoorWaypoint = postDoorWaypoint or existing.postDoorWaypoint
        existing.finalTarget = target
        existing.wakeReturn = true
        scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, target, reason or "wake_return_origin", true)
        return true, "wake_return_route_door_already_tracked"
    end

    if alreadyOpen == true then
        local sourceEntry, ownerNpcId = findTrackedDoorEntry(door)
        local inheritedWasLocked = sourceEntry and sourceEntry.wasLocked == true or false
        local inheritedLockLevel = sourceEntry and sourceEntry.lockLevel or nil
        if sourceEntry then
            local shareOk, shareReason, keyId = npcCanShareLockedDoor(sourceEntry, npc)
            if shareOk ~= true then
                infoLog("wake_return_open_door_share_rejected_locked", npc.recordId or npc.id, tostring(door.recordId or door.id), "owner", tostring(ownerNpcId), "reason", tostring(shareReason), "key", tostring(keyId))
                return false, shareReason or "locked_route_door_missing_key"
            end
        elseif isDoorLocked(door) then
            local canOpen, lockedReason = npcCanOpenDoor(door, npc)
            if canOpen ~= true then return false, lockedReason or "locked_route_door_missing_key" end
            inheritedWasLocked = true
            inheritedLockLevel = doorLockLevel(door)
        end

        local list = sleepRouteDoorsByNpc[npcId] or {}
        table.insert(list, {
            door = door,
            doorId = doorObjectId(door),
            doorRecordId = door.recordId,
            npc = npc,
            openedAt = sourceEntry and sourceEntry.openedAt or now,
            closeAfter = now + ADOPTED_OPEN_DOOR_CLOSE_AFTER_SECONDS,
            wasClosedBeforeAssist = sourceEntry and sourceEntry.wasClosedBeforeAssist == true or false,
            wasLocked = inheritedWasLocked,
            lockLevel = inheritedLockLevel,
        postDoorWaypoint = postDoorWaypoint,
        finalTarget = target,
        startPosition = npc.position,
        wakeReturn = true,
        sharedRouteDoor = true,
            safeCloseDistance = 135,
            maxOpenSeconds = 20,
        })
        sleepRouteDoorsByNpc[npcId] = list
        scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, target, reason or "wake_return_open_route_door", true)
        infoLog("wake_return_open_door_adopted_by_sdp", npc.recordId or npc.id, tostring(door.recordId or door.id), "owner", tostring(ownerNpcId), "reason", tostring(openReason))
        return true, openReason or "wake_return_open_route_door"
    end

    local wasLocked = isDoorLocked(door)
    local originalLockLevel = wasLocked and doorLockLevel(door) or nil
    if wasLocked == true then
        local lockable = routeAssist.lockableApi()
        if lockable and lockable.unlock then
            local okUnlock, unlockErr = pcall(lockable.unlock, door)
            if not okUnlock then
                debugLog("wake return route door unlock failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(unlockErr))
                return false, "unlock_failed"
            end
        else
            debugLog("wake return route door unlock unavailable", npc.recordId or npc.id, tostring(door.recordId or door.id))
            return false, "unlock_unavailable"
        end
    end

    local okOpen, openErr = pcall(types.Door.activateDoor, door, true)
    if not okOpen then
        if wasLocked == true then
            local lockable = routeAssist.lockableApi()
            if lockable and lockable.lock then pcall(lockable.lock, door, originalLockLevel or 1) end
        end
        debugLog("wake return route door open failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(openErr))
        return false, "open_failed"
    end

    local list = sleepRouteDoorsByNpc[npcId] or {}
    table.insert(list, {
        door = door,
        doorId = doorObjectId(door),
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = now,
        closeAfter = now + ROUTE_DOOR_CLOSE_AFTER_SECONDS,
        wasClosedBeforeAssist = true,
        wasLocked = wasLocked == true,
        lockLevel = originalLockLevel,
        postDoorWaypoint = postDoorWaypoint,
        finalTarget = target,
        startPosition = npc.position,
        wakeReturn = true,
        safeCloseDistance = 135,
        maxOpenSeconds = 20,
    })
    sleepRouteDoorsByNpc[npcId] = list
    scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, target, reason or "wake_return_origin", true)
    infoLog("wake_return_door_owned_by_sdp", npc.recordId or npc.id, tostring(door.recordId or door.id), "locked", tostring(wasLocked == true), "reason", tostring(openReason))
    debugLog("wake return route door assist", npc.recordId or npc.id, "opened", tostring(door.recordId or door.id), "target", tostring(target), "postDoorWaypoint", tostring(postDoorWaypoint), "reason", tostring(reason or "wake_return_origin"))
    return true, openReason or "wake_return_route_door_opened"
end

function M.onOpen(ev)
    local npc = ev and ev.npc
    local door = ev and ev.door
    local postDoorWaypoint = ev and ev.postDoorWaypoint
    local npcId = npc and npc.id
    local data = npcId and assignedActors()[npcId] or nil
    if not npcId then return end
    local evReason = tostring(ev and ev.reason or "")

    if evReason == "actor_opened_sleep_route_door"
        and isObjValid(door)
        and M.isOpenNonTeleport(door)
    then
        if not data or data.interactionType ~= "sleeping" then
            debugLog("route_door_assist", npc.recordId or npc.id, "missing_sleep_assignment", tostring(door and (door.recordId or door.id)), evReason)
            return
        end
        local passable, passReason = isActorOpenedSleepRouteDoor(door, npc, data)
        if passable ~= true then
            infoLog("door_actor_opened_adoption_rejected", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(passReason))
            debugLog("route_door_assist", npc.recordId or npc.id, "actor_opened_adoption_rejected", tostring(door and (door.recordId or door.id)), tostring(passReason))
            return
        end
        if not trackAdoptedOpenDoorUse(npcId, npc, door, postDoorWaypoint) then return end
        data.sleepRouteNeedsDoorAssist = true
        if data.approachPos then
            scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, data.approachPos, evReason)
        end
        infoLog("door_actor_opened_adopted_by_sdp", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "postDoorWaypoint", tostring(postDoorWaypoint))
        debugLog("route_door_assist", npc.recordId or npc.id, "actor_opened_adopted", tostring(door and (door.recordId or door.id)), "postDoorWaypoint", tostring(postDoorWaypoint))
        return
    end

    if evReason == "already_open_collision_reset"
        and isObjValid(door)
        and M.isOpenNonTeleport(door)
    then
        if not data or data.interactionType ~= "sleeping" then
            debugLog("route_door_assist", npc.recordId or npc.id, "missing_sleep_assignment", tostring(door and (door.recordId or door.id)), tostring(ev and ev.reason))
            return
        end
        local passable, passReason = isNonTeleportRouteDoor(door, npc, data)
        if passable ~= true then
            infoLog("door_open_blocker_reset_rejected", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(passReason))
            debugLog("route_door_assist", npc.recordId or npc.id, "open_blocker_reset_rejected", tostring(door and (door.recordId or door.id)), tostring(passReason))
            return
        end
        local trackedEntry, ownerNpcId = findTrackedDoorEntry(door)
        if trackedEntry and tostring(ownerNpcId) ~= tostring(npcId) then
            infoLog("door_open_blocker_reset_shared_user", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "owner", tostring(ownerNpcId))
            debugLog("route_door_assist", npc.recordId or npc.id, "open_blocker_reset_shared_user", tostring(door and (door.recordId or door.id)), tostring(ownerNpcId))
        end
        local okClose, closeErr = pcall(types.Door.activateDoor, door, false)
        if not okClose then
            debugLog("route_door_assist", npc.recordId or npc.id, "open_blocker_reset_close_failed", tostring(door and (door.recordId or door.id)), tostring(closeErr))
            return
        end
        local finalTarget = data.approachPos
        local clearanceWaypoint = finalTarget and sameSideDoorClearancePoint({
            door = door,
            resetClearDistance = OPEN_DOOR_RESET_APPROACH_DISTANCE,
        }, npc, finalTarget) or nil
        infoLog("door_open_blocker_reset_closed", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(ev.reason))
        debugLog("route_door_assist", npc.recordId or npc.id, "open_blocker_reset_closed", tostring(door and (door.recordId or door.id)), "postDoorWaypoint", tostring(postDoorWaypoint), "clearance", tostring(clearanceWaypoint))
        trackResetClosedDoorWatch(npcId, npc, door, postDoorWaypoint, finalTarget, "already_open_collision_reset")
        if finalTarget then
            scheduleRouteRestart(npcId, npc, nil, ROUTE_RESTART_DELAY_SECONDS, finalTarget, "already_open_collision_reset", false, {
                clearanceWaypoint = clearanceWaypoint,
            })
        end
        return
    end

    if evReason == "already_open_collision_suspected"
        and isObjValid(door)
        and M.isOpenNonTeleport(door)
    then
        if not data or data.interactionType ~= "sleeping" then
            debugLog("route_door_assist", npc.recordId or npc.id, "missing_sleep_assignment", tostring(door and (door.recordId or door.id)), tostring(ev and ev.reason))
            return
        end
        local passable, passReason = isNonTeleportRouteDoor(door, npc, data)
        if passable ~= true then
            infoLog("door_already_open_adoption_rejected", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(passReason))
            debugLog("route_door_assist", npc.recordId or npc.id, "already_open_adoption_rejected", tostring(door and (door.recordId or door.id)), tostring(passReason))
            return
        end
        if not trackAdoptedOpenDoorUse(npcId, npc, door, postDoorWaypoint) then return end
        if data and data.interactionType == "sleeping" then
            data.sleepRouteNeedsDoorAssist = true
            if data.approachPos then
                scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, data.approachPos, evReason)
            end
        end
        infoLog("door_already_open_adopted_by_sdp", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(ev.reason))
        debugLog("route_door_assist", npc.recordId or npc.id, "adopted_already_open", tostring(door and (door.recordId or door.id)), tostring(ev.reason))
        return
    end

    if not data or data.interactionType ~= "sleeping" then
        debugLog("route_door_assist", npc.recordId or npc.id, "missing_sleep_assignment", tostring(door and (door.recordId or door.id)), tostring(ev and ev.reason))
        return
    end

    local ok, reason = canOpenRouteDoor(door, npc, data)
    if not ok then
        if tostring(reason) == "not_closed" then
            local trackedEntry, ownerNpcId = findTrackedDoorEntry(door)
            local restartAllowed = true
            if trackedEntry then
                local shareOk, shareReason, keyId = npcCanShareLockedDoor(trackedEntry, npc)
                if shareOk then
                    data.sleepRouteNeedsDoorAssist = true
                    trackSharedDoorUse(npcId, npc, door, trackedEntry, postDoorWaypoint)
                    infoLog("door_already_open_owned_by_sdp", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "owner", tostring(ownerNpcId))
                    infoLog("door_shared_by_sdp", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "owner", tostring(ownerNpcId), "locked", tostring(trackedEntry.wasLocked == true))
                else
                    restartAllowed = false
                    infoLog("door_shared_rejected_locked", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "owner", tostring(ownerNpcId), "reason", tostring(shareReason), "key", tostring(keyId))
                end
            else
                if tostring(ev and ev.reason or "") == "already_open_collision_suspected" and trackAdoptedOpenDoorUse(npcId, npc, door, postDoorWaypoint) then
                    data.sleepRouteNeedsDoorAssist = true
                    infoLog("door_already_open_adopted_by_sdp", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", tostring(ev.reason))
                else
                    infoLog("door_already_open", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)))
                    infoLog("door_close_skipped_not_owned", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", "already_open_not_owned_by_sdp")
                end
            end
            if data and data.approachPos and restartAllowed == true then
                scheduleRouteRestart(npcId, npc, postDoorWaypoint, ROUTE_RESTART_DELAY_SECONDS, data.approachPos, "already_open_route_door")
            end
            debugLog("route_door_assist", npc.recordId or npc.id, trackedEntry and "shared_open_door" or "already_open_not_owned", tostring(door and (door.recordId or door.id)), tostring(reason))
            return
        end
        if tostring(reason) == "door_too_far_from_route" or tostring(reason) == "door_not_between_actor_and_bed" then
            data.sleepRouteNeedsDoorAssist = false
            notifyLocalRouteDoorRejected(npc, door, reason, data)
        end
        debugLog("route_door_assist", npc.recordId or npc.id, "rejected", tostring(door and (door.recordId or door.id)), tostring(reason))
        return
    end
    local wasLocked = isDoorLocked(door)
    local originalLockLevel = wasLocked and doorLockLevel(door) or nil
    infoLog("door_initial_state", npc.recordId or npc.id, tostring(door.recordId or door.id), "closed", "true", "locked", tostring(wasLocked == true))

    local list = sleepRouteDoorsByNpc[npcId] or {}
    for _, entry in ipairs(list) do
        if entry.door == door or entry.doorId == doorObjectId(door) then
            local now = core.getSimulationTime() or 0
            entry.closeAfter = math.min(entry.closeAfter or (now + SHARED_DOOR_CLOSE_AFTER_SECONDS), now + SHARED_DOOR_CLOSE_AFTER_SECONDS)
            entry.postDoorWaypoint = postDoorWaypoint or entry.postDoorWaypoint
            entry.startPosition = entry.startPosition or npc.position
            entry.usePoint = entry.usePoint or (ev and ev.usePoint)
            entry.directFinalAfterOpen = tostring(ev and ev.reason or "") == "sleep_route_assist"
            if data and data.approachPos then
                local directFinal = tostring(ev and ev.reason or "") == "sleep_route_assist"
                scheduleRouteRestart(npcId, npc, postDoorWaypoint, directFinal and ROUTE_DOOR_POST_OPEN_REPATH_DELAY_SECONDS or ROUTE_RESTART_DELAY_SECONDS, data.approachPos, tostring(ev and ev.reason or "sleep_route_assist"), false, {
                    directFinal = directFinal,
                })
            end
            return
        end
    end

    if wasLocked == true then
        local lockable = routeAssist.lockableApi()
        if lockable and lockable.unlock then
            local okUnlock, unlockErr = pcall(lockable.unlock, door)
            if not okUnlock then
                debugLog("sleep route door unlock failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(unlockErr))
                return
            end
        else
            debugLog("sleep route door unlock unavailable", npc.recordId or npc.id, tostring(door.recordId or door.id))
            return
        end
    end

    local okOpen, err = pcall(types.Door.activateDoor, door, true)
    if not okOpen then
        if wasLocked == true then
            local lockable = routeAssist.lockableApi()
            if lockable and lockable.lock then pcall(lockable.lock, door, originalLockLevel or 1) end
        end
        debugLog("sleep route door open failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(err))
        return
    end
    table.insert(list, {
        door = door,
        doorId = doorObjectId(door),
        doorRecordId = door.recordId,
        npc = npc,
        openedAt = core.getSimulationTime() or 0,
        closeAfter = (core.getSimulationTime() or 0) + ROUTE_DOOR_CLOSE_AFTER_SECONDS,
        wasClosedBeforeAssist = true,
        wasLocked = wasLocked == true,
        lockLevel = originalLockLevel,
        postDoorWaypoint = postDoorWaypoint,
        startPosition = npc.position,
        usePoint = ev and ev.usePoint,
        directFinalAfterOpen = tostring(ev and ev.reason or "") == "sleep_route_assist",
        safeCloseDistance = 135,
        maxOpenSeconds = 20,
    })
    data.sleepRouteNeedsDoorAssist = true
    sleepRouteDoorsByNpc[npcId] = list
    infoLog("door_owned_by_sdp", npc.recordId or npc.id, tostring(door.recordId or door.id), "locked", tostring(wasLocked == true))
    if data and data.approachPos then
        local directFinal = tostring(ev and ev.reason or "") == "sleep_route_assist"
        scheduleRouteRestart(npcId, npc, postDoorWaypoint, directFinal and ROUTE_DOOR_POST_OPEN_REPATH_DELAY_SECONDS or ROUTE_RESTART_DELAY_SECONDS, data.approachPos, tostring(ev and ev.reason or "sleep_route_assist"), false, {
            directFinal = directFinal,
        })
    end
    debugLog("route_door_assist", npc.recordId or npc.id, "opened", tostring(door.recordId or door.id), tostring(ev and ev.reason or "route_assist"), "usePoint", tostring(ev and ev.usePoint), "postDoorWaypoint", tostring(postDoorWaypoint))
    infoLog("post_door_waypoint_chosen", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(postDoorWaypoint))
end

return M
