-- assignment/routeAssist.lua
---@omw-context all
-- Shared same-cell route-door primitives. Lifecycle ownership stays with the
-- caller so sleep, sitting, stations, and return paths can keep separate policy.

local types = require('openmw.types')
local util = require('openmw.util')

local M = {}

local function noop(...)
end

function M.vectorLength2d(v)
    if not v then return 0 end
    return math.sqrt((v.x or 0) * (v.x or 0) + (v.y or 0) * (v.y or 0))
end

function M.distanceToSegment2d(p, a, b)
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

function M.segmentProjection2d(p, a, b)
    if not (p and a and b) then return nil end
    local ax, ay = a.x or 0, a.y or 0
    local bx, by = b.x or 0, b.y or 0
    local px, py = p.x or 0, p.y or 0
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 <= 1 then return 0 end
    return ((px - ax) * dx + (py - ay) * dy) / len2
end

function M.doorObjectId(door)
    return door and (door.id or door.recordId) or nil
end

function M.lockableApi()
    return (types and types.Door and types.Door.baseType) or (types and types.Lockable)
end

function M.isDoorLocked(door)
    if not (door and types and types.Door) then return true end
    local lockable = M.lockableApi()
    if lockable and lockable.isLocked then
        local ok, locked = pcall(lockable.isLocked, door)
        if ok then return locked == true end
    end
    return true
end

function M.doorLockLevel(door)
    local lockable = M.lockableApi()
    if lockable and lockable.getLockLevel then
        local ok, level = pcall(lockable.getLockLevel, door)
        if ok and tonumber(level) then return tonumber(level) end
    end
    return 1
end

function M.isDoorTrapped(door)
    local lockable = M.lockableApi()
    if lockable and lockable.getTrapSpell then
        local ok, trap = pcall(lockable.getTrapSpell, door)
        if ok and trap ~= nil and trap ~= "" then return true, trap end
    end
    return false, nil
end

