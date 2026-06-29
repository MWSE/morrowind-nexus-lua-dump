-- interactionSeeker.lua
---@omw-context local
---@diagnostic disable: assign-type-mismatch, undefined-field, need-check-nil, cast-local-type
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local async = require('openmw.async')
local ai = I.AI
local types = require('openmw.types')
local profiles = require('scripts/sitDownPlease/profiles/catalog')
calibrationExport = require('scripts/sitDownPlease/calibration/exportRows')
seatingClearance = require('scripts/sitDownPlease/interactions/sitting/clearance')
seatingClutterBlockers = require('scripts/sitDownPlease/interactions/sitting/clutterBlockers')
interactionAnimation = require('scripts/sitDownPlease/animation/playback')
sleepRoutePlanner = require('scripts/sitDownPlease/interactions/sleeping/routePlanner')
sdpSleepInitialRejectRescuePoint = require('scripts/sitDownPlease/interactions/sleeping/initialRejectRescuePoint')
sdpSleepApproachBarrier = require('scripts/sitDownPlease/interactions/sleeping/approachBarrier')
routeAssist = require('scripts/sitDownPlease/assignment/routeAssist')
sleepSurfacePolicy = require('scripts/sitDownPlease/interactions/sleeping/surfacePolicy')
sleepSurfaceClutter = require('scripts/sitDownPlease/interactions/sleeping/surfaceClutter')
sdpSleepFinalSafety = require('scripts/sitDownPlease/interactions/sleeping/finalSafety')
sittingPosePlanner = require('scripts/sitDownPlease/interactions/sitting/posePlanner')
sittingOffsetResolver = require('scripts/sitDownPlease/interactions/sitting/offsetResolver')
calibrationPoseState = require('scripts/sitDownPlease/calibration/poseState')
npcCalibrationEvents = require('scripts/sitDownPlease/calibration/npcCalibrationEvents')
externalAiTakeover = require('scripts/sitDownPlease/compatibility/externalAiTakeover')
sdpProceduralChatterCompat = require('scripts/sitDownPlease/compatibility/proceduralChatter')
sdpAiSuppression = require('scripts/sitDownPlease/assignment/aiSuppression')
sdpSittingFacingRefiner = require('scripts/sitDownPlease/interactions/sitting/facingRefiner')
sdpSittingBenchSlots = require('scripts/sitDownPlease/interactions/sitting/benchSlots')
sdpSittingStandExit = require('scripts/sitDownPlease/interactions/sitting/standExit')
sdpSurfaceSampler = require('scripts/sitDownPlease/world/surfaceSampler')
sdpAnimatedMorrowindSeekerModule = require('scripts/sitDownPlease/compatibility/animatedMorrowindSeeker')
sdpScriptedAnimationCompat = require('scripts/sitDownPlease/compatibility/scriptedAnimations')
sdpManualAssignment = require('scripts/sitDownPlease/assignment/manualAssignment')
sdpQuestSafety = require('scripts/sitDownPlease/compatibility/questSafety')
sdpActorRoles = require('scripts/sitDownPlease/assignment/actorRoles')
sdpServicePolicy = require('scripts/sitDownPlease/assignment/servicePolicy')
sdpLectureAnimation = require('scripts/sitDownPlease/interactions/lectures/animation')
sdpLectureEligibility = require('scripts/sitDownPlease/interactions/lectures/eligibility')
sdpLectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')
sdpLecturePresenterEntryControllerModule = require('scripts/sitDownPlease/interactions/lectures/presenterEntryController')
sdpLectureLocalAudienceStateModule = require('scripts/sitDownPlease/interactions/lectures/localAudienceState')
sdpStationLocalRouteAssistModule = require('scripts/sitDownPlease/interactions/lectures/localRouteAssist')
sdpStationLocalHoldModule = require('scripts/sitDownPlease/interactions/lectures/localStationHold')
sdpSittingLocalResolver = require('scripts/sitDownPlease/interactions/sitting/localResolver')
sdpSleepSurfaceSampler = require('scripts/sitDownPlease/interactions/sleeping/surfaceSampler')
sdpSleepAnchorResolver = require('scripts/sitDownPlease/interactions/sleeping/anchorResolver')
sdpSleepNormalizationPolicy = require('scripts/sitDownPlease/interactions/sleeping/normalizationPolicy')
sdpSleepCalibrationWarnings = require('scripts/sitDownPlease/interactions/sleeping/calibrationWarnings')
sdpSleepLocalDoorAssistModule = require('scripts/sitDownPlease/interactions/sleeping/localDoorAssist')
sdpSleepWakeCleanup = require('scripts/sitDownPlease/interactions/sleeping/wakeCleanup')
sdpScalePolicy = require('scripts/sitDownPlease/world/scalePolicy')
sdpExternalAnimationCompat = require('scripts/sitDownPlease/compatibility/externalAnimations')
sdpAssignmentEligibility = require('scripts/sitDownPlease/assignment/eligibility')
sdpFocusMetadata = require('scripts/sitDownPlease/calibration/focusMetadata')

-- =============================================================================
-- LOCAL OBJECT INTERACTION SEEKER (NPC LOCAL SCRIPT)
--
-- This keeps the original visual sitting approach:
--   - local script validates the assigned object and chooses a final pose
--   - global script moves the actor to the approach/final pose
--   - local script plays/stops the interaction animation
--
-- Sitting and sleeping are active. The former prayer interaction has been
-- left inactive for later re-implementation outside the active mod folder.
-- =============================================================================

local settings = profiles.settings()

actorDeadReason = function(actor)
    return sdpAssignmentEligibility.actorDeadReason(actor, types)
end

local BLACKLIST_IDS = profiles.npcBlacklist
local AI_POLL_INTERVAL = 0.5
local FOLLOWER_REPORT_INTERVAL = 3

local currentObject = nil
local currentProfile = nil
local currentInteractionType = nil
local currentInteractionData = nil
local currentInteractionInitialPlacement = false
local currentAnimation = nil
local currentAnimationOptions = nil
local currentAnimationQueued = false
local currentSlot = nil
local currentSlotKey = nil
local currentSlotName = nil
local currentFinalPosition = nil
local currentFinalRotation = nil
local runtimeSleepCalibration = { x = nil, y = nil, z = nil, yaw = nil }
local runtimeSittingCalibration = { x = nil, y = nil, z = nil, yaw = nil }
local calibrationExportSequence = 0

local isInteracting = false
local interactionAssigned = false
local standRequested = false
local followerReportTimer = 0
local seekerReadyReportTimer = 0
local seekerReadyReportsRemaining = 6
local lastReportedFollowerState = nil
local targetPos = nil
local aiPollTimer = 0
sdpInteractionAiSuppression = nil
local currentSittingBaseHitPos = nil
local currentSittingFacingDirection = nil
local currentSittingAppliedCalibration = nil
local currentSittingAppliedProfileOffset = nil
local currentSittingAppliedAnimationOffset = nil
local currentSittingPoseActivity = nil
local currentSittingPoseAnimation = nil
local currentSleepApproachPos = nil
local currentSleepApproachName = nil
local currentSleepExitPositions = nil
local currentSleepExitName = nil
local currentSleepBedTop = nil
local currentSleepRawBedTop = nil
local currentSleepObjectTop = nil
local currentSleepProfileRootOffset = nil
local currentSleepCalibrationOffset = nil
local currentSleepMergedRootOffset = nil
local currentSleepAnimationNormalizationOffset = nil
local currentSleepCalibrationYawDegrees = 0
local currentSleepPoseYawOffset = nil
local currentSleepSurfaceMode = nil
local currentSleepRawSurfaceMode = nil
local currentSleepSurfaceSamples = 0
local currentCalibrationTargetKey = nil
sdpSleepDoorAssist = nil
sdpSleepDoorAssistContext = nil
sdpCurrentStationAssignment = nil
sdpStationHold = nil
sdpLecturePresenterAnimationState = nil
sdpLectureAudienceAnimationState = nil
sdpLectureLocalAudienceState = nil
sdpLectureAudienceRestoreAnimation = nil
sdpLectureAudienceAssetRejectLogged = false
sdpLecturePresenterEntryController = nil
sdpLectureBookAttachedBone = nil
local briefTravelDest = nil
local briefTravelStartedAt = nil
local briefTravelTimeout = 8
local briefTravelRadius = 70
local currentInteractionTravelDest = nil
local currentInteractionTravelStartedAt = nil
local currentInteractionStartedAt = nil
local externalTravelTracker = externalAiTakeover.newTracker()
local onSitDownPleaseStartAIPackage = nil
local onSleepRouteDoorRejected = nil
local onStopInteractionObject = nil
local normalizeDirection3 = nil
local objectForwardDirection = nil
local objectRightDirection = nil
local directionDot2 = nil
local projectedObjectOffset = nil

sdpNearbyPlayer = function()
    local ok, player = pcall(function()
        return nearby and nearby.players and nearby.players[1] or nil
    end)
    if ok then return player end
    return nil
end

local function debugLog(...)
    profiles.debugLog(settings, self.object.recordId or self.object.id, ...)
end

sdpStationRouteAssist = sdpStationLocalRouteAssistModule.create({
    actor = function() return self.object end,
    doors = function() return nearby and nearby.doors or nil end,
    now = function() return core.getSimulationTime and core.getSimulationTime() or 0 end,
    sendGlobalEvent = function(name, payload) return core.sendGlobalEvent(name, payload) end,
    routeAssist = routeAssist,
    debugLog = debugLog,
})

local function resetRuntimeCalibrationOffsets(reason)
    runtimeSittingCalibration = calibrationPoseState.emptyOffset()
    runtimeSleepCalibration = calibrationPoseState.emptyOffset()
    debugLog("calibration baseline reset", tostring(reason or "target_changed"))
end

local function copyIncomingCalibration(calibration)
    if type(calibration) ~= "table" then return nil end
    return {
        x = tonumber(calibration.x) or 0,
        y = tonumber(calibration.y) or 0,
        z = tonumber(calibration.z) or 0,
        yaw = tonumber(calibration.yaw) or 0,
    }
end

local function restoreIncomingCalibration(data)
    local calibration = copyIncomingCalibration(data and data.calibration)
    if not calibration then return end
    if data.interactionType == "sitting" then
        runtimeSittingCalibration = calibration
    elseif data.interactionType == "sleeping" then
        runtimeSleepCalibration = calibration
    else
        return
    end
    debugLog("calibration baseline restored", tostring(data.interactionType), calibrationPoseState.offsetText(calibration))
end

local function localActorShouldSuppressReadyReport()
    local actor = self.object
    local recordId = actor and actor.recordId and string.lower(tostring(actor.recordId)) or nil
    if recordId and BLACKLIST_IDS and BLACKLIST_IDS[recordId] then return true end
    if sdpQuestSafety.questActorReason(actor, types, sdpNearbyPlayer()) then return true end
    if sdpProceduralChatterCompat.assignmentBlockReason(actor, core) then return true end
    if profiles.externalAnimationNpcReason and profiles.externalAnimationNpcReason(actor) then return true end
    return false
end

local function reportSeekerReady(reason)
    if localActorShouldSuppressReadyReport() then return end
    pcall(function()
        core.sendGlobalEvent('SitDownPleaseNpcSeekerReady', {
            npc = self.object,
            recordId = self.object and self.object.recordId or nil,
            reason = reason or 'ready',
        })
    end)
end

local function actorAiSuppression()
    if not sdpInteractionAiSuppression then
        sdpInteractionAiSuppression = sdpAiSuppression.create({
            core = core,
            types = types,
            selfModule = self,
            debugLog = debugLog,
        })
    end
    return sdpInteractionAiSuppression
end

local function suppressSleepingGreetingSound()
    -- Sleeping NPCs should not keep playing proximity greetings as if they were
    -- awake. The focused aiSuppression helper owns the sound-stop details.
    if currentInteractionType ~= "sleeping" then return end
    actorAiSuppression():stopSayIfActive("sleep suppress greeting sound")
end

local function applySleepHelloSuppression()
    -- Sleeping NPCs and active station presenters should not get pulled into
    -- normal hello/idle facing while SDP owns their pose. Station presenters
    -- suppress only hello so explicit dialogue activation still works normally.
    local sleepActive = currentInteractionType == "sleeping" and (isInteracting or interactionAssigned)
    local stationPresenterActive = sdpCurrentStationAssignment and sdpCurrentStationAssignment.active == true and not (isInteracting or interactionAssigned)
    if sleepActive then
        actorAiSuppression():apply("sleep")
    elseif stationPresenterActive then
        actorAiSuppression():apply("station_presenter")
    end
end

local function clearSleepHelloSuppression(reason)
    if sdpInteractionAiSuppression then
        sdpInteractionAiSuppression:clear(reason)
    end
end

local refreshCurrentSittingCalibration = nil
local refreshCurrentSleepCalibration = nil
local npcCalibrationEventsBinding = nil

profiles.subscribeSettings(async:callback(function(_, key)
    settings = profiles.settings()
end))

local function sittingSeatCategory(profile, obj)
    if profiles.sittingSeatCategory then return profiles.sittingSeatCategory(profile, obj) end
    local t = profile and profile.type and string.lower(tostring(profile.type)) or ""
    if t == "chair" then return "backed_chair" end
    if t ~= "" and t ~= "fallback" then return t end
    local id = obj and obj.recordId and string.lower(tostring(obj.recordId)) or ""
    if id:find("barstool", 1, true) then return "barstool" end
    if id:find("stool", 1, true) then return "stool" end
    if id:find("bench", 1, true) then return "bench" end
    if id:find("chair", 1, true) then return "backed_chair" end
    return "stool"
end

local function isBenchFurniture(obj, profile)
    return sittingSeatCategory(profile, obj) == "bench"
end

local function getAiTargets(packageType)
    if not (ai and ai.getTargets) then return nil end
    local ok, targets = pcall(ai.getTargets, packageType)
    if ok then return targets end
    return nil
end

local function getActiveAiPackage()
    if not (ai and ai.getActivePackage) then return nil end
    local ok, pkg = pcall(ai.getActivePackage)
    if ok then return pkg end
    return nil
end

local function activeDangerReason()
    -- Do not use types.Actor.stats.ai.alarm/flee here. Those are baseline AI
    -- settings, not reliable active-state flags, so normal idle NPCs can have
    -- nonzero values and would be falsely rejected from sitting/sleeping.
    if ai and ai.isFleeing then
        local ok, fleeing = pcall(ai.isFleeing)
        if ok and fleeing then return "active_fleeing" end
    end

    local combatTargets = getAiTargets("Combat")
    if combatTargets and #combatTargets > 0 then
        return "combat_target"
    end

    local pkg = getActiveAiPackage()
    if pkg and pkg.type then
        if pkg.type == "Combat" then return "combat_package" end
        if pkg.type == "Pursue" then return "pursue_package" end
    end

    return nil
end

