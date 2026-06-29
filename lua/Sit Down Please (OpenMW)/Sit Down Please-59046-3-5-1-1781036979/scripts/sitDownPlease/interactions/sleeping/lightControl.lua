-- interactions/sleeping/lightControl.lua
---@omw-context global
---@diagnostic disable: assign-type-mismatch, undefined-field
-- Runtime-isolated sleep-triggered light control for Sit Down Please.
-- Enabled by default. Keeps scans/candidates runtime-only; persists only the
-- generated off-record lookup and minimal active replacement state.

local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local assignmentEligibility = require('scripts/sitDownPlease/assignment/eligibility')
local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')
local cellContext = require('scripts/sitDownPlease/world/cellContext')

local module = {}

local MOD_PREFIX = 'sdp3_sleep_light_off_'
local RESTORE_REASON_WAKE = {
    scheduled_wake_time = true,
    sleep_window_ended = true,
    settings_disabled = true,
    cell_change = true,
    activated_by_player_dialogue = true,
    sleeping_disturbed_by_close_player = true,
    sleeping_disturbed_by_close_sneaking_player = true,
    sleeping_disturbed_by_invisible_close_player = true,
    sleeping_disturbed_by_player = true,
    sleeping_disturbed_by_dialogue = true,
    disturbed_by_player = true,
    disturbed_sleep = true,
    sleep_disturbed = true,
}

local PLAYER_WAKE_BEDSIDE_RESTORE_REASONS = {
    activated_by_player_dialogue = true,
    sleeping_disturbed_by_close_player = true,
    sleeping_disturbed_by_close_sneaking_player = true,
    sleeping_disturbed_by_invisible_close_player = true,
    sleeping_disturbed_by_player = true,
    sleeping_disturbed_by_dialogue = true,
    disturbed_by_player = true,
    disturbed_sleep = true,
    sleep_disturbed = true,
}

local function isPlayerVisibleWakeReason(reason)
    local text = tostring(reason or "")
    if PLAYER_WAKE_BEDSIDE_RESTORE_REASONS[text] == true then return true end
    return text:find("disturb", 1, true) ~= nil and text:find("player", 1, true) ~= nil
end

local RESTORE_IMMEDIATE_REASONS = {
    settings_disabled = true,
    cell_change = true,
    reload_cleanup = true,
    cleanup = true,
}

local LOCAL_RESTORE_REJECT_REASONS = {
    no_path_to_bed = true,
    wrong_floor_or_unreachable = true,
    blocked_by_wall = true,
    route_too_indirect = true,
    approach_too_far_from_navmesh = true,
    approach_navmesh_behind_collision = true,
    visible_sleep_route_incomplete = true,
    sleep_route_incomplete = true,
    sleep_entry_rejected = true,
    public_bed_requires_door_assist = true,
    locked_route_door = true,
    blocked_route_door = true,
    trapped_route_door = true,
    initial_sleep_surface_not_ready = true,
    sleep_initial_placement_rejected = true,
}

local DEFAULT_PUBLIC_RADIUS_MULTIPLIER = 0.65
local DEFAULT_PUBLIC_VERTICAL_TOLERANCE = 360
local DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS = 350
local DEFAULT_VISIBLE_SLEEP_RADIUS = 360
local DEFAULT_AWAKE_NEARBY_VISIBLE_SLEEP_RADIUS = 440
local DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS = 210
local DEFAULT_AWAKE_SAME_ROOM_KEEP_RADIUS = 520
local DEFAULT_AWAKE_NPC_KEEP_LIGHT_RADIUS = 520
local DEFAULT_PRIVATE_VISIBLE_VERTICAL_BELOW_TOLERANCE = 70
local DEFAULT_PRIVATE_VISIBLE_VERTICAL_ABOVE_TOLERANCE = 260
local PENDING_SLEEPER_LIGHT_BATCH_TIMEOUT = 8

local settings = {}
local function noopLog(...)
end

local debugLog = noopLog

local saveData = {
    generatedRecords = {},
    reverseRecordLookup = {},
    activeReplacements = {},
}

local currentCell = nil
local currentCellKey = nil
local lightCandidateCache = nil
local sleepers = {}
-- Last known light anchors are kept runtime-only so a failed sleep start or
-- pre-animation cancellation can still restore the exact bedside lights it touched.
local sleepLightAnchors = {}
local pendingOps = {}
local pendingSet = {}
local restoreDelay = {}
local companionActors = {}
local lastFollowerUtilAvailable = nil
local restoredBehaviorLogged = false
local pendingSleepers = {}
local wakePathRestoreState = {}
local evaluateAnchor
local postEntryReevaluateAt = nil
local postEntryReevaluateReason = nil
local restoreHoldUntil = nil
local restoreHoldReason = nil

local function now()
    if core and core.getSimulationTime then return core.getSimulationTime() end
    return 0
end

local function restoreHoldActive(reason)
    local t = now()
    if not restoreHoldUntil or restoreHoldUntil <= t then
        restoreHoldUntil = nil
        restoreHoldReason = nil
        return false, 0
    end
    local text = tostring(reason or '')
    if RESTORE_IMMEDIATE_REASONS[text]
        or text == 'scheduled_wake_time'
        or text == 'sleep_window_ended'
        or text == 'time_advance_sleep_window_ended'
        or text == 'daytime_failsafe'
        or text == 'off_hours_service_window_ended'
    then
        return false, 0
    end
    return true, restoreHoldUntil - t
end

local function isValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return obj:isValid() end)
    if not (ok and valid == true) then return false end
    local okEnabled, enabled = pcall(function() return obj.enabled end)
    if okEnabled and enabled == false then return false end
    return true
end

local function objectId(value)
    if value == nil then return nil end
    local valueType = type(value)
    if valueType == 'string' or valueType == 'number' then return value end
    local ok, id = pcall(function() return value.id end)
    if ok and id ~= nil then return id end
    return value
end

local function objectRecordId(value)
    if value == nil then return nil end
    local ok, recordId = pcall(function() return value.recordId end)
    if ok and recordId ~= nil then return recordId end
    return objectId(value)
end

local function objectCell(value)
    if value == nil then return nil end
    local ok, cell = pcall(function() return value.cell end)
    if ok then return cell end
    return nil
end

local function objectPosition(value)
    if value == nil then return nil end
    local ok, position = pcall(function() return value.position end)
    if ok then return position end
    return nil
end

local function positionValue(value)
    if value == nil then return nil end
    local okX, x = pcall(function() return value.x end)
    local okY, y = pcall(function() return value.y end)
    local okZ, z = pcall(function() return value.z end)
    if okX and okY and okZ and x ~= nil and y ~= nil and z ~= nil then return value end
    return objectPosition(value)
end

local function cellKey(cell)
    return cellContext.cellName(cell)
end

local function lower(s)
    if s == nil then return '' end
    return string.lower(tostring(s))
end

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t or {}) do copy[k] = v end
    return copy
end

local function distance(a, b)
    if not a or not b then return math.huge end
    return (a - b):length()
end

local function objectCount(obj)
    local count = tonumber(obj and obj.count) or 1
    if count < 1 then return 1 end
    return math.floor(count)
end

local function isZeroCountRemoveError(err)
    return lower(err):find("can't remove 0 of 0 items", 1, true) ~= nil
end

local function sleeperCount()
    local count = 0
    for _ in pairs(sleepers or {}) do count = count + 1 end
    return count
end

local function pendingSleeperCount(cell)
    local count = 0
    local ck = cell and cellKey(cell) or nil
    local currentTime = now()
    for actorId, anchor in pairs(pendingSleepers or {}) do
        local inScope = anchor and (not ck or not anchor.cellKey or anchor.cellKey == ck)
        if inScope then count = count + 1 end
        if anchor and anchor.registeredAt and currentTime - anchor.registeredAt > PENDING_SLEEPER_LIGHT_BATCH_TIMEOUT then
            pendingSleepers[actorId] = nil
            if inScope then count = math.max(0, count - 1) end
            debugLog('sleep lights pending sleeper timed out', tostring(anchor.actorRecordId or actorId), 'age', tostring(currentTime - anchor.registeredAt))
        end
    end
    return count
end

local function pendingSleeperAnchor(actorOrId)
    local actorId = objectId(actorOrId)
    return actorId and pendingSleepers[actorId] or nil
end

local function reevaluateActiveSleepers(reason, immediate)
    for _, anchor in pairs(sleepers or {}) do
        evaluateAnchor(anchor, immediate == true)
    end
    if pendingSleeperCount(currentCell) == 0 then
        debugLog('sleep lights off after pending sleeper batch', 'reason', tostring(reason or 'batch_complete'), 'sleepers', tostring(sleeperCount()))
    end
end

