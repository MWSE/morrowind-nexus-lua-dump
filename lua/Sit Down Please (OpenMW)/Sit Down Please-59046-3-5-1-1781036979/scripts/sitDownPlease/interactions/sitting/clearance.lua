-- interactions/sitting/clearance.lua
---@omw-context none
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

local function clearanceObject(env)
    if not env then return nil end
    if env.clearanceObject then return env.clearanceObject end
    if env.currentObject then
        local ok, obj = pcall(env.currentObject)
        if ok then return obj end
    end
    return nil
end

local function nearestFrontObstacleDistance(env, finalPos, direction)
    local dir = normalizeDirection3(env.util, direction)
    if not (finalPos and dir and env.nearby and env.nearby.castRay and env.nearby.COLLISION_TYPE) then return nil end
    local best = nil
    local bestObject = nil
    local currentObject = clearanceObject(env)
    local rayOptions = { collisionType = env.nearby.COLLISION_TYPE.World }
    if currentObject then rayOptions.ignore = currentObject end
    for _, z in ipairs({ 24, 38, 52, 66 }) do
        local from = finalPos + env.util.vector3(0, 0, z)
        local to = from + dir * 58
        local result = env.nearby.castRay(from, to, rayOptions)
        if result.hit and result.hitPos and not env.rayHitBelongsToObject(result.hitObject, currentObject) then
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
    local currentObject = clearanceObject(env)
    local rayOptions = { collisionType = env.nearby.COLLISION_TYPE.World }
    if currentObject then rayOptions.ignore = currentObject end
    for _, testDir in ipairs(directions) do
        testDir = normalizeDirection3(env.util, testDir)
        if testDir then
            for _, z in ipairs({ 30, 46, 62 }) do
                local from = finalPos + env.util.vector3(0, 0, z * scale)
                local to = from + testDir * rayDistance
                local result = env.nearby.castRay(from, to, rayOptions)
                if result.hit and result.hitPos and not env.rayHitBelongsToObject(result.hitObject, currentObject) then
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

local function objectScale(obj)
    if not obj then return 1 end
    local ok, scale = pcall(function() return obj.scale end)
    if ok and type(scale) == "number" then return scale end
    return 1
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
    if not data then return false end
    if data.manualAssignOverrideTesting ~= true and data.explicitFillOverride ~= true and data.calibrationFill ~= true then return false end
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

local function objectLooksGenericClearanceBlocker(env, obj)
    if not obj then return false end
    if objectLooksTableOrCounter(env, obj) or objectLooksStool(env, obj) then return true end
    local record = tostring(objectRecord(obj) or ""):lower()
    local model = tostring(objectModel(env, obj) or ""):lower()
    local name = tostring(objectName(env, obj) or ""):lower()
    local text = record .. " " .. model .. " " .. name
    if text:find("chair", 1, true) or text:find("bench", 1, true) or text:find("bed", 1, true)
        or text:find("table", 1, true) or text:find("counter", 1, true) or text:find("bar", 1, true)
        or text:find("closet", 1, true) or text:find("wardrobe", 1, true) or text:find("shelf", 1, true)
        or text:find("chest", 1, true) or text:find("crate", 1, true) or text:find("barrel", 1, true)
        or text:find("basket", 1, true) or text:find("sack", 1, true) or text:find("stool", 1, true)
        or text:find("planter", 1, true) or text:find("potted", 1, true) or text:find("plant", 1, true)
        or text:find("pot_", 1, true) or text:find("_pot", 1, true) or text:find("vase", 1, true) then
        return true
    end
    -- Architecture/set pieces and walls produce very close ray hits in tight
    -- interiors. Those should not masquerade as seat blockers; actual wall-fit
    -- problems are handled by routing/facing and by item/furniture blockers.
    if text:find("set", 1, true) or text:find("wall", 1, true) or text:find("floor", 1, true)
        or text:find("hall", 1, true) or text:find("ceiling", 1, true) or text:find("stair", 1, true)
        or text:find("doorjamb", 1, true) then
        return false
    end
    return false
end

local function objectLooksArchitectureWall(env, obj)
    if not obj then return false end
    if objectLooksTableOrCounter(env, obj) or objectLooksStool(env, obj) then return false end
    local record = tostring(objectRecord(obj) or ""):lower()
    local model = tostring(objectModel(env, obj) or ""):lower()
    local name = tostring(objectName(env, obj) or ""):lower()
    local text = record .. " " .. model .. " " .. name
    return text:find("wall", 1, true) ~= nil
        or text:find("roomt", 1, true) ~= nil
        or text:find("corner", 1, true) ~= nil
        or text:find("pillar", 1, true) ~= nil
        or text:find("in_hlaalu", 1, true) ~= nil
        or text:find("doorjamb", 1, true) ~= nil
end

local function sittingFloorFootprintUnsupported(env, finalPos, dir, scale, currentObject)
    if not (env and finalPos and dir and env.util and env.nearby and env.nearby.castRay and env.nearby.COLLISION_TYPE) then
        return false, 0, 0
    end
    local right = env.util.vector3(dir.y, -dir.x, 0)
    local samples = {
        env.util.vector3(0, 0, 0),
        right * (22 * scale),
        right * (-22 * scale),
        dir * (22 * scale),
        dir * (-22 * scale),
        right * (26 * scale) + dir * (-14 * scale),
        right * (-26 * scale) + dir * (-14 * scale),
    }
    local missing = 0
    local total = 0
    for _, offset in ipairs(samples) do
        total = total + 1
        local probe = finalPos + offset
        local hit = env.nearby.castRay(
            probe + env.util.vector3(0, 0, 36),
            probe - env.util.vector3(0, 0, 118),
            { collisionType = env.nearby.COLLISION_TYPE.World, radius = 0, ignore = currentObject }
        )
        if not (hit and hit.hit and hit.hitPos) then
            missing = missing + 1
        end
    end
    return missing >= 4, missing, total
end

local function samePhysicalFurniture(env, obj, currentObject)
    if not (obj and currentObject) then return false end
    if obj == currentObject then return true end
    local objRecord = tostring(objectRecord(obj) or ""):lower()
    local currentRecord = tostring(objectRecord(currentObject) or ""):lower()
    if objRecord == "" or objRecord ~= currentRecord then return false end
    local objModel = tostring(objectModel(env, obj) or ""):lower()
    local currentModel = tostring(objectModel(env, currentObject) or ""):lower()
    return objModel ~= "" and objModel == currentModel and flatDistance(obj.position, currentObject.position) <= 72
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

local function blockerIsFacingFocus(data, blocker)
    return data and data.facingObject and blocker and data.facingObject == blocker
