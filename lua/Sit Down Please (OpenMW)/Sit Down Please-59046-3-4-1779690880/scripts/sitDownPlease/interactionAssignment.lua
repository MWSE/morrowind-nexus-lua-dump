-- interactionAssignment.lua
local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local gUtils = require('scripts/sitDownPlease/lib/gUtils')
local profiles = require('scripts/sitDownPlease/profiles/catalog')
local sleepLightControl = require('scripts/sitDownPlease/sleeping/lightControl')
local cellContext = require('scripts/sitDownPlease/world/cellContext')
local sleepBedAccess = require('scripts/sitDownPlease/sleeping/bedAccess')
local calibrationLock = require('scripts/sitDownPlease/calibration/lockState')
local sleepRouteDoors = require('scripts/sitDownPlease/sleeping/routeDoors')
local handoffTracker = require('scripts/sitDownPlease/assignment/handoffTracker')
local assignmentEligibility = require('scripts/sitDownPlease/assignment/eligibility')
local sittingCooldownModule = require('scripts/sitDownPlease/assignment/sittingCooldowns')
sdpInteractionOrigins = require('scripts/sitDownPlease/assignment/origins')
sdpExternalAiTakeover = require('scripts/sitDownPlease/compatibility/externalAiTakeover')
sdpAnimatedMorrowindCompat = require('scripts/sitDownPlease/compatibility/animatedMorrowind')

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

local function actorDeadReason(actor)
    return assignmentEligibility.actorDeadReason(actor, types)
end

local stopInteractionForNpc
local targetYawForData
local buildCandidateSlots
local chooseCandidateForNpc
local sendConsiderInteraction
local tryTeleport
local isObjValid
local sleepReservationNpcId
local updateSleepReservationState
local sleepFinalPlacementSane
local directlyBesideReservedBed
local settleInitialPlacementOverlay
local clearSleepHomeOrigin
local isNpcRecordEligibleForInteraction

-- Map: npc.id -> active local interaction state.
local assignedActors = {}

-- Map: slotKey -> npc.id. Prevents two actors from taking the same profiled slot.
-- This is runtime-only and also acts as the pending claim while a local NPC
-- script is validating a just-sent candidate.
local occupiedSlots = {}

-- Map: npc.id -> queued stand-up teleport attempts. Sleeping can have multiple
-- fallback exit positions plus an original-position fallback.
local pendingSittingReassignments = {}
local pendingSittingOriginWalks = {}
-- Initial-placement handoffs are tracked so the black cover can be released
-- after the local NPC scripts answer. They also serve as the guard against
-- revealing the world before hidden placement has actually settled.
local pendingInitialHandoffs = {}
local followerPackageActors = {}
local recentSittingMemory = {}
local sittingCooldowns = sittingCooldownModule.new()
local postWakeReturnOrigins = {}
sdpSavedInteractionOrigins = {}
-- Same-cell unlocked route doors are tracked in sleeping/routeDoors.lua.
local largeTimeAdvanceThisUpdate = false

local calibrationMenu = nil
local wakeExit = nil

-- Runtime-only relevant-object cache. This avoids re-checking every cup, bottle,
-- rug, light, and door in the cell every time NPCs reconsider sitting/sleeping.
-- It is rebuilt on cell/settings changes and is never written to save/settings.
local relevantObjectCache = {}
local claimRejectLogCache = {}

local lastCell = nil
local lastCellExterior = nil
local lastPlayerPosition = nil
local onCellChange = nil
local completedInitialCellScan = false
local sleepObservedCooldowns = {}
local sleepWakeRetryCooldowns = {}
local lastSleepLightDeferredLogAt = -999
-- Runtime-only per-NPC/per-bed suppression. If a bed route is rejected for
-- reachability, skip that same slot briefly so another reachable bed can win
-- instead of retrying the wall-blocked candidate every scan.
local sleepRouteRejectCooldowns = {}
-- Runtime-only bed reservations. These are deliberately not saved: they exist
-- only to stop same-night pileups and retry churn inside the currently active
-- session/cell. A reservation starts when a bed is considered/assigned, not only
-- after the actor reaches the bed.
local sleepBedReservations = {}
local sleepReservationByNpc = {}
sdpAnimatedMorrowindCompatState = {
    detected = false,
    detectionReason = nil,
    externalPlacementPatchDetected = false,
    externalPlacementPatchReason = nil,
    detectionLogged = false,
    activeLogged = false,
    externalPlacementPatchLogged = false,
    actorSeenLogged = {},
    checkedActors = {},
    pending = {},
    settle = {},
    retryNextAt = nil,
    retryUntil = nil,
    retryReason = nil,
    retryLogged = false,
}
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

-- Sitting lifecycle stays runtime-only and opportunistic: it can auto-place NPCs
-- into seats on cell entry, occasionally release them back to their origin, or
-- ask them to move to another nearby seat. The local NPC script still rejects the
-- assignment if a quest/schedule package is active.
local SITTING_LIFECYCLE_MIN_SECONDS = 2700
local SITTING_LIFECYCLE_SPREAD_SECONDS = 4500
local SITTING_LIFECYCLE_MOVE_SEAT_CHANCE = 0.25
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

local NOISY_DEBUG_TAGS = {
    ["candidate scan"] = true,
    ["candidate count"] = true,
    ["candidate within radius"] = true,
    ["no candidate within radius"] = true,
    ["reject object occupied"] = true,
    ["reject relevant object"] = true,
    ["reject by time"] = true,
    ["relevant object cache hit"] = true,
    ["relevant object cache cleared"] = true,
    ["sleep priority no available beds"] = true,
    ["sleep priority skip npc"] = true,
    ["sleep priority summary"] = true,
    ["skip npc"] = true,
    ["reject object physically claimed"] = true,
    ["reject sleep bed reserved"] = true,
    ["reject sleep route cooldown"] = true,
    ["sleep_before_start_hour"] = true,
    ["sleep_after_actor_wake_time"] = true,
    ["guard_or_publican_class"] = true,
    ["barter_service_npc"] = true,
    ["external_animation_npc"] = true,
    ["active_travel_package"] = true,
    ["collision_or_raycast_validation_failed"] = true,
    ["sleep lights scan"] = true,
    ["sleep lights scan detail"] = true,
    ["sleep light off"] = true,
    ["sleep light restore"] = true,
    ["teleport busy deferred"] = true,
}

local function debugLog(...)
    if settings and settings.debug == true and settings.verboseDebug ~= true then
        local tag = select(1, ...)
        if NOISY_DEBUG_TAGS[tostring(tag)] then return end
    end
    profiles.debugLog(settings, ...)
end

local function infoLog(...)
    profiles.debugLog(settings, ...)
end

function refreshAnimatedMorrowindDetection(reason)
    local detected, detectionReason = sdpAnimatedMorrowindCompat.detectContent(core)
    local externalPatchDetected, externalPatchReason = sdpAnimatedMorrowindCompat.detectExternalPlacementPatch(core)
    sdpAnimatedMorrowindCompatState.detected = detected == true
    sdpAnimatedMorrowindCompatState.detectionReason = detectionReason
    sdpAnimatedMorrowindCompatState.externalPlacementPatchDetected = externalPatchDetected == true
    sdpAnimatedMorrowindCompatState.externalPlacementPatchReason = externalPatchReason
    if sdpAnimatedMorrowindCompatState.detectionLogged ~= true then
        sdpAnimatedMorrowindCompatState.detectionLogged = true
        infoLog(
            "animated morrowind detection",
            "detected", tostring(sdpAnimatedMorrowindCompatState.detected),
            "reason", tostring(detectionReason),
            "externalPlacementPatch", tostring(sdpAnimatedMorrowindCompatState.externalPlacementPatchDetected),
            "externalPlacementPatchReason", tostring(externalPatchReason),
            "source", tostring(reason or "startup")
        )
    else
        debugLog(
            "animated morrowind detection",
            "detected", tostring(sdpAnimatedMorrowindCompatState.detected),
            "reason", tostring(detectionReason),
            "externalPlacementPatch", tostring(sdpAnimatedMorrowindCompatState.externalPlacementPatchDetected),
            "externalPlacementPatchReason", tostring(externalPatchReason),
            "source", tostring(reason or "refresh")
        )
    end
    if sdpAnimatedMorrowindCompatState.detected == true
        and sdpAnimatedMorrowindCompatState.activeLogged ~= true
        and settings and settings.animatedMorrowindAlignmentAssist == true then
        sdpAnimatedMorrowindCompatState.activeLogged = true
        infoLog(
            "animated morrowind compat active",
            "reason", tostring(detectionReason),
            "setting", tostring(settings and settings.animatedMorrowindAlignmentAssist)
        )
    end
    if sdpAnimatedMorrowindCompatState.externalPlacementPatchDetected == true
        and sdpAnimatedMorrowindCompatState.externalPlacementPatchLogged ~= true then
        sdpAnimatedMorrowindCompatState.externalPlacementPatchLogged = true
        infoLog(
            "animated morrowind external placement patch detected",
            "reason", tostring(externalPatchReason),
            "assist", "yield_for_patch_positioned_actors"
        )
    end
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
                manualOverride = sourceData and sourceData.manualAssignOverrideApplied == true,
                manualOverrideReason = sourceData and sourceData.manualAssignOverrideReason,
            })
        end)
    end
end

local function debugLogOnce(cache, key, ...)
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
profiles.logStartupProfileStatus(infoLog)
infoLog(
    "settings loaded",
    "sleepWindow", tostring(settings.sleepStartHour) .. "-" .. tostring(settings.sleepEndHour),
    "sleepRadius", tostring(settings.sleepSearchRadius),
    "maxRadius", tostring(settings.maxSearchRadius),
    "doorAssist", tostring(settings.sleepSmartDoorAssist),
    "initialPlacement", tostring(settings.sleepInitialPlacementEnabled),
    "disguiseInitialPlacement", tostring(settings.disguiseInitialPlacement)
)
refreshAnimatedMorrowindDetection("startup")

sleepLightControl.setDebugLog(debugLog)
sleepLightControl.refreshSettings(settings)

local function clearRelevantObjectCache(reason)
    relevantObjectCache = {}
    if settings and settings.debug == true then
        debugLog("relevant object cache cleared", tostring(reason or "unknown"))
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
    sdpAnimatedMorrowindCompatState.checkedActors = {}
    sdpAnimatedMorrowindCompatState.pending = {}
    sdpAnimatedMorrowindCompatState.settle = {}
    sdpAnimatedMorrowindCompatState.retryNextAt = nil
    sdpAnimatedMorrowindCompatState.retryUntil = nil
    sdpAnimatedMorrowindCompatState.retryReason = nil
    sdpAnimatedMorrowindCompatState.retryLogged = false
    if settings and settings.debug == true then
        debugLog("animated morrowind compat runtime cleared", tostring(reason or "unknown"))
    end
end

local function sittingLifecycleInterval(npc, seed)
    local minSeconds = tonumber(settings.sittingLifecycleMinSeconds or SITTING_LIFECYCLE_MIN_SECONDS) or SITTING_LIFECYCLE_MIN_SECONDS
    local maxSeconds = tonumber(settings.sittingLifecycleMaxSeconds or (minSeconds + SITTING_LIFECYCLE_SPREAD_SECONDS)) or (minSeconds + SITTING_LIFECYCLE_SPREAD_SECONDS)
    -- Migrate exact old default pairs at runtime so existing test settings do not
    -- keep the old too-short sitting timer after upgrading.
    if (minSeconds == 600 and maxSeconds == 1500) or (minSeconds == 1200 and maxSeconds == 3600) then
        minSeconds = SITTING_LIFECYCLE_MIN_SECONDS
        maxSeconds = minSeconds + SITTING_LIFECYCLE_SPREAD_SECONDS
    end
    if maxSeconds < minSeconds then maxSeconds = minSeconds end
    local key = tostring(npc and (npc.recordId or npc.id) or "<npc>") .. "::sitlife::" .. tostring(seed or 0)
    return minSeconds + ((maxSeconds - minSeconds) * profiles.stableUnitInterval(key))
end

local function scheduleSittingLifecycle(data, reason)
    if settings.sittingLifecycleEnabled ~= true then return end
    if not data or data.interactionType ~= "sitting" or not data.npc then return end
    data.sittingLifecycleGeneration = (data.sittingLifecycleGeneration or 0) + 1
    data.sittingLifecycleNextAt = core.getSimulationTime() + sittingLifecycleInterval(data.npc, data.sittingLifecycleGeneration)
    debugLog("sitting lifecycle scheduled", data.npc.recordId or data.npc.id, tostring(reason or "scheduled"), "seconds", tostring(data.sittingLifecycleNextAt - core.getSimulationTime()))
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
    if settings.sittingLifecycleEnabled ~= true then return nil end
    if not data or data.interactionType ~= "sitting" or data.state ~= STATES.interacting then return nil end
    if calibrationHoldActive(data) then
        data.sittingLifecycleNextAt = core.getSimulationTime() + 30
        return nil
    end
    if not data.sittingLifecycleNextAt or core.getSimulationTime() < data.sittingLifecycleNextAt then return nil end
    local key = tostring(data.npc and (data.npc.recordId or data.npc.id) or "<npc>") .. "::sitlife-action::" .. tostring(data.sittingLifecycleGeneration or 0)
    local chance = tonumber(settings.sittingLifecycleMoveSeatChance or SITTING_LIFECYCLE_MOVE_SEAT_CHANCE) or SITTING_LIFECYCLE_MOVE_SEAT_CHANCE
    if chance < 0 then chance = 0 elseif chance > 1 then chance = 1 end
    if profiles.stableUnitInterval(key) < chance then
        return "sitting_lifecycle_change_seat"
    end
    return "sitting_lifecycle_return_origin"
end

local function hoursSince(a, b)
    if a == nil or b == nil then return nil end
    local delta = (b - a) % 24
    return delta
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
        local age = hoursSince(item.rememberedHour, now)
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

local function chooseRememberedSittingCandidate(npc, candidates)
    if isNpcObjectValidForAssignment and not isNpcObjectValidForAssignment(npc) then return nil end
    local mem = sittingMemoryFor(npc)
    if not (mem and candidates) then return nil end
    for _, candidate in ipairs(candidates) do
        if candidate and candidate.interactionType == "sitting" and not occupiedSlots[candidate.slotKey]
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


local function isServiceOrFixedPostNpc(npc)
    if not npc or not types.NPC.objectIsInstance(npc) then return true end
    local ok, rec = pcall(types.NPC.record, npc.recordId)
    if not ok or not rec then return true end
    local cls = rec.class and string.lower(tostring(rec.class)) or ""
    if cls == "guard" or cls == "publican" then return true end
    local services = rec.servicesOffered
    if services and (services.Barter == true or services.Travel == true) then return true end
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
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
    sittingLifecycleMinSeconds = true,
    sittingLifecycleMaxSeconds = true,
    sittingLifecycleMoveSeatChance = true,
    sittingStandCooldownSeconds = true,
    sittingBriefWanderEnabled = true,
    sittingBriefWanderChance = true,
    sittingBriefWanderDistance = true,
    sittingAllowServiceNpcs = true,
    sittingServiceNpcRadius = true,
    userNpcBlacklist = true,
    userFurnitureBlacklist = true,
    userCellBlacklist = true,
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
    if key == sdpAnimatedMorrowindCompat.SETTING_KEY then
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

calibrationMenu = require('scripts/sitDownPlease/calibration/menu').create({
    world = world,
    core = core,
    types = types,
    util = util,
    profiles = profiles,
    calibrationLock = calibrationLock,
    interactingState = STATES.interacting,
    isObjValid = function(obj) return isObjValid(obj) end,
    buildCandidateSlots = function(...) return buildCandidateSlots(...) end,
    chooseCandidateForNpc = function(...) return chooseCandidateForNpc(...) end,
    sendConsiderInteraction = function(...) return sendConsiderInteraction(...) end,
    infoLog = infoLog,
    debugLog = debugLog,
    cellName = cellName,
    clearRelevantObjectCache = clearRelevantObjectCache,
    getAssignedActors = function() return assignedActors end,
    isSlotOccupied = function(slotKey)
        return slotKey ~= nil and occupiedSlots ~= nil and occupiedSlots[slotKey] ~= nil
    end,
    stopInteractionForNpc = function() return stopInteractionForNpc end,
    isNpcEligibleForInteraction = function(...) return isNpcRecordEligibleForInteraction(...) end,
})