local function schedulePostEntryReevaluate(reason, delay)
    local due = now() + (tonumber(delay) or 0.35)
    if not postEntryReevaluateAt or due < postEntryReevaluateAt then
        postEntryReevaluateAt = due
        postEntryReevaluateReason = reason or 'post_sleep_entry_awake_light_check'
    end
end

local function pendingOffCount()
    local count = 0
    for _, op in ipairs(pendingOps or {}) do
        if op and op.kind == 'off' then count = count + 1 end
    end
    return count
end

local function verticalDistance(a, b)
    if not a or not b then return math.huge end
    return math.abs((a.z or 0) - (b.z or 0))
end

local function verticalDelta(reference, pos)
    if not reference or not pos then return math.huge end
    return (pos.z or 0) - (reference.z or 0)
end

local function anchorVerticalReference(anchor)
    if not anchor then return nil end
    -- Sleeping pose roots often sit above the practical floor/bedside height.
    -- Use the solved side/approach floor point for same-floor light filtering so
    -- downstairs lamps directly under the bed do not count as bedside lights.
    return anchor.floorPosition or anchor.approachPosition or anchor.bedPosition or anchor.position
end

local function isPrivateSleepContext(cell)
    return cellContext.isLikelyPrivateResidence and cellContext.isLikelyPrivateResidence(cell) == true
end

local function effectiveLightRadius(anchor)
    local radius = tonumber(settings.lightControlRadius or 1200) or 1200

    -- Late-night initial placement should make a private home look like it was
    -- already dark when the player entered. Visible bedtime/resleep only shrinks
    -- to the immediate bed area when an awake NPC is actually influencing the
    -- light decision; if everyone nearby is asleep, the room should go dark.
    if anchor and anchor.initialPlacement ~= true and anchor.awakeNpcLightMode ~= 'no_awake_nearby' then
        local visibleRadius = tonumber(settings.lightControlVisibleSleepRadius or DEFAULT_VISIBLE_SLEEP_RADIUS) or DEFAULT_VISIBLE_SLEEP_RADIUS
        radius = math.min(radius, visibleRadius)
    end

    if anchor and anchor.awakeNpcLightMode == 'awake_nearby_smaller_radius' then
        local nearbyRadius = tonumber(settings.lightControlAwakeNearbyVisibleSleepRadius or DEFAULT_AWAKE_NEARBY_VISIBLE_SLEEP_RADIUS) or DEFAULT_AWAKE_NEARBY_VISIBLE_SLEEP_RADIUS
        radius = math.min(radius, nearbyRadius)
    elseif anchor and anchor.awakeNpcLightMode == 'awake_directly_beside_skip' then
        local directRadius = tonumber(settings.lightControlAwakeDirectBedsideRadius or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS) or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS
        radius = math.min(radius, directRadius)
    end

    if anchor and anchor.cell and not isPrivateSleepContext(anchor.cell) then
        radius = radius * (tonumber(settings.lightControlPublicRadiusMultiplier or DEFAULT_PUBLIC_RADIUS_MULTIPLIER) or DEFAULT_PUBLIC_RADIUS_MULTIPLIER)
    end
    if anchor and anchor.awakeNpcLightMode == 'awake_nearby_smaller_radius' then
        local nearbyRadius = tonumber(settings.lightControlAwakeNearbyVisibleSleepRadius or DEFAULT_AWAKE_NEARBY_VISIBLE_SLEEP_RADIUS) or DEFAULT_AWAKE_NEARBY_VISIBLE_SLEEP_RADIUS
        radius = math.max(radius, nearbyRadius, DEFAULT_VISIBLE_SLEEP_RADIUS)
    end
    return radius
end

