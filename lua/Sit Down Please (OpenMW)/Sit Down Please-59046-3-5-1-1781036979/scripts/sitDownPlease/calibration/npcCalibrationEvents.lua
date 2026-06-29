-- Calibration event handlers for the NPC-local interaction script.
---@omw-context none
-- Kept outside interactionSeeker.lua so the entrypoint stays below OpenMW Lua's
-- 200-local main chunk limit.

local calibrationExport = require('scripts/sitDownPlease/calibration/exportRows')
local calibrationMetadata = require('scripts/sitDownPlease/calibration/metadata')
local calibrationPoseState = require('scripts/sitDownPlease/calibration/poseState')
local sleepCalibrationWarnings = require('scripts/sitDownPlease/interactions/sleeping/calibrationWarnings')
local surfaceProbe = require('scripts/sitDownPlease/world/surfaceProbe')

local M = {}

local function offsetText(offset)
    offset = offset or {}
    return tostring(offset.x or 0) .. "," .. tostring(offset.y or 0) .. "," .. tostring(offset.z or 0) .. ",yaw=" .. tostring(offset.yaw or 0)
end

local function effectiveSleepBedType(profile, slotName)
    local slot = tostring(slotName or ""):lower()
    if slot == "sleep_top" then return "top_bunk" end
    if slot == "sleep_bottom" then return "bottom_bunk" end
    return profile and (profile.bedType or profile.type) or nil
end

local function actorCellName(actor)
    local ok, value = pcall(function()
        return actor and actor.cell and (actor.cell.name or actor.cell.id)
    end)
    if ok and value ~= nil then return value end
    return nil
end

local function objectContentFile(obj)
    local value = obj and obj.contentFile or nil
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end

local function objectModelPath(profiles, obj)
    local value = profiles and profiles.objectModelPath and profiles.objectModelPath(obj) or nil
    if value == nil or tostring(value) == "" then
        local ok, rec = pcall(function()
            if obj and obj.type and obj.type.record then return obj.type.record(obj) end
            return nil
        end)
        if ok and rec and rec.model then value = rec.model end
    end
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end

local function profileLayerFile(profile)
    local variant = profile and (profile.chairOrientationVariant or profile.orientationVariant or profile.stationOrientationVariant) or nil
    local source = variant and variant.sourceName or profile and profile.sourceName or nil
    if source == nil or tostring(source) == "" then return nil end
    return tostring(source)
end

local function logNoChangeApproval(ctx, sequence, kind, state)
    local actor = ctx.actor and ctx.actor() or nil
    print("[SitDownPlease Calibration Approval]",
        "NO_CHANGE_APPROVAL",
        "export_sequence", tostring(sequence),
        "kind", tostring(kind),
        "actor", tostring(actor and (actor.recordId or actor.id)),
        "actorScale", tostring(actor and actor.scale),
        "object", tostring(state.currentObject and state.currentObject.recordId),
        "model", tostring(objectModelPath(state.profiles, state.currentObject)),
        "contentFile", tostring(objectContentFile(state.currentObject)),
        "objectScale", tostring(state.currentObject and state.currentObject.scale),
        "profile", tostring(state.currentProfile and state.currentProfile.profileId),
        "profileSource", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
        "profileLayerFile", tostring(profileLayerFile(state.currentProfile)),
        "profileKey", tostring(state.currentProfile and state.currentProfile.profileSelectionKey),
        "slot", tostring(state.currentSlotName or state.currentSlotKey),
        "cell", tostring(actorCellName(actor)),
        "simTime", tostring(ctx.core and ctx.core.getSimulationTime and ctx.core.getSimulationTime() or nil)
    )
end

local function calibrationHasEvidenceContext(runtime)
    runtime = runtime or {}
    return runtime.calibrationFillLabel ~= nil
        or runtime.calibrationFillRole ~= nil
        or runtime.calibrationFillSource ~= nil
        or runtime.calibrationFillIndex ~= nil
        or runtime.calibrationRuntimeObjectId ~= nil
        or runtime.actorDisplayLabel ~= nil
        or runtime.manualAssignOverrideApplied == true
        or runtime.manualOverrideApplied == true
        or runtime.explicitFillOverride == true
end