end

local candidateMatchesObject

local function blockerMatchesFacingFocus(env, data, blocker)
    if not (data and blocker) then return false end
    if blockerIsFacingFocus(data, blocker) then return true end
    if data.facingObject and candidateMatchesObject(env, {
        object = data.facingObject,
        recordId = data.facingObjectId,
        model = data.facingObjectModel,
        name = data.facingObjectName,
        position = data.facingObjectPosition or data.facingObject.position,
        kind = data.facingKind,
    }, blocker) then
        return true
    end
    for _, candidate in ipairs(data.facingCandidates or {}) do
        if candidateMatchesObject(env, candidate, blocker) then return true end
    end
    if objectLooksTableOrCounter(env, blocker) and data.facingObjectPosition and blocker.position then
        return flatDistance(blocker.position, data.facingObjectPosition) <= 48
    end
    return false
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
    local currentObject = clearanceObject(env)
    if data and data.tableClearanceFocusCleared == true then
        if env and env.debugLog then
            env.debugLog(
                "seat clearance restored ignored table focus candidate",
                "reason", tostring(data.tableClearanceFocusClearReason or "physical_forward_mismatch"),
                "object", tostring(data.objectId),
                "ignoredFocus", tostring(data.ignoredFacingKind)
            )
        end
        addTableCandidate(env, candidates, seen, {
            object = data.ignoredFacingObject,
            recordId = data.ignoredFacingObjectId,
            model = data.ignoredFacingObjectModel,
            name = data.ignoredFacingObjectName,
            kind = data.ignoredFacingKind or "ignored_table_focus",
            position = data.ignoredFacingObjectPosition,
            source = data.tableClearanceFocusClearReason or "physical_forward_mismatch",
            surfaceHit = data.ignoredFacingSurfaceHit == true,
        })
    end
    if data and data.facingObject then
        addTableCandidate(env, candidates, seen, {
            object = data.facingObject,
            recordId = data.facingObjectId,
            model = data.facingObjectModel,
            kind = data.facingKind,
            position = data.facingObjectPosition or data.facingObject.position,
            source = data.facingSurfaceSource,
            surfaceHit = data.facingSurfaceHit == true,
            facingFocus = true,
        })
    elseif data and data.facingObjectPosition then
        addTableCandidate(env, candidates, seen, {
            recordId = data.facingObjectId,
            model = data.facingObjectModel,
            kind = data.facingKind,
            position = data.facingObjectPosition,
            source = data.facingSurfaceSource,
            surfaceHit = data.facingSurfaceHit == true,
            facingFocus = true,
        })
    end
    for _, candidate in ipairs(data and data.facingCandidates or {}) do
        addTableCandidate(env, candidates, seen, candidate)
    end
    -- Fallback scan: some profile/facing paths keep the physical chair
    -- orientation and do not carry the nearby table/counter as facingObject,
    -- even though the actor can clearly clip through it.  Scan local furniture
    -- objects for table/counter/bar candidates so clearance does not depend on
    -- the facing solver having chosen that object as the active focus.
    local groups = env and env.nearby and { env.nearby.activators, env.nearby.statics, env.nearby.items } or {}
    for _, group in ipairs(groups) do
        for _, obj in ipairs(group or {}) do
            if obj and obj.position and obj ~= currentObject and objectLooksTableOrCounter(env, obj) then
                local near = math.min(flatDistance(obj.position, bodyPoint), flatDistance(obj.position, kneePoint), flatDistance(obj.position, chairPos))
                if near <= 280 then
                    addTableCandidate(env, candidates, seen, {
                        object = obj,
                        recordId = objectRecord(obj),
                        model = objectModel(env, obj),
                        name = objectName(env, obj),
                        kind = "nearby_table_scan",
                        position = obj.position,
                        source = "nearby_table_scan",
                        surfaceHit = false,
                    })
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        local apos, bpos = candidatePosition(a), candidatePosition(b)
        local ad = math.min(flatDistance(apos, bodyPoint), flatDistance(apos, kneePoint), flatDistance(apos, chairPos))
        local bd = math.min(flatDistance(bpos, bodyPoint), flatDistance(bpos, kneePoint), flatDistance(bpos, chairPos))
        return ad < bd
    end)
    return candidates
end

function candidateMatchesObject(env, candidate, obj)
    if not (candidate and obj) then return false end
    if candidate.object and candidate.object == obj then return true end
    local candidateRecordId = tostring(candidateRecord(candidate) or ""):lower()
    local objectRecordId = tostring(objectRecord(obj) or ""):lower()
    if candidateRecordId == "" or candidateRecordId ~= objectRecordId then return false end
    local candidateModelPath = tostring(candidateModel(env, candidate) or ""):lower()
    local objectModelPath = tostring(objectModel(env, obj) or ""):lower()
    if candidateModelPath ~= "" and objectModelPath ~= "" and candidateModelPath ~= objectModelPath then return false end
    local candidatePos = candidatePosition(candidate)
    return candidatePos and obj.position and flatDistance(candidatePos, obj.position) <= 90
end

local function sampledTableSurfaceOverlap(env, candidate, finalPos, kneePoint, dir, scale)
    if not (env and env.util and env.nearby and env.nearby.castRay and env.nearby.COLLISION_TYPE and candidate and finalPos and dir) then
        return false, { sampled = false, reason = "ray_unavailable" }
    end
    local normalizedDir = normalizeDirection3(env.util, dir)
    if not normalizedDir then return false, { sampled = false, reason = "missing_direction" } end
    local right = env.util.vector3(normalizedDir.y, -normalizedDir.x, 0)
    local samples = {
        finalPos,
        finalPos + normalizedDir * (18 * scale),
        kneePoint or (finalPos + normalizedDir * (34 * scale)),
        finalPos + normalizedDir * (44 * scale),
        finalPos + right * (16 * scale),
        finalPos - right * (16 * scale),
        finalPos + normalizedDir * (24 * scale) + right * (14 * scale),
        finalPos + normalizedDir * (24 * scale) - right * (14 * scale),
    }
    local bestHit = nil
    local currentObject = clearanceObject(env)
    local rayOptions = { collisionType = env.nearby.COLLISION_TYPE.World }
    if currentObject then rayOptions.ignore = currentObject end
    for _, base in ipairs(samples) do
        local from = base + env.util.vector3(0, 0, 118 * scale)
        local to = base + env.util.vector3(0, 0, 12 * scale)
        local result = env.nearby.castRay(from, to, rayOptions)
        if result and result.hit and result.hitPos then
            local hitObject = result.hitObject
            if candidateMatchesObject(env, candidate, hitObject) then
                local vertical = (result.hitPos.z or 0) - (finalPos.z or 0)
                if vertical >= 10 * scale and vertical <= 118 * scale then
                    return true, { sampled = true, vertical = vertical, record = objectRecord(hitObject), model = objectModel(env, hitObject) }
                end
                bestHit = bestHit or { sampled = true, vertical = vertical, reason = "vertical_out_of_range", record = objectRecord(hitObject), model = objectModel(env, hitObject) }
            end
        end
    end
    return false, bestHit or { sampled = true, reason = "no_candidate_surface_hit" }