function M.actorHasDoorKey(npc, door)
    if not (npc and door) then return false, nil, "missing_actor_or_door" end
    local lockable = M.lockableApi()
    if not (lockable and lockable.getKeyRecord) then return false, nil, "key_api_unavailable" end
    local okKey, keyRecord = pcall(lockable.getKeyRecord, door)
    if not (okKey and keyRecord) then return false, nil, "unknown_key" end
    local keyId = keyRecord.id or keyRecord["recordId"] or tostring(keyRecord)
    if not keyId or keyId == "" then return false, nil, "unknown_key" end
    local okInv, inventory = pcall(function()
        if types and types.Actor and types.Actor.inventory then return types.Actor.inventory(npc) end
        return npc:inventory()
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

function M.npcCanOpenDoor(door, npc, options)
    options = options or {}
    local debugLog = options.debugLog or noop
    local prefix = options.logPrefix or "route_door_assist"
    local actorLabel = npc and (npc.recordId or npc.id) or "<npc>"
    local doorLabel = door and (door.recordId or door.id) or "<door>"
    local trapped, trap = M.isDoorTrapped(door)
    if trapped == true then
        debugLog(prefix, actorLabel, "trapped_route_door_rejected", tostring(doorLabel), "trap", tostring(trap and trap.id or trap))
        return false, "trapped_route_door"
    end
    if not M.isDoorLocked(door) then return true, "unlocked" end
    if options.allowLockedDoorOverride == true then
        debugLog(prefix, actorLabel, "locked_route_door_debug_override", tostring(doorLabel))
        return true, "locked_route_door_debug_override"
    end
    local hasKey, keyId, keyReason = M.actorHasDoorKey(npc, door)
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        debugLog(prefix, actorLabel, "locked_route_door_unknown_key", tostring(doorLabel), "key", tostring(keyId))
        return false, "locked_route_door_unknown_key"
    end
    if hasKey then
        debugLog(prefix, actorLabel, "locked_route_door_actor_has_key", tostring(doorLabel), "key", tostring(keyId))
        return true, "locked_route_door_actor_has_key"
    end
    debugLog(prefix, actorLabel, "locked_route_door_missing_key", tostring(doorLabel), "key", tostring(keyId))
    return false, "locked_route_door_missing_key"
end

function M.isNonTeleportDoor(door)
    if not (door and types and types.Door and types.Door.objectIsInstance) then return false end
    local okInstance, isDoor = pcall(types.Door.objectIsInstance, door)
    if not (okInstance and isDoor == true) then return false end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    if okTeleport and isTeleport == true then return false end
    return true
end

function M.isTeleportDoor(door)
    if not (door and types and types.Door and types.Door.objectIsInstance) then return false end
    local okInstance, isDoor = pcall(types.Door.objectIsInstance, door)
    if not (okInstance and isDoor == true) then return false end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    return okTeleport and isTeleport == true
end

function M.teleportDoorRouteReason(door, npc)
    if not M.isTeleportDoor(door) then return nil end
    if M.isDoorLocked(door) then
        local _, _, keyReason = M.actorHasDoorKey(npc, door)
        if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
            return "key_unknown_teleport_door_route"
        end
        return "locked_teleport_door_route"
    end
    return "teleport_door_route_required"
end

function M.teleportDoorOnRouteSegment(cell, fromPos, targetPos, npc, options)
    options = options or {}
    if not (cell and cell.getAll and fromPos and targetPos and types and types.Door) then return nil, nil end
    local okList, doors = pcall(function() return cell:getAll(types.Door) end)
    if not (okList and doors) then return nil, nil end

    local bestDoor, bestReason, bestDist
    for _, door in ipairs(doors) do
        if M.isTeleportDoor(door) then
            local onRoute = M.doorOnRouteSegment(door, fromPos, targetPos, {
                maxVertical = tonumber(options.maxVertical) or 260,
                maxLineDistance = tonumber(options.maxLineDistance) or 220,
                maxActorDistance = tonumber(options.maxActorDistance) or 1200,
                maxTargetDistance = tonumber(options.maxTargetDistance) or 1200,
            })
            if onRoute then
                local dist = (door.position - fromPos):length()
                if not bestDist or dist < bestDist then
                    bestDoor = door
                    bestReason = M.teleportDoorRouteReason(door, npc)
                    bestDist = dist
                end
            end
        end
    end

    return bestDoor, bestReason
end

function M.isClosedNonTeleport(door)
    if not M.isNonTeleportDoor(door) then return false end
    local okClosed, closed = pcall(types.Door.isClosed, door)
    return okClosed and closed == true
end

function M.isOpenNonTeleport(door)
    if not M.isNonTeleportDoor(door) then return false end
    local okOpen, isOpen = pcall(types.Door.isOpen, door)
    return okOpen and isOpen == true
end

function M.openability(door, npc, options)
    if not M.isClosedNonTeleport(door) then return false, "not_closed_route_door" end
    return M.npcCanOpenDoor(door, npc, options)
end

function M.isClosedOpenableNonTeleport(door, npc, options)
    local ok = M.openability(door, npc, options)
    return ok == true
end

function M.doorOnRouteSegment(door, fromPos, targetPos, options)
    options = options or {}
    if not (door and door.position and fromPos and targetPos) then return false, "missing_route_context" end
    local lineDist, t = M.distanceToSegment2d(door.position, fromPos, targetPos)
    local rawT = M.segmentProjection2d(door.position, fromPos, targetPos)
    local actorDist = (door.position - fromPos):length()
    local targetDist = (door.position - targetPos):length()
    local vertical = math.abs((door.position.z or 0) - (fromPos.z or 0))
    local minT = tonumber(options.minSegmentT) or -0.05
    local maxT = tonumber(options.maxSegmentT) or 1.05
    if vertical > (tonumber(options.maxVertical) or 135) then return false, "door_wrong_vertical_band" end
    if lineDist > (tonumber(options.maxLineDistance) or 150) then return false, "door_not_between_actor_and_target" end
    if rawT and (rawT < minT or rawT > maxT) then return false, "door_outside_route_segment" end
    if actorDist > (tonumber(options.maxActorDistance) or 850) or targetDist > (tonumber(options.maxTargetDistance) or 850) then
        return false, "door_too_far_from_route"
    end
    return true, nil
end

function M.waypointPastDoor(door, fromPos, targetPos, distance)
    if not (door and door.position and fromPos and targetPos) then return nil end
    local dx = (targetPos.x or 0) - (fromPos.x or 0)
    local dy = (targetPos.y or 0) - (fromPos.y or 0)
    local dz = (targetPos.z or 0) - (fromPos.z or 0)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len <= 1 then return nil end
    return door.position + (targetPos - fromPos) * ((tonumber(distance) or 150) / len)
end

function M.sameSideDoorPoint(door, fromPos, targetPos, distance, z)
    if not (door and door.position and fromPos and targetPos) then return nil end
    local dx = (targetPos.x or 0) - (fromPos.x or 0)
    local dy = (targetPos.y or 0) - (fromPos.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    local fx = dx / len
    local fy = dy / len
    local actorSide = ((fromPos.x or 0) - (door.position.x or 0)) * fx
        + ((fromPos.y or 0) - (door.position.y or 0)) * fy
    local side = actorSide >= 0 and 1 or -1
    local clearDistance = tonumber(distance) or 120
    return util.vector3(
        (door.position.x or 0) + fx * side * clearDistance,
        (door.position.y or 0) + fy * side * clearDistance,
        z or fromPos.z or door.position.z or 0
    )
end

function M.doorUseWaypoints(door, fromPos, targetPos, options)
    options = options or {}
    if not (door and door.position and fromPos and targetPos) then return {} end
    local dx = (targetPos.x or 0) - (fromPos.x or 0)
    local dy = (targetPos.y or 0) - (fromPos.y or 0)
    local len2d = math.sqrt(dx * dx + dy * dy)
    if len2d <= 1 then return {} end

    local forward = util.vector3(dx / len2d, dy / len2d, 0)
    local lateral = util.vector3(-dy / len2d, dx / len2d, 0)
    local beforeDistance = tonumber(options.beforeDistance) or 115
    local afterDistance = tonumber(options.afterDistance) or 175
    local sideDistance = tonumber(options.sideDistance) or 90
    local z = tonumber(options.z)
    local base = z and util.vector3(door.position.x, door.position.y, z) or door.position

    local offsets = {
        sideDistance,
        -sideDistance,
        0,
        sideDistance * 1.45,
        -sideDistance * 1.45,
    }
    local result = {}
    for _, side in ipairs(offsets) do
        result[#result + 1] = {
            usePoint = base - forward * beforeDistance + lateral * side,
            postPoint = base + forward * afterDistance + lateral * side,
            sideOffset = side,
        }
    end
    return result
end

return M