wakeExit = require('scripts/sitDownPlease/sleeping/wakeExit').create({
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
            postWakeReturnOrigins[npcId] = nil
        end
        if tdata.returnOriginPosition then
            postWakeReturnOrigins[npcId] = {
                npc = npc,
                origin = tdata.returnOriginPosition,
                rotation = tdata.returnOriginRotation or tdata.rotation or npc.rotation,
                reason = tdata.reason,
            }
            debugLog(mode == "immediate" and "interaction return origin travel" or "queued interaction return origin travel", npc.recordId or npc.id, tostring(tdata.reason), "origin", tostring(tdata.returnOriginPosition))
            npc:sendEvent('SitDownPleaseStartAIPackage', {
                type = "Travel",
                destPosition = tdata.returnOriginPosition,
                isRepeat = false,
                cancelOther = true,
            })
        end
    end,
})

sleepRouteDoors.configure({
    infoLog = infoLog,
    debugLog = debugLog,
    isObjValid = function(obj) return isObjValid(obj) end,
    assignedActors = assignedActors,
    states = STATES,
    sleepReservationExistsForNpc = function(npc)
        local npcId = sleepReservationNpcId and sleepReservationNpcId(npc) or nil
        return npcId ~= nil and sleepReservationByNpc[npcId] ~= nil
    end,
})

local function processPendingSittingReassignments()
    local t = core.getSimulationTime()
    for npcId, item in pairs(pendingSittingReassignments) do
        local npc = type(item) == "table" and item.npc or nil
        if type(item) ~= "table" then
            -- Metadata such as lifecycle group timing lives beside queued NPC
            -- reassignments; only table entries are actual reassignment jobs.
        elseif item.due and item.due > t then
            -- not due yet
        elseif assignedActors[npcId] or wakeExit.hasPendingStandTeleport(npcId) then
            item.due = t + 0.25
        elseif not isObjValid(npc) then
            pendingSittingReassignments[npcId] = nil
        else
            local candidates = buildCandidateSlots(npc.cell, "sitting")
            local candidate = chooseCandidateForNpc(npc, candidates, "sitting", { avoidSlotKey = item.avoidSlotKey })
            if candidate then
                pendingSittingReassignments[npcId] = nil
                debugLog("sitting lifecycle reassign", npc.recordId or npc.id, "object", tostring(candidate.objectId), "slot", tostring(candidate.slotName))
                sendConsiderInteraction(npc, candidate)
            else
                pendingSittingReassignments[npcId] = nil
                debugLog("sitting lifecycle reassign no candidate", npc.recordId or npc.id)
            end
        end
    end
end

local function processPendingSittingOriginWalks()
    local t = core.getSimulationTime()
    for npcId, item in pairs(pendingSittingOriginWalks) do
        local npc = item and item.npc
        if not item or (item.due and item.due > t) then
            -- not due yet
        elseif not isObjValid(npc) or assignedActors[npcId] then
            pendingSittingOriginWalks[npcId] = nil
        elseif item.stage == "returning" then
            if not item.origin or (npc.position - item.origin):length() <= 80 or (item.startedAt and t - item.startedAt > item.timeout) then
                item.stage = "brief_wander"
                item.startedAt = t
                if item.idleDest then
                    npc:sendEvent('SitDownPleaseBriefWander', {
                        destPosition = item.idleDest,
                        reason = item.reason or "sitting_lifecycle_return_origin",
                        timeout = item.timeout or SITTING_IDLE_WALK_TIMEOUT,
                        radius = 70,
                    })
                    debugLog("sitting brief wander queued", npc.recordId or npc.id, "dest", tostring(item.idleDest))
                else
                    pendingSittingOriginWalks[npcId] = nil
                end
            elseif not item.startedAt then
                item.startedAt = t
            end
        elseif item.stage == "brief_wander" then
            if not item.idleDest or (npc.position - item.idleDest):length() <= 70 or (item.startedAt and t - item.startedAt > item.timeout) then
                npc:sendEvent('SitDownPleaseClearBriefTravel', { reason = "brief_wander_done", destPosition = item.idleDest, radius = 120 })
                if item.origin and (npc.position - item.origin):length() > 85 then
                    item.stage = "wander_returning"
                    item.startedAt = t
                    npc:sendEvent('SitDownPleaseStartAIPackage', {
                        type = "Travel",
                        destPosition = item.origin,
                        isRepeat = false,
                    })
                    debugLog("sitting brief wander return home", npc.recordId or npc.id, "origin", tostring(item.origin))
                else
                    pendingSittingOriginWalks[npcId] = nil
                end
            end
        elseif item.stage == "wander_returning" then
            if not item.origin or (npc.position - item.origin):length() <= 80 or (item.startedAt and t - item.startedAt > item.timeout) then
                npc:sendEvent('SitDownPleaseClearBriefTravel', { reason = "brief_wander_return_done", destPosition = item.origin, radius = 120 })
                pendingSittingOriginWalks[npcId] = nil
            end
        end
    end
end

local function addUniquePosition(list, pos)
    if not pos then return end
    for _, existing in ipairs(list) do
        if existing and (existing - pos):length() < 8 then return end
    end
    table.insert(list, pos)
end

local function rotationFromYaw(yaw, fallback)
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


local function sendBeginTransitionEvent(npc, data, reason)
    if not npc or not data then return end
    npc:sendEvent('BeginInteractionTransition', {
        interactionType = data.interactionType,
        targetPos = data.approachPos or data.position,
        reason = reason,
        radius = data.interactionType == "sleeping" and 900 or 80,
    })
end

local function profileAllowsBlockedApproach(profile)
    return profile and (profile.allowBlockedApproachTeleport == true or profile.allowBlockedApproachTransition == true)
end

local function settingAllowsBlockedApproach()
    return settings and settings.allowBlockedApproachTeleport == true
end

local function isNearEnoughForBlockedApproachFallback(npc, data)
    if not npc or not data then return false end

    local maxFinalDistance = data.profile.approachForceTransitionDistance or 240
    local maxObjectDistance = data.profile.approachForceObjectDistance or 260

    if data.finalPosition and (npc.position - data.finalPosition):length() <= maxFinalDistance then
        return true
    end

    if data.object and data.object.position and (npc.position - data.object.position):length() <= maxObjectDistance then
        return true
    end

    return false
end

local function sleepEntryGate(npc, data, reason)
    if not (npc and data and data.interactionType == "sleeping") then return true, "not_sleep" end
    if data.initialPlacement == true then return true, "initial_placement" end

    local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or math.huge
    local vertical = data.approachPos and math.abs((npc.position.z or 0) - (data.approachPos.z or 0)) or math.huge
    local transitionDistance = data.profile and (data.profile.transitionDistance or settings.transitionDistance) or settings.transitionDistance or 100
    local fallbackReason = reason == "blocked_approach_fallback"
        or reason == "approach_hard_timeout_fallback"
        or reason == "manual_assign_no_progress_fallback"
        or reason == "manual_assign_hard_timeout_fallback"

    if fallbackReason and data.manualSleepEntryOverride == true then
        return true, "manual_sleep_entry_override", approachDistance, vertical
    end

    if reason == "reached_approach" or data.reachedValidSleepApproach == true then
        return true, "reached_valid_sleep_approach", approachDistance, vertical
    end

    -- Blocked-approach fallback is allowed only as a tiny bed-edge correction,
    -- never as a bridge through walls, ceilings, stairs, or unrelated rooms.
    if fallbackReason then
        local nearApproach = approachDistance <= math.max(transitionDistance * 1.35, transitionDistance + 24)
        if nearApproach and vertical <= 60 then
            return true, "bed_edge_blocked_approach", approachDistance, vertical
        end
        local besideBed, besideReason, bedDistance, bedVertical = directlyBesideReservedBed(npc, data)
        if besideBed then
            return true, besideReason, bedDistance or approachDistance, bedVertical or vertical
        end
        if vertical > 90 then
            return false, "wrong_floor_or_unreachable", approachDistance, vertical
        end
        return false, besideReason == "not_directly_beside_bed" and "blocked_by_wall" or "no_path_to_bed", approachDistance, vertical
    end

    return false, "no_path_to_bed", approachDistance, vertical
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
        if data.initialPlacement ~= true and data.manualSleepEntryOverride ~= true and reason ~= "reached_approach" then
            local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or 0
            local objectDistance = data.object and (npc.position - data.object.position):length() or 0
            local maxApproach = (data.profile.transitionDistance or settings.transitionDistance or 100) * 2.25
            local maxObject = data.profile.approachForceObjectDistance or 320
            if approachDistance > maxApproach and objectDistance > maxObject then
                debugLog("sleep entry snap rejected", npc.recordId or npc.id, "reason", tostring(reason), "approachDistance", tostring(approachDistance), "objectDistance", tostring(objectDistance), "object", tostring(data.objectId))
                stopInteractionForNpc(npc, "visible_sleep_route_incomplete")
                return
            end
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
            initialPlacement = false,
            visibleSleep = true,
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

    local blockedFallbackAllowed = settingAllowsBlockedApproach() or profileAllowsBlockedApproach(data.profile)
    local directBedEntryAllowed = false
    if data.interactionType == "sleeping" then
        directBedEntryAllowed = directlyBesideReservedBed(npc, data) == true
    end
    if not (blockedFallbackAllowed or directBedEntryAllowed) then
        return false
    end

    if data.approachElapsed < forceMinSeconds and not directBedEntryAllowed then
        return false
    end

    if not isNearEnoughForBlockedApproachFallback(npc, data) then
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
        -- Patch 2: if the actor is genuinely stuck right at the reserved bed edge,
        -- let sleepEntryGate make the final safe/no-wall/no-floor decision instead
        -- of blanket-rejecting all blocked-approach fallbacks.
        beginTransition(npc, data, reason)
        return true
    end

    beginTransition(npc, data, reason)
    return true
end

local function objectLocalOffset(obj, offset)
    if not offset then return obj.position end
    local scale = tonumber(obj.scale) or 1
    if scale <= 0 then scale = 1 end
    return obj.position + obj.rotation * util.vector3((offset.x or 0) * scale, (offset.y or 0) * scale, (offset.z or 0) * scale)
end

local function objectSlotKey(obj, slotName)
    local pos = obj.position
    local posKey = pos and string.format("@%.1f,%.1f,%.1f", pos.x, pos.y, pos.z) or ""
    return tostring(obj.id or obj.recordId or "<object>") .. posKey .. "::" .. tostring(slotName or "default")
end

local function actorKey(npc)
    return cellContext.actorKey(npc)
end

clearSleepHomeOrigin = function(npc, reason)
    local cleared, key = sdpInteractionOrigins.clearHome(npc, { actorKey = actorKey })
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

sleepReservationNpcId = function(npc)
    return npc and tostring(npc.id or npc.recordId or "<npc>") or nil
end

local function sleepReservationOwnerLabel(reservation)
    return reservation and tostring(reservation.npcRecordId or reservation.npcId or "<none>") or "<none>"
end

local function releaseSleepReservationBySlot(slotKey, reason, expectedNpcId)
    if not slotKey then return end
    local reservation = sleepBedReservations[slotKey]
    if not reservation then return end
    if expectedNpcId and reservation.npcId and reservation.npcId ~= expectedNpcId then return end
    sleepBedReservations[slotKey] = nil
    if reservation.npcId and sleepReservationByNpc[reservation.npcId] == slotKey then
        sleepReservationByNpc[reservation.npcId] = nil
    end
    sleepLightControl.clearPendingSleeper(reservation.npcId, reason or "reservation_released", tostring(reason or ""):find("reject", 1, true) ~= nil or tostring(reason or ""):find("failed", 1, true) ~= nil)
    debugLog(
        "sleep reservation released",
        sleepReservationOwnerLabel(reservation),
        "slot", tostring(slotKey),
        "reason", tostring(reason or "released")
    )
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
    local npcId = type(npcOrId) == "string" and npcOrId or sleepReservationNpcId(npcOrId)
    if not npcId then return end
    local slotKey = sleepReservationByNpc[npcId]
    if slotKey then releaseSleepReservationBySlot(slotKey, reason, npcId) end
end

local function reserveSleepBed(npc, candidate, reason, state, ttl)
    if not (npc and candidate and candidate.slotKey) then return nil end
    local npcId = sleepReservationNpcId(npc)
    if not npcId then return nil end

    local existingSlot = sleepReservationByNpc[npcId]
    local now = sleepReservationNow()
    local expiresIn = tonumber(ttl or SLEEP_RESERVATION_SECONDS) or SLEEP_RESERVATION_SECONDS
    if existingSlot and existingSlot == candidate.slotKey and sleepBedReservations[existingSlot] then
        local reservation = sleepBedReservations[existingSlot]
        reservation.npc = npc
        reservation.object = candidate.object or reservation.object
        reservation.objectId = candidate.objectId or reservation.objectId
        reservation.state = state or reservation.state or "assigned"
        reservation.reason = reason or reservation.reason or "normal_assignment"
        reservation.expiresAt = now + expiresIn
        if settings.debug then
            debugLog(
                "sleep reservation reused",
                reservation.npcRecordId,
                "slot", tostring(candidate.slotKey),
                "object", tostring(candidate.objectId),
                "state", tostring(reservation.state),
                "reason", tostring(reservation.reason),
                "seconds", tostring(expiresIn)
            )
        end
        return reservation
    end
    if existingSlot and existingSlot ~= candidate.slotKey then
        releaseSleepReservationBySlot(existingSlot, "npc_reassigned_bed", npcId)
    end

    local reservation = {
        bedKey = candidate.slotKey,
        slotKey = candidate.slotKey,
        npc = npc,
        npcId = npcId,
        npcRecordId = npc.recordId or npc.id,
        cellName = npc.cell and cellName(npc.cell) or nil,
        objectId = candidate.objectId,
        object = candidate.object,
        state = state or "assigned",
        reason = reason or "normal_assignment",
        reservedAt = now,
        expiresAt = now + expiresIn,
        lastFailureReason = nil,
    }
    sleepBedReservations[candidate.slotKey] = reservation
    sleepReservationByNpc[npcId] = candidate.slotKey
    sleepLightControl.registerPendingSleeper(npc, {
        object = candidate.object,
        bed = candidate.object,
        bedId = candidate.objectId,
        position = candidate.object and candidate.object.position or npc.position,
        approachPosition = candidate.approachPos,
        initialPlacement = candidate.initialPlacement == true,
        state = state or "assigned",
    })
    debugLog(
        "sleep reservation created",
        reservation.npcRecordId,
        "slot", tostring(candidate.slotKey),
        "object", tostring(candidate.objectId),
        "state", tostring(reservation.state),
        "reason", tostring(reservation.reason),
        "seconds", tostring(expiresIn)
    )
    return reservation
end

updateSleepReservationState = function(npcOrId, state, reason, ttl)
    local npcId = type(npcOrId) == "string" and npcOrId or sleepReservationNpcId(npcOrId)
    if not npcId then return nil end
    local slotKey = sleepReservationByNpc[npcId]
    local reservation = slotKey and sleepBedReservations[slotKey] or nil
    if not reservation then return nil end
    reservation.state = state or reservation.state
    reservation.lastReason = reason or reservation.lastReason
    if ttl then reservation.expiresAt = sleepReservationNow() + ttl end
    debugLog(
        "sleep reservation state",
        sleepReservationOwnerLabel(reservation),
        "slot", tostring(slotKey),
        "state", tostring(reservation.state),
        "reason", tostring(reason or reservation.lastReason or "update")
    )
    return reservation
end

local function markSleepReservationFailed(npc, slotKey, reason)
    local npcId = sleepReservationNpcId(npc)
    local reservation = slotKey and sleepBedReservations[slotKey] or (npcId and sleepBedReservations[sleepReservationByNpc[npcId]] or nil)
    if not reservation then return end
    if npcId and reservation.npcId ~= npcId then return end
    reservation.state = "failed_cooldown"
    reservation.lastFailureReason = reason or "failed"
    reservation.expiresAt = sleepReservationNow() + SLEEP_FAILED_RESERVATION_SECONDS
    sleepLightControl.clearPendingSleeper(reservation.npcId, reason or "sleep_reservation_failed", true)
    debugLog(
        "sleep reservation failed cooldown",
        sleepReservationOwnerLabel(reservation),
        "slot", tostring(reservation.slotKey),
        "reason", tostring(reason or "failed"),
        "seconds", tostring(SLEEP_FAILED_RESERVATION_SECONDS)
    )