end

local function objectBoundingBox(obj)
    if not obj then return nil end
    local ok, box = pcall(function() return obj:getBoundingBox() end)
    if ok then return box end
    return nil
end

local function boxMinMax(box)
    if not box then return nil end
    local minX, minY, minZ, maxX, maxY, maxZ = nil, nil, nil, nil, nil, nil
    for _, v in ipairs(box.vertices or {}) do
        if v then
            minX = minX and math.min(minX, v.x or 0) or (v.x or 0)
            minY = minY and math.min(minY, v.y or 0) or (v.y or 0)
            minZ = minZ and math.min(minZ, v.z or 0) or (v.z or 0)
            maxX = maxX and math.max(maxX, v.x or 0) or (v.x or 0)
            maxY = maxY and math.max(maxY, v.y or 0) or (v.y or 0)
            maxZ = maxZ and math.max(maxZ, v.z or 0) or (v.z or 0)
        end
    end
    if minX then
        return { x = minX, y = minY, z = minZ }, { x = maxX, y = maxY, z = maxZ }
    end
    if box.center and box.halfSize then
        return {
            x = (box.center.x or 0) - math.abs(box.halfSize.x or 0),
            y = (box.center.y or 0) - math.abs(box.halfSize.y or 0),
            z = (box.center.z or 0) - math.abs(box.halfSize.z or 0),
        }, {
            x = (box.center.x or 0) + math.abs(box.halfSize.x or 0),
            y = (box.center.y or 0) + math.abs(box.halfSize.y or 0),
            z = (box.center.z or 0) + math.abs(box.halfSize.z or 0),
        }
    end
    return nil
end

local function pointInsideExpandedXY(pos, minPos, maxPos, pad)
    if not (pos and minPos and maxPos) then return false end
    pad = tonumber(pad or 0) or 0
    return (pos.x or 0) >= (minPos.x or 0) - pad
        and (pos.x or 0) <= (maxPos.x or 0) + pad
        and (pos.y or 0) >= (minPos.y or 0) - pad
        and (pos.y or 0) <= (maxPos.y or 0) + pad
end

local function tableBoundingBoxBodyOverlap(env, candidate, finalPos, kneePoint, dir, scale, surfaceKind)
    if surfaceKind == "bar" then return false, { reason = "bar_counter_leniency" } end
    local obj = candidateObject(candidate)
    local minPos, maxPos = boxMinMax(objectBoundingBox(obj))
    if not (minPos and maxPos and finalPos and dir) then
        return false, { reason = "missing_bounding_box" }
    end

    local tableTopDelta = (maxPos.z or 0) - (finalPos.z or 0)
    local tableTopRelevant = tableTopDelta >= (18 * scale) and tableTopDelta <= (122 * scale)
    if not tableTopRelevant then
        return false, {
            reason = "tabletop_vertical_out_of_range",
            tableTopDelta = tableTopDelta,
            boxMinZ = minPos.z,
            boxMaxZ = maxPos.z,
        }
    end

    local normalizedDir = normalizeDirection3(env.util, dir)
    if not normalizedDir then return false, { reason = "missing_direction" } end
    local right = env.util.vector3(normalizedDir.y, -normalizedDir.x, 0)
    local frontPoint = finalPos + normalizedDir * (22 * scale)
    local shoulderLeft = finalPos + normalizedDir * (10 * scale) + right * (18 * scale)
    local shoulderRight = finalPos + normalizedDir * (10 * scale) - right * (18 * scale)
    local bodyInside = pointInsideExpandedXY(finalPos, minPos, maxPos, 10 * scale)
    local frontInside = pointInsideExpandedXY(frontPoint, minPos, maxPos, 8 * scale)
    local shoulderInside = pointInsideExpandedXY(shoulderLeft, minPos, maxPos, 4 * scale)
        or pointInsideExpandedXY(shoulderRight, minPos, maxPos, 4 * scale)
    local kneeInside = pointInsideExpandedXY(kneePoint, minPos, maxPos, 0)
    local pos = candidatePosition(candidate)
    local toTable = normalizeDirection3(env.util, pos and {
        x = (pos.x or 0) - (finalPos.x or 0),
        y = (pos.y or 0) - (finalPos.y or 0),
        z = 0,
    } or nil)
    local frontDot = directionDot2(toTable, normalizedDir)
    local facingEnvelope = frontDot > -0.05
    local bodyEnvelopeInside = bodyInside or frontInside or shoulderInside
    local legEnvelopeInside = kneeInside and pointInsideExpandedXY(finalPos, minPos, maxPos, 34 * scale)
    local physicalForwardMismatch = candidate and candidate.source == "physical_forward_mismatch"
    local physicalForwardBodyInsideTabletop = physicalForwardMismatch
        and (bodyInside or shoulderInside)
        and tableTopDelta >= (18 * scale)
        and tableTopDelta <= (96 * scale)
    local rejects = (facingEnvelope and (bodyEnvelopeInside or legEnvelopeInside)) or physicalForwardBodyInsideTabletop

    return rejects == true, {
        reason = physicalForwardBodyInsideTabletop and "physical_forward_body_intersects_tabletop_aabb"
            or (rejects and "body_envelope_intersects_table_aabb" or "body_envelope_clear"),
        bodyInside = bodyInside,
        frontInside = frontInside,
        shoulderInside = shoulderInside,
        kneeInside = kneeInside,
        bodyEnvelopeInside = bodyEnvelopeInside,
        legEnvelopeInside = legEnvelopeInside,
        physicalForwardMismatch = physicalForwardMismatch,
        physicalForwardBodyInsideTabletop = physicalForwardBodyInsideTabletop,
        frontDot = frontDot,
        tableTopDelta = tableTopDelta,
        boxMinX = minPos.x,
        boxMinY = minPos.y,
        boxMinZ = minPos.z,
        boxMaxX = maxPos.x,
        boxMaxY = maxPos.y,
        boxMaxZ = maxPos.z,
    }
end

