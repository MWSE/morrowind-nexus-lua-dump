-- FurnitureRouteScorer.lua
-- Local-script-only navmesh route ranking and key-aware locked-door rejection.
-- Used by SittingLogic and SleepLogic; requires openmw.nearby (not available in globals).

local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")

local FurnitureRouteScorer = {}

local FINAL_PLACEMENT_WEIGHT = 0.15
local NAV_SNAP_MAX_DELTA = 150
local NAV_DEST_MAX_DELTA = 145
local FIND_PATH_DEST_TOLERANCE = 48
local ROUTE_DOOR_LINE_MAX_DIST = 150
local ROUTE_DOOR_VERTICAL_MAX_DIST = 180
local ROUTE_DOOR_ENDPOINT_PADDING = 0.08

-- =============================================================================
-- Lockable / door helpers (ported from Sit Down Please routeDoors / interactionSeeker)
-- =============================================================================

local function lockableApi()
    return (types and (types.Lockable or types.LOCKABLE))
        or (types and types.Door and types.Door.baseType)
end

local function lockApiAvailable()
    local lockable = lockableApi()
    return lockable and lockable.isLocked ~= nil
end

local function isDoorLocked(door)
    if not lockApiAvailable() then return false end
    local lockable = lockableApi()
    local ok, locked = pcall(lockable.isLocked, door)
    if ok then return locked == true end
    return true
end

local function actorHasDoorKey(actor, door)
    if not (actor and door) then return false, nil, "missing_actor_or_door" end
    local lockable = lockableApi()
    if not (lockable and lockable.getKeyRecord) then return false, nil, "key_api_unavailable" end

    local okKey, keyRecord = pcall(lockable.getKeyRecord, door)
    if not (okKey and keyRecord) then return false, nil, "unknown_key" end
    local keyId = keyRecord.id or keyRecord.recordId or tostring(keyRecord)
    if not keyId or keyId == "" then return false, nil, "unknown_key" end

    local okInv, inventory = pcall(function()
        if types and types.Actor and types.Actor.inventory then
            return types.Actor.inventory(actor)
        end
        return actor:inventory()
    end)
    if not (okInv and inventory) then return false, keyId, "inventory_unavailable" end
    if inventory.countOf then
        local okCount, count = pcall(inventory.countOf, inventory, keyId)
        if okCount then return (tonumber(count) or 0) > 0, keyId, "countOf" end
    end
    if inventory.find then
        local okFind, found = pcall(inventory.find, inventory, keyId)
        return okFind and found ~= nil, keyId, "find"
    end
    return false, keyId, "inventory_key_lookup_unavailable"
end

local function npcCanOpenDoor(door, actor)
    if not isDoorLocked(door) then return true, "unlocked" end
    local hasKey, _, keyReason = actorHasDoorKey(actor, door)
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        return false, "locked_route_door_unknown_key"
    end
    if hasKey then return true, "locked_route_door_actor_has_key" end
    return false, "locked_route_door_missing_key"
end

local function doorIsNonTeleportInstance(door)
    if not (door and types and types.Door and types.Door.objectIsInstance) then return false end
    local okInstance, isDoor = pcall(types.Door.objectIsInstance, door)
    if not (okInstance and isDoor == true) then return false end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    if okTeleport and isTeleport == true then return false end
    return true
end

local function routeDoorIsClosedNonTeleport(door)
    if not doorIsNonTeleportInstance(door) then return false end
    local okClosed, closed = pcall(types.Door.isClosed, door)
    return okClosed and closed == true
end

local function routeDoorOpenability(door, actor)
    if not routeDoorIsClosedNonTeleport(door) then return false, "not_closed_route_door" end
    if not isDoorLocked(door) then return true, "unlocked" end
    return npcCanOpenDoor(door, actor)
end

-- =============================================================================
-- Navmesh / path helpers
-- =============================================================================

local function actorAgentBounds(actor)
    if types and types.Actor and types.Actor.getPathfindingAgentBounds then
        local okBounds, bounds = pcall(types.Actor.getPathfindingAgentBounds, actor)
        if okBounds and bounds then return bounds end
    end
    return nil
end

