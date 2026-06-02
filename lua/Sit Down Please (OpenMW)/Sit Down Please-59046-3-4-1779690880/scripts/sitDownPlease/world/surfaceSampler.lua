-- world/surfaceSampler.lua
--
-- Pure local-script surface sampling helpers. This module preserves the current
-- seat-surface algorithm; future sampler changes should happen here, not inside
-- interactionSeeker.lua.

local M = {}

local function objectLocalOffset(env, obj, offset)
    if not obj or not offset then return obj and obj.position or nil end
    local scale = tonumber(obj.scale) or 1
    if scale <= 0 then scale = 1 end
    return obj.position + obj.rotation * env.util.vector3((offset.x or 0) * scale, (offset.y or 0) * scale, (offset.z or 0) * scale)
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
    if lowerCount < math.max(2, topBandSamples or 0) then
        local sparseButClearSeatBand = lowerCount >= 1
            and (topBandSamples or 0) <= 1
            and (stats.hits or 0) <= 3
            and drop >= 28
            and drop <= 55
        if not sparseButClearSeatBand then return nil, lowerCount, drop end
    end
    return lowerBand, lowerCount, drop
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
        end
    end

    local sampledTop, sampledCount = M.averageTopSurfaceHits(env, objectHits, 18)
    if sampledTop then
        local stats = M.surfaceHitZStats(objectHits)
        if stats and env.sittingSeatCategory(profile, obj) == "backed_chair" and stats.span >= 28 and sampledCount <= math.max(2, math.floor(stats.hits / 2)) then
            local lowerBand, lowerCount, lowerDrop = lowerSeatBandForBackedChair(env, objectHits, stats, sampledCount, 18)
            if lowerBand then
                env.debugLog(
                    "sitting surface backed chair lower band selected",
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
            else
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
        return sampledTop, "sampled_sitting_surface_top", sampledCount
    end

    if profile and profile.externalProfile == true then
        sampledTop, sampledCount = M.averageTopSurfaceHits(env, anyHits, 18)
        if sampledTop then
            return sampledTop, "sampled_sitting_surface_any_hit_external", sampledCount
        end
    end

    local center = M.objectTopPosition(env, obj)
    if center then return center, "object_center_surface", 1 end

    return nil, "no_object_surface_hit", 0
end

return M