end

local function sleepReservationForCandidate(candidate)
    if not (candidate and candidate.slotKey) then return nil end
    local reservation = sleepBedReservations[candidate.slotKey]
    if not reservation then return nil end
    if reservation.expiresAt and sleepReservationNow() > reservation.expiresAt then
        releaseSleepReservationBySlot(candidate.slotKey, "expired")
        return nil
    end
    return reservation
end

local function sleepCandidateReservedByOther(npc, candidate)
    local reservation = sleepReservationForCandidate(candidate)
    if not reservation then return false, nil end
    local npcId = sleepReservationNpcId(npc)
    if npcId and reservation.npcId == npcId then return false, reservation end
    return true, reservation
end

local function pruneSleepReservations(reason)
    local now = sleepReservationNow()
    for slotKey, reservation in pairs(sleepBedReservations) do
        local expired = reservation.expiresAt and now > reservation.expiresAt
        local npc = reservation.npc
        local invalidNpc = npc ~= nil and not isObjValid(npc)
        local invalidObject = reservation.object ~= nil and not isObjValid(reservation.object)
        if expired or invalidNpc or invalidObject then
            releaseSleepReservationBySlot(slotKey, expired and "expired" or invalidNpc and "npc_invalid" or invalidObject and "bed_invalid" or reason)
        end
    end
end

local function originReferenceForSleep(npc)
    local home = sdpInteractionOrigins.homeFor(npc, { actorKey = actorKey })
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
    if not (data and data.interactionType == "sleeping" and finalPos) then return true, "not_sleep" end
    local profile = data.profile or {}
    local approach = data.approachPos or data.exitPosition
    local objPos = data.object and data.object.position or nil

    if approach then
        local maxAbove = tonumber(profile.sleepFinalMaxAboveApproachZ or SLEEP_FINAL_MAX_ABOVE_APPROACH_Z) or SLEEP_FINAL_MAX_ABOVE_APPROACH_Z
        local dz = (finalPos.z or 0) - (approach.z or 0)
        if dz > maxAbove then
            return false, "final_above_approach", dz, maxAbove
        end
    end

    if objPos then
        local maxAboveObject = tonumber(profile.sleepFinalMaxAboveObjectZ or SLEEP_FINAL_MAX_ABOVE_OBJECT_Z) or SLEEP_FINAL_MAX_ABOVE_OBJECT_Z
        local dzObj = (finalPos.z or 0) - (objPos.z or 0)
        if dzObj > maxAboveObject then
            return false, "final_above_bed_object", dzObj, maxAboveObject
        end
        local maxBelowObject = tonumber(profile.sleepFinalMaxBelowObjectZ or 360) or 360
        if dzObj < -maxBelowObject then
            return false, "final_below_bed_object", dzObj, maxBelowObject
        end
    end

    if npc and npc.position and data.initialPlacement ~= true and trigger ~= "reached_approach" and data.reachedValidSleepApproach ~= true then
        local maxAboveActor = tonumber(profile.sleepFinalMaxAboveActorZ or 240) or 240
        local dzNpc = (finalPos.z or 0) - (npc.position.z or 0)
        if dzNpc > maxAboveActor then
            return false, "final_above_actor_floor", dzNpc, maxAboveActor
        end
    end

    return true, "ok"
end

directlyBesideReservedBed = function(npc, data)
    if not (npc and data and data.interactionType == "sleeping" and data.object and data.object.position) then return false, "missing" end
    local npcId = sleepReservationNpcId(npc)
    local reservationSlotKey = npcId and sleepReservationByNpc[npcId] or nil
    local reservation = reservationSlotKey and sleepBedReservations[reservationSlotKey] or nil
    if reservation and reservation.slotKey ~= data.slotKey then return false, "different_reservation" end
    local objectDistance = (npc.position - data.object.position):length()
    local approachDistance = data.approachPos and (npc.position - data.approachPos):length() or objectDistance
    local approachVertical = data.approachPos and math.abs((npc.position.z or 0) - (data.approachPos.z or 0)) or 0
    local objectVertical = math.abs((npc.position.z or 0) - (data.object.position.z or 0))
    local maxDist = tonumber(data.profile and data.profile.sleepDirectEntryDistance or SLEEP_DIRECT_BED_ENTRY_DISTANCE) or SLEEP_DIRECT_BED_ENTRY_DISTANCE
    local maxVertical = tonumber(data.profile and data.profile.sleepDirectEntryVertical or SLEEP_DIRECT_BED_ENTRY_VERTICAL) or SLEEP_DIRECT_BED_ENTRY_VERTICAL
    local maxApproach = math.max(maxDist * 1.35, maxDist + 35)
    if objectDistance <= maxDist
        and approachDistance <= maxApproach
        and objectVertical <= maxVertical + 45
        and (approachVertical <= maxVertical or objectVertical <= maxVertical) then
        return true, "directly_beside_bed", math.max(objectDistance, approachDistance), math.max(approachVertical, objectVertical)
    end
    if objectDistance <= maxDist and approachDistance > maxApproach then
        return false, "beside_bed_wrong_entry_side", approachDistance, math.max(approachVertical, objectVertical)
    end
    return false, "not_directly_beside_bed", objectDistance, math.max(approachVertical, objectVertical)
end

local SLEEP_ROUTE_REJECT_COOLDOWN_SECONDS = 90

local function sleepRouteRejectReason(reason)
    local text = tostring(reason or "")
    return text == "no_path_to_bed"
        or text == "wrong_floor_or_unreachable"
        or text == "blocked_by_wall"
        or text == "route_too_indirect"
        or text == "approach_too_far_from_navmesh"
        or text == "approach_navmesh_behind_collision"
        or text == "visible_sleep_route_incomplete"
        or text == "sleep_route_incomplete"
        or text == "sleep_entry_rejected"
        or text == "public_bed_requires_door_assist"
        or text == "locked_route_door"
        or text == "blocked_route_door"
end

local function sleepRouteRejectKey(npc, slotKey)
    if not (npc and slotKey) then return nil end
    return tostring(npc.id or npc.recordId or "<npc>") .. "::" .. tostring(slotKey)
end

local function sleepRouteRejectCooldownActive(npc, slotKey)
    local key = sleepRouteRejectKey(npc, slotKey)
    if not key then return false end

    local untilTime = sleepRouteRejectCooldowns[key]
    if not untilTime then return false end
    if realTimeNow() < untilTime then return true end

    sleepRouteRejectCooldowns[key] = nil
    return false
end

local function markSleepRouteRejected(npc, slotKey, reason)
    local key = sleepRouteRejectKey(npc, slotKey)
    if not key then return end

    sleepRouteRejectCooldowns[key] = realTimeNow() + SLEEP_ROUTE_REJECT_COOLDOWN_SECONDS
    debugLog(
        "sleep_route_reject_cooldown_from_local",
        npc.recordId or npc.id,
        "slot", tostring(slotKey),
        "reason", tostring(reason),
        "seconds", tostring(SLEEP_ROUTE_REJECT_COOLDOWN_SECONDS)
    )
end

local function sleepWakeBiasForNpc(npc)
    return require('scripts/sitDownPlease/interactions/sleeping').wakeBiasForNpc(npc, settings, profiles, types)
end

local function npcHasTravelService(npc)
    if not (npc and npc.recordId and types.NPC and types.NPC.record) then return false end
    local okRecord, rec = pcall(types.NPC.record, npc.recordId)
    if not okRecord or not rec then return false end
    local services = rec.servicesOffered
    if services and services.Travel == true then return true end
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
end

local function npcHasServiceRole(npc)
    if not (npc and npc.recordId and types.NPC and types.NPC.record) then return false end
    local okRecord, rec = pcall(types.NPC.record, npc.recordId)
    if not okRecord or not rec then return false end
    local services = rec.servicesOffered
    -- Sitting may include trainers and travel-service NPCs if they remain near
    -- their post. Barter merchants are intentionally excluded from sitting.
    if services and (services.Travel == true or services.Training == true) then return true end
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
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

local MORNING_WAKE_REASONS = {
    scheduled_wake_time = true,
    sleep_window_ended = true,
    time_advance_sleep_window_ended = true,
    daytime_failsafe = true,
}

local function shouldWalkToOriginAfterWake(reason)
    if not reason then return false end
    local text = tostring(reason)
    if MORNING_WAKE_REASONS[text] == true then return true end
    return text:find("scheduled_wake", 1, true) ~= nil
        or text:find("sleep_window_ended", 1, true) ~= nil
end

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

local function sleepEligibilityForNpc(npc, cell, assignmentContext)
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

    local initialPlacement = settings.sleepInitialPlacementEnabled == true
        and forceInBedPhase == true
        and assignmentContext
        and (assignmentContext.sleepInitialPlacementAllowed == true or assignmentContext.initialPlacementAllowed == true)

    if not initialPlacement and settings.sleepAvoidObservedPlayer == true then
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

local function isFactionLeader(npc)
    if not npc or not types.NPC.objectIsInstance(npc) then return false end
    if not (types.NPC.getFactions and types.NPC.getFactionRank) then return false end
    if not (require('openmw.core').factions and require('openmw.core').factions.records) then return false end

    local okFactions, factionIds = pcall(types.NPC.getFactions, npc)
    if not okFactions or not factionIds then return false end

    local core = require('openmw.core')
    for _, factionId in ipairs(factionIds) do
        local factionRec = core.factions.records[factionId] or core.factions.records[string.lower(factionId)]
        if factionRec and factionRec.ranks then
            local maxRank = #factionRec.ranks
            local okRank, rank = pcall(types.NPC.getFactionRank, npc, factionId)
            if okRank and rank == maxRank and rank > 0 then
                return true
            end
        end
    end

    return false
end

local function npcIsFollowerByUtil(npc)
    if not (npc and npc.id and I and I.FollowerDetectionUtil and I.FollowerDetectionUtil.getFollowerList) then return false end
    local ok, followers = pcall(I.FollowerDetectionUtil.getFollowerList)
    if not ok or type(followers) ~= "table" then return false end
    local state = followers[npc.id]
    if not state then return false end
    if state.followsPlayer == true then return true end
    local leader = state.leader or state.superLeader
    return leader and leader.type and types.Player and leader.type == types.Player or false
end


local function externalAnimationNpcReason(npc)
    if profiles.externalAnimationNpcReason then return profiles.externalAnimationNpcReason(npc) end
    local recordId = npc and npc.recordId and string.lower(tostring(npc.recordId)) or ""
    if recordId:find("^am_") then return "external_animation_npc" end
    return nil
end

local function candidatePhysicallyClaimedByExternalNpc(npc, candidate)
    if not (npc and npc.cell and candidate and candidate.object and candidate.object.position) then return false, nil, nil end
    -- This is not a default-space assignment. It only treats furniture as claimed
    -- when an external actor's known pose matches the candidate type and the
    -- actor is physically close to that furniture in the current cell. Keep the
    -- sitting radius tight so nearby animated actors do not claim unrelated chairs.
    local claimRadius = candidate.interactionType == "sleeping" and 150 or 82
    local claimVertical = candidate.interactionType == "sleeping" and 95 or 70
    for _, other in ipairs(npc.cell:getAll(types.NPC)) do
        if other and other.id and other.id ~= npc.id then
            local reason = profiles.externalAnimationClaimReason and profiles.externalAnimationClaimReason(other, candidate) or nil
            if reason and other.position then
                local delta = other.position - candidate.object.position
                if math.abs(delta.z or 0) <= claimVertical and delta:length() <= claimRadius then
                    return true, reason, other
                end
            end
        end
    end
    return false, nil, nil
end

local function isBarOrCounterRecord(recordId)
    local id = tostring(recordId or ""):lower()
    if id == "" then return false end

    -- Station protection must only treat actual bar/counter statics as station
    -- dividers. The earlier substring test matched records like barrels because
    -- they contain "bar", which could falsely mark an NPC as behind a counter.
    if id:find("barrel", 1, true) or id:find("barrow", 1, true) or id:find("barstool", 1, true) then return false end
    if id:find("stool", 1, true) or id:find("chair", 1, true) or id:find("bench", 1, true) then return false end

    if id:find("counter", 1, true) then return true end
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

local function npcLooksLikeVampire(npc, rec)
    local recordId = npc and npc.recordId and string.lower(tostring(npc.recordId)) or ""
    local cls = rec and rec.class and string.lower(tostring(rec.class)) or ""
    local name = rec and rec.name and string.lower(tostring(rec.name)) or ""
    if recordId:find("vampire", 1, true) or cls:find("vampire", 1, true) or name:find("vampire", 1, true) then
        return true
    end

    local okEffects, hasEffect = pcall(function()
        if not (types and types.Actor and types.Actor.activeEffects and npc) then return false end
        local effects = types.Actor.activeEffects(npc)
        if not effects or not effects.getEffect then return false end
        local vamp = effects:getEffect("vampirism")
        return vamp ~= nil and (tonumber(vamp.magnitude or 0) or 0) > 0
    end)
    return okEffects and hasEffect == true
end

isNpcRecordEligibleForInteraction = function(npc, interactionType)
    if not npc or not npc.id or not types.NPC.objectIsInstance(npc) then
        return false, "not_npc"
    end

    local dead, deadReason = actorDeadReason(npc)
    if dead then return false, deadReason end

    local blacklistedReason = profiles.npcBlacklistedReason and profiles.npcBlacklistedReason(npc, settings) or nil
    if blacklistedReason then return false, blacklistedReason end

    local hiddenReason = assignmentEligibility.hiddenOrStagedNpcReason(npc)
    if hiddenReason then
        return false, hiddenReason
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

    if npcIsFollowerByUtil(npc) then
        return false, "follower"
    end
    if npc.id and followerPackageActors[npc.id] == true then
        return false, "active_follow_or_escort_package"
    end

    local okRecord, rec = pcall(types.NPC.record, npc.recordId)
    if not okRecord or not rec then
        -- Keep legacy behavior if the record cannot be inspected. The local script
        -- still performs final validation before accepting any interaction.
        return true, nil
    end

    if npcLooksLikeVampire(npc, rec) then
        return false, "vampire"
    end

    local cls = rec.class and string.lower(tostring(rec.class)) or nil
    if cls == "guard" or cls == "publican" then
        return false, "guard_or_publican_class"
    end

    local services = rec.servicesOffered
    if interactionType == "sitting" then
        -- Traders/barter merchants should not be pulled into seats. Trainers and
        -- travel-service NPCs may sit only if the selected seat is very close to
        -- their post; radius enforcement happens during candidate scoring.
        if services and services.Barter == true then
            return false, "barter_service_npc"
        end
        if settings.sittingAllowServiceNpcs ~= true then
            if services then
                if services.Travel == true then return false, "travel_service_npc" end
                if services.Training == true then return false, "training_service_npc" end
            end
            if rec.travelDestinations and #rec.travelDestinations > 0 then
                return false, "travel_destination_npc"
            end
            if isFactionLeader(npc) then
                return false, "faction_leader"
            end
        end
    elseif interactionType == "sleeping" then
        -- Sleep is time-gated and bed-gated. Merchants, trainers, quest givers,
        -- and faction leaders may sleep if a qualifying bed is genuinely local.
        -- Publicans remain awake via the class rule above. Travel NPCs are allowed
        -- but use a smaller bed-search radius so they do not wander away from posts.
    else
        if services then
            if services.Travel == true then return false, "travel_service_npc" end
            if services.Barter == true then return false, "barter_service_npc" end
            if services.Training == true then return false, "training_service_npc" end
        end
    end

    return true, nil
end

local function directionBetween(fromPos, toPos)
    if not fromPos or not toPos then return nil end
    local delta = toPos - fromPos
    local flat = util.vector2(delta.x, delta.y)
    if flat:length() <= 1 then return nil end
    local norm = flat:normalize()
    return util.vector3(norm.x, norm.y, 0)
end

local function recordLooksLikeBarSurface(recordId)
    local id = recordId and string.lower(tostring(recordId)) or ""
    if id == "" then return false end
    if id:find("barrel", 1, true) or id:find("barrow", 1, true) or id:find("barstool", 1, true) then return false end
    if id:find("stool", 1, true) or id:find("chair", 1, true) or id:find("bench", 1, true) then return false end
    if id:find("counter", 1, true) then return true end
    if id:find("_bar_", 1, true) or id:find("/bar_", 1, true) then return true end
    if id:match("^bar[_%-%s]") or id:match("[_%-%s]bar[_%-%s]") then return true end
    return false
