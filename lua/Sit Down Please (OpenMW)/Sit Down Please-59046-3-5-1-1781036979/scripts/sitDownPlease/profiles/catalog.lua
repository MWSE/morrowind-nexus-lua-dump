-- profiles/catalog.lua
---@omw-context runtime
---@diagnostic disable: assign-type-mismatch
--
-- Shared data and conservative helpers for local NPC/object interactions.
-- This module intentionally contains only profile/config data and pure helpers so
-- sitting and sleeping can stay active while profile/template-token support is
-- prepared without guessing additional OpenMW APIs.

local core = require('openmw.core')
local storage = require('openmw.storage')
local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')
local modInfo = require('scripts/sitDownPlease/world/modRegistry')
local externalAnimationCompat = require('scripts/sitDownPlease/compatibility/externalAnimations')
local logging = require('scripts/sitDownPlease/diagnostics/logging')
local scalePolicy = require('scripts/sitDownPlease/world/scalePolicy')

local sittingInteraction = require('scripts/sitDownPlease/interactions/sitting/core')
local sleepingInteraction = require('scripts/sitDownPlease/interactions/sleeping/core')
local profileLoader = require('scripts/sitDownPlease/profiles/fileLoader')
local profileScope = require('scripts/sitDownPlease/profiles/scope')
local seatingSlots = require('scripts/sitDownPlease/profiles/seatingSlots')
local sleepCandidateClassifier = require('scripts/sitDownPlease/interactions/sleeping/candidateRules')

local module = {}
local profileSelectionLogCache = {}

module.MOD_ID = modInfo.MOD_ID
module.VERSION = modInfo.VERSION
module.DISPLAY_VERSION = modInfo.DISPLAY_VERSION or tostring(modInfo.VERSION)
module.SETTINGS_PAGE = modInfo.SETTINGS_PAGE
module.SETTINGS_GROUP = modInfo.SETTINGS_GROUP
module.SETTINGS_SITTING_GROUP = modInfo.SETTINGS_SITTING_GROUP
module.SETTINGS_SLEEPING_GROUP = modInfo.SETTINGS_SLEEPING_GROUP
module.SETTINGS_SERVICE_ROLES_GROUP = modInfo.SETTINGS_SERVICE_ROLES_GROUP
module.SETTINGS_LIGHTING_GROUP = modInfo.SETTINGS_LIGHTING_GROUP
module.SETTINGS_STATIONS_GROUP = modInfo.SETTINGS_STATIONS_GROUP
module.SETTINGS_RELEASE_SAFETY_GROUP = modInfo.SETTINGS_RELEASE_SAFETY_GROUP
module.SETTINGS_BLACKLIST_GROUP = modInfo.SETTINGS_BLACKLIST_GROUP
module.SETTINGS_ADVANCED_GROUP = modInfo.SETTINGS_ADVANCED_GROUP
module.SETTING_GROUP_KEYS = {
    module.SETTINGS_GROUP,
    module.SETTINGS_SITTING_GROUP,
    module.SETTINGS_SLEEPING_GROUP,
    module.SETTINGS_SERVICE_ROLES_GROUP,
    module.SETTINGS_LIGHTING_GROUP,
    module.SETTINGS_STATIONS_GROUP,
    module.SETTINGS_RELEASE_SAFETY_GROUP,
    module.SETTINGS_BLACKLIST_GROUP,
    module.SETTINGS_ADVANCED_GROUP,
}
module.L10N = modInfo.L10N

module.INTERACTION_TYPES = {
    sitting = "sitting",
    sleeping = "sleeping"
}

module.interactions = {
    sitting = sittingInteraction,
    sleeping = sleepingInteraction,
}

module.INTERACTION_STATES = {
    idle = "idle",
    approaching = "approaching",
    transitioning = "transitioning",
    interacting = "interacting",
    exiting = "exiting"
}

-- Central defaults used by both the settings UI registration and runtime scripts.
module.DEFAULT_SETTINGS = {
    logLevel = "off",
    debug = false,
    verboseDebug = false,
    userNpcBlacklist = "",
    userFurnitureBlacklist = "",
    userCellBlacklist = "",
    verifiedLocationsOnly = true,

    enableSitting = true,
    enableSleeping = true,

    sittingInitialPlacementEnabled = true,
    sittingLifecycleEnabled = true,
    sittingStandCooldownSeconds = 45,
    sittingBriefWanderEnabled = false,
    sittingBriefWanderChance = 0.025,
    sittingBriefWanderDistance = 35,
    sittingAllowServiceNpcs = true,
    sittingServiceNpcRadius = 450,
    serviceNpcOffHoursEnabled = true,
    serviceNpcOffHoursIncludePublicans = true,
    serviceNpcOffHoursIncludeTraders = true,
    serviceNpcOffHoursIncludeTrainers = true,
    serviceNpcOffHoursIncludeFactionLeaders = true,
    serviceNpcOffHoursSittingChance = 0.45,
    serviceNpcOffHoursPublicanSittingChance = 0.20,
    serviceNpcOffHoursStartHour = 20,
    serviceNpcOffHoursEndHour = 8,
    serviceNpcOffHoursSittingRadius = 650,
    serviceNpcOffHoursSleepRadius = 1200,
    stationLecternEnabled = true,
    stationLecternPresenterChance = 0.50,
    stationLecternAudienceChance = 0.70,
    stationLecternMinHours = 0.5,
    stationLecternMaxHours = 3,
    stationLecternScanSeconds = 10,


    -- Safety Gate is now the player-facing broad-coverage guard. Keep
    -- unprofiled matching enabled from code so verified/compat paths are not
    -- split across multiple visible toggles.
    allowFallbackSitting = true,
    allowFallbackBackedChairs = true,
    allowFallbackSleeping = true,
    animatedMorrowindAlignmentAssist = false,
    allowBlockedApproachTeleport = false,
    disguiseInitialPlacement = true,


    maxSearchRadius = 700,
    -- Sleeping is still local/current-cell only, but beds can be farther from
    -- an NPC's idle marker than a chair/stool. Late-night initial placement can
    -- use a larger radius because the NPC is meant to already be asleep when
    -- the cell loads/assigns.
    sleepSearchRadius = 1400,
    sleepInitialPlacementSearchRadius = 5000,
    transitionDistance = 100,
    lerpDuration = 1,

    sleepStartHour = 20,
    sleepForceInBedHour = 23.5,
    sleepEndHour = 8,
    sleepInitialPlacementEnabled = true,
    sleepSmartDoorAssist = true,
    sleepAvoidObservedPlayer = true,
    sleepObservedPlayerCooldown = 120,
    sleepObservedPlayerDistance = 500,
    sleepObservedPlayerCloseDistance = 150,
    sleepObservedPlayerDispositionThreshold = 70,
    sleepObservedPlayerAllowanceChance = 0.25,
    sleepingWakeDistance = 120,
    sleepingSneakWakeDistance = 60,
    sleepWakeGraceSeconds = 6,
    sleepSuppressHello = true,
    sleepSuppressAiStats = true,
    sleepWakeRetryCooldown = 20,

    -- Wake-up is intentionally varied like bedtime. NPCs can wake between
    -- sleepWakeStartHour and sleepEndHour; job/service-style classes bias
    -- toward the earlier side of that range when allowed to sleep.
    sleepWakeStartHour = 5,
    sleepJobWakeBias = 0.55,

    -- Legacy hidden setting kept so old saves do not lose the key.
    sdpOpenCalibrationMenuAction = 0,
    -- Developer-only calibration panel gate. The panel is opened by an input
    -- binding while in-game, not directly from the Settings/MainMenu screen.
    sdpCalibrationHotkeyEnabled = false,
    sdpCalibrationHotkey = "c",


    -- Sleep-triggered light control. Enabled by default so interiors
    -- can settle naturally around sleeping NPCs; all replacements remain
    -- runtime-managed and reversible.
    enableLightControl = true,
    lightControlRadius = 1200,
    lightControlAwakeNpcRadius = 1600,
    -- If awake non-follower NPCs are nearby but not directly beside the bed,
    -- still allow a smaller immediate bedside radius to go dark. Followers are
    -- ignored by sleep-light awake-NPC checks.
    lightControlAwakeNearbyVisibleSleepRadius = 440,
    lightControlAwakeDirectBedsideRadius = 210,
    lightControlCandles = true,
    lightControlLanterns = true,
    lightControlTorches = true,
    lightControlFires = false,
    lightControlBatchSize = 4,
    lightControlPublicRadiusMultiplier = 0.65,
    lightControlVerticalTolerance = 360,
    lightControlPlayerWakeBedsideRestoreRadius = 350,
    -- Short re-entry sitting memory is disabled by default to avoid save/state bloat.
    -- When enabled, runtime code stores a tiny bounded list of primitive keys only.

    -- Full private-residence radius is used only for late-night initial placement.
    -- When an NPC visibly goes to bed while the player is already present, keep
    -- the light change local to the bed area so it does not reveal/announce the
    -- routine from elsewhere in the house.
    lightControlVisibleSleepRadius = 360,
    lightControlPrivateVisibleVerticalBelowTolerance = 70,
    lightControlPrivateVisibleVerticalAboveTolerance = 260,

}

-- Keep these internal/default-only values fixed from code rather than reading
-- stale saved development values. Safety Gate is the visible broad-coverage
-- control; fallback profile toggles stay code-owned defaults.
module.HIDDEN_DEFAULT_ONLY_SETTINGS = {
    -- Internal tuning only. Do not read stale saved dev values from earlier
    -- builds; the current visible-sleep light radius is deliberately local and same-floor filtered.
    lightControlVisibleSleepRadius = true,
    lightControlAwakeNearbyVisibleSleepRadius = true,
    lightControlAwakeDirectBedsideRadius = true,
    lightControlPrivateVisibleVerticalBelowTolerance = true,
    lightControlPrivateVisibleVerticalAboveTolerance = true,
    allowFallbackSitting = true,
    allowFallbackBackedChairs = true,
    allowFallbackSleeping = true,
    sittingBriefWanderEnabled = true,

}

