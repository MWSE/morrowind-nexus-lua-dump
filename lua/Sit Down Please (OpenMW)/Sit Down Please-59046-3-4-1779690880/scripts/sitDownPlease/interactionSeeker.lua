-- interactionSeeker.lua
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local async = require('openmw.async')
local ai = require('openmw.interfaces').AI
local types = require('openmw.types')
local profiles = require('scripts/sitDownPlease/profiles/catalog')
local calibrationExport = require('scripts/sitDownPlease/calibration/exportRows')
local seatingClearance = require('scripts/sitDownPlease/seating/clearance')
local interactionAnimation = require('scripts/sitDownPlease/animation/playback')
local sleepRoutePlanner = require('scripts/sitDownPlease/sleeping/routePlanner')
local sittingPosePlanner = require('scripts/sitDownPlease/seating/posePlanner')
local sittingOffsetResolver = require('scripts/sitDownPlease/seating/offsetResolver')
local calibrationPoseState = require('scripts/sitDownPlease/calibration/poseState')
local npcCalibrationEvents = require('scripts/sitDownPlease/calibration/npcCalibrationEvents')
local externalAiTakeover = require('scripts/sitDownPlease/compatibility/externalAiTakeover')
sdpSittingFacingRefiner = require('scripts/sitDownPlease/seating/facingRefiner')
sdpSurfaceSampler = require('scripts/sitDownPlease/world/surfaceSampler')
sdpAnimatedMorrowindCompat = require('scripts/sitDownPlease/compatibility/animatedMorrowind')
sdpScriptedAnimationCompat = require('scripts/sitDownPlease/compatibility/scriptedAnimations')
sdpManualAssignment = require('scripts/sitDownPlease/assignment/manualAssignment')

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
    return require('scripts/sitDownPlease/assignment/eligibility').actorDeadReason(actor, types)
end

local BLACKLIST_IDS = profiles.npcBlacklist
local AI_POLL_INTERVAL = 0.5
local FOLLOWER_REPORT_INTERVAL = 3

local currentObject = nil
local currentProfile = nil
local currentInteractionType = nil
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
local sleepAiSuppressionDeltas = nil
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
local currentSleepProfileRootOffset = nil
local currentSleepCalibrationOffset = nil
local currentSleepMergedRootOffset = nil
local currentSleepAnimationNormalizationOffset = nil
local currentSleepCalibrationYawDegrees = 0
local currentSleepPoseYawOffset = nil
local currentSleepSurfaceMode = nil
local currentSleepSurfaceSamples = 0
local currentSleepRouteNeedsDoorAssist = false
local currentCalibrationTargetKey = nil
sdpAnimatedMorrowindCompatDialogueUntil = 0
local briefTravelDest = nil
local briefTravelStartedAt = nil
local briefTravelTimeout = 8
local briefTravelRadius = 70
local sleepDoorAssistElapsed = 0
local sleepDoorAssistRequested = {}
local sleepDoorAssistLastOpenedAt = 0
local currentInteractionTravelDest = nil
local currentInteractionTravelStartedAt = nil
local currentInteractionStartedAt = nil
local externalTravelTracker = externalAiTakeover.newTracker()
local onSitDownPleaseStartAIPackage = nil
local normalizeDirection3 = nil
local objectForwardDirection = nil
local objectRightDirection = nil
local directionDot2 = nil
local clearDistanceForDirection = nil
local allRadialDirections = nil

local function debugLog(...)
    profiles.debugLog(settings, self.object.recordId or self.object.id, ...)
end

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

local function suppressSleepingGreetingSound()
    -- Sleeping NPCs should not keep playing proximity greetings as if they were
    -- awake. OpenMW does not expose a safe generic "close eyes" or "disable
    -- hello" API here, but Dynamic Actors uses the same sound stop pattern for
    -- dialogue voice control. This only suppresses active voice lines while the
    -- actor is in the sleep interaction; it does not alter the NPC's record AI.
    if currentInteractionType ~= "sleeping" then return end
    if not (core and core.sound and core.sound.isSayActive and core.sound.stopSay) then return end
    local ok, active = pcall(core.sound.isSayActive, self)
    if ok and active then
        pcall(core.sound.stopSay, self)
        debugLog("sleep suppress greeting sound")
    end
end



local function aiStatValue(stat)
    if not stat then return nil end
    local value = tonumber(stat.modified or stat.base or 0)
    if value == nil then value = tonumber(stat.base or 0) end
    return value or 0
end

local function applySleepHelloSuppression()
    -- Sleeping NPCs should be much less capable of noticing/greeting/reacting to
    -- the player than awake NPCs. Stop active greetings, and temporarily lower
    -- relevant AI stats while the actor is assigned to/sustaining sleep. These
    -- modifiers are restored when the sleep interaction ends. This is deliberately
    -- local and reversible; it is not a permanent NPC record edit and it still
    -- allows explicit wake rules such as player activation, hits, combat, and
    -- close-player disturbance.
    if currentInteractionType ~= "sleeping" or not (isInteracting or interactionAssigned) then return end
    if sleepAiSuppressionDeltas then return end
    if not (types and types.Actor and types.Actor.stats and types.Actor.stats.ai) then return end

    local aiStats = types.Actor.stats.ai
    local statNames = { "hello", "fight", "alarm" }
    local penalty = 10000
    sleepAiSuppressionDeltas = {}

    for _, statName in ipairs(statNames) do
        local getter = aiStats[statName]
        if getter then
            local ok, stat = pcall(getter, self)
            if ok and stat then
                local current = aiStatValue(stat)
                local delta = -(math.max(penalty, current + penalty))
                local okSet = pcall(function()
                    stat.modifier = (tonumber(stat.modifier) or 0) + delta
                end)
                if okSet then
                    sleepAiSuppressionDeltas[statName] = delta
                end
            end
        end
    end

    local count = 0
    for _ in pairs(sleepAiSuppressionDeltas) do count = count + 1 end
    if count == 0 then
        sleepAiSuppressionDeltas = nil
        debugLog("sleep suppress ai stats failed")
    else
        debugLog("sleep suppress ai stats", "count", tostring(count), "penalty", tostring(penalty))
    end
end

local function clearSleepHelloSuppression(reason)
    if not sleepAiSuppressionDeltas then return end
    if not (types and types.Actor and types.Actor.stats and types.Actor.stats.ai) then
        sleepAiSuppressionDeltas = nil
        return
    end

    local aiStats = types.Actor.stats.ai
    local restored = 0
    for statName, delta in pairs(sleepAiSuppressionDeltas) do
        local getter = aiStats[statName]
        if getter then
            local ok, stat = pcall(getter, self)
            if ok and stat then
                local okSet = pcall(function()
                    stat.modifier = (tonumber(stat.modifier) or 0) - delta
                end)
                if okSet then restored = restored + 1 end
            end
        end
    end
    sleepAiSuppressionDeltas = nil
    debugLog("sleep restore ai stats", "restored", tostring(restored), "reason", tostring(reason or "clear"))
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

local function isFactionLeader(actor)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end
    if not (types.NPC.getFactions and types.NPC.getFactionRank) then return false end
    if not (core.factions and core.factions.records) then return false end

    local factionIds = types.NPC.getFactions(actor)
    if not factionIds then return false end

    for _, factionId in ipairs(factionIds) do
        local factionRec = core.factions.records[factionId] or core.factions.records[string.lower(factionId)]
        if factionRec and factionRec.ranks then
            local maxRank = #factionRec.ranks
            local ok, rank = pcall(types.NPC.getFactionRank, actor, factionId)
            if ok and rank == maxRank and rank > 0 then
                return true
            end
        end
    end

    return false
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

local function vectorFromOffset(offset)
    if not offset then return util.vector3(0, 0, 0) end
    return util.vector3(offset.x or 0, offset.y or 0, offset.z or 0)
end

local function objectLocalOffset(obj, offset)
    if not obj or not offset then return obj and obj.position or nil end
    local scale = tonumber(obj.scale) or 1
    if scale <= 0 then scale = 1 end
    return obj.position + obj.rotation * util.vector3((offset.x or 0) * scale, (offset.y or 0) * scale, (offset.z or 0) * scale)
end

local function objectLocalHorizontalOffset(obj, offset)
    if not obj or not offset then return util.vector3(0, 0, 0) end
    local scale = tonumber(obj.scale) or 1
    if scale <= 0 then scale = 1 end
    return obj.rotation * util.vector3((offset.x or 0) * scale, (offset.y or 0) * scale, 0)
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
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
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
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        debugLog = debugLog,
    }
end

sampleSittingSurface = function(obj, profile)
    return sdpSurfaceSampler.sampleSittingSurface(surfaceSamplerContext(), obj, profile)
end

function averageTopSurfaceHits(hits, tolerance)
    return sdpSurfaceSampler.averageTopSurfaceHits(surfaceSamplerContext(), hits, tolerance)
end

sdpSeatObjectEnabled = function(obj)
    if not obj then return false end
    local ok, enabled = pcall(function() return obj.enabled end)
    if ok and enabled == false then return false end
    return true
end

sdpItemLooksLikeSeatClutter = function(item)
    local recordId = item and item.recordId or ""
    local model = profiles.objectModelPath(item) or ""
    local name = ""
    local ok, rec = pcall(function()
        if item and item.type and item.type.record then return item.type.record(item) end
        return nil
    end)
    if ok and rec and rec.name then name = rec.name end
    local text = (tostring(recordId) .. " " .. tostring(model) .. " " .. tostring(name)):lower()
    return text:find("book", 1, true) ~= nil
        or text:find("text_", 1, true) ~= nil
        or text:find("paper", 1, true) ~= nil
        or text:find("parchment", 1, true) ~= nil
        or text:find("scroll", 1, true) ~= nil
        or text:find("note", 1, true) ~= nil
        or text:find("letter", 1, true) ~= nil
end