local function passesVerticalContext(anchor, obj)
    if not (anchor and obj and anchor.position and obj.position) then return false end
    local verticalAnchor = anchorVerticalReference(anchor) or anchor.position
    if anchor.cell and isPrivateSleepContext(anchor.cell) then
        -- Whole-house darkness is only for late-night initial placement. If the
        -- player is already present and sees the sleeper go to bed or wake up,
        -- keep light changes on the same practical floor/height band as the bed.
        if anchor.initialPlacement == true then return true end
        -- Use an asymmetric band: bedside candles mounted above the bed should
        -- count, but downstairs lights below the practical floor/approach height
        -- should not. A symmetric tolerance caused shelf candles above the bed to
        -- be rejected; a broad symmetric tolerance let lower-floor lights through.
        local belowTolerance = tonumber(settings.lightControlPrivateVisibleVerticalBelowTolerance or DEFAULT_PRIVATE_VISIBLE_VERTICAL_BELOW_TOLERANCE) or DEFAULT_PRIVATE_VISIBLE_VERTICAL_BELOW_TOLERANCE
        local aboveTolerance = tonumber(settings.lightControlPrivateVisibleVerticalAboveTolerance or DEFAULT_PRIVATE_VISIBLE_VERTICAL_ABOVE_TOLERANCE) or DEFAULT_PRIVATE_VISIBLE_VERTICAL_ABOVE_TOLERANCE
        local dz = verticalDelta(verticalAnchor, obj.position)
        return dz >= -belowTolerance and dz <= aboveTolerance
    end
    local tolerance = tonumber(settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE
    return verticalDistance(verticalAnchor, obj.position) <= tolerance
end

local function objectRecord(obj)
    return objectMatchers.objectRecord(obj)
end

local function lightRecord(objOrId)
    local ok, rec = pcall(function() return types.Light.record(objOrId) end)
    if ok then return rec end
    return nil
end

local function sameCell(a, b)
    if not a or not b then return false end
    return cellKey(a) == cellKey(b)
end

local function isFollowerByFollowerDetectionUtil(npc)
    if not (npc and npc.id and I and I.FollowerDetectionUtil and I.FollowerDetectionUtil.getFollowerList) then return false end
    local ok, followers = pcall(I.FollowerDetectionUtil.getFollowerList)
    if not ok or type(followers) ~= 'table' then return false end
    local state = followers[npc.id]
    if not state then return false end
    if state.followsPlayer == true then return true end
    local leader = state.leader or state.superLeader
    return leader and leader.type and types.Player and leader.type == types.Player or false
end

local function npcLooksLikeCompanion(npc)
    if not npc then return false end
    -- Prefer FollowerDetectionUtil when available. This is a soft dependency: no
    -- hard require, no error if absent, and our local fallback still works.
    if isFollowerByFollowerDetectionUtil(npc) then return true end
    if npc.id and companionActors[npc.id] == true then return true end
    local recordId = lower(npc.recordId or npc.id)
    local rec = objectRecord(npc)
    local name = lower(rec and rec.name or recordId)
    local class = lower(rec and rec.class or "")

    -- Lightweight fallback for common companion/follower records. The real path
    -- is FollowerDetectionUtil or the runtime follower-state report from the NPC
    -- local script.
    return recordId:find("companion", 1, true)
        or recordId:find("follower", 1, true)
        or name:find("companion", 1, true)
        or class:find("companion", 1, true)
end

local function clearLightCache(reason)
    lightCandidateCache = nil
    if settings.verboseDebug == true or settings.debugVerbose == true then debugLog('sleep lights cache cleared', tostring(reason or 'unknown')) end
end

local function noteFollowerUtilAvailability()
    local available = I and I.FollowerDetectionUtil and I.FollowerDetectionUtil.getFollowerList ~= nil or false
    if available ~= lastFollowerUtilAvailable then
        lastFollowerUtilAvailable = available
        debugLog('sleep lights follower util', available and 'available' or 'absent')
    end
end

local function categoryForLight(obj)
    local category, reason = objectMatchers.classifyLight(obj, settings)
    if category == 'lantern' then return 'lantern', nil end
    if category == 'lamp' then return 'lantern', nil end
    return category, reason
end

local function settingAllowsCategory(category)
    if category == 'candle' then return settings.lightControlCandles == true end
    if category == 'lantern' then return settings.lightControlLanterns == true end
    if category == 'torch' then return settings.lightControlTorches == true end
    if category == 'fire' then return settings.lightControlFires == true end
    return false
end

local function isEligibleLight(obj)
    if not isValid(obj) then return false, 'invalid' end
    if not (types.Light and types.Light.objectIsInstance and types.Light.objectIsInstance(obj)) then return false, 'not_light' end
    if not obj.cell then return false, 'missing_cell' end
    if obj.cell.hasSky then return false, 'exterior_or_has_sky' end
    if obj.count ~= nil and obj.count <= 0 then return false, 'count_zero' end
    if obj.recordId and saveData.reverseRecordLookup and saveData.reverseRecordLookup[obj.recordId] then
        return false, 'managed_off_record'
    end

    local category, reason = categoryForLight(obj)
    if not category then return false, reason or 'uncategorized' end
    if not settingAllowsCategory(category) then return false, 'category_disabled' end

    return true, nil, category
end

local function scanLights(cell)
    if not settings.enableLightControl then return {} end
    if lightCandidateCache and lightCandidateCache.cellKey == cellKey(cell) then
        if settings.verboseDebug == true or settings.debugVerbose == true then debugLog('sleep lights cache hit', tostring(#lightCandidateCache.objects), cellKey(cell)) end
        return lightCandidateCache.objects
    end

    local candidates = {}
    local scanned, rejected = 0, 0
    local categoryCounts = {}
    local rejectCounts = {}
    if cell and cell.getAll and types.Light then
        for _, obj in ipairs(cell:getAll(types.Light)) do
            scanned = scanned + 1
            local ok, reason, category = isEligibleLight(obj)
            if ok then
                candidates[#candidates + 1] = { object = obj, category = category }
                categoryCounts[category or 'unknown'] = (categoryCounts[category or 'unknown'] or 0) + 1
            else
                rejected = rejected + 1
                reason = reason or 'rejected'
                rejectCounts[reason] = (rejectCounts[reason] or 0) + 1
            end
        end
    end

    lightCandidateCache = { cellKey = cellKey(cell), objects = candidates }
    debugLog('sleep lights scan', 'cell', cellKey(cell), 'scanned', tostring(scanned), 'eligible', tostring(#candidates), 'rejected', tostring(rejected))
    if settings.debug then
        local catSummary = {}
        for k, v in pairs(categoryCounts) do catSummary[#catSummary + 1] = tostring(k) .. '=' .. tostring(v) end
        table.sort(catSummary)
        local rejectSummary = {}
        for k, v in pairs(rejectCounts) do rejectSummary[#rejectSummary + 1] = tostring(k) .. '=' .. tostring(v) end
        table.sort(rejectSummary)
        debugLog('sleep lights scan detail', 'categories', table.concat(catSummary, ','), 'rejects', table.concat(rejectSummary, ','))
    end
    return candidates
end

local function awakeNpcLightMode(anchor)
    if not anchor or not anchor.cell or not anchor.position then return 'missing_anchor', nil, 0, 0, 0, 0, nil end
    local radius = tonumber(settings.lightControlAwakeNpcRadius or 1600) or 1600
    if radius <= 0 then return 'no_awake_nearby', nil, 0, 0, 0, 0, nil end
    if not types.NPC or not anchor.cell.getAll then return 'no_awake_nearby', nil, 0, 0, 0, 0, nil end

    local directRadius = tonumber(settings.lightControlAwakeDirectBedsideRadius or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS) or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS
    local nearbyCount = 0
    local directCount = 0
    local followersIgnored = 0
    local pendingIgnored = 0
    local nearestId = nil
    local nearestPos = nil
    local nearestDist = math.huge

    for _, npc in ipairs(anchor.cell:getAll(types.NPC)) do
        local dead = assignmentEligibility.actorDeadReason(npc, types)
        if isValid(npc)
            and npc.id ~= anchor.actorId
            and not sleepers[npc.id]
            and not dead
            and npc.position
        then
            local d = distance(npc.position, anchor.position)
            local pending = pendingSleeperAnchor(npc)
            if pending and d <= radius then
                pendingIgnored = pendingIgnored + 1
                debugLog('sleep lights pending sleeper ignored as awake', tostring(npc.recordId or npc.id), 'anchor', tostring(anchor.actorRecordId or anchor.actorId), 'distance', tostring(d), 'state', tostring(pending.state))
            elseif npcLooksLikeCompanion(npc) then
                if d <= radius then followersIgnored = followersIgnored + 1 end
            else
                if d <= radius then
                    nearbyCount = nearbyCount + 1
                    if d < nearestDist then
                        nearestDist = d
                        nearestId = npc.recordId or npc.id
                        nearestPos = npc.position
                    end
                    if d <= directRadius then directCount = directCount + 1 end
                end
            end
        end
    end

    if directCount > 0 then return 'awake_directly_beside_skip', nearestId, nearbyCount, directCount, followersIgnored, pendingIgnored, nearestPos, nearestDist end
    if nearbyCount > 0 then return 'awake_nearby_smaller_radius', nearestId, nearbyCount, directCount, followersIgnored, pendingIgnored, nearestPos, nearestDist end
    return 'no_awake_nearby', nil, nearbyCount, directCount, followersIgnored, pendingIgnored, nil, nil
end

local function ensureOffRecordId(onRecordId)
    if saveData.generatedRecords[onRecordId] then return saveData.generatedRecords[onRecordId] end

    local original = lightRecord(onRecordId)
    if not original then return nil end

    local draft = { template = original, isOffByDefault = true }
    local okDraft, recordDraft = pcall(types.Light.createRecordDraft, draft)
    if not okDraft or not recordDraft then return nil end

    local okCreate, newRecord = pcall(world.createRecord, recordDraft)
    if not okCreate or not newRecord then return nil end

    saveData.generatedRecords[onRecordId] = newRecord.id
    saveData.reverseRecordLookup[newRecord.id] = onRecordId
    return newRecord.id
end

local function animatedInterface()
    return I and I.AnimatedLanternsAndSigns or nil
end

local function notifyAnimatedLanterns(oldObj, newObj)
    local als = animatedInterface()
    if not (als and als.replaceLantern) then return end
    pcall(function() als.replaceLantern(oldObj, newObj) end)
end

local function createReplacementObject(newRecordId, cell, pos, rotation, scale, count)
    local okCreate, newObj = pcall(world.createObject, newRecordId, count)
    if not okCreate or not newObj then return nil, newObj or 'create_failed' end

    local okTp, tpErr = pcall(function() newObj:teleport(cell, pos, { rotation = rotation, onGround = false }) end)
    if not okTp then return nil, tpErr end

    if scale and scale ~= 1 and newObj.setScale then
        pcall(function() newObj:setScale(scale) end)
    end

    return newObj, nil
end

local function replaceObject(oldObj, newRecordId, options)
    if not isValid(oldObj) or not newRecordId then return nil, 'invalid_replace_args' end
    local cell = oldObj.cell
    local pos = oldObj.position
    local rotation = oldObj.rotation
    local scale = oldObj.scale
    local count = objectCount(oldObj)
    if not (cell and pos) then return nil, 'missing_transform' end

    local okRemove, removeErr = pcall(function() oldObj:remove() end)
    if not okRemove then
        if not (options and options.recoverZeroCount == true and isZeroCountRemoveError(removeErr)) then
            return nil, removeErr
        end
        local recoveredObj, recoveredErr = createReplacementObject(newRecordId, cell, pos, rotation, scale, count)
        if recoveredObj then
            debugLog('sleep light restore recovered zero-count replacement', tostring(objectRecordId(oldObj)), '->', tostring(newRecordId))
            return recoveredObj, nil
        end
        return nil, recoveredErr or removeErr
    end

    local newObj, err = createReplacementObject(newRecordId, cell, pos, rotation, scale, count)
    if not newObj then return nil, err end
    notifyAnimatedLanterns(oldObj, newObj)
    return newObj, nil
end

local function queueOp(kind, payload, immediate)
    if not payload then return end
    local key = kind .. ':' .. tostring(payload.objectId or payload.offObjectId or payload.originalObjectId or #pendingOps)
    if pendingSet[key] then return end
    pendingSet[key] = true
    pendingOps[#pendingOps + 1] = { kind = kind, payload = payload, key = key }
    if immediate then module.processPending(true) end
end

local function cancelPendingOffForActor(actorId, reason)
    if not actorId then return 0 end
    local kept = {}
    local removed = 0
    for _, op in ipairs(pendingOps or {}) do
        local p = op and op.payload or {}
        if op and op.kind == 'off' and p.anchorActorId == actorId then
            if op.key then pendingSet[op.key] = nil end
            removed = removed + 1
        else
            kept[#kept + 1] = op
        end
    end
    pendingOps = kept
    if removed > 0 then debugLog('sleep lights pending off cancelled', 'actor', tostring(actorId), 'count', tostring(removed), 'reason', tostring(reason)) end
    return removed
end

local function turnOffLight(light, anchor, immediate, meta)
    if not isValid(light) then return false end
    if saveData.reverseRecordLookup[light.recordId] then return false end
    if saveData.activeReplacements[light.id] then return false end

    local offRecordId = ensureOffRecordId(light.recordId)
    if not offRecordId then return false end

    queueOp('off', {
        object = light,
        objectId = light.id,
        recordId = light.recordId,
        offRecordId = offRecordId,
        anchorActorId = anchor and anchor.actorId,
        cellKey = light.cell and cellKey(light.cell),
        category = meta and meta.category,
        distanceFromAnchor = meta and meta.dist,
    }, immediate)
    return true
end

local function queueRestore(activeKey, entry, immediate, reason)
    if not entry then return end
    queueOp('restore', {
        activeKey = activeKey,
        offObject = entry.offObject,
        offObjectId = entry.offObjectId,
        originalRecordId = entry.originalRecordId,
        position = entry.position,
        cellKey = entry.cellKey,
        reason = reason,
    }, immediate)
end

local function recoverActiveReplacementRefs(cell)
    if not (cell and cell.getAll and types.Light) then return end
    local ck = cellKey(cell)
    local lights = cell:getAll(types.Light)
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        if entry and entry.offRecordId and not isValid(entry.offObject) then
            if not entry.cellKey or entry.cellKey == ck then
                local bestObj = nil
                local bestDist = nil
                for _, obj in ipairs(lights) do
                    if obj and obj.recordId == entry.offRecordId then
                        local d = 0
                        if entry.position and obj.position then d = distance(obj.position, entry.position) end
                        if not bestDist or d < bestDist then
                            bestObj = obj
                            bestDist = d
                        end
                    end
                end
                if bestObj then
                    entry.offObject = bestObj
                    entry.offObjectId = bestObj.id
                    entry.position = bestObj.position or entry.position
                    entry.cellKey = entry.cellKey or ck
                    if activeKey ~= bestObj.id then
                        saveData.activeReplacements[bestObj.id] = entry
                        saveData.activeReplacements[activeKey] = nil
                    end
                    debugLog('sleep light recovered tracked off object', tostring(entry.offRecordId), tostring(entry.originalRecordId), 'dist', tostring(bestDist or 0))
                end
            end
        end
    end
end

local function activeReplacementStillRelevant(entry)
    if not entry or not isValid(entry.offObject) then return false end
    local offCell = entry.offObject.cell
    if currentCell and offCell and not sameCell(offCell, currentCell) then return true end

    for _, anchor in pairs(sleepers) do
        if anchor.cell and offCell and sameCell(anchor.cell, offCell) and anchor.position then
            local mode, _, _, _, _, _, awakePos = awakeNpcLightMode(anchor)
            if mode == 'awake_directly_beside_skip' then mode = 'awake_nearby_smaller_radius' end
            anchor.awakeNpcLightMode = mode
            anchor.awakeNpcLightPosition = awakePos
            local radius = effectiveLightRadius(anchor)
            if mode ~= 'awake_directly_beside_skip'
                and passesVerticalContext(anchor, entry.offObject)
                and distance(entry.offObject.position, anchor.position) <= radius then
                return true
            end
        end
    end
    return false
end

local function awakeNpcMayKeepSameRoomLight(anchor, mode, awakePos, awakeDistance)
    if not (anchor and anchor.position and awakePos) then return false end
    if mode ~= 'awake_directly_beside_skip' and mode ~= 'awake_nearby_smaller_radius' then return false end
    local maxDistance = tonumber(settings.lightControlAwakeSameRoomKeepRadius or DEFAULT_AWAKE_SAME_ROOM_KEEP_RADIUS) or DEFAULT_AWAKE_SAME_ROOM_KEEP_RADIUS
    if maxDistance <= 0 or (tonumber(awakeDistance) or math.huge) > maxDistance then return false end
    local verticalAnchor = anchorVerticalReference(anchor) or anchor.position
    local verticalTolerance = tonumber(settings.lightControlAwakeSameRoomVerticalTolerance or settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE
    return verticalDistance(verticalAnchor, awakePos) <= verticalTolerance
end

local function awakeNpcLightContexts(anchor)
    if not (anchor and anchor.cell and anchor.cell.getAll and anchor.position and types.NPC) then return {} end
    local maxDistance = tonumber(settings.lightControlAwakeSameRoomKeepRadius or DEFAULT_AWAKE_SAME_ROOM_KEEP_RADIUS) or DEFAULT_AWAKE_SAME_ROOM_KEEP_RADIUS
    if maxDistance <= 0 then return {} end
    local verticalAnchor = anchorVerticalReference(anchor) or anchor.position
    local verticalTolerance = tonumber(settings.lightControlAwakeSameRoomVerticalTolerance or settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE
    local contexts = {}
    for _, npc in ipairs(anchor.cell:getAll(types.NPC)) do
        local dead = assignmentEligibility.actorDeadReason(npc, types)
        if isValid(npc)
            and npc.id ~= anchor.actorId
            and not sleepers[npc.id]
            and not pendingSleeperAnchor(npc)
            and not dead
            and npc.position
        then
            local anchorDist = distance(npc.position, anchor.position)
            if anchorDist <= maxDistance and verticalDistance(verticalAnchor, npc.position) <= verticalTolerance then
                contexts[#contexts + 1] = {
                    npc = npc,
                    npcId = npc.id,
                    npcRecordId = npc.recordId,
                    position = npc.position,
                    anchorDistance = anchorDist,
                }
            end
        end
    end
    return contexts
end

local function preserveAwakeNpcNearestLights(anchor, eligible, mode, radius)
    if not (anchor and eligible) then return 0, 0 end
    local awakeContexts = awakeNpcLightContexts(anchor)
    if #awakeContexts == 0 then return 0, 0 end

    local keepRadius = tonumber(settings.lightControlAwakeNpcKeepLightRadius or DEFAULT_AWAKE_NPC_KEEP_LIGHT_RADIUS) or DEFAULT_AWAKE_NPC_KEEP_LIGHT_RADIUS
    if keepRadius <= 0 then return 0, #awakeContexts end
    local anchorRadius = tonumber(radius or effectiveLightRadius(anchor)) or effectiveLightRadius(anchor)
    local keepOnObjectIds = {}
    local keptLights = 0
    local queuedRestores = 0

    for _, awake in ipairs(awakeContexts) do
        local best = nil
        for i, entry in ipairs(eligible) do
            local light = entry and entry.object
            local pos = light and light.position
            local awakeDist = pos and distance(pos, awake.position) or nil
            if awakeDist and awakeDist <= keepRadius then
                local anchorDist = distance(pos, anchor.position)
                if not best
                    or awakeDist < best.awakeDist
                    or (awakeDist == best.awakeDist and anchorDist < (best.anchorDist or math.huge))
                then
                    best = {
                        kind = 'on',
                        index = i,
                        object = light,
                        objectId = objectId(light),
                        recordId = light and light.recordId,
                        awakeDist = awakeDist,
                        anchorDist = anchorDist,
                    }
                end
            end
        end

        for activeKey, entry in pairs(saveData.activeReplacements or {}) do
            local offObj = entry and entry.offObject
            local pos = isValid(offObj) and offObj.position or entry and entry.position
            local cellOk = true
            if isValid(offObj) and anchor.cell and offObj.cell then cellOk = sameCell(anchor.cell, offObj.cell) end
            if pos and cellOk and distance(pos, anchor.position) <= anchorRadius then
                local awakeDist = distance(pos, awake.position)
                if awakeDist <= keepRadius then
                    local anchorDist = distance(pos, anchor.position)
                    local verticalOk = isValid(offObj) and passesVerticalContext(anchor, offObj) or true
                    if verticalOk
                        and (
                            not best
                            or awakeDist < best.awakeDist
                            or (awakeDist == best.awakeDist and anchorDist < (best.anchorDist or math.huge))
                        )
                    then
                        best = {
                            kind = 'off',
                            activeKey = activeKey,
                            entry = entry,
                            object = offObj,
                            objectId = activeKey,
                            recordId = entry.originalRecordId,
                            awakeDist = awakeDist,
                            anchorDist = anchorDist,
                        }
                    end
                end
            end
        end

        if best then
            if best.kind == 'on' then
                keepOnObjectIds[tostring(best.objectId)] = true
            elseif best.kind == 'off' then
                restoreDelay[best.activeKey] = nil
                queueRestore(best.activeKey, best.entry, false, 'awake_npc_nearest_light')
                queuedRestores = queuedRestores + 1
            end
            keptLights = keptLights + 1
            debugLog(
                'sleep lights kept awake npc nearest light',
                'actor', tostring(anchor.actorRecordId or anchor.actorId),
                'awakeNpc', tostring(awake.npcRecordId or awake.npcId),
                'light', tostring(best.recordId or best.objectId),
                'state', tostring(best.kind),
                'awakeDistance', tostring(best.awakeDist),
                'anchorDistance', tostring(best.anchorDist),
                'mode', tostring(mode)
            )
        end
    end

    if queuedRestores > 0 then module.processPending(true) end

    if next(keepOnObjectIds) then
        for i = #eligible, 1, -1 do
            local entry = eligible[i]
            local id = entry and entry.object and objectId(entry.object)
            if id ~= nil and keepOnObjectIds[tostring(id)] == true then
                table.remove(eligible, i)
            end
        end
    end

    return keptLights, #awakeContexts
end

local function restoreEntriesNearAnchor(anchor, reason, immediate, radiusOverride)
    if not anchor or not anchor.position then return 0 end
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    local radius = tonumber(radiusOverride or settings.lightControlPlayerWakeBedsideRestoreRadius or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS) or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS
    local count = 0
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        local offObj = entry and entry.offObject
        local pos = isValid(offObj) and offObj.position or entry and entry.position
        local cellOk = true
        if isValid(offObj) and anchor.cell and offObj.cell then cellOk = sameCell(anchor.cell, offObj.cell) end
        local verticalOk = true
        if isValid(offObj) then verticalOk = passesVerticalContext(anchor, offObj)
        elseif pos and anchor.position and anchor.cell and not isPrivateSleepContext(anchor.cell) then
            verticalOk = math.abs((pos.z or 0) - (anchor.position.z or 0)) <= (tonumber(settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE)
        end
        if pos and cellOk and verticalOk and distance(pos, anchor.position) <= radius then
            restoreDelay[activeKey] = nil
            queueRestore(activeKey, entry, false, reason or 'player_wake_bedside_restore')
            count = count + 1
        end
    end
    debugLog('sleep lights bedside restore', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'radius', tostring(radius), 'queued', tostring(count), 'reason', tostring(reason))
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end

local function restoreNoLongerNeededNearAnchor(anchor, reason, immediate, radiusOverride)
    if not anchor or not anchor.position then return 0 end
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    local radius = tonumber(radiusOverride or settings.lightControlPlayerWakeBedsideRestoreRadius or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS) or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS
    local count = 0
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        local offObj = entry and entry.offObject
        local pos = isValid(offObj) and offObj.position or entry and entry.position
        local cellOk = true
        if isValid(offObj) and anchor.cell and offObj.cell then cellOk = sameCell(anchor.cell, offObj.cell) end
        local verticalOk = true
        if isValid(offObj) then verticalOk = passesVerticalContext(anchor, offObj)
        elseif pos and anchor.position and anchor.cell and not isPrivateSleepContext(anchor.cell) then
            verticalOk = math.abs((pos.z or 0) - (anchor.position.z or 0)) <= (tonumber(settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE)
        end
        if pos and cellOk and verticalOk and distance(pos, anchor.position) <= radius and not activeReplacementStillRelevant(entry) then
            restoreDelay[activeKey] = nil
            queueRestore(activeKey, entry, false, reason or 'wake_bedside_restore')
            count = count + 1
        end
    end
    debugLog('sleep lights local wake restore', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'radius', tostring(radius), 'queued', tostring(count), 'reason', tostring(reason))
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end

local function activeSleeperDirectlyNeedsLightOff(entry, wakeAnchor)
    if not entry or not isValid(entry.offObject) then return false end
    local offObj = entry.offObject
    local offCell = offObj.cell
    local directRadius = tonumber(settings.lightControlAwakeDirectBedsideRadius or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS) or DEFAULT_AWAKE_DIRECT_BEDSIDE_RADIUS
    for _, anchor in pairs(sleepers) do
        if anchor ~= wakeAnchor and anchor.cell and offCell and sameCell(anchor.cell, offCell) and anchor.position then
            if passesVerticalContext(anchor, offObj) and distance(offObj.position, anchor.position) <= directRadius then
                return true
            end
        end
    end
    return false
end

local function restoreWakeEntriesNearAnchor(anchor, reason, immediate, radiusOverride)
    if not anchor then return 0 end
    local wakeAnchor = shallowCopy(anchor)
    wakeAnchor.position = anchor.floorPosition or anchor.approachPosition or anchor.position
    if not wakeAnchor.position then return 0 end
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    local radius = tonumber(radiusOverride or settings.lightControlPlayerWakeBedsideRestoreRadius or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS) or DEFAULT_PLAYER_WAKE_BEDSIDE_RESTORE_RADIUS
    local count = 0
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        local offObj = entry and entry.offObject
        local pos = isValid(offObj) and offObj.position or entry and entry.position
        local cellOk = true
        if isValid(offObj) and wakeAnchor.cell and offObj.cell then cellOk = sameCell(wakeAnchor.cell, offObj.cell) end
        local verticalOk = true
        if isValid(offObj) then verticalOk = passesVerticalContext(wakeAnchor, offObj)
        elseif pos and wakeAnchor.position and wakeAnchor.cell and not isPrivateSleepContext(wakeAnchor.cell) then
            verticalOk = math.abs((pos.z or 0) - (wakeAnchor.position.z or 0)) <= (tonumber(settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE)
        end
        if pos and cellOk and verticalOk and distance(pos, wakeAnchor.position) <= radius and not activeSleeperDirectlyNeedsLightOff(entry, anchor) then
            restoreDelay[activeKey] = nil
            queueRestore(activeKey, entry, false, reason or 'wake_bedside_restore')
            count = count + 1
        end
    end
    debugLog('sleep lights wake restore', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'radius', tostring(radius), 'queued', tostring(count), 'reason', tostring(reason))
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end

local function activeReplacementCount()
    local count = 0
    for _ in pairs(saveData.activeReplacements or {}) do count = count + 1 end
    return count
end

local function restoreClosestEntriesNearAnchor(anchor, reason, immediate, limit)
    if not anchor or not anchor.position then return 0 end
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    limit = tonumber(limit or 3) or 3
    if limit < 1 then return 0 end

    local candidates = {}
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        local offObj = entry and entry.offObject
        local pos = isValid(offObj) and offObj.position or entry and entry.position
        local cellOk = true
        if isValid(offObj) and anchor.cell and offObj.cell then cellOk = sameCell(anchor.cell, offObj.cell) end
        local verticalOk = true
        if isValid(offObj) then verticalOk = passesVerticalContext(anchor, offObj)
        elseif pos and anchor.position and anchor.cell and not isPrivateSleepContext(anchor.cell) then
            verticalOk = math.abs((pos.z or 0) - (anchor.position.z or 0)) <= (tonumber(settings.lightControlVerticalTolerance or DEFAULT_PUBLIC_VERTICAL_TOLERANCE) or DEFAULT_PUBLIC_VERTICAL_TOLERANCE)
        end
        if pos and cellOk and verticalOk then
            candidates[#candidates + 1] = {
                activeKey = activeKey,
                entry = entry,
                dist = distance(pos, anchor.position),
                owned = entry.anchorActorId ~= nil and entry.anchorActorId == anchor.actorId,
            }
        end
    end

    table.sort(candidates, function(a, b)
        if a.owned ~= b.owned then return a.owned == true end
        return (a.dist or math.huge) < (b.dist or math.huge)
    end)

    local count = 0
    for _, item in ipairs(candidates) do
        if count >= limit then break end
        restoreDelay[item.activeKey] = nil
        queueRestore(item.activeKey, item.entry, false, reason or 'player_wake_closest_restore')
        count = count + 1
    end

    debugLog('sleep lights closest restore fallback', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'queued', tostring(count), 'reason', tostring(reason))
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end


local function restoreOwnedEntriesForActor(anchor, reason, immediate, limit)
    if not anchor or not anchor.actorId then return 0 end
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    limit = tonumber(limit or 6) or 6
    local candidates = {}
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        if entry and entry.anchorActorId == anchor.actorId then
            local offObj = entry.offObject
            local pos = isValid(offObj) and offObj.position or entry.position
            local dist = pos and anchor.position and distance(pos, anchor.position) or math.huge
            candidates[#candidates + 1] = { activeKey = activeKey, entry = entry, dist = dist }
        end
    end
    table.sort(candidates, function(a, b) return (a.dist or math.huge) < (b.dist or math.huge) end)
    local count = 0
    for _, item in ipairs(candidates) do
        if count >= limit then break end
        restoreDelay[item.activeKey] = nil
        queueRestore(item.activeKey, item.entry, false, reason or 'player_wake_owned_restore')
        count = count + 1
    end
    debugLog('sleep lights owned restore fallback', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'queued', tostring(count), 'reason', tostring(reason))
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end

local function restoreAll(reason, immediate)
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    local count = 0
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        restoreDelay[activeKey] = nil
        queueRestore(activeKey, entry, false, reason or 'restore_all')
        count = count + 1
    end
    if count > 0 then debugLog('sleep lights restore all', 'queued', tostring(count), 'reason', tostring(reason), 'immediate', tostring(immediate == true)) end
    if immediate == true and count > 0 then module.processPending(true) end
    return count
end

local function restoreNoLongerNeeded(reason, immediate)
    if currentCell then recoverActiveReplacementRefs(currentCell) end
    if not settings.enableLightControl then immediate = true end
    if RESTORE_IMMEDIATE_REASONS[reason] then immediate = true end
    local activeSleepers = sleeperCount()
    local pendingAssignments = pendingOffCount()
    local held, holdRemaining = restoreHoldActive(reason)
    debugLog('sleeper_count_for_light', tostring(activeSleepers), 'pendingOff', tostring(pendingAssignments), 'reason', tostring(reason), 'immediate', tostring(immediate == true), 'restoreHold', tostring(held == true))
    for activeKey, entry in pairs(saveData.activeReplacements) do
        if not activeReplacementStillRelevant(entry) then
            restoreDelay[activeKey] = nil
            if immediate then
                queueRestore(activeKey, entry, false, reason or 'restore')
            else
                local delay = 0
                if held then
                    delay = math.max(tonumber(holdRemaining) or 0, 2) + 2
                    debugLog('restore held during night sleep release', 'activeKey', tostring(activeKey), 'holdReason', tostring(restoreHoldReason), 'releaseReason', tostring(reason), 'seconds', tostring(delay))
                elseif RESTORE_REASON_WAKE[reason] then
                    local seed = tonumber(string.match(tostring(activeKey), '(%d+)')) or 0
                    delay = 2 + (seed % 11)
                elseif activeSleepers > 0 then
                    delay = 4
                    debugLog('restore skipped because other sleeper still active', 'activeKey', tostring(activeKey), 'sleepers', tostring(activeSleepers), 'reason', tostring(reason))
                elseif pendingAssignments > 0 then
                    delay = 4
                    debugLog('restore delayed because assignment still pending', 'activeKey', tostring(activeKey), 'pendingOff', tostring(pendingAssignments), 'reason', tostring(reason))
                end
                restoreDelay[activeKey] = now() + delay
            end
        end
    end
    if immediate == true then module.processPending(true) end
end

evaluateAnchor = function(anchor, immediate)
    if not settings.enableLightControl then return end
    if not anchor or not anchor.cell or not anchor.position then return end
    if anchor.cell.hasSky then return end

    local mode, awakeId, nearbyCount, directCount, followersIgnored, pendingIgnored, awakePos, awakeDistance = awakeNpcLightMode(anchor)
    local batchPending = pendingSleeperCount(anchor.cell)
    local activeSleeperCount = sleeperCount()
    anchor.awakeNpcLightMode = mode
    anchor.awakeNpcLightActorId = awakeId
    anchor.awakeNpcLightPosition = awakePos
    anchor.preserveAwakeNpcClosestLight = anchor.initialPlacement ~= true and awakeNpcMayKeepSameRoomLight(anchor, mode, awakePos, awakeDistance)
    if mode == 'awake_directly_beside_skip' and anchor.initialPlacement ~= true and anchor.visibleSleep ~= false then
        if batchPending > 0 or activeSleeperCount > 1 then
            debugLog('sleep lights bedtime batch downgraded awake bedside blocker', tostring(anchor.actorRecordId or anchor.actorId), tostring(awakeId), 'nearby', tostring(nearbyCount), 'direct', tostring(directCount), 'followersIgnored', tostring(followersIgnored), 'pendingIgnored', tostring(pendingIgnored), 'pendingSleepers', tostring(batchPending), 'activeSleepers', tostring(activeSleeperCount), 'preserveSameRoomLight', tostring(anchor.preserveAwakeNpcClosestLight == true))
        else
            debugLog('sleep lights awake bedside keeps closest light', tostring(anchor.actorRecordId or anchor.actorId), tostring(awakeId), 'nearby', tostring(nearbyCount), 'direct', tostring(directCount), 'followersIgnored', tostring(followersIgnored), 'pendingIgnored', tostring(pendingIgnored), 'preserveSameRoomLight', tostring(anchor.preserveAwakeNpcClosestLight == true))
        end
        mode = 'awake_nearby_smaller_radius'
        anchor.awakeNpcLightMode = mode
    elseif mode == 'awake_directly_beside_skip' then
        debugLog('sleep lights initial placement awake bedside context', tostring(anchor.actorRecordId or anchor.actorId), tostring(awakeId), 'nearby', tostring(nearbyCount), 'direct', tostring(directCount), 'followersIgnored', tostring(followersIgnored), 'pendingIgnored', tostring(pendingIgnored), 'pendingSleepers', tostring(batchPending), 'activeSleepers', tostring(activeSleeperCount), 'preserveSameRoomLight', tostring(anchor.preserveAwakeNpcClosestLight == true))
        mode = 'initial_sleep_ignores_awake_bedside'
        anchor.awakeNpcLightMode = mode
    end
    if batchPending > 0 then
        debugLog('sleep lights batch pending sleepers count', tostring(batchPending), 'anchor', tostring(anchor.actorRecordId or anchor.actorId))
        debugLog('sleep lights deferred until batch complete', 'anchor', tostring(anchor.actorRecordId or anchor.actorId), 'pendingSleepers', tostring(batchPending))
    end

    local radius = effectiveLightRadius(anchor)
    for activeKey, entry in pairs(saveData.activeReplacements or {}) do
        if entry and isValid(entry.offObject) and entry.offObject.position and distance(entry.offObject.position, anchor.position) <= radius then
            restoreDelay[activeKey] = nil
        end
    end

    local candidates = scanLights(anchor.cell)
    local eligible = {}
    for _, entry in ipairs(candidates) do
        local light = entry.object
        if isValid(light)
            and light.position
            and passesVerticalContext(anchor, light)
            and distance(light.position, anchor.position) <= radius then
            eligible[#eligible + 1] = { object = light, category = entry.category, dist = distance(light.position, anchor.position) }
        end
    end
    table.sort(eligible, function(a, b)
        if (a.dist or math.huge) ~= (b.dist or math.huge) then return (a.dist or math.huge) < (b.dist or math.huge) end
        return tostring(a.object and (a.object.recordId or a.object.id)) < tostring(b.object and (b.object.recordId or b.object.id))
    end)

    local eligibleBeforeKeep = #eligible
    local keptAwakeLights, awakeLightContexts = preserveAwakeNpcNearestLights(anchor, eligible, mode, radius)

    local queued = 0
    local maxLights = tonumber(settings.lightControlMaxLightsPerSleeper or 0) or 0
    for _, entry in ipairs(eligible) do
        if maxLights > 0 and queued >= maxLights then break end
        if turnOffLight(entry.object, anchor, immediate, entry) then
            queued = queued + 1
        end
    end
    debugLog('sleep lights off request', 'actor', tostring(anchor.actorRecordId or anchor.actorId), 'mode', tostring(mode), 'followersIgnored', tostring(followersIgnored), 'pendingIgnored', tostring(pendingIgnored), 'nearbyAwake', tostring(nearbyCount), 'directAwake', tostring(directCount), 'awakeLightContexts', tostring(awakeLightContexts), 'keptAwakeLights', tostring(keptAwakeLights), 'preserveSameRoomLight', tostring(anchor.preserveAwakeNpcClosestLight == true), 'radius', tostring(radius), 'eligibleNear', tostring(#eligible), 'eligibleBeforeAwakeKeep', tostring(eligibleBeforeKeep), 'queuedCandidates', tostring(queued), 'immediate', tostring(immediate == true))
end

function module.setDebugLog(fn)
    debugLog = fn or noopLog
end

function module.refreshSettings(newSettings)
    settings = newSettings or {}
    noteFollowerUtilAvailability()
    if not restoredBehaviorLogged then
        restoredBehaviorLogged = true
        debugLog('sleep lights behavior restored_to_pre_7_1')
    end
    if not settings.enableLightControl then
        restoreNoLongerNeeded('settings_disabled', true)
    end
end

function module.onCellChange(cell, reason)
    currentCell = cell
    currentCellKey = cellKey(cell)
    lightCandidateCache = nil
    sleepers = {}
    sleepLightAnchors = {}
    pendingSleepers = {}
    postEntryReevaluateAt = nil
    postEntryReevaluateReason = nil
    restoreHoldUntil = nil
    restoreHoldReason = nil
    recoverActiveReplacementRefs(cell)
    debugLog('sleep lights cell context', tostring(currentCellKey), tostring(reason or 'cell_change'))
    if not settings.enableLightControl then return end
    restoreNoLongerNeeded('cell_change', true)
end

function module.registerPendingSleeper(actor, data)
    if not settings.enableLightControl then return end
    if not isValid(actor) then return end
    local pos = data and (data.finalPosition or data.position) or actor.position
    local bed = data and (data.bed or data.object) or nil
    if bed and isValid(bed) and bed.position then pos = data and data.finalPosition or bed.position or pos end
    if not pos then return end
    pendingSleepers[actor.id] = {
        actor = actor,
        actorId = actor.id,
        actorRecordId = actor.recordId,
        cell = actor.cell,
        cellKey = actor.cell and cellKey(actor.cell) or nil,
        position = pos,
        bedPosition = bed and isValid(bed) and bed.position or nil,
        approachPosition = data and (data.approachPosition or data.approachPos) or nil,
        floorPosition = data and (data.exitPosition or data.floorPosition or data.approachPosition or data.approachPos) or nil,
        originPosition = data and positionValue(data.originPosition or data.preInteractionPosition or data.preInteractionPos) or nil,
        bedId = data and data.bedId or bed and (bed.id or bed.recordId),
        initialPlacement = data and data.initialPlacement == true,
        state = data and data.state or 'assigned',
        registeredAt = now(),
    }
    debugLog('sleep lights batch pending sleepers count', tostring(pendingSleeperCount(actor.cell)), 'registered', tostring(actor.recordId or actor.id))
end

function module.clearPendingSleeper(actorOrId, reason, rejected)
    local actorId = objectId(actorOrId)
    if not actorId or not pendingSleepers[actorId] then return end
    local anchor = pendingSleepers[actorId]
    pendingSleepers[actorId] = nil
    debugLog('sleep lights batch pending sleepers count', tostring(pendingSleeperCount(currentCell)), 'cleared', tostring(actorId), 'reason', tostring(reason or 'cleared'))
    if rejected == true then
        cancelPendingOffForActor(actorId, reason or 'sleep_rejected')
        if restoreHoldActive(reason or 'sleep_rejected_bedside_restore') then
            debugLog('sleep lights pending sleeper restore held', 'actor', tostring(actorId), 'reason', tostring(reason), 'holdReason', tostring(restoreHoldReason))
            reevaluateActiveSleepers(reason or 'sleep_rejected_restore_held', true)
        else
            restoreEntriesNearAnchor(anchor, reason or 'sleep_rejected_bedside_restore', true, settings.lightControlRejectedSleepBedsideRestoreRadius or settings.lightControlPlayerWakeBedsideRestoreRadius)
        end
    elseif pendingSleeperCount(currentCell) == 0 then
        reevaluateActiveSleepers(reason or 'pending_batch_complete', true)
    end
end

function module.registerSleeper(actor, data, immediate)
    if not settings.enableLightControl then return end
    if not isValid(actor) then return end
    module.clearPendingSleeper(actor, data and data.initialPlacement == true and 'pending_accepted_initial' or 'pending_accepted', false)
    local pos = data and (data.finalPosition or data.position) or actor.position
    local bed = data and data.bed or data and data.object
    if bed and isValid(bed) and bed.position then pos = data.finalPosition or bed.position or pos end
    if not pos then return end
    local initialPlacement = data and data.initialPlacement == true
    local visibleSleep = not initialPlacement
    if data and data.visibleSleep ~= nil then visibleSleep = data.visibleSleep == true end

    local anchor = {
        actor = actor,
        actorId = actor.id,
        actorRecordId = actor.recordId,
        cell = actor.cell,
        position = pos,
        bedPosition = bed and isValid(bed) and bed.position or nil,
        approachPosition = data and data.approachPosition or data and data.approachPos or nil,
        floorPosition = data and data.exitPosition or data and data.floorPosition or data and data.approachPosition or data and data.approachPos or nil,
        originPosition = data and positionValue(data.originPosition or data.preInteractionPosition or data.preInteractionPos) or nil,
        bedId = data and data.bedId or bed and (bed.id or bed.recordId),
        initialPlacement = initialPlacement,
        visibleSleep = visibleSleep,
        registeredAt = now(),
    }
    sleepers[actor.id] = anchor
    sleepLightAnchors[actor.id] = anchor
    evaluateAnchor(anchor, immediate == true)
    if initialPlacement ~= true then
        schedulePostEntryReevaluate('post_sleep_entry_awake_light_check', settings.lightControlPostEntryReevaluateDelay or 0.35)
    end
    if initialPlacement == true then
        reevaluateActiveSleepers('initial_sleeper_registered', immediate == true)
    end
end

function module.unregisterSleeper(actorOrId, reason, immediate)
    local actorId = objectId(actorOrId)
    module.clearPendingSleeper(actorId, reason or 'unregister', tostring(reason or ''):find('reject', 1, true) ~= nil or tostring(reason or ''):find('failed', 1, true) ~= nil)
    local anchor = actorId and (sleepers[actorId] or sleepLightAnchors[actorId]) or nil
    local cancelledPendingOff = cancelPendingOffForActor(actorId, reason)
    debugLog('sleep lights unregister sleeper', 'actor', tostring(actorId), 'reason', tostring(reason), 'hadAnchor', tostring(anchor ~= nil), 'active', tostring((function() local n=0; for _ in pairs(saveData.activeReplacements or {}) do n=n+1 end; return n end)()), 'cancelledPendingOff', tostring(cancelledPendingOff))
    if not anchor and objectPosition(actorOrId) then
        anchor = {
            actor = actorOrId,
            actorId = actorId,
            actorRecordId = objectRecordId(actorOrId),
            cell = objectCell(actorOrId),
            position = objectPosition(actorOrId),
        }
    end
    if actorId then sleepers[actorId] = nil end

    if isPlayerVisibleWakeReason(reason) and anchor then
        -- Player wake/disturbance is a visible event, even if the sleeper was initially placed
        -- during cell entry. Restore only the immediate/same-floor bedside band.
        anchor.initialPlacement = false
        anchor.visibleSleep = true
        -- Player wake gets a hard immediate bedside restore in every interior type.
        -- Private homes stop there; public/shared interiors can restore any other
        -- no-longer-needed owned lights using the ordinary short varied delay.
        local restored = restoreEntriesNearAnchor(anchor, reason, true, settings.lightControlPlayerWakeBedsideRestoreRadius)
        if restored == 0 then
            restored = restoreClosestEntriesNearAnchor(anchor, reason, true, 3)
        end
        if restored == 0 then
            restoreOwnedEntriesForActor(anchor, reason, true, 6)
        end
        module.processPending(true)
        if anchor.cell and isPrivateSleepContext(anchor.cell) then
            return
        end
        restoreNoLongerNeeded(reason, false)
        return
    end

    if LOCAL_RESTORE_REJECT_REASONS[tostring(reason or '')] and anchor then
        anchor.initialPlacement = false
        anchor.visibleSleep = true
        if restoreHoldActive(reason or 'sleep_rejected_bedside_restore') then
            debugLog('sleep lights route reject restore held', 'actor', tostring(actorId), 'reason', tostring(reason), 'holdReason', tostring(restoreHoldReason))
            reevaluateActiveSleepers(reason or 'sleep_rejected_restore_held', immediate == true)
        else
            restoreEntriesNearAnchor(anchor, reason or 'sleep_rejected_bedside_restore', immediate == true, settings.lightControlRejectedSleepBedsideRestoreRadius or settings.lightControlPlayerWakeBedsideRestoreRadius)
            module.processPending(immediate == true)
        end
        return
    end

    if RESTORE_REASON_WAKE[tostring(reason or '')] and anchor then
        anchor.initialPlacement = false
        anchor.visibleSleep = true
        restoreWakeEntriesNearAnchor(anchor, reason or 'wake_bedside_restore', true, settings.lightControlPlayerWakeBedsideRestoreRadius)
        if sleeperCount() <= 0 then
            restoreAll(reason or 'all_sleepers_awake', true)
        end
        module.processPending(true)
        return
    end

    restoreNoLongerNeeded(reason or 'wake', immediate == true)
end

function module.clearSleepers(reason)
    sleepers = {}
    sleepLightAnchors = {}
    postEntryReevaluateAt = nil
    postEntryReevaluateReason = nil
    restoreNoLongerNeeded(reason or 'clear', false)
end

function module.isActorSleeping(actorOrId)
    local actorId = objectId(actorOrId)
    return actorId ~= nil and sleepers[actorId] ~= nil
end

function module.getSleepingActors()
    return sleepers
end

function module.processPending(immediate)
    local batchSize = tonumber(settings.lightControlBatchSize or 4) or 4
    if immediate then batchSize = math.max(batchSize, math.min(64, batchSize * 8)) end
    if batchSize < 1 then batchSize = 1 end

    local processed = 0
    local i = 1
    while i <= #pendingOps and processed < batchSize do
        local op = pendingOps[i]
        table.remove(pendingOps, i)
        if op and op.key then pendingSet[op.key] = nil end
        processed = processed + 1

        if op and op.kind == 'off' then
            local p = op.payload or {}
            local light = p.object
            if isValid(light) and light.recordId == p.recordId then
                local newObj, err = replaceObject(light, p.offRecordId)
                if newObj then
                    saveData.activeReplacements[newObj.id] = {
                        offObject = newObj,
                        offObjectId = newObj.id,
                        originalObjectId = p.objectId,
                        originalRecordId = p.recordId,
                        offRecordId = p.offRecordId,
                        position = newObj.position,
                        cellKey = p.cellKey,
                        anchorActorId = p.anchorActorId,
                    }
                    clearLightCache('light_replaced_off')
                    debugLog('sleep light off', tostring(p.recordId), 'object', tostring(p.objectId), 'offObject', tostring(newObj.id), 'category', tostring(p.category), 'dist', tostring(p.distanceFromAnchor), '->', tostring(p.offRecordId))
                elseif not isZeroCountRemoveError(err) then
                    debugLog('sleep light off failed', tostring(p.recordId), tostring(err))
                end
            end
        elseif op and op.kind == 'restore' then
            local p = op.payload or {}
            local entry = saveData.activeReplacements[p.activeKey]
            local offObj = entry and entry.offObject or p.offObject
            local originalRecordId = entry and entry.originalRecordId or p.originalRecordId
            if isValid(offObj) and originalRecordId then
                local newObj, err = replaceObject(offObj, originalRecordId, { recoverZeroCount = true })
                if newObj then
                    saveData.activeReplacements[p.activeKey] = nil
                    clearLightCache('light_restored')
                    debugLog('sleep light restore', tostring(originalRecordId), 'offObject', tostring(p.activeKey), 'reason', tostring(p.reason))
                else
                    debugLog('sleep light restore failed', tostring(originalRecordId), tostring(err))
                end
            else
                saveData.activeReplacements[p.activeKey] = nil
            end
        end
    end

    local t = now()
    if postEntryReevaluateAt and postEntryReevaluateAt <= t then
        local reason = postEntryReevaluateReason or 'post_sleep_entry_awake_light_check'
        postEntryReevaluateAt = nil
        postEntryReevaluateReason = nil
        reevaluateActiveSleepers(reason, true)
    end
    for activeKey, due in pairs(restoreDelay) do
        if due <= t then
            local entry = saveData.activeReplacements[activeKey]
            if entry then
                if activeReplacementStillRelevant(entry) then
                    debugLog('restore skipped because other sleeper still active', 'activeKey', tostring(activeKey), 'sleepers', tostring(sleeperCount()), 'reason', 'delayed_restore')
                    restoreDelay[activeKey] = nil
                elseif restoreHoldActive('delayed_restore') then
                    restoreDelay[activeKey] = (restoreHoldUntil or t) + 2
                    debugLog('restore delayed by night sleep release hold', 'activeKey', tostring(activeKey), 'holdReason', tostring(restoreHoldReason), 'reason', 'delayed_restore')
                elseif pendingOffCount() > 0 then
                    restoreDelay[activeKey] = t + 2
                    debugLog('restore delayed because assignment still pending', 'activeKey', tostring(activeKey), 'pendingOff', tostring(pendingOffCount()), 'reason', 'delayed_restore')
                else
                    queueRestore(activeKey, entry, false, 'delayed_restore')
                    restoreDelay[activeKey] = nil
                end
            else
                restoreDelay[activeKey] = nil
            end
        end
    end
end

function module.onLoad(data)
    saveData = data or {}
    saveData.generatedRecords = saveData.generatedRecords or {}
    saveData.reverseRecordLookup = saveData.reverseRecordLookup or {}
    saveData.activeReplacements = saveData.activeReplacements or {}
    for _, entry in pairs(saveData.activeReplacements) do
        if entry then
            entry.offObject = nil
        end
    end
    -- Object references from a prior session are deliberately discarded on load.
    -- Current-cell recovery reacquires off-lights by record/position instead.
end

function module.onSave()
    local active = {}
    for key, entry in pairs(saveData.activeReplacements or {}) do
        if entry and entry.offRecordId and entry.originalRecordId then
            local activeKey = tostring(entry.offObjectId or key)
            active[activeKey] = {
                offObjectId = entry.offObjectId,
                originalObjectId = entry.originalObjectId,
                originalRecordId = entry.originalRecordId,
                offRecordId = entry.offRecordId,
                position = entry.position,
                cellKey = entry.cellKey,
                anchorActorId = entry.anchorActorId,
            }
        end
    end
    return {
        generatedRecords = saveData.generatedRecords or {},
        reverseRecordLookup = saveData.reverseRecordLookup or {},
        activeReplacements = active,
    }
end


function module.restoreAll(reason, immediate)
    return restoreAll(reason or 'restore_all', immediate == true)
end

function module.restoreNearActor(actorOrId, reason, immediate, radius)
    local actorId = objectId(actorOrId)
    local anchor = actorId and sleepers[actorId]
    if not anchor and objectPosition(actorOrId) then
        anchor = { actorId = actorId, actorRecordId = objectRecordId(actorOrId), cell = objectCell(actorOrId), position = objectPosition(actorOrId) }
    end
    return restoreWakeEntriesNearAnchor(anchor, reason or 'restore_near_actor', immediate == true, radius)
end

function module.restoreNearActorThrottled(actorOrId, reason, immediate, radius, opts)
    if activeReplacementCount() <= 0 then return 0, "no_active_replacements" end
    local actorId = objectId(actorOrId)
    local pos = objectPosition(actorOrId)
    if not (actorId and pos) then return 0, "missing_actor_position" end

    opts = opts or {}
    local now = core.getSimulationTime() or 0
    local minInterval = tonumber(opts.minInterval or 0.75) or 0.75
    local minMove = tonumber(opts.minMove or 90) or 90
    local state = wakePathRestoreState[actorId]
    if state then
        local elapsed = now - (tonumber(state.at) or 0)
        local moved = state.position and (pos - state.position):length() or math.huge
        if elapsed < minInterval and moved < minMove then return 0, "throttled" end
    end

    wakePathRestoreState[actorId] = { at = now, position = pos }
    return module.restoreNearActor(actorOrId, reason or 'restore_near_actor_throttled', immediate == true, radius)
end

function module.holdRestores(reason, seconds)
    local duration = tonumber(seconds) or 30
    if duration < 1 then duration = 1 end
    local untilTime = now() + duration
    if not restoreHoldUntil or untilTime > restoreHoldUntil then
        restoreHoldUntil = untilTime
        restoreHoldReason = reason or 'sleep_restore_hold'
    end
    debugLog('sleep lights restore hold', 'reason', tostring(reason), 'seconds', tostring(duration), 'until', tostring(restoreHoldUntil))
    return true
end

function module.requestSleepLightsOff(payload)
    if not settings.enableLightControl then return false, "disabled" end
    payload = payload or {}
    local cell = currentCell or (world.players[1] and world.players[1].cell)
    if not cell then return false, "missing_cell" end

    local anchors = payload.anchors or {}
    local count = 0
    for _, item in ipairs(anchors) do
        local pos = item and item.position
        if pos then
            local anchor = {
                actorId = item.actorId or objectId(item.actor),
                actorRecordId = item.actorRecordId or objectRecordId(item.actor) or item.actorId,
                bedId = item.bedId,
                cell = cell,
                position = pos,
                bedPosition = item.bedPosition,
                approachPosition = item.approachPosition or item.approachPos,
                floorPosition = item.floorPosition or item.exitPosition or item.approachPosition or item.approachPos,
                originPosition = positionValue(item.originPosition or item.preInteractionPosition or item.preInteractionPos),
                initialPlacement = item.initialPlacement == true,
                visibleSleep = not (item.initialPlacement == true),
            }
            evaluateAnchor(anchor, payload.immediate == true)
            count = count + 1
        end
    end
    debugLog('sleep lights external off request', 'source', tostring(payload.source), 'anchors', tostring(count))
    return true, count
end

function module.requestSleepLightsRestore(payload)
    payload = payload or {}
    restoreNoLongerNeeded(payload.reason or 'external_restore', payload.immediate == true or payload.restoreAllForSourceInCell == true)
    debugLog('sleep lights external restore request', 'source', tostring(payload.source), 'reason', tostring(payload.reason))
    return true
end

function module.getStatus()
    local sleeperCount = 0
    for _ in pairs(sleepers) do sleeperCount = sleeperCount + 1 end
    local activeCount = 0
    for _ in pairs(saveData.activeReplacements or {}) do activeCount = activeCount + 1 end
    return {
        version = 1,
        enabled = settings.enableLightControl == true,
        sleepers = sleeperCount,
        activeReplacements = activeCount,
        pending = #pendingOps,
    }
end

function module.noteCompanionState(data)
    if not data then return end
    local actor = data.actor
    local actorId = data.actorId or objectId(actor)
    if not actorId then return end
    if data.isFollower == true or data.isCompanion == true then
        companionActors[actorId] = true
    else
        companionActors[actorId] = nil
    end
end

return module
