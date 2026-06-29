-- interactions/sleeping/surfaceSampler.lua
---@omw-context local
-- Resolves the sleep surface for a selected bed-like object.  This deliberately
-- prioritizes evidence that belongs to the bed object before considering generic
-- nearby physics/render hits.  That prevents nightstands, tables, floors,
-- stacked clutter, or canopy collision from becoming the "bed" surface.

local util = require('openmw.util')
local sleepSurfacePolicy = require('scripts/sitDownPlease/interactions/sleeping/surfacePolicy')
local sleepSurfaceClutter = require('scripts/sitDownPlease/interactions/sleeping/surfaceClutter')

local M = {}

local function text(value)
    return string.lower(tostring(value or ""))
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function effectiveSleepSurfaceMinHeight(profile)
    local minHeight = profile and profile.sleepSurfaceMinHeight or 25
    local mode = tostring(profile and profile.sleepSurfaceCenterMode or "")
    local bedType = string.lower(tostring(profile and (profile.bedType or profile.type) or ""))
    local rootZ = tonumber(profile and profile.sleepRootZOffset) or 0

    if mode == "object_origin_xy"
        and rootZ <= -120
        and bedType ~= "bedroll"
        and bedType ~= "hammock"
    then
        -- Object-origin beds can ray-hit low frames or legs before the visible
        -- mattress.  A prone root lowered by ~180 units should not treat those
        -- low hits as the sleep surface.
        minHeight = math.max(minHeight, 80)
    end

    return minHeight
end

local function surfaceEntriesInBand(entries, obj, profile)
    if not entries or #entries == 0 or not obj or not obj.position then return {} end

    local minHeight = effectiveSleepSurfaceMinHeight(profile)
    local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
    local minZ = obj.position.z + minHeight
    local maxZ = obj.position.z + maxHeight

    local filtered = {}
    for _, entry in ipairs(entries) do
        local hitPos = entry and entry.hitPos
        if hitPos and hitPos.z >= minZ and hitPos.z <= maxZ then
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