function M.bind(ctx)
    local handlers = {}

    local function printScaleContext(kind, sequence, state, rowDiffers, baseHint)
        local actor = ctx.actor and ctx.actor() or nil
        local scale = calibrationExport.scalePromotionContext(state.currentObject, actor, rowDiffers, baseHint)
        print("[SitDownPlease Calibration Export]",
            "SCALE_CONTEXT",
            "export_sequence", tostring(sequence),
            "kind", tostring(kind),
            "cell", tostring(actorCellName(ctx.actor and ctx.actor() or nil)),
            "object", tostring(state.currentObject and state.currentObject.recordId),
            "profile", tostring(state.currentProfile and state.currentProfile.profileId),
            "slot", tostring(state.currentSlotName or state.currentSlotKey),
            "objectScale", tostring(scale.objectScale),
            "actorScale", tostring(scale.actorScale),
            "objectScaleNonStandard", tostring(scale.objectScaleNonStandard == true),
            "actorScaleNonStandard", tostring(scale.actorScaleNonStandard == true),
            "scalePromotionCaution", tostring(scale.promotionCaution),
            "scaleAdjustedHint", tostring(scale.promotionHint)
        )
        return scale
    end

    local function printSittingCalibration(label)
        local sequence = ctx.nextCalibrationExportSequence()
        local state = ctx.state()
        local cal = ctx.sittingCalibrationSnapshot()
        local activity = state.currentSittingPoseActivity or "standard"
        local animation = state.currentSittingPoseAnimation or state.currentAnimation or "<none>"
        local profileOffset = state.currentSittingAppliedProfileOffset or ctx.sittingProfileOffsetFor(state.currentProfile, activity, animation)
        local animationOffset = state.currentSittingAppliedAnimationOffset or ctx.sittingAnimationNormalizationFor(animation, state.currentProfile)
        local row = calibrationExport.sittingProfileExportRow(state.currentProfile, state.currentObject, state.profiles, profileOffset, cal)
        local variantRow = calibrationExport.chairOrientationProfileRow(state.currentProfile, state.currentObject, state.profiles, profileOffset, cal, state.currentSlotName or state.currentSlotKey or "default", { actor = ctx.actor(), objectScale = state.currentObject and state.currentObject.scale })
        local objectOverrideRow = calibrationExport.chairObjectOverrideRow(state.currentProfile, state.currentObject, state.profiles, profileOffset, cal, state.currentSlotName or state.currentSlotKey or "default", { actor = ctx.actor(), objectScale = state.currentObject and state.currentObject.scale })
        local runtimeSittingCalibration = ctx.runtimeSittingCalibration()
        local classification = calibrationExport.sittingPromotionClassification(state.currentProfile, state.currentObject, profileOffset, cal, {
            actor = ctx.actor(),
            facingKind = runtimeSittingCalibration.facingKind,
            manualOverride = runtimeSittingCalibration.manualAssignOverrideApplied == true,
        })
        local promotionHint = classification.hint
        if classification.rowDiffers == true and animation and animation ~= "" and animation ~= "<none>" then
            promotionHint = "review_animation_or_context_before_promote"
        end
        local sittingScaleContext = printScaleContext("sitting", sequence, state, classification.rowDiffers == true, promotionHint)
        promotionHint = sittingScaleContext.promotionHint or promotionHint
        local sittingRecommendedFile = classification.rowDiffers == true and "furnitureProfiles/sdp/global/chairProfileVariants.txt" or "already_loaded_profile"
        if classification.rowDiffers == true and sittingScaleContext.objectScaleNonStandard == true then
            sittingRecommendedFile = "furnitureProfiles/sdp/global/chairObjectOverrides.txt"
        end
        if classification.rowDiffers ~= true and calibrationHasEvidenceContext(runtimeSittingCalibration) ~= true then
            logNoChangeApproval(ctx, sequence, "sitting", state)
            return
        end

        print("[SitDownPlease]", tostring(label or "seat calibration"),
            "seat", tostring(state.currentObject and state.currentObject.recordId or "<none>"),
            "model", tostring(objectModelPath(state.profiles, state.currentObject)),
            "contentFile", tostring(objectContentFile(state.currentObject)),
            "objectScale", tostring(state.currentObject and state.currentObject.scale),
            "profileLayerWinner", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
            "profileLayerFile", tostring(profileLayerFile(state.currentProfile)),
            "profileOffset", offsetText(profileOffset),
            "animationOffset", offsetText(animationOffset),
            "currentChanges", offsetText(cal),
            "copyRow", row
        )
        print("[SitDownPlease Calibration Export]",
            "export_sequence", tostring(sequence),
            "cell", tostring(actorCellName(ctx.actor and ctx.actor() or nil)),
            "object", tostring(state.currentObject and state.currentObject.recordId),
            "model", tostring(objectModelPath(state.profiles, state.currentObject)),
            "contentFile", tostring(objectContentFile(state.currentObject)),
            "currently_loaded_profile_key", tostring(state.currentProfile and state.currentProfile.profileId),
            "profile_layer_winner", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
            "profile_layer_file", tostring(profileLayerFile(state.currentProfile)),
            "selection_source", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
            "selection_key", tostring(state.currentProfile and state.currentProfile.profileSelectionKey),
            "selection_reason", tostring(state.currentProfile and state.currentProfile.profileSelectionReason),
            "loaded_profile_offset", offsetText(profileOffset),
            "normalized_offset", offsetText({
                x = (tonumber(profileOffset and profileOffset.x) or 0) + (tonumber(cal and cal.x) or 0),
                y = (tonumber(profileOffset and profileOffset.y) or 0) + (tonumber(cal and cal.y) or 0),
                z = (tonumber(profileOffset and profileOffset.z) or 0) + (tonumber(cal and cal.z) or 0),
                yaw = (tonumber(profileOffset and profileOffset.yaw) or 0) + (tonumber(cal and cal.yaw) or 0),
            }),
            "animation", tostring(animation),
            "animation_normalization_offset", offsetText(animationOffset),
            "row_differs_from_loaded_profile", tostring(classification.rowDiffers == true),
            "promotion_hint", tostring(promotionHint),
            "recommended_file", tostring(sittingRecommendedFile),
            "classification", tostring(classification.label),
            "reason", tostring(classification.reason),
            "clearance_override", tostring(runtimeSittingCalibration.manualAssignOverrideApplied == true),
            "clearance_override_reason", tostring(runtimeSittingCalibration.manualAssignOverrideReason),
            "scale_context", tostring(classification.scaleContext and classification.scaleContext.notes or ""),
            "actorScale", tostring(classification.scaleContext and classification.scaleContext.actorScale or (ctx.actor() and ctx.actor().scale)),
            "objectScale", tostring(classification.scaleContext and classification.scaleContext.objectScale or (state.currentObject and state.currentObject.scale))
        )

        local snap = runtimeSittingCalibration.solverSnapshot or {}
        print("[SitDownPlease Calibration Export]",
            "chair_solver_basis",
            "object", tostring(state.currentObject and state.currentObject.recordId),
            "profile", tostring(state.currentProfile and state.currentProfile.profileId),
            "baseLocal", calibrationExport.offsetLabel(snap.baseLocal),
            "finalLocal", calibrationExport.offsetLabel(snap.finalLocal),
            "deltaLocal", calibrationExport.offsetLabel(snap.deltaLocal),
            "objectYawDeg", tostring(calibrationExport.shortNumber(snap.objectYawDeg or 0)),
            "objectScale", tostring(snap.objectScale),
            "actorScale", tostring(snap.actorScale),
            "facingReason", tostring(snap.facingReason),
            "facingKind", tostring(snap.facingKind),
            "facingObject", tostring(snap.facingObjectId),
            "facingObjectModel", tostring(snap.facingObjectModel),
            "facingObjectScale", tostring(snap.facingObjectScale),
            "surface", tostring(snap.surfaceMode),
            "surfaceSamples", tostring(snap.surfaceSamples),
            "manualOverride", tostring(runtimeSittingCalibration.manualAssignOverrideApplied == true),
            "manualOverrideReason", tostring(runtimeSittingCalibration.manualAssignOverrideReason)
        )
        surfaceProbe.request({
            nearby = ctx.nearby,
            async = ctx.async,
            util = ctx.util,
            actor = ctx.actor(),
            profiles = state.profiles,
            rayHitBelongsToObject = ctx.rayHitBelongsToObject,
        }, {
            sequence = sequence,
            kind = "sitting",
            object = state.currentObject,
            profile = state.currentProfile,
            selectedSurface = state.currentSittingBaseHitPos,
            surfaceMode = snap.surfaceMode,
            surfaceSamples = snap.surfaceSamples,
        })
        print("[SitDownPlease Calibration Export]", tostring(classification.label), "seat", tostring(state.currentObject and state.currentObject.recordId), "profile", tostring(state.currentProfile and state.currentProfile.profileId), "reason", tostring(classification.reason))
        if classification.conflict == true then
            print("[SitDownPlease Calibration Export]", "chair calibration conflicts with existing profile", "seat", tostring(state.currentObject and state.currentObject.recordId), "profile", tostring(state.currentProfile and state.currentProfile.profileId))
        end
        print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/chairProfiles.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
        print("[SitDownPlease Calibration Export]", "ROW", row)
        print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/chairProfileVariants.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
        print("[SitDownPlease Calibration Export]", "CHAIR_ORIENTATION_ROW", variantRow)
        if classification.rowDiffers == true and sittingScaleContext.objectScaleNonStandard == true then
            print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/chairObjectOverrides.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId), "SLOT", tostring(state.currentSlotName or state.currentSlotKey or "default"))
            print("[SitDownPlease Calibration Export]", "CHAIR_OBJECT_OVERRIDE_ROW", objectOverrideRow)
        end

        if classification.rowDiffers == true and animation and animation ~= "" and animation ~= "<none>" then
            local buckets = state.profiles.objectYawBuckets and state.profiles.objectYawBuckets(state.currentObject) or {}
            local normalizationRow = calibrationExport.animationNormalizationRow({
                interactionType = "sitting",
                animation = animation,
                object = state.currentObject,
                actor = ctx.actor(),
                profiles = state.profiles,
                profileId = state.currentProfile and state.currentProfile.profileId or "",
                slotName = state.currentSlotName or state.currentSlotKey or "default",
                yawBucket90 = buckets and buckets.yawBucket90 or "",
                baseOffset = animationOffset,
                delta = cal,
                notes = "Scoped sitting animation normalization candidate from calibration export; promote only if the furniture profile is correct for other sitting animations.",
            })
            print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/animationNormalizationOffsets.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
            print("[SitDownPlease Calibration Export]", "ANIMATION_NORMALIZATION_ROW", normalizationRow)
        end

        calibrationMetadata.print("sitting", state.currentObject, ctx.actor(), state.types, calibrationExport.shortNumber, {
            profileSource = state.currentProfile and (state.currentProfile.chairOrientationVariantSource or (state.currentProfile.externalProfile == true and "explicit_profile" or "fallback")) or "missing_profile",
            slot = state.currentSlotName or state.currentSlotKey,
            surfaceMode = snap.surfaceMode,
            basisSource = snap.facingReason,
            promotableFlag = promotionHint,
            safetyFlag = classification.label,
            manualOverride = runtimeSittingCalibration.manualAssignOverrideApplied == true,
            manualOverrideReason = runtimeSittingCalibration.manualAssignOverrideReason,
            actorLabel = runtimeSittingCalibration.actorDisplayLabel or runtimeSittingCalibration.calibrationFillLabel,
            fillRole = runtimeSittingCalibration.calibrationFillRole,
            fillSource = runtimeSittingCalibration.calibrationFillSource,
            fillIndex = runtimeSittingCalibration.calibrationFillIndex,
            runtimeObjectId = runtimeSittingCalibration.calibrationRuntimeObjectId,
            cell = actorCellName(ctx.actor and ctx.actor() or nil),
            surfaceBlockerReason = runtimeSittingCalibration.surfaceBlockerReason,
            surfaceBlockerOverrideReason = runtimeSittingCalibration.surfaceBlockerOverrideReason,
            surfaceBlockerKind = runtimeSittingCalibration.surfaceBlockerKind,
            surfaceBlockerObjectId = runtimeSittingCalibration.surfaceBlockerObjectId,
            surfaceBlockerDistance = runtimeSittingCalibration.surfaceBlockerDistance,
            surfaceBlockerVertical = runtimeSittingCalibration.surfaceBlockerVertical,
            surfaceBlockerLocalReason = runtimeSittingCalibration.surfaceBlockerLocalReason,
            softBlockerReason = runtimeSittingCalibration.softBlockerReason,
            hardBlockerReason = runtimeSittingCalibration.hardBlockerReason,
            sleepSafetyReason = runtimeSittingCalibration.sleepSafetyReason,
            sleepSafetyDelta = runtimeSittingCalibration.sleepSafetyDelta,
            sleepSafetyLimit = runtimeSittingCalibration.sleepSafetyLimit,
            sleepSafetyOverrideReason = runtimeSittingCalibration.sleepSafetyOverrideReason,
            sleepCalibrationWarningReason = runtimeSittingCalibration.sleepCalibrationWarningReason,
        })
    end

    local function printSleepCalibrationDetails(label, reason)
        local sequence = ctx.nextCalibrationExportSequence()
        local state = ctx.state()
        local calibrationYawDiffers = math.abs(tonumber(state.currentSleepCalibrationYawDegrees) or 0) > 0.001
        local rowDiffers = calibrationExport.offsetDiffers(state.currentSleepProfileRootOffset, state.currentSleepMergedRootOffset, 0.5)
            or calibrationYawDiffers
        local promotionHint = calibrationExport.sleepPromotionHint(state.currentProfile, rowDiffers)
        local profileSource = calibrationExport.sleepProfileSource(state.currentProfile)
        local recommendedFile = calibrationExport.sleepRecommendedFile(state.currentProfile, rowDiffers)
        local sleepScaleContext = printScaleContext("sleeping", sequence, state, rowDiffers, promotionHint)
        if rowDiffers and sleepScaleContext.objectScaleNonStandard == true and recommendedFile == "furnitureProfiles/sdp/global/bedProfileVariants.txt" then
            recommendedFile = "furnitureProfiles/sdp/global/bedObjectOverrides.txt"
        end
        promotionHint = sleepScaleContext.promotionHint or promotionHint
        local normalizationRole = (rowDiffers and state.currentAnimation) and "secondary_candidate_after_profile_slot_is_verified" or "not_needed_for_unchanged_profile"
        if rowDiffers ~= true and calibrationHasEvidenceContext(ctx.runtimeSleepCalibration()) ~= true then
            logNoChangeApproval(ctx, sequence, "sleeping", state)
            return
        end

        print("[SitDownPlease]", tostring(label or "sleep calibration"),
            "reason", tostring(reason or "calibration"),
            "actor", tostring(ctx.actor() and (ctx.actor().recordId or ctx.actor().id)),
            "object", tostring(state.currentObject and state.currentObject.recordId),
            "model", tostring(state.currentObject and state.profiles.objectModelPath(state.currentObject)),
            "profile", tostring(state.currentProfile and state.currentProfile.profileId),
            "category", tostring(effectiveSleepBedType(state.currentProfile, state.currentSlotName or state.currentSlotKey)),
            "slot", tostring(state.currentSlotName or state.currentSlotKey),
            "profileOffset", calibrationExport.offsetLabel(state.currentSleepProfileRootOffset),
            "animation", tostring(state.currentAnimation),
            "animationNormalizationOffset", calibrationExport.offsetLabel(state.currentSleepAnimationNormalizationOffset),
            "calibrationOffset", calibrationExport.offsetLabel(state.currentSleepCalibrationOffset),
            "mergedFinalOffset", calibrationExport.offsetLabel(state.currentSleepMergedRootOffset),
            "localXOffset", tostring(state.currentSleepMergedRootOffset and state.currentSleepMergedRootOffset.x or 0),
            "localYOffset", tostring(state.currentSleepMergedRootOffset and state.currentSleepMergedRootOffset.y or 0),
            "heightOffset", tostring(state.currentSleepMergedRootOffset and state.currentSleepMergedRootOffset.z or 0),
            "yawOffset", tostring(state.currentSleepCalibrationYawDegrees or 0),
            "worldFinalPosition", tostring(state.currentFinalPosition),
            "worldFinalRotation", tostring(state.currentFinalRotation),
            "longAxis", "local_y",
            "shortAxis", "local_x",
            "surface", tostring(state.currentSleepSurfaceMode),
            "surfaceSamples", tostring(state.currentSleepSurfaceSamples),
            "axisOverride", tostring(state.currentProfile and state.currentProfile.sleepAxisOverride ~= nil),
            "mergedWithProfile", "true"
        )
        print("[SitDownPlease Calibration Export]",
            "export_sequence", tostring(sequence),
            "cell", tostring(actorCellName(ctx.actor and ctx.actor() or nil)),
            "currently_loaded_profile_key", tostring(state.currentProfile and state.currentProfile.profileId),
            "selection_source", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
            "selection_key", tostring(state.currentProfile and state.currentProfile.profileSelectionKey),
            "selection_reason", tostring(state.currentProfile and state.currentProfile.profileSelectionReason),
            "loaded_profile_offset", calibrationExport.offsetLabel(state.currentSleepProfileRootOffset),
            "row_differs_from_loaded_profile", tostring(rowDiffers),
            "promotion_hint", tostring(promotionHint),
            "recommended_file", tostring(recommendedFile),
            "animation_normalization_role", tostring(normalizationRole),
            "scale_context", tostring(calibrationExport.scaleContextForExport(ctx.actor(), state.currentObject).notes),
            "actorScale", tostring(calibrationExport.scaleContextForExport(ctx.actor(), state.currentObject).actorScale),
            "objectScale", tostring(calibrationExport.scaleContextForExport(ctx.actor(), state.currentObject).objectScale)
        )
        surfaceProbe.request({
            nearby = ctx.nearby,
            async = ctx.async,
            util = ctx.util,
            actor = ctx.actor(),
            profiles = state.profiles,
            rayHitBelongsToObject = ctx.rayHitBelongsToObject,
        }, {
            sequence = sequence,
            kind = "sleeping",
            object = state.currentObject,
            profile = state.currentProfile,
            selectedSurface = state.currentSleepBedTop,
            surfaceMode = state.currentSleepSurfaceMode,
            surfaceSamples = state.currentSleepSurfaceSamples,
        })
        if profileSource ~= "explicit_profile" and profileSource ~= "explicit_profile_orientation_variant" then
            print("[SitDownPlease Calibration Export]",
                "profile_missing_despite_recent_calibration_export",
                "recordId", tostring(state.currentObject and state.currentObject.recordId),
                "profile", tostring(state.currentProfile and state.currentProfile.profileId),
                "profileSource", tostring(profileSource)
            )
        end
        print("[SitDownPlease Calibration Export]", "SLOT_IDENTITY", "recordId", tostring(state.currentObject and state.currentObject.recordId), "slot", tostring(state.currentSlotName or state.currentSlotKey), "bedType", tostring(effectiveSleepBedType(state.currentProfile, state.currentSlotName or state.currentSlotKey)))
        if state.currentProfile and (state.currentProfile.bedType == "double" or (state.currentProfile.slots and #state.currentProfile.slots > 1)) and state.currentSleepMergedRootOffset then
            print("[SitDownPlease Calibration Export]", "MIRRORED_SLOT_SUGGESTION_NOT_FINAL", "sourceSlot", tostring(state.currentSlotName or state.currentSlotKey), "suggestedOffset", calibrationExport.offsetLabel({ x = -(tonumber(state.currentSleepMergedRootOffset.x) or 0), y = tonumber(state.currentSleepMergedRootOffset.y) or 0, z = tonumber(state.currentSleepMergedRootOffset.z) or 0 }))
        end
        print("[SitDownPlease Calibration Export]", "FILE", "furnitureProfiles/sdp/global/bedProfiles.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId), "SLOT", tostring(state.currentSlotName or state.currentSlotKey))
        print("[SitDownPlease Calibration Export]", "ROW", calibrationExport.bedProfileCopyRow({
            profile = state.currentProfile,
            object = state.currentObject,
            actor = ctx.actor(),
            profiles = state.profiles,
            mergedRootOffset = state.currentSleepMergedRootOffset,
            poseYawOffset = state.currentSleepPoseYawOffset,
            slotName = state.currentSlotName,
            syncSlotZ = ctx.runtimeSleepCalibration().syncSlotZ,
            syncSlotXY = ctx.runtimeSleepCalibration().syncSlotXY,
        }))

        local buckets = state.profiles.objectYawBuckets and state.profiles.objectYawBuckets(state.currentObject) or {}
        print("[SitDownPlease Calibration Export]", "ORIENTATION_ROW", calibrationExport.bedOrientationProfileRow({
            profile = state.currentProfile,
            object = state.currentObject,
            profiles = state.profiles,
            mergedRootOffset = state.currentSleepMergedRootOffset,
            poseYawOffset = state.currentSleepPoseYawOffset,
            slotName = state.currentSlotName,
            syncSlotYaw = ctx.runtimeSleepCalibration().syncSlotYaw,
            actor = ctx.actor(),
            objectScale = state.currentObject and state.currentObject.scale,
        }))
        if rowDiffers and state.currentAnimation then
            print("[SitDownPlease Calibration Export]",
                "ANIMATION_NORMALIZATION_SUPPRESSED",
                "role", tostring(normalizationRole),
                "reason", "physical_slot_row_owns_current_delta",
                "animation", tostring(state.currentAnimation),
                "object", tostring(state.currentObject and state.currentObject.recordId),
                "profile", tostring(state.currentProfile and state.currentProfile.profileId),
                "slot", tostring(state.currentSlotName or state.currentSlotKey),
                "yawBucket90", tostring(buckets.yawBucket90),
                "baseOffset", calibrationExport.offsetLabel(state.currentSleepAnimationNormalizationOffset),
                "delta", calibrationExport.offsetLabel({
                    x = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.x or 0,
                    y = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.y or 0,
                    z = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.z or 0,
                    yaw = state.currentSleepCalibrationYawDegrees or 0,
                })
            )
        end
        print("[SitDownPlease Calibration Export]", "ORIENTATION_METADATA",
            "objectYawRad", tostring(buckets.objectYawRad),
            "objectYawDeg", tostring(calibrationExport.shortNumber(buckets.objectYawDeg or 0)),
            "yawBucket45", tostring(buckets.yawBucket45),
            "yawBucket90", tostring(buckets.yawBucket90),
            "profileSource", tostring(profileSource),
            "selectionSource", tostring(state.currentProfile and state.currentProfile.profileSelectionSource),
            "selectionKey", tostring(state.currentProfile and state.currentProfile.profileSelectionKey),
            "recordId", tostring(state.currentObject and state.currentObject.recordId),
            "model", tostring(state.currentObject and state.profiles.objectModelPath(state.currentObject)),
            "profileId", tostring(state.currentProfile and state.currentProfile.profileId),
            "slot", tostring(state.currentSlotName or state.currentSlotKey),
            "bedType", tostring(effectiveSleepBedType(state.currentProfile, state.currentSlotName or state.currentSlotKey)),
            "finalOffset", calibrationExport.offsetLabel(state.currentSleepMergedRootOffset),
            "surface", tostring(state.currentSleepSurfaceMode)
        )
        calibrationMetadata.print("sleeping", state.currentObject, ctx.actor(), state.types, calibrationExport.shortNumber, {
            profileSource = profileSource,
            yawBucket90 = buckets.yawBucket90,
            slot = state.currentSlotName or state.currentSlotKey,
            surfaceMode = state.currentSleepSurfaceMode,
            basisSource = profileSource,
            promotableFlag = promotionHint,
            safetyFlag = rowDiffers and "review_before_promote" or "matches_loaded_profile",
            actorLabel = ctx.runtimeSleepCalibration().actorDisplayLabel or ctx.runtimeSleepCalibration().calibrationFillLabel,
            fillRole = ctx.runtimeSleepCalibration().calibrationFillRole,
            fillSource = ctx.runtimeSleepCalibration().calibrationFillSource,
            fillIndex = ctx.runtimeSleepCalibration().calibrationFillIndex,
            runtimeObjectId = ctx.runtimeSleepCalibration().calibrationRuntimeObjectId,
            cell = actorCellName(ctx.actor and ctx.actor() or nil),
            hardBlockerReason = ctx.runtimeSleepCalibration().hardBlockerReason,
            sleepSafetyReason = ctx.runtimeSleepCalibration().sleepSafetyReason,
            sleepSafetyDelta = ctx.runtimeSleepCalibration().sleepSafetyDelta,
            sleepSafetyLimit = ctx.runtimeSleepCalibration().sleepSafetyLimit,
            sleepSafetyOverrideReason = ctx.runtimeSleepCalibration().sleepSafetyOverrideReason,
            sleepCalibrationWarningReason = ctx.runtimeSleepCalibration().sleepCalibrationWarningReason,
            sleepCalibrationEvidenceReason = sleepCalibrationWarnings.evidenceReason(state.currentSleepSurfaceMode, {
                profile = state.currentProfile,
                slotName = state.currentSlotName,
                slotKey = state.currentSlotKey,
                objectId = state.currentObject and state.currentObject.recordId,
            }),
        })
    end

    function handlers.onSetSittingCalibration(data)
        data = data or {}
        local runtimeSittingCalibration = ctx.runtimeSittingCalibration()
        if data.x ~= nil then runtimeSittingCalibration.x = tonumber(data.x) or 0 end
        if data.y ~= nil then runtimeSittingCalibration.y = tonumber(data.y) or 0 end
        if data.z ~= nil then runtimeSittingCalibration.z = tonumber(data.z) or 0 end
        if data.yaw ~= nil then runtimeSittingCalibration.yaw = tonumber(data.yaw) or 0 end
        printSittingCalibration("set sitting calibration")
    end

    function handlers.onNudgeSittingCalibration(data)
        data = data or {}
        local cal = ctx.sittingCalibrationSnapshot()
        local runtimeSittingCalibration = ctx.runtimeSittingCalibration()
        runtimeSittingCalibration.x = cal.x + (tonumber(data.x) or 0)
        runtimeSittingCalibration.y = cal.y + (tonumber(data.y) or 0)
        runtimeSittingCalibration.z = cal.z + (tonumber(data.z) or 0)
        runtimeSittingCalibration.yaw = cal.yaw + (tonumber(data.yaw) or 0)
        if data.syncSlotZ ~= nil then runtimeSittingCalibration.syncSlotZ = data.syncSlotZ == true end
        if data.syncSlotXY ~= nil then runtimeSittingCalibration.syncSlotXY = data.syncSlotXY == true end
        if data.syncSlotYaw ~= nil then runtimeSittingCalibration.syncSlotYaw = data.syncSlotYaw == true end
        ctx.debugLog("sitting calibration nudge applied", tostring(data.reason or "menu_nudge"), "export", "suppressed")
        local state = ctx.state()
        if state.currentInteractionType == "sitting" and ctx.refreshCurrentSittingCalibration then
            ctx.refreshCurrentSittingCalibration(data.reason or "menu_nudge")
        end
    end

    function handlers.onResetSittingCalibration()
        ctx.setRuntimeSittingCalibration(calibrationPoseState.emptyOffset())
        local state = ctx.state()
        if state.currentInteractionType == "sitting" and ctx.refreshCurrentSittingCalibration then
            ctx.refreshCurrentSittingCalibration("menu_reset")
        end
        printSittingCalibration("reset sitting calibration to saved profile")
    end

    function handlers.printSleepCalibration(label)
        local runtimeSleepCalibration = ctx.runtimeSleepCalibration()
        print("[SitDownPlease]", tostring(label or "sleep calibration"),
            "x", tostring(tonumber(runtimeSleepCalibration.x) or 0),
            "y", tostring(tonumber(runtimeSleepCalibration.y) or 0),
            "z", tostring(tonumber(runtimeSleepCalibration.z) or 0),
            "yaw", tostring(tonumber(runtimeSleepCalibration.yaw) or 0)
        )
    end

    function handlers.onSetSleepCalibration(data)
        data = data or {}
        local runtimeSleepCalibration = ctx.runtimeSleepCalibration()
        if data.x ~= nil then runtimeSleepCalibration.x = tonumber(data.x) or 0 end
        if data.y ~= nil then runtimeSleepCalibration.y = tonumber(data.y) or 0 end
        if data.z ~= nil then runtimeSleepCalibration.z = tonumber(data.z) or 0 end
        if data.yaw ~= nil then runtimeSleepCalibration.yaw = tonumber(data.yaw) or 0 end
        handlers.printSleepCalibration("set sleep calibration")
    end

    function handlers.onNudgeSleepCalibration(data)
        data = data or {}
        local state = ctx.state()
        local targetObjectId = tostring(data.objectRecordId or data.objectId or "")
        local currentObjectId = state.currentObject and tostring(state.currentObject.recordId or "") or ""
        local targetSlotKey = tostring(data.slotKey or "")
        local currentSlotKey = tostring(state.currentSlotKey or "")
        if targetObjectId ~= "" and currentObjectId ~= "" and targetObjectId ~= currentObjectId then
            ctx.debugLog("sleep calibration nudge ignored", tostring(data.reason or "menu_nudge"), "reason", "target_object_mismatch", "expected", targetObjectId, "current", currentObjectId)
            return
        end
        if targetSlotKey ~= "" and currentSlotKey ~= "" and targetSlotKey ~= currentSlotKey then
            ctx.debugLog("sleep calibration nudge ignored", tostring(data.reason or "menu_nudge"), "reason", "target_slot_mismatch", "expected", targetSlotKey, "current", currentSlotKey)
            return
        end
        local runtimeSleepCalibration = ctx.runtimeSleepCalibration()
        runtimeSleepCalibration.x = (tonumber(runtimeSleepCalibration.x) or 0) + (tonumber(data.x) or 0)
        runtimeSleepCalibration.y = (tonumber(runtimeSleepCalibration.y) or 0) + (tonumber(data.y) or 0)
        runtimeSleepCalibration.z = (tonumber(runtimeSleepCalibration.z) or 0) + (tonumber(data.z) or 0)
        runtimeSleepCalibration.yaw = (tonumber(runtimeSleepCalibration.yaw) or 0) + (tonumber(data.yaw) or 0)
        if data.syncSlotZ ~= nil then runtimeSleepCalibration.syncSlotZ = data.syncSlotZ == true end
        if data.syncSlotXY ~= nil then runtimeSleepCalibration.syncSlotXY = data.syncSlotXY == true end
        if data.syncSlotYaw ~= nil then runtimeSleepCalibration.syncSlotYaw = data.syncSlotYaw == true end
        ctx.debugLog("sleep calibration nudge applied", tostring(data.reason or "menu_nudge"), "export", "suppressed")
        if state.currentInteractionType == "sleeping" and ctx.refreshCurrentSleepCalibration then
            ctx.refreshCurrentSleepCalibration(data.reason or "menu_nudge", true)
        end
    end

    function handlers.onResetSleepCalibration(data)
        data = data or {}
        local state = ctx.state()
        local targetObjectId = tostring(data.objectRecordId or data.objectId or "")
        local currentObjectId = state.currentObject and tostring(state.currentObject.recordId or "") or ""
        local targetSlotKey = tostring(data.slotKey or "")
        local currentSlotKey = tostring(state.currentSlotKey or "")
        if targetObjectId ~= "" and currentObjectId ~= "" and targetObjectId ~= currentObjectId then
            ctx.debugLog("sleep calibration reset ignored", tostring(data.reason or "menu_reset"), "reason", "target_object_mismatch", "expected", targetObjectId, "current", currentObjectId)
            return
        end
        if targetSlotKey ~= "" and currentSlotKey ~= "" and targetSlotKey ~= currentSlotKey then
            ctx.debugLog("sleep calibration reset ignored", tostring(data.reason or "menu_reset"), "reason", "target_slot_mismatch", "expected", targetSlotKey, "current", currentSlotKey)
            return
        end
        ctx.setRuntimeSleepCalibration(calibrationPoseState.emptyOffset())
        if state.currentInteractionType == "sleeping" and ctx.refreshCurrentSleepCalibration then
            ctx.refreshCurrentSleepCalibration("menu_reset")
        else
            handlers.printSleepCalibration("reset sleep calibration to saved profile")
        end
    end

    function handlers.onSleepCalibrationSettingsChanged(data)
        ctx.setRuntimeSleepCalibration(calibrationPoseState.emptyOffset())
        local state = ctx.state()
        if state.isInteracting and state.currentInteractionType == "sleeping" then
            ctx.refreshCurrentSleepCalibration(data and data.reason or "settings")
        end
    end

    function handlers.onReapplyLockedCalibration(data)
        local state = ctx.state()
        local requestedType = data and data.interactionType
        if requestedType ~= state.currentInteractionType then
            print("[SitDownPlease]", "calibration action failed", "reason", "unsupported_or_mismatched_interaction_type", "requested", tostring(requestedType), "current", tostring(state.currentInteractionType))
            return
        end
        if data and data.slotKey and state.currentSlotKey and data.slotKey ~= state.currentSlotKey then
            print("[SitDownPlease]", "calibration action failed", "reason", "slot_invalid", "expected", tostring(data.slotKey), "current", tostring(state.currentSlotKey))
            return
        end
        if state.currentInteractionType == "sitting" then
            if ctx.refreshCurrentSittingCalibration(data and data.reason or "locked_calibration") then
                if ctx.replayCurrentAnimation then
                    ctx.replayCurrentAnimation(data and data.reason or "locked_calibration")
                end
                printSittingCalibration("sitting calibration reapplied")
            else
                print("[SitDownPlease]", "sitting calibration action failed", "reason", "no_current_calibration_target")
            end
        elseif state.currentInteractionType == "sleeping" then
            if ctx.refreshCurrentSleepCalibration(data and data.reason or "locked_calibration") then
                if ctx.replayCurrentAnimation then
                    ctx.replayCurrentAnimation(data and data.reason or "locked_calibration")
                end
            end
        else
            print("[SitDownPlease]", "calibration action failed", "reason", "unsupported_interaction_type")
        end
    end

    function handlers.onDebugGoToBed()
        local actor = ctx.actor()
        print("[SitDownPlease]", "console command", "SitDownPleaseGoToBed", tostring(actor.recordId or actor.id))
        ctx.core.sendGlobalEvent('SitDownPleaseGoToBed', {
            npc = actor,
            actor = actor,
            source = "selected_npc_console",
        })
    end

    return {
        handlers = handlers,
        printSittingCalibration = printSittingCalibration,
        printSleepCalibrationDetails = printSleepCalibrationDetails,
    }
end

return M
