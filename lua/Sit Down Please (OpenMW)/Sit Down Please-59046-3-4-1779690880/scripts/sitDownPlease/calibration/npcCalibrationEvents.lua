-- Calibration event handlers for the NPC-local interaction script.
-- Kept outside interactionSeeker.lua so the entrypoint stays below OpenMW Lua's
-- 200-local main chunk limit.

local calibrationExport = require('scripts/sitDownPlease/calibration/exportRows')
local calibrationMetadata = require('scripts/sitDownPlease/calibration/metadata')
local calibrationPoseState = require('scripts/sitDownPlease/calibration/poseState')

local M = {}

local function offsetText(offset)
    offset = offset or {}
    return tostring(offset.x or 0) .. "," .. tostring(offset.y or 0) .. "," .. tostring(offset.z or 0) .. ",yaw=" .. tostring(offset.yaw or 0)
end

function M.bind(ctx)
    local handlers = {}

    local function printSittingCalibration(label)
        local sequence = ctx.nextCalibrationExportSequence()
        local state = ctx.state()
        local cal = ctx.sittingCalibrationSnapshot()
        local activity = state.currentSittingPoseActivity or "standard"
        local animation = state.currentSittingPoseAnimation or state.currentAnimation or "<none>"
        local profileOffset = state.currentSittingAppliedProfileOffset or ctx.sittingProfileOffsetFor(state.currentProfile, activity, animation)
        local animationOffset = state.currentSittingAppliedAnimationOffset or ctx.sittingAnimationNormalizationFor(animation, state.currentProfile)
        local row = calibrationExport.sittingProfileExportRow(state.currentProfile, state.currentObject, state.profiles, profileOffset, cal)
        local variantRow = calibrationExport.chairOrientationProfileRow(state.currentProfile, state.currentObject, state.profiles, profileOffset, cal, state.currentSlotName or state.currentSlotKey or "default")
        local runtimeSittingCalibration = ctx.runtimeSittingCalibration()
        local classification = calibrationExport.sittingPromotionClassification(state.currentProfile, state.currentObject, profileOffset, cal, {
            facingKind = runtimeSittingCalibration.facingKind,
            manualOverride = runtimeSittingCalibration.manualAssignOverrideApplied == true,
        })
        local promotionHint = classification.hint
        if classification.rowDiffers == true and animation and animation ~= "" and animation ~= "<none>" then
            promotionHint = "review_animation_or_context_before_promote"
        end

        print("[SitDownPlease]", tostring(label or "seat calibration"),
            "seat", tostring(state.currentObject and state.currentObject.recordId or "<none>"),
            "profileOffset", offsetText(profileOffset),
            "animationOffset", offsetText(animationOffset),
            "currentChanges", offsetText(cal),
            "copyRow", row
        )
        print("[SitDownPlease Calibration Export]",
            "export_sequence", tostring(sequence),
            "currently_loaded_profile_key", tostring(state.currentProfile and state.currentProfile.profileId),
            "loaded_profile_offset", offsetText(profileOffset),
            "animation", tostring(animation),
            "animation_normalization_offset", offsetText(animationOffset),
            "row_differs_from_loaded_profile", tostring(classification.rowDiffers == true),
            "promotion_hint", tostring(promotionHint),
            "classification", tostring(classification.label),
            "reason", tostring(classification.reason)
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
            "surface", tostring(snap.surfaceMode),
            "surfaceSamples", tostring(snap.surfaceSamples),
            "manualOverride", tostring(runtimeSittingCalibration.manualAssignOverrideApplied == true),
            "manualOverrideReason", tostring(runtimeSittingCalibration.manualAssignOverrideReason)
        )
        print("[SitDownPlease Calibration Export]", tostring(classification.label), "seat", tostring(state.currentObject and state.currentObject.recordId), "profile", tostring(state.currentProfile and state.currentProfile.profileId), "reason", tostring(classification.reason))
        if classification.conflict == true then
            print("[SitDownPlease Calibration Export]", "chair calibration conflicts with existing profile", "seat", tostring(state.currentObject and state.currentObject.recordId), "profile", tostring(state.currentProfile and state.currentProfile.profileId))
        end
        print("[SitDownPlease Calibration Export]", "FILE", "sdp_furnitureProfiles/chairProfiles.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
        print("[SitDownPlease Calibration Export]", "ROW", row)
        print("[SitDownPlease Calibration Export]", "FILE", "sdp_furnitureProfiles/chairProfileVariants.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
        print("[SitDownPlease Calibration Export]", "CHAIR_ORIENTATION_ROW", variantRow)

        if classification.rowDiffers == true and animation and animation ~= "" and animation ~= "<none>" then
            local buckets = state.profiles.objectYawBuckets and state.profiles.objectYawBuckets(state.currentObject) or {}
            local normalizationRow = calibrationExport.animationNormalizationRow({
                interactionType = "sitting",
                animation = animation,
                object = state.currentObject,
                profiles = state.profiles,
                profileId = state.currentProfile and state.currentProfile.profileId or "",
                slotName = state.currentSlotName or state.currentSlotKey or "default",
                yawBucket90 = buckets and buckets.yawBucket90 or "",
                baseOffset = animationOffset,
                delta = cal,
                notes = "Scoped sitting animation normalization candidate from calibration export; promote only if the furniture profile is correct for other sitting animations.",
            })
            print("[SitDownPlease Calibration Export]", "FILE", "sdp_furnitureProfiles/animationNormalizationOffsets.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId))
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
        })
    end

    local function printSleepCalibrationDetails(label, reason)
        local sequence = ctx.nextCalibrationExportSequence()
        local state = ctx.state()
        local rowDiffers = calibrationExport.offsetDiffers(state.currentSleepProfileRootOffset, state.currentSleepMergedRootOffset, 0.5)
        local promotionHint = calibrationExport.sleepPromotionHint(state.currentProfile, rowDiffers)
        if rowDiffers and state.currentAnimation then promotionHint = "review_animation_normalization_first" end
        local profileSource = calibrationExport.sleepProfileSource(state.currentProfile)
        local recommendedFile = (rowDiffers and state.currentAnimation) and "sdp_furnitureProfiles/animationNormalizationOffsets.txt" or "sdp_furnitureProfiles/bedProfiles.txt"

        print("[SitDownPlease]", tostring(label or "sleep calibration"),
            "reason", tostring(reason or "calibration"),
            "actor", tostring(ctx.actor() and (ctx.actor().recordId or ctx.actor().id)),
            "object", tostring(state.currentObject and state.currentObject.recordId),
            "model", tostring(state.currentObject and state.profiles.objectModelPath(state.currentObject)),
            "profile", tostring(state.currentProfile and state.currentProfile.profileId),
            "category", tostring(state.currentProfile and (state.currentProfile.bedType or state.currentProfile.type)),
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
            "currently_loaded_profile_key", tostring(state.currentProfile and state.currentProfile.profileId),
            "loaded_profile_offset", calibrationExport.offsetLabel(state.currentSleepProfileRootOffset),
            "row_differs_from_loaded_profile", tostring(rowDiffers),
            "promotion_hint", tostring(promotionHint),
            "recommended_file", tostring(recommendedFile)
        )
        if profileSource ~= "explicit_profile" and profileSource ~= "explicit_profile_orientation_variant" then
            print("[SitDownPlease Calibration Export]",
                "profile_missing_despite_recent_calibration_export",
                "recordId", tostring(state.currentObject and state.currentObject.recordId),
                "profile", tostring(state.currentProfile and state.currentProfile.profileId),
                "profileSource", tostring(profileSource)
            )
        end
        print("[SitDownPlease Calibration Export]", "SLOT_IDENTITY", "recordId", tostring(state.currentObject and state.currentObject.recordId), "slot", tostring(state.currentSlotName or state.currentSlotKey), "bedType", tostring(state.currentProfile and (state.currentProfile.bedType or state.currentProfile.type)))
        if state.currentProfile and (state.currentProfile.bedType == "double" or (state.currentProfile.slots and #state.currentProfile.slots > 1)) and state.currentSleepMergedRootOffset then
            print("[SitDownPlease Calibration Export]", "MIRRORED_SLOT_SUGGESTION_NOT_FINAL", "sourceSlot", tostring(state.currentSlotName or state.currentSlotKey), "suggestedOffset", calibrationExport.offsetLabel({ x = -(tonumber(state.currentSleepMergedRootOffset.x) or 0), y = tonumber(state.currentSleepMergedRootOffset.y) or 0, z = tonumber(state.currentSleepMergedRootOffset.z) or 0 }))
        end
        print("[SitDownPlease Calibration Export]", "FILE", "sdp_furnitureProfiles/bedProfiles.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId), "SLOT", tostring(state.currentSlotName or state.currentSlotKey))
        print("[SitDownPlease Calibration Export]", "ROW", calibrationExport.bedProfileCopyRow({
            profile = state.currentProfile,
            object = state.currentObject,
            profiles = state.profiles,
            mergedRootOffset = state.currentSleepMergedRootOffset,
            poseYawOffset = state.currentSleepPoseYawOffset,
            slotName = state.currentSlotName,
        }))

        local buckets = state.profiles.objectYawBuckets and state.profiles.objectYawBuckets(state.currentObject) or {}
        print("[SitDownPlease Calibration Export]", "ORIENTATION_ROW", calibrationExport.bedOrientationProfileRow({
            profile = state.currentProfile,
            object = state.currentObject,
            profiles = state.profiles,
            mergedRootOffset = state.currentSleepMergedRootOffset,
            poseYawOffset = state.currentSleepPoseYawOffset,
            slotName = state.currentSlotName,
        }))
        if rowDiffers and state.currentAnimation then
            print("[SitDownPlease Calibration Export]", "FILE", "sdp_furnitureProfiles/animationNormalizationOffsets.txt", "TARGET", tostring(state.currentObject and state.currentObject.recordId), "PROFILE", tostring(state.currentProfile and state.currentProfile.profileId), "SLOT", tostring(state.currentSlotName or state.currentSlotKey))
            print("[SitDownPlease Calibration Export]", "ANIMATION_NORMALIZATION_ROW", calibrationExport.animationNormalizationRow({
                interactionType = "sleeping",
                animation = state.currentAnimation,
                object = state.currentObject,
                profiles = state.profiles,
                profileId = state.currentProfile and state.currentProfile.profileId,
                slotName = state.currentSlotName or state.currentSlotKey,
                yawBucket90 = buckets.yawBucket90,
                baseOffset = state.currentSleepAnimationNormalizationOffset,
                delta = {
                    x = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.x or 0,
                    y = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.y or 0,
                    z = state.currentSleepCalibrationOffset and state.currentSleepCalibrationOffset.z or 0,
                    yaw = state.currentSleepCalibrationYawDegrees or 0,
                },
            }))
        end
        print("[SitDownPlease Calibration Export]", "ORIENTATION_METADATA",
            "objectYawRad", tostring(buckets.objectYawRad),
            "objectYawDeg", tostring(calibrationExport.shortNumber(buckets.objectYawDeg or 0)),
            "yawBucket45", tostring(buckets.yawBucket45),
            "yawBucket90", tostring(buckets.yawBucket90),
            "profileSource", tostring(profileSource),
            "recordId", tostring(state.currentObject and state.currentObject.recordId),
            "model", tostring(state.currentObject and state.profiles.objectModelPath(state.currentObject)),
            "profileId", tostring(state.currentProfile and state.currentProfile.profileId),
            "slot", tostring(state.currentSlotName or state.currentSlotKey),
            "bedType", tostring(state.currentProfile and (state.currentProfile.bedType or state.currentProfile.type)),
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
        local runtimeSleepCalibration = ctx.runtimeSleepCalibration()
        runtimeSleepCalibration.x = (tonumber(runtimeSleepCalibration.x) or 0) + (tonumber(data.x) or 0)
        runtimeSleepCalibration.y = (tonumber(runtimeSleepCalibration.y) or 0) + (tonumber(data.y) or 0)
        runtimeSleepCalibration.z = (tonumber(runtimeSleepCalibration.z) or 0) + (tonumber(data.z) or 0)
        runtimeSleepCalibration.yaw = (tonumber(runtimeSleepCalibration.yaw) or 0) + (tonumber(data.yaw) or 0)
        ctx.debugLog("sleep calibration nudge applied", tostring(data.reason or "menu_nudge"), "export", "suppressed")
        local state = ctx.state()
        if state.currentInteractionType == "sleeping" and ctx.refreshCurrentSleepCalibration then
            ctx.refreshCurrentSleepCalibration(data.reason or "menu_nudge", true)
        end
    end

    function handlers.onResetSleepCalibration()
        ctx.setRuntimeSleepCalibration(calibrationPoseState.emptyOffset())
        local state = ctx.state()
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
                printSittingCalibration("sitting calibration reapplied")
            else
                print("[SitDownPlease]", "sitting calibration action failed", "reason", "no_current_calibration_target")
            end
        elseif state.currentInteractionType == "sleeping" then
            ctx.refreshCurrentSleepCalibration(data and data.reason or "locked_calibration")
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
