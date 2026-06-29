-- interactions/sleeping/normalizationPolicy.lua
---@omw-context all
-- Keeps sleep animation-normalization rows from fighting exact/object-scoped
-- physical bed corrections. Normalization rows are useful when the animation
-- root is genuinely offset; they are dangerous when a later physical/object
-- profile already absorbed that visual correction.

local M = {}

local function n(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function copy(offset)
    offset = offset or {}
    return {
        x = n(offset.x, 0),
        y = n(offset.y, 0),
        z = n(offset.z, 0),
        yaw = n(offset.yaw, 0),
    }
end

local function absmaxXY(offset)
    return math.max(math.abs(n(offset and offset.x, 0)), math.abs(n(offset and offset.y, 0)))
end

local function magnitude(offset)
    local x = n(offset and offset.x, 0)
    local y = n(offset and offset.y, 0)
    local z = n(offset and offset.z, 0)
    return math.sqrt(x * x + y * y + z * z)
end

local function sourceName(profile)
    local variant = profile and profile.orientationVariant or nil
    return lower((variant and variant.sourceName) or (profile and profile.orientationVariantSourceName) or (profile and profile.sourceName) or "")
end

local function hasObjectScopedVariant(profile)
    local variant = profile and profile.orientationVariant or nil
    if variant and variant.objectPosition ~= nil then return true end
    return sourceName(profile):find("bedobjectoverrides", 1, true) ~= nil
end

local function hasExplicitPhysicalVariant(profile)
    return profile and profile.orientationVariantSource == "explicit_profile_orientation_variant"
end

local function weakSurface(surfaceMode)
    local mode = lower(surfaceMode)
    return mode == ""
        or mode:find("any_sample", 1, true) ~= nil
        or mode:find("any_hit", 1, true) ~= nil
        or mode:find("render_any", 1, true) ~= nil
        or mode:find("fallback", 1, true) ~= nil
        or mode:find("object_origin_xy_stabilized_from_", 1, true) ~= nil
end

local function isLarge(offset)
    return absmaxXY(offset) > 24
        or math.abs(n(offset and offset.z, 0)) > 32
        or math.abs(n(offset and offset.yaw, 0)) > 45
end

local function zeroed(reason, original)
    return { x = 0, y = 0, z = 0, yaw = 0 }, reason, copy(original)
end

local function keepVerticalOnly(reason, original)
    return { x = 0, y = 0, z = n(original and original.z, 0), yaw = 0 }, reason, copy(original)
end

function M.resolve(offset, context)
    offset = copy(offset)
    context = context or {}
    if magnitude(offset) < 0.0001 then return offset, nil, nil end

    local profile = context.profile
    local objectScoped = hasObjectScopedVariant(profile)
    local explicitPhysical = hasExplicitPhysicalVariant(profile)
    local surfaceMode = context.surfaceMode

    -- Object overrides are exact placed-object fixes. If a large old animation
    -- normalization row also applies, that usually means the correction is being
    -- double-applied. Keep only tiny residual normalizations in this layer.
    if objectScoped and isLarge(offset) then
        return zeroed("object_override_suppressed_large_sleep_normalization", offset)
    end

    -- Broad physical variants with weak/any surface evidence are also a danger:
    -- a big X/Y animation residual can drag the final pose away from the bed
    -- anchor and make the profile look wrong again in the next cell. Keep a
    -- modest Z-only residual when present, but drop XY/yaw.
    if explicitPhysical and weakSurface(surfaceMode) and absmaxXY(offset) > 32 then
        if math.abs(n(offset.z, 0)) <= 32 then
            return keepVerticalOnly("weak_surface_suppressed_sleep_normalization_xy", offset)
        end
        return zeroed("weak_surface_suppressed_large_sleep_normalization", offset)
    end

    return offset, nil, nil
end

return M
