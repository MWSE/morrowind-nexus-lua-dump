-- sleeping/routeDoors.lua
-- Runtime-only same-cell door assist for sleep routing.
-- Kept out of interactionAssignment.lua because door probing/repath/cleanup is
-- independent from candidate selection and was contributing to the global script
-- becoming too large.

local core = require('openmw.core')
local types = require('openmw.types')

local M = {}

local ctx = {}
local sleepRouteDoorsByNpc = {}

function M.configure(newCtx)
    ctx = newCtx or {}
end

local function debugLog(...)
    if ctx.debugLog then ctx.debugLog(...) end
end

local function infoLog(...)
    if ctx.infoLog then ctx.infoLog(...) end
end

local function isObjValid(obj)
    return ctx.isObjValid and ctx.isObjValid(obj) or false
end

local function doorObjectId(door)
    return door and (door.id or door.recordId) or nil
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

local function doorBetweenActorAndBed(door, npc, data)
    if not (door and door.position and npc and npc.position and data) then return false, "missing_route_context" end
    if data.interactionType ~= "sleeping" then return false, "not_sleep_route" end
    if ctx.sleepReservationExistsForNpc and ctx.sleepReservationExistsForNpc(npc) ~= true then return false, "no_sleep_reservation" end
    local target = data.approachPos or data.finalPosition or (data.object and data.object.position)
    if not target then return false, "missing_sleep_target" end
    local lineDist, t = distanceToSegment2d(door.position, npc.position, target)
    local actorDist = (door.position - npc.position):length()
    local targetDist = (door.position - target):length()
    local vertical = math.abs((door.position.z or 0) - (npc.position.z or 0))
    if vertical > 135 then return false, "door_wrong_vertical_band" end
    if lineDist > 150 then return false, "door_not_between_actor_and_bed" end
    if t and (t < -0.05 or t > 1.05) then return false, "door_outside_route_segment" end
    if actorDist > 850 or targetDist > 850 then return false, "door_too_far_from_route" end
    return true, nil
end

local function lockableApi()
    return (types and types.Door and types.Door.baseType) or (types and (types.Lockable or types.LOCKABLE))
end

local function isDoorLocked(door)
    if not (door and types and types.Door) then return true end
    local lockable = lockableApi()
    if lockable and lockable.isLocked then
        local ok, locked = pcall(lockable.isLocked, door)
        if ok then return locked == true end
    end
    return true
end

local function doorLockLevel(door)
    local lockable = lockableApi()
    if lockable and lockable.getLockLevel then
        local ok, level = pcall(lockable.getLockLevel, door)
        if ok and tonumber(level) then return tonumber(level) end
    end
    return 1
end

local function actorHasDoorKey(npc, door)
    if not (npc and door) then return false, nil, "missing_actor_or_door" end
    local lockable = lockableApi()
    if not (lockable and lockable.getKeyRecord) then return false, nil, "key_api_unavailable" end
    local okKey, keyRecord = pcall(lockable.getKeyRecord, door)
    if not (okKey and keyRecord) then return false, nil, "unknown_key" end
    local keyId = keyRecord.id or keyRecord.recordId or tostring(keyRecord)
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

local function npcCanOpenDoor(door, npc)
    if not isDoorLocked(door) then return true, "unlocked" end
    local hasKey, keyId, keyReason = actorHasDoorKey(npc, door)
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        debugLog("route_door_assist", npc and (npc.recordId or npc.id) or "<npc>", "locked_route_door_unknown_key", tostring(door and (door.recordId or door.id)), "key", tostring(keyId))
        return false, "locked_route_door_unknown_key"
    end
    if hasKey then
        debugLog("route_door_assist", npc and (npc.recordId or npc.id) or "<npc>", "locked_route_door_actor_has_key", tostring(door and (door.recordId or door.id)), "key", tostring(keyId))
        return true, "locked_route_door_actor_has_key"
    end
    debugLog("route_door_assist", npc and (npc.recordId or npc.id) or "<npc>", "locked_route_door_missing_key", tostring(door and (door.recordId or door.id)), "key", tostring(keyId))
    return false, "locked_route_door_missing_key"