local function pathStatusIsUsable(status)
    if status == nil then return false end
    if nearby and nearby.FIND_PATH_STATUS then
        if status == nearby.FIND_PATH_STATUS.Success then return true end
        if status == nearby.FIND_PATH_STATUS.PartialPath then return true end
    end
    local label = tostring(status)
    return label:find("Success", 1, true) ~= nil
        or label:find("PartialPath", 1, true) ~= nil
end

local function pathStatusIsSuccess(status)
    if status == nil then return false end
    if nearby and nearby.FIND_PATH_STATUS and status == nearby.FIND_PATH_STATUS.Success then
        return true
    end
    local label = tostring(status)
    return label == "Success" or label == "success" or label:find("Success", 1, true) ~= nil
end

local function navPathLength(path)
    if not path or #path < 2 then return nil end
    local total = 0
    for i = 1, #path - 1 do
        total = total + (path[i + 1] - path[i]):length()
    end
    return total
end

local function distanceToSegment2d(p, a, b)
    if not (p and a and b) then return math.huge, nil end
    local ax, ay = a.x or 0, a.y or 0
    local bx, by = b.x or 0, b.y or 0
    local px, py = p.x or 0, p.y or 0
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 <= 1 then
        return math.sqrt((px - ax) ^ 2 + (py - ay) ^ 2), 0
    end
    local t = ((px - ax) * dx + (py - ay) * dy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local cx, cy = ax + t * dx, ay + t * dy
    return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2), t
end

local function nearestWalkNavmeshPosition(pos, includeFlags, maxDelta)
    if not (pos and nearby and nearby.findNearestNavMeshPosition) then
        return pos, "unavailable", 0
    end
    local options = {
        includeFlags = includeFlags,
        searchAreaHalfExtents = util.vector3(150, 150, 120),
    }
    local ok, navPos = pcall(nearby.findNearestNavMeshPosition, pos, options)
    if not (ok and navPos) then return nil, "no_nearest_navmesh", math.huge end
    local delta = (navPos - pos):length()
    if delta > (maxDelta or NAV_SNAP_MAX_DELTA) then
        return nil, "approach_too_far_from_navmesh", delta
    end
    return navPos, "snapped", delta
end

local function pathStatusWithFlags(actor, dest, includeFlags)
    if not (actor and nearby and nearby.findPath and dest) then return nil, nil end
    local flags = nearby.NAVIGATOR_FLAGS
    if not flags then return nil, nil end

    local options = {
        includeFlags = includeFlags,
        destinationTolerance = FIND_PATH_DEST_TOLERANCE,
    }
    local bounds = actorAgentBounds(actor)
    if bounds then options.agentBounds = bounds end

    local source = actor.position
    local walkFlags = (flags.Walk or 0) + (flags.UsePathgrid or 0)
    local navSource = nearestWalkNavmeshPosition(source, walkFlags, NAV_SNAP_MAX_DELTA)
    if navSource then source = navSource end

    local navDest = nearestWalkNavmeshPosition(dest, includeFlags, NAV_DEST_MAX_DELTA)
    if not navDest then return nil, nil end

    local ok, status, path = pcall(nearby.findPath, source, navDest, options)
    if ok then return status, path end
    return nil, nil
end