local function isBacklessSeatCategory(category)
    return category == "stool" or category == "barstool" or category == "bench" or category == "single_seat_bench"
end

local function candidateIsBacklessTableFocus(candidate)
    if not candidate then return false end
    if candidate.facingFocus == true then return true end
    local source = tostring(candidate.source or "")
    return source == "assignment_candidate" or source == "radial_surface"
end

local function selectedBacklessTableLegroomAllowed(candidate, surfaceKind, category, bodyDistance, kneeDistance, tableTopDelta, sampledSurfaceVertical, boxMeta, scale, tightConfirmedLegroomBlock, physicalForwardSurfaceOverlap, unconfirmedBodyBuriedInTable)
    if not isBacklessSeatCategory(category) then return false end
    if not candidateIsBacklessTableFocus(candidate) then return false end
    if surfaceKind ~= "table" and surfaceKind ~= "bar" then return false end
    local isLooseStool = category == "stool" or category == "barstool"
    local minBodyDistance = isLooseStool and 36 or 48
    local minKneeDistance = isLooseStool and 18 or 28
    local verticalClearanceOk = (tableTopDelta and tableTopDelta >= ((isLooseStool and 42 or 48) * scale))
        or (sampledSurfaceVertical and sampledSurfaceVertical >= ((isLooseStool and 42 or 48) * scale))
    if physicalForwardSurfaceOverlap == true then return false end
    if tightConfirmedLegroomBlock == true and not (isLooseStool and verticalClearanceOk) then return false end
    if bodyDistance < (minBodyDistance * scale) or kneeDistance < (minKneeDistance * scale) then return false end
    if boxMeta and boxMeta.bodyInside == true and (
        bodyDistance < ((minBodyDistance + 6) * scale)
        or kneeDistance < ((minKneeDistance + 4) * scale)
    ) then
        return false
    end

    if not verticalClearanceOk then return false end

    if unconfirmedBodyBuriedInTable == true then
        local isBench = category == "bench" or category == "single_seat_bench"
        local intendedStoolLegroom = isLooseStool
            and ((tableTopDelta and tableTopDelta >= (42 * scale))
                or (sampledSurfaceVertical and sampledSurfaceVertical >= (42 * scale)))
            and bodyDistance >= (minBodyDistance * scale)
            and kneeDistance >= (minKneeDistance * scale)
        local highTableClearance = (tableTopDelta and tableTopDelta >= (56 * scale))
            or (sampledSurfaceVertical and sampledSurfaceVertical >= (56 * scale))
        if not (
            (isBench and highTableClearance and bodyDistance >= (64 * scale) and kneeDistance >= (44 * scale))
            or intendedStoolLegroom
        ) then
            return false
        end
    end

    return true
end

local function backlessTableLegroomLooksPlayable(surfaceKind, category, bodyDistance, kneeDistance, tableTopDelta, sampledSurfaceVertical, boxMeta, scale, tightConfirmedLegroomBlock, physicalForwardSurfaceOverlap, unconfirmedBodyBuriedInTable, unconfirmedForwardBodyBuriedInTable)
    if not isBacklessSeatCategory(category) then return false end
    if surfaceKind ~= "table" and surfaceKind ~= "bar" then return false end
    local isLooseStool = category == "stool" or category == "barstool"
    local minBodyDistance = isLooseStool and 36 or 48
    local minKneeDistance = isLooseStool and 18 or 28
    local verticalClearanceOk = (tableTopDelta and tableTopDelta >= ((isLooseStool and 42 or 48) * scale))
        or (sampledSurfaceVertical and sampledSurfaceVertical >= ((isLooseStool and 42 or 48) * scale))
    local looseStoolLegroom = isLooseStool
        and verticalClearanceOk
        and bodyDistance >= (minBodyDistance * scale)
        and kneeDistance >= (minKneeDistance * scale)
    if physicalForwardSurfaceOverlap == true then return false end
    if tightConfirmedLegroomBlock == true and not looseStoolLegroom then return false end
    if (unconfirmedBodyBuriedInTable == true or unconfirmedForwardBodyBuriedInTable == true) and not looseStoolLegroom then return false end
    if boxMeta and boxMeta.bodyInside == true and not looseStoolLegroom then return false end
    if bodyDistance < (minBodyDistance * scale) or kneeDistance < (minKneeDistance * scale) then return false end

    return verticalClearanceOk
end

