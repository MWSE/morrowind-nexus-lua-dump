-- Stable furniture interaction origin tracking and return-to-origin queues.
---@omw-context all
--
-- Persisted records deliberately store only small scalar facts. Live return
-- queues may hold runtime object references, but they are never saved.

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

function M.peek(records, ev, opts)
    for i, record in ipairs(records or {}) do
        if matchesEvent(record, ev, opts) then
            return record, i
        end
    end
    return nil, nil
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

function M.mergeRecords(existing, additions, maxRecords)
    local merged = M.normalize(existing)
    local limit = tonumber(maxRecords or 80) or 80

    for _, record in ipairs(M.normalize(additions)) do
        merged[#merged + 1] = record
    end

    while #merged > limit do
        table.remove(merged, 1)
    end

    return merged
end

function M.createReturnQueue(env)
    local queue = {}
    local R = {}

    local function debugLog(...)
        if env and env.debugLog then env.debugLog(...) end
    end

    local function isObjValid(obj)
        return env and env.isObjValid and env.isObjValid(obj) == true
    end

    local function assignedActors()
        return env and env.assignedActors and env.assignedActors() or {}
    end

    local function hasPendingStandTeleport(npcId)
        return env and env.hasPendingStandTeleport and env.hasPendingStandTeleport(npcId) == true
    end

    local function actorDeadReason(npc)
        if env and env.actorDeadReason then return env.actorDeadReason(npc) end
        return false, nil
    end

    local function shouldClearHome(reason)
        return env and env.shouldClearHome and env.shouldClearHome(reason) == true
    end

    local function placeAtOrigin(npcId, item, distance, reason, now)
        local npc = item and item.npc
        local origin = item and item.origin
        local ok, err = false, "tryTeleport_unavailable"
        if env and env.tryTeleport then
            ok, err = env.tryTeleport(npc, npc and npc.cell or nil, origin, { rotation = item.rotation or (npc and npc.rotation), onGround = true })
        end
        if ok then
            debugLog("post-wake return origin placed", npc and (npc.recordId or npc.id) or tostring(npcId), "origin", tostring(origin), "distance", tostring(distance), "reason", tostring(reason or "placement"))
            queue[npcId] = nil
            if shouldClearHome(item.reason) and env and env.clearHome then env.clearHome(npc, reason or "placed_return_to_origin") end
            return true
        end
        item.nextAttemptAt = (tonumber(now) or 0) + 0.25
        debugLog("post-wake return origin placement failed", npc and (npc.recordId or npc.id) or tostring(npcId), tostring(err), "reason", tostring(reason or "placement"))
        return false
    end

    function R:set(npcOrId, item)
        local key = type(npcOrId) == "table" and npcOrId.id or npcOrId
        if key == nil then return end
        queue[key] = item
    end

    function R:get(npcOrId)
        local key = type(npcOrId) == "table" and npcOrId.id or npcOrId
        return key ~= nil and queue[key] or nil
    end

    function R:clear(npcOrId)
        local key = type(npcOrId) == "table" and npcOrId.id or npcOrId
        if key ~= nil then queue[key] = nil end
    end

    function R:reset()
        queue = {}
    end

    function R:raw()
        return queue
    end

    function R:process(force)
        if env and env.inSleepWindow and env.inSleepWindow() and force ~= true then return end
        local now = env and env.now and env.now() or 0
        local active = assignedActors()

        for npcId, item in pairs(queue) do
            local npc = item and item.npc
            if not isObjValid(npc) then
                queue[npcId] = nil
            elseif actorDeadReason(npc) then
                queue[npcId] = nil
                debugLog("post-wake return origin cancelled", npc.recordId or npc.id, "reason", "dead_actor")
            elseif active[npcId] or hasPendingStandTeleport(npcId) then
                -- wait until the actor has actually exited any bed/interaction
            elseif item.origin then
                local distance = npc.position and (npc.position - item.origin):length() or 999999
                local completionRadius = tonumber(item.completionRadius or (env and env.completionRadius)) or 96
                if distance < completionRadius then
                    if item.exactOnComplete == true and env and env.tryTeleport then
                        if not placeAtOrigin(npcId, item, distance, "returned_to_origin_exact", now) then
                            item.nextAttemptAt = now + 0.25
                        end
                    else
                        debugLog("post-wake return origin complete", npc.recordId or npc.id, "distance", tostring(distance))
                        queue[npcId] = nil
                        if shouldClearHome(item.reason) and env and env.clearHome then env.clearHome(npc, "returned_to_origin") end
                    end
                elseif force == true then
                    placeAtOrigin(npcId, item, distance, "forced_return_to_origin", now)
                elseif not item.nextAttemptAt or item.nextAttemptAt <= now then
                    local retryInterval = tonumber(item.retryInterval or (env and env.retryInterval)) or 3
                    local maxAttempts = tonumber(item.maxAttempts or (env and env.maxAttempts)) or 12
                    item.attempts = (item.attempts or 0) + 1
                    item.nextAttemptAt = now + retryInterval
                    local progressThreshold = tonumber(item.progressThreshold or (env and env.progressThreshold)) or 24
                    if item.lastDistance == nil or distance < (tonumber(item.lastDistance) or distance) - progressThreshold then
                        item.lastDistance = distance
                        item.noProgressAttempts = 0
                    else
                        item.noProgressAttempts = (item.noProgressAttempts or 0) + 1
                    end
                    local maxNoProgressAttempts = tonumber(item.maxNoProgressAttempts or (env and env.maxNoProgressAttempts)) or 4
                    if (item.noProgressAttempts or 0) >= maxNoProgressAttempts then
                        debugLog("post-wake return origin giving up", npc.recordId or npc.id, "distance", tostring(distance), "noProgress", tostring(item.noProgressAttempts or 0), "reason", "no_progress", "home", "retained")
                        queue[npcId] = nil
                    else

                        local assisted, assistReason = false, nil
                        if env and env.assistReturnRouteDoor then
                            assisted, assistReason = env.assistReturnRouteDoor(npc, item.origin, item.reason or "post_wake_return_origin")
                        end
                        if assisted == true then
                            debugLog(
                                "post-wake return origin door-assisted",
                                npc.recordId or npc.id,
                                "origin", tostring(item.origin),
                                "reason", tostring(assistReason),
                                "attempt", tostring(item.attempts)
                            )
                        else
                            npc:sendEvent('SitDownPleaseStartAIPackage', {
                                type = "Travel",
                                destPosition = item.origin,
                                isRepeat = false,
                                cancelOther = true,
                                preserveExternalPackage = item.preserveExternalPackage == true,
                            })
                            debugLog("post-wake return origin travel", npc.recordId or npc.id, "origin", tostring(item.origin), "force", tostring(force == true), "attempt", tostring(item.attempts), "distance", tostring(distance), "noProgress", tostring(item.noProgressAttempts or 0))
                        end
                        if item.attempts >= maxAttempts then
                            if item.keepTrying == true then
                                local retryAfterMax = tonumber(item.retryAfterMaxAttempts or (env and env.retryAfterMaxAttempts)) or (retryInterval * 4)
                                local maxDeferrals = tonumber(item.maxRetryDeferrals or (env and env.maxRetryDeferrals)) or 3
                                item.retryDeferrals = (item.retryDeferrals or 0) + 1
                                if item.retryDeferrals > maxDeferrals then
                                    debugLog("post-wake return origin giving up", npc.recordId or npc.id, "distance", tostring(distance), "deferrals", tostring(item.retryDeferrals), "reason", "retry_deferral_limit")
                                    queue[npcId] = nil
                                else
                                    debugLog("post-wake return origin retry deferred", npc.recordId or npc.id, "distance", tostring(distance), "attempts", tostring(item.attempts), "deferrals", tostring(item.retryDeferrals), "next", tostring(retryAfterMax))
                                    item.attempts = 0
                                    item.nextAttemptAt = now + retryAfterMax
                                end
                            else
                                debugLog("post-wake return origin giving up", npc.recordId or npc.id, "distance", tostring(distance))
                                queue[npcId] = nil
                            end
                        end
                    end
                end
            end
        end
    end

    return R
end

function M.createSittingOriginQueue(env)
    local queue = {}
    local Q = {}

    local function debugLog(...)
        if env and env.debugLog then env.debugLog(...) end
    end

    local function isObjValid(obj)
        return env and env.isObjValid and env.isObjValid(obj) == true
    end

    local function assignedActors()
        return env and env.assignedActors and env.assignedActors() or {}
    end

    local function now()
        return env and env.now and env.now() or 0
    end

    function Q:set(npcOrId, item)
        local key = type(npcOrId) == "table" and npcOrId.id or npcOrId
        if key ~= nil then queue[key] = item end
    end

    function Q:clear(npcOrId)
        local key = type(npcOrId) == "table" and npcOrId.id or npcOrId
        if key ~= nil then queue[key] = nil end
    end

    function Q:reset()
        queue = {}
    end

    function Q:process()
        local t = now()
        local active = assignedActors()
        for npcId, item in pairs(queue) do
            local npc = item and item.npc
            if not item or (item.due and item.due > t) then
                -- not due yet
            elseif not isObjValid(npc) or active[npcId] then
                queue[npcId] = nil
            elseif item.stage == "returning" then
                if not item.origin or (npc.position - item.origin):length() <= 80 or (item.startedAt and t - item.startedAt > item.timeout) then
                    item.stage = "brief_wander"
                    item.startedAt = t
                    if item.idleDest then
                        npc:sendEvent('SitDownPleaseBriefWander', {
                            destPosition = item.idleDest,
                            reason = item.reason or "sitting_lifecycle_return_origin",
                            timeout = item.timeout or 8,
                            radius = 70,
                        })
                        debugLog("sitting brief wander queued", npc.recordId or npc.id, "dest", tostring(item.idleDest))
                    else
                        queue[npcId] = nil
                    end
                elseif not item.startedAt then
                    item.startedAt = t
                end
            elseif item.stage == "brief_wander" then
                if not item.idleDest or (npc.position - item.idleDest):length() <= 70 or (item.startedAt and t - item.startedAt > item.timeout) then
                    npc:sendEvent('SitDownPleaseClearBriefTravel', { reason = "brief_wander_done", destPosition = item.idleDest, radius = 120 })
                    if item.origin and (npc.position - item.origin):length() > 85 then
                        item.stage = "wander_returning"
                        item.startedAt = t
                        npc:sendEvent('SitDownPleaseStartAIPackage', {
                            type = "Travel",
                            destPosition = item.origin,
                            isRepeat = false,
                        })
                        debugLog("sitting brief wander return home", npc.recordId or npc.id, "origin", tostring(item.origin))
                    else
                        queue[npcId] = nil
                    end
                end
            elseif item.stage == "wander_returning" then
                if not item.origin or (npc.position - item.origin):length() <= 80 or (item.startedAt and t - item.startedAt > item.timeout) then
                    npc:sendEvent('SitDownPleaseClearBriefTravel', { reason = "brief_wander_return_done", destPosition = item.origin, radius = 120 })
                    queue[npcId] = nil
                end
            end
        end
    end

    return Q
end

return M