local function scanPathForClosedRouteDoor(path, actor, includeBlockedDoor)
    if not (path and #path >= 2 and nearby and nearby.COLLISION_TYPE and nearby.castRay) then
        return nil
    end
    local lastDoor = nil
    for i = 1, #path - 1 do
        local ok, result = pcall(function()
            local res = nearby.castRay(path[i] + util.vector3(0, 0, 54), path[i + 1] + util.vector3(0, 0, 54), {
                collisionType = nearby.COLLISION_TYPE.Door,
                ignore = lastDoor,
            })
            if res and res.hitObject then return res end
            -- Try in reverse to handle start-inside-collision issues
            return nearby.castRay(path[i + 1] + util.vector3(0, 0, 54), path[i] + util.vector3(0, 0, 54), {
                collisionType = nearby.COLLISION_TYPE.Door,
                ignore = lastDoor,
            })
        end)
        local door = ok and result and result.hitObject or nil
        if door and routeDoorIsClosedNonTeleport(door) then
            local canOpen, openReason = routeDoorOpenability(door, actor)
            if canOpen or includeBlockedDoor == true then
                return door, canOpen, openReason
            end
        end
        lastDoor = door
    end
    return nil
end

local function firstClosedRouteDoorOnPath(actor, dest, includeBlockedDoor)
    if not (actor and dest and nearby and nearby.NAVIGATOR_FLAGS) then return nil end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not (walk and openDoor) then return nil end

    local baseFlags = walk + openDoor + (flags.UsePathgrid or 0)
    local status, path = pathStatusWithFlags(actor, dest, baseFlags)
    if not pathStatusIsSuccess(status) or not path then return nil end
    return scanPathForClosedRouteDoor(path, actor, includeBlockedDoor)
end

local function findBlockingDoorOnSegment(actor, fromPos, toPos)
    if not (actor and fromPos and toPos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then
        return nil
    end
    local ok, result = pcall(function()
        local res = nearby.castRay(
            fromPos + util.vector3(0, 0, 54),
            toPos + util.vector3(0, 0, 54),
            { collisionType = nearby.COLLISION_TYPE.Door }
        )
        if res and res.hitObject then return res end
        -- Try in reverse to handle start-inside-collision issues
        return nearby.castRay(
            toPos + util.vector3(0, 0, 54),
            fromPos + util.vector3(0, 0, 54),
            { collisionType = nearby.COLLISION_TYPE.Door }
        )
    end)
    local door = ok and result and result.hitObject or nil
    if door and routeDoorIsClosedNonTeleport(door) then
        local canOpen, openReason = routeDoorOpenability(door, actor)
        return door, canOpen, openReason
    end
    return nil
end

local function findNearbyBlockingDoorOnRoute(actor, fromPos, toPos)
    if not (actor and fromPos and toPos and nearby and nearby.doors) then return nil end
    local bestDoor, bestScore, bestCanOpen, bestReason = nil, nil, nil, nil
    local routeLen = (toPos - fromPos):length()

    for _, door in ipairs(nearby.doors) do
        if routeDoorIsClosedNonTeleport(door) and door.position then
            local lineDist, t = distanceToSegment2d(door.position, fromPos, toPos)
            local vertical = math.abs((door.position.z or 0) - (fromPos.z or 0))
            local actorDist = (door.position - fromPos):length()
            local targetDist = (door.position - toPos):length()
            if lineDist <= ROUTE_DOOR_LINE_MAX_DIST
                    and vertical <= ROUTE_DOOR_VERTICAL_MAX_DIST
                    and t and t > ROUTE_DOOR_ENDPOINT_PADDING and t < (1 - ROUTE_DOOR_ENDPOINT_PADDING)
                    and actorDist <= math.max(300, routeLen + 180)
                    and targetDist <= math.max(300, routeLen + 180) then
                local canOpen, openReason = routeDoorOpenability(door, actor)
                local score = lineDist + math.abs(t - 0.5) * 60 + actorDist * 0.02
                if not bestScore or score < bestScore then
                    bestDoor, bestScore, bestCanOpen, bestReason = door, score, canOpen, openReason
                end
            end
        end
    end

    return bestDoor, bestCanOpen, bestReason
end

local function rejectReasonFromDoorOpenability(openReason)
    local reasonText = tostring(openReason or "")
    if reasonText:find("unknown_key", 1, true) then
        return "locked_route_door_unknown_key"
    end
    return "locked_route_door_missing_key"
end

--- Returns a rejection reason string, or nil if the actor can reach dest.
function FurnitureRouteScorer.routeAccessRejectReason(actor, dest)
    if not lockApiAvailable() then return nil end
    if not (actor and dest and nearby and nearby.NAVIGATOR_FLAGS and nearby.findPath) then
        return nil
    end

    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not walk then return nil end

    local baseFlags = walk + (flags.UsePathgrid or 0)
    local closedStatus, closedPath = pathStatusWithFlags(actor, dest, baseFlags)
    local openStatus, openPath = nil, nil
    if openDoor then
        openStatus, openPath = pathStatusWithFlags(actor, dest, baseFlags + openDoor)
    end
    local closedOk = pathStatusIsSuccess(closedStatus)
    local openOk = pathStatusIsSuccess(openStatus)

    -- SDP case: route only works when door areas are allowed on the navmesh.
    if not closedOk and openOk then
        local routeDoor, canOpen, openReason = firstClosedRouteDoorOnPath(actor, dest, true)
        if routeDoor and canOpen ~= true then
            return rejectReasonFromDoorOpenability(openReason)
        end
        local nearbyDoor, nearbyCanOpen, nearbyReason = findNearbyBlockingDoorOnRoute(actor, actor.position, dest)
        if nearbyDoor and nearbyCanOpen ~= true then
            return rejectReasonFromDoorOpenability(nearbyReason)
        end
        local lineDoor, lineCanOpen, lineReason = findBlockingDoorOnSegment(actor, actor.position, dest)
        if lineDoor and lineCanOpen ~= true then
            return rejectReasonFromDoorOpenability(lineReason)
        end
        return nil
    end

    -- Closed-door path exists but may still cross a shut locked door (common in interiors).
    if closedOk and closedPath then
        local routeDoor, canOpen, openReason = scanPathForClosedRouteDoor(closedPath, actor, true)
        if routeDoor and canOpen ~= true then
            return rejectReasonFromDoorOpenability(openReason)
        end
    end

    -- Direct segment: catches cases navmesh connects rooms but travel line hits the door.
    local segDoor, segCanOpen, segReason = findBlockingDoorOnSegment(actor, actor.position, dest)
    if segDoor and segCanOpen ~= true then
        return rejectReasonFromDoorOpenability(segReason)
    end

    -- Path segment raycasts can miss a door if the path points skirt the door
    -- collision. Scan loaded nearby doors as a geometric fallback.
    local nearbyDoor, nearbyCanOpen, nearbyReason = findNearbyBlockingDoorOnRoute(actor, actor.position, dest)
    if nearbyDoor and nearbyCanOpen ~= true then
        return rejectReasonFromDoorOpenability(nearbyReason)
    end

    return nil
end

local function lockedRouteRejectReason(actor, dest)
    return FurnitureRouteScorer.routeAccessRejectReason(actor, dest)
end

local function debugLog(...)
    if ScheduleConfig.DEBUG_MODE then
        print(string.format("[FurnitureRouteScorer] %s", string.format(...)))
    end
end

-- =============================================================================
-- Public API
-- =============================================================================

--- Rank furniture candidates by navmesh route length (lower is better).
--- candidates: { object, approachPos?, roughDist?, ... }
--- Returns ranked list (best first), usedNavmesh (bool).
function FurnitureRouteScorer.rank(actor, candidates, opts)
    opts = opts or {}
    if not candidates or #candidates == 0 then
        return {}, false
    end

    if ScheduleConfig.NAVMESH_RANKING_ENABLED == false then
        return candidates, false
    end

    if not (actor and nearby and nearby.findPath and nearby.NAVIGATOR_FLAGS) then
        return candidates, false
    end

    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not walk then return candidates, false end

    local baseFlags = walk + (flags.UsePathgrid or 0)
    local openFlags = openDoor and (baseFlags + openDoor) or baseFlags
    local scored = {}

    for _, candidate in ipairs(candidates) do
        local obj = candidate.object
        if obj then
            local dest = candidate.approachPos or obj.position
            local lockReason = FurnitureRouteScorer.routeAccessRejectReason(actor, dest)
            if lockReason then
                debugLog("reject npc=%s object=%s reason=%s",
                    tostring(actor.recordId), tostring(obj.recordId), lockReason)
            else
                local closedStatus, closedPath = pathStatusWithFlags(actor, dest, baseFlags)
                local openStatus, openPath = pathStatusWithFlags(actor, dest, openFlags)
                local routeLen = nil
                if pathStatusIsUsable(closedStatus) and closedPath then
                    routeLen = navPathLength(closedPath)
                elseif pathStatusIsUsable(openStatus) and openPath then
                    routeLen = navPathLength(openPath)
                end
                if routeLen then
                    local finalDist = 0
                    if candidate.approachPos and obj.position then
                        finalDist = (candidate.approachPos - obj.position):length()
                    end
                    local score = routeLen + finalDist * FINAL_PLACEMENT_WEIGHT
                    table.insert(scored, {
                        candidate = candidate,
                        score = score,
                        routeLength = routeLen,
                    })
                end
            end
        end
    end

    if #scored > 0 then
        table.sort(scored, function(a, b) return a.score < b.score end)
        local ranked = {}
        for _, entry in ipairs(scored) do
            table.insert(ranked, entry.candidate)
        end
        return ranked, true
    end

    return candidates, false
end

return FurnitureRouteScorer