sdpSeatClutterLists = function()
    local lists = {}
    if not nearby then return lists end
    if nearby.items then lists[#lists + 1] = nearby.items end
    if nearby.activators then lists[#lists + 1] = nearby.activators end
    return lists
end

sdpSeatLocalClutterHit = function(item, sitPosition, profile)
    if not (item and item.position and sitPosition) then return false, nil, nil, nil end
    local category = sittingSeatCategory(profile, currentObject)
    local dx = (item.position.x or 0) - (sitPosition.x or 0)
    local dy = (item.position.y or 0) - (sitPosition.y or 0)
    local dz = (item.position.z or 0) - (sitPosition.z or 0)
    local flatToSeat = math.sqrt(dx * dx + dy * dy)
    local radius = category == "bench" and 34 or (category == "stool" and 36 or 42)
    if flatToSeat <= radius and dz >= -18 and dz <= 50 then
        return true, flatToSeat, dz, "seat_position"
    end

    if category ~= "backed_chair" or not (currentObject and currentObject.position) then
        return false, flatToSeat, dz, nil
    end

    local odx = (item.position.x or 0) - (currentObject.position.x or 0)
    local ody = (item.position.y or 0) - (currentObject.position.y or 0)
    local odz = (item.position.z or 0) - (currentObject.position.z or 0)
    local forward = objectForwardDirection and objectForwardDirection(currentObject) or nil
    local right = objectRightDirection and objectRightDirection(currentObject) or nil
    if not (forward and right) then return false, flatToSeat, dz, nil end

    local localForward = odx * (forward.x or 0) + ody * (forward.y or 0)
    local localRight = odx * (right.x or 0) + ody * (right.y or 0)
    local onChairPan = math.abs(localRight) <= 48 and math.abs(localForward) <= 64
    local nearSeatHeight = dz >= -42 and dz <= 50
    local nearObjectSeatHeight = odz >= -18 and odz <= 70
    if onChairPan and nearSeatHeight and nearObjectSeatHeight then
        return true, flatToSeat, dz, "chair_local_surface"
    end

    return false, flatToSeat, dz, nil
end

sdpSeatSurfaceClutterBlocker = function(sitPosition, profile)
    if not sitPosition then return nil end
    for _, list in ipairs(sdpSeatClutterLists()) do
        for _, item in ipairs(list) do
            if sdpSeatObjectEnabled(item) and sdpItemLooksLikeSeatClutter(item) and item.position then
                local hit, flat, dz, reason = sdpSeatLocalClutterHit(item, sitPosition, profile)
                if hit then
                    return item, flat, dz, reason
                end
            end
        end
    end
    return nil
end

local function averageSurfaceBandHits(hits, obj, profile)
    if not hits or #hits == 0 or not obj or not obj.position then return nil, 0 end

    local minHeight = profile and profile.sleepSurfaceMinHeight or 25
    local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
    local minZ = obj.position.z + minHeight
    local maxZ = obj.position.z + maxHeight

    local sum = util.vector3(0, 0, 0)
    local count = 0
    for _, hitPos in ipairs(hits) do
        if hitPos and hitPos.z >= minZ and hitPos.z <= maxZ then
            sum = sum + hitPos
            count = count + 1
        end
    end

    if count == 0 then return nil, 0 end
    return sum / count, count
end

local function surfaceEntriesInBand(entries, obj, profile)
    if not entries or #entries == 0 or not obj or not obj.position then return {} end

    local minHeight = profile and profile.sleepSurfaceMinHeight or 25
    local maxHeight = profile and profile.sleepSurfaceMaxHeight or 260
    local minZ = obj.position.z + minHeight
    local maxZ = obj.position.z + maxHeight

    local filtered = {}
    for _, entry in ipairs(entries) do
        local hitPos = entry and entry.hitPos
        if hitPos and hitPos.z >= minZ and hitPos.z <= maxZ then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

local function centerFromSampleOffsetExtents(entries, obj)
    if not entries or #entries == 0 or not obj then return nil, 0, nil end

    local minX, maxX, minY, maxY, zSum, count = nil, nil, nil, nil, 0, 0
    for _, entry in ipairs(entries) do
        local offset = entry.offset or {}
        local hitPos = entry.hitPos
        local x = offset.x or 0
        local y = offset.y or 0
        if not minX or x < minX then minX = x end
        if not maxX or x > maxX then maxX = x end
        if not minY or y < minY then minY = y end
        if not maxY or y > maxY then maxY = y end
        if hitPos then
            zSum = zSum + hitPos.z
            count = count + 1
        end
    end

    if count == 0 or not minX or not maxX or not minY or not maxY then return nil, 0, nil end

    local centerOffset = { x = (minX + maxX) / 2, y = (minY + maxY) / 2, z = 0 }
    local center = objectLocalOffset(obj, centerOffset)
    if center then
        center = util.vector3(center.x, center.y, zSum / count)
    end
    return center, count, centerOffset
end

local lastSleepSurfaceCenterOffset = nil

local function sampledObjectTopCenter(obj, profile)
    lastSleepSurfaceCenterOffset = nil
    if not obj then return nil, 0, "missing_object" end

    local offsets = profile and profile.sleepSurfaceSampleOffsets or nil
    if not offsets then
        return objectTopPosition(obj), 1, "object_center"
    end

    local objectHits = {}
    local anyHits = {}
    local objectEntries = {}
    local anyEntries = {}
    for _, offset in ipairs(offsets) do
        local base = objectLocalOffset(obj, offset)
        if base then
            local from = base + util.vector3(0, 0, 260)
            local to = base - util.vector3(0, 0, 160)
            local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
            if result.hit and result.hitPos then
                local entry = { offset = offset, hitPos = result.hitPos, hitObject = result.hitObject }
                table.insert(anyHits, result.hitPos)
                table.insert(anyEntries, entry)
                if rayHitBelongsToObject(result.hitObject, obj) then
                    table.insert(objectHits, result.hitPos)
                    table.insert(objectEntries, entry)
                end
            end
        end
    end

    local tolerance = profile and profile.sleepSurfaceTopTolerance or 18

    if profile and profile.sleepSurfaceCenterMode == "object_origin_xy" then
        local entries = surfaceEntriesInBand(objectEntries, obj, profile)
        if #entries == 0 and profile.allowAnySleepSurfaceHit ~= false then
            entries = surfaceEntriesInBand(anyEntries, obj, profile)
        end
        if #entries > 0 then
            local zSum = 0
            for _, entry in ipairs(entries) do zSum = zSum + (entry.hitPos.z or 0) end
            lastSleepSurfaceCenterOffset = { x = 0, y = 0, z = 0 }
            return util.vector3(obj.position.x, obj.position.y, zSum / #entries), #entries, "object_origin_xy"
        end
        local top = objectTopPosition(obj)
        if top then
            lastSleepSurfaceCenterOffset = { x = 0, y = 0, z = 0 }
            return util.vector3(obj.position.x, obj.position.y, top.z), 1, "object_origin_xy_top"
        end
    end

    -- Best mode for beds: use the extents of the sampled surface hits in object-local
    -- offset space, then put the root at that detected mattress/bed-surface center.
    -- This avoids the failed scalar "inward" shoves that moved actors along the wrong
    -- axis for rotated or origin-weird beds.
    if profile and profile.sleepSurfaceCenterMode == "sample_extents" then
        local entries = surfaceEntriesInBand(objectEntries, obj, profile)
        local center, count, centerOffset = centerFromSampleOffsetExtents(entries, obj)
        if center then
            lastSleepSurfaceCenterOffset = centerOffset
            return center, count, "object_sample_extents"
        end

        if profile.allowAnySleepSurfaceHit ~= false then
            entries = surfaceEntriesInBand(anyEntries, obj, profile)
            center, count, centerOffset = centerFromSampleOffsetExtents(entries, obj)
            if center then
                lastSleepSurfaceCenterOffset = centerOffset
                return center, count, "any_sample_extents"
            end
        end
    end

    local center, count = averageSurfaceBandHits(objectHits, obj, profile)
    if center then return center, count, "object_surface_band" end

    if not profile or profile.allowAnySleepSurfaceHit ~= false then
        center, count = averageSurfaceBandHits(anyHits, obj, profile)
        if center then return center, count, "surface_band_any_hit" end
    end

    center, count = averageTopSurfaceHits(objectHits, tolerance)
    if center then return center, count, "object_hits_top" end

    if not profile or profile.allowAnySleepSurfaceHit ~= false then
        center, count = averageTopSurfaceHits(anyHits, tolerance)
        if center then return center, count, "top_any_hit" end
    end

    return objectTopPosition(obj), 0, "object_origin_fallback"
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
    local recordId = actor and actor.recordId and string.lower(tostring(actor.recordId)) or ""
    if recordId:find("^am_") then return "external_animation_npc" end
    return nil
end

local function actorLooksLikeVampire(actor, rec)
    local recordId = actor and actor.recordId and string.lower(tostring(actor.recordId)) or ""
    local cls = rec and rec.class and string.lower(tostring(rec.class)) or ""
    local name = rec and rec.name and string.lower(tostring(rec.name)) or ""
    if recordId:find("vampire", 1, true) or cls:find("vampire", 1, true) or name:find("vampire", 1, true) then
        return true
    end

    local okEffects, hasEffect = pcall(function()
        if not (types and types.Actor and types.Actor.activeEffects and actor) then return false end
        local effects = types.Actor.activeEffects(actor)
        if not effects or not effects.getEffect then return false end
        local vamp = effects:getEffect("vampirism")
        return vamp ~= nil and (tonumber(vamp.magnitude or 0) or 0) > 0
    end)
    return okEffects and hasEffect == true
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
    if not (data and data.manualAssignOverrideTesting == true) then return false end
    reason = tostring(reason or "")
    local canBypass = reason == "barter_service_npc"
        or reason == "travel_service_npc"
        or reason == "training_service_npc"
        or reason == "service_npc"
        or reason == "guard_or_publican_class"
        or reason == "publican_class"
        or reason == "travel_destination_npc"
        or reason == "faction_leader"
        or reason == "important_npc"
        or reason == "quest_npc"
        or reason == "outside_allowed_time_window"
        or reason == "sleep_before_actor_bedtime"
        or reason == "sleep_after_actor_wake_time"
    if canBypass then noteManualAssignOverride(data, reason) end
    return canBypass
end

local function isBlacklistedForInteraction(actor, interactionType, data)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end

    local dead, deadReason = actorDeadReason(actor)
    if dead then return true, deadReason end

    local actorId = actor.recordId and string.lower(actor.recordId) or nil
    if actorId and BLACKLIST_IDS[actorId] then return true, "blacklisted_npc" end

    local incapacitationReason = externalAiTakeover.externalIncapacitationReason(actor, types)
    if incapacitationReason then return true, incapacitationReason end

    local controlScriptReason = externalAiTakeover.externalControlScriptReason(actor)
    if controlScriptReason then return true, controlScriptReason end

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

    if actorLooksLikeVampire(actor, rec) then
        return true, "vampire"
    end

    local cls = rec.class and string.lower(tostring(rec.class)) or ""
    if cls == "guard" or cls == "publican" then
        local reason = "guard_or_publican_class"
        if manualAssignCanBypassLocalBlock(reason, data) then
            debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_npc_class")
        else
            return true, reason
        end
    end

    local services = rec.servicesOffered
    if interactionType == "sleeping" then
        -- Sleep is bed-gated and time-gated. Do not reject trainers, merchants,
        -- faction leaders, or travel-service NPCs just because they offer services.
        -- The intended hard sleep exclusions are followers/escorts, vampires,
        -- guards, publicans, combat/danger, and explicit profile blacklists.
        return false, nil
    end

    if services then
        if interactionType == "sitting" then
            if services.Barter == true then
                local reason = "barter_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
            if services.Travel == true and settings.sittingAllowServiceNpcs ~= true then
                local reason = "travel_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
            if services.Training == true and settings.sittingAllowServiceNpcs ~= true then
                local reason = "training_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
        else
            if services.Travel == true then
                local reason = "travel_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
            if services.Barter == true then
                local reason = "barter_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
            if services.Training == true then
                local reason = "training_service_npc"
                if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
            end
        end
    end

    if rec.travelDestinations and #rec.travelDestinations > 0 and not (interactionType == "sitting" and settings.sittingAllowServiceNpcs == true) then
        local reason = "travel_destination_npc"
        if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
    end

    if isFactionLeader(actor) and not (interactionType == "sitting" and settings.sittingAllowServiceNpcs == true) then
        local reason = "faction_leader"
        if manualAssignCanBypassLocalBlock(reason, data) then debugLog("nearest_manual_assign_override", "reason", reason, "bypass", "local_service_npc") else return true, reason end
    end

    return false, nil
end

local function vectorLength2d(v)
    if not v then return 0 end
    return math.sqrt((v.x or 0) * (v.x or 0) + (v.y or 0) * (v.y or 0))
end

local function distanceToSegment2d(p, a, b)
    if not (p and a and b) then return nil, nil end
    local ax, ay = a.x or 0, a.y or 0
    local bx, by = b.x or 0, b.y or 0
    local px, py = p.x or 0, p.y or 0
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 <= 1 then
        return math.sqrt((px - ax) ^ 2 + (py - ay) ^ 2), 0
    end
    local t = ((px - ax) * dx + (py - ay) * dy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local cx, cy = ax + t * dx, ay + t * dy
    return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2), t
end

local function doorIsNonTeleportInstance(door)
    if not (door and types and types.Door and types.Door.objectIsInstance) then return false end
    local okInstance, isDoor = pcall(types.Door.objectIsInstance, door)
    if not (okInstance and isDoor == true) then return false end
    local okTeleport, isTeleport = pcall(types.Door.isTeleport, door)
    if okTeleport and isTeleport == true then return false end
    return true
end

local function lockableApi()
    return (types and types.Door and types.Door.baseType) or (types and (types.Lockable or types.LOCKABLE))
end

local function doorIsLocked(door)
    local lockable = lockableApi()
    if lockable and lockable.isLocked then
        local okLocked, locked = pcall(lockable.isLocked, door)
        if okLocked then return locked == true end
    end
    return true
end

local function actorHasDoorKey(actor, door)
    if not (actor and door) then return false, nil, "missing_actor_or_door" end
    local lockable = lockableApi()
    if not (lockable and lockable.getKeyRecord) then return false, nil, "key_api_unavailable" end

    local okKey, keyRecord = pcall(lockable.getKeyRecord, door)
    if not (okKey and keyRecord) then return false, nil, "unknown_key" end
    local keyId = keyRecord.id or keyRecord.recordId or tostring(keyRecord)
    if not keyId or keyId == "" then return false, nil, "unknown_key" end

    local okInv, inventory = pcall(function()
        if types and types.Actor and types.Actor.inventory then return types.Actor.inventory(actor) end
        return actor:inventory()
    end)
    if not (okInv and inventory) then return false, keyId, "inventory_unavailable" end
    if inventory.countOf then
        local okCount, count = pcall(inventory.countOf, inventory, keyId)
        if okCount then return (tonumber(count) or 0) > 0, keyId, "countOf" end
    end
    if inventory.find then
        local okFind, found = pcall(inventory.find, inventory, keyId)
        return okFind and found ~= nil, keyId, "find"
    end
    return false, keyId, "inventory_key_lookup_unavailable"
end

local function routeDoorIsClosedNonTeleport(door)
    if not doorIsNonTeleportInstance(door) then return false end
    local okClosed, closed = pcall(types.Door.isClosed, door)
    return okClosed and closed == true
end

local function routeDoorOpenability(door, actor)
    if not routeDoorIsClosedNonTeleport(door) then return false, "not_closed_route_door" end
    if not doorIsLocked(door) then return true, "unlocked" end
    local hasKey, keyId, keyReason = actorHasDoorKey(actor or self.object, door)
    if keyReason == "unknown_key" or keyReason == "key_api_unavailable" then
        debugLog("locked route door check", "door", tostring(door and (door.recordId or door.id)), "locked", "true", "key", tostring(keyId), "reason", "locked_route_door_unknown_key")
        return false, "locked_route_door_unknown_key"
    end
    if hasKey then
        debugLog("locked route door check", "door", tostring(door and (door.recordId or door.id)), "locked", "true", "key", tostring(keyId), "reason", "locked_route_door_actor_has_key")
        return true, "locked_route_door_actor_has_key"
    end
    debugLog("locked route door check", "door", tostring(door and (door.recordId or door.id)), "locked", "true", "key", tostring(keyId), "reason", "locked_route_door_missing_key")
    return false, "locked_route_door_missing_key"
end

local function routeDoorIsClosedUnlockedNonTeleport(door)
    local ok = routeDoorOpenability(door, self.object)
    return ok == true
end

local function routeDoorIsOpenNonTeleport(door)
    if not doorIsNonTeleportInstance(door) then return false end
    local okOpen, isOpen = pcall(types.Door.isOpen, door)
    return okOpen and isOpen == true
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

local function navPathLength(path)
    if not path or #path == 0 then return nil end
    local total = 0
    for i = 1, #path - 1 do
        total = total + (path[i + 1] - path[i]):length()
    end
    return total
end

local function routeProbablyNeedsDoor(dest)
    if currentSleepRouteNeedsDoorAssist == true then return true end
    if not (nearby and nearby.NAVIGATOR_FLAGS and nearby.findPath and dest) then return false end
    local flags = nearby.NAVIGATOR_FLAGS
    local walk = flags.Walk
    local openDoor = flags.OpenDoor
    if not (walk and openDoor) then return false end
    local baseFlags = walk + (flags.UsePathgrid or 0)
    local closedStatus = pathStatusWithFlags(dest, baseFlags)
    local openStatus = pathStatusWithFlags(dest, baseFlags + openDoor)
    if pathStatusIsSuccess(openStatus) and not pathStatusIsSuccess(closedStatus) then return true end
    return false
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
        return nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
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
    if not (pos and finalPos) then return false end

    -- The approach point can be path-reachable while the actual bed root is still
    -- behind a door, wall, or room boundary. Patch 30/35 used a single low ray
    -- from the bed edge to the final prone root; legitimate beds often blocked
    -- that ray with their own collision, causing valid profiled beds to reject.
    -- Use two higher rays instead. A real wall/door should block both; ordinary
    -- bed geometry should usually not.
    local lowClearance = pos + util.vector3(0, 0, 120)
    local lowTarget = finalPos + util.vector3(0, 0, 120)
    local highClearance = pos + util.vector3(0, 0, 170)
    local highTarget = finalPos + util.vector3(0, 0, 170)
    return rayBlockedBetween(lowClearance, lowTarget, 42) and rayBlockedBetween(highClearance, highTarget, 42)
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
                ignore = lastDoor,
            })
        end)
        local door = ok and result and result.hitObject or nil
        if door and routeDoorIsClosedNonTeleport(door) then
            local canOpen, openReason = routeDoorOpenability(door, self.object)
            if canOpen or includeBlockedDoor == true then
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
        if chosenPathLength and actorLineBlocked then
            local straightDistance = (navPos - self.object.position):length()
            local maxIndirectRoute = math.max(750, (straightDistance * 3.0) + 240)
            if chosenPathLength > maxIndirectRoute then
                if settings.debug == true then
                    debugLog(
                        logPrefix or "sleep_entry_rejected",
                        "reason", "route_too_indirect",
                        "object", tostring(currentObject and currentObject.recordId),
                        "approach", tostring(pos),
                        "navApproach", tostring(navPos),
                        "pathLength", tostring(chosenPathLength),
                        "straightDistance", tostring(straightDistance)
                    )
                end
                return false, "route_too_indirect", { closedStatus = closedStatus, openStatus = openStatus, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength, actorLineBlocked = actorLineBlocked }
            end
        end

        if sleepApproachToFinalBlocked(navPos, finalPos) then
            if settings.debug == true then
                debugLog(
                    logPrefix or "sleep_entry_rejected",
                    "reason", "blocked_by_wall",
                    "object", tostring(currentObject and currentObject.recordId),
                    "approach", tostring(pos),
                    "navApproach", tostring(navPos),
                    "closedStatus", pathStatusLabel(closedStatus),
                    "openStatus", pathStatusLabel(openStatus),
                    "finalBlocked", "true"
                )
            end
            return false, "blocked_by_wall", { closedStatus = closedStatus, openStatus = openStatus, finalBlocked = true, navPos = navPos, navReason = navReason, navDelta = navDelta, pathLength = chosenPathLength }
        end

        local needsDoorAssist = openOk and not closedOk
        local routeDoor, routeWaypoint, routeDoorCanOpen, routeDoorReason = nil, nil, nil, nil
        if needsDoorAssist then
            routeDoor, routeWaypoint, routeDoorCanOpen, routeDoorReason = firstClosedRouteDoorOnPath(navPos, true)

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
                local reason = tostring(routeDoorReason or ""):find("locked_route_door", 1, true) and "locked_route_door" or "blocked_route_door"
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
    if pathStatusIsSuccess(closedStatus) or not pathStatusIsSuccess(openStatus) then return nil end

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