end

local function sittingFocusKindFromText(text)
    local id = text and string.lower(tostring(text)) or ""
    if id == "" then return nil end
    -- Do not accidentally treat the chair/bench/stool itself as the thing to face.
    if id:find("chair", 1, true) or id:find("bench", 1, true) or id:find("stool", 1, true) then
        return nil
    end
    if recordLooksLikeBarSurface(id) then return "bar" end
    if id:find("table", 1, true) or id:find("desk", 1, true) then return "table" end
    if id:find("furnm_shelf_02", 1, true)
        or id:find("furn_n_m_shelf_02", 1, true)
        or id:find("furn_n_m_shlf02", 1, true) then return "table" end
    if id:find("hearth", 1, true)
        or id:find("fireplace", 1, true)
        or id:find("pitfire", 1, true)
        or id:find("campfire", 1, true)
        or id:find("fire", 1, true)
        or id:find("logpile", 1, true) then return "fire" end
    return nil
end

local function objectNameForFocus(obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then return obj.type.record(obj) end
        return nil
    end)
    if ok and rec and rec.name then return rec.name end
    return nil
end

local function sittingFocusKind(obj)
    if not obj then return nil end
    local text = tostring(obj.recordId or "") .. " " .. tostring(profiles.objectModelPath(obj) or "") .. " " .. tostring(objectNameForFocus(obj) or "")
    return sittingFocusKindFromText(text)
end

local function sittingSeatText(obj)
    if not obj then return "" end
    return (tostring(obj.recordId or "") .. " "
        .. tostring(profiles.objectModelPath(obj) or "") .. " "
        .. tostring(objectNameForFocus(obj) or "")):lower()
end

local function sittingSeatLooksLikeStool(obj)
    local text = sittingSeatText(obj)
    return text:find("stool", 1, true) ~= nil or text:find("barstool", 1, true) ~= nil
end

sdpSittingAssignmentObjectForwardDirection = function(obj)
    local yaw = 0
    if obj and obj.rotation then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then yaw = value end
    end
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

sdpSittingAssignmentForwardDotToFocus = function(seatObj, fromPos, focusPos)
    local direction = directionBetween(fromPos, focusPos)
    if not direction then return nil end
    local forward = sdpSittingAssignmentObjectForwardDirection(seatObj)
    return (forward.x or 0) * (direction.x or 0) + (forward.y or 0) * (direction.y or 0)
end

local function findNearestSittingFocusDirection(cell, fromPos, seatObj)
    -- Patch 34: contextual table animations/props are inactive. Keep the useful
    -- facing behavior only: tables/desks/counters/bars pull the seated NPC's
    -- gaze toward the surface, fires are a weaker cue, and wall/open-space
    -- fallback still happens later in the local script.
    local bestObj = nil
    local bestKind = nil
    local bestScore = nil
    local maxDist = 340
    local focusCandidates = {}
    local seatIsStool = sittingSeatLooksLikeStool(seatObj)
    local seatIsBarstool = sittingSeatText(seatObj):find("barstool", 1, true) ~= nil

    for _, obj in ipairs(cell:getAll()) do
        if obj and obj.position then
            local kind = sittingFocusKind(obj)
            if kind then
                local dist = (obj.position - fromPos):length()
                if dist <= maxDist then
                    local score = dist
                    local forwardDot = nil
                    if kind == "bar" then
                        if seatIsBarstool then
                            score = score - (dist <= 180 and 95 or 35)
                        elseif seatIsStool then
                            score = score + 35
                        else
                            score = score - 60
                        end
                    end
                    if kind == "table" then score = score - (seatIsStool and 20 or 35) end
                    if kind == "fire" then score = score + 30 end
                    if seatIsBarstool and kind == "bar" and dist <= 180 then
                        forwardDot = sdpSittingAssignmentForwardDotToFocus(seatObj, fromPos, obj.position)
                        if forwardDot and forwardDot > 0.35 then
                            score = score - 140
                        elseif forwardDot and forwardDot < -0.2 then
                            score = score + 45
                        end
                    end
                    if kind == "table" or kind == "bar" or kind == "fire" then
                        focusCandidates[#focusCandidates + 1] = {
                            object = obj,
                            recordId = obj.recordId,
                            model = profiles.objectModelPath(obj),
                            name = objectNameForFocus(obj),
                            kind = kind,
                            position = obj.position,
                            distance = dist,
                            score = score,
                            forwardDot = forwardDot,
                        }
                    end
                    if not bestScore or score < bestScore then
                        bestObj = obj
                        bestKind = kind
                        bestScore = score
                    end
                end
            end
        end
    end

    if bestObj then
        table.sort(focusCandidates, function(a, b)
            if seatIsStool then
                local scoreA = a.score or math.huge
                local scoreB = b.score or math.huge
                if scoreA ~= scoreB then return scoreA < scoreB end
            end
            return (a.distance or math.huge) < (b.distance or math.huge)
        end)
        while #focusCandidates > 8 do table.remove(focusCandidates) end
        return directionBetween(fromPos, bestObj.position), bestObj, bestKind, focusCandidates
    end
    return nil, nil, nil, focusCandidates
end

local function sittingCandidateSeatPosition(obj, profile, slot, slotIndex)
    if not (obj and obj.position) then return nil end
    local slots = profile and profile.slots or nil
    local slotCount = slots and #slots or 0
    local category = tostring(profile and (profile.seatCategory or profile.type or profile.seatType) or ""):lower()
    if slotCount <= 1 or category:find("bench", 1, true) == nil then return obj.position end

    local name = tostring(slot and slot.name or ""):lower()
    local index = tonumber(slotIndex or 1) or 1
    if name == "seat_a" then index = 1
    elseif name == "seat_b" then index = 2
    elseif name == "seat_c" then index = 3
    elseif name == "seat_d" then index = 4
    end

    local spacing = slotCount >= 3 and 64 or 82
    local centeredIndex = index - ((slotCount + 1) / 2)
    return objectLocalOffset(obj, { x = centeredIndex * spacing, y = 0, z = 0 })
end

local function relevantCacheKey(cell, interactionType)
    return cellContext.cellInteractionCacheKey(cell, interactionType)
end

local function collectRelevantObjects(cell, interactionType)
    local key = relevantCacheKey(cell, interactionType)
    local cached = relevantObjectCache[key]
    if cached then
        if settings.debug == true then
            debugLog(
                "relevant object cache hit", interactionType,
                "cell", tostring(cellName(cell)),
                "relevant", tostring(#cached.objects),
                "scanned", tostring(cached.scannedCount),
                "irrelevant", tostring(cached.irrelevantCount)
            )
        end
        return cached.objects, cached.scannedCount, cached.relevantCount, cached.irrelevantCount, true
    end

    local objects = {}
    local scannedCount = 0
    local relevantCount = 0

    for _, obj in ipairs(cell:getAll()) do
        scannedCount = scannedCount + 1
        local isRelevant = true
        if profiles.objectLooksRelevantForInteraction then
            isRelevant = profiles.objectLooksRelevantForInteraction(obj, interactionType, settings) == true
        end
        if not isRelevant and settings.debug == true then
            if interactionType == "sleeping" and profiles.sleepFallbackCandidateStatus then
                local ok, reason = profiles.sleepFallbackCandidateStatus(obj)
                if ok ~= true and reason and reason ~= "non_sleep_object" then
                    local objectId = tostring(obj and (obj.recordId or obj.id))
                    local message = "sleep candidate rejected non_sleep_object"
                    if reason == "clothing" then message = "sleep candidate rejected clothing" end
                    debugLogOnce(
                        claimRejectLogCache,
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
                    debugLogOnce(
                        claimRejectLogCache,
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
    relevantObjectCache[key] = {
        objects = objects,
        scannedCount = scannedCount,
        relevantCount = relevantCount,
        irrelevantCount = irrelevantCount,
    }

    return objects, scannedCount, relevantCount, irrelevantCount, false
end

buildCandidateSlots = function(cell, interactionType, options)
    options = options or {}
    local candidates = {}
    local currentHour = profiles.getGameHour()
    local rejectedCount = 0
    local relevantObjects, scannedCount, relevantCount, irrelevantCount, cacheHit = collectRelevantObjects(cell, interactionType)

    for _, obj in ipairs(relevantObjects or {}) do
        if isObjValid(obj) then
            local profile, reason = profiles.getProfileForObject(obj, interactionType, settings)
            if profile then
                local timeOk, timeReason = true, nil
                if options.ignoreTimeGate ~= true then
                    timeOk, timeReason = profiles.isInteractionAllowedByTime(interactionType, profile, settings, currentHour)
                end
                if timeOk then
                    local model = profiles.objectModelPath(obj)
                    local slots = profile.slots or { { name = "default" } }

                    for i, slot in ipairs(slots) do
                        local slotName = profiles.slotName(slot, i)
                        local slotKey = objectSlotKey(obj, slotName)
                        local occupiedByTestNpc, testNpcData = assignmentEligibility.slotOccupiedByTestNpc(occupiedSlots, assignedActors, slotKey)
                        if not occupiedSlots[slotKey] or (options.allowOccupiedByTestNpc == true and occupiedByTestNpc == true) then
                            local approachPos = nil
                            if interactionType ~= "sleeping" then
                                approachPos = objectLocalOffset(obj, slot.approachOffset or (profile.approachOffsets and profile.approachOffsets[1]))
                            end
                            local seatPos = nil
                            if interactionType == "sitting" then
                                seatPos = sittingCandidateSeatPosition(obj, profile, slot, i)
                            end
                            local sleepSlotPos = nil
                            if interactionType == "sleeping" then
                                local rootOffset = slot and slot.sleepRootLocalOffset or profile.sleepRootLocalOffset
                                local sleepOffset = slot and slot.sleepOffset or profile.sleepOffset
                                local localOffset = {
                                    x = (rootOffset and rootOffset.x or 0) + (sleepOffset and sleepOffset.x or 0),
                                    y = (rootOffset and rootOffset.y or 0) + (sleepOffset and sleepOffset.y or 0),
                                    z = 0,
                                }
                                sleepSlotPos = (localOffset.x ~= 0 or localOffset.y ~= 0) and objectLocalOffset(obj, localOffset) or obj.position
                            end
                            local preferredFacingDirection = nil
                            local facingObject = nil
                            local facingKind = nil
                            local facingCandidates = nil
                            if interactionType == "sitting" then
                                local seatCategory = string.lower(tostring(profile.seatCategory or profile.type or ""))
                                local rotationMode = string.lower(tostring(profile.rotationMode or ""))
                                if not (seatCategory:find("bench", 1, true) and rotationMode == "faceopenside") then
                                    preferredFacingDirection, facingObject, facingKind, facingCandidates = findNearestSittingFocusDirection(cell, seatPos or obj.position, obj)
                                end
                            end

                            table.insert(candidates, {
                                object = obj,
                                objectId = obj.recordId,
                                model = model,
                                profile = profile,
                                profileId = profile.profileId,
                                interactionType = interactionType,
                                slot = slot,
                                slotName = slotName,
                                slotKey = slotKey,
                                occupiedByTestNpc = occupiedByTestNpc == true,
                                occupiedByTestNpcActor = testNpcData and testNpcData.npc or nil,
                                occupiedByTestNpcInteractionType = testNpcData and testNpcData.interactionType or nil,
                                position = sleepSlotPos or seatPos,
                                approachPos = approachPos,
                                preferredFacingDirection = preferredFacingDirection,
                                facingObject = facingObject,
                                facingObjectId = facingObject and facingObject.recordId or nil,
                                facingObjectModel = facingObject and profiles.objectModelPath(facingObject) or nil,
                                facingObjectName = facingObject and objectNameForFocus(facingObject) or nil,
                                facingKind = facingKind,
                                facingObjectPosition = facingObject and facingObject.position or nil,
                                facingCandidates = facingCandidates,
                                fallbackUsed = reason == "fallback_profile",
                                currentHour = currentHour,
                            })
                            if interactionType == "sleeping" and reason == "fallback_profile" and settings.debug == true then debugLog("fallback_sleeping accepted bedlike_candidate", tostring(obj.recordId or obj.id), "model", tostring(model), "reason", tostring(profile.fallbackSleepCandidateReason)) end
                        elseif settings.debug then
                            rejectedCount = rejectedCount + 1
                            debugLog("reject object occupied", interactionType, profiles.objectDebugId(obj), slotKey)
                        end
                    end
                else
                    rejectedCount = rejectedCount + 1
                    debugLog("reject by time", interactionType, profiles.objectDebugId(obj), timeReason, "hour", tostring(currentHour))
                end
            elseif settings.debug and reason ~= "profile_for_different_interaction" then
                rejectedCount = rejectedCount + 1
                local model = profiles.objectModelPath(obj)
                debugLog("reject relevant object", interactionType, profiles.objectDebugId(obj), reason, "model", tostring(model))
            end
        end
    end

    debugLog(
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

local function interactionOrderForCurrentTime()
    local currentHour = profiles.getGameHour()
    if settings.enableSleeping == true
        and profiles.isHourInWindow(currentHour, settings.sleepStartHour, settings.sleepEndHour) then
        return { "sleeping", "sitting" }
    end
    return { "sitting", "sleeping" }
end

local function candidateSearchRadius(interactionType, candidate, context)
    if context and context.debugForce == true then
        return settings.sleepInitialPlacementSearchRadius or settings.sleepSearchRadius or settings.maxSearchRadius or 5000
    end

    if interactionType == "sleeping" then
        local radius
        if context and context.initialPlacement == true then
            radius = settings.sleepInitialPlacementSearchRadius or 5000
        elseif candidate and candidate.profile and candidate.profile.sleepSearchRadius then
            radius = candidate.profile.sleepSearchRadius
        else
            radius = settings.sleepSearchRadius or settings.maxSearchRadius or 700
        end

        -- Travel NPCs may sleep, but only if the bed is very local to their post.
        -- This avoids silt strider/boat/guild-guide style NPCs walking across the
        -- cell to sleep while still allowing a bed right behind/near them.
        if context and context.npc and npcHasTravelService(context.npc) then
            radius = math.min(radius, 650)
        end

        local originPreferredDist = context and context.npc and candidate and sleepOriginPreferredDistance(context.npc, candidate) or nil
        local bedAccessBlockReason = context and context.npc and candidate and sleepBedAccess.normalAssignmentBlockReason({
            cell = context.npc.cell,
            candidate = candidate,
            originPreferred = originPreferredDist ~= nil,
            initialPlacement = context.initialPlacement == true,
            debugForce = context.debugForce == true,
            helpers = {
                objectModelPath = profiles.objectModelPath,
                objectName = objectNameForFocus,
                types = types,
            },
        }) or nil
        if bedAccessBlockReason then
            if settings.debug then
                debugLog(
                    "sleep bed access radius blocked",
                    context.npc.recordId or context.npc.id,
                    "object", tostring(candidate.objectId),
                    "slot", tostring(candidate.slotName),
                    "reason", tostring(bedAccessBlockReason)
                )
            end
            radius = 0
        end

        -- Public/service interiors often contain rentable/player rooms behind doors.
        -- Do not let normal late-night scans pull arbitrary idle NPCs across the
        -- building into distant beds; origin-preferred beds and load-door initial
        -- placement keep their wider search.
        if context and context.npc and candidate and sleepBedAccess.shouldRestrictDoorAssist(context.npc.cell, originPreferredDist ~= nil, context.debugForce == true) then
            if not (context and context.initialPlacement == true) then
                radius = math.min(radius, 260)
            end
        end
        return radius
    end

    if interactionType == "sitting" and context and context.npc and settings.sittingAllowServiceNpcs == true and npcHasServiceRole(context.npc) then
        return math.min(settings.maxSearchRadius or 700, settings.sittingServiceNpcRadius or 200, 220)
    end

    return settings.maxSearchRadius or 700
end

chooseCandidateForNpc = function(npc, candidates, interactionType, context)
    context = context or {}
    context.npc = npc
    if not isNpcObjectValidForAssignment(npc) then return nil end
    local bestIndex = nil
    local bestDist = nil
    local bestRadius = nil
    local nearestCandidate = nil
    local nearestDist = nil
    local nearestRadius = nil
    local preferredIndex = nil
    local preferredDist = nil
    local preferredRadius = nil
    local preferredRouteBlocked = false
    local preferredRouteBlockedObject = nil
    local preferredRouteBlockedDist = nil

    pruneSleepReservations("choose_candidate")

    for i, candidate in ipairs(candidates) do
        if candidate and candidate.object and not occupiedSlots[candidate.slotKey] and candidate.slotKey ~= context.avoidSlotKey then
            local candidateType = interactionType or candidate.interactionType
            local physicallyClaimed, claimReason, claimingNpc = candidatePhysicallyClaimedByExternalNpc(npc, candidate)
            local stationedBehindCounter = candidatePullsStationedNpcFromCounter(npc, candidate)
            if physicallyClaimed then
                if settings.debug then
                    local claimKey = tostring(candidateType) .. "|" .. tostring(npc and npc.id) .. "|" .. tostring(candidate.objectId) .. "|" .. tostring(claimingNpc and claimingNpc.id)
                    debugLogOnce(
                        claimRejectLogCache,
                        claimKey,
                        "reject object physically claimed",
                        npc.recordId or npc.id,
                        "type", tostring(candidateType),
                        "object", tostring(candidate.objectId),
                        "by", tostring(claimingNpc and (claimingNpc.recordId or claimingNpc.id)),
                        "reason", tostring(claimReason)
                    )
                end
            elseif stationedBehindCounter then
                if settings.debug then
                    debugLog(
                        "reject stationed behind counter",
                        npc.recordId or npc.id,
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName),
                        "reason", "station_side_protection"
                    )
                end
            elseif candidateType == "sleeping" and sleepRouteRejectCooldownActive(npc, candidate.slotKey) then
                local originPreferredDist = sleepOriginPreferredDistance(npc, candidate)
                if originPreferredDist then
                    preferredRouteBlocked = true
                    preferredRouteBlockedObject = candidate.objectId
                    if not preferredRouteBlockedDist or originPreferredDist < preferredRouteBlockedDist then
                        preferredRouteBlockedDist = originPreferredDist
                    end
                end
                if settings.debug then
                    debugLog(
                        "reject sleep route cooldown",
                        npc.recordId or npc.id,
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName)
                    )
                end
            elseif candidateType == "sleeping" and sleepCandidateReservedByOther(npc, candidate) then
                local _, reservation = sleepCandidateReservedByOther(npc, candidate)
                if settings.debug then
                    debugLog(
                        "reject sleep bed reserved",
                        npc.recordId or npc.id,
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName),
                        "owner", sleepReservationOwnerLabel(reservation)
                    )
                end
            else
                local originPreferredDist = candidateType == "sleeping" and sleepOriginPreferredDistance(npc, candidate) or nil
                local sleepAccessBlockReason = candidateType == "sleeping" and sleepBedAccess.normalAssignmentBlockReason({
                    cell = npc.cell,
                    candidate = candidate,
                    originPreferred = originPreferredDist ~= nil,
                    initialPlacement = context.initialPlacement == true,
                    debugForce = context.debugForce == true,
                    helpers = {
                        objectModelPath = profiles.objectModelPath,
                        objectName = objectNameForFocus,
                        types = types,
                    },
                }) or nil
                local distanceTarget = candidateType == "sleeping" and candidate.position or candidate.object.position
                local dist = (npc.position - (distanceTarget or candidate.object.position)):length()
                local radius = candidateSearchRadius(candidateType, candidate, context)

                if not nearestDist or dist < nearestDist then
                    nearestCandidate = candidate
                    nearestDist = dist
                    nearestRadius = radius
                end

                if sleepAccessBlockReason then
                    if settings.debug then
                        debugLog(
                            "reject sleep bed access",
                            npc.recordId or npc.id,
                            "object", tostring(candidate.objectId),
                            "slot", tostring(candidate.slotName),
                            "reason", tostring(sleepAccessBlockReason)
                        )
                    end
                elseif candidateType == "sleeping" then
                    if originPreferredDist and dist <= radius and (not preferredDist or originPreferredDist < preferredDist) then
                        preferredIndex = i
                        preferredDist = originPreferredDist
                        preferredRadius = radius
                    end

                    if dist <= radius and (not bestDist or dist < bestDist) then
                        bestIndex = i
                        bestDist = dist
                        bestRadius = radius
                    end
                else
                    if dist <= radius and (not bestDist or dist < bestDist) then
                        bestIndex = i
                        bestDist = dist
                        bestRadius = radius
                    end
                end
            end
        end
    end

    if preferredIndex then
        if preferredRouteBlocked
            and preferredRouteBlockedDist
            and preferredDist
            and preferredDist > preferredRouteBlockedDist + 96 then
            if settings.debug then
                local preferredCandidate = candidates[preferredIndex]
                debugLog(
                    "sleep origin preferred alternate blocked by failed closer route",
                    npc.recordId or npc.id,
                    "blockedObject", tostring(preferredRouteBlockedObject),
                    "alternateObject", tostring(preferredCandidate and preferredCandidate.objectId),
                    "blockedDistance", tostring(preferredRouteBlockedDist),
                    "alternateDistance", tostring(preferredDist)
                )
            end
            return nil
        end
        bestIndex = preferredIndex
        bestDist = preferredDist
        bestRadius = preferredRadius
        if settings.debug then
            local preferredCandidate = candidates[preferredIndex]
            debugLog(
                "sleep origin preferred bed",
                npc.recordId or npc.id,
                "object", tostring(preferredCandidate and preferredCandidate.objectId),
                "distance", tostring(preferredDist)
            )
        end
    elseif preferredRouteBlocked then
        if settings.debug then
            debugLog(
                "sleep origin preferred blocked by route cooldown",
                npc.recordId or npc.id,
                "object", tostring(preferredRouteBlockedObject)
            )
        end
        return nil
    end

    if not bestIndex then
        if settings.debug and nearestCandidate then
            debugLog(
                "no candidate within radius",
                npc.recordId or npc.id,
                "type", tostring(interactionType or nearestCandidate.interactionType),
                "nearestObject", tostring(nearestCandidate.objectId),
                "model", tostring(nearestCandidate.model),
                "distance", tostring(nearestDist),
                "radius", tostring(nearestRadius)
            )
        end
        return nil
    end

    local candidate = candidates[bestIndex]
    if candidate and candidate.interactionType == "sleeping"
        and candidate.debugForced ~= true
        and not (context and context.debugForce == true)
        and sleepBedAccess.shouldRestrictDoorAssist(npc.cell, sleepOriginPreferredDistance(npc, candidate) ~= nil, context and context.debugForce == true) then
        candidate.disallowSleepDoorAssist = true
        if settings.debug then
            debugLog(
                "public sleep bed door-assist restricted",
                npc.recordId or npc.id,
                "object", tostring(candidate.objectId),
                "slot", tostring(candidate.slotName),
                "cell", cellName(npc.cell)
            )
        end
    end
    table.remove(candidates, bestIndex)
    if settings.debug then
        debugLog(
            "candidate within radius",
            npc.recordId or npc.id,
            "type", tostring(interactionType or candidate.interactionType),
            "object", tostring(candidate.objectId),
            "distance", tostring(bestDist),
            "radius", tostring(bestRadius)
        )
    end
    return candidate, bestDist
end

sendConsiderInteraction = function(npc, candidate)
    occupiedSlots[candidate.slotKey] = npc.id
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
    clearRelevantObjectCache("slot_claimed")
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

    if candidate.initialPlacement == true then
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
        preferredFacingDirection = candidate.preferredFacingDirection,
        facingObject = candidate.facingObject,
        facingObjectId = candidate.facingObjectId,
        facingObjectModel = candidate.facingObjectModel,
        facingObjectName = candidate.facingObjectName,
        facingKind = candidate.facingKind,
        facingObjectPosition = candidate.facingObjectPosition,
        facingCandidates = candidate.facingCandidates,
        fallbackUsed = candidate.fallbackUsed,
        currentHour = candidate.currentHour,
        initialPlacement = candidate.initialPlacement == true,
        sleepPhase = candidate.sleepPhase,
        actorBedtime = candidate.actorBedtime,
        actorWakeTime = candidate.actorWakeTime,
        sleepWakeBias = candidate.sleepWakeBias,
        observedPlayerOverride = candidate.observedPlayerOverride,
        disallowSleepDoorAssist = candidate.disallowSleepDoorAssist == true,
        ignoreTimeGate = candidate.ignoreTimeGate == true or candidate.debugForced == true,
        debugForced = candidate.debugForced == true,
        calibrationAction = candidate.calibrationAction == true,
        calibrationReason = candidate.calibrationReason,
        calibration = candidate.calibration,
        manualAssign = candidate.manualAssign == true,
        manualAssignRetryCount = candidate.manualAssignRetryCount,
        manualAssignOverrideTesting = candidate.manualAssignOverrideTesting == true,
        manualAssignOverrideReason = candidate.manualAssignOverrideReason,
        sleepAccessOverrideReason = candidate.sleepAccessOverrideReason,
        calibrationTestNpc = candidate.calibrationTestNpc == true,
    }

    local now = core.getSimulationTime()
    if candidate.initialPlacement == true and candidate.interactionType == "sleeping" and npc.id then
        pendingInitialHandoffs[npc.id] = now
    end
    npc:sendEvent("ConsiderInteractionObject", eventPayload)
    handoffTracker.track(npc, candidate, eventPayload, now)
