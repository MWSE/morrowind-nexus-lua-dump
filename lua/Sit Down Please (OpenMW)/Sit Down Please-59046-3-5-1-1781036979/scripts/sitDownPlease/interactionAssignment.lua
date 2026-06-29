-- interactionAssignment.lua
---@omw-context global
---@diagnostic disable: assign-type-mismatch
local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local gUtils = require('scripts/sitDownPlease/lib/gUtils')
local profiles = require('scripts/sitDownPlease/profiles/catalog')
local sleepLightControl = require('scripts/sitDownPlease/interactions/sleeping/lightControl')
sdpSleepCore = require('scripts/sitDownPlease/interactions/sleeping/core')
local cellContext = require('scripts/sitDownPlease/world/cellContext')
local sleepBedAccess = require('scripts/sitDownPlease/interactions/sleeping/bedAccess')
local calibrationLock = require('scripts/sitDownPlease/calibration/lockState')
local sleepRouteDoors = require('scripts/sitDownPlease/interactions/sleeping/routeDoors')
sdpSleepEntryGate = require('scripts/sitDownPlease/interactions/sleeping/entryGate')
local sleepRouteRejection = require('scripts/sitDownPlease/interactions/sleeping/routeRejection')
sdpSleepInitialRejectRescue = require('scripts/sitDownPlease/interactions/sleeping/initialRejectRescue')
local sleepApproachTimeout = require('scripts/sitDownPlease/interactions/sleeping/approachTimeout')
sdpSleepRouteStartTravel = require('scripts/sitDownPlease/interactions/sleeping/routeStartTravel')
local sleepReservationsModule = require('scripts/sitDownPlease/interactions/sleeping/reservations')
local initialPlacementGuards = require('scripts/sitDownPlease/assignment/initialPlacementGuards')
sdpSleepFinalSafety = require('scripts/sitDownPlease/interactions/sleeping/finalSafety')
local handoffTracker = require('scripts/sitDownPlease/assignment/handoffTracker')
local assignmentEligibility = require('scripts/sitDownPlease/assignment/eligibility')
local candidateBuilder = require('scripts/sitDownPlease/assignment/candidateBuilder')
sdpCandidateSelector = require('scripts/sitDownPlease/assignment/candidateSelector')
sdpAssignmentPublicInterface = require('scripts/sitDownPlease/assignment/publicInterface')
sdpSchedulerArrivalPlacementOk, sdpSchedulerArrivalPlacement = pcall(require, 'scripts/sitDownPlease/assignment/schedulerArrivalPlacement')
if not sdpSchedulerArrivalPlacementOk then
    sdpSchedulerArrivalPlacement = {
        request = function()
            return false, "scheduler_arrival_placement_module_unavailable"
        end,
    }
end
sdpSlotOwnership = require('scripts/sitDownPlease/assignment/slotOwnership')
local sittingCooldownModule = require('scripts/sitDownPlease/interactions/sitting/cooldowns')
sdpSittingLocalRejectRetry = require('scripts/sitDownPlease/interactions/sitting/localRejectRetry')
local sittingLifecycleModule = require('scripts/sitDownPlease/interactions/sitting/lifecycle')
local sittingFocusSelector = require('scripts/sitDownPlease/interactions/sitting/focusSelector')
local seatingClutterBlockers = require('scripts/sitDownPlease/interactions/sitting/clutterBlockers')
local smoothMoveModule = require('scripts/sitDownPlease/calibration/smoothMove')
local calibrationBlockerMarkerEvents = require('scripts/sitDownPlease/calibration/blockerMarkerEvents')
sdpFocusMetadata = require('scripts/sitDownPlease/calibration/focusMetadata')
sdpSittingStandExit = require('scripts/sitDownPlease/interactions/sitting/standExit')
sdpStationAssignments = require('scripts/sitDownPlease/interactions/lectures/session')
sdpStationRouteDoors = require('scripts/sitDownPlease/interactions/lectures/routeDoors')
sdpLectureAudience = require('scripts/sitDownPlease/interactions/lectures/audience')
sdpLectureAudienceRelease = require('scripts/sitDownPlease/interactions/lectures/audienceRelease')
sdpLectureAudienceReleasePersistence = require('scripts/sitDownPlease/interactions/lectures/audienceReleasePersistence')
sdpLectureTrace = require('scripts/sitDownPlease/interactions/lectures/trace')
sdpLectureSeatReservations = require('scripts/sitDownPlease/interactions/lectures/seatReservations')
sdpLectureAssignmentController = require('scripts/sitDownPlease/interactions/lectures/assignmentController')
local lectureAudienceTransitionBridgeModule = require('scripts/sitDownPlease/interactions/lectures/audienceTransitionBridge')
sdpCalibrationFillOwnership = require('scripts/sitDownPlease/calibration/fillOwnership')
sdpOriginTracker = require('scripts/sitDownPlease/assignment/originTracker')
sdpActorRoles = require('scripts/sitDownPlease/assignment/actorRoles')
sdpServicePolicy = require('scripts/sitDownPlease/assignment/servicePolicy')
sdpReleaseSafetyGate = require('scripts/sitDownPlease/assignment/releaseSafetyGate')
sdpRelevantObjectCacheInvalidation = require('scripts/sitDownPlease/assignment/relevantObjectCacheInvalidation')
sdpAssignmentScanCadence = require('scripts/sitDownPlease/assignment/scanCadence')
sdpSettingsRescan = require('scripts/sitDownPlease/assignment/settingsRescan')
sdpExternalAiTakeover = require('scripts/sitDownPlease/compatibility/externalAiTakeover')
sdpProceduralChatterCompat = require('scripts/sitDownPlease/compatibility/proceduralChatter')
sdpExternalAnimationCompat = require('scripts/sitDownPlease/compatibility/externalAnimations')
sdpAnimatedMorrowindAssignmentModule = require('scripts/sitDownPlease/compatibility/animatedMorrowindAssignment')
sdpScalePolicy = require('scripts/sitDownPlease/world/scalePolicy')

-- =============================================================================
-- LOCAL OBJECT INTERACTION MANAGER (GLOBAL SCRIPT)
--
-- The original sitting feature is preserved, but furniture is now selected through
-- explicit interaction profiles. Unknown furniture is skipped unless the relevant
-- fallback setting is enabled in profiles/catalog.lua.
--
-- Active behavior:
--   - sitting on profiled stools/benches, including a light runtime lifecycle.
--   - sleeping on profiled beds, with wake/origin/light handling.
--
-- Extracted for later:
--   - prayer code is intentionally inactive in this build; keep any archived prayer work outside the active mod folder.
-- =============================================================================

local settings = profiles.settings()
local STATES = profiles.INTERACTION_STATES
sdpSettingsRescanState = sdpSettingsRescan.newState()

local function actorDeadReason(actor)
    return assignmentEligibility.actorDeadReason(actor, types)
end

local function primaryPlayer()
    return world and world.players and world.players[1] or nil
end

local stopInteractionForNpc
local targetYawForData
local buildCandidateSlots
local chooseCandidateForNpc
local sendConsiderInteraction
local tryTeleport
local isObjValid
local sleepReservationNpcId
local sleepReservationForCandidate
local updateSleepReservationState
local sleepFinalPlacementSane
local directlyBesideReservedBed
local markSleepRouteRejected
local sleepEligibilityForNpc
local settleInitialPlacementOverlay
local clearSleepHomeOrigin
local isNpcRecordEligibleForInteraction
local rotationFromYaw
local objectNameForFocus
local objectSlotKey
local debugLogOnce

-- Map: npc.id -> active local interaction state.
local assignedActors = {}

-- Map: slotKey -> npc.id. Prevents two actors from taking the same profiled slot.
-- This is runtime-only and also acts as the pending claim while a local NPC
-- script is validating a just-sent candidate.
local occupiedSlots = {}

-- Map: npc.id -> queued sitting reassignment attempts.
local pendingSittingReassignments = {}
local savedPendingLectureAudienceReleases = {}
-- Initial-placement handoffs are tracked so the black cover can be released
-- after the local NPC scripts answer. They also serve as the guard against
-- revealing the world before hidden placement has actually settled.
local pendingInitialHandoffs = {}
local lastInitialPlacementFinalSettleReason = nil
local lastInitialPlacementFinalSettleAt = -100
local followerPackageActors = {}
local recentSittingMemory = {}
local sittingCooldowns = sittingCooldownModule.new()
local postWakeReturnOrigins = nil
local sittingOriginReturns = nil
stationReturnOrigins = nil
sdpSavedInteractionOrigins = {}
-- Same-cell unlocked sleep route doors are tracked in interactions/sleeping/routeDoors.lua.
local largeTimeAdvanceThisUpdate = false

local calibrationMenu = nil
local wakeExit = nil

-- Runtime-only relevant-object cache. This avoids re-checking every cup, bottle,
-- rug, light, and door in the cell every time NPCs reconsider sitting/sleeping.
-- It is rebuilt on cell/settings changes and is never written to save/settings.
local relevantObjectCache = {}
sdpRelevantObjectCacheInvalidator = sdpRelevantObjectCacheInvalidator or sdpRelevantObjectCacheInvalidation.new()
local claimRejectLogCache = {}

local lastCell = nil
local lastCellExterior = nil
local lastPlayerPosition = nil
local onCellChange = nil
sdpDelayedInitialPlacementRetry = {}
sdpAmbientSittingScan = { elapsed = 0 }
sdpExteriorAssignmentScan = sdpExteriorAssignmentScan or { elapsed = 0, sleepElapsed = 0, pending = nil }
local completedInitialCellScan = false
sdpInitialReadyRetryLastEntryAt = sdpInitialReadyRetryLastEntryAt or -100
sdpInitialReadyRetryLastEntrySource = sdpInitialReadyRetryLastEntrySource or nil
sdpInitialReadyRetryLastCandidateCount = sdpInitialReadyRetryLastCandidateCount or 0
sdpInitialReadyRetryAttempts = sdpInitialReadyRetryAttempts or {}
local sleepObservedCooldowns = {}
local sleepWakeRetryCooldowns = {}
local lastSleepLightDeferredLogAt = -999
-- Runtime-only per-NPC/per-bed suppression. If a bed route is rejected for
-- reachability, skip that same slot briefly so another reachable bed can win
-- instead of retrying the wall-blocked candidate every scan.
local sleepRouteRejectCooldowns = {}
sdpSleepReservations = nil
sdpSmoothCalibrationMoveController = nil
local SLEEP_RESERVATION_SECONDS = 12 * 60
local SLEEP_FAILED_RESERVATION_SECONDS = 90
local SLEEP_ORIGIN_PREFERRED_BED_DISTANCE = 230
local SLEEP_DIRECT_BED_ENTRY_DISTANCE = 300
local SLEEP_DIRECT_BED_ENTRY_VERTICAL = 95
local SLEEP_FINAL_MAX_ABOVE_APPROACH_Z = 170
local SLEEP_FINAL_MAX_ABOVE_OBJECT_Z = 260
local SLEEP_EXTERNAL_DISPLACEMENT_DISTANCE = 900
local SLEEP_EXTERNAL_DISPLACEMENT_VERTICAL = 320

local function cellIsExterior(cell)
    if not cell then return false end
    if cell.isExterior ~= nil then return cell.isExterior == true end
    return cell.hasSky == true
end

local function isTeleportInProgressError(err)
    local text = tostring(err or "")
    return text:find("Teleport currently in progress", 1, true) ~= nil
        or text:find("teleport currently in progress", 1, true) ~= nil
        or text:find("already in the process of teleporting", 1, true) ~= nil
end


local function transitionAllowsInitialPlacement(previousCell, currentCell, previousExterior, currentExterior, previousPosition, currentPosition)
    if not previousCell then return true, "initial_load" end
    if previousExterior == true and currentExterior == true then
        local distance = nil
        if previousPosition and currentPosition then
            local ok, value = pcall(function() return (currentPosition - previousPosition):length() end)
            if ok then distance = value end
        end
        if distance and distance > 2200 then return true, "exterior_teleport" end
        return false, "exterior_streaming"
    end
    return true, "load_or_teleport_cell_change"
end

local playerStealthState = { isSneaking = false, known = false, updatedAt = 0 }

-- Sleep should take priority over optional local interactions once an actor's
-- bedtime has arrived. This accumulator avoids scanning the whole cell every
-- frame while still letting seated or idle NPCs reconsider sleep as
-- the night progresses.
local sleepPriorityElapsed = 0
local sleepPriorityGameElapsedHours = 0

-- Sitting lifecycle stays runtime-only and opportunistic: it can auto-place NPCs
-- into seats on cell entry, occasionally release them back to their origin, or
-- ask them to move to another nearby seat. The local NPC script still rejects the
-- assignment if a quest/schedule package is active.
local SITTING_AMBIENT_SCAN_SECONDS = 75
-- Recent-seat memory is deliberately session-only and not written by onSave.
-- It remains an internal bounded convenience, not an end-user setting.
local SITTING_MEMORY_RETENTION_HOURS = 1.0
local SITTING_MEMORY_MAX_ENTRIES = 12
local SITTING_MEMORY_INTERNAL_ENABLED = false
local SITTING_COOLDOWN_SECONDS = 45
local SITTING_BRIEF_WANDER_CHANCE = 0.025
local SITTING_BRIEF_WANDER_DISTANCE = 35
local SITTING_IDLE_WALK_TIMEOUT = 4.0

local lastGameHour = nil

local function debugLog(...)
    if settings and settings.debug == true and settings.verboseDebug ~= true then
        local tag = select(1, ...)
        if profiles.isNoisyDebugTag(tag) then return end
    end
    profiles.debugLog(settings, ...)
end

local function infoLog(...)
    profiles.debugLog(settings, ...)
end

local function verboseInfoLog(...)
    profiles.verboseLog(settings, ...)
end

sdpAnimatedMorrowindAssignment = sdpAnimatedMorrowindAssignmentModule.create({
    settings = function() return settings end,
    profiles = profiles,
    types = types,
    core = core,
    util = util,
    assignedActors = function() return assignedActors end,
    claimRejectLogCache = function() return claimRejectLogCache end,
    isObjValid = function(obj) return isObjValid and isObjValid(obj) or false end,
    actorDeadReason = actorDeadReason,
    hiddenOrStagedNpcReason = function(npc)
        return assignmentEligibility.hiddenOrStagedNpcReason(npc, { types = types, player = primaryPlayer() })
    end,
    buildCandidateSlots = function(cell, interactionType, options)
        return buildCandidateSlots(cell, interactionType, options)
    end,
    objectSlotKey = function(obj, slotName) return objectSlotKey(obj, slotName) end,
    objectName = function(obj) return objectNameForFocus(obj) end,
    tryTeleport = function(obj, cell, pos, opts) return tryTeleport(obj, cell, pos, opts) end,
    smoothMove = function(npc, data, pos, rotation, label, reason, options)
        if sdpQueueSmoothCalibrationMove then
            return sdpQueueSmoothCalibrationMove(npc, data, pos, rotation, label, reason, options)
        end
        return false
    end,
    debugLog = debugLog,
    infoLog = infoLog,
    debugLogOnce = function(cache, key, ...) return debugLogOnce(cache, key, ...) end,
})

function refreshAnimatedMorrowindDetection(reason)
    return sdpAnimatedMorrowindAssignment.refreshDetection(reason)
end

local function sendCalibrationMenuStatus(message, interactionType, targetLabel, cleared, extra)
    local silent = type(extra) == "table" and extra.silent == true
    if targetLabel and not silent then
        infoLog("calibration_target_display_state", tostring(targetLabel), "message", tostring(message))
    elseif cleared == true and not silent then
        infoLog("calibration_target_display_state", "Target: none selected", "message", tostring(message))
    end
    local payload = { message = message, interactionType = interactionType, targetLabel = targetLabel, cleared = cleared == true }
    if type(extra) == "table" then
        for key, value in pairs(extra) do payload[key] = value end
    end
    for _, player in ipairs(world.players or {}) do pcall(function() player:sendEvent("SitDownPleaseCalibrationMenuStatus", payload) end) end
end

sdpZeroCalibrationOffset = function()
    return { x = 0, y = 0, z = 0, yaw = 0 }
end

local function sendCalibrationOffsets(interactionType, profileOffset, animationOffset, calibration, animation, sourceData)
    if interactionType ~= "sitting" and interactionType ~= "sleeping" then return end
    local activeSession = calibrationLock.session
    if not (activeSession and activeSession.interactionType == interactionType) then return end
    local activeLabel = calibrationLock.sessionLabel(activeSession)
    if sourceData then
        local sourceLabel = calibrationLock.sessionLabel(sourceData)
        if sourceLabel ~= activeLabel then return end
    end
    for _, player in ipairs(world.players or {}) do
        pcall(function()
            player:sendEvent("SitDownPleaseCalibrationOffsets", {
                interactionType = interactionType,
                profileOffset = profileOffset or sdpZeroCalibrationOffset(),
                animationOffset = animationOffset or sdpZeroCalibrationOffset(),
                calibration = calibration or sdpZeroCalibrationOffset(),
                animation = animation,
                targetLabel = activeLabel,
                sdpOwnedAssignment = sourceData ~= nil,
                nudgeEnabled = sourceData ~= nil
                    and sourceData.state == STATES.interacting
                    and sourceData.externalPhysicalClaimed ~= true,
                manualOverride = sourceData and sourceData.manualAssignOverrideApplied == true,
                manualOverrideReason = sourceData and sourceData.manualAssignOverrideReason,
                surfaceBlockerReason = sourceData and sourceData.surfaceBlockerReason,
                surfaceBlockerOverrideReason = sourceData and sourceData.surfaceBlockerOverrideReason,
                surfaceBlockerKind = sourceData and sourceData.surfaceBlockerKind,
                surfaceBlockerObjectId = sourceData and sourceData.surfaceBlockerObjectId,
                surfaceBlockerDistance = sourceData and sourceData.surfaceBlockerDistance,
                surfaceBlockerVertical = sourceData and sourceData.surfaceBlockerVertical,
                surfaceBlockerLocalReason = sourceData and sourceData.surfaceBlockerLocalReason,
                softBlockerReason = sourceData and sourceData.softBlockerReason,
                hardBlockerReason = sourceData and sourceData.hardBlockerReason,
                externalPhysicalClaimed = sourceData and sourceData.externalPhysicalClaimed == true,
                safetyEvaluated = sourceData and sourceData.safetyEvaluated == true,
                sleepSafetyReason = sourceData and sourceData.sleepSafetyReason,
                sleepSafetyDelta = sourceData and sourceData.sleepSafetyDelta,
                sleepSafetyLimit = sourceData and sourceData.sleepSafetyLimit,
                sleepSafetyOverrideReason = sourceData and sourceData.sleepSafetyOverrideReason,
                sleepSafetyRepairReason = sourceData and sourceData.sleepSafetyRepairReason,
                sleepSafetyRepairDelta = sourceData and sourceData.sleepSafetyRepairDelta,
                sleepSafetyRepairLimit = sourceData and sourceData.sleepSafetyRepairLimit,
                sleepCalibrationWarningReason = sourceData and sourceData.sleepCalibrationWarningReason,
                sleepAccessOverrideReason = sourceData and sourceData.sleepAccessOverrideReason,
                releaseSafetyGateEnabled = sourceData and sourceData.releaseSafetyGateEnabled,
                releaseSafetyGateStatus = sourceData and sourceData.releaseSafetyGateStatus,
                releaseSafetyGateReason = sourceData and sourceData.releaseSafetyGateReason,
                releaseSafetyGateCell = sourceData and sourceData.releaseSafetyGateCell,
                releaseSafetyGateRegion = sourceData and sourceData.releaseSafetyGateRegion,
                releaseSafetyGateFurnitureType = sourceData and sourceData.releaseSafetyGateFurnitureType,
                releaseSafetyGateLabel = sourceData and sourceData.releaseSafetyGateLabel,
                calibrationFillLabel = sourceData and sourceData.calibrationFillLabel,
                calibrationFillRole = sourceData and sourceData.calibrationFillRole,
                calibrationFillSource = sourceData and sourceData.calibrationFillSource,
                calibrationFillIndex = sourceData and sourceData.calibrationFillIndex,
                calibrationFillSessionId = sourceData and sourceData.calibrationFillSessionId,
                calibrationRuntimeObjectId = sourceData and sourceData.calibrationRuntimeObjectId,
                lectureAudienceTarget = sourceData and sourceData.lectureAudienceTarget == true,
                lectureAudienceSource = sourceData and sourceData.audienceSource,
                lectureAudienceSessionId = sourceData and sourceData.lectureSessionId,
                facingObjectId = sourceData and sourceData.facingObjectId,
                facingObjectRefId = sourceData and sourceData.facingObjectRefId,
                facingObjectModel = sourceData and sourceData.facingObjectModel,
                facingObjectName = sourceData and sourceData.facingObjectName,
                facingObjectScale = sourceData and sourceData.facingObjectScale,
                facingKind = sourceData and sourceData.facingKind,
                facingReason = sourceData and sourceData.facingReason,
                facingSurfaceSource = sourceData and sourceData.facingSurfaceSource,
                facingSurfaceHit = sourceData and sourceData.facingSurfaceHit == true,
                facingCandidates = sourceData and sdpFocusMetadata.sanitizeCandidates(sourceData.facingCandidates, 8),
                ignoredFacingObjectId = sourceData and sourceData.ignoredFacingObjectId,
                ignoredFacingObjectRefId = sourceData and sourceData.ignoredFacingObjectRefId,
                ignoredFacingObjectModel = sourceData and sourceData.ignoredFacingObjectModel,
                ignoredFacingObjectName = sourceData and sourceData.ignoredFacingObjectName,
                ignoredFacingObjectScale = sourceData and sourceData.ignoredFacingObjectScale,
                ignoredFacingKind = sourceData and sourceData.ignoredFacingKind,
                ignoredFacingSurfaceSource = sourceData and sourceData.ignoredFacingSurfaceSource,
                ignoredFacingSurfaceHit = sourceData and sourceData.ignoredFacingSurfaceHit == true,
                ignoredFacingFocusDot = sourceData and sourceData.ignoredFacingFocusDot,
                ignoredFacingCandidates = sourceData and sdpFocusMetadata.sanitizeCandidates(sourceData.ignoredFacingCandidates, 8),
                tableClearanceFocusCleared = sourceData and sourceData.tableClearanceFocusCleared == true,
                tableClearanceFocusClearReason = sourceData and sourceData.tableClearanceFocusClearReason,
                actorScale = sourceData and sourceData.npc and sourceData.npc.scale,
                objectScale = sourceData and sourceData.object and sourceData.object.scale,
            })
        end)
    end
end

function sdpCalibrationStatusExtraFromAssignment(sourceData, extra)
    local payload = {}
    if type(extra) == "table" then
        for key, value in pairs(extra) do payload[key] = value end
    end
    if not sourceData then return payload end
    payload.surfaceBlockerReason = sourceData.surfaceBlockerReason
    payload.surfaceBlockerOverrideReason = sourceData.surfaceBlockerOverrideReason
    payload.surfaceBlockerKind = sourceData.surfaceBlockerKind
    payload.surfaceBlockerObjectId = sourceData.surfaceBlockerObjectId
    payload.surfaceBlockerDistance = sourceData.surfaceBlockerDistance
    payload.surfaceBlockerVertical = sourceData.surfaceBlockerVertical
    payload.surfaceBlockerLocalReason = sourceData.surfaceBlockerLocalReason
    payload.softBlockerReason = sourceData.softBlockerReason
    payload.hardBlockerReason = sourceData.hardBlockerReason
    payload.safetyEvaluated = sourceData.safetyEvaluated == true
    payload.sleepSafetyReason = sourceData.sleepSafetyReason
    payload.sleepSafetyDelta = sourceData.sleepSafetyDelta
    payload.sleepSafetyLimit = sourceData.sleepSafetyLimit
    payload.sleepSafetyOverrideReason = sourceData.sleepSafetyOverrideReason
    payload.sleepSafetyRepairReason = sourceData.sleepSafetyRepairReason
    payload.sleepSafetyRepairDelta = sourceData.sleepSafetyRepairDelta
    payload.sleepSafetyRepairLimit = sourceData.sleepSafetyRepairLimit
    payload.sleepCalibrationWarningReason = sourceData.sleepCalibrationWarningReason
    payload.sleepAccessOverrideReason = sourceData.sleepAccessOverrideReason
    payload.releaseSafetyGateEnabled = sourceData.releaseSafetyGateEnabled
    payload.releaseSafetyGateStatus = sourceData.releaseSafetyGateStatus
    payload.releaseSafetyGateReason = sourceData.releaseSafetyGateReason
    payload.releaseSafetyGateCell = sourceData.releaseSafetyGateCell
    payload.releaseSafetyGateRegion = sourceData.releaseSafetyGateRegion
    payload.releaseSafetyGateFurnitureType = sourceData.releaseSafetyGateFurnitureType
    payload.releaseSafetyGateLabel = sourceData.releaseSafetyGateLabel
    payload.calibrationFillLabel = sourceData.calibrationFillLabel
    payload.calibrationFillRole = sourceData.calibrationFillRole
    payload.calibrationFillSource = sourceData.calibrationFillSource
    payload.calibrationFillIndex = sourceData.calibrationFillIndex
    payload.calibrationFillSessionId = sourceData.calibrationFillSessionId
    payload.calibrationRuntimeObjectId = sourceData.calibrationRuntimeObjectId
    payload.lectureAudienceTarget = sourceData.lectureAudienceTarget == true
    payload.lectureAudienceSource = sourceData.audienceSource
    payload.lectureAudienceSessionId = sourceData.lectureSessionId
    payload.facingObjectId = sourceData.facingObjectId
    payload.facingObjectRefId = sourceData.facingObjectRefId
    payload.facingObjectModel = sourceData.facingObjectModel
    payload.facingObjectName = sourceData.facingObjectName
    payload.facingObjectScale = sourceData.facingObjectScale
    payload.facingKind = sourceData.facingKind
    payload.facingReason = sourceData.facingReason
    payload.facingSurfaceSource = sourceData.facingSurfaceSource
    payload.facingSurfaceHit = sourceData.facingSurfaceHit == true
    payload.facingCandidates = sdpFocusMetadata.sanitizeCandidates(sourceData.facingCandidates, 8)
    payload.ignoredFacingObjectId = sourceData.ignoredFacingObjectId
    payload.ignoredFacingObjectRefId = sourceData.ignoredFacingObjectRefId
    payload.ignoredFacingObjectModel = sourceData.ignoredFacingObjectModel
    payload.ignoredFacingObjectName = sourceData.ignoredFacingObjectName
    payload.ignoredFacingObjectScale = sourceData.ignoredFacingObjectScale
    payload.ignoredFacingKind = sourceData.ignoredFacingKind
    payload.ignoredFacingSurfaceSource = sourceData.ignoredFacingSurfaceSource
    payload.ignoredFacingSurfaceHit = sourceData.ignoredFacingSurfaceHit == true
    payload.ignoredFacingFocusDot = sourceData.ignoredFacingFocusDot
    payload.ignoredFacingCandidates = sdpFocusMetadata.sanitizeCandidates(sourceData.ignoredFacingCandidates, 8)
    payload.tableClearanceFocusCleared = sourceData.tableClearanceFocusCleared == true
    payload.tableClearanceFocusClearReason = sourceData.tableClearanceFocusClearReason
    payload.actorScale = sourceData.npc and sourceData.npc.scale
    payload.objectScale = sourceData.object and sourceData.object.scale
    return payload
end

debugLogOnce = function(cache, key, ...)
    if cache[key] then return end
    cache[key] = true
    debugLog(...)
end

infoLog(
    "startup script loaded",
    "script", "interactionAssignment",
    "version", tostring(profiles.DISPLAY_VERSION or profiles.VERSION),
    "sleep", tostring(settings.enableSleeping),
    "sit", tostring(settings.enableSitting),
    "lights", tostring(settings.enableLightControl),
    "profileRows", tostring(profiles.PROFILE_ROWS_LOADED or 0)
)
profiles.logStartupProfileStatus(infoLog, verboseInfoLog)
infoLog(
    "settings loaded",
    "sleepWindow", tostring(settings.sleepStartHour) .. "-" .. tostring(settings.sleepEndHour),
    "sleepRadius", tostring(settings.sleepSearchRadius),
    "maxRadius", tostring(settings.maxSearchRadius),
    "logLevel", tostring(settings.logLevel),
    "doorAssist", tostring(settings.sleepSmartDoorAssist),
    "initialPlacement", tostring(settings.sleepInitialPlacementEnabled),
    "disguiseInitialPlacement", tostring(settings.disguiseInitialPlacement)
)
refreshAnimatedMorrowindDetection("startup")

sleepLightControl.setDebugLog(debugLog)
sleepLightControl.refreshSettings(settings)

local function clearRelevantObjectCache(reason)
    local shouldClear, reasonKey = sdpRelevantObjectCacheInvalidator.shouldClear(reason, core.getSimulationTime and core.getSimulationTime() or 0)
    if shouldClear ~= true then return end
    relevantObjectCache = {}
    if settings and settings.debug == true then
        debugLog("relevant object cache cleared", reasonKey)
    end
end

local function logSleepLightDeferred(reason, status, currentHour)
    local now = core.getSimulationTime and core.getSimulationTime() or 0
    if now - lastSleepLightDeferredLogAt < 10 then return end
    lastSleepLightDeferredLogAt = now
    status = status or {}
    debugLog(
        "sleep lights daytime failsafe deferred",
        "reason", tostring(reason or "active_sleeper"),
        "sleepers", tostring(status.sleepers),
        "active", tostring(status.activeReplacements),
        "hour", tostring(currentHour)
    )
end

function clearAnimatedMorrowindCompatRuntime(reason)
    return sdpAnimatedMorrowindAssignment.clearRuntime(reason)
end

local function scheduleSittingLifecycle(data, reason)
    return sittingLifecycleModule.schedule(data, {
        settings = settings,
        profiles = profiles,
        debugLog = debugLog,
    }, reason)
end

local function deferSittingLifecycle(data, seconds)
    return sittingLifecycleModule.defer(data, {
        core = core,
    }, seconds)
end

local function calibrationHoldActive(data)
    return data and data.calibrationMenuHoldUntil and core.getSimulationTime() <= data.calibrationMenuHoldUntil
end

SITTING_CALIBRATION_SETTING_KEYS = {
    sittingCalibrationOffsetX = true,
    sittingCalibrationOffsetY = true,
    sittingCalibrationOffsetZ = true,
    sittingCalibrationYawDegrees = true,
}

SLEEP_CALIBRATION_SETTING_KEYS = {
    sleepCalibrationOffsetX = true,
    sleepCalibrationOffsetY = true,
    sleepCalibrationOffsetZ = true,
    sleepCalibrationYawDegrees = true,
}

local function sittingLifecycleAction(data)
    return sittingLifecycleModule.action(data, {
        settings = settings,
        profiles = profiles,
        core = core,
        interactingState = STATES.interacting,
        calibrationHoldActive = calibrationHoldActive,
    })
end

local function cellName(cell)
    return cellContext.cellName(cell)
end

local function sittingMemoryKey(cell, npc)
    if not (cell and npc) then return nil end
    return tostring(cellName(cell)) .. "::" .. tostring(npc.recordId or npc.id)
end

local function pruneSittingMemory(now)
    if SITTING_MEMORY_INTERNAL_ENABLED ~= true then
        recentSittingMemory = {}
        return
    end
    now = now or profiles.getGameHour()
    local count = 0
    local oldestKey, oldestAge = nil, -1
    for key, item in pairs(recentSittingMemory) do
        local age = sittingLifecycleModule.gameHoursSince(item.rememberedHour, now)
        if age == nil or age > SITTING_MEMORY_RETENTION_HOURS then
            recentSittingMemory[key] = nil
        else
            count = count + 1
            if age > oldestAge then oldestKey, oldestAge = key, age end
        end
    end
    if count > SITTING_MEMORY_MAX_ENTRIES and oldestKey then
        recentSittingMemory[oldestKey] = nil
    end
end

local function rememberSittingAssignment(data, reason)
    if SITTING_MEMORY_INTERNAL_ENABLED ~= true then return end
    if not data or data.interactionType ~= "sitting" or not data.npc or not data.object then return end
    local key = sittingMemoryKey(data.npc.cell, data.npc)
    if not key then return end
    pruneSittingMemory()
    -- Store only primitive identifiers. Do not retain object references or vectors
    -- in the short re-entry memory; this keeps the feature bounded and avoids
    -- save/state bloat if OpenMW serializes global Lua state.
    recentSittingMemory[key] = {
        npcRecordId = data.npc.recordId or data.npc.id,
        objectId = data.objectId,
        slotName = data.slotName,
        rememberedHour = profiles.getGameHour(),
        reason = reason or "accepted",
    }
end

local function sittingMemoryFor(npc)
    if SITTING_MEMORY_INTERNAL_ENABLED ~= true then
        if next(recentSittingMemory) ~= nil then recentSittingMemory = {} end
        return nil
    end
    pruneSittingMemory()
    local key = sittingMemoryKey(npc and npc.cell, npc)
    if not key then return nil end
    return recentSittingMemory[key]
end

local function clearSittingMemoryFor(npc, reason)
    if SITTING_MEMORY_INTERNAL_ENABLED ~= true then return end
    local key = sittingMemoryKey(npc and npc.cell, npc)
    if not key or not recentSittingMemory[key] then return end
    recentSittingMemory[key] = nil
    debugLog("sitting memory cleared", npc.recordId or npc.id, tostring(reason or "cleared"))
end