local function maybeAssistSleepRouteDoor(dt)
    if settings.sleepSmartDoorAssist == false then return end
    if currentInteractionType ~= "sleeping" or not interactionAssigned or isInteracting then return end
    if not targetPos then return end
    if not (nearby and nearby.doors and core and core.sendGlobalEvent) then return end

    sleepDoorAssistElapsed = sleepDoorAssistElapsed + (dt or 0)
    if sleepDoorAssistElapsed < 0.45 then return end
    sleepDoorAssistElapsed = 0

    local actorPos = self.object.position
    local toTarget = targetPos - actorPos
    if vectorLength2d(toTarget) < 80 then return end

    local routeNeedsDoor = routeProbablyNeedsDoor(targetPos)
    if not routeNeedsDoor then
        -- Open doors can still leave collision in the route. Do not toggle them;
        -- add a one-shot waypoint just beyond the doorway and let the existing
        -- approach monitoring resume from there.
        local openDoor, openWaypoint, openScore = nil, nil, nil
        for _, door in ipairs(nearby.doors) do
            if routeDoorIsOpenNonTeleport(door) then
                local doorKey = "open:" .. tostring(door.id or door.recordId or door)
                if not sleepDoorAssistRequested[doorKey] then
                    local actorDist = (door.position - actorPos):length()
                    local targetDist = (door.position - targetPos):length()
                    local lineDist, t = distanceToSegment2d(door.position, actorPos, targetPos)
                    local vertical = math.abs((door.position.z or 0) - (actorPos.z or 0))
                    if actorDist <= 240 and targetDist <= math.max(260, vectorLength2d(toTarget) + 160) and lineDist and lineDist <= 115 and t and t > 0.03 and t < 0.97 and vertical <= 180 then
                        local score = actorDist + lineDist * 1.5
                        if not openScore or score < openScore then
                            local dir = normalizeDirection3(targetPos - actorPos)
                            openDoor, openScore = door, score
                            openWaypoint = dir and (door.position + dir * 150) or nil
                        end
                    end
                end
            end
        end
        if openDoor and openWaypoint then
            local doorKey = "open:" .. tostring(openDoor.id or openDoor.recordId or openDoor)
            sleepDoorAssistRequested[doorKey] = true
            debugLog("door_already_open", tostring(openDoor.recordId or openDoor.id), "actor", tostring(self.object and (self.object.recordId or self.object.id)))
            debugLog("door_collision_suspected", tostring(openDoor.recordId or openDoor.id), "actorDistance", tostring((openDoor.position - actorPos):length()), "target", tostring(targetPos))
            debugLog("post_door_waypoint_chosen", tostring(openDoor.recordId or openDoor.id), tostring(openWaypoint))
            core.sendGlobalEvent('SitDownPleaseOpenSleepRouteDoor', {
                npc = self.object,
                door = openDoor,
                reason = "already_open_collision_suspected",
                postDoorWaypoint = openWaypoint,
            })
            onSitDownPleaseStartAIPackage({
                type = "Travel",
                destPosition = openWaypoint,
                isRepeat = false,
                cancelOther = true,
                destinationTolerance = 90,
            })
            debugLog("door_route_retry", tostring(openDoor.recordId or openDoor.id), "stage", "open_door_waypoint", "target", tostring(openWaypoint))
        end
        return
    end

    local bestDoor, bestScore, bestWaypoint = nil, nil, nil
    local pathDoor, pathWaypoint = firstClosedRouteDoorOnPath(targetPos)
    if pathDoor then
        local doorKey = tostring(pathDoor.id or pathDoor.recordId or pathDoor)
        local actorDist = (pathDoor.position - actorPos):length()
        local targetDist = (pathDoor.position - targetPos):length()
        if not sleepDoorAssistRequested[doorKey] and actorDist <= 340 and targetDist <= math.max(260, vectorLength2d(toTarget) + 180) then
            bestDoor = pathDoor
            bestScore = actorDist
            bestWaypoint = pathWaypoint
        end
    end

    for _, door in ipairs(nearby.doors) do
        if not bestDoor and routeDoorIsClosedUnlockedNonTeleport(door) then
            local doorKey = tostring(door.id or door.recordId or door)
            if not sleepDoorAssistRequested[doorKey] then
                local actorDist = (door.position - actorPos):length()
                local targetDist = (door.position - targetPos):length()
                local lineDist, t = distanceToSegment2d(door.position, actorPos, targetPos)
                local vertical = math.abs((door.position.z or 0) - (actorPos.z or 0))
                if actorDist <= 260 and targetDist <= math.max(260, vectorLength2d(toTarget) + 160) and lineDist and lineDist <= 140 and t and t > 0.03 and t < 0.97 and vertical <= 180 then
                    local score = actorDist + lineDist * 1.5 + math.abs(t - 0.35) * 80
                    if not bestScore or score < bestScore then
                        bestDoor, bestScore = door, score
                        local dir = normalizeDirection3(targetPos - actorPos)
                        bestWaypoint = dir and (door.position + dir * 150) or nil
                    end
                end
            end
        end
    end

    if bestDoor then
        local doorKey = tostring(bestDoor.id or bestDoor.recordId or bestDoor)
        sleepDoorAssistRequested[doorKey] = true
        sleepDoorAssistLastOpenedAt = core.getSimulationTime() or 0
        core.sendGlobalEvent('SitDownPleaseOpenSleepRouteDoor', {
            npc = self.object,
            door = bestDoor,
            reason = "sleep_route_assist",
            postDoorWaypoint = bestWaypoint,
        })
        debugLog("route_door_assist", "requested", tostring(bestDoor.recordId or bestDoor.id), "postDoorWaypoint", tostring(bestWaypoint))
    end