module.SETTING_CANONICAL_GROUPS = {
    logLevel = module.SETTINGS_ADVANCED_GROUP,
    debug = module.SETTINGS_ADVANCED_GROUP,
    verboseDebug = module.SETTINGS_ADVANCED_GROUP,
    userNpcBlacklist = module.SETTINGS_BLACKLIST_GROUP,
    userFurnitureBlacklist = module.SETTINGS_BLACKLIST_GROUP,
    userCellBlacklist = module.SETTINGS_BLACKLIST_GROUP,
    verifiedLocationsOnly = module.SETTINGS_BLACKLIST_GROUP,

    enableSitting = module.SETTINGS_SITTING_GROUP,
    sittingInitialPlacementEnabled = module.SETTINGS_SITTING_GROUP,
    sittingLifecycleEnabled = module.SETTINGS_SITTING_GROUP,
    sittingStandCooldownSeconds = module.SETTINGS_SITTING_GROUP,
    sittingBriefWanderEnabled = module.SETTINGS_SITTING_GROUP,
    sittingBriefWanderChance = module.SETTINGS_SITTING_GROUP,
    sittingBriefWanderDistance = module.SETTINGS_SITTING_GROUP,
    sittingAllowServiceNpcs = module.SETTINGS_SERVICE_ROLES_GROUP,
    sittingServiceNpcRadius = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursEnabled = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursStartHour = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursEndHour = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursIncludePublicans = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursIncludeTraders = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursIncludeTrainers = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursIncludeFactionLeaders = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursSittingChance = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursPublicanSittingChance = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursSittingRadius = module.SETTINGS_SERVICE_ROLES_GROUP,
    serviceNpcOffHoursSleepRadius = module.SETTINGS_SERVICE_ROLES_GROUP,
    stationLecternEnabled = module.SETTINGS_STATIONS_GROUP,
    stationLecternPresenterChance = module.SETTINGS_STATIONS_GROUP,
    stationLecternAudienceChance = module.SETTINGS_STATIONS_GROUP,
    maxSearchRadius = module.SETTINGS_SITTING_GROUP,
    transitionDistance = module.SETTINGS_ADVANCED_GROUP,
    lerpDuration = module.SETTINGS_ADVANCED_GROUP,

    enableSleeping = module.SETTINGS_SLEEPING_GROUP,
    sleepStartHour = module.SETTINGS_SLEEPING_GROUP,
    sleepForceInBedHour = module.SETTINGS_SLEEPING_GROUP,
    sleepEndHour = module.SETTINGS_SLEEPING_GROUP,
    sleepInitialPlacementEnabled = module.SETTINGS_SLEEPING_GROUP,
    sleepSmartDoorAssist = module.SETTINGS_SLEEPING_GROUP,
    disguiseInitialPlacement = module.SETTINGS_ADVANCED_GROUP,
    sleepAvoidObservedPlayer = module.SETTINGS_SLEEPING_GROUP,
    sleepObservedPlayerCooldown = module.SETTINGS_SLEEPING_GROUP,
    sleepObservedPlayerDistance = module.SETTINGS_SLEEPING_GROUP,
    sleepObservedPlayerDispositionThreshold = module.SETTINGS_SLEEPING_GROUP,
    sleepObservedPlayerAllowanceChance = module.SETTINGS_SLEEPING_GROUP,
    sleepingWakeDistance = module.SETTINGS_SLEEPING_GROUP,
    sleepingSneakWakeDistance = module.SETTINGS_SLEEPING_GROUP,

    enableLightControl = module.SETTINGS_LIGHTING_GROUP,
    lightControlRadius = module.SETTINGS_LIGHTING_GROUP,
    lightControlAwakeNpcRadius = module.SETTINGS_LIGHTING_GROUP,
    lightControlCandles = module.SETTINGS_LIGHTING_GROUP,
    lightControlLanterns = module.SETTINGS_LIGHTING_GROUP,
    lightControlTorches = module.SETTINGS_LIGHTING_GROUP,
    lightControlFires = module.SETTINGS_LIGHTING_GROUP,
    lightControlBatchSize = module.SETTINGS_LIGHTING_GROUP,
    lightControlPlayerWakeBedsideRestoreRadius = module.SETTINGS_LIGHTING_GROUP,

    animatedMorrowindAlignmentAssist = module.SETTINGS_ADVANCED_GROUP,

    sdpOpenCalibrationMenuAction = module.SETTINGS_ADVANCED_GROUP,
    sdpCalibrationHotkeyEnabled = module.SETTINGS_ADVANCED_GROUP,
    sdpCalibrationHotkey = module.SETTINGS_ADVANCED_GROUP,
}

module.objectBlacklist = {
    -- ["object_record_id"] = true,
    ["furn_velothi_prayer_stool_01"] = true, -- Explicitly excluded from normal sitting; kneeling/prayer animation is not supported.
    ["t_nor_furnp_stoolstem_03a"] = true, -- Tamriel Data Nordic footstool; not a real sitting-height stool.
    ["sky_furn_nord_stool_stem_01_03"] = true, -- Old/object key for T_Nor_FurnP_StoolStem_03a.
    ["roht_mg_rubble_chair_01"] = true, -- Invisible/staged ROHT rubble chair; not player-visible furniture.
    ["roht_mg_rubble_chair_02"] = true, -- Invisible/staged ROHT rubble chair; not player-visible furniture.
}

module.cellBlacklist = {
    ["caldera, ghorak manor"] = true, -- 3.3.5: cluttered multi-level creature/NPC interior causes repeated unsafe bed and chair assignments.
}

module.npcBlacklist = {
    -- ["npc_record_id"] = true,
    ["vd_tarancur"] = true, -- ROHT/Balmora Mages Guild staging conflict; repeatedly assigned to invisible rubble chair.
}

function module.externalAnimationNpcReason(actor)
    return externalAnimationCompat.externalAnimationNpcReason(actor)
end

function module.externalAnimationClaimReason(actor, candidate)
    return externalAnimationCompat.claimReasonForCandidate(actor, candidate)
end

function module.externalAnimationClaimMatch(actor, candidate)
    return externalAnimationCompat.claimMatchForCandidate(actor, candidate)
end

function module.sittingSeatCategory(profile, obj)
    local raw = profile and (profile.seatCategory or profile.type) or nil
    local keys = obj and module.objectProfileKeys(obj) or { obj and obj.recordId }
    return seatingSlots.categoryFromKeys(keys, raw)
end

function module.sittingFallbackCategoryFromKeys(keys)
    return seatingSlots.categoryFromKeys(keys, nil)
end

function module.fallbackSittingCategoryAllowed(category, settings)
    if not (settings and settings.allowFallbackSitting == true) then return false end
    category = string.lower(tostring(category or ""))
    if category == "prayer_stool" then return false end
    if category == "stool" or category == "bench" or category == "barstool" then return true end
    if category == "chair" or category == "backedchair" or category == "backed_chair" then
        return settings.allowFallbackBackedChairs == true
    end
    return false
end

-- Script-side sleep spread tuning. These are intentionally not player-facing.
-- Player settings define the broad window: when NPCs start considering bed and
-- the latest time they can remain asleep. These constants derive the internal
-- variation ranges from that window.
module.SLEEP_FORCE_IN_BED_DELAY_HOURS = 3.5
module.SLEEP_WAKE_VARIATION_HOURS = 3.0
module.SLEEP_JOB_WAKE_BIAS = 0.55

