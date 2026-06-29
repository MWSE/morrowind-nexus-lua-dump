-- interactions/sleeping/approachBarrier.lua
---@omw-context local
-- Validates the short leg from a sleep approach point to the actual bed pose.

local nearby = require('openmw.nearby')
local util = require('openmw.util')
local routeAssist = require('scripts/sitDownPlease/assignment/routeAssist')

local M = {}

local function rayBlockedBetween(from, to, allowance)
    if not (from and to and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return false end
    local fullDist = (to - from):length()
    if fullDist <= 1 then return false end
    local ok, result = pcall(function()
        return nearby.castRay(from, to, {
            collisionType = nearby.COLLISION_TYPE.World,
            radius = 0,
        })
    end)
    if not (ok and result and result.hit and result.hitPos) then return false end
    local hitDist = (result.hitPos - from):length()
    return hitDist < math.max(24, fullDist - (allowance or 28))
end

local function closedDoorBetween(from, to, ignore)
    if not (from and to and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return nil end
    local ok, result = pcall(function()
        return nearby.castRay(from, to, {
            collisionType = nearby.COLLISION_TYPE.Door,
            radius = 0,
            ignore = ignore,
        })
    end)
    local door = ok and result and result.hitObject or nil
    if door and routeAssist.isClosedNonTeleport(door) then return door end
    return nil
end

local function routeDoorRejectReason(detail)
    local text = tostring(detail or "")
    if text:find("trapped_route_door", 1, true) then return "trapped_route_door" end
    if text:find("locked_route_door", 1, true) then return "locked_route_door" end
    return "blocked_route_door"
end

function M.unopenableRouteDoorOnPath(ctx, dest)
    if not (ctx and ctx.firstClosedRouteDoorOnPath and dest) then return false, nil, nil, nil, nil end
    local door, waypoint, canOpen, openReason = ctx.firstClosedRouteDoorOnPath(dest, true)
    if door and canOpen ~= true then
        return true, routeDoorRejectReason(openReason), door, openReason, waypoint
    end
    return false, nil, door, openReason, waypoint
end

function M.blockedBetween(pos, finalPos, npc, options)
    options = options or {}
    if not (pos and finalPos) then return false, nil, nil, nil end

    local lowClearance = pos + util.vector3(0, 0, 120)
    local lowTarget = finalPos + util.vector3(0, 0, 120)
    local highClearance = pos + util.vector3(0, 0, 170)
    local highTarget = finalPos + util.vector3(0, 0, 170)

    local lowDoor = closedDoorBetween(lowClearance, lowTarget)
    local highDoor = closedDoorBetween(highClearance, highTarget, lowDoor)
    local routeDoor = lowDoor or highDoor
    if routeDoor then
        local canOpen, openReason = routeAssist.openability(routeDoor, npc, {
            debugLog = options.debugLog,
            logPrefix = "route_door_assist",
        })
        if canOpen ~= true then
            return true, routeDoorRejectReason(openReason), routeDoor, openReason
        end
    end

    if rayBlockedBetween(lowClearance, lowTarget, 42)
        and rayBlockedBetween(highClearance, highTarget, 42)
    then
        return true, "blocked_by_wall", nil, nil
    end

    return false, nil, nil, nil
end

return M