end

local function stopCurrentAnim()
    clearSleepHelloSuppression("stop_current_anim")
    if currentInteractionType == "sleeping" and currentAnimationQueued and anim and anim.clearAnimationQueue then
        pcall(anim.clearAnimationQueue, self, true)
        debugLog("sleep animation queue cleared", "reason", "stop_current_anim", "clearScripted", "true")
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
        if currentInteractionType == "sleeping" then
            if not destPosition or not pkg.destPosition then return false end
            return (pkg.destPosition - destPosition):length() > radius
        end

        if destPosition and pkg.destPosition and (pkg.destPosition - destPosition):length() < radius then
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

local function requestStand(reason)
    if standRequested then return end
    standRequested = true

    stopCurrentAnim()
    isInteracting = false
    interactionAssigned = false
    currentInteractionTravelDest = nil
    currentInteractionTravelStartedAt = nil
    currentInteractionStartedAt = nil
    currentInteractionInitialPlacement = false
    externalTravelTracker:reset()

    clearInteractionTravelPackage(reason)

    core.sendGlobalEvent('CancelInteractionForNpc', {
        npc = self.object,
        npcId = self.object and self.object.id,
        recordId = self.object and self.object.recordId,
        reason = reason,
        interactionType = currentInteractionType,
        slotKey = currentSlotKey,
    })
end

legacyBenchAxisProbe = function(bench)
    local center = bench.position
    local xHits, yHits = 0, 0
    local xLength, yLength = 0, 0
    if not center then return { xHits = 0, yHits = 0, xLength = 0, yLength = 0 } end
    for i = -5, 5 do
        local xResult = nearby.castRay(center + util.vector3(i * 10, 0, 100), center + util.vector3(i * 10, 0, 0), { collisionType = nearby.COLLISION_TYPE.World })
        if xResult.hit and rayHitBelongsToObject(xResult.hitObject, bench) then
            xHits = xHits + 1
            xLength = xLength + 10
        end
        local yResult = nearby.castRay(center + util.vector3(0, i * 10, 100), center + util.vector3(0, i * 10, 0), { collisionType = nearby.COLLISION_TYPE.World })
        if yResult.hit and rayHitBelongsToObject(yResult.hitObject, bench) then
            yHits = yHits + 1
            yLength = yLength + 10
        end
    end
    return { xHits = xHits, yHits = yHits, xLength = xLength, yLength = yLength, axis = xHits > yHits and "world_x" or "world_y" }
end

benchAxisExtents = function(bench, axis, label)
    local center = bench and bench.position
    if not (center and axis) then return { length = 0, hits = 0, min = 0, max = 0, zLevel = center and center.z or 0, label = label } end
    local minT, maxT, hits = nil, nil, 0
    local zLevel = center.z
    for i = -16, 16 do
        local t = i * 20
        local p = center + axis * t
        local result = nearby.castRay(p + util.vector3(0, 0, 140), p - util.vector3(0, 0, 80), { collisionType = nearby.COLLISION_TYPE.World })
        if result.hit and result.hitPos and rayHitBelongsToObject(result.hitObject, bench) then
            hits = hits + 1
            minT = minT and math.min(minT, t) or t
            maxT = maxT and math.max(maxT, t) or t
            zLevel = result.hitPos.z
        end
    end
    local length = (minT ~= nil and maxT ~= nil) and math.max(20, maxT - minT + 20) or 0
    return { length = length, hits = hits, min = minT or 0, max = maxT or 0, zLevel = zLevel, label = label }
end

determineBenchOrientationAndLength = function(bench)
    local forward = objectForwardDirection(bench)
    local right = objectRightDirection(bench)
    local legacy = legacyBenchAxisProbe(bench)
    local fExt = benchAxisExtents(bench, forward, "object_forward")
    local rExt = benchAxisExtents(bench, right, "object_right")
    local selected = (fExt.length >= rExt.length) and fExt or rExt
    local longAxis = (selected == fExt) and forward or right
    local crossAxis = (selected == fExt) and right or forward
    local length = selected.length
    if length <= 0 then
        length = math.max(160, math.max(legacy.xLength or 0, legacy.yLength or 0))
    end
    debugLog(
        "bench basis comparison current_vs_legacy",
        "object", tostring(bench and bench.recordId),
        "legacyAxis", tostring(legacy.axis),
        "legacyX", tostring(legacy.xLength),
        "legacyY", tostring(legacy.yLength),
        "objectForwardLength", tostring(fExt.length),
        "objectRightLength", tostring(rExt.length)
    )
    debugLog("bench extents raw", "object", tostring(bench and bench.recordId), "forwardHits", tostring(fExt.hits), "forwardMinMax", tostring(fExt.min) .. ":" .. tostring(fExt.max), "rightHits", tostring(rExt.hits), "rightMinMax", tostring(rExt.min) .. ":" .. tostring(rExt.max))
    debugLog("bench long axis selected", "object", tostring(bench and bench.recordId), "axis", tostring(selected.label), "length", tostring(length))
    return {
        longAxis = longAxis,
        crossAxis = crossAxis,
        label = selected.label,
        legacy = legacy,
        min = selected.min,
        max = selected.max,
        hits = selected.hits,
    }, length, selected.zLevel or (bench.position and bench.position.z or 0)
