-- assignment/candidateBuilder.lua
---@omw-context none
-- Builds interaction candidates from cell furniture. The global entrypoint
-- supplies OpenMW context and mutable runtime ledgers; this module owns the
-- scan/filter/slot-construction policy.

local M = {}
local scanCadence = require('scripts/sitDownPlease/assignment/scanCadence')

local function settingsFrom(ctx)
    if type(ctx.settings) == "function" then return ctx.settings() end
    return ctx.settings or {}
end

local function relevantCache(ctx)
    if type(ctx.relevantObjectCache) == "function" then return ctx.relevantObjectCache() end
    return ctx.relevantObjectCache
end

local function claimRejectCache(ctx)
    if type(ctx.claimRejectLogCache) == "function" then return ctx.claimRejectLogCache() end
    return ctx.claimRejectLogCache
end

local function occupiedSlots(ctx)
    if type(ctx.occupiedSlots) == "function" then return ctx.occupiedSlots() end
    return ctx.occupiedSlots
end

local function assignedActors(ctx)
    if type(ctx.assignedActors) == "function" then return ctx.assignedActors() end
    return ctx.assignedActors
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function relevantCacheKey(ctx, cell, interactionType)
    return ctx.cellContext.cellInteractionCacheKey(cell, interactionType)
end