local function makeSurfaceGrid(width, length, step)
    local offsets = {}
    local halfWidth = (tonumber(width) or 0) / 2
    local halfLength = (tonumber(length) or 0) / 2
    local sampleStep = tonumber(step) or 80

    local function add(x, y)
        offsets[#offsets + 1] = { x = x, y = y, z = 0 }
    end

    add(0, 0)

    local x = -halfWidth
    while x <= halfWidth + 0.001 do
        local y = -halfLength
        while y <= halfLength + 0.001 do
            if not (math.abs(x) < 0.001 and math.abs(y) < 0.001) then
                add(x, y)
            end
            y = y + sampleStep
        end
        x = x + sampleStep
    end

    return offsets
end

-- Profile schema notes:
-- - `slots` may define multiple final positions for benches, beds, bunks, or altars.
-- - `template` is reserved for future hidden-cell token profiles.
-- - Offset tables are object-local and are applied through object.rotation when used.
-- - Unknown furniture is skipped unless the relevant fallback setting is enabled.
module.profilesByRecordId = {}
module.scopedProfilesByRecordId = {}
module.sleepOrientationVariants = {}
module.stationOrientationVariants = {}
module.stationProfilesByRecordId = {}
module.scopedStationProfilesByRecordId = {}


module.sleepingProfileSchema = {
    interactionType = "sleeping",
    type = "bed",
    -- Prefer VA/Dynamic Actors lying poses when available; fall back to vanilla
    -- knockout/knockdown only if those custom pose groups are not installed for
    -- the actor. The local NPC script chooses the first available group at runtime.
    animation = "sdpvasitting8",
    animations = { "sdpvasitting8", "sdpvasitting9", "knockout", "knockdown" },
    -- Available VA/Dynamic Actors lying poses. The local script chooses one
    -- deterministically per actor/object so multiple sleepers do not all use
    -- the same pose, while remaining stable across rescans.
    sleepAnimationVariants = {
        -- sdpvasitting7 reads like a waking/resting-on-elbow pose, so keep it out of
        -- automatic sleep selection. Use flatter sleeping/lying poses instead.
        -- These VA/Dynamic Actors groups face opposite the earlier shared default,
        -- so keep yaw as a per-variant override rather than a one-size setting.
        { animation = "sdpvasitting8", label = "sleeping_on_side", sleepPoseYawOffset = math.rad(-90), sleepRootZOffset = 0 },
        { animation = "sdpvasitting9", label = "lying_on_back", sleepPoseYawOffset = math.rad(-90), sleepRootZOffset = 0 },
    },
    animationOptions = {
        loops = 200,
        forceLoop = true,
        speed = 1.0,
        priority = 13,
        blendMask = 15,
    },
    -- Generic vanilla active-bed placement. This is intentionally conservative
    -- and can be overridden by per-record or template-token profiles later.
    sleepOffset = { x = 0, y = 0, z = 0 },
    -- VA/Dynamic Actors lying poses are authored around the actor root, not the
    -- bed surface. Lower the root below the sampled mattress/surface point and
    -- rotate the pose so the head points toward the pillow/head side. These
    -- offsets are root/pose calibration, not camera offsets from Dynamic Actors.
    -- Tuned from testing: -220 placed the actor on the floor; -120 floated too high.
    sleepRootZOffset = -180,
    sleepPoseYawOffset = math.rad(-90),
    -- The VA lying root tends to sit beside/high above bed meshes if placed at
    -- the sampled surface point. Nudge inward from the chosen approach side and
    -- lower the root so the prone body rests on the mattress instead of beside it.
    -- Nudge the actor root inward from the approach side. This remains a profile
    -- calibration value: the bed surface height is procedural, but lying-pose root
    -- alignment varies by pose/model and can be overridden per profile later.
    sleepInwardOffsetFromApproach = 0,
    -- Actor-root local offset applied after procedural surface sampling.
    -- This is the profile/template equivalent of the alignment markers used by
    -- other animation mods: the bed surface height is detected procedurally,
    -- while the prone animation root gets a per-profile local nudge.
    sleepRootLocalOffset = { x = 0, y = 0, z = 0 },
    sleepSurfaceTopTolerance = 18,
    sleepStartAnimationDelay = 0.25,
    allowAnySleepSurfaceHit = true,
    -- Sample multiple object-local points and raycast down to find the actual
    -- bed top/center. This mirrors why sitting works better: it uses real hit
    -- positions instead of trusting the record origin, which can sit at a bed end.
    sleepSurfaceSampleOffsets = makeSurfaceGrid(300, 340, 85),
    sleepSurfaceCenterMode = "sample_extents",
    sleepSurfaceMinHeight = 80,
    sleepSurfaceMaxHeight = 280,
    rotationOffset = 0,
    allowPerFrameCorrection = true,
    allowBlockedApproachTeleport = false,
    sleepSnapIntoBed = true,
    sleepReturnToOriginFallback = true,
    sleepExitIncludeApproachFallback = false,
    sleepExitDisableRingFallback = true,
    sleepExitPreferApproachSide = true,
    -- Wake placement should use side-of-bed floor candidates only. Head/foot
    -- exits make sleepers appear to climb out through pillows, bedframes, or
    -- walls, especially on beds pushed into corners.
    sleepExitSideOnly = true,
    transitionDistance = 80,
    approachStuckTimeout = 2.5,
    approachHardTimeout = 8,
    approachForceMinSeconds = 2.5,
    approachForceTransitionDistance = 220,
    approachForceObjectDistance = 320,
    allowedHours = { start = 22, finish = 6 },
    whitelistOnly = true,
    -- Beds are often pushed against walls or have object origins/orientations that do
    -- not match a single "front" approach. Try multiple object-local approaches and
    -- let the NPC-local script pick the closest one for that actor.
    approachOffsets = {
        { name = "foot", x = 0, y = -160, z = 0 },
        { name = "head", x = 0, y = 160, z = 0 },
        { name = "left", x = -160, y = 0, z = 0 },
        { name = "right", x = 160, y = 0, z = 0 },
    },
    exitOffsets = {
        -- Universal side-only stand-up candidates. Head/foot/ring/approach exits
        -- are deliberately excluded so waking NPCs do not climb through pillows,
        -- footboards, or walls. Specific bedProfiles rows inherit this default.
        { name = "left_exit", x = -115, y = 0, z = 0 },
        { name = "right_exit", x = 115, y = 0, z = 0 },
        { name = "left_forward_exit", x = -115, y = 42, z = 0 },
        { name = "right_forward_exit", x = 115, y = 42, z = 0 },
        { name = "left_back_exit", x = -115, y = -42, z = 0 },
        { name = "right_back_exit", x = 115, y = -42, z = 0 },
    },
    slots = {
        { name = "sleep_main", sleepOffset = { x = 0, y = 0, z = 0 } },
    },
    template = {
        tokenProfileId = nil,
        requiredTokens = { "sleep_body" },
        optionalTokens = { "bed_entry_left", "bed_entry_right", "upper_bunk", "lower_bunk", "facing_marker", "transition_start" },
        status = "scaffold_only"
    }
}



local fallbackProfiles = {
    sitting = {
        profileId = "fallback_sitting",
        interactionType = "sitting",
        type = "fallback",
        animation = "sdpvasitting6",
        animations = { "sdpvasitting6", "sdparmsonkneessitidle1", "sitidle1", "SitIdle1", "sdpvasitting2", "sdpvasitting3", "sdpvasitting4" },
        finalForwardOffset = -7,
        finalZOffset = -36,
        rotationMode = "faceOpenSide",
        allowPerFrameCorrection = true,
        allowFallbackPositioning = true,
        isFallback = true,
    },
    sleeping = {
        profileId = "fallback_sleeping",
        interactionType = "sleeping",
        type = "fallback_sleep_surface",
        -- Used for generic beds/bedrolls/hammocks when fallback sleeping is enabled.
        -- Hammocks especially may need a real explicit profile later; this keeps
        -- them eligible without logging every unrelated object.
        animation = "sdpvasitting8",
        animations = { "sdpvasitting8", "sdpvasitting9", "knockout", "knockdown" },
        sleepAnimationVariants = {
        { animation = "sdpvasitting8", label = "sleeping_on_side", sleepPoseYawOffset = math.rad(-90), sleepRootZOffset = 0 },
        { animation = "sdpvasitting9", label = "lying_on_back", sleepPoseYawOffset = math.rad(-90), sleepRootZOffset = 0 },
        },
        animationOptions = {
            loops = 200,
            forceLoop = true,
            speed = 1.0,
            priority = 5,
            blendMask = 15,
        },
        sleepOffset = { x = 0, y = 0, z = 0 },
        -- Tuned from testing: -220 placed the actor on the floor; -120 floated too high.
        sleepRootZOffset = -180,
        sleepPoseYawOffset = math.rad(-90),
            -- Nudge the actor root inward from the approach side. This remains a profile
        -- calibration value: the bed surface height is procedural, but lying-pose root
        -- alignment varies by pose/model and can be overridden per profile later.
        sleepInwardOffsetFromApproach = 0,
        sleepRootLocalOffset = { x = 0, y = 0, z = 0 },
        sleepSurfaceTopTolerance = 18,
        allowAnySleepSurfaceHit = true,
        sleepSurfaceSampleOffsets = makeSurfaceGrid(300, 340, 85),
    sleepSurfaceCenterMode = "sample_extents",
    sleepSurfaceMinHeight = 80,
    sleepSurfaceMaxHeight = 280,
        rotationOffset = 0,
        allowPerFrameCorrection = true,
        allowBlockedApproachTeleport = false,
        sleepSnapIntoBed = true,
        sleepReturnToOriginFallback = true,
        sleepExitSideOnly = true,
        sleepExitIncludeApproachFallback = false,
        sleepExitDisableRingFallback = true,
        sleepExitPreferApproachSide = true,
        transitionDistance = 80,
        approachStuckTimeout = 2.5,
        approachHardTimeout = 8,
        approachForceMinSeconds = 2.5,
        approachForceTransitionDistance = 220,
        approachForceObjectDistance = 320,
        allowFallbackPositioning = true,
        allowedHours = { start = 22, finish = 6 },
        approachOffsets = {
            { name = "foot", x = 0, y = -160, z = 0 },
            { name = "head", x = 0, y = 160, z = 0 },
            { name = "left", x = -160, y = 0, z = 0 },
            { name = "right", x = 160, y = 0, z = 0 },
        },
        exitOffsets = {
            { name = "left_exit", x = -115, y = 0, z = 0 },
            { name = "right_exit", x = 115, y = 0, z = 0 },
            { name = "left_forward_exit", x = -115, y = 42, z = 0 },
            { name = "right_forward_exit", x = 115, y = 42, z = 0 },
        },
        slots = {
            { name = "sleep_main", sleepOffset = { x = 0, y = 0, z = 0 } },
        },
        isFallback = true,
    },
}
module.fallbackProfiles = fallbackProfiles

local function normalizeId(id)
    if not id then return nil end
    return string.lower(tostring(id))
end
module.normalizeId = normalizeId

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t or {}) do copy[k] = v end
    return copy
end
module.shallowCopy = shallowCopy

local function parseUserBlacklist(raw, allowComma)
    local out = {}
    raw = tostring(raw or "")
    local separators = allowComma == false and "[\r\n;|]+" or "[\r\n;,|]+"
    raw = raw:gsub(separators, "\n")
    for token in raw:gmatch("([^\n]+)") do
        local value = normalizeId((token:gsub("^%s*[\"']?", ""):gsub("[\"']?%s*$", "")))
        if value and value ~= "" then out[value] = true end
    end
    return out
end

local function blacklistHasId(list, ...)
    for i = 1, select("#", ...) do
        local value = normalizeId(select(i, ...))
        if value and value ~= "" and list and list[value] == true then return true, value end
    end
    return false, nil
end

function module.userNpcBlacklist(settings)
    return parseUserBlacklist(settings and settings.userNpcBlacklist, true)
end

function module.userFurnitureBlacklist(settings)
    return parseUserBlacklist(settings and settings.userFurnitureBlacklist, true)
end

function module.userCellBlacklist(settings)
    return parseUserBlacklist(settings and settings.userCellBlacklist, false)
end

local function cellBlacklistName(cell)
    if not cell then return "" end
    return tostring(cell.name or cell.id or "")
end

function module.npcBlacklistedReason(actor, settings)
    if blacklistHasId(module.npcBlacklist, actor and actor.recordId, actor and actor.id) then
        return "blacklisted_npc"
    end
    if blacklistHasId(module.userNpcBlacklist(settings), actor and actor.recordId, actor and actor.id) then
        return "user_blacklisted_npc"
    end
    return nil
end

function module.objectBlacklistedReason(obj, settings)
    local keys = module.objectProfileKeys and module.objectProfileKeys(obj) or {}
    for _, key in ipairs(keys) do
        if module.objectBlacklist[key] then return "blacklisted_object" end
    end
    local userList = module.userFurnitureBlacklist(settings)
    if blacklistHasId(userList, obj and obj.recordId, obj and obj.id) then
        return "user_blacklisted_object"
    end
    for _, key in ipairs(keys) do
        if userList[key] then return "user_blacklisted_object" end
    end
    return nil
end

function module.cellBlacklistedReason(cell, settings)
    if blacklistHasId(module.cellBlacklist, cellBlacklistName(cell), cell and cell.id) then
        return "blacklisted_cell"
    end
    if blacklistHasId(module.userCellBlacklist(settings), cellBlacklistName(cell), cell and cell.id) then
        return "user_blacklisted_cell"
    end
    return nil
end

local function cloneProfile(base, profileId)
    local profile = shallowCopy(base)
    profile.profileId = profileId
    return profile
end

local function cloneSlots(slots)
    local copy = {}
    for i, slot in ipairs(slots or {}) do
        copy[i] = shallowCopy(slot)
    end
    return copy
end

local function registerProfileAliases(ids, baseProfile)
    local profilesByRecordId = module.profilesByRecordId or {}
    module.profilesByRecordId = profilesByRecordId
    for _, id in ipairs(ids) do
        local recordId = normalizeId(id)
        local profile = cloneProfile(baseProfile, recordId)
        if profile and profile.interactionType == "sleeping" then
            profile.profileBedTypeAverageAlias = true
        end
        if recordId and recordId ~= "" then
            profilesByRecordId[recordId] = profile
        end
    end
end

local vanillaBedProfile = cloneProfile(module.sleepingProfileSchema, "vanilla_active_bed")

registerProfileAliases({
    "active_de_r_bed_01",
    "active_de_p_bed_03",
    "active_de_p_bed_04",
    "active_de_p_bed_05",
    "active_de_r_bed_06",
    "active_de_pr_bed_07",
    "active_de_pr_bed_08",
    "active_de_p_bed_09",
    "active_de_p_bed_10",
    "active_de_p_bed_11",
    "active_de_p_bed_12",
    "active_de_p_bed_13",
    "active_de_p_bed_14",
    "active_de_p_bed_15",
    "active_de_p_bed_16",
    "active_de_r_bed_17",
    "active_de_r_bed_18",
    "active_de_r_bed_19",
    "active_de_r_bed_20",
    "active_de_pr_bed_21",
    "active_de_pr_bed_22",
    "active_de_pr_bed_23",
    "active_de_pr_bed_24",
    "active_de_pr_bed_25",
    "active_de_pr_bed_26",
    "active_de_pr_bed_27",
    "active_de_bedroll",
    "active_com_bed_01",
    "active_com_bed_02",
    "active_com_bed_03",
    "active_com_bed_04",
    "active_com_bed_05",
    "active_com_bed_06",
    "active_com_bed_07",
}, vanillaBedProfile)



-- Record-specific chair/bed offsets now live only in external TSV files under
-- furnitureProfiles/sdp/. If those files fail to load, the mod deliberately
-- falls back only to the broad generic schemas/fallback behavior, not hidden
-- hardcoded per-bed calibration values.