local function activePackageBlocksNewInteraction(interactionType, data)
    if data and (data.ignoreAiPackageGate == true or data.initialPlacement == true) then return false, nil end
    local pkg = getActiveAiPackage()
    if not (pkg and pkg.type) then return false, nil end

    -- This mod is opportunistic. It may override ordinary Wander, but it should
    -- not stomp active quest/schedule packages such as Travel, Follow, Escort,
    -- Pursue, Combat, Activate, or other non-idle packages. luaNPCschedule uses
    -- Travel packages heavily, so treating active Travel as a hard block is the
    -- safest cross-mod behavior.
    if pkg.type == "Wander" then return false, nil end
    if pkg.type == "Travel" then
        -- Allow this mod's own already-started Travel package to continue through
        -- validation. Any other Travel package still wins, preserving quest/schedule
        -- AI from mods such as luaNPCschedule. Developer/manual calibration may
        -- deliberately override travel so the tester can force-profile furniture.
        local expected = data and (data.approachPos or data.destPosition or data.targetPos)
        local pkgDest = pkg.destPosition or pkg.destination
        if expected and pkgDest and (pkgDest - expected):length() < 100 then
            return false, nil
        end
        if data and data.manualAssignOverrideTesting == true then
            data.manualAssignOverrideApplied = true
            data.manualAssignOverrideReasons = data.manualAssignOverrideReasons or {}
            data.manualAssignOverrideReasons[#data.manualAssignOverrideReasons + 1] = "active_travel_package"
            return false, nil
        end
        return true, "active_travel_package"
    end
    if pkg.type == "Follow" or pkg.type == "Escort" then return true, "active_follow_or_escort_package" end
    if pkg.type == "Combat" or pkg.type == "Pursue" then return true, "active_danger_package" end
    return true, "active_" .. tostring(pkg.type) .. "_package"
end

local function objectLocalOffset(obj, offset)
    if not obj then return nil end
    return sdpScalePolicy.objectLocalPosition(util, obj, offset)
end

sdpStationHold = sdpStationLocalHoldModule.create({
    util = util,
    actor = function() return self.object end,
    controls = function() return self.controls end,
    now = function() return core.getSimulationTime and core.getSimulationTime() or 0 end,
    sendGlobalEvent = function(name, payload) return core.sendGlobalEvent(name, payload) end,
    currentAssignment = function() return sdpCurrentStationAssignment end,
    presenterEntryController = function() return sdpLecturePresenterEntryController end,
    presenterAnimationState = function() return sdpLecturePresenterAnimationState end,
    interactionActive = function() return isInteracting or interactionAssigned end,
    activeDangerReason = activeDangerReason,
    getAiTargets = getAiTargets,
    getActiveAiPackage = getActiveAiPackage,
    releaseStation = function(data) return sdpOnStationReleased(data) end,
    applySuppression = applySleepHelloSuppression,
    debugLog = debugLog,
    trace = function(tag, ...)
        sdpLectureTrace.log(debugLog, tag, ...)
    end,
})

sdpStationRotationFromYaw = function(yaw, fallback)
    return sdpStationHold.rotationFromYaw(yaw, fallback)
end

sdpStationYawFromDirection = function(fromPos, toPos, fallbackYaw)
    return sdpStationHold.yawFromDirection(fromPos, toPos, fallbackYaw)
end

sdpCurrentActorYaw = function()
    return sdpStationHold.currentActorYaw()
end

sdpStationYawDifference = function(a, b)
    return sdpStationHold.yawDifference(a, b)
end

sdpRequestStationPoseRestore = function(pos, yaw, reason, options)
    return sdpStationHold.requestPoseRestore(pos, yaw, reason, options)
end

sdpRotateStationActor = function(yaw, reason)
    return sdpStationHold.rotateActor(yaw, reason)
end

sdpLecturePresenterEntryController = sdpLecturePresenterEntryControllerModule.create({
    util = util,
    actor = function() return self.object end,
    now = function() return core.getSimulationTime and core.getSimulationTime() or 0 end,
    currentAssignment = function() return sdpCurrentStationAssignment end,
    requestPose = function(pos, yaw, reason, options)
        return sdpRequestStationPoseRestore(pos, yaw, reason, options)
    end,
    startPresenterAnimation = function(payload)
        return sdpStartLecturePresenterAnimation(payload)
    end,
    markPoseRestoreNow = function(now)
        sdpStationHold.markPoseRestoreNow(now)
    end,
    trace = function(tag, ...)
        sdpLectureTrace.log(debugLog, tag, ...)
    end,
})
sdpLectureLocalAudienceState = sdpLectureLocalAudienceStateModule.create()

sdpProcessStationPresenterEntry = function(dt)
    if not sdpLecturePresenterEntryController then return false end
    return sdpLecturePresenterEntryController.process(dt)
end

sdpStationTravelMatches = function(pkgDest, radius)
    return sdpStationHold.stationTravelMatches(pkgDest, radius)
end

sdpMaintainStationAssignment = function(dt)
    return sdpStationHold.maintain(dt)
end

local function objectLocalHorizontalOffset(obj, offset)
    if not obj or not offset then return util.vector3(0, 0, 0) end
    return sdpScalePolicy.objectLocalHorizontalVector(util, obj, offset)
end

local function yawLateralHorizontalOffset(yaw, amount)
    amount = tonumber(amount) or 0
    if amount == 0 then return util.vector3(0, 0, 0) end
    yaw = tonumber(yaw) or 0
    -- Actor forward in OpenMW yaw terms is sin/cos; lateral/right is the
    -- perpendicular. Double-bed slot spread must be perpendicular to the prone
    -- body axis, not blindly along the furniture model's local X/Y axis.
    return util.vector3(math.cos(yaw) * amount, -math.sin(yaw) * amount, 0)
end

local function projectToFloor(pos, zOffset)
    if not pos then return nil end
    local from = pos + util.vector3(0, 0, 140)
    local to = pos - util.vector3(0, 0, 140)
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
    if result.hit and result.hitPos then
        return result.hitPos + util.vector3(0, 0, zOffset or 0)
    end
    return pos
end

local function objectTopPosition(obj)
    return sdpSurfaceSampler.objectTopPosition(surfaceSamplerContext(), obj)
end

local function rayHitBelongsToObject(hitObject, obj)
    if hitObject == obj then return true end
    if not (hitObject and obj) then return false end
    local hitPos = hitObject.position
    local objPos = obj.position
    local positionsClose = false
    if hitPos and objPos then
        positionsClose = (hitPos - objPos):length() <= 12
    end
    if hitObject.id and obj.id and hitObject.id == obj.id then
        return not (hitPos and objPos) or positionsClose
    end
    if hitObject.recordId and obj.recordId and hitObject.recordId == obj.recordId then
        return positionsClose
    end
    return false
end

surfaceSamplerContext = function()
    return {
        nearby = nearby,
        util = util,
        actor = self.object,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        debugLog = debugLog,
    }
end

local function seatClutterContext()
    return {
        nearby = nearby,
        util = util,
        profiles = profiles,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        objectForwardDirection = objectForwardDirection,
        objectRightDirection = objectRightDirection,
    }
end

sampleSittingSurface = function(obj, profile)
    return sdpSurfaceSampler.sampleSittingSurface(surfaceSamplerContext(), obj, profile)
end

function averageTopSurfaceHits(hits, tolerance)
    return sdpSurfaceSampler.averageTopSurfaceHits(surfaceSamplerContext(), hits, tolerance)
end

local lastSleepSurfaceCenterOffset = nil

local function sleepSurfaceSamplerContext()
    return {
        nearby = nearby,
        actor = self.object,
        profiles = profiles,
        debugLog = debugLog,
        objectTopPosition = objectTopPosition,
        objectLocalOffset = objectLocalOffset,
        rayHitBelongsToObject = rayHitBelongsToObject,
        averageTopSurfaceHits = averageTopSurfaceHits,
    }
end

local function sampledObjectTopCenter(obj, profile)
    local center, count, source, centerOffset = sdpSleepSurfaceSampler.sample(sleepSurfaceSamplerContext(), obj, profile)
    lastSleepSurfaceCenterOffset = centerOffset
    return center, count, source
end

local function yawFromObject(obj, rotationOffset)
    local yaw = 0
    if obj and obj.rotation then
        local ok, value = pcall(function()
            return obj.rotation:getYaw()
        end)
        if ok and value then yaw = value end
    end
    return yaw + (rotationOffset or 0)
end

local function directionBetween(fromPos, toPos)
    if not fromPos or not toPos then return nil end
    local delta = toPos - fromPos
    local flat = util.vector2(delta.x, delta.y)
    if flat:length() <= 1 then return nil end
    local norm = flat:normalize()
    return util.vector3(norm.x, norm.y, 0)
end

local animationAvailable = interactionAnimation.available
local animationNameAliases = interactionAnimation.nameAliases

local function animationDebugCandidates(profile, data)
    return interactionAnimation.debugCandidates(profile, data)
end

local function chooseAvailableAnimation(profile, data)
    return interactionAnimation.chooseAvailable(profile, data)
end


local function externalAnimationNpcReason(actor)
    if profiles.externalAnimationNpcReason then return profiles.externalAnimationNpcReason(actor) end
    return sdpExternalAnimationCompat.externalAnimationNpcReason(actor)
end

local function noteManualAssignOverride(data, reason)
    sdpManualAssignment.noteTestingOverride(data, reason)
end

local function seedManualAssignOverrideReason(data)
    if not (data and data.manualAssignOverrideTesting == true) then return end
    local reason = data.sleepAccessOverrideReason or data.manualAssignOverrideReason
    if not reason then return end
    noteManualAssignOverride(data, reason)
    debugLog("nearest_manual_assign_override", "reason", tostring(reason), "bypass", "sleep_bed_access")
end

local function manualAssignCanBypassLocalBlock(reason, data)
    return sdpManualAssignment.canBypassLocalBlock(data, reason)
end

sdpLectureAudienceCanBypassLocalBlock = function(reason, rec, data)
    return data and data.lectureAudienceTarget == true
        and sdpLectureEligibility.softAudienceRoleAllowed(reason, rec, sdpServicePolicy) == true
end

local function isBlacklistedForInteraction(actor, interactionType, data)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end

    local dead, deadReason = actorDeadReason(actor)
    if dead then return true, deadReason end

    local actorId = actor.recordId and string.lower(actor.recordId) or nil
    if actorId and BLACKLIST_IDS[actorId] then return true, "blacklisted_npc" end
    local questReason = sdpQuestSafety.questActorReason(actor, types, sdpNearbyPlayer())
    if questReason then return true, questReason end

    local incapacitationReason = externalAiTakeover.externalIncapacitationReason(actor, types)
    if incapacitationReason then return true, incapacitationReason end

    local controlScriptReason = externalAiTakeover.externalControlScriptReason(actor)
    if controlScriptReason then return true, controlScriptReason end

    local proceduralChatterReason = sdpProceduralChatterCompat.assignmentBlockReason(actor, core)
    if proceduralChatterReason then
        if data and data.manualAssignOverrideTesting == true then
            noteManualAssignOverride(data, proceduralChatterReason)
            return false
        end
        if data and data.calibrationAction == true then return false end
        return true, proceduralChatterReason
    end

    local stanceReason = externalAiTakeover.activeNonIdleStanceReason(actor, types)
    if stanceReason then
        if data and data.manualAssignOverrideTesting == true then
            noteManualAssignOverride(data, stanceReason)
            return false
        end
        if data and data.calibrationAction == true then return false end
        return true, stanceReason
    end

    local externalAnimationReason = externalAnimationNpcReason(actor)
    if externalAnimationReason then return true, externalAnimationReason end

    local followTargets = getAiTargets("Follow")
    if followTargets and #followTargets > 0 then return true, "follow_package" end

    local escortTargets = getAiTargets("Escort")
    if escortTargets and #escortTargets > 0 then return true, "escort_package" end

    local pkg = getActiveAiPackage()
    if pkg and (pkg.type == "Follow" or pkg.type == "Escort") then
        return true, "follow_or_escort_package"
    end

    local dangerReason = activeDangerReason()
    if dangerReason then
        return true, dangerReason
    end

    local rec = types.NPC.record(actor.recordId)
    if not rec then return false, nil end

    if sdpActorRoles.looksLikeVampire(actor, rec, types) then
        return true, "vampire"
    end

    local isFactionLeader = sdpActorRoles.isFactionLeader(actor, types, core)
    local offHoursReason = sdpServicePolicy.offHoursServiceRecordReason(rec, settings, profiles, profiles.getGameHour(), isFactionLeader)
    local classBlockReason = sdpServicePolicy.classBlockReason(rec, offHoursReason)
    if classBlockReason then
        local reason = classBlockReason
        if sdpLectureAudienceCanBypassLocalBlock(reason, rec, data) then
            debugLog("lecture audience soft role bypass", tostring(reason))
        elseif manualAssignCanBypassLocalBlock(reason, data) then
            debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_npc_class")
        else
            return true, reason
        end
    end

    if interactionType == "sleeping" then
        -- Sleep is bed-gated and time-gated. Do not reject trainers, merchants,
        -- faction leaders, or travel-service NPCs just because they offer services.
        -- Publicans remain excluded unless the off-hours policy is active.
        return false, nil
    end

    local serviceBlockReason
    if interactionType == "sitting" then
        serviceBlockReason = sdpServicePolicy.sittingBlockReason(rec, settings, offHoursReason, isFactionLeader)
    else
        serviceBlockReason = sdpServicePolicy.nonSittingServiceBlockReason(rec)
    end
    if serviceBlockReason then
        local reason = serviceBlockReason
        if sdpLectureAudienceCanBypassLocalBlock(reason, rec, data) then
            debugLog("lecture audience soft role bypass", tostring(reason))
        elseif manualAssignCanBypassLocalBlock(reason, data) then
            debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc")
        else
            return true, reason
        end
    end

    if rec.travelDestinations and #rec.travelDestinations > 0 and not (interactionType == "sitting" and settings.sittingAllowServiceNpcs == true) then
        local reason = "travel_destination_npc"
        if sdpLectureAudienceCanBypassLocalBlock(reason, rec, data) then debugLog("lecture audience soft role bypass", tostring(reason)) elseif manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
    end

    if isFactionLeader and not offHoursReason and not (interactionType == "sitting" and settings.sittingAllowServiceNpcs == true) then
        local reason = "faction_leader"
        if sdpLectureAudienceCanBypassLocalBlock(reason, rec, data) then debugLog("lecture audience soft role bypass", tostring(reason)) elseif manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
    end

    return false, nil
end

local function vectorLength2d(v)
    return routeAssist.vectorLength2d(v)
end

local function distanceToSegment2d(p, a, b)
    return routeAssist.distanceToSegment2d(p, a, b)
end

local function routeDoorIsClosedNonTeleport(door)
    return routeAssist.isClosedNonTeleport(door)
end

local function routeDoorOpenability(door, actor)
    return routeAssist.openability(door, actor or self.object, {
        debugLog = debugLog,
        logPrefix = "route_door_assist",
    })
end

local function openDoorBlocksRoute(door, fromPos, targetPos)
    if not (door and fromPos and targetPos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return false end
    local ok, result = pcall(function()
        return nearby.castRay(fromPos + util.vector3(0, 0, 54), targetPos + util.vector3(0, 0, 54), {
            collisionType = nearby.COLLISION_TYPE.Door,
            radius = 0,
        })
    end)
    local hitObject = ok and result and result.hitObject or nil
    return hitObject == door
end

local function routeDoorRequiredForSleepApproach(door, navPos)
    if not (door and navPos) then return false, "missing_route_door_context" end
    if openDoorBlocksRoute(door, self.object.position, navPos) then
        return true, "direct_door_ray"
    end

    local onSegment, segmentReason = routeAssist.doorOnRouteSegment(door, self.object.position, navPos, {
        maxVertical = 220,
        maxLineDistance = 190,
        maxActorDistance = 2200,
        maxTargetDistance = 2200,
    })
    if onSegment == true then return true, "near_actor_target_segment" end
    return false, segmentReason or "door_not_on_actor_target_segment"
end

local function routeDoorRejectReason(detail)
    local text = tostring(detail or "")
    if text:find("trapped_route_door", 1, true) then return "trapped_route_door" end
    if text:find("locked_route_door", 1, true) then return "locked_route_door" end
    return "blocked_route_door"
end

local rayBlockedBetween

local function actorAgentBounds()
    if types and types.Actor and types.Actor.getPathfindingAgentBounds then
        local okBounds, bounds = pcall(types.Actor.getPathfindingAgentBounds, self.object)
        if okBounds and bounds then return bounds end
    end
    return nil
end

local function nearestWalkNavmeshPosition(pos, includeFlags, maxDelta, maxBlockedSnap)
    if not (pos and nearby and nearby.findNearestNavMeshPosition) then return pos, "unavailable", 0 end
    local options = {
        includeFlags = includeFlags,
        searchAreaHalfExtents = util.vector3(150, 150, 120),
    }
    local bounds = actorAgentBounds()
    if bounds then options.agentBounds = bounds end
    local ok, navPos = pcall(nearby.findNearestNavMeshPosition, pos, options)
    if not (ok and navPos) then return nil, "no_nearest_navmesh", math.huge end
    local delta = (navPos - pos):length()
    if delta > (maxDelta or 125) then return nil, "approach_too_far_from_navmesh", delta end
    if maxBlockedSnap and delta > maxBlockedSnap and rayBlockedBetween(pos + util.vector3(0, 0, 54), navPos + util.vector3(0, 0, 54), 18) then
        return nil, "approach_navmesh_behind_collision", delta
    end
    return navPos, delta > 1 and "snapped" or "exact", delta
end

local function pathStatusWithFlags(dest, includeFlags)
    if not (nearby and nearby.findPath and dest) then return nil, nil end
    local options = {}
    if includeFlags then options.includeFlags = includeFlags end
    local bounds = actorAgentBounds()
    if bounds then options.agentBounds = bounds end
    if options.destinationTolerance == nil then options.destinationTolerance = 48 end
    local source = self.object.position
    local navSource = nearestWalkNavmeshPosition(source, includeFlags, 150, 42)
    if navSource then source = navSource end
    local ok, status, path = pcall(nearby.findPath, source, dest, options)
    if ok then return status, path end
    return nil, nil
end

local function nearestSleepNavmeshPosition(pos)
    if not (pos and nearby and nearby.findNearestNavMeshPosition and nearby.NAVIGATOR_FLAGS) then return pos, "unavailable", 0 end
    local flags = nearby.NAVIGATOR_FLAGS
    local includeFlags = (flags.Walk or 0) + (flags.UsePathgrid or 0)
    return nearestWalkNavmeshPosition(pos, includeFlags, 125, 36)
end

local function pathStatusIsSuccess(status)
    if status == nil then return false end
    if nearby and nearby.FIND_PATH_STATUS and status == nearby.FIND_PATH_STATUS.Success then return true end
    local label = tostring(status)
    return label == "Success" or label == "success" or label:find("Success", 1, true) ~= nil
end

local function pathStatusLabel(status)
    if status == nil then return "unavailable" end
    if nearby and nearby.FIND_PATH_STATUS then
        for key, value in pairs(nearby.FIND_PATH_STATUS) do
            if value == status then return tostring(key) end
        end
    end
    return tostring(status)
end

local function schedulerStandDispersalNavTarget(pos)
    if not (pos and nearby and nearby.NAVIGATOR_FLAGS) then return nil, "navmesh_unavailable" end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk or 0
    if walk <= 0 then return nil, "walk_flag_unavailable" end
    local includeFlags = walk + (flags.UsePathgrid or 0)
    local navPos, navReason, navDelta = nearestWalkNavmeshPosition(pos, includeFlags, 260, 48)
    if not navPos then return nil, navReason or "no_nearest_navmesh", navDelta end
    local status = nil
    if nearby.findPath then
        status = pathStatusWithFlags(navPos, includeFlags)
        if not pathStatusIsSuccess(status) then return nil, "path_" .. pathStatusLabel(status), navDelta end
    end
    return navPos, "ok", navDelta
end

local function onSchedulerStandDispersal(data)
    if isInteracting or interactionAssigned then
        debugLog("scheduler stand dispersal skipped busy", tostring(data and data.reason))
        return
    end
    local targets = data and data.targets or nil
    if not (targets and #targets > 0 and self.object and self.object.cell) then
        debugLog("scheduler stand dispersal skipped no targets", tostring(data and data.reason))
        return
    end
    local lastReason = nil
    for index, target in ipairs(targets) do
        local navPos, reason = schedulerStandDispersalNavTarget(target and target.position or nil)
        if navPos then
            core.sendGlobalEvent("SitDownPleaseSchedulerStandDispersalReady", {
                npc = self.object,
                position = navPos,
                source = data.source,
                reason = data.reason,
                targetIndex = index,
                targetObjectId = target.objectId,
            })
            debugLog(
                "scheduler stand dispersal target validated",
                "target", tostring(index),
                "object", tostring(target.objectId),
                "position", tostring(navPos),
                "reason", tostring(data.reason)
            )
            return
        else
            lastReason = reason
        end
    end
    core.sendGlobalEvent("SitDownPleaseSchedulerStandDispersalFailed", {
        npc = self.object,
        source = data.source,
        reason = data.reason,
        failureReason = lastReason or "no_reachable_target",
    })
    debugLog("scheduler stand dispersal failed", tostring(data and data.reason), tostring(lastReason))
end

local function navPathLength(path)
    if not path or #path == 0 then return nil end
    local total = 0
    for i = 1, #path - 1 do
        total = total + (path[i + 1] - path[i]):length()
    end
    return total
end

local function horizontalDistance3(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt((dx * dx) + (dy * dy))
end

rayBlockedBetween = function(from, to, allowance)
    if not (from and to and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return false end
    local fullDist = (to - from):length()
    if fullDist <= 1 then return false end
    local ok, result = pcall(function()
        return nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
    end)
    if not (ok and result and result.hit and result.hitPos) then return false end
    local hitDist = (result.hitPos - from):length()
    return hitDist < math.max(24, fullDist - (allowance or 28))
end

local function sleepApproachLineBlocked(pos)
    if not pos then return false end
    local from = self.object.position + util.vector3(0, 0, 54)
    local to = pos + util.vector3(0, 0, 54)
    return rayBlockedBetween(from, to, 28)
end

local function sleepApproachToFinalBlocked(pos, finalPos)
    return sdpSleepApproachBarrier.blockedBetween(pos, finalPos, self.object, {
        debugLog = debugLog,
        ignoreObject = currentObject,
    })
end

local function sleepApproachPathStatus(dest)
    if not (nearby and nearby.NAVIGATOR_FLAGS and nearby.findPath and dest) then
        return nil, nil, nil
    end

    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not walk then return nil, nil, nil end

    local baseFlags = walk + (flags.UsePathgrid or 0)
    local closedStatus, closedPath = pathStatusWithFlags(dest, baseFlags)
    local openStatus, openPath = nil, nil
    if openDoor then
        openStatus, openPath = pathStatusWithFlags(dest, baseFlags + openDoor)
    end

    return closedStatus, openStatus, openDoor ~= nil, closedPath, openPath
end

local function firstClosedRouteDoorOnPath(dest, includeBlockedDoor)
    if not (dest and nearby and nearby.NAVIGATOR_FLAGS and nearby.COLLISION_TYPE and nearby.castRay) then return nil end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not (walk and openDoor) then return nil end
    local baseFlags = walk + openDoor + (flags.UsePathgrid or 0)
    local status, path = pathStatusWithFlags(dest, baseFlags)
    if not pathStatusIsSuccess(status) or not path or #path < 2 then return nil end

    local lastDoor = nil
    for i = 1, #path - 1 do
        local ok, result = pcall(function()
            return nearby.castRay(path[i] + util.vector3(0, 0, 54), path[i + 1] + util.vector3(0, 0, 54), {
                collisionType = nearby.COLLISION_TYPE.Door,
                radius = 0,
                ignore = lastDoor,
            })
        end)
        local door = ok and result and result.hitObject or nil
        if door and routeAssist.isNonTeleportDoor(door) then
            local closed = routeDoorIsClosedNonTeleport(door)
            local canOpen, openReason
            if closed then
                canOpen, openReason = routeDoorOpenability(door, self.object)
            else
                canOpen, openReason = routeAssist.npcCanOpenDoor(door, self.object, {
                    debugLog = debugLog,
                    logPrefix = "route_door_assist",
                })
            end
            if (closed or canOpen ~= true) and (canOpen or includeBlockedDoor == true) then
                local waypoint = path[math.min(i + 2, #path)] or path[i + 1]
                if waypoint and (waypoint - self.object.position):length() < 90 then
                    local dir = normalizeDirection3(path[i + 1] - path[i]) or normalizeDirection3(dest - self.object.position)
                    if dir then waypoint = door.position + dir * 150 end
                end
                return door, waypoint, canOpen, openReason
            end
        end
        lastDoor = door
    end
    return nil
end

local function classifySleepApproachFailure(pos, finalPos, closedStatus, openStatus)
    local vertical = pos and math.abs((self.object.position.z or 0) - (pos.z or 0)) or 0
    local horizontal = horizontalDistance3(self.object.position, pos)

    if sleepApproachLineBlocked(pos) then
        return "blocked_by_wall"
    end

    -- A large Z split while the actor is horizontally near the bed is the classic
    -- upstairs/downstairs or stairs-under-room failure: radius says close, the route
    -- says no. Treat that as unreachable rather than letting a later snap bridge it.
    if vertical > 140 and horizontal < 520 then
        return "wrong_floor_or_unreachable"
    end

    if closedStatus ~= nil or openStatus ~= nil then return "no_path_to_bed" end
    return nil
end

local function currentSleepTargetIsExplicitBunk(data)
    local profile = (data and data.profile) or currentProfile or {}
    local text = table.concat({
        string.lower(tostring(currentSlotName or currentSlotKey or "")),
        string.lower(tostring(profile.profileId or "")),
        string.lower(tostring(profile.bedType or "")),
        string.lower(tostring(profile.type or "")),
        string.lower(tostring(currentObject and currentObject.recordId or "")),
    }, " ")
    return text:find("bunk", 1, true) ~= nil
        or text:find("sleep_top", 1, true) ~= nil
        or text:find("sleep_bottom", 1, true) ~= nil
end

local function bunkApproachMayTrustPath(data, navPos, finalPos, pathLength, closedOk, finalBlockedReason)
    if finalBlockedReason ~= nil and tostring(finalBlockedReason) ~= "blocked_by_wall" then return false end
    if closedOk ~= true then return false end
    if not currentSleepTargetIsExplicitBunk(data) then return false end
    pathLength = tonumber(pathLength)
    if not pathLength or pathLength > 360 then return false end
    if horizontalDistance3(navPos, finalPos) > 270 then return false end
    local vertical = math.abs(((navPos and navPos.z) or 0) - ((finalPos and finalPos.z) or 0))
    return vertical <= 230
end

local function sleepApproachReachability(pos, finalPos, data, logPrefix)
    if not pos then return false, "no_path_to_bed", nil end

    local navPos, navReason, navDelta = nearestSleepNavmeshPosition(pos)
    if not navPos then
        if settings.debug == true then
            debugLog(
                logPrefix or "sleep_entry_rejected",
                "reason", tostring(navReason),
                "object", tostring(currentObject and currentObject.recordId),
                "approach", tostring(pos),
                "navDelta", tostring(navDelta)
            )
        end
        return false, navReason or "approach_not_on_navmesh", {
            navReason = navReason,
            navDelta = navDelta,
        }
    end

    local closedStatus, openStatus, checkedOpenDoor, closedPath, openPath = sleepApproachPathStatus(navPos)
    local closedOk = pathStatusIsSuccess(closedStatus)
    local openOk = pathStatusIsSuccess(openStatus)
    local actorLineBlocked = rayBlockedBetween(self.object.position + util.vector3(0, 0, 54), navPos + util.vector3(0, 0, 54), 34)
    local chosenPathLength = closedOk and navPathLength(closedPath) or (openOk and navPathLength(openPath) or nil)

    if closedOk or openOk then
        local tooIndirect, indirectReason, indirectDetails = sleepRoutePlanner.approachPathTooIndirect({
            debug = settings.debug == true,
            debugLog = debugLog,
            logPrefix = logPrefix or "sleep_entry_rejected",
            currentObject = function() return currentObject end,
        }, {
            pathLength = chosenPathLength,
            actorLineBlocked = actorLineBlocked,
            straightDistance = (navPos - self.object.position):length(),
            approach = pos,
            navApproach = navPos,
        })
        if tooIndirect then
            indirectDetails = indirectDetails or {}
            indirectDetails.closedStatus = closedStatus
            indirectDetails.openStatus = openStatus
            indirectDetails.navPos = navPos
            indirectDetails.navReason = navReason
            indirectDetails.navDelta = navDelta
            return false, indirectReason, indirectDetails
        end

        local finalBlocked, finalBlockedReason, finalBlockedDoor, finalBlockedDoorReason = sleepApproachToFinalBlocked(navPos, finalPos)
        if finalBlocked then
            if bunkApproachMayTrustPath(data, navPos, finalPos, chosenPathLength, closedOk, finalBlockedReason) then
                if settings.debug == true then
                    debugLog(
                        "sleep_entry_route_bypassed",
                        "reason", "bunk_bedside_path_trusted",
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "pathLength", tostring(chosenPathLength),
                        "finalBlockedReason", tostring(finalBlockedReason)
                    )
                end
            else
                local reason = finalBlockedReason or "blocked_by_wall"
                if settings.debug == true then
                    debugLog(
                        logPrefix or "sleep_entry_rejected",
                        "reason", tostring(reason),
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "door", tostring(finalBlockedDoor and (finalBlockedDoor.recordId or finalBlockedDoor.id)),
                        "doorReason", tostring(finalBlockedDoorReason),
                        "closedStatus", pathStatusLabel(closedStatus),
                        "openStatus", pathStatusLabel(openStatus),
                        "finalBlocked", "true"
                    )
                end
                return false, reason, { closedStatus = closedStatus, openStatus = openStatus, finalBlocked = true, routeDoor = finalBlockedDoor, routeDoorReason = finalBlockedDoorReason, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
            end
        end

        local unopenableRouteDoor, routeDoorBlockReason, blockedRouteDoor, blockedRouteDoorReason, blockedRouteWaypoint = sdpSleepApproachBarrier.unopenableRouteDoorOnPath({
            firstClosedRouteDoorOnPath = firstClosedRouteDoorOnPath,
        }, navPos)
        if unopenableRouteDoor == true then
            local doorRequired, doorRequiredReason = routeDoorRequiredForSleepApproach(blockedRouteDoor, navPos)
            if doorRequired ~= true then
                if settings.debug == true then
                    debugLog(
                        logPrefix or "sleep_entry_rejected",
                        "reason", "route_too_indirect",
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "door", tostring(blockedRouteDoor and (blockedRouteDoor.recordId or blockedRouteDoor.id)),
                        "doorReason", tostring(blockedRouteDoorReason),
                        "doorRequiredReason", tostring(doorRequiredReason),
                        "closedStatus", pathStatusLabel(closedStatus),
                        "openStatus", pathStatusLabel(openStatus),
                        "actorLineBlocked", tostring(actorLineBlocked == true),
                        "pathLength", tostring(chosenPathLength)
                    )
                end
                return false, "route_too_indirect", { closedStatus = closedStatus, openStatus = openStatus, indirectRouteDoor = true, routeDoor = blockedRouteDoor, routeDoorReason = blockedRouteDoorReason, routeDoorRequiredReason = doorRequiredReason, routeWaypoint = blockedRouteWaypoint, actorLineBlocked = actorLineBlocked, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
            end

            if settings.debug == true then
                debugLog(
                    logPrefix or "sleep_entry_rejected",
                    "reason", tostring(routeDoorBlockReason),
                    "object", tostring(currentObject and currentObject.recordId),
                    "approach", tostring(pos),
                    "navApproach", tostring(navPos),
                    "door", tostring(blockedRouteDoor and (blockedRouteDoor.recordId or blockedRouteDoor.id)),
                    "doorReason", tostring(blockedRouteDoorReason),
                    "closedStatus", pathStatusLabel(closedStatus),
                    "openStatus", pathStatusLabel(openStatus),
                    "actorLineBlocked", tostring(actorLineBlocked == true)
                )
            end
            return false, routeDoorBlockReason, { closedStatus = closedStatus, openStatus = openStatus, needsDoorAssist = true, routeDoor = blockedRouteDoor, routeDoorReason = blockedRouteDoorReason, routeWaypoint = blockedRouteWaypoint, actorLineBlocked = actorLineBlocked, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
        end

        local needsDoorAssist = openOk and not closedOk
        local routeDoor, routeWaypoint, routeDoorCanOpen, routeDoorReason = nil, nil, nil, nil
        if needsDoorAssist then
            routeDoor, routeWaypoint, routeDoorCanOpen, routeDoorReason = firstClosedRouteDoorOnPath(navPos, true)
            if routeDoor then
                local doorRequired, doorRequiredReason = routeDoorRequiredForSleepApproach(routeDoor, navPos)
                if doorRequired ~= true then
                    if settings.debug == true then
                        debugLog(
                            logPrefix or "sleep_entry_rejected",
                            "reason", "route_too_indirect",
                            "object", tostring(currentObject and currentObject.recordId),
                            "approach", tostring(pos),
                            "navApproach", tostring(navPos),
                            "door", tostring(routeDoor and (routeDoor.recordId or routeDoor.id)),
                            "doorReason", tostring(routeDoorReason),
                            "doorRequiredReason", tostring(doorRequiredReason),
                            "closedStatus", pathStatusLabel(closedStatus),
                            "openStatus", pathStatusLabel(openStatus),
                            "pathLength", tostring(chosenPathLength)
                        )
                    end
                    return false, "route_too_indirect", { closedStatus = closedStatus, openStatus = openStatus, needsDoorAssist = true, indirectRouteDoor = true, routeDoor = routeDoor, routeDoorReason = routeDoorReason, routeDoorRequiredReason = doorRequiredReason, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
                end
            end

            if data and data.disallowSleepDoorAssist == true then
                if settings.debug == true then
                    debugLog(
                        logPrefix or "sleep_entry_rejected",
                        "reason", "public_bed_requires_door_assist",
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "door", tostring(routeDoor and (routeDoor.recordId or routeDoor.id)),
                        "doorReason", tostring(routeDoorReason),
                        "closedStatus", pathStatusLabel(closedStatus),
                        "openStatus", pathStatusLabel(openStatus)
                    )
                end
                return false, "public_bed_requires_door_assist", { closedStatus = closedStatus, openStatus = openStatus, needsDoorAssist = true, routeDoor = routeDoor, routeDoorReason = routeDoorReason, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
            end

            if routeDoor and routeDoorCanOpen ~= true then
                local reason = routeDoorRejectReason(routeDoorReason)
                if settings.debug == true then
                    debugLog(
                        logPrefix or "sleep_entry_rejected",
                        "reason", tostring(reason),
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "door", tostring(routeDoor and (routeDoor.recordId or routeDoor.id)),
                        "doorReason", tostring(routeDoorReason),
                        "closedStatus", pathStatusLabel(closedStatus),
                        "openStatus", pathStatusLabel(openStatus)
                    )
                end
                return false, reason, { closedStatus = closedStatus, openStatus = openStatus, needsDoorAssist = true, routeDoor = routeDoor, routeDoorReason = routeDoorReason, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
            end
        end

        if needsDoorAssist and settings.debug == true then
            debugLog(
                "route_door_assist",
                "object", tostring(currentObject and currentObject.recordId),
                "approach", tostring(pos),
                "navApproach", tostring(navPos),
                "door", tostring(routeDoor and (routeDoor.recordId or routeDoor.id)),
                "doorReason", tostring(routeDoorReason),
                "closedStatus", pathStatusLabel(closedStatus),
                "openStatus", pathStatusLabel(openStatus)
            )
        end
        return true, needsDoorAssist and "route_door_assist" or "path_reachable", {
            closedStatus = closedStatus,
            openStatus = openStatus,
            needsDoorAssist = needsDoorAssist,
            routeDoor = routeDoor,
            routeDoorReason = routeDoorReason,
            routeWaypoint = routeWaypoint,
            actorLineBlocked = actorLineBlocked,
            navPos = navPos,
            navReason = navReason,
            navDelta = navDelta,
            pathLength = chosenPathLength,
        }
    end

    if closedStatus ~= nil or openStatus ~= nil or checkedOpenDoor == true then
        local reason = classifySleepApproachFailure(navPos, finalPos, closedStatus, openStatus) or "no_path_to_bed"
        if settings.debug == true then
            debugLog(
                logPrefix or "sleep_entry_rejected",
                "reason", tostring(reason),
                "object", tostring(currentObject and currentObject.recordId),
                "approach", tostring(pos),
                "navApproach", tostring(navPos),
                "closedStatus", pathStatusLabel(closedStatus),
                "openStatus", pathStatusLabel(openStatus)
            )
        end
        return false, reason, { closedStatus = closedStatus, openStatus = openStatus, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
    end

    -- Last-resort builds without findPath: still reject the two visibly bad cases
    -- we can detect locally, but do not break every bed on API-unavailable builds.
    local fallbackReason = classifySleepApproachFailure(navPos, finalPos, nil, nil)
    if fallbackReason == "blocked_by_wall" or fallbackReason == "wrong_floor_or_unreachable" then
        if settings.debug == true then
            debugLog(logPrefix or "sleep_entry_rejected", "reason", tostring(fallbackReason), "object", tostring(currentObject and currentObject.recordId), "approach", tostring(pos), "navApproach", tostring(navPos), "pathApi", "unavailable")
        end
        return false, fallbackReason, { navPos = navPos, navReason = navReason, navDelta = navDelta }
    end

    return true, "path_api_unavailable", { navPos = navPos, navReason = navReason, navDelta = navDelta }
end

local function sittingLockedRouteRejectReason(dest, data)
    if not (dest and nearby and nearby.NAVIGATOR_FLAGS and nearby.findPath) then return nil end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not (walk and openDoor) then return nil end

    local navPos = nearestWalkNavmeshPosition(dest, walk + (flags.UsePathgrid or 0), 145, 38)
    if not navPos then return nil end
    local baseFlags = walk + (flags.UsePathgrid or 0)
    local closedStatus = pathStatusWithFlags(navPos, baseFlags)
    local openStatus = pathStatusWithFlags(navPos, baseFlags + openDoor)
    if pathStatusIsSuccess(closedStatus) then return nil end

    local teleportDoor, teleportReason = routeAssist.teleportDoorOnRouteSegment(self.object.cell, self.object.position, navPos, self.object, {
        maxVertical = 260,
        maxLineDistance = 220,
        maxActorDistance = 1200,
        maxTargetDistance = 1200,
    })
    if teleportDoor and teleportReason then
        debugLog(
            "sitting_teleport_door_route_rejected",
            "object", tostring(currentObject and currentObject.recordId),
            "door", tostring(teleportDoor.recordId or teleportDoor.id),
            "reason", tostring(teleportReason),
            "closedStatus", pathStatusLabel(closedStatus),
            "openStatus", pathStatusLabel(openStatus)
        )
        if data and data.manualAssign == true then
            debugLog(
                "manual_assign_teleport_door_route_rejected",
                "object", tostring(currentObject and currentObject.recordId),
                "door", tostring(teleportDoor.recordId or teleportDoor.id),
                "reason", tostring(teleportReason)
            )
        end
        return teleportReason
    end

    if not pathStatusIsSuccess(openStatus) then return nil end

    local routeDoor, _, routeDoorCanOpen, routeDoorReason = firstClosedRouteDoorOnPath(navPos, true)
    if not routeDoor then return nil end
    debugLog(
        "sitting_locked_route_door_check",
        "object", tostring(currentObject and currentObject.recordId),
        "door", tostring(routeDoor.recordId or routeDoor.id),
        "doorReason", tostring(routeDoorReason),
        "closedStatus", pathStatusLabel(closedStatus),
        "openStatus", pathStatusLabel(openStatus)
    )
    if routeDoorCanOpen == true then
        debugLog("sitting_locked_route_door_actor_has_key", "door", tostring(routeDoor.recordId or routeDoor.id), "reason", tostring(routeDoorReason))
        return nil
    end
    local reasonText = tostring(routeDoorReason or "")
    local reason = reasonText:find("unknown_key", 1, true) and "sitting_locked_route_door_unknown_key" or "sitting_locked_route_door_missing_key"
    debugLog(reason, "door", tostring(routeDoor.recordId or routeDoor.id), "reason", tostring(routeDoorReason))
    debugLog("sitting_locked_route_rejected", "object", tostring(currentObject and currentObject.recordId), "door", tostring(routeDoor.recordId or routeDoor.id), "reason", tostring(reason))
    if data and data.manualAssign == true then
        debugLog("manual_assign_locked_route_rejected", "object", tostring(currentObject and currentObject.recordId), "door", tostring(routeDoor.recordId or routeDoor.id), "reason", tostring(reason))
    end
    if data and data.calibrationReason == "developer_test_npc" then
        debugLog("test_npc_locked_route_rejected", "object", tostring(currentObject and currentObject.recordId), "door", tostring(routeDoor.recordId or routeDoor.id), "reason", tostring(reason))
    end
    return "sitting_locked_route_rejected"
end

sdpSleepDoorAssistContext = {
    settings = function() return settings end,
    actor = function() return self.object end,
    doors = function() return nearby and nearby.doors or nil end,
    nearby = nearby,
    now = function() return core.getSimulationTime and core.getSimulationTime() or 0 end,
    routeAssist = routeAssist,
    doorRayLift = util.vector3(0, 0, 54),
    pathStatusWithFlags = pathStatusWithFlags,
    pathStatusIsSuccess = pathStatusIsSuccess,
    firstClosedRouteDoorOnPath = firstClosedRouteDoorOnPath,
    openDoorBlocksRoute = openDoorBlocksRoute,
    rayBlockedBetween = function(from, to, allowance)
        if not (from and to) then return false end
        return rayBlockedBetween(from + util.vector3(0, 0, 54), to + util.vector3(0, 0, 54), allowance)
    end,
    vectorLength2d = vectorLength2d,
    distanceToSegment2d = distanceToSegment2d,
    normalizeDirection3 = function(value) return normalizeDirection3 and normalizeDirection3(value) or nil end,
    interactionState = function()
        return {
            currentInteractionType = currentInteractionType,
            interactionAssigned = interactionAssigned,
            isInteracting = isInteracting,
            targetPos = targetPos,
        }
    end,
    sendGlobalEvent = function(name, payload) return core.sendGlobalEvent(name, payload) end,
    startAIPackage = function(data) return onSitDownPleaseStartAIPackage(data) end,
    rejectRouteDoor = function(reason, door, detail)
        if onSleepRouteDoorRejected then return onSleepRouteDoorRejected(reason, door, detail) end
        return false
    end,
    debugLog = debugLog,
}
sdpSleepDoorAssist = sdpSleepLocalDoorAssistModule.create(sdpSleepDoorAssistContext)

local function maybeAssistSleepRouteDoor(dt)
    return sdpSleepDoorAssist.process(dt)
end

sdpMaybeAssistStationRouteDoor = function(dt)
    return sdpStationRouteAssist.process(dt)
end

sdpLectureAnimationGroupAvailable = function(group)
    if not (group and anim and anim.hasGroup) then return false end
    local ok, hasGroup = pcall(anim.hasGroup, self, group)
    return ok and hasGroup == true
end

sdpCancelLectureAnimationGroup = function(group)
    if group and anim and anim.cancel then pcall(anim.cancel, self, group) end
end

sdpLogRejectedAudienceAssets = function(reason)
    if sdpLectureAudienceAssetRejectLogged == true then return end
    sdpLectureAudienceAssetRejectLogged = true
    local groups = sdpLectureAnimation and sdpLectureAnimation.rejectedAudienceAssets and sdpLectureAnimation.rejectedAudienceAssets() or nil
    sdpLectureTrace.log(
        debugLog,
        "audience_reaction_asset_rejected",
        "reason", tostring(reason or (sdpLectureAnimation and sdpLectureAnimation.audienceUnsafeAssetReason) or "audience_assets_disabled"),
        "groups", groups and table.concat(groups, ",") or "unknown",
        "session", tostring(sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil)
    )
end

sdpLectureBlendMask = function(kind)
    if kind == "presenter_base" then
        return anim.BLEND_MASK and anim.BLEND_MASK.UpperBody or 14
    end
    if kind == "audience_base" then
        return anim.BLEND_MASK and anim.BLEND_MASK.All or 15
    end
    if kind == "audience_beat" then
        return anim.BLEND_MASK and anim.BLEND_MASK.All or 15
    end
    return anim.BLEND_MASK and anim.BLEND_MASK.UpperBody or 14
end

sdpPlayLectureAnimationGroup = function(group, beat, kind)
    if not group then return false, "missing_group" end
    if not sdpLectureAnimationGroupAvailable(group) then return false, "group_unavailable" end
    if not (anim and anim.playBlended) then return false, "playBlended_unavailable" end
    local options = {
        loops = tonumber(beat and beat.loops) or 0,
        forceLoop = beat and beat.forceLoop == true or false,
        priority = anim.PRIORITY and anim.PRIORITY.Scripted or 13,
        blendMask = sdpLectureBlendMask(kind),
        autoDisable = not (beat and beat.autoDisable == false),
        speed = 1.0,
    }
    local ok, err = pcall(anim.playBlended, self, group, options)
    if ok and err == false then
        ok = false
        err = "playBlended_returned_false"
    end
    if not ok then return false, tostring(err) end
    return true, nil
end

sdpPlayLectureAudienceBaseAnimation = function(state)
    local lectureAudienceSessionId = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil
    sdpLectureTrace.log(debugLog, "audience_animation_attempt", "stage", "base", "session", tostring(lectureAudienceSessionId))
    if not sdpLectureAnimation then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "lecture_animation_unavailable")
        return false, "lecture_animation_unavailable"
    end
    if sdpLectureAnimation.audienceAnimationsEnabled and sdpLectureAnimation.audienceAnimationsEnabled() ~= true then
        local reason = sdpLectureAnimation.audienceUnsafeAssetReason or "audience_assets_disabled"
        sdpLogRejectedAudienceAssets(reason)
        sdpLectureTrace.log(debugLog, "audience_reaction_suppressed", "reason", "audience_assets_disabled", "session", tostring(lectureAudienceSessionId))
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "audience_assets_disabled", "stage", "base")
        return false, "audience_assets_disabled"
    end
    local group = sdpLectureAnimation.audienceBaseGroup and sdpLectureAnimation.audienceBaseGroup(state or sdpLectureAudienceAnimationState) or nil
    if not group then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "missing_audience_base_group")
        return false, "missing_audience_base_group"
    end
    if not sdpLectureAnimationGroupAvailable(group) then
        debugLog("lecture audience base animation unavailable", tostring(group))
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "group_unavailable", "group", tostring(group))
        return false, "group_unavailable"
    end
    if currentAnimation and currentAnimation ~= group and anim and anim.cancel then
        pcall(anim.cancel, self, currentAnimation)
    end
    local ok, err = sdpPlayLectureAnimationGroup(group, {
        loops = 999,
        forceLoop = true,
        autoDisable = false,
    }, "audience_base")
    if not ok then
        debugLog("lecture audience base animation failed", tostring(group), tostring(err))
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", tostring(err), "group", tostring(group))
        return false, err
    end
    currentAnimation = group
    currentSittingPoseAnimation = group
    debugLog("lecture audience base animation", tostring(group))
    sdpLectureTrace.log(debugLog, "audience_animation_started", "group", tostring(group), "session", tostring(lectureAudienceSessionId))
    return true, nil
end

sdpLectureBookVisible = function(visible)
    if not sdpLectureAnimation then return end
    if visible == true then
        if not (anim and anim.addVfx and anim.hasBone) then return end
        local attachBone = nil
        local bones = sdpLectureAnimation.bookBones or { sdpLectureAnimation.bookBone }
        for _, boneName in ipairs(bones) do
            local okBone, hasBone = pcall(anim.hasBone, self, boneName)
            if okBone and hasBone == true then
                attachBone = boneName
                break
            end
        end
        if not attachBone then return end
        if sdpLectureBookAttachedBone == attachBone then return end
        if sdpLectureBookAttachedBone and anim.removeVfx then
            pcall(anim.removeVfx, self, sdpLectureAnimation.bookVfxId)
        end
        local okAdd, addErr = pcall(anim.addVfx, self, sdpLectureAnimation.bookModel, {
            boneName = attachBone,
            loop = true,
            useAmbientLight = false,
            vfxId = sdpLectureAnimation.bookVfxId,
        })
        if okAdd then
            sdpLectureBookAttachedBone = attachBone
            debugLog("lecture book attached", tostring(attachBone))
            sdpLectureTrace.log(debugLog, "book_attachment", "bone", tostring(attachBone))
        else
            debugLog("lecture book attach failed", tostring(attachBone), tostring(addErr))
            sdpLectureTrace.log(debugLog, "book_attachment_failed", "bone", tostring(attachBone), "reason", tostring(addErr))
        end
    elseif anim and anim.removeVfx then
        pcall(anim.removeVfx, self, sdpLectureAnimation.bookVfxId)
        sdpLectureBookAttachedBone = nil
    end
end

sdpLectureMaybeSay = function(beat)
    if not (beat and sdpLectureAnimation) then return end
    local kind = tostring(beat.kind or "")
    if kind ~= "light" and kind ~= "expressive" then return end
    if sdpLectureAnimation.presenterSpeechSoundEnabled ~= true then
        sdpLectureTrace.log(debugLog, "presenter_speech_mouth_skipped", "reason", "speech_sound_disabled", "kind", kind)
        return
    end
    if not (sdpLectureAnimation.presenterSpeechSound and core and core.sound and core.sound.say and self) then
        sdpLectureTrace.log(debugLog, "presenter_speech_mouth_skipped", "reason", "speech_sound_unavailable", "kind", kind)
        return
    end
    if core.sound.isSayActive then
        local okActive, active = pcall(core.sound.isSayActive, self)
        if okActive and active == true then
            sdpLectureTrace.log(debugLog, "presenter_speech_mouth_skipped", "reason", "say_active", "kind", kind)
            return
        end
    end
    local okSay, sayErr = pcall(core.sound.say, sdpLectureAnimation.presenterSpeechSound, self)
    if okSay then
        sdpLectureTrace.log(debugLog, "presenter_speech_mouth_started", "sound", tostring(sdpLectureAnimation.presenterSpeechSound), "kind", kind)
    else
        sdpLectureTrace.log(debugLog, "presenter_speech_mouth_skipped", "reason", tostring(sayErr), "sound", tostring(sdpLectureAnimation.presenterSpeechSound), "kind", kind)
    end
end

sdpLogMissingLectureGroup = function(state, group, role)
    if not (state and group) then return end
    state.missingLogged = state.missingLogged or {}
    if state.missingLogged[group] then return end
    state.missingLogged[group] = true
    debugLog("lecture animation group unavailable", tostring(role), tostring(group))
end

sdpPlayPresenterLectureBeat = function(beat)
    if not (beat and sdpLecturePresenterAnimationState) then return false end
    local group = beat.group
    if not group then return false end
    local state = sdpLecturePresenterAnimationState
    if not sdpLectureAnimationGroupAvailable(group) then
        sdpLogMissingLectureGroup(state, group, "presenter")
        sdpLectureTrace.log(debugLog, "presenter_animation_skipped", "reason", "group_unavailable", "group", tostring(group), "kind", tostring(beat.kind))
        return false
    end
    if state.currentGroup and state.currentGroup ~= group and beat.kind == "base" then
        sdpCancelLectureAnimationGroup(state.currentGroup)
    end
    local ok, err = sdpPlayLectureAnimationGroup(group, beat, beat.kind == "base" and "presenter_base" or "presenter_beat")
    if not ok then
        debugLog("lecture presenter animation failed", tostring(group), tostring(err))
        sdpLectureTrace.log(debugLog, "presenter_animation_skipped", "reason", tostring(err), "group", tostring(group), "kind", tostring(beat.kind))
        return false
    end
    state.currentGroup = group
    sdpLectureBookVisible(beat.attachBook == true)
    sdpLectureMaybeSay(beat)
    debugLog("lecture presenter animation", tostring(beat.kind), tostring(group))
    sdpLectureTrace.log(debugLog, "presenter_animation_started", "kind", tostring(beat.kind), "group", tostring(group), "session", tostring(state.sessionId))
    return true
end

sdpStartLecturePresenterAnimation = function(payload)
    sdpLectureTrace.log(
        debugLog,
        "presenter_animation_attempt",
        "session", tostring(payload and payload.sessionId),
        "reason", tostring(payload and payload.reason),
        "hasPayload", tostring(payload ~= nil),
        "hasModule", tostring(sdpLectureAnimation ~= nil)
    )
    if not (payload and sdpLectureAnimation) then
        sdpLectureTrace.log(debugLog, "presenter_animation_skipped", "reason", payload and "lecture_animation_unavailable" or "missing_payload")
        return
    end
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    sdpLecturePresenterAnimationState = sdpLectureAnimation.initialPresenterState(payload, self.object and (self.object.recordId or self.object.id), now)
    sdpPlayPresenterLectureBeat({
        kind = "base",
        group = sdpLectureAnimation.presenterBaseGroup(sdpLecturePresenterAnimationState),
        loops = 999,
        forceLoop = true,
        autoDisable = false,
        attachBook = true,
    })
end

sdpRefreshLecturePresenterAnimation = function(payload)
    if not (payload and sdpLectureAnimation) then
        sdpLectureTrace.log(debugLog, "presenter_animation_skipped", "reason", payload and "lecture_animation_unavailable" or "missing_refresh_payload")
        return
    end
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    if not sdpLecturePresenterAnimationState then
        sdpStartLecturePresenterAnimation(payload)
        return
    end
    sdpLectureAnimation.refreshPresenterState(sdpLecturePresenterAnimationState, payload, now)
end

sdpStopLecturePresenterAnimation = function(reason)
    if sdpLecturePresenterAnimationState and sdpLecturePresenterAnimationState.currentGroup then
        sdpCancelLectureAnimationGroup(sdpLecturePresenterAnimationState.currentGroup)
    end
    sdpLectureBookVisible(false)
    if core and core.sound and core.sound.stopSay and self then
        pcall(core.sound.stopSay, self)
    end
    if sdpLecturePresenterAnimationState then
        debugLog("lecture presenter animation stopped", tostring(reason))
    end
    sdpLecturePresenterAnimationState = nil
end

sdpStartLectureAudienceAnimation = function(data)
    local lectureAudienceTarget = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.target() or false
    local lectureAudienceSessionId = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil
    sdpLectureTrace.log(
        debugLog,
        "audience_animation_attempt",
        "stage", "state_start",
        "lectureTarget", tostring(lectureAudienceTarget == true),
        "session", tostring(lectureAudienceSessionId),
        "hasModule", tostring(sdpLectureAnimation ~= nil)
    )
    if lectureAudienceTarget ~= true then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "not_lecture_audience_target")
        return
    end
    if not sdpLectureAnimation then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "lecture_animation_unavailable")
        return
    end
    if sdpLectureAnimation.audienceAnimationsEnabled and sdpLectureAnimation.audienceAnimationsEnabled() ~= true then
        sdpLectureAudienceAnimationState = nil
        sdpLogRejectedAudienceAssets(sdpLectureAnimation.audienceUnsafeAssetReason)
        sdpLectureTrace.log(debugLog, "audience_reaction_suppressed", "reason", "audience_assets_disabled", "session", tostring(lectureAudienceSessionId))
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "audience_assets_disabled", "stage", "state_start")
        return
    end
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    sdpLectureAudienceRestoreAnimation = sdpLectureAudienceRestoreAnimation
        or data and data.animation
        or currentSittingPoseAnimation
        or currentAnimation
    sdpLectureAudienceAnimationState = sdpLectureAnimation.initialAudienceState({
        lectureSessionId = lectureAudienceSessionId,
        sessionId = lectureAudienceSessionId,
        slotKey = currentSlotKey,
        audienceHeadFocusPosition = data and data.audienceHeadFocusPosition,
    }, self.object and (self.object.id or self.object.recordId), now)
    sdpPlayLectureAudienceBaseAnimation(sdpLectureAudienceAnimationState)
    debugLog("lecture audience animation state started", tostring(lectureAudienceSessionId), tostring(data and data.reason), "headFocus", tostring(data and data.audienceHeadFocusPosition))
end

sdpStopLectureAudienceAnimation = function(reason)
    if sdpLectureAudienceAnimationState then
        debugLog("lecture audience animation state stopped", tostring(reason))
    end
    sdpLectureAudienceAnimationState = nil
end

sdpProcessLectureAnimations = function(dt)
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    if sdpLecturePresenterAnimationState and sdpLecturePresenterAnimationState.active == true then
        local beat = sdpLectureAnimation.selectPresenterBeat(sdpLecturePresenterAnimationState, now)
        if beat then sdpPlayPresenterLectureBeat(beat) end
    end
    if sdpLectureAudienceAnimationState and sdpLectureAudienceAnimationState.active == true and isInteracting and currentInteractionType == "sitting" then
        local lectureAudienceSessionId = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil
        local beat, suppression = sdpLectureAnimation.selectAudienceBeat(sdpLectureAudienceAnimationState, now)
        if suppression then
            if suppression.reason == "audience_assets_disabled" then
                sdpLogRejectedAudienceAssets(suppression.assetReason)
            end
            sdpLectureTrace.log(
                debugLog,
                "audience_reaction_suppressed",
                "reason", tostring(suppression.reason),
                "lastGroup", tostring(suppression.lastGroup),
                "session", tostring(lectureAudienceSessionId)
            )
        end
        if beat and beat.group then
            sdpLectureTrace.log(
                debugLog,
                "audience_reaction_selected",
                "kind", tostring(beat.kind),
                "group", tostring(beat.group),
                "session", tostring(lectureAudienceSessionId),
                "headFocus", tostring(sdpLectureAudienceAnimationState and sdpLectureAudienceAnimationState.headFocusPosition),
                "repeatAvoided", tostring(beat.suppressedRepeat == true)
            )
            if sdpLectureAnimationGroupAvailable(beat.group) then
                local playKind = (beat.kind == "base_restore" or beat.baseRefresh == true) and "audience_base" or "audience_beat"
                local ok, err = sdpPlayLectureAnimationGroup(beat.group, beat, playKind)
                if ok then
                    if beat.kind == "base_restore" or beat.baseRefresh == true then
                        currentAnimation = beat.group
                        currentSittingPoseAnimation = beat.group
                    end
                    debugLog("lecture audience animation", tostring(beat.kind), tostring(beat.group))
                    sdpLectureTrace.log(debugLog, "audience_animation_started", "kind", tostring(beat.kind), "group", tostring(beat.group), "session", tostring(lectureAudienceSessionId))
                    if (beat.autoDisable == true or beat.holdUntilRestore == true) and sdpLectureAnimation.scheduleAudienceBaseRestore then
                        sdpLectureAnimation.scheduleAudienceBaseRestore(sdpLectureAudienceAnimationState, now, beat.restoreBaseAfter or 2.4)
                    end
                else
                    debugLog("lecture audience animation failed", tostring(beat.group), tostring(err))
                    sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", tostring(err), "group", tostring(beat.group), "kind", tostring(beat.kind))
                end
            else
                sdpLogMissingLectureGroup(sdpLectureAudienceAnimationState, beat.group, "audience")
                sdpLectureTrace.log(debugLog, "audience_reaction_suppressed", "reason", "group_unavailable", "group", tostring(beat.group), "kind", tostring(beat.kind))
                sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "group_unavailable", "group", tostring(beat.group), "kind", tostring(beat.kind))
            end
        end
    end
end

sdpOnLectureAudienceReaction = function(data)
    local lectureAudienceSessionId = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil
    if not (sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.target()) then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "reaction_not_lecture_audience", "group", tostring(data and data.group))
        return
    end
    if not sdpLectureAudienceAnimationState then
        sdpStartLectureAudienceAnimation({ reason = "reaction_bootstrap" })
    end
    if sdpLectureAnimation and sdpLectureAnimation.audienceAnimationsEnabled and sdpLectureAnimation.audienceAnimationsEnabled() ~= true then
        sdpLogRejectedAudienceAssets(sdpLectureAnimation.audienceUnsafeAssetReason)
        sdpLectureTrace.log(debugLog, "audience_reaction_suppressed", "reason", "audience_assets_disabled", "group", tostring(data and data.group), "kind", "lecture_end_reaction")
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "audience_assets_disabled", "group", tostring(data and data.group), "kind", "lecture_end_reaction")
        return
    end
    local group = tostring(data and data.group or "")
    if group == "" then
        sdpLectureTrace.log(debugLog, "audience_reaction_suppressed", "reason", "missing_reaction_group", "kind", "lecture_end_reaction")
        return
    end
    if not sdpLectureAnimationGroupAvailable(group) then
        sdpLogMissingLectureGroup(sdpLectureAudienceAnimationState, group, "audience")
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "group_unavailable", "group", group, "kind", "lecture_end_reaction")
        return
    end
    local ok, err = sdpPlayLectureAnimationGroup(group, {
        loops = 0,
        forceLoop = false,
        autoDisable = true,
    }, "audience_beat")
    if ok then
        local now = core.getSimulationTime and core.getSimulationTime() or 0
        if sdpLectureAnimation and sdpLectureAnimation.scheduleAudienceBaseRestore and not (data and data.skipBaseRestore == true) then
            sdpLectureAnimation.scheduleAudienceBaseRestore(sdpLectureAudienceAnimationState, now, tonumber(data and data.restoreBaseAfter) or 2.35)
        end
        debugLog("lecture audience animation", tostring(data and data.reason or "reaction"), group)
        sdpLectureTrace.log(debugLog, "audience_animation_started", "kind", tostring(data and data.reason or "reaction"), "group", group, "session", tostring(lectureAudienceSessionId))
    else
        debugLog("lecture audience animation failed", group, tostring(err))
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", tostring(err), "group", group, "kind", "lecture_end_reaction")
    end
end

local function stopCurrentAnim()
    clearSleepHelloSuppression("stop_current_anim")
    sdpStopLectureAudienceAnimation("stop_current_anim")
    if currentInteractionType == "sleeping" and currentAnimationQueued and anim and anim.clearAnimationQueue then
        pcall(anim.clearAnimationQueue, self, true)
        debugLog("sleep animation queue cleared", "reason", "stop_current_anim", "clearScripted", "true")
    end
    if currentInteractionType == "sitting" then
        interactionAnimation.forceCancelSittingGroups(debugLog, "stop_current_anim", self)
    end
    if currentAnimation and anim and anim.cancel then
        pcall(anim.cancel, self, currentAnimation)
    end
    currentAnimationQueued = false
end

local function clearInteractionTravelPackage(reason, destPosition, radius)
    if not (ai and ai.filterPackages) then return end

    destPosition = destPosition or targetPos
    radius = radius or (currentInteractionType == "sleeping" and 900 or 80)
    local preserveExternalTravel = externalAiTakeover.stopReasonPreservesExternalTravel(reason)

    ai.filterPackages(function(pkg)
        if not pkg or pkg.type ~= 'Travel' then return true end
        if preserveExternalTravel then return true end

        -- For sleeping, bed approach markers are often inside or behind bed
        -- collision. Once the global script begins the final transition, remove
        -- the Travel package so pathfinding does not keep fighting the scripted
        -- teleport into bed. For sitting, only remove the package if it
        -- is clearly the one this mod started.
        local pkgDest = pkg.destPosition or pkg.destination
        if reason == "station_assigned" then
            if not pkgDest then return true end
            if destPosition and (pkgDest - destPosition):length() <= radius then return false end
            if currentInteractionTravelDest and (pkgDest - currentInteractionTravelDest):length() <= radius then return false end
            return true
        end

        if currentInteractionType == "sleeping" then
            if not destPosition or not pkgDest then return false end
            return (pkgDest - destPosition):length() > radius
        end

        if destPosition and pkgDest and (pkgDest - destPosition):length() < radius then
            return false
        end

        return true
    end)

    if preserveExternalTravel then
        debugLog("preserved external travel", "type", tostring(currentInteractionType), "reason", tostring(reason))
    else
        debugLog("cleared interaction travel", "type", tostring(currentInteractionType), "reason", tostring(reason))
    end
end

local function sittingStandExitFloorHitReason(pos, floorZ)
    if not (pos and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return true, "ray_api_unavailable" end
    local from = pos + util.vector3(0, 0, 96)
    local to = pos + util.vector3(0, 0, -220)
    local collisionType = (nearby.COLLISION_TYPE.World or 0) + (nearby.COLLISION_TYPE.HeightMap or 0)
    local ok, result = pcall(function()
        return nearby.castRay(from, to, { collisionType = collisionType, radius = 0 })
    end)
    if not (ok and result and result.hit and result.hitPos) then
        return false, "no_floor_hit_void_risk"
    end
    local hitZ = tonumber(result.hitPos.z) or 0
    if floorZ and hitZ > (tonumber(floorZ) or 0) + 60 then
        return false, "floor_probe_hit_high_geometry", hitZ
    end
    return true, "floor_hit", hitZ
end

local function currentSittingStandExitData()
    local data = profiles.shallowCopy(currentInteractionData or {})
    data.actorPosition = self.object and self.object.position or nil
    data.object = data.object or currentObject
    data.objectId = data.objectId or (currentObject and currentObject.recordId)
    data.profile = data.profile or currentProfile
    data.slotName = data.slotName or currentSlotName
    data.slotKey = data.slotKey or currentSlotKey
    data.position = data.position or currentSittingBaseHitPos
    data.hitPos = data.hitPos or currentSittingBaseHitPos
    data.finalPosition = currentFinalPosition or data.finalPosition
    data.facingDirection = currentSittingFacingDirection or data.facingDirection
    data.facingObjectPosition = data.facingObjectPosition
    data.approachPos = data.approachPos or targetPos
    data.preInteractionPos = data.preInteractionPos
    data.seatCategory = sittingSeatCategory(currentProfile, currentObject)
    return data
end

local function validatedCurrentSittingStandExits(reason, opts)
    opts = opts or {}
    if not (sdpSittingStandExit and currentFinalPosition) then return nil, "missing_final_position" end
    local flags = nearby and nearby.NAVIGATOR_FLAGS
    local includeFlags = flags and ((flags.Walk or 0) + (flags.UsePathgrid or 0)) or nil
    local data = currentSittingStandExitData()
    local exits, meta = sdpSittingStandExit.validatedCandidates(data, util, {
        actorLabel = tostring(self.object and (self.object.recordId or self.object.id) or "<npc>"),
        debugLog = debugLog,
        rayBlockedBetween = rayBlockedBetween,
        floorHitReason = sittingStandExitFloorHitReason,
        maxNavSnap = 145,
        nearestWalkNavmeshPosition = function(pos)
            return nearestWalkNavmeshPosition(pos, includeFlags, 145, 38)
        end,
    }, {
        reason = reason,
        forced = opts.forced == true,
        allowEmergencyOrigin = opts.allowEmergencyOrigin == true,
        allowNearbyPads = opts.allowNearbyPads == true,
        preferNearbyPads = opts.preferNearbyPads == true,
        allowNearbySearch = opts.allowNearbySearch == true,
        logFallbackSelection = opts.logFallbackSelection,
    })
    if not exits or #exits == 0 then
        debugLog(
            "sitting stand exit release held",
            self.object and (self.object.recordId or self.object.id) or "<npc>",
            "reason", tostring(reason),
            "object", tostring(data.objectId),
            "slot", tostring(data.slotName),
            "rejected", tostring(meta and meta.rejected),
            "raw", tostring(meta and meta.raw)
        )
        return nil, "no_safe_sitting_stand_exit"
    end
    return exits, nil, meta
end

local function requestStand(reason)
    if standRequested then return end
    local safeSittingStandExits = nil
    local safeForcedSittingStandExits = nil
    local forcedMeta = nil
    if currentInteractionType == "sitting" and (isInteracting or interactionAssigned) then
        local forcedRelease = sdpSittingStandExit and sdpSittingStandExit.isForcedRelease and sdpSittingStandExit.isForcedRelease(reason, currentInteractionData) == true
        local rejectReason
        if forcedRelease then
            safeForcedSittingStandExits, rejectReason, forcedMeta = validatedCurrentSittingStandExits(reason, {
                forced = true,
                allowEmergencyOrigin = true,
                logFallbackSelection = true,
            })
            safeSittingStandExits = safeForcedSittingStandExits
        else
            safeSittingStandExits, rejectReason = validatedCurrentSittingStandExits(reason, {
                forced = false,
                allowEmergencyOrigin = false,
            })
        end
        if not safeSittingStandExits then
            debugLog("sitting release blocked", self.object.recordId or self.object.id, "reason", tostring(reason), "failure", tostring(rejectReason))
            return
        end
    end
    standRequested = true

    stopCurrentAnim()
    isInteracting = false
    interactionAssigned = false
    currentInteractionTravelDest = nil
    currentInteractionTravelStartedAt = nil
    currentInteractionStartedAt = nil
    currentInteractionData = nil
    currentInteractionInitialPlacement = false
    sdpCurrentCalibrationFill = false
    externalTravelTracker:reset()

    clearInteractionTravelPackage(reason)

    core.sendGlobalEvent('CancelInteractionForNpc', {
        npc = self.object,
        npcId = self.object and self.object.id,
        recordId = self.object and self.object.recordId,
        reason = reason,
        interactionType = currentInteractionType,
        slotKey = currentSlotKey,
        sittingStandExitPositions = safeSittingStandExits,
        sittingStandExitValidated = safeSittingStandExits ~= nil,
        sittingForcedStandExitPositions = safeForcedSittingStandExits,
        sittingForcedStandExitValidated = safeForcedSittingStandExits ~= nil,
        sittingForcedStandExitLog = forcedMeta and forcedMeta.firstFallbackLog or nil,
        sittingForcedStandExitLabel = forcedMeta and forcedMeta.firstLabel or nil,
    })
end

sdpBenchSlotContext = function()
    return {
        util = util,
        nearby = nearby,
        debugLog = debugLog,
        rayHitBelongsToObject = rayHitBelongsToObject,
        objectForwardDirection = objectForwardDirection or sittingPosePlanner.objectForwardDirection,
        objectRightDirection = objectRightDirection or sittingPosePlanner.objectRightDirection,
    }
end

legacyBenchAxisProbe = function(bench)
    return sdpSittingBenchSlots.legacyAxisProbe(sdpBenchSlotContext(), bench)
end

benchAxisExtents = function(bench, axis, label)
    return sdpSittingBenchSlots.axisExtents(sdpBenchSlotContext(), bench, axis, label)
end

determineBenchOrientationAndLength = function(bench)
    return sdpSittingBenchSlots.determineOrientationAndLength(sdpBenchSlotContext(), bench)
end

getBenchSittingPositions = function(bench, orientation, length, zLevel, profile)
    return sdpSittingBenchSlots.sittingPositions(sdpBenchSlotContext(), bench, orientation, length, zLevel, profile)
end

normalizeDirection3 = sittingPosePlanner.normalizeDirection3
objectForwardDirection = sittingPosePlanner.objectForwardDirection
objectRightDirection = sittingPosePlanner.objectRightDirection
directionDot2 = sittingPosePlanner.directionDot2

sdpFocusVisibleFromSeat = function(pos, data)
    if not (pos and data and data.facingObjectPosition and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return true end
    local from = pos + util.vector3(0, 0, 54)
    local to = data.facingObjectPosition + util.vector3(0, 0, 54)
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
    if not result.hit then return true end
    if data.facingObject and rayHitBelongsToObject(result.hitObject, data.facingObject) then return true end
    local hitDist = result.hitPos and (result.hitPos - from):length() or nil
    local focusDist = (to - from):length()
    if hitDist and focusDist and hitDist >= focusDist - 18 then return true end
    debugLog(
        "bench facing table focus blocked by world",
        "object", tostring(currentObject and currentObject.recordId),
        "focus", tostring(data.facingObjectId),
        "hit", tostring(result.hitObject and (result.hitObject.recordId or result.hitObject.id)),
        "hitDistance", tostring(hitDist),
        "focusDistance", tostring(focusDist)
    )
    return false
end

sdpSittingPoseContext = function(data)
    return {
        debugLog = debugLog,
        sittingSeatCategory = sittingSeatCategory,
        focusVisibleFromSeat = function(pos) return sdpFocusVisibleFromSeat(pos, data) end,
        focusSurfaceHitFromSeat = function() return data and data.facingSurfaceHit == true end,
        clearIgnoredFacingFocus = function(reason, kind, dot)
            if not data then return end
            data.ignoredFacingKind = data.facingKind or kind
            data.ignoredFacingObject = data.facingObject
            data.ignoredFacingObjectId = data.facingObjectId
            data.ignoredFacingObjectRefId = data.facingObjectRefId or (data.facingObject and sdpFocusMetadata.objectRefId(data.facingObject)) or nil
            data.ignoredFacingObjectModel = data.facingObjectModel
            data.ignoredFacingObjectName = data.facingObjectName
            data.ignoredFacingObjectScale = data.facingObjectScale
            data.ignoredFacingObjectPosition = data.facingObjectPosition
            data.ignoredFacingCandidates = data.facingCandidates
            data.ignoredFacingSurfaceHit = data.facingSurfaceHit == true
            data.ignoredFacingSurfaceSource = data.facingSurfaceSource
            data.ignoredFacingFocusDot = dot
            data.tableClearanceFocusCleared = true
            data.tableClearanceFocusClearReason = reason or "physical_forward_mismatch"
            data.facingKind = nil
            data.facingObject = nil
            data.facingObjectId = nil
            data.facingObjectRefId = nil
            data.facingObjectModel = nil
            data.facingObjectName = nil
            data.facingObjectScale = nil
            data.facingObjectPosition = nil
            data.facingCandidates = nil
            data.facingSurfaceHit = nil
            data.facingSurfaceSource = nil
        end,
    }
end

local function determineFacingDirection(sitPosition, orientation, preferredFacingDirection, preferredFacingKind, profile, obj, data)
    return sittingPosePlanner.determineFacingDirection(
        sdpSittingPoseContext(data),
        sitPosition,
        orientation,
        preferredFacingDirection,
        preferredFacingKind,
        profile,
        obj
    )
end

local function sittingCalibrationSnapshot()
    return {
        x = tonumber(runtimeSittingCalibration.x) or 0,
        y = tonumber(runtimeSittingCalibration.y) or 0,
        z = tonumber(runtimeSittingCalibration.z) or 0,
        yaw = tonumber(runtimeSittingCalibration.yaw) or 0,
    }
end

local function zeroSittingOffset()
    return sittingOffsetResolver.zero()
end

local function sittingProfileOffsetFor(profile, activity, animation)
    return sittingOffsetResolver.profileOffsetFor(profile, activity, animation, currentSlotName or currentSlotKey or "default")
end

sittingAnimationNormalizationFor = function(animation, profile)
    local buckets = profiles.objectYawBuckets and profiles.objectYawBuckets(currentObject) or {}
    return sittingOffsetResolver.normalizationFor("sitting", animation, {
        object = currentObject,
        recordId = currentObject and currentObject.recordId,
        model = profiles.objectModelPath(currentObject),
        profileModel = profile and profile.model,
        profileId = profile and profile.profileId,
        slotName = currentSlotName or currentSlotKey,
        yawBucket90 = buckets.yawBucket90,
        objectYawDeg = buckets.objectYawDeg,
    })
end

local function finalPositionForProfile(hitPos, facingDirection, profile, activity, animation)
    local objectScale = sdpScalePolicy and sdpScalePolicy.objectScaleForPlacement(currentObject) or 1
    local forwardOffset = (profile.finalForwardOffset or -7) * objectScale
    local zOffset = profile.finalZOffset or -36
    zOffset = sdpScalePolicy.actorPoseValue(self.object, zOffset)
    local fx, fy = facingDirection.x or 0, facingDirection.y or 0
    local flen = math.sqrt(fx * fx + fy * fy)
    if flen <= 0.001 then fx, fy, flen = 0, 1, 1 end
    local forward2 = util.vector2(fx / flen, fy / flen)
    local right2 = util.vector2(forward2.y, -forward2.x)

    local profileOffset = sittingProfileOffsetFor(profile, activity or "standard", animation)
    local animationOffset = sittingAnimationNormalizationFor(animation, profile)
    if animationOffset then
        local scaledZ = sdpScalePolicy.actorPoseValue(self.object, animationOffset.z or 0)
        animationOffset = { x = animationOffset.x, y = animationOffset.y, z = scaledZ, yaw = animationOffset.yaw }
    end
    local calibration = sittingCalibrationSnapshot()
    local placementOffset = sittingOffsetResolver.mergedOffset(profileOffset, animationOffset, calibration)
    local width = (placementOffset.x or 0) * objectScale
    local depth = (placementOffset.y or 0) * objectScale
    local furnitureHeight = ((profileOffset and profileOffset.z) or 0) + ((calibration and calibration.z) or 0)
    local animationHeight = animationOffset and animationOffset.z or 0
    local height = (furnitureHeight * objectScale) + animationHeight
    local yaw = math.rad(placementOffset.yaw)

    local planar = forward2 * (forwardOffset + depth) + right2 * width
    return hitPos + util.vector3(planar.x, planar.y, zOffset + height), yaw, profileOffset, calibration, animationOffset
end

function reprojectSittingFacingFromBody(finalPos, facingDirection, profile, data)
    if not (finalPos and data and data.facingObjectPosition) then return facingDirection, nil end
    local kind = data.facingKind
    if kind ~= "table" and kind ~= "bar" then return facingDirection, nil end
    local category = sittingSeatCategory(profile, currentObject)
    if category == "backed_chair" or category == "single_seat_bench" or category == "bench" then return facingDirection, nil end

    local bodyFacing = directionBetween(finalPos, data.facingObjectPosition)
    if not bodyFacing then return facingDirection, nil end
    local current = normalizeDirection3(facingDirection)
    if current and directionDot2(current, bodyFacing) > 0.985 then return facingDirection, nil end

    debugLog(
        "sitting facing reprojected from body position",
        "object", tostring(currentObject and currentObject.recordId),
        "focus", tostring(data.facingObjectId),
        "kind", tostring(kind),
        "from", tostring(facingDirection),
        "to", tostring(bodyFacing)
    )
    return bodyFacing, "body_to_" .. tostring(kind)
end

local function currentObjectLocalZ(pos)
    if not (currentObject and currentObject.position and pos) then return nil end
    return (pos.z or 0) - (currentObject.position.z or 0)
end

local function explicitProfileCanCorrectSittingZ(profile)
    if not (profile and profile.externalProfile == true) then return false end
    local category = sittingSeatCategory(profile, currentObject)
    return category == "backed_chair"
        or category == "stool"
        or category == "barstool"
        or category == "single_seat_bench"
end

local function correctExplicitProfileSittingZ(basePos, finalPos, profile, profileOffset, calibration, surfaceMode, animationOffset)
    if not (basePos and finalPos and explicitProfileCanCorrectSittingZ(profile) and currentObject and currentObject.position) then
        return finalPos, nil, nil
    end

    profileOffset = profileOffset or sittingProfileOffsetFor(profile, "standard", profile and profile.animation)
    animationOffset = animationOffset or sittingAnimationNormalizationFor(profile and profile.animation, profile)
    calibration = calibration or zeroSittingOffset()
    local profileZ = (profileOffset and profileOffset.z or 0) + (animationOffset and animationOffset.z or 0) + (calibration and calibration.z or 0)
    local finalZOffset = profile.finalZOffset or -36
    local expectedWorldZ = (basePos.z or 0) + finalZOffset + profileZ
    local actualWorldZ = finalPos.z or 0
    local actualLocalZ = currentObjectLocalZ(finalPos)
    if not actualLocalZ then return finalPos, nil, nil end

    local category = sittingSeatCategory(profile, currentObject)
    local tolerance = category == "backed_chair" and 22 or 26
    local drift = actualWorldZ - expectedWorldZ
    if math.abs(drift) <= tolerance then return finalPos, nil, nil end

    local corrected = util.vector3(finalPos.x, finalPos.y, expectedWorldZ)
    local correctedLocalZ = currentObjectLocalZ(corrected)
    debugLog(
        "sitting vertical corrected from explicit profile",
        "object", tostring(currentObject and currentObject.recordId),
        "profile", tostring(profile and profile.profileId),
        "category", tostring(category),
        "surface", tostring(surfaceMode),
        "actualWorldZ", tostring(actualWorldZ),
        "expectedWorldZ", tostring(expectedWorldZ),
        "actualLocalZ", tostring(actualLocalZ),
        "expectedLocalZ", tostring(correctedLocalZ),
        "seatSurfaceZ", tostring(basePos and basePos.z),
        "finalZOffset", tostring(finalZOffset),
        "profileZ", tostring(profileZ),
        "drift", tostring(drift),
        "tolerance", tostring(tolerance),
        "correctedLocalZ", tostring(correctedLocalZ)
    )
    return corrected, "explicit_profile_z_corrected", {
        result = "explicit_profile_z_corrected",
        actualWorldZ = actualWorldZ,
        expectedWorldZ = expectedWorldZ,
        actualLocalZ = actualLocalZ,
        expectedLocalZ = correctedLocalZ,
        correctedLocalZ = correctedLocalZ,
        seatSurfaceZ = basePos and basePos.z,
        finalZOffset = finalZOffset,
        profileZ = profileZ,
        drift = drift,
        tolerance = tolerance,
        category = category,
        surfaceMode = surfaceMode,
    }
end

local function rejectSittingFinalIfBlocked(finalPos, facingDirection, profile, data, selectedObject)
    return seatingClearance.rejectSittingFinalIfBlocked({
        nearby = nearby,
        util = util,
        currentObject = function() return selectedObject or currentObject end,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        debugLog = debugLog,
        objectModelPath = profiles.objectModelPath,
        objectName = function(obj)
            local ok, rec = pcall(function()
                if obj and obj.type and obj.type.record then return obj.type.record(obj) end
                return nil
            end)
            if ok and rec then return rec.name end
            return nil
        end,
        actorScale = function()
            local scale = self.object and self.object.scale or nil
            if type(scale) == "number" then return scale end
            return 1
        end,
    }, finalPos, facingDirection, profile, data)
end

local sittingFinalVerticalLooksSane

sittingFinalVerticalLooksSane = function(basePos, finalPos, profile)
    if not (basePos and finalPos) then return false end
    local category = sittingSeatCategory(profile, currentObject)
    if (category == "stool" or category == "barstool") and finalPos.z > (basePos.z or 0) - 8 then
        return false
    end
    local dz = math.abs((finalPos.z or 0) - ((basePos.z or 0) + (profile and profile.finalZOffset or -36)))
    local maxDelta = category == "bench" and 90 or 75
    if dz > maxDelta then return false end
    if finalPos.z > (basePos.z or 0) + 85 then return false end
    if finalPos.z < (basePos.z or 0) - 120 then return false end
    return true
end

function activeAnimationBlocksExternalCompat()
    local reason = sdpScriptedAnimationCompat
        and sdpScriptedAnimationCompat.activeBlockingAnimationReason(self.object, anim)
        or nil
    if reason then return true, reason end
    return false, nil
end

sdpAnimatedMorrowindSeeker = sdpAnimatedMorrowindSeekerModule.create({
    settings = function() return settings end,
    profiles = profiles,
    core = core,
    util = util,
    actor = function() return self.object end,
    interactionActive = function() return isInteracting or interactionAssigned end,
    activeDangerReason = activeDangerReason,
    activePackageBlocksNewInteraction = activePackageBlocksNewInteraction,
    activeAnimationBlocksExternalCompat = activeAnimationBlocksExternalCompat,
    currentObject = function() return currentObject end,
    setCurrentObject = function(obj) currentObject = obj end,
    sampleSittingSurface = sampleSittingSurface,
    normalizeDirection3 = normalizeDirection3,
    finalPositionForProfile = finalPositionForProfile,
    debugLog = debugLog,
})

function onAnimatedMorrowindAlignmentAssist(data)
    return sdpAnimatedMorrowindSeeker.onAssist(data)
end

local function sendResult(data)
    local ok, err = pcall(function()
        core.sendGlobalEvent("InteractionCheckResult", data)
    end)
    return ok, err
end

clearRejectedInitialSleepAnimation = function(data, reason)
    local interactionType = data and data.interactionType or currentInteractionType
    if interactionType ~= "sleeping" then return end
    if not (currentAnimationQueued or currentInteractionInitialPlacement == true or (data and data.initialPlacement == true)) then return end

    local clearReason = "sleep_rejected_" .. tostring(reason or "unknown")
    interactionAnimation.forceClearQueue(debugLog, clearReason, true, self)
    interactionAnimation.forceCancelSleepGroups(debugLog, clearReason, self)
end

clearStaleSleepAnimationBeforeSitting = function(data)
        if not (data and data.interactionType == "sitting") then return end
    local hadSleepState = currentInteractionType == "sleeping"
        or currentAnimationQueued == true
        or currentInteractionInitialPlacement == true

    local reason = data.manualAssign == true and "before_manual_sitting_consider" or "before_sitting_consider"
    if hadSleepState then
        interactionAnimation.forceClearQueue(debugLog, reason, true, self)
    end
    interactionAnimation.forceCancelSleepGroups(debugLog, reason, self)
    debugLog(
        "stale sleep animation cleared before sitting validation",
        "reason", reason,
        "hadSleepState", tostring(hadSleepState),
        "manualAssign", tostring(data.manualAssign == true),
        "object", tostring(data.object and data.object.recordId)
    )
end

local function reject(data, reason)
    if (data and data.interactionType or currentInteractionType) == "sitting" then
        calibrationExport.traceLocalSittingAcceptance(core, self.object, currentObject, currentSlotName, debugLog, "blocked", {
            object = data and data.object or currentObject,
            objectId = data and data.object and data.object.recordId or nil,
            slotName = data and data.slotName or currentSlotName,
            reason = reason,
        })
    end
    clearRejectedInitialSleepAnimation(data, reason)
    sendResult({
        npc = self.object,
        object = data and data.object or currentObject,
        objectId = data and data.object and data.object.recordId or nil,
        interactionType = data and data.interactionType or currentInteractionType,
        profileId = data and data.profileId or nil,
        slotKey = data and data.slotKey or currentSlotKey,
        slotName = data and data.slotName or currentSlotName,
        facingObject = data and data.facingObject or nil,
        facingObjectId = data and data.facingObjectId or nil,
        facingObjectRefId = data and data.facingObjectRefId or nil,
        facingObjectModel = data and data.facingObjectModel or nil,
        facingObjectName = data and data.facingObjectName or nil,
        facingObjectScale = data and data.facingObjectScale or nil,
        facingKind = data and data.facingKind or nil,
        facingReason = data and data.facingReason or nil,
        facingObjectPosition = data and data.facingObjectPosition or nil,
        facingCandidates = data and data.facingCandidates or nil,
        facingSurfaceHit = data and data.facingSurfaceHit == true,
        facingSurfaceSource = data and data.facingSurfaceSource or nil,
        ignoredFacingObject = data and data.ignoredFacingObject or nil,
        ignoredFacingObjectId = data and data.ignoredFacingObjectId or nil,
        ignoredFacingObjectRefId = data and data.ignoredFacingObjectRefId or nil,
        ignoredFacingObjectModel = data and data.ignoredFacingObjectModel or nil,
        ignoredFacingObjectName = data and data.ignoredFacingObjectName or nil,
        ignoredFacingObjectScale = data and data.ignoredFacingObjectScale or nil,
        ignoredFacingKind = data and data.ignoredFacingKind or nil,
        ignoredFacingObjectPosition = data and data.ignoredFacingObjectPosition or nil,
        ignoredFacingCandidates = data and data.ignoredFacingCandidates or nil,
        ignoredFacingSurfaceHit = data and data.ignoredFacingSurfaceHit == true,
        ignoredFacingSurfaceSource = data and data.ignoredFacingSurfaceSource or nil,
        ignoredFacingFocusDot = data and data.ignoredFacingFocusDot or nil,
        tableClearanceFocusCleared = data and data.tableClearanceFocusCleared == true,
        tableClearanceFocusClearReason = data and data.tableClearanceFocusClearReason or nil,
        currentHour = data and data.currentHour or nil,
        initialPlacement = data and data.initialPlacement == true,
        suppressInitialPlacementOverlay = data and data.suppressInitialPlacementOverlay == true,
        schedulerArrivalPlacement = data and data.schedulerArrivalPlacement == true,
        manualAssign = data and data.manualAssign == true,
        manualAssignRetryCount = data and data.manualAssignRetryCount,
        manualAssignOverrideTesting = data and data.manualAssignOverrideTesting == true,
        calibrationAction = data and data.calibrationAction == true,
        calibrationReason = data and data.calibrationReason,
        calibrationFill = data and data.calibrationFill == true,
        explicitFillOverride = data and data.explicitFillOverride == true,
        calibrationFillLabel = data and data.calibrationFillLabel,
        calibrationFillRole = data and data.calibrationFillRole,
        calibrationFillSource = data and data.calibrationFillSource,
        calibrationFillIndex = data and data.calibrationFillIndex,
        calibrationFillSessionId = data and data.calibrationFillSessionId,
        calibrationRuntimeObjectId = data and data.calibrationRuntimeObjectId,
        actorDisplayLabel = data and data.actorDisplayLabel,
        calibrationTestNpc = data and data.calibrationTestNpc == true,
        hardBlockerReason = data and data.hardBlockerReason,
        surfaceBlockerReason = data and data.surfaceBlockerReason,
        surfaceBlockerOverrideReason = data and data.surfaceBlockerOverrideReason,
        surfaceBlockerKind = data and data.surfaceBlockerKind,
        surfaceBlockerObjectId = data and data.surfaceBlockerObjectId,
        surfaceBlockerDistance = data and data.surfaceBlockerDistance,
        surfaceBlockerVertical = data and data.surfaceBlockerVertical,
        surfaceBlockerLocalReason = data and data.surfaceBlockerLocalReason,
        softBlockerReason = data and data.softBlockerReason,
        sleepSafetyReason = data and data.sleepSafetyReason,
        sleepSafetyDelta = data and data.sleepSafetyDelta,
        sleepSafetyLimit = data and data.sleepSafetyLimit,
        sleepSafetyOverrideReason = data and data.sleepSafetyOverrideReason,
        sleepAccessOverrideReason = data and data.sleepAccessOverrideReason,
        sleepRouteReason = data and data.sleepRouteReason,
        sleepRouteApproachName = data and data.sleepRouteApproachName,
        sleepRouteApproachPos = data and data.sleepRouteApproachPos,
        sleepRouteNavPos = data and data.sleepRouteNavPos,
        sleepRouteNavReason = data and data.sleepRouteNavReason,
        sleepRouteNavDelta = data and data.sleepRouteNavDelta,
        sleepRoutePathLength = data and data.sleepRoutePathLength,
        rescuePosition = sdpSleepInitialRejectRescuePoint and sdpSleepInitialRejectRescuePoint.position({
            currentObject = function() return currentObject end,
            currentSlotName = function() return currentSlotName end,
            currentFinalPosition = function() return currentFinalPosition end,
            selfObject = function() return self.object end,
            projectedObjectOffset = function(offset) return projectedObjectOffset(currentObject, offset) end,
            nearestWalkNavmeshPosition = nearestWalkNavmeshPosition,
            nearby = nearby,
            settings = settings,
            debugLog = debugLog,
        }, data, reason) or nil,
        approachPos = data and data.approachPos or currentSleepApproachPos,
        preInteractionPos = data and data.preInteractionPos,
        preInteractionRot = data and data.preInteractionRot,
        finalPosition = data and data.finalPosition or currentFinalPosition,
        exitPosition = data and data.exitPosition or currentSleepExitPositions and currentSleepExitPositions[1] or nil,
        sleepFloorPosition = data and data.sleepFloorPosition,
        usable = false,
        reason = reason,
    })
end

onSleepRouteDoorRejected = function(reason, door, detail)
    if currentInteractionType ~= "sleeping" or not interactionAssigned or isInteracting then return false end
    local reasonText = tostring(reason or "")
    local detailText = tostring(detail or "")
    local routeReason = (reasonText:find("trapped_route_door", 1, true) or detailText:find("trapped_route_door", 1, true)) and "trapped_route_door"
        or (reasonText:find("locked_route_door", 1, true) or detailText:find("locked_route_door", 1, true)) and "locked_route_door"
        or "blocked_route_door"
    debugLog(
        "sleep_route_local_door_rejected",
        self.object.recordId or self.object.id,
        "object", tostring(currentObject and currentObject.recordId),
        "door", tostring(door and (door.recordId or door.id)),
        "reason", tostring(routeReason),
        "detail", tostring(detail)
    )
    core.sendGlobalEvent('SitDownPleaseCloseRejectedSleepRouteDoor', {
        npc = self.object,
        door = door,
        reason = routeReason,
        detail = detail,
    })
    reject(currentInteractionData, routeReason)
    if onStopInteractionObject then
        local stopData = profiles.shallowCopy(currentInteractionData or {})
        stopData.reason = routeReason
        stopData.interactionType = "sleeping"
        stopData.forceClearSleepAnimation = true
        onStopInteractionObject(stopData)
    end
    return true
end

local function validateAssignedObject(data)
    if not data or not data.object then return false, "missing_object" end
    if not data.interactionType then return false, "unsupported_interaction_type" end

    local profile, reason = profiles.getProfileForObject(data.object, data.interactionType, settings)
    if not profile then return false, reason end

    if data.interactionType == "sleeping" and profile.isFallback == true and profiles.sleepFallbackCandidateStatus then
        local okSleep, sleepReason = profiles.sleepFallbackCandidateStatus(data.object)
        if okSleep ~= true then
            if settings.verboseDebug == true then
                debugLog("sleep candidate rejected non_sleep_object", "object", tostring(data.object and data.object.recordId), "model", tostring(profiles.objectModelPath(data.object)), "reason", tostring(sleepReason))
            end
            return false, "non_sleep_object"
        end
    end

    if data.profileId and profile.profileId ~= data.profileId and not profile.isFallback then
        return false, "profile_mismatch"
    end

    if data.ignoreTimeGate ~= true then
        local timeOk, timeReason = profiles.isInteractionAllowedByTime(data.interactionType, profile, settings, data.currentHour)
        if not timeOk then
            if manualAssignCanBypassLocalBlock(timeReason, data) then
                debugLog("nearest_manual_assign_override", "reason", tostring(timeReason), "bypass", "local_time_gate")
            else
                return false, timeReason
            end
        end
    end

    local packageBlocked, packageReason = activePackageBlocksNewInteraction(data.interactionType, data)
    if packageBlocked then return false, packageReason end

    local blacklisted, blacklistReason = isBlacklistedForInteraction(self.object, data.interactionType, data)
    if blacklisted then return false, blacklistReason end

    local scriptedAnimationReason = sdpScriptedAnimationCompat
        and sdpScriptedAnimationCompat.activeExternalAnimationReason(self.object, anim)
        or nil
    if scriptedAnimationReason then return false, scriptedAnimationReason end

    local chosenAnimation, chosenVariant = chooseAvailableAnimation(profile, data)
    if not chosenAnimation then
        debugLog(
            "missing animation group",
            "type", tostring(data.interactionType),
            "animation", tostring(profile.animation),
            "tested", tostring(animationDebugCandidates(profile, data)),
            "profile", tostring(profile.profileId),
            "object", tostring(data.object and data.object.recordId)
        )
        return false, "missing_animation"
    end

    profile = profiles.shallowCopy(profile)
    profile.animation = chosenAnimation
    profile.chosenAnimationVariant = chosenVariant
    if chosenVariant then
        profile.chosenAnimationLabel = chosenVariant.label or chosenVariant.name or chosenVariant.id
        if chosenVariant.speed then
            profile.animationOptions = profiles.shallowCopy(profile.animationOptions or {})
            profile.animationOptions.speed = chosenVariant.speed
        end
    end

    return true, nil, profile
end

local function sendAcceptedInteraction(data)
    sendResult(data)
end

projectedObjectOffset = function(obj, offset)
    local pos = objectLocalOffset(obj, offset)
    return projectToFloor(pos, offset and offset.z or 0)
end

local function sleepRouteContext()
    return {
        currentObject = function() return currentObject end,
        selfObject = function() return self.object end,
        projectedObjectOffset = function(offset) return projectedObjectOffset(currentObject, offset) end,
        objectLocalHorizontalOffset = objectLocalHorizontalOffset,
        projectToFloor = projectToFloor,
        nearestWalkNavmeshPosition = nearestWalkNavmeshPosition,
        sleepApproachReachability = sleepApproachReachability,
        horizontalDistance3 = horizontalDistance3,
        rayBlockedBetween = rayBlockedBetween,
        debugLog = debugLog,
    }
end

local function chooseSleepApproachPosition(data, slot, profile, finalPos)
    return sleepRoutePlanner.chooseApproach(sleepRouteContext(), data, slot, profile, finalPos)
end

local function chooseSleepExitPositions(slot, profile, finalPos, approachPos, approachName)
    return sleepRoutePlanner.chooseExits(sleepRouteContext(), slot, profile, finalPos, approachPos, approachName)
end

local function sleepFinalPlacementLocallySane(finalPos, approachPos, bedTop, profile, stage, data, surfaceMode, surfaceSamples)
    local saneProfile = profile
    local slotText = string.lower(tostring(currentSlotName or currentSlotKey or ""))
    local profileText = string.lower(tostring(profile and (profile.profileId or profile.bedType or profile.type) or ""))
    if slotText:find("top", 1, true) and profileText:find("bunk", 1, true) then
        saneProfile = profiles.shallowCopy(profile)
        saneProfile.sleepFinalMaxAboveApproachZ = saneProfile.sleepFinalMaxAboveApproachZ or 230
    end
    local serviceActor = false
    if sdpServicePolicy and types then
        local rec = sdpServicePolicy.record(self.object, types)
        serviceActor = sdpServicePolicy.isServiceOrFixedPost(rec) == true
    end
    return sleepRoutePlanner.finalPlacementLocallySane(sleepRouteContext(), finalPos, approachPos, bedTop, saneProfile, stage, {
        actor = self.object,
        actorPos = self.object and self.object.position,
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        surfaceMode = surfaceMode,
        surfaceSamples = surfaceSamples,
        surfaceTopPosition = data and (data.sleepObjectTopPosition or data.sleepSurfaceTopPosition),
        fallbackUsed = data and data.fallbackUsed,
        calibrationAction = data and data.calibrationAction,
        calibrationFill = data and data.calibrationFill,
        explicitFillOverride = data and data.explicitFillOverride,
        manualAssignOverrideTesting = data and data.manualAssignOverrideTesting,
        manualSleepEntryOverride = data and data.manualSleepEntryOverride,
        debugForced = data and data.debugForced,
        initialPlacement = data and data.initialPlacement,
        reachedValidSleepApproach = data and data.reachedValidSleepApproach,
        serviceActor = serviceActor,
    })
end


initialSleepActorAlreadyAtBed = function(data, obj)
    if not (data and data.initialPlacement == true and self.object and self.object.position and obj and obj.position) then
        return false, nil, nil
    end

    local horizontal = horizontalDistance3(self.object.position, obj.position)
    local vertical = math.abs((self.object.position.z or 0) - (obj.position.z or 0))
    if horizontal > 90 or vertical > 220 then return false, horizontal, vertical end

    local actorEye = self.object.position + util.vector3(0, 0, 54)
    local bedEye = obj.position + util.vector3(0, 0, 54)
    if rayBlockedBetween(actorEye, bedEye, 32) then
        if horizontal <= 45 and vertical <= 160 then
            debugLog(
                "sleep_entry_route_bypassed",
                "reason", "initial_very_near_bed_collision_bypass",
                "object", tostring(obj.recordId),
                "horizontal", tostring(horizontal),
                "vertical", tostring(vertical)
            )
            return true, horizontal, vertical
        end
        return false, horizontal, vertical
    end

    return true, horizontal, vertical
end

initialSleepMayBypassApproachRoute = function(data, profile, reason, details)
    return sleepRoutePlanner.initialMayBypassApproachRoute(data, profile, reason, details)
end


local function evaluateSleepingInteraction(data, profile)
    local slot = data.slot or {}
    local sleepOffset = slot.sleepOffset or profile.sleepOffset or { x = 0, y = 0, z = 0 }
    local bedTop, sampleCount, surfaceMode = sampledObjectTopCenter(currentObject, profile)
    bedTop = bedTop or currentObject.position
    local bedObjectTop = objectTopPosition(currentObject)
    data.sleepObjectTopPosition = bedObjectTop
    data.sleepSurfaceTopPosition = bedObjectTop
    local placementBedTop, placementSurfaceMode, sleepAnchorStabilized, sleepAnchorReason = sdpSleepAnchorResolver.resolve(currentObject, bedTop, surfaceMode, profile, {
        slot = slot,
        slotName = currentSlotName,
    })
    if sleepAnchorStabilized and settings.verboseDebug == true then
        debugLog(
            "sleep placement anchor stabilized",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "slot", tostring(currentSlotName or currentSlotKey),
            "surfaceMode", tostring(surfaceMode),
            "placementSurfaceMode", tostring(placementSurfaceMode),
            "reason", tostring(sleepAnchorReason),
            "rawBedTop", tostring(bedTop),
            "anchor", tostring(placementBedTop)
        )
    elseif sleepAnchorReason == "bunk_or_canopy_requires_surface_evidence" and settings.verboseDebug == true then
        debugLog(
            "sleep placement anchor stabilization skipped",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "slot", tostring(currentSlotName or currentSlotKey),
            "surfaceMode", tostring(surfaceMode),
            "reason", tostring(sleepAnchorReason)
        )
    end

    -- Lying pose groups from VA/Dynamic Actors are not aligned like sitting
    -- idles. The surface sample finds the bed/mattress top, but the actor root
    -- needs to sit below that surface or the prone body appears high/in the
    -- ceiling. A separate yaw offset also lets the pose run lengthwise with
    -- beds instead of 90 degrees across them.
    local variant = profile.chosenAnimationVariant or {}
    local bedType = string.lower(tostring(profile.bedType or profile.type or ""))
    local recordId = string.lower(tostring(currentObject and currentObject.recordId or ""))
    local normalizeVaSleepRoot = recordId == "active_com_bunk_01"
        or recordId == "active_com_bunk_02"
    local bunkSlotUsesConvertedRoot = recordId == "active_com_bunk_01"
        or recordId == "active_com_bunk_02"
        or recordId == "active_de_p_bed_09"
    local variantRootZOffset = variant.sleepRootZOffset
    if profile.externalProfile ~= true or normalizeVaSleepRoot ~= true or bedType == "bedroll" or bedType == "hammock" then
        variantRootZOffset = nil
    end
    local rootZOffset = slot.sleepRootZOffset or variantRootZOffset or profile.sleepRootZOffset or 0
    local poseYawOffset = slot.sleepPoseYawOffset or variant.sleepPoseYawOffset or profile.sleepPoseYawOffset or 0
    local profileRootLocalOffset = slot.sleepRootLocalOffset or variant.sleepRootLocalOffset or profile.sleepRootLocalOffset
    local explicitBunkSlot = (bedType == "top_bunk" or bedType == "bottom_bunk" or tostring(slot.name or currentSlotName or "") == "sleep_top" or tostring(slot.name or currentSlotName or "") == "sleep_bottom")
        and profileRootLocalOffset ~= nil
    if explicitBunkSlot and bunkSlotUsesConvertedRoot and slot.sleepRootZOffset == nil and rootZOffset ~= 0 then
        debugLog(
            "bunk root z normalized",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "slot", tostring(currentSlotName),
            "bedType", tostring(bedType),
            "oldRootZOffset", tostring(rootZOffset),
            "newRootZOffset", "0",
            "reason", "explicit_bunk_slot_offset"
        )
        rootZOffset = 0
    elseif explicitBunkSlot and rootZOffset ~= 0 then
        debugLog(
            "bunk root z retained",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "slot", tostring(currentSlotName),
            "bedType", tostring(bedType),
            "rootZOffset", tostring(rootZOffset),
            "reason", "explicit_bunk_slot_uses_pose_root_drop"
        )
    end
    local buckets = profiles.objectYawBuckets and profiles.objectYawBuckets(currentObject) or {}
    local sleepAnimationOffset = sittingOffsetResolver.normalizationFor("sleeping", profile.animation, {
        object = currentObject,
        recordId = currentObject and currentObject.recordId,
        model = profiles.objectModelPath(currentObject),
        profileModel = profile and profile.model,
        profileId = profile.profileId,
        slotName = currentSlotName or currentSlotKey,
        yawBucket90 = buckets.yawBucket90,
        objectYawDeg = buckets.objectYawDeg,
    })
    if sleepAnimationOffset then
        local scaledZ = sdpScalePolicy.actorPoseValue(self.object, sleepAnimationOffset.z or 0)
        sleepAnimationOffset = { x = sleepAnimationOffset.x, y = sleepAnimationOffset.y, z = scaledZ, yaw = sleepAnimationOffset.yaw }
        local resolvedOffset, normalizationPolicyReason, originalNormalization = sdpSleepNormalizationPolicy.resolve(sleepAnimationOffset, {
            profile = profile,
            object = currentObject,
            slotName = currentSlotName or currentSlotKey,
            surfaceMode = placementSurfaceMode or surfaceMode,
            animation = profile and profile.animation,
        })
        if normalizationPolicyReason then
            debugLog(
                "sleep animation normalization suppressed",
                "reason", tostring(normalizationPolicyReason),
                "object", tostring(currentObject and currentObject.recordId),
                "profile", tostring(profile and profile.profileId),
                "slot", tostring(currentSlotName or currentSlotKey),
                "animation", tostring(profile and profile.animation),
                "source", tostring(profile and profile.orientationVariant and profile.orientationVariant.sourceName),
                "original", calibrationExport.offsetLabel(originalNormalization),
                "applied", calibrationExport.offsetLabel(resolvedOffset),
                "surfaceMode", tostring(placementSurfaceMode or surfaceMode)
            )
        end
        sleepAnimationOffset = resolvedOffset
    end

    local calibrationOffset = {
        x = tonumber(runtimeSleepCalibration.x) or 0,
        y = tonumber(runtimeSleepCalibration.y) or 0,
        z = tonumber(runtimeSleepCalibration.z) or 0,
    }
    local calibrationYawDegrees = tonumber(runtimeSleepCalibration.yaw) or 0
    local calibrationOverridesProfile = calibrationOffset.x ~= 0 or calibrationOffset.y ~= 0 or calibrationOffset.z ~= 0
        or calibrationYawDegrees ~= 0

    -- Menu nudges layer on top of the saved profile until reset.
    local base = profileRootLocalOffset or { x = 0, y = 0, z = 0 }
    local visibleRootLocalOffset = {
        x = (base.x or 0) + calibrationOffset.x,
        y = (base.y or 0) + calibrationOffset.y,
        z = (base.z or 0) + calibrationOffset.z,
    }
    if calibrationYawDegrees ~= 0 then poseYawOffset = poseYawOffset + math.rad(calibrationYawDegrees) end
    rootZOffset = sdpScalePolicy.actorPoseValue(self.object, rootZOffset)

    local placementRootLocalOffset = {
        x = visibleRootLocalOffset.x + (sleepAnimationOffset.x or 0),
        y = visibleRootLocalOffset.y + (sleepAnimationOffset.y or 0),
        z = visibleRootLocalOffset.z + (sleepAnimationOffset.z or 0),
    }
    local placementPoseYawOffset = poseYawOffset + math.rad(sleepAnimationOffset.yaw or 0)

    local finalRot = yawFromObject(currentObject, (slot.rotationOffset or profile.rotationOffset or 0) + placementPoseYawOffset)
    local sleepLateralOffset = slot.sleepLateralOffset or profile.sleepLateralOffset or 0
    local finalPos = placementBedTop
        + objectLocalHorizontalOffset(currentObject, sleepOffset)
        + objectLocalHorizontalOffset(currentObject, placementRootLocalOffset)
        + yawLateralHorizontalOffset(finalRot, sleepLateralOffset)
        + util.vector3(0, 0, (sleepOffset.z or 0) + (placementRootLocalOffset and placementRootLocalOffset.z or 0) + rootZOffset)

    finalPos = sdpSleepFinalSafety.repairedOrOriginal({
        finalPosition = finalPos,
        surfacePosition = placementBedTop,
        bedTop = placementBedTop,
        object = currentObject,
        profile = profile,
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        surfaceMode = placementSurfaceMode,
        surfaceSamples = sampleCount,
        surfaceTopPosition = bedObjectTop,
        fallbackUsed = data and data.fallbackUsed,
        data = data,
        debugLog = debugLog,
        stage = "pre_approach",
    })

    local approachPos, approachName, approachReachable, approachReason, approachDetails
    if data.calibrationAction == true and data.disallowSleepDoorAssist == true then
        local preflightPos, preflightName, preflightReachable, preflightReason = chooseSleepApproachPosition(data, slot, profile, finalPos)
        if preflightReachable ~= true and (
            preflightReason == "public_bed_requires_door_assist"
            or preflightReason == "locked_route_door"
            or preflightReason == "blocked_route_door"
        ) then
            debugLog(
                "manual sleep public bed rejected",
                "object", tostring(currentObject and currentObject.recordId),
                "slot", tostring(currentSlotName or currentSlotKey),
                "reason", "public_bed_requires_door_assist",
                "routeReason", tostring(preflightReason),
                "approach", tostring(preflightPos),
                "approachName", tostring(preflightName)
            )
            if sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, "public_bed_requires_door_assist", "sleep_door_assist") then
                approachPos = finalPos
                approachName = "manual_sleep_door_assist_override"
                approachReachable = true
                approachReason = "manual_sleep_door_assist_override"
                approachDetails = { manualOverride = true }
            else
                reject(data, "public_bed_requires_door_assist")
                return
            end
        end
    end
    if data.calibrationAction == true and approachReachable ~= true then
        approachPos = data.approachPos or currentSleepApproachPos or targetPos or finalPos
        approachName = currentSleepApproachName or data.approachName or "locked"
        approachReachable = true
        approachReason = "calibration_locked"
        approachDetails = {}
    else
        approachPos, approachName, approachReachable, approachReason, approachDetails = chooseSleepApproachPosition(data, slot, profile, finalPos)
    end
    if approachReachable ~= true then
        local lockedRouteSeen = approachDetails and approachDetails.sawLockedRouteDoorReject == true
        local alreadyAtBed, bedHorizontal, bedVertical = false, nil, nil
        if not lockedRouteSeen then
            alreadyAtBed, bedHorizontal, bedVertical = initialSleepActorAlreadyAtBed(data, currentObject)
        end
        if alreadyAtBed == true then
            approachPos = self.object.position
            approachName = "initial_near_bed"
            approachReachable = true
            approachReason = "initial_near_bed_route_bypass"
            approachDetails = {
                actorAlreadyAtBed = true,
                bedHorizontal = bedHorizontal,
                bedVertical = bedVertical,
            }
            debugLog(
                "sleep_entry_route_bypassed",
                "reason", tostring(approachReason),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "bedHorizontal", tostring(bedHorizontal),
                "bedVertical", tostring(bedVertical)
            )
        elseif initialSleepMayBypassApproachRoute(data, profile, approachReason, approachDetails) then
            approachPos = finalPos
            approachName = "initial_profiled_bed_direct"
            approachDetails = {
                initialRouteBypass = true,
                originalReason = approachReason,
            }
            approachReachable = true
            approachReason = "initial_profiled_bed_route_bypass"
            debugLog(
                "sleep_entry_route_bypassed",
                "reason", tostring(approachReason),
                "originalReason", tostring(approachDetails.originalReason),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName)
            )
        elseif data.initialPlacement == true and approachDetails and approachDetails.sawLockedRouteDoorReject == true then
            debugLog(
                "sleep_entry_route_bypass_suppressed",
                "reason", "locked_route_door",
                "originalReason", tostring(approachReason),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "doorReason", tostring(approachDetails.routeDoorReason)
            )
        end
    end
    if approachReachable ~= true then
        if sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, approachReason or "no_path_to_bed", "sleep_approach_route") then
            local originalReason = approachReason
            approachPos = finalPos
            approachName = "manual_sleep_route_override"
            approachReachable = true
            approachReason = "manual_sleep_route_override"
            approachDetails = { manualOverride = true, originalReason = originalReason }
        else
            if data then
                data.sleepRouteReason = approachReason or "no_path_to_bed"
                data.sleepRouteApproachName = approachName
                data.sleepRouteApproachPos = approachPos
                data.sleepRouteNavPos = approachDetails and approachDetails.navPos or nil
                data.sleepRouteNavReason = approachDetails and approachDetails.navReason or nil
                data.sleepRouteNavDelta = approachDetails and approachDetails.navDelta or nil
                data.sleepRoutePathLength = approachDetails and approachDetails.pathLength or approachDetails and approachDetails.routeDist or nil
            end
            debugLog(
                "sleep_entry_rejected",
                "reason", tostring(approachReason or "no_path_to_bed"),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "approach", tostring(approachName),
                "approachPos", tostring(approachPos),
                "navPos", approachDetails and tostring(approachDetails.navPos) or "nil",
                "navReason", approachDetails and tostring(approachDetails.navReason) or "nil",
                "navDelta", approachDetails and tostring(approachDetails.navDelta) or "nil",
                "pathLength", approachDetails and tostring(approachDetails.pathLength or approachDetails.routeDist) or "nil",
                "closedStatus", approachDetails and pathStatusLabel(approachDetails.closedStatus) or "nil",
                "openStatus", approachDetails and pathStatusLabel(approachDetails.openStatus) or "nil"
            )
            reject(data, approachReason or "no_path_to_bed")
            return
        end
    end

    if not sdpSleepFinalSafety.checkLocal({
        data = data,
        stage = "before_inward",
        object = currentObject,
        model = profiles.objectModelPath(currentObject),
        profile = profile,
        slotName = currentSlotName,
        finalPosition = finalPos,
        approachPosition = approachPos,
        bedTop = placementBedTop,
        surfaceTopPosition = bedObjectTop,
        debugLog = debugLog,
        validate = function()
            return sleepFinalPlacementLocallySane(finalPos, approachPos, placementBedTop, profile, "before_inward", data, placementSurfaceMode, sampleCount)
        end,
        noteOverride = function(reason) noteManualAssignOverride(data, reason or "sleep_final_position_invalid") end,
        manualBypass = function(reason, label)
            return sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, reason or "sleep_final_position_invalid", label)
        end,
        reject = function(reason) reject(data, reason or "sleep_final_position_invalid") end,
    }) then return end

    local inwardOffset = slot.sleepInwardOffsetFromApproach or variant.sleepInwardOffsetFromApproach or profile.sleepInwardOffsetFromApproach or 0
    if inwardOffset ~= 0 then
        local inward = nil
        if approachName == "left" then
            inward = { x = inwardOffset, y = 0, z = 0 }
        elseif approachName == "right" then
            inward = { x = -inwardOffset, y = 0, z = 0 }
        elseif approachName == "foot" then
            inward = { x = 0, y = inwardOffset, z = 0 }
        elseif approachName == "head" then
            inward = { x = 0, y = -inwardOffset, z = 0 }
        end
        if inward then
            finalPos = finalPos + objectLocalHorizontalOffset(currentObject, inward)
        end
    end

    if not sdpSleepFinalSafety.checkLocal({
        data = data,
        stage = "after_inward",
        object = currentObject,
        model = profiles.objectModelPath(currentObject),
        profile = profile,
        slotName = currentSlotName,
        finalPosition = finalPos,
        approachPosition = approachPos,
        bedTop = placementBedTop,
        surfaceTopPosition = bedObjectTop,
        debugLog = debugLog,
        validate = function()
            return sleepFinalPlacementLocallySane(finalPos, approachPos, placementBedTop, profile, "after_inward", data, placementSurfaceMode, sampleCount)
        end,
        noteOverride = function(reason) noteManualAssignOverride(data, reason or "sleep_final_position_invalid") end,
        manualBypass = function(reason, label)
            return sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, reason or "sleep_final_position_invalid", label)
        end,
        reject = function(reason) reject(data, reason or "sleep_final_position_invalid") end,
    }) then return end

    local sleepRouteStage = { ok = true, needsDoorAssist = false }
    if data.initialPlacement ~= true and approachDetails and approachDetails.needsDoorAssist == true then
        sleepRouteStage = sdpSleepLocalDoorAssistModule.prepareInitialStage(sdpSleepDoorAssistContext, approachDetails, approachPos)
        if sleepRouteStage.ok ~= true then
            debugLog(
                "sleep_entry_rejected",
                "reason", tostring(sleepRouteStage.rejectReason),
                "detail", tostring(sleepRouteStage.detail),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "approach", tostring(approachName),
                "approachPos", tostring(approachPos),
                "door", tostring(sleepRouteStage.door and (sleepRouteStage.door.recordId or sleepRouteStage.door.id))
            )
            reject(data, sleepRouteStage.rejectReason or "blocked_route_door")
            return
        end
        debugLog(
            "route_door_assist",
            "initial_stage_prepared",
            "actor", tostring(self.object and (self.object.recordId or self.object.id)),
            "door", tostring(sleepRouteStage.door and (sleepRouteStage.door.recordId or sleepRouteStage.door.id)),
            "usePoint", tostring(sleepRouteStage.startPosition),
            "postDoorWaypoint", tostring(sleepRouteStage.postDoorWaypoint),
            "approach", tostring(approachPos)
        )
    end

    local sleepClutter, sleepClutterDistance, sleepClutterZ, sleepClutterReason, sleepClutterKind = sleepSurfaceClutter.surfaceBlocker({
        nearby = nearby,
        profiles = profiles,
        debugLog = debugLog,
        surfaceMode = placementSurfaceMode or surfaceMode,
        surfaceSamples = sampleCount or 0,
        finalPosition = finalPos,
        slot = slot,
        slotName = currentSlotName,
    }, placementBedTop or finalPos, currentObject, profile)
    if sleepClutter then
        data.surfaceBlockerReason = "sleep_surface_blocked_by_item"
        data.surfaceBlockerKind = tostring(sleepClutterKind or "sleep_surface_blocked_by_item")
        data.surfaceBlockerObjectId = tostring(sleepClutter.recordId or sleepClutter.id)
        data.surfaceBlockerDistance = sleepClutterDistance
        data.surfaceBlockerVertical = sleepClutterZ
        data.surfaceBlockerLocalReason = sleepClutterReason
        if data.manualAssignOverrideTesting == true or data.explicitFillOverride == true or data.calibrationFill == true or data.calibrationAction == true then
            data.surfaceBlockerOverrideReason = "sleep_surface_blocked_by_item"
            data.softBlockerReason = tostring(sleepClutterKind or "sleep_surface_blocked_by_item")
            noteManualAssignOverride(data, "sleep_surface_blocked_by_item")
            debugLog(
                "sleep surface clutter override",
                "object", tostring(currentObject and currentObject.recordId),
                "slot", tostring(currentSlotName),
                "clutter", tostring(sleepClutter.recordId or sleepClutter.id),
                "kind", tostring(sleepClutterKind),
                "distance", tostring(sleepClutterDistance),
                "vertical", tostring(sleepClutterZ)
            )
        else
            data.softBlockerReason = tostring(sleepClutterKind or "sleep_surface_blocked_by_item")
            debugLog(
                "sleep surface rejected clutter",
                "object", tostring(currentObject and currentObject.recordId),
                "slot", tostring(currentSlotName),
                "clutter", tostring(sleepClutter.recordId or sleepClutter.id),
                "kind", tostring(sleepClutterKind),
                "distance", tostring(sleepClutterDistance),
                "vertical", tostring(sleepClutterZ),
                "reason", tostring(sleepClutterReason)
            )
            reject(data, "sleep_surface_blocked_by_item")
            return
        end
    end

    local exitPositions, exitName
    if data.calibrationAction == true and currentSleepExitPositions then
        exitPositions = currentSleepExitPositions
        exitName = currentSleepExitName or "locked"
    else
        exitPositions, exitName = chooseSleepExitPositions(slot, profile, finalPos, approachPos, approachName)
    end
    if not sleepRoutePlanner.hasExitPositions(exitPositions) then
        if sleepRoutePlanner.missingExitMayBeOverridden(data) then
            noteManualAssignOverride(data, "no_safe_sleep_stand_exit")
        else
            reject(data, "no_safe_sleep_stand_exit")
            return
        end
    end

    targetPos = approachPos or finalPos
    currentFinalPosition = finalPos
    currentFinalRotation = finalRot
    currentSleepApproachPos = approachPos
    currentSleepApproachName = approachName
    currentSleepExitPositions = exitPositions
    currentSleepExitName = exitName
    currentSleepBedTop = placementBedTop
    currentSleepRawBedTop = bedTop
    currentSleepObjectTop = bedObjectTop
    if sdpSleepDoorAssist then
        sdpSleepDoorAssist.setNeedsDoorAssist(approachDetails and approachDetails.needsDoorAssist == true or false)
    end
    currentSleepProfileRootOffset = profileRootLocalOffset
    currentSleepCalibrationOffset = calibrationOffset
    currentSleepMergedRootOffset = visibleRootLocalOffset
    currentSleepAnimationNormalizationOffset = sleepAnimationOffset
    currentSleepCalibrationYawDegrees = calibrationYawDegrees
    currentSleepPoseYawOffset = poseYawOffset
    currentSleepSurfaceMode = placementSurfaceMode
    currentSleepRawSurfaceMode = surfaceMode
    currentSleepSurfaceSamples = sampleCount or 0
    data.sleepCalibrationWarningReason = sdpSleepCalibrationWarnings.reason(placementSurfaceMode, calibrationOffset, finalPos, placementBedTop, {
        profile = profile,
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        objectId = currentObject and currentObject.recordId,
    })
    runtimeSleepCalibration.sleepCalibrationWarningReason = data.sleepCalibrationWarningReason
    interactionAssigned = true
    applySleepHelloSuppression()

    debugLog(
        "resolved sleep transform",
        "object", tostring(currentObject.recordId),
        "model", tostring(profiles.objectModelPath(currentObject)),
        "targetType", "bed",
        "slot", tostring(currentSlotName),
        "profile", tostring(profile.profileId),
        "profileSource", tostring(profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile)),
        "selectionSource", tostring(profile.profileSelectionSource),
        "selectionReason", tostring(profile.profileSelectionReason),
        "selectionKey", tostring(profile.profileSelectionKey),
        "profileOffset", profileRootLocalOffset and (tostring(profileRootLocalOffset.x) .. "," .. tostring(profileRootLocalOffset.y) .. "," .. tostring(profileRootLocalOffset.z or 0)) or "nil",
        "animationOffset", calibrationExport.offsetLabel(sleepAnimationOffset),
        "calibration", tostring(calibrationOffset.x) .. "," .. tostring(calibrationOffset.y) .. "," .. tostring(calibrationOffset.z) .. ",yaw=" .. tostring(calibrationYawDegrees),
        "surfaceMode", tostring(surfaceMode),
        "surfaceSamples", tostring(sampleCount),
        "bedTop", tostring(bedTop),
        "rootZOffset", tostring(rootZOffset),
        "final", tostring(finalPos),
        "rotation", tostring(finalRot)
    )

    local slotIndexForAudit = 1
    if currentSlotName == "sleep_b" or currentSlotName == "sleep_right" or currentSlotName == "sleep_top" then
        slotIndexForAudit = 2
    elseif currentSlotName == "sleep_c" then
        slotIndexForAudit = 3
    end
    debugLog(
        "sleep z resolution audit",
        "cell", tostring(currentObject.cell and (currentObject.cell.name or currentObject.cell.id)),
        "object", tostring(currentObject.recordId),
        "model", tostring(profiles.objectModelPath(currentObject)),
        "targetType", "bed",
        "slot", tostring(currentSlotName),
        "slotIndex", tostring(slotIndexForAudit),
        "profileKey", tostring(profile.profileId),
        "profileSource", tostring(profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile)),
        "selectionSource", tostring(profile.profileSelectionSource),
        "selectionReason", tostring(profile.profileSelectionReason),
        "selectionKey", tostring(profile.profileSelectionKey),
        "rawProfileZ", tostring(profileRootLocalOffset and profileRootLocalOffset.z or nil),
        "generatedDefaultZ", tostring((slot and slot.sleepRootLocalOffset and slot.sleepRootLocalOffset.z) or (profile and profile.sleepRootLocalOffset and profile.sleepRootLocalOffset.z) or nil),
        "animationZ", tostring(sleepAnimationOffset and sleepAnimationOffset.z or 0),
        "calibrationZ", tostring(calibrationOffset and calibrationOffset.z or 0),
        "syncedGroupedZAdjustment", tostring((data and data.syncSlotZ == true) and (calibrationOffset and calibrationOffset.z or 0) or 0),
        "finalResolvedZ", tostring(finalPos and finalPos.z),
        "offsetSource", tostring(profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile)),
        "rootZOffset", tostring(rootZOffset)
    )

    if bedType == "top_bunk"
        or bedType == "bottom_bunk"
        or tostring(currentSlotName or "") == "sleep_top"
        or tostring(currentSlotName or "") == "sleep_bottom"
        or recordId:find("bunk", 1, true) then
        debugLog(
            "bunk resolved sleep transform",
            "object", tostring(currentObject.recordId),
            "model", tostring(profiles.objectModelPath(currentObject)),
            "bedType", tostring(bedType),
            "profile", tostring(profile.profileId),
            "profileSource", tostring(profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile)),
            "selectionSource", tostring(profile.profileSelectionSource),
            "selectionReason", tostring(profile.profileSelectionReason),
            "selectionKey", tostring(profile.profileSelectionKey),
            "slot", tostring(currentSlotName),
            "slotClass", tostring(currentSlotName == "sleep_top" and "top" or (currentSlotName == "sleep_bottom" and "bottom" or bedType)),
            "surfaceMode", tostring(surfaceMode),
            "rootZOffset", tostring(rootZOffset),
            "profileOffset", profileRootLocalOffset and (tostring(profileRootLocalOffset.x) .. "," .. tostring(profileRootLocalOffset.y) .. "," .. tostring(profileRootLocalOffset.z or 0)) or "nil",
            "animationOffset", calibrationExport.offsetLabel(sleepAnimationOffset),
            "calibration", tostring(calibrationOffset.x) .. "," .. tostring(calibrationOffset.y) .. "," .. tostring(calibrationOffset.z) .. ",yaw=" .. tostring(calibrationYawDegrees),
            "zSmoothing", tostring(data and data.calibrationAction == true),
            "final", tostring(finalPos),
            "rotation", tostring(finalRot)
        )
    end

    debugLog(
        "accepted sleep local",
        "object", tostring(currentObject.recordId),
        "model", tostring(profiles.objectModelPath(currentObject)),
        "profile", tostring(profile.profileId),
        "slot", tostring(currentSlotName),
        "approach", tostring(approachName),
        "route", tostring(approachReason),
        "navDelta", tostring(approachDetails and approachDetails.navDelta),
        "pathLength", tostring(approachDetails and approachDetails.pathLength),
        "exit", tostring(exitName),
        "animation", tostring(profile.animation),
        "selectionSource", tostring(profile.profileSelectionSource),
        "selectionReason", tostring(profile.profileSelectionReason),
        "selectionKey", tostring(profile.profileSelectionKey),
        "variant", tostring(profile.chosenAnimationLabel),
        "surfaceSamples", tostring(sampleCount),
        "surfaceMode", tostring(placementSurfaceMode),
        "rawSurfaceMode", tostring(surfaceMode),
        "surfaceAnchorStabilized", tostring(sleepAnchorStabilized),
        "surfaceCenterOffset", lastSleepSurfaceCenterOffset and ((tostring(lastSleepSurfaceCenterOffset.x or 0)) .. "," .. (tostring(lastSleepSurfaceCenterOffset.y or 0))) or "nil",
        "rootZOffset", tostring(rootZOffset),
        "poseYawOffset", tostring(poseYawOffset),
        "rootLocalOffset", placementRootLocalOffset and (tostring(placementRootLocalOffset.x) .. "," .. tostring(placementRootLocalOffset.y) .. "," .. tostring(placementRootLocalOffset.z or 0)) or "nil",
        "animationNormalizationOffset", calibrationExport.offsetLabel(sleepAnimationOffset),
        "lateralOffset", tostring(sleepLateralOffset),
        "calibrationOffset", tostring(calibrationOffset.x) .. "," .. tostring(calibrationOffset.y) .. "," .. tostring(calibrationOffset.z),
        "calibrationYaw", tostring(calibrationYawDegrees),
        "calibrationMergedWithProfile", tostring(calibrationOverridesProfile),
        "profileRootLocalOffset", profileRootLocalOffset and (tostring(profileRootLocalOffset.x) .. "," .. tostring(profileRootLocalOffset.y) .. "," .. tostring(profileRootLocalOffset.z or 0)) or "nil",
        "axis", "slot_lateral=actor_perpendicular",
        "profileOverridesAxis", tostring(profile.sleepAxisOverride ~= nil or slot.sleepAxisOverride ~= nil),
        "inwardOffset", tostring(inwardOffset),
        "final", tostring(finalPos),
        "rotation", tostring(finalRot),
        "hour", tostring(data.currentHour),
        "bedtime", tostring(data.actorBedtime),
        "wake", tostring(data.actorWakeTime)
    )
    calibrationPoseState.debugBaseline(debugLog, "sleep calibration baseline", {
        actor = self.object,
        object = currentObject,
        model = profiles.objectModelPath(currentObject),
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        profileId = profile.profileId,
        profileOffset = profileRootLocalOffset,
        currentDelta = { x = calibrationOffset.x, y = calibrationOffset.y, z = calibrationOffset.z, yaw = calibrationYawDegrees },
        finalPosition = finalPos,
        sleepSurfacePosition = placementBedTop,
        sleepRawSurfacePosition = bedTop,
        sleepSurfaceMode = placementSurfaceMode,
        sleepRawSurfaceMode = surfaceMode,
        sleepSurfaceAnchorStabilized = sleepAnchorStabilized == true,
        sleepSurfaceSamples = sampleCount or 0,
        finalRotation = finalRot,
        surfaceMode = placementSurfaceMode,
        basisSource = profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile),
    })
    if profile and currentObject and (profile.bedType == "double" or (profile.slots and #profile.slots > 1) or tostring(currentObject.recordId or "") == "active_de_r_bed_20") then
        debugLog("multi-slot bed profile selected", tostring(currentObject.recordId), "profile", tostring(profile.profileId), "bedType", tostring(profile.bedType), "slots", tostring(profile.slots and #profile.slots or 0))
        debugLog(tostring(currentObject.recordId) .. " slot selected", tostring(currentSlotName or currentSlotKey))
        if tostring(currentObject.recordId or "") == "active_de_r_bed_20" then
            debugLog("active_de_r_bed_20 calibrated slot promoted", tostring(currentSlotName or currentSlotKey))
            if not (profile.slots and #profile.slots > 1) then
                debugLog("active_de_r_bed_20 other slot missing calibration")
            end
        end
    end
    if profile.orientationVariantSource == "explicit_profile_orientation_variant" then
        debugLog("profile orientation variant selected", tostring(currentObject.recordId), "slot", tostring(currentSlotName), "yawBucket90", tostring(profile.orientationYawBucket90), "source", tostring(profile.orientationVariantSource))
    elseif currentObject and currentObject.recordId == "active_com_bunk_02" then
        debugLog("profile orientation variant fallback", tostring(currentObject.recordId), "slot", tostring(currentSlotName), "yawBucket90", tostring(profile.orientationYawBucket90), "source", tostring(profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile)))
    end

    if data.suppressAcceptedResult == true then return true, data end

    sendAcceptedInteraction({
        npc = self.object,
        object = currentObject,
        objectId = currentObject.recordId,
        model = profiles.objectModelPath(currentObject),
        profile = profile,
        profileId = profile.profileId,
        profileSelectionTrace = profile.profileSelectionTrace,
        profileSelectionSource = profile.profileSelectionSource,
        profileSelectionReason = profile.profileSelectionReason,
        profileSelectionKey = profile.profileSelectionKey,
        interactionType = currentInteractionType,
        slot = slot,
        slotKey = currentSlotKey,
        slotName = currentSlotName,
        approachPos = approachPos,
        approachName = approachName,
        sleepRouteStatus = approachReason,
        sleepRouteNeedsDoorAssist = approachDetails and approachDetails.needsDoorAssist == true or false,
        sleepRouteStartPosition = sleepRouteStage.startPosition,
        sleepRoutePostDoorWaypoint = sleepRouteStage.postDoorWaypoint,
        exitPosition = exitPositions and exitPositions[1] or approachPos,
        exitPositions = exitPositions,
        hitPos = finalPos,
        finalPosition = finalPos,
        finalRotation = finalRot,
        sleepSurfacePosition = placementBedTop,
        sleepRawSurfacePosition = bedTop,
        sleepFloorPosition = finalPos and projectToFloor(finalPos, 0) or nil,
        sleepSurfaceMode = placementSurfaceMode,
        sleepRawSurfaceMode = surfaceMode,
        sleepSurfaceAnchorStabilized = sleepAnchorStabilized == true,
        sleepSurfaceSamples = sampleCount or 0,
        sleepObjectTopPosition = bedObjectTop,
        sleepSurfaceTopPosition = bedObjectTop,
        surfaceMode = placementSurfaceMode,
        rawSurfaceMode = surfaceMode,
        surfaceSamples = sampleCount or 0,
        bedTop = placementBedTop,
        rawBedTop = bedTop,
        animation = profile.animation,
        profileOffset = profileRootLocalOffset,
        animationOffset = sleepAnimationOffset,
        calibration = {
            x = calibrationOffset.x,
            y = calibrationOffset.y,
            z = calibrationOffset.z,
            yaw = calibrationYawDegrees,
        },
        fallbackUsed = data.fallbackUsed,
        currentHour = data.currentHour,
        initialPlacement = data.initialPlacement == true,
        suppressInitialPlacementOverlay = data.suppressInitialPlacementOverlay == true,
        schedulerArrivalPlacement = data.schedulerArrivalPlacement == true,
        sleepPhase = data.sleepPhase,
        actorBedtime = data.actorBedtime,
        actorWakeTime = data.actorWakeTime,
        sleepWakeBias = data.sleepWakeBias,
        observedPlayerOverride = data.observedPlayerOverride,
        calibrationAction = data.calibrationAction == true,
        calibrationReason = data.calibrationReason,
        calibrationFill = data.calibrationFill == true,
        explicitFillOverride = data.explicitFillOverride == true,
        calibrationFillLabel = data.calibrationFillLabel,
        calibrationFillRole = data.calibrationFillRole,
        calibrationFillSource = data.calibrationFillSource,
        calibrationFillIndex = data.calibrationFillIndex,
        calibrationFillSessionId = data.calibrationFillSessionId,
        calibrationRuntimeObjectId = data.calibrationRuntimeObjectId,
        actorDisplayLabel = data.actorDisplayLabel,
        calibrationTestNpc = data.calibrationTestNpc == true,
        lectureAudienceTarget = data.lectureAudienceTarget == true,
        lectureAudienceShortcut = data.lectureAudienceShortcut == true,
        lectureAudienceTeleport = data.lectureAudienceTeleport == true,
        lecternPosition = data.lecternPosition,
        stationPosition = data.stationPosition,
        audienceHeadFocusPosition = data.audienceHeadFocusPosition,
        audienceSource = data.audienceSource,
        manualAssign = data.manualAssign == true,
        manualAssignRetryCount = data.manualAssignRetryCount,
        manualAssignOverrideTesting = data.manualAssignOverrideTesting == true,
        manualAssignOverrideApplied = data.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = data.manualAssignOverrideReasons and table.concat(data.manualAssignOverrideReasons, ",") or nil,
        sleepRouteReason = data.sleepRouteReason,
        sleepRouteApproachName = data.sleepRouteApproachName,
        sleepRouteApproachPos = data.sleepRouteApproachPos,
        sleepRouteNavPos = data.sleepRouteNavPos,
        sleepRouteNavReason = data.sleepRouteNavReason,
        sleepRouteNavDelta = data.sleepRouteNavDelta,
        sleepRoutePathLength = data.sleepRoutePathLength,
        surfaceBlockerReason = data.surfaceBlockerReason,
        surfaceBlockerOverrideReason = data.surfaceBlockerOverrideReason,
        surfaceBlockerKind = data.surfaceBlockerKind,
        surfaceBlockerObjectId = data.surfaceBlockerObjectId,
        surfaceBlockerDistance = data.surfaceBlockerDistance,
        surfaceBlockerVertical = data.surfaceBlockerVertical,
        surfaceBlockerLocalReason = data.surfaceBlockerLocalReason,
        softBlockerReason = data.softBlockerReason,
        hardBlockerReason = data.hardBlockerReason,
        sleepSafetyReason = data.sleepSafetyReason,
        sleepSafetyDelta = data.sleepSafetyDelta,
        sleepSafetyLimit = data.sleepSafetyLimit,
        sleepSafetyRepairReason = data.sleepSafetyRepairReason,
        sleepSafetyRepairDelta = data.sleepSafetyRepairDelta,
        sleepSafetyRepairLimit = data.sleepSafetyRepairLimit,
        sleepCalibrationWarningReason = data.sleepCalibrationWarningReason,
        releaseSafetyGateEnabled = data.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = data.releaseSafetyGateStatus,
        releaseSafetyGateReason = data.releaseSafetyGateReason,
        releaseSafetyGateCell = data.releaseSafetyGateCell,
        releaseSafetyGateRegion = data.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = data.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = data.releaseSafetyGateLabel,
        usable = true
    })
    return true, data
end

local function resetInteractionRouteState()
    if sdpSleepDoorAssist then sdpSleepDoorAssist.reset() end
    currentInteractionTravelDest = nil
    currentInteractionTravelStartedAt = nil
    currentInteractionStartedAt = nil
    externalTravelTracker:reset()
end

sdpCreateSittingLocalResolverContext = function()
    return {
        actor = self.object,
        core = core,
        nearby = nearby,
        util = util,
        profiles = profiles,
        calibrationExport = calibrationExport,
        seatingClearance = seatingClearance,
        seatingClutterBlockers = seatingClutterBlockers,
        sittingFacingRefiner = sdpSittingFacingRefiner,
        manualAssignment = sdpManualAssignment,
        currentObject = currentObject,
        currentSlotName = currentSlotName,
        currentAnimation = currentAnimation,
        sampleSittingSurface = sampleSittingSurface,
        debugLog = debugLog,
        noteManualAssignOverride = noteManualAssignOverride,
        isBenchFurniture = isBenchFurniture,
        determineBenchOrientationAndLength = determineBenchOrientationAndLength,
        getBenchSittingPositions = getBenchSittingPositions,
        seatClutterContext = seatClutterContext,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        determineFacingDirection = determineFacingDirection,
        chooseAvailableAnimation = chooseAvailableAnimation,
        finalPositionForProfile = finalPositionForProfile,
        reprojectSittingFacingFromBody = reprojectSittingFacingFromBody,
        correctExplicitProfileSittingZ = correctExplicitProfileSittingZ,
        rejectSittingFinalIfBlocked = rejectSittingFinalIfBlocked,
        sittingFinalVerticalLooksSane = sittingFinalVerticalLooksSane,
        sittingLockedRouteRejectReason = sittingLockedRouteRejectReason,
        reject = reject,
    }
end

local function onConsiderInteractionObject(data)
    local dead, deadReason = actorDeadReason(self.object)
    if dead then
        core.sendGlobalEvent('InteractionCheckResult', {
            npc = self.object,
            object = data and data.object or nil,
            objectId = data and data.objectId or nil,
            profileId = data and data.profileId or nil,
            interactionType = data and data.interactionType or nil,
            slotKey = data and data.slotKey or nil,
            slotName = data and data.slotName or nil,
            initialPlacement = data and data.initialPlacement == true,
            suppressInitialPlacementOverlay = data and data.suppressInitialPlacementOverlay == true,
            manualAssign = data and data.manualAssign == true,
            calibrationFill = data and data.calibrationFill == true,
            explicitFillOverride = data and data.explicitFillOverride == true,
            calibrationFillLabel = data and data.calibrationFillLabel,
            calibrationFillRole = data and data.calibrationFillRole,
            calibrationFillSource = data and data.calibrationFillSource,
            calibrationFillIndex = data and data.calibrationFillIndex,
            calibrationFillSessionId = data and data.calibrationFillSessionId,
            calibrationRuntimeObjectId = data and data.calibrationRuntimeObjectId,
            actorDisplayLabel = data and data.actorDisplayLabel,
            calibrationTestNpc = data and data.calibrationTestNpc == true,
            usable = false,
            reason = deadReason or "dead_actor",
        })
        return
    end

    standRequested = false
    interactionAssigned = false
    targetPos = nil
    aiPollTimer = 0

    clearStaleSleepAnimationBeforeSitting(data)
    seedManualAssignOverrideReason(data)

    local ok, reason, profile = validateAssignedObject(data)
    if not ok then
        reject(data, reason)
        return
    end

    currentObject = data.object
    currentProfile = profile
    currentInteractionType = data.interactionType
    currentInteractionData = data
    currentInteractionInitialPlacement = data.initialPlacement == true
    sdpCurrentCalibrationFill = data.calibrationFill == true or data.calibrationTestNpc == true
    currentAnimation = profile.animation
    currentAnimationOptions = profile.animationOptions
    currentSlot = data.slot
    currentSlotKey = data.slotKey
    currentSlotName = data.slotName
    local resetCalibration, targetKey = calibrationPoseState.shouldReset(currentCalibrationTargetKey, currentObject, currentInteractionType, currentSlotKey, profile and profile.profileId)
    if resetCalibration then
        resetRuntimeCalibrationOffsets("new_target")
        currentCalibrationTargetKey = targetKey
    end
    restoreIncomingCalibration(data)
    local runtimeIdentity = {
        actorDisplayLabel = data.actorDisplayLabel or data.calibrationFillLabel,
        calibrationFillLabel = data.calibrationFillLabel,
        calibrationFillRole = data.calibrationFillRole,
        calibrationFillSource = data.calibrationFillSource,
        calibrationFillIndex = data.calibrationFillIndex,
        calibrationRuntimeObjectId = data.calibrationRuntimeObjectId,
    }
    if currentInteractionType == "sleeping" then
        for key, value in pairs(runtimeIdentity) do runtimeSleepCalibration[key] = value end
    else
        for key, value in pairs(runtimeIdentity) do runtimeSittingCalibration[key] = value end
    end
    resetInteractionRouteState()
    if sdpLectureLocalAudienceState then
        sdpLectureLocalAudienceState.resetFromAssignment(data)
    end

    if currentInteractionType == "sleeping" then
        evaluateSleepingInteraction(data, profile)
        return
    end


    if currentInteractionType ~= "sitting" then
        reject(data, "unsupported_interaction_type")
        return
    end

    local sittingResolution = sdpSittingLocalResolver.resolve(sdpCreateSittingLocalResolverContext(), data, profile)
    if not sittingResolution then return end

    local sitPosition = sittingResolution.sitPosition
    local surfaceMode = sittingResolution.surfaceMode
    local surfaceSamples = sittingResolution.surfaceSamples
    local poseActivity = sittingResolution.poseActivity
    local poseAnimation = sittingResolution.poseAnimation
    local finalPos = sittingResolution.finalPos
    local finalRot = sittingResolution.finalRot
    local profileOffset = sittingResolution.profileOffset
    local appliedCalibration = sittingResolution.appliedCalibration
    local animationOffset = sittingResolution.animationOffset
    local facingDirection = sittingResolution.facingDirection
    local facingReason = sittingResolution.facingReason
    local solverSnapshot = sittingResolution.solverSnapshot
    local clearanceMeta = sittingResolution.clearanceMeta
    local zCorrectionMeta = sittingResolution.zCorrectionMeta
    local adjustReason = sittingResolution.adjustReason
    currentAnimation = sittingResolution.currentAnimation
    currentFinalPosition = finalPos
    currentFinalRotation = finalRot
    currentSittingBaseHitPos = sitPosition
    currentSittingFacingDirection = facingDirection
    currentSittingAppliedCalibration = appliedCalibration
    currentSittingAppliedProfileOffset = profileOffset
    currentSittingAppliedAnimationOffset = animationOffset
    currentSittingPoseActivity = poseActivity
    currentSittingPoseAnimation = poseAnimation
    runtimeSittingCalibration.facingKind = data.facingKind
    runtimeSittingCalibration.facingReason = facingReason
    runtimeSittingCalibration.solverSnapshot = solverSnapshot
    runtimeSittingCalibration.manualAssignOverrideApplied = data.manualAssignOverrideApplied == true
    runtimeSittingCalibration.manualAssignOverrideReason = data.manualAssignOverrideReasons and table.concat(data.manualAssignOverrideReasons, ",") or nil
    calibrationExport.logSittingSolverBasis(debugLog, "sitting solver basis", currentObject, profile, solverSnapshot)
    calibrationExport.logDemidChairBasisComparison(debugLog, self.object, currentObject, solverSnapshot, clearanceMeta or zCorrectionMeta or { result = "accepted" })
    calibrationPoseState.debugBaseline(debugLog, "sitting calibration baseline", {
        actor = self.object,
        object = currentObject,
        model = profiles.objectModelPath(currentObject),
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        profileId = profile.profileId,
        profileOffset = profileOffset,
        currentDelta = appliedCalibration,
        finalPosition = finalPos,
        finalRotation = finalRot,
        surfaceMode = surfaceMode,
        basisSource = facingReason,
    })

    local sittingStandExitPositions, sittingStandRejectReason = validatedCurrentSittingStandExits("local_acceptance", {
        forced = false,
        allowEmergencyOrigin = false,
        allowNearbyPads = true,
        preferNearbyPads = true,
        allowNearbySearch = true,
    })
    local sittingForcedStandExitPositions, sittingForcedRejectReason, sittingForcedMeta = validatedCurrentSittingStandExits("local_acceptance_forced", {
        forced = true,
        allowEmergencyOrigin = true,
        logFallbackSelection = false,
    })
    if not sittingStandExitPositions and not (sdpSittingStandExit.assignmentMayUseForcedAcceptance and sdpSittingStandExit.assignmentMayUseForcedAcceptance(data)) then
        reject(data, sittingStandRejectReason or "no_safe_sitting_stand_exit")
        return
    end
    if not (sittingStandExitPositions or sittingForcedStandExitPositions) then
        reject(data, sittingForcedRejectReason or "no_safe_sitting_stand_exit")
        return
    end

    targetPos = data.approachPos or sitPosition
    interactionAssigned = true
    if data.lectureAudienceTarget == true then
        sdpStationRouteAssist.setPath({
            stationType = "lecture_audience",
            slotName = data.slotName,
            slotKey = data.slotKey,
            object = data.facingObject or data.object,
            objectId = data.facingObjectId or data.objectId,
            finalPosition = targetPos,
            stationPosition = data.stationPosition,
            lecternPosition = data.lecternPosition,
            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
            lectureSessionId = data.lectureSessionId,
            stationSlotKey = data.stationSlotKey,
            startedAt = core.getSimulationTime and core.getSimulationTime() or 0,
        })
        debugLog("lecture audience pathing tracked", tostring(data.facingObjectId or data.objectId), tostring(data.slotName), "target", tostring(targetPos))
    end

    local focusLog, focusModelLog, focusCandidatesLog = sdpFocusMetadata.logSummary(data)
    debugLog(
        "accepted local",
        "type", tostring(currentInteractionType),
        "object", tostring(currentObject.recordId),
        "model", tostring(profiles.objectModelPath(currentObject)),
        "profile", tostring(profile.profileId),
        "slot", tostring(currentSlotName),
        "facing", tostring(facingReason),
        "fallback", tostring(data.fallbackUsed),
        "clearance", tostring(adjustReason),
        "animation", tostring(currentSittingPoseAnimation),
        "selectionSource", tostring(profile.profileSelectionSource),
        "selectionReason", tostring(profile.profileSelectionReason),
        "selectionKey", tostring(profile.profileSelectionKey),
        "surface", tostring(surfaceMode),
        "surfaceSamples", tostring(surfaceSamples),
        "focus", tostring(focusLog),
        "focusModel", tostring(focusModelLog),
        "focusCandidates", tostring(focusCandidatesLog),
        "profileOffset", currentSittingAppliedProfileOffset and (tostring(currentSittingAppliedProfileOffset.x) .. "," .. tostring(currentSittingAppliedProfileOffset.y) .. "," .. tostring(currentSittingAppliedProfileOffset.z) .. ",yaw=" .. tostring(currentSittingAppliedProfileOffset.yaw)) or "0,0,0,yaw=0",
        "animationOffset", currentSittingAppliedAnimationOffset and (tostring(currentSittingAppliedAnimationOffset.x) .. "," .. tostring(currentSittingAppliedAnimationOffset.y) .. "," .. tostring(currentSittingAppliedAnimationOffset.z) .. ",yaw=" .. tostring(currentSittingAppliedAnimationOffset.yaw)) or "0,0,0,yaw=0",
        "calibration", tostring(currentSittingAppliedCalibration and (tostring(currentSittingAppliedCalibration.x) .. "," .. tostring(currentSittingAppliedCalibration.y) .. "," .. tostring(currentSittingAppliedCalibration.z) .. ",yaw=" .. tostring(currentSittingAppliedCalibration.yaw)) or "0,0,0,yaw=0"),
        "profileRowHint", tostring(profile.profileId or currentObject.recordId or "") .. "	<seatType>	" .. tostring(profiles.objectModelPath(currentObject) or "") .. "	<localX>	<localY>	<localZ>	<yaw>	copy to chairProfiles.txt",
        "hour", tostring(data.currentHour)
    )

    local resultPayload = {
        npc = self.object,
        object = currentObject,
        objectId = currentObject.recordId,
        model = profiles.objectModelPath(currentObject),
        profile = profile,
        profileId = profile.profileId,
        profileSelectionTrace = profile.profileSelectionTrace,
        profileSelectionSource = profile.profileSelectionSource,
        profileSelectionReason = profile.profileSelectionReason,
        profileSelectionKey = profile.profileSelectionKey,
        interactionType = currentInteractionType,
        slot = data.slot,
        slotKey = currentSlotKey,
        slotName = currentSlotName,
        approachPos = data.approachPos or sitPosition,
        preInteractionPos = data.preInteractionPos,
        preInteractionRot = data.preInteractionRot,
        hitPos = sitPosition,
        finalPosition = finalPos,
        finalRotation = finalRot,
        animation = currentSittingPoseAnimation,
        profileOffset = profileOffset,
        animationOffset = animationOffset,
        calibration = appliedCalibration,
        facingDirection = facingDirection,
        facingObject = data.facingObject,
        facingObjectId = data.facingObjectId,
        facingObjectRefId = data.facingObjectRefId,
        facingObjectModel = data.facingObjectModel,
        facingObjectName = data.facingObjectName,
        facingObjectScale = data.facingObjectScale,
        facingKind = data.facingKind,
        facingReason = facingReason,
        facingObjectPosition = data.facingObjectPosition,
        facingCandidates = data.facingCandidates,
        facingSurfaceHit = data.facingSurfaceHit == true,
        facingSurfaceSource = data.facingSurfaceSource,
        ignoredFacingObject = data.ignoredFacingObject,
        ignoredFacingObjectId = data.ignoredFacingObjectId,
        ignoredFacingObjectRefId = data.ignoredFacingObjectRefId,
        ignoredFacingObjectModel = data.ignoredFacingObjectModel,
        ignoredFacingObjectName = data.ignoredFacingObjectName,
        ignoredFacingObjectScale = data.ignoredFacingObjectScale,
        ignoredFacingKind = data.ignoredFacingKind,
        ignoredFacingObjectPosition = data.ignoredFacingObjectPosition,
        ignoredFacingCandidates = data.ignoredFacingCandidates,
        ignoredFacingSurfaceHit = data.ignoredFacingSurfaceHit == true,
        ignoredFacingSurfaceSource = data.ignoredFacingSurfaceSource,
        ignoredFacingFocusDot = data.ignoredFacingFocusDot,
        tableClearanceFocusCleared = data.tableClearanceFocusCleared == true,
        tableClearanceFocusClearReason = data.tableClearanceFocusClearReason,
        seatCategory = sittingSeatCategory(profile, currentObject),
        sittingStandExitPositions = sittingStandExitPositions,
        sittingStandExitValidated = sittingStandExitPositions ~= nil,
        sittingForcedStandExitPositions = sittingForcedStandExitPositions,
        sittingForcedStandExitValidated = sittingForcedStandExitPositions ~= nil,
        sittingForcedStandExitLog = sittingForcedMeta and sittingForcedMeta.firstFallbackLog or nil,
        sittingForcedStandExitLabel = sittingForcedMeta and sittingForcedMeta.firstLabel or nil,
        lectureAudienceTarget = data.lectureAudienceTarget == true,
        lectureAudienceShortcut = data.lectureAudienceShortcut == true,
        lectureAudienceTeleport = data.lectureAudienceTeleport == true,
        lecternPosition = data.lecternPosition,
        stationPosition = data.stationPosition,
        audienceHeadFocusPosition = data.audienceHeadFocusPosition,
        lectureSessionId = data.lectureSessionId,
        stationSlotKey = data.stationSlotKey,
        audienceSource = data.audienceSource,
        fallbackUsed = data.fallbackUsed,
        initialPlacement = data.initialPlacement == true,
        suppressInitialPlacementOverlay = data.suppressInitialPlacementOverlay == true,
        schedulerArrivalPlacement = data.schedulerArrivalPlacement == true,
        manualAssign = data.manualAssign == true,
        manualAssignRetryCount = data.manualAssignRetryCount,
        manualAssignOverrideTesting = data.manualAssignOverrideTesting == true,
        manualAssignOverrideApplied = data.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = data.manualAssignOverrideReasons and table.concat(data.manualAssignOverrideReasons, ",") or nil,
        surfaceBlockerReason = data.surfaceBlockerReason,
        surfaceBlockerOverrideReason = data.surfaceBlockerOverrideReason,
        surfaceBlockerKind = data.surfaceBlockerKind,
        surfaceBlockerObjectId = data.surfaceBlockerObjectId,
        surfaceBlockerDistance = data.surfaceBlockerDistance,
        surfaceBlockerVertical = data.surfaceBlockerVertical,
        surfaceBlockerLocalReason = data.surfaceBlockerLocalReason,
        softBlockerReason = data.softBlockerReason,
        hardBlockerReason = data.hardBlockerReason,
        calibrationAction = data.calibrationAction == true,
        calibrationReason = data.calibrationReason,
        calibrationFill = data.calibrationFill == true,
        explicitFillOverride = data.explicitFillOverride == true,
        calibrationFillLabel = data.calibrationFillLabel,
        calibrationFillRole = data.calibrationFillRole,
        calibrationFillSource = data.calibrationFillSource,
        calibrationFillIndex = data.calibrationFillIndex,
        calibrationFillSessionId = data.calibrationFillSessionId,
        calibrationRuntimeObjectId = data.calibrationRuntimeObjectId,
        actorDisplayLabel = data.actorDisplayLabel,
        calibrationTestNpc = data.calibrationTestNpc == true,
        releaseSafetyGateEnabled = data.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = data.releaseSafetyGateStatus,
        releaseSafetyGateReason = data.releaseSafetyGateReason,
        releaseSafetyGateCell = data.releaseSafetyGateCell,
        releaseSafetyGateRegion = data.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = data.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = data.releaseSafetyGateLabel,
        currentHour = data.currentHour,
        usable = true
    }
    calibrationExport.traceLocalSittingAcceptance(core, self.object, currentObject, currentSlotName, debugLog, "sending result", resultPayload)
    local sent, sendErr = sendResult(resultPayload)
    if sent then
        calibrationExport.traceLocalSittingAcceptance(core, self.object, currentObject, currentSlotName, debugLog, "sent", resultPayload)
    else
        calibrationExport.traceLocalSittingAcceptance(core, self.object, currentObject, currentSlotName, debugLog, "blocked", {
            objectId = currentObject and currentObject.recordId,
            slotName = currentSlotName,
            reason = "send_failed:" .. tostring(sendErr),
        })
    end
end

local function onBeginInteractionTransition(data)
    clearInteractionTravelPackage(
        data and data.reason or "begin_transition",
        data and data.targetPos or targetPos,
        data and data.radius or nil
    )
end

local function onStartInteractionAnimation(data)
    if standRequested then return end
    if isInteracting and not (data and data.forceReplay == true) then return end
    local okEnabled, enabled = pcall(function() return self.object.enabled end)
    if okEnabled and enabled == false then
        debugLog("animation play skipped", "type", tostring(currentInteractionType), "reason", "disabled_actor")
        requestStand("disabled_actor")
        return
    end
    local baseAnimation = data and data.animation or currentAnimation
    local animation = baseAnimation

    if not animation then
        requestStand("missing_animation")
        return
    end

    currentAnimation = animation
    currentAnimationOptions = data and data.animationOptions or currentAnimationOptions

    local ok, err
    local options = profiles.shallowCopy(currentAnimationOptions or {})
    options.loops = options.loops or 999
    options.forceLoop = options.forceLoop == nil and true or options.forceLoop
    options.priority = options.priority or anim.PRIORITY.Scripted

    currentAnimationQueued = false

    if currentInteractionType == "sleeping" then
        -- Sleep poses need scripted priority; queue first, then fall back.
        local queuedOptions = {
            loops = options.loops,
            forceLoop = options.forceLoop,
            speed = options.speed or 1.0,
            startKey = options.startKey or options.startkey,
            stopKey = options.stopKey or options.stopkey,
        }
        if anim and anim.clearAnimationQueue then
            pcall(anim.clearAnimationQueue, self, true)
            debugLog("sleep animation queue cleared", "reason", "before_sleep_playQueued", "clearScripted", "true")
        end
        interactionAnimation.forceCancelSittingGroups(debugLog, "before_sleep_playQueued", self)
        if anim and anim.cancel then
            pcall(anim.cancel, self, animation)
        end

        debugLog(
            "sleep animation queue requested",
            "animation", tostring(animation),
            "method", "playQueued",
            "loops", tostring(queuedOptions.loops),
            "forceLoop", tostring(queuedOptions.forceLoop)
        )

        local okQueued, errQueued = false, "openmw.animation.playQueued unavailable"
        if anim and anim.playQueued then
            okQueued, errQueued = pcall(anim.playQueued, self, animation, queuedOptions)
            if okQueued and errQueued == false then
                okQueued = false
                errQueued = "playQueued_returned_false"
            end
        end

        if okQueued then
            ok, err = true, nil
            currentAnimationQueued = true
            debugLog("sleep animation queued", "animation", tostring(animation), "method", "playQueued")
        else
            -- Fallback keeps scripted priority so Wander cannot win visually.
            options.priority = anim.PRIORITY.Scripted or 13
            options.blendMask = anim.BLEND_MASK and anim.BLEND_MASK.All or 15
            options.autoDisable = false
            debugLog(
                "sleep animation queue failed fallback blended",
                "animation", tostring(animation),
                "error", tostring(errQueued),
                "priority", tostring(options.priority),
                "blendMask", tostring(options.blendMask)
            )
            if anim and anim.playBlended then
                ok, err = pcall(anim.playBlended, self, animation, options)
                if ok and err == false then
                    ok = false
                    err = "playBlended_returned_false"
                end
            else
                ok, err = false, "openmw.animation.playBlended unavailable"
            end
            if not ok and I.AnimationController and I.AnimationController.playBlendedAnimation then
                ok, err = pcall(I.AnimationController.playBlendedAnimation, animation, options)
                if ok and err == false then
                    ok = false
                    err = "AnimationController_returned_false"
                end
            end
        end
    else
        if currentInteractionType == "sitting" then
            interactionAnimation.forceClearQueue(debugLog, "before_sitting_play", true, self)
            interactionAnimation.forceCancelSleepGroups(debugLog, "before_sitting_play", self)
        end
        if anim and anim.playBlended then
            ok, err = pcall(anim.playBlended, self, animation, options)
            if ok and err == false then
                ok = false
                err = "playBlended_returned_false"
            end
        else
            ok, err = false, "openmw.animation.playBlended unavailable"
        end

        if not ok and I.AnimationController and I.AnimationController.playBlendedAnimation then
            ok, err = pcall(I.AnimationController.playBlendedAnimation, animation, options)
            if ok and err == false then
                ok = false
                err = "AnimationController_returned_false"
            end
        end
    end

    if not ok then
        debugLog(
            "animation play failed",
            "type", tostring(currentInteractionType),
            "animation", tostring(animation),
            "error", tostring(err)
        )
        requestStand("animation_play_failed")
        return
    end

    isInteracting = true
    currentInteractionStartedAt = core.getSimulationTime and core.getSimulationTime() or 0
    if currentInteractionType == "sleeping" then
        applySleepHelloSuppression()
    end
    if currentInteractionType == "sitting" and sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.target() then
        sdpStartLectureAudienceAnimation(data)
        sdpLectureLocalAudienceState.notifySeated({
            core = core,
            debugLog = debugLog,
            trace = sdpLectureTrace.log,
            npc = self.object,
            interactionType = currentInteractionType,
            objectId = currentObject and (currentObject.recordId or currentObject.id),
            slotName = currentSlotName,
            slotKey = currentSlotKey,
        }, data)
    end
    local playing = nil
    if anim and anim.isPlaying then
        local okPlaying, isPlaying = pcall(anim.isPlaying, self, animation)
        if okPlaying then playing = isPlaying end
    end
    debugLog(
        "animation started",
        "type", tostring(currentInteractionType),
        "animation", tostring(animation),
        "playing", tostring(playing),
        "priority", tostring(options.priority),
        "blendMask", tostring(options.blendMask)
    )
    if currentInteractionType == "sleeping" and playing == false then
        debugLog("sleep animation not playing after start", "animation", tostring(animation))
        requestStand("sleep_animation_not_playing")
        return
    end
end

sdpOnLectureAudienceTransition = function(data)
    if currentInteractionType ~= "sitting" or not isInteracting then
        sdpLectureTrace.log(debugLog, "audience_animation_skipped", "reason", "transition_not_currently_sitting")
        return
    end
    sdpLectureAudienceRestoreAnimation = data and data.animation or currentSittingPoseAnimation or currentAnimation
    if sdpLectureLocalAudienceState then
        sdpLectureLocalAudienceState.applyTransition(data)
    end
    if data and data.forceReplay == true then
        sdpStopLectureAudienceAnimation("transition_force_replay")
    end
    if not sdpLectureAudienceAnimationState then
        sdpStartLectureAudienceAnimation({
            reason = data and data.reason or "lecture_audience_transition",
            animation = sdpLectureAudienceRestoreAnimation,
            audienceHeadFocusPosition = data and data.audienceHeadFocusPosition,
        })
    end
    local lectureAudienceSessionId = sdpLectureLocalAudienceState and sdpLectureLocalAudienceState.sessionId() or nil
    debugLog("lecture audience transitioned in place", tostring(lectureAudienceSessionId), tostring(data and data.reason), "headFocus", tostring(data and data.audienceHeadFocusPosition))
    sdpLectureTrace.log(debugLog, "audience_transition_local", "session", tostring(lectureAudienceSessionId), "restore", tostring(sdpLectureAudienceRestoreAnimation), "headFocus", tostring(data and data.audienceHeadFocusPosition))
end

sdpOnLectureAudienceRelease = function(data)
    local restoreAnimation = data and data.animation or sdpLectureAudienceRestoreAnimation
    local restoreSitting = not (data and data.restoreSitting == false)
    sdpStopLectureAudienceAnimation(data and data.reason or "lecture_audience_release")
    if sdpLectureLocalAudienceState then sdpLectureLocalAudienceState.clear() end
    sdpLectureAudienceRestoreAnimation = nil
    if restoreSitting and currentInteractionType == "sitting" and restoreAnimation then
        onStartInteractionAnimation({
            interactionType = "sitting",
            animation = restoreAnimation,
            forceReplay = true,
        })
        sdpLectureTrace.log(debugLog, "audience_release_local", "mode", "restore_sitting", "animation", tostring(restoreAnimation))
    else
        sdpLectureTrace.log(debugLog, "audience_release_local", "mode", "stop_only", "animation", tostring(restoreAnimation))
    end
end


onStopInteractionObject = function(data)
    local stopReason = data and data.reason or "stop_interaction"
    if sdpSleepWakeCleanup.handleWakeCleanupOnly(data, {
        currentInteractionType = currentInteractionType,
        isInteracting = isInteracting,
        interactionAssigned = interactionAssigned,
        currentAnimationQueued = currentAnimationQueued,
        stationAssignment = sdpCurrentStationAssignment,
        animation = interactionAnimation,
        debugLog = debugLog,
        selfRef = self,
    }) then
        return
    end

    stopCurrentAnim()
    if data and (data.forceClearSleepAnimation == true or data.interactionType == "sleeping" or data.interactionType == "sitting" or tostring(stopReason):find("wake", 1, true) or tostring(stopReason):find("sleep_window", 1, true))
        and (data.wakeCleanupOnly ~= true or currentInteractionType == "sleeping" or isInteracting == true or interactionAssigned == true or currentAnimationQueued == true)
    then
        interactionAnimation.forceClearQueue(debugLog, stopReason, true, self)
        interactionAnimation.forceCancelSleepGroups(debugLog, stopReason, self)
        interactionAnimation.forceCancelSittingGroups(debugLog, stopReason, self)
    elseif data and data.wakeCleanupOnly == true then
        debugLog("wake cleanup probe ignored no local sleep state", "reason", tostring(stopReason))
    end
    clearInteractionTravelPackage(stopReason)
    isInteracting = false
    interactionAssigned = false
    currentAnimationOptions = nil
    currentAnimationQueued = false
    currentSlot = nil
    currentSittingBaseHitPos = nil
    currentSittingFacingDirection = nil
    currentSittingAppliedCalibration = nil
    currentSittingAppliedAnimationOffset = nil
    currentSleepApproachPos = nil
    currentSleepApproachName = nil
    currentSleepExitPositions = nil
    currentSleepExitName = nil
    currentSleepBedTop = nil
    currentSleepRawBedTop = nil
    currentSleepObjectTop = nil
    currentSleepProfileRootOffset = nil
    currentSleepCalibrationOffset = nil
    currentSleepMergedRootOffset = nil
    currentSleepCalibrationYawDegrees = 0
    currentSleepPoseYawOffset = nil
    currentSleepSurfaceMode = nil
    currentSleepRawSurfaceMode = nil
    currentSleepSurfaceSamples = 0
    currentInteractionInitialPlacement = false
    if sdpLectureLocalAudienceState then sdpLectureLocalAudienceState.clear() end
    currentCalibrationTargetKey = nil
    externalTravelTracker:reset()
    resetRuntimeCalibrationOffsets(stopReason)
    if sdpSleepDoorAssist then sdpSleepDoorAssist.reset() end
    aiPollTimer = 0
end

local function onInteractionDialogueStarted(data)
    if sdpAnimatedMorrowindSeeker then sdpAnimatedMorrowindSeeker.onDialogueStarted(5) end
    if sdpCurrentStationAssignment and sdpCurrentStationAssignment.active == true and not (isInteracting or interactionAssigned) then
        if sdpLecturePresenterEntryController and sdpLecturePresenterEntryController.onDialogueStarted then
            sdpLecturePresenterEntryController.onDialogueStarted(5)
        end
        return
    end
    if not (isInteracting or interactionAssigned) then return end

    if currentInteractionType == "sitting" then
        -- Keep seated NPCs seated during conversation. The player script may
        -- optionally apply an experimental camera nudge; the local NPC script
        -- only reports the seated target/pose and does not manipulate camera state.
        if data and data.player then
            pcall(function()
                data.player:sendEvent('SitDownPleaseSeatedDialogueState', {
                    active = true,
                    actor = self.object,
                    actorId = self.object.id,
                    recordId = self.object.recordId,
                    finalPosition = currentFinalPosition or self.object.position,
                    finalRotation = currentFinalRotation,
                    interactionType = currentInteractionType,
                })
            end)
        end
        debugLog(
            "dialogue keep seated",
            "mode", tostring(data and data.mode or nil)
        )
        return
    end

    local reason = "dialogue_started"
    if currentInteractionType == "sleeping" then
        reason = "dialogue_wake"
    end

    debugLog(
        "dialogue release",
        "type", tostring(currentInteractionType),
        "mode", tostring(data and data.mode or nil),
        "reason", reason
    )
    requestStand(reason)
end

sdpOnStationAssigned = function(data)
    if not data then return end
    local stationTravelDest = currentInteractionTravelDest
    local assignedAt = core.getSimulationTime and core.getSimulationTime() or 0
    sdpCurrentStationAssignment = {
        active = true,
        stationType = data.stationType,
        slotName = data.slotName,
        slotKey = data.slotKey,
        object = data.object,
        objectId = data.objectId,
        finalPosition = data.finalPosition,
        finalRotation = tonumber(data.finalRotation),
        facingDirection = data.facingDirection,
        assignedAt = assignedAt,
        travelGraceUntil = assignedAt + 10,
    }
    sdpStationRouteAssist.clear()
    clearInteractionTravelPackage("station_assigned", data.finalPosition, 220)
    if stationTravelDest and (not data.finalPosition or (stationTravelDest - data.finalPosition):length() >= 1) then
        clearInteractionTravelPackage("station_assigned", stationTravelDest, 220)
    end
    currentInteractionTravelDest = nil
    currentInteractionTravelStartedAt = nil
    if sdpStationHold then sdpStationHold.resetHoldTimers(assignedAt) end
    local presenterAnimationDeferred = sdpLecturePresenterEntryController
        and sdpLecturePresenterEntryController.onStationAssigned(data)
        or false
    if tostring(data.stationType or "") == "lectern" then
        if data.lectureAnimation then
            if not presenterAnimationDeferred then
                sdpStartLecturePresenterAnimation(data.lectureAnimation)
            end
        else
            sdpLectureTrace.log(
                debugLog,
                "presenter_animation_skipped",
                "reason", "waiting_for_audience",
                "stage", "station_assigned",
                "session", tostring(data.lectureSessionId or data.slotKey),
                "object", tostring(data.objectId)
            )
        end
    end
    debugLog("station assigned", tostring(data.stationType), tostring(data.objectId), tostring(data.slotName))
    sdpLectureTrace.log(
        debugLog,
        "presenter_facing_hold_applied",
        "reason", "station_assigned",
        "stationType", tostring(data.stationType),
        "object", tostring(data.objectId),
        "slot", tostring(data.slotKey),
        "yaw", tostring(data.finalRotation),
        "final", tostring(data.finalPosition)
    )
end

sdpOnLectureAnimationRefresh = function(data)
    if sdpLecturePresenterEntryController and sdpLecturePresenterEntryController.onLectureAnimationRefresh(data) then return end
    sdpRefreshLecturePresenterAnimation(data)
end

sdpOnStationPathingStarted = function(data)
    if not (data and data.finalPosition) then return end
    sdpStationRouteAssist.setPath({
        stationType = data.stationType,
        slotName = data.slotName,
        slotKey = data.slotKey,
        object = data.object,
        objectId = data.objectId,
        finalPosition = data.finalPosition,
        approachPosition = data.approachPosition,
        finalRotation = data.finalRotation,
        facingDirection = data.facingDirection,
        allowRouteDoorOverride = data.allowRouteDoorOverride == true,
        startedAt = core.getSimulationTime and core.getSimulationTime() or 0,
    })
    debugLog("station pathing received", tostring(data.stationType), tostring(data.objectId), tostring(data.slotName), "target", tostring(data.finalPosition), "approach", tostring(data.approachPosition))
end

sdpOnStationReleased = function(data)
    if not sdpCurrentStationAssignment then return end
    debugLog("station released", tostring(data and data.reason), tostring(sdpCurrentStationAssignment.stationType), tostring(sdpCurrentStationAssignment.objectId))
    sdpLectureTrace.log(debugLog, "release_end_fired_local", "reason", tostring(data and data.reason), "stationType", tostring(sdpCurrentStationAssignment.stationType), "object", tostring(sdpCurrentStationAssignment.objectId))
    sdpStopLecturePresenterAnimation(data and data.reason or "station_released")
    clearSleepHelloSuppression("station_released")
    sdpCurrentStationAssignment = nil
    sdpStationRouteAssist.clear()
    if sdpLecturePresenterEntryController then sdpLecturePresenterEntryController.clear() end
    if sdpStationHold then sdpStationHold.clear() end
end

local function onDied()
    local dead = actorDeadReason(self.object)
    if dead ~= true then
        debugLog("died event ignored", "actor_not_dead")
        return
    end
    requestStand('died')
end

local function onHit()
    requestStand('hit')
end

if I.Combat and I.Combat.addOnHitHandler then
    I.Combat.addOnHitHandler(function()
        requestStand('hit')
    end)
end

local function activePackageRequiresRelease(pkg)
    if not pkg or not pkg.type then return false, nil end
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    local ownTravelGrace = currentInteractionTravelStartedAt and (now - currentInteractionTravelStartedAt) <= 10
    local pkgDest = pkg.destPosition or pkg.destination

    if pkg.type == "Combat" or pkg.type == "Pursue" then
        return true, "combat"
    end

    if pkg.type == "Follow" or pkg.type == "Escort" then
        return true, "follow_or_escort"
    end

    if pkg.type == "Travel" then
        if sdpStationTravelMatches(pkgDest, 220) then
            return false, nil
        end

        if currentInteractionType == "sleeping" then
            local interactionElapsed = currentInteractionStartedAt and (now - currentInteractionStartedAt) or 0
            local release, takeoverReason, detail = externalTravelTracker:travelDecision({
                pkg = pkg,
                now = now,
                interactionType = currentInteractionType,
                initialPlacement = currentInteractionInitialPlacement == true,
                interactionElapsed = interactionElapsed,
                targetPos = targetPos,
                actorPosition = self.object and self.object.position or nil,
                ownTravelGrace = ownTravelGrace,
                currentInteractionTravelDest = currentInteractionTravelDest,
            })
            if release then
                debugLog(
                    "sleep external ai takeover release",
                    "reason", tostring(takeoverReason),
                    "dest", tostring(detail and detail.dest),
                    "elapsed", tostring(detail and detail.interactionElapsed)
                )
                return true, takeoverReason or "other_travel"
            end
            return false, nil
        end

        if currentInteractionType == "sitting" then
            local sinceStart = currentInteractionStartedAt and (now - currentInteractionStartedAt) or nil
            local nearSeat = targetPos and pkgDest and (pkgDest - targetPos):length() < 160
            local nearBrief = briefTravelDest and pkgDest and (pkgDest - briefTravelDest):length() < 160
            local nearOwnTravel = currentInteractionTravelDest and pkgDest and (pkgDest - currentInteractionTravelDest):length() < 160
            if nearSeat or nearBrief or nearOwnTravel then
                return false, nil
            end
            if sinceStart and sinceStart <= 2.5 then
                debugLog("sitting retained transient travel package", "elapsed", tostring(sinceStart), "dest", tostring(pkgDest))
                return false, nil
            end
        end
        if not (targetPos and pkgDest and (pkgDest - targetPos):length() < 120) then
            return true, "other_travel"
        end
        return false, nil
    end

    if ownTravelGrace and currentInteractionType == "sleeping" then
        -- OpenMW can briefly surface door/opening or package-transition internals
        -- after a script-started Travel package. Do not cancel our own sleep route
        -- during that short window unless it is combat/follow/escort/pursue above.
        if pkg.type == "AvoidDoor" and sdpSleepDoorAssist and sdpSleepDoorAssist.adoptActorOpenedDoor then
            sdpSleepDoorAssist.adoptActorOpenedDoor("actor_opened_sleep_route_door")
        end
        debugLog("sleep route retained transient package", tostring(pkg.type))
        return false, nil
    end

    if currentInteractionType == "sleeping" and pkg.type == "Wander" then
        -- Harmless idle package churn should not wake sleepers, but real
        -- non-Wander packages above/below should still release the actor.
        return false, nil
    end

    if currentInteractionType == "sitting" and pkg.type ~= "Wander" then
        local sinceStart = currentInteractionStartedAt and (now - currentInteractionStartedAt) or nil
        if sinceStart and sinceStart <= 3.0 then
            debugLog("sitting retained transient ai package", tostring(pkg.type), "elapsed", tostring(sinceStart))
            return false, nil
        end
        -- New sitting assignments already yield to non-idle AI packages. Keep
        -- the same rule for active sitting after the short startup grace so
        -- schedule/control mods using Activate or other packages can take over.
        debugLog("sitting external ai package release", tostring(pkg.type))
        return true, "other_ai_package"
    end

    if pkg.type ~= "Wander" then
        externalTravelTracker:reset()
        return true, "other_ai_package"
    end

    externalTravelTracker:reset()
    return false, nil
end

local function currentFollowerState()
    local followTargets = getAiTargets("Follow")
    if followTargets and #followTargets > 0 then return true end
    local escortTargets = getAiTargets("Escort")
    if escortTargets and #escortTargets > 0 then return true end
    local pkg = getActiveAiPackage()
    return pkg and (pkg.type == "Follow" or pkg.type == "Escort") or false
end

local function reportFollowerStateIfChanged(force)
    local isFollower = currentFollowerState() == true
    if not force and isFollower == lastReportedFollowerState then return end
    lastReportedFollowerState = isFollower
    core.sendGlobalEvent('SitDownPleaseFollowerState', {
        actor = self.object,
        actorId = self.object.id,
        recordId = self.object.recordId,
        isFollower = isFollower,
        isCompanion = isFollower,
    })
end


local function briefWanderPathLooksClear(dest)
    if not dest then return false end
    local from = self.object.position + util.vector3(0, 0, 48)
    local to = dest + util.vector3(0, 0, 48)
    local ok, result = pcall(function()
        return nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, radius = 0 })
    end)
    if ok and result and result.hit and result.hitPos then
        local blockedDist = (result.hitPos - from):length()
        local fullDist = (to - from):length()
        if fullDist > 0 and blockedDist < math.max(12, fullDist - 18) then
            return false
        end
    end
    return true
end

local function clearBriefTravel(reason)
    if briefTravelDest and ai and ai.startPackage then
        clearInteractionTravelPackage(reason or "brief_wander_done", briefTravelDest, 120)
    end
    briefTravelDest = nil
    briefTravelStartedAt = nil
end

local function onSitDownPleaseBriefWander(data)
    if not data or not data.destPosition then return end
    if not briefWanderPathLooksClear(data.destPosition) then
        debugLog("sitting brief wander rejected", "blocked_path")
        return
    end
    briefTravelDest = data.destPosition
    briefTravelStartedAt = core.getSimulationTime()
    briefTravelTimeout = tonumber(data.timeout or 8) or 8
    briefTravelRadius = tonumber(data.radius or 70) or 70
    onSitDownPleaseStartAIPackage({ type = "Travel", destPosition = briefTravelDest, isRepeat = false })
    if settings.debug == true then debugLog("sitting brief wander started", tostring(briefTravelDest)) end
end

local function onSitDownPleaseClearBriefTravel(data)
    clearBriefTravel((data and data.reason) or "brief_wander_done")
end

local function onUpdate(dt)
    local dead, deadReason = actorDeadReason(self.object)
    if dead and (isInteracting or interactionAssigned or currentInteractionType ~= nil) then
        requestStand(deadReason or "dead_actor")
        return
    end

    if seekerReadyReportsRemaining and seekerReadyReportsRemaining > 0 then
        seekerReadyReportTimer = seekerReadyReportTimer + dt
        if seekerReadyReportTimer >= 0.35 then
            seekerReadyReportTimer = 0
            seekerReadyReportsRemaining = seekerReadyReportsRemaining - 1
            reportSeekerReady("update")
        end
    end

    followerReportTimer = followerReportTimer + dt
    if followerReportTimer >= FOLLOWER_REPORT_INTERVAL then
        followerReportTimer = 0
        reportFollowerStateIfChanged(false)
    end

    if briefTravelDest then
        local dist = (self.object.position - briefTravelDest):length()
        local elapsed = briefTravelStartedAt and (core.getSimulationTime() - briefTravelStartedAt) or 0
        if dist <= briefTravelRadius or elapsed >= briefTravelTimeout then
            clearBriefTravel("brief_wander_done")
        end
    end

    maybeAssistSleepRouteDoor(dt)
    sdpMaybeAssistStationRouteDoor(dt)
    if not sdpProcessStationPresenterEntry(dt) then
        sdpMaintainStationAssignment(dt)
    end
    sdpProcessLectureAnimations(dt)
    if currentInteractionType == "sleeping" and (isInteracting or interactionAssigned) then
        applySleepHelloSuppression()
        suppressSleepingGreetingSound()
    end


    if isInteracting then
        local interactionElapsed = currentInteractionStartedAt and ((core.getSimulationTime and core.getSimulationTime() or 0) - currentInteractionStartedAt) or 0
        local controlReason, controlValue = nil, nil
        if interactionElapsed > 0.35 then
            controlReason, controlValue = externalAiTakeover.activeControlInputReason(self, self.controls)
        end
        if controlReason then
            debugLog("external control input release", tostring(controlReason), tostring(controlValue), "type", tostring(currentInteractionType))
            requestStand(controlReason)
            return
        end

        if currentInteractionType == "sleeping" then
            -- Hold the sleeper still. Without this, normal idle/hello behavior can
            -- still rotate or twitch the body while the sleep pose is playing.
            self.controls.movement = 0
            self.controls.sideMovement = 0
            self.controls.yawChange = 0
            applySleepHelloSuppression()
            suppressSleepingGreetingSound()
        else
            if sdpCurrentCalibrationFill == true then
                self.controls.movement = 0
                self.controls.sideMovement = 0
            end
            self.controls.yawChange = 0
        end
    end

    if (isInteracting or interactionAssigned) and not standRequested then
        aiPollTimer = aiPollTimer + dt
        if aiPollTimer < AI_POLL_INTERVAL then
            return
        end
        aiPollTimer = 0

        local dangerReason = activeDangerReason()
        if dangerReason then
            requestStand(dangerReason)
            return
        end

        local proceduralChatterReason = sdpProceduralChatterCompat.physicalControlReason(self.object, core)
        if proceduralChatterReason then
            debugLog("procedural chatter control release", tostring(proceduralChatterReason), "type", tostring(currentInteractionType))
            requestStand(proceduralChatterReason)
            return
        end

        local controlScriptReason, controlScript = externalAiTakeover.externalControlScriptReason(self.object)
        if controlScriptReason then
            debugLog("external control script release", tostring(controlScript), "type", tostring(currentInteractionType))
            requestStand(controlScriptReason)
            return
        end

        local stanceReason, stance = externalAiTakeover.activeNonIdleStanceReason(self.object, types)
        if stanceReason then
            local stanceConst = types and types.Actor and types.Actor.STANCE or {}
            local weaponStance = stanceConst.Weapon or 1
            if currentInteractionType == "sitting" and (stance == weaponStance or stance == 1) then
                if types and types.Actor and types.Actor.setStance and stanceConst.Nothing then
                    local okSet, errSet = pcall(types.Actor.setStance, self.object, stanceConst.Nothing)
                    debugLog(
                        "seated actor stance normalized for activation compatibility",
                        tostring(stance),
                        "ok", tostring(okSet),
                        "err", tostring(errSet)
                    )
                else
                    debugLog("active weapon stance ignored while seated", tostring(stance), "type", tostring(currentInteractionType))
                end
            else
                debugLog("active stance release", tostring(stance), "type", tostring(currentInteractionType))
                requestStand(stanceReason)
                return
            end
        end

        if isInteracting then
            local blockingAnimationReason = sdpScriptedAnimationCompat
                and sdpScriptedAnimationCompat.activeBlockingAnimationReason(self.object, anim)
                or nil
            if blockingAnimationReason then
                if currentInteractionType == "sitting" and tostring(blockingAnimationReason):find("weapon", 1, true) then
                    debugLog("active weapon animation ignored while seated", tostring(blockingAnimationReason), "type", tostring(currentInteractionType))
                else
                    debugLog("active blocking animation release", tostring(blockingAnimationReason), "type", tostring(currentInteractionType))
                    requestStand(blockingAnimationReason)
                    return
                end
            end
        end

        local scriptedAnimationReason = sdpScriptedAnimationCompat
            and sdpScriptedAnimationCompat.activeExternalAnimationReason(self.object, anim)
            or nil
        if scriptedAnimationReason then
            debugLog("active external animation release", tostring(scriptedAnimationReason), "type", tostring(currentInteractionType))
            requestStand(scriptedAnimationReason)
            return
        end

        local followTargets = getAiTargets("Follow")
        if followTargets and #followTargets > 0 then
            requestStand('follow')
            return
        end

        local escortTargets = getAiTargets("Escort")
        if escortTargets and #escortTargets > 0 then
            requestStand('escort')
            return
        end

        local release, reason = activePackageRequiresRelease(getActiveAiPackage())
        if release then
            requestStand(reason)
        end
    end
end

onSitDownPleaseStartAIPackage = function(data)
    if not data or not data.type then return end
    if not (ai and ai.startPackage) then
        debugLog("ai startPackage unavailable", tostring(data.type))
        return
    end

    local package, packageReason = externalAiTakeover.normalizeStartPackage(data)
    if not package then
        debugLog("ai package start skipped", tostring(data.type), tostring(packageReason))
        return
    end
    local preserveBlocked, preserveReason = externalAiTakeover.preservedStartBlockedByActivePackage(package, getActiveAiPackage())
    if preserveBlocked then
        debugLog("ai package start skipped", tostring(package.type), tostring(preserveReason), tostring(externalAiTakeover.packageDestination(package) or ""))
        return
    end
    local ok, err = pcall(function()
        ai.startPackage(package)
    end)

    if ok then
        if package.type == "Travel" then
            currentInteractionTravelDest = externalAiTakeover.packageDestination(package)
            currentInteractionTravelStartedAt = core.getSimulationTime and core.getSimulationTime() or 0
        end
        debugLog("ai package started", tostring(package.type), tostring(externalAiTakeover.packageDestination(package) or ""))
    else
        debugLog("ai package start failed", tostring(data.type), tostring(err))
    end
end

local function onSleepRouteDoorAssistRejected(ev)
    if not (ev and currentInteractionType == "sleeping" and interactionAssigned and not isInteracting) then return end
    if sdpSleepDoorAssist and sdpSleepDoorAssist.noteRejectedDoor then
        sdpSleepDoorAssist.noteRejectedDoor(ev.doorKey or ev.doorId or ev.doorRecordId, ev.reason or "route_door_rejected")
        if ev.doorRecordId then sdpSleepDoorAssist.noteRejectedDoor(ev.doorRecordId, ev.reason or "route_door_rejected") end
    end
    local resumeTarget = targetPos or ev.resumeTarget
    if resumeTarget then
        debugLog(
            "route_door_assist",
            "local_rejected_door_resume_route",
            tostring(ev.doorRecordId or ev.doorKey),
            "reason", tostring(ev.reason),
            "target", tostring(resumeTarget)
        )
        onSitDownPleaseStartAIPackage({
            type = "Travel",
            destPosition = resumeTarget,
            isRepeat = false,
            cancelOther = true,
            destinationTolerance = 32,
        })
    end
end

refreshCurrentSittingCalibration = function(reason)
    if not (isInteracting and currentInteractionType == "sitting") then return false end
    if not (currentProfile and currentSittingBaseHitPos and currentSittingFacingDirection) then return false end

    local finalPos, finalYawOffset, profileOffset, appliedCalibration, animationOffset = finalPositionForProfile(
        currentSittingBaseHitPos,
        currentSittingFacingDirection,
        currentProfile,
        currentSittingPoseActivity or "standard",
        currentSittingPoseAnimation or currentAnimation
    )
    local finalRot = math.atan2(currentSittingFacingDirection.x, currentSittingFacingDirection.y) + (finalYawOffset or 0)

    currentFinalPosition = finalPos
    currentFinalRotation = finalRot
    currentSittingAppliedCalibration = appliedCalibration
    currentSittingAppliedProfileOffset = profileOffset
    currentSittingAppliedAnimationOffset = animationOffset
    if currentInteractionData then
        currentInteractionData.surfaceBlockerReason = nil
        currentInteractionData.surfaceBlockerOverrideReason = nil
        currentInteractionData.surfaceBlockerKind = nil
        currentInteractionData.surfaceBlockerObjectId = nil
        currentInteractionData.surfaceBlockerDistance = nil
        currentInteractionData.surfaceBlockerVertical = nil
        currentInteractionData.surfaceBlockerLocalReason = nil
    end

    local clearanceData = profiles.shallowCopy(currentInteractionData or {})
    clearanceData.facingKind = clearanceData.facingKind or runtimeSittingCalibration.facingKind
    clearanceData.facingObject = clearanceData.facingObject or (currentInteractionData and currentInteractionData.facingObject)
    clearanceData.facingObjectId = clearanceData.facingObjectId or (currentInteractionData and currentInteractionData.facingObjectId)
    clearanceData.facingObjectModel = clearanceData.facingObjectModel or (currentInteractionData and currentInteractionData.facingObjectModel)
    clearanceData.facingObjectName = clearanceData.facingObjectName or (currentInteractionData and currentInteractionData.facingObjectName)
    clearanceData.facingObjectScale = clearanceData.facingObjectScale or (currentInteractionData and currentInteractionData.facingObjectScale)
    clearanceData.facingObjectPosition = clearanceData.facingObjectPosition or (currentInteractionData and currentInteractionData.facingObjectPosition)
    clearanceData.facingCandidates = clearanceData.facingCandidates or (currentInteractionData and currentInteractionData.facingCandidates)
    local clutter, clutterDistance, clutterZ, clutterReason, clutterKind = seatingClutterBlockers.surfaceBlocker({
        nearby = nearby,
        util = util,
        profiles = profiles,
        rayHitBelongsToObject = rayHitBelongsToObject,
    }, currentSittingBaseHitPos, currentProfile, currentObject)
    if clutter then
        runtimeSittingCalibration.surfaceBlockerReason = "seat_surface_blocked_by_item"
        runtimeSittingCalibration.surfaceBlockerKind = tostring(clutterKind or "seat_surface_blocked_by_item")
        runtimeSittingCalibration.surfaceBlockerObjectId = tostring(clutter.recordId or clutter.id)
        runtimeSittingCalibration.surfaceBlockerDistance = clutterDistance
        runtimeSittingCalibration.surfaceBlockerVertical = clutterZ
        runtimeSittingCalibration.surfaceBlockerLocalReason = clutterReason
        if currentInteractionData then
            currentInteractionData.surfaceBlockerReason = runtimeSittingCalibration.surfaceBlockerReason
            currentInteractionData.surfaceBlockerKind = runtimeSittingCalibration.surfaceBlockerKind
            currentInteractionData.surfaceBlockerObjectId = runtimeSittingCalibration.surfaceBlockerObjectId
            currentInteractionData.surfaceBlockerDistance = runtimeSittingCalibration.surfaceBlockerDistance
            currentInteractionData.surfaceBlockerVertical = runtimeSittingCalibration.surfaceBlockerVertical
            currentInteractionData.surfaceBlockerLocalReason = runtimeSittingCalibration.surfaceBlockerLocalReason
        end
    end
    local _, clearanceReason, clearanceMeta = seatingClearance.rejectSittingFinalIfBlocked({
        nearby = nearby,
        util = util,
        profiles = profiles,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        debugLog = debugLog,
        currentObject = function() return currentObject end,
        objectModelPath = function(obj) return profiles.objectModelPath(obj) end,
        actorScale = function() return self.object and self.object.scale or 1 end,
    }, finalPos, currentSittingFacingDirection, currentProfile, clearanceData)
    if clearanceReason and not clutter then
        runtimeSittingCalibration.surfaceBlockerReason = tostring(clearanceReason)
        runtimeSittingCalibration.surfaceBlockerKind = tostring((clearanceMeta and (clearanceMeta.category or clearanceMeta.result)) or clearanceReason)
        runtimeSittingCalibration.surfaceBlockerObjectId = clearanceMeta and clearanceMeta.blockerRecord or nil
        runtimeSittingCalibration.surfaceBlockerDistance = clearanceMeta and (clearanceMeta.blockerDistance or clearanceMeta.tableDistance) or nil
        runtimeSittingCalibration.surfaceBlockerVertical = clearanceMeta and clearanceMeta.vertical or nil
        if currentInteractionData then
            currentInteractionData.surfaceBlockerReason = runtimeSittingCalibration.surfaceBlockerReason
            currentInteractionData.surfaceBlockerKind = runtimeSittingCalibration.surfaceBlockerKind
            currentInteractionData.surfaceBlockerObjectId = runtimeSittingCalibration.surfaceBlockerObjectId
            currentInteractionData.surfaceBlockerDistance = runtimeSittingCalibration.surfaceBlockerDistance
            currentInteractionData.surfaceBlockerVertical = runtimeSittingCalibration.surfaceBlockerVertical
        end
    elseif not clutter then
        runtimeSittingCalibration.surfaceBlockerReason = nil
        runtimeSittingCalibration.surfaceBlockerKind = nil
        runtimeSittingCalibration.surfaceBlockerObjectId = nil
        runtimeSittingCalibration.surfaceBlockerDistance = nil
        runtimeSittingCalibration.surfaceBlockerVertical = nil
        runtimeSittingCalibration.surfaceBlockerLocalReason = nil
    end

    if core and core.sendGlobalEvent then
        core.sendGlobalEvent("SitDownPleaseSittingCalibrationUpdated", {
            npc = self.object,
            finalPosition = finalPos,
            finalRotation = finalRot,
            animation = currentSittingPoseAnimation or currentAnimation,
            profileOffset = profileOffset,
            animationOffset = animationOffset,
            calibration = appliedCalibration,
            activity = currentSittingPoseActivity or "standard",
            surfaceBlockerReason = runtimeSittingCalibration.surfaceBlockerReason,
            surfaceBlockerKind = runtimeSittingCalibration.surfaceBlockerKind,
            surfaceBlockerObjectId = runtimeSittingCalibration.surfaceBlockerObjectId,
            surfaceBlockerDistance = runtimeSittingCalibration.surfaceBlockerDistance,
            surfaceBlockerVertical = runtimeSittingCalibration.surfaceBlockerVertical,
            surfaceBlockerLocalReason = runtimeSittingCalibration.surfaceBlockerLocalReason,
            reason = reason or "settings",
        })
    end

    debugLog(
        "sitting calibration refreshed",
        tostring(reason or "settings"),
        "object", tostring(currentObject and currentObject.recordId),
        "activity", tostring(currentSittingPoseActivity or "standard"),
        "animation", tostring(currentSittingPoseAnimation or currentAnimation),
        "profileOffset", profileOffset and (tostring(profileOffset.x) .. "," .. tostring(profileOffset.y) .. "," .. tostring(profileOffset.z) .. ",yaw=" .. tostring(profileOffset.yaw)) or "0,0,0,yaw=0",
        "animationOffset", animationOffset and (tostring(animationOffset.x) .. "," .. tostring(animationOffset.y) .. "," .. tostring(animationOffset.z) .. ",yaw=" .. tostring(animationOffset.yaw)) or "0,0,0,yaw=0",
        "calibration", appliedCalibration and (tostring(appliedCalibration.x) .. "," .. tostring(appliedCalibration.y) .. "," .. tostring(appliedCalibration.z) .. ",yaw=" .. tostring(appliedCalibration.yaw)) or "0,0,0,yaw=0"
    )
    return true
end

function onRefreshSittingCalibration(data)
    refreshCurrentSittingCalibration(data and data.reason or "settings")
end

refreshCurrentSleepCalibration = function(reason, suppressExport)
    if not (currentInteractionType == "sleeping" and (isInteracting or interactionAssigned)) then
        print("[SitDownPlease]", "sleep calibration action failed", "reason", "no_current_calibration_target")
        return false
    end
    if not (currentObject and currentProfile and currentSlotKey) then
        print("[SitDownPlease]", "sleep calibration action failed", "reason", "profile_missing_or_slot_invalid")
        return false
    end

    local refreshData = {
        object = currentObject,
        interactionType = "sleeping",
        profileId = currentProfile.profileId,
        slot = currentSlot,
        slotName = currentSlotName,
        slotKey = currentSlotKey,
        approachPos = currentSleepApproachPos or targetPos,
        approachName = currentSleepApproachName,
        currentHour = profiles.getGameHour(),
        calibrationAction = true,
        calibrationReason = reason or "calibration",
        suppressAcceptedResult = true,
        ignoreTimeGate = true,
    }
    local _, evaluatedData = evaluateSleepingInteraction(refreshData, currentProfile)
    evaluatedData = evaluatedData or refreshData
    local sleepCalibrationState = runtimeSleepCalibration
    local warningReason = sdpSleepCalibrationWarnings.reason(
        currentSleepSurfaceMode,
        currentSleepCalibrationOffset,
        currentFinalPosition,
        currentSleepBedTop,
        {
            profile = currentProfile,
            slotName = currentSlotName,
            slotKey = currentSlotKey,
            objectId = currentObject and currentObject.recordId,
        }
    )
    evaluatedData.sleepCalibrationWarningReason = warningReason
    sleepCalibrationState.sleepCalibrationWarningReason = evaluatedData.sleepCalibrationWarningReason

    if core and core.sendGlobalEvent and currentFinalPosition then
        core.sendGlobalEvent("SitDownPleaseSleepCalibrationUpdated", {
            npc = self.object,
            object = currentObject,
            objectId = currentObject.recordId,
            model = profiles.objectModelPath(currentObject),
            profile = currentProfile,
            profileId = currentProfile.profileId,
            slotKey = currentSlotKey,
            slotName = currentSlotName,
            approachPos = currentSleepApproachPos,
            exitPosition = currentSleepExitPositions and currentSleepExitPositions[1] or nil,
            exitPositions = currentSleepExitPositions,
            finalPosition = currentFinalPosition,
            finalRotation = currentFinalRotation,
            animation = currentProfile and currentProfile.animation or currentAnimation,
            profileOffset = currentSleepProfileRootOffset,
            animationOffset = currentSleepAnimationNormalizationOffset,
            sleepSurfaceMode = currentSleepSurfaceMode,
            sleepRawSurfaceMode = evaluatedData.sleepRawSurfaceMode or currentSleepRawSurfaceMode,
            rawSurfaceMode = evaluatedData.rawSurfaceMode or currentSleepRawSurfaceMode,
            sleepSurfaceAnchorStabilized = evaluatedData.sleepSurfaceAnchorStabilized == true,
            sleepSurfaceSamples = currentSleepSurfaceSamples,
            sleepObjectTopPosition = currentSleepObjectTop,
            sleepSurfaceTopPosition = currentSleepObjectTop,
            surfaceMode = currentSleepSurfaceMode,
            rawBedTop = evaluatedData.rawBedTop or evaluatedData.sleepRawSurfacePosition or currentSleepRawBedTop,
            sleepRawSurfacePosition = evaluatedData.sleepRawSurfacePosition or evaluatedData.rawBedTop or currentSleepRawBedTop,
            surfaceSamples = currentSleepSurfaceSamples,
            bedTop = currentSleepBedTop,
            sleepSurfacePosition = currentSleepBedTop,
            safetyEvaluated = true,
            manualAssignOverrideApplied = evaluatedData.manualAssignOverrideApplied == true,
            manualAssignOverrideReason = evaluatedData.manualAssignOverrideReasons and table.concat(evaluatedData.manualAssignOverrideReasons, ",") or evaluatedData.manualAssignOverrideReason,
            surfaceBlockerReason = evaluatedData.surfaceBlockerReason,
            surfaceBlockerOverrideReason = evaluatedData.surfaceBlockerOverrideReason,
            surfaceBlockerKind = evaluatedData.surfaceBlockerKind,
            surfaceBlockerObjectId = evaluatedData.surfaceBlockerObjectId,
            surfaceBlockerDistance = evaluatedData.surfaceBlockerDistance,
            surfaceBlockerVertical = evaluatedData.surfaceBlockerVertical,
            surfaceBlockerLocalReason = evaluatedData.surfaceBlockerLocalReason,
            softBlockerReason = evaluatedData.softBlockerReason,
            hardBlockerReason = evaluatedData.hardBlockerReason,
            sleepSafetyReason = evaluatedData.sleepSafetyReason,
            sleepSafetyDelta = evaluatedData.sleepSafetyDelta,
            sleepSafetyLimit = evaluatedData.sleepSafetyLimit,
            sleepSafetyOverrideReason = evaluatedData.sleepSafetyOverrideReason,
            sleepSafetyRepairReason = evaluatedData.sleepSafetyRepairReason,
            sleepSafetyRepairDelta = evaluatedData.sleepSafetyRepairDelta,
            sleepSafetyRepairLimit = evaluatedData.sleepSafetyRepairLimit,
            sleepCalibrationWarningReason = evaluatedData.sleepCalibrationWarningReason,
            releaseSafetyGateEnabled = evaluatedData.releaseSafetyGateEnabled,
            releaseSafetyGateStatus = evaluatedData.releaseSafetyGateStatus,
            releaseSafetyGateReason = evaluatedData.releaseSafetyGateReason,
            releaseSafetyGateCell = evaluatedData.releaseSafetyGateCell,
            releaseSafetyGateRegion = evaluatedData.releaseSafetyGateRegion,
            releaseSafetyGateFurnitureType = evaluatedData.releaseSafetyGateFurnitureType,
            releaseSafetyGateLabel = evaluatedData.releaseSafetyGateLabel,
            calibration = {
                x = currentSleepCalibrationOffset and currentSleepCalibrationOffset.x or 0,
                y = currentSleepCalibrationOffset and currentSleepCalibrationOffset.y or 0,
                z = currentSleepCalibrationOffset and currentSleepCalibrationOffset.z or 0,
                yaw = currentSleepCalibrationYawDegrees or 0,
            },
            reason = reason or "calibration",
        })
    end
    if suppressExport ~= true then
        npcCalibrationEventsBinding.printSleepCalibrationDetails("sleep calibration reapplied", reason)
    else
        debugLog("sleep calibration refreshed", tostring(reason or "calibration"), "export", "suppressed")
    end
    return true
end

npcCalibrationEventsBinding = npcCalibrationEvents.bind({
    core = core,
    actor = function() return self.object end,
    debugLog = debugLog,
    state = function()
        return {
            currentObject = currentObject,
            currentProfile = currentProfile,
            currentInteractionType = currentInteractionType,
            currentAnimation = currentAnimation,
            currentSlotKey = currentSlotKey,
            currentSlotName = currentSlotName,
            currentSittingBaseHitPos = currentSittingBaseHitPos,
            currentSittingAppliedProfileOffset = currentSittingAppliedProfileOffset,
            currentSittingAppliedAnimationOffset = currentSittingAppliedAnimationOffset,
            currentSittingPoseActivity = currentSittingPoseActivity,
            currentSittingPoseAnimation = currentSittingPoseAnimation,
            currentSleepBedTop = currentSleepBedTop,
            currentSleepAnimationNormalizationOffset = currentSleepAnimationNormalizationOffset,
            currentSleepCalibrationOffset = currentSleepCalibrationOffset,
            currentSleepCalibrationYawDegrees = currentSleepCalibrationYawDegrees,
            currentSleepMergedRootOffset = currentSleepMergedRootOffset,
            currentSleepPoseYawOffset = currentSleepPoseYawOffset,
            currentSleepProfileRootOffset = currentSleepProfileRootOffset,
            currentSleepSurfaceMode = currentSleepSurfaceMode,
            currentSleepSurfaceSamples = currentSleepSurfaceSamples,
            currentFinalPosition = currentFinalPosition,
            currentFinalRotation = currentFinalRotation,
            isInteracting = isInteracting,
            profiles = profiles,
            types = types,
        }
    end,
    nearby = nearby,
    async = async,
    util = util,
    rayHitBelongsToObject = rayHitBelongsToObject,
    nextCalibrationExportSequence = function()
        calibrationExportSequence = calibrationExportSequence + 1
        return calibrationExportSequence
    end,
    runtimeSittingCalibration = function() return runtimeSittingCalibration end,
    runtimeSleepCalibration = function() return runtimeSleepCalibration end,
    setRuntimeSittingCalibration = function(value) runtimeSittingCalibration = value end,
    setRuntimeSleepCalibration = function(value) runtimeSleepCalibration = value end,
    sittingCalibrationSnapshot = sittingCalibrationSnapshot,
    sittingProfileOffsetFor = sittingProfileOffsetFor,
    sittingAnimationNormalizationFor = sittingAnimationNormalizationFor,
    refreshCurrentSittingCalibration = function(reason) return refreshCurrentSittingCalibration(reason) end,
    refreshCurrentSleepCalibration = function(reason, suppressExport) return refreshCurrentSleepCalibration(reason, suppressExport) end,
    replayCurrentAnimation = function(reason)
        if not currentAnimation then
            debugLog("calibration replay skipped", tostring(reason or "locked_calibration"), "reason", "missing_animation")
            return false
        end
        onStartInteractionAnimation({
            animation = currentAnimation,
            animationOptions = currentAnimationOptions,
            forceReplay = true,
            reason = reason or "locked_calibration",
        })
        debugLog("calibration animation replay requested", tostring(reason or "locked_calibration"), "type", tostring(currentInteractionType), "animation", tostring(currentAnimation))
        return true
    end,
})

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = function()
            seekerReadyReportsRemaining = 6
            seekerReadyReportTimer = 0.35
            reportSeekerReady("init")
        end,
        onLoad = function()
            if isInteracting or interactionAssigned or currentInteractionType ~= nil or currentAnimationQueued == true then
                onStopInteractionObject({
                    reason = "load_runtime_reset",
                    interactionType = currentInteractionType,
                    forceClearSleepAnimation = true,
                })
            else
                if sdpCurrentStationAssignment then
                    sdpOnStationReleased({ reason = "load_runtime_reset" })
                else
                    sdpStopLecturePresenterAnimation("load_runtime_reset")
                end
                sdpStopLectureAudienceAnimation("load_runtime_reset")
                if sdpLectureLocalAudienceState then sdpLectureLocalAudienceState.clear() end
            end
            seekerReadyReportsRemaining = 6
            seekerReadyReportTimer = 0.35
            reportSeekerReady("load")
        end,
    },
    eventHandlers = {
        ConsiderInteractionObject = onConsiderInteractionObject,
        SitDownPleaseAnimatedMorrowindAlignmentAssist = onAnimatedMorrowindAlignmentAssist,
        BeginInteractionTransition = onBeginInteractionTransition,
        StartInteractionAnimation = onStartInteractionAnimation,
        StopInteractionObject = onStopInteractionObject,
        SitDownPleaseStartAIPackage = onSitDownPleaseStartAIPackage,
        SitDownPleaseSleepRouteDoorRejected = onSleepRouteDoorAssistRejected,
        SitDownPleaseSchedulerStandDispersal = onSchedulerStandDispersal,
        SitDownPleaseBriefWander = onSitDownPleaseBriefWander,
        SitDownPleaseClearBriefTravel = onSitDownPleaseClearBriefTravel,
        InteractionDialogueStarted = onInteractionDialogueStarted,
        InteractionDialogueStopped = function(data)
            if sdpAnimatedMorrowindSeeker then sdpAnimatedMorrowindSeeker.onDialogueStopped() end
            if sdpCurrentStationAssignment and sdpCurrentStationAssignment.active == true and not (isInteracting or interactionAssigned) then
                if sdpLecturePresenterEntryController and sdpLecturePresenterEntryController.onDialogueStopped then
                    sdpLecturePresenterEntryController.onDialogueStopped(1.5)
                end
            end
            local player = data and data.player
            if player then
                pcall(function()
                    player:sendEvent('SitDownPleaseSeatedDialogueState', {
                        active = false,
                        actorId = self.object.id,
                        recordId = self.object.recordId,
                    })
                end)
            end
        end,
        SitDownPleaseStationAssigned = sdpOnStationAssigned,
        SitDownPleaseLectureAnimationRefresh = sdpOnLectureAnimationRefresh,
        SitDownPleaseLectureAudienceReaction = sdpOnLectureAudienceReaction,
        SitDownPleaseLectureAudienceTransition = sdpOnLectureAudienceTransition,
        SitDownPleaseLectureAudienceRelease = sdpOnLectureAudienceRelease,
        SitDownPleaseStationPathingStarted = sdpOnStationPathingStarted,
        SitDownPleaseStationReleased = sdpOnStationReleased,
        SitDownPleaseGoToBed = npcCalibrationEventsBinding.handlers.onDebugGoToBed,
        SitDownPleaseSetSittingCalibration = npcCalibrationEventsBinding.handlers.onSetSittingCalibration,
        SitDownPleaseNudgeSittingCalibration = npcCalibrationEventsBinding.handlers.onNudgeSittingCalibration,
        SitDownPleaseResetSittingCalibration = npcCalibrationEventsBinding.handlers.onResetSittingCalibration,
        SitDownPleaseRefreshSittingCalibration = onRefreshSittingCalibration,
        SitDownPleasePrintSittingCalibration = function() npcCalibrationEventsBinding.printSittingCalibration("sitting calibration") end,
        SitDownPleaseReapplyLockedCalibration = npcCalibrationEventsBinding.handlers.onReapplyLockedCalibration,
        SitDownPleaseSetSleepCalibration = npcCalibrationEventsBinding.handlers.onSetSleepCalibration,
        SitDownPleaseNudgeSleepCalibration = npcCalibrationEventsBinding.handlers.onNudgeSleepCalibration,
        SitDownPleaseResetSleepCalibration = npcCalibrationEventsBinding.handlers.onResetSleepCalibration,
        SitDownPleaseSleepCalibrationSettingsChanged = npcCalibrationEventsBinding.handlers.onSleepCalibrationSettingsChanged,
        SitDownPleasePrintSleepCalibration = function(data) npcCalibrationEventsBinding.printSleepCalibrationDetails("sleep calibration", data and data.reason or "print") end,
        Died = onDied,
        Hit = onHit,

        -- Legacy aliases preserve the original sitting handshake.
        ConsiderTheStool = function(data)
            onConsiderInteractionObject({
                object = data and data.stool or nil,
                interactionType = "sitting",
                profileId = data and data.profileId or nil,
                slotKey = data and data.slotKey or nil,
                slotName = data and data.slotName or nil,
                approachPos = data and data.approachPos or nil,
                preferredFacingDirection = data and data.preferredFacingDirection or nil,
                fallbackUsed = data and data.fallbackUsed or false,
                currentHour = profiles.getGameHour(),
            })
        end,
        SitDownPlease = function()
            onStartInteractionAnimation({ interactionType = "sitting", animation = currentAnimation or "sdparmsonkneessitidle1" })
        end,
        StandUpPlease = onStopInteractionObject,
    }
}
