-- Persist compact pending lecture-audience release records across save/load.
---@omw-context global

local originTracker = require('scripts/sitDownPlease/assignment/originTracker')
local persistedActors = require('scripts/sitDownPlease/interactions/lectures/persistedActors')

local M = {}
local MAX_RECORDS = 80

local function actorId(npc)
    return npc and npc.id and tostring(npc.id) or nil
end

local function actorRecordId(npc)
    return npc and npc.recordId and tostring(npc.recordId) or nil
end

local function cellNameFor(npc, env)
    if not (npc and npc.cell and env and env.cellName) then return nil end
    local ok, value = pcall(env.cellName, npc.cell)
    if ok and value then return tostring(value) end
    return nil
end

local function recordKey(record)
    return tostring(record and (record.actorId or record.actorRecordId) or "<actor>")
        .. "::" .. tostring(record and record.stationSlotKey or "<station>")
end

local function recordCellIsActive(record, env)
    if not (record and record.cellName and env and env.activeCellName) then return false end
    return tostring(record.cellName) == tostring(env.activeCellName)
end

local function normalizeRecord(record)
    if type(record) ~= "table" or not (record.actorId or record.actorRecordId) then return nil end
    return {
        actorId = record.actorId and tostring(record.actorId) or nil,
        actorRecordId = record.actorRecordId and tostring(record.actorRecordId) or nil,
        actorPosition = persistedActors.copyPosition(record.actorPosition),
        cellName = record.cellName and tostring(record.cellName) or nil,
        dueIn = math.max(0, tonumber(record.dueIn) or 0),
        source = record.source and tostring(record.source) or "lecture_ended",
        stopReason = record.stopReason and tostring(record.stopReason) or "sitting_lifecycle_return_origin",
        returnToSitting = record.returnToSitting == true,
        returnOriginPosition = originTracker.saveVector(record.returnOriginPosition),
        returnOriginYaw = tonumber(record.returnOriginYaw),
        stationSlotKey = record.stationSlotKey and tostring(record.stationSlotKey) or nil,
    }
end

function M.normalize(records)
    local normalized = {}
    for _, record in ipairs(records or {}) do
        local copy = normalizeRecord(record)
        if copy then
            normalized[#normalized + 1] = copy
            if #normalized >= MAX_RECORDS then break end
        end
    end
    return normalized
end

function M.snapshotPending(pending, env)
    local now = env and env.now and env.now() or 0
    local records = {}
    for _, item in pairs(pending or {}) do
        if type(item) == "table" then
            local npc = item and item.npc
            if item.releaseOnly == true and npc and npc.id then
            local record = normalizeRecord({
                actorId = actorId(npc),
                actorRecordId = actorRecordId(npc),
                actorPosition = persistedActors.positionSnapshot(npc.position),
                cellName = cellNameFor(npc, env),
                dueIn = math.max(0, (tonumber(item.due) or now) - now),
                source = item.source,
                stopReason = item.stopReason,
                returnToSitting = item.returnToSitting == true,
                returnOriginPosition = item.returnOriginPosition,
                returnOriginYaw = originTracker.saveRotationYaw(item.returnOriginRotation),
                stationSlotKey = item.stationSlotKey,
            })
                if record then
                    records[#records + 1] = record
                    if #records >= MAX_RECORDS then break end
                end
            end
        end
    end
    return records
end

function M.merge(existing, additions)
    local merged = {}
    local seen = {}
    -- Fresh pending releases from the current save frame take priority over
    -- unresolved rows from prior loads when the bounded save list fills up.
    for _, source in ipairs({ M.normalize(additions), M.normalize(existing) }) do
        for _, record in ipairs(source) do
            local key = recordKey(record)
            if not seen[key] then
                merged[#merged + 1] = record
                seen[key] = true
                if #merged >= MAX_RECORDS then return merged end
            end
        end
    end
    return merged
end

local function findActiveActor(record, env)
    local actors = env and env.activeActors or nil
    if not actors then return nil end
    local candidates = {}
    for _, npc in ipairs(actors) do
        local valid = env and env.isObjValid and env.isObjValid(npc) or npc ~= nil
        if valid then
            local currentCell = record.cellName and cellNameFor(npc, env) or nil
            if not record.cellName or (currentCell and currentCell == record.cellName) then
                candidates[#candidates + 1] = npc
            end
        end
    end
    return persistedActors.findActor(candidates, record, {
        isValid = function(npc)
            return env and env.isObjValid and env.isObjValid(npc) or npc ~= nil
        end,
        positionTolerance = 180,
    })
end

function M.restoreAvailable(records, pending, env)
    local remaining = {}
    local restored = 0
    local dropped = 0
    local now = env and env.now and env.now() or 0
    for _, record in ipairs(M.normalize(records)) do
        local npc = findActiveActor(record, env)
        if npc and npc.id then
            pending[npc.id] = {
                npc = npc,
                due = now + math.max(0.05, tonumber(record.dueIn) or 0),
                source = record.source or "lecture_ended",
                stopReason = record.stopReason or "sitting_lifecycle_return_origin",
                releaseOnly = true,
                returnToSitting = record.returnToSitting == true,
                returnOriginPosition = originTracker.loadVector(record.returnOriginPosition),
                returnOriginRotation = env and env.rotationFromYaw
                    and env.rotationFromYaw(tonumber(record.returnOriginYaw), npc.rotation)
                    or npc.rotation,
                stationSlotKey = record.stationSlotKey,
            }
            restored = restored + 1
        elseif recordCellIsActive(record, env) then
            dropped = dropped + 1
        else
            remaining[#remaining + 1] = record
        end
    end
    return remaining, restored, dropped
end

return M
