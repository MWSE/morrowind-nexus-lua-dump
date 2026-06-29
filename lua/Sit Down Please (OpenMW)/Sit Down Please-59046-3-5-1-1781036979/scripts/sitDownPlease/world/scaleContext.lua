-- world/scaleContext.lua
---@omw-context none
-- Central runtime scale policy for SDP.
--
-- Profile offsets are authored in unscaled furniture-local units. Runtime
-- placement applies object scale exactly once when converting those offsets to
-- world space. Calibration/export normalizes world evidence back to profile
-- units and flags non-standard actor/object scale so scaled test actors do not
-- become broad profile truth.

local M = {}

local EPSILON = 0.01

local function n(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

function M.clamp(value, minValue, maxValue)
    value = n(value, 1)
    minValue = n(minValue, 0.1)
    maxValue = n(maxValue, 10)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function M.rawScale(objOrScale, fallback)
    local scale = type(objOrScale) == "number" and objOrScale or (objOrScale and objOrScale.scale)
    scale = n(scale, fallback or 1)
    if scale <= 0 then return fallback or 1 end
    return scale
end

function M.objectScale(obj)
    return M.rawScale(obj, 1)
end

function M.actorScale(actor)
    return M.rawScale(actor, 1)
end

function M.isNonStandard(scale, epsilon)
    scale = n(scale, 1)
    epsilon = n(epsilon, EPSILON)
    return math.abs(scale - 1) > epsilon
end

function M.objectScaleForPlacement(obj)
    -- Respect normal object scaling, but prevent pathological scales from
    -- exploding profile offsets.
    return M.clamp(M.objectScale(obj), 0.25, 4.0)
end

function M.objectScaleForClearance(obj)
    return M.clamp(M.objectScale(obj), 0.55, 1.75)
end

function M.actorScaleForClearance(actorOrScale)
    local value = type(actorOrScale) == "number" and actorOrScale or M.actorScale(actorOrScale)
    return M.clamp(value, 0.65, 1.6)
end

function M.clearanceActorScale(actorOrScale)
    local value = type(actorOrScale) == "number" and actorOrScale or M.actorScale(actorOrScale)
    return M.clamp(value, 0.75, 1.35)
end

function M.actorScaleForPose(actor)
    return M.clamp(M.actorScale(actor), 0.75, 1.35)
end

function M.obstructionScale(obj)
    return M.clamp(M.objectScale(obj), 0.45, 2.5)
end

function M.scaledLocalVector(util, obj, offset, opts)
    if not util then return nil end
    offset = offset or {}
    local scale = M.objectScaleForPlacement(obj)
    local z = opts and opts.horizontalOnly == true and 0 or (n(offset.z, 0))
    return util.vector3(n(offset.x, 0) * scale, n(offset.y, 0) * scale, z * scale)
end

function M.objectLocalPosition(util, obj, offset)
    if not obj then return nil end
    if not offset then return obj.position end
    return obj.position + obj.rotation * M.scaledLocalVector(util, obj, offset)
end

function M.objectLocalHorizontalVector(util, obj, offset)
    if not (util and obj and offset) then return util and util.vector3(0, 0, 0) or nil end
    return obj.rotation * M.scaledLocalVector(util, obj, offset, { horizontalOnly = true })
end

function M.worldToObjectLocal(obj, worldPos, opts)
    if not (obj and obj.position and worldPos) then return nil end
    local objectYaw = 0
    if obj.rotation and obj.rotation.getYaw then
        local ok, yaw = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(yaw) == "number" then objectYaw = yaw end
    end
    local delta = worldPos - obj.position
    local c = math.cos(-objectYaw)
    local s = math.sin(-objectYaw)
    local scale = M.objectScaleForPlacement(obj)
    if math.abs(scale) <= 0.0001 then scale = 1 end
    local z = (n(delta.z, 0)) / scale
    if opts and opts.horizontalOnly == true then z = 0 end
    return {
        x = (n(delta.x, 0) * c - n(delta.y, 0) * s) / scale,
        y = (n(delta.x, 0) * s + n(delta.y, 0) * c) / scale,
        z = z,
    }
end

function M.profileSpaceVector(worldLocal, obj)
    if not worldLocal then return nil end
    local scale = M.objectScaleForPlacement(obj)
    if math.abs(scale) <= 0.0001 then scale = 1 end
    return {
        x = n(worldLocal.x, 0) / scale,
        y = n(worldLocal.y, 0) / scale,
        z = n(worldLocal.z, 0) / scale,
        yaw = worldLocal.yaw,
    }
end

function M.scaledRadius(baseRadius, targetObj, blockerObj, opts)
    opts = opts or {}
    local targetScale = opts.ignoreTargetScale and 1 or M.objectScaleForClearance(targetObj)
    local blockerScale = opts.ignoreBlockerScale and 1 or M.obstructionScale(blockerObj)
    local radius = n(baseRadius, 0) * targetScale
    if blockerScale > 1 then
        radius = radius + (blockerScale - 1) * n(opts.largeBlockerBonus or 12, 12)
    elseif blockerScale < 1 then
        radius = radius - (1 - blockerScale) * n(opts.smallBlockerPenalty or 4, 4)
    end
    local minRadius = n(opts.minRadius, n(baseRadius, 0) * 0.65)
    local maxRadius = n(opts.maxRadius, n(baseRadius, 0) * 1.85)
    return M.clamp(radius, minRadius, maxRadius)
end

function M.scaledVerticalBand(minZ, maxZ, blockerObj, opts)
    opts = opts or {}
    local blockerScale = M.obstructionScale(blockerObj)
    local extra = 0
    if blockerScale > 1 then extra = (blockerScale - 1) * n(opts.largeBlockerZBonus or 18, 18) end
    return n(minZ, 0) - extra * 0.35, n(maxZ, 0) + extra
end

function M.actorPoseValue(actor, value, opts)
    value = n(value, 0)
    local scale = M.actorScaleForPose(actor)
    local epsilon = n(opts and opts.epsilon, 0.025)
    if math.abs(scale - 1) <= epsilon or value == 0 then return value, false, scale end
    return value * scale, true, scale
end

function M.scaleContext(actorScale, objectScale)
    actorScale = n(actorScale, 1)
    objectScale = n(objectScale, 1)
    local actorNonStandard = M.isNonStandard(actorScale)
    local objectNonStandard = M.isNonStandard(objectScale)
    if not (actorNonStandard or objectNonStandard) then
        return {
            actorScale = actorScale,
            objectScale = objectScale,
            actorNonStandard = false,
            objectNonStandard = false,
            nonStandard = false,
            hasScaleContext = false,
            notes = "",
            warning = "standard_scale",
            promoteHint = "ok_for_broad_profile_if_other_layers_agree",
        }
    end
    local parts = {}
    if actorNonStandard then parts[#parts + 1] = "actorScale=" .. tostring(actorScale) end
    if objectNonStandard then parts[#parts + 1] = "objectScale=" .. tostring(objectScale) end
    local warning = "nonstandard_scale_context:" .. table.concat(parts, ";")
    local promoteHint = objectNonStandard and "prefer_object_scoped_or_scaled_retest;do_not_promote_broad_row_from_scaled_object" or "actor_scale_evidence_only;do_not_bake_actor_scale_into_profile"
    return {
        actorScale = actorScale,
        objectScale = objectScale,
        actorNonStandard = actorNonStandard,
        objectNonStandard = objectNonStandard,
        nonStandard = true,
        hasScaleContext = true,
        notes = warning .. ";" .. promoteHint,
        warning = warning,
        promoteHint = promoteHint,
    }
end

function M.calibrationContext(actor, obj)
    return M.scaleContext(M.actorScale(actor), M.objectScale(obj))
end

function M.exportWarning(actorScale, objectScale)
    local ctx = M.scaleContext(actorScale, objectScale)
    if not ctx.nonStandard then return nil end
    return ctx.warning, ctx.promoteHint
end

function M.appendScaleNote(notes, actorScale, objectScale)
    local warning, hint = M.exportWarning(actorScale, objectScale)
    if not warning then return notes end
    notes = tostring(notes or "")
    if notes ~= "" then notes = notes .. "; " end
    return notes .. warning .. "; " .. hint
end

function M.promotionHintSuffix(actor, obj)
    local ctx = M.calibrationContext(actor, obj)
    if ctx.hasScaleContext ~= true then return nil, ctx end
    if ctx.actorNonStandard then return "scale_review_required", ctx end
    return "scale_context", ctx
end

return M
