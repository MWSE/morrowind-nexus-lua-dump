-- interactions/sleeping/anchorResolver.lua
---@omw-context local
-- Resolves the stable placement anchor for sleep. The important rule is that
-- sampled surface Z is useful, but sampled XY from "any"/fallback hits can be
-- contaminated by nearby floors, canopy/collision, clutter, or adjacent beds.
-- In those weak cases, keep the sampled Z but pin XY back to the selected bed
-- object so profiles/slots/normalization stop fighting cell-specific samples.
local util = require('openmw.util')

local M = {}

local function lower(value)
    return string.lower(tostring(value or ""))
end

function M.needsStableXY(surfaceMode)
    local mode = lower(surfaceMode)
    if mode == "" then return false end
    if mode:find("object_origin_xy_stabilized_from_", 1, true) == 1 then return false end
    if mode == "object_origin_xy_stabilized" then return false end
    if mode == "object_origin_xy"
        or mode == "object_origin_xy_top"
        or mode == "object_origin_xy_render_object_band"
        or mode == "object_origin_xy_any_band"
        or mode == "object_origin_xy_render_any_band" then
        return false
    end
    if mode:find("fallback", 1, true) then return true end
    if mode:find("any_sample", 1, true) then return true end
    if mode:find("render_any", 1, true) then return true end
    if mode:find("top_any_hit", 1, true)
        or mode == "surface_band_any_hit" then
        return true
    end
    return false
end

local function bedKind(profile, obj)
    local text = table.concat({
        lower(profile and profile.profileId),
        lower(profile and profile.bedType),
        lower(profile and profile.type),
        lower(obj and obj.recordId),
    }, " ")
    if text:find("bunk", 1, true) then return "bunk" end
    if text:find("canopy", 1, true) then return "canopy" end
    if text:find("hammock", 1, true) then return "hammock" end
    if text:find("bedroll", 1, true) or text:find("matressnomad", 1, true) or text:find("mattressnomad", 1, true) then return "bedroll" end
    return "bed"
end

function M.resolve(obj, rawSurfacePos, surfaceMode, profile, options)
    if not (obj and obj.position and rawSurfacePos) then
        return rawSurfacePos, surfaceMode, false, "missing_anchor_input"
    end
    if profile and profile.sleepUseSampledSurfaceXY == true then
        return rawSurfacePos, surfaceMode, false, "profile_uses_sampled_xy"
    end
    if not M.needsStableXY(surfaceMode) then
        return rawSurfacePos, surfaceMode, false, "surface_xy_trusted"
    end

    local kind = bedKind(profile, obj)
    if kind == "bunk" or kind == "canopy" then
        local z = rawSurfacePos.z or obj.position.z or 0
        local anchor = util.vector3(obj.position.x or 0, obj.position.y or 0, z)
        local mode = "object_origin_xy_stabilized_from_" .. tostring(surfaceMode or "unknown") .. "_" .. kind
        return anchor, mode, true, kind .. "_object_origin_xy"
    end
    local z = rawSurfacePos.z or obj.position.z or 0
    local anchor = util.vector3(obj.position.x or 0, obj.position.y or 0, z)
    local mode = "object_origin_xy_stabilized_from_" .. tostring(surfaceMode or "unknown")
    return anchor, mode, true, kind
end

return M
