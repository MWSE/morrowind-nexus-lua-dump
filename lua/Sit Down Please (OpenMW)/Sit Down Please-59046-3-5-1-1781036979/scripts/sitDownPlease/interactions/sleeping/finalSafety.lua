-- interactions/sleeping/finalSafety.lua
---@omw-context runtime
-- Final sleep-transform guard. The universal release trust gate lives in
-- assignment/releaseSafetyGate.lua; this module only evaluates bed final
-- transforms. Debug/manual/fill paths may override placement failures for
-- calibration evidence while still carrying the failed reason in metadata.

local util = require('openmw.util')

local scaleContext = require('scripts/sitDownPlease/world/scaleContext')

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function n(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function horizontalDistance(a, b)
    if not (a and b) then return nil end
    local dx = n(a.x, 0) - n(b.x, 0)
    local dy = n(a.y, 0) - n(b.y, 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function verticalDelta(a, b)
    if not (a and b) then return nil end
    return n(a.z, 0) - n(b.z, 0)
end

local function vector3(x, y, z)
    if util and util.vector3 then return util.vector3(x, y, z) end
    return { x = x, y = y, z = z }
end

local function offsetXYMagnitude(offset)
    if not offset then return 0 end
    local x = n(offset.x, 0)
    local y = n(offset.y, 0)
    return math.sqrt(x * x + y * y)
end

local function maxSlotXY(profile)
    local maxValue = offsetXYMagnitude(profile and profile.sleepRootLocalOffset)
    if profile and profile.slots then
        for _, slot in ipairs(profile.slots) do
            maxValue = math.max(maxValue, offsetXYMagnitude(slot and slot.sleepRootLocalOffset))
        end
    end
    return maxValue
end

local function profileText(profile, slotName, objectId)
    return table.concat({
        lower(profile and profile.profileId),
        lower(profile and profile.bedType),
        lower(profile and profile.type),
        lower(slotName),
        lower(objectId),
    }, " ")
end

local function isBunk(profile, slotName, objectId)
    local t = profileText(profile, slotName, objectId)
    return t:find("bunk", 1, true) ~= nil
        or t:find("sleep_top", 1, true) ~= nil
        or t:find("sleep_bottom", 1, true) ~= nil
end

local function isDouble(profile, slotName, objectId)
    local t = profileText(profile, slotName, objectId)
    return t:find("double", 1, true) ~= nil
        or t:find("sleep_a", 1, true) ~= nil
        or t:find("sleep_b", 1, true) ~= nil
        or t:find("sleep_left", 1, true) ~= nil
        or t:find("sleep_right", 1, true) ~= nil
end

local function isBedroll(profile, slotName, objectId)
    local t = profileText(profile, slotName, objectId)
    return t:find("bedroll", 1, true) ~= nil
        or t:find("matressnomad", 1, true) ~= nil
        or t:find("mattressnomad", 1, true) ~= nil
end

local function isHammock(profile, slotName, objectId)
    return profileText(profile, slotName, objectId):find("hammock", 1, true) ~= nil
end

local function isCanopy(profile, slotName, objectId)
    local t = profileText(profile, slotName, objectId)
    return t:find("canopy", 1, true) ~= nil
        or t:find("canop", 1, true) ~= nil
end

local function horizontalLimit(profile, slotName, objectId)
    local explicit = tonumber(profile and profile.sleepFinalMaxHorizontalFromSurface)
    if explicit then return explicit end
    if isDouble(profile, slotName, objectId) then return 380 end
    if isBunk(profile, slotName, objectId) then return 380 end
    if isHammock(profile, slotName, objectId) then return 360 end
    if isBedroll(profile, slotName, objectId) then return 280 end
    return math.max(320, maxSlotXY(profile) + 180)
end

local expectedRootDrop

local function belowSurfaceLimit(profile, slotName, slotKey, objectId)
    local explicit = tonumber(profile and profile.sleepFinalMaxBelowSurfaceZ)
    if explicit then return explicit end
    local expectedDrop = expectedRootDrop(profile, slotName, slotKey)
    if isBunk(profile, slotName, objectId) then return math.max(380, expectedDrop + 70) end
    if isHammock(profile, slotName, objectId) then return math.max(340, expectedDrop + 85) end
    if isBedroll(profile, slotName, objectId) then return math.max(260, expectedDrop + 70) end
    return 310
end

local function belowObjectLimit(profile, slotName, objectId)
    local explicit = tonumber(profile and profile.sleepFinalMaxBelowObjectZ)
    if explicit then return explicit end
    if isBunk(profile, slotName, objectId) then return 380 end
    if isHammock(profile, slotName, objectId) then return 340 end
    if isBedroll(profile, slotName, objectId) then return 280 end
    return 330
end

local function debugContext(data, opts)
    data = data or {}
    opts = opts or {}
    return data.calibrationAction == true
        or data.calibrationFill == true
        or data.explicitFillOverride == true
        or data.manualAssignOverrideTesting == true
        or data.manualAssignOverrideApplied == true
        or data.manualAssign == true
        or data.manualSleepEntryOverride == true
        or data.debugForced == true
        or opts.calibrationAction == true
        or opts.calibrationFill == true
        or opts.explicitFillOverride == true
        or opts.manualAssignOverrideTesting == true
        or opts.manualAssignOverrideApplied == true
        or opts.manualAssign == true
        or opts.manualSleepEntryOverride == true
        or opts.debugForced == true
end

function M.isInsideFurnitureReason(reason)
    reason = tostring(reason or "")
    return reason == "sleep_body_inside_bed" or reason == "bed_surface_submerged"
end

function M.overrideReasonFor(reason)
    if M.isInsideFurnitureReason(reason) then return "debug_override_bed_inside_furniture" end
    return tostring(reason or "sleep_final_position_invalid")
end

local function fail(opts, reason, delta, limit, hard)
    local debug = debugContext(opts and opts.data, opts)
    return false, reason, delta, limit, { hard = hard == true and not debug, baseHard = hard == true, debugOverrideAvailable = debug == true }
end

function M.weakSurfaceMode(surfaceMode)
    local mode = lower(surfaceMode)
    if mode == "" then return true end
    -- This mode is generated after the anchor solver pins XY back to the bed
    -- object while keeping the best available sampled Z. Treat it as stable
    -- enough for normal gameplay; the remaining bounds checks still apply.
    if mode:find("object_origin_xy_stabilized_from_", 1, true) == 1 then return false end
    if mode == "object_origin_xy" or mode == "object_origin_xy_top" or mode == "object_origin_xy_render_object_band" then return false end
    if mode:find("fallback", 1, true) then return true end
    if mode == "object_center" then return true end
    if mode:find("any_sample", 1, true) then return true end
    if mode:find("any_hit", 1, true) then return true end
    if mode:find("render_any", 1, true) then return true end
    if mode:find("surface_band_any", 1, true) then return true end
    return false
end

local function profileAllowsObjectOriginFallback(profile, surfaceMode, slotName, objectId)
    if not (profile and profile.allowObjectOriginFallbackSleep == true) then return false end
    local mode = lower(surfaceMode)
    if mode ~= "object_origin_fallback" and mode ~= "object_origin_xy_fallback" then return false end
    -- Only explicit-slot beds should be allowed to use this. The normal hard
    -- bounds below still reject below-floor, below-object, and far-from-bed
    -- results, but this keeps visually approved object-only bunks usable in
    -- normal play when OpenMW cannot give us a useful owned surface sample.
    if profile.slots and #profile.slots > 0 then return true end
    return isBunk(profile, slotName, objectId)
end

local function anySurfaceAnchorMode(surfaceMode)
    local mode = lower(surfaceMode)
    return mode:find("object_origin_xy_stabilized_from_any_sample", 1, true) ~= nil
        or mode:find("object_origin_xy_stabilized_from_any_surface", 1, true) ~= nil
        or mode:find("object_origin_xy_stabilized_from_any_hit", 1, true) ~= nil
        or mode:find("object_origin_xy_stabilized_from_render_any", 1, true) ~= nil
        or mode:find("object_origin_xy_stabilized_from_top_any_hit", 1, true) ~= nil
        or mode:find("top_any_hit", 1, true) ~= nil
end

local function unrepairedLowObjectSurfaceMode(surfaceMode)
    return lower(surfaceMode):find("low_unrepaired", 1, true) ~= nil
end

local function explicitAnySurfaceAnchorAllowed(profile)
    if profile and profile.allowAnySleepSurfaceAnchor == true then return true end
    local policy = lower(profile and profile.sleepSurfaceAnchorPolicy)
    return policy == "high_any_top"
        or policy == "top_any_hit"
        or policy == "any_surface_anchor"
end

local function hasObjectScopedSleepVariant(profile, slotName)
    if not profile then return false end
    local orientation = profile.orientationVariant
    if orientation and orientation.objectPosition then return true end
    local wanted = lower(slotName)
    for _, slot in ipairs(profile.slots or {}) do
        if slot and slot.orientationVariant and slot.orientationVariant.objectPosition then
            local slotLabel = lower(slot.name or slot.slotName or slot.key)
            if wanted == "" or slotLabel == "" or wanted == slotLabel then return true end
        end
    end
    return false
end

local function anySurfaceAnchorAllowed(profile, slotName, objectId)
    if profile and profile.allowAnySleepSurfaceHit == false then return false end
    if explicitAnySurfaceAnchorAllowed(profile) then return true end
    if hasObjectScopedSleepVariant(profile, slotName) then return true end
    return isBedroll(profile, slotName, objectId) or isHammock(profile, slotName, objectId)
end

local function initialActorAlreadyAtFinal(actorPos, finalPos)
    local horizontal = horizontalDistance(actorPos, finalPos)
    local vertical = math.abs(verticalDelta(actorPos, finalPos) or math.huge)
    return horizontal ~= nil and horizontal <= 80 and vertical <= 120
end

local function initialActorNearObject(actorPos, objectPos, finalPos)
    local objectHorizontal = horizontalDistance(actorPos, objectPos)
    local objectVertical = math.abs(verticalDelta(actorPos, objectPos) or math.huge)
    if objectHorizontal ~= nil and objectHorizontal <= 240 and objectVertical <= 170 then return true end

    local finalHorizontal = horizontalDistance(actorPos, finalPos)
    return finalHorizontal ~= nil and finalHorizontal <= 240 and objectVertical <= 220
end

function M.isHardReject(reason)
    reason = tostring(reason or "")
    return reason == "sleep_missing_final_position"
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

function expectedRootDrop(profile, slotName, slotKey)
    profile = profile or {}
    local slot = slotFor(profile, slotName, slotKey) or {}
    local sleepOffset = slot.sleepOffset or profile.sleepOffset or {}
    local rootLocalOffset = slot.sleepRootLocalOffset or profile.sleepRootLocalOffset or {}
    local rootZOffset = slot.sleepRootZOffset
    if rootZOffset == nil then rootZOffset = profile.sleepRootZOffset end
    local z = n(sleepOffset.z, 0) + n(rootLocalOffset.z, 0) + n(rootZOffset, 0)
    return math.max(0, -z)
end

local function insideBedLimit(profile, slotName, slotKey, objectId)
    local explicit = tonumber(profile and profile.sleepFinalInsideBedLimitZ)
    if explicit then return explicit end
    local expectedDrop = expectedRootDrop(profile, slotName, slotKey)
    if isHammock(profile, slotName, objectId) then return math.max(430, expectedDrop + 190) end
    if isBedroll(profile, slotName, objectId) then return math.max(360, expectedDrop + 150) end
    if isBunk(profile, slotName, objectId) then return math.max(330, expectedDrop + 135) end
    return math.max(255, expectedDrop + 85)
end

local function anySurfaceAnchorBelowLimit(profile, slotName, slotKey, objectId)
    local explicit = tonumber(profile and profile.sleepFinalMaxBelowAnySurfaceAnchorZ)
    if explicit then return explicit end
    local expectedDrop = expectedRootDrop(profile, slotName, slotKey)
    if isHammock(profile, slotName, objectId) then return math.max(300, expectedDrop + 70) end
    if isBedroll(profile, slotName, objectId) then return math.max(210, expectedDrop + 55) end
    if isBunk(profile, slotName, objectId) then return math.max(220, expectedDrop + 70) end
    return math.max(70, expectedDrop + 70)
end

local function anySurfaceAnchorAboveLimit(profile, slotName, objectId)
    local explicit = tonumber(profile and profile.sleepFinalMaxAboveAnySurfaceAnchorZ)
    if explicit then return explicit end
    if isHammock(profile, slotName, objectId) or isBedroll(profile, slotName, objectId) then return 130 end
    if isBunk(profile, slotName, objectId) then return 130 end
    return 80
end

local function submergedSurfaceLimit(profile, slotName, objectId)
    local explicit = tonumber(profile and profile.sleepSurfaceSubmergedLimitZ)
    if explicit then return explicit end
    if isBunk(profile, slotName, objectId)
        or isCanopy(profile, slotName, objectId)
        or isHammock(profile, slotName, objectId)
        or isBedroll(profile, slotName, objectId) then
        return nil
    end
    return 70
end

local function unpackArgs(opts)
    opts = opts or {}
    local data = opts.data or {}
    return opts, data,
        opts.profile or data.profile or {},
        opts.object or data.object,
        opts.objectId or data.objectId or (opts.object or data.object) and ((opts.object or data.object).recordId or (opts.object or data.object).id),
        opts.finalPosition or opts.finalPos,
        opts.approachPosition or opts.approachPos or data.approachPos or data.exitPosition,
        opts.surfacePosition or opts.bedTop or data.sleepBedTop or data.sleepSurfacePosition or data.bedTop or data.hitPos,
        opts.surfaceTopPosition or opts.bedObjectTop or data.sleepSurfaceTopPosition or data.sleepObjectTopPosition or data.bedObjectTop,
        opts.floorPos or data.sleepFloorPosition,
        opts.actor or opts.npc or data.npc,
        opts.slotName or data.slotName,
        opts.slotKey or data.slotKey,
        opts.surfaceMode or data.sleepSurfaceMode or data.surfaceMode,
        tonumber(opts.surfaceSamples or data.sleepSurfaceSamples or data.surfaceSamples or 0) or 0
end

function M.validate(opts)
    local _, data, profile, object, objectId, finalPos, approachPos, surfacePos, surfaceTopPos, floorPos, actor, slotName, slotKey, surfaceMode, surfaceSamples = unpackArgs(opts)
    if data.interactionType ~= nil and data.interactionType ~= "sleeping" then return true, "not_sleep" end
    if not (finalPos and finalPos.x ~= nil and finalPos.y ~= nil and finalPos.z ~= nil) then
        return false, "sleep_missing_final_position", nil, nil, { hard = true }
    end

    local objectPos = (opts and (opts.objectPosition or opts.objectPos)) or (object and object.position)
    local actorPos = (opts and (opts.actorPosition or opts.actorPos)) or (actor and actor.position)
    local fallbackUsed = (opts and opts.fallbackUsed == true) or data.fallbackUsed == true or profile.isFallback == true
    local serviceActor = (opts and opts.serviceActor == true) or data.offHoursServiceNpc == true or data.serviceActor == true
    local initialPlacement = (opts and opts.initialPlacement == true) or data.initialPlacement == true
    local reachedValidApproach = (opts and opts.reachedValidSleepApproach == true) or data.reachedValidSleepApproach == true or lower(opts and opts.trigger) == "reached_approach"
    local objectLimitScale = scaleContext.clamp(scaleContext.objectScale(object), 0.5, 2.0)
    local actorLimitScale = scaleContext.clearanceActorScale(actor)
    local mixedLimitScale = math.max(objectLimitScale, actorLimitScale)

    if isBunk(profile, slotName, objectId) then
        local slot = lower(slotName)
        if not (slot:find("sleep_top", 1, true) or slot:find("sleep_bottom", 1, true)) then
            return fail(opts, "sleep_bunk_slot_untrusted", tostring(slotName), "sleep_top_or_sleep_bottom", false)
        end
        if initialPlacement
            and surfaceSamples <= 0
            and lower(surfaceMode):find("fallback", 1, true)
            and not initialActorAlreadyAtFinal(actorPos, finalPos)
            and not initialActorNearObject(actorPos, objectPos, finalPos)
        then
            return fail(opts, "initial_sleep_surface_not_ready", tostring(surfaceMode or "nil"), surfaceSamples, false)
        end
    end

    local anySurfaceAnchor = anySurfaceAnchorMode(surfaceMode)
    if unrepairedLowObjectSurfaceMode(surfaceMode) then
        return fail(opts, "sleep_surface_low_object_unrepaired", tostring(surfaceMode or "nil"), surfaceSamples, false)
    end

    if anySurfaceAnchor and not debugContext(data, opts) and not anySurfaceAnchorAllowed(profile, slotName, objectId) then
        return fail(opts, "sleep_surface_any_anchor", tostring(surfaceMode or "nil"), surfaceSamples, false)
    end

    if M.weakSurfaceMode(surfaceMode) and not profileAllowsObjectOriginFallback(profile, surfaceMode, slotName, objectId) then
        if fallbackUsed or surfaceSamples <= 0 then
            return fail(opts, "sleep_surface_untrusted", tostring(surfaceMode or "nil"), surfaceSamples, false)
        end
        if serviceActor then
            return fail(opts, "sleep_service_actor_fallback_rejected", tostring(surfaceMode or "nil"), surfaceSamples, false)
        end
    end

    if surfacePos then
        local hd = horizontalDistance(finalPos, surfacePos)
        local hLimit = horizontalLimit(profile, slotName, objectId) * objectLimitScale
        if hd and hd > hLimit then return fail(opts, "sleep_position_too_far_from_surface", hd, hLimit, true) end
        local dz = verticalDelta(finalPos, surfacePos)
        if anySurfaceAnchor and not debugContext(data, opts) then
            local anchorBelowLimit = anySurfaceAnchorBelowLimit(profile, slotName, slotKey, objectId) * mixedLimitScale
            if dz and dz < -anchorBelowLimit then
                return fail(opts, "sleep_position_below_sampled_surface", dz, -anchorBelowLimit, true)
            end
            local anchorAboveLimit = anySurfaceAnchorAboveLimit(profile, slotName, objectId) * mixedLimitScale
            if dz and dz > anchorAboveLimit then
                return fail(opts, "sleep_position_above_sampled_surface", dz, anchorAboveLimit, true)
            end
        end
        local insideLimit = insideBedLimit(profile, slotName, slotKey, objectId) * mixedLimitScale
        if dz and dz < -insideLimit then return fail(opts, "sleep_body_inside_bed", dz, -insideLimit, true) end
        local aboveLimit = n(profile.sleepFinalMaxAboveSurfaceZ, 115) * mixedLimitScale
        if dz and dz > aboveLimit then return fail(opts, "sleep_position_above_sampled_surface", dz, aboveLimit, true) end
        local belowLimit = belowSurfaceLimit(profile, slotName, slotKey, objectId) * objectLimitScale
        if dz and dz < -belowLimit then return fail(opts, "sleep_position_below_sampled_surface", dz, -belowLimit, true) end
    end

    if surfacePos and surfaceTopPos then
        local submergedLimit = submergedSurfaceLimit(profile, slotName, objectId)
        local surfaceDz = submergedLimit and verticalDelta(surfacePos, surfaceTopPos) or nil
        if surfaceDz and surfaceDz < -submergedLimit then
            local finalDz = verticalDelta(finalPos, surfaceTopPos)
            local finalLimit = (insideBedLimit(profile, slotName, slotKey, objectId) - 20) * mixedLimitScale
            if finalDz and finalDz < -finalLimit then
                return fail(opts, "bed_surface_submerged", surfaceDz, -submergedLimit, true)
            end
        end
    end

    if objectPos then
        local hd = horizontalDistance(finalPos, objectPos)
        local hLimit = n(profile.sleepFinalMaxObjectHorizontal, horizontalLimit(profile, slotName, objectId) + 100) * objectLimitScale
        if hd and hd > hLimit then return fail(opts, "sleep_position_too_far_from_bed", hd, hLimit, true) end
        local dz = verticalDelta(finalPos, objectPos)
        local aboveLimit = n(profile.sleepFinalMaxAboveObjectZ, 290) * objectLimitScale
        if dz and dz > aboveLimit then return fail(opts, "sleep_position_above_bed_object", dz, aboveLimit, true) end
        local belowLimit = belowObjectLimit(profile, slotName, objectId) * objectLimitScale
        if dz and dz < -belowLimit then return fail(opts, "sleep_position_below_bed_object", dz, -belowLimit, true) end
    end

    if approachPos then
        local dz = verticalDelta(finalPos, approachPos)
        local aboveLimit = n(profile.sleepFinalMaxAboveApproachZ, isBunk(profile, slotName, objectId) and 240 or 180) * mixedLimitScale
        if dz and dz > aboveLimit then return fail(opts, "sleep_position_above_approach", dz, aboveLimit, true) end
        local belowLimit = n(profile.sleepFinalMaxBelowApproachZ, isBunk(profile, slotName, objectId) and 440 or 360) * mixedLimitScale
        if dz and dz < -belowLimit then return fail(opts, "sleep_position_below_approach", dz, -belowLimit, true) end
    end

    if floorPos then
        local dz = verticalDelta(finalPos, floorPos)
        local limit = n(profile.sleepFinalMaxBelowFloorZ, isBunk(profile, slotName, objectId) and 65 or 45) * actorLimitScale
        local approachDz = approachPos and verticalDelta(finalPos, approachPos) or nil
        local reachedApproachFloorOk = approachDz and approachDz >= -limit
        if dz and dz < -limit and not reachedApproachFloorOk then
            return fail(opts, "sleep_position_below_floor", dz, -limit, true)
        end
    end

    if actorPos and not initialPlacement and not reachedValidApproach then
        local dz = verticalDelta(finalPos, actorPos)
        local aboveLimit = n(profile.sleepFinalMaxAboveActorZ, 250) * actorLimitScale
        if dz and dz > aboveLimit then return fail(opts, "sleep_position_above_actor", dz, aboveLimit, true) end
        local belowLimit = n(profile.sleepFinalMaxBelowActorZ, 380) * actorLimitScale
        if dz and dz < -belowLimit then return fail(opts, "sleep_position_below_actor", dz, -belowLimit, true) end
    end

    return true, "ok", nil, nil, { hard = false }
end

local function copyWith(pos, x, y, z)
    return vector3(x ~= nil and x or pos.x, y ~= nil and y or pos.y, z ~= nil and z or pos.z)
end

local function repairHorizontal(finalPos, anchor, limit)
    local distance = horizontalDistance(finalPos, anchor)
    if not (distance and limit and distance > limit and distance <= limit + 180 and distance > 0.01) then return nil end
    local targetDistance = math.max(0, limit - 8)
    local scale = targetDistance / distance
    return copyWith(finalPos,
        n(anchor.x, 0) + (n(finalPos.x, 0) - n(anchor.x, 0)) * scale,
        n(anchor.y, 0) + (n(finalPos.y, 0) - n(anchor.y, 0)) * scale,
        n(finalPos.z, 0)
    )
end

local function repairVertical(finalPos, anchor, minZ, maxZ)
    local currentZ = n(finalPos.z, 0)
    local targetZ = nil
    if maxZ and currentZ > maxZ and currentZ - maxZ <= 160 then
        targetZ = maxZ
    elseif minZ and currentZ < minZ and minZ - currentZ <= 160 then
        targetZ = minZ
    end
    if targetZ == nil then return nil end
    return copyWith(finalPos, n(finalPos.x, 0), n(finalPos.y, 0), targetZ)
end

function M.repair(opts)
    opts = opts or {}
    if debugContext(opts.data, opts) then return nil end
    local sane, reason, delta, limit = M.validate(opts)
    if sane == true then return nil end

    local _, data, profile, object, objectId, finalPos, approachPos, surfacePos, _, floorPos, _, slotName, slotKey = unpackArgs(opts)
    if not finalPos then return nil end
    local objectPos = opts.objectPosition or opts.objectPos or (object and object.position)
    local repaired = nil

    if reason == "sleep_position_too_far_from_surface" and surfacePos then
        repaired = repairHorizontal(finalPos, surfacePos, limit)
    elseif reason == "sleep_position_too_far_from_bed" and objectPos then
        repaired = repairHorizontal(finalPos, objectPos, limit)
    elseif reason == "sleep_position_above_sampled_surface" and surfacePos then
        repaired = repairVertical(finalPos, surfacePos, nil, n(surfacePos.z, 0) + (limit or 115) - 2)
    elseif reason == "sleep_position_below_sampled_surface" and surfacePos then
        repaired = repairVertical(finalPos, surfacePos, n(surfacePos.z, 0) - (limit or belowSurfaceLimit(profile, slotName, slotKey, objectId)) + 2, nil)
    elseif reason == "sleep_position_above_bed_object" and objectPos then
        repaired = repairVertical(finalPos, objectPos, nil, n(objectPos.z, 0) + (limit or 290) - 2)
    elseif reason == "sleep_position_below_bed_object" and objectPos then
        repaired = repairVertical(finalPos, objectPos, n(objectPos.z, 0) - (limit or belowObjectLimit(profile, slotName, objectId)) + 2, nil)
    elseif reason == "sleep_position_below_floor" and floorPos then
        repaired = repairVertical(finalPos, floorPos, n(floorPos.z, 0) - (limit or 45) + 2, nil)
    end

    if not repaired then return nil, reason, delta, limit end
    local repairedOpts = {}
    for k, v in pairs(opts) do repairedOpts[k] = v end
    repairedOpts.finalPosition = repaired
    repairedOpts.finalPos = repaired
    local ok = M.validate(repairedOpts)
    if ok == true then return repaired, reason, delta, limit end
    return nil, reason, delta, limit
end

function M.repairedOrOriginal(opts)
    opts = opts or {}
    local finalPos = opts.finalPosition or opts.finalPos
    local repaired, reason, delta, limit = M.repair(opts)
    if repaired then
        local data = opts.data or {}
        data.sleepSafetyRepairReason = reason
        data.sleepSafetyRepairDelta = delta
        data.sleepSafetyRepairLimit = limit
        if opts.debugLog then
            opts.debugLog(
                "sleep final safety repaired",
                "reason", tostring(reason),
                "object", tostring(opts.objectId or (opts.object and (opts.object.recordId or opts.object.id))),
                "profile", tostring(opts.profile and opts.profile.profileId),
                "slot", tostring(opts.slotName or opts.slotKey),
                "delta", tostring(delta),
                "limit", tostring(limit),
                "old", tostring(finalPos),
                "new", tostring(repaired),
                "stage", tostring(opts.stage)
            )
        end
        return repaired
    end
    return finalPos
end

function M.validateAssignment(opts)
    opts = opts or {}
    local data = opts.data
    local finalPos = opts.finalPosition
    if not (data and data.interactionType == "sleeping" and finalPos) then return true, "not_sleep" end

    local sane, reason, delta, limit, details = M.validate({
        npc = opts.npc,
        data = data,
        finalPosition = finalPos,
        object = data.object,
        approachPosition = data.approachPos or data.exitPosition,
        surfacePosition = data.sleepBedTop or data.sleepSurfacePosition or data.bedTop or data.hitPos,
        surfaceTopPosition = data.sleepObjectTopPosition or data.sleepSurfaceTopPosition,
        floorPos = data.sleepFloorPosition,
        surfaceMode = data.sleepSurfaceMode or data.surfaceMode,
        surfaceSamples = data.sleepSurfaceSamples or data.surfaceSamples,
        initialPlacement = data.initialPlacement,
        reachedValidSleepApproach = data.reachedValidSleepApproach,
        profile = data.profile,
        trigger = opts.trigger,
    })
    if sane ~= true then
        data.sleepSafetyReason = reason
        data.sleepSafetyDelta = delta
        data.sleepSafetyLimit = limit
        local canDebugOverride = debugContext(data, opts) and not M.isHardReject(reason)
        if M.isInsideFurnitureReason(reason) and not canDebugOverride then
            data.hardBlockerReason = data.hardBlockerReason or "bed_final_transform_rejected"
        end
        if canDebugOverride then
            data.sleepSafetyOverrideReason = M.overrideReasonFor(reason)
            if M.isInsideFurnitureReason(reason) then
                data.hardBlockerReason = data.sleepSafetyOverrideReason
            else
                data.hardBlockerReason = data.hardBlockerReason or data.sleepSafetyOverrideReason
            end
            if opts.debugLog then
                opts.debugLog(
                    "sleep final safety calibration debug override",
                    opts.npc and (opts.npc.recordId or opts.npc.id) or "<npc>",
                    "reason", tostring(reason),
                    "object", tostring(data.objectId),
                    "delta", tostring(delta),
                    "limit", tostring(limit),
                    "trigger", tostring(opts.trigger),
                    "normalPlayWouldBlock", "true"
                )
            end
            return true, "debug_sleep_final_safety_override", delta, limit, details
        end
    end
    return sane, reason, delta, limit, details
end

function M.checkLocal(opts)
    opts = opts or {}
    local validate = opts.validate
    if not validate then return true end
    local sane, reason, delta, limit, details = validate()
    if sane == true then return true end

    local data = opts.data or {}
    data.sleepSafetyReason = reason
    data.sleepSafetyDelta = delta
    data.sleepSafetyLimit = limit

    local hard = (details and details.hard == true) or M.isHardReject(reason)
    local canDebugOverride = debugContext(data, opts) and not M.isHardReject(reason)
    if M.isInsideFurnitureReason(reason) and not canDebugOverride then
        data.hardBlockerReason = data.hardBlockerReason or "bed_final_transform_rejected"
    end

    if opts.debugLog then
        opts.debugLog(
            "sleep final safety rejected",
            "reason", tostring(reason),
            "object", tostring(opts.object and (opts.object.recordId or opts.object.id)),
            "profile", tostring(opts.profile and opts.profile.profileId),
            "slot", tostring(opts.slotName or opts.slotKey),
            "delta", tostring(delta),
            "limit", tostring(limit),
            "stage", tostring(opts.stage),
            "hard", tostring(hard),
            "debugOverride", tostring(canDebugOverride)
        )
    end

    if canDebugOverride then
        data.sleepSafetyOverrideReason = M.overrideReasonFor(reason)
        if M.isInsideFurnitureReason(reason) then
            data.hardBlockerReason = data.sleepSafetyOverrideReason
        else
            data.hardBlockerReason = data.hardBlockerReason or data.sleepSafetyOverrideReason
        end
        if opts.noteOverride then opts.noteOverride(data.sleepSafetyOverrideReason) end
        if opts.manualBypass then
            local ok = opts.manualBypass(data.sleepSafetyOverrideReason, "sleep_final_safety")
            if ok == true then return true end
        end
        -- Developer paths are allowed to continue even if the manualBypass
        -- helper only recorded metadata. Normal gameplay never reaches this.
        return true
    end

    if hard ~= true and opts.manualBypass then
        local ok = opts.manualBypass(reason or "sleep_final_position_invalid", "sleep_final_safety")
        if ok == true then return true end
    end

    if opts.reject then opts.reject(reason or "sleep_final_position_invalid") end
    return false
end

M.evaluate = M.validate

return M