end

local function isNonTeleportRouteDoor(door, npc, data)
    if not (isObjValid(door) and isObjValid(npc) and types and types.Door and types.Door.objectIsInstance) then return false, "invalid" end
    local okInstance, isDoor = pcall(types.Door.objectIsInstance, door)
    if not (okInstance and isDoor == true) then return false, "not_door" end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    if okTeleport and isTeleport == true then return false, "teleport_door" end
    local canOpen, openReason = npcCanOpenDoor(door, npc)
    if not canOpen then return false, openReason end
    if door.cell and npc.cell and door.cell ~= npc.cell then return false, "different_cell" end
    local betweenOk, betweenReason = doorBetweenActorAndBed(door, npc, data)
    if not betweenOk then return false, betweenReason end
    return true, openReason
end

local function canOpenRouteDoor(door, npc, data)
    local ok, reason = isNonTeleportRouteDoor(door, npc, data)
    if not ok then return false, reason end
    local okClosed, closed = pcall(types.Door.isClosed, door)
    if not (okClosed and closed == true) then return false, "not_closed" end
    return true, nil
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
    if isObjValid(npc) and npc.position and door.position then
        local clearDistance = tonumber(entry.safeCloseDistance or 230) or 230
        if (npc.position - door.position):length() <= clearDistance and now < ((entry.openedAt or now) + 45) then
            entry.closeAfter = now + 1.0
            debugLog("sleep route door close deferred actor_near_door", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "distance", tostring((npc.position - door.position):length()), "reason", tostring(reason or "route_done"))
            infoLog("door_close_delayed_actor_near", tostring(entry.doorRecordId or door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
            return false
        end
    end
    local ok, err = pcall(types.Door.activateDoor, door, false)
    if ok then
        if entry.wasLocked == true then
            local lockable = lockableApi()
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

function M.closeForNpc(npcId, reason)
    if not npcId then return end
    local list = sleepRouteDoorsByNpc[npcId]
    if not list then return end
    local now = core.getSimulationTime() or 0
    for _, entry in ipairs(list) do
        entry.closeAfter = math.min(entry.closeAfter or (now + 0.8), now + 0.8)
        entry.closeReason = reason or entry.closeReason or "route_done"
    end
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
            local data = ctx.assignedActors and ctx.assignedActors[npcId] or nil
            local keep = {}
            for _, entry in ipairs(list) do
                local door = entry and entry.door
                local npc = (data and data.npc) or entry.npc
                local shouldClose = false
                if not isObjValid(door) then
                    shouldClose = true
                else
                    local shouldAttemptClose = false
                    if entry.closeAfter and now >= entry.closeAfter then
                        shouldAttemptClose = true
                    elseif not data or data.interactionType ~= "sleeping" or data.state == (ctx.states and ctx.states.interacting) then
                        entry.closeAfter = entry.closeAfter or (now + 0.8)
                    end

                    if shouldAttemptClose then
                        if not isObjValid(npc) or not npc.position or not door.position or (npc.position - door.position):length() > 230 or now >= ((entry.openedAt or now) + 45) then
                            shouldClose = true
                        else
                            entry.closeAfter = now + 1.5
                            if data and data.approachPos and (not entry.nextClearNudgeAt or now >= entry.nextClearNudgeAt) then
                                entry.nextClearNudgeAt = now + 2.0
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

                if shouldClose then
                    if not closeRouteDoorEntry(npcId, entry, entry.closeReason or (data and "sleep_route_settled" or "sleep_route_cancelled")) then
                        table.insert(keep, entry)
                        shouldClose = false
                    end
                else
                    table.insert(keep, entry)
                end
            end
            if #keep > 0 then sleepRouteDoorsByNpc[npcId] = keep else sleepRouteDoorsByNpc[npcId] = nil end
        end
    end

    local pending = sleepRouteDoorsByNpc.__pendingRestarts
    if pending then
        for npcId, entry in pairs(pending) do
            local data = ctx.assignedActors and ctx.assignedActors[npcId] or nil
            local npc = entry and entry.npc
            if not entry or (entry.due and now < entry.due) then
                -- not due yet
            elseif not data or data.interactionType ~= "sleeping" or data.state == (ctx.states and ctx.states.interacting) then
                pending[npcId] = nil
            elseif not isObjValid(npc) or not data.approachPos then
                pending[npcId] = nil
            else
                local stage = entry.stage or "post_door"
                local dest = data.approachPos
                local tolerance = 70
                if stage == "post_door" and entry.postDoorWaypoint then
                    dest = entry.postDoorWaypoint
                    tolerance = 90
                    entry.stage = "approach"
                    entry.due = now + 0.95
                else
                    entry.stage = "done"
                end

                npc:sendEvent('SitDownPleaseStartAIPackage', {
                    type = "Travel",
                    destPosition = dest,
                    isRepeat = false,
                    cancelOther = true,
                    destinationTolerance = tolerance,
                })
                entry.count = (entry.count or 0) + 1
                if entry.stage == "done" or entry.count >= 3 then
                    pending[npcId] = nil
                end
                debugLog("route_door_assist", npc.recordId or npc.id, "delayed_repath", "stage", tostring(stage), "count", tostring(entry.count), "target", tostring(dest), "finalApproach", tostring(data.approachPos))
                infoLog("door_route_retry", npc.recordId or npc.id, "stage", tostring(stage), "count", tostring(entry.count), "target", tostring(dest))
            end
        end
    end
end

function M.onOpen(ev)
    local npc = ev and ev.npc
    local door = ev and ev.door
    local postDoorWaypoint = ev and ev.postDoorWaypoint
    local npcId = npc and npc.id
    local data = npcId and ctx.assignedActors and ctx.assignedActors[npcId] or nil
    if not npcId or not data or data.interactionType ~= "sleeping" then return end
    local ok, reason = canOpenRouteDoor(door, npc, data)
    if not ok then
        if tostring(reason) == "not_closed" then
            infoLog("door_already_open", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)))
            infoLog("door_close_skipped_not_owned", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), "reason", "already_open_not_owned_by_sdp")
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
            entry.closeAfter = math.max(entry.closeAfter or 0, (core.getSimulationTime() or 0) + 6)
            if data and data.approachPos then
                local pending = sleepRouteDoorsByNpc.__pendingRestarts or {}
                sleepRouteDoorsByNpc.__pendingRestarts = pending
                pending[npcId] = {
                    npc = npc,
                    due = (core.getSimulationTime() or 0) + 0.45,
                    count = 0,
                    stage = postDoorWaypoint and "post_door" or "approach",
                    postDoorWaypoint = postDoorWaypoint,
                }
            end
            return
        end
    end

    if wasLocked == true then
        local lockable = lockableApi()
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
            local lockable = lockableApi()
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
        closeAfter = (core.getSimulationTime() or 0) + 8,
        wasClosedBeforeAssist = true,
        wasLocked = wasLocked == true,
        lockLevel = originalLockLevel,
        postDoorWaypoint = postDoorWaypoint,
    })
    sleepRouteDoorsByNpc[npcId] = list
    infoLog("door_owned_by_sdp", npc.recordId or npc.id, tostring(door.recordId or door.id), "locked", tostring(wasLocked == true))
    if data and data.approachPos then
        local pending = sleepRouteDoorsByNpc.__pendingRestarts or {}
        sleepRouteDoorsByNpc.__pendingRestarts = pending
        pending[npcId] = {
            npc = npc,
            due = (core.getSimulationTime() or 0) + 0.85,
            count = 0,
            stage = postDoorWaypoint and "post_door" or "approach",
            postDoorWaypoint = postDoorWaypoint,
        }
    end
    debugLog("route_door_assist", npc.recordId or npc.id, "opened", tostring(door.recordId or door.id), tostring(ev and ev.reason or "route_assist"), "postDoorWaypoint", tostring(postDoorWaypoint))
    infoLog("post_door_waypoint_chosen", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(postDoorWaypoint))
end

return M
