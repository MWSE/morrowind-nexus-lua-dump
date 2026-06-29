-- sitting/localResolver.lua
---@omw-context none
-- Resolves local sitting placement for the NPC seeker without making the seeker
-- own sitting-specific surface, blocker, facing, and final-pose logic.

local M = {}

local TELEPORT_ROUTE_REASONS = {
    teleport_door_route_required = true,
    locked_teleport_door_route = true,
    key_unknown_teleport_door_route = true,
}

local CLEARANCE_BLOCKER_REASONS = {
    tight_table_or_counter_rejected = true,
    clearance_blocked_by_object = true,
}

local function teleportRouteReason(reason)
    return TELEPORT_ROUTE_REASONS[tostring(reason or "")] == true
end

local function clearanceBlockerReason(reason)
    return CLEARANCE_BLOCKER_REASONS[tostring(reason or "")] == true
end

local function clearAcceptedClearanceBlocker(data, debugLog, currentObject, currentSlotName)
    if not (data and clearanceBlockerReason(data.surfaceBlockerReason)) then return end
    local oldReason = data.surfaceBlockerReason
    data.surfaceBlockerReason = nil
    if clearanceBlockerReason(data.surfaceBlockerOverrideReason) then
        data.surfaceBlockerOverrideReason = nil
    end
    data.surfaceBlockerKind = nil
    data.surfaceBlockerObjectId = nil
    data.surfaceBlockerDistance = nil
    data.surfaceBlockerVertical = nil
    data.surfaceBlockerLocalReason = nil
    if data.softBlockerReason == oldReason then
        data.softBlockerReason = nil
    end
    if debugLog then
        debugLog(
            "sitting clearance accepted cleared stale blocker",
            "reason", tostring(oldReason),
            "object", tostring(currentObject and currentObject.recordId),
            "slot", tostring(currentSlotName)
        )
    end
end

local function existingActorReachabilityReason(data, routeReason)
    if data and (data.calibrationFillLabel ~= nil or data.calibrationFillSource == "borrowed") then
        return "fill_existing_actor_unreachable+" .. tostring(routeReason)
    end
    if data and data.manualAssign == true then
        return "assign_nearest_actor_unreachable+" .. tostring(routeReason)
    end
    return tostring(routeReason)
end

