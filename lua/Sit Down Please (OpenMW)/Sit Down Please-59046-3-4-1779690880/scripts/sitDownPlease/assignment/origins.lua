-- Primitive save/load helpers for stable furniture interaction origins.
--
-- This module deliberately persists only small scalar facts. It never stores
-- OpenMW object/cell references or pending actions, so save-load recovery can
-- restore return-to-origin behavior without replaying stale teleports.

local util = require('openmw.util')

local M = {}
local sleepHomeOrigins = {}

local function actorKey(npc, opts)
    if npc and npc.id then return npc.id end
    if opts and opts.actorKey then return opts.actorKey(npc) end
    return npc and tostring(npc.recordId or npc) or nil
end

function M.resetHomeOrigins()
    sleepHomeOrigins = {}
end

function M.homeFor(npc, opts)
    local key = actorKey(npc, opts)
    if key then return sleepHomeOrigins[key], key end
    return nil, nil
end

function M.setHome(npc, position, rotation, reason, opts)
    local key = actorKey(npc, opts)
    if not key or not position then return nil end
    local existing = sleepHomeOrigins[key]
    if existing and existing.position then return existing end
    local item = {
        position = position,
        rotation = rotation,
        reason = reason or "sleep_assigned",
    }
    sleepHomeOrigins[key] = item
    return item
end

function M.clearHome(npc, opts)
    local key = actorKey(npc, opts)
    if key and sleepHomeOrigins[key] then
        sleepHomeOrigins[key] = nil
        return true, key
    end
    return false, key
end

function M.saveVector(pos)
    local ok, x, y, z = pcall(function()
        return pos and pos.x, pos and pos.y, pos and pos.z
    end)
    if not ok or x == nil or y == nil or z == nil then return nil end
    return {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
    }
end

function M.loadVector(pos)
    if type(pos) ~= "table" or pos.x == nil or pos.y == nil or pos.z == nil then return nil end
    return util.vector3(tonumber(pos.x) or 0, tonumber(pos.y) or 0, tonumber(pos.z) or 0)
end

function M.saveRotationYaw(rotation)
    if type(rotation) == "number" then return rotation end
    local ok, yaw = pcall(function()
        return rotation and rotation:getYaw()
    end)
    if ok and yaw ~= nil then return tonumber(yaw) or 0 end
    return nil
end

local function objectPositionMatches(record, obj)
    local savedPos = M.loadVector(record and record.objectPosition)
    if not (savedPos and obj and obj.position) then return false end
    local ok, dist = pcall(function() return (obj.position - savedPos):length() end)
    return ok and dist and dist <= 24
end

local function matchesEvent(record, ev, opts)
    if not (record and ev and ev.initialPlacement == true and ev.npc) then return false end
    if tostring(record.interactionType or "") ~= tostring(ev.interactionType or "") then return false end

    local actorId = ev.npc.id and tostring(ev.npc.id) or nil
    local actorRecordId = ev.npc.recordId and tostring(ev.npc.recordId) or nil
    local savedActorId = record.actorId and tostring(record.actorId) or nil
    local savedRecordId = record.actorRecordId and tostring(record.actorRecordId) or nil
    if savedActorId and actorId then
        if savedActorId ~= actorId then return false end
    elseif savedRecordId and actorRecordId then
        if savedRecordId ~= actorRecordId then return false end
    else
        return false
    end

    local cellName = opts and opts.cellName
    local savedCell = record.cellName and tostring(record.cellName) or nil
    local currentCell = ev.npc.cell and cellName and cellName(ev.npc.cell) or nil
    if savedCell and currentCell and savedCell ~= currentCell then return false end
    if record.objectId and ev.objectId and tostring(record.objectId) ~= tostring(ev.objectId) then return false end
    if record.slotName and ev.slotName and tostring(record.slotName) ~= tostring(ev.slotName) then return false end

    local slotMatches = record.slotKey and ev.slotKey and tostring(record.slotKey) == tostring(ev.slotKey)
    if not slotMatches and not objectPositionMatches(record, ev.object) then return false end

    return M.loadVector(record.origin) ~= nil
end

function M.take(records, ev, opts)
    for i, record in ipairs(records or {}) do
        if matchesEvent(record, ev, opts) then
            table.remove(records, i)
            return record
        end
    end
    return nil
end

function M.normalize(records)
    local normalized = {}
    for _, record in ipairs(records or {}) do
        if record and M.loadVector(record.origin) then
            normalized[#normalized + 1] = {
                actorId = record.actorId,
                actorRecordId = record.actorRecordId,
                cellName = record.cellName,
                interactionType = record.interactionType,
                objectId = record.objectId,
                objectPosition = M.saveVector(M.loadVector(record.objectPosition)),
                slotKey = record.slotKey,
                slotName = record.slotName,
                origin = M.saveVector(M.loadVector(record.origin)),
                originYaw = tonumber(record.originYaw),
            }
        end
    end
    return normalized
end

function M.buildSaveData(assignedActors, opts)
    local records = {}
    local states = opts and opts.states
    local isObjValid = opts and opts.isObjValid
    local cellName = opts and opts.cellName

    for _, data in pairs(assignedActors or {}) do
        if data
            and data.state == (states and states.interacting)
            and data.preInteractionPos
            and data.interactionType
            and data.objectId
            and isObjValid
            and isObjValid(data.npc)
        then
            records[#records + 1] = {
                actorId = data.npc.id,
                actorRecordId = data.npc.recordId,
                cellName = data.assignedCellName or (data.npc.cell and cellName and cellName(data.npc.cell) or nil),
                interactionType = data.interactionType,
                objectId = data.objectId,
                objectPosition = M.saveVector(data.object and data.object.position),
                slotKey = data.slotKey,
                slotName = data.slotName,
                origin = M.saveVector(data.preInteractionPos),
                originYaw = M.saveRotationYaw(data.preInteractionRot),
            }
        end
    end

    return records
end

return M