end

getBenchSittingPositions = function(bench, orientation, length, zLevel, profile)
    local center = bench.position
    local positions = {}
    local profileSlots = profile and profile.slots or nil
    local desiredSlots = math.max(1, #(profileSlots or {}))
    local longAxis = orientation and orientation.longAxis or objectRightDirection(bench)
    local minT = orientation and tonumber(orientation.min) or nil
    local maxT = orientation and tonumber(orientation.max) or nil
    local hasMeasuredSpan = (orientation and tonumber(orientation.hits) or 0) > 0 and minT ~= nil and maxT ~= nil and maxT > minT
    local measuredLength = tonumber(length) or 0
    local slotCount = math.min(math.max(1, desiredSlots), 3)
    if hasMeasuredSpan then
        if measuredLength < 96 then
            slotCount = 1
        elseif measuredLength < 156 then
            slotCount = math.min(slotCount, 2)
        end
    end
    if orientation then
        orientation.singleSeatBench = slotCount == 1
    end
    local usableLength = math.max(measuredLength, slotCount >= 2 and 160 or 80)
    if not hasMeasuredSpan then
        minT = -usableLength / 2
        maxT = usableLength / 2
    end
    usableLength = math.max(20, maxT - minT)

    if slotCount == 1 then
        local t = (minT + maxT) / 2
        local pos = center + longAxis * t
        positions[1] = util.vector3(pos.x, pos.y, zLevel)
    elseif slotCount == 2 then
        local first = minT + usableLength / 4
        local second = minT + usableLength * 3 / 4
        positions[1] = center + longAxis * first
        positions[2] = center + longAxis * second
        positions[1] = util.vector3(positions[1].x, positions[1].y, zLevel)
        positions[2] = util.vector3(positions[2].x, positions[2].y, zLevel)
    else
        local step = usableLength / 3
        positions[1] = center + longAxis * (minT + step / 2)
        positions[2] = center + longAxis * (minT + step * 1.5)
        positions[3] = center + longAxis * (minT + step * 2.5)
        positions[1] = util.vector3(positions[1].x, positions[1].y, zLevel)
        positions[2] = util.vector3(positions[2].x, positions[2].y, zLevel)
        positions[3] = util.vector3(positions[3].x, positions[3].y, zLevel)
    end

    debugLog("bench slot count computed", "object", tostring(bench and bench.recordId), "length", tostring(length), "profileSlots", tostring(desiredSlots), "slots", tostring(#positions), "span", tostring(minT) .. ":" .. tostring(maxT), "measured", tostring(hasMeasuredSpan), "singleSeat", tostring(orientation and orientation.singleSeatBench == true))
    if #positions >= 2 then
        debugLog("bench multi slot allowed", "object", tostring(bench and bench.recordId), "length", tostring(length), "slots", tostring(#positions))
    else
        debugLog("bench single slot due to explicit profile", "object", tostring(bench and bench.recordId), "length", tostring(length))
    end
    for i, pos in ipairs(positions) do
        local localLabel = i == 1 and "seat_a" or (i == 2 and "seat_b" or "seat_c")
        debugLog("bench slot positions local", "object", tostring(bench and bench.recordId), "slot", localLabel, "world", tostring(pos), "axis", tostring(orientation and orientation.label))
    end
    return positions
end

normalizeDirection3 = sittingPosePlanner.normalizeDirection3
objectForwardDirection = sittingPosePlanner.objectForwardDirection
objectRightDirection = sittingPosePlanner.objectRightDirection
directionDot2 = sittingPosePlanner.directionDot2
clearDistanceForDirection = sittingPosePlanner.clearDistanceForDirection
allRadialDirections = sittingPosePlanner.allRadialDirections

sdpFocusVisibleFromSeat = function(pos, data)
    if not (pos and data and data.facingObjectPosition and nearby and nearby.castRay and nearby.COLLISION_TYPE) then return true end
    local from = pos + util.vector3(0, 0, 54)
    local to = data.facingObjectPosition + util.vector3(0, 0, 54)
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
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
    local forwardOffset = profile.finalForwardOffset or -7
    local zOffset = profile.finalZOffset or -36
    local fx, fy = facingDirection.x or 0, facingDirection.y or 0
    local flen = math.sqrt(fx * fx + fy * fy)
    if flen <= 0.001 then fx, fy, flen = 0, 1, 1 end
    local forward2 = util.vector2(fx / flen, fy / flen)
    local right2 = util.vector2(forward2.y, -forward2.x)

    local profileOffset = sittingProfileOffsetFor(profile, activity or "standard", animation)
    local animationOffset = sittingAnimationNormalizationFor(animation, profile)
    local calibration = sittingCalibrationSnapshot()
    local placementOffset = sittingOffsetResolver.mergedOffset(profileOffset, animationOffset, calibration)
    local width = placementOffset.x
    local depth = placementOffset.y
    local height = placementOffset.z
    local yaw = math.rad(placementOffset.yaw)

    local planar = forward2 * (forwardOffset + depth) + right2 * width
    return hitPos + util.vector3(planar.x, planar.y, zOffset + height), yaw, profileOffset, calibration, animationOffset
end

function reprojectSittingFacingFromBody(finalPos, facingDirection, profile, data)
    if not (finalPos and data and data.facingObjectPosition) then return facingDirection, nil end
    local kind = data.facingKind
    if kind ~= "table" and kind ~= "bar" then return facingDirection, nil end
    local category = sittingSeatCategory(profile, currentObject)
    if category == "backed_chair" or category == "single_seat_bench" then return facingDirection, nil end

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

local function rejectSittingFinalIfBlocked(finalPos, facingDirection, profile, data)
    return seatingClearance.rejectSittingFinalIfBlocked({
        nearby = nearby,
        util = util,
        currentObject = function() return currentObject end,
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

local function tryOpenSpaceSittingFallback(sitPosition, originalFacingDirection, profile, data, poseActivity, poseAnimation)
    local category = sittingSeatCategory(profile, currentObject)
    if category == "stool" then return nil end
    if category ~= "barstool" then return nil end
    if data and data.facingKind == "bar" then return nil end

    if data and data.facingKind == "table" then
        return nil
    end

    local directions = {}
    local function addDirection(dir)
        dir = normalizeDirection3(dir)
        if not dir then return end
        for _, existing in ipairs(directions) do
            if directionDot2(existing, dir) > 0.96 then return end
        end
        directions[#directions + 1] = dir
    end

    if originalFacingDirection then addDirection(originalFacingDirection * -1) end
    if data and data.preferredFacingDirection then addDirection(data.preferredFacingDirection * -1) end
    if currentObject then
        local forward = objectForwardDirection(currentObject)
        local right = objectRightDirection(currentObject)
        addDirection(forward)
        addDirection(forward * -1)
        addDirection(right)
        addDirection(right * -1)
    end
    for _, dir in ipairs(allRadialDirections()) do addDirection(dir) end

    local best = nil
    local bestScore = nil
    for _, dir in ipairs(directions) do
        local candidatePos, candidateYawOffset, candidateProfileOffset, candidateCalibration, candidateAnimationOffset = finalPositionForProfile(sitPosition, dir, profile, poseActivity, poseAnimation)
        local correctedPos, zReason = correctExplicitProfileSittingZ(sitPosition, candidatePos, profile, candidateProfileOffset, candidateCalibration, "fallback_outward", candidateAnimationOffset)
        if zReason then candidatePos = correctedPos end
        local adjustedPos, adjustReason = rejectSittingFinalIfBlocked(candidatePos, dir, profile, data)
        if not adjustReason and sittingFinalVerticalLooksSane(sitPosition, adjustedPos or candidatePos, profile) then
            local score = clearDistanceForDirection(sitPosition, dir, 140)
            -- Prefer the direct outward/opposite direction if it is valid, then
            -- fall back to the clearest radial direction. This lets barstools be
            -- used facing away from the bar instead of rejected as table-tight.
            if not best or score > bestScore then
                best = {
                    finalPos = adjustedPos or candidatePos,
                    facingDirection = dir,
                    finalYawOffset = candidateYawOffset,
                    profileOffset = candidateProfileOffset,
                    appliedCalibration = candidateCalibration,
                    reason = "stool_outward_open_space",
                }
                bestScore = score
            end
            debugLog("barstool outward candidate accepted", "object", tostring(currentObject and currentObject.recordId), "score", tostring(score))
            if originalFacingDirection and directionDot2(dir, normalizeDirection3(originalFacingDirection * -1)) > 0.96 then
                return best
            end
        end
    end

    if not best then
        debugLog("barstool final clearance rejected no_outward_space", "object", tostring(currentObject and currentObject.recordId))
    end
    return best
end

sittingFinalVerticalLooksSane = function(basePos, finalPos, profile)
    if not (basePos and finalPos) then return false end
    local category = sittingSeatCategory(profile, currentObject)
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

function sendAnimatedMorrowindCompatResult(payload)
    payload = payload or {}
    payload.npc = self.object
    payload.recordId = self.object and self.object.recordId or nil
    local ok, err = pcall(function()
        core.sendGlobalEvent("SitDownPleaseAnimatedMorrowindAlignmentResult", payload)
    end)
    if not ok then debugLog("animated morrowind compat result failed", tostring(err)) end
end

function onAnimatedMorrowindAlignmentAssist(data)
    local requestId = data and data.requestId or nil
    local actorReason = sdpAnimatedMorrowindCompat.knownSittingActorReason(self.object)
    if not actorReason then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = "not_known_am_sitter" })
        return
    end
    if isInteracting or interactionAssigned then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = "normal_sdp_interaction_active" })
        return
    end
    if core.getSimulationTime() < (sdpAnimatedMorrowindCompatDialogueUntil or 0) then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = "dialogue_active" })
        return
    end
    local dangerReason = activeDangerReason()
    if dangerReason then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = dangerReason })
        return
    end
    local packageBlocks, packageReason = activePackageBlocksNewInteraction("sitting", data)
    if packageBlocks then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = packageReason })
        return
    end
    local animationBlocks, animationReason = activeAnimationBlocksExternalCompat()
    if animationBlocks then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = animationReason })
        return
    end

    local obj = data and data.object or nil
    if not (obj and obj.position) then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, skippedReason = "missing_object" })
        return
    end

    local profile = data.profile
    if not profile then
        profile = profiles.getProfileForObject(obj, "sitting", settings)
    end
    if not profile then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, objectId = data.objectId, skippedReason = "missing_profile" })
        return
    end

    local priorObject = currentObject
    currentObject = obj
    local sitPosition, surfaceMode, surfaceSamples = sampleSittingSurface(obj, profile)
    if not sitPosition then
        currentObject = priorObject
        sendAnimatedMorrowindCompatResult({
            requestId = requestId,
            objectId = data.objectId,
            profileId = data.profileId or profile.profileId,
            skippedReason = "surface_" .. tostring(surfaceMode or "unavailable"),
        })
        return
    end

    local facingDirection = normalizeDirection3(data.preferredFacingDirection)
    if not facingDirection and self.object and self.object.rotation then
        local yaw = self.object.rotation:getYaw()
        facingDirection = util.vector3(math.sin(yaw), math.cos(yaw), 0)
    end
    facingDirection = facingDirection or util.vector3(0, 1, 0)

    local finalPos = finalPositionForProfile(sitPosition, facingDirection, profile, "standard", profile.animation)
    currentObject = priorObject
    if not finalPos then
        sendAnimatedMorrowindCompatResult({ requestId = requestId, objectId = data.objectId, skippedReason = "missing_expected_position" })
        return
    end

    local sdpExpectedZ = finalPos.z
    local originalZ = self.object and self.object.position and self.object.position.z or nil
    local expectedZ, expectedReason = sdpAnimatedMorrowindCompat.expectedExternalSeatedZ(self.object, sitPosition.z, sdpExpectedZ, originalZ)
    if not expectedZ then
        sendAnimatedMorrowindCompatResult({
            requestId = requestId,
            objectId = data.objectId,
            profileId = data.profileId or profile.profileId,
            skippedReason = expectedReason or "unsupported_external_root_family",
        })
        return
    end
    local targetZ, reason, delta = sdpAnimatedMorrowindCompat.correctionTarget(originalZ, expectedZ, self.object)
    local correctionNeeded = targetZ ~= nil

    debugLog(
        "animated morrowind compat evaluated",
        "actorReason", tostring(actorReason),
        "object", tostring(data.objectId),
        "profile", tostring(data.profileId or profile.profileId),
        "surface", tostring(surfaceMode),
        "samples", tostring(surfaceSamples),
        "originalZ", tostring(originalZ),
        "expectedZ", tostring(expectedZ),
        "expectedReason", tostring(expectedReason),
        "sdpExpectedZ", tostring(sdpExpectedZ),
        "delta", tostring(delta),
        "result", correctionNeeded and "correction_needed" or tostring(reason)
    )

    sendAnimatedMorrowindCompatResult({
        requestId = requestId,
        object = obj,
        objectId = data.objectId,
        profileId = data.profileId or profile.profileId,
        surfaceMode = surfaceMode,
        surfaceSamples = surfaceSamples,
        originalZ = originalZ,
        expectedZ = expectedZ,
        sdpExpectedZ = sdpExpectedZ,
        targetZ = targetZ,
        delta = delta,
        correctionNeeded = correctionNeeded,
        skippedReason = correctionNeeded and nil or reason,
    })
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
        currentHour = data and data.currentHour or nil,
        initialPlacement = data and data.initialPlacement == true,
        manualAssign = data and data.manualAssign == true,
        manualAssignRetryCount = data and data.manualAssignRetryCount,
        manualAssignOverrideTesting = data and data.manualAssignOverrideTesting == true,
        calibrationAction = data and data.calibrationAction == true,
        calibrationReason = data and data.calibrationReason,
        usable = false,
        reason = reason,
    })
