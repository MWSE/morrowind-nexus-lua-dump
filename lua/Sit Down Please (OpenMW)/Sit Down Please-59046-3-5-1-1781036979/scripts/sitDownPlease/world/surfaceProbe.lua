-- Calibration-only comparison between physics collision rays and rendering rays.
---@omw-context none
-- This does not choose placement; it prints evidence for profile triage.

local scalePolicy = require('scripts/sitDownPlease/world/scalePolicy')

local M = {}

local function cleanNumber(value)
    value = tonumber(value) or 0
    if math.abs(value) < 0.0001 then value = 0 end
    local rounded = math.floor(value + (value >= 0 and 0.5 or -0.5))
    if math.abs(value - rounded) < 0.0001 then return tostring(rounded) end
    local text = string.format("%.3f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    if text == "-0" then return "0" end
    return text
end

local function vectorLabel(pos)
    if not pos then return "nil" end
    return cleanNumber(pos.x) .. "," .. cleanNumber(pos.y) .. "," .. cleanNumber(pos.z)
end

local function objectLocalOffset(env, obj, offset)
    if not obj or not offset then return obj and obj.position or nil end
    return scalePolicy.objectLocalPosition(env.util, obj, offset)
end

local function rayHitBelongsToObject(env, hitObject, obj)
    if env.rayHitBelongsToObject then
        local ok, belongs = pcall(env.rayHitBelongsToObject, hitObject, obj)
        if ok then return belongs == true end
    end
    if hitObject == obj then return true end
    if not (hitObject and obj) then return false end
    local hitPos = hitObject.position
    local objPos = obj.position
    local positionsClose = false
    if hitPos and objPos then
        positionsClose = (hitPos - objPos):length() <= 12
    end
    if hitObject.id and obj.id and hitObject.id == obj.id then
        return not (hitPos and objPos) or positionsClose
    end
    if hitObject.recordId and obj.recordId and hitObject.recordId == obj.recordId then
        return positionsClose
    end
    return false
end

local function sittingOffsets(profile)
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
    return offsets, 160, 80
end

local function sleepingOffsets(profile)
    local offsets = profile and profile.sleepSurfaceSampleOffsets or nil
    if offsets then return offsets, 260, 160 end
    return { { x = 0, y = 0, z = 0 } }, 180, 60
end

local function topAverage(entries, tolerance)
    if not entries or #entries == 0 then return nil, 0 end
    local maxZ = nil
    for _, entry in ipairs(entries) do
        local z = entry.hitPos and entry.hitPos.z or nil
        if z and (not maxZ or z > maxZ) then maxZ = z end
    end
    if not maxZ then return nil, 0 end
    local minZ = maxZ - (tolerance or 18)
    local sum, count = 0, 0
    for _, entry in ipairs(entries) do
        local z = entry.hitPos and entry.hitPos.z or nil
        if z and z >= minZ then
            sum = sum + z
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return sum / count, count
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
        minHeight = math.max(minHeight, 80)
    end

    return minHeight
end

local function bandAverage(entries, obj, profile)
    if not entries or #entries == 0 or not (obj and obj.position) then return nil, 0 end
    local minHeight = effectiveSleepSurfaceMinHeight(profile)
    local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
    local minZ = obj.position.z + minHeight
    local maxZ = obj.position.z + maxHeight
    local sum, count = 0, 0
    for _, entry in ipairs(entries) do
        local z = entry.hitPos and entry.hitPos.z or nil
        if z and z >= minZ and z <= maxZ then
            sum = sum + z
            count = count + 1
        end
    end
    if count == 0 then return nil, 0 end
    return sum / count, count
end

local function centerFromSampleOffsetExtents(env, entries, obj)
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
            zSum = zSum + (hitPos.z or 0)
            count = count + 1
        end
    end
    if count == 0 or not minX or not maxX or not minY or not maxY then return nil, 0, nil end
    local centerOffset = { x = (minX + maxX) / 2, y = (minY + maxY) / 2, z = 0 }
    local center = objectLocalOffset(env, obj, centerOffset)
    if center then center = env.util.vector3(center.x, center.y, zSum / count) end
    return center, count, centerOffset
end

local function summary(env, entries, obj, profile, kind)
    local minZ, maxZ = nil, nil
    for _, entry in ipairs(entries or {}) do
        local z = entry.hitPos and entry.hitPos.z or nil
        if z then
            minZ = minZ and math.min(minZ, z) or z
            maxZ = maxZ and math.max(maxZ, z) or z
        end
    end
    local topZ, topCount = topAverage(entries, profile and profile.sleepSurfaceTopTolerance or 18)
    local bandZ, bandCount = nil, 0
    local extentsCenter, extentsCount, extentsOffset = nil, 0, nil
    if kind == "sleeping" then
        bandZ, bandCount = bandAverage(entries, obj, profile)
        if profile and profile.sleepSurfaceCenterMode == "sample_extents" then
            local bandEntries = {}
            local minHeight = effectiveSleepSurfaceMinHeight(profile)
            local maxHeight = profile.sleepSurfaceMaxHeight or 260
            local minBandZ = obj and obj.position and obj.position.z + minHeight or nil
            local maxBandZ = obj and obj.position and obj.position.z + maxHeight or nil
            for _, entry in ipairs(entries or {}) do
                local z = entry.hitPos and entry.hitPos.z or nil
                if z and minBandZ and maxBandZ and z >= minBandZ and z <= maxBandZ then
                    bandEntries[#bandEntries + 1] = entry
                end
            end
            extentsCenter, extentsCount, extentsOffset = centerFromSampleOffsetExtents(env, bandEntries, obj)
        end
    end
    return {
        count = entries and #entries or 0,
        minZ = minZ,
        maxZ = maxZ,
        span = minZ and maxZ and (maxZ - minZ) or nil,
        topZ = topZ,
        topCount = topCount,
        bandZ = bandZ,
        bandCount = bandCount,
        extentsCenter = extentsCenter,
        extentsCount = extentsCount,
        extentsOffset = extentsOffset,
    }
end

local function castPhysics(env, obj, offsets, fromZ, toZ)
    local objectEntries, anyEntries = {}, {}
    for _, offset in ipairs(offsets or {}) do
        local base = objectLocalOffset(env, obj, offset)
        if base then
            local from = base + env.util.vector3(0, 0, fromZ)
            local to = base - env.util.vector3(0, 0, toZ)
            local ok, result = pcall(function()
                return env.nearby.castRay(from, to, { collisionType = env.nearby.COLLISION_TYPE.World })
            end)
            if ok and result and result.hit and result.hitPos then
                local entry = { offset = offset, hitPos = result.hitPos, hitObject = result.hitObject }
                anyEntries[#anyEntries + 1] = entry
                if rayHitBelongsToObject(env, result.hitObject, obj) then
                    objectEntries[#objectEntries + 1] = entry
                end
            end
        end
    end
    return objectEntries, anyEntries
end

local function labelObject(env, obj)
    if not obj then return "nil" end
    local model = nil
    if env.profiles and env.profiles.objectModelPath then
        local ok, value = pcall(env.profiles.objectModelPath, obj)
        if ok then model = value end
    end
    return tostring(obj.recordId or obj.id) .. (model and ("|" .. tostring(model)) or "")
end

local function printSummary(prefix, s)
    print("[SitDownPlease Calibration Export]", prefix,
        "hits", tostring(s and s.count or 0),
        "topZ", s and s.topZ and cleanNumber(s.topZ) or "nil",
        "topCount", tostring(s and s.topCount or 0),
        "bandZ", s and s.bandZ and cleanNumber(s.bandZ) or "nil",
        "bandCount", tostring(s and s.bandCount or 0),
        "minZ", s and s.minZ and cleanNumber(s.minZ) or "nil",
        "maxZ", s and s.maxZ and cleanNumber(s.maxZ) or "nil",
        "span", s and s.span and cleanNumber(s.span) or "nil",
        "extentsCenter", vectorLabel(s and s.extentsCenter),
        "extentsCount", tostring(s and s.extentsCount or 0),
        "extentsOffset", vectorLabel(s and s.extentsOffset)
    )
end

local function selectedModeUsesAnySurface(mode)
    local value = string.lower(tostring(mode or ""))
    return value:find("any", 1, true) ~= nil
end

local summaryCandidateZ

local function selectedMinusObjectSurfaceZ(objectSummary, selectedZ)
    if not selectedZ then return nil end
    local objectZ = summaryCandidateZ(objectSummary, selectedZ)
    if not objectZ then return nil end
    return selectedZ - objectZ
end

local function isBackedChair(profile)
    return tostring(profile and profile.type or "") == "backed_chair"
end

local function selectedObjectCollisionTopIsStable(mode, physicsObject, selectedZ)
    if not (physicsObject and selectedZ) then return false end
    local text = tostring(mode or "")
    if text ~= "sampled_sitting_surface_top" and text ~= "sampled_sitting_surface_backed_chair_lower_band" then
        return false
    end
    if (physicsObject.count or 0) < 4 or (physicsObject.topCount or 0) < 4 then return false end
    if physicsObject.span and physicsObject.span > 16 then return false end
    if not physicsObject.topZ then return false end
    return math.abs((physicsObject.topZ or 0) - (selectedZ or 0)) <= 4
end

local function renderTopLooksLikeBackOrArm(renderObject, selectedZ)
    if not (renderObject and selectedZ and renderObject.topZ and renderObject.minZ) then return false end
    local rise = (renderObject.topZ or 0) - (selectedZ or 0)
    if rise < 22 or rise > 46 then return false end
    if (renderObject.topCount or 0) > 1 then return false end
    if (renderObject.count or 0) < 4 then return false end
    if math.abs((renderObject.minZ or 0) - (selectedZ or 0)) > 8 then return false end
    return true
end

function summaryCandidateZ(s, selectedZ)
    if not s then return nil end
    local candidates = {}
    if s.extentsCenter and s.extentsCenter.z then candidates[#candidates + 1] = s.extentsCenter.z end
    if s.bandZ then candidates[#candidates + 1] = s.bandZ end
    if s.topZ then candidates[#candidates + 1] = s.topZ end
    if #candidates == 0 then return nil end
    if not selectedZ then return candidates[1] end

    local best = candidates[1]
    local bestDelta = math.abs(best - selectedZ)
    for i = 2, #candidates do
        local delta = math.abs(candidates[i] - selectedZ)
        if delta < bestDelta then
            best = candidates[i]
            bestDelta = delta
        end
    end
    return best
end

function M.request(env, data)
    env = env or {}
    data = data or {}
    local obj = data.object
    local profile = data.profile
    if not (env.nearby and env.util and env.async and obj and obj.position) then return end
    if not (env.nearby.castRay and env.nearby.asyncCastRenderingRay and env.async.callback) then
        print("[SitDownPlease Calibration Export]", "SURFACE_PROBE_UNAVAILABLE", "reason", "missing_rendering_ray_api")
        return
    end

    local kind = data.kind == "sleeping" and "sleeping" or "sitting"
    local offsets, fromZ, toZ
    if kind == "sleeping" then
        offsets, fromZ, toZ = sleepingOffsets(profile)
    else
        offsets, fromZ, toZ = sittingOffsets(profile)
    end
    local physicsObjectEntries, physicsAnyEntries = castPhysics(env, obj, offsets, fromZ, toZ)
    local renderObjectEntries, renderAnyEntries = {}, {}
    local pending = #offsets
    if pending == 0 then return end

    local options = env.actor and { ignore = env.actor } or nil
    local sequence = data.sequence
    local selectedSurface = data.selectedSurface

    local function finish()
        if pending > 0 then return end

        local physicsObject = summary(env, physicsObjectEntries, obj, profile, kind)
        local physicsAny = summary(env, physicsAnyEntries, obj, profile, kind)
        local renderObject = summary(env, renderObjectEntries, obj, profile, kind)
        local renderAny = summary(env, renderAnyEntries, obj, profile, kind)
        local selectedZ = selectedSurface and selectedSurface.z or nil
        local anySurfaceSelected = selectedModeUsesAnySurface(data.surfaceMode)
        local compareRenderZ = anySurfaceSelected and summaryCandidateZ(renderAny, selectedZ) or summaryCandidateZ(renderObject, selectedZ)
        local comparePhysicsZ = selectedZ or (anySurfaceSelected and summaryCandidateZ(physicsAny, compareRenderZ) or summaryCandidateZ(physicsObject, compareRenderZ))
        local deltaZ = compareRenderZ and comparePhysicsZ and (compareRenderZ - comparePhysicsZ) or nil
        local warningTolerance = anySurfaceSelected and 32 or 12
        local warning = deltaZ and math.abs(deltaZ) >= warningTolerance
        local selectedMinusObjectZ = anySurfaceSelected and selectedMinusObjectSurfaceZ(physicsObject, selectedZ) or nil
        local objectGapWarning = selectedMinusObjectZ and selectedMinusObjectZ >= 90
        local stableBackedChairCollisionAnchor = kind == "sitting"
            and isBackedChair(profile)
            and selectedObjectCollisionTopIsStable(data.surfaceMode, physicsObject, selectedZ)
            and renderTopLooksLikeBackOrArm(renderObject, selectedZ)
        local warningLabel = "none"
        if stableBackedChairCollisionAnchor then
            warning = false
            warningLabel = "stable_collision_anchor_visual_back_gap"
        elseif warning then
            warningLabel = "collision_visual_mismatch_possible"
        elseif objectGapWarning then
            warningLabel = "mesh_collision_anchor_gap_possible"
        end

        print("[SitDownPlease Calibration Export]", "SURFACE_PROBE",
            "export_sequence", tostring(sequence),
            "kind", tostring(kind),
            "object", labelObject(env, obj),
            "profile", tostring(profile and profile.profileId),
            "mode", tostring(data.surfaceMode),
            "samples", tostring(data.surfaceSamples),
            "selectedSurface", vectorLabel(selectedSurface),
            "renderMinusSelectedZ", deltaZ and cleanNumber(deltaZ) or "nil",
            "selectedMinusObjectZ", selectedMinusObjectZ and cleanNumber(selectedMinusObjectZ) or "nil",
            "basis", anySurfaceSelected and "any_surface" or "object_surface",
            "warningTolerance", cleanNumber(warningTolerance),
            "warning", warningLabel
        )
        printSummary("SURFACE_PROBE_PHYSICS_OBJECT", physicsObject)
        printSummary("SURFACE_PROBE_PHYSICS_ANY", physicsAny)
        printSummary("SURFACE_PROBE_RENDER_OBJECT", renderObject)
        printSummary("SURFACE_PROBE_RENDER_ANY", renderAny)

        if warning then
            print("[SitDownPlease Calibration Export]", "SURFACE_PROBE_PROMOTION_NOTE",
                "export_sequence", tostring(sequence),
                "note", "Large rendering-vs-physics Z delta; review as collision/visible-mesh sampler evidence before promoting broad profile rows."
            )
        elseif objectGapWarning then
            print("[SitDownPlease Calibration Export]", "SURFACE_PROBE_PROMOTION_NOTE",
                "export_sequence", tostring(sequence),
                "note", "Selected high any-surface is far above object-owned collision; review as mesh collision override or sampler-policy evidence before promoting profile or normalization rows."
            )
        end
    end

    for _, offset in ipairs(offsets) do
        local base = objectLocalOffset(env, obj, offset)
        if base then
            local from = base + env.util.vector3(0, 0, fromZ)
            local to = base - env.util.vector3(0, 0, toZ)
            local ok = pcall(function()
                env.nearby.asyncCastRenderingRay(env.async:callback(function(result)
                    pending = pending - 1
                    if result and result.hit and result.hitPos then
                        local entry = { offset = offset, hitPos = result.hitPos, hitObject = result.hitObject }
                        renderAnyEntries[#renderAnyEntries + 1] = entry
                        if rayHitBelongsToObject(env, result.hitObject, obj) then
                            renderObjectEntries[#renderObjectEntries + 1] = entry
                        end
                    end
                    finish()
                end), from, to, options)
            end)
            if not ok then
                pending = pending - 1
                finish()
            end
        else
            pending = pending - 1
            finish()
        end
    end
end

return M
