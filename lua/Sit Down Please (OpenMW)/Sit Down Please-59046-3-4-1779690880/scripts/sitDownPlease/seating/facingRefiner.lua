-- seating/facingRefiner.lua
--
-- Refines table/bar facing using local collision rays. The global assignment
-- script can only rank object origins; this local pass checks which surface is
-- actually visible from the sampled seat point.

local M = {}
local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')

local function objectName(env, obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then return obj.type.record(obj) end
        return nil
    end)
    if ok and rec then return rec.name end
    return nil
end

local function objectText(env, obj)
    return objectMatchers.objectText(obj, env.profiles.objectModelPath, objectName(env, obj))
end

local function objectLooksLikeBarSurface(env, obj)
    return objectMatchers.surfaceKindFromText(objectText(env, obj)) == "bar"
end

local function objectLooksLikeTableSurface(env, obj)
    return objectMatchers.objectLooksLikeTableOrBarSurface(obj, env.profiles.objectModelPath, objectName(env, obj))
end

local function objectLooksLikeWallShelfTable(env, obj)
    local text = objectText(env, obj)
    return text:find("furnm_shelf_02", 1, true) ~= nil
        or text:find("furn_n_m_shelf_02", 1, true) ~= nil
        or text:find("furn_n_m_shlf02", 1, true) ~= nil
end

local function objectLooksLikeFireFocus(env, obj)
    local text = objectText(env, obj)
    return text:find("hearth", 1, true) ~= nil
        or text:find("fireplace", 1, true) ~= nil
        or text:find("pitfire", 1, true) ~= nil
        or text:find("campfire", 1, true) ~= nil
        or text:find("fire", 1, true) ~= nil
        or text:find("logpile", 1, true) ~= nil
end