end

local function validateAssignedObject(data)
    if not data or not data.object then return false, "missing_object" end
    if not data.interactionType then return false, "unsupported_interaction_type" end

    local profile, reason = profiles.getProfileForObject(data.object, data.interactionType, settings)
    if not profile then return false, reason end

    if data.interactionType == "sleeping" and profile.isFallback == true and profiles.sleepFallbackCandidateStatus then
        local okSleep, sleepReason = profiles.sleepFallbackCandidateStatus(data.object)
        if okSleep ~= true then
            debugLog("sleep candidate rejected non_sleep_object", "object", tostring(data.object and data.object.recordId), "model", tostring(profiles.objectModelPath(data.object)), "reason", tostring(sleepReason))
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

local function projectedObjectOffset(obj, offset)
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
        sleepApproachReachability = sleepApproachReachability,
        horizontalDistance3 = horizontalDistance3,
        rayBlockedBetween = rayBlockedBetween,
    }
end

local function chooseSleepApproachPosition(data, slot, profile, finalPos)
    return sleepRoutePlanner.chooseApproach(sleepRouteContext(), data, slot, profile, finalPos)
end

local function chooseSleepExitPositions(slot, profile, finalPos, approachPos, approachName)
    return sleepRoutePlanner.chooseExits(sleepRouteContext(), slot, profile, finalPos, approachPos, approachName)
end

local function sleepFinalPlacementLocallySane(finalPos, approachPos, bedTop, profile, stage)
    return sleepRoutePlanner.finalPlacementLocallySane(sleepRouteContext(), finalPos, approachPos, bedTop, profile, stage)
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

initialSleepMayBypassApproachRoute = function(data, profile, reason)
    if not (data and data.initialPlacement == true and profile and profile.externalProfile == true) then return false end
    if data.calibrationAction == true or data.fallback == true then return false end

    reason = tostring(reason or "")
    return reason == "approach_too_far_from_navmesh"
        or reason == "approach_navmesh_behind_collision"
        or reason == "blocked_by_wall"
        or reason == "route_too_indirect"
end