local function tableOverlapStatus(env, candidate, finalPos, kneePoint, chairPos, dir, scale, category)
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
    local toTable = normalizeDirection3(env.util, {
        x = (pos.x or 0) - (finalPos.x or 0),
        y = (pos.y or 0) - (finalPos.y or 0),
        z = 0,
    })
    local frontDot = directionDot2(toTable, dir)
    local inForwardEnvelope = frontDot > -0.05
    local clearlyInForwardEnvelope = frontDot > 0.10
    local strictBodyOverlapReach = bodyOverlapReach * 0.65
    local sampledOverlap, sampleMeta = sampledTableSurfaceOverlap(env, candidate, finalPos, kneePoint, dir, scale)
    local boundingBoxOverlap, boxMeta = tableBoundingBoxBodyOverlap(env, candidate, finalPos, kneePoint, dir, scale, surfaceKind)
    -- Knee proximity is normal for tucked seats. This flag remains diagnostic
    -- for non-chair categories; backed/backless seats use torso overlap below.
    local tightConfirmedLegroomBlock = candidate.surfaceHit == true
        and verticalOk
        and frontDot > 0.35
        and chairDistance <= (110 * scale)
        and kneeDistance <= (145 * scale)
        and bodyDistance <= (170 * scale)
    local surfaceConfirmed = candidate.surfaceHit == true
    local severeBodyIntersection = verticalOk and bodyDistance <= (strictBodyOverlapReach * 0.85)
        and inForwardEnvelope
        and chairDistance <= (115 * scale)
    local bodyInsideTableEnvelope = surfaceConfirmed
        and verticalOk
        and inForwardEnvelope
        and bodyDistance <= (160 * scale)
        and kneeDistance <= (210 * scale)
        and chairDistance <= (245 * scale)
    local kneesBuriedInFrontSurface = surfaceConfirmed
        and verticalOk
        and clearlyInForwardEnvelope
        and kneeDistance <= (170 * scale)
        and bodyDistance <= (220 * scale)
    local physicalForwardSurfaceOverlap = surfaceConfirmed
        and verticalOk
        and candidate.source == "physical_forward_mismatch"
        and bodyDistance <= (72 * scale)
        and kneeDistance <= (105 * scale)
        and chairDistance <= (76 * scale)
    local nearbyScan = candidate.kind == "nearby_table_scan" or candidate.source == "nearby_table_scan"
    local unconfirmedBodyBuriedInTable = not surfaceConfirmed
        and verticalOk
        and (surfaceKind == "table" or surfaceKind == "bar")
        and frontDot > 0.35
        and bodyDistance <= (80 * scale)
        and kneeDistance <= (130 * scale)
        and chairDistance <= (160 * scale)
    local unconfirmedNearbyTableScanBuried = not surfaceConfirmed
        and verticalOk
        and nearbyScan
        and frontDot > 0.55
        and bodyDistance <= (70 * scale)
        and kneeDistance <= (115 * scale)
        and chairDistance <= (140 * scale)
    local unconfirmedLikelyTableClipping = not surfaceConfirmed
        and verticalOk
        and nearbyScan
        and (surfaceKind == "table" or surfaceKind == "bar")
        and frontDot > 0.65
        and bodyDistance <= (96 * scale)
        and kneeDistance <= (96 * scale)
        and chairDistance <= (130 * scale)
    local unconfirmedForwardBodyBuriedInTable = not surfaceConfirmed
        and verticalOk
        and (surfaceKind == "table" or surfaceKind == "bar")
        and frontDot > 0.25
        and bodyDistance <= (54 * scale)
        and kneeDistance <= (172 * scale)
        and chairDistance <= (220 * scale)
    -- Some tavern tables/counters do not give a corroborating candidate surface
    -- ray because their collision is sparse or the scan found them through the
    -- generic nearby-object path. Still reject the obvious case where the actor
    -- core is inside the table envelope. This is backed-chair only; stools,
    -- benches, and barstools keep their looser focus-clearance behavior below.
    local unconfirmedCoreTableIntersection = not surfaceConfirmed
        and verticalOk
        and nearbyScan
        and (surfaceKind == "table" or surfaceKind == "bar")
        and frontDot > 0.45
        and bodyDistance <= (64 * scale)
        and kneeDistance <= (108 * scale)
        and chairDistance <= (130 * scale)
    local obviousUnconfirmedTableOverlap = unconfirmedBodyBuriedInTable
        or unconfirmedNearbyTableScanBuried
        or unconfirmedLikelyTableClipping
        or unconfirmedForwardBodyBuriedInTable
        or unconfirmedCoreTableIntersection
    local sampledCloseBodyOverlap = sampledOverlap
        and verticalOk
        and inForwardEnvelope
        and bodyDistance <= (70 * scale)
        and kneeDistance <= (135 * scale)
        and chairDistance <= (105 * scale)
    local backlessSurfaceSeat = isBacklessSeatCategory(category)
    local backedSurfaceSeat = category == "backed_chair"
    local tableTopDelta = boxMeta and boxMeta.tableTopDelta
    local sampledSurfaceVertical = sampleMeta and sampleMeta.vertical
    local selectedBacklessTableLegroom = selectedBacklessTableLegroomAllowed(
        candidate,
        surfaceKind,
        category,
        bodyDistance,
        kneeDistance,
        tableTopDelta,
        sampledSurfaceVertical,
        boxMeta,
        scale,
        tightConfirmedLegroomBlock,
        physicalForwardSurfaceOverlap,
        unconfirmedBodyBuriedInTable
    )
    local playableBacklessTableLegroom = selectedBacklessTableLegroom
        or backlessTableLegroomLooksPlayable(
            surfaceKind,
            category,
            bodyDistance,
            kneeDistance,
            tableTopDelta,
            sampledSurfaceVertical,
            boxMeta,
            scale,
            tightConfirmedLegroomBlock,
            physicalForwardSurfaceOverlap,
            unconfirmedBodyBuriedInTable,
            unconfirmedForwardBodyBuriedInTable
        )
    local backlessTorsoTableOverlap = backlessSurfaceSeat
        and verticalOk
        and inForwardEnvelope
        and not playableBacklessTableLegroom
        and (boundingBoxOverlap or sampledOverlap)
        and (
            (boxMeta and boxMeta.bodyInside == true)
            or unconfirmedBodyBuriedInTable
            or (sampledOverlap and bodyDistance <= (38 * scale) and kneeDistance <= (24 * scale))
        )
    local backedPhysicalForwardTabletopOverlap = backedSurfaceSeat
        and verticalOk
        and boxMeta
        and boxMeta.physicalForwardBodyInsideTabletop == true
    local backedBodyEnvelopeInsideTabletop = backedSurfaceSeat
        and verticalOk
        and boxMeta
        and boxMeta.bodyEnvelopeInside == true
        and (candidate.surfaceHit == true or candidate.source == "physical_forward_mismatch" or boxMeta.physicalForwardMismatch == true)
        and (surfaceKind == "table" or surfaceKind == "bar" or surfaceKind == "counter")
        and bodyDistance <= (78 * scale)
        and kneeDistance <= (132 * scale)
        and chairDistance <= (120 * scale)
        and tableTopDelta ~= nil
        and tableTopDelta >= (18 * scale)
        and tableTopDelta <= (122 * scale)
    local backedTorsoTableOverlap = backedSurfaceSeat
        and verticalOk
        and (
            backedPhysicalForwardTabletopOverlap
            or backedBodyEnvelopeInsideTabletop
            or (
                inForwardEnvelope
                and (boundingBoxOverlap or sampledOverlap)
                and (
                    (boxMeta and boxMeta.bodyEnvelopeInside == true)
                    or severeBodyIntersection
                    or (sampledCloseBodyOverlap and bodyDistance <= (58 * scale))
                )
            )
        )
    local sampledConfirmedOverlap = sampledOverlap and (
        -- A backed chair can be close to a table, and knees can tuck under it.
        -- The actor torso should not occupy the tabletop/counter volume. The stricter body
        -- envelope below restores rejection for visually obvious clipping while
        -- still ignoring ordinary architecture/wall proximity.
        (sampledCloseBodyOverlap and not backlessSurfaceSeat and not backedSurfaceSeat)
        or
        severeBodyIntersection
        or (bodyInsideTableEnvelope and not backlessSurfaceSeat and not backedSurfaceSeat)
        or (kneesBuriedInFrontSurface and not backedSurfaceSeat and not backlessSurfaceSeat)
        or (surfaceConfirmed and tightConfirmedLegroomBlock and not backedSurfaceSeat and not backlessSurfaceSeat)
    )
    local physicalForwardCorroboratedOverlap = physicalForwardSurfaceOverlap
        and (sampledOverlap or boundingBoxOverlap)
    local backedUnconfirmedOverlap = backedSurfaceSeat and (
        unconfirmedBodyBuriedInTable
        or unconfirmedNearbyTableScanBuried
        or (unconfirmedForwardBodyBuriedInTable and bodyDistance <= (42 * scale))
        or (unconfirmedCoreTableIntersection and bodyDistance <= (48 * scale))
    )
    local categoryBoundingBoxOverlap = boundingBoxOverlap
        and not backlessSurfaceSeat
        and not (backedSurfaceSeat and not backedTorsoTableOverlap)
    local categoryUnconfirmedOverlap = obviousUnconfirmedTableOverlap
        and not backlessSurfaceSeat
        and ((not backedSurfaceSeat) or backedUnconfirmedOverlap)
    local actualOverlap = verticalOk and (sampledConfirmedOverlap or physicalForwardCorroboratedOverlap or categoryUnconfirmedOverlap or categoryBoundingBoxOverlap or backlessTorsoTableOverlap or backedTorsoTableOverlap)
    local reason = nil
    if not verticalOk then reason = "vertical_mismatch"
    elseif not horizontalOk then reason = "too_far"
    elseif physicalForwardSurfaceOverlap and not physicalForwardCorroboratedOverlap then reason = "physical_forward_surface_uncorroborated"
    elseif playableBacklessTableLegroom then reason = selectedBacklessTableLegroom and "selected_backless_table_legroom_allowed" or "backless_table_legroom_allowed"
    elseif backlessSurfaceSeat and (sampledOverlap or boundingBoxOverlap or obviousUnconfirmedTableOverlap) and not backlessTorsoTableOverlap then reason = "backless_table_legroom_allowed"
    elseif backedSurfaceSeat and (sampledOverlap or boundingBoxOverlap or obviousUnconfirmedTableOverlap) and not backedTorsoTableOverlap then reason = "backed_table_legroom_allowed"
    elseif not (sampledOverlap or physicalForwardCorroboratedOverlap or categoryUnconfirmedOverlap or categoryBoundingBoxOverlap or backlessTorsoTableOverlap or backedTorsoTableOverlap) then reason = "no_sampled_surface_overlap"
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
        backlessSurfaceSeat = backlessSurfaceSeat,
        backedSurfaceSeat = backedSurfaceSeat,
        backlessTorsoTableOverlap = backlessTorsoTableOverlap,
        selectedBacklessTableLegroom = selectedBacklessTableLegroom,
        playableBacklessTableLegroom = playableBacklessTableLegroom,
        backedTorsoTableOverlap = backedTorsoTableOverlap,
        backedPhysicalForwardTabletopOverlap = backedPhysicalForwardTabletopOverlap,
        backedBodyEnvelopeInsideTabletop = backedBodyEnvelopeInsideTabletop,
        backedUnconfirmedOverlap = backedUnconfirmedOverlap,
        physicalForwardSurfaceOverlap = physicalForwardSurfaceOverlap,
        physicalForwardCorroboratedOverlap = physicalForwardCorroboratedOverlap,
        sampledCloseBodyOverlap = sampledCloseBodyOverlap,
        obviousUnconfirmedTableOverlap = obviousUnconfirmedTableOverlap,
        sampledConfirmedOverlap = sampledConfirmedOverlap,
        unconfirmedBodyBuriedInTable = unconfirmedBodyBuriedInTable,
        unconfirmedNearbyTableScanBuried = unconfirmedNearbyTableScanBuried,
        unconfirmedLikelyTableClipping = unconfirmedLikelyTableClipping,
        unconfirmedForwardBodyBuriedInTable = unconfirmedForwardBodyBuriedInTable,
        unconfirmedCoreTableIntersection = unconfirmedCoreTableIntersection,
        surfaceKind = surfaceKind,
        surfaceSource = candidate.source,
        surfaceHit = candidate.surfaceHit == true,
        sampledSurfaceOverlap = sampledOverlap,
        sampledSurfaceReason = sampleMeta and sampleMeta.reason,
        sampledSurfaceVertical = sampleMeta and sampleMeta.vertical,
        boundingBoxOverlap = boundingBoxOverlap,
        boundingBoxReason = boxMeta and boxMeta.reason,
        boundingBoxBodyInside = boxMeta and boxMeta.bodyInside,
        boundingBoxFrontInside = boxMeta and boxMeta.frontInside,
        boundingBoxShoulderInside = boxMeta and boxMeta.shoulderInside,
        boundingBoxKneeInside = boxMeta and boxMeta.kneeInside,
        boundingBoxBodyEnvelopeInside = boxMeta and boxMeta.bodyEnvelopeInside,
        boundingBoxLegEnvelopeInside = boxMeta and boxMeta.legEnvelopeInside,
        boundingBoxPhysicalForwardMismatch = boxMeta and boxMeta.physicalForwardMismatch,
        boundingBoxPhysicalForwardBodyInsideTabletop = boxMeta and boxMeta.physicalForwardBodyInsideTabletop,
        boundingBoxFrontDot = boxMeta and boxMeta.frontDot,
        boundingBoxTableTopDelta = boxMeta and boxMeta.tableTopDelta,
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
        "seat object scale", tostring(objectScale(clearanceObject(env))),
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
        "seat object scale", tostring(objectScale(clearanceObject(env))),
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
        "seatObjectScale", tostring(objectScale(clearanceObject(env))),
        "blockerObjectScale", tostring(objectScale(candidateObject(candidate))),
        "surfaceHit", tostring(meta and meta.surfaceHit),
        "sampledSurfaceOverlap", tostring(meta and meta.sampledSurfaceOverlap),
        "sampledSurfaceReason", tostring(meta and meta.sampledSurfaceReason),
        "sampledSurfaceVertical", tostring(meta and meta.sampledSurfaceVertical),
        "sampledCloseBodyOverlap", tostring(meta and meta.sampledCloseBodyOverlap),
        "physicalForwardSurfaceOverlap", tostring(meta and meta.physicalForwardSurfaceOverlap),
        "physicalForwardCorroboratedOverlap", tostring(meta and meta.physicalForwardCorroboratedOverlap),
        "unconfirmedForwardBodyBuriedInTable", tostring(meta and meta.unconfirmedForwardBodyBuriedInTable),
        "unconfirmedCoreTableIntersection", tostring(meta and meta.unconfirmedCoreTableIntersection),
        "obviousUnconfirmedTableOverlap", tostring(meta and meta.obviousUnconfirmedTableOverlap),
        "backlessSurfaceSeat", tostring(meta and meta.backlessSurfaceSeat),
        "backlessTorsoTableOverlap", tostring(meta and meta.backlessTorsoTableOverlap),
        "playableBacklessTableLegroom", tostring(meta and meta.playableBacklessTableLegroom),
        "backedSurfaceSeat", tostring(meta and meta.backedSurfaceSeat),
        "backedTorsoTableOverlap", tostring(meta and meta.backedTorsoTableOverlap),
        "backedPhysicalForwardTabletopOverlap", tostring(meta and meta.backedPhysicalForwardTabletopOverlap),
        "backedBodyEnvelopeInsideTabletop", tostring(meta and meta.backedBodyEnvelopeInsideTabletop),
        "backedUnconfirmedOverlap", tostring(meta and meta.backedUnconfirmedOverlap),
        "selectedBacklessTableLegroom", tostring(meta and meta.selectedBacklessTableLegroom),
        "boundingBoxOverlap", tostring(meta and meta.boundingBoxOverlap),
        "boundingBoxReason", tostring(meta and meta.boundingBoxReason),
        "boundingBoxBodyInside", tostring(meta and meta.boundingBoxBodyInside),
        "boundingBoxFrontInside", tostring(meta and meta.boundingBoxFrontInside),
        "boundingBoxShoulderInside", tostring(meta and meta.boundingBoxShoulderInside),
        "boundingBoxKneeInside", tostring(meta and meta.boundingBoxKneeInside),
        "boundingBoxBodyEnvelopeInside", tostring(meta and meta.boundingBoxBodyEnvelopeInside),
        "boundingBoxLegEnvelopeInside", tostring(meta and meta.boundingBoxLegEnvelopeInside),
        "boundingBoxPhysicalForwardMismatch", tostring(meta and meta.boundingBoxPhysicalForwardMismatch),
        "boundingBoxPhysicalForwardBodyInsideTabletop", tostring(meta and meta.boundingBoxPhysicalForwardBodyInsideTabletop),
        "boundingBoxTableTopDelta", tostring(meta and meta.boundingBoxTableTopDelta),
        "tightConfirmedLegroomBlock", tostring(meta and meta.tightConfirmedLegroomBlock)
    )