end

function animatedMorrowindCompatEnabled()
    return settings and settings.animatedMorrowindAlignmentAssist == true
end

function noteAnimatedMorrowindSitterSeen(npc, reason)
    if not (npc and npc.id) then return end
    if sdpAnimatedMorrowindCompatState.actorSeenLogged[npc.id] then return end
    sdpAnimatedMorrowindCompatState.actorSeenLogged[npc.id] = true
    debugLog(
        "animated morrowind sitter recognized",
        npc.recordId or npc.id,
        "reason", tostring(reason),
        "contentDetected", tostring(sdpAnimatedMorrowindCompatState.detected)
    )
end

function animatedMorrowindCompatCanConsiderNpc(npc)
    if animatedMorrowindCompatEnabled() ~= true then return false, "setting_disabled" end
    if not (npc and npc.id and npc.position and npc.cell and types.NPC.objectIsInstance(npc)) then return false, "not_npc" end
    if not isObjValid(npc) then return false, "invalid_actor" end
    if assignedActors[npc.id] then return false, "normal_sdp_assignment_active" end
    if sdpAnimatedMorrowindCompatState.checkedActors[npc.id] then return false, "already_checked" end
    if sdpAnimatedMorrowindCompatState.pending[npc.id] then return false, "pending" end
    local dead, deadReason = actorDeadReason(npc)
    if dead then return false, deadReason end
    local hiddenReason = assignmentEligibility.hiddenOrStagedNpcReason(npc)
    if hiddenReason then return false, hiddenReason end

    if sdpAnimatedMorrowindCompatState.externalPlacementPatchDetected == true
        and sdpAnimatedMorrowindCompat.externalPlacementPatchOwnsActor(npc) then
        return false, "external_am_bcom_patch_positioned_actor"
    end

    local amReason = sdpAnimatedMorrowindCompat.knownSittingActorReason(npc)
    if not amReason then return false, "not_known_am_sitter" end
    noteAnimatedMorrowindSitterSeen(npc, amReason)

    if sdpAnimatedMorrowindCompatState.detected ~= true then
        -- Hybrid fallback: a known AM seated actor in the loaded cell is strong
        -- enough evidence to activate the assist even if the content file was
        -- renamed or the API cannot expose it.
        sdpAnimatedMorrowindCompatState.detected = true
        sdpAnimatedMorrowindCompatState.detectionReason = "known_actor:" .. tostring(npc.recordId or npc.id)
        if sdpAnimatedMorrowindCompatState.activeLogged ~= true then
            sdpAnimatedMorrowindCompatState.activeLogged = true
            infoLog(
                "animated morrowind compat active",
                "reason", tostring(sdpAnimatedMorrowindCompatState.detectionReason),
                "setting", tostring(settings and settings.animatedMorrowindAlignmentAssist)
            )
        end
    end

    return true, amReason
end

function sendAnimatedMorrowindCompatRequest(npc, candidate, actorReason, source)
    if not (npc and npc.id and candidate and candidate.object) then return false, "missing_request_data" end
    local requestId = tostring(npc.id) .. ":" .. tostring(core.getSimulationTime())
    sdpAnimatedMorrowindCompatState.pending[npc.id] = {
        requestId = requestId,
        npc = npc,
        object = candidate.object,
        objectId = candidate.objectId,
        sentAt = core.getSimulationTime(),
    }
    npc:sendEvent("SitDownPleaseAnimatedMorrowindAlignmentAssist", {
        requestId = requestId,
        object = candidate.object,
        objectId = candidate.objectId,
        model = candidate.model,
        profile = candidate.profile,
        profileId = candidate.profileId,
        slot = candidate.slot,
        slotName = candidate.slotName,
        slotKey = candidate.slotKey,
        preferredFacingDirection = candidate.preferredFacingDirection,
        facingKind = candidate.facingKind,
        actorReason = actorReason,
        source = source,
    })
    debugLog(
        "animated morrowind compat request",
        npc.recordId or npc.id,
        "object", tostring(candidate.objectId),
        "profile", tostring(candidate.profileId),
        "slot", tostring(candidate.slotName),
        "source", tostring(source)
    )
    return true, nil
end