local function evaluateSleepingInteraction(data, profile)
    local slot = data.slot or {}
    local sleepOffset = slot.sleepOffset or profile.sleepOffset or { x = 0, y = 0, z = 0 }
    local bedTop, sampleCount, surfaceMode = sampledObjectTopCenter(currentObject, profile)
    bedTop = bedTop or currentObject.position

    -- Lying pose groups from VA/Dynamic Actors are not aligned like sitting
    -- idles. The surface sample finds the bed/mattress top, but the actor root
    -- needs to sit below that surface or the prone body appears high/in the
    -- ceiling. A separate yaw offset also lets the pose run lengthwise with
    -- beds instead of 90 degrees across them.
    local variant = profile.chosenAnimationVariant or {}
    local bedType = string.lower(tostring(profile.bedType or profile.type or ""))
    local recordId = string.lower(tostring(currentObject and currentObject.recordId or ""))
    local normalizeVaSleepRoot = recordId == "active_com_bed_05"
        or recordId == "active_com_bunk_01"
        or recordId == "active_com_bunk_02"
    local variantRootZOffset = variant.sleepRootZOffset
    if profile.externalProfile ~= true or normalizeVaSleepRoot ~= true or bedType == "bedroll" or bedType == "hammock" then
        variantRootZOffset = nil
    end
    local rootZOffset = slot.sleepRootZOffset or variantRootZOffset or profile.sleepRootZOffset or 0
    local poseYawOffset = slot.sleepPoseYawOffset or variant.sleepPoseYawOffset or profile.sleepPoseYawOffset or 0
    local profileRootLocalOffset = slot.sleepRootLocalOffset or variant.sleepRootLocalOffset or profile.sleepRootLocalOffset
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

    local calibrationOffset = {
        x = tonumber(runtimeSleepCalibration.x) or 0,
        y = tonumber(runtimeSleepCalibration.y) or 0,
        z = tonumber(runtimeSleepCalibration.z) or 0,
    }
    local calibrationYawDegrees = tonumber(runtimeSleepCalibration.yaw) or 0
    local calibrationOverridesProfile = calibrationOffset.x ~= 0 or calibrationOffset.y ~= 0 or calibrationOffset.z ~= 0
        or calibrationYawDegrees ~= 0

    -- Developer-menu calibration is deliberately simple: nudges are temporary
    -- changes added on top of the saved profile. Resetting clears the changes
    -- and returns to the loaded .txt profile.
    local base = profileRootLocalOffset or { x = 0, y = 0, z = 0 }
    local visibleRootLocalOffset = {
        x = (base.x or 0) + calibrationOffset.x,
        y = (base.y or 0) + calibrationOffset.y,
        z = (base.z or 0) + calibrationOffset.z,
    }
    if calibrationYawDegrees ~= 0 then poseYawOffset = poseYawOffset + math.rad(calibrationYawDegrees) end

    local placementRootLocalOffset = {
        x = visibleRootLocalOffset.x + (sleepAnimationOffset.x or 0),
        y = visibleRootLocalOffset.y + (sleepAnimationOffset.y or 0),
        z = visibleRootLocalOffset.z + (sleepAnimationOffset.z or 0),
    }
    local placementPoseYawOffset = poseYawOffset + math.rad(sleepAnimationOffset.yaw or 0)

    local finalRot = yawFromObject(currentObject, (slot.rotationOffset or profile.rotationOffset or 0) + placementPoseYawOffset)
    local sleepLateralOffset = slot.sleepLateralOffset or profile.sleepLateralOffset or 0
    local finalPos = bedTop
        + objectLocalHorizontalOffset(currentObject, sleepOffset)
        + objectLocalHorizontalOffset(currentObject, placementRootLocalOffset)
        + yawLateralHorizontalOffset(finalRot, sleepLateralOffset)
        + util.vector3(0, 0, (sleepOffset.z or 0) + (placementRootLocalOffset and placementRootLocalOffset.z or 0) + rootZOffset)
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
        local alreadyAtBed, bedHorizontal, bedVertical = initialSleepActorAlreadyAtBed(data, currentObject)
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
        elseif initialSleepMayBypassApproachRoute(data, profile, approachReason) then
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
            debugLog(
                "sleep_entry_rejected",
                "reason", tostring(approachReason or "no_path_to_bed"),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "approach", tostring(approachName),
                "approachPos", tostring(approachPos),
                "closedStatus", approachDetails and pathStatusLabel(approachDetails.closedStatus) or "nil",
                "openStatus", approachDetails and pathStatusLabel(approachDetails.openStatus) or "nil"
            )
            reject(data, approachReason or "no_path_to_bed")
            return
        end
    end

    local sane, sanityReason, sanityDelta, sanityLimit = sleepFinalPlacementLocallySane(finalPos, approachPos, bedTop, profile, "before_inward")
    if sane ~= true then
        if sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, sanityReason or "sleep_final_position_invalid", "sleep_final_sanity_before_inward") then
            sane = true
        else
            debugLog(
                "sleep_entry_rejected",
                "reason", tostring(sanityReason),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "delta", tostring(sanityDelta),
                "limit", tostring(sanityLimit),
                "final", tostring(finalPos),
                "approachPos", tostring(approachPos),
                "bedTop", tostring(bedTop)
            )
            reject(data, sanityReason or "sleep_final_position_invalid")
            return
        end
    end

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

    sane, sanityReason, sanityDelta, sanityLimit = sleepFinalPlacementLocallySane(finalPos, approachPos, bedTop, profile, "after_inward")
    if sane ~= true then
        if sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, sanityReason or "sleep_final_position_invalid", "sleep_final_sanity_after_inward") then
            sane = true
        else
            debugLog(
                "sleep_entry_rejected",
                "reason", tostring(sanityReason),
                "object", tostring(currentObject and currentObject.recordId),
                "model", tostring(profiles.objectModelPath(currentObject)),
                "profile", tostring(profile.profileId),
                "slot", tostring(currentSlotName),
                "delta", tostring(sanityDelta),
                "limit", tostring(sanityLimit),
                "final", tostring(finalPos),
                "approachPos", tostring(approachPos),
                "bedTop", tostring(bedTop)
            )
            reject(data, sanityReason or "sleep_final_position_invalid")
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

    targetPos = approachPos or finalPos
    currentFinalPosition = finalPos
    currentFinalRotation = finalRot
    currentSleepApproachPos = approachPos
    currentSleepApproachName = approachName
    currentSleepExitPositions = exitPositions
    currentSleepExitName = exitName
    currentSleepBedTop = bedTop
    currentSleepRouteNeedsDoorAssist = approachDetails and approachDetails.needsDoorAssist == true or false
    currentSleepProfileRootOffset = profileRootLocalOffset
    currentSleepCalibrationOffset = calibrationOffset
    currentSleepMergedRootOffset = visibleRootLocalOffset
    currentSleepAnimationNormalizationOffset = sleepAnimationOffset
    currentSleepCalibrationYawDegrees = calibrationYawDegrees
    currentSleepPoseYawOffset = poseYawOffset
    currentSleepSurfaceMode = surfaceMode
    currentSleepSurfaceSamples = sampleCount or 0
    interactionAssigned = true
    applySleepHelloSuppression()

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
        "variant", tostring(profile.chosenAnimationLabel),
        "surfaceSamples", tostring(sampleCount),
        "surfaceMode", tostring(surfaceMode),
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
        finalRotation = finalRot,
        surfaceMode = surfaceMode,
        basisSource = profile.orientationVariantSource or calibrationExport.sleepProfileSource(profile),
    })
    if profile and currentObject and (profile.bedType == "double" or (profile.slots and #profile.slots > 1) or tostring(currentObject.recordId or "") == "active_de_r_bed_20") then
        debugLog("double bed profile selected", tostring(currentObject.recordId), "profile", tostring(profile.profileId), "slots", tostring(profile.slots and #profile.slots or 0))
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

    if data.suppressAcceptedResult == true then return end

    sendAcceptedInteraction({
        npc = self.object,
        object = currentObject,
        objectId = currentObject.recordId,
        model = profiles.objectModelPath(currentObject),
        profile = profile,
        profileId = profile.profileId,
        interactionType = currentInteractionType,
        slot = slot,
        slotKey = currentSlotKey,
        slotName = currentSlotName,
        approachPos = approachPos,
        approachName = approachName,
        sleepRouteStatus = approachReason,
        sleepRouteNeedsDoorAssist = approachDetails and approachDetails.needsDoorAssist == true or false,
        exitPosition = exitPositions and exitPositions[1] or approachPos,
        exitPositions = exitPositions,
        hitPos = finalPos,
        finalPosition = finalPos,
        finalRotation = finalRot,
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
        sleepPhase = data.sleepPhase,
        actorBedtime = data.actorBedtime,
        actorWakeTime = data.actorWakeTime,
        sleepWakeBias = data.sleepWakeBias,
        observedPlayerOverride = data.observedPlayerOverride,
        calibrationAction = data.calibrationAction == true,
        calibrationReason = data.calibrationReason,
        manualAssign = data.manualAssign == true,
        manualAssignRetryCount = data.manualAssignRetryCount,
        manualAssignOverrideTesting = data.manualAssignOverrideTesting == true,
        manualAssignOverrideApplied = data.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = data.manualAssignOverrideReasons and table.concat(data.manualAssignOverrideReasons, ",") or nil,
        usable = true
    })
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
            manualAssign = data and data.manualAssign == true,
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
    currentInteractionInitialPlacement = data.initialPlacement == true
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
    sleepDoorAssistElapsed = 0
    sleepDoorAssistRequested = {}
    currentSleepRouteNeedsDoorAssist = false
    currentInteractionTravelDest = nil
    currentInteractionTravelStartedAt = nil
    currentInteractionStartedAt = nil
    externalTravelTracker:reset()

    if currentInteractionType == "sleeping" then
        evaluateSleepingInteraction(data, profile)
        return
    end


    if currentInteractionType ~= "sitting" then
        reject(data, "unsupported_interaction_type")
        return
    end

    local sitPosition, surfaceMode, surfaceSamples = sampleSittingSurface(currentObject, profile)
    if not sitPosition then
        debugLog(
            "sitting surface validation failed",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "mode", tostring(surfaceMode),
            "samples", tostring(surfaceSamples)
        )
        reject(data, "collision_or_raycast_validation_failed")
        return
    end

    local orientation = nil

    if isBenchFurniture(currentObject, profile) then
        local length, zLevel
        orientation, length, zLevel = determineBenchOrientationAndLength(currentObject)
        local positions = getBenchSittingPositions(currentObject, orientation, length, zLevel, profile)
        local slotIndex = currentSlotName == "seat_c" and 3 or (currentSlotName == "seat_b" and 2 or 1)
        if slotIndex > #positions then
            if data.manualAssignOverrideTesting == true then
                noteManualAssignOverride(data, "bench_slot_unavailable_short_length")
                debugLog("nearest_manual_assign_override", "reason", "bench_slot_unavailable_short_length", "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "fallback", "first_available_position")
                sitPosition = positions[1] or sitPosition
            else
                reject(data, "bench_slot_unavailable_short_length")
                return
            end
        else
            sitPosition = positions[slotIndex] or positions[1] or sitPosition
        end
    end

    local surfaceBlockerOverrideReason = nil
    local clutter, clutterDistance, clutterZ, clutterReason = sdpSeatSurfaceClutterBlocker(sitPosition, profile)
    if clutter then
        debugLog(
            "sitting surface rejected clutter",
            "object", tostring(currentObject and currentObject.recordId),
            "profile", tostring(profile and profile.profileId),
            "clutter", tostring(clutter.recordId or clutter.id),
            "distance", tostring(clutterDistance),
            "vertical", tostring(clutterZ),
            "reason", tostring(clutterReason)
        )
        if data.manualAssignOverrideTesting == true then
            surfaceBlockerOverrideReason = "seat_surface_blocked_by_item"
            noteManualAssignOverride(data, surfaceBlockerOverrideReason)
            debugLog("nearest_manual_assign_override", "reason", surfaceBlockerOverrideReason, "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "sitting_surface_item")
        else
            reject(data, "seat_surface_blocked_by_item")
            return
        end
    end

    data.sittingSeatPosition = sitPosition
    local poseActivity = "standard"
    sdpSittingFacingRefiner.refine({
        nearby = nearby,
        util = util,
        profiles = profiles,
        rayHitBelongsToObject = rayHitBelongsToObject,
        sittingSeatCategory = sittingSeatCategory,
        debugLog = debugLog,
    }, sitPosition, data, profile, currentObject)

    local facingDirection, facingReason = determineFacingDirection(sitPosition, orientation, data.preferredFacingDirection, data.facingKind, profile, currentObject, data)
    if surfaceBlockerOverrideReason then
        facingReason = tostring(facingReason) .. "+manual_item_override"
    end
    data.preferredFacingDirection = facingDirection
    local refinedAnimation, refinedVariant = chooseAvailableAnimation(profile, data)
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
    local finalPos, finalYawOffset, profileOffset, appliedCalibration, animationOffset = finalPositionForProfile(sitPosition, facingDirection, profile, poseActivity, poseAnimation)
    local reprojectedFacing, reprojectReason = reprojectSittingFacingFromBody(finalPos, facingDirection, profile, data)
    if reprojectReason then
        facingDirection = reprojectedFacing
        finalPos, finalYawOffset, profileOffset, appliedCalibration, animationOffset = finalPositionForProfile(sitPosition, facingDirection, profile, poseActivity, poseAnimation)
        facingReason = tostring(facingReason) .. "+" .. tostring(reprojectReason)
        data.preferredFacingDirection = facingDirection
    end
    local zCorrectionReason, zCorrectionMeta = nil, nil
    finalPos, zCorrectionReason, zCorrectionMeta = correctExplicitProfileSittingZ(sitPosition, finalPos, profile, profileOffset, appliedCalibration, surfaceMode, animationOffset)
    if zCorrectionReason then
        facingReason = tostring(facingReason) .. "+" .. tostring(zCorrectionReason)
    end
    local adjustedPos, adjustReason, clearanceMeta = rejectSittingFinalIfBlocked(finalPos, facingDirection, profile, data)
    if adjustReason == "tight_table_or_counter_rejected" then
        local fallback = tryOpenSpaceSittingFallback(sitPosition, facingDirection, profile, data, poseActivity, poseAnimation)
        if fallback then
            finalPos = fallback.finalPos
            facingDirection = fallback.facingDirection
            finalYawOffset = fallback.finalYawOffset
            profileOffset = fallback.profileOffset
            appliedCalibration = fallback.appliedCalibration
            facingReason = tostring(facingReason) .. "+" .. tostring(fallback.reason)
            adjustReason = fallback.reason
            if sittingSeatCategory(profile, currentObject) == "barstool" then
                debugLog("barstool inward candidate rejected but fallback outward accepted", "object", tostring(currentObject and currentObject.recordId))
            end
            debugLog("facing " .. tostring(facingReason), "object", tostring(currentObject and currentObject.recordId))
            debugLog("clearance " .. tostring(adjustReason), "object", tostring(currentObject and currentObject.recordId))
        else
            if seatingClearance.manualAssignMayBypassSittingClearance(data, clearanceMeta, sittingSeatCategory(profile, currentObject)) then
                noteManualAssignOverride(data, tostring(adjustReason))
                debugLog("nearest_manual_assign_override", "reason", tostring(adjustReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "sitting_clearance")
                facingReason = tostring(facingReason) .. "+manual_clearance_override"
                adjustReason = "manual_clearance_override"
            else
                local snap = calibrationExport.sittingSolverSnapshot(currentObject, sitPosition, finalPos, self.object, finalYawOffset, facingDirection, facingReason, data, surfaceMode, surfaceSamples)
                calibrationExport.logDemidChairBasisComparison(debugLog, self.object, currentObject, snap, clearanceMeta or { result = adjustReason })
                reject(data, adjustReason)
                return
            end
        end
    elseif adjustReason then
        finalPos = adjustedPos
        facingReason = tostring(facingReason) .. "+" .. tostring(adjustReason)
    end
    local solverSnapshot = calibrationExport.sittingSolverSnapshot(currentObject, sitPosition, finalPos, self.object, finalYawOffset, facingDirection, facingReason, data, surfaceMode, surfaceSamples)
    if not sittingFinalVerticalLooksSane(sitPosition, finalPos, profile) then
        if sdpManualAssignment.bypassLocalRejection({ debugLog = debugLog, object = currentObject, slotName = currentSlotName }, data, "initial_sitting_vertical_rejected", "sitting_vertical_sanity") then
            facingReason = tostring(facingReason) .. "+manual_vertical_override"
        else
            calibrationExport.logDemidChairBasisComparison(debugLog, self.object, currentObject, solverSnapshot, zCorrectionMeta or { result = "initial_sitting_vertical_rejected" })
            reject(data, "initial_sitting_vertical_rejected")
            return
        end
    end
    local lockedRouteReason = sittingLockedRouteRejectReason(data.approachPos or sitPosition, data)
    if lockedRouteReason then
        if data.manualAssignOverrideTesting == true then
            noteManualAssignOverride(data, tostring(lockedRouteReason))
            debugLog("nearest_manual_assign_override", "reason", tostring(lockedRouteReason), "object", tostring(currentObject and currentObject.recordId), "slot", tostring(currentSlotName), "bypass", "sitting_locked_route")
            facingReason = tostring(facingReason) .. "+manual_locked_route_override"
        else
            calibrationExport.logDemidChairBasisComparison(debugLog, self.object, currentObject, solverSnapshot, { result = lockedRouteReason })
            reject(data, lockedRouteReason)
            return
        end
    end
    local finalRot = math.atan2(facingDirection.x, facingDirection.y) + (finalYawOffset or 0)
    calibrationExport.traceLocalSittingAcceptance(core, self.object, currentObject, currentSlotName, debugLog, "begin", {
        objectId = currentObject and currentObject.recordId,
        slotName = currentSlotName,
        reason = adjustReason,
    })
    if sittingSeatCategory(profile, currentObject) == "backed_chair" then
        local objectYaw = currentObject and currentObject.rotation and currentObject.rotation.getYaw and currentObject.rotation:getYaw() or 0
        debugLog(
            "backed_chair_rotation_final",
            "objectYaw", tostring(objectYaw),
            "profileYaw", tostring(finalYawOffset or 0),
            "finalYaw", tostring(finalRot)
        )
    end
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

    targetPos = data.approachPos or sitPosition
    interactionAssigned = true

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
        "surface", tostring(surfaceMode),
        "surfaceSamples", tostring(surfaceSamples),
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
        interactionType = currentInteractionType,
        slot = data.slot,
        slotKey = currentSlotKey,
        slotName = currentSlotName,
        approachPos = data.approachPos or sitPosition,
        hitPos = sitPosition,
        finalPosition = finalPos,
        finalRotation = finalRot,
        animation = currentSittingPoseAnimation,
        profileOffset = profileOffset,
        animationOffset = animationOffset,
        calibration = appliedCalibration,
        facingDirection = facingDirection,
        facingObjectId = data.facingObjectId,
        facingObjectModel = data.facingObjectModel,
        facingObjectName = data.facingObjectName,
        facingKind = data.facingKind,
        facingObjectPosition = data.facingObjectPosition,
        fallbackUsed = data.fallbackUsed,
        initialPlacement = data.initialPlacement == true,
        manualAssign = data.manualAssign == true,
        manualAssignRetryCount = data.manualAssignRetryCount,
        manualAssignOverrideTesting = data.manualAssignOverrideTesting == true,
        manualAssignOverrideApplied = data.manualAssignOverrideApplied == true,
        manualAssignOverrideReason = data.manualAssignOverrideReasons and table.concat(data.manualAssignOverrideReasons, ",") or nil,
        calibrationAction = data.calibrationAction == true,
        calibrationReason = data.calibrationReason,
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
        -- OpenMW documents playBlended as vulnerable to the hardcoded character
        -- controller cancelling/altering the pose, and recommends playQueued for
        -- scripted animations. Sleeping must visibly override Wander/idle/movement,
        -- so prefer playQueued and only fall back to blended/scripted priority.
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
            -- Fallback remains, but force true scripted priority. The old profile
            -- value was priority 5 (Movement), which can lose visually to Wander.
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


local function onStopInteractionObject(data)
    local stopReason = data and data.reason or "stop_interaction"
    if data and data.wakeCleanupOnly == true and currentInteractionType ~= "sleeping" then
        interactionAnimation.forceCancelSleepGroups(debugLog, stopReason, self)
        debugLog(
            "wake cleanup probe force-cleared sleep groups without local sleep state",
            "reason", tostring(stopReason),
            "currentType", tostring(currentInteractionType)
        )
        return
    end

    stopCurrentAnim()
    if data and (data.forceClearSleepAnimation == true or data.interactionType == "sleeping" or data.interactionType == "sitting" or tostring(stopReason):find("wake", 1, true) or tostring(stopReason):find("sleep_window", 1, true))
        and (data.wakeCleanupOnly ~= true or currentInteractionType == "sleeping" or isInteracting == true or interactionAssigned == true or currentAnimationQueued == true)
    then
        interactionAnimation.forceClearQueue(debugLog, stopReason, true, self)
        interactionAnimation.forceCancelSleepGroups(debugLog, stopReason, self)
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
    currentSleepProfileRootOffset = nil
    currentSleepCalibrationOffset = nil
    currentSleepMergedRootOffset = nil
    currentSleepCalibrationYawDegrees = 0
    currentSleepPoseYawOffset = nil
    currentSleepSurfaceMode = nil
    currentSleepSurfaceSamples = 0
    currentInteractionInitialPlacement = false
    currentCalibrationTargetKey = nil
    externalTravelTracker:reset()
    resetRuntimeCalibrationOffsets(stopReason)
    sleepDoorAssistElapsed = 0
    sleepDoorAssistRequested = {}
    aiPollTimer = 0
end

local function onInteractionDialogueStarted(data)
    sdpAnimatedMorrowindCompatDialogueUntil = core.getSimulationTime() + 5
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

local function onDied()
    if types and types.Actor and types.Actor.isDead then
        local okDead, dead = pcall(function() return types.Actor.isDead(self.object) end)
        if okDead and dead ~= true then
            debugLog("died event ignored", "actor_not_dead")
            return
        end
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
        -- Player proximity/greeting chatter and hit-react animation noise should
        -- not stand a seated NPC up. Combat/follow/escort/pursue and real Travel
        -- packages are handled above; other package types are logged and ignored
        -- so the ordinary sitting lifecycle timer can still release the actor.
        debugLog("sitting ignored non-release ai package", tostring(pkg.type))
        return false, nil
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
        return nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
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
                debugLog("active weapon stance ignored while seated", tostring(stance), "type", tostring(currentInteractionType))
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

    local package = data
    if package.type == "Travel" and (package.cancelOther == nil or package.destinationTolerance == nil) then
        package = profiles.shallowCopy(data)
        if package.cancelOther == nil then package.cancelOther = true end
        if package.destinationTolerance == nil then package.destinationTolerance = 70 end
    end
    local ok, err = pcall(function()
        ai.startPackage(package)
    end)

    -- Some OpenMW builds/examples use destination instead of destPosition for
    -- Travel package payloads. Try the alternate key if the first call fails.
    if not ok and data.type == "Travel" and data.destPosition and data.destination == nil then
        package = profiles.shallowCopy(data)
        package.destination = data.destPosition
        if package.cancelOther == nil then package.cancelOther = true end
        if package.destinationTolerance == nil then package.destinationTolerance = 70 end
        ok, err = pcall(function()
            ai.startPackage(package)
        end)
    end

    if ok then
        if package.type == "Travel" then
            currentInteractionTravelDest = package.destPosition or package.destination
            currentInteractionTravelStartedAt = core.getSimulationTime and core.getSimulationTime() or 0
        end
        debugLog("ai package started", tostring(package.type), package.destPosition and tostring(package.destPosition) or (package.destination and tostring(package.destination) or ""))
    else
        debugLog("ai package start failed", tostring(data.type), tostring(err))
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
            animation = currentSittingPoseAnimation or currentAnimation,
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

local function onRefreshSittingCalibration(data)
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

    evaluateSleepingInteraction({
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
    }, currentProfile)

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
            currentSittingAppliedProfileOffset = currentSittingAppliedProfileOffset,
            currentSittingAppliedAnimationOffset = currentSittingAppliedAnimationOffset,
            currentSittingPoseActivity = currentSittingPoseActivity,
            currentSittingPoseAnimation = currentSittingPoseAnimation,
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
        SitDownPleaseBriefWander = onSitDownPleaseBriefWander,
        SitDownPleaseClearBriefTravel = onSitDownPleaseClearBriefTravel,
        InteractionDialogueStarted = onInteractionDialogueStarted,
        InteractionDialogueStopped = function(data)
            sdpAnimatedMorrowindCompatDialogueUntil = 0
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
            onStartInteractionAnimation({ interactionType = "sitting", animation = currentAnimation or "sitidle1" })
        end,
        StandUpPlease = onStopInteractionObject,
    }
}