function M.resolve(ctx, data, profile)
    local currentObject = ctx.currentObject
    local currentSlotName = ctx.currentSlotName
    local currentAnimation = ctx.currentAnimation
    local debugLog = ctx.debugLog
    local profiles = ctx.profiles

    local sitPosition, surfaceMode, surfaceSamples = ctx.sampleSittingSurface(currentObject, profile)
    if not sitPosition then
        debugLog(
            "sitting surface validation failed",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "mode", tostring(surfaceMode),
            "samples", tostring(surfaceSamples)
        )
        if (data.explicitFillOverride == true or data.calibrationFill == true or data.manualAssignOverrideTesting == true)
            and profile
            and profile.externalProfile == true
            and currentObject
            and currentObject.position
        then
            ctx.noteManualAssignOverride(data, "collision_or_raycast_validation_failed")
            sitPosition = currentObject.position
            surfaceMode = "explicit_fill_profile_surface_override:" .. tostring(surfaceMode or "missing_surface")
            surfaceSamples = 0
            debugLog(
                "explicit fill surface validation override",
                "object", tostring(currentObject and currentObject.recordId),
                "profile", tostring(profile and profile.profileId),
                "slot", tostring(currentSlotName),
                "reason", "collision_or_raycast_validation_failed",
                "surface", tostring(surfaceMode)
            )
        else
            ctx.reject(data, "collision_or_raycast_validation_failed")
            return nil
        end
    end

    local orientation = nil

    if ctx.isBenchFurniture(currentObject, profile) then
        local length, zLevel
        orientation, length, zLevel = ctx.determineBenchOrientationAndLength(currentObject)
        local positions = ctx.getBenchSittingPositions(currentObject, orientation, length, zLevel, profile)
        local slotIndex = currentSlotName == "seat_c" and 3 or (currentSlotName == "seat_b" and 2 or 1)
        if slotIndex > #positions then
            if data.manualAssignOverrideTesting == true then
                ctx.noteManualAssignOverride(data, "bench_slot_unavailable_short_length")
                debugLog("nearest_manual_assign_override", "reason", "bench_slot_unavailable_short_length", "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "fallback", "first_available_position")
                sitPosition = positions[1] or sitPosition
            else
                ctx.reject(data, "bench_slot_unavailable_short_length")
                return nil
            end
        else
            sitPosition = positions[slotIndex] or positions[1] or sitPosition
        end
    end

    local surfaceBlockerOverrideReason = nil
    local clutter, clutterDistance, clutterZ, clutterReason, clutterKind = ctx.seatingClutterBlockers.surfaceBlocker(ctx.seatClutterContext(), sitPosition, profile, currentObject)
    if clutter then
        data.surfaceBlockerReason = "seat_surface_blocked_by_item"
        data.surfaceBlockerKind = tostring(clutterKind or "seat_surface_blocked_by_item")
        data.surfaceBlockerObjectId = tostring(clutter.recordId or clutter.id)
        data.surfaceBlockerDistance = clutterDistance
        data.surfaceBlockerVertical = clutterZ
        data.surfaceBlockerLocalReason = clutterReason
        if clutterKind == "soft_surface" then
            local softZ = ctx.seatingClutterBlockers.softSurfaceTopZ(ctx.seatClutterContext(), clutter, sitPosition)
            if softZ then
                local oldZ = sitPosition.z
                sitPosition = ctx.util.vector3(sitPosition.x, sitPosition.y, softZ)
                surfaceMode = tostring(surfaceMode or "surface") .. "+soft_seat_clutter_surface"
                data.surfaceBlockerReason = "soft_seat_clutter_surface"
                data.softBlockerReason = tostring(clutterKind)
                debugLog(
                    "soft seat clutter surface applied",
                    "object", tostring(currentObject and currentObject.recordId),
                    "profile", tostring(profile and profile.profileId),
                    "slot", tostring(currentSlotName),
                    "clutter", tostring(clutter.recordId or clutter.id),
                    "oldZ", tostring(oldZ),
                    "newZ", tostring(softZ),
                    "deltaZ", tostring(softZ - oldZ),
                    "reason", tostring(clutterReason)
                )
                clutter = nil
            else
                debugLog(
                    "soft seat clutter surface unavailable",
                    "object", tostring(currentObject and currentObject.recordId),
                    "profile", tostring(profile and profile.profileId),
                    "slot", tostring(currentSlotName),
                    "clutter", tostring(clutter.recordId or clutter.id),
                    "vertical", tostring(clutterZ),
                    "reason", tostring(clutterReason)
                )
            end
        end
    end
    if clutter then
        debugLog(
            "sitting surface rejected clutter",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "clutter", tostring(clutter.recordId or clutter.id),
            "distance", tostring(clutterDistance),
            "vertical", tostring(clutterZ),
            "reason", tostring(clutterReason),
            "kind", tostring(clutterKind)
        )
        if data.manualAssignOverrideTesting == true or data.explicitFillOverride == true or data.calibrationFill == true then
            surfaceBlockerOverrideReason = "seat_surface_blocked_by_item"
            data.surfaceBlockerOverrideReason = surfaceBlockerOverrideReason
            data.softBlockerReason = tostring(clutterKind or "seat_surface_blocked_by_item")
            ctx.noteManualAssignOverride(data, surfaceBlockerOverrideReason)
            local bypass = (data.explicitFillOverride == true or data.calibrationFill == true) and "explicit_fill_soft_reject" or "sitting_surface_item"
            debugLog("explicit fill soft reject override", "reason", surfaceBlockerOverrideReason, "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "clutter", tostring(clutter.recordId or clutter.id), "bypass", bypass)
            debugLog("nearest_manual_assign_override", "reason", surfaceBlockerOverrideReason, "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", bypass)
        else
            data.softBlockerReason = tostring(clutterKind or "seat_surface_blocked_by_item")
            ctx.reject(data, "seat_surface_blocked_by_item")
            return nil
        end
    end

    data.sittingSeatPosition = sitPosition
    local poseActivity = "standard"
    ctx.sittingFacingRefiner.refine({
        nearby = ctx.nearby,
        util = ctx.util,
        profiles = profiles,
        rayHitBelongsToObject = ctx.rayHitBelongsToObject,
        sittingSeatCategory = ctx.sittingSeatCategory,
        debugLog = debugLog,
    }, sitPosition, data, profile, currentObject)

    local facingDirection, facingReason = ctx.determineFacingDirection(sitPosition, orientation, data.preferredFacingDirection, data.facingKind, profile, currentObject, data)
    if surfaceBlockerOverrideReason then
        facingReason = tostring(facingReason) .. "+manual_item_override"
    end
    data.preferredFacingDirection = facingDirection
    local refinedAnimation, refinedVariant = ctx.chooseAvailableAnimation(profile, data)
    if refinedAnimation and refinedAnimation ~= currentAnimation then
        debugLog(
            "sitting animation refined after facing",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "from", tostring(currentAnimation),
            "to", tostring(refinedAnimation),
            "facingKind", tostring(data and data.facingKind),
            "facingObject", tostring(data and data.facingObjectId),
            "facingReason", tostring(facingReason)
        )
        currentAnimation = refinedAnimation
        profile.animation = refinedAnimation
        profile.chosenAnimationVariant = refinedVariant
    end
    local poseAnimation = currentAnimation
    if profile.chairOrientationVariantSource == "explicit_chair_orientation_variant" then
        debugLog(
            "chair orientation variant selected",
            tostring(currentObject and currentObject.recordId),
            "slot", tostring(currentSlotName),
            "yawBucket90", tostring(profile.chairOrientationYawBucket90),
            "source", tostring(profile.chairOrientationVariantSource)
        )
    end
    local finalPos, finalYawOffset, profileOffset, appliedCalibration, animationOffset = ctx.finalPositionForProfile(sitPosition, facingDirection, profile, poseActivity, poseAnimation)
    local reprojectedFacing, reprojectReason = ctx.reprojectSittingFacingFromBody(finalPos, facingDirection, profile, data)
    if reprojectReason then
        facingDirection = reprojectedFacing
        finalPos, finalYawOffset, profileOffset, appliedCalibration, animationOffset = ctx.finalPositionForProfile(sitPosition, facingDirection, profile, poseActivity, poseAnimation)
        facingReason = tostring(facingReason) .. "+" .. tostring(reprojectReason)
        data.preferredFacingDirection = facingDirection
    end
    local zCorrectionReason, zCorrectionMeta = nil, nil
    finalPos, zCorrectionReason, zCorrectionMeta = ctx.correctExplicitProfileSittingZ(sitPosition, finalPos, profile, profileOffset, appliedCalibration, surfaceMode, animationOffset)
    if zCorrectionReason then
        facingReason = tostring(facingReason) .. "+" .. tostring(zCorrectionReason)
    end
    local adjustedPos, adjustReason, clearanceMeta = ctx.rejectSittingFinalIfBlocked(finalPos, facingDirection, profile, data, currentObject)
    if adjustReason then
        data.surfaceBlockerReason = tostring(adjustReason)
        data.surfaceBlockerKind = tostring((clearanceMeta and (clearanceMeta.category or clearanceMeta.result)) or adjustReason)
        data.surfaceBlockerObjectId = clearanceMeta and clearanceMeta.blockerRecord or data.surfaceBlockerObjectId
        data.surfaceBlockerDistance = clearanceMeta and (clearanceMeta.blockerDistance or clearanceMeta.tableDistance) or data.surfaceBlockerDistance
        data.surfaceBlockerVertical = clearanceMeta and clearanceMeta.vertical or data.surfaceBlockerVertical
        if ctx.seatingClearance.manualAssignMayBypassSittingClearance(data, clearanceMeta, ctx.sittingSeatCategory(profile, currentObject)) then
            ctx.noteManualAssignOverride(data, tostring(adjustReason))
            debugLog("nearest_manual_assign_override", "reason", tostring(adjustReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "sitting_clearance")
            facingReason = tostring(facingReason) .. "+manual_clearance_override"
            adjustReason = "manual_clearance_override"
        else
            local snap = ctx.calibrationExport.sittingSolverSnapshot(currentObject, sitPosition, finalPos, ctx.actor, finalYawOffset, facingDirection, facingReason, data, surfaceMode, surfaceSamples)
            ctx.calibrationExport.logDemidChairBasisComparison(debugLog, ctx.actor, currentObject, snap, clearanceMeta or { result = adjustReason })
            ctx.reject(data, adjustReason)
            return nil
        end
    elseif adjustedPos then
        finalPos = adjustedPos
    end
    if not adjustReason then
        clearAcceptedClearanceBlocker(data, debugLog, currentObject, currentSlotName)
    end
    local solverSnapshot = ctx.calibrationExport.sittingSolverSnapshot(currentObject, sitPosition, finalPos, ctx.actor, finalYawOffset, facingDirection, facingReason, data, surfaceMode, surfaceSamples)
    if not ctx.sittingFinalVerticalLooksSane(sitPosition, finalPos, profile) then
        if ctx.manualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, "initial_sitting_vertical_rejected", "sitting_vertical_sanity") then
            facingReason = tostring(facingReason) .. "+manual_vertical_override"
        else
            ctx.calibrationExport.logDemidChairBasisComparison(debugLog, ctx.actor, currentObject, solverSnapshot, zCorrectionMeta or { result = "initial_sitting_vertical_rejected" })
            ctx.reject(data, "initial_sitting_vertical_rejected")
            return nil
        end
    end
    local lockedRouteReason = ctx.sittingLockedRouteRejectReason(data.approachPos or sitPosition, data)
    if lockedRouteReason then
        if teleportRouteReason(lockedRouteReason) then
            data.hardBlockerReason = tostring(lockedRouteReason)
            if data.calibrationTestNpc == true and data.manualAssignOverrideTesting == true then
                ctx.noteManualAssignOverride(data, "spawned_test_actor_reachability_override")
                debugLog("spawned_test_actor_reachability_override", "reason", tostring(lockedRouteReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "teleport_door_route")
                facingReason = tostring(facingReason) .. "+spawned_test_actor_reachability_override"
            else
                local rejectReason = existingActorReachabilityReason(data, lockedRouteReason)
                data.hardBlockerReason = tostring(lockedRouteReason)
                debugLog("sitting_teleport_door_route_hard_reject", "reason", tostring(rejectReason), "routeReason", tostring(lockedRouteReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName))
                ctx.calibrationExport.logDemidChairBasisComparison(debugLog, ctx.actor, currentObject, solverSnapshot, { result = rejectReason, routeReason = lockedRouteReason })
                ctx.reject(data, rejectReason)
                return nil
            end
        elseif data.manualAssignOverrideTesting == true then
            ctx.noteManualAssignOverride(data, tostring(lockedRouteReason))
            debugLog("nearest_manual_assign_override", "reason", tostring(lockedRouteReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "sitting_locked_route")
            facingReason = tostring(facingReason) .. "+manual_locked_route_override"
        else
            ctx.calibrationExport.logDemidChairBasisComparison(debugLog, ctx.actor, currentObject, solverSnapshot, { result = lockedRouteReason })
            ctx.reject(data, lockedRouteReason)
            return nil
        end
    end
    local yawOffsetBeforeBenchNormalize = finalYawOffset
    local seatCategoryForYaw = ctx.sittingSeatCategory(profile, currentObject)
    local focusYawOwnsBody = (seatCategoryForYaw == "bench"
        or seatCategoryForYaw == "single_seat_bench"
        or seatCategoryForYaw == "stool"
        or seatCategoryForYaw == "barstool")
        and (data.facingKind == "table" or data.facingKind == "bar" or data.facingKind == "lectern" or data.facingKind == "grinder")
    local tableFacingYaw = math.atan2(facingDirection.x, facingDirection.y)
    local rawFurnitureYaw = currentObject and currentObject.rotation and currentObject.rotation.getYaw and currentObject.rotation:getYaw() or nil
    if focusYawOwnsBody
        and math.abs(tonumber(finalYawOffset) or 0) > math.rad(45) then
        finalYawOffset = 0
        debugLog(
            seatCategoryForYaw == "bench" and "bench slot yaw normalized" or "seat focus yaw normalized",
            "cell", tostring(currentObject and currentObject.cell and (currentObject.cell.name or currentObject.cell.id)),
            "object", tostring(currentObject and currentObject.recordId),
            "model", tostring(currentObject and profiles.objectModelPath(currentObject)),
            "slot", tostring(currentSlotName),
            "slotIndex", tostring(currentSlotName == "seat_b" and 2 or (currentSlotName == "seat_c" and 3 or 1)),
            "category", tostring(seatCategoryForYaw),
            "facingKind", tostring(data.facingKind),
            "rawFurnitureYaw", tostring(rawFurnitureYaw),
            "profileYaw", tostring(yawOffsetBeforeBenchNormalize),
            "tableFacingYaw", tostring(tableFacingYaw),
            "finalYaw", tostring(tableFacingYaw),
            "yawSource", "focus_direction",
            "tableFacing", "true",
            "oldYawOffset", tostring(yawOffsetBeforeBenchNormalize),
            "newYawOffset", "0"
        )
        facingReason = tostring(facingReason) .. "+focus_slot_yaw_normalized"
    end
    local finalRot = math.atan2(facingDirection.x, facingDirection.y) + (finalYawOffset or 0)
    if focusYawOwnsBody then
        debugLog(
            seatCategoryForYaw == "bench" and "bench yaw resolution" or "seat focus yaw resolution",
            "cell", tostring(currentObject and currentObject.cell and (currentObject.cell.name or currentObject.cell.id)),
            "object", tostring(currentObject and currentObject.recordId),
            "model", tostring(currentObject and profiles.objectModelPath(currentObject)),
            "slot", tostring(currentSlotName),
            "slotIndex", tostring(currentSlotName == "seat_b" and 2 or (currentSlotName == "seat_c" and 3 or 1)),
            "rawFurnitureYaw", tostring(rawFurnitureYaw),
            "profileYaw", tostring(yawOffsetBeforeBenchNormalize),
            "tableFacingYaw", tostring(tableFacingYaw),
            "finalYaw", tostring(finalRot),
            "yawSource", math.abs(tonumber(yawOffsetBeforeBenchNormalize) or 0) > math.rad(45) and "focus_direction" or "profile_or_focus_aligned",
            "tableFacing", tostring(data.facingKind == "table" or data.facingKind == "bar" or data.facingKind == "lectern" or data.facingKind == "grinder")
        )
    end
    data.facingReason = facingReason
    local sittingProfileSource = profile and profile.chairOrientationVariantSource
        or (profile and profile.externalProfile == true and "explicit_profile")
        or (profile and profile.profileId and "fallback_or_generated")
        or "fallback"
    debugLog(
        "resolved sitting transform",
        "object", tostring(currentObject.recordId),
        "model", tostring(profiles.objectModelPath(currentObject)),
        "targetType", "seat",
        "slot", tostring(currentSlotName),
        "profile", tostring(profile.profileId),
        "profileSource", tostring(sittingProfileSource),
        "selectionSource", tostring(profile.profileSelectionSource),
        "selectionReason", tostring(profile.profileSelectionReason),
        "selectionKey", tostring(profile.profileSelectionKey),
        "facing", tostring(facingReason),
        "facingObject", tostring(data.facingObjectId),
        "surfaceMode", tostring(surfaceMode),
        "surfaceSamples", tostring(surfaceSamples),
        "profileOffset", profileOffset and (tostring(profileOffset.x) .. "," .. tostring(profileOffset.y) .. "," .. tostring(profileOffset.z) .. ",yaw=" .. tostring(profileOffset.yaw)) or "0,0,0,yaw=0",
        "animationOffset", animationOffset and (tostring(animationOffset.x) .. "," .. tostring(animationOffset.y) .. "," .. tostring(animationOffset.z) .. ",yaw=" .. tostring(animationOffset.yaw)) or "0,0,0,yaw=0",
        "calibration", appliedCalibration and (tostring(appliedCalibration.x) .. "," .. tostring(appliedCalibration.y) .. "," .. tostring(appliedCalibration.z) .. ",yaw=" .. tostring(appliedCalibration.yaw)) or "0,0,0,yaw=0",
        "seat", tostring(sitPosition),
        "final", tostring(finalPos),
        "rotation", tostring(finalRot)
    )
    ctx.calibrationExport.traceLocalSittingAcceptance(ctx.core, ctx.actor, currentObject, currentSlotName, debugLog, "begin", {
        objectId = currentObject and currentObject.recordId,
        slotName = currentSlotName,
        reason = adjustReason,
    })
    if ctx.sittingSeatCategory(profile, currentObject) == "backed_chair" then
        local objectYaw = currentObject and currentObject.rotation and currentObject.rotation.getYaw and currentObject.rotation:getYaw() or 0
        debugLog(
            "backed_chair_rotation_final",
            "objectYaw", tostring(objectYaw),
            "profileYaw", tostring(finalYawOffset or 0),
            "finalYaw", tostring(finalRot)
        )
    end

    return {
        sitPosition = sitPosition,
        surfaceMode = surfaceMode,
        surfaceSamples = surfaceSamples,
        poseActivity = poseActivity,
        poseAnimation = poseAnimation,
        currentAnimation = currentAnimation,
        finalPos = finalPos,
        finalRot = finalRot,
        finalYawOffset = finalYawOffset,
        facingDirection = facingDirection,
        facingReason = facingReason,
        profileOffset = profileOffset,
        appliedCalibration = appliedCalibration,
        animationOffset = animationOffset,
        solverSnapshot = solverSnapshot,
        clearanceMeta = clearanceMeta,
        zCorrectionMeta = zCorrectionMeta,
        adjustReason = adjustReason,
    }
end

return M