local function flatDistance(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function directionBetween(env, fromPos, toPos)
    if not (fromPos and toPos) then return nil end
    local delta = toPos - fromPos
    local flat = env.util.vector2(delta.x, delta.y)
    if flat:length() <= 1 then return nil end
    local norm = flat:normalize()
    return env.util.vector3(norm.x, norm.y, 0)
end

local function rotateFlatDirection(env, dir, radians)
    if not (env and env.util and dir) then return dir end
    local cosA = math.cos(radians)
    local sinA = math.sin(radians)
    return env.util.vector3(
        (dir.x or 0) * cosA - (dir.y or 0) * sinA,
        (dir.x or 0) * sinA + (dir.y or 0) * cosA,
        0
    )
end

local function objectForwardDirection(env, obj)
    local yaw = 0
    if obj and obj.rotation then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then yaw = value end
    end
    return env.util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

local function forwardDotToPosition(env, obj, fromPos, toPos)
    local direction = directionBetween(env, fromPos, toPos)
    if not direction then return nil end
    local forward = objectForwardDirection(env, obj)
    return (forward.x or 0) * (direction.x or 0) + (forward.y or 0) * (direction.y or 0)
end

local function seatSurfaceMaxDistance(category, kind)
    if category == "barstool" and kind == "bar" then
        return 210
    end
    return 360
end

local function radialSurfaceCandidate(env, sitPosition, category, currentObject)
    if not (env and sitPosition and env.nearby and env.util) then return nil end
    local best, bestScore = nil, nil
    local from = sitPosition + env.util.vector3(0, 0, 48)

    for i = 0, 15 do
        local angle = (math.pi * 2 * i) / 16
        local dir = env.util.vector3(math.cos(angle), math.sin(angle), 0)
        local result = env.nearby.castRay(from, from + dir * 240, { collisionType = env.nearby.COLLISION_TYPE.World })
        if result.hit and result.hitObject and result.hitPos then
            local kind = nil
            if objectLooksLikeBarSurface(env, result.hitObject) then
                kind = "bar"
            elseif objectLooksLikeTableSurface(env, result.hitObject) then
                kind = "table"
            end
            if kind then
                local distance = flatDistance(sitPosition, result.hitPos)
                if distance >= 18 and distance <= 220 then
                    local score = distance
                    if kind == "bar" then
                        score = score + (category == "barstool" and -55 or 45)
                    end
                    if kind == "table" then score = score - 20 end
                    if category == "barstool" and kind == "bar" then score = score - 35 end
                    local forwardDot = nil
                    if category == "barstool" and kind == "bar" then
                        forwardDot = forwardDotToPosition(env, currentObject, sitPosition, result.hitPos)
                        if forwardDot and forwardDot > 0.35 then
                            score = score - 140
                        elseif forwardDot and forwardDot < -0.2 then
                            score = score + 45
                        end
                    end
                    if not bestScore or score < bestScore then
                        bestScore = score
                        best = {
                            object = result.hitObject,
                            kind = kind,
                            position = result.hitPos,
                            score = score,
                            distance = distance,
                            source = "radial_surface",
                            surfaceHit = true,
                            forwardDot = forwardDot,
                        }
                    end
                end
            end
        end
    end

    return best, bestScore
end

function M.refine(env, sitPosition, data, profile, currentObject)
    if not (env and sitPosition and data) then return end
    local facingCandidates = type(data.facingCandidates) == "table" and data.facingCandidates or {}
    local category = env.sittingSeatCategory(profile, currentObject)
    local best, bestScore = radialSurfaceCandidate(env, sitPosition, category, currentObject)

    for _, candidate in ipairs(facingCandidates) do
        local obj = candidate and candidate.object or nil
        local pos = candidate and (candidate.position or (obj and obj.position)) or nil
        local kind = candidate and candidate.kind or nil
        if obj and pos and (kind == "table" or kind == "bar" or kind == "fire") then
            local distance = flatDistance(sitPosition, pos)
            local maxDistance = kind == "fire" and 260 or seatSurfaceMaxDistance(category, kind)
            if distance <= maxDistance then
                local targetPos = pos
                local score = distance
                if kind == "bar" then
                    score = score + (category == "barstool" and -65 or 45)
                end
                if kind == "table" then score = score - 25 end
                if kind == "fire" then score = score + 15 end
                if category == "barstool" and kind == "bar" then score = score - 30 end
                local forwardDot = nil
                if category == "barstool" and kind == "bar" then
                    forwardDot = candidate.forwardDot or forwardDotToPosition(env, currentObject, sitPosition, pos)
                    if forwardDot and forwardDot > 0.35 then
                        score = score - 140
                    elseif forwardDot and forwardDot < -0.2 then
                        score = score + 45
                    end
                end

                local surfaceHit = false
                if kind ~= "fire" then
                    local from = sitPosition + env.util.vector3(0, 0, 48)
                    local to = pos + env.util.vector3(0, 0, 48)
                    local result = env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
                    if result.hit and result.hitObject and result.hitPos then
                        if env.rayHitBelongsToObject(result.hitObject, obj) then
                            targetPos = result.hitPos
                            surfaceHit = true
                            score = score - 70
                        elseif objectLooksLikeTableSurface(env, result.hitObject) then
                            targetPos = result.hitPos
                            surfaceHit = true
                            score = score - (objectLooksLikeBarSurface(env, result.hitObject) and 55 or 35)
                        else
                            score = score + 30
                        end
                    else
                        score = score - 15
                    end
                end

                local rejectBenchOriginOnlyFocus = category == "bench"
                    and kind ~= "fire"
                    and surfaceHit ~= true
                    and not objectLooksLikeWallShelfTable(env, obj)
                if not rejectBenchOriginOnlyFocus then
                    -- A collision hit from the sampled seat is the best evidence for
                    -- what is physically in front of the NPC. Nearby object origins
                    -- are still useful as a fallback, but they should not pull a
                    -- stool toward the wrong side of a table when a local surface was
                    -- already found.
                    local canReplaceLocalSurface = not best
                        or best.source ~= "radial_surface"
                        or (best.kind == kind and distance < ((best.distance or math.huge) - 10))
                        or (
                            category == "barstool"
                            and kind == "bar"
                            and best.kind == "table"
                            and forwardDot
                            and forwardDot > 0.35
                            and score < (bestScore or math.huge)
                        )
                    if canReplaceLocalSurface and (not bestScore or score < bestScore) then
                        bestScore = score
                        local refinedKind = kind
                        if kind ~= "fire" and objectLooksLikeBarSurface(env, obj) then
                            refinedKind = "bar"
                        elseif kind == "fire" and not objectLooksLikeFireFocus(env, obj) then
                            refinedKind = kind
                        end
                        best = {
                            object = obj,
                            kind = refinedKind,
                            position = targetPos,
                            score = score,
                            distance = distance,
                            source = "assignment_candidate",
                            surfaceHit = surfaceHit,
                            forwardDot = forwardDot,
                        }
                    end
                elseif env.debugLog then
                    env.debugLog(
                        "sitting facing candidate rejected origin_only_bench_focus",
                        "object", tostring(currentObject and currentObject.recordId),
                        "focus", tostring(obj and obj.recordId),
                        "kind", tostring(kind),
                        "distance", tostring(distance)
                    )
                end
            end
        end
    end

    if not (best and best.position) then return end
    local refined = directionBetween(env, sitPosition, best.position)
    if not refined then return end
    local closeWallShelfCorrection = false
    if best.kind == "table"
        and best.surfaceHit ~= true
        and (best.distance or math.huge) <= 64
        and objectLooksLikeWallShelfTable(env, best.object) then
        refined = rotateFlatDirection(env, refined, -math.pi / 4)
        closeWallShelfCorrection = true
    end

    data.preferredFacingDirection = refined
    data.facingObject = best.object
    data.facingObjectId = best.object and best.object.recordId or data.facingObjectId
    data.facingObjectModel = best.object and env.profiles.objectModelPath(best.object) or data.facingObjectModel
    data.facingObjectName = best.object and objectName(env, best.object) or data.facingObjectName
    data.facingKind = best.kind
    data.facingObjectPosition = best.position
    data.facingSurfaceSource = best.source
    data.facingSurfaceHit = best.surfaceHit == true
    env.debugLog(
        "sitting facing refined from local surface",
        "object", tostring(currentObject and currentObject.recordId),
        "focus", tostring(data.facingObjectId),
        "kind", tostring(best.kind),
        "source", tostring(best.source),
        "surfaceHit", tostring(best.surfaceHit == true),
        "score", tostring(best.score),
        "distance", tostring(best.distance),
        "forwardDot", tostring(best.forwardDot),
        "closeWallShelfCorrection", tostring(closeWallShelfCorrection)
    )
end

return M