function runAnimatedMorrowindCompatPass(cell, sittingCandidates, source)
    if not cell or animatedMorrowindCompatEnabled() ~= true then return end

    local compatNpcs = {}
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        local canConsider, actorReason = animatedMorrowindCompatCanConsiderNpc(npc)
        if canConsider then
            compatNpcs[#compatNpcs + 1] = { npc = npc, actorReason = actorReason }
        elseif actorReason ~= "not_known_am_sitter" and actorReason ~= "already_checked" and actorReason ~= "pending" then
            debugLogOnce(
                claimRejectLogCache,
                "am_skip:" .. tostring(npc and (npc.id or npc.recordId) or "<npc>") .. ":" .. tostring(actorReason),
                "animated morrowind compat skipped",
                npc and (npc.recordId or npc.id) or "<npc>",
                "reason", tostring(actorReason)
            )
        end
    end

    if #compatNpcs == 0 then return end

    local candidates = sittingCandidates
    if not candidates then candidates = buildCandidateSlots(cell, "sitting", { compatPass = true }) end
    if not candidates or #candidates == 0 then
        for _, item in ipairs(compatNpcs) do
            if item.npc and item.npc.id then
                sdpAnimatedMorrowindCompatState.checkedActors[item.npc.id] = "no_sitting_candidates"
                debugLog("animated morrowind compat skipped", item.npc.recordId or item.npc.id, "reason", "no_sitting_candidates")
            end
        end
        return
    end

    for _, item in ipairs(compatNpcs) do
        local npc = item.npc
        if npc and npc.id then
            local candidate, rejectReason, dist, vertical = sdpAnimatedMorrowindCompat.chooseNearbySeat(npc, candidates, profiles)
            if not candidate then
                candidate, rejectReason, dist, vertical = sdpAnimatedMorrowindCompat.chooseExternalSurfaceSeat(npc, cell, {
                    isObjValid = isObjValid,
                    objectModelPath = profiles.objectModelPath,
                    objectSlotKey = objectSlotKey,
                    objectName = objectNameForFocus,
                })
            end
            if candidate then
                sendAnimatedMorrowindCompatRequest(npc, candidate, item.actorReason, source)
            else
                sdpAnimatedMorrowindCompatState.checkedActors[npc.id] = rejectReason or "no_candidate"
                debugLog(
                    "animated morrowind compat skipped",
                    npc.recordId or npc.id,
                    "reason", tostring(rejectReason),
                    "nearestDistance", tostring(dist),
                    "vertical", tostring(vertical)
                )
            end
        end
    end
end

function scheduleAnimatedMorrowindCompatRetry(reason, delaySeconds, durationSeconds)
    if animatedMorrowindCompatEnabled() ~= true then return end
    local now = core.getSimulationTime()
    sdpAnimatedMorrowindCompatState.retryNextAt = now + (tonumber(delaySeconds) or 0.45)
    sdpAnimatedMorrowindCompatState.retryUntil = now + (tonumber(durationSeconds) or 2.5)
    sdpAnimatedMorrowindCompatState.retryReason = reason or "retry"
    sdpAnimatedMorrowindCompatState.retryLogged = false
end

function processAnimatedMorrowindCompatRetry()
    local retryUntil = tonumber(sdpAnimatedMorrowindCompatState.retryUntil)
    if not retryUntil then return end
    local now = core.getSimulationTime()
    if now > retryUntil then
        sdpAnimatedMorrowindCompatState.retryNextAt = nil
        sdpAnimatedMorrowindCompatState.retryUntil = nil
        sdpAnimatedMorrowindCompatState.retryReason = nil
        sdpAnimatedMorrowindCompatState.retryLogged = false
        return
    end
    if now < (tonumber(sdpAnimatedMorrowindCompatState.retryNextAt) or retryUntil) then return end

    sdpAnimatedMorrowindCompatState.retryNextAt = now + 0.55
    if sdpAnimatedMorrowindCompatState.retryLogged ~= true then
        sdpAnimatedMorrowindCompatState.retryLogged = true
        debugLog("animated morrowind compat delayed retry", tostring(sdpAnimatedMorrowindCompatState.retryReason))
    end
    runAnimatedMorrowindCompatPass(lastCell, nil, tostring(sdpAnimatedMorrowindCompatState.retryReason or "retry"))
end

local function assignNpcsToLocalInteractions(cell, assignmentContext)
    if not cell then return end
    assignmentContext = assignmentContext or {}

    local npcScanStats = {
        total = 0,
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
            candidatesByType[interactionType] = buildCandidateSlots(cell, interactionType)
            debugLog("candidate count", interactionType, tostring(#candidatesByType[interactionType]))
        else
            debugLog("interaction disabled", interactionType)
        end
    end

    local npcs = cell:getAll(types.NPC)
    for _, npc in ipairs(npcs) do
        if npc and npc.id then
            npcScanStats.total = npcScanStats.total + 1
            if assignedActors[npc.id] then
                npcScanStats.alreadyAssigned = npcScanStats.alreadyAssigned + 1
            else
                for _, interactionType in ipairs(interactionOrder) do
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
                        npcScanStats.disabledOrIneligible = npcScanStats.disabledOrIneligible + 1
                        debugLog("skip npc", npc.recordId or npc.id, "type", interactionType, "reason", tostring(reason))
                    else
                        local canConsider = true
                        local sleepTiming = nil
                        if interactionType == "sleeping" then
                            canConsider, reason, sleepTiming = sleepEligibilityForNpc(npc, cell, assignmentContext)
                            if not canConsider then
                                assignmentEligibility.sendWakeCleanupProbe(npc, reason, assignmentContext and assignmentContext.source or nil, assignedActors, isObjValid, debugLog)
                                npcScanStats.disabledOrIneligible = npcScanStats.disabledOrIneligible + 1
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

                        local candidates = canConsider and candidatesByType[interactionType] or nil
                        if candidates and #candidates > 0 then
                            npcScanStats.attempted = npcScanStats.attempted + 1
                            local candidate = nil
                            if interactionType == "sitting" and assignmentContext.sittingInitialPlacementAllowed == true then
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
                                elseif interactionType == "sitting" and assignmentContext.sittingInitialPlacementAllowed == true then
                                    candidate = profiles.shallowCopy(candidate)
                                    candidate.initialPlacement = true
                                end
                                npcScanStats.sentConsider = npcScanStats.sentConsider + 1
                                if candidate.initialPlacement == true then
                                    npcScanStats.initialSentConsider = npcScanStats.initialSentConsider + 1
                                    if candidate.interactionType == "sleeping" then
                                        npcScanStats.initialSleepSentConsider = npcScanStats.initialSleepSentConsider + 1
                                        table.insert(npcScanStats.initialSleepActorIds, npc.id)
                                    end
                                end
                                sendConsiderInteraction(npc, candidate)
                                break
                            else
                                npcScanStats.noCandidate = npcScanStats.noCandidate + 1
                            end
                        end
                    end
                end
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

local function clearAssignedActors(reason, notifyLocalScripts)
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
    sleepBedReservations = {}
    sleepReservationByNpc = {}
    wakeExit.clearStandAndWakeAll()
    pendingSittingReassignments = {}
    pendingSittingOriginWalks = {}
    pendingInitialHandoffs = {}
    handoffTracker.reset()
    sleepRouteDoors.clearPendingRestarts()
    sleepRouteRejectCooldowns = {}
    if reason ~= "settings_rescan" then
        sdpInteractionOrigins.resetHomeOrigins()
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
    -- A settings-triggered rescan happens in the same live cell. Notify local
    -- NPC scripts before clearing global state; otherwise the global script can
    -- forget an actor while the local script remains in sitting/sleeping
    -- state. Actual cell changes can safely discard old-cell state without
    -- trying to message unloaded actors.
    clearAnimatedMorrowindCompatRuntime(source == "settings" and "settings_rescan" or "cell_change")
    clearAssignedActors(source == "settings" and "settings_rescan" or "cell_rescan", source == "settings")
    if isCellEntry and calibrationLock.clearForCellChange({ infoLog = infoLog }, source or "cell_change") then
        sendCalibrationMenuStatus("", nil, nil, true, { silent = true })
    end

    local stats = assignNpcsToLocalInteractions(cell, {
        source = source or "cell_change",
        sleepInitialPlacementAllowed = sleepInitialPlacementAllowed,
        sittingInitialPlacementAllowed = sittingInitialPlacementAllowed,
    })
    if isCellEntry then
        scheduleAnimatedMorrowindCompatRetry(tostring(source or "cell_change") .. "_delayed_alignment", 0.45, 8.0)
    end

    completedInitialCellScan = true
    if isCellEntry and world and world.players then
        for _, player in ipairs(world.players) do pcall(function() player:sendEvent('SitDownPleaseInitialAssignmentScanComplete', { initialSleepSentConsider = stats and stats.initialSleepSentConsider or 0, initialSleepActorIds = stats and stats.initialSleepActorIds or nil, initialSentConsider = stats and stats.initialSentConsider or 0, source = source or "cell_change" }) end) end
    end
    if isCellEntry and settleInitialPlacementOverlay and (not stats or tonumber(stats.initialSleepSentConsider or 0) <= 0) then
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

    -- Developer calibration should not make a seated NPC stand up just because
    -- the normal correction loop still has stale teleport-busy bookkeeping.
    local now = core.getSimulationTime() or 0
    data.calibrationMenuHoldUntil = now + 45
    data.teleportBusySkips = nil
    data.teleportBusyFirstAt = nil

    if data.state == STATES.interacting or data.state == STATES.transitioning then
        local ok, err = tryTeleport(npc, npc.cell, ev.finalPosition, { rotation = rotationFromYaw(data.finalRotation or npc.rotation:getYaw(), npc.rotation) })
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
    if not (ev and ev.npc and ev.npc.id) then return end
    local npc = ev.npc
    local pending = sdpAnimatedMorrowindCompatState.pending[npc.id]
    if not pending or pending.requestId ~= ev.requestId then
        debugLog("animated morrowind compat stale result", npc.recordId or npc.id, "request", tostring(ev.requestId))
        return
    end
    sdpAnimatedMorrowindCompatState.pending[npc.id] = nil
    sdpAnimatedMorrowindCompatState.checkedActors[npc.id] = ev.skippedReason or (ev.correctionNeeded and "corrected" or "checked")

    if assignedActors[npc.id] then
        debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "normal_sdp_assignment_active")
        return
    end
    if not isObjValid(npc) then return end

    if ev.correctionNeeded ~= true then
        debugLog(
            "animated morrowind compat skipped",
            npc.recordId or npc.id,
            "reason", tostring(ev.skippedReason or "no_correction_needed"),
            "object", tostring(ev.objectId),
            "originalZ", tostring(ev.originalZ),
            "expectedZ", tostring(ev.expectedZ),
            "delta", tostring(ev.delta)
        )
        return
    end

    local targetZ = tonumber(ev.targetZ)
    if not (targetZ and npc.position and npc.cell) then
        debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "missing_target")
        return
    end

    local currentPos = npc.position
    if pending.object and isObjValid(pending.object) and pending.object.position then
        local dist = sdpAnimatedMorrowindCompat.horizontalDistance(currentPos, pending.object.position)
        if dist and dist > (sdpAnimatedMorrowindCompat.SEAT_RADIUS + 22) then
            debugLog("animated morrowind compat skipped", npc.recordId or npc.id, "reason", "actor_moved_from_seat", "distance", tostring(dist))
            return
        end
    end
    local newPosition = util.vector3(currentPos.x, currentPos.y, targetZ)
    local ok, err = tryTeleport(npc, npc.cell, newPosition, { rotation = npc.rotation })
    if ok then
        local settleAttempts, settleSeconds, settleInterval, settlePolicy = sdpAnimatedMorrowindCompat.settlePolicyForActor(npc)
        sdpAnimatedMorrowindCompatState.settle[npc.id] = {
            npc = npc,
            object = pending.object,
            objectId = ev.objectId,
            profileId = ev.profileId,
            targetZ = targetZ,
            attemptsRemaining = settleAttempts,
            interval = settleInterval,
            policy = settlePolicy,
            lastObservedZ = currentPos.z,
            externalRestoreStrikes = 0,
            nextAt = core.getSimulationTime() + 0.45,
            expiresAt = core.getSimulationTime() + settleSeconds,
        }
        debugLog(
            "animated morrowind compat applied",
            npc.recordId or npc.id,
            "object", tostring(ev.objectId),
            "profile", tostring(ev.profileId),
            "surface", tostring(ev.surfaceMode),
            "originalZ", tostring(ev.originalZ),
            "currentZ", tostring(currentPos.z),
            "correctedZ", tostring(targetZ),
            "delta", tostring(ev.delta),
            "settlePolicy", tostring(settlePolicy),
            "settleAttempts", tostring(settleAttempts),
            "settleSeconds", tostring(settleSeconds)
        )
        infoLog(
            "animated morrowind alignment assist",
            npc.recordId or npc.id,
            "object", tostring(ev.objectId),
            "z", tostring(ev.originalZ) .. "->" .. tostring(targetZ)
        )
    else
        debugLog("animated morrowind compat teleport failed", npc.recordId or npc.id, tostring(err))
    end
end

function processAnimatedMorrowindSettleCorrections()
    local now = core.getSimulationTime()
    for npcId, item in pairs(sdpAnimatedMorrowindCompatState.settle or {}) do
        local npc = item and item.npc or nil
        if not item or not isObjValid(npc) or assignedActors[npcId] then
            sdpAnimatedMorrowindCompatState.settle[npcId] = nil
        elseif now >= (item.expiresAt or 0) or (item.attemptsRemaining or 0) <= 0 then
            sdpAnimatedMorrowindCompatState.settle[npcId] = nil
        elseif now >= (item.nextAt or 0) then
            local currentPos = npc.position
            local targetZ = tonumber(item.targetZ)
            local shouldRetry = currentPos and targetZ and math.abs((currentPos.z or 0) - targetZ) > 4
            if shouldRetry and item.object and isObjValid(item.object) and item.object.position then
                local dist = sdpAnimatedMorrowindCompat.horizontalDistance(currentPos, item.object.position)
                if dist and dist > (sdpAnimatedMorrowindCompat.SEAT_RADIUS + 22) then
                    shouldRetry = false
                    sdpAnimatedMorrowindCompatState.settle[npcId] = nil
                    debugLog("animated morrowind compat settle stopped", npc.recordId or npc.id, "reason", "actor_moved_from_seat", "distance", tostring(dist))
                end
            end
            if shouldRetry then
                if item.lastObservedZ and math.abs((currentPos.z or 0) - item.lastObservedZ) <= 1.5
                    and math.abs((currentPos.z or 0) - targetZ) > 4 then
                    item.externalRestoreStrikes = (item.externalRestoreStrikes or 0) + 1
                else
                    item.externalRestoreStrikes = 0
                end
                item.lastObservedZ = currentPos.z
                if (item.externalRestoreStrikes or 0) >= 3 then
                    sdpAnimatedMorrowindCompatState.settle[npcId] = nil
                    debugLog(
                        "animated morrowind compat settle stopped",
                        npc.recordId or npc.id,
                        "reason", "external_controller_restored_position",
                        "currentZ", tostring(currentPos.z),
                        "targetZ", tostring(targetZ),
                        "policy", tostring(item.policy)
                    )
                else
                    local newPosition = util.vector3(currentPos.x, currentPos.y, targetZ)
                    local ok, err = tryTeleport(npc, npc.cell, newPosition, { rotation = npc.rotation })
                    item.attemptsRemaining = (item.attemptsRemaining or 0) - 1
                    item.nextAt = now + (tonumber(item.interval) or sdpAnimatedMorrowindCompat.DEFAULT_SETTLE_INTERVAL)
                    if ok then
                        debugLog(
                            "animated morrowind compat settle reapplied",
                            npc.recordId or npc.id,
                            "object", tostring(item.objectId),
                            "currentZ", tostring(currentPos.z),
                            "targetZ", tostring(targetZ),
                            "remaining", tostring(item.attemptsRemaining),
                            "policy", tostring(item.policy)
                        )
                    else
                        debugLog("animated morrowind compat settle failed", npc.recordId or npc.id, tostring(err))
                    end
                end
            else
                item.nextAt = now + (tonumber(item.interval) or sdpAnimatedMorrowindCompat.DEFAULT_SETTLE_INTERVAL)
            end
        end
    end
end

local function onInteractionCheckResult(ev)
    if not ev or not ev.npc or not ev.npc.id then return end
    local hadPendingHandoff = handoffTracker.releaseOnResult(ev.npc.id)
    local wasInitialHandoff = pendingInitialHandoffs[ev.npc.id] ~= nil or ev.initialPlacement == true
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
        debugLog(
            "reject",
            ev.npc.recordId or ev.npc.id,
            "type", tostring(ev.interactionType),
            "object", tostring(ev.objectId),
            "profile", tostring(ev.profileId),
            "slot", tostring(ev.slotName),
            "reason", tostring(ev.reason),
            "hour", tostring(ev.currentHour)
        )
        if ev.manualAssign == true then
            if ev.manualAssignOverrideTesting == true then
                infoLog("nearest_manual_assign_normal_play_blocker", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason))
                infoLog("calibration_target_blocker_reason", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason))
            else
                infoLog("nearest_manual_assign_target_failed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason))
                infoLog("calibration_target_rejected", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "reason", tostring(ev.reason))
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
        if ev.interactionType == "sitting" and tostring(ev.reason or "") == "missing_animation" then
            setSittingAnimationRejectCooldown(ev.npc, 1800, "missing_animation")
            debugLog("sitting local rejection remembered", ev.npc.recordId or ev.npc.id, "reason", "missing_animation", "object", tostring(ev.objectId), "profile", tostring(ev.profileId))
        end
        local routeFailureReassigned = false
        if ev.interactionType == "sleeping" and sleepRouteRejectReason(ev.reason) then
            debugLog(
                "sleep_route_rejected_feedback_received",
                ev.npc.recordId or ev.npc.id,
                "object", tostring(ev.objectId),
                "slot", tostring(ev.slotName),
                "reason", tostring(ev.reason)
            )
            markSleepRouteRejected(ev.npc, ev.slotKey, ev.reason)
            local sleepTiming = ev.initialPlacement == true and {
                npc = ev.npc,
                initialPlacement = true,
                ignoreTimeGate = true,
            } or { npc = ev.npc }
            local candidates = buildCandidateSlots(ev.npc.cell, "sleeping", sleepTiming)
            local candidate = chooseCandidateForNpc(ev.npc, candidates, "sleeping", sleepTiming)
            if candidate then
                candidate.initialPlacement = ev.initialPlacement == true
                candidate.ignoreTimeGate = sleepTiming.ignoreTimeGate == true
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
        if ev.initialPlacement == true and ev.interactionType == "sleeping" then
            sleepLightControl.unregisterSleeper(ev.npc, "sleep_initial_placement_rejected", true)
            sleepLightControl.processPending(true)
        end
        if wasInitialHandoff and settleInitialPlacementOverlay and not routeFailureReassigned then settleInitialPlacementOverlay("initial_placement_rejected", ev.npc) end
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
        existingAssignment.slot = ev.slot or existingAssignment.slot
        existingAssignment.profile = ev.profile or existingAssignment.profile
        existingAssignment.profileId = ev.profileId or existingAssignment.profileId
        existingAssignment.profileOffset = ev.profileOffset or existingAssignment.profileOffset
        existingAssignment.animationOffset = ev.animationOffset or existingAssignment.animationOffset
        existingAssignment.animationName = ev.animation or existingAssignment.animationName
        existingAssignment.calibration = ev.calibration or existingAssignment.calibration
        sendCalibrationOffsets("sleeping", existingAssignment.profileOffset, existingAssignment.animationOffset, existingAssignment.calibration, existingAssignment.animationName, existingAssignment)
        if ev.calibrationAction == true then
            existingAssignment.calibrationMenuHoldUntil = core.getSimulationTime() + 45
            existingAssignment.teleportBusySkips = nil
            existingAssignment.teleportBusyFirstAt = nil
        end
        updateSleepReservationState(ev.npc, existingAssignment.state == STATES.interacting and "sleeping" or "routing", "duplicate_assignment_reused")
        calibrationLock.rememberTarget(existingAssignment, { cellName = cellName, now = core.getSimulationTime }, ev.calibrationAction == true and "calibration_reused" or "duplicate_assignment_reused")
        if ev.manualAssign == true then
            calibrationLock.rememberTarget(existingAssignment, { cellName = cellName, now = core.getSimulationTime }, "manual_assign_reused")
            infoLog("nearest_manual_assign_set_calibration_target", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("nearest_manual_assign_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("calibration_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "label", calibrationLock.sessionLabel(existingAssignment))
            infoLog("reassign_target_reached", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
            infoLog("nearest_manual_assign_status", "accepted", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "override", tostring(ev.manualAssignOverrideApplied == true), "overrideReason", tostring(ev.manualAssignOverrideReason))
            sendCalibrationMenuStatus("Assign Nearest target confirmed.", ev.interactionType, calibrationLock.sessionLabel(existingAssignment), false, {
                testingOverride = ev.manualAssignOverrideApplied == true,
                testingOverrideReason = ev.manualAssignOverrideReason,
            })
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
        return
    end

    local savedOrigin = sdpInteractionOrigins.take(sdpSavedInteractionOrigins, ev, { cellName = cellName })
    local sleepOriginPos = savedOrigin and sdpInteractionOrigins.loadVector(savedOrigin.origin) or ev.npc.position
    local sleepOriginRot = savedOrigin and rotationFromYaw(tonumber(savedOrigin.originYaw), ev.npc.rotation) or ev.npc.rotation
    if savedOrigin then
        debugLog(
            "interaction origin restored",
            ev.npc.recordId or ev.npc.id,
            "type", tostring(ev.interactionType),
            "object", tostring(ev.objectId),
            "slot", tostring(ev.slotName)
        )
    elseif ev.interactionType == "sleeping" then
        local home = sdpInteractionOrigins.homeFor(ev.npc, { actorKey = actorKey })
        local pendingReturn = postWakeReturnOrigins[ev.npc.id]
        if home and home.position then
            sleepOriginPos = home.position
            sleepOriginRot = home.rotation or sleepOriginRot
        elseif pendingReturn and pendingReturn.origin then
            sleepOriginPos = pendingReturn.origin
            sleepOriginRot = pendingReturn.rotation or sleepOriginRot
            sdpInteractionOrigins.setHome(ev.npc, sleepOriginPos, sleepOriginRot, "pending_return_origin", { actorKey = actorKey })
        else
            sdpInteractionOrigins.setHome(ev.npc, ev.npc.position, ev.npc.rotation, "new_sleep_origin", { actorKey = actorKey })
        end
    end
    if savedOrigin and ev.interactionType == "sleeping" then
        sdpInteractionOrigins.setHome(ev.npc, sleepOriginPos, sleepOriginRot, "saved_interaction_origin", { actorKey = actorKey })
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
        state = STATES.approaching,
        assignedCellName = ev.npc.cell and cellName(ev.npc.cell) or nil,
        slotKey = ev.slotKey,
        slotName = ev.slotName,
        slot = ev.slot,
        position = ev.hitPos,
        finalPosition = ev.finalPosition,
        approachPos = ev.approachPos or ev.hitPos,
        sleepRouteStatus = ev.sleepRouteStatus,
        sleepRouteNeedsDoorAssist = ev.sleepRouteNeedsDoorAssist == true,
        reachedValidSleepApproach = false,
        exitPosition = ev.exitPosition,
        exitPositions = ev.exitPositions,
        preInteractionPos = sleepOriginPos,
        preInteractionRot = sleepOriginRot,
        facingDirection = ev.facingDirection,
        finalRotation = ev.finalRotation,
        facingObject = ev.facingObject,
        facingObjectId = ev.facingObjectId,
        facingObjectModel = ev.facingObjectModel,
        facingObjectName = ev.facingObjectName,
        facingKind = ev.facingKind,
        facingObjectPosition = ev.facingObjectPosition,
        facingCandidates = ev.facingCandidates,
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
        calibrationAction = ev.calibrationAction == true,
        calibrationReason = ev.calibrationReason,
        calibrationTestNpc = ev.calibrationTestNpc == true,
        lerpTime = nil,
        sentStartEvent = false,
        approachElapsed = 0,
        approachStuckElapsed = 0,
        lastApproachDistance = nil,
    }

    if ev.interactionType == "sleeping" then
        updateSleepReservationState(ev.npc, ev.initialPlacement == true and "sleeping" or "routing", ev.initialPlacement == true and "initial_placement_accepted" or "local_accepted")
        sendCalibrationOffsets("sleeping", ev.profileOffset, ev.animationOffset, ev.calibration, ev.animation, ev)
    elseif ev.interactionType == "sitting" then
        sendCalibrationOffsets("sitting", ev.profileOffset, ev.animationOffset, ev.calibration, ev.animation, ev)
    end

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
        "initial", tostring(ev.initialPlacement == true)
    )

    local data = assignedActors[ev.npc.id]
    if ev.calibrationAction == true then
        data.calibrationMenuHoldUntil = core.getSimulationTime() + 45
    end
    calibrationLock.rememberTarget(data, { cellName = cellName, now = core.getSimulationTime }, ev.initialPlacement and "initial_placement" or "accepted")
    if ev.manualAssign == true then
        calibrationLock.rememberTarget(data, { cellName = cellName, now = core.getSimulationTime }, "manual_assign")
        infoLog("nearest_manual_assign_set_calibration_target", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("nearest_manual_assign_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("calibration_target_confirmed", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "label", calibrationLock.sessionLabel(data))
        infoLog("reassign_target_reached", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName))
        infoLog("nearest_manual_assign_status", "accepted", ev.npc.recordId or ev.npc.id, "type", tostring(ev.interactionType), "object", tostring(ev.objectId), "slot", tostring(ev.slotName), "override", tostring(ev.manualAssignOverrideApplied == true), "overrideReason", tostring(ev.manualAssignOverrideReason))
        sendCalibrationMenuStatus("Assign Nearest target confirmed.", ev.interactionType, calibrationLock.sessionLabel(data), false, {
            testingOverride = ev.manualAssignOverrideApplied == true,
            testingOverrideReason = ev.manualAssignOverrideReason,
        })
    end
    if ev.interactionType == "sitting" then
        rememberSittingAssignment(data, ev.initialPlacement and "initial_placement" or "accepted")
    end
    if ev.initialPlacement == true and ev.interactionType == "sleeping" and ev.finalPosition then
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

        calibrationLock.notifyDisguiseInitialPlacement(ev.npc, "sleeping", "sleep_initial_placement", {
            settings = settings,
            world = world,
            duration = 0.62,
            holdDuration = 0.65,
            object = ev.object,
            objectId = ev.objectId,
            finalPosition = ev.finalPosition,
        })
        notifyPlayersSleepingState(ev.npc, true, "sleep_initial_placement")
        sleepLightControl.registerSleeper(ev.npc, {
            object = ev.object,
            bed = ev.object,
            bedId = ev.objectId,
            finalPosition = ev.finalPosition,
            position = ev.finalPosition,
            exitPosition = ev.exitPosition,
            approachPosition = ev.approachPos,
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
        })
        return
    end

    if ev.initialPlacement == true and ev.interactionType == "sitting" and ev.finalPosition then
        data.npcStandingPos = ev.approachPos or ev.npc.position
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
        })
        return
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

    ev.npc:sendEvent('SitDownPleaseStartAIPackage', {
        type = "Travel",
        destPosition = ev.approachPos or ev.hitPos,
        isRepeat = false,
        cancelOther = ev.manualAssignOverrideTesting == true,
    })
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
            or text == "scheduled_wake_time"
            or text == "sleep_window_ended"
            or text == "sleeping_disturbed_by_close_player"
            or text == "sleeping_disturbed_by_close_sneaking_player"
            or text == "sleeping_disturbed_by_invisible_close_player"
        if protected then
            debugLog("calibration hold blocked stop", npc.recordId or npc.id, tostring(reason), "type", tostring(data.interactionType), "until", tostring(data.calibrationMenuHoldUntil))
            if data.interactionType == "sitting" then
                data.sittingLifecycleNextAt = core.getSimulationTime() + 30
            end
            return
        end
    end
    assignedActors[npc.id] = nil
    if tostring(reason or "") == "dead_actor" then
        infoLog("assignment released dead_actor", npc.recordId or npc.id, "type", tostring(data and data.interactionType), "slot", tostring(data and data.slotKey))
    end
    local wakeSummaryReturnOrigin = nil

    if data and data.slotKey then
        occupiedSlots[data.slotKey] = nil
        clearRelevantObjectCache("slot_released")
    end

    if data and data.interactionType == "sleeping" then
        if sleepRouteRejectReason(reason) then
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
            postWakeReturnOrigins[npc.id] = {
                npc = npc,
                origin = data.preInteractionPos,
                rotation = data.preInteractionRot,
                reason = reason,
            }
        end
    end

    if data then
        local standPositions = {}
        local returnOriginPosition = nil
        local wakeExitWalkPosition = nil
        local suppressStandExitTeleport = data.teleportBusyTimedOut == true and tostring(reason or "") == "teleport_failed"

        if data.interactionType == "sitting" and reason == "sitting_lifecycle_change_seat" then
            setSittingCooldown(npc, 45, reason)
            pendingSittingReassignments[npc.id] = {
                npc = npc,
                due = core.getSimulationTime() + 0.35,
                avoidSlotKey = data.slotKey,
                source = reason,
            }
        elseif data.interactionType == "sitting" and reason == "sitting_lifecycle_return_origin" and data.preInteractionPos then
            returnOriginPosition = data.preInteractionPos
            setSittingCooldown(npc, nil, reason)
            local idleDest = findBriefIdleWalkDestination(npc, data.preInteractionPos)
            if idleDest then
                pendingSittingOriginWalks[npc.id] = {
                    npc = npc,
                    origin = data.preInteractionPos,
                    idleDest = idleDest,
                    due = core.getSimulationTime() + 0.5,
                    timeout = SITTING_IDLE_WALK_TIMEOUT,
                    stage = "returning",
                    reason = reason,
                }
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
                    -- preserved external package continue.
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
                if reason == "activated_by_player_dialogue" and data.exitPosition then
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
                    -- stored pre-sleep origin/idle point.
                    addUniquePosition(standPositions, data.exitPosition)
                    if data.exitPositions then
                        for _, pos in ipairs(data.exitPositions) do addUniquePosition(standPositions, pos) end
                    end
                    addUniquePosition(standPositions, data.npcStandingPos)
                end

                if shouldWalkToOriginAfterWake(reason) and data.preInteractionPos then
                    returnOriginPosition = data.preInteractionPos
                    wakeSummaryReturnOrigin = returnOriginPosition
                    postWakeReturnOrigins[npc.id] = {
                        npc = npc,
                        origin = data.preInteractionPos,
                        rotation = data.preInteractionRot,
                        reason = reason,
                    }
                    if largeTimeAdvanceThisUpdate == true then
                        debugLog("wake time-advance bedside exit requested", npc.recordId or npc.id, tostring(reason), "origin", tostring(data.preInteractionPos))
                    end
                elseif not wakeExitWalkPosition and data.profile and data.profile.sleepReturnToOriginFallback ~= false then
                    -- Only use origin as a last fallback for non-wake cleanup; never
                    -- use it as the first visible wake exit.
                    addUniquePosition(standPositions, data.preInteractionPos)
                end
            end
        elseif data.npcStandingPos then
            -- Sitting stand-up should return to the same floor-side approach point
            -- used to enter the seat. Adding Z here made some NPCs pop onto the
            -- stool/chair top when the approach sample was already at floor height.
            addUniquePosition(standPositions, data.npcStandingPos)
        end

        if wakeExitWalkPosition then
            if not wakeExit.queueWakeExitWalk(npc, wakeExitWalkPosition, reason, {
                timeout = 6.0,
                radius = 80,
                maxNudges = 1,
                firstNudgeAfter = 2.5,
                interactionType = data.interactionType,
                finalPosition = data.finalPosition,
                floorDrop = data.profile and data.profile.sleepExitFloorDrop or nil,
                maxSleepExitDrop = data.profile and data.profile.sleepMaxExitDrop or nil,
            }) then
                wakeExitWalkPosition = nil
                debugLog("wake exit walk fallback to stand teleport", npc.recordId or npc.id, tostring(reason))
            end
        end

        if not wakeExitWalkPosition and #standPositions > 0 then
            local standRotation = data.npcStandingRot or data.preInteractionRot or npc.rotation
            local queued = wakeExit.queueStandTeleport({
                npc = npc,
                positions = standPositions,
                index = 1,
                rotation = standRotation,
                reason = reason,
                interactionType = data.interactionType,
                finalPosition = data.finalPosition,
                floorDrop = data.profile and data.profile.sleepExitFloorDrop or nil,
                maxSleepExitDrop = data.profile and data.profile.sleepMaxExitDrop or nil,
                returnOriginPosition = returnOriginPosition,
                returnOriginRotation = data.preInteractionRot,
                clearSleepHomeOnSuccess = data.interactionType == "sleeping" and shouldWalkToOriginAfterWake(reason) and not returnOriginPosition,
            })
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

        local immediateLightRestore = reason == "activated_by_player_dialogue"
            or reason == "settings_disabled"
            or reason == "cell_change"
            or reason == "cleanup"
            or isExternalSleepReleaseReason(reason)
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