end

local function backlessTableFocusLimit(category, scale)
    if category == "stool" or category == "barstool" then return 24 * scale end
    if category == "bench" or category == "single_seat_bench" then return 20 * scale end
    return 18 * scale
end

local function rejectBacklessTableOverlap(env, data, profile, finalPos, kneePoint, chairPos, dir, scale, category)
    if not (data and data.facingKind == "table") then return nil end
    local tableCandidates = collectTableCandidates(env, data, finalPos, kneePoint, chairPos)
    if env and env.debugLog then
        env.debugLog("backless_table_clearance_candidates", tostring(#tableCandidates), "profile", tostring(profile and profile.profileId), "category", tostring(category))
    end
    for _, candidate in ipairs(tableCandidates) do
        local rejects, ignoreReason, meta = tableOverlapStatus(env, candidate, finalPos, kneePoint, chairPos, dir, scale, category)
        logTableCandidate(env, candidate, meta)
        if rejects then
            local blocker = candidateObject(candidate)
            logDecision(env, profile, finalPos, blocker, meta and meta.kneeDistance, scale, "tight_table_or_counter_rejected", "backlessTableOverlap=true")
            return "tight_table_or_counter_rejected", {
                result = "tight_table_or_counter_rejected",
                tabletopOverlap = true,
                focusKind = "table",
                tableDistance = meta and meta.kneeDistance,
                tableLimit = meta and meta.tabletopReach,
                blockerRecord = candidateRecord(candidate),
                blockerModel = candidateModel(env, candidate),
                blockerDistance = meta and meta.kneeDistance,
                vertical = meta and meta.vertical,
                category = category,
            }
        elseif env and env.debugLog then
            env.debugLog(
                "backless_table_candidate_ignored",
                "reason", tostring(ignoreReason or "no_overlap"),
                "object", tostring(candidateRecord(candidate)),
                "distance", tostring(meta and meta.kneeDistance),
                "category", tostring(category)
            )
        end
    end
    return nil
end

function M.rejectSittingFinalIfBlocked(env, finalPos, facingDirection, profile, data)
    if not (env and finalPos and facingDirection and profile) then return finalPos, nil end
    if profile.unsafeIfBlocked ~= true then return finalPos, nil end

    local dir = normalizeDirection3(env.util, facingDirection)
    if not dir then return finalPos, nil end

    local currentObject = clearanceObject(env)
    local category = normalizedCategory(env.sittingSeatCategory(profile, currentObject))
    local isStool = category == "stool" or category == "barstool" or objectLooksStool(env, currentObject)
    local isBacklessTableSeat = isStool or category == "bench" or category == "single_seat_bench"
    local actorScale = env.actorScale and env.actorScale() or 1
    local scale = tonumber(actorScale or 1) or 1
    if scale < 0.75 then scale = 0.75 elseif scale > 1.35 then scale = 1.35 end

    local distance, frontBlocker = nearestFrontObstacleDistance(env, finalPos, dir)
    local focusDistance = focusBlockDistance(env, finalPos, dir, data)
    local bodyDistance, bodyBlocker = nearestBodyObstacleDistance(env, finalPos, dir, category, scale)
    local frontArchitectureWall = frontBlocker and objectLooksArchitectureWall(env, frontBlocker) or false
    if bodyBlocker and not objectLooksGenericClearanceBlocker(env, bodyBlocker) then
        bodyDistance, bodyBlocker = nil, nil
    end
    if frontBlocker and not objectLooksGenericClearanceBlocker(env, frontBlocker) then
        if not (isBacklessTableSeat and data and data.facingKind == "open_space" and frontArchitectureWall) then
            distance, frontBlocker = nil, nil
        end
    end
    if samePhysicalFurniture(env, bodyBlocker, currentObject) then
        bodyDistance, bodyBlocker = nil, nil
    end
    if samePhysicalFurniture(env, frontBlocker, currentObject) then
        distance, frontBlocker = nil, nil
    end

    local frontLimit = (isBacklessTableSeat and 18 or (category == "backed_chair" and 28 or 38)) * scale
    local focusLimit = (isBacklessTableSeat or not (data and data.facingSurfaceHit == true)) and nil or (88 * scale)
    local bodyLimit
    if category == "bench" or category == "single_seat_bench" then
        -- Backless benches are often placed tight against walls/tables. A tiny
        -- wall/interior ray hit near the body point should not become a blocker;
        -- stacked furniture and real seat clutter are handled by clutterBlockers.
        bodyLimit = 6 * scale
    elseif category == "stool" or category == "barstool" then
        bodyLimit = 10 * scale
    else
        bodyLimit = (category == "backed_chair" and 30 or 24) * scale
    end
    local backedTableLimit = 44 * scale
    local kneePoint = finalPos + dir * (category == "backed_chair" and 34 * scale or 24 * scale)

    if isBacklessTableSeat and data and data.facingKind == "open_space" and frontArchitectureWall and distance and distance <= (72 * scale) then
        logDecision(env, profile, finalPos, frontBlocker, distance, scale, "clearance_blocked_by_object", "openSpaceWallLimit=" .. tostring(72 * scale))
        return nil, "clearance_blocked_by_object", { result = "clearance_blocked_by_object", frontDistance = distance, frontLimit = 72 * scale, blockerRecord = objectRecord(frontBlocker), blockerModel = objectModel(env, frontBlocker), blockerDistance = distance, category = category, facingKind = "open_space_wall" }
    end

    if isBacklessTableSeat then
        local unsupported, missing, total = sittingFloorFootprintUnsupported(env, finalPos, dir, scale, currentObject)
        if unsupported then
            logDecision(env, profile, finalPos, nil, missing, scale, "clearance_blocked_by_object", "floorSupportMissing=" .. tostring(missing) .. "/" .. tostring(total))
            return nil, "clearance_blocked_by_object", { result = "clearance_blocked_by_object", unsupportedFloorSamples = missing, totalFloorSamples = total, category = category }
        end
    end

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
            local rejects, ignoreReason, meta = tableOverlapStatus(env, candidate, finalPos, kneePoint, currentObject and currentObject.position or finalPos, dir, scale, category)
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
        local blocker = bodyBlocker or frontBlocker
        local blockerDistance = bodyDistance or distance
        local acceptedFocus = false
        if blockerMatchesFacingFocus(env, data, blocker) then
            if blockerDistance and blockerDistance < (4 * scale) then
                logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "tight_table_or_counter_rejected", "barFocusLimit=" .. tostring(blockerDistance))
                return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", focusKind = "bar", blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance, category = category }
            end
            if env and env.debugLog then
                env.debugLog("backless_bar_focus_clearance_accepted_focus_blocker", "object", tostring(objectRecord(blocker)), "distance", tostring(blockerDistance), "category", tostring(category))
            end
            if bodyBlocker == blocker then bodyDistance, bodyBlocker = nil, nil end
            if frontBlocker == blocker then distance, frontBlocker = nil, nil end
            acceptedFocus = true
        elseif isRelevantBarFocusBlocker(env, data, blocker) and blockerDistance and blockerDistance < (4 * scale) then
            logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "tight_table_or_counter_rejected", "barFocusLimit=" .. tostring(blockerDistance))
            return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", focusKind = "bar", blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance, category = category }
        elseif focusDistance and data.facingObject and env and env.debugLog then
            env.debugLog("backless_bar_focus_clearance_accepted_focus_only", "object", tostring(objectRecord(data.facingObject)), "distance", tostring(focusDistance), "category", tostring(category))
            acceptedFocus = true
        end
        if acceptedFocus then
            focusDistance = nil
        end
    end

    if isBacklessTableSeat and data and data.facingKind == "table" then
        local blocker = bodyBlocker or frontBlocker
        local blockerDistance = bodyDistance or distance
        -- For backless seats facing a table, proximity alone is not a clip.
        -- Actual tabletop/body overlap is already tested by rejectBacklessTableOverlap()
        -- above. Keeping a separate distance-only veto here falsely blocked
        -- valid tavern stools that visually tuck under tables.
        local tableFocusTightLimit = 0
        local acceptedFocus = false
        local tableReason, tableMeta = rejectBacklessTableOverlap(env, data, profile, finalPos, kneePoint, currentObject and currentObject.position or finalPos, dir, scale, category)
        if tableReason then
            return nil, tableReason, tableMeta
        end
        if blockerMatchesFacingFocus(env, data, blocker) then
            if blockerDistance and blockerDistance < tableFocusTightLimit then
                logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "tight_table_or_counter_rejected", "tableFocusLimit=" .. tostring(blockerDistance))
                return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", focusKind = "table", blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance, category = category }
            end
            if env and env.debugLog then
                env.debugLog("backless_table_focus_clearance_accepted_focus_blocker", "object", tostring(objectRecord(blocker)), "distance", tostring(blockerDistance), "category", tostring(category))
            end
            if bodyBlocker == blocker then bodyDistance, bodyBlocker = nil, nil end
            if frontBlocker == blocker then distance, frontBlocker = nil, nil end
            acceptedFocus = true
        elseif isRelevantTableOrBarFocusBlocker(env, data, blocker) and blockerDistance and blockerDistance < tableFocusTightLimit then
            logDecision(env, profile, finalPos, blocker, blockerDistance, scale, "tight_table_or_counter_rejected", "tableFocusLimit=" .. tostring(blockerDistance))
            return nil, "tight_table_or_counter_rejected", { result = "tight_table_or_counter_rejected", focusKind = "table", blockerRecord = objectRecord(blocker), blockerModel = objectModel(env, blocker), blockerDistance = blockerDistance, category = category }
        elseif focusDistance and data.facingObject and env and env.debugLog then
            env.debugLog("backless_table_focus_clearance_accepted_focus_only", "object", tostring(objectRecord(data.facingObject)), "distance", tostring(focusDistance), "category", tostring(category))
            acceptedFocus = true
        end
        if acceptedFocus then
            focusDistance = nil
        end
    end

    if bodyDistance and bodyDistance < bodyLimit then
        local bodyReason = objectLooksTableOrCounter(env, bodyBlocker) and "tight_table_or_counter_rejected" or "clearance_blocked_by_object"
        logDecision(env, profile, finalPos, bodyBlocker, bodyDistance, scale, bodyReason, "bodyLimit=" .. tostring(bodyLimit))
        return nil, bodyReason, { result = bodyReason, bodyDistance = bodyDistance, bodyLimit = bodyLimit, blockerRecord = objectRecord(bodyBlocker), blockerModel = objectModel(env, bodyBlocker), blockerDistance = bodyDistance, category = category }
    end
    if distance and distance < frontLimit then
        local frontReason = objectLooksTableOrCounter(env, frontBlocker) and "tight_table_or_counter_rejected" or "clearance_blocked_by_object"
        logDecision(env, profile, finalPos, frontBlocker, distance, scale, frontReason, "frontLimit=" .. tostring(frontLimit))
        return nil, frontReason, { result = frontReason, frontDistance = distance, frontLimit = frontLimit, blockerRecord = objectRecord(frontBlocker), blockerModel = objectModel(env, frontBlocker), blockerDistance = distance, category = category }
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