local function chooseRememberedSittingCandidate(npc, candidates)
    if isNpcObjectValidForAssignment and not isNpcObjectValidForAssignment(npc) then return nil end
    local mem = sittingMemoryFor(npc)
    if not (mem and candidates) then return nil end
    for _, candidate in ipairs(candidates) do
        if candidate and candidate.interactionType == "sitting" and not sdpSlotOwnership.claimedByOther(candidate.slotKey, npc, occupiedSlots, assignedActors)
            and candidate.objectId == mem.objectId
            and (mem.slotName == nil or candidate.slotName == mem.slotName) then
            candidate.initialPlacement = true
            candidate.memoryReused = true
            debugLog("sitting memory reused", npc.recordId or npc.id, "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName))
            return candidate
        end
    end
    return nil
end


local function setSittingCooldown(npc, seconds, reason)
    sittingCooldownModule.setNormal(sittingCooldowns, core, npc, seconds, settings.sittingStandCooldownSeconds or SITTING_COOLDOWN_SECONDS, debugLog, reason)
end

local function sittingCooldownActive(npc)
    return sittingCooldownModule.isNormalActive(sittingCooldowns, core, npc)
end

local function setSittingAnimationRejectCooldown(npc, seconds, reason)
    sittingCooldownModule.setAnimationReject(sittingCooldowns, core, npc, seconds, debugLog, reason)
end

local function sittingAnimationRejectCooldownActive(npc)
    return sittingCooldownModule.isAnimationRejectActive(sittingCooldowns, core, npc)
end

sdpSetSittingLocalRejectCooldown = function(npc, slotKey, seconds, reason)
    sittingCooldownModule.setLocalReject(sittingCooldowns, core, npc, slotKey, seconds, debugLog, reason)
end

sdpSittingLocalRejectCooldownActive = function(npc, slotKey)
    return sittingCooldownModule.isLocalRejectActive(sittingCooldowns, core, npc, slotKey)
end


local function isServiceOrFixedPostNpc(npc)
    if not npc or not types.NPC.objectIsInstance(npc) then return true end
    local ok, rec = pcall(types.NPC.record, npc.recordId)
    if not ok or not rec then return true end
    return sdpServicePolicy.isServiceOrFixedPost(rec)
end

local function findBriefIdleWalkDestination(npc, origin)
    if not (npc and origin and npc.cell) then return nil end
    if settings.sittingBriefWanderEnabled ~= true then return nil end
    if isServiceOrFixedPostNpc(npc) then return nil end

    local chance = tonumber(settings.sittingBriefWanderChance or SITTING_BRIEF_WANDER_CHANCE) or SITTING_BRIEF_WANDER_CHANCE
    chance = math.max(0, math.min(chance, 1))
    if chance <= 0 then return nil end
    local key = tostring(npc.recordId or npc.id) .. "::brief-wander::" .. tostring(math.floor((core.getSimulationTime() or 0) / 60))
    if profiles.stableUnitInterval(key) > chance then return nil end

    local maxDist = tonumber(settings.sittingBriefWanderDistance or SITTING_BRIEF_WANDER_DISTANCE) or SITTING_BRIEF_WANDER_DISTANCE
    maxDist = math.max(0, math.min(maxDist, 90))
    if maxDist <= 1 then return nil end

    local candidates = {
        util.vector3(maxDist, 0, 0), util.vector3(-maxDist, 0, 0),
        util.vector3(0, maxDist, 0), util.vector3(0, -maxDist, 0),
        util.vector3(maxDist * 0.7, maxDist * 0.7, 0), util.vector3(-maxDist * 0.7, maxDist * 0.7, 0),
        util.vector3(maxDist * 0.7, -maxDist * 0.7, 0), util.vector3(-maxDist * 0.7, -maxDist * 0.7, 0),
    }
    local start = (math.floor(profiles.stableUnitInterval(key .. "::dir") * #candidates) % #candidates) + 1
    for i = 0, #candidates - 1 do
        local idx = ((start + i - 1) % #candidates) + 1
        return origin + candidates[idx]
    end
    return nil
end

local function notifyPlayersSleepingState(npc, sleeping, reason)
    if not npc then return end
    for _, player in ipairs(world.players) do
        pcall(function()
            player:sendEvent('SitDownPleaseSleepingActorState', {
                actor = npc,
                actorId = npc.id,
                recordId = npc.recordId,
                sleeping = sleeping == true,
                reason = reason,
            })
        end)
    end
end


local RESCAN_SETTING_KEYS = {
    enableSitting = true,
    sittingInitialPlacementEnabled = true,
    sittingLifecycleEnabled = true,
    sittingStandCooldownSeconds = true,
    sittingBriefWanderEnabled = true,
    sittingBriefWanderChance = true,
    sittingBriefWanderDistance = true,
    sittingAllowServiceNpcs = true,
    sittingServiceNpcRadius = true,
    serviceNpcOffHoursSittingChance = true,
    serviceNpcOffHoursPublicanSittingChance = true,
    serviceNpcOffHoursEnabled = true,
    serviceNpcOffHoursStartHour = true,
    serviceNpcOffHoursEndHour = true,
    serviceNpcOffHoursSittingRadius = true,
    serviceNpcOffHoursSleepRadius = true,
    verifiedLocationsOnly = true,
    enableSleeping = true,
    allowFallbackSitting = true,
    allowFallbackBackedChairs = true,
    animatedMorrowindAlignmentAssist = true,
    allowFallbackSleeping = true,
    allowBlockedApproachTeleport = true,
    maxSearchRadius = true,
    sleepSearchRadius = true,
    sleepInitialPlacementSearchRadius = true,
    transitionDistance = true,
    lerpDuration = true,
    sleepStartHour = true,
    sleepForceInBedHour = true,
    sleepEndHour = true,
    sleepInitialPlacementEnabled = true,
    sleepAvoidObservedPlayer = true,
    sleepObservedPlayerCooldown = true,
    sleepObservedPlayerDistance = true,
    sleepObservedPlayerCloseDistance = true,
    sleepObservedPlayerDispositionThreshold = true,
    sleepObservedPlayerAllowanceChance = true,
    sleepingWakeDistance = true,
    sleepingSneakWakeDistance = true,
    sleepWakeStartHour = true,
    sleepJobWakeBias = true,
    enableLightControl = true,
    lightControlRadius = true,
    lightControlAwakeNpcRadius = true,
    lightControlCandles = true,
    lightControlLanterns = true,
    lightControlTorches = true,
    lightControlFires = true,
    lightControlBatchSize = true,
}

profiles.subscribeSettings(require('openmw.async'):callback(function(_, key)
    settings = profiles.settings()
    sleepLightControl.refreshSettings(settings)
    debugLog("settings changed", tostring(key))
    if key == sdpAnimatedMorrowindAssignmentModule.SETTING_KEY then
        clearAnimatedMorrowindCompatRuntime("settings:" .. tostring(key))
        refreshAnimatedMorrowindDetection("settings:" .. tostring(key))
    end


    -- If the player-observation sleep gate is disabled, discard old observation
    -- cooldowns so prior player_observed rejections cannot keep suppressing sleep.
    if key == "sleepAvoidObservedPlayer" and settings.sleepAvoidObservedPlayer ~= true then
        sleepObservedCooldowns = {}
        debugLog("sleep observation gate disabled; cleared observed-player cooldowns")
    end

    if SLEEP_CALIBRATION_SETTING_KEYS[key] then
        -- Sleep calibration must not trigger a full cell assignment pass. A full
        -- rescan can make the actor stand up, create duplicate bed reservations,
        -- and start several identical Travel packages while the user is trying to
        -- tune one bed. Local NPC scripts subscribe to settings and reapply only
        -- their own current locked sleep target.
        debugLog("sleep calibration settings changed", tostring(key), "no_full_rescan")
        return
    end

    if SITTING_CALIBRATION_SETTING_KEYS[key] then
        -- Sitting calibration is a live alignment aid. Do not clear assignments
        -- and rescan the cell, because that can make the exact NPC/seat being
        -- calibrated stand up and choose another chair. Ask current local sitting
        -- scripts to recompute their existing seat placement instead.
        for _, data in pairs(assignedActors) do
            if data and data.interactionType == "sitting" and isObjValid(data.npc) then
                data.npc:sendEvent("SitDownPleaseRefreshSittingCalibration", { reason = "settings:" .. tostring(key) })
            end
        end
        return
    end

    if sdpSettingsRescan.isDebouncedKey(key) then
        sdpSettingsRescan.queue(sdpSettingsRescanState, core.getSimulationTime and core.getSimulationTime() or 0, key, 0.85)
        debugLog("settings rescan queued", tostring(key), "debounced", "true")
        return
    end

    -- Only behavior-affecting settings trigger a rescan. Pure diagnostics like
    -- debug should not make everyone stand up and reassess their object.
    if RESCAN_SETTING_KEYS[key] then
        clearRelevantObjectCache("settings:" .. tostring(key))
        if onCellChange then onCellChange("settings") end
    end
end))

isObjValid = function(obj)
    local ok, valid = pcall(function()
        return obj and obj.isValid and obj:isValid()
    end)
    if not (ok and valid == true) then return false end
    local okEnabled, enabled = pcall(function() return obj.enabled end)
    if okEnabled and enabled == false then return false end
    return true
end

isNpcObjectValidForAssignment = function(npc)
    if not (npc and npc.id and npc.position and npc.cell and types and types.NPC and types.NPC.objectIsInstance) then
        return false
    end
    local okNpc, isNpc = pcall(types.NPC.objectIsInstance, npc)
    if not (okNpc and isNpc == true) then return false end
    return isObjValid(npc)
end

local function deferTeleportFailure(data, err, context)
    if not data then return false end
    if isTeleportInProgressError(err) then
        -- OpenMW reports this when a previous teleport has been accepted but has
        -- not completed yet. This should resolve quickly. If it persists, stop
        -- the interaction instead of generating minutes of log spam and keeping
        -- the actor trapped in a correction loop.
        local now = core.getSimulationTime() or 0
        data.teleportBusySkips = (data.teleportBusySkips or 0) + 1
        data.teleportBusyFirstAt = data.teleportBusyFirstAt or now
        local busyDuration = now - data.teleportBusyFirstAt
        local calibrationHold = data.calibrationMenuHoldUntil and now <= data.calibrationMenuHoldUntil
        local maxBusy = data.interactionType == "sitting" and 3.0 or 6.0
        if calibrationHold then
            maxBusy = math.max(maxBusy, 45.0)
        end
        if busyDuration > maxBusy then
            data.teleportBusyTimedOut = true
            data.teleportBusyTimeoutContext = context
            data.teleportBusyTimeoutAt = now
            debugLog(
                "teleport busy timeout",
                data.npc and (data.npc.recordId or data.npc.id) or "<npc>",
                tostring(context),
                "seconds", tostring(busyDuration),
                tostring(err)
            )
            return false
        end
        if settings.debug == true and (data.teleportBusySkips == 1 or data.teleportBusySkips % 300 == 0) then
            debugLog("teleport busy deferred", data.npc and (data.npc.recordId or data.npc.id) or "<npc>", tostring(context), tostring(err))
        end
        return true
    end
    return false
end

calibrationMenu = require('scripts/sitDownPlease/calibration/actionController').create({
    world = world,
    core = core,
    types = types,
    util = util,
    storage = storage,
    profiles = profiles,
    settings = settings,
    calibrationLock = calibrationLock,
    interactingState = STATES.interacting,
    isObjValid = function(obj) return isObjValid(obj) end,
    buildCandidateSlots = function(...) return buildCandidateSlots(...) end,
    chooseCandidateForNpc = function(...) return chooseCandidateForNpc(...) end,
    sendConsiderInteraction = function(...) return sendConsiderInteraction(...) end,
    infoLog = infoLog,
    debugLog = debugLog,
    cellName = cellName,
    releaseSafetyGate = sdpReleaseSafetyGate,
    clearRelevantObjectCache = clearRelevantObjectCache,
    getAssignedActors = function() return assignedActors end,
    isSlotOccupied = function(slotKey)
        return sdpSlotOwnership.ownerFor(slotKey, occupiedSlots, assignedActors) ~= nil
    end,
    clearOccupiedSlot = function(slotKey, reason)
        if not slotKey then return false end
        local ownerId = occupiedSlots[slotKey]
        occupiedSlots[slotKey] = nil
        if ownerId ~= nil then
            debugLog("occupied slot cleared", tostring(slotKey), "owner", tostring(ownerId), "reason", tostring(reason))
            return true
        end
        return false
    end,
    stopInteractionForNpc = function() return stopInteractionForNpc end,
    isNpcEligibleForInteraction = function(...) return isNpcRecordEligibleForInteraction(...) end,
    triggerStationLecture = function(...) if sdpTriggerStationLecture then return sdpTriggerStationLecture(...) end end,
    claimStationWithNpc = function(...) if sdpClaimStationWithNpc then return sdpClaimStationWithNpc(...) end return false, "station_claim_unavailable" end,
    releaseStationForNpc = function(...) if sdpReleaseStationForNpc then return sdpReleaseStationForNpc(...) end return false end,
    stationSlotKey = function(...) return sdpStationSlotKey(...) end,
    stationSlotOccupied = function(...) if sdpStationSlotOccupied then return sdpStationSlotOccupied(...) end return false, false end,
    stationDataForNpc = function(...) if sdpStationDataForNpc then return sdpStationDataForNpc(...) end return nil end,
    claimedStationData = function(...) if sdpClaimedStationData then return sdpClaimedStationData(...) end return nil end,
    applyStationCalibration = function(...) if sdpApplyStationCalibration then return sdpApplyStationCalibration(...) end return false, "station_calibration_unavailable" end,
})

wakeExit = require('scripts/sitDownPlease/interactions/sleeping/wakeExit').create({
    core = core,
    isObjValid = function(obj) return isObjValid(obj) end,
    tryTeleport = function(obj, cell, pos, opts) return tryTeleport(obj, cell, pos, opts) end,
    debugLog = debugLog,
    infoLog = infoLog,
    isNpcBusyForPostWake = function(npcId)
        return assignedActors[npcId] ~= nil
            or wakeExit.hasPendingStandTeleport(npcId)
            or wakeExit.hasPendingWakeExitWalk(npcId)
    end,
    onStandTeleportSuccess = function(npcId, npc, tdata, _, mode)
        if tdata.clearSleepHomeOnSuccess == true and not tdata.returnOriginPosition then
            clearSleepHomeOrigin(npc, mode == "immediate" and "time_advance_wake_exit_placed" or "queued_time_advance_wake_exit_placed")
            ---@type any
            local origins = postWakeReturnOrigins
            if origins and origins.clear then origins:clear(npcId) end
        end
        if tdata.returnOriginPosition then
            ---@type any
            local origins = postWakeReturnOrigins
            local persistentOriginReturn = tdata.returnOriginPosition ~= nil
            if origins and origins.set then origins:set(npcId, {
                npc = npc,
                origin = tdata.returnOriginPosition,
                rotation = tdata.returnOriginRotation or tdata.rotation or npc.rotation,
                reason = tdata.reason,
                keepTrying = persistentOriginReturn,
                maxAttempts = persistentOriginReturn and 20 or nil,
                retryAfterMaxAttempts = persistentOriginReturn and 15 or nil,
                completionRadius = persistentOriginReturn and 16 or nil,
                exactOnComplete = persistentOriginReturn,
                nextAttemptAt = core.getSimulationTime() + 0.75,
                maxNoProgressAttempts = 3,
            }) end
            debugLog(mode == "immediate" and "interaction return origin scheduled" or "queued interaction return origin scheduled", npc.recordId or npc.id, tostring(tdata.reason), "origin", tostring(tdata.returnOriginPosition))
            local assisted, assistReason = false, nil
            if sleepRouteDoors and sleepRouteDoors.assistWakeReturn then
                assisted, assistReason = sleepRouteDoors.assistWakeReturn(npc, tdata.returnOriginPosition, tdata.reason or "wake_return_origin")
            end
            if assisted == true then
                debugLog(
                    "interaction return origin door-assisted",
                    npc.recordId or npc.id,
                    tostring(tdata.reason),
                    "origin", tostring(tdata.returnOriginPosition),
                    "doorReason", tostring(assistReason)
                )
                return
            end
            debugLog("interaction return origin queued", npc.recordId or npc.id, tostring(tdata.reason), "origin", tostring(tdata.returnOriginPosition), "delay", "0.75")
        end
    end,
})

sleepRouteDoors.configure({
    infoLog = infoLog,
    debugLog = debugLog,
    isObjValid = function(obj) return isObjValid(obj) end,
    assignedActors = function() return assignedActors end,
    states = STATES,
    sleepReservationExistsForNpc = function(npc)
        return sdpSleepReservations.existsForNpc(npc)
    end,
})

sdpStationRouteDoors.configure({
    infoLog = infoLog,
    debugLog = debugLog,
    isObjValid = function(obj) return isObjValid(obj) end,
    now = core.getSimulationTime,
})

local function processPendingSittingReassignments()
    local t = core.getSimulationTime()
    sdpLectureSeatReservations.prune(t)
    if #savedPendingLectureAudienceReleases > 0 then
        local player = primaryPlayer()
        local restored, dropped
        savedPendingLectureAudienceReleases, restored, dropped = sdpLectureAudienceReleasePersistence.restoreAvailable(savedPendingLectureAudienceReleases, pendingSittingReassignments, {
            activeActors = world.activeActors,
            activeCellName = player and player.cell and cellName(player.cell) or nil,
            now = core.getSimulationTime,
            isObjValid = isObjValid,
            cellName = cellName,
            rotationFromYaw = rotationFromYaw,
        })
        if restored and restored > 0 then
            debugLog("pending lecture audience releases restored", tostring(restored))
        end
        if dropped and dropped > 0 then
            debugLog("stale pending lecture audience releases dropped", tostring(dropped))
        end
    end
    for npcId, item in pairs(pendingSittingReassignments) do
        local npc = type(item) == "table" and item.npc or nil
        if type(item) ~= "table" then
            -- Metadata such as lifecycle group timing lives beside queued NPC
            -- reassignments; only table entries are actual reassignment jobs.
        elseif item.due and item.due > t then
            -- not due yet
        elseif item.releaseOnly == true then
            pendingSittingReassignments[npcId] = nil
            if assignedActors[npcId] then
                local data = assignedActors[npcId]
                if item.returnToSitting == true
                    and data
                    and data.interactionType == "sitting"
                    and data.lectureAudienceTarget == true then
                    local restoreAnimation = data.lectureAudienceOriginalAnimation
                        or data.animationName
                        or (data.profile and data.profile.animation)
                    if sdpLectureAudienceBridge and sdpLectureAudienceBridge.clear then
                        sdpLectureAudienceBridge.clear(data)
                    end
                    scheduleSittingLifecycle(data, "lecture_audience_return_to_sitting")
                    ---@type any
                    local eventNpc = npc
                    if eventNpc then
                        eventNpc:sendEvent("SitDownPleaseLectureAudienceRelease", {
                            reason = item.source or "lecture_ended",
                            animation = restoreAnimation,
                        })
                    end
                    sdpLectureTrace.log(
                        debugLog,
                        "audience_release_to_sitting",
                        "actor", tostring(npc and (npc.recordId or npc.id) or npcId),
                        "source", tostring(item.source),
                        "animation", tostring(restoreAnimation)
                    )
                else
                    if item.returnOriginPosition then
                        data.preInteractionPos = item.returnOriginPosition
                        data.preInteractionRot = item.returnOriginRotation or data.preInteractionRot
                        local hiddenReturnOk = sdpLectureAudienceRelease.tryHiddenOriginReturn({
                            settings = settings,
                            tryTeleport = tryTeleport,
                            debugLog = debugLog,
                        }, npc, item.returnOriginPosition, data.preInteractionRot, item.source)
                        data.lectureAudienceReturnMode = hiddenReturnOk and "origin_hidden_teleport" or "origin_walk"
                        sdpLectureTrace.log(
                            debugLog,
                            "audience_release_return_origin",
                            "actor", tostring(npc and (npc.recordId or npc.id) or npcId),
                            "station", tostring(data.stationSlotKey),
                            "origin", tostring(item.returnOriginPosition),
                            "source", tostring(item.source),
                            "mode", hiddenReturnOk and "hidden_teleport_release_due" or "release_due"
                        )
                        if npc and npc.sendEvent then
                            npc:sendEvent("SitDownPleaseLectureAudienceRelease", {
                                reason = item.source or "lecture_ended",
                                restoreSitting = false,
                            })
                        end
                    end
                    stopInteractionForNpc(npc, item.stopReason or item.source or "lecture_ended")
                end
            elseif npc and item.returnOriginPosition then
                local hiddenReturnOk = sdpLectureAudienceRelease.tryHiddenOriginReturn({
                    settings = settings,
                    tryTeleport = tryTeleport,
                    debugLog = debugLog,
                }, npc, item.returnOriginPosition, item.returnOriginRotation, item.source)
                sdpLectureTrace.log(
                    debugLog,
                    "audience_release_return_origin",
                    "actor", tostring(npc.recordId or npc.id or npcId),
                    "station", tostring(item.stationSlotKey),
                    "origin", tostring(item.returnOriginPosition),
                    "source", tostring(item.source),
                    "mode", hiddenReturnOk and "orphan_hidden_teleport_release_due" or "orphan_release_due"
                )
                if npc.sendEvent then
                    npc:sendEvent("SitDownPleaseLectureAudienceRelease", {
                        reason = item.source or "lecture_ended",
                        restoreSitting = false,
                    })
                end
                if not hiddenReturnOk and stationReturnOrigins then
                    stationReturnOrigins:set(npc.id, {
                        npc = npc,
                        origin = item.returnOriginPosition,
                        rotation = item.returnOriginRotation or npc.rotation,
                        reason = item.source or "lecture_ended",
                        keepTrying = true,
                        maxAttempts = 20,
                        retryAfterMaxAttempts = 15,
                        completionRadius = 16,
                        exactOnComplete = true,
                        preserveExternalPackage = true,
                    })
                end
            end
            local npcLabel = npc and (npc.recordId or npc.id) or tostring(npcId)
            debugLog("sitting lifecycle release after lecture", npcLabel, tostring(item.source))
        elseif assignedActors[npcId] or wakeExit.hasPendingStandTeleport(npcId) then
            item.due = t + 0.25
        elseif not isObjValid(npc) then
            pendingSittingReassignments[npcId] = nil
        else
            if not (npc and npc.cell) then
                pendingSittingReassignments[npcId] = nil
                debugLog("sitting lifecycle reassign no cell", tostring(npcId))
            else
                local candidates = buildCandidateSlots(npc.cell, "sitting", {
                    lectureAudienceTarget = item.preferLecternAudience == true,
                    interiorLecternAudience = item.interiorLecternAudience == true,
                    lectureFocusObject = item.lecternObject,
                    lectureFocusPosition = item.stationPosition or item.lecternPosition,
                })
                local pendingReservedCount = 0
                if item.preferLecternAudience == true then
                    local filtered = {}
                    for _, candidate in ipairs(candidates) do
                        if sdpLectureSeatReservations.reservedForOther(candidate, npcId, t) then
                            pendingReservedCount = pendingReservedCount + 1
                        else
                            filtered[#filtered + 1] = candidate
                        end
                    end
                    candidates = filtered
                end
                if item.preferLecternAudience == true then
                    local npcLabel = npc and (npc.recordId or npc.id) or tostring(npcId)
                    sdpLectureTrace.log(
                        debugLog,
                        "seat_candidates_found",
                        "actor", tostring(npcLabel),
                        "count", tostring(#candidates),
                        "pendingReserved", tostring(pendingReservedCount),
                        "station", tostring(item.stationSlotKey),
                        "teleport", tostring(item.lectureAudienceTeleport == true)
                    )
                end
                local candidate = chooseCandidateForNpc(npc, candidates, "sitting", {
                    avoidSlotKey = item.avoidSlotKey,
                    preferLecternAudience = item.preferLecternAudience == true,
                    lecternPosition = item.lecternPosition,
                    stationPosition = item.stationPosition,
                    stationFacingDirection = item.stationFacingDirection,
                    interiorLecternAudience = item.interiorLecternAudience == true,
                })
                if candidate then
                    pendingSittingReassignments[npcId] = nil
                    candidate.lectureAudienceTarget = item.preferLecternAudience == true
                    candidate.lectureAudienceOriginPosition = item.lectureAudienceOriginPosition
                    candidate.lectureAudienceOriginRotation = item.lectureAudienceOriginRotation
                    candidate.lectureAudienceOriginSource = item.lectureAudienceOriginSource
                    candidate.lecternPosition = item.lecternPosition
                    candidate.stationPosition = item.stationPosition
                    candidate.stationFacingDirection = item.stationFacingDirection
                    candidate.audienceHeadFocusPosition = item.audienceHeadFocusPosition or item.stationPosition or item.lecternPosition
                    candidate.lectureSessionId = item.lectureSessionId
                    candidate.stationSlotKey = item.stationSlotKey
                    candidate.audienceSource = item.audienceSource or item.source
                    candidate.lectureAudienceShortcut = item.lectureAudienceShortcut == true
                    candidate.lectureAudienceTeleport = item.lectureAudienceTeleport == true
                    local npcLabel = npc and (npc.recordId or npc.id) or tostring(npcId)
                    if item.preferLecternAudience == true then
                        sdpLectureSeatReservations.reserve(candidate, npcId, t, 7)
                        sdpLectureTrace.log(
                            debugLog,
                            "audience_assignment_sent",
                            "actor", tostring(npcLabel),
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidate.slotName),
                            "station", tostring(item.stationSlotKey),
                            "headFocus", tostring(candidate.audienceHeadFocusPosition),
                            "shortcut", tostring(item.lectureAudienceShortcut == true),
                            "teleport", tostring(item.lectureAudienceTeleport == true)
                        )
                    end
                    debugLog("sitting lifecycle reassign", npcLabel, "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName))
                    sendConsiderInteraction(npc, candidate)
                else
                    pendingSittingReassignments[npcId] = nil
                    local npcLabel = npc and (npc.recordId or npc.id) or tostring(npcId)
                    if item.preferLecternAudience == true then
                        sdpLectureTrace.log(
                            debugLog,
                            "audience_assignment_failed",
                            "actor", tostring(npcLabel),
                            "reason", "no_valid_audience_seat",
                            "station", tostring(item.stationSlotKey),
                            "source", tostring(item.audienceSource or item.source),
                            "shortcut", tostring(item.lectureAudienceShortcut == true),
                            "teleport", tostring(item.lectureAudienceTeleport == true)
                        )
                    end
                    debugLog("sitting lifecycle reassign no candidate", npcLabel)
                    infoLog(
                        "lecture audience assignment failed",
                        npcLabel,
                        "reason", "no_valid_audience_seat",
                        "station", tostring(item.stationSlotKey),
                        "source", tostring(item.audienceSource or item.source),
                        "shortcut", tostring(item.lectureAudienceShortcut == true),
                        "teleport", tostring(item.lectureAudienceTeleport == true)
                    )
                end
            end
        end
    end
end

local function processPendingSittingOriginWalks()
    if sittingOriginReturns then sittingOriginReturns:process() end
end

local function addUniquePosition(list, pos)
    if not pos then return end
    for _, existing in ipairs(list) do
        if existing and (existing - pos):length() < 8 then return end
    end
    table.insert(list, pos)
end

rotationFromYaw = function(yaw, fallback)
    if type(yaw) == "number" then
        return util.transform.rotateZ(yaw)
    elseif yaw then
        return yaw
    end
    return fallback
end

tryTeleport = function(obj, cell, pos, opts)
    local ok, err = pcall(function()
        obj:teleport(cell, pos, opts)
    end)
    return ok, err
end

function sdpSmoothCalibrationReason(reason)
    return smoothMoveModule.reason(reason)
end

function sdpYawDeltaShortest(fromYaw, toYaw)
    return smoothMoveModule.yawDelta(fromYaw, toYaw)
end

sdpSmoothCalibrationMoveController = smoothMoveModule.create({
    now = core.getSimulationTime,
    isObjValid = function(obj) return isObjValid and isObjValid(obj) or false end,
    assignedActorFor = function(npcId) return npcId and assignedActors[npcId] or nil end,
    isInteractionState = function(data)
        return data and (data.state == STATES.interacting or data.state == STATES.transitioning)
    end,
    tryTeleport = tryTeleport,
    rotationFromYaw = rotationFromYaw,
    deferTeleportFailure = deferTeleportFailure,
    debugLog = debugLog,
})

function sdpQueueSmoothCalibrationMove(npc, data, finalPosition, finalRotation, label, reason, options)
    return sdpSmoothCalibrationMoveController.queue(npc, data, finalPosition, finalRotation, label, reason, options)
end

function sdpSmoothCalibrationMoveActive(npcId)
    return sdpSmoothCalibrationMoveController.active(npcId)
end

function sdpProcessSmoothCalibrationMoves()
    return sdpSmoothCalibrationMoveController.process()
end


local function sendBeginTransitionEvent(npc, data, reason)
    if not npc or not data then return end
    npc:sendEvent('BeginInteractionTransition', {
        interactionType = data.interactionType,
        targetPos = data.approachPos or data.position,
        reason = reason,
        radius = data.interactionType == "sleeping" and 900 or 80,
    })
end

sdpSleepEntryGateEnv = function()
    return {
        settings = settings,
        sleepReservations = sdpSleepReservations,
        sleepReservationForCandidate = sleepReservationForCandidate,
        directEntryDistance = SLEEP_DIRECT_BED_ENTRY_DISTANCE,
        directEntryVertical = SLEEP_DIRECT_BED_ENTRY_VERTICAL,
    }
end

local function sleepEntryGate(npc, data, reason)
    return sdpSleepEntryGate.evaluate(sdpSleepEntryGateEnv(), npc, data, reason)
end

local function beginTransition(npc, data, reason)
    if not npc or not data or data.state == STATES.transitioning or data.state == STATES.interacting then return end

    if data.interactionType == "sleeping" then
        local allowed, gateReason, approachDistance, vertical = sleepEntryGate(npc, data, reason or "begin_transition")
        if not allowed then
            debugLog(
                "sleep_entry_rejected",
                npc.recordId or npc.id,
                "reason", tostring(gateReason),
                "trigger", tostring(reason or "begin_transition"),
                "object", tostring(data.objectId),
                "approachDistance", tostring(approachDistance),
                "vertical", tostring(vertical)
            )
            stopInteractionForNpc(npc, gateReason or "sleep_entry_rejected")
            return
        end

        data.reachedValidSleepApproach = true
        debugLog(
            "sleep_entry_allowed",
            npc.recordId or npc.id,
            "reason", tostring(gateReason),
            "trigger", tostring(reason or "begin_transition"),
            "object", tostring(data.objectId),
            "approachDistance", tostring(approachDistance),
            "vertical", tostring(vertical)
        )
    end

    sendBeginTransitionEvent(npc, data, reason or "begin_transition")

    -- Beds are collision/pathing trouble spots. Once the NPC has gotten close
    -- enough or has stalled at the edge, snap directly into the final sleep pose
    -- instead of requiring the Travel package to reach an exact approach marker.
    if data.interactionType == "sleeping" and data.profile and data.profile.sleepSnapIntoBed ~= false and data.finalPosition then
        -- Do not reject tall beds solely because the final prone root is above
        -- the actor's floor position. Only block the visibly bad case: a fallback
        -- transition where the NPC is still nowhere near either the bed object or
        -- the selected approach point. If the actor actually reaches the approach,
        -- allow the bed snap even when Z differs.
        local routeIncomplete, approachDistance, objectDistance = sdpSleepEntryGate.snapRouteIncomplete(sdpSleepEntryGateEnv(), npc, data, reason)
        if routeIncomplete then
            debugLog("sleep entry snap rejected", npc.recordId or npc.id, "reason", tostring(reason), "approachDistance", tostring(approachDistance), "objectDistance", tostring(objectDistance), "object", tostring(data.objectId))
            stopInteractionForNpc(npc, "visible_sleep_route_incomplete")
            return
        end
        local sane, sanityReason, sanityDelta, sanityLimit = sleepFinalPlacementSane(npc, data, data.finalPosition, reason or "sleep_entry")
        if not sane then
            debugLog(
                "sleep placement rejected",
                npc.recordId or npc.id,
                "reason", tostring(sanityReason),
                "trigger", tostring(reason or "sleep_entry"),
                "object", tostring(data.objectId),
                "delta", tostring(sanityDelta),
                "limit", tostring(sanityLimit),
                "final", tostring(data.finalPosition),
                "approach", tostring(data.approachPos)
            )
            stopInteractionForNpc(npc, sanityReason or "sleep_placement_rejected")
            return
        end

        local targetAngle = targetYawForData(npc, data)
        local ok, err = tryTeleport(npc, npc.cell, data.finalPosition, { rotation = rotationFromYaw(targetAngle, npc.rotation) })
        if not ok then
            if deferTeleportFailure(data, err, "sleep_entry") then
                return
            end
            debugLog("sleep entry teleport failed", npc.recordId or npc.id, tostring(reason), tostring(err))
            stopInteractionForNpc(npc, "sleep_entry_teleport_failed")
            return
        end

        sleepRouteDoors.closeForNpc(npc.id, "sleep_entry")
        data.state = STATES.interacting
        updateSleepReservationState(npc, "sleeping", reason or "sleep_entry")
        data.interactionStartedAt = core.getSimulationTime()
        data.usedSleepEntrySnap = true
        data.sleepExternalDisplacementGraceUntil = core.getSimulationTime() + 1.5
        data.sentStartEvent = true
        data.lerpTime = 1
        notifyPlayersSleepingState(npc, true, reason or "sleep_entry")
        sleepLightControl.registerSleeper(npc, {
            object = data.object,
            bed = data.object,
            bedId = data.objectId,
            finalPosition = data.finalPosition,
            position = data.finalPosition,
            exitPosition = data.exitPosition,
            approachPosition = data.approachPos,
            originPosition = data.preInteractionPos,
            initialPlacement = data.initialPlacement == true,
            visibleSleep = data.initialPlacement ~= true,
        }, false)

        debugLog(
            "sleep entry teleport",
            npc.recordId or npc.id,
            tostring(data.interactionType),
            tostring(data.slotName),
            "reason", tostring(reason or "sleep_entry_snap")
        )

        -- Give OpenMW a short moment to finish the accepted teleport before
        -- starting the lying pose. Starting the animation and then immediately
        -- hitting an "already in the process of teleporting" correction error was
        -- causing the global script to stop the interaction and queue a stand-up
        -- teleport, which looked like a brief flash onto the bed followed by the
        -- NPC standing at the edge.
        data.pendingStartEvent = true
        data.startEventDelay = data.profile.sleepStartAnimationDelay or 0.25
        data.sentStartEvent = false
        return
    end

    data.npcStandingPos = npc.position
    data.npcStandingRot = npc.rotation
    data.state = STATES.transitioning
    data.lerpTime = 0

    if data.interactionType == "sitting" and data.manualAssign == true and data.profile and not data.sentStartEvent then
        data.sentStartEvent = true
        npc:sendEvent('StartInteractionAnimation', {
            interactionType = data.interactionType,
            animation = data.profile.animation,
            animationOptions = data.profile.animationOptions,
            forceReplay = true,
            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
        })
    end

    debugLog(
        "transitioning",
        npc.recordId or npc.id,
        tostring(data.interactionType),
        tostring(data.slotName),
        "reason", tostring(reason or "reached_approach")
    )
end

local function updateApproachProgress(npc, data, distance, dt)
    if not npc or not data or data.state ~= STATES.approaching then return false end

    data.approachElapsed = (data.approachElapsed or 0) + dt
    local sleepTimeoutReason, sleepTimeoutMax = sleepApproachTimeout.reason(data)
    if sleepTimeoutReason then
        debugLog(
            "sleep approach timeout",
            npc.recordId or npc.id,
            "object", tostring(data.objectId),
            "slot", tostring(data.slotName),
            "elapsed", tostring(data.approachElapsed),
            "max", tostring(sleepTimeoutMax),
            "distance", tostring(distance),
            "reason", tostring(sleepTimeoutReason)
        )
        stopInteractionForNpc(npc, sleepTimeoutReason)
        local retried, retryReason = sleepRouteRejection.retryAfterStopped({
            debugLog = debugLog,
            markSleepRouteRejected = markSleepRouteRejected,
            sleepEligibilityForNpc = sleepEligibilityForNpc,
            buildCandidateSlots = buildCandidateSlots,
            chooseCandidateForNpc = chooseCandidateForNpc,
            sendConsiderInteraction = sendConsiderInteraction,
        }, npc, data, sleepTimeoutReason)
        if retried ~= true and retryReason == "no_candidate" then
            sleepRouteRejection.returnHomeAfterFailedRoute({
                sendReturnHomeAfterFailedRoute = function(returnNpc, returnData, returnReason)
                    local origin = returnData and returnData.preInteractionPos
                    if not (isObjValid(returnNpc) and origin and returnNpc.position) then return false end
                    if (returnNpc.position - origin):length() <= 120 then return false end
                    local assisted, assistReason = sleepRouteDoors.assistWakeReturn(returnNpc, origin, "sleep_route_failure_return_origin")
                    if assisted == true then
                        debugLog(
                            "sleep_route_failure_return_origin_door_assisted",
                            returnNpc.recordId or returnNpc.id,
                            "reason", tostring(returnReason),
                            "origin", tostring(origin),
                            "failedObject", tostring(returnData.objectId),
                            "slot", tostring(returnData.slotName),
                            "assistReason", tostring(assistReason)
                        )
                        return true
                    end
                    returnNpc:sendEvent('SitDownPleaseStartAIPackage', {
                        type = "Travel",
                        destPosition = origin,
                        isRepeat = false,
                        cancelOther = true,
                        destinationTolerance = 100,
                    })
                    debugLog(
                        "sleep_route_failure_return_origin",
                        returnNpc.recordId or returnNpc.id,
                        "reason", tostring(returnReason),
                        "origin", tostring(origin),
                        "failedObject", tostring(returnData.objectId),
                        "slot", tostring(returnData.slotName),
                        "assistReason", tostring(assistReason)
                    )
                    return true
                end,
            }, npc, data, sleepTimeoutReason)
        end
        return true
    end

    local minImprovement = data.profile.approachMinProgress or 5
    if data.lastApproachDistance == nil or distance < data.lastApproachDistance - minImprovement then
        data.lastApproachDistance = distance
        data.approachStuckElapsed = 0
        return false
    end

    data.approachStuckElapsed = (data.approachStuckElapsed or 0) + dt

    local timeout = data.profile.approachStuckTimeout or 4
    local hardTimeout = data.profile.approachHardTimeout
    local forceMinSeconds = data.profile.approachForceMinSeconds or 0
    local verticalToApproach = data.approachPos and math.abs((npc.position.z or 0) - (data.approachPos.z or 0)) or 0
    if data.interactionType == "sleeping" and verticalToApproach > 55 and data.manualAssignOverrideTesting ~= true then
        timeout = math.max(timeout, 18)
        hardTimeout = math.max(hardTimeout or 0, 30)
        forceMinSeconds = math.max(forceMinSeconds, 8)
    end
    local stuckTimedOut = data.approachStuckElapsed >= timeout
    local hardTimedOut = hardTimeout and data.approachElapsed >= hardTimeout

    if not stuckTimedOut and not hardTimedOut then return false end
    if data.manualAssignOverrideTesting == true and require('scripts/sitDownPlease/assignment/manualAssignment').tryManualRouteFallback({
        infoLog = infoLog,
        debugLog = debugLog,
        tryTeleport = tryTeleport,
        beginTransition = beginTransition,
        rotationFromYaw = rotationFromYaw,
        targetYawForData = targetYawForData,
        sendStatus = sendCalibrationMenuStatus,
        stopInteractionForNpc = stopInteractionForNpc,
    }, npc, data, distance, stuckTimedOut, hardTimedOut) then
        return true
    end

    local blockedFallbackAllowed = sdpSleepEntryGate.blockedFallbackAllowed(sdpSleepEntryGateEnv(), data.profile)
    local directBedEntryAllowed = false
    if data.interactionType == "sleeping" then
        directBedEntryAllowed = sdpSleepEntryGate.directBedEntryAllowed(sdpSleepEntryGateEnv(), npc, data)
    end
    if not (blockedFallbackAllowed or directBedEntryAllowed) then
        return false
    end

    if data.approachElapsed < forceMinSeconds and not directBedEntryAllowed then
        return false
    end

    if not sdpSleepEntryGate.nearEnoughForBlockedApproachFallback(npc, data) then
        return false
    end

    local reason = hardTimedOut and "approach_hard_timeout_fallback" or "blocked_approach_fallback"
    debugLog(
        reason,
        npc.recordId or npc.id,
        "type", tostring(data.interactionType),
        "object", tostring(data.objectId),
        "profile", tostring(data.profileId),
        "approachDistance", tostring(distance),
        "stuckSeconds", tostring(data.approachStuckElapsed),
        "elapsed", tostring(data.approachElapsed)
    )

    if data.interactionType == "sleeping" then
        -- If the actor is genuinely stuck right at the reserved bed edge, let
        -- sleepEntryGate make the final safe/no-wall/no-floor decision instead
        -- of rejecting every blocked-approach fallback.
        beginTransition(npc, data, reason)
        return true
    end

    beginTransition(npc, data, reason)
    return true
end

local function objectLocalOffset(obj, offset)
    if not obj then return nil end
    if not offset then return obj.position end
    return sdpScalePolicy.objectLocalPosition(util, obj, offset)
end

objectSlotKey = function(obj, slotName)
    local pos = obj.position
    local posKey = pos and string.format("@%.1f,%.1f,%.1f", pos.x, pos.y, pos.z) or ""
    return tostring(obj.id or obj.recordId or "<object>") .. posKey .. "::" .. tostring(slotName or "default")
end

sdpStationSlotKey = function(obj, profile)
    return objectSlotKey(obj, "station:" .. tostring(profile and profile.slotName or "station"))
end

local function actorKey(npc)
    return cellContext.actorKey(npc)
end

clearSleepHomeOrigin = function(npc, reason)
    local cleared, key = sdpOriginTracker.clearHome(npc, { actorKey = actorKey })
    if cleared then
        debugLog("sleep home origin cleared", npc and (npc.recordId or npc.id) or tostring(key), tostring(reason or "unknown"))
    end
end

local function safeYaw(obj)
    if not obj or not obj.rotation then return 0 end
    local ok, yaw = pcall(function() return obj.rotation:getYaw() end)
    if ok and yaw then return yaw end
    return 0
end

targetYawForData = function(npc, data)
    local targetAngle = data and data.finalRotation or nil
    if not targetAngle and data and data.facingDirection then
        targetAngle = math.atan2(data.facingDirection.x, data.facingDirection.y)
    end
    if targetAngle then return targetAngle end
    return safeYaw(npc)
end

local function actorForward(obj)
    local yaw = safeYaw(obj)
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

local function getDispositionToPlayer(npc, player)
    if not (npc and player and types.NPC and types.NPC.getDisposition) then return 50 end
    local ok, disposition = pcall(types.NPC.getDisposition, npc, player)
    if ok and type(disposition) == "number" then return disposition end
    return 50
end

local function realTimeNow()
    if core and core.getRealTime then
        local ok, now = pcall(core.getRealTime)
        if ok and now then return now end
    end
    return 0
end

local function sleepCooldownKey(npc)
    return tostring(npc and (npc.id or npc.recordId) or "<npc>")
end

local function sleepReservationNow()
    return core.getSimulationTime() or realTimeNow() or 0
end

sdpSleepReservations = sleepReservationsModule.create({
    settings = settings,
    ttl = SLEEP_RESERVATION_SECONDS,
    failedTtl = SLEEP_FAILED_RESERVATION_SECONDS,
    now = sleepReservationNow,
    cellName = cellName,
    sleepLightControl = sleepLightControl,
    isObjValid = function(obj) return isObjValid and isObjValid(obj) or false end,
    debugLog = debugLog,
})

sleepReservationNpcId = function(npc)
    return sdpSleepReservations.npcId(npc)
end

local function sleepReservationOwnerLabel(reservation)
    return sdpSleepReservations.ownerLabel(reservation)
end

local function releaseSleepReservationBySlot(slotKey, reason, expectedNpcId)
    return sdpSleepReservations.releaseBySlot(slotKey, reason, expectedNpcId)
end

handoffTracker.configure({
    infoLog = infoLog,
    debugLog = debugLog,
    isObjValid = function(obj) return isObjValid and isObjValid(obj) or false end,
    assignedActorFor = function(npcId) return npcId and assignedActors[npcId] or nil end,
    releaseOccupiedSlot = function(slotKey, npcId)
        if slotKey and occupiedSlots[slotKey] == npcId then occupiedSlots[slotKey] = nil end
    end,
    releaseSleepReservationBySlot = releaseSleepReservationBySlot,
    sleepReservationNpcId = sleepReservationNpcId,
    sleepLightControl = sleepLightControl,
    clearRelevantObjectCache = clearRelevantObjectCache,
    clearInitialHandoff = function(npcId)
        if npcId then pendingInitialHandoffs[npcId] = nil end
    end,
    settleInitialPlacementOverlay = function(reason, npcOrId)
        if settleInitialPlacementOverlay then settleInitialPlacementOverlay(reason, npcOrId) end
    end,
    onManualAssignTimeout = function(npc, candidate, reason)
        if calibrationMenu and calibrationMenu.onManualAssignTimeout then
            calibrationMenu.onManualAssignTimeout(npc, candidate, reason)
        end
    end,
})

local function releaseSleepReservationForNpc(npcOrId, reason)
    return sdpSleepReservations.releaseForNpc(npcOrId, reason)
end

local function reserveSleepBed(npc, candidate, reason, state, ttl)
    return sdpSleepReservations.reserve(npc, candidate, reason, state, ttl)
end

updateSleepReservationState = function(npcOrId, state, reason, ttl)
    return sdpSleepReservations.updateState(npcOrId, state, reason, ttl)
end

local function markSleepReservationFailed(npc, slotKey, reason)
    return sdpSleepReservations.markFailed(npc, slotKey, reason)
end

sleepReservationForCandidate = function(candidate)
    return sdpSleepReservations.forCandidate(candidate)
end

local function sleepCandidateReservedByOther(npc, candidate)
    return sdpSleepReservations.reservedByOther(npc, candidate)
end

local function pruneSleepReservations(reason)
    return sdpSleepReservations.prune(reason)
end

local function originReferenceForSleep(npc)
    local home = sdpOriginTracker.homeFor(npc, { actorKey = actorKey })
    if home and home.position then return home.position end
    return npc and npc.position or nil
end

local function sleepOriginPreferredDistance(npc, candidate)
    if not (npc and candidate and candidate.object and candidate.object.position) then return nil end
    if candidate.fallbackUsed == true and profiles.sleepFallbackCandidateStatus then
        local ok, reason = profiles.sleepFallbackCandidateStatus(candidate.object)
        if ok ~= true then
            debugLog("sleep origin preferred rejected non_bed", npc.recordId or npc.id, "object", tostring(candidate.objectId), "reason", tostring(reason))
            debugLog("sleep origin preferred fallback skipped", npc.recordId or npc.id, "object", tostring(candidate.objectId))
            return nil
        end
    end
    local origin = originReferenceForSleep(npc)
    if not origin then return nil end
    local dist = (origin - candidate.object.position):length()
    if dist <= SLEEP_ORIGIN_PREFERRED_BED_DISTANCE then return dist end
    return nil
end

sleepFinalPlacementSane = function(npc, data, finalPos, trigger)
    return sdpSleepFinalSafety.validateAssignment({
        npc = npc,
        data = data,
        finalPosition = finalPos,
        trigger = trigger,
        debugLog = debugLog,
    })
end

directlyBesideReservedBed = function(npc, data)
    return sdpSleepEntryGate.directlyBesideReservedBed(sdpSleepEntryGateEnv(), npc, data)
end

local function sleepRouteRejectCooldownActive(npc, slotKey)
    return sleepRouteRejection.cooldownActive(sleepRouteRejectCooldowns, realTimeNow(), npc, slotKey)
end

markSleepRouteRejected = function(npc, slotKey, reason)
    return sleepRouteRejection.markCooldown(sleepRouteRejectCooldowns, realTimeNow(), npc, slotKey, reason, debugLog)
end

local function sleepWakeBiasForNpc(npc)
    return sdpSleepCore.wakeBiasForNpc(npc, settings, profiles, types)
end

local function playerObject()
    return world.players and world.players[1] or nil
end

local function forwardHourDelta(previousHour, currentHour)
    previousHour = tonumber(previousHour)
    currentHour = tonumber(currentHour)
    if previousHour == nil or currentHour == nil then return 0 end
    local delta = currentHour - previousHour
    if delta < 0 then delta = delta + 24 end
    return delta
end

local function isCurrentTimeInSleepWindow()
    local hour = profiles.getGameHour()
    local phase = profiles.hourInSleepWindowPhase(settings, hour)
    return phase and phase.allowed == true, phase and phase.reason or nil, hour
end

local function isSleepObservedCooldownActive(npc)
    local untilTime = sleepObservedCooldowns[sleepCooldownKey(npc)]
    if not untilTime then return false end
    if realTimeNow() < untilTime then return true end
    sleepObservedCooldowns[sleepCooldownKey(npc)] = nil
    return false
end

local function isSleepWakeRetryCooldownActive(npc)
    local key = sleepCooldownKey(npc)
    local untilTime = sleepWakeRetryCooldowns[key]
    if not untilTime then return false end
    if realTimeNow() < untilTime then return true, untilTime - realTimeNow() end
    sleepWakeRetryCooldowns[key] = nil
    return false
end

local function setSleepWakeRetryCooldown(npc, reason)
    local cooldown = tonumber(settings.sleepWakeRetryCooldown or 20) or 20
    if not npc or cooldown <= 0 then return end

    if reason == "activated_by_player_dialogue" then
        local player = playerObject()
        local disposition = getDispositionToPlayer(npc, player)
        if disposition >= 70 then
            -- Trusted NPCs can return sooner than suspicious NPCs, but 8 seconds
            -- was short enough that they could head back to bed immediately after
            -- the dialogue closed. Keep it short, not instant.
            cooldown = math.max(cooldown, 30)
        elseif disposition < 40 then
            -- Low-trust NPCs stay unsettled longer. The existing observed-player
            -- check still prevents them from returning to bed while the player is
            -- nearby/visible.
            cooldown = math.max(cooldown, 120)
        else
            cooldown = math.max(cooldown, 60)
        end
        debugLog("sleep wake retry disposition", npc.recordId or npc.id, "disposition", tostring(disposition), "cooldown", tostring(cooldown))
    end

    sleepWakeRetryCooldowns[sleepCooldownKey(npc)] = realTimeNow() + cooldown
    debugLog("sleep wake retry cooldown", npc.recordId or npc.id, tostring(reason), "seconds", tostring(cooldown))
end

local function shouldDelaySleepAfterWake(reason)
    if not reason then return false end
    local text = tostring(reason)
    return text:find("activated_by_player", 1, true) ~= nil
        or text:find("disturbed", 1, true) ~= nil
        or text:find("wake", 1, true) ~= nil
        or text:find("^external_", 1) ~= nil
        or text == "external_travel_takeover"
        or text == "external_incapacitation_spell"
        or text == "active_non_idle_stance"
        or text == "other_travel"
        or text == "other_ai_package"
        or text == "follow_or_escort"
        or text == "combat"
end

local function isExternalSleepReleaseReason(reason)
    local text = tostring(reason or "")
    return text == "external_travel_takeover"
        or text == "external_actor_invalid"
        or text == "external_sleep_cell_change"
        or text == "external_sleep_displaced"
        or text == "other_travel"
        or text == "other_ai_package"
        or text == "follow_or_escort"
        or text == "combat"
        or text == "active_non_idle_stance"
        or text:find("^external_", 1) ~= nil
end

function sdpWithSleepWakeExitOptions(item, data)
    item = item or {}
    local profile = data and data.profile or nil
    if profile then
        item.floorDrop = profile.sleepExitFloorDrop
        item.maxSleepExitHorizontal = profile.sleepMaxExitHorizontal
        item.maxFloorExitHorizontal = profile.sleepMaxFloorExitHorizontal
        item.maxSleepExitDrop = profile.sleepMaxExitDrop
        item.maxFloorExitDrop = profile.sleepMaxFloorExitDrop
        item.maxWakeExitWalkDrop = profile.sleepMaxWakeExitWalkDrop
    end
    return item
end

local MORNING_WAKE_REASONS = {
    scheduled_wake_time = true,
    sleep_window_ended = true,
    time_advance_sleep_window_ended = true,
    daytime_failsafe = true,
    off_hours_service_window_ended = true,
}

local function shouldWalkToOriginAfterWake(reason)
    if not reason then return false end
    local text = tostring(reason)
    if MORNING_WAKE_REASONS[text] == true then return true end
    return text:find("scheduled_wake", 1, true) ~= nil
        or text:find("sleep_window_ended", 1, true) ~= nil
end

postWakeReturnOrigins = sdpOriginTracker.createReturnQueue({
    now = function() return core.getSimulationTime() end,
    inSleepWindow = function() return isCurrentTimeInSleepWindow() end,
    isObjValid = function(obj) return isObjValid(obj) end,
    actorDeadReason = actorDeadReason,
    assignedActors = function() return assignedActors end,
    hasPendingStandTeleport = function(npcId) return wakeExit and wakeExit.hasPendingStandTeleport(npcId) end,
    tryTeleport = function(...) return tryTeleport(...) end,
    clearHome = function(npc, reason) return clearSleepHomeOrigin(npc, reason) end,
    shouldClearHome = shouldWalkToOriginAfterWake,
    assistReturnRouteDoor = function(npc, origin, reason)
        if sleepRouteDoors and sleepRouteDoors.assistWakeReturn then
            return sleepRouteDoors.assistWakeReturn(npc, origin, reason or "post_wake_return_origin")
        end
        return false
    end,
    progressThreshold = 24,
    debugLog = debugLog,
})

sittingOriginReturns = sdpOriginTracker.createSittingOriginQueue({
    now = function() return core.getSimulationTime() end,
    isObjValid = function(obj) return isObjValid(obj) end,
    assignedActors = function() return assignedActors end,
    debugLog = debugLog,
})

stationReturnOrigins = sdpOriginTracker.createReturnQueue({
    now = function() return core.getSimulationTime() end,
    isObjValid = function(obj) return isObjValid(obj) end,
    assignedActors = function() return assignedActors end,
    hasPendingStandTeleport = function() return false end,
    tryTeleport = function(...) return tryTeleport(...) end,
    shouldClearHome = function() return false end,
    debugLog = debugLog,
})

local function playerLikelyObservedByNpc(npc, player)
    if not (npc and player and npc.position and player.position) then return false, "no_player" end

    local distance = (player.position - npc.position):length()
    local observedDistance = settings.sleepObservedPlayerDistance or 500
    local closeDistance = settings.sleepObservedPlayerCloseDistance or 150

    if distance > observedDistance then
        return false, "player_too_far", distance
    end

    if distance <= closeDistance then
        return true, "player_close", distance
    end

    local delta = player.position - npc.position
    local flat = util.vector2(delta.x, delta.y)
    if flat:length() <= 1 then return false, "no_direction", distance end
    local norm = flat:normalize()
    local dir = util.vector3(norm.x, norm.y, 0)

    local facing = actorForward(npc)
    local dot = facing.x * dir.x + facing.y * dir.y

    if playerStealthState.known and playerStealthState.isInvisible then
        return false, "player_invisible", distance
    end

    local chameleon = tonumber(playerStealthState.chameleon or 0) or 0
    if chameleon >= 100 then
        return false, "player_full_chameleon", distance
    end

    if playerStealthState.known and playerStealthState.isSneaking then
        -- Borrowing the shape of Sneak Is Good Now's logic: sneaking/chameleon
        -- narrows the effective attention cone instead of blocking sleep merely
        -- because the player is somewhere in the cell.
        local threshold = 0.75 + (0.2 * math.min(100, math.max(0, chameleon)) / 100)
        return dot > threshold, "player_in_sneak_narrow_view", distance
    end

    return dot > 0.35, "player_in_view", distance
end

local function observedPlayerMayStillSleep(npc, player, cell)
    local disposition = getDispositionToPlayer(npc, player)
    local threshold = settings.sleepObservedPlayerDispositionThreshold or 70
    if disposition >= threshold then
        return true, "trusted_disposition", disposition
    end

    local chance = settings.sleepObservedPlayerAllowanceChance or 0
    if chance <= 0 then return false, "no_allowance", disposition end
    if chance >= 1 then return true, "allowance_always", disposition end

    local key = actorKey(npc) .. "::" .. cellName(cell) .. "::observed_sleep"
    local unit = profiles.stableUnitInterval(key)
    if unit <= chance then
        return true, "deterministic_allowance", disposition
    end

    return false, "player_observed", disposition
end

sleepEligibilityForNpc = function(npc, cell, assignmentContext)
    local currentHour = profiles.getGameHour()
    local timing = profiles.actorSleepTiming(actorKey(npc), cellName(cell), settings, currentHour, { wakeBias = sleepWakeBiasForNpc(npc) })
    if not timing.allowed then
        return false, timing.reason or "sleep_not_allowed_by_time", timing
    end

    local wakeCooldownActive, wakeCooldownRemaining = isSleepWakeRetryCooldownActive(npc)
    if wakeCooldownActive then
        timing.wakeCooldownRemaining = wakeCooldownRemaining
        return false, "sleep_wake_retry_cooldown", timing
    end

    local forceInBedPhase = timing.phase == "force_in_bed"
        or (timing.forceDelta ~= nil and timing.nowDelta ~= nil and timing.nowDelta >= timing.forceDelta)

    local allowDueBedtimeInitialPlacement = assignmentContext and assignmentContext.allowDueBedtimeInitialPlacement == true
    local initialPlacement = settings.sleepInitialPlacementEnabled == true
        and (forceInBedPhase == true or allowDueBedtimeInitialPlacement == true)
        and assignmentContext
        and (assignmentContext.sleepInitialPlacementAllowed == true or assignmentContext.initialPlacementAllowed == true)

    local assignmentSource = tostring(assignmentContext and assignmentContext.source or "")
    local skipObservedPlayer = initialPlacement == true
        and (
            assignmentSource:find("^initial_load") ~= nil
            or assignmentSource:find("^cell_change") ~= nil
            or (assignmentContext and assignmentContext.schedulerArrivalPlacement == true)
        )
    if not skipObservedPlayer and settings.sleepAvoidObservedPlayer == true then
        if isSleepObservedCooldownActive(npc) then
            timing.observedReason = "player_observed_cooldown"
            return false, "player_observed_cooldown", timing
        end

        local player = world.players[1]
        local observed, observedReason, observedDistance = playerLikelyObservedByNpc(npc, player)
        if observed then
            local allowed, allowanceReason, disposition = observedPlayerMayStillSleep(npc, player, cell)
            timing.observedReason = observedReason
            timing.observedDistance = observedDistance
            timing.observedDisposition = disposition
            timing.observedAllowanceReason = allowanceReason

            if not allowed then
                local cooldown = settings.sleepObservedPlayerCooldown or 120
                if cooldown > 0 then
                    sleepObservedCooldowns[sleepCooldownKey(npc)] = realTimeNow() + cooldown
                end
                return false, "player_observed", timing
            end

            timing.observedPlayerOverride = allowanceReason
        end
    elseif settings.sleepAvoidObservedPlayer ~= true then
        -- This is diagnostic only; it confirms that the setting is actually being
        -- honored. Other sleep gates, such as actor bedtime, missing animation,
        -- distance, service-NPC filters, or bed pathing, may still reject sleep.
        timing.observedReason = "observed_player_check_disabled"
    end

    timing.initialPlacement = initialPlacement
    timing.observedPlayerBypass = skipObservedPlayer
        and assignmentContext
        and assignmentContext.schedulerArrivalPlacement == true
        and "scheduler_arrival_initial_placement"
        or (skipObservedPlayer and "cell_entry_initial_placement" or nil)
    timing.currentHour = currentHour
    return true, nil, timing
end

local function sleepingWakeReason(npc, data)
    if not npc or not npc.position then return nil end
    if data and data.calibrationAction == true then return nil end

    local currentHour = profiles.getGameHour()
    local timing = profiles.actorSleepTiming(actorKey(npc), cellName(npc.cell), settings, currentHour, {
        wakeBias = data and data.sleepWakeBias or sleepWakeBiasForNpc(npc)
    })
    if not timing.allowed then
        if timing.reason == "sleep_after_actor_wake_time" then
            return "scheduled_wake_time"
        elseif timing.reason == "outside_allowed_time_window" or timing.reason == "sleep_before_start_hour" then
            return "sleep_window_ended"
        end
    end

    local grace = settings.sleepWakeGraceSeconds or 6
    if data and data.interactionStartedAt and grace > 0 then
        local elapsed = core.getSimulationTime() - data.interactionStartedAt
        if elapsed < grace then return nil end
    end

    if calibrationHoldActive(data) then
        return nil
    end

    local player = world.players[1]
    if not (player and player.position) then return nil end

    local wakeDistance = settings.sleepingWakeDistance or 0
    local reason = "sleeping_disturbed_by_close_player"

    if playerStealthState.known then
        if playerStealthState.isInvisible then
            wakeDistance = wakeDistance * 0.2
            reason = "sleeping_disturbed_by_invisible_close_player"
        elseif playerStealthState.isSneaking then
            wakeDistance = settings.sleepingSneakWakeDistance or wakeDistance
            reason = "sleeping_disturbed_by_close_sneaking_player"
        end

        local chameleon = tonumber(playerStealthState.chameleon or 0) or 0
        if chameleon > 0 then
            wakeDistance = wakeDistance * math.max(0.15, 1 - math.min(100, chameleon) / 100)
        end

        if playerStealthState.isMoving == false then
            wakeDistance = wakeDistance * 0.75
        end
    end

    if wakeDistance <= 0 then return nil end
    if (player.position - npc.position):length() <= wakeDistance then
        return reason
    end

    return nil
end

local function npcIsFollowerByUtil(npc)
    local followerUtil = I and I["FollowerDetectionUtil"] or nil
    if not (npc and npc.id and followerUtil and followerUtil.getFollowerList) then return false end
    local ok, followers = pcall(followerUtil.getFollowerList)
    if not ok or type(followers) ~= "table" then return false end
    local state = followers[npc.id]
    if not state then return false end
    if state.followsPlayer == true then return true end
    local leader = state.leader or state.superLeader
    return leader and leader.type and types.Player and leader.type == types.Player or false
end

sdpStationFollowerBlockReason = function(npc)
    if npcIsFollowerByUtil(npc) then return "follower" end
    if npc and npc.id and followerPackageActors[npc.id] == true then return "active_follow_or_escort_package" end
    return nil
end

sdpStationCellIsInterior = function(cell)
    if not cell then return false end
    local ok, value = pcall(function() return cell.isExterior end)
    if ok and type(value) == "boolean" then return value ~= true end
    if type(cell.isExterior) == "function" then
        local okMethod, methodValue = pcall(function() return cell:isExterior() end)
        if okMethod and type(methodValue) == "boolean" then return methodValue ~= true end
    end
    return true
end


local function externalAnimationNpcReason(npc)
    if profiles.externalAnimationNpcReason then return profiles.externalAnimationNpcReason(npc) end
    return sdpExternalAnimationCompat.externalAnimationNpcReason(npc)
end

local function externalClaimForCandidate(cell, candidate, excludeNpc)
    if not (cell and cell.getAll and candidate and candidate.object and candidate.object.position) then return false, nil, nil end
    -- This is not a default-space assignment. It only treats furniture as claimed
    -- when an external actor's known pose matches the candidate type and the
    -- actor is physically close to that furniture in the current cell. Keep the
    -- sitting radius tight so nearby animated actors do not claim unrelated chairs.
    local claimRadius = candidate.interactionType == "sleeping" and 150 or 96
    local claimVertical = candidate.interactionType == "sleeping" and 95 or 130
    for _, other in ipairs(cell:getAll(types.NPC)) do
        if other and other.id and (not excludeNpc or other.id ~= excludeNpc.id) then
            local reason, source, dist, vertical = nil, nil, nil, nil
            if profiles.externalAnimationClaimMatch then
                reason, source, dist, vertical = profiles.externalAnimationClaimMatch(other, candidate)
            else
                reason = profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(other, candidate) or nil
            end
            if reason and source then
                return true, tostring(reason) .. ":" .. tostring(source), other
            elseif reason and other.position then
                local delta = other.position - candidate.object.position
                local flat = math.sqrt(((delta.x or 0) * (delta.x or 0)) + ((delta.y or 0) * (delta.y or 0)))
                if math.abs(delta.z or 0) <= claimVertical and flat <= claimRadius then
                    return true, reason, other
                end
            end
        end
    end
    return false, nil, nil
end

local function candidatePhysicallyClaimedByExternalNpc(npc, candidate)
    if not (npc and npc.cell) then return false, nil, nil end
    return externalClaimForCandidate(npc.cell, candidate, npc)
end

local function isBarOrCounterRecord(recordId)
    local id = tostring(recordId or ""):lower()
    if id == "" then return false end

    -- Station protection must only treat actual bar/counter/lectern statics as station
    -- dividers. The earlier substring test matched records like barrels because
    -- they contain "bar", which could falsely mark an NPC as behind a counter.
    if id:find("barrel", 1, true) or id:find("barrow", 1, true) or id:find("barstool", 1, true) then return false end
    if id:find("stool", 1, true) or id:find("chair", 1, true) or id:find("bench", 1, true) then return false end

    if id:find("counter", 1, true) then return true end
    if id:find("lecturn", 1, true) or id:find("lectern", 1, true) then return true end
    if id:find("_bar_", 1, true) then return true end
    if id:find("/bar_", 1, true) then return true end
    if id:match("^bar[_%-%s]") then return true end
    if id:match("[_%-%s]bar[_%-%s]") then return true end

    return false
end

local function flatVectorFromTo(a, b)
    if not (a and b) then return nil end
    local dx, dy = (b.x or 0) - (a.x or 0), (b.y or 0) - (a.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return nil end
    return util.vector3(dx / len, dy / len, 0), len
end

local function candidatePullsStationedNpcFromCounter(npc, candidate)
    if not (npc and npc.cell and npc.position and candidate and candidate.interactionType == "sitting" and candidate.object and candidate.object.position) then return false end
    local seatId = tostring(candidate.objectId or ""):lower()
    local profileType = candidate.profile and profiles.sittingSeatCategory and profiles.sittingSeatCategory(candidate.profile, candidate.object) or tostring(candidate.profile and candidate.profile.type or "")
    local isExplicitBarstool = seatId:find("barstool", 1, true) ~= nil or profileType == "barstool"
    local isPlainStool = (profileType == "stool" or seatId:find("stool", 1, true) ~= nil) and not isExplicitBarstool

    local nearestCounter, nearestCounterDist = nil, nil
    for _, obj in ipairs(npc.cell:getAll()) do
        if obj and obj.position and obj ~= candidate.object and isBarOrCounterRecord(obj.recordId) then
            local d = (npc.position - obj.position):length()
            if d <= 170 and (not nearestCounterDist or d < nearestCounterDist) then
                nearestCounter, nearestCounterDist = obj, d
            end
        end
    end

    if not nearestCounter then return false end
    local seatDist = (npc.position - candidate.object.position):length()
    local stationId = nearestCounter.recordId and string.lower(tostring(nearestCounter.recordId)) or ""
    local stationIsLectern = stationId:find("lecturn", 1, true) ~= nil or stationId:find("lectern", 1, true) ~= nil

    -- Lecterns represent a work post more than a bar rail. A speaker standing
    -- behind one should not be pulled into audience seating while on duty; bench
    -- facing can still use lecterns for NPCs that are already eligible to sit.
    if stationIsLectern and seatDist > 115 then
        return true
    end

    -- Station protection is meant to stop a placed NPC from being pulled out of
    -- a behind-counter post into public/customer space. It must not block the
    -- NPC's own local stool behind that same counter. Fine-Mouth's Shack showed
    -- the old threshold was too aggressive: a nearby profiled stool was rejected
    -- before the local script could even test sitting.
    if isPlainStool and seatDist <= 165 then
        return false
    end

    local counterToNpc = flatVectorFromTo(nearestCounter.position, npc.position)
    local counterToSeat = flatVectorFromTo(nearestCounter.position, candidate.object.position)
    if counterToNpc and counterToSeat then
        local dot = (counterToNpc.x or 0) * (counterToSeat.x or 0) + (counterToNpc.y or 0) * (counterToSeat.y or 0)
        -- Only reject a side-crossing move when it actually pulls the NPC a real
        -- distance away from their station. Barstools remain stricter because they
        -- are more likely to be public/customer-side seats; plain local stools get
        -- a larger allowance for calibration and station seating.
        local sideCrossDistance = isExplicitBarstool and 95 or 165
        if dot < -0.15 and seatDist > sideCrossDistance then return true end
    end

    -- Fallback if side cannot be established: a stationed NPC right behind a bar
    -- may use only local seats. Do not classify every stool as a public barstool;
    -- ordinary stools near counters are still valid local station seats.
    if isExplicitBarstool and seatDist > math.max(125, nearestCounterDist + 38) then
        return true
    end
    return false
end

isNpcRecordEligibleForInteraction = function(npc, interactionType)
    if not npc or not npc.id or not types.NPC.objectIsInstance(npc) then
        return false, "not_npc"
    end

    local dead, deadReason = actorDeadReason(npc)
    if dead then return false, deadReason end

    local blacklistedReason = profiles.npcBlacklistedReason and profiles.npcBlacklistedReason(npc, settings) or nil
    if blacklistedReason then return false, blacklistedReason end

    if calibrationMenu and calibrationMenu.isCalibrationFillActor and calibrationMenu.isCalibrationFillActor(npc) == true then
        return false, "calibration_fill_owned"
    end

    local hiddenReason = assignmentEligibility.hiddenOrStagedNpcReason(npc, { types = types, player = primaryPlayer(), cellName = cellName })
    if hiddenReason then
        return false, hiddenReason
    end

    local proceduralChatterReason = sdpProceduralChatterCompat.assignmentBlockReason(npc, core)
    if proceduralChatterReason then
        return false, proceduralChatterReason
    end

    local incapacitationReason = sdpExternalAiTakeover.externalIncapacitationReason(npc, types)
    if incapacitationReason then
        return false, incapacitationReason
    end

    local controlScriptReason = sdpExternalAiTakeover.externalControlScriptReason(npc)
    if controlScriptReason then
        return false, controlScriptReason
    end

    local stanceReason = sdpExternalAiTakeover.activeNonIdleStanceReason(npc, types)
    if stanceReason then
        return false, stanceReason
    end

    local externalAnimationReason = externalAnimationNpcReason(npc)
    if externalAnimationReason then
        return false, externalAnimationReason
    end

    local followerReason = sdpStationFollowerBlockReason(npc)
    if followerReason then return false, followerReason end

    local okRecord, rec = pcall(types.NPC.record, npc.recordId)
    if not okRecord or not rec then
        -- Keep legacy behavior if the record cannot be inspected. The local script
        -- still performs final validation before accepting any interaction.
        return true, nil
    end

    if sdpActorRoles.looksLikeVampire(npc, rec, types) then
        return false, "vampire"
    end

    local isFactionLeader = sdpActorRoles.isFactionLeader(npc, types, core)
    local offHoursReason = sdpServicePolicy.offHoursServiceRecordReason(rec, settings, profiles, profiles.getGameHour(), isFactionLeader)
    if interactionType == "sitting" and offHoursReason then
        local allowed, sittingReason = sdpServicePolicy.offHoursSittingAllowed(npc, rec, settings, profiles, profiles.getGameHour(), isFactionLeader)
        if allowed then
            offHoursReason = sittingReason or offHoursReason
        else
            offHoursReason = nil
        end
    end
    local classBlockReason = sdpServicePolicy.classBlockReason(rec, offHoursReason)
    if classBlockReason then return false, classBlockReason end

    if interactionType == "sitting" then
        -- Traders/publicans/trainers can use configurable off-hours behavior, but
        -- this stays opportunistic and yields to actual AI/schedule packages.
        local serviceBlockReason = sdpServicePolicy.sittingBlockReason(rec, settings, offHoursReason, isFactionLeader)
        if serviceBlockReason then return false, serviceBlockReason end
    elseif interactionType == "sleeping" then
        -- Sleep is time-gated and bed-gated. Merchants, trainers, quest givers,
        -- faction leaders, and off-hours publicans may sleep if a qualifying bed
        -- is genuinely local. Travel NPCs keep the smaller radius below.
    else
        local serviceBlockReason = sdpServicePolicy.nonSittingServiceBlockReason(rec)
        if serviceBlockReason then return false, serviceBlockReason end
    end

    return true, nil
end

objectNameForFocus = function(obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then return obj.type.record(obj) end
        return nil
    end)
    if ok and rec and rec.name then return rec.name end
    return nil
end

local function sittingFocusEnv()
    return {
        util = util,
        profiles = profiles,
        settings = settings,
        stationAssignments = sdpStationAssignments,
        stationSlotKey = sdpStationSlotKey,
        objectLocalOffset = objectLocalOffset,
        debugLog = debugLog,
        verboseLog = verboseInfoLog,
    }
end

local function seatObjectLooksOverturned(obj)
    return sittingFocusSelector.seatObjectLooksOverturned(sittingFocusEnv(), obj)
end

sdpSittingAssignmentObjectForwardDirection = function(obj)
    return sittingFocusSelector.objectForwardDirection(util, obj)
end

sdpSittingAssignmentForwardDotToFocus = function(seatObj, fromPos, focusPos)
    return sittingFocusSelector.forwardDotToFocus(util, seatObj, fromPos, focusPos)
end

sdpSittingAssignmentFocusCompatible = function(kind, seatObj, profile, fromPos, focusPos)
    return sittingFocusSelector.focusCompatible(util, kind, seatObj, profile, fromPos, focusPos)
end

local function findNearestSittingFocusDirection(cell, fromPos, seatObj, profile, options)
    return sittingFocusSelector.nearestDirection(sittingFocusEnv(), cell, fromPos, seatObj, profile, options)
end

local function sittingCandidateSeatPosition(obj, profile, slot, slotIndex)
    return sittingFocusSelector.candidateSeatPosition(sittingFocusEnv(), obj, profile, slot, slotIndex)
end

local function sittingSeatSurfaceBlocker(cell, seatPos, profile, obj, objects)
    return seatingClutterBlockers.surfaceBlocker({
        objects = objects,
        profiles = profiles,
        sittingSeatCategory = profiles.sittingSeatCategory,
    }, seatPos, profile, obj)
end

local function candidateBuilderEnv()
    return {
        cellContext = cellContext,
        profiles = profiles,
        settings = settings,
        assignmentEligibility = assignmentEligibility,
        slotOwnership = sdpSlotOwnership,
        releaseSafetyGate = sdpReleaseSafetyGate,
        util = util,
        occupiedSlots = function() return occupiedSlots end,
        assignedActors = function() return assignedActors end,
        relevantObjectCache = function() return relevantObjectCache end,
        claimRejectLogCache = function() return claimRejectLogCache end,
        isObjValid = isObjValid,
        seatObjectLooksOverturned = seatObjectLooksOverturned,
        objectLocalOffset = objectLocalOffset,
        objectSlotKey = objectSlotKey,
        objectNameForFocus = objectNameForFocus,
        sittingCandidateSeatPosition = sittingCandidateSeatPosition,
        sittingSeatSurfaceBlocker = sittingSeatSurfaceBlocker,
        findNearestSittingFocusDirection = findNearestSittingFocusDirection,
        externalClaimForCandidate = externalClaimForCandidate,
        cellName = cellName,
        debugLog = debugLog,
        debugLogOnce = debugLogOnce,
        verboseInfoLog = verboseInfoLog,
    }
end

buildCandidateSlots = function(cell, interactionType, options)
    return candidateBuilder.build(candidateBuilderEnv(), cell, interactionType, options)
end

local function interactionOrderForCurrentTime()
    local currentHour = profiles.getGameHour()
    if settings.enableSleeping == true
        and profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        return { "sleeping", "sitting" }
    end
    return { "sitting", "sleeping" }
end

sdpCandidateSelectorEnv = function()
    return {
        profiles = profiles,
        settings = settings,
        types = types,
        core = core,
        actorRoles = sdpActorRoles,
        servicePolicy = sdpServicePolicy,
        routeAssist = routeAssist,
        sleepBedAccess = sleepBedAccess,
        slotOwnership = sdpSlotOwnership,
        occupiedSlots = function() return occupiedSlots end,
        assignedActors = function() return assignedActors end,
        claimRejectLogCache = function() return claimRejectLogCache end,
        isNpcObjectValidForAssignment = isNpcObjectValidForAssignment,
        pruneSleepReservations = pruneSleepReservations,
        sleepOriginPreferredDistance = sleepOriginPreferredDistance,
        sleepCandidateReservedByOther = sleepCandidateReservedByOther,
        sleepReservationOwnerLabel = sleepReservationOwnerLabel,
        sleepRouteRejectCooldownActive = sleepRouteRejectCooldownActive,
        sittingLocalRejectCooldownActive = sdpSittingLocalRejectCooldownActive,
        candidatePhysicallyClaimedByExternalNpc = candidatePhysicallyClaimedByExternalNpc,
        candidatePullsStationedNpcFromCounter = candidatePullsStationedNpcFromCounter,
        objectNameForFocus = objectNameForFocus,
        cellName = cellName,
        debugLog = debugLog,
        debugLogOnce = debugLogOnce,
    }
end

function sdpFlatForwardDot(fromPos, toPos, facing)
    return sdpCandidateSelector.flatForwardDot(fromPos, toPos, facing)
end

function sdpLecternAudienceBehindPresenter(candidate, context)
    return sdpCandidateSelector.lecternAudienceBehindPresenter(candidate, context)
end

chooseCandidateForNpc = function(npc, candidates, interactionType, context)
    return sdpCandidateSelector.choose(sdpCandidateSelectorEnv(), npc, candidates, interactionType, context)
end

sendConsiderInteraction = function(npc, candidate)
    if initialPlacementGuards.hasPendingSleepHandoff(pendingInitialHandoffs, npc, candidate) then
        debugLog(
            "consider skipped pending initial sleep handoff",
            npc and (npc.recordId or npc.id) or "<npc>",
            "object", tostring(candidate and candidate.objectId),
            "slot", tostring(candidate and candidate.slotName)
        )
        return false, "initial_sleep_handoff_pending"
    end
    local claimed, ownerId, ownerData, ownerSource = sdpSlotOwnership.claimedByOther(candidate and candidate.slotKey, npc, occupiedSlots, assignedActors)
    if claimed then
        debugLog(
            "consider skipped slot claimed",
            npc and (npc.recordId or npc.id) or "<npc>",
            "object", tostring(candidate and candidate.objectId),
            "slot", tostring(candidate and candidate.slotName),
            "owner", tostring(ownerData and ownerData.npc and (ownerData.npc.recordId or ownerData.npc.id) or ownerId),
            "source", tostring(ownerSource)
        )
        return false, "slot_claimed_by_other"
    end
    local claimOk, claimReason = sdpSlotOwnership.claim(candidate.slotKey, npc, occupiedSlots, assignedActors)
    if not claimOk then
        debugLog(
            "consider skipped slot claim failed",
            npc and (npc.recordId or npc.id) or "<npc>",
            "object", tostring(candidate and candidate.objectId),
            "slot", tostring(candidate and candidate.slotName),
            "reason", tostring(claimReason)
        )
        return false, claimReason or "slot_claim_failed"
    end
    if candidate.interactionType == "sleeping" then
        local reservationReason = sleepOriginPreferredDistance(npc, candidate) and "origin_preferred" or (candidate.initialPlacement == true and "initial_load" or "normal_assignment")
        reserveSleepBed(npc, candidate, reservationReason, "assigned")
    end
    local session = calibrationLock.session
    if session and session.calibration and candidate.calibration == nil
        and session.interactionType == candidate.interactionType
        and session.slotKey == candidate.slotKey
        and (session.actor == nil or session.actor == npc or tostring(session.actorId or "") == tostring(npc and npc.id or ""))
        and (session.object == nil or session.object == candidate.object)
    then
        candidate.calibration = session.calibration
        debugLog("calibration carried into assignment", npc.recordId or npc.id, "type", tostring(candidate.interactionType), "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName))
    end
    -- Slot occupancy is checked after relevant-object expansion, so claiming a
    -- slot should not invalidate the expensive cell-level relevance cache.
    debugLog(
        "consider",
        npc.recordId or npc.id,
        "cell", cellName(npc.cell),
        "type", candidate.interactionType,
        "object", tostring(candidate.objectId),
        "model", tostring(candidate.model),
        "profile", tostring(candidate.profileId),
        "slot", tostring(candidate.slotName),
        "fallback", tostring(candidate.fallbackUsed),
        "hour", tostring(candidate.currentHour),
        "bedtime", tostring(candidate.actorBedtime),
        "wake", tostring(candidate.actorWakeTime),
        "initial", tostring(candidate.initialPlacement == true),
        "phase", tostring(candidate.sleepPhase),
        "doorAssistRestricted", tostring(candidate.disallowSleepDoorAssist == true)
    )

    if candidate.initialPlacement == true
        and candidate.suppressInitialPlacementOverlay ~= true
        and not sdpCalibrationFillOwnership.isAcceptedEvent(candidate) then
        if candidate.interactionType == "sleeping" and npc.id then pendingInitialHandoffs[npc.id] = core.getSimulationTime() end
        if candidate.interactionType == "sleeping" then
            calibrationLock.notifyDisguiseInitialPlacement(npc, candidate.interactionType, "initial_placement_pending", {
                settings = settings,
                world = world,
                duration = 0.68,
                holdDuration = 0.22,
                object = candidate.object,
                objectId = candidate.objectId,
                position = candidate.object and candidate.object.position or nil,
            })
        end
    end

    local eventPayload = {
        object = candidate.object,
        interactionType = candidate.interactionType,
        profile = candidate.profile,
        profileId = candidate.profileId,
        slot = candidate.slot,
        slotName = candidate.slotName,
        slotKey = candidate.slotKey,
        approachPos = candidate.approachPos,
        preInteractionPos = candidate.preInteractionPos or npc.position,
        preInteractionRot = candidate.preInteractionRot or npc.rotation,
        preferredFacingDirection = candidate.preferredFacingDirection,
        facingObject = candidate.facingObject,
        facingObjectId = candidate.facingObjectId,
        facingObjectRefId = candidate.facingObjectRefId,
        facingObjectModel = candidate.facingObjectModel,
        facingObjectName = candidate.facingObjectName,
        facingObjectScale = candidate.facingObjectScale,
        facingKind = candidate.facingKind,
        facingReason = candidate.facingReason,
        facingObjectPosition = candidate.facingObjectPosition,
        facingCandidates = candidate.facingCandidates,
        fallbackUsed = candidate.fallbackUsed,
        currentHour = candidate.currentHour,
        initialPlacement = candidate.initialPlacement == true,
        suppressInitialPlacementOverlay = candidate.suppressInitialPlacementOverlay == true,
        schedulerArrivalPlacement = candidate.schedulerArrivalPlacement == true,
        sleepPhase = candidate.sleepPhase,
        actorBedtime = candidate.actorBedtime,
        actorWakeTime = candidate.actorWakeTime,
        sleepWakeBias = candidate.sleepWakeBias,
        observedPlayerOverride = candidate.observedPlayerOverride,
        disallowSleepDoorAssist = candidate.disallowSleepDoorAssist == true,
        lectureAudienceTarget = candidate.lectureAudienceTarget == true,
        lectureAudienceShortcut = candidate.lectureAudienceShortcut == true,
        lectureAudienceTeleport = candidate.lectureAudienceTeleport == true,
        ignoreTimeGate = candidate.ignoreTimeGate == true or candidate.debugForced == true,
        debugForced = candidate.debugForced == true,
        calibrationAction = candidate.calibrationAction == true,
        calibrationReason = candidate.calibrationReason,
        calibrationFill = candidate.calibrationFill == true,
        explicitFillOverride = candidate.explicitFillOverride == true,
        calibrationFillLabel = candidate.calibrationFillLabel,
        calibrationFillRole = candidate.calibrationFillRole,
        calibrationFillSource = candidate.calibrationFillSource,
        calibrationFillIndex = candidate.calibrationFillIndex,
        calibrationFillSessionId = candidate.calibrationFillSessionId,
        calibrationRuntimeObjectId = candidate.calibrationRuntimeObjectId,
        actorDisplayLabel = candidate.actorDisplayLabel,
        calibration = candidate.calibration,
        manualAssign = candidate.manualAssign == true,
        manualAssignRetryCount = candidate.manualAssignRetryCount,
        manualAssignOverrideTesting = candidate.manualAssignOverrideTesting == true,
        manualAssignOverrideReason = candidate.manualAssignOverrideReason,
        sleepAccessOverrideReason = candidate.sleepAccessOverrideReason,
        releaseSafetyGateEnabled = candidate.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = candidate.releaseSafetyGateStatus,
        releaseSafetyGateReason = candidate.releaseSafetyGateReason,
        releaseSafetyGateCell = candidate.releaseSafetyGateCell,
        releaseSafetyGateRegion = candidate.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = candidate.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = candidate.releaseSafetyGateLabel,
        seatCategory = candidate.releaseSafetyGateFurnitureType,
        calibrationTestNpc = candidate.calibrationTestNpc == true,
        lecternPosition = candidate.lecternPosition,
        stationPosition = candidate.stationPosition,
        audienceHeadFocusPosition = candidate.audienceHeadFocusPosition,
        lectureSessionId = candidate.lectureSessionId,
        stationSlotKey = candidate.stationSlotKey,
        audienceSource = candidate.audienceSource,
    }

    local now = core.getSimulationTime()
    if candidate.initialPlacement == true
        and candidate.suppressInitialPlacementOverlay ~= true
        and candidate.interactionType == "sleeping"
        and npc.id
        and not sdpCalibrationFillOwnership.isAcceptedEvent(candidate)
    then
        pendingInitialHandoffs[npc.id] = now
    end
    if candidate.interactionType == "sleeping" and sleepLightControl.registerPendingSleeper then
        sleepLightControl.registerPendingSleeper(npc, {
            object = candidate.object,
            bed = candidate.object,
            bedId = candidate.objectId,
            finalPosition = candidate.finalPosition,
            position = candidate.finalPosition,
            exitPosition = candidate.exitPosition,
            approachPosition = candidate.approachPos,
            originPosition = candidate.preInteractionPos,
            initialPlacement = candidate.initialPlacement == true,
            state = "consider_sent",
        })
    end
    npc:sendEvent("ConsiderInteractionObject", eventPayload)
    handoffTracker.track(npc, candidate, eventPayload, now)
    return true
end

function animatedMorrowindCompatEnabled()
    return sdpAnimatedMorrowindAssignment.enabled()
end

function runAnimatedMorrowindCompatPass(cell, sittingCandidates, source)
    return sdpAnimatedMorrowindAssignment.runPass(cell, sittingCandidates, source)
end

function scheduleAnimatedMorrowindCompatRetry(reason, delaySeconds, durationSeconds)
    return sdpAnimatedMorrowindAssignment.scheduleRetry(reason, delaySeconds, durationSeconds)
end

function processAnimatedMorrowindCompatRetry()
    return sdpAnimatedMorrowindAssignment.processRetry(lastCell)
end

local function assignNpcsToLocalInteractions(cell, assignmentContext)
    if not cell then return end
    assignmentContext = assignmentContext or {}

    local npcScanStats = {
        total = 0,
        candidateTotal = 0,
        sleepCandidateCount = 0,
        sittingCandidateCount = 0,
        alreadyAssigned = 0,
        attempted = 0,
        sentConsider = 0,
        initialSentConsider = 0,
        initialSleepSentConsider = 0,
        initialSleepActorIds = {},
        noCandidate = 0,
        disabledOrIneligible = 0,
    }

    local candidatesByType = {}
    claimRejectLogCache = {}
    local cellBlacklistReason = profiles.cellBlacklistedReason and profiles.cellBlacklistedReason(cell, settings) or nil
    if cellBlacklistReason then
        npcScanStats.skippedCell = true
        npcScanStats.reason = cellBlacklistReason
        local npcs = cell:getAll(types.NPC)
        npcScanStats.total = #(npcs or {})
        debugLog(
            "assignment skipped cell blacklist",
            tostring(cellName(cell)),
            "reason", tostring(cellBlacklistReason),
            "animatedMorrowindCompat", tostring(animatedMorrowindCompatEnabled() == true)
        )
        runAnimatedMorrowindCompatPass(cell, nil, tostring(assignmentContext.source or "assignment_scan") .. "_cell_blacklist")
        return npcScanStats
    end

    debugLog(
        "assignment settings",
        "sleep", tostring(settings.enableSleeping),
        "fallbackSleep", tostring(settings.allowFallbackSleeping),
        "sit", tostring(settings.enableSitting),
        "fallbackSit", tostring(settings.allowFallbackSitting),
        "fallbackBackedChairs", tostring(settings.allowFallbackBackedChairs),
        "doorAssist", tostring(settings.sleepSmartDoorAssist),
        "hour", tostring(profiles.getGameHour())
    )
    local interactionOrder = interactionOrderForCurrentTime()
    for _, interactionType in ipairs(interactionOrder) do
        if profiles.isInteractionEnabled(settings, interactionType) then
            candidatesByType[interactionType] = buildCandidateSlots(cell, interactionType, assignmentContext)
            local candidateCount = #candidatesByType[interactionType]
            npcScanStats.candidateTotal = npcScanStats.candidateTotal + candidateCount
            if interactionType == "sleeping" then
                npcScanStats.sleepCandidateCount = candidateCount
            elseif interactionType == "sitting" then
                npcScanStats.sittingCandidateCount = candidateCount
            end
            debugLog("candidate count", interactionType, tostring(candidateCount))
        else
            debugLog("interaction disabled", interactionType)
        end
    end

    local npcs = cell:getAll(types.NPC)
    local maxNpcs = tonumber(assignmentContext.maxNpcs)
    local maxAssignments = tonumber(assignmentContext.maxAssignments)
    local consideredNpcs = 0
    for _, npc in ipairs(npcs) do
        if npc and npc.id and sdpAssignmentScanCadence.actorWithinExteriorPolicy(npc, assignmentContext) then
            if not maxNpcs or consideredNpcs < maxNpcs then
                consideredNpcs = consideredNpcs + 1
                npcScanStats.total = npcScanStats.total + 1
                assignSingleNpcToBuiltCandidates(npc, cell, candidatesByType, interactionOrder, assignmentContext, npcScanStats)
                if maxAssignments and npcScanStats.sentConsider >= maxAssignments then break end
            end
        end
    end

    runAnimatedMorrowindCompatPass(cell, candidatesByType.sitting, assignmentContext.source or "assignment_scan")

    debugLog(
        "npc assignment scan",
        "source", tostring(assignmentContext.source or "unknown"),
        "total", tostring(npcScanStats.total),
        "alreadyAssigned", tostring(npcScanStats.alreadyAssigned),
        "attempted", tostring(npcScanStats.attempted),
        "sentConsider", tostring(npcScanStats.sentConsider),
        "noCandidate", tostring(npcScanStats.noCandidate),
        "ineligible", tostring(npcScanStats.disabledOrIneligible)
    )
    local source = tostring(assignmentContext.source or "unknown")
    if source ~= "periodic_sleep_priority" and source ~= "choose_candidate" then
        infoLog(
            "scan summary",
            "source", source,
            "npcs", tostring(npcScanStats.total),
            "sent", tostring(npcScanStats.sentConsider),
            "noCandidate", tostring(npcScanStats.noCandidate),
            "ineligible", tostring(npcScanStats.disabledOrIneligible)
        )
    end
    return npcScanStats
end

function sdpCurrentCellNpcsForExteriorScan(cell)
    if not (cell and cell.getAll) then return {} end
    local ok, npcs = pcall(function() return cell:getAll(types.NPC) end)
    if ok and npcs then return npcs end
    return {}
end

function sdpExteriorNearbyAssignmentOptions(cell, source, kind, initial)
    if not sdpAssignmentScanCadence.isExteriorCell(cell) then return nil end
    local player = primaryPlayer()
    local npcs = sdpCurrentCellNpcsForExteriorScan(cell)
    if initial == true then return sdpAssignmentScanCadence.exteriorInitialOptions(cell, source, player, npcs) end
    return sdpAssignmentScanCadence.exteriorPeriodicOptions(cell, source, player, npcs, kind)
end

function sdpRunExteriorNearbyAssignment(cell, source, kind, initial)
    local options = sdpExteriorNearbyAssignmentOptions(cell, source, kind, initial)
    if not options then return nil end
    options.source = source
    debugLog(
        "exterior nearby assignment scan",
        "source", tostring(source),
        "kind", tostring(kind or "mixed"),
        "radius", tostring(options.maxReferenceDistance),
        "maxNpcs", tostring(options.maxNpcs),
        "maxAssignments", tostring(options.maxAssignments)
    )
    return assignNpcsToLocalInteractions(cell, options)
end

function sdpScheduleExteriorEntryNearbyScan(cell, source)
    if not sdpAssignmentScanCadence.isExteriorCell(cell) then return end
    local now = core.getSimulationTime() or 0
    sdpExteriorAssignmentScan.pending = {
        cell = cell,
        source = tostring(source or "exterior_cell_entry") .. "_nearby_settled",
        due = now + sdpAssignmentScanCadence.exteriorCellEntryDelaySeconds(),
    }
    debugLog("exterior entry assignment deferred", tostring(cellName(cell)), "source", tostring(source), "delay", tostring(sdpAssignmentScanCadence.exteriorCellEntryDelaySeconds()))
end

function sdpProcessExteriorEntryNearbyScan()
    local pending = sdpExteriorAssignmentScan and sdpExteriorAssignmentScan.pending or nil
    if not pending then return end
    local player = primaryPlayer()
    if not (player and player.cell and player.cell == pending.cell) then
        sdpExteriorAssignmentScan.pending = nil
        return
    end
    if (core.getSimulationTime() or 0) < (pending.due or 0) then return end
    sdpExteriorAssignmentScan.pending = nil
    sdpRunExteriorNearbyAssignment(pending.cell, pending.source, "entry", true)
end

assignSingleNpcToBuiltCandidates = function(npc, cell, candidatesByType, interactionOrder, assignmentContext, npcScanStats)
    if not (npc and npc.id) then return false, "invalid_npc" end
    cell = cell or npc.cell
    if assignedActors[npc.id] then
        if npcScanStats then npcScanStats.alreadyAssigned = npcScanStats.alreadyAssigned + 1 end
        return false, "already_assigned"
    end

    for _, interactionType in ipairs(interactionOrder or {}) do
        local eligible, reason = isNpcRecordEligibleForInteraction(npc, interactionType)
        if interactionType == "sitting" and sittingAnimationRejectCooldownActive(npc) then
            eligible = false
            reason = "sitting_missing_animation_cooldown"
        elseif interactionType == "sitting" and sittingCooldownActive(npc) then
            eligible = false
            reason = "sitting_recently_stood"
        end
        if not eligible then
            if interactionType == "sleeping" then
                assignmentEligibility.sendStaleSleepCleanupProbe(npc, reason, assignmentContext and assignmentContext.source or nil, assignedActors, isObjValid, debugLog)
            end
            if npcScanStats then npcScanStats.disabledOrIneligible = npcScanStats.disabledOrIneligible + 1 end
            debugLog("skip npc", npc.recordId or npc.id, "type", interactionType, "reason", tostring(reason))
        else
            local canConsider = true
            local sleepTiming = nil
            if interactionType == "sleeping" then
                canConsider, reason, sleepTiming = sleepEligibilityForNpc(npc, cell, assignmentContext)
                if not canConsider then
                    assignmentEligibility.sendWakeCleanupProbe(npc, reason, assignmentContext and assignmentContext.source or nil, assignedActors, isObjValid, debugLog)
                    if npcScanStats then npcScanStats.disabledOrIneligible = npcScanStats.disabledOrIneligible + 1 end
                    debugLog(
                        "skip npc",
                        npc.recordId or npc.id,
                        "type", interactionType,
                        "reason", tostring(reason),
                        "hour", tostring(sleepTiming and sleepTiming.currentHour),
                        "bedtime", tostring(sleepTiming and sleepTiming.actorBedtime),
                        "phase", tostring(sleepTiming and sleepTiming.phase),
                        "observed", tostring(sleepTiming and sleepTiming.observedReason),
                        "disposition", tostring(sleepTiming and sleepTiming.observedDisposition)
                    )
                end
            end

            local candidates = canConsider and candidatesByType and candidatesByType[interactionType] or nil
            if candidates and #candidates > 0 then
                if npcScanStats then npcScanStats.attempted = npcScanStats.attempted + 1 end
                local candidate = nil
                if interactionType == "sitting" and assignmentContext and assignmentContext.sittingInitialPlacementAllowed == true then
                    candidate = chooseRememberedSittingCandidate(npc, candidates)
                end
                if not candidate then
                    candidate = chooseCandidateForNpc(npc, candidates, interactionType, sleepTiming)
                end
                if candidate then
                    if sleepTiming then
                        candidate = profiles.shallowCopy(candidate)
                        candidate.initialPlacement = sleepTiming.initialPlacement == true
                        candidate.sleepPhase = sleepTiming.phase
                        candidate.actorBedtime = sleepTiming.actorBedtime
                        candidate.actorWakeTime = sleepTiming.actorWakeTime
                        candidate.sleepWakeBias = sleepTiming.wakeBias
                        candidate.observedPlayerOverride = sleepTiming.observedPlayerOverride
                    elseif interactionType == "sitting" and assignmentContext and assignmentContext.sittingInitialPlacementAllowed == true then
                        candidate = profiles.shallowCopy(candidate)
                        candidate.initialPlacement = true
                    end
                    local sentOk, sentReason = sendConsiderInteraction(npc, candidate)
                    if sentOk then
                        if npcScanStats then
                            npcScanStats.sentConsider = npcScanStats.sentConsider + 1
                            if candidate.initialPlacement == true then
                                npcScanStats.initialSentConsider = npcScanStats.initialSentConsider + 1
                                if candidate.interactionType == "sleeping" then
                                    npcScanStats.initialSleepSentConsider = npcScanStats.initialSleepSentConsider + 1
                                    table.insert(npcScanStats.initialSleepActorIds, npc.id)
                                end
                            end
                        end
                        return true, interactionType
                    end
                    return false, sentReason or "consider_not_sent"
                else
                    if npcScanStats then npcScanStats.noCandidate = npcScanStats.noCandidate + 1 end
                end
            end
        end
    end

    return false, "no_candidate"
end

sdpSchedulerArrivalPlacementEnv = function()
    return {
        settings = settings,
        profiles = profiles,
        types = types,
        currentCell = function() return lastCell end,
        assignedActors = function() return assignedActors end,
        occupiedSlots = function() return occupiedSlots end,
        slotOwnership = sdpSlotOwnership,
        buildCandidateSlots = buildCandidateSlots,
        sendConsiderInteraction = sendConsiderInteraction,
        isNpcObjectValidForAssignment = isNpcObjectValidForAssignment,
        isNpcEligibleForInteraction = isNpcRecordEligibleForInteraction,
        sleepEligibilityForNpc = sleepEligibilityForNpc,
        isObjValid = isObjValid,
        cellName = cellName,
        debugLog = debugLog,
        infoLog = infoLog,
        requestStandDispersal = function(...) if sdpRequestSchedulerStandDispersal then return sdpRequestSchedulerStandDispersal(...) end return false end,
    }
end

sdpRequestSchedulerArrivalOverlay = function(payload)
    calibrationLock.notifyDisguiseInitialPlacement(nil, "scheduler", "scheduler_arrival_precover", {
        settings = settings,
        world = world,
        duration = 0.72,
        holdDuration = 0.18,
        precover = true,
        bridge = true,
        visibilityReason = "scheduler_arrival",
        actorCount = payload and payload.actorCount or nil,
        cellName = payload and payload.cellName or nil,
    })
end

sdpRequestSchedulerStandDispersal = function(npc, cell, targets, source, reason)
    if not (isObjValid(npc) and cell and targets and #targets > 0) then return false end
    npc:sendEvent("SitDownPleaseSchedulerStandDispersal", {
        targets = targets,
        source = source or "scheduler_arrival_fallback",
        reason = reason or "sit_sleep_unavailable",
        initialPlacement = true,
    })
    debugLog(
        "scheduler arrival stand dispersal requested",
        npc.recordId or npc.id,
        "cell", tostring(cellName(cell)),
        "targets", tostring(#targets),
        "reason", tostring(reason)
    )
    return true
end

sdpRequestSchedulerStandDispersalForActor = function(npc, reason, source)
    if not (isObjValid(npc) and npc.cell and sdpSchedulerArrivalPlacement and sdpSchedulerArrivalPlacement.targetsForActor) then return false end
    local targets = sdpSchedulerArrivalPlacement.targetsForActor(
        sdpSchedulerArrivalPlacementEnv(),
        npc,
        npc.cell,
        source or "scheduler_arrival_local_reject"
    )
    return sdpRequestSchedulerStandDispersal(npc, npc.cell, targets, source or "scheduler_arrival_local_reject", reason)
end

sdpTryAssignReadyNpcAfterInitialScan = function(data)
    local npc = data and data.npc or nil
    if not (npc and npc.id) then return false end
    if assignedActors[npc.id] or sdpInitialReadyRetryAttempts[npc.id] then return false end
    if completedInitialCellScan ~= true then return false end

    local player = primaryPlayer()
    local cell = player and player.cell or nil
    if not (cell and lastCell and cell == lastCell) then return false end
    if npc.cell ~= cell then return false end
    if initialPlacementGuards.shouldSkipReadyRetry(sdpInitialReadyRetryLastCandidateCount) then return false end

    local now = core.getSimulationTime() or 0
    local sinceEntry = now - (sdpInitialReadyRetryLastEntryAt or -100)
    if sinceEntry < 0 or sinceEntry > 5.5 then return false end
    if not isNpcObjectValidForAssignment(npc) then return false end

    sdpInitialReadyRetryAttempts[npc.id] = now

    local source = tostring(sdpInitialReadyRetryLastEntrySource or "initial_load") .. "_seeker_ready"
    local interactionOrder = interactionOrderForCurrentTime()
    local candidatesByType = {}
    for _, interactionType in ipairs(interactionOrder) do
        if profiles.isInteractionEnabled(settings, interactionType) then
            candidatesByType[interactionType] = buildCandidateSlots(cell, interactionType, assignmentContext)
        end
    end

    local stats = {
        total = 1,
        alreadyAssigned = 0,
        attempted = 0,
        sentConsider = 0,
        initialSentConsider = 0,
        initialSleepSentConsider = 0,
        initialSleepActorIds = {},
        noCandidate = 0,
        disabledOrIneligible = 0,
    }
    local sent, result = assignSingleNpcToBuiltCandidates(npc, cell, candidatesByType, interactionOrder, {
        source = source,
        sleepInitialPlacementAllowed = true,
        sittingInitialPlacementAllowed = settings.sittingInitialPlacementEnabled == true,
    }, stats)

    debugLog(
        "seeker ready initial assignment scan",
        npc.recordId or npc.id,
        "source", source,
        "reason", tostring(data and data.reason),
        "sent", tostring(sent == true),
        "result", tostring(result),
        "attempted", tostring(stats.attempted),
        "noCandidate", tostring(stats.noCandidate),
        "ineligible", tostring(stats.disabledOrIneligible)
    )
    return sent == true
end

sdpLectureAudienceBridge = lectureAudienceTransitionBridgeModule.create({
    assignedActors = function() return assignedActors end,
    interactingState = STATES.interacting,
    transitioningState = STATES.transitioning,
    scheduleLifecycle = scheduleSittingLifecycle,
    slotClaimedByOther = function(slotKey, npc)
        return sdpSlotOwnership.claimedByOther(slotKey, npc, occupiedSlots, assignedActors)
    end,
    claimOccupiedSlot = function(slotKey, npc)
        return sdpSlotOwnership.claim(slotKey, npc, occupiedSlots, assignedActors)
    end,
    noteAudienceMember = function(slotKey, member, details)
        if sdpStationAssignments and sdpStationAssignments.noteAudienceMember then
            sdpStationAssignments.noteAudienceMember(slotKey, member, details)
        end
    end,
    trace = function(tag, ...)
        sdpLectureTrace.log(debugLog, tag, ...)
    end,
    sendTransitionEvent = function(member, payload)
        if member and member.sendEvent then
            member:sendEvent("SitDownPleaseLectureAudienceTransition", payload or {})
        end
    end,
})

sdpStationRuntimeContext = function(dt, forceScan, initialPlacement, targetStationObject)
    return {
        settings = settings,
        profiles = profiles,
        types = types,
        core = core,
        util = util,
        assignedActors = assignedActors,
        stopInteractionForNpc = stopInteractionForNpc,
        actorRoles = sdpActorRoles,
        servicePolicy = sdpServicePolicy,
        releaseSafetyGate = sdpReleaseSafetyGate,
        cellName = cellName,
        dt = dt or 0,
        forceScan = forceScan == true,
        initialPlacement = initialPlacement == true,
        largeTimeAdvance = largeTimeAdvanceThisUpdate == true,
        targetStationObject = targetStationObject,
        isObjValid = function(obj) return isObjValid(obj) end,
        actorDeadReason = actorDeadReason,
        followerBlockReason = sdpStationFollowerBlockReason,
        externalIncapacitationReason = function(npc)
            return sdpExternalAiTakeover.externalIncapacitationReason(npc, types)
        end,
        externalControlScriptReason = function(npc)
            return sdpExternalAiTakeover.externalControlScriptReason(npc)
        end,
        activeNonIdleStanceReason = function(npc)
            return sdpExternalAiTakeover.activeNonIdleStanceReason(npc, types)
        end,
        externalAnimationNpcReason = externalAnimationNpcReason,
        isNpcEligibleForInteraction = isNpcRecordEligibleForInteraction,
        objectSlotKey = objectSlotKey,
        tryTeleport = tryTeleport,
        rotationFromYaw = rotationFromYaw,
        smoothMove = sdpQueueSmoothCalibrationMove,
        smoothMoveActive = sdpSmoothCalibrationMoveActive,
        now = core.getSimulationTime,
        infoLog = infoLog,
        debugLog = debugLog,
        disguiseStationRelease = function(npc, object, reason, payload)
            calibrationLock.notifyDisguiseInitialPlacement(npc, "station", reason or "station_release_after_wait", {
                settings = settings,
                world = world,
                object = object,
                objectId = object and object.recordId or nil,
                position = payload and payload.position or npc and npc.position,
                duration = 0.75,
                holdDuration = 0.35,
            })
        end,
        releaseAudienceNpc = function(npc, reason, delay, audienceItem)
            if not (npc and npc.id) then return end
            local data = assignedActors[npc.id]
            local returnOrigin = data and (data.lectureAudienceOriginPosition or data.preInteractionPos)
                or audienceItem and audienceItem.originPosition
                or nil
            local returnRotation = data and (data.lectureAudienceOriginRotation or data.preInteractionRot)
                or audienceItem and audienceItem.originRotation
                or nil
            local returnToSitting = data
                and data.interactionType == "sitting"
                and data.lectureAudienceTarget == true
                and (data.lectureAudienceReturnMode == "normal_sitting" or data.lectureAudienceWasAlreadySitting == true)
                and returnOrigin == nil
            if data and returnOrigin then
                data.preInteractionPos = returnOrigin
                data.preInteractionRot = returnRotation or data.preInteractionRot
                sdpLectureTrace.log(
                    debugLog,
                    "audience_release_return_origin",
                    "actor", tostring(npc.recordId or npc.id),
                    "station", tostring(data.stationSlotKey),
                    "origin", tostring(returnOrigin),
                    "reason", tostring(reason or "lecture_ended"),
                    "mode", "stand_exit_then_travel",
                    "delay", tostring(delay)
                )
            elseif data and data.lectureAudienceTarget == true then
                sdpLectureTrace.log(
                    debugLog,
                    "audience_release_return_origin",
                    "actor", tostring(npc.recordId or npc.id),
                    "station", tostring(data.stationSlotKey),
                    "origin", "nil",
                    "reason", tostring(reason or "lecture_ended"),
                    "mode", returnToSitting and "restore_sitting_no_origin" or "stop_without_origin",
                    "delay", tostring(delay)
                )
            end
            pendingSittingReassignments[npc.id] = {
                npc = npc,
                due = (core.getSimulationTime() or 0) + (tonumber(delay) or 8),
                source = reason or "lecture_ended",
                stopReason = "sitting_lifecycle_return_origin",
                releaseOnly = true,
                returnToSitting = returnToSitting == true,
                returnOriginPosition = returnOrigin,
                returnOriginRotation = returnRotation,
                stationSlotKey = data and data.stationSlotKey or audienceItem and audienceItem.stationSlotKey,
            }
        end,
        sendAudienceReaction = function(npc, payload)
            if npc and npc.sendEvent then
                npc:sendEvent("SitDownPleaseLectureAudienceReaction", payload or {})
            end
        end,
        returnToOrigin = function(npc, origin, rotation, reason)
            if not (npc and npc.id and origin and stationReturnOrigins) then return end
            local label = npc.recordId or npc.id
            local reasonText = tostring(reason or "station_return_origin")
            local hiddenRelease = settings.disguiseInitialPlacement == true
                and (reasonText == "station_duration_complete_after_wait" or reasonText:find("after_wait", 1, true) ~= nil)
            if hiddenRelease == true and tryTeleport then
                local ok, err = tryTeleport(npc, npc.cell, origin, {
                    rotation = rotation or npc.rotation,
                    onGround = true,
                })
                if ok then
                    debugLog("station presenter return origin hidden teleport", tostring(label), "origin", tostring(origin), "reason", reasonText)
                    return
                end
                debugLog("station presenter return origin hidden teleport failed", tostring(label), tostring(err), "reason", reasonText)
            end
            stationReturnOrigins:set(npc.id, {
                npc = npc,
                origin = origin,
                rotation = rotation or npc.rotation,
                reason = reasonText,
                keepTrying = true,
                maxAttempts = 20,
                retryAfterMaxAttempts = 15,
                completionRadius = 48,
                preserveExternalPackage = true,
            })
            debugLog("station presenter return origin queued", tostring(label), "origin", tostring(origin), "reason", reasonText)
            npc:sendEvent('SitDownPleaseStartAIPackage', {
                type = "Travel",
                destPosition = origin,
                isRepeat = false,
                cancelOther = true,
                destinationTolerance = 48,
                preserveExternalPackage = true,
                reason = reasonText,
                stationType = "lectern",
            })
        end,
        stationPresenterOrigin = function(npc)
            local data = npc and npc.id and assignedActors[npc.id] or nil
            if not data then return nil, nil, nil end
            if data.lectureAudienceOriginPosition then
                return data.lectureAudienceOriginPosition, data.lectureAudienceOriginRotation, "previous_audience_origin"
            end
            if data.preInteractionPos then
                return data.preInteractionPos, data.preInteractionRot, "previous_interaction_origin"
            end
            if data.npcStandingPos then
                return data.npcStandingPos, data.npcStandingRot, "previous_standing_origin"
            end
            return nil, nil, nil
        end,
        tryStartTravel = function(npc, dest, reason, options)
            if not (npc and dest) then return false end
            options = options or {}
            npc:sendEvent('SitDownPleaseStartAIPackage', {
                type = "Travel",
                destPosition = dest,
                isRepeat = false,
                cancelOther = options.cancelOther,
                destinationTolerance = options.destinationTolerance,
                reason = reason or "station_return_origin",
                stationType = options.stationType,
                slotKey = options.slotKey,
                objectId = options.objectId,
            })
            return true
        end,
    }
end

sdpLectureAudienceContext = function()
    return {
        settings = settings,
        profiles = profiles,
        types = types,
        assignedActors = assignedActors,
        pendingSittingReassignments = pendingSittingReassignments,
        stationAssignments = sdpStationAssignments,
        now = core.getSimulationTime,
        cellIsInterior = sdpStationCellIsInterior,
        isObjValid = function(obj) return isObjValid(obj) end,
        actorDeadReason = actorDeadReason,
        followerBlockReason = sdpStationFollowerBlockReason,
        isNpcEligibleForInteraction = isNpcRecordEligibleForInteraction,
        servicePolicy = sdpServicePolicy,
        stopInteractionForNpc = stopInteractionForNpc,
        transitionSeatedAudienceMember = sdpLectureAudienceBridge.transitionSeated,
        debugLog = debugLog,
        infoLog = infoLog,
    }
end

sdpLectureAssignmentEnv = function()
    return {
        settings = settings,
        profiles = profiles,
        stationAssignments = sdpStationAssignments,
        lectureAudience = sdpLectureAudience,
        lectureTrace = sdpLectureTrace,
        runtimeContext = sdpStationRuntimeContext,
        audienceContext = sdpLectureAudienceContext,
        stationSlotKey = sdpStationSlotKey,
        lastCell = function() return lastCell end,
        pendingInitialHandoffs = function() return pendingInitialHandoffs end,
        settleInitialPlacementOverlay = settleInitialPlacementOverlay,
        isObjValid = function(obj) return isObjValid(obj) end,
        isNpcValid = isNpcObjectValidForAssignment,
        smoothMove = sdpQueueSmoothCalibrationMove,
        smoothMoveActive = sdpSmoothCalibrationMoveActive,
        tryTeleport = tryTeleport,
        rotationFromYaw = rotationFromYaw,
        debugLog = debugLog,
        infoLog = infoLog,
    }
end

sdpRebalanceLecternAudience = function(newlyClaimed, options)
    return sdpLectureAssignmentController.rebalanceLecternAudience(sdpLectureAssignmentEnv(), newlyClaimed, options)
end

sdpProcessStationAssignments = function(cell, dt, forceScan, initialPlacement, targetStationObject)
    return sdpLectureAssignmentController.processStationAssignments(sdpLectureAssignmentEnv(), cell, dt, forceScan, initialPlacement, targetStationObject)
end

sdpTriggerStationLecture = function(session, options)
    return sdpLectureAssignmentController.triggerStationLecture(sdpLectureAssignmentEnv(), session, options)
end

sdpClaimStationWithNpc = function(sessionOrObject, npc, options)
    return sdpLectureAssignmentController.claimStationWithNpc(sdpLectureAssignmentEnv(), sessionOrObject, npc, options)
end

sdpReleaseStationForNpc = function(npc, reason)
    return sdpLectureAssignmentController.releaseStationForNpc(sdpLectureAssignmentEnv(), npc, reason)
end

sdpStationDataForNpc = function(npc)
    return sdpLectureAssignmentController.stationDataForNpc(sdpLectureAssignmentEnv(), npc)
end

sdpStationSlotOccupied = function(slotKey)
    return sdpLectureAssignmentController.stationSlotOccupied(sdpLectureAssignmentEnv(), slotKey)
end

sdpClaimedStationData = function(slotKey)
    return sdpLectureAssignmentController.claimedStationData(sdpLectureAssignmentEnv(), slotKey)
end

sdpApplyStationCalibration = function(session)
    return sdpLectureAssignmentController.applyStationCalibration(sdpLectureAssignmentEnv(), session)
end

sdpOnStationPoseRequest = function(ev)
    return sdpLectureAssignmentController.onStationPoseRequest(sdpLectureAssignmentEnv(), ev)
end

local function clearAssignedActors(reason, notifyLocalScripts)
    local savedInteractionOrigins = nil
    if reason ~= "settings_rescan" then
        savedInteractionOrigins = sdpOriginTracker.buildSaveData(assignedActors, {
            states = STATES,
            isObjValid = isObjValid,
            cellName = cellName,
        })
    end

    for npcId, data in pairs(assignedActors) do
        if data and data.slotKey then
            occupiedSlots[data.slotKey] = nil
        end

        if notifyLocalScripts and data and isObjValid(data.npc) then
            data.npc:sendEvent('StopInteractionObject', {
                reason = reason or "assignment_cleared",
                interactionType = data.interactionType,
                forceClearSleepAnimation = data.interactionType == "sleeping" or data.interactionType == "sitting",
            })
        end
    end

    assignedActors = {}
    occupiedSlots = {}
    sdpSleepReservations.reset()
    wakeExit.clearStandAndWakeAll()
    pendingSittingReassignments = {}
    sdpLectureSeatReservations.clear()
    sdpSmoothCalibrationMoveController.reset()
    calibrationBlockerMarkerEvents.sendAllCleared(world.players, reason or "assignment_cleared")
    if reason == "cell_rescan" or reason == "settings_rescan" then
        sdpStationAssignments.snapshotActiveLectures(sdpStationRuntimeContext(0, false, false, nil), reason)
    end
    sdpStationAssignments.reset(reason == "cell_rescan")
    sittingOriginReturns:reset()
    stationReturnOrigins:reset()
    pendingInitialHandoffs = {}
    lastInitialPlacementFinalSettleReason = nil
    lastInitialPlacementFinalSettleAt = -100
    sdpInitialReadyRetryAttempts = {}
    handoffTracker.reset()
    sleepRouteDoors.clearPendingRestarts()
    sdpStationRouteDoors.reset(reason or "assignment_cleared")
    sleepRouteRejectCooldowns = {}
    if reason ~= "settings_rescan" then
        sdpSavedInteractionOrigins = sdpOriginTracker.mergeRecords(sdpSavedInteractionOrigins, savedInteractionOrigins)
        sdpOriginTracker.resetHomeOrigins()
    end
    sleepLightControl.clearSleepers(reason or "assignment_cleared")
    clearRelevantObjectCache("cell_change")
end

onCellChange = function(source)
    local player = world.players[1]
    local cell = player and player.cell or nil

    local isCellEntry = source == "initial_load" or source == "cell_change" or source == "cell_change_event"
    local sleepInitialPlacementAllowed = isCellEntry == true
    local sittingInitialPlacementAllowed = isCellEntry == true and settings.sittingInitialPlacementEnabled == true

    sleepLightControl.onCellChange(cell, source or "cell_change")
    if isCellEntry then
        sdpInitialReadyRetryLastEntryAt = core.getSimulationTime() or 0
        sdpInitialReadyRetryLastEntrySource = source or "cell_change"
        sdpInitialReadyRetryLastCandidateCount = 0
        sdpInitialReadyRetryAttempts = {}
    end
    -- A settings-triggered rescan happens in the same live cell. Notify local
    -- NPC scripts before clearing global state; otherwise the global script can
    -- forget an actor while the local script remains in sitting/sleeping
    -- state. Actual cell changes can safely discard old-cell state without
    -- trying to message unloaded actors.
    clearAnimatedMorrowindCompatRuntime(source == "settings" and "settings_rescan" or "cell_change")
    if isCellEntry and calibrationMenu and calibrationMenu.clearCalibrationTestNpcs then
        calibrationMenu.clearCalibrationTestNpcs(source or "cell_change")
    end
    clearAssignedActors(source == "settings" and "settings_rescan" or "cell_rescan", source == "settings")
    if isCellEntry and calibrationLock.clearForCellChange({ infoLog = infoLog }, source or "cell_change") then
        sendCalibrationMenuStatus("", nil, nil, true, { silent = true })
    end

    local stats = nil
    if sdpAssignmentScanCadence.isExteriorCell(cell) then
        stats = {
            total = 0,
            candidateTotal = 0,
            sleepCandidateCount = 0,
            sittingCandidateCount = 0,
            alreadyAssigned = 0,
            attempted = 0,
            sentConsider = 0,
            initialSentConsider = 0,
            initialSleepSentConsider = 0,
            initialSleepActorIds = {},
            noCandidate = 0,
            disabledOrIneligible = 0,
            skippedExteriorWideScan = true,
        }
        debugLog("assignment skipped exterior wide scan", tostring(cellName(cell)), "source", tostring(source or "cell_change"))
        if isCellEntry and source ~= "exterior_streaming" then
            sdpScheduleExteriorEntryNearbyScan(cell, source or "cell_change")
        end
    else
        sdpProcessStationAssignments(cell, 0, true, isCellEntry == true)
        stats = assignNpcsToLocalInteractions(cell, {
            source = source or "cell_change",
            sleepInitialPlacementAllowed = sleepInitialPlacementAllowed,
            sittingInitialPlacementAllowed = sittingInitialPlacementAllowed,
            allowDueBedtimeInitialPlacement = isCellEntry == true,
        })
        if isCellEntry and sdpDelayedInitialPlacementRetry and sdpDelayedInitialPlacementRetry.schedule then
            sdpDelayedInitialPlacementRetry.schedule(cell, source or "cell_change", stats)
        end
        if isCellEntry then
            scheduleAnimatedMorrowindCompatRetry(tostring(source or "cell_change") .. "_delayed_alignment", 0.45, 8.0)
        end
    end
    if isCellEntry then
        sdpInitialReadyRetryLastCandidateCount = tonumber(stats and stats.candidateTotal or 0) or 0
    end

    completedInitialCellScan = true
    if isCellEntry and world and world.players then
        for _, player in ipairs(world.players) do pcall(function() player:sendEvent('SitDownPleaseInitialAssignmentScanComplete', { initialSleepSentConsider = stats and stats.initialSleepSentConsider or 0, initialSleepActorIds = stats and stats.initialSleepActorIds or nil, initialSentConsider = stats and stats.initialSentConsider or 0, source = source or "cell_change" }) end) end
    end
    if isCellEntry
        and settleInitialPlacementOverlay
        and not (sdpDelayedInitialPlacementRetry.pending and sdpDelayedInitialPlacementRetry.pending.holdOverlay == true)
        and (not stats or tonumber(stats.initialSleepSentConsider or 0) <= 0)
    then
        settleInitialPlacementOverlay("no_initial_sleep_candidates")
    end
end

local function onSittingCalibrationUpdated(ev)
    local npc = ev and ev.npc
    if not (npc and npc.id and ev.finalPosition) then return end
    local data = assignedActors[npc.id]
    if not (data and data.interactionType == "sitting") then return end

    data.finalPosition = ev.finalPosition
    data.finalRotation = ev.finalRotation or data.finalRotation
    data.position = ev.finalPosition
    data.profileOffset = ev.profileOffset or data.profileOffset
    data.animationOffset = ev.animationOffset or data.animationOffset
    data.animationName = ev.animation or data.animationName
    data.calibration = ev.calibration or data.calibration
    sendCalibrationOffsets("sitting", data.profileOffset, data.animationOffset, data.calibration, data.animationName, data)

    -- Calibration holds keep normal teleport retry state out of menu nudges.
    local now = core.getSimulationTime() or 0
    data.calibrationMenuHoldUntil = now + 45
    data.teleportBusySkips = nil
    data.teleportBusyFirstAt = nil

    if data.state == STATES.interacting or data.state == STATES.transitioning then
        local targetYaw = data.finalRotation or npc.rotation:getYaw()
        if sdpQueueSmoothCalibrationMove(npc, data, ev.finalPosition, targetYaw, "sitting_calibration_smooth", ev.reason) then
            debugLog(
                "sitting calibration smooth queued",
                npc.recordId or npc.id,
                "reason", tostring(ev.reason or "settings"),
                "activity", tostring(ev.activity or "standard"),
                "animation", tostring(ev.animation or ""),
                "final", tostring(ev.finalPosition)
            )
            return
        end
        local ok, err = tryTeleport(npc, npc.cell, ev.finalPosition, { rotation = rotationFromYaw(targetYaw, npc.rotation) })
        if ok then
            debugLog(
                "sitting calibration applied",
                npc.recordId or npc.id,
                "reason", tostring(ev.reason or "settings"),
                "activity", tostring(ev.activity or "standard"),
                "animation", tostring(ev.animation or ""),
                "final", tostring(ev.finalPosition)
            )
        elseif not deferTeleportFailure(data, err, "sitting_calibration") then
            debugLog("sitting calibration teleport failed", npc.recordId or npc.id, tostring(err))
        end
    else
        debugLog("sitting calibration stored", npc.recordId or npc.id, "state", tostring(data.state), "reason", tostring(ev.reason or "settings"))
    end
end

function onAnimatedMorrowindAlignmentResult(ev)
    return sdpAnimatedMorrowindAssignment.onAlignmentResult(ev)
end

function processAnimatedMorrowindSettleCorrections()
    return sdpAnimatedMorrowindAssignment.processSettleCorrections()
end

sdpRetrySittingAfterLocalReject = function(ev)
    return sdpSittingLocalRejectRetry.retry({
        settings = function() return settings end,
        buildCandidateSlots = buildCandidateSlots,
        chooseCandidateForNpc = chooseCandidateForNpc,
        sendConsiderInteraction = sendConsiderInteraction,
        setLocalRejectCooldown = sdpSetSittingLocalRejectCooldown,
        shallowCopy = profiles.shallowCopy,
        debugLog = debugLog,
    }, ev)
end

sdpRescueInitialSleepReject = function(ev, handoffItem)
    if not (ev and ev.initialPlacement == true and ev.interactionType == "sleeping") then return false end
    if ev.schedulerArrivalPlacement == true or sdpCalibrationFillOwnership.isAcceptedEvent(ev) then return false end
    local savedOrigin, savedOriginIndex = sdpOriginTracker.peek(sdpSavedInteractionOrigins, ev, { cellName = cellName })
    local homeOrigin = sdpOriginTracker.homeFor(ev.npc, { actorKey = actorKey })
    local rescued = sdpSleepInitialRejectRescue.rescue({
        tryTeleport = function(...) return tryTeleport(...) end,
        loadVector = sdpOriginTracker.loadVector,
        rotationFromYaw = rotationFromYaw,
        debugLog = debugLog,
    }, ev, {
        savedOrigin = savedOrigin,
        homeOrigin = homeOrigin,
        handoffCandidate = handoffItem and handoffItem.candidate or nil,
    }) == true
    if rescued and savedOriginIndex then table.remove(sdpSavedInteractionOrigins, savedOriginIndex) end
    return rescued
end

local function onInteractionCheckResult(ev)
    if not ev or not ev.npc or not ev.npc.id then return end
    local hadPendingHandoff, handoffItem = handoffTracker.releaseOnResult(ev.npc.id)
    local wasInitialHandoff = pendingInitialHandoffs[ev.npc.id] ~= nil
        or (ev.initialPlacement == true and ev.suppressInitialPlacementOverlay ~= true)
    pendingInitialHandoffs[ev.npc.id] = nil

    local resultActorDead, resultDeadReason = actorDeadReason(ev.npc)
    if resultActorDead then
        if ev.slotKey then occupiedSlots[ev.slotKey] = nil end
        if ev.interactionType == "sleeping" then
            releaseSleepReservationBySlot(ev.slotKey, resultDeadReason or "dead_actor", sleepReservationNpcId(ev.npc))
            sleepLightControl.unregisterSleeper(ev.npc, resultDeadReason or "dead_actor", true)
            sleepLightControl.processPending(true)
        end
        assignedActors[ev.npc.id] = nil
        wakeExit.clearStandAndWakeForNpc(ev.npc.id)
        calibrationBlockerMarkerEvents.sendCleared(world.players, ev, resultDeadReason or "dead_actor")
        clearRelevantObjectCache("dead_actor")
        infoLog("assignment released dead_actor", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        if wasInitialHandoff and settleInitialPlacementOverlay then settleInitialPlacementOverlay("dead_actor", ev.npc) end
        return
    end

    if not ev.usable then
        if ev.slotKey then
            occupiedSlots[ev.slotKey] = nil
            clearRelevantObjectCache("slot_rejected")
        end
        if ev.interactionType == "sleeping" then
            if tostring(ev.reason or ""):find("active_", 1, true) == 1 then
                markSleepReservationFailed(ev.npc, ev.slotKey, ev.reason)
            else
                releaseSleepReservationBySlot(ev.slotKey, ev.reason or "local_rejected", sleepReservationNpcId(ev.npc))
            end
        end
        local focusLog, focusModelLog, focusCandidatesLog = sdpFocusMetadata.logSummary(ev)
        debugLog(
            "reject",
            ev.npc.recordId or ev.npc.id,
            "type", tostring(ev.interactionType),
            "object", tostring(ev.objectId),
            "profile", tostring(ev.profileId),
            "slot", tostring(ev.slotName),
            "reason", tostring(ev.reason),
            "approach", tostring(ev.sleepRouteApproachName),
            "approachPos", tostring(ev.sleepRouteApproachPos),
            "navPos", tostring(ev.sleepRouteNavPos),
            "navReason", tostring(ev.sleepRouteNavReason),
            "navDelta", tostring(ev.sleepRouteNavDelta),
            "pathLength", tostring(ev.sleepRoutePathLength),
            "focus", tostring(focusLog),
            "focusModel", tostring(focusModelLog),
            "focusCandidates", tostring(focusCandidatesLog),
            "hour", tostring(ev.currentHour)
        )
        calibrationBlockerMarkerEvents.sendRejectedBlocked(world.players, ev)
        if ev.manualAssign == true then
            if ev.manualAssignOverrideTesting == true then
                infoLog("nearest_manual_assign_normal_play_blocker", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason), "focus", tostring(focusLog), "focusCandidates", tostring(focusCandidatesLog))
                infoLog("calibration_target_blocker_reason", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason), "focus", tostring(focusLog), "focusCandidates", tostring(focusCandidatesLog))
            else
                infoLog("nearest_manual_assign_target_failed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason), "focus", tostring(focusLog), "focusCandidates", tostring(focusCandidatesLog))
                infoLog("calibration_target_rejected", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason), "focus", tostring(focusLog), "focusCandidates", tostring(focusCandidatesLog))
            end
            local retried = false
            if calibrationMenu and calibrationMenu.onManualAssignRejected then
                retried = calibrationMenu.onManualAssignRejected(ev) == true
            end
            if not retried then
                local message = ev.manualAssignOverrideTesting == true
                    and ("Assign Nearest normal-play blocker: " .. tostring(ev.reason or "unknown"))
                    or ("Assign Nearest could not complete: " .. tostring(ev.reason or "unknown"))
                sendCalibrationMenuStatus(message, ev.interactionType)
            end
        end
        if (ev.calibrationFill == true
            or ev.calibrationTestNpc == true
            or ev.calibrationFillSource ~= nil
            or ev.calibrationFillLabel ~= nil)
            and calibrationMenu and calibrationMenu.onCalibrationFillRejected then
            calibrationMenu.onCalibrationFillRejected(ev)
        end
        if ev.interactionType == "sitting" and tostring(ev.reason or "") == "missing_animation" then
            setSittingAnimationRejectCooldown(ev.npc, 1800, "missing_animation")
            debugLog("sitting local rejection remembered", ev.npc.recordId or ev.npc.id, "reason", "missing_animation", "object", tostring(ev.objectId), "profile", tostring(ev.profileId))
        end
        sdpRescueInitialSleepReject(ev, handoffItem)
        if ev.schedulerArrivalPlacement == true then
            if ev.initialPlacement == true and ev.interactionType == "sleeping" then
                sleepLightControl.unregisterSleeper(ev.npc, "sleep_initial_placement_rejected", true)
                sleepLightControl.processPending(true)
            end
            local schedulerFallbackDispersed = sdpRequestSchedulerStandDispersalForActor(
                ev.npc,
                "local_rejected_" .. tostring(ev.reason or "unknown"),
                "scheduler_arrival_local_reject"
            ) == true
            if wasInitialHandoff and settleInitialPlacementOverlay and not schedulerFallbackDispersed then
                settleInitialPlacementOverlay("initial_placement_rejected", ev.npc)
            end
            return
        end
        local sittingFailureReassigned = sdpRetrySittingAfterLocalReject(ev)
        local routeFailureReassigned = false
        local routeRejectHandled, routeRejectCandidate = false, nil
        if not (ev.initialPlacement == true and ev.interactionType == "sleeping") then
            routeRejectHandled, routeRejectCandidate = sleepRouteRejection.retryCandidate({
                debugLog = debugLog,
                markSleepRouteRejected = markSleepRouteRejected,
                buildCandidateSlots = buildCandidateSlots,
                chooseCandidateForNpc = chooseCandidateForNpc,
            }, ev)
        end
        if routeRejectHandled == true then
            local candidate = routeRejectCandidate
            if candidate then
                routeFailureReassigned = true
                debugLog(
                    "reassignment_after_local_route_failure",
                    ev.npc.recordId or ev.npc.id,
                    "fromObject", tostring(ev.objectId),
                    "toObject", tostring(candidate.objectId),
                    "slot", tostring(candidate.slotName),
                    "reason", tostring(ev.reason)
                )
                sendConsiderInteraction(ev.npc, candidate)
            end
        end
        if ev.interactionType == "sleeping" and tostring(ev.reason or ""):find("active_", 1, true) == 1 then
            -- Avoid retry spam when another mod/quest/schedule owns the actor AI.
            -- A longer cooldown prevents periodic sleep priority from repeatedly
            -- reassigning the same NPC to a bed while a Travel/Follow/etc. package
            -- is still active.
            local seconds = math.max(120, tonumber(settings.sleepWakeRetryCooldown or 20) or 20)
            sleepWakeRetryCooldowns[sleepCooldownKey(ev.npc)] = realTimeNow() + seconds
            debugLog("sleep active-package cooldown", ev.npc.recordId or ev.npc.id, tostring(ev.reason), "seconds", tostring(seconds))
        end
        if ev.initialPlacement == true and ev.interactionType == "sleeping" and not sdpCalibrationFillOwnership.isAcceptedEvent(ev) then
            sleepLightControl.unregisterSleeper(ev.npc, "sleep_initial_placement_rejected", true)
            sleepLightControl.processPending(true)
        end
        if wasInitialHandoff
            and settleInitialPlacementOverlay
            and not routeFailureReassigned
            and not sittingFailureReassigned
        then
            settleInitialPlacementOverlay("initial_placement_rejected", ev.npc)
        end
        return
    end

    local existingAssignment = assignedActors[ev.npc.id]
    if ev.interactionType == "sitting" then
        local staleSittingResult = not hadPendingHandoff and existingAssignment and existingAssignment.interactionType == "sitting"
        infoLog(
            staleSittingResult and "global sitting accepted result stale ignored" or "global sitting accepted result received",
            ev.npc.recordId or ev.npc.id,
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName)
        )
        if staleSittingResult then
            calibrationBlockerMarkerEvents.sendCleared(world.players, ev, "stale_accepted")
            return
        end
    end
    if ev.interactionType == "sleeping"
        and existingAssignment
        and existingAssignment.interactionType == "sleeping"
        and existingAssignment.slotKey == ev.slotKey
        and existingAssignment.objectId == ev.objectId
        and (existingAssignment.state == STATES.approaching or existingAssignment.state == STATES.transitioning or existingAssignment.state == STATES.interacting)
    then
        existingAssignment.finalPosition = ev.finalPosition or existingAssignment.finalPosition
        existingAssignment.finalRotation = ev.finalRotation or existingAssignment.finalRotation
        existingAssignment.position = ev.hitPos or existingAssignment.position
        existingAssignment.approachPos = ev.approachPos or existingAssignment.approachPos
        existingAssignment.sleepRouteStartPosition = ev.sleepRouteStartPosition or existingAssignment.sleepRouteStartPosition
        existingAssignment.sleepRoutePostDoorWaypoint = ev.sleepRoutePostDoorWaypoint or existingAssignment.sleepRoutePostDoorWaypoint
        existingAssignment.slot = ev.slot or existingAssignment.slot
        existingAssignment.profile = ev.profile or existingAssignment.profile
        existingAssignment.profileId = ev.profileId or existingAssignment.profileId
        existingAssignment.profileOffset = ev.profileOffset or existingAssignment.profileOffset
        existingAssignment.animationOffset = ev.animationOffset or existingAssignment.animationOffset
        existingAssignment.animationName = ev.animation or existingAssignment.animationName
        existingAssignment.calibration = ev.calibration or existingAssignment.calibration
        existingAssignment.manualAssignOverrideApplied = ev.manualAssignOverrideApplied == true
        existingAssignment.manualAssignOverrideReason = ev.manualAssignOverrideReason
        existingAssignment.sleepRouteReason = ev.sleepRouteReason or existingAssignment.sleepRouteReason
        existingAssignment.sleepRouteApproachName = ev.sleepRouteApproachName or existingAssignment.sleepRouteApproachName
        existingAssignment.sleepRouteApproachPos = ev.sleepRouteApproachPos or existingAssignment.sleepRouteApproachPos
        existingAssignment.sleepRouteNavPos = ev.sleepRouteNavPos or existingAssignment.sleepRouteNavPos
        existingAssignment.sleepRouteNavReason = ev.sleepRouteNavReason or existingAssignment.sleepRouteNavReason
        existingAssignment.sleepRouteNavDelta = ev.sleepRouteNavDelta or existingAssignment.sleepRouteNavDelta
        existingAssignment.sleepRoutePathLength = ev.sleepRoutePathLength or existingAssignment.sleepRoutePathLength
        existingAssignment.surfaceBlockerReason = ev.surfaceBlockerReason
        existingAssignment.surfaceBlockerOverrideReason = ev.surfaceBlockerOverrideReason
        existingAssignment.surfaceBlockerKind = ev.surfaceBlockerKind
        existingAssignment.surfaceBlockerObjectId = ev.surfaceBlockerObjectId
        existingAssignment.surfaceBlockerDistance = ev.surfaceBlockerDistance
        existingAssignment.surfaceBlockerVertical = ev.surfaceBlockerVertical
        existingAssignment.surfaceBlockerLocalReason = ev.surfaceBlockerLocalReason
        existingAssignment.softBlockerReason = ev.softBlockerReason
        existingAssignment.hardBlockerReason = ev.hardBlockerReason
        existingAssignment.surfaceMode = ev.sleepSurfaceMode or ev.surfaceMode or existingAssignment.surfaceMode
        existingAssignment.surfaceSamples = ev.sleepSurfaceSamples or ev.surfaceSamples or existingAssignment.surfaceSamples
        existingAssignment.sleepSurfaceMode = ev.sleepSurfaceMode or ev.surfaceMode or existingAssignment.sleepSurfaceMode
        existingAssignment.sleepRawSurfaceMode = ev.sleepRawSurfaceMode or ev.rawSurfaceMode or existingAssignment.sleepRawSurfaceMode
        existingAssignment.rawSurfaceMode = ev.rawSurfaceMode or ev.sleepRawSurfaceMode or existingAssignment.rawSurfaceMode
        existingAssignment.sleepSurfaceAnchorStabilized = ev.sleepSurfaceAnchorStabilized == true or existingAssignment.sleepSurfaceAnchorStabilized == true
        existingAssignment.safetyEvaluated = ev.safetyEvaluated == true
        existingAssignment.bedTop = ev.bedTop or ev.sleepSurfacePosition or existingAssignment.bedTop
        existingAssignment.sleepSurfacePosition = ev.sleepSurfacePosition or ev.bedTop or existingAssignment.sleepSurfacePosition
        existingAssignment.sleepObjectTopPosition = ev.sleepObjectTopPosition or ev.sleepSurfaceTopPosition or existingAssignment.sleepObjectTopPosition
        existingAssignment.sleepSurfaceTopPosition = ev.sleepSurfaceTopPosition or ev.sleepObjectTopPosition or existingAssignment.sleepSurfaceTopPosition
        existingAssignment.rawBedTop = ev.rawBedTop or ev.sleepRawSurfacePosition or existingAssignment.rawBedTop
        existingAssignment.sleepRawSurfacePosition = ev.sleepRawSurfacePosition or ev.rawBedTop or existingAssignment.sleepRawSurfacePosition
        existingAssignment.sleepFloorPosition = ev.sleepFloorPosition or existingAssignment.sleepFloorPosition
        if ev.safetyEvaluated == true then
            existingAssignment.sleepSafetyReason = ev.sleepSafetyReason
            existingAssignment.sleepSafetyDelta = ev.sleepSafetyDelta
            existingAssignment.sleepSafetyLimit = ev.sleepSafetyLimit
            existingAssignment.sleepSafetyOverrideReason = ev.sleepSafetyOverrideReason
            existingAssignment.sleepSafetyRepairReason = ev.sleepSafetyRepairReason
            existingAssignment.sleepSafetyRepairDelta = ev.sleepSafetyRepairDelta
            existingAssignment.sleepSafetyRepairLimit = ev.sleepSafetyRepairLimit
            existingAssignment.sleepCalibrationWarningReason = ev.sleepCalibrationWarningReason
        else
            existingAssignment.sleepSafetyReason = ev.sleepSafetyReason or existingAssignment.sleepSafetyReason
            existingAssignment.sleepSafetyDelta = ev.sleepSafetyDelta or existingAssignment.sleepSafetyDelta
            existingAssignment.sleepSafetyLimit = ev.sleepSafetyLimit or existingAssignment.sleepSafetyLimit
            existingAssignment.sleepSafetyOverrideReason = ev.sleepSafetyOverrideReason or existingAssignment.sleepSafetyOverrideReason
            existingAssignment.sleepSafetyRepairReason = ev.sleepSafetyRepairReason or existingAssignment.sleepSafetyRepairReason
            existingAssignment.sleepSafetyRepairDelta = ev.sleepSafetyRepairDelta or existingAssignment.sleepSafetyRepairDelta
            existingAssignment.sleepSafetyRepairLimit = ev.sleepSafetyRepairLimit or existingAssignment.sleepSafetyRepairLimit
            existingAssignment.sleepCalibrationWarningReason = ev.sleepCalibrationWarningReason
        end
        existingAssignment.calibrationAction = existingAssignment.calibrationAction == true or ev.calibrationAction == true
        existingAssignment.calibrationReason = ev.calibrationReason or existingAssignment.calibrationReason
        existingAssignment.calibrationTestNpc = existingAssignment.calibrationTestNpc == true or ev.calibrationTestNpc == true
        existingAssignment.calibrationFill = existingAssignment.calibrationFill == true or ev.calibrationFill == true
        existingAssignment.calibrationFillLabel = ev.calibrationFillLabel or existingAssignment.calibrationFillLabel
        existingAssignment.calibrationFillRole = ev.calibrationFillRole or existingAssignment.calibrationFillRole
        existingAssignment.calibrationFillSource = ev.calibrationFillSource or existingAssignment.calibrationFillSource
        existingAssignment.calibrationFillIndex = ev.calibrationFillIndex or existingAssignment.calibrationFillIndex
        existingAssignment.calibrationFillSessionId = ev.calibrationFillSessionId or existingAssignment.calibrationFillSessionId
        existingAssignment.calibrationRuntimeObjectId = ev.calibrationRuntimeObjectId or existingAssignment.calibrationRuntimeObjectId
        existingAssignment.actorDisplayLabel = ev.actorDisplayLabel or existingAssignment.actorDisplayLabel
        sendCalibrationOffsets("sleeping", existingAssignment.profileOffset, existingAssignment.animationOffset, existingAssignment.calibration, existingAssignment.animationName, existingAssignment)
        if ev.calibrationAction == true then
            existingAssignment.calibrationMenuHoldUntil = core.getSimulationTime() + 45
            existingAssignment.teleportBusySkips = nil
            existingAssignment.teleportBusyFirstAt = nil
        end
        updateSleepReservationState(ev.npc, existingAssignment.state == STATES.interacting and "sleeping" or "routing", "duplicate_assignment_reused")
        local fillOwnedAccepted = sdpCalibrationFillOwnership.isAcceptedEvent(ev)
        if not fillOwnedAccepted then
            calibrationLock.rememberTarget(existingAssignment, { cellName = cellName, now = core.getSimulationTime }, ev.calibrationAction == true and "calibration_reused" or "duplicate_assignment_reused")
        end
        if ev.manualAssign == true and not fillOwnedAccepted then
            calibrationLock.rememberTarget(existingAssignment, { cellName = cellName, now = core.getSimulationTime }, "manual_assign_reused")
            infoLog("nearest_manual_assign_set_calibration_target", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("nearest_manual_assign_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("calibration_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "label", calibrationLock.sessionLabel(existingAssignment))
            infoLog("reassign_target_reached", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("nearest_manual_assign_status", "accepted", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "override", tostring(ev.manualAssignOverrideApplied == true), "overrideReason", tostring(ev.manualAssignOverrideReason))
            sendCalibrationMenuStatus("Assign Nearest target confirmed.", ev.interactionType, calibrationLock.sessionLabel(existingAssignment), false, sdpCalibrationStatusExtraFromAssignment(existingAssignment, {
                testingOverride = ev.manualAssignOverrideApplied == true,
                testingOverrideReason = ev.manualAssignOverrideReason,
            }))
        end
        if ev.calibrationAction == true and ev.finalPosition
            and (existingAssignment.state == STATES.interacting or existingAssignment.state == STATES.transitioning) then
            local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(existingAssignment.finalRotation or ev.npc.rotation:getYaw(), ev.npc.rotation) })
            if ok then
                infoLog("calibration re-enter applied", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.calibrationReason or "reenter"))
            elseif not deferTeleportFailure(existingAssignment, err, "calibration_reenter") then
                debugLog("calibration re-enter teleport failed", ev.npc.recordId or ev.npc.id, tostring(err))
            end
        end
        if settings.debug then
            debugLog(
                "sleep duplicate assignment reused",
                ev.npc.recordId or ev.npc.id,
                "object", tostring(ev.objectId),
                "slot", tostring(ev.slotName),
                "state", tostring(existingAssignment.state)
            )
        end
        if not calibrationBlockerMarkerEvents.sendBlocked(world.players, existingAssignment) then
            calibrationBlockerMarkerEvents.sendCleared(world.players, ev, "accepted")
        end
        return
    end

    local savedOrigin = sdpOriginTracker.take(sdpSavedInteractionOrigins, ev, { cellName = cellName })
    local sleepOriginPos = ev.preInteractionPos or (savedOrigin and sdpOriginTracker.loadVector(savedOrigin.origin)) or ev.npc.position
    local sleepOriginRot = ev.preInteractionRot or (savedOrigin and rotationFromYaw(tonumber(savedOrigin.originYaw), ev.npc.rotation)) or ev.npc.rotation
    if savedOrigin then
        debugLog(
            "interaction origin restored",
            ev.npc.recordId or ev.npc.id,
            "type", tostring(ev.interactionType),
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName)
        )
    elseif ev.interactionType == "sleeping" then
        local home = sdpOriginTracker.homeFor(ev.npc, { actorKey = actorKey })
        local pendingReturn = postWakeReturnOrigins:get(ev.npc.id)
        if home and home.position then
            sleepOriginPos = home.position
            sleepOriginRot = home.rotation or sleepOriginRot
        elseif pendingReturn and pendingReturn.origin then
            sleepOriginPos = pendingReturn.origin
            sleepOriginRot = pendingReturn.rotation or sleepOriginRot
            sdpOriginTracker.setHome(ev.npc, sleepOriginPos, sleepOriginRot, "pending_return_origin", { actorKey = actorKey })
        else
            sdpOriginTracker.setHome(ev.npc, ev.npc.position, ev.npc.rotation, "new_sleep_origin", { actorKey = actorKey })
        end
    end
    if savedOrigin and ev.interactionType == "sleeping" then
        sdpOriginTracker.setHome(ev.npc, sleepOriginPos, sleepOriginRot, "saved_interaction_origin", { actorKey = actorKey })
    end

    assignedActors[ev.npc.id] = {
        npc = ev.npc,
        object = ev.object,
        objectId = ev.objectId,
        model = ev.model,
        profile = ev.profile or {
            animation = "sdpvasitting6",
            allowPerFrameCorrection = true,
            transitionDistance = settings.transitionDistance,
            lerpDuration = settings.lerpDuration,
        },
        profileId = ev.profileId,
        interactionType = ev.interactionType or "sitting",
        schedulerArrivalPlacement = ev.schedulerArrivalPlacement == true,
        state = STATES.approaching,
        assignedCellName = ev.npc.cell and cellName(ev.npc.cell) or nil,
        slotKey = ev.slotKey,
        slotName = ev.slotName,
        slot = ev.slot,
        position = ev.hitPos,
        finalPosition = ev.finalPosition,
        bedTop = ev.bedTop or ev.sleepSurfacePosition,
        sleepObjectTopPosition = ev.sleepObjectTopPosition or ev.sleepSurfaceTopPosition,
        sleepSurfaceTopPosition = ev.sleepSurfaceTopPosition or ev.sleepObjectTopPosition,
        surfaceMode = ev.sleepSurfaceMode or ev.surfaceMode,
        surfaceSamples = ev.sleepSurfaceSamples or ev.surfaceSamples,
        sleepSurfacePosition = ev.sleepSurfacePosition or ev.bedTop or ev.hitPos,
        sleepFloorPosition = ev.sleepFloorPosition,
        approachPos = ev.approachPos or ev.hitPos,
        sleepRouteStatus = ev.sleepRouteStatus,
        sleepRouteNeedsDoorAssist = ev.sleepRouteNeedsDoorAssist == true,
        sleepRouteStartPosition = ev.sleepRouteStartPosition,
        sleepRoutePostDoorWaypoint = ev.sleepRoutePostDoorWaypoint,
        reachedValidSleepApproach = false,
        exitPosition = ev.exitPosition,
        exitPositions = ev.exitPositions,
        preInteractionPos = sleepOriginPos,
        preInteractionRot = sleepOriginRot,
        facingDirection = ev.facingDirection,
        finalRotation = ev.finalRotation,
        facingObject = ev.facingObject,
        facingObjectId = ev.facingObjectId,
        facingObjectRefId = ev.facingObjectRefId,
        facingObjectModel = ev.facingObjectModel,
        facingObjectName = ev.facingObjectName,
        facingObjectScale = ev.facingObjectScale,
        facingKind = ev.facingKind,
        facingReason = ev.facingReason,
        facingObjectPosition = ev.facingObjectPosition,
        facingCandidates = ev.facingCandidates,
        ignoredFacingObject = ev.ignoredFacingObject,
        ignoredFacingObjectId = ev.ignoredFacingObjectId,
        ignoredFacingObjectRefId = ev.ignoredFacingObjectRefId,
        ignoredFacingObjectModel = ev.ignoredFacingObjectModel,
        ignoredFacingObjectName = ev.ignoredFacingObjectName,
        ignoredFacingObjectScale = ev.ignoredFacingObjectScale,
        ignoredFacingKind = ev.ignoredFacingKind,
        ignoredFacingObjectPosition = ev.ignoredFacingObjectPosition,
        ignoredFacingCandidates = ev.ignoredFacingCandidates,
        ignoredFacingSurfaceHit = ev.ignoredFacingSurfaceHit == true,
        ignoredFacingSurfaceSource = ev.ignoredFacingSurfaceSource,
        ignoredFacingFocusDot = ev.ignoredFacingFocusDot,
        tableClearanceFocusCleared = ev.tableClearanceFocusCleared == true,
        tableClearanceFocusClearReason = ev.tableClearanceFocusClearReason,
        lectureAudienceTarget = ev.lectureAudienceTarget == true,
        lectureAudienceShortcut = ev.lectureAudienceShortcut == true,
        lectureAudienceTeleport = ev.lectureAudienceTeleport == true,
        lectureAudienceOriginPosition = ev.lectureAudienceOriginPosition,
        lectureAudienceOriginRotation = ev.lectureAudienceOriginRotation,
        lectureAudienceOriginSource = ev.lectureAudienceOriginSource,
        lecternPosition = ev.lecternPosition,
        stationPosition = ev.stationPosition,
        audienceHeadFocusPosition = ev.audienceHeadFocusPosition,
        lectureSessionId = ev.lectureSessionId,
        stationSlotKey = ev.stationSlotKey,
        audienceSource = ev.audienceSource,
        profileOffset = ev.profileOffset,
        animationOffset = ev.animationOffset,
        animationName = ev.animation,
        calibration = ev.calibration,
        fallbackUsed = ev.fallbackUsed == true,
        currentHour = ev.currentHour,
        initialPlacement = ev.initialPlacement == true,
        sleepPhase = ev.sleepPhase,
        actorBedtime = ev.actorBedtime,
        actorWakeTime = ev.actorWakeTime,
        sleepWakeBias = ev.sleepWakeBias,
        observedPlayerOverride = ev.observedPlayerOverride,
        manualAssign = ev.manualAssign == true,
        manualAssignOverrideTesting = ev.manualAssignOverrideTesting == true,
        manualAssignOverrideApplied = ev.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = ev.manualAssignOverrideReason,
        surfaceBlockerReason = ev.surfaceBlockerReason,
        surfaceBlockerOverrideReason = ev.surfaceBlockerOverrideReason,
        surfaceBlockerKind = ev.surfaceBlockerKind,
        surfaceBlockerObjectId = ev.surfaceBlockerObjectId,
        surfaceBlockerDistance = ev.surfaceBlockerDistance,
        surfaceBlockerVertical = ev.surfaceBlockerVertical,
        surfaceBlockerLocalReason = ev.surfaceBlockerLocalReason,
        softBlockerReason = ev.softBlockerReason,
        hardBlockerReason = ev.hardBlockerReason,
        calibrationAction = ev.calibrationAction == true,
        calibrationReason = ev.calibrationReason,
        calibrationTestNpc = ev.calibrationTestNpc == true,
        calibrationFill = ev.calibrationFill == true,
        calibrationFillLabel = ev.calibrationFillLabel,
        calibrationFillRole = ev.calibrationFillRole,
        calibrationFillSource = ev.calibrationFillSource,
        calibrationFillIndex = ev.calibrationFillIndex,
        calibrationFillSessionId = ev.calibrationFillSessionId,
        calibrationRuntimeObjectId = ev.calibrationRuntimeObjectId,
        actorDisplayLabel = ev.actorDisplayLabel,
        sleepAccessOverrideReason = ev.sleepAccessOverrideReason,
        releaseSafetyGateEnabled = ev.releaseSafetyGateEnabled,
        releaseSafetyGateStatus = ev.releaseSafetyGateStatus,
        releaseSafetyGateReason = ev.releaseSafetyGateReason,
        releaseSafetyGateCell = ev.releaseSafetyGateCell,
        releaseSafetyGateRegion = ev.releaseSafetyGateRegion,
        releaseSafetyGateFurnitureType = ev.releaseSafetyGateFurnitureType,
        releaseSafetyGateLabel = ev.releaseSafetyGateLabel,
        seatCategory = ev.seatCategory or ev.releaseSafetyGateFurnitureType,
        sittingStandExitPositions = ev.sittingStandExitPositions,
        sittingStandExitValidated = ev.sittingStandExitValidated == true,
        sittingForcedStandExitPositions = ev.sittingForcedStandExitPositions,
        sittingForcedStandExitValidated = ev.sittingForcedStandExitValidated == true,
        sittingForcedStandExitLog = ev.sittingForcedStandExitLog,
        sittingForcedStandExitLabel = ev.sittingForcedStandExitLabel,
        sleepSafetyReason = ev.sleepSafetyReason,
        sleepSafetyDelta = ev.sleepSafetyDelta,
        sleepSafetyLimit = ev.sleepSafetyLimit,
        sleepSafetyOverrideReason = ev.sleepSafetyOverrideReason,
        sleepCalibrationWarningReason = ev.sleepCalibrationWarningReason,
        lerpTime = nil,
        sentStartEvent = false,
        approachElapsed = 0,
        approachStuckElapsed = 0,
        lastApproachDistance = nil,
        offHoursServiceNpc = (ev.interactionType == "sitting" or ev.interactionType == "sleeping") and sdpServicePolicy.offHoursServiceReason(ev.npc, settings, profiles, types, profiles.getGameHour(), sdpActorRoles.isFactionLeader(ev.npc, types, core)) ~= nil,
    }

    if ev.interactionType == "sleeping" then
        updateSleepReservationState(ev.npc, ev.initialPlacement == true and "sleeping" or "routing", ev.initialPlacement == true and "initial_placement_accepted" or "local_accepted")
        sendCalibrationOffsets("sleeping", ev.profileOffset, ev.animationOffset, ev.calibration, ev.animation, assignedActors[ev.npc.id])
    elseif ev.interactionType == "sitting" then
        sendCalibrationOffsets("sitting", ev.profileOffset, ev.animationOffset, ev.calibration, ev.animation, assignedActors[ev.npc.id])
    end

    local focusLog, focusModelLog, focusCandidatesLog = sdpFocusMetadata.logSummary(ev)
    debugLog(
        "accepted",
        ev.npc.recordId or ev.npc.id,
        "cell", cellName(ev.npc.cell),
        "type", tostring(ev.interactionType),
        "object", tostring(ev.objectId),
        "model", tostring(ev.model),
        "profile", tostring(ev.profileId),
        "slot", tostring(ev.slotName),
        "approach", tostring(ev.approachPos),
        "route", tostring(ev.sleepRouteStatus),
        "final", tostring(ev.finalPosition or ev.hitPos),
        "rotation", tostring(ev.finalRotation),
        "focus", tostring(focusLog),
        "focusModel", tostring(focusModelLog),
        "focusCandidates", tostring(focusCandidatesLog),
        "fallback", tostring(ev.fallbackUsed),
        "hour", tostring(ev.currentHour)
    )
    infoLog(
        "accepted assignment",
        ev.npc.recordId or ev.npc.id,
        "type", tostring(ev.interactionType),
        "object", tostring(ev.objectId),
        "profile", tostring(ev.profileId),
        "slot", tostring(ev.slotName),
        "focus", tostring(focusLog),
        "focusCandidates", tostring(focusCandidatesLog),
        "initial", tostring(ev.initialPlacement == true)
    )

    local data = assignedActors[ev.npc.id]
    if not calibrationBlockerMarkerEvents.sendBlocked(world.players, data) then
        calibrationBlockerMarkerEvents.sendCleared(world.players, ev, "accepted")
    end
    if ev.calibrationAction == true then
        data.calibrationMenuHoldUntil = core.getSimulationTime() + 45
    end
    local fillOwnedAccepted = sdpCalibrationFillOwnership.isAcceptedEvent(ev)
    if not fillOwnedAccepted then
        calibrationLock.rememberTarget(data, { cellName = cellName, now = core.getSimulationTime }, ev.initialPlacement and "initial_placement" or "accepted")
    end
    if ev.manualAssign == true and not fillOwnedAccepted then
        calibrationLock.rememberTarget(data, { cellName = cellName, now = core.getSimulationTime }, "manual_assign")
        infoLog("nearest_manual_assign_set_calibration_target", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("nearest_manual_assign_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("calibration_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "label", calibrationLock.sessionLabel(data))
        infoLog("reassign_target_reached", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("nearest_manual_assign_status", "accepted", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "override", tostring(ev.manualAssignOverrideApplied == true), "overrideReason", tostring(ev.manualAssignOverrideReason))
        sendCalibrationMenuStatus("Assign Nearest target confirmed.", ev.interactionType, calibrationLock.sessionLabel(data), false, sdpCalibrationStatusExtraFromAssignment(data, {
            testingOverride = ev.manualAssignOverrideApplied == true,
            testingOverrideReason = ev.manualAssignOverrideReason,
        }))
    end
    if ev.interactionType == "sitting" then
        rememberSittingAssignment(data, ev.initialPlacement and "initial_placement" or "accepted")
    end
    if data.lectureAudienceTarget == true then
        if not data.lectureAudienceOriginPosition then
            data.lectureAudienceOriginPosition = data.preInteractionPos or (ev.npc and ev.npc.position)
            data.lectureAudienceOriginRotation = data.preInteractionRot or (ev.npc and ev.npc.rotation)
            data.lectureAudienceOriginSource = "assignment_accept_origin"
        end
        sdpLectureTrace.log(
            debugLog,
            "audience_origin_captured",
            "actor", tostring(ev.npc.recordId or ev.npc.id),
            "station", tostring(data.stationSlotKey),
            "object", tostring(data.objectId),
            "slot", tostring(data.slotName),
            "source", tostring(data.lectureAudienceOriginSource),
            "origin", tostring(data.lectureAudienceOriginPosition),
            "teleport", tostring(data.lectureAudienceTeleport == true)
        )
    end
    if ev.initialPlacement == true and ev.interactionType == "sleeping" and ev.finalPosition and not fillOwnedAccepted then
        data.npcStandingPos = nil
        data.npcStandingRot = ev.npc.rotation
        data.exitPosition = ev.exitPosition or ev.approachPos
        sleepRouteDoors.closeForNpc(ev.npc.id, "sleep_entry")
        data.state = STATES.interacting
        data.interactionStartedAt = core.getSimulationTime()
        data.sentStartEvent = true
        data.usedSleepEntrySnap = true
        data.sleepExternalDisplacementGraceUntil = core.getSimulationTime() + 1.5
        data.lerpTime = 1

        local targetAngle = targetYawForData(ev.npc, data)

        local sane, sanityReason, sanityDelta, sanityLimit = sleepFinalPlacementSane(ev.npc, data, ev.finalPosition, "sleep_initial_placement")
        if not sane then
            debugLog(
                "sleep initial placement rejected",
                ev.npc.recordId or ev.npc.id,
                "reason", tostring(sanityReason),
                "object", tostring(ev.objectId),
                "delta", tostring(sanityDelta),
                "limit", tostring(sanityLimit),
                "final", tostring(ev.finalPosition),
                "approach", tostring(ev.approachPos)
            )
            sleepLightControl.unregisterSleeper(ev.npc, sanityReason or "sleep_initial_placement_rejected", true)
            sleepLightControl.processPending(true)
            stopInteractionForNpc(ev.npc, sanityReason or "sleep_initial_placement_rejected")
            if wasInitialHandoff and settleInitialPlacementOverlay then settleInitialPlacementOverlay("sleep_initial_placement_rejected", ev.npc) end
            return
        end

        local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(targetAngle, ev.npc.rotation) })
        if not ok then
            debugLog("sleep initial placement failed", ev.npc.recordId or ev.npc.id, tostring(err))
            stopInteractionForNpc(ev.npc, "sleep_initial_placement_failed")
            if wasInitialHandoff and settleInitialPlacementOverlay then settleInitialPlacementOverlay("sleep_initial_placement_failed", ev.npc) end
            return
        end

        if ev.suppressInitialPlacementOverlay ~= true then
            calibrationLock.notifyDisguiseInitialPlacement(ev.npc, "sleeping", "sleep_initial_placement", {
                settings = settings,
                world = world,
                duration = 0.62,
                holdDuration = 0.65,
                object = ev.object,
                objectId = ev.objectId,
                finalPosition = ev.finalPosition,
            })
        end
        notifyPlayersSleepingState(ev.npc, true, "sleep_initial_placement")
        sleepLightControl.registerSleeper(ev.npc, {
            object = ev.object,
            bed = ev.object,
            bedId = ev.objectId,
            finalPosition = ev.finalPosition,
            position = ev.finalPosition,
            exitPosition = ev.exitPosition,
            approachPosition = ev.approachPos,
            originPosition = data.preInteractionPos or ev.preInteractionPos,
            initialPlacement = true,
            visibleSleep = false,
        }, true)
        if settleInitialPlacementOverlay then settleInitialPlacementOverlay("sleep_initial_placement_done", ev.npc) end

        debugLog(
            "sleep_initial_placement",
            ev.npc.recordId or ev.npc.id,
            "object", tostring(ev.objectId),
            "profile", tostring(ev.profileId),
            "hour", tostring(ev.currentHour),
            "bedtime", tostring(ev.actorBedtime),
            "wake", tostring(ev.actorWakeTime),
            "phase", tostring(ev.sleepPhase)
        )

        ev.npc:sendEvent('StartInteractionAnimation', {
            interactionType = ev.interactionType,
            animation = data.profile.animation,
            animationOptions = data.profile.animationOptions,
            forceReplay = true,
            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
        })
        return
    end

    if ev.initialPlacement == true and ev.interactionType == "sitting" and ev.finalPosition and not fillOwnedAccepted then
        data.npcStandingPos = (sdpSittingStandExit and sdpSittingStandExit.primary(data, util)) or ev.approachPos or ev.npc.position
        data.npcStandingRot = ev.npc.rotation
        sleepRouteDoors.closeForNpc(ev.npc.id, "sleep_entry")
        data.state = STATES.interacting
        data.interactionStartedAt = core.getSimulationTime()
        data.sentStartEvent = true
        data.lerpTime = 1

        local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(ev.finalRotation or ev.npc.rotation:getYaw(), ev.npc.rotation) })
        if not ok then
            debugLog("sitting initial placement failed", ev.npc.recordId or ev.npc.id, tostring(err))
            stopInteractionForNpc(ev.npc, "sitting_initial_placement_failed")
            if wasInitialHandoff and settleInitialPlacementOverlay then settleInitialPlacementOverlay("sitting_initial_placement_failed", ev.npc) end
            return
        end

        -- Sitting initial placement is allowed for out-of-sight/remembered seats,
        -- but it should not request or hold the black load cover. Start the pose
        -- immediately after the snap so visible seats do not show a standing flash.
        scheduleSittingLifecycle(data, "initial_placement")
        debugLog("sitting initial placement", ev.npc.recordId or ev.npc.id, "object", tostring(ev.objectId), "profile", tostring(ev.profileId))
        ev.npc:sendEvent('StartInteractionAnimation', {
            interactionType = ev.interactionType,
            animation = data.profile.animation,
            animationOptions = data.profile.animationOptions,
            forceReplay = true,
            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
        })
        return
    end

    if ev.calibrationFill == true and ev.calibrationTestNpc == true and ev.interactionType == "sleeping" and ev.finalPosition then
        local sane, sanityReason, sanityDelta, sanityLimit = sleepFinalPlacementSane(ev.npc, data, ev.finalPosition, "calibration_fill")
        if sane then
            local targetAngle = targetYawForData(ev.npc, data)
            local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(targetAngle, ev.npc.rotation) })
            if ok then
                sleepRouteDoors.closeForNpc(ev.npc.id, "calibration_fill")
                data.npcStandingPos = nil
                data.npcStandingRot = ev.npc.rotation
                data.exitPosition = ev.exitPosition or ev.approachPos
                data.state = STATES.interacting
                data.interactionStartedAt = core.getSimulationTime()
                data.usedSleepEntrySnap = true
                data.sleepExternalDisplacementGraceUntil = core.getSimulationTime() + 1.5
                data.sentStartEvent = false
                data.pendingStartEvent = true
                data.startEventDelay = data.profile.sleepStartAnimationDelay or 0.25
                data.lerpTime = 1
                updateSleepReservationState(ev.npc, "sleeping", "calibration_fill_snap")
                notifyPlayersSleepingState(ev.npc, true, "calibration_fill_snap")
                sleepLightControl.registerSleeper(ev.npc, {
                    object = ev.object,
                    bed = ev.object,
                    bedId = ev.objectId,
                    finalPosition = ev.finalPosition,
                    position = ev.finalPosition,
                    exitPosition = ev.exitPosition,
                    approachPosition = ev.approachPos,
                    originPosition = data.preInteractionPos or ev.preInteractionPos,
                    initialPlacement = data.initialPlacement == true,
                    visibleSleep = data.initialPlacement ~= true,
                }, false)
                debugLog("sleep calibration fill snap", ev.npc.recordId or ev.npc.id, "object", tostring(ev.objectId), "profile", tostring(ev.profileId), "slot", tostring(ev.slotName))
                return
            end
            if not deferTeleportFailure(data, err, "sleep_calibration_fill_snap") then
                debugLog("sleep calibration fill snap failed", ev.npc.recordId or ev.npc.id, tostring(err))
            end
        else
            debugLog(
                "sleep calibration fill snap rejected",
                ev.npc.recordId or ev.npc.id,
                "reason", tostring(sanityReason),
                "object", tostring(ev.objectId),
                "delta", tostring(sanityDelta),
                "limit", tostring(sanityLimit),
                "final", tostring(ev.finalPosition),
                "approach", tostring(ev.approachPos)
            )
        end
    end

    if ev.calibrationFill == true and ev.calibrationTestNpc == true and ev.interactionType == "sitting" and ev.finalPosition then
        local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(ev.finalRotation or ev.npc.rotation:getYaw(), ev.npc.rotation) })
        if ok then
            data.npcStandingPos = (sdpSittingStandExit and sdpSittingStandExit.acceptedExitPosition(data, util, ev)) or ev.approachPos or ev.npc.position
            data.npcStandingRot = ev.npc.rotation
            data.state = STATES.interacting
            data.interactionStartedAt = core.getSimulationTime()
            data.sentStartEvent = true
            data.lerpTime = 1
            scheduleSittingLifecycle(data, "calibration_fill_snap")
            debugLog("sitting calibration fill snap", ev.npc.recordId or ev.npc.id, "object", tostring(ev.objectId), "profile", tostring(ev.profileId), "slot", tostring(ev.slotName))
            ev.npc:sendEvent('StartInteractionAnimation', {
                interactionType = ev.interactionType,
                animation = data.profile.animation,
                animationOptions = data.profile.animationOptions,
                forceReplay = true,
                audienceHeadFocusPosition = data.audienceHeadFocusPosition,
            })
            return
        end
        if not deferTeleportFailure(data, err, "sitting_calibration_fill_snap") then
            debugLog("sitting calibration fill snap failed", ev.npc.recordId or ev.npc.id, tostring(err))
        end
    end

    if ev.lectureAudienceTeleport == true and ev.interactionType == "sitting" and ev.finalPosition then
        local targetCell = ev.npc and ev.npc.cell or ev.object and ev.object.cell
        local priorStandingPos = data.npcStandingPos or data.approachPos or data.preInteractionPos or ev.approachPos
        local priorStandingRot = data.npcStandingRot or data.preInteractionRot or ev.npc.rotation
        sdpLectureTrace.log(
            debugLog,
            "audience_immediate_snap_attempted",
            "actor", tostring(ev.npc and (ev.npc.recordId or ev.npc.id)),
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName),
            "station", tostring(ev.stationSlotKey),
            "targetCell", tostring(targetCell ~= nil)
        )
        if not targetCell then
            sdpLectureTrace.log(debugLog, "audience_immediate_snap_failed", "actor", tostring(ev.npc and (ev.npc.recordId or ev.npc.id)), "reason", "missing_target_cell")
        else
        local ok, err = tryTeleport(ev.npc, targetCell, ev.finalPosition, { rotation = rotationFromYaw(ev.finalRotation or ev.npc.rotation:getYaw(), ev.npc.rotation) })
        if ok then
            data.npcStandingPos = (sdpSittingStandExit and sdpSittingStandExit.primary(data, util)) or priorStandingPos
            data.npcStandingRot = priorStandingRot
            data.state = STATES.interacting
            data.interactionStartedAt = core.getSimulationTime()
            data.sentStartEvent = true
            data.lerpTime = 1
            scheduleSittingLifecycle(data, "lecture_audience_teleport_snap")
            infoLog("lecture audience teleport snap", ev.npc.recordId or ev.npc.id, "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "station", tostring(ev.stationSlotKey))
            sdpLectureTrace.log(debugLog, "audience_immediate_snap_succeeded", "actor", tostring(ev.npc.recordId or ev.npc.id), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "station", tostring(ev.stationSlotKey))
            ev.npc:sendEvent('StartInteractionAnimation', {
                interactionType = ev.interactionType,
                animation = data.profile.animation,
                animationOptions = data.profile.animationOptions,
                forceReplay = true,
                audienceHeadFocusPosition = data.audienceHeadFocusPosition,
            })
            return
        end
        if not deferTeleportFailure(data, err, "lecture_audience_teleport_snap") then
            debugLog("lecture audience teleport snap failed", ev.npc.recordId or ev.npc.id, tostring(err))
            sdpLectureTrace.log(debugLog, "audience_immediate_snap_failed", "actor", tostring(ev.npc.recordId or ev.npc.id), "reason", tostring(err))
        end
        end
    end

    if ev.manualAssign == true and ev.interactionType == "sitting" and ev.finalPosition then
        data.npcStandingPos = nil
        data.npcStandingRot = ev.npc.rotation
        data.state = STATES.interacting
        data.interactionStartedAt = core.getSimulationTime()
        data.sentStartEvent = true
        data.lerpTime = 1

        local ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.finalPosition, { rotation = rotationFromYaw(ev.finalRotation or ev.npc.rotation:getYaw(), ev.npc.rotation) })
        if ok then
            scheduleSittingLifecycle(data, "manual_assign_snap")
            debugLog("sitting manual assignment snap", ev.npc.recordId or ev.npc.id, "object", tostring(ev.objectId), "profile", tostring(ev.profileId))
            ev.npc:sendEvent('StartInteractionAnimation', {
                interactionType = ev.interactionType,
                animation = data.profile.animation,
                animationOptions = data.profile.animationOptions,
                forceReplay = true,
                audienceHeadFocusPosition = data.audienceHeadFocusPosition,
            })
            return
        end

        data.state = STATES.approaching
        data.sentStartEvent = false
        data.lerpTime = nil
        debugLog("sitting manual assignment snap failed", ev.npc.recordId or ev.npc.id, tostring(err))
    end

    if ev.interactionType == "sleeping" then
        local approach = data.approachPos or data.position
        if approach then
            local distance = (ev.npc.position - approach):length()
            local transitionDistance = data.profile.transitionDistance or settings.transitionDistance
            if distance < transitionDistance then
                data.reachedValidSleepApproach = true
                debugLog(
                    "sleep immediate entry from accepted local",
                    ev.npc.recordId or ev.npc.id,
                    "object", tostring(ev.objectId),
                    "approach", tostring(approach),
                    "distance", tostring(distance),
                    "threshold", tostring(transitionDistance)
                )
                beginTransition(ev.npc, data, "reached_approach")
                return
            end
        end
    end

    local initialTravel = sdpSleepRouteStartTravel.packageForAcceptedSleep(ev, data)
    if initialTravel.usedDoorStage == true then
        debugLog(
            "sleep route initial door stage travel",
            ev.npc.recordId or ev.npc.id,
            "target", tostring(initialTravel.destPosition),
            "approach", tostring(data.approachPos),
            "postDoorWaypoint", tostring(data.sleepRoutePostDoorWaypoint)
        )
    end
    initialTravel.usedDoorStage = nil
    ev.npc:sendEvent('SitDownPleaseStartAIPackage', initialTravel)
