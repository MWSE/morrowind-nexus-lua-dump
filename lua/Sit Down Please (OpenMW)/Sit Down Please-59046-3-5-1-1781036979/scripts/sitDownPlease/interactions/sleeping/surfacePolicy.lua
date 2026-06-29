-- interactions/sleeping/surfacePolicy.lua
---@omw-context none
-- Sleep-surface fallback rules shared by local bed placement and diagnostics.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

function M.anySurfaceAllowed(profile)
    if not profile then return true, nil end
    if profile.allowAnySleepSurfaceHit == false then
        return false, "profile_object_surface_only"
    end

    local bedText = lower(profile.bedType or profile.type)
    local idText = lower(profile.profileId or profile.recordId)
    if bedText:find("bunk", 1, true) or idText:find("bunk", 1, true) then
        return false, "bunk_bed_object_surface_only"
    end

    return true, nil
end

return M
