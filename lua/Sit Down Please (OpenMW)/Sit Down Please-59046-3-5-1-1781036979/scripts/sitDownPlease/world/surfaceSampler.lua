-- world/surfaceSampler.lua
---@omw-context none
--
-- Pure local-script surface sampling helpers. This module preserves the current
-- seat-surface algorithm; future sampler changes should happen here, not inside
-- interactionSeeker.lua.

local scalePolicy = require('scripts/sitDownPlease/world/scalePolicy')

local M = {}

local function objectLocalOffset(env, obj, offset)
    if not obj or not offset then return obj and obj.position or nil end
    return scalePolicy.objectLocalPosition(env.util, obj, offset)
end

function M.objectTopPosition(env, obj)
    if not (env and env.nearby and env.util and obj) then return nil end
    local from = obj.position + env.util.vector3(0, 0, 180)
    local to = obj.position - env.util.vector3(0, 0, 60)
    local result = env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
    if result.hit and result.hitObject == obj and result.hitPos then
        return result.hitPos
    end
    return nil
end

function M.surfaceHitZStats(hits)
    if not hits or #hits == 0 then return nil end
    local minZ, maxZ = nil, nil
    for _, hitPos in ipairs(hits) do
        if hitPos then
            local z = hitPos.z or 0
            minZ = minZ and math.min(minZ, z) or z
            maxZ = maxZ and math.max(maxZ, z) or z
        end
    end
    if not (minZ and maxZ) then return nil end
    return { minZ = minZ, maxZ = maxZ, span = maxZ - minZ, hits = #hits }
end

function M.averageTopSurfaceHits(env, hits, tolerance)
    if not hits or #hits == 0 then return nil, 0 end

    local maxZ = nil
    for _, hitPos in ipairs(hits) do
        if hitPos and (not maxZ or hitPos.z > maxZ) then
            maxZ = hitPos.z
        end
    end

    if not maxZ then return nil, 0 end

    local sum = env.util.vector3(0, 0, 0)
    local count = 0
    local minZ = maxZ - (tolerance or 18)
    for _, hitPos in ipairs(hits) do
        if hitPos and hitPos.z >= minZ then
            sum = sum + hitPos
            count = count + 1
        end
    end

    if count == 0 then return nil, 0 end
    return sum / count, count
end

local function averageBandAtZ(env, hits, bandZ, tolerance)
    if not (hits and bandZ) then return nil, 0 end
    local sum = env.util.vector3(0, 0, 0)
    local count = 0
    local minZ = bandZ - (tolerance or 18)
    local maxZ = bandZ + 0.5
    for _, hitPos in ipairs(hits) do
        if hitPos and hitPos.z >= minZ and hitPos.z <= maxZ then
            sum = sum + hitPos
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return sum / count, count
end

local function lowerSeatBandForBackedChair(env, hits, stats, topBandSamples, tolerance)
    if not (hits and stats and stats.maxZ) then return nil, 0, nil end
    local minLowerZ = stats.maxZ - (tolerance or 18)
    local lowerMaxZ = nil
    for _, hitPos in ipairs(hits) do
        local z = hitPos and hitPos.z or nil
        if z and z < minLowerZ and (not lowerMaxZ or z > lowerMaxZ) then
            lowerMaxZ = z
        end
    end
    if not lowerMaxZ then return nil, 0, nil end
    local drop = stats.maxZ - lowerMaxZ
    if drop > 70 then return nil, 0, drop end
    local lowerBand, lowerCount = averageBandAtZ(env, hits, lowerMaxZ, tolerance)
    if lowerCount < math.max(2, math.ceil((stats.hits or 0) * 0.25)) then
        local sparseButClearSeatBand = lowerCount >= 1
            and (topBandSamples or 0) <= 1
            and (stats.hits or 0) <= 3
            and drop >= 28
            and drop <= 55
        if not sparseButClearSeatBand then return nil, lowerCount, drop end
    end
    return lowerBand, lowerCount, drop
end

local function externalSittingSurfaceLooksPlausible(env, obj, profile, surface)
    if not (obj and obj.position and surface) then return true end
    local deltaZ = (surface.z or 0) - (obj.position.z or 0)
    local category = env and env.sittingSeatCategory and env.sittingSeatCategory(profile, obj) or tostring(profile and profile.type or "")
    category = tostring(category or ""):lower()
    local upper = (category == "stool" or category == "barstool") and 48 or 90
    if deltaZ >= -65 and deltaZ <= upper then return true end

    if env and env.debugLog then
        env.debugLog(
            "sitting external surface rejected implausible height",
            "object", tostring(obj and obj.recordId),
            "profile", tostring(profile and profile.profileId),
            "category", tostring(category),
            "deltaZ", tostring(deltaZ),
            "objectZ", tostring(obj.position and obj.position.z),
            "surfaceZ", tostring(surface and surface.z)
        )
    end
    return false
end

local function allowExternalSittingSurface(env, obj, profile)
    if not (profile and profile.externalProfile == true) then return false end
    local category = env and env.sittingSeatCategory and env.sittingSeatCategory(profile, obj) or tostring(profile.type or "")
    category = tostring(category or ""):lower()
    if category == "backed_chair"
        or category == "single_seat_bench"
        or category == "bench" then
        if env and env.debugLog then
            env.debugLog(
                "sitting external surface fallback blocked for profiled seat",
                "object", tostring(obj and obj.recordId),
                "profile", tostring(profile and profile.profileId),
                "category", tostring(category)
            )
        end
        return false
    end
    return true
end

local function castRenderingRay(env, from, to)
    if not (env and env.nearby and env.nearby.castRenderingRay and from and to) then return nil end
    local ok, result = pcall(function()
        return env.nearby.castRenderingRay(from, to, { ignore = env.actor })
    end)
    if ok and result and result.hit and result.hitPos then return result end
    return nil
end

local function backedChairLowerBand(env, hits, obj, profile, source, tolerance)
    local sampledTop, sampledCount = M.averageTopSurfaceHits(env, hits, tolerance or 18)
    if not sampledTop then return nil end
    local stats = M.surfaceHitZStats(hits)
    if stats and env.sittingSeatCategory(profile, obj) == "backed_chair" and stats.span >= 28 and sampledCount <= math.max(2, math.floor(stats.hits / 2)) then
        local lowerBand, lowerCount, lowerDrop = lowerSeatBandForBackedChair(env, hits, stats, sampledCount, tolerance or 18)
        if lowerBand then
            local objectScale = scalePolicy.objectScale(obj)
            if scalePolicy.isNonStandard(objectScale, 0.08) and (lowerDrop or 0) > 34 then
                env.debugLog(
                    "sitting surface backed chair lower band rejected for scaled object",
                    "source", tostring(source or "collision"),
                    "object", tostring(obj and obj.recordId),
                    "profile", tostring(profile and profile.profileId),
                    "objectScale", tostring(objectScale),
                    "drop", tostring(lowerDrop),
                    "chosenTop", tostring(sampledTop)
                )
                return nil, lowerCount, lowerDrop, sampledTop, sampledCount, stats
            end
            env.debugLog(
                "sitting surface backed chair lower band selected",
                "source", tostring(source or "collision"),
                "object", tostring(obj and obj.recordId),
                "profile", tostring(profile and profile.profileId),
                "samples", tostring(stats.hits),
                "topBandSamples", tostring(sampledCount),
                "lowerBandSamples", tostring(lowerCount),
                "minZ", tostring(stats.minZ),
                "maxZ", tostring(stats.maxZ),
                "span", tostring(stats.span),
                "drop", tostring(lowerDrop),
                "chosen", tostring(lowerBand)
            )
            return lowerBand, lowerCount, lowerDrop
        end
        return nil, lowerCount, lowerDrop, sampledTop, sampledCount, stats
    end
    return nil, nil, nil, sampledTop, sampledCount, stats
end

local function renderingSeatBelowCollision(env, obj, profile, sampledTop, sampledCount, renderObjectHits)
    if not (sampledTop and renderObjectHits and #renderObjectHits > 0) then return nil end
    if env.sittingSeatCategory(profile, obj) ~= "backed_chair" then return nil end

    local renderTop, renderCount = M.averageTopSurfaceHits(env, renderObjectHits, 12)
    local renderStats = M.surfaceHitZStats(renderObjectHits)
    if not (renderTop and renderStats) then return nil end

    local drop = (sampledTop.z or 0) - (renderTop.z or 0)
    if drop < 24 or drop > 58 then return nil end
    if renderStats.span > 14 then return nil end
    if renderCount < math.max(2, math.min(4, sampledCount or 0)) then return nil end

    env.debugLog(
        "sitting surface render visual seat selected below collision",
        "object", tostring(obj and obj.recordId),
        "profile", tostring(profile and profile.profileId),
        "collisionTop", tostring(sampledTop),
        "renderTop", tostring(renderTop),
        "renderSamples", tostring(renderCount),
        "renderSpan", tostring(renderStats.span),
        "drop", tostring(drop)
    )
    return renderTop, renderCount, drop
end

function M.sampleSittingSurface(env, obj, profile)
    if not obj then return nil, "missing_object", 0 end
    local offsets = {
        { x = 0, y = 0, z = 0 },
        { x = 20, y = 0, z = 0 }, { x = -20, y = 0, z = 0 },
        { x = 0, y = 20, z = 0 }, { x = 0, y = -20, z = 0 },
        { x = 36, y = 0, z = 0 }, { x = -36, y = 0, z = 0 },
        { x = 0, y = 36, z = 0 }, { x = 0, y = -36, z = 0 },
    }

    if profile and profile.type == "bench" then
        offsets[#offsets + 1] = { x = 60, y = 0, z = 0 }
        offsets[#offsets + 1] = { x = -60, y = 0, z = 0 }
        offsets[#offsets + 1] = { x = 0, y = 60, z = 0 }
        offsets[#offsets + 1] = { x = 0, y = -60, z = 0 }
    end

    local objectHits = {}
    local anyHits = {}
    local renderObjectHits = {}
    local renderAnyHits = {}
    for _, offset in ipairs(offsets) do
        local base = objectLocalOffset(env, obj, offset)
        if base then
            local from = base + env.util.vector3(0, 0, 160)
            local to = base - env.util.vector3(0, 0, 80)
            local result = env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
            if result.hit and result.hitPos then
                table.insert(anyHits, result.hitPos)
                if env.rayHitBelongsToObject(result.hitObject, obj) then
                    table.insert(objectHits, result.hitPos)
                end
            end
            local renderResult = castRenderingRay(env, from, to)
            if renderResult then
                table.insert(renderAnyHits, renderResult.hitPos)
                if env.rayHitBelongsToObject(renderResult.hitObject, obj) then
                    table.insert(renderObjectHits, renderResult.hitPos)
                end
            end
        end
    end

    local sampledTop, sampledCount = M.averageTopSurfaceHits(env, objectHits, 18)
    if sampledTop then
        local stats = M.surfaceHitZStats(objectHits)
        if stats and env.sittingSeatCategory(profile, obj) == "backed_chair" and stats.span >= 28 then
            local lowerBand, lowerCount, lowerDrop = lowerSeatBandForBackedChair(env, objectHits, stats, sampledCount, 18)
            if lowerBand then
                local objectScale = scalePolicy.objectScale(obj)
                if scalePolicy.isNonStandard(objectScale, 0.08) and (lowerDrop or 0) > 34 then
                    env.debugLog(
                        "sitting surface backed chair lower band rejected for scaled object",
                        "source", "collision",
                        "object", tostring(obj and obj.recordId),
                        "profile", tostring(profile and profile.profileId),
                        "objectScale", tostring(objectScale),
                        "drop", tostring(lowerDrop),
                        "chosenTop", tostring(sampledTop)
                    )
                else
                    env.debugLog(
                        "sitting surface backed chair lower band selected",
                        "source", "collision",
                        "object", tostring(obj and obj.recordId),
                        "profile", tostring(profile and profile.profileId),
                        "samples", tostring(stats.hits),
                        "topBandSamples", tostring(sampledCount),
                        "lowerBandSamples", tostring(lowerCount),
                        "minZ", tostring(stats.minZ),
                        "maxZ", tostring(stats.maxZ),
                        "span", tostring(stats.span),
                        "drop", tostring(lowerDrop),
                        "chosen", tostring(lowerBand)
                    )
                    return lowerBand, "sampled_sitting_surface_backed_chair_lower_band", lowerCount
                end
            else
                local renderLowerBand, renderLowerCount = backedChairLowerBand(env, renderObjectHits, obj, profile, "render", 18)
                if renderLowerBand then
                    return renderLowerBand, "render_sitting_surface_backed_chair_lower_band", renderLowerCount
                end
                env.debugLog(
                    "sitting surface suspicious backed chair high band",
                    "object", tostring(obj and obj.recordId),
                    "profile", tostring(profile and profile.profileId),
                    "samples", tostring(stats.hits),
                    "topBandSamples", tostring(sampledCount),
                    "lowerBandSamples", tostring(lowerCount),
                    "minZ", tostring(stats.minZ),
                    "maxZ", tostring(stats.maxZ),
                    "span", tostring(stats.span),
                    "drop", tostring(lowerDrop),
                    "chosen", tostring(sampledTop)
                )
            end
        end
        local renderSeat, renderSeatCount = renderingSeatBelowCollision(env, obj, profile, sampledTop, sampledCount, renderObjectHits)
        if renderSeat then
            return renderSeat, "render_sitting_surface_visual_seat_below_collision", renderSeatCount
        end
        return sampledTop, "sampled_sitting_surface_top", sampledCount
    end

    local renderLowerBand, renderLowerCount, _, renderTop, renderTopCount = backedChairLowerBand(env, renderObjectHits, obj, profile, "render", 18)
    if renderLowerBand then
        return renderLowerBand, "render_sitting_surface_backed_chair_lower_band", renderLowerCount
    end
    if renderTop then
        return renderTop, "render_sitting_surface_top", renderTopCount
    end

    if allowExternalSittingSurface(env, obj, profile) then
        sampledTop, sampledCount = M.averageTopSurfaceHits(env, anyHits, 18)
        if sampledTop and externalSittingSurfaceLooksPlausible(env, obj, profile, sampledTop) then
            return sampledTop, "sampled_sitting_surface_any_hit_external", sampledCount
        elseif sampledTop then
            return obj.position, "object_origin_after_suspicious_external_surface", sampledCount
        end
        sampledTop, sampledCount = M.averageTopSurfaceHits(env, renderAnyHits, 18)
        if sampledTop and externalSittingSurfaceLooksPlausible(env, obj, profile, sampledTop) then
            return sampledTop, "render_sitting_surface_any_hit_external", sampledCount
        elseif sampledTop then
            return obj.position, "object_origin_after_suspicious_render_surface", sampledCount
        end
    end

    local center = M.objectTopPosition(env, obj)
    if center then return center, "object_center_surface", 1 end

    return nil, "no_object_surface_hit", 0
end

return M