end

stopInteractionForNpc = function(npc, reason, expectedNpcId)
    if not npc or not npc.id then return end
    if expectedNpcId and tostring(npc.id) ~= tostring(expectedNpcId) then
        debugLog("teleport_failed_actor_mismatch_blocked", "expected", tostring(expectedNpcId), "actual", tostring(npc.id), "reason", tostring(reason))
        return
    end

    local data = assignedActors[npc.id]
    if reason == "teleport_failed" and data and data.npc and data.npc.id and tostring(data.npc.id) ~= tostring(npc.id) then
        debugLog("teleport_failed_actor_mismatch_blocked", "expected", tostring(data.npc.id), "actual", tostring(npc.id), "reason", tostring(reason))
        return
    end
    if calibrationHoldActive(data) then
        local text = tostring(reason or "")
        local protected = text == "teleport_failed"
            or text == "sitting_lifecycle_change_seat"
            or text == "sitting_lifecycle_return_origin"
            or text == "off_hours_service_window_ended"
            or text == "scheduled_wake_time"
            or text == "sleep_window_ended"
            or text == "sleeping_disturbed_by_close_player"
            or text == "sleeping_disturbed_by_close_sneaking_player"
            or text == "sleeping_disturbed_by_invisible_close_player"
        if protected then
            debugLog("calibration hold blocked stop", npc.recordId or npc.id, tostring(reason), "type", tostring(data.interactionType), "until", tostring(data.calibrationMenuHoldUntil))
            if data.interactionType == "sitting" then
                deferSittingLifecycle(data, 30)
            end
            return
        end
    end
    if data and data.interactionType == "sitting" then
        local validatedExits = data.sittingStandExitValidated == true and data.sittingStandExitPositions or nil
        if not (validatedExits and #validatedExits > 0) then
            local forcedRelease = sdpSittingStandExit
                and sdpSittingStandExit.isForcedRelease
                and sdpSittingStandExit.isForcedRelease(reason, data) == true
            local forcedExits = data.sittingForcedStandExitValidated == true and data.sittingForcedStandExitPositions or nil
            if forcedRelease and forcedExits and #forcedExits > 0 then
                data.sittingStandExitPositions = forcedExits
                data.sittingStandExitValidated = true
                if data.sittingForcedStandExitLog then
                    if data.sittingForcedStandExitLog == "stand_exit_emergency_origin" then
                        debugLog("stand_exit_no_safe_candidate", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName), "forced", "true")
                    end
                    debugLog(
                        data.sittingForcedStandExitLog,
                        npc.recordId or npc.id,
                        "reason", tostring(reason),
                        "label", tostring(data.sittingForcedStandExitLabel),
                        "object", tostring(data.objectId),
                        "slot", tostring(data.slotName)
                    )
                end
            elseif forcedRelease and data.preInteractionPos then
                debugLog("stand_exit_no_safe_candidate", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName), "forced", "true")
                debugLog("stand_exit_emergency_origin", npc.recordId or npc.id, "reason", tostring(reason), "origin", tostring(data.preInteractionPos), "object", tostring(data.objectId), "slot", tostring(data.slotName))
                data.sittingStandExitPositions = { data.preInteractionPos }
                data.sittingStandExitValidated = true
            elseif forcedRelease then
                debugLog("stand_exit_no_safe_candidate", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName), "forced", "true")
                debugLog("stand_exit_forced_release_failed", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName))
                deferSittingLifecycle(data, 10)
                return
            else
                local now = core.getSimulationTime()
                if not data.lastStandExitRetryLogAt or now - data.lastStandExitRetryLogAt > 10 then
                    data.lastStandExitRetryLogAt = now
                    debugLog("stand_exit_no_safe_candidate", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName), "forced", "false")
                    debugLog("stand_exit_retry_later", npc.recordId or npc.id, "reason", tostring(reason), "object", tostring(data.objectId), "slot", tostring(data.slotName))
                end
                deferSittingLifecycle(data, 30)
                return
            end
        end
    end
    assignedActors[npc.id] = nil
    calibrationBlockerMarkerEvents.sendCleared(world.players, { npc = npc }, reason or "assignment_stopped")
    if tostring(reason or "") == "dead_actor" then
        if postWakeReturnOrigins and postWakeReturnOrigins.clear then postWakeReturnOrigins:clear(npc.id) end
        if sleepRouteDoors and sleepRouteDoors.closeForNpc then sleepRouteDoors.closeForNpc(npc.id, "dead_actor") end
        infoLog("assignment released dead_actor", npc.recordId or npc.id, "type", tostring(data and data.interactionType), "slot", tostring(data and data.slotKey))
    end
    local wakeSummaryReturnOrigin = nil

    if data and data.slotKey then
        occupiedSlots[data.slotKey] = nil
    end

    if data and data.interactionType == "sleeping" then
        if sleepRouteRejection.isRouteRejectReason(reason) then
            markSleepRouteRejected(npc, data.slotKey, reason)
            releaseSleepReservationBySlot(data.slotKey, reason or "sleep_route_rejected", sleepReservationNpcId(npc))
        elseif tostring(reason or ""):find("active_", 1, true) == 1 then
            markSleepReservationFailed(npc, data.slotKey, reason)
        else
            releaseSleepReservationBySlot(data.slotKey, reason or "sleep_stop", sleepReservationNpcId(npc))
        end
    end

    if data and data.interactionType == "sleeping" and shouldDelaySleepAfterWake(reason) then
        setSleepWakeRetryCooldown(npc, reason)
        if reason == "activated_by_player_dialogue" and data.preInteractionPos then
            postWakeReturnOrigins:set(npc.id, {
                npc = npc,
                origin = data.preInteractionPos,
                rotation = data.preInteractionRot,
                reason = reason,
                keepTrying = true,
                maxAttempts = 20,
                retryAfterMaxAttempts = 15,
                completionRadius = 16,
                exactOnComplete = true,
            })
        end
    end

    if data then
        local standPositions = {}
        local returnOriginPosition = nil
        local wakeExitWalkPosition = nil
        local suppressStandExitTeleport = data.teleportBusyTimedOut == true and tostring(reason or "") == "teleport_failed"

        if data.interactionType == "sitting" and reason == "sitting_lifecycle_change_seat" then
            clearSittingMemoryFor(npc, reason)
            setSittingCooldown(npc, 45, reason)
            pendingSittingReassignments[npc.id] = {
                npc = npc,
                due = core.getSimulationTime() + 0.35,
                avoidSlotKey = data.slotKey,
                source = reason,
            }
        elseif data.interactionType == "sitting"
            and (reason == "sitting_lifecycle_return_origin" or reason == "off_hours_service_window_ended")
            and data.preInteractionPos then
            clearSittingMemoryFor(npc, reason)
            returnOriginPosition = data.preInteractionPos
            setSittingCooldown(npc, nil, reason)
            local idleDest = reason == "off_hours_service_window_ended" and nil or findBriefIdleWalkDestination(npc, data.preInteractionPos)
            if idleDest then
                sittingOriginReturns:set(npc.id, {
                    npc = npc,
                    origin = data.preInteractionPos,
                    idleDest = idleDest,
                    due = core.getSimulationTime() + 0.5,
                    timeout = SITTING_IDLE_WALK_TIMEOUT,
                    stage = "returning",
                    reason = reason,
                })
            end
        end

        if suppressStandExitTeleport then
            debugLog(
                "stand teleport skipped",
                npc.recordId or npc.id,
                tostring(reason),
                "reason", "teleport_busy_timeout",
                "context", tostring(data.teleportBusyTimeoutContext)
            )
        elseif data.interactionType == "sleeping" then
            local hasEnteredBed = data.usedSleepEntrySnap == true
                or data.state == STATES.transitioning
                or data.state == STATES.interacting

            if isExternalSleepReleaseReason(reason) then
                if hasEnteredBed and sdpExternalAiTakeover.sleepReleaseShouldUseBedsideExit(reason) then
                    -- Real external movement should win, but starting that movement
                    -- from an SDP bed pose can leave the actor at a bad Z/navmesh
                    -- point. Move only to a vetted bedside/floor exit, then let the
                    -- preserved external package continue. For bunks, prefer the
                    -- proven approach floor before side exits; side exits on stacked
                    -- beds can be outside the room shell in tight interiors.
                    if sdpSleepCore.isBunkProfile(data.profile) or tostring(data.objectId or data.objectRecordId or ''):lower():find('bunk', 1, true) ~= nil then
                        addUniquePosition(standPositions, data.approachPos)
                    end
                    addUniquePosition(standPositions, data.exitPosition)
                    if data.exitPositions then
                        for _, pos in ipairs(data.exitPositions) do addUniquePosition(standPositions, pos) end
                    end
                    addUniquePosition(standPositions, data.npcStandingPos)
                    debugLog(
                        "sleep external release bedside safe exit",
                        npc.recordId or npc.id,
                        "reason", tostring(reason),
                        "exits", tostring(#standPositions),
                        "final", tostring(data.finalPosition)
                    )
                else
                    -- Another mod has already taken ownership of the actor's
                    -- placement, or the actor never entered the bed pose. Release
                    -- SDP animation/light/reservation state without moving them.
                    debugLog(
                        "sleep external release no exit correction",
                        npc.recordId or npc.id,
                        "reason", tostring(reason),
                        "origin", tostring(data.preInteractionPos),
                        "final", tostring(data.finalPosition)
                    )
                end
            elseif not hasEnteredBed then
                -- Route/validation abort while the NPC is still walking to bed: do
                -- not use bedside exits or original-position correction teleports.
                -- The actor is not in the sleep pose yet, so any forced exit point
                -- would itself be a visible wall-warp toward the bed.
                debugLog(
                    "sleep_entry_rejected",
                    npc.recordId or npc.id,
                    "reason", tostring(reason),
                    "state", tostring(data.state),
                    "object", tostring(data.objectId),
                    "action", "not_in_bed_no_exit"
                )
            else
                if sdpSleepCore.shouldUseWakeExitWalk(reason, data) then
                    -- Player wake should not hard-teleport the actor from prone pose
                    -- to the bedside floor. Let the local script stop the sleep pose,
                    -- then make the actor walk from the bed to the selected side exit
                    -- before deferred dialogue opens. Keep the normal stand-exit
                    -- candidates as a fallback in case that walk exit is unsafe.
                    wakeExitWalkPosition = data.exitPosition
                    addUniquePosition(standPositions, data.exitPosition)
                    if data.exitPositions then
                        for _, pos in ipairs(data.exitPositions) do addUniquePosition(standPositions, pos) end
                    end
                    addUniquePosition(standPositions, data.npcStandingPos)
                else
                    -- Morning/time-advance wake must place the actor on a valid floor
                    -- exit near the bed, never directly on the stored origin or on top
                    -- of the mattress. If appropriate, the actor then walks to the
                    -- stored pre-sleep origin/idle point. For bunks, use the already
                    -- route-validated approach floor first; do not trust a lateral
                    -- bunk side exit until safer candidates have failed.
                    if sdpSleepCore.isBunkProfile(data.profile) or tostring(data.objectId or data.objectRecordId or ''):lower():find('bunk', 1, true) ~= nil then
                        addUniquePosition(standPositions, data.approachPos)
                    end
                    addUniquePosition(standPositions, data.exitPosition)
                    if data.exitPositions then
                        for _, pos in ipairs(data.exitPositions) do addUniquePosition(standPositions, pos) end
                    end
                    addUniquePosition(standPositions, data.npcStandingPos)
                end

                if shouldWalkToOriginAfterWake(reason) and data.preInteractionPos then
                    returnOriginPosition = data.preInteractionPos
                    wakeSummaryReturnOrigin = returnOriginPosition
                    postWakeReturnOrigins:set(npc.id, {
                        npc = npc,
                        origin = data.preInteractionPos,
                        rotation = data.preInteractionRot,
                        reason = reason,
                        keepTrying = true,
                        maxAttempts = 20,
                        retryAfterMaxAttempts = 15,
                        completionRadius = 16,
                        exactOnComplete = true,
                        nextAttemptAt = core.getSimulationTime() + 0.75,
                        maxNoProgressAttempts = 3,
                    })
                    if largeTimeAdvanceThisUpdate == true then
                        debugLog("wake time-advance bedside exit requested", npc.recordId or npc.id, tostring(reason), "origin", tostring(data.preInteractionPos))
                    end
                elseif not wakeExitWalkPosition and data.profile and data.profile.sleepReturnToOriginFallback ~= false then
                    -- Only use origin as a last fallback for non-wake cleanup; never
                    -- use it as the first visible wake exit.
                    addUniquePosition(standPositions, data.preInteractionPos)
                end
            end
        elseif data.interactionType == "sitting" then
            local suppressAudienceHiddenStandExit = sdpLectureAudienceRelease
                and sdpLectureAudienceRelease.shouldSuppressStandExitAfterHiddenReturn
                and sdpLectureAudienceRelease.shouldSuppressStandExitAfterHiddenReturn(data, reason)
            if suppressAudienceHiddenStandExit then
                sdpLectureTrace.log(
                    debugLog,
                    "audience_release_hidden_origin_stand_exit_suppressed",
                    "actor", tostring(npc.recordId or npc.id),
                    "station", tostring(data.stationSlotKey),
                    "origin", tostring(data.preInteractionPos)
                )
            else
                local exits = data.sittingStandExitValidated == true and data.sittingStandExitPositions or nil
                if exits then
                    for _, pos in ipairs(exits) do addUniquePosition(standPositions, pos) end
                end
                if data.lectureAudienceReturnMode == "origin_walk" then
                    sdpLectureTrace.log(
                        debugLog,
                        "audience_release_safe_stand_exit",
                        "actor", tostring(npc.recordId or npc.id),
                        "station", tostring(data.stationSlotKey),
                        "exitCount", tostring(#standPositions),
                        "origin", tostring(returnOriginPosition)
                    )
                end
            end
        end

        if wakeExitWalkPosition then
            if not wakeExit.queueWakeExitWalk(npc, wakeExitWalkPosition, reason, sdpWithSleepWakeExitOptions({
                timeout = 6.0,
                radius = 80,
                maxNudges = 1,
                firstNudgeAfter = 2.5,
                interactionType = data.interactionType,
                finalPosition = data.finalPosition,
            }, data)) then
                wakeExitWalkPosition = nil
                debugLog("wake exit walk fallback to stand teleport", npc.recordId or npc.id, tostring(reason))
            end
        end

        if not wakeExitWalkPosition and #standPositions > 0 then
            local standRotation = data.npcStandingRot or data.preInteractionRot or npc.rotation
            local queued = wakeExit.queueStandTeleport(sdpWithSleepWakeExitOptions({
                npc = npc,
                positions = standPositions,
                index = 1,
                rotation = standRotation,
                reason = reason,
                interactionType = data.interactionType,
                finalPosition = data.finalPosition,
                returnOriginPosition = returnOriginPosition,
                returnOriginRotation = data.preInteractionRot,
                clearSleepHomeOnSuccess = data.interactionType == "sleeping" and shouldWalkToOriginAfterWake(reason) and not returnOriginPosition,
            }, data))
            if queued then
                wakeExit.tryImmediateStandTeleportForNpc(npc.id)
            end
        end
    end

    if data and data.interactionType == "sleeping" then
        wakeExit.markPendingWakeCleanup(npc, reason)
        debugLog(
            "wake summary",
            npc.recordId or npc.id,
            "reason", tostring(reason),
            "origin", tostring(data.preInteractionPos),
            "exit", tostring(data.exitPosition),
            "returnOrigin", tostring(wakeSummaryReturnOrigin),
            "hour", tostring(profiles.getGameHour())
        )

        local immediateLightRestore = sdpSleepCore.isPlayerVisibleWakeReason(reason)
            or reason == "settings_disabled"
            or reason == "cell_change"
            or reason == "cleanup"
            or isExternalSleepReleaseReason(reason)
        if isCurrentTimeInSleepWindow()
            and not shouldWalkToOriginAfterWake(reason)
            and reason ~= "settings_disabled"
            and reason ~= "cell_change"
            and reason ~= "cleanup"
            and sleepLightControl.holdRestores
        then
            sleepLightControl.holdRestores(reason or "night_sleep_release", 180)
        end
        sleepLightControl.unregisterSleeper(npc, reason, immediateLightRestore)
        if immediateLightRestore then sleepLightControl.processPending(true) end
        notifyPlayersSleepingState(npc, false, reason)
    end

    if data and data.interactionType == "sleeping" then
        sleepRouteDoors.closeForNpc(npc.id, reason)
    end
    debugLog("stop", npc.recordId or npc.id, "reason", tostring(reason), "type", data and data.interactionType or "<none>")
    npc:sendEvent('StopInteractionObject', {
        reason = reason,
        interactionType = data and data.interactionType or nil,
        forceClearSleepAnimation = data and (data.interactionType == "sleeping" or data.interactionType == "sitting") or false,
    })
    local walkItem = npc and npc.id and wakeExit.getWakeExitWalkForNpc(npc.id) or nil
    if walkItem and walkItem.destPosition then
        npc:sendEvent('SitDownPleaseStartAIPackage', {
            type = "Travel",
            destPosition = walkItem.destPosition,
            isRepeat = false,
            cancelOther = true,
        })
    end
end

local function onCancelInteractionForNpc(ev)
    local npc = ev and ev.npc
    local npcId = ev and ev.npcId
    if (not isObjValid(npc)) and npcId and assignedActors[npcId] then
        npc = assignedActors[npcId].npc
    end
    if not isObjValid(npc) and ev and ev.recordId then
        for id, data in pairs(assignedActors) do
            if data and data.npc and tostring(data.npc.recordId or "") == tostring(ev.recordId) then
                npc = data.npc
                npcId = id
                break
            end
        end
    end
    if isObjValid(npc) then
        if sdpStationAssignments and sdpStationAssignments.stationDataForNpc and sdpStationAssignments.stationDataForNpc(npc) then
            sdpStationAssignments.releaseForNpc(npc, ev and ev.reason or "cancelled", sdpStationRuntimeContext(0, true, false, nil))
        end
        local active = npc and npc.id and assignedActors[npc.id] or nil
        if active and ev and ev.sittingStandExitValidated == true then
            active.sittingStandExitPositions = ev.sittingStandExitPositions
            active.sittingStandExitValidated = true
        end
        if active and ev and ev.sittingForcedStandExitValidated == true then
            active.sittingForcedStandExitPositions = ev.sittingForcedStandExitPositions
            active.sittingForcedStandExitValidated = true
            active.sittingForcedStandExitLog = ev.sittingForcedStandExitLog
            active.sittingForcedStandExitLabel = ev.sittingForcedStandExitLabel
        end
        stopInteractionForNpc(npc, ev and ev.reason or "cancelled")
    elseif npcId and assignedActors[npcId] then
        releaseSleepReservationForNpc(npcId, ev and ev.reason or "cancel_invalid_actor")
        assignedActors[npcId] = nil
        wakeExit.clearStandAndWakeForNpc(npcId)
        sleepRouteDoors.closeForNpc(npcId, ev and ev.reason or "cancelled")
        clearRelevantObjectCache("cancel_invalid_actor")
    end
end

local function forceNpcToBedNow(npc, source)
    if not npc or not npc.id or not npc.cell then
        debugLog("debug go-to-bed rejected", tostring(source or "console"), "missing_npc_or_cell")
        return
    end
    local dead, deadReason = actorDeadReason(npc)
    if dead then
        debugLog("debug go-to-bed rejected", tostring(source or "console"), npc.recordId or npc.id, tostring(deadReason))
        return
    end

    if assignedActors[npc.id] then
        stopInteractionForNpc(npc, "debug_force_bed_rescan")
        wakeExit.clearStandAndWakeForNpc(npc.id)
    end

    local candidates = buildCandidateSlots(npc.cell, "sleeping", { ignoreTimeGate = true })
    local candidate = chooseCandidateForNpc(npc, candidates, "sleeping", { debugForce = true })
    if not candidate then
        debugLog("debug go-to-bed no bed", npc.recordId or npc.id, "cell", cellName(npc.cell), "source", tostring(source or "console"))
        return
    end

    candidate = profiles.shallowCopy(candidate)
    candidate.initialPlacement = false
    candidate.sleepPhase = "debug_forced"
    candidate.actorBedtime = profiles.getGameHour()
    candidate.actorWakeTime = nil
    candidate.sleepWakeBias = 0
    candidate.debugForced = true
    candidate.ignoreTimeGate = true

    debugLog(
        "debug go-to-bed assign",
        npc.recordId or npc.id,
        "cell", cellName(npc.cell),
        "object", tostring(candidate.objectId),
        "profile", tostring(candidate.profileId),
        "source", tostring(source or "console")
    )

    sendConsiderInteraction(npc, candidate)
end

local function onTryStartInteraction(ev)
    if not ev or not ev.npc or not ev.npc.cell then return end
    local interactionType = ev.interactionType or ev.type
    if not profiles.INTERACTION_TYPES[interactionType] then
        debugLog("tryStartInteraction rejected unsupported interaction", tostring(interactionType))
        return
    end
    if not profiles.isInteractionEnabled(settings, interactionType) then
        debugLog("tryStartInteraction rejected disabled interaction", tostring(interactionType))
        return
    end
    local dead, deadReason = actorDeadReason(ev.npc)
    if dead then
        debugLog("skip npc", ev.npc.recordId or ev.npc.id, "type", tostring(interactionType), "reason", tostring(deadReason))
        return
    end

    local candidates = buildCandidateSlots(ev.npc.cell, interactionType)
    local candidate = chooseCandidateForNpc(ev.npc, candidates, interactionType, nil)
    if candidate then
        sendConsiderInteraction(ev.npc, candidate)
    else
        debugLog("tryStartInteraction found no candidate", ev.npc.recordId or ev.npc.id, tostring(interactionType))
    end
end

local function externalSleepDisplacementReason(npcId, npc, data)
    if not (npc and data and data.interactionType == "sleeping") then return nil end
    if data.state ~= STATES.interacting then return nil end
    if data.calibrationAction == true or calibrationHoldActive(data) then return nil end
    if wakeExit.hasPendingStandTeleport(npcId) or wakeExit.hasPendingWakeExitWalk(npcId) then return nil end

    local currentCellName = npc.cell and cellName(npc.cell) or nil
    if data.assignedCellName and currentCellName and currentCellName ~= data.assignedCellName then
        return "external_sleep_cell_change", currentCellName
    end

    if data.pendingStartEvent == true then return nil end
    local graceUntil = tonumber(data.sleepExternalDisplacementGraceUntil)
    if graceUntil and core.getSimulationTime() < graceUntil then return nil end
    data.sleepExternalDisplacementGraceUntil = nil

    if not (npc.position and data.finalPosition) then return nil end

    local delta = npc.position - data.finalPosition
    local distance = delta:length()
    local vertical = math.abs((npc.position.z or 0) - (data.finalPosition.z or 0))
    local maxDistance = tonumber(data.profile and data.profile.sleepExternalDisplacementDistance or SLEEP_EXTERNAL_DISPLACEMENT_DISTANCE) or SLEEP_EXTERNAL_DISPLACEMENT_DISTANCE
    local maxVertical = tonumber(data.profile and data.profile.sleepExternalDisplacementVertical or SLEEP_EXTERNAL_DISPLACEMENT_VERTICAL) or SLEEP_EXTERNAL_DISPLACEMENT_VERTICAL

    if distance > maxDistance or vertical > maxVertical then
        return "external_sleep_displaced", "distance=" .. tostring(distance) .. ",vertical=" .. tostring(vertical)
    end

    return nil
end

function sdpPreservePreemptedOriginForSleep(npc, active, candidate, reason)
    if not (npc and candidate) then return nil end
    local origin = active and active.preInteractionPos or nil
    local rotation = active and active.preInteractionRot or nil
    local source = "active_interaction_origin"
    if not origin then
        origin = npc.position
        rotation = npc.rotation
        source = "current_actor_position"
    end
    if not origin then return nil end

    sdpOriginTracker.setHome(npc, origin, rotation, reason or "sleep_priority_preempt_origin", { actorKey = npc.recordId or npc.id })
    candidate.preInteractionPos = origin
    candidate.preInteractionRot = rotation
    return source
end


local function assignSleepPriorityInteractions(cell, source, opts)
    if not cell or settings.enableSleeping ~= true then return end
    opts = opts or {}
    local maxAssignments = tonumber(opts.maxAssignments)

    local currentHour = profiles.getGameHour()
    if not profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        return
    end

    local stats = {
        total = 0,
        alreadySleeping = 0,
        activeNonSleep = 0,
        eligible = 0,
        canSleep = 0,
        assigned = 0,
        deferredStandExit = 0,
        noCandidate = 0,
        ineligible = 0,
    }

    local sleepCandidates = buildCandidateSlots(cell, "sleeping")
    if not sleepCandidates or #sleepCandidates == 0 then
        debugLog("sleep priority no available beds", tostring(source or "periodic"), "hour", tostring(currentHour))
        return
    end

    for _, npc in ipairs(cell:getAll(types.NPC)) do
        if npc and npc.id then
            stats.total = stats.total + 1
            local dead, deadReason = actorDeadReason(npc)
            if dead then
                stats.ineligible = stats.ineligible + 1
                debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", tostring(deadReason))
            else
            local active = assignedActors[npc.id]
            local reservedSleepSlot = sdpSleepReservations.reservedSlotForNpc(npc)

            -- Already-sleeping actors are done. Actors that have a pending bed
            -- reservation from the initial/current scan are also left alone. The
            -- priority pass previously raced the normal assignment pass: it
            -- released origin-preferred beds, reassigned actors to different
            -- beds in the same tick, then rejected them for active travel.
            if active and active.calibrationAction == true then
                stats.alreadySleeping = stats.alreadySleeping + 1
                if settings.debug then
                    debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", "calibration_action")
                end
            elseif active and active.interactionType == "sleeping" then
                stats.alreadySleeping = stats.alreadySleeping + 1
            elseif reservedSleepSlot then
                stats.alreadySleeping = stats.alreadySleeping + 1
                if settings.debug then
                    debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", "sleep_reserved", "slot", tostring(reservedSleepSlot))
                end
            elseif wakeExit.hasPendingStandTeleport(npc.id) then
                stats.ineligible = stats.ineligible + 1
                if settings.debug then
                    debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", "pending_stand_exit")
                end
            else
                if active then stats.activeNonSleep = stats.activeNonSleep + 1 end
                local stationReleasedForSleep = sdpStationAssignments.consumeSleepWindowReleaseForNpc
                    and sdpStationAssignments.consumeSleepWindowReleaseForNpc(npc, core.getSimulationTime() or 0)
                    or false
                if stationReleasedForSleep == true then
                    debugLog("actor considered for sleep after lecture release", npc.recordId or npc.id, "hour", tostring(currentHour))
                end
                local eligible, reason = isNpcRecordEligibleForInteraction(npc, "sleeping")
                if eligible then
                    stats.eligible = stats.eligible + 1
                    local canSleep, sleepReason, sleepTiming = sleepEligibilityForNpc(npc, cell, {
                        source = source or "sleep_priority",
                        sleepInitialPlacementAllowed = opts.sleepInitialPlacementAllowed == true,
                        sittingInitialPlacementAllowed = false,
                        allowDueBedtimeInitialPlacement = opts.allowDueBedtimeInitialPlacement == true,
                    })

                    if canSleep then
                        if stationReleasedForSleep == true then
                            debugLog(
                                "actor eligible for sleep after lecture release",
                                npc.recordId or npc.id,
                                "hour", tostring(currentHour),
                                "bedtime", tostring(sleepTiming and sleepTiming.actorBedtime),
                                "phase", tostring(sleepTiming and sleepTiming.phase)
                            )
                        end
                        stats.canSleep = stats.canSleep + 1
                        local candidate = chooseCandidateForNpc(npc, sleepCandidates, "sleeping", sleepTiming)
                        if candidate then
                            candidate = profiles.shallowCopy(candidate)
                            if candidate.disallowSleepDoorAssist == true and not sleepOriginPreferredDistance(npc, candidate) then
                                stats.noCandidate = stats.noCandidate + 1
                                if settings.debug then
                                    debugLog(
                                        active and "sleep priority preserves active interaction" or "sleep priority skips public restricted bed",
                                        npc.recordId or npc.id,
                                        "object", tostring(candidate.objectId),
                                        "slot", tostring(candidate.slotName),
                                        "reason", "public_bed_requires_door_assist"
                                    )
                                end
                            else
                                local deferForStandExit = false
                                candidate.initialPlacement = opts.initialPlacement == true
                                candidate.sleepPhase = sleepTiming and sleepTiming.phase or nil
                                candidate.actorBedtime = sleepTiming and sleepTiming.actorBedtime or nil
                                candidate.actorWakeTime = sleepTiming and sleepTiming.actorWakeTime or nil
                                candidate.sleepWakeBias = sleepTiming and sleepTiming.wakeBias or nil
                                candidate.observedPlayerOverride = sleepTiming and sleepTiming.observedPlayerOverride or nil

                                if active then
                                    local originSource = sdpPreservePreemptedOriginForSleep(npc, active, candidate, "sleep_priority_preempt_origin")
                                    debugLog(
                                        "sleep priority preempts interaction",
                                        npc.recordId or npc.id,
                                        "from", tostring(active.interactionType),
                                        "originSource", tostring(originSource),
                                        "hour", tostring(currentHour),
                                        "bedtime", tostring(candidate.actorBedtime),
                                        "phase", tostring(candidate.sleepPhase)
                                    )
                                    stopInteractionForNpc(npc, "sleep_priority")
                                    if active.interactionType ~= "sitting" then
                                        -- Sitting preemption relies on this queued exit
                                        -- to move the actor off the chair before bed handoff.
                                        wakeExit.clearStandTeleportForNpc(npc.id)
                                    elseif wakeExit.hasPendingStandTeleport(npc.id) then
                                        deferForStandExit = true
                                        stats.deferredStandExit = stats.deferredStandExit + 1
                                        debugLog(
                                            "sleep priority waits for sitting stand exit",
                                            npc.recordId or npc.id,
                                            "object", tostring(candidate.objectId),
                                            "slot", tostring(candidate.slotName)
                                        )
                                    end
                                else
                                    debugLog(
                                        "sleep priority assigns idle npc",
                                        npc.recordId or npc.id,
                                        "hour", tostring(currentHour),
                                        "bedtime", tostring(candidate.actorBedtime),
                                        "phase", tostring(candidate.sleepPhase)
                                    )
                                end

                                if not deferForStandExit then
                                    stats.assigned = stats.assigned + 1
                                    sendConsiderInteraction(npc, candidate)
                                    if maxAssignments and stats.assigned >= maxAssignments then break end
                                end
                            end
                        else
                            stats.noCandidate = stats.noCandidate + 1
                        end
                    else
                        stats.ineligible = stats.ineligible + 1
                        debugLog(
                            "sleep priority skip npc",
                            npc.recordId or npc.id,
                            "reason", tostring(sleepReason),
                            "hour", tostring(sleepTiming and sleepTiming.currentHour or currentHour),
                            "bedtime", tostring(sleepTiming and sleepTiming.actorBedtime),
                            "phase", tostring(sleepTiming and sleepTiming.phase)
                        )
                    end
                else
                    stats.ineligible = stats.ineligible + 1
                    debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", tostring(reason))
                end
            end
            end
        end
    end

    debugLog(
        "sleep priority summary",
        tostring(source or "periodic"),
        "total", tostring(stats.total),
        "alreadySleeping", tostring(stats.alreadySleeping),
        "activeNonSleep", tostring(stats.activeNonSleep),
        "eligible", tostring(stats.eligible),
        "canSleep", tostring(stats.canSleep),
        "assigned", tostring(stats.assigned),
        "deferredStandExit", tostring(stats.deferredStandExit),
        "noCandidate", tostring(stats.noCandidate),
        "ineligible", tostring(stats.ineligible)
    )
end

sdpDelayedInitialPlacementRetry.schedule = function(cell, source, initialStats)
    if sdpAssignmentScanCadence.isExteriorCell(cell) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    if not (cell and settings.enableSleeping == true and settings.sleepInitialPlacementEnabled == true) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    local currentHour = profiles.getGameHour()
    if not profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    if initialPlacementGuards.shouldSkipDelayedSleepRetry(initialStats) then
        sdpDelayedInitialPlacementRetry.pending = nil
        debugLog("initial placement retry skipped", tostring(cellName(cell)), "source", tostring(source or "cell_change"), "reason", "no_sleep_candidates")
        return
    end
    local now = core.getSimulationTime() or 0
    sdpDelayedInitialPlacementRetry.pending = {
        cell = cell,
        source = tostring(source or "cell_change"),
        nextAt = now + 0.35,
        untilAt = now + 4.5,
        attempts = 0,
        holdOverlay = (tonumber(initialStats and initialStats.total or 0) or 0) <= 0,
    }
    debugLog("initial placement retry scheduled", tostring(cellName(cell)), "source", tostring(source or "cell_change"))
end

sdpDelayedInitialPlacementRetry.process = function()
    local retry = sdpDelayedInitialPlacementRetry.pending
    if not retry then return end
    local player = world.players[1]
    if not (player and player.cell and player.cell == retry.cell) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    if not (settings.enableSleeping == true and settings.sleepInitialPlacementEnabled == true) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    local currentHour = profiles.getGameHour()
    if not profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end

    local now = core.getSimulationTime() or 0
    if now < (retry.nextAt or 0) then return end

    retry.attempts = (retry.attempts or 0) + 1
    local source = retry.source .. "_delayed_initial_" .. tostring(retry.attempts)
    local stats = assignNpcsToLocalInteractions(retry.cell, {
        source = source,
        sleepInitialPlacementAllowed = true,
        sittingInitialPlacementAllowed = false,
    })
    assignSleepPriorityInteractions(retry.cell, source .. "_sleep_priority", {
        initialPlacement = true,
        sleepInitialPlacementAllowed = true,
        allowDueBedtimeInitialPlacement = true,
    })
    sleepLightControl.processPending(true)

    local sent = tonumber(stats and stats.initialSleepSentConsider or 0) or 0
    local npcTotal = tonumber(stats and stats.total or 0) or 0
    debugLog(
        "initial placement retry scan",
        "source", source,
        "attempt", tostring(retry.attempts),
        "npcs", tostring(npcTotal),
        "initialSleepSent", tostring(sent)
    )

    local retryDone = sent > 0
        or retry.attempts >= 6
        or now >= (retry.untilAt or now)
    if retryDone then
        if sent <= 0 and retry.holdOverlay == true and settleInitialPlacementOverlay then
            settleInitialPlacementOverlay("no_initial_sleep_candidates_delayed")
        end
        sdpDelayedInitialPlacementRetry.pending = nil
        return
    end
    retry.nextAt = now + 0.8
end

local function processAmbientSittingScan(dt)
    if not (lastCell and settings.enableSitting == true and settings.sittingLifecycleEnabled == true) then
        if sdpAmbientSittingScan then sdpAmbientSittingScan.elapsed = 0 end
        return
    end
    if isCurrentTimeInSleepWindow() then
        if sdpAmbientSittingScan then sdpAmbientSittingScan.elapsed = 0 end
        return
    end
    sdpAmbientSittingScan.elapsed = (tonumber(sdpAmbientSittingScan.elapsed) or 0) + (tonumber(dt) or 0)
    local interval = tonumber(settings.sittingAmbientScanSeconds or SITTING_AMBIENT_SCAN_SECONDS) or SITTING_AMBIENT_SCAN_SECONDS
    if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
        interval = math.max(interval, sdpAssignmentScanCadence.exteriorAmbientSeconds())
    end
    if interval < 20 then interval = 20 end
    if sdpAmbientSittingScan.elapsed < interval then return end
    sdpAmbientSittingScan.elapsed = 0
    if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
        debugLog("periodic exterior sitting ambient nearby scan", tostring(cellName(lastCell)))
        sdpRunExteriorNearbyAssignment(lastCell, "periodic_sitting_ambient_exterior_nearby", "sitting", false)
    else
        debugLog("periodic sitting ambient scan", tostring(cellName(lastCell)))
        assignNpcsToLocalInteractions(lastCell, {
            source = "periodic_sitting_ambient",
            sleepInitialPlacementAllowed = false,
            sittingInitialPlacementAllowed = false,
        })
    end
end


local function sendInitialPlacementResult(reason, npcOrId)
    if not (settings and settings.disguiseInitialPlacement == true and world and world.players) then return end
    local actorId = nil
    local recordId = nil
    if type(npcOrId) == "string" then
        actorId = npcOrId
    elseif npcOrId then
        actorId = npcOrId.id
        recordId = npcOrId.recordId
    end
    if not actorId then return end
    for _, player in ipairs(world.players) do
        pcall(function()
            player:sendEvent('SitDownPleaseInitialPlacementSettled', {
                reason = reason or "settled",
                actorId = actorId,
                recordId = recordId,
                perActorResult = true,
                holdDuration = 0.04,
            })
        end)
    end
end

settleInitialPlacementOverlay = function(reason, npcOrId)
    if not (settings and settings.disguiseInitialPlacement == true and world and world.players) then return end
    local settleReason = tostring(reason or "settled")
    if npcOrId ~= nil then
        sendInitialPlacementResult(settleReason, npcOrId)
    end
    local now = core.getSimulationTime()
    local pendingCount = 0
    for npcId, pendingAt in pairs(pendingInitialHandoffs or {}) do
        if pendingAt and (now - (tonumber(pendingAt) or now)) < 1.8 then
            pendingCount = pendingCount + 1
        else
            pendingInitialHandoffs[npcId] = nil
            sendInitialPlacementResult("initial_handoff_timeout", npcId)
        end
    end
    if pendingCount > 0 then
        debugLog("initial placement overlay not settled pending local results", settleReason, "pending", tostring(pendingCount))
        return
    end
    if lastInitialPlacementFinalSettleReason == settleReason
        and now - (tonumber(lastInitialPlacementFinalSettleAt) or -100) < 0.35 then
        return
    end
    lastInitialPlacementFinalSettleReason = settleReason
    lastInitialPlacementFinalSettleAt = now
    debugLog("initial placement overlay final settle after all initial candidates resolved", settleReason)
    for _, player in ipairs(world.players) do
        pcall(function()
            player:sendEvent('SitDownPleaseInitialPlacementSettled', {
                reason = settleReason,
                holdDuration = (settleReason == "sleep_initial_placement_done" and 0.65)
                    or nil,
                final = true,
            })
        end)
    end
end

local function processPostWakeReturnOrigins(force)
    local radius = tonumber(settings.lightControlWakePathRestoreRadius or 220) or 220
    for _, item in pairs(postWakeReturnOrigins:raw() or {}) do
        local npc = item and item.npc
        local dead = false
        if isObjValid(npc) then dead = actorDeadReason(npc) == true end
        if isObjValid(npc) and not dead then
            if sleepLightControl.restoreNearActorThrottled then
                sleepLightControl.restoreNearActorThrottled(npc, "post_wake_walk_light_restore", true, radius, {
                    minInterval = 0.75,
                    minMove = 90,
                })
            else
                sleepLightControl.restoreNearActor(npc, "post_wake_walk_light_restore", true, radius)
            end
        end
    end
    postWakeReturnOrigins:process(force)
end

local function resolveActiveSleepersAfterTimeAdvance(currentHour)
    local resolved = 0
    local sleepers = {}
    for npcId, data in pairs(assignedActors) do
        if data and data.interactionType == "sleeping" and data.calibrationAction ~= true then
            sleepers[#sleepers + 1] = { id = npcId, data = data }
        end
    end
    table.sort(sleepers, function(a, b)
        return tostring(a and a.id or "") < tostring(b and b.id or "")
    end)

    for index, item in ipairs(sleepers) do
        local data = item and item.data
        local npc = data and data.npc
        if data and assignedActors[item.id] == data and isObjValid(npc) then
            -- Use the normal sleeping stop path for scheduled morning/time-advance
            -- wakes.  The old direct queueStandTeleport path skipped the same
            -- wake-exit selection used by dialogue/presence wakes and could leave
            -- actors in bunk/bed geometry.
            data.scheduledWakeOrder = index
            stopInteractionForNpc(npc, "time_advance_sleep_window_ended")
            resolved = resolved + 1
            debugLog("wake time-advance scheduled via normal sleep exit", npc.recordId or npc.id, "order", tostring(index), "hour", tostring(currentHour))
        end
    end

    if resolved > 0 then
        clearRelevantObjectCache("time_advance_sleep_resolved")
        sleepLightControl.processPending(true)
    end

    return resolved
end

local function handleLargeTimeAdvance(deltaHours, currentHour)
    if deltaHours < 0.25 then return end
    debugLog("time advance detected", "deltaHours", tostring(deltaHours), "hour", tostring(currentHour))
    local inSleepWindow = isCurrentTimeInSleepWindow()
    if not inSleepWindow then
        local resolved = resolveActiveSleepersAfterTimeAdvance(currentHour)
        processPostWakeReturnOrigins(false)
        local lightStatus = sleepLightControl.getStatus()
        if not (lightStatus and (tonumber(lightStatus.sleepers) or 0) > 0) then
            sleepLightControl.restoreAll('daytime_failsafe', true)
        else
            logSleepLightDeferred("time_advance", lightStatus, currentHour)
        end
        sleepLightControl.processPending(true)
        debugLog("time advance wake resolution", "sleepersResolved", tostring(resolved), "hour", tostring(currentHour))
        if settings.enableSitting == true and lastCell then
            if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
                sdpRunExteriorNearbyAssignment(lastCell, "time_advance_sitting_refresh_exterior_nearby", "sitting", false)
            else
                assignNpcsToLocalInteractions(lastCell, {
                    source = "time_advance_sitting_refresh",
                    sleepInitialPlacementAllowed = false,
                    sittingInitialPlacementAllowed = settings.sittingInitialPlacementEnabled == true,
                })
            end
        end
    else
        local phase = profiles.hourInSleepWindowPhase(settings, currentHour)
        local dueSleepInitialPlacement = settings.sleepInitialPlacementEnabled == true
            and phase
            and (phase.phase == "force_in_bed" or deltaHours >= 0.25)
        if dueSleepInitialPlacement then
            debugLog("time advance sleep initial placement", "hour", tostring(currentHour), "phase", tostring(phase.phase), "deltaHours", tostring(deltaHours))
            if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
                sdpRunExteriorNearbyAssignment(lastCell, "time_advance_sleep_initial_exterior_nearby", "sleep", false)
            else
                assignSleepPriorityInteractions(lastCell, "time_advance_sleep_initial", {
                    initialPlacement = true,
                    sleepInitialPlacementAllowed = true,
                    allowDueBedtimeInitialPlacement = phase.phase ~= "force_in_bed",
                })
            end
            sleepLightControl.processPending(true)
        else
            if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
                sdpRunExteriorNearbyAssignment(lastCell, "time_advance_sleep_priority_exterior_nearby", "sleep", false)
            else
                assignSleepPriorityInteractions(lastCell, "time_advance_sleep_priority")
            end
        end
    end
end

local function onActivateNpc(obj, actor)
    if not obj or not obj.id or not actor or actor.type ~= types.Player then
        return nil
    end

    local data = assignedActors[obj.id]
    if not data then return nil end

    if data.interactionType == "sleeping" then
        if playerStealthState.known == true and playerStealthState.isSneaking == true then
            debugLog("activation allows sneaking player to use sleeping npc", obj.recordId or obj.id)
            return nil
        end

        -- Only block/defer activation if the NPC is actually in the sleep pose or
        -- waiting for the post-teleport sleep animation to start. If the NPC is
        -- merely walking toward a bed, cancel the route and let normal dialogue
        -- proceed immediately.
        if data.state ~= STATES.interacting and data.pendingStartEvent ~= true and data.usedSleepEntrySnap ~= true then
            debugLog(
                "activation cancels pending sleep route",
                obj.recordId or obj.id,
                "state", tostring(data.state),
                "reason", "activated_by_player_dialogue"
            )
            stopInteractionForNpc(obj, "activated_by_player_dialogue_pending_route")
            return nil
        end

        debugLog("activation wakes sleeping npc before deferred dialogue", obj.recordId or obj.id)
        wakeExit.queuePostWakeActivation(obj, actor, "activated_by_player_dialogue")
        stopInteractionForNpc(obj, "activated_by_player_dialogue")
        -- Block this activation. Once the NPC has left the sleep pose/bed, this
        -- script calls npc:activateBy(actor) so dialogue opens from the standing
        -- state instead of while the actor is still locked into the bed pose.
        return false
    end

    if data.interactionType == "sitting" then
        -- Let seated NPCs talk while remaining seated. The local script keeps the
        -- sitting pose running during dialogue; do not release the seat here.
        debugLog("activation keeps seated npc in place for dialogue", obj.recordId or obj.id)
        return nil
    end


    return nil
end

if I.Activation and I.Activation.addHandlerForType then
    I.Activation.addHandlerForType(types.NPC, onActivateNpc)
else
    debugLog("activation handler unavailable; dialogue wake uses player UiModeChanged fallback")
end

local function handlePlayerCellTransition(trigger)
    local player = world.players[1]
    if not (player and player.cell) then return false end
    if player.cell == lastCell then
        lastPlayerPosition = player.position
        return false
    end

    local currentCell = player.cell
    local currentExterior = cellIsExterior(currentCell)
    local allowInitialPlacement, transitionReason = transitionAllowsInitialPlacement(lastCell, currentCell, lastCellExterior, currentExterior, lastPlayerPosition, player.position)
    local source
    if lastCell == nil then
        source = "initial_load"
    elseif allowInitialPlacement == true then
        source = trigger == "event" and "cell_change_event" or "cell_change"
    else
        source = "exterior_streaming"
    end

    lastCell = currentCell
    lastCellExterior = currentExterior
    lastPlayerPosition = player.position
    sleepPriorityElapsed = 0
    sleepPriorityGameElapsedHours = 0
    if sdpAmbientSittingScan then sdpAmbientSittingScan.elapsed = 0 end
    debugLog("cell transition", tostring(source), "reason", tostring(transitionReason), "exterior", tostring(currentExterior), "trigger", tostring(trigger or "update"))
    onCellChange(source)
    -- Do not wait for the periodic priority timer on real load/teleport cell
    -- entries. Exterior streaming is live world traversal, so it should not
    -- trigger hidden initial placement or instant sleep preemption.
    if allowInitialPlacement == true and not sdpAssignmentScanCadence.isExteriorCell(lastCell) then
        assignSleepPriorityInteractions(lastCell, source .. "_immediate_sleep_priority")
    end
    return true
end

local function onUpdate(dt)
    handlePlayerCellTransition("update")
    sdpSettingsRescan.process(sdpSettingsRescanState, core.getSimulationTime and core.getSimulationTime() or 0, {
        clearRelevantObjectCache = clearRelevantObjectCache,
        onCellChange = onCellChange,
        debugLog = debugLog,
    })

    sdpProcessSmoothCalibrationMoves()
    sleepLightControl.processPending(false)
    handoffTracker.process()
    processAnimatedMorrowindSettleCorrections()
    processAnimatedMorrowindCompatRetry()
    sdpProcessStationAssignments(lastCell, dt, false, false)
    stationReturnOrigins:process(false)
    if next(pendingInitialHandoffs) ~= nil then settleInitialPlacementOverlay("initial_handoff_timeout") end
    sleepRouteDoors.process()
    sdpStationRouteDoors.process()
    local currentHour = profiles.getGameHour()
    if currentHour ~= nil then
        local hourDelta = forwardHourDelta(lastGameHour, currentHour)
        largeTimeAdvanceThisUpdate = hourDelta >= 0.5
        handleLargeTimeAdvance(hourDelta, currentHour)
        lastGameHour = currentHour
        local inSleepWindow = isCurrentTimeInSleepWindow()
        if inSleepWindow then
            sleepPriorityGameElapsedHours = sleepPriorityGameElapsedHours + (tonumber(hourDelta) or 0)
        else
            sleepPriorityGameElapsedHours = 0
        end
        if not inSleepWindow then
            -- Safety net: any lights owned by this mod should not remain off in
            -- daytime/morning if a wake path was interrupted by waiting/resting,
            -- another mod, or a missed event.
            local status = sleepLightControl.getStatus()
            if status and status.activeReplacements and status.activeReplacements > 0 and (tonumber(status.sleepers) or 0) <= 0 then
                sleepLightControl.restoreAll('daytime_failsafe', true)
                sleepLightControl.processPending(true)
            elseif status and status.activeReplacements and status.activeReplacements > 0 then
                logSleepLightDeferred("daytime_failsafe", status, currentHour)
            end
            processPostWakeReturnOrigins(false)
        end
    end
    if sdpDelayedInitialPlacementRetry and sdpDelayedInitialPlacementRetry.process then
        sdpDelayedInitialPlacementRetry.process()
    end
    sdpProcessExteriorEntryNearbyScan()
    processAmbientSittingScan(dt)

    -- Time can cross into an actor's bedtime while the player is already in the
    -- cell. Periodically give sleep priority over lower-priority local
    -- interactions such as sitting, and also let otherwise idle NPCs
    -- claim available beds. This does not create travel schedules or move actors
    -- across cells; it only considers beds in the current cell/radius.
    sleepPriorityElapsed = sleepPriorityElapsed + dt
    local sleepPriorityGameHours = sdpAssignmentScanCadence.sleepPriorityGameHours()
    local sleepPrioritySeconds = sdpAssignmentScanCadence.sleepPrioritySeconds()
    if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
        sleepPrioritySeconds = math.max(sleepPrioritySeconds, sdpAssignmentScanCadence.exteriorSleepPrioritySeconds())
    end
    local sleepPriorityDue = sleepPriorityElapsed >= sleepPrioritySeconds
        or (sleepPriorityGameHours and sleepPriorityGameElapsedHours >= sleepPriorityGameHours)
    if sleepPriorityDue then
        local source = "periodic_sleep_priority"
        sleepPriorityElapsed = 0
        sleepPriorityGameElapsedHours = 0
        if sdpAssignmentScanCadence.isExteriorCell(lastCell) then
            sdpRunExteriorNearbyAssignment(lastCell, source .. "_exterior_nearby", "sleep", false)
        else
            assignSleepPriorityInteractions(lastCell, source, {
                maxAssignments = sdpAssignmentScanCadence.periodicSleepPriorityMaxAssignments(source, currentHour),
            })
        end
    end

    for npcId, data in pairs(assignedActors) do
        local npc = data.npc
        if not isObjValid(npc) then
            if data.slotKey then
                occupiedSlots[data.slotKey] = nil
                clearRelevantObjectCache("invalid_actor_slot_released")
            end
            if data.interactionType == "sleeping" then
                releaseSleepReservationForNpc(npcId, "invalid_actor")
                setSleepWakeRetryCooldown(npc, "external_actor_invalid")
                sleepLightControl.unregisterSleeper(npc or npcId, "external_actor_invalid", true)
                sleepLightControl.processPending(true)
                notifyPlayersSleepingState(npc, false, "external_actor_invalid")
                wakeExit.clearForNpc(npcId)
                postWakeReturnOrigins:clear(npcId)
                debugLog("sleep external release", npc and (npc.recordId or npc.id) or tostring(npcId), "reason", "external_actor_invalid")
            end
            assignedActors[npcId] = nil
        else
            local dead, deadReason = actorDeadReason(npc)
            if dead then
                stopInteractionForNpc(npc, deadReason or "dead_actor")
            elseif data.object and not isObjValid(data.object) then
                stopInteractionForNpc(npc, "object_invalid")
            else
            local wakeReason = nil
            if data.interactionType == "sleeping" and data.state == STATES.interacting then
                wakeReason = sleepingWakeReason(npc, data)
                if not wakeReason then
                    local incapacitationReason, incapacitationMarker = sdpExternalAiTakeover.externalIncapacitationReason(npc, types)
                    if incapacitationReason then
                        debugLog("sleep external incapacitation detected", npc.recordId or npc.id, "reason", tostring(incapacitationReason), "marker", tostring(incapacitationMarker))
                        wakeReason = incapacitationReason
                    end
                end
                if not wakeReason then
                    local externalReason, externalDetail = externalSleepDisplacementReason(npcId, npc, data)
                    if externalReason then
                        debugLog("sleep external displacement detected", npc.recordId or npc.id, "reason", tostring(externalReason), "detail", tostring(externalDetail))
                        wakeReason = externalReason
                    end
                end
            end

            local serviceReleaseReason = data.calibrationAction == true and nil or sdpServicePolicy.offHoursReleaseReason(npc, data, settings, profiles, types, profiles.getGameHour(), sdpActorRoles.isFactionLeader(npc, types, core))
            if serviceReleaseReason and data.interactionType == "sleeping" then
                wakeReason = serviceReleaseReason
            end

            if wakeReason then
                stopInteractionForNpc(npc, wakeReason)
            else
                local sitAction = data.interactionType == "sitting" and (serviceReleaseReason or sittingLifecycleAction(data)) or nil
                if sitAction then
                    local now = core.getSimulationTime() or 0
                    local gapKey = tostring(npc and (npc.recordId or npc.id) or "<npc>") .. "::sitlife-group-gap::" .. tostring(data.sittingLifecycleGeneration or 0)
                    local gap = 90 + (210 * profiles.stableUnitInterval(gapKey))
                    local nextGroupAt = pendingSittingReassignments.__nextLifecycleGroupActionAt or 0
                    if now < nextGroupAt then
                        deferSittingLifecycle(data, gap)
                        debugLog("sitting lifecycle deferred", npc.recordId or npc.id, "group_spacing", "seconds", tostring(gap))
                    else
                        pendingSittingReassignments.__nextLifecycleGroupActionAt = now + gap
                        debugLog("sitting lifecycle action", npc.recordId or npc.id, tostring(sitAction))
                        stopInteractionForNpc(npc, sitAction)
                    end
                elseif data.pendingStartEvent == true then
                    data.startEventDelay = (data.startEventDelay or 0) - dt
                    if data.startEventDelay <= 0 then
                        data.pendingStartEvent = false
                        data.sentStartEvent = true
                        npc:sendEvent('StartInteractionAnimation', {
                            interactionType = data.interactionType,
                            animation = data.profile.animation,
                            animationOptions = data.profile.animationOptions,
                            forceReplay = data.initialPlacement == true,
                            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
                                        })
                    end
                end

                local approach = data.approachPos or data.position
                local distance = (npc.position - approach):length()
                local transitionDistance = data.profile.transitionDistance or settings.transitionDistance

                local directSleepEntry = false
                local directSleepReason = nil
                local directSleepDistance = nil
                local directSleepVertical = nil
                if data.interactionType == "sleeping" and data.reachedValidSleepApproach ~= true then
                    directSleepEntry, directSleepReason, directSleepDistance, directSleepVertical = directlyBesideReservedBed(npc, data)
                end

                if directSleepEntry then
                    data.reachedValidSleepApproach = true
                    debugLog(
                        "reached_valid_sleep_approach",
                        npc.recordId or npc.id,
                        "object", tostring(data.objectId),
                        "approach", tostring(data.approachPos),
                        "distance", tostring(directSleepDistance or distance),
                        "vertical", tostring(directSleepVertical),
                        "route", tostring(data.sleepRouteStatus),
                        "reason", tostring(directSleepReason)
                    )
                    beginTransition(npc, data, "reached_approach")
                elseif distance <= transitionDistance then
                    if data.interactionType == "sleeping" and data.reachedValidSleepApproach ~= true then
                        data.reachedValidSleepApproach = true
                        debugLog(
                            "reached_valid_sleep_approach",
                            npc.recordId or npc.id,
                            "object", tostring(data.objectId),
                            "approach", tostring(data.approachPos),
                            "distance", tostring(distance),
                            "route", tostring(data.sleepRouteStatus)
                        )
                    end
                    beginTransition(npc, data, "reached_approach")
                else
                    updateApproachProgress(npc, data, distance, dt)
                end

                if data.npcStandingPos ~= nil then
                    data.lerpTime = data.lerpTime + dt

                    local lerpDuration = data.profile.lerpDuration or settings.lerpDuration
                    local lerpProgress = data.lerpTime / lerpDuration
                    if lerpProgress >= 1 then lerpProgress = 1 end

                    if lerpProgress >= 0.5 and not data.sentStartEvent and data.interactionType ~= "sleeping" then
                        data.sentStartEvent = true
                        npc:sendEvent('StartInteractionAnimation', {
                            interactionType = data.interactionType,
                            animation = data.profile.animation,
                            animationOptions = data.profile.animationOptions,
                            forceReplay = data.initialPlacement == true,
                            audienceHeadFocusPosition = data.audienceHeadFocusPosition,
                                        })
                    end

                    local targetPos = data.finalPosition or data.position
                    local newPosition = gUtils.lerp(data.npcStandingPos, targetPos, lerpProgress)

                    local targetAngle = data.finalRotation
                    if not targetAngle and data.facingDirection then
                        targetAngle = math.atan2(data.facingDirection.x, data.facingDirection.y)
                    end
                    targetAngle = targetAngle or data.npcStandingRot:getYaw()

                    local newAngle = gUtils.lerpAngle(data.npcStandingRot:getYaw(), targetAngle, lerpProgress)
                    local transitionTeleportOk = true

                    if sdpSmoothCalibrationMoveActive(npcId) then
                        -- Smooth calibration owns placement for this frame.
                    elseif data.state == STATES.transitioning or data.profile.allowPerFrameCorrection then
                        local ok, err = tryTeleport(npc, npc.cell, newPosition, { rotation = rotationFromYaw(newAngle, npc.rotation) })
                        transitionTeleportOk = ok == true
                        if not ok and not deferTeleportFailure(data, err, "transition_or_correction") then
                            stopInteractionForNpc(npc, "teleport_failed", npcId)
                        end
                    end

                    if lerpProgress >= 1 then
                        if data.interactionType == "sleeping" and transitionTeleportOk ~= true then
                            data.sleepFinalTeleportPending = true
                            data.lerpTime = math.max(0, lerpDuration - 0.05)
                        else
                            data.state = STATES.interacting
                            data.interactionStartedAt = data.interactionStartedAt or core.getSimulationTime()
                            if not data.sentStartEvent then
                                data.sentStartEvent = true
                                npc:sendEvent('StartInteractionAnimation', {
                                    interactionType = data.interactionType,
                                    animation = data.profile.animation,
                                    animationOptions = data.profile.animationOptions,
                                    forceReplay = data.initialPlacement == true,
                                    audienceHeadFocusPosition = data.audienceHeadFocusPosition,
                                                })
                            end
                            if data.interactionType == "sitting" and not (data.sittingLifecycleStartGameTimeHours or data.sittingLifecycleStartGameHour) then
                                scheduleSittingLifecycle(data, "transition_complete")
                            end
                            if data.interactionType == "sleeping" and not data.lightRegistered then
                                data.lightRegistered = true
                                sleepLightControl.registerSleeper(npc, {
                                    object = data.object,
                                    bed = data.object,
                                    bedId = data.objectId,
                                    finalPosition = data.finalPosition,
                                    position = data.finalPosition,
                                    exitPosition = data.exitPosition,
                                    approachPosition = data.approachPos,
                                    originPosition = data.preInteractionPos,
                                    initialPlacement = data.initialPlacement == true,
                                    visibleSleep = data.initialPlacement ~= true,
                                }, false)
                            end
                        end
                    end
                elseif data.state == STATES.interacting
                    and data.profile.allowPerFrameCorrection == true
                    and data.finalPosition
                    and not sdpSmoothCalibrationMoveActive(npcId)
                then
                    -- Sleep entry/initial placement may snap straight to the bed
                    -- without a lerp. Continue lightly enforcing the final bed
                    -- position so collision/pathing does not push the sleeper back
                    -- to the failed approach edge.
                    local targetAngle = targetYawForData(npc, data)
                    local ok, err = tryTeleport(npc, npc.cell, data.finalPosition, { rotation = rotationFromYaw(targetAngle, npc.rotation) })
                    if not ok and not deferTeleportFailure(data, err, "sleep_position_correction") then
                        stopInteractionForNpc(npc, "teleport_failed", npcId)
                    end
                end
                if assignedActors[npcId] == data then
                    calibrationBlockerMarkerEvents.syncAssignment(world.players, data, core.getSimulationTime() or 0)
                end
            end
        end
    end
    end

    wakeExit.processPendingStandTeleports()
    wakeExit.processWakeExitWalks()
    processPendingSittingReassignments()
    processPendingSittingOriginWalks()
    wakeExit.processPostWakeActivations()
    largeTimeAdvanceThisUpdate = false
end

local function onLectureAudienceSeated(ev)
    local npc = ev and ev.npc
    if not (npc and npc.id and sdpStationAssignments and sdpStationAssignments.noteAudienceMember) then return end
    local data = assignedActors[npc.id]
    if not (data and data.lectureAudienceTarget == true and data.stationSlotKey) then return end
    local incomingStation = ev.stationSlotKey or ev.audienceKey
    if incomingStation and tostring(incomingStation) ~= tostring(data.stationSlotKey) then
        sdpLectureTrace.log(
            debugLog,
            "audience_arrival_ignored",
            "actor", tostring(npc.recordId or npc.id),
            "station", tostring(incomingStation),
            "expected", tostring(data.stationSlotKey),
            "reason", "station_mismatch"
        )
        return
    end
    if ev.lectureSessionId and data.lectureSessionId and tostring(ev.lectureSessionId) ~= tostring(data.lectureSessionId) then
        sdpLectureTrace.log(
            debugLog,
            "audience_arrival_ignored",
            "actor", tostring(npc.recordId or npc.id),
            "station", tostring(data.stationSlotKey),
            "session", tostring(ev.lectureSessionId),
            "expected", tostring(data.lectureSessionId),
            "reason", "session_mismatch"
        )
        return
    end
    if sdpStationAssignments.noteAudienceMember(data.stationSlotKey, npc, {
        originPosition = data.lectureAudienceOriginPosition or data.preInteractionPos,
        originRotation = data.lectureAudienceOriginRotation or data.preInteractionRot,
        returnMode = data.lectureAudienceReturnMode,
        wasAlreadySitting = data.lectureAudienceWasAlreadySitting == true,
        originalAnimation = data.lectureAudienceOriginalAnimation or data.animationName,
    }) then
        sdpLectureTrace.log(
            debugLog,
            "audience_arrival_noted",
            "actor", tostring(npc.recordId or npc.id),
            "station", tostring(data.stationSlotKey),
            "slot", tostring(data.slotName),
            "stage", "local_seated",
            "teleport", tostring(data.lectureAudienceTeleport == true)
        )
    end
end

function clearTransientRuntimeForLoad(reason, savedOrigins, savedLectureSessions, savedLectureAudienceReleases)
    assignedActors = {}
    occupiedSlots = {}
    calibrationBlockerMarkerEvents.sendAllCleared(world.players, reason or "load")
    pendingSittingReassignments = {}
    sdpSettingsRescan.reset(sdpSettingsRescanState)
    savedPendingLectureAudienceReleases = sdpLectureAudienceReleasePersistence.normalize(savedLectureAudienceReleases)
    sdpLectureSeatReservations.clear()
    sdpStationAssignments.reset()
    local restoredLectureSessions = sdpStationAssignments.onLoad and sdpStationAssignments.onLoad(savedLectureSessions) or 0
    if restoredLectureSessions > 0 then
        debugLog("lecture sessions loaded", tostring(restoredLectureSessions), "reason", tostring(reason or "load"))
    end
    sittingOriginReturns:reset()
    stationReturnOrigins:reset()
    pendingInitialHandoffs = {}
    followerPackageActors = {}
    recentSittingMemory = {}
    sdpInitialReadyRetryAttempts = {}
    sdpInitialReadyRetryLastEntryAt = -100
    sdpInitialReadyRetryLastEntrySource = nil
    sdpInitialReadyRetryLastCandidateCount = 0
    sittingCooldowns = sittingCooldownModule.new()
    postWakeReturnOrigins:reset()
    sdpOriginTracker.resetHomeOrigins()
    sleepObservedCooldowns = {}
    sleepWakeRetryCooldowns = {}
    sleepRouteRejectCooldowns = {}
    sdpSleepReservations.reset()
    sdpSavedInteractionOrigins = sdpOriginTracker.normalize(savedOrigins)
    largeTimeAdvanceThisUpdate = false
    lastCell = nil
    lastCellExterior = nil
    lastPlayerPosition = nil
    completedInitialCellScan = false
    if sdpDelayedInitialPlacementRetry then sdpDelayedInitialPlacementRetry.pending = nil end
    if sdpAmbientSittingScan then sdpAmbientSittingScan.elapsed = 0 end
    if sdpRelevantObjectCacheInvalidator then sdpRelevantObjectCacheInvalidator.reset() end
    claimRejectLogCache = {}
    sleepPriorityElapsed = 0
    sleepPriorityGameElapsedHours = 0
    lastGameHour = nil
    if wakeExit then wakeExit.clearAll() end
    handoffTracker.reset()
    sleepRouteDoors.clearPendingRestarts()
    sdpStationRouteDoors.reset(reason or "load")
    clearAnimatedMorrowindCompatRuntime(reason or "load")
    clearRelevantObjectCache(reason or "load")
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = function(data)
            clearTransientRuntimeForLoad("load", data and data.interactionOrigins or nil, data and data.lectureSessions or nil, data and data.lectureAudienceReleases or nil)
            sleepLightControl.onLoad(data and data.sleepLightControl or nil)
        end,
        onInit = function(data)
            clearTransientRuntimeForLoad("init", data and data.interactionOrigins or nil, data and data.lectureSessions or nil, data and data.lectureAudienceReleases or nil)
            sleepLightControl.onLoad(data and data.sleepLightControl or nil)
        end,
        onSave = function()
            return {
                interactionOriginVersion = 1,
                interactionOrigins = sdpOriginTracker.buildSaveData(assignedActors, {
                    states = STATES,
                    isObjValid = isObjValid,
                    cellName = cellName,
                }),
                lectureSessions = sdpStationAssignments.onSave and sdpStationAssignments.onSave(sdpStationRuntimeContext(0, false, false, nil)) or nil,
                lectureAudienceReleases = sdpLectureAudienceReleasePersistence.merge(
                    savedPendingLectureAudienceReleases,
                    sdpLectureAudienceReleasePersistence.snapshotPending(pendingSittingReassignments, {
                        now = core.getSimulationTime,
                        cellName = cellName,
                    })
                ),
                sleepLightControl = sleepLightControl.onSave(),
            }
        end,
    },
    interfaceName = "SleepLightControl",
    interface = {
        version = 1,
        requestSleepLightsOff = function(payload) return sleepLightControl.requestSleepLightsOff(payload) end,
        requestSleepLightsRestore = function(payload) return sleepLightControl.requestSleepLightsRestore(payload) end,
        getStatus = function() return sleepLightControl.getStatus() end,
        isActorSleeping = function(actorOrId) return sleepLightControl.isActorSleeping(actorOrId) end,
        getSleepingActors = function() return sleepLightControl.getSleepingActors() end,
        isActorManagedBySitDownPlease = function(actorOrId) return sdpAssignmentPublicInterface.isActorManaged(assignedActors, actorOrId) end,
        getActorInteractionState = function(actorOrId) return sdpAssignmentPublicInterface.actorInteractionState(assignedActors, actorOrId) end,
        isVerboseDebugEnabled = function()
            return settings and (settings.logLevel == "verbose" or settings.verboseDebug == true or settings.debugVerbose == true) or false
        end,
        requestSchedulerArrivalPlacement = function(payload)
            return sdpSchedulerArrivalPlacement.request(sdpSchedulerArrivalPlacementEnv(), payload or {})
        end,
        requestSchedulerArrivalOverlay = function(payload)
            return sdpRequestSchedulerArrivalOverlay(payload or {})
        end,
        requestRescan = function() if onCellChange then onCellChange('interface_request') end end,
    },
    eventHandlers = {
        CellChange = function() handlePlayerCellTransition("event") end,
        PC_StateChanged = function(data)
            sdpProceduralChatterCompat.noteStateChanged(data, core)
        end,
        PC_ClearConversationState = function(data)
            if data and data.npcId then
                sdpProceduralChatterCompat.noteStateChanged({ npcId = data.npcId, state = "idle" }, core)
            end
        end,
        SitDownPleasePlayerStealthState = function(data)
            if data then
                playerStealthState.isSneaking = data.isSneaking == true
                playerStealthState.isMoving = data.isMoving == true
                playerStealthState.isInvisible = data.isInvisible == true
                playerStealthState.chameleon = tonumber(data.chameleon or 0) or 0
                playerStealthState.known = data.known == true
                playerStealthState.updatedAt = realTimeNow()
            end
        end,
        SitDownPleaseFollowerState = function(data)
            if data and data.actorId then followerPackageActors[data.actorId] = data.isFollower == true or data.isCompanion == true end
            sleepLightControl.noteCompanionState(data)
        end,
        SitDownPleaseNpcSeekerReady = function(data)
            handoffTracker.noteReady(data, settings)
            if data and data.npc then
                wakeExit.sendPendingWakeCleanupIfNeeded(data.npc, data.reason or "seeker_ready")
                sdpTryAssignReadyNpcAfterInitialScan(data)
            end
        end,
        SitDownPleaseLocalSittingAcceptanceTrace = function(data)
            handoffTracker.noteLocalTrace(data)
        end,
        InteractionCheckResult = onInteractionCheckResult,
        SitDownPleaseSchedulerStandDispersalReady = function(ev)
            if ev and ev.npc then
                local ok, err = false, nil
                if ev.position and ev.npc.cell then
                    ok, err = tryTeleport(ev.npc, ev.npc.cell, ev.position, { onGround = true })
                end
                if not ok then
                    debugLog(
                        "scheduler arrival stand dispersal teleport failed",
                        ev.npc.recordId or ev.npc.id,
                        "target", tostring(ev.targetIndex),
                        "object", tostring(ev.targetObjectId),
                        "reason", tostring(ev.reason),
                        "error", tostring(err)
                    )
                    return
                end
                debugLog(
                    "scheduler arrival stand dispersed",
                    ev.npc.recordId or ev.npc.id,
                    "target", tostring(ev.targetIndex),
                    "object", tostring(ev.targetObjectId),
                    "reason", tostring(ev.reason),
                    "position", tostring(ev.position)
                )
            end
        end,
        SitDownPleaseSchedulerStandDispersalFailed = function(ev)
            if ev and ev.npc then
                debugLog(
                    "scheduler arrival stand dispersal failed",
                    ev.npc.recordId or ev.npc.id,
                    "reason", tostring(ev.reason),
                    "failure", tostring(ev.failureReason)
                )
            end
        end,
        SitDownPleaseLectureAudienceSeated = onLectureAudienceSeated,
        SitDownPleaseAnimatedMorrowindAlignmentResult = onAnimatedMorrowindAlignmentResult,
        SitDownPleaseSittingCalibrationUpdated = onSittingCalibrationUpdated,
        SitDownPleaseStationPoseRequest = function(ev) sdpOnStationPoseRequest(ev) end,
        SitDownPleaseSleepCalibrationUpdated = function(ev)
            local npc = ev and ev.npc
            local data = npc and npc.id and assignedActors[npc.id] or nil
            calibrationLock.onSleepUpdated(ev, {
                assignedActors = assignedActors,
                states = STATES,
                tryTeleport = tryTeleport,
                rotationFromYaw = rotationFromYaw,
                deferTeleportFailure = deferTeleportFailure,
                smoothMove = sdpQueueSmoothCalibrationMove,
                infoLog = infoLog,
                debugLog = debugLog,
                now = core.getSimulationTime,
            })
            sendCalibrationOffsets("sleeping", ev and ev.profileOffset, ev and ev.animationOffset, ev and ev.calibration, ev and ev.animation, data or ev)
        end,
        CancelInteractionForNpc = onCancelInteractionForNpc,
        SitDownPleaseOpenSleepRouteDoor = function(ev) sleepRouteDoors.onOpen(ev) end,
        SitDownPleaseCloseRejectedSleepRouteDoor = function(ev) sleepRouteDoors.closeRejectedDoor(ev and ev.npc, ev and ev.door, ev and ev.reason or "route_rejected") end,
        SitDownPleaseOpenStationRouteDoor = function(ev) sdpStationRouteDoors.onOpen(ev) end,
        SitDownPleaseCalibrationMenuAction = function(ev) calibrationMenu.onCalibrationMenuAction(ev) end,
        TryStartInteraction = onTryStartInteraction,
        SitDownPleaseGoToBed = function(ev)
            forceNpcToBedNow(ev and (ev.npc or ev.actor), ev and ev.source or "console")
        end,
        -- Legacy event aliases kept so older local-script copies or saves do not break.
        StoolCheckResult = onInteractionCheckResult,
        CancelSittingForNpc = onCancelInteractionForNpc,
    }
}