local function assignSleepPriorityInteractions(cell, source, opts)
    if not cell or settings.enableSleeping ~= true then return end
    opts = opts or {}

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
            local reservedSleepSlot = sleepReservationByNpc[sleepReservationNpcId(npc)]

            -- Already-sleeping actors are done. Actors that have a pending bed
            -- reservation from the initial/current scan are also left alone. The
            -- priority pass previously raced the normal assignment pass: it
            -- released origin-preferred beds, reassigned actors to different
            -- beds in the same tick, then rejected them for active travel.
            if active and active.interactionType == "sleeping" then
                stats.alreadySleeping = stats.alreadySleeping + 1
            elseif reservedSleepSlot then
                stats.alreadySleeping = stats.alreadySleeping + 1
                if settings.debug then
                    debugLog("sleep priority skip npc", npc.recordId or npc.id, "reason", "sleep_reserved", "slot", tostring(reservedSleepSlot))
                end
            else
                if active then stats.activeNonSleep = stats.activeNonSleep + 1 end
                local eligible, reason = isNpcRecordEligibleForInteraction(npc, "sleeping")
                if eligible then
                    stats.eligible = stats.eligible + 1
                    local canSleep, sleepReason, sleepTiming = sleepEligibilityForNpc(npc, cell, {
                        source = source or "sleep_priority",
                        sleepInitialPlacementAllowed = opts.sleepInitialPlacementAllowed == true,
                        sittingInitialPlacementAllowed = false,
                    })

                    if canSleep then
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
                                stats.assigned = stats.assigned + 1
                                candidate.initialPlacement = opts.initialPlacement == true
                                candidate.sleepPhase = sleepTiming and sleepTiming.phase or nil
                                candidate.actorBedtime = sleepTiming and sleepTiming.actorBedtime or nil
                                candidate.actorWakeTime = sleepTiming and sleepTiming.actorWakeTime or nil
                                candidate.sleepWakeBias = sleepTiming and sleepTiming.wakeBias or nil
                                candidate.observedPlayerOverride = sleepTiming and sleepTiming.observedPlayerOverride or nil

                                if active then
                                debugLog(
                                    "sleep priority preempts interaction",
                                    npc.recordId or npc.id,
                                    "from", tostring(active.interactionType),
                                    "hour", tostring(currentHour),
                                    "bedtime", tostring(candidate.actorBedtime),
                                    "phase", tostring(candidate.sleepPhase)
                                )
                                stopInteractionForNpc(npc, "sleep_priority")
                                -- Do not let a queued stand-up teleport from the
                                -- old interaction fire after this actor has been
                                -- handed a bed candidate.
                                wakeExit.clearStandTeleportForNpc(npc.id)
                            else
                                debugLog(
                                    "sleep priority assigns idle npc",
                                    npc.recordId or npc.id,
                                    "hour", tostring(currentHour),
                                    "bedtime", tostring(candidate.actorBedtime),
                                    "phase", tostring(candidate.sleepPhase)
                                )
                            end

                                sendConsiderInteraction(npc, candidate)
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
        "noCandidate", tostring(stats.noCandidate),
        "ineligible", tostring(stats.ineligible)
    )
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
    if npcOrId ~= nil then
        sendInitialPlacementResult(reason or "settled", npcOrId)
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
        debugLog("initial placement overlay not settled pending local results", tostring(reason or "settled"), "pending", tostring(pendingCount))
        return
    end
    debugLog("initial placement overlay final settle after all initial candidates resolved", tostring(reason or "settled"))
    for _, player in ipairs(world.players) do
        pcall(function()
            player:sendEvent('SitDownPleaseInitialPlacementSettled', {
                reason = reason or "settled",
                holdDuration = (reason == "sleep_initial_placement_done" and 0.65)
                    or nil,
                final = true,
            })
        end)
    end
