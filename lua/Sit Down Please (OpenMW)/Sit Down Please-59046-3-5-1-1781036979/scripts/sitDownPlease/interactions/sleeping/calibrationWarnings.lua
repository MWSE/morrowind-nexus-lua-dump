-- interactions/sleeping/calibrationWarnings.lua
---@omw-context none

local M = {}

local function n(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function slotFor(profile, slotName, slotKey)
    if not (profile and profile.slots) then return nil end
    local wantedName = lower(slotName)
    local wantedKey = lower(slotKey)
    for _, slot in ipairs(profile.slots) do
        if slot then
            if wantedName ~= "" and lower(slot.name) == wantedName then return slot end
            if wantedKey ~= "" and lower(slot.key) == wantedKey then return slot end
        end
    end
    return nil
end

local function expectedRootDrop(opts)
    opts = opts or {}
    local profile = opts.profile or {}
    local slot = slotFor(profile, opts.slotName, opts.slotKey) or {}
    local sleepOffset = slot.sleepOffset or profile.sleepOffset or {}
    local rootLocalOffset = slot.sleepRootLocalOffset or profile.sleepRootLocalOffset or {}
    local rootZOffset = slot.sleepRootZOffset
    if rootZOffset == nil then rootZOffset = profile.sleepRootZOffset end
    local z = n(sleepOffset.z, 0) + n(rootLocalOffset.z, 0) + n(rootZOffset, 0)
    return math.max(0, -z)
end

local function profileText(opts)
    opts = opts or {}
    local profile = opts.profile or {}
    return table.concat({
        lower(profile.profileId),
        lower(profile.bedType),
        lower(profile.type),
        lower(opts.slotName),
        lower(opts.objectId),
    }, " ")
end

local function anySurfaceAnchorAllowed(opts)
    opts = opts or {}
    local profile = opts.profile or {}
    if profile.allowAnySleepSurfaceHit == false then return false end
    if profile.allowAnySleepSurfaceAnchor == true then return true end
    local policy = lower(profile.sleepSurfaceAnchorPolicy)
    if policy == "high_any_top" or policy == "top_any_hit" or policy == "any_surface_anchor" then return true end
    local text = profileText(opts)
    return text:find("bedroll", 1, true) ~= nil
        or text:find("matressnomad", 1, true) ~= nil
        or text:find("mattressnomad", 1, true) ~= nil
        or text:find("hammock", 1, true) ~= nil
end

local function objectOriginFallbackAllowed(opts)
    opts = opts or {}
    local profile = opts.profile or {}
    if profile.allowObjectOriginFallbackSleep ~= true then return false end
    local mode = lower(opts.surfaceMode)
    if mode ~= "object_origin_fallback"
        and mode ~= "object_origin_xy_fallback"
        and mode:find("object_origin_xy_stabilized_from_object_origin_fallback", 1, true) == nil then
        return false
    end
    if profile.slots and #profile.slots > 0 then return true end
    return profileText(opts):find("bunk", 1, true) ~= nil
end

local function appendSurfaceEvidence(out, mode, opts)
    if mode:find("any_sample", 1, true)
        or mode:find("any_surface", 1, true)
        or mode:find("any_hit", 1, true)
        or mode:find("render_any", 1, true) then
        if anySurfaceAnchorAllowed(opts) then
            out = M.append(out, "sleep_surface_any_anchor_allowed")
        else
            out = M.append(out, "sleep_surface_any_anchor")
        end
        if mode:find("object_origin_xy_stabilized_from_", 1, true) then
            out = M.append(out, "sleep_surface_object_hits_missing")
        end
    end
    opts.surfaceMode = opts.surfaceMode or mode
    if mode:find("fallback", 1, true) then
        if objectOriginFallbackAllowed(opts) then
            out = M.append(out, "sleep_surface_object_origin_fallback_allowed")
        else
            out = M.append(out, "sleep_surface_untrusted")
        end
    end
    return out
end

function M.append(existing, reason)
    reason = tostring(reason or "")
    if reason == "" or reason == "nil" then return existing end
    local text = tostring(existing or "")
    if text:find(reason, 1, true) then return text end
    if text == "" or text == "nil" then return reason end
    return text .. "," .. reason
end

function M.reason(surfaceMode, calibration, finalPos, surfacePos, opts)
    local out = nil
    opts = opts or {}
    local mode = tostring(surfaceMode or ""):lower()
    if mode:find("any_sample", 1, true)
        or mode:find("any_surface", 1, true)
        or mode:find("any_hit", 1, true)
        or mode:find("render_any", 1, true) then
        local allowedAnyAnchor = anySurfaceAnchorAllowed(opts)
        if not allowedAnyAnchor then
            out = M.append(out, "sleep_surface_any_anchor")
        end
        if mode:find("object_origin_xy_stabilized_from_", 1, true) then
            out = M.append(out, "sleep_surface_object_hits_missing")
        end
    end
    opts.surfaceMode = surfaceMode
    if mode:find("fallback", 1, true) then
        if objectOriginFallbackAllowed(opts) then
            out = M.append(out, "sleep_surface_object_origin_fallback_allowed")
        else
            out = M.append(out, "sleep_surface_untrusted")
        end
    end

    calibration = calibration or {}
    local x = n(calibration.x, 0)
    local y = n(calibration.y, 0)
    local z = n(calibration.z, 0)
    if z <= -75 then out = M.append(out, "sleep_calibration_large_negative_z") end
    if math.sqrt(x * x + y * y + z * z) >= 140 then out = M.append(out, "sleep_calibration_large_offset") end
    local rootDropLimit = math.max(75, expectedRootDrop(opts) + 75)
    if finalPos and surfacePos and finalPos.z and surfacePos.z and n(finalPos.z, 0) - n(surfacePos.z, 0) <= -rootDropLimit then
        out = M.append(out, "sleep_calibration_large_negative_z")
    end
    return out
end

function M.evidenceReason(surfaceMode, opts)
    opts = opts or {}
    opts.surfaceMode = surfaceMode
    return appendSurfaceEvidence(nil, tostring(surfaceMode or ""):lower(), opts)
end

return M
