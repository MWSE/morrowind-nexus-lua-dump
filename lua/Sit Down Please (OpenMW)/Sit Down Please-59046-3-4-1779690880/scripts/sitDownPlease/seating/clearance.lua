-- seating/clearance.lua
--
-- Local-script sitting clearance checks. The module receives OpenMW-local
-- helpers from interactionSeeker.lua so it does not require global-only APIs.

local M = {}
local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')

local function normalizeDirection3(util, v)
    if not v then return nil end
    local x, y = v.x or 0, v.y or 0
    local len = math.sqrt(x * x + y * y)
    if len <= 0.001 then return nil end
    return util.vector3(x / len, y / len, 0)
end

local function directionDot2(a, b)
    if not (a and b) then return -1 end
    return (a.x or 0) * (b.x or 0) + (a.y or 0) * (b.y or 0)
end

local function nearestFrontObstacleDistance(env, finalPos, direction)
    local dir = normalizeDirection3(env.util, direction)
    if not (finalPos and dir and env.nearby and env.nearby.castRay and env.nearby.COLLISION_TYPE) then return nil end
    local best = nil
    local bestObject = nil
    for _, z in ipairs({ 24, 38, 52, 66 }) do
        local from = finalPos + env.util.vector3(0, 0, z)
        local to = from + dir * 58
        local result = env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
        if result.hit and result.hitPos and not env.rayHitBelongsToObject(result.hitObject, env.currentObject()) then
            local dist = (result.hitPos - from):length()
            if not best or dist < best then
                best = dist
                bestObject = result.hitObject
            end
        end
    end
    return best, bestObject
end

local function focusBlockDistance(env, finalPos, facingDirection, data)
    if not (finalPos and facingDirection and data and (data.facingKind == "table" or data.facingKind == "bar") and data.facingObjectPosition) then return nil end
    local toFocus = data.facingObjectPosition - finalPos
    local flatDist = math.sqrt((toFocus.x or 0) * (toFocus.x or 0) + (toFocus.y or 0) * (toFocus.y or 0))
    if flatDist <= 1 or flatDist > 185 then return nil end
    local toFocusDir = normalizeDirection3(env.util, toFocus)
    if not toFocusDir then return nil end
    if directionDot2(toFocusDir, facingDirection) < 0.25 then return nil end
    return flatDist
end