end

local function processPostWakeReturnOrigins(force)
    local inSleepWindow = isCurrentTimeInSleepWindow()
    if inSleepWindow and force ~= true then return end

    local now = core.getSimulationTime()
    for npcId, item in pairs(postWakeReturnOrigins) do
        local npc = item and item.npc
        if not isObjValid(npc) then
            postWakeReturnOrigins[npcId] = nil
        elseif assignedActors[npcId] or wakeExit.hasPendingStandTeleport(npcId) then
            -- wait until the actor has actually exited any bed/interaction
        elseif item.origin then
            local distance = npc.position and (npc.position - item.origin):length() or 999999
            if distance < 96 then
                debugLog("post-wake return origin complete", npc.recordId or npc.id, "distance", tostring(distance))
                postWakeReturnOrigins[npcId] = nil
                if shouldWalkToOriginAfterWake(item.reason) then clearSleepHomeOrigin(npc, "returned_to_origin") end
            elseif force == true then
                local ok, err = tryTeleport(npc, npc.cell, item.origin, { rotation = item.rotation or npc.rotation, onGround = true })
                if ok then
                    debugLog("post-wake return origin placed", npc.recordId or npc.id, "origin", tostring(item.origin), "distance", tostring(distance))
                    postWakeReturnOrigins[npcId] = nil
                    if shouldWalkToOriginAfterWake(item.reason) then clearSleepHomeOrigin(npc, "forced_return_to_origin") end
                else
                    item.nextAttemptAt = now + 0.25
                    debugLog("post-wake return origin placement failed", npc.recordId or npc.id, tostring(err))
                end
            elseif not item.nextAttemptAt or item.nextAttemptAt <= now then
                item.attempts = (item.attempts or 0) + 1
                item.nextAttemptAt = now + 3
                npc:sendEvent('SitDownPleaseStartAIPackage', {
                    type = "Travel",
                    destPosition = item.origin,
                    isRepeat = false,
                    cancelOther = true,
                })
                debugLog("post-wake return origin travel", npc.recordId or npc.id, "origin", tostring(item.origin), "force", tostring(force == true), "attempt", tostring(item.attempts), "distance", tostring(distance))
                if item.attempts >= 12 then
                    -- Stop retrying forever, but do not teleport during ordinary visible gameplay.
                    debugLog("post-wake return origin giving up", npc.recordId or npc.id, "distance", tostring(distance))
                    postWakeReturnOrigins[npcId] = nil
                end
            end
        end
    end
end

local function resolveActiveSleepersAfterTimeAdvance(currentHour)
    local resolved = 0
    for npcId, data in pairs(assignedActors) do
        if data and data.interactionType == "sleeping" then
            local npc = data.npc
            assignedActors[npcId] = nil
            if data.slotKey then occupiedSlots[data.slotKey] = nil end
            wakeExit.clearForNpc(npcId)
            postWakeReturnOrigins[npcId] = nil

            if isObjValid(npc) then
                local positions = {}
                addUniquePosition(positions, data.exitPosition)
                if data.exitPositions then
                    for _, pos in ipairs(data.exitPositions) do addUniquePosition(positions, pos) end
                end
                addUniquePosition(positions, data.npcStandingPos)

                local placed = false
                local lastErr = nil
                local rotation = data.npcStandingRot or data.preInteractionRot or npc.rotation
                for index, pos in ipairs(positions) do
                    local ok, err = tryTeleport(npc, npc.cell, pos, { rotation = rotation or npc.rotation })
                    if ok then
                        placed = true
                        debugLog("wake time-advance bedside exit placement", npc.recordId or npc.id, "exitIndex", tostring(index), "origin", tostring(data.preInteractionPos), "hour", tostring(currentHour))
                        if data.preInteractionPos then
                            postWakeReturnOrigins[npc.id] = {
                                npc = npc,
                                origin = data.preInteractionPos,
                                rotation = data.preInteractionRot,
                                reason = "time_advance_sleep_window_ended",
                            }
                            debugLog("interaction return origin travel", npc.recordId or npc.id, "time_advance_sleep_window_ended", "origin", tostring(data.preInteractionPos))
                            npc:sendEvent('SitDownPleaseStartAIPackage', {
                                type = "Travel",
                                destPosition = data.preInteractionPos,
                                isRepeat = false,
                                cancelOther = true,
                            })
                        end
                        break
                    end
                    lastErr = err
                end

                if not placed then
                    wakeExit.queueStandTeleport({
                        npc = npc,
                        positions = positions,
                        index = 1,
                        rotation = rotation or npc.rotation,
                        reason = "time_advance_sleep_window_ended",
                        interactionType = data.interactionType,
                        finalPosition = data.finalPosition,
                        returnOriginPosition = data.preInteractionPos,
                        returnOriginRotation = data.preInteractionRot,
                        clearSleepHomeOnSuccess = not data.preInteractionPos,
                    })
                    debugLog("wake time-advance bedside exit placement queued", npc.recordId or npc.id, tostring(lastErr))
                end
                wakeExit.markPendingWakeCleanup(npc, "time_advance_sleep_window_ended")

                sleepLightControl.unregisterSleeper(npc, "time_advance_sleep_window_ended", true)
                notifyPlayersSleepingState(npc, false, "time_advance_sleep_window_ended")
                npc:sendEvent('StopInteractionObject', {
                    reason = "time_advance_sleep_window_ended",
                    interactionType = data.interactionType,
                    forceClearSleepAnimation = true,
                })
                debugLog(
                    "wake summary",
                    npc.recordId or npc.id,
                    "reason", "time_advance_sleep_window_ended",
                    "origin", tostring(data.preInteractionPos),
                    "placed", tostring(placed),
                    "hour", tostring(currentHour)
                )
                resolved = resolved + 1
            end
        end
    end

    if resolved > 0 then
        clearRelevantObjectCache("time_advance_sleep_resolved")
        sleepLightControl.processPending(true)
    end

    return resolved
end

local function handleLargeTimeAdvance(deltaHours, currentHour)
    if deltaHours < 0.5 then return end
    debugLog("time advance detected", "deltaHours", tostring(deltaHours), "hour", tostring(currentHour))
    local inSleepWindow = isCurrentTimeInSleepWindow()
    if not inSleepWindow then
        local resolved = resolveActiveSleepersAfterTimeAdvance(currentHour)
        processPostWakeReturnOrigins(true)
        local lightStatus = sleepLightControl.getStatus()
        if not (lightStatus and (tonumber(lightStatus.sleepers) or 0) > 0) then
            sleepLightControl.restoreAll('daytime_failsafe', true)
        else
            logSleepLightDeferred("time_advance", lightStatus, currentHour)
        end
        sleepLightControl.processPending(true)
        debugLog("time advance wake resolution", "sleepersResolved", tostring(resolved), "hour", tostring(currentHour))
        if settings.enableSitting == true and lastCell then
            assignNpcsToLocalInteractions(lastCell, {
                source = "time_advance_sitting_refresh",
                sleepInitialPlacementAllowed = false,
                sittingInitialPlacementAllowed = settings.sittingInitialPlacementEnabled == true,
            })
        end
    else
        local phase = profiles.hourInSleepWindowPhase(settings, currentHour)
        if settings.sleepInitialPlacementEnabled == true and phase and phase.phase == "force_in_bed" then
            debugLog("time advance sleep initial placement", "hour", tostring(currentHour), "phase", tostring(phase.phase))
            assignSleepPriorityInteractions(lastCell, "time_advance_sleep_initial", {
                initialPlacement = true,
                sleepInitialPlacementAllowed = true,
            })
            sleepLightControl.processPending(true)
        else
            assignSleepPriorityInteractions(lastCell, "time_advance_sleep_priority")
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
        -- proceed immediately. Patch 34 treated approaching NPCs as sleepers,
        -- which made failed/slow bed routes look like broken wake behavior.
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
    debugLog("cell transition", tostring(source), "reason", tostring(transitionReason), "exterior", tostring(currentExterior), "trigger", tostring(trigger or "update"))
    onCellChange(source)
    -- Do not wait for the periodic priority timer on real load/teleport cell
    -- entries. Exterior streaming is live world traversal, so it should not
    -- trigger hidden initial placement or instant sleep preemption.
    if allowInitialPlacement == true then
        assignSleepPriorityInteractions(lastCell, source .. "_immediate_sleep_priority")
    end
    return true
end

local function onUpdate(dt)
    handlePlayerCellTransition("update")

    sleepLightControl.processPending(false)
    handoffTracker.process()
    processAnimatedMorrowindSettleCorrections()
    processAnimatedMorrowindCompatRetry()
    if next(pendingInitialHandoffs) ~= nil then settleInitialPlacementOverlay("initial_handoff_timeout") end
    sleepRouteDoors.process()
    local currentHour = profiles.getGameHour()
    if currentHour ~= nil then
        local hourDelta = forwardHourDelta(lastGameHour, currentHour)
        largeTimeAdvanceThisUpdate = hourDelta >= 0.5
        handleLargeTimeAdvance(hourDelta, currentHour)
        lastGameHour = currentHour
        local inSleepWindow = isCurrentTimeInSleepWindow()
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

    -- Time can cross into an actor's bedtime while the player is already in the
    -- cell. Periodically give sleep priority over lower-priority local
    -- interactions such as sitting, and also let otherwise idle NPCs
    -- claim available beds. This does not create travel schedules or move actors
    -- across cells; it only considers beds in the current cell/radius.
    sleepPriorityElapsed = sleepPriorityElapsed + dt
    if sleepPriorityElapsed >= 8 then
        sleepPriorityElapsed = 0
        assignSleepPriorityInteractions(lastCell, "periodic_sleep_priority")
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
                postWakeReturnOrigins[npcId] = nil
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

            if wakeReason then
                stopInteractionForNpc(npc, wakeReason)
            else
                local sitAction = sittingLifecycleAction(data)
                if sitAction then
                    local now = core.getSimulationTime() or 0
                    local gapKey = tostring(npc and (npc.recordId or npc.id) or "<npc>") .. "::sitlife-group-gap::" .. tostring(data.sittingLifecycleGeneration or 0)
                    local gap = 90 + (210 * profiles.stableUnitInterval(gapKey))
                    local nextGroupAt = pendingSittingReassignments.__nextLifecycleGroupActionAt or 0
                    if now < nextGroupAt then
                        data.sittingLifecycleNextAt = now + gap
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

                    if lerpProgress >= 0.5 and not data.sentStartEvent then
                        data.sentStartEvent = true
                        npc:sendEvent('StartInteractionAnimation', {
                            interactionType = data.interactionType,
                            animation = data.profile.animation,
                            animationOptions = data.profile.animationOptions,
                            forceReplay = data.initialPlacement == true,
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

                    if data.state == STATES.transitioning or data.profile.allowPerFrameCorrection then
                        local ok, err = tryTeleport(npc, npc.cell, newPosition, { rotation = rotationFromYaw(newAngle, npc.rotation) })
                        if not ok and not deferTeleportFailure(data, err, "transition_or_correction") then
                            stopInteractionForNpc(npc, "teleport_failed", npcId)
                        end
                    end

                    if lerpProgress >= 1 then
                        data.state = STATES.interacting
                        data.interactionStartedAt = data.interactionStartedAt or core.getSimulationTime()
                        if data.interactionType == "sitting" and not data.sittingLifecycleNextAt then
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
                            }, false)
                        end
                    end
                elseif data.state == STATES.interacting
                    and data.profile.allowPerFrameCorrection == true
                    and data.finalPosition
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

function clearTransientRuntimeForLoad(reason, savedOrigins)
    assignedActors = {}
    occupiedSlots = {}
    pendingSittingReassignments = {}
    pendingSittingOriginWalks = {}
    pendingInitialHandoffs = {}
    followerPackageActors = {}
    recentSittingMemory = {}
    sittingCooldowns = sittingCooldownModule.new()
    postWakeReturnOrigins = {}
    sdpInteractionOrigins.resetHomeOrigins()
    sleepObservedCooldowns = {}
    sleepWakeRetryCooldowns = {}
    sleepRouteRejectCooldowns = {}
    sleepBedReservations = {}
    sleepReservationByNpc = {}
    sdpSavedInteractionOrigins = sdpInteractionOrigins.normalize(savedOrigins)
    largeTimeAdvanceThisUpdate = false
    lastCell = nil
    lastCellExterior = nil
    lastPlayerPosition = nil
    completedInitialCellScan = false
    claimRejectLogCache = {}
    sleepPriorityElapsed = 0
    lastGameHour = nil
    if wakeExit then wakeExit.clearAll() end
    handoffTracker.reset()
    sleepRouteDoors.clearPendingRestarts()
    clearAnimatedMorrowindCompatRuntime(reason or "load")
    clearRelevantObjectCache(reason or "load")
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = function(data)
            clearTransientRuntimeForLoad("load", data and data.interactionOrigins or nil)
            sleepLightControl.onLoad(data and data.sleepLightControl or nil)
        end,
        onInit = function(data)
            clearTransientRuntimeForLoad("init", data and data.interactionOrigins or nil)
            sleepLightControl.onLoad(data and data.sleepLightControl or nil)
        end,
        onSave = function()
            return {
                interactionOriginVersion = 1,
                interactionOrigins = sdpInteractionOrigins.buildSaveData(assignedActors, {
                    states = STATES,
                    isObjValid = isObjValid,
                    cellName = cellName,
                }),
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
        requestRescan = function() if onCellChange then onCellChange('interface_request') end end,
    },
    eventHandlers = {
        CellChange = function() handlePlayerCellTransition("event") end,
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
            end
        end,
        SitDownPleaseLocalSittingAcceptanceTrace = function(data)
            handoffTracker.noteLocalTrace(data)
        end,
        InteractionCheckResult = onInteractionCheckResult,
        SitDownPleaseAnimatedMorrowindAlignmentResult = onAnimatedMorrowindAlignmentResult,
        SitDownPleaseSittingCalibrationUpdated = onSittingCalibrationUpdated,
        SitDownPleaseSleepCalibrationUpdated = function(ev)
            calibrationLock.onSleepUpdated(ev, {
                assignedActors = assignedActors,
                states = STATES,
                tryTeleport = tryTeleport,
                rotationFromYaw = rotationFromYaw,
                deferTeleportFailure = deferTeleportFailure,
                infoLog = infoLog,
                debugLog = debugLog,
                now = core.getSimulationTime,
            })
            sendCalibrationOffsets("sleeping", ev and ev.profileOffset, ev and ev.animationOffset, ev and ev.calibration, ev and ev.animation, ev)
        end,
        CancelInteractionForNpc = onCancelInteractionForNpc,
        SitDownPleaseOpenSleepRouteDoor = function(ev) sleepRouteDoors.onOpen(ev) end,
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