local function collectRelevantObjects(ctx, cell, interactionType, options)
    local profiles = ctx.profiles
    local settings = settingsFrom(ctx)
    local key = relevantCacheKey(ctx, cell, interactionType)
    local cache = (options and options.exteriorNearbyOnly == true) and nil or relevantCache(ctx)
    local cached = cache and cache[key] or nil
    if cached then
        if settings.debug == true then
            ctx.debugLog(
                "relevant object cache hit", interactionType,
                "cell", tostring(ctx.cellName(cell)),
                "relevant", tostring(#cached.objects),
                "scanned", tostring(cached.scannedCount),
                "irrelevant", tostring(cached.irrelevantCount)
            )
        end
        return cached.objects, cached.allObjects or cached.objects, cached.scannedCount, cached.relevantCount, cached.irrelevantCount, true
    end

    local allObjects = {}
    local objects = {}
    local scannedCount = 0
    local relevantCount = 0

    for _, obj in ipairs(cell:getAll()) do
        scannedCount = scannedCount + 1
        local withinExteriorBudget = scanCadence.objectWithinExteriorPolicy(obj, options, 90)
        if withinExteriorBudget then allObjects[#allObjects + 1] = obj end
        local isRelevant = withinExteriorBudget
        if isRelevant and profiles.objectLooksRelevantForInteraction then
            isRelevant = profiles.objectLooksRelevantForInteraction(obj, interactionType, settings) == true
        end
        if not isRelevant and settings.verboseDebug == true then
            if interactionType == "sleeping" and profiles.sleepFallbackCandidateStatus then
                local ok, reason = profiles.sleepFallbackCandidateStatus(obj)
                if ok ~= true and reason and reason ~= "non_sleep_object" then
                    local objectId = tostring(obj and (obj.recordId or obj.id))
                    local message = "sleep candidate rejected non_sleep_object"
                    if reason == "clothing" then message = "sleep candidate rejected clothing" end
                    ctx.debugLogOnce(
                        claimRejectCache(ctx),
                        "sleep_nonbed|" .. objectId .. "|" .. tostring(reason),
                        message,
                        "object", objectId,
                        "model", tostring(profiles.objectModelPath(obj)),
                        "reason", tostring(reason)
                    )
                end
            elseif interactionType == "sitting" and profiles.sittingFallbackCandidateStatus then
                local ok, reason = profiles.sittingFallbackCandidateStatus(obj, settings)
                if ok ~= true and reason == "prayer_stool_normal_sitting_not_supported" then
                    local objectId = tostring(obj and (obj.recordId or obj.id))
                    ctx.debugLogOnce(
                        claimRejectCache(ctx),
                        "sitting_prayer_stool|" .. objectId,
                        "prayer stool rejected normal_sitting_not_supported",
                        "object", objectId,
                        "model", tostring(profiles.objectModelPath(obj))
                    )
                end
            end
        end
        if isRelevant then
            relevantCount = relevantCount + 1
            objects[#objects + 1] = obj
        end
    end

    local irrelevantCount = scannedCount - relevantCount
    if cache then
        cache[key] = {
            objects = objects,
            allObjects = allObjects,
            scannedCount = scannedCount,
            relevantCount = relevantCount,
            irrelevantCount = irrelevantCount,
        }
    end

    return objects, allObjects, scannedCount, relevantCount, irrelevantCount, false
end

local function sleepSlotReferencePosition(ctx, obj, profile, slot)
    local function horizontalVector(offset)
        if not offset then return nil end
        local pos = ctx.objectLocalOffset(obj, { x = offset.x or 0, y = offset.y or 0, z = 0 })
        if not (pos and obj and obj.position) then return nil end
        local delta = pos - obj.position
        return { x = delta.x or 0, y = delta.y or 0, z = 0 }
    end

    local function yawOf(object)
        if not (object and object.rotation) then return 0 end
        local ok, yaw = pcall(function() return object.rotation:getYaw() end)
        if ok and yaw then return yaw end
        return 0
    end

    local function lateralVector(yaw, amount)
        amount = tonumber(amount) or 0
        if amount == 0 then return nil end
        yaw = tonumber(yaw) or 0
        return { x = math.cos(yaw) * amount, y = -math.sin(yaw) * amount, z = 0 }
    end

    local rootOffset = slot and slot.sleepRootLocalOffset or profile and profile.sleepRootLocalOffset or nil
    local sleepOffset = slot and slot.sleepOffset or profile and profile.sleepOffset or nil
    local sleepVector = horizontalVector(sleepOffset) or { x = 0, y = 0, z = 0 }
    local rootVector = horizontalVector(rootOffset) or { x = 0, y = 0, z = 0 }
    local poseYawOffset = slot and slot.sleepPoseYawOffset or profile and profile.sleepPoseYawOffset or 0
    local rotationOffset = slot and slot.rotationOffset or profile and profile.rotationOffset or 0
    local finalYaw = yawOf(obj) + (tonumber(rotationOffset) or 0) + (tonumber(poseYawOffset) or 0)
    local lateral = lateralVector(finalYaw, slot and slot.sleepLateralOffset or profile and profile.sleepLateralOffset) or { x = 0, y = 0, z = 0 }
    local x = sleepVector.x + rootVector.x + lateral.x
    local y = sleepVector.y + rootVector.y + lateral.y
    if x ~= 0 or y ~= 0 then
        local base = obj.position
        return base + ctx.util.vector3(x, y, 0), "sleep_final_xy"
    end
    return obj.position, "object_origin"
end

function M.build(ctx, cell, interactionType, options)
    options = options or {}
    local profiles = ctx.profiles
    local settings = settingsFrom(ctx)
    local candidates = {}
    local currentHour = profiles.getGameHour()
    local rejectedCount = 0
    local relevantObjects, allObjects, scannedCount, relevantCount, irrelevantCount, cacheHit = collectRelevantObjects(ctx, cell, interactionType, options)

    for _, obj in ipairs(relevantObjects or {}) do
        if ctx.isObjValid(obj) then
            local overturned = interactionType == "sitting" and ctx.seatObjectLooksOverturned(obj)
            local profile, reason = nil, nil
            if overturned then
                reason = "sitting_object_not_upright"
            else
                profile, reason = profiles.getProfileForObject(obj, interactionType, settings)
            end
            if profile then
                local releaseGateSeatCategory = interactionType == "sitting"
                    and profiles.sittingSeatCategory
                    and profiles.sittingSeatCategory(profile, obj)
                    or nil
                local releaseGateOk, releaseGateReason, releaseGatePolicy = ctx.releaseSafetyGate.candidateAllowed(settings, cell, interactionType, profile, obj, {
                    seatCategory = releaseGateSeatCategory,
                    calibrationAction = options.calibrationAction,
                    manualAssign = options.manualAssign,
                    calibrationFill = options.calibrationFill,
                    testingOverride = options.testingOverride,
                    debugForce = options.debugForce,
                    targetedManual = options.targetedManual,
                    externalCompatibilityAssist = options.externalCompatibilityAssist,
                })
                if releaseGateOk then
                    local timeOk, timeReason = true, nil
                    if options.ignoreTimeGate ~= true then
                        timeOk, timeReason = profiles.isInteractionAllowedByTime(interactionType, profile, settings, currentHour)
                    end
                    if timeOk then
                        local model = profiles.objectModelPath(obj)
                        local slots = profile.slots or { { name = "default" } }

                        for i, slot in ipairs(slots) do
                            local slotName = profiles.slotName(slot, i)
                            local slotKey = ctx.objectSlotKey(obj, slotName)
                            local slotOwnerId, slotOwnerData, slotOwnerSource = ctx.slotOwnership.ownerFor(slotKey, occupiedSlots(ctx), assignedActors(ctx))
                            local occupiedByTestNpc, testNpcData = ctx.assignmentEligibility.slotOccupiedByTestNpc(occupiedSlots(ctx), assignedActors(ctx), slotKey)
                            local occupiedAllowed = options.allowOccupiedSlots == true
                                or (options.allowOccupiedByTestNpc == true and occupiedByTestNpc == true)
                            if not slotOwnerId or occupiedAllowed then
                                local approachPos = nil
                                if interactionType ~= "sleeping" then
                                    approachPos = ctx.objectLocalOffset(obj, slot.approachOffset or (profile.approachOffsets and profile.approachOffsets[1]))
                                end
                                local seatPos = nil
                                if interactionType == "sitting" then
                                    seatPos = ctx.sittingCandidateSeatPosition(obj, profile, slot, i)
                                end
                                local surfaceBlocker = nil
                                local surfaceBlockerDistance = nil
                                local surfaceBlockerVertical = nil
                                local surfaceBlockerLocalReason = nil
                                local surfaceBlockerKind = nil
                                if interactionType == "sitting" and seatPos and ctx.sittingSeatSurfaceBlocker then
                                    surfaceBlocker, surfaceBlockerDistance, surfaceBlockerVertical, surfaceBlockerLocalReason, surfaceBlockerKind = ctx.sittingSeatSurfaceBlocker(cell, seatPos, profile, obj, allObjects)
                                end
                                local sleepSlotPos = nil
                                local sleepSlotReference = nil
                                if interactionType == "sleeping" then
                                    sleepSlotPos, sleepSlotReference = sleepSlotReferencePosition(ctx, obj, profile, slot)
                                end
                                local preferredFacingDirection = nil
                                local facingObject = nil
                                local facingKind = nil
                                local facingCandidates = nil
                                if interactionType == "sitting" then
                                    local seatCategory = string.lower(tostring(profile.seatCategory or profile.type or ""))
                                    local rotationMode = string.lower(tostring(profile.rotationMode or ""))
                                    if options and options.exteriorNearbyOnly == true then
                                        options.focusObjects = allObjects
                                    end
                                    preferredFacingDirection, facingObject, facingKind, facingCandidates = ctx.findNearestSittingFocusDirection(cell, seatPos or obj.position, obj, profile, options)
                                    if seatCategory:find("bench", 1, true) and rotationMode == "faceopenside" and facingKind and settings.verboseDebug == true and settings.debug == true then
                                        ctx.verboseInfoLog(
                                            "bench open-side profile received focus",
                                            "object", tostring(obj and obj.recordId),
                                            "slot", tostring(slotName),
                                            "focus", tostring(facingKind),
                                            "focusObject", tostring(facingObject and (facingObject.recordId or facingObject.id))
                                        )
                                    end
                                end

                                local candidateData = {
                                    object = obj,
                                    objectId = obj.recordId,
                                    model = model,
                                    profile = profile,
                                    profileId = profile.profileId,
                                    profileSelectionTrace = profile.profileSelectionTrace,
                                    profileSelectionSource = profile.profileSelectionSource,
                                    profileSelectionReason = profile.profileSelectionReason,
                                    profileSelectionKey = profile.profileSelectionKey,
                                    interactionType = interactionType,
                                    slot = slot,
                                    slotName = slotName,
                                    slotKey = slotKey,
                                    slotOwnerId = slotOwnerId,
                                    slotOwnerData = slotOwnerData,
                                    slotOwnerSource = slotOwnerSource,
                                    occupiedByAnyActor = slotOwnerId ~= nil,
                                    occupiedByTestNpc = occupiedByTestNpc == true,
                                    occupiedByTestNpcActor = testNpcData and testNpcData.npc or nil,
                                    occupiedByTestNpcInteractionType = testNpcData and testNpcData.interactionType or nil,
                                    position = sleepSlotPos or seatPos,
                                    sleepSlotReference = sleepSlotReference,
                                    approachPos = approachPos,
                                    preferredFacingDirection = preferredFacingDirection,
                                    facingObject = facingObject,
                                    facingObjectId = facingObject and facingObject.recordId or nil,
                                    facingObjectRefId = facingObject and facingObject.id or nil,
                                    facingObjectModel = facingObject and profiles.objectModelPath(facingObject) or nil,
                                    facingObjectName = facingObject and ctx.objectNameForFocus(facingObject) or nil,
                                    facingObjectScale = facingObject and facingObject.scale or nil,
                                    facingObjectContentFile = facingObject and facingObject.contentFile or nil,
                                    facingKind = facingKind,
                                    facingObjectPosition = facingObject and facingObject.position or nil,
                                    facingObjectDistance = facingObject and flatDistance(facingObject.position, seatPos or obj.position) or nil,
                                    facingCandidates = facingCandidates,
                                    fallbackUsed = reason == "fallback_profile",
                                    currentHour = currentHour,
                                    releaseSafetyGateEnabled = releaseGatePolicy and releaseGatePolicy.enabled == true,
                                    releaseSafetyGateStatus = releaseGatePolicy and releaseGatePolicy.status or nil,
                                    releaseSafetyGateReason = releaseGatePolicy and releaseGatePolicy.reason or releaseGateReason,
                                    releaseSafetyGateCell = releaseGatePolicy and releaseGatePolicy.cellName or nil,
                                    releaseSafetyGateRegion = releaseGatePolicy and releaseGatePolicy.regionName or nil,
                                    releaseSafetyGateFurnitureType = releaseGatePolicy and releaseGatePolicy.furnitureType or releaseGateSeatCategory,
                                    releaseSafetyGateLabel = ctx.releaseSafetyGate.visibleLabel and ctx.releaseSafetyGate.visibleLabel(releaseGatePolicy) or nil,
                                    surfaceBlockerReason = surfaceBlocker and "seat_surface_blocked_by_item" or nil,
                                    surfaceBlockerKind = surfaceBlocker and tostring(surfaceBlockerKind or "seat_surface_blocked_by_item") or nil,
                                    surfaceBlockerObjectId = surfaceBlocker and tostring(surfaceBlocker.recordId or surfaceBlocker.id) or nil,
                                    surfaceBlockerDistance = surfaceBlockerDistance,
                                    surfaceBlockerVertical = surfaceBlockerVertical,
                                    surfaceBlockerLocalReason = surfaceBlockerLocalReason,
                                    softBlockerReason = surfaceBlocker and tostring(surfaceBlockerKind or "seat_surface_blocked_by_item") or nil,
                                }
                                local externallyClaimed, externalReason, externalActor = ctx.externalClaimForCandidate(cell, candidateData, nil)
                                if externallyClaimed == true then
                                    candidateData.externalPhysicalClaimed = true
                                    candidateData.externalPhysicalClaimReason = externalReason or "external_furniture_claimed"
                                    candidateData.externalPhysicalClaimActor = externalActor
                                    candidateData.externalPhysicalClaimActorRecordId = externalActor and externalActor.recordId or nil
                                    candidateData.externalPhysicalClaimActorId = externalActor and externalActor.id or nil
                                    candidateData.hardBlockerReason = "external_furniture_claimed"
                                end
                                table.insert(candidates, candidateData)
                                if interactionType == "sleeping" and reason == "fallback_profile" and settings.debug == true then
                                    ctx.debugLog("fallback_sleeping accepted bedlike_candidate", tostring(obj.recordId or obj.id), "model", tostring(model), "reason", tostring(profile.fallbackSleepCandidateReason))
                                end
                            elseif settings.debug then
                                rejectedCount = rejectedCount + 1
                                ctx.debugLog("reject object occupied", interactionType, profiles.objectDebugId(obj), slotKey)
                            end
                        end
                    else
                        rejectedCount = rejectedCount + 1
                        ctx.debugLog("reject by time", interactionType, profiles.objectDebugId(obj), timeReason, "hour", tostring(currentHour))
                    end
                else
                    rejectedCount = rejectedCount + 1
                    ctx.debugLog(
                        "reject by release safety gate",
                        interactionType,
                        profiles.objectDebugId(obj),
                        tostring(releaseGateReason),
                        "cell", tostring(ctx.cellName(cell)),
                        "region", tostring(releaseGatePolicy and releaseGatePolicy.regionName),
                        "category", tostring(releaseGateSeatCategory)
                    )
                end
            elseif settings.debug and reason ~= "profile_for_different_interaction" then
                rejectedCount = rejectedCount + 1
                local model = profiles.objectModelPath(obj)
                ctx.debugLog("reject relevant object", interactionType, profiles.objectDebugId(obj), reason, "model", tostring(model))
            end
        end
    end

    ctx.debugLog(
        "candidate scan", interactionType,
        "scanned", tostring(scannedCount or 0),
        "relevant", tostring(relevantCount or 0),
        "irrelevant", tostring(irrelevantCount or 0),
        "candidates", tostring(#candidates),
        "rejectedRelevant", tostring(rejectedCount),
        "cache", cacheHit and "hit" or "miss"
    )

    return candidates
end

return M
