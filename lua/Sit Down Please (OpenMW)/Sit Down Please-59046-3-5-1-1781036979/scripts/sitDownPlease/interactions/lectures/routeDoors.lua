-- interactions/lectures/routeDoors.lua
---@omw-context global
-- Same-cell route-door assist for live lectern/station presenter paths.

local types = require('openmw.types')
local routeAssist = require('scripts/sitDownPlease/assignment/routeAssist')

local M = {}
local ctx = {}
local doorsByNpc = {}

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

local function now()
    return ctx.now and ctx.now() or 0
end

local function actorNearDoor(entry)
    local door = entry and entry.door
    local npc = entry and entry.npc
    local cell = door and door.cell
    if not (cell and cell.getAll and door and door.position) then return false end
    local ok, npcs = pcall(function() return cell:getAll(types.NPC) end)
    if not (ok and npcs) then return false end
    for _, other in ipairs(npcs) do
        if other ~= npc and isObjValid(other) and other.position and (other.position - door.position):length() <= 190 then
            return true
        end
    end
    return false
end

local function closeEntry(npcId, entry, reason)
    local door = entry and entry.door
    if not isObjValid(door) then return true end
    if actorNearDoor(entry) and now() < ((entry.openedAt or 0) + 45) then
        entry.closeAfter = now() + 1.5
        debugLog("station route door close delayed actor_near_door", tostring(door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
        return false
    end
    local okOpen, isOpen = pcall(types.Door.isOpen, door)
    if okOpen and isOpen ~= true then return true end
    local ok, err = pcall(types.Door.activateDoor, door, false)
    if ok then
        if entry.wasLocked == true then
            local lockable = routeAssist.lockableApi()
            if lockable and lockable.lock then
                local okLock, lockErr = pcall(lockable.lock, door, entry.lockLevel or 1)
                if not okLock then debugLog("station route door relock failed", tostring(door.recordId or door.id), tostring(lockErr)) end
            end
        end
        debugLog("station route door close", tostring(door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
        infoLog("station_door_close_completed", tostring(door.recordId or door.id), "npc", tostring(npcId), "reason", tostring(reason or "route_done"))
        return true
    end
    debugLog("station route door close failed", tostring(door.recordId or door.id), tostring(err))
    return false
end

function M.onOpen(ev)
    local npc = ev and ev.npc
    local door = ev and ev.door
    local dest = ev and ev.destPosition
    local npcId = npc and npc.id
    if not (npcId and isObjValid(npc) and isObjValid(door) and dest) then return end
    local onRoute, routeReason = routeAssist.doorOnRouteSegment(door, npc.position, dest, {
        maxVertical = 160,
        maxLineDistance = 165,
        maxActorDistance = 900,
        maxTargetDistance = 1000,
    })
    if not onRoute then
        debugLog("station route door rejected", npc.recordId or npc.id, tostring(door and (door.recordId or door.id)), tostring(routeReason))
        return
    end
    local canOpen, openReason = routeAssist.openability(door, npc, {
        allowLockedDoorOverride = ev and ev.allowLockedDoorOverride == true,
        debugLog = debugLog,
        logPrefix = "station_route_door_assist",
    })
    if canOpen ~= true then
        debugLog("station route door rejected", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(openReason))
        return
    end
    local wasLocked = routeAssist.isDoorLocked(door)
    local lockLevel = wasLocked and routeAssist.doorLockLevel(door) or nil
    if wasLocked == true then
        local lockable = routeAssist.lockableApi()
        if lockable and lockable.unlock then
            local okUnlock, unlockErr = pcall(lockable.unlock, door)
            if not okUnlock then
                debugLog("station route door unlock failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(unlockErr))
                return
            end
        else
            debugLog("station route door unlock unavailable", npc.recordId or npc.id, tostring(door.recordId or door.id))
            return
        end
    end
    local ok, err = pcall(types.Door.activateDoor, door, true)
    if not ok then
        if wasLocked == true then
            local lockable = routeAssist.lockableApi()
            if lockable and lockable.lock then pcall(lockable.lock, door, lockLevel or 1) end
        end
        debugLog("station route door open failed", npc.recordId or npc.id, tostring(door.recordId or door.id), tostring(err))
        return
    end
    local list = doorsByNpc[npcId] or {}
    list[#list + 1] = {
        npc = npc,
        door = door,
        destPosition = dest,
        openedAt = now(),
        closeAfter = now() + 8,
        wasLocked = wasLocked == true,
        lockLevel = lockLevel,
    }
    doorsByNpc[npcId] = list
    debugLog("station route door opened", npc.recordId or npc.id, tostring(door.recordId or door.id), "reason", tostring(ev and ev.reason or "station_route_assist"))
    infoLog("station_door_owned_by_sdp", npc.recordId or npc.id, tostring(door.recordId or door.id))
end

function M.process()
    local current = now()
    for npcId, list in pairs(doorsByNpc) do
        local keep = {}
        for _, entry in ipairs(list) do
            if entry.closeAfter and current >= entry.closeAfter then
                if not closeEntry(npcId, entry, "station_route_done") then keep[#keep + 1] = entry end
            else
                keep[#keep + 1] = entry
            end
        end
        if #keep > 0 then doorsByNpc[npcId] = keep else doorsByNpc[npcId] = nil end
    end
end

function M.reset(reason)
    for npcId, list in pairs(doorsByNpc) do
        for _, entry in ipairs(list) do closeEntry(npcId, entry, reason or "reset") end
    end
    doorsByNpc = {}
end

return M