local function nearestBodyObstacleDistance(env, finalPos, facingDirection, category, actorScale)
    local dir = normalizeDirection3(env.util, facingDirection)
    if not (finalPos and dir and env.nearby and env.nearby.castRay and env.nearby.COLLISION_TYPE) then return nil end
    local right = env.util.vector3(dir.y, -dir.x, 0)
    local scale = tonumber(actorScale or 1) or 1
    if scale < 0.75 then scale = 0.75 elseif scale > 1.35 then scale = 1.35 end
    local rayDistance = (category == "backed_chair" and 42 or 30) * scale
    local directions = { dir, dir * -1, right, right * -1 }
    if category == "backed_chair" then
        directions[#directions + 1] = normalizeDirection3(env.util, dir + right)
        directions[#directions + 1] = normalizeDirection3(env.util, dir - right)
        directions[#directions + 1] = normalizeDirection3(env.util, (dir * -1) + right)
        directions[#directions + 1] = normalizeDirection3(env.util, (dir * -1) - right)
    end

    local best = nil
    local bestObject = nil
    for _, testDir in ipairs(directions) do
        testDir = normalizeDirection3(env.util, testDir)
        if testDir then
            for _, z in ipairs({ 30, 46, 62 }) do
                local from = finalPos + env.util.vector3(0, 0, z * scale)
                local to = from + testDir * rayDistance
                local result = env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
                if result.hit and result.hitPos and not env.rayHitBelongsToObject(result.hitObject, env.currentObject()) then
                    local dist = (result.hitPos - from):length()
                    if not best or dist < best then
                        best = dist
                        bestObject = result.hitObject
                    end
                end
            end
        end
    end
    return best, bestObject
end

local function objectRecord(obj)
    if not obj then return nil end
    local ok, recordId = pcall(function() return obj.recordId end)
    if ok and recordId then return recordId end
    ok, recordId = pcall(function() return obj.id end)
    if ok then return recordId end
    return nil
end

local function objectModel(env, obj)
    if not (env and env.objectModelPath and obj) then return nil end
    local ok, model = pcall(env.objectModelPath, obj)
    if ok then return model end
    return nil
end

local function objectName(env, obj)
    if not obj then return nil end
    if env and env.objectName then
        local ok, name = pcall(env.objectName, obj)
        if ok then return name end
    end
    return nil
end

local function flatDistance(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function normalizedCategory(category)
    category = (tostring(category or ""):lower():match("^%s*(.-)%s*$")) or ""
    if category == "chair" or category == "backedchair" then return "backed_chair" end
    if category == "bar stool" or category == "bar-stool" then return "barstool" end
    if category == "directionalstool" or category == "directional_stool" or category == "directional stool" or category == "directional-stool" then return "single_seat_bench" end
    if category == "single seat bench" or category == "single-seat-bench" or category == "singleseatbench" then return "single_seat_bench" end
    return category
end

function M.manualAssignMayBypassSittingClearance(data, clearanceMeta, category)
    if not data or data.manualAssignOverrideTesting ~= true then return false end
    return true
end

local function objectLooksTableOrCounter(env, obj)
    return objectMatchers.objectLooksLikeTableOrBarSurface(obj, function(target) return objectModel(env, target) end, objectName(env, obj))
end

local function objectLooksStool(env, obj)
    local record = tostring(objectRecord(obj) or ""):lower()
    local model = tostring(objectModel(env, obj) or ""):lower()
    local name = tostring(objectName(env, obj) or ""):lower()
    local text = record .. " " .. model .. " " .. name
    return text:find("barstool", 1, true) ~= nil or text:find("stool", 1, true) ~= nil
end

local function isRelevantBarFocusBlocker(env, data, blocker)
    if not (data and data.facingKind == "bar" and blocker) then return false end
    if data.facingObject and blocker == data.facingObject then return true end
    return objectLooksTableOrCounter(env, blocker)
end

local function isRelevantTableOrBarFocusBlocker(env, data, blocker)
    if not (data and (data.facingKind == "table" or data.facingKind == "bar") and blocker) then return false end
    if data.facingObject and blocker == data.facingObject then return true end
    return objectLooksTableOrCounter(env, blocker)
end

local function candidateRecord(candidate)
    return candidate and (candidate.recordId or objectRecord(candidate.object)) or nil
end

local function candidateModel(env, candidate)
    return candidate and (candidate.model or objectModel(env, candidate.object)) or nil
end

local function candidateName(env, candidate)
    return candidate and (candidate.name or objectName(env, candidate.object)) or nil
end

local function candidateObject(candidate)
    return candidate and candidate.object or nil
end

local function candidatePosition(candidate)
    return candidate and (candidate.position or (candidate.object and candidate.object.position)) or nil
end

local function candidateLooksTableOrCounter(env, candidate)
    if not candidate then return false end
    if candidate.object and objectLooksTableOrCounter(env, candidate.object) then return true end
    local text = objectMatchers.surfaceText(candidate.recordId, candidate.model, candidate.name, candidate.kind)
    return objectMatchers.textLooksLikeTableOrBarSurface(text)
end

local function addTableCandidate(env, list, seen, candidate)
    if not candidate or not candidateLooksTableOrCounter(env, candidate) then return end
    local pos = candidatePosition(candidate)
    if not pos then return end
    local key = tostring(candidate.recordId or objectRecord(candidate.object) or "?") .. "@" .. tostring(math.floor(pos.x or 0)) .. "," .. tostring(math.floor(pos.y or 0)) .. "," .. tostring(math.floor(pos.z or 0))
    if seen[key] then return end
    seen[key] = true
    list[#list + 1] = candidate
end

local function collectTableCandidates(env, data, bodyPoint, kneePoint, chairPos)
    local candidates = {}
    local seen = {}
    if data and data.facingObject then
        addTableCandidate(env, candidates, seen, {
            object = data.facingObject,
            recordId = data.facingObjectId,
            model = data.facingObjectModel,
            kind = data.facingKind,
            position = data.facingObjectPosition or data.facingObject.position,
            source = data.facingSurfaceSource,
            surfaceHit = data.facingSurfaceHit == true,
        })
    elseif data and data.facingObjectPosition then
        addTableCandidate(env, candidates, seen, {
            recordId = data.facingObjectId,
            model = data.facingObjectModel,
            kind = data.facingKind,
            position = data.facingObjectPosition,
            source = data.facingSurfaceSource,
            surfaceHit = data.facingSurfaceHit == true,
        })
    end
    for _, candidate in ipairs(data and data.facingCandidates or {}) do
        addTableCandidate(env, candidates, seen, candidate)
    end
    table.sort(candidates, function(a, b)
        local apos, bpos = candidatePosition(a), candidatePosition(b)
        local ad = math.min(flatDistance(apos, bodyPoint), flatDistance(apos, kneePoint), flatDistance(apos, chairPos))
        local bd = math.min(flatDistance(bpos, bodyPoint), flatDistance(bpos, kneePoint), flatDistance(bpos, chairPos))
        return ad < bd
    end)
    return candidates
end

local function tableOverlapStatus(env, candidate, finalPos, kneePoint, chairPos, dir, scale)
    local pos = candidatePosition(candidate)
    if not pos then return false, "no_position", nil end
    local bodyDistance = flatDistance(pos, finalPos)
    local kneeDistance = flatDistance(pos, kneePoint)
    local chairDistance = flatDistance(pos, chairPos)
    local text = objectMatchers.surfaceText(candidateRecord(candidate), candidateModel(env, candidate), candidateName(env, candidate), candidate.kind)
    local surfaceKind = objectMatchers.surfaceKindFromText(text) or "surface"
    local broadSurface = surfaceKind == "bar"
    local tabletopReach = (broadSurface and 190 or 155) * scale
    local bodyReach = (broadSurface and 145 or 120) * scale
    local chairReach = (broadSurface and 220 or 185) * scale
    local vertical = (pos.z or 0) - (finalPos.z or 0)
    local verticalOk = vertical >= -85 * scale and vertical <= 145 * scale
    local horizontalOk = kneeDistance <= tabletopReach or bodyDistance <= bodyReach or (chairDistance <= chairReach and kneeDistance <= tabletopReach + 42 * scale)
    local kneeOverlapReach = (broadSurface and 140 or 108) * scale
    local bodyOverlapReach = (broadSurface and 120 or 86) * scale
    local chairOverlapReach = (broadSurface and 170 or 140) * scale
    local tightChairBodyOverlap = chairDistance <= (62 * scale) and bodyDistance <= (100 * scale) and kneeDistance <= tabletopReach
    local horizontalOverlap = kneeDistance <= kneeOverlapReach or bodyDistance <= bodyOverlapReach or (chairDistance <= chairOverlapReach and kneeDistance <= kneeOverlapReach + 12 * scale) or tightChairBodyOverlap
    local toTable = normalizeDirection3(env.util, {
        x = (pos.x or 0) - (finalPos.x or 0),
        y = (pos.y or 0) - (finalPos.y or 0),
        z = 0,
    })
    local frontDot = directionDot2(toTable, dir)
    local strictBodyOverlapReach = bodyOverlapReach * 0.65
    -- Do not reject ordinary tucked backed chairs. Knee proximity to a table is
    -- expected; reject only when the body is inside the furniture or the front
    -- test point is almost touching it.
    local tightConfirmedLegroomBlock = candidate.surfaceHit == true
        and verticalOk
        and frontDot > 0.45
        and chairDistance <= (64 * scale)
        and kneeDistance <= (118 * scale)
        and bodyDistance <= (140 * scale)
    local actualOverlap = horizontalOverlap and verticalOk and (
        bodyDistance <= strictBodyOverlapReach
        or kneeDistance <= (24 * scale)
        or (frontDot > 0.65 and kneeDistance <= (32 * scale))
        or tightChairBodyOverlap
        or tightConfirmedLegroomBlock
    )
    local reason = nil
    if not verticalOk then reason = "vertical_mismatch"
    elseif not horizontalOk then reason = "too_far"
    elseif not actualOverlap then reason = "no_overlap" end
    return actualOverlap, reason, {
        bodyDistance = bodyDistance,
        kneeDistance = kneeDistance,
        chairDistance = chairDistance,
        vertical = vertical,
        frontDot = frontDot,
        tabletopReach = tabletopReach,
        bodyReach = bodyReach,
        chairReach = chairReach,
        kneeOverlapReach = kneeOverlapReach,
        bodyOverlapReach = bodyOverlapReach,
        strictBodyOverlapReach = strictBodyOverlapReach,
        chairOverlapReach = chairOverlapReach,
        tightChairBodyOverlap = tightChairBodyOverlap,
        tightConfirmedLegroomBlock = tightConfirmedLegroomBlock,
        surfaceKind = surfaceKind,
        surfaceSource = candidate.source,
        surfaceHit = candidate.surfaceHit == true,
    }
end


local function logDecision(env, profile, finalPos, blocker, distance, actorScale, decision, meta)
    if not (env and env.debugLog) then return end
    local source = "fallback"
    if profile and profile.externalProfile == true then source = "explicit_profile"
    elseif profile and profile.profileId == "fallback_backed_chair" then source = "fallback_backed_chair"
    elseif profile and profile.profileId == "fallback_stool" then source = "fallback_stool" end
    env.debugLog(
        "seat clearance decision",
        "profile", tostring(profile and profile.profileId),
        "seat clearance profile source", source,
        "seat clearance final pose after profile", tostring(finalPos),
        "seat clearance blocker chosen", tostring(objectRecord(blocker)), tostring(objectModel(env, blocker)),
        "seat clearance result", tostring(decision),
        "clearance profile used", tostring(profile and profile.profileId),
        "final body point", tostring(finalPos),
        "nearest blocker record/model", tostring(objectRecord(blocker)), tostring(objectModel(env, blocker)),
        "blocker distance", tostring(distance),
        "actor scale", tostring(actorScale),
        "decision", tostring(decision),
        "meta", tostring(meta)
    )
end

local function logBackedChairClearance(env, label, profile, finalPos, kneePoint, blocker, distance, threshold, actorScale)
    if not (env and env.debugLog) then return end
    env.debugLog(
        label,
        "profile", tostring(profile and profile.profileId),
        "blocker record/model", tostring(objectRecord(blocker)), tostring(objectModel(env, blocker)),
        "blocker distance", tostring(distance),
        "threshold", tostring(threshold),
        "actor scale", tostring(actorScale),
        "final body point", tostring(finalPos),
        "final knee/front test point", tostring(kneePoint)
    )
end

local function logTableCandidate(env, candidate, meta)
    if not (env and env.debugLog and candidate) then return end
    env.debugLog(
        "seat clearance blocker candidate table/counter",
        tostring(candidateRecord(candidate)),
        tostring(candidateModel(env, candidate)),
        "name", tostring(candidateName(env, candidate)),
        "bodyDistance", tostring(meta and meta.bodyDistance),
        "kneeDistance", tostring(meta and meta.kneeDistance),
        "chairDistance", tostring(meta and meta.chairDistance),
        "vertical", tostring(meta and meta.vertical),
        "frontDot", tostring(meta and meta.frontDot),
        "surfaceKind", tostring(meta and meta.surfaceKind),
        "surfaceSource", tostring(meta and meta.surfaceSource),
        "surfaceHit", tostring(meta and meta.surfaceHit),
        "tightConfirmedLegroomBlock", tostring(meta and meta.tightConfirmedLegroomBlock)
    )
end

function M.rejectSittingFinalIfBlocked(env, finalPos, facingDirection, profile, data)
    if not (env and finalPos and facingDirection and profile) then return finalPos, nil end
    if profile.unsafeIfBlocked ~= true then return finalPos, nil end

    local dir = normalizeDirection3(env.util, facingDirection)
    if not dir then return finalPos, nil end

    local currentObject = env.currentObject and env.currentObject() or nil
    local category = normalizedCategory(env.sittingSeatCategory(profile, currentObject))
    local isStool = category == "stool" or category == "barstool" or objectLooksStool(env, currentObject)
    local isBacklessTableSeat = isStool or category == "bench" or category == "single_seat_bench"
    local actorScale = env.actorScale and env.actorScale() or 1
    local scale = tonumber(actorScale or 1) or 1
    if scale < 0.75 then scale = 0.75 elseif scale > 1.35 then scale = 1.35 end

    local distance, frontBlocker = nearestFrontObstacleDistance(env, finalPos, dir)
    local focusDistance = focusBlockDistance(env, finalPos, dir, data)
    local bodyDistance, bodyBlocker = nearestBodyObstacleDistance(env, finalPos, dir, category, scale)

    local frontLimit = (isBacklessTableSeat and 18 or (category == "backed_chair" and 28 or 38)) * scale
    local focusLimit = isBacklessTableSeat and nil or (88 * scale)
    local bodyLimit = (category == "backed_chair" and 30 or (isBacklessTableSeat and 15 or 24)) * scale
    local backedTableLimit = 44 * scale
    local kneePoint = finalPos + dir * (category == "backed_chair" and 34 * scale or 24 * scale)

    if category == "backed_chair" then
        local tableDistance, tableBlocker = nil, nil
        if bodyDistance and objectLooksTableOrCounter(env, bodyBlocker) then
            tableDistance, tableBlocker = bodyDistance, bodyBlocker
        elseif distance and objectLooksTableOrCounter(env, frontBlocker) then
            tableDistance, tableBlocker = distance, frontBlocker
        elseif focusDistance and data and data.facingObject then
            tableDistance, tableBlocker = focusDistance, data.facingObject
        end
        local checkedDistance = tableDistance or bodyDistance or distance or focusDistance
        local checkedBlocker = tableBlocker or bodyBlocker or frontBlocker or (data and data.facingObject)
        local tableCandidates = collectTableCandidates(env, data, finalPos, kneePoint, currentObject and currentObject.position or finalPos)
        if env and env.debugLog then
            env.debugLog("seat clearance blocker search candidates count", tostring(#tableCandidates), "profile", tostring(profile and profile.profileId))
            if #tableCandidates == 0 then
                env.debugLog("seat clearance blocker search failed no_table_counter_candidates", "profile", tostring(profile and profile.profileId), "final body point", tostring(finalPos), "final knee/front test point", tostring(kneePoint))
            end
        end
        for _, candidate in ipairs(tableCandidates) do
            local rejects, ignoreReason, meta = tableOverlapStatus(env, candidate, finalPos, kneePoint, currentObject and currentObject.position or finalPos, dir, scale)
            logTableCandidate(env, candidate, meta)
            if rejects then
                local blocker = candidateObject(candidate)
                if env and env.debugLog then env.debugLog("backed_chair_tabletop_overlap_rejected", "actual_overlap") end
                logBackedChairClearance(env, "backed_chair_tabletop_overlap_rejected", profile, finalPos, kneePoint, blocker, meta and meta.kneeDistance, backedTableLimit, scale)
                logBackedChairClearance(env, "backed_chair_table_clearance_rejected", profile, finalPos, kneePoint, blocker, meta and meta.kneeDistance, backedTableLimit, scale)
                logDecision(env, profile, finalPos, blocker, meta and meta.kneeDistance, scale, "tight_table_or_counter_rejected", "tabletopOverlap=true")
                return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", tabletopOverlap = true, tableDistance = meta and meta.kneeDistance, tableLimit = meta and meta.tabletopReach, blockerRecord = candidateRecord(candidate), blockerModel = candidateModel(env, candidate), blockerDistance = meta and meta.kneeDistance, vertical = meta and meta.vertical, category = category }
            elseif ignoreReason == "too_far" then
                logBackedChairClearance(env, "backed_chair_table_candidate_ignored_too_far", profile, finalPos, kneePoint, candidateObject(candidate), meta and meta.kneeDistance, meta and meta.tabletopReach, scale)
            elseif ignoreReason == "vertical_mismatch" then
                logBackedChairClearance(env, "backed_chair_table_candidate_ignored_vertical_mismatch", profile, finalPos, kneePoint, candidateObject(candidate), meta and meta.kneeDistance, meta and meta.tabletopReach, scale)
            else
                logBackedChairClearance(env, "backed_chair_table_candidate_ignored_no_overlap", profile, finalPos, kneePoint, candidateObject(candidate), meta and meta.kneeDistance, meta and meta.tabletopReach, scale)
            end
        end
        logBackedChairClearance(env, "backed_chair_table_clearance_checked", profile, finalPos, kneePoint, checkedBlocker, checkedDistance, backedTableLimit, scale)
        logBackedChairClearance(env, checkedBlocker and "backed_chair_table_clearance_accepted_no_overlap" or "backed_chair_table_clearance_accepted_no_blocker", profile, finalPos, kneePoint, checkedBlocker, checkedDistance, backedTableLimit, scale)
        if bodyDistance and objectLooksTableOrCounter(env, bodyBlocker) then
            bodyDistance = nil
            bodyBlocker = nil
        end
        if distance and objectLooksTableOrCounter(env, frontBlocker) then
            distance = nil
            frontBlocker = nil
        end
        if data and data.facingObject and objectLooksTableOrCounter(env, data.facingObject) then
            focusDistance = nil
        end
    end

    if isBacklessTableSeat and data and data.facingKind == "bar" then
        local blocker = bodyBlocker or frontBlocker or data.facingObject
        local blockerDistance = bodyDistance or distance or focusDistance
        if isRelevantBarFocusBlocker(env, data, blocker) and (not blockerDistance or blockerDistance >= (4 * scale)) then
            logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "accepted_bar_focus_tight_stool", "category=" .. tostring(category))
            if env and env.debugLog then
                env.debugLog("barstool final clearance accepted", "category", tostring(category), "final", tostring(finalPos), "focus", "bar")
            end
            return finalPos, nil, { result = "accepted_bar_focus_tight_stool", category = category, blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance }
        end
    end

    if isBacklessTableSeat and data and data.facingKind == "table" then
        local blocker = bodyBlocker or frontBlocker or data.facingObject
        local blockerDistance = bodyDistance or distance or focusDistance
        if isRelevantTableOrBarFocusBlocker(env, data, blocker) and (not blockerDistance or blockerDistance >= (8 * scale)) then
            logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "accepted_table_focus_tight_stool", "category=" .. tostring(category))
            if env and env.debugLog then
                env.debugLog("stool table-focus clearance accepted", "category", tostring(category), "final", tostring(finalPos), "focus", "table")
            end
            return finalPos, nil, { result = "accepted_table_focus_tight_stool", category = category, blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance }
        end
    end

    if bodyDistance and bodyDistance < bodyLimit then
        logDecision(env, profile, finalPos, bodyBlocker, bodyDistance, scale, "tight_table_or_counter_rejected", "bodyLimit=" .. tostring(bodyLimit))
        return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", bodyDistance = bodyDistance, bodyLimit = bodyLimit, blockerRecord = objectRecord(bodyBlocker), blockerModel = objectModel(env, bodyBlocker), blockerDistance = bodyDistance, category = category }
    end
    if distance and distance < frontLimit then
        logDecision(env, profile, finalPos, frontBlocker, distance, scale, "tight_table_or_counter_rejected", "frontLimit=" .. tostring(frontLimit))
        return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", frontDistance = distance, frontLimit = frontLimit, blockerRecord = objectRecord(frontBlocker), blockerModel = objectModel(env, frontBlocker), blockerDistance = distance, category = category }
    end
    if focusLimit and focusDistance and focusDistance < focusLimit then
        logDecision(env, profile, finalPos, data and data.facingObject, focusDistance, scale, "tight_table_or_counter_rejected", "focusLimit=" .. tostring(focusLimit))
        return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", focusDistance = focusDistance, focusLimit = focusLimit, blockerRecord = objectRecord(data and data.facingObject), blockerModel = objectModel(env, data and data.facingObject), blockerDistance = focusDistance, category = category }
    end

    logDecision(env, profile, finalPos, bodyBlocker or frontBlocker, bodyDistance or distance or focusDistance, scale, "accepted", "category=" .. tostring(category))
    if isStool and env and env.debugLog then
        env.debugLog("barstool final clearance accepted", "category", tostring(category), "final", tostring(finalPos))
    end
    return finalPos, nil, { result = "accepted", category = category }
end

return M