local function hitPositionsFromEntries(entries)
    local hits = {}
    for _, entry in ipairs(entries or {}) do
        if entry and entry.hitPos then hits[#hits + 1] = entry.hitPos end
    end
    return hits
end

local function averageSurfaceBandHits(entriesOrHits, obj, profile)
    if not entriesOrHits or #entriesOrHits == 0 or not obj or not obj.position then return nil, 0 end

    local hits = {}
    local first = entriesOrHits[1]
    if first and first.hitPos then
        hits = hitPositionsFromEntries(surfaceEntriesInBand(entriesOrHits, obj, profile))
    else
        local minHeight = effectiveSleepSurfaceMinHeight(profile)
        local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
        local minZ = obj.position.z + minHeight
        local maxZ = obj.position.z + maxHeight
        for _, hitPos in ipairs(entriesOrHits) do
            if hitPos and hitPos.z >= minZ and hitPos.z <= maxZ then hits[#hits + 1] = hitPos end
        end
    end

    if #hits == 0 then return nil, 0 end
    local sum = util.vector3(0, 0, 0)
    for _, hitPos in ipairs(hits) do sum = sum + hitPos end
    return sum / #hits, #hits
end

local function centerFromSampleOffsetExtents(ctx, entries, obj)
    if not entries or #entries == 0 or not obj then return nil, 0, nil end

    local minX, maxX, minY, maxY, zSum, count = nil, nil, nil, nil, 0, 0
    for _, entry in ipairs(entries) do
        local offset = entry.offset or {}
        local hitPos = entry.hitPos
        local x = offset.x or 0
        local y = offset.y or 0
        if not minX or x < minX then minX = x end
        if not maxX or x > maxX then maxX = x end
        if not minY or y < minY then minY = y end
        if not maxY or y > maxY then maxY = y end
        if hitPos then
            zSum = zSum + hitPos.z
            count = count + 1
        end
    end

    if count == 0 or not minX or not maxX or not minY or not maxY then return nil, 0, nil end

    local centerOffset = { x = (minX + maxX) / 2, y = (minY + maxY) / 2, z = 0 }
    local center = ctx.objectLocalOffset(obj, centerOffset)
    if center then center = util.vector3(center.x, center.y, zSum / count) end
    return center, count, centerOffset
end

local function repairEligibleProfile(profile)
    if not profile then return false end
    local mode = tostring(profile.sleepSurfaceCenterMode or "")
    if mode ~= "sample_extents" then return false end
    local textValue = text(profile.bedType or profile.type) .. " " .. text(profile.profileId or profile.recordId)
    if textValue:find("bunk", 1, true)
        or textValue:find("canopy", 1, true)
        or textValue:find("canop", 1, true)
        or textValue:find("bedroll", 1, true)
        or textValue:find("hammock", 1, true) then
        return false
    end
    return (tonumber(profile.sleepRootZOffset) or 0) <= -120
end

local function explicitHighAnyTopAnchor(profile)
    if profile and profile.allowAnySleepSurfaceAnchor == true then return true end
    local policy = text(profile and profile.sleepSurfaceAnchorPolicy)
    return policy == "high_any_top" or policy == "top_any_hit" or policy == "any_surface_anchor"
end

local function topSurfaceFromEntries(ctx, entries, obj, profile)
    if not (ctx and ctx.averageTopSurfaceHits and obj and obj.position) then return nil, 0 end
    local bandEntries = surfaceEntriesInBand(entries, obj, profile)
    local topCenter, topCount = ctx.averageTopSurfaceHits(hitPositionsFromEntries(bandEntries), profile and profile.sleepSurfaceTopTolerance or 18)
    if not (topCenter and topCenter.z) then return nil, 0 end

    local relativeZ = topCenter.z - (obj.position.z or 0)
    local minHeight = effectiveSleepSurfaceMinHeight(profile)
    local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
    if relativeZ < minHeight or relativeZ > maxHeight then return nil, 0 end
    return topCenter, topCount
end

local function betterTopSurface(current, currentCount, currentMode, candidate, candidateCount, candidateMode)
    if not candidate then return current, currentCount, currentMode end
    if not current then return candidate, candidateCount, candidateMode end
    if (candidate.z or 0) > (current.z or 0) + 6 then
        return candidate, candidateCount, candidateMode
    end
    return current, currentCount, currentMode
end

local function corroboratedAnyTopSurface(ctx, obj, profile, anyEntries, renderAnyEntries)
    local physicsTop, physicsTopCount = topSurfaceFromEntries(ctx, anyEntries, obj, profile)
    local renderTop, renderTopCount = topSurfaceFromEntries(ctx, renderAnyEntries, obj, profile)
    local meta = {
        physicsTopZ = physicsTop and physicsTop.z or nil,
        physicsTopCount = physicsTopCount or 0,
        renderTopZ = renderTop and renderTop.z or nil,
        renderTopCount = renderTopCount or 0,
    }

    if not (physicsTop and renderTop and (physicsTopCount or 0) >= 2 and (renderTopCount or 0) >= 2) then
        meta.reason = physicsTop and "any_surface_lacks_render_corroboration" or "any_surface_lacks_physics_top"
        return nil, 0, nil, meta
    end

    local tolerance = tonumber(profile and profile.sleepAnySurfaceAgreementTolerance) or 32
    local deltaZ = math.abs((physicsTop.z or 0) - (renderTop.z or 0))
    meta.deltaZ = deltaZ
    meta.tolerance = tolerance

    local top, topCount, topMode = betterTopSurface(
        physicsTop,
        physicsTopCount,
        "top_any_hit",
        renderTop,
        renderTopCount,
        "render_any_surface_band"
    )
    meta.reason = deltaZ > tolerance and "any_surface_render_mismatch" or "any_surface_render_corroborated"
    if deltaZ > tolerance then
        return nil, 0, nil, meta
    end
    return top, topCount, topMode, meta
end

local function highAnyPhysicsOnlyRepairSurface(ctx, obj, profile, anyEntries, agreement)
    if not (explicitHighAnyTopAnchor(profile) and obj and obj.position) then return nil, 0, nil end
    local physicsTop, physicsTopCount = topSurfaceFromEntries(ctx, anyEntries, obj, profile)
    if not (physicsTop and physicsTop.z and (physicsTopCount or 0) >= (tonumber(profile.sleepHighAnyPhysicsRepairMinCount) or 3)) then
        return nil, 0, nil
    end
    if agreement then
        agreement.physicsOnlyRepair = true
        agreement.physicsOnlyTopZ = physicsTop.z
        agreement.physicsOnlyTopCount = physicsTopCount
    end
    return physicsTop, physicsTopCount, "top_any_hit_explicit_physics_only"
end

local function repairTopSurface(ctx, obj, profile, anyEntries, renderAnyEntries)
    local top, topCount, topMode, agreement = corroboratedAnyTopSurface(ctx, obj, profile, anyEntries, renderAnyEntries)
    if top then return top, topCount, topMode, agreement end
    local physicsTop, physicsTopCount, physicsMode = highAnyPhysicsOnlyRepairSurface(ctx, obj, profile, anyEntries, agreement)
    if physicsTop then
        agreement = agreement or {}
        agreement.reason = "explicit_high_any_physics_only"
        agreement.physicsOnlyRepair = true
        return physicsTop, physicsTopCount, physicsMode, agreement
    end
    return nil, 0, nil, agreement
end

local function repairLowObjectSurface(ctx, obj, profile, objectSurface, anyEntries, renderAnyEntries, allowAnySleepSurface)
    if not (allowAnySleepSurface and repairEligibleProfile(profile) and objectSurface and objectSurface.z and obj and obj.position) then return nil end

    local minHeight = effectiveSleepSurfaceMinHeight(profile)
    local relativeObjectZ = objectSurface.z - (obj.position.z or 0)
    local lowTolerance = tonumber(profile.sleepLowObjectSurfaceTolerance) or 45
    if relativeObjectZ > minHeight + lowTolerance then return nil end

    local top, topCount, topMode, agreement = repairTopSurface(ctx, obj, profile, anyEntries, renderAnyEntries)
    if not (top and top.z and (topCount or 0) >= 2) then
        debugLog(
            ctx,
            "sleep low object surface repair skipped",
            "object", tostring(obj and obj.recordId),
            "profile", tostring(profile and profile.profileId),
            "objectSurfaceZ", tostring(objectSurface.z),
            "reason", tostring(agreement and agreement.reason or "no_any_surface"),
            "physicsTopZ", tostring(agreement and agreement.physicsTopZ),
            "renderTopZ", tostring(agreement and agreement.renderTopZ),
            "physicsOnlyTopZ", tostring(agreement and agreement.physicsOnlyTopZ),
            "deltaZ", tostring(agreement and agreement.deltaZ),
            "tolerance", tostring(agreement and agreement.tolerance)
        )
        return nil
    end
    local requiredDelta = tonumber(profile.sleepLowObjectSurfaceRepairDelta) or 90
    local deltaZ = (top.z or 0) - (objectSurface.z or 0)
    if deltaZ < requiredDelta then return nil end

    debugLog(
        ctx,
        "sleep low object surface repaired",
        "object", tostring(obj and obj.recordId),
        "profile", tostring(profile and profile.profileId),
        "objectSurfaceZ", tostring(objectSurface.z),
        "topSurfaceZ", tostring(top.z),
        "deltaZ", tostring(deltaZ),
        "topCount", tostring(topCount),
        "mode", tostring(topMode),
        "repairReason", tostring(agreement and agreement.reason),
        "physicsOnlyRepair", tostring(agreement and agreement.physicsOnlyRepair),
        "physicsTopZ", tostring(agreement and agreement.physicsTopZ or agreement and agreement.physicsOnlyTopZ),
        "renderTopZ", tostring(agreement and agreement.renderTopZ),
        "renderDeltaZ", tostring(agreement and agreement.deltaZ)
    )
    return top, topCount, topMode
end

local function unrepairedLowObjectSurface(ctx, obj, profile, objectSurface, anyEntries, renderAnyEntries)
    if not (repairEligibleProfile(profile) and objectSurface and objectSurface.z and obj and obj.position) then return false end

    local minHeight = effectiveSleepSurfaceMinHeight(profile)
    local relativeObjectZ = objectSurface.z - (obj.position.z or 0)
    local lowTolerance = tonumber(profile.sleepLowObjectSurfaceTolerance) or 45
    if relativeObjectZ > minHeight + lowTolerance then return false end

    local top, topCount, topMode, agreement = corroboratedAnyTopSurface(ctx, obj, profile, anyEntries, renderAnyEntries)
    local physicsTopZ = agreement and agreement.physicsTopZ or nil
    local renderTopZ = agreement and agreement.renderTopZ or nil
    local candidateTopZ = top and top.z or physicsTopZ or renderTopZ
    local candidateCount = topCount or 0
    if (agreement and agreement.physicsTopCount or 0) > candidateCount then candidateCount = agreement.physicsTopCount end
    if (agreement and agreement.renderTopCount or 0) > candidateCount then candidateCount = agreement.renderTopCount end
    if not (candidateTopZ and candidateCount >= 2) then return false end

    local requiredDelta = tonumber(profile.sleepLowObjectSurfaceRepairDelta) or 90
    local deltaZ = candidateTopZ - (objectSurface.z or 0)
    if deltaZ < requiredDelta then return false end

    debugLog(
        ctx,
        "sleep low object surface left unrepaired",
        "object", tostring(obj and obj.recordId),
        "profile", tostring(profile and profile.profileId),
        "objectSurfaceZ", tostring(objectSurface.z),
        "candidateTopZ", tostring(candidateTopZ),
        "deltaZ", tostring(deltaZ),
        "candidateCount", tostring(candidateCount),
        "reason", tostring(agreement and agreement.reason or "unknown"),
        "mode", tostring(topMode),
        "physicsTopZ", tostring(physicsTopZ),
        "renderTopZ", tostring(renderTopZ)
    )
    return true
end

local function castSleepVisualSurface(ctx, from, to)
    local nearby = ctx and ctx.nearby
    if not (nearby and nearby.castRenderingRay and from and to) then return nil end
    local options = ctx.actor and { ignore = ctx.actor } or nil
    local ok, result = pcall(function()
        return nearby.castRenderingRay(from, to, options)
    end)
    if not (ok and result and result.hit and result.hitPos) then return nil end
    return result
end

local function collectSampleEntries(ctx, obj, profile)
    local nearby = ctx.nearby
    local offsets = profile and profile.sleepSurfaceSampleOffsets or nil
    if not offsets then return nil end

    local objectEntries = {}
    local anyEntries = {}
    local renderObjectEntries = {}
    local renderAnyEntries = {}

    for _, offset in ipairs(offsets) do
        local base = ctx.objectLocalOffset(obj, offset)
        if base then
            local from = base + util.vector3(0, 0, 260)
            local to = base - util.vector3(0, 0, 160)
            local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
            if result.hit and result.hitPos then
                local entry = { offset = offset, hitPos = result.hitPos, hitObject = result.hitObject }
                anyEntries[#anyEntries + 1] = entry
                if ctx.rayHitBelongsToObject(result.hitObject, obj) then objectEntries[#objectEntries + 1] = entry end
            end
            local renderResult = castSleepVisualSurface(ctx, from, to)
            if renderResult then
                local entry = { offset = offset, hitPos = renderResult.hitPos, hitObject = renderResult.hitObject }
                renderAnyEntries[#renderAnyEntries + 1] = entry
                if ctx.rayHitBelongsToObject(renderResult.hitObject, obj) then renderObjectEntries[#renderObjectEntries + 1] = entry end
            end
        end
    end

    return objectEntries, anyEntries, renderObjectEntries, renderAnyEntries
end

local preferRenderObjectSurface -- forward declaration

local function filteredAnyEntries(ctx, entries, obj, profile, source)
    return sleepSurfaceClutter.filterEntries(entries, obj, profile, {
        profiles = ctx.profiles,
        rayHitBelongsToObject = ctx.rayHitBelongsToObject,
        debugLog = ctx.debugLog,
        source = source,
    })
end

local function objectOriginXY(ctx, obj, profile, objectEntries, anyEntries, renderObjectEntries, renderAnyEntries, allowAnySleepSurface, anySleepSurfaceBlockedReason)
    local preferRender = preferRenderObjectSurface(ctx, obj, profile)
    local firstEntries = surfaceEntriesInBand(preferRender and renderObjectEntries or objectEntries, obj, profile)
    if #firstEntries > 0 then
        local zSum = 0
        for _, entry in ipairs(firstEntries) do zSum = zSum + (entry.hitPos.z or 0) end
        return util.vector3(obj.position.x, obj.position.y, zSum / #firstEntries), #firstEntries, preferRender and "object_origin_xy_render_object_band" or "object_origin_xy", { x = 0, y = 0, z = 0 }
    end

    local entries = surfaceEntriesInBand(preferRender and objectEntries or renderObjectEntries, obj, profile)
    if #entries > 0 then
        local zSum = 0
        for _, entry in ipairs(entries) do zSum = zSum + (entry.hitPos.z or 0) end
        return util.vector3(obj.position.x, obj.position.y, zSum / #entries), #entries, preferRender and "object_origin_xy" or "object_origin_xy_render_object_band", { x = 0, y = 0, z = 0 }
    end

    local top = ctx.objectTopPosition(obj)
    if top then
        local minHeight = effectiveSleepSurfaceMinHeight(profile)
        local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
        local relativeTop = (top.z or 0) - (obj.position.z or 0)
        if relativeTop >= minHeight and relativeTop <= maxHeight then
            return util.vector3(obj.position.x, obj.position.y, top.z), 1, "object_origin_xy_top", { x = 0, y = 0, z = 0 }
        end
        if profile.allowLowObjectOriginTop == true and relativeTop > 0 and relativeTop <= maxHeight then
            debugLog(ctx, "sleep object-origin low top accepted", "object", tostring(obj.recordId), "profile", tostring(profile and profile.profileId), "relativeTop", tostring(relativeTop), "minHeight", tostring(minHeight), "maxHeight", tostring(maxHeight))
            return util.vector3(obj.position.x, obj.position.y, top.z), 1, "object_origin_xy_low_top", { x = 0, y = 0, z = 0 }
        end
    end

    if allowAnySleepSurface then
        entries = surfaceEntriesInBand(anyEntries, obj, profile)
        if #entries > 0 then
            local zSum = 0
            for _, entry in ipairs(entries) do zSum = zSum + (entry.hitPos.z or 0) end
            return util.vector3(obj.position.x, obj.position.y, zSum / #entries), #entries, "object_origin_xy_any_band", { x = 0, y = 0, z = 0 }
        end
        entries = surfaceEntriesInBand(renderAnyEntries, obj, profile)
        if #entries > 0 then
            local zSum = 0
            for _, entry in ipairs(entries) do zSum = zSum + (entry.hitPos.z or 0) end
            return util.vector3(obj.position.x, obj.position.y, zSum / #entries), #entries, "object_origin_xy_render_any_band", { x = 0, y = 0, z = 0 }
        end
    else
        debugLog(ctx, "sleep object-origin any-surface skipped", "object", tostring(obj.recordId), "reason", tostring(anySleepSurfaceBlockedReason))
    end

    debugLog(ctx, "sleep object-origin fallback after rejected top", "object", tostring(obj.recordId), "profile", tostring(profile and profile.profileId), "reason", "no_valid_surface_band_for_object_origin_xy")
    return obj.position, 0, "object_origin_xy_fallback", { x = 0, y = 0, z = 0 }
end

local function sampleExtents(ctx, obj, profile, objectEntries, anyEntries, renderObjectEntries, renderAnyEntries, allowAnySleepSurface)
    local preferRender = preferRenderObjectSurface(ctx, obj, profile)
    local entries = surfaceEntriesInBand(preferRender and renderObjectEntries or objectEntries, obj, profile)
    local center, count, centerOffset = centerFromSampleOffsetExtents(ctx, entries, obj)
    if center then
        local repaired, repairedCount, repairedMode = repairLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries, allowAnySleepSurface)
        if repaired then return repaired, repairedCount, repairedMode, nil end
        if unrepairedLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries) then
            return center, count, (preferRender and "render_object_sample_extents" or "object_sample_extents") .. "_low_unrepaired", centerOffset
        end
        return center, count, preferRender and "render_object_sample_extents" or "object_sample_extents", centerOffset
    end

    entries = surfaceEntriesInBand(preferRender and objectEntries or renderObjectEntries, obj, profile)
    center, count, centerOffset = centerFromSampleOffsetExtents(ctx, entries, obj)
    if center then
        local repaired, repairedCount, repairedMode = repairLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries, allowAnySleepSurface)
        if repaired then return repaired, repairedCount, repairedMode, nil end
        if unrepairedLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries) then
            return center, count, (preferRender and "object_sample_extents" or "render_object_sample_extents") .. "_low_unrepaired", centerOffset
        end
        return center, count, preferRender and "object_sample_extents" or "render_object_sample_extents", centerOffset
    end

    center, count = averageSurfaceBandHits(preferRender and renderObjectEntries or objectEntries, obj, profile)
    if center then
        if unrepairedLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries) then
            return center, count, (preferRender and "render_object_surface_band" or "object_surface_band") .. "_low_unrepaired", nil
        end
        return center, count, preferRender and "render_object_surface_band" or "object_surface_band", nil
    end

    center, count = averageSurfaceBandHits(preferRender and objectEntries or renderObjectEntries, obj, profile)
    if center then
        if unrepairedLowObjectSurface(ctx, obj, profile, center, anyEntries, renderAnyEntries) then
            return center, count, (preferRender and "object_surface_band" or "render_object_surface_band") .. "_low_unrepaired", nil
        end
        return center, count, preferRender and "object_surface_band" or "render_object_surface_band", nil
    end

    if allowAnySleepSurface then
        entries = surfaceEntriesInBand(anyEntries, obj, profile)
        center, count, centerOffset = centerFromSampleOffsetExtents(ctx, entries, obj)
        if center then return center, count, "any_sample_extents", centerOffset end

        entries = surfaceEntriesInBand(renderAnyEntries, obj, profile)
        center, count, centerOffset = centerFromSampleOffsetExtents(ctx, entries, obj)
        if center then return center, count, "render_any_sample_extents", centerOffset end

        center, count = averageSurfaceBandHits(anyEntries, obj, profile)
        if center then return center, count, "surface_band_any_hit", nil end

        center, count = averageSurfaceBandHits(renderAnyEntries, obj, profile)
        if center then return center, count, "render_any_surface_band", nil end
    end

    local tolerance = profile and profile.sleepSurfaceTopTolerance or 18
    local objectHits = hitPositionsFromEntries(objectEntries)
    local topCenter, topCount = ctx.averageTopSurfaceHits and ctx.averageTopSurfaceHits(objectHits, tolerance) or nil, 0
    if topCenter then return topCenter, topCount, "object_hits_top", nil end

    if allowAnySleepSurface then
        local anyHits = hitPositionsFromEntries(anyEntries)
        topCenter, topCount = ctx.averageTopSurfaceHits and ctx.averageTopSurfaceHits(anyHits, tolerance) or nil, 0
        if topCenter then return topCenter, topCount, "top_any_hit", nil end
    end

    return nil, 0, nil, nil
end


local function profileText(ctx, obj, profile)
    local model = ""
    if ctx and ctx.profiles and ctx.profiles.objectModelPath then
        model = tostring(ctx.profiles.objectModelPath(obj) or "")
    end
    return table.concat({
        text(obj and (obj.recordId or obj.id)),
        text(model),
        text(profile and (profile.bedType or profile.type or profile.profileId or profile.recordId)),
    }, " ")
end

local function profileIsBunkOrCanopy(ctx, obj, profile)
    local t = profileText(ctx, obj, profile)
    return t:find("bunk", 1, true) ~= nil
        or t:find("canopy", 1, true) ~= nil
        or t:find("canop", 1, true) ~= nil
end

function preferRenderObjectSurface(ctx, obj, profile)
    if not profile then return false end
    if profile.sleepPreferPhysicsSurface == true then return false end
    if profile.sleepPreferRenderSurface == true then return true end
    if profileIsBunkOrCanopy(ctx, obj, profile) then return true end
    local rootZ = tonumber(profile.sleepRootZOffset) or 0
    return rootZ <= -150 and tostring(profile.sleepSurfaceCenterMode or "") == "sample_extents"
end


function M.sample(ctx, obj, profile)
    if not obj then return nil, 0, "missing_object", nil end
    if not profile or not profile.sleepSurfaceSampleOffsets then
        return ctx.objectTopPosition(obj), 1, "object_center", nil
    end

    local objectEntries, anyEntries, renderObjectEntries, renderAnyEntries = collectSampleEntries(ctx, obj, profile)
    local allowAnySleepSurface, anySleepSurfaceBlockedReason = sleepSurfacePolicy.anySurfaceAllowed(profile)
    local filteredAny = filteredAnyEntries(ctx, anyEntries, obj, profile, "physics_any")
    local filteredRenderAny = filteredAnyEntries(ctx, renderAnyEntries, obj, profile, "render_any")

    if not allowAnySleepSurface then
        debugLog(ctx, "sleep any-surface fallback blocked", "object", tostring(obj.recordId), "profile", tostring(profile and profile.profileId), "reason", tostring(anySleepSurfaceBlockedReason), "slots", tostring(profile and profile.slots and #profile.slots or 0), "bedType", tostring(profile and profile.bedType))
    end

    if profile.sleepSurfaceCenterMode == "object_origin_xy" then
        return objectOriginXY(ctx, obj, profile, objectEntries, filteredAny, renderObjectEntries, filteredRenderAny, allowAnySleepSurface, anySleepSurfaceBlockedReason)
    end

    if profile.sleepSurfaceCenterMode == "sample_extents" then
        local center, count, mode, centerOffset = sampleExtents(ctx, obj, profile, objectEntries, filteredAny, renderObjectEntries, filteredRenderAny, allowAnySleepSurface)
        if center then return center, count, mode, centerOffset end
    end

    -- General fallback after center-mode-specific logic: still prefer object-owned
    -- physics/render evidence before generic nearby hits.
    local center, count = averageSurfaceBandHits(objectEntries, obj, profile)
    if center then return center, count, "object_surface_band", nil end

    center, count = averageSurfaceBandHits(renderObjectEntries, obj, profile)
    if center then return center, count, "render_object_surface_band", nil end

    if allowAnySleepSurface then
        center, count = averageSurfaceBandHits(filteredAny, obj, profile)
        if center then return center, count, "surface_band_any_hit", nil end

        center, count = averageSurfaceBandHits(filteredRenderAny, obj, profile)
        if center then return center, count, "render_any_surface_band", nil end
    end

    local tolerance = profile and profile.sleepSurfaceTopTolerance or 18
    local topCenter, topCount = ctx.averageTopSurfaceHits(hitPositionsFromEntries(objectEntries), tolerance)
    if topCenter then return topCenter, topCount, "object_hits_top", nil end

    if allowAnySleepSurface then
        topCenter, topCount = ctx.averageTopSurfaceHits(hitPositionsFromEntries(filteredAny), tolerance)
        if topCenter then return topCenter, topCount, "top_any_hit", nil end
    end

    return ctx.objectTopPosition(obj), 0, "object_origin_fallback", nil
end

return M
