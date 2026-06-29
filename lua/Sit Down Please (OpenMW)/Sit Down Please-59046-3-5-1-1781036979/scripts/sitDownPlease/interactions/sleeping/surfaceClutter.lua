-- interactions/sleeping/surfaceClutter.lua
---@omw-context none
-- Filters non-bed clutter out of sleep-surface fallback samples.

local clutterItems = require('scripts/sitDownPlease/world/clutterItems')
local scaleContext = require('scripts/sitDownPlease/world/scaleContext')

local M = {}

local function isSleepSurfaceBlocker(kind)
    -- Paper/books can poison sampled surface height, but they should not be a
    -- hard normal-play sleep blocker.  A note on a bed is not the same as a
    -- bottle, lantern, armor piece, or furniture sitting on the mattress.
    return kind == "hard_blocker" or kind == "soft_item_blocker"
end

local function isSleepSurfaceSampleBlocker(kind)
    return isSleepSurfaceBlocker(kind) or kind == "paper_item"
end

function M.filterEntries(entries, obj, profile, env)
    if not entries or #entries == 0 then return entries or {} end
    local rayHitBelongsToObject = env and env.rayHitBelongsToObject
    local filtered = {}
    for _, entry in ipairs(entries) do
        local hitObject = entry and entry.hitObject
        local keep = true
        local kind = nil
        if hitObject and rayHitBelongsToObject and not rayHitBelongsToObject(hitObject, obj) then
            kind = clutterItems.kind(env, hitObject)
            if isSleepSurfaceSampleBlocker(kind) then
                keep = false
            end
        end
        if keep then
            filtered[#filtered + 1] = entry
        else
            local debugLog = env and env.debugLog
            if debugLog then
                debugLog(
                    "sleep surface clutter hit ignored",
                    "object", tostring(obj and obj.recordId),
                    "profile", tostring(profile and profile.profileId),
                    "hit", tostring(hitObject and (hitObject.recordId or hitObject.id)),
                    "kind", tostring(kind),
                    "source", tostring(env and env.source or "surface_sample")
                )
            end
        end
    end
    return filtered
end

local function lists(env)
    local nearby = env and env.nearby
    local result = {}
    if not nearby then return result end
    if nearby.items then result[#result + 1] = nearby.items end
    if nearby.activators then result[#result + 1] = nearby.activators end
    return result
end

local function sleepGridBounds(profile)
    local samples = profile and profile.sleepSurfaceSampleOffsets or nil
    if not (samples and #samples > 0) then return nil end
    local minX, maxX, minY, maxY = nil, nil, nil, nil
    for _, sample in ipairs(samples) do
        local x, y = tonumber(sample.x), tonumber(sample.y)
        if x and y then
            minX = minX and math.min(minX, x) or x
            maxX = maxX and math.max(maxX, x) or x
            minY = minY and math.min(minY, y) or y
            maxY = maxY and math.max(maxY, y) or y
        end
    end
    if not (minX and maxX and minY and maxY) then return nil end
    return { minX = minX, maxX = maxX, minY = minY, maxY = maxY }
end

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function localOffsetSum(a, b)
    a = a or {}
    b = b or {}
    return {
        x = (tonumber(a.x) or 0) + (tonumber(b.x) or 0),
        y = (tonumber(a.y) or 0) + (tonumber(b.y) or 0),
        z = (tonumber(a.z) or 0) + (tonumber(b.z) or 0),
    }
end

local function slotCenterLocal(profile, slot)
    if not slot then return nil end
    return localOffsetSum(slot.sleepRootLocalOffset or profile and profile.sleepRootLocalOffset, slot.sleepOffset or profile and profile.sleepOffset)
end

local function slotScopedBounds(profile, slot)
    local slotName = lower(slot and slot.name)
    local bedText = table.concat({
        lower(profile and profile.profileId),
        lower(profile and profile.bedType),
        lower(profile and profile.type),
        slotName,
    }, " ")
    local isBunk = bedText:find("bunk", 1, true) ~= nil
        or slotName:find("top", 1, true) ~= nil
        or slotName:find("bottom", 1, true) ~= nil
    if not isBunk then return nil end
    local center = slotCenterLocal(profile, slot)
    if not center then return nil end
    local halfX = 125
    local halfY = 82
    return {
        minX = center.x - halfX,
        maxX = center.x + halfX,
        minY = center.y - halfY,
        maxY = center.y + halfY,
        minZ = center.z - 34,
        maxZ = center.z + 72,
        slotScoped = true,
    }
end

local function sleepGridBoundsFor(profile, env)
    local slotBounds = slotScopedBounds(profile, env and env.slot)
    if slotBounds then return slotBounds end
    local bounds = sleepGridBounds(profile)
    if bounds then bounds.slotScoped = false end
    return bounds
end

local function objectLocalPoint(obj, worldPos)
    return scaleContext.worldToObjectLocal(obj, worldPos)
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function objectText(env, obj)
    local profiles = env and env.profiles
    local model = profiles and profiles.objectModelPath and profiles.objectModelPath(obj) or ""
    local name = ""
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then return obj.type.record(obj) end
        return nil
    end)
    if ok and rec and rec.name then name = rec.name end
    return (tostring(obj and obj.recordId or "") .. " " .. tostring(model) .. " " .. tostring(name)):lower()
end

local function isLightLike(env, item)
    local text = objectText(env, item)
    return text:find("lantern", 1, true) ~= nil
        or text:find("lamp", 1, true) ~= nil
        or text:find("candle", 1, true) ~= nil
        or text:find("light", 1, true) ~= nil
end

local function isClearlyAboveSleepSurface(env, item, kind, dz, localPos, bounds)
    dz = tonumber(dz) or 0
    local localZ = localPos and tonumber(localPos.z) or nil
    local maxZ = bounds and tonumber(bounds.maxZ) or nil

    -- Anything this far above the sampled surface is hanging/placed overhead,
    -- not lying on the bed. This catches lanterns and high decorative armor.
    if dz > 72 then return true end

    -- Lights hang close to bed footprints often enough that they need a lower
    -- overhead threshold than general clutter.
    if isLightLike(env, item) then
        if dz > 34 then return true end
        if localZ and maxZ and localZ > maxZ + 10 then return true end
    end

    -- Non-paper soft/hard blockers still must be rejected when actually on the
    -- sleep surface, but local Z above the grid means wall/shelf/ceiling clutter.
    if localZ and maxZ and localZ > maxZ + 24 then return true end
    if kind == "paper_item" and dz > 12 then return true end
    return false
end

local function sleepSurfaceBlockerFlatLimit(profile, weakSurface)
    local bedType = tostring(profile and (profile.bedType or profile.type) or ""):lower()
    if bedType == "double" then return weakSurface and 140 or 170 end
    if bedType == "top_bunk" or bedType == "bottom_bunk" or bedType == "bunk" then return weakSurface and 90 or 112 end
    if bedType == "bedroll" or bedType == "hammock" then return weakSurface and 72 or 92 end
    return weakSurface and 94 or 120
end

local function itemWithinSleepGrid(item, obj, profile, sleepSurfacePosition, weakSurface, env)
    local bounds = sleepGridBoundsFor(profile, env)
    if not (bounds and item and item.position and obj and obj.position) then return false, nil, nil, nil, false, bounds end
    local localPos = objectLocalPoint(obj, item.position)
    if not localPos then return false, nil, nil, nil, bounds.slotScoped == true, bounds end
    local margin = weakSurface and 4 or 10
    if bounds.slotScoped == true then
        margin = math.min(margin, 6)
    end
    local xOk = localPos.x >= bounds.minX - margin and localPos.x <= bounds.maxX + margin
    local yOk = localPos.y >= bounds.minY - margin and localPos.y <= bounds.maxY + margin
    local zOk = true
    if bounds.minZ and bounds.maxZ and localPos.z then
        zOk = localPos.z >= bounds.minZ - margin and localPos.z <= bounds.maxZ + margin
    end
    local dz = (item.position.z or 0) - (sleepSurfacePosition and sleepSurfacePosition.z or obj.position.z or 0)
    local minZ, maxZ = scaleContext.scaledVerticalBand(-12, 48, item, { largeBlockerZBonus = 18 })
    local surfaceFlat = flatDistance(item.position, sleepSurfacePosition)
    local maxSurfaceFlat = sleepSurfaceBlockerFlatLimit(profile, weakSurface)
    if surfaceFlat and surfaceFlat > maxSurfaceFlat then
        return false, localPos, surfaceFlat, dz, bounds.slotScoped == true, bounds
    end
    if bounds.slotScoped == true then
        maxSurfaceFlat = weakSurface and 78 or 96
        if surfaceFlat and surfaceFlat > maxSurfaceFlat then
            return false, localPos, surfaceFlat, dz, true, bounds
        end
    end
    return xOk and yOk and zOk and dz >= minZ and dz <= maxZ, localPos, nil, dz, bounds.slotScoped == true, bounds
end

local function weakSurfaceEvidence(env)
    local mode = tostring(env and env.surfaceMode or ""):lower()
    local samples = tonumber(env and env.surfaceSamples or 0) or 0
    return samples <= 0
        or mode == ""
        or mode:find("fallback", 1, true) ~= nil
        or mode == "object_center"
        or mode:find("object_origin_fallback", 1, true) ~= nil
end

local function finalPoseRadius(profile)
    local bedType = tostring(profile and (profile.bedType or profile.type) or ""):lower()
    if bedType == "double" then return 185 end
    if bedType == "top_bunk" or bedType == "bottom_bunk" or bedType == "bunk" then return 170 end
    if bedType == "bedroll" or bedType == "hammock" then return 115 end
    return 145
end

local function itemTooFarFromFinalPose(env, item, profile)
    local finalPos = env and env.finalPosition
    if not (finalPos and item and item.position) then return false, nil end
    local flat = flatDistance(item.position, finalPos)
    local radius = finalPoseRadius(profile)
    if flat and flat > radius then return true, flat end
    return false, flat
end

function M.surfaceBlocker(env, sleepSurfacePosition, obj, profile)
    if not sleepSurfacePosition then return nil end
    local weakSurface = weakSurfaceEvidence(env)
    local bedType = tostring(profile and (profile.bedType or profile.type) or ""):lower()
    local baseRadius = 34
    if bedType == "double" then baseRadius = 46
    elseif bedType == "top_bunk" or bedType == "bottom_bunk" or bedType == "bunk" then baseRadius = 42
    elseif bedType == "bedroll" or bedType == "hammock" then baseRadius = 32 end
    for _, list in ipairs(lists(env)) do
        for _, item in ipairs(list) do
            if item ~= obj and clutterItems.objectEnabled(item) and item.position then
                local kind = clutterItems.kind(env, item)
                if isSleepSurfaceBlocker(kind) then
                    if weakSurface and kind == "soft_item_blocker" then
                        local debugLog = env and env.debugLog
                        if debugLog then
                            debugLog(
                                "sleep surface soft clutter ignored weak surface",
                                "object", tostring(obj and obj.recordId),
                                "profile", tostring(profile and profile.profileId),
                                "item", tostring(item and (item.recordId or item.id)),
                                "surfaceMode", tostring(env and env.surfaceMode),
                                "surfaceSamples", tostring(env and env.surfaceSamples)
                            )
                        end
                    else
                    local dx = (item.position.x or 0) - (sleepSurfacePosition.x or 0)
                    local dy = (item.position.y or 0) - (sleepSurfacePosition.y or 0)
                    local dz = (item.position.z or 0) - (sleepSurfacePosition.z or 0)
                    local flat = math.sqrt(dx * dx + dy * dy)
                    local inGrid, localPos, _, gridDz, slotScoped, gridBounds = itemWithinSleepGrid(item, obj, profile, sleepSurfacePosition, weakSurface, env)
                    local radius = scaleContext.scaledRadius(baseRadius, obj, item, { minRadius = baseRadius * 0.72, maxRadius = baseRadius * 1.45, largeBlockerBonus = 8 })
                    local minZ, maxZ = scaleContext.scaledVerticalBand(-6, 36, item, { largeBlockerZBonus = 10 })
                    local tooFarFromFinal, finalFlat = itemTooFarFromFinalPose(env, item, profile)
                    if isClearlyAboveSleepSurface(env, item, kind, dz, localPos, gridBounds) then
                        local debugLog = env and env.debugLog
                        if debugLog then
                            debugLog(
                                "sleep surface clutter ignored overhead item",
                                "object", tostring(obj and obj.recordId),
                                "profile", tostring(profile and profile.profileId),
                                "item", tostring(item and (item.recordId or item.id)),
                                "kind", tostring(kind),
                                "surfaceDistance", tostring(flat),
                                "vertical", tostring(dz)
                            )
                        end
                    elseif tooFarFromFinal and (weakSurface or inGrid or flat > radius) then
                        local debugLog = env and env.debugLog
                        if debugLog then
                            debugLog(
                                "sleep surface clutter ignored distant from final pose",
                                "object", tostring(obj and obj.recordId),
                                "profile", tostring(profile and profile.profileId),
                                "slot", tostring(env and env.slotName),
                                "item", tostring(item and (item.recordId or item.id)),
                                "kind", tostring(kind),
                                "surfaceMode", tostring(env and env.surfaceMode),
                                "surfaceSamples", tostring(env and env.surfaceSamples),
                                "surfaceDistance", tostring(flat),
                                "finalDistance", tostring(finalFlat)
                            )
                        end
                    elseif inGrid then
                        return item, flat, gridDz or dz, "sleep_surface_grid", kind
                    elseif slotScoped then
                        local debugLog = env and env.debugLog
                        if debugLog then
                            debugLog(
                                "sleep surface clutter ignored outside slot grid",
                                "object", tostring(obj and obj.recordId),
                                "profile", tostring(profile and profile.profileId),
                                "slot", tostring(env and env.slotName),
                                "item", tostring(item and (item.recordId or item.id)),
                                "kind", tostring(kind),
                                "local", tostring(localPos),
                                "surfaceDistance", tostring(flat),
                                "vertical", tostring(dz)
                            )
                        end
                    elseif flat <= radius and dz >= minZ and dz <= maxZ then
                        return item, flat, dz, "sleep_surface_region", kind
                    end
                    end
                end
            end
        end
    end
    return nil
end

return M