-- External TSV profile overlays. Keep record-specific chair/bed data in furnitureProfiles/sdp/global/*.txt or scoped folders below furnitureProfiles/sdp/.
-- This is silent here because the module is loaded by MENU/GLOBAL/PLAYER/NPC contexts.
-- The global script prints one startup summary with PROFILE_ROWS_LOADED.
module.PROFILE_ROWS_LOADED = profileLoader.loadProfileFiles(module, nil)
module.PROFILE_LOAD_SUMMARY = profileLoader.lastLoadSummary or {}

function module.profileLoadCounts()
    local summary = module.PROFILE_LOAD_SUMMARY or {}
    return {
        bedRows = tonumber(summary.bedRows or 0) or 0,
        chairRows = tonumber(summary.chairRows or 0) or 0,
        stationRows = tonumber(summary.stationRows or 0) or 0,
        bedVariantRows = tonumber(summary.bedVariantRows or 0) or 0,
        chairVariantRows = tonumber(summary.chairVariantRows or 0) or 0,
        malformedRows = tonumber(summary.malformedRows or 0) or 0,
        skippedRows = tonumber(summary.skippedRows or 0) or 0,
        duplicateKeys = #(summary.duplicateKeys or {}),
        acceptedRows = summary.acceptedRows or {},
        rejectedRows = summary.rejectedRows or {},
        loadedFiles = summary.loadedFiles or {},
        missingFiles = summary.missingFiles or {},
    }
end

local function joinedKeys(t)
    local out = {}
    for key, value in pairs(t or {}) do
        if value == true then out[#out + 1] = tostring(key) end
    end
    table.sort(out)
    return table.concat(out, ",")
end

local function joinedList(t)
    local out = {}
    for _, value in ipairs(t or {}) do out[#out + 1] = tostring(value) end
    table.sort(out)
    return table.concat(out, ",")
end

function module.explicitProfileStatus(recordId)
    local key = normalizeId(recordId)
    local profile = key and module.profilesByRecordId[key] or nil
    if not profile then return { recordId = recordId, found = false, explicit = false } end
    return {
        recordId = recordId,
        found = true,
        explicit = profile.externalProfile == true,
        interactionType = profile.interactionType,
        profileId = profile.profileId,
        sourceName = profile.sourceName,
        fallback = profile.externalProfile ~= true and (profile.isFallback == true or profile.profileBedTypeFallback ~= nil),
    }
end

function module.logStartupProfileStatus(infoLog, verboseInfoLog)
    if not infoLog then return end
    verboseInfoLog = verboseInfoLog or infoLog
    local profileCounts = module.profileLoadCounts and module.profileLoadCounts() or {}
    infoLog(
        "profile loader counts",
        "bedRows=" .. tostring(profileCounts.bedRows or 0),
        "chairRows=" .. tostring(profileCounts.chairRows or 0),
        "stationRows=" .. tostring(profileCounts.stationRows or 0),
        "bedVariantRows=" .. tostring(profileCounts.bedVariantRows or 0),
        "chairVariantRows=" .. tostring(profileCounts.chairVariantRows or 0),
        "malformedRows=" .. tostring(profileCounts.malformedRows or 0),
        "skippedRows=" .. tostring(profileCounts.skippedRows or 0),
        "duplicateKeys=" .. tostring(profileCounts.duplicateKeys or 0),
        "acceptedRows=" .. tostring(#(profileCounts.acceptedRows or {})),
        "rejectedRows=" .. tostring(#(profileCounts.rejectedRows or {}))
    )
    infoLog(
        "profile loader files",
        "loaded", joinedKeys(profileCounts.loadedFiles),
        "missing", joinedList(profileCounts.missingFiles)
    )
    for _, row in ipairs(profileCounts.acceptedRows or {}) do
        verboseInfoLog(
            "profile loader row accepted",
            "source", tostring(row.source),
            "kind", tostring(row.kind),
            "key", tostring(row.key),
            "detail", tostring(row.detail)
        )
    end
    for _, row in ipairs(profileCounts.rejectedRows or {}) do
        infoLog(
            "profile loader row rejected",
            "source", tostring(row.source),
            "kind", tostring(row.kind),
            "reason", tostring(row.reason),
            "detail", tostring(row.detail)
        )
    end
    for _, recordId in ipairs({
        "active_de_p_bed_09",
        "active_de_p_bed_10",
        "active_de_p_bed_04",
        "active_de_p_bed_15",
        "ab_furn_demidbedsingle02",
        "ab_furn_demidbedbunk03",
        "active_com_bunk_01",
        "active_com_bunk_02",
        "active_com_bed_04",
        "active_com_bed_03",
        "active_com_bed_06",
        "furn_de_p_chair_02",
        "furn_de_r_chair_03",
        "furn_de_r_bench_01",
        "ab_furn_demidchair",
        "furn_com_rm_chair_03",
        "furn_com_rm_barstool",
        "ab_furn_demidbench",
        "active_de_r_bed_20",
        "furn_de_ex_bench_01",
        "furn_de_p_bench_03",
        "furn_de_p_bench_04",
        "furn_de_bench_03",
        "furn_de_ex_stool_02",
    }) do
        local status = module.explicitProfileStatus and module.explicitProfileStatus(recordId) or {}
        infoLog(
            "profile loader explicit",
            recordId,
            status.explicit == true and "found" or "missing",
            "profile", tostring(status.profileId),
            "type", tostring(status.interactionType),
            "source", tostring(status.sourceName),
            "fallback", tostring(status.fallback == true)
        )
    end
    infoLog(
        "profile loader explicit",
        "furn_velothi_prayer_stool_01",
        "excluded",
        "profile", "prayer_stool",
        "type", "sitting",
        "source", "hard_exclusion",
        "fallback", "false",
        "reason", "normal_sitting_not_supported"
    )
end


function module.settings()
    local merged = shallowCopy(module.DEFAULT_SETTINGS)
    local logLevelWasStored = false

    for key in pairs(module.DEFAULT_SETTINGS) do
        if not module.HIDDEN_DEFAULT_ONLY_SETTINGS[key] then
            local value = nil
            local canonicalGroup = module.SETTING_CANONICAL_GROUPS[key] or module.SETTINGS_GROUP
            value = storage.globalSection(canonicalGroup):get(key)
            if value == nil then
                for _, groupKey in ipairs(module.SETTING_GROUP_KEYS) do
                    if groupKey ~= canonicalGroup then
                        value = storage.globalSection(groupKey):get(key)
                        if value ~= nil then break end
                    end
                end
            end
            if key == "logLevel" and value ~= nil then logLevelWasStored = true end
            if value ~= nil then merged[key] = value end
        end
    end

    if logLevelWasStored ~= true then
        if merged.verboseDebug == true or merged.debugVerbose == true then
            merged.logLevel = "verbose"
        elseif merged.debug == true then
            merged.logLevel = "trace"
        end
    end

    return logging.applyDerivedFlags(merged)
end

function module.settingsSection()
    -- Legacy compatibility: callers that still expect one section receive the old one.
    return storage.globalSection(module.SETTINGS_GROUP)
end

function module.settingsSections()
    local sections = {}
    for _, groupKey in ipairs(module.SETTING_GROUP_KEYS) do
        sections[#sections + 1] = storage.globalSection(groupKey)
    end
    return sections
end

function module.subscribeSettings(callback)
    for _, section in ipairs(module.settingsSections()) do
        section:subscribe(callback)
    end
end

function module.logLevel(settings)
    return logging.level(settings)
end

module.NOISY_DEBUG_TAGS = logging.NOISY_TRACE_TAGS

function module.isNoisyDebugTag(tag)
    return logging.isNoisyTraceTag(tag)
end

function module.debugLog(settings, ...)
    logging.debugLog(settings, ...)
end

function module.verboseLog(settings, ...)
    logging.verboseLog(settings, ...)
end

function module.objectDebugId(obj)
    if not obj then return "<nil>" end
    return tostring(obj.recordId or obj.id or "<unknown-object>")
end

function module.objectModelPath(obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then
            return obj.type.record(obj)
        end
        return nil
    end)
    if ok and rec and rec.model then return rec.model end
    return nil
end

function module.isInteractionEnabled(settings, interactionType)
    if interactionType == "sitting" then return settings.enableSitting == true end
    if interactionType == "sleeping" then return settings.enableSleeping == true end
    return false
end

function module.isHourInWindow(currentHour, startHour, endHour)
    if currentHour == nil or startHour == nil or endHour == nil then return false end
    if startHour == endHour then return false end
    if startHour < endHour then
        return currentHour >= startHour and currentHour < endHour
    end
    return currentHour >= startHour or currentHour < endHour
end

function module.getGameHour()
    if not core or not core.getGameTime then return nil end
    return (core.getGameTime() % (24 * 60 * 60)) / 3600
end

function module.getGameTime()
    if not core or not core.getGameTime then return nil end
    return core.getGameTime()
end

local function normalizeHour(hour)
    if hour == nil then return nil end
    hour = tonumber(hour)
    if not hour then return nil end
    hour = hour % 24
    if hour < 0 then hour = hour + 24 end
    return hour
end
module.normalizeHour = normalizeHour

function module.hourDeltaFrom(startHour, hour)
    startHour = normalizeHour(startHour)
    hour = normalizeHour(hour)
    if startHour == nil or hour == nil then return nil end
    local delta = hour - startHour
    if delta < 0 then delta = delta + 24 end
    return delta
end

function module.stableUnitInterval(key)
    key = tostring(key or "")
    local hash = 0
    for i = 1, #key do
        hash = (hash * 131 + key:byte(i)) % 1000003
    end
    return (hash % 1000000) / 1000000
end

function module.stableMixedUnitInterval(key)
    key = tostring(key or "")
    local len = #key
    local h1 = 0
    local h2 = 0
    for i = 1, len do
        local byte = key:byte(i)
        h1 = (h1 * 131 + byte + i * 17) % 1000003
        h2 = (h2 * 137 + byte * (len - i + 1) + i * 31) % 1000033
    end
    local hash = (h1 * 9176 + h2 * 6113 + len * 101) % 1000000
    return hash / 1000000
end

function module.derivedSleepForceHour(settings)
    local startHour = normalizeHour(settings and settings.sleepStartHour)
    local endHour = normalizeHour(settings and settings.sleepEndHour)
    if not startHour or not endHour then return nil end

    local totalDelta = module.hourDeltaFrom(startHour, endHour)
    if not totalDelta or totalDelta <= 0 then return nil end

    local configured = normalizeHour(settings and settings.sleepForceInBedHour)
    local configuredDelta = configured and module.hourDeltaFrom(startHour, configured) or nil
    if configured and configuredDelta and configuredDelta > 0 and configuredDelta < totalDelta then
        return configured, configuredDelta
    end

    local delay = math.min(module.SLEEP_FORCE_IN_BED_DELAY_HOURS, math.max(0.25, totalDelta * 0.35))
    return normalizeHour(startHour + delay), delay
end

function module.derivedWakeStartHour(settings)
    local startHour = normalizeHour(settings and settings.sleepStartHour)
    local endHour = normalizeHour(settings and settings.sleepEndHour)
    if not startHour or not endHour then return nil end

    local totalDelta = module.hourDeltaFrom(startHour, endHour)
    if not totalDelta or totalDelta <= 0 then return nil end

    local window = math.min(module.SLEEP_WAKE_VARIATION_HOURS, math.max(0.5, totalDelta * 0.35))
    return normalizeHour(endHour - window), totalDelta - window, window
end

function module.hourInSleepWindowPhase(settings, currentHour)
    if not settings or currentHour == nil then
        return { allowed = false, reason = "missing_safe_time_api" }
    end

    local startHour = normalizeHour(settings.sleepStartHour)
    local endHour = normalizeHour(settings.sleepEndHour)
    local forceHour, forceDelay = module.derivedSleepForceHour(settings)

    if not startHour or not endHour then
        return { allowed = false, reason = "missing_safe_time_api" }
    end

    if not module.isHourInWindow(currentHour, startHour, endHour) then
        return { allowed = false, reason = "sleep_before_start_hour" }
    end

    local totalDelta = module.hourDeltaFrom(startHour, endHour)
    local nowDelta = module.hourDeltaFrom(startHour, currentHour)
    if not totalDelta or totalDelta <= 0 or not nowDelta then
        return { allowed = false, reason = "invalid_sleep_window" }
    end

    local forceDelta = forceDelay or (forceHour and module.hourDeltaFrom(startHour, forceHour))
    if not forceHour or not forceDelta then
        return { allowed = true, phase = "bedtime_range", nowDelta = nowDelta, totalDelta = totalDelta }
    end

    if forceDelta <= 0 then
        return { allowed = true, phase = "force_in_bed", nowDelta = nowDelta, forceDelta = 0, totalDelta = totalDelta }
    end

    if forceDelta >= totalDelta then
        return { allowed = true, phase = "bedtime_range", nowDelta = nowDelta, forceDelta = forceDelta, totalDelta = totalDelta }
    end

    if nowDelta >= forceDelta then
        return { allowed = true, phase = "force_in_bed", nowDelta = nowDelta, forceDelta = forceDelta, totalDelta = totalDelta }
    end

    return { allowed = true, phase = "bedtime_range", nowDelta = nowDelta, forceDelta = forceDelta, totalDelta = totalDelta }
end

function module.actorSleepTiming(actorKey, cellKey, settings, currentHour, options)
    options = options or {}
    local phase = module.hourInSleepWindowPhase(settings, currentHour)
    if not phase.allowed then return phase end

    local startHour = normalizeHour(settings.sleepStartHour)
    local forceHour, forceDelta = module.derivedSleepForceHour(settings)
    local endHour = normalizeHour(settings.sleepEndHour)
    local totalDelta = phase.totalDelta
    local nowDelta = phase.nowDelta

    if not startHour or not endHour or not totalDelta or not nowDelta then
        return { allowed = false, reason = "missing_safe_time_api" }
    end

    -- Deterministic bedtime inside the broad player-facing start window. Keep
    -- the per-actor time even after force-in-bed so priority/search policy does
    -- not collapse everyone to the hard cutoff.
    if forceHour and forceDelta and forceDelta > 0 then
        local key = tostring(actorKey or "<actor>") .. "::" .. tostring(cellKey or "<cell>") .. "::bedtime"
        local unit = module.stableMixedUnitInterval(key)
        local actorDelta = forceDelta * unit
        local actorBedtime = normalizeHour(startHour + actorDelta)

        phase.actorBedtime = actorBedtime
        phase.actorBedtimeDelta = actorDelta

        if phase.nowDelta < actorDelta then
            phase.allowed = false
            phase.reason = "sleep_before_actor_bedtime"
            return phase
        end
    else
        phase.actorBedtime = startHour
        phase.actorBedtimeDelta = 0
    end

    -- Deterministic wake time inside an internal wake window ending at the
    -- player-facing latest wake hour. This prevents synchronized wakeups while
    -- keeping the precise spread script-side.
    local wakeStartHour, wakeStartDelta = module.derivedWakeStartHour(settings)
    local wakeEndDelta = totalDelta

    if wakeStartDelta and wakeStartDelta > 0 and wakeStartDelta < wakeEndDelta then
        local key = tostring(actorKey or "<actor>") .. "::" .. tostring(cellKey or "<cell>") .. "::wake"
        local unit = module.stableMixedUnitInterval(key)
        local bias = tonumber(options.wakeBias or 0) or 0
        if bias < 0 then bias = 0 end
        if bias > 0.95 then bias = 0.95 end
        unit = unit * (1 - bias)
        local wakeDelta = wakeStartDelta + ((wakeEndDelta - wakeStartDelta) * unit)
        local wakeHour = normalizeHour(startHour + wakeDelta)
        phase.actorWakeTime = wakeHour
        phase.actorWakeDelta = wakeDelta
        phase.wakeBias = bias
        phase.wakeStartHour = wakeStartHour

        if nowDelta >= wakeDelta then
            phase.allowed = false
            phase.reason = "sleep_after_actor_wake_time"
            return phase
        end
    else
        phase.actorWakeTime = endHour
        phase.actorWakeDelta = totalDelta
        if nowDelta >= totalDelta then
            phase.allowed = false
            phase.reason = "outside_allowed_time_window"
            return phase
        end
    end

    return phase
end

function module.isInteractionAllowedByTime(interactionType, profile, settings, currentHour)
    if interactionType ~= "sleeping" then
        return true, nil
    end

    local startHour = settings.sleepStartHour
    local endHour = settings.sleepEndHour
    if profile and profile.allowedHours and profile.useProfileAllowedHours == true then
        startHour = profile.allowedHours.start or startHour
        endHour = profile.allowedHours.finish or endHour
    end

    if currentHour == nil then
        return false, "missing_safe_time_api"
    end

    if not module.isHourInWindow(currentHour, startHour, endHour) then
        return false, "outside_allowed_time_window"
    end

    return true, nil
end

local function isFallbackAllowed(settings, interactionType)
    if interactionType == "sitting" then return settings.allowFallbackSitting == true end
    if interactionType == "sleeping" then return settings.allowFallbackSleeping == true end
    return false
end

local recordLooksLikeSittable = objectMatchers.recordLooksLikeSittable
local recordLooksLikeBed = objectMatchers.recordLooksLikeBed
local anyKeyLooksLike = objectMatchers.anyKeyLooksLike

module.objectRecord = objectMatchers.objectRecord

function module.objectProfileKeys(obj)
    return objectMatchers.profileKeys(obj)
end

local traceSelectedProfile
local traceSkippedProfile
local applyStationOrientationVariant

local function bestScopedProfileForObject(entries, obj, interactionType)
    local best = nil
    local bestScore = nil
    for _, profile in ipairs(entries or {}) do
        if profile and profile.interactionType == interactionType and profileScope.matchesObject(profile.scope, obj) then
            local score = profileScope.specificityScore(profile.scope)
            if best == nil or score >= bestScore then
                best = profile
                bestScore = score
            end
        end
    end
    return best
end

function module.stationProfileForObject(obj, settings)
    if not obj then return traceSkippedProfile(obj, "station", settings, nil, "missing_object") end
    local keys = module.objectProfileKeys(obj)
    local blacklistedReason = module.objectBlacklistedReason(obj, settings)
    if blacklistedReason then return traceSkippedProfile(obj, "station", settings, keys, blacklistedReason) end
    for _, key in ipairs(keys) do
        local scopedProfile = bestScopedProfileForObject(module.scopedStationProfilesByRecordId and module.scopedStationProfilesByRecordId[key], obj, "station")
        if scopedProfile then
            local applied = applyStationOrientationVariant and applyStationOrientationVariant(scopedProfile, obj, key) or scopedProfile
            return traceSelectedProfile(obj, "station", settings, keys, key, applied, nil, "matched_scoped_station_profile_key")
        end
        local profile = module.stationProfilesByRecordId and module.stationProfilesByRecordId[key]
        if profile then
            local applied = applyStationOrientationVariant and applyStationOrientationVariant(profile, obj, key) or profile
            return traceSelectedProfile(obj, "station", settings, keys, key, applied, nil, "matched_station_profile_key")
        end
    end
    return traceSkippedProfile(obj, "station", settings, keys, "no_station_profile")
end

function module.stationWorldPosition(obj, profile, util)
    if not (obj and obj.position and profile and profile.localOffset and util) then return nil end
    local yaw = 0
    if obj.rotation and obj.rotation.getYaw then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then yaw = value end
    end
    local offset = profile.localOffset
    local localVector = scalePolicy.scaledLocalVector(util, obj, offset)
    local x = localVector and localVector.x or 0
    local y = localVector and localVector.y or 0
    local z = localVector and localVector.z or 0
    local c = math.cos(yaw)
    local s = math.sin(yaw)
    return obj.position + util.vector3(x * c - y * s, x * s + y * c, z)
end

function module.stationFacingDirection(obj, profile, util)
    if not (profile and util) then return nil end
    local objectYaw = 0
    if obj and obj.rotation and obj.rotation.getYaw then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and type(value) == "number" then objectYaw = value end
    end
    local yaw = objectYaw + math.rad(tonumber(profile.facingYawDeg) or 0)
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

function module.objectLooksRelevantForInteraction(obj, interactionType, settings)
    if not obj then return false end
    if objectMatchers.objectEnabled(obj) ~= true then return false end
    if objectMatchers.hiddenOrStagedObjectReason(obj) then return false end
    if module.objectBlacklistedReason(obj, settings) then return false end

    local keys = module.objectProfileKeys(obj)
    if #keys == 0 then return false end

    for _, key in ipairs(keys) do
        if bestScopedProfileForObject(module.scopedProfilesByRecordId and module.scopedProfilesByRecordId[key], obj, interactionType) then
            return true
        end
        if module.profilesByRecordId[key] then
            return module.profilesByRecordId[key].interactionType == interactionType
        end
    end

    if not isFallbackAllowed(settings, interactionType) then
        return false
    end

    if interactionType == "sitting" then
        local ok = module.sittingFallbackCandidateStatus(obj, settings)
        return ok == true
    end

    if interactionType == "sleeping" then
        local ok = sleepCandidateClassifier.classify(obj, module.objectModelPath(obj))
        return ok == true
    end


    return false
end

function module.sleepFallbackCandidateStatus(obj)
    if obj and objectMatchers.objectEnabled(obj) ~= true then return false, "disabled_object" end
    local blacklistedReason = module.objectBlacklistedReason(obj, nil)
    if blacklistedReason then return false, blacklistedReason end
    local hiddenReason = objectMatchers.hiddenOrStagedObjectReason(obj)
    if hiddenReason then return false, hiddenReason end
    return sleepCandidateClassifier.classify(obj, module.objectModelPath(obj))
end

function module.sittingFallbackCandidateStatus(obj, settings)
    if obj and objectMatchers.objectEnabled(obj) ~= true then return false, "disabled_object" end
    local blacklistedReason = module.objectBlacklistedReason(obj, settings)
    if blacklistedReason then return false, blacklistedReason end
    local hiddenReason = objectMatchers.hiddenOrStagedObjectReason(obj)
    if hiddenReason then return false, hiddenReason end
    local keys = module.objectProfileKeys(obj)
    if #keys == 0 then return false, "missing_object_record" end
    local ok = anyKeyLooksLike(keys, recordLooksLikeSittable)
    if ok ~= true then return false, "not_sittable_token" end
    local category = module.sittingFallbackCategoryFromKeys(keys)
    if category == "prayer_stool" then return false, "prayer_stool_normal_sitting_not_supported", category end
    if module.fallbackSittingCategoryAllowed(category, settings) ~= true then
        return false, "fallback_sitting_category_not_allowed", category
    end
    return true, "fallback_sitting_allowed", category
end


local function classifyBedTypeFromRecordId(recordId)
    local id = normalizeId(recordId) or ""
    if id:find("hammock", 1, true) then return "hammock" end
    if id:find("bedroll", 1, true)
        or id:find("roll", 1, true)
        or id:find("matressnomad", 1, true)
        or id:find("mattressnomad", 1, true)
    then
        return "bedroll"
    end
    if id:find("bottom", 1, true) or id:find("lower", 1, true) or id:find("bunk_02", 1, true) then return "bottom_bunk" end
    if id:find("bunk", 1, true) or id:find("upper", 1, true) or id:find("top", 1, true) then return "top_bunk" end
    if id:find("double", 1, true) or id:find("_d_", 1, true) then return "double" end
    return "single"
end

local function generatedSleepProfileUnsafeReason(profile, recordId)
    if not (profile and profile.interactionType == "sleeping") then return nil end
    if profile.externalProfile == true then return nil end
    local bedType = profile.bedType or classifyBedTypeFromRecordId(recordId)
    if bedType == "double" then return "fallback_double_bed_requires_explicit_slots" end
    if bedType == "top_bunk" or bedType == "bottom_bunk" or bedType == "bunk" or bedType == "bunk_bed" then
        return "fallback_bunk_requires_explicit_top_bottom_slots"
    end
    return nil
end

local function buildSleepProfileAverages()
    local sums = {}
    local counts = {}

    local function add(kind, profile)
        if not (kind and profile and profile.sleepRootLocalOffset) then return end
        local bucket = sums[kind]
        if not bucket then
            bucket = { x = 0, y = 0, z = 0 }
            sums[kind] = bucket
            counts[kind] = 0
        end
        bucket.x = bucket.x + (tonumber(profile.sleepRootLocalOffset.x) or 0)
        bucket.y = bucket.y + (tonumber(profile.sleepRootLocalOffset.y) or 0)
        bucket.z = bucket.z + (tonumber(profile.sleepRootLocalOffset.z) or 0)
        counts[kind] = (counts[kind] or 0) + 1
    end

    for recordId, profile in pairs(module.profilesByRecordId or {}) do
        if profile and profile.externalProfile == true and profile.interactionType == "sleeping" then
            local kind = profile.bedType or classifyBedTypeFromRecordId(recordId)
            add(kind, profile)
            add("all", profile)
        end
    end

    local averages = {}
    for kind, bucket in pairs(sums) do
        local count = counts[kind] or 0
        if count > 0 then
            averages[kind] = {
                sleepRootLocalOffset = { x = bucket.x / count, y = bucket.y / count, z = bucket.z / count },
                count = count,
            }
        end
    end

    return averages
end

module.sleepProfileAverages = buildSleepProfileAverages()

local function applyGenericBedTypeDefaults(profile, settings, recordId)
    if not profile or profile.interactionType ~= "sleeping" or profile.externalProfile == true then return profile end
    local averages = module.sleepProfileAverages or {}
    local bedType = profile.bedType or classifyBedTypeFromRecordId(recordId)
    local avg = averages[bedType] or averages.single or averages.all
    if not avg then return profile end

    local copy = shallowCopy(profile)
    copy.profileBedTypeFallback = bedType
    copy.profileBedTypeFallbackCount = avg.count
    copy.profileBedTypeFallbackLowConfidence = true
    copy.profileBedTypeFallbackAxes = "z_only"
    if not copy.bedType then copy.bedType = bedType end
    local base = profile.sleepRootLocalOffset or { x = 0, y = 0, z = 0 }
    copy.sleepRootLocalOffset = {
        x = tonumber(base.x) or 0,
        y = tonumber(base.y) or 0,
        z = avg.sleepRootLocalOffset.z or 0,
    }
    return copy
end

local function yawFromObject(obj)
    if not (obj and obj.rotation and obj.rotation.getYaw) then return 0 end
    local ok, yaw = pcall(function() return obj.rotation:getYaw() end)
    if ok and tonumber(yaw) then return tonumber(yaw) end
    return 0
end

local function yawBucket(deg, size)
    size = tonumber(size) or 90
    local normalized = ((tonumber(deg) or 0) % 360 + 360) % 360
    return (math.floor((normalized + (size / 2)) / size) * size) % 360
end

function module.objectYawBuckets(obj)
    local deg = math.deg(yawFromObject(obj))
    return {
        objectYawRad = yawFromObject(obj),
        objectYawDeg = deg,
        yawBucket45 = yawBucket(deg, 45),
        yawBucket90 = yawBucket(deg, 90),
    }
end

local function sleepVariantKey(recordId, model, profileId, slotName, yawBucket90)
    return table.concat({
        normalizeId(recordId) or "",
        string.lower(tostring(model or "")),
        string.lower(tostring(profileId or "")),
        string.lower(tostring(slotName or "")),
        tostring(tonumber(yawBucket90) or 0),
    }, "|")
end

local function normalizedDegrees(deg)
    return ((tonumber(deg) or 0) % 360 + 360) % 360
end

local function yawInRange(deg, minDeg, maxDeg)
    if minDeg == nil and maxDeg == nil then return true end
    deg = normalizedDegrees(deg)
    if minDeg == nil then return deg <= normalizedDegrees(maxDeg) end
    if maxDeg == nil then return deg >= normalizedDegrees(minDeg) end
    minDeg = normalizedDegrees(minDeg)
    maxDeg = normalizedDegrees(maxDeg)
    if minDeg <= maxDeg then return deg >= minDeg and deg <= maxDeg end
    return deg >= minDeg or deg <= maxDeg
end

local function sleepVariantMatchesObject(variant, obj, buckets)
    if variant and not profileScope.matchesObject(variant.scope, obj) then return false end
    local anchor = variant and variant.objectPosition or nil
    if anchor then
        local pos = obj and obj.position or nil
        if not pos then return false end
        local dx = (pos.x or 0) - (anchor.x or 0)
        local dy = (pos.y or 0) - (anchor.y or 0)
        local flat = math.sqrt(dx * dx + dy * dy)
        local dz = anchor.z ~= nil and math.abs((pos.z or 0) - (anchor.z or 0)) or 0
        if flat > 8 or dz > 12 then return false end
    end
    if variant and (variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil) then
        return yawInRange(buckets and buckets.objectYawDeg or 0, variant.yawMinDeg, variant.yawMaxDeg)
    end
    return true
end

local function sharedSlotAxes(profile)
    return profile and profile.sharedSlotAxes or nil
end

local function hasTopBottomSleepSlots(profile)
    if not profile then return false end
    local hasTop = false
    local hasBottom = false
    for _, slot in ipairs(profile.slots or {}) do
        local name = tostring(slot and slot.name or "")
        if name == "sleep_top" then hasTop = true end
        if name == "sleep_bottom" then hasBottom = true end
    end
    return hasTop and hasBottom
end

local function sleepProfileSharesSlotYaw(profile)
    if not profile then return false end
    local bedType = tostring(profile.bedType or profile.type or "")
    return bedType == "double"
        or bedType == "top_bunk"
        or bedType == "bottom_bunk"
        or hasTopBottomSleepSlots(profile)
end

local function copyOffsetWithSharedAxes(original, source, axes)
    original = original or {}
    source = source or {}
    if not axes then return original end
    local copy = {
        x = tonumber(original.x) or 0,
        y = tonumber(original.y) or 0,
        z = tonumber(original.z) or 0,
    }
    if axes.x then copy.x = tonumber(source.x) or copy.x end
    if axes.y then copy.y = tonumber(source.y) or copy.y end
    if axes.z then copy.z = tonumber(source.z) or copy.z end
    return copy
end

local function yawRangeWidth(minDeg, maxDeg)
    if minDeg == nil and maxDeg == nil then return 360 end
    if minDeg == nil or maxDeg == nil then return 360 end
    minDeg = normalizedDegrees(minDeg)
    maxDeg = normalizedDegrees(maxDeg)
    if minDeg <= maxDeg then return math.max(0, maxDeg - minDeg) end
    return math.max(0, (360 - minDeg) + maxDeg)
end

local function objectAnchorDistanceScore(anchor, obj)
    if not anchor then return 0 end
    local pos = obj and obj.position or nil
    if not pos then return -1000000 end
    local dx = (pos.x or 0) - (anchor.x or 0)
    local dy = (pos.y or 0) - (anchor.y or 0)
    local flat = math.sqrt(dx * dx + dy * dy)
    local dz = anchor.z ~= nil and math.abs((pos.z or 0) - (anchor.z or 0)) or 0
    -- Object-scoped rows are strongest, but if more than one matches the tolerance,
    -- prefer the physically closest one. This prevents a broad yaw row or an older
    -- nearby object row from winning over the exact placed-object evidence.
    return 100000 - (flat * 10) - dz
end

local function sleepVariantSpecificityScore(variant, obj)
    if not variant then return -1000000 end
    local score = profileScope.specificityScore(variant.scope)
    if variant.objectPosition ~= nil then
        score = score + objectAnchorDistanceScore(variant.objectPosition, obj)
    end
    if variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil then
        score = score + 1000 + (360 - yawRangeWidth(variant.yawMinDeg, variant.yawMaxDeg))
    end
    return score
end

local function firstMatchingSleepVariant(entry, obj, buckets)
    if not entry then return nil end
    if entry.recordId ~= nil then
        if sleepVariantMatchesObject(entry, obj, buckets) then return entry end
        return nil
    end

    local best = nil
    local bestScore = nil
    for _, variant in ipairs(entry) do
        if sleepVariantMatchesObject(variant, obj, buckets) then
            local score = sleepVariantSpecificityScore(variant, obj)
            -- Later rows win when specificity ties. That matches the calibration
            -- workflow where same-target repeat prints usually mean the latest
            -- intentional correction should supersede the previous one, while
            -- still letting object/range specificity beat broad yaw rows.
            if best == nil or score >= bestScore then
                best = variant
                bestScore = score
            end
        end
    end
    return best
end

local function chairVariantMatchesObject(variant, obj, buckets)
    if variant and not profileScope.matchesObject(variant.scope, obj) then return false end
    local anchor = variant and variant.objectPosition or nil
    if anchor then
        local pos = obj and obj.position or nil
        if not pos then return false end
        local dx = (pos.x or 0) - (anchor.x or 0)
        local dy = (pos.y or 0) - (anchor.y or 0)
        local flat = math.sqrt(dx * dx + dy * dy)
        local dz = anchor.z ~= nil and math.abs((pos.z or 0) - (anchor.z or 0)) or 0
        if flat > 8 or dz > 12 then return false end
    end
    if variant and (variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil) then
        return yawInRange(buckets and buckets.objectYawDeg or 0, variant.yawMinDeg, variant.yawMaxDeg)
    end
    return true
end

local function stationVariantMatchesObject(variant, obj, buckets)
    if variant and not profileScope.matchesObject(variant.scope, obj) then return false end
    local anchor = variant and variant.objectPosition or nil
    if anchor then
        local pos = obj and obj.position or nil
        if not pos then return false end
        local dx = (pos.x or 0) - (anchor.x or 0)
        local dy = (pos.y or 0) - (anchor.y or 0)
        local flat = math.sqrt(dx * dx + dy * dy)
        local dz = anchor.z ~= nil and math.abs((pos.z or 0) - (anchor.z or 0)) or 0
        if flat > 8 or dz > 12 then return false end
    end
    if variant and (variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil) then
        return yawInRange(buckets and buckets.objectYawDeg or 0, variant.yawMinDeg, variant.yawMaxDeg)
    end
    return true
end

local function stationVariantSpecificityScore(variant, obj)
    if not variant then return -1000000 end
    local score = profileScope.specificityScore(variant.scope)
    if variant.objectPosition ~= nil then
        score = score + objectAnchorDistanceScore(variant.objectPosition, obj)
    end
    if variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil then
        score = score + 1000 + (360 - yawRangeWidth(variant.yawMinDeg, variant.yawMaxDeg))
    end
    return score
end

local function firstMatchingStationVariant(entry, obj, buckets)
    if not entry then return nil end
    if entry.recordId ~= nil then
        if stationVariantMatchesObject(entry, obj, buckets) then return entry end
        return nil
    end

    local best = nil
    local bestScore = nil
    for _, variant in ipairs(entry) do
        if stationVariantMatchesObject(variant, obj, buckets) then
            local score = stationVariantSpecificityScore(variant, obj)
            if best == nil or score >= bestScore then
                best = variant
                bestScore = score
            end
        end
    end
    return best
end

local function chairVariantSpecificityScore(variant, obj)
    if not variant then return -1000000 end
    local score = profileScope.specificityScore(variant.scope)
    if variant.objectPosition ~= nil then
        score = score + objectAnchorDistanceScore(variant.objectPosition, obj)
    end
    if variant.yawMinDeg ~= nil or variant.yawMaxDeg ~= nil then
        score = score + 1000 + (360 - yawRangeWidth(variant.yawMinDeg, variant.yawMaxDeg))
    end
    return score
end

local function firstMatchingChairVariant(entry, obj, buckets)
    if not entry then return nil end
    if entry.recordId ~= nil then
        if chairVariantMatchesObject(entry, obj, buckets) then return entry end
        return nil
    end

    local best = nil
    local bestScore = nil
    for _, variant in ipairs(entry) do
        if chairVariantMatchesObject(variant, obj, buckets) then
            local score = chairVariantSpecificityScore(variant, obj)
            -- Prefer the narrowest matching yaw range. If two rows are equally
            -- specific, prefer the later row so intentional reprints supersede
            -- older same-target calibration attempts without broadening the fix.
            if best == nil or score >= bestScore then
                best = variant
                bestScore = score
            end
        end
    end
    return best
end

local function chairVariantKey(recordId, model, profileId, slotName, yawBucket90)
    return table.concat({
        normalizeId(recordId) or "",
        string.lower(tostring(model or "")),
        string.lower(tostring(profileId or "")),
        string.lower(tostring(slotName or "")),
        tostring(tonumber(yawBucket90) or 0),
    }, "|")
end

local function stationVariantKey(recordId, model, profileId, slotName, yawBucket90)
    return table.concat({
        normalizeId(recordId) or "",
        string.lower(tostring(model or "")),
        string.lower(tostring(profileId or "")),
        string.lower(tostring(slotName or "")),
        tostring(tonumber(yawBucket90) or 0),
    }, "|")
end

local function csvList(values)
    local out = {}
    for _, value in ipairs(values or {}) do out[#out + 1] = tostring(value) end
    return table.concat(out, ",")
end

local function profileSelectionSource(profile, reason)
    if not profile then return "none" end
    if profile.orientationVariantSource then return profile.orientationVariantSource end
    if profile.chairOrientationVariantSource then return profile.chairOrientationVariantSource end
    if profile.stationOrientationVariantSource then return profile.stationOrientationVariantSource end
    if reason == "fallback_profile" or profile.isFallback == true then return "fallback_profile" end
    if profile.profileBedTypeFallbackLowConfidence == true then return "bed_type_average_low_confidence" end
    if profile.profileBedTypeFallback then return "bed_type_average" end
    if profile.profileBedTypeAverageAlias == true then return "bed_type_average_alias" end
    if profile.externalProfile == true then return "explicit_profile" end
    if profile.sourceName then return "explicit_profile" end
    if profile.profileId then return "built_in_profile" end
    return "unknown_profile_source"
end

local function selectionTraceFor(obj, interactionType, keys, selectedKey, profile, reason, outcome, detail)
    local buckets = module.objectYawBuckets and module.objectYawBuckets(obj) or {}
    local trace = {
        outcome = tostring(outcome or (profile and "selected" or "skipped")),
        interactionType = tostring(interactionType or ""),
        objectId = tostring(obj and (obj.recordId or obj.id) or ""),
        model = tostring(module.objectModelPath(obj) or ""),
        profileId = tostring(profile and profile.profileId or ""),
        selectedKey = tostring(selectedKey or ""),
        candidateKeys = csvList(keys),
        reason = tostring(reason or ""),
        source = profileSelectionSource(profile, reason),
        sourceName = tostring(profile and profile.sourceName or ""),
        fallbackReason = tostring(profile and profile.fallbackSleepCandidateReason or ""),
        scope = tostring(profileScope.label(profile and profile.scope) or ""),
        orientationVariantSource = tostring(profile and profile.orientationVariantSource or ""),
        chairVariantSource = tostring(profile and profile.chairOrientationVariantSource or ""),
        stationVariantSource = tostring(profile and profile.stationOrientationVariantSource or ""),
        yawBucket90 = tostring(buckets.yawBucket90 or ""),
        yawBucket45 = tostring(buckets.yawBucket45 or ""),
        objectYawDeg = tostring(buckets.objectYawDeg or ""),
        detail = tostring(detail or ""),
    }
    if profile and profile.orientationVariant then
        trace.variantSource = tostring(profile.orientationVariant.sourceName or "")
        trace.variantSlot = tostring(profile.orientationVariant.slotName or "")
        trace.variantProfile = tostring(profile.orientationVariant.profileId or "")
        trace.variantScope = tostring(profileScope.label(profile.orientationVariant.scope) or "")
    elseif profile and profile.chairOrientationVariant then
        trace.variantSource = tostring(profile.chairOrientationVariant.sourceName or "")
        trace.variantSlot = tostring(profile.chairOrientationVariant.slotName or "")
        trace.variantProfile = tostring(profile.chairOrientationVariant.profileId or "")
        trace.variantScope = tostring(profileScope.label(profile.chairOrientationVariant.scope) or "")
    elseif profile and profile.stationOrientationVariant then
        trace.variantSource = tostring(profile.stationOrientationVariant.sourceName or "")
        trace.variantSlot = tostring(profile.stationOrientationVariant.slotName or "")
        trace.variantProfile = tostring(profile.stationOrientationVariant.profileId or "")
        trace.variantScope = tostring(profileScope.label(profile.stationOrientationVariant.scope) or "")
    end
    return trace
end

local function logProfileSelection(settings, trace)
    if not trace then return end
    if trace.outcome == "skipped" and trace.interactionType == "station" and trace.reason == "no_station_profile" then return end
    if trace.outcome == "selected" and trace.interactionType == "station" then
        local key = table.concat({
            tostring(trace.interactionType),
            tostring(trace.outcome),
            tostring(trace.objectId),
            tostring(trace.profileId),
            tostring(trace.selectedKey),
            tostring(trace.source),
        }, "|")
        local now = core.getSimulationTime and core.getSimulationTime() or 0
        local last = profileSelectionLogCache[key]
        if last and now - last < 3 then return end
        profileSelectionLogCache[key] = now
    end
    module.debugLog(
        settings,
        "profile selection " .. tostring(trace.outcome),
        "type", tostring(trace.interactionType),
        "object", tostring(trace.objectId),
        "model", tostring(trace.model),
        "profile", tostring(trace.profileId),
        "source", tostring(trace.source),
        "sourceFile", tostring(trace.sourceName),
        "selectedKey", tostring(trace.selectedKey),
        "candidateKeys", tostring(trace.candidateKeys),
        "reason", tostring(trace.reason),
        "detail", tostring(trace.detail),
        "scope", tostring(trace.scope),
        "variantSource", tostring(trace.orientationVariantSource ~= "" and trace.orientationVariantSource or (trace.chairVariantSource ~= "" and trace.chairVariantSource or trace.stationVariantSource)),
        "variantFile", tostring(trace.variantSource or ""),
        "variantScope", tostring(trace.variantScope or ""),
        "variantSlot", tostring(trace.variantSlot or ""),
        "yawBucket90", tostring(trace.yawBucket90),
        "objectYawDeg", tostring(trace.objectYawDeg)
    )
end

traceSelectedProfile = function(obj, interactionType, settings, keys, selectedKey, profile, reason, detail)
    local copy = shallowCopy(profile or {})
    local trace = selectionTraceFor(obj, interactionType, keys, selectedKey, copy, reason, "selected", detail)
    copy.profileSelectionTrace = trace
    copy.profileSelectionSource = trace.source
    copy.profileSelectionReason = trace.reason
    copy.profileSelectionKey = trace.selectedKey
    logProfileSelection(settings, trace)
    return copy
end

traceSkippedProfile = function(obj, interactionType, settings, keys, reason, detail)
    logProfileSelection(settings, selectionTraceFor(obj, interactionType, keys, nil, nil, reason, "skipped", detail))
    return nil, reason
end

applyStationOrientationVariant = function(profile, obj, recordId)
    if not (profile and profile.interactionType == "station" and obj) then return profile end
    local buckets = module.objectYawBuckets(obj)
    local bucket90 = buckets.yawBucket90
    local variants = module.stationOrientationVariants or {}
    local model = module.objectModelPath(obj) or profile.model or ""
    local profileId = profile.profileId or recordId
    local slotName = string.lower(tostring(profile.slotName or "presenter"))
    local selected = firstMatchingStationVariant(variants[stationVariantKey(recordId, model, profileId, slotName, bucket90)], obj, buckets)
        or firstMatchingStationVariant(variants[stationVariantKey(recordId, "", profileId, slotName, bucket90)], obj, buckets)
    if not selected then return profile end

    local copied = shallowCopy(profile)
    copied.localOffset = selected.localOffset or profile.localOffset
    if selected.facingYawDeg ~= nil then copied.facingYawDeg = selected.facingYawDeg end
    if selected.radius ~= nil then copied.radius = selected.radius end
    if selected.stationType and selected.stationType ~= "" then copied.stationType = selected.stationType end
    if selected.flags then copied.flags = selected.flags end
    copied.stationOrientationVariant = selected
    copied.stationOrientationVariantSource = "explicit_station_orientation_variant"
    copied.stationOrientationYawBucket90 = bucket90
    copied.stationOrientationYawBucket45 = buckets.yawBucket45
    copied.stationOrientationObjectYawDeg = buckets.objectYawDeg
    return copied
end

local function applySleepOrientationVariant(profile, obj, recordId)
    if not (profile and profile.interactionType == "sleeping" and obj) then return profile end
    local buckets = module.objectYawBuckets(obj)
    local bucket90 = buckets.yawBucket90
    local variants = module.sleepOrientationVariants or {}
    local model = module.objectModelPath(obj) or profile.model or ""
    local profileId = profile.profileId or recordId
    local copied = nil
    local selected = nil
    local selectedYawOffset = nil

    for i, slot in ipairs(profile.slots or {}) do
        local slotName = module.slotName(slot, i)
        local variant = firstMatchingSleepVariant(variants[sleepVariantKey(recordId, model, profileId, slotName, bucket90)], obj, buckets)
            or firstMatchingSleepVariant(variants[sleepVariantKey(recordId, "", profileId, slotName, bucket90)], obj, buckets)
        if variant then
            if not copied then
                copied = shallowCopy(profile)
                copied.slots = cloneSlots(profile.slots)
            end
            copied.slots[i] = shallowCopy(copied.slots[i])
            copied.slots[i].sleepRootLocalOffset = variant.sleepRootLocalOffset
            if variant.sleepPoseYawOffset ~= nil then copied.slots[i].sleepPoseYawOffset = variant.sleepPoseYawOffset end
            copied.slots[i].orientationVariant = variant
            copied.orientationVariantSource = "explicit_profile_orientation_variant"
            copied.orientationYawBucket90 = bucket90
            copied.orientationYawBucket45 = buckets.yawBucket45
            copied.orientationObjectYawDeg = buckets.objectYawDeg
            selected = variant
            if variant.sleepPoseYawOffset ~= nil then selectedYawOffset = variant.sleepPoseYawOffset end
        end
    end

    if copied then
        local axes = sharedSlotAxes(copied)
        if axes and selected and selected.sleepRootLocalOffset then
            for i, slot in ipairs(copied.slots or {}) do
                copied.slots[i] = shallowCopy(slot)
                copied.slots[i].sleepRootLocalOffset = copyOffsetWithSharedAxes(
                    slot.sleepRootLocalOffset or profile.slots[i] and profile.slots[i].sleepRootLocalOffset or profile.sleepRootLocalOffset,
                    selected.sleepRootLocalOffset,
                    axes
                )
            end
        end
        if selectedYawOffset ~= nil and sleepProfileSharesSlotYaw(copied) and not (selected and selected.splitSlotYaw == true) then
            for i, slot in ipairs(copied.slots or {}) do
                copied.slots[i] = shallowCopy(slot)
                local explicitYaw = slot.orientationVariant and slot.orientationVariant.sleepPoseYawOffset ~= nil
                if not explicitYaw then
                    copied.slots[i].sleepPoseYawOffset = selectedYawOffset
                end
            end
        end
        copied.orientationVariant = selected
        return copied
    end

    if normalizeId(recordId) == "active_com_bunk_02" then
        local copy = shallowCopy(profile)
        copy.orientationVariantSource = profile.externalProfile == true and "explicit_profile" or (profile.profileBedTypeFallbackLowConfidence and "bed_type_average_low_confidence" or (profile.profileBedTypeFallback and "bed_type_average" or "fallback"))
        copy.orientationVariantFallback = true
        copy.orientationYawBucket90 = bucket90
        copy.orientationYawBucket45 = buckets.yawBucket45
        copy.orientationObjectYawDeg = buckets.objectYawDeg
        return copy
    end

    return profile
end

local function applyChairOrientationVariant(profile, obj, recordId)
    if not (profile and profile.interactionType == "sitting" and obj) then return profile end
    local buckets = module.objectYawBuckets(obj)
    local bucket90 = buckets.yawBucket90
    local variants = module.chairOrientationVariants or {}
    local model = module.objectModelPath(obj) or profile.model or ""
    local profileId = profile.profileId or recordId
    local copied = nil
    local selected = nil
    local slotOffsets = nil

    local function offsetDelta(finalOffset)
        local baseOffset = profile.sittingActivityOffsets and profile.sittingActivityOffsets.standard or nil
        baseOffset = baseOffset or { x = 0, y = 0, z = 0, yaw = 0 }
        finalOffset = finalOffset or { x = 0, y = 0, z = 0, yaw = 0 }
        return {
            x = (tonumber(finalOffset.x) or 0) - (tonumber(baseOffset.x) or 0),
            y = (tonumber(finalOffset.y) or 0) - (tonumber(baseOffset.y) or 0),
            z = (tonumber(finalOffset.z) or 0) - (tonumber(baseOffset.z) or 0),
            yaw = (tonumber(finalOffset.yaw) or 0) - (tonumber(baseOffset.yaw) or 0),
        }
    end

    local function includeVariant(slotName)
        local variant = firstMatchingChairVariant(variants[chairVariantKey(recordId, model, profileId, slotName, bucket90)], obj, buckets)
            or firstMatchingChairVariant(variants[chairVariantKey(recordId, "", profileId, slotName, bucket90)], obj, buckets)
        if not variant then return end
        if not copied then
            copied = shallowCopy(profile)
            slotOffsets = {}
            for key, value in pairs(profile.sittingSlotOrientationOffsets or {}) do slotOffsets[key] = value end
            copied.sittingSlotOrientationOffsets = slotOffsets
            copied.chairOrientationVariantSource = "explicit_chair_orientation_variant"
            copied.chairOrientationYawBucket90 = bucket90
            copied.chairOrientationYawBucket45 = buckets.yawBucket45
            copied.chairOrientationObjectYawDeg = buckets.objectYawDeg
        end
        copied.sittingSlotOrientationOffsets[string.lower(tostring(slotName or "default"))] = offsetDelta(variant.offset)
        selected = variant
    end

    if profile.slots and #profile.slots > 0 then
        for i, slot in ipairs(profile.slots) do
            includeVariant(module.slotName(slot, i))
        end
    else
        includeVariant("default")
    end

    if copied then
        local axes = sharedSlotAxes(copied)
        local selectedOffset = selected and selected.offset and offsetDelta(selected.offset) or nil
        if axes and selectedOffset and profile.slots and #profile.slots > 0 then
            for i, slot in ipairs(profile.slots) do
                local slotName = string.lower(tostring(module.slotName(slot, i)))
                local existing = copied.sittingSlotOrientationOffsets[slotName] or { x = 0, y = 0, z = 0, yaw = 0 }
                copied.sittingSlotOrientationOffsets[slotName] = {
                    x = axes.x and selectedOffset.x or (tonumber(existing.x) or 0),
                    y = axes.y and selectedOffset.y or (tonumber(existing.y) or 0),
                    z = axes.z and selectedOffset.z or (tonumber(existing.z) or 0),
                    yaw = tonumber(existing.yaw) or 0,
                }
            end
        end
        copied.chairOrientationVariant = selected
        return copied
    end

    return profile
end

function module.getProfileForObject(obj, interactionType, settings)
    if not obj then return traceSkippedProfile(obj, interactionType, settings, nil, "missing_object") end

    local keys = module.objectProfileKeys(obj)
    if #keys == 0 then return traceSkippedProfile(obj, interactionType, settings, keys, "missing_object_record") end

    local blacklistedReason = module.objectBlacklistedReason(obj, settings)
    if blacklistedReason then return traceSkippedProfile(obj, interactionType, settings, keys, blacklistedReason) end

    for _, key in ipairs(keys) do
        local scopedProfile = bestScopedProfileForObject(module.scopedProfilesByRecordId and module.scopedProfilesByRecordId[key], obj, interactionType)
        if scopedProfile then
            local applied = applyGenericBedTypeDefaults(scopedProfile, settings, key)
            if interactionType == "sleeping" then applied = applySleepOrientationVariant(applied, obj, key) end
            if interactionType == "sitting" then applied = applyChairOrientationVariant(applied, obj, key) end
            return traceSelectedProfile(obj, interactionType, settings, keys, key, applied, nil, "matched_scoped_profile_key")
        end
        local profile = module.profilesByRecordId[key]
        if profile and profile.interactionType == interactionType then
            if interactionType == "sleeping" and profile.profileBedTypeAverageAlias == true and not isFallbackAllowed(settings, interactionType) then
                return traceSkippedProfile(obj, interactionType, settings, keys, "fallback_sleeping_disabled", "matched=" .. tostring(key))
            end
            local unsafeGeneratedReason = interactionType == "sleeping" and generatedSleepProfileUnsafeReason(profile, key) or nil
            if unsafeGeneratedReason then
                return traceSkippedProfile(obj, interactionType, settings, keys, unsafeGeneratedReason, "matched=" .. tostring(key))
            end
            local applied = applyGenericBedTypeDefaults(profile, settings, key)
            if interactionType == "sleeping" then applied = applySleepOrientationVariant(applied, obj, key) end
            if interactionType == "sitting" then applied = applyChairOrientationVariant(applied, obj, key) end
            return traceSelectedProfile(obj, interactionType, settings, keys, key, applied, nil, "matched_profile_key")
        end
    end

    for _, key in ipairs(keys) do
        local scopedOther = bestScopedProfileForObject(module.scopedProfilesByRecordId and module.scopedProfilesByRecordId[key], obj, "sitting")
            or bestScopedProfileForObject(module.scopedProfilesByRecordId and module.scopedProfilesByRecordId[key], obj, "sleeping")
        if scopedOther and scopedOther.interactionType ~= interactionType then
            return traceSkippedProfile(obj, interactionType, settings, keys, "profile_for_different_interaction", "matched=" .. tostring(key) .. " type=" .. tostring(scopedOther.interactionType))
        end
        local profile = module.profilesByRecordId[key]
        if profile and profile.interactionType ~= interactionType then
            return traceSkippedProfile(obj, interactionType, settings, keys, "profile_for_different_interaction", "matched=" .. tostring(key) .. " type=" .. tostring(profile.interactionType))
        end
    end

    if interactionType == "sitting" and isFallbackAllowed(settings, interactionType) then
        local ok, statusReason, fallbackCategory = module.sittingFallbackCandidateStatus(obj, settings)
        if ok then
            local fallbackProfile
            fallbackProfile, fallbackCategory = seatingSlots.fallbackProfileForKeys(fallbackProfiles.sitting, keys, settings)
            if fallbackProfile then
                local applied = applyChairOrientationVariant(fallbackProfile, obj, keys[1])
                return traceSelectedProfile(obj, interactionType, settings, keys, keys[1], applied, "fallback_profile", "fallback_category=" .. tostring(fallbackCategory))
            end
            if fallbackCategory == "backed_chair" then
                return traceSkippedProfile(obj, interactionType, settings, keys, "fallback_backed_chair_disabled", "fallback_category=backed_chair")
            end
        elseif statusReason then
            return traceSkippedProfile(obj, interactionType, settings, keys, statusReason, "fallback_category=" .. tostring(fallbackCategory))
        end
    end

    if interactionType == "sleeping" and isFallbackAllowed(settings, interactionType) then
        local ok, sleepReason, fallbackBedType = sleepCandidateClassifier.classifyDetailed(obj, module.objectModelPath(obj))
        if ok then
            if fallbackBedType == "double" then
                return traceSkippedProfile(obj, interactionType, settings, keys, "fallback_double_bed_requires_explicit_slots", "sleep_classifier=" .. tostring(sleepReason))
            end
            if fallbackBedType == "bunk" or fallbackBedType == "top_bunk" or fallbackBedType == "bottom_bunk" then
                return traceSkippedProfile(obj, interactionType, settings, keys, "fallback_bunk_requires_explicit_top_bottom_slots", "sleep_classifier=" .. tostring(sleepReason))
            end
            local baseProfile = shallowCopy(fallbackProfiles.sleeping)
            baseProfile.bedType = fallbackBedType or baseProfile.bedType
            if fallbackBedType == "bedroll" then
                baseProfile.allowAnySleepSurfaceHit = false
                baseProfile.sleepSurfaceMinHeight = 0
                baseProfile.profileBedTypeFallbackLowConfidence = true
            end
            local profile = applySleepOrientationVariant(applyGenericBedTypeDefaults(baseProfile, settings, keys[1]), obj, keys[1])
            profile.fallbackSleepCandidateReason = sleepReason
            profile.fallbackBedType = fallbackBedType
            return traceSelectedProfile(obj, interactionType, settings, keys, keys[1], profile, "fallback_profile", "sleep_classifier=" .. tostring(sleepReason) .. " bedType=" .. tostring(fallbackBedType))
        end
        return traceSkippedProfile(obj, interactionType, settings, keys, "non_sleep_object", "sleep_classifier=" .. tostring(sleepReason))
    end


    return traceSkippedProfile(obj, interactionType, settings, keys, "no_profile")
end

function module.slotName(slot, index)
    if slot and slot.name then return slot.name end
    return "slot_" .. tostring(index or 1)
end

function module.templateStatus()
    return {
        implemented = false,
        reason = "OpenMW template-cell/token discovery APIs were not present in the existing mod and were not guessed.",
        tokenTypes = {
            "seat",
            "sleep_body",
            "approach_front",
            "approach_left",
            "approach_right",
            "facing_marker",
            "transition_start",
            "multi_slot",
        }
    }
end

return module
