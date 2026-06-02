local self = require('openmw.self')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local cfg = require('scripts.slyropes.config')
local common = require('scripts.slyropes.common')
local settings = require('scripts.slyropes.settings')

local L10N = core.l10n('SlyNerevarine')

local M = {}
local v3 = util.vector3

local lockActive = false
local rayWasVisible = false
local rayLostLogged = false
local lastReason = nil
local lastRope = nil
local lastHitPos = nil
local lockSeconds = 0
local lostSeconds = 0
local elapsedSinceSend = 999
local balanceCache = nil
local balanceCacheSeconds = 999
local statsFallbackLogged = false
local fatigueFallbackLogged = false
local acrobaticsFallbackLogged = false
local agilityFallbackLogged = false
local xpFallbackLogged = false
local balanceCheckSeconds = 0
local xpSeconds = 0
local inactiveScanSeconds = 999
local messageCooldown = 0
local balanceReacquireSuppression = 0
local pendingFallMessage = nil
local pendingFallStartZ = nil
local pendingFallReason = nil
local debugSnapshotSeconds = 999
local settingsRefreshSeconds = 999

local function log(msg)
    if settings.debugEnabled() then
        print('[Sly Nerevarine] ' .. msg)
    end
end

local function tr(key, args, fallback)
    local ok, value = pcall(function()
        if args ~= nil then
            return L10N(key, args)
        end
        return L10N(key)
    end)

    if ok and value and value ~= '' then
        return value
    end
    return fallback or tostring(key or '')
end

local function xyDistance(a, b)
    if not a or not b then
        return 999999
    end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(x, lo, hi)
    x = tonumber(x) or lo
    if x < lo then
        return lo
    end
    if x > hi then
        return hi
    end
    return x
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

local function statModified(statFn, fallback)
    if type(statFn) ~= 'function' then
        return fallback, false
    end

    local ok, stat = pcall(function()
        return statFn(self)
    end)

    if ok and stat and type(stat.modified) == 'number' then
        return stat.modified, true
    end

    return fallback, false
end

local function readFatigueRatio()
    local actorStats = types.Actor and types.Actor.stats
    local fallback = cfg.COMPETENCY_FALLBACK_FATIGUE_RATIO or 1.0
    if not actorStats or not actorStats.dynamic or not actorStats.dynamic.fatigue then
        return fallback, false
    end

    local ok, fatigue = pcall(function()
        return actorStats.dynamic.fatigue(self)
    end)

    if not ok or not fatigue then
        return fallback, false
    end

    local current = tonumber(fatigue.current)
    local base = tonumber(fatigue.base)
    local modifier = tonumber(fatigue.modifier) or 0
    if not current or not base then
        return fallback, false
    end

    local maxFatigue = base + modifier
    if maxFatigue <= 0 then
        maxFatigue = base
    end
    if maxFatigue <= 0 then
        return fallback, false
    end

    return clamp(current / maxFatigue, 0, 1), true
end

local function readCompetency()
    if not cfg.COMPETENCY_ENABLED then
        return 1.0, cfg.COMPETENCY_FALLBACK_ACROBATICS or 50, cfg.COMPETENCY_FALLBACK_AGILITY or 50, 1.0, 1.0
    end

    local actorStats = types.Actor and types.Actor.stats
    local npcStats = types.NPC and types.NPC.stats
    local acro = cfg.COMPETENCY_FALLBACK_ACROBATICS or 50
    local agility = cfg.COMPETENCY_FALLBACK_AGILITY or 50
    local okAcro = false
    local okAgility = false

    -- Skills live on NPC.stats rather than Actor.stats. PLAYER extends NPC, so this is the correct path for the player.
    -- The older Actor.stats.skills lookup silently fell back to 50 Acrobatics on API 129.
    if npcStats and npcStats.skills and npcStats.skills.acrobatics then
        acro, okAcro = statModified(npcStats.skills.acrobatics, acro)
    end
    if actorStats and actorStats.attributes and actorStats.attributes.agility then
        agility, okAgility = statModified(actorStats.attributes.agility, agility)
    elseif npcStats and npcStats.attributes and npcStats.attributes.agility then
        agility, okAgility = statModified(npcStats.attributes.agility, agility)
    end

    if settings.debugEnabled() and not okAcro and not acrobaticsFallbackLogged then
        log('Acrobatics stat read fallback active; using default acro=' .. tostring(acro))
        acrobaticsFallbackLogged = true
    end
    if settings.debugEnabled() and not okAgility and not agilityFallbackLogged then
        log('Agility stat read fallback active; using default agi=' .. tostring(agility))
        agilityFallbackLogged = true
    end
    if settings.debugEnabled() and (not okAcro or not okAgility) and not statsFallbackLogged then
        statsFallbackLogged = true
    end

    local fatigueRatio, okFatigue = readFatigueRatio()
    if settings.debugEnabled() and not okFatigue and not fatigueFallbackLogged then
        log('fatigue read fallback active for competency; using default fatigue ratio')
        fatigueFallbackLogged = true
    end

    local aW = cfg.COMPETENCY_ACROBATICS_WEIGHT or 0.70
    local gW = cfg.COMPETENCY_AGILITY_WEIGHT or 0.30
    local denom = aW + gW
    if denom <= 0 then
        denom = 1
    end

    local weighted = ((acro * aW) + (agility * gW)) / denom

    -- Weighted average alone made one very strong stat either too dominant or too weak depending
    -- on the weight split. The carry curve below lets either Acrobatics or Agility at 60+ make
    -- the walk mostly reliable, while 5/5 remains effectively unable to mount.
    local bestStat = math.max(tonumber(acro) or 0, tonumber(agility) or 0)
    local carryAt60 = cfg.COMPETENCY_BEST_STAT_CARRY_AT_60 or 0.78
    local bestCarry
    if bestStat >= 60 then
        bestCarry = lerp(carryAt60, 1.0, clamp((bestStat - 60) / 40, 0, 1))
    else
        bestCarry = clamp(bestStat / 60, 0, 1) * carryAt60
    end

    local skillCompetency = clamp(math.max(weighted / 100, bestCarry), 0, 1)
    local fatigueMult = lerp(cfg.FATIGUE_COMPETENCY_MULT_MIN or 0.35, cfg.FATIGUE_COMPETENCY_MULT_MAX or 1.05, fatigueRatio)
    local effectiveCompetency = clamp(skillCompetency * fatigueMult, 0, 1)
    return effectiveCompetency, acro, agility, fatigueRatio, skillCompetency
end

local function currentBalance(dt)
    balanceCacheSeconds = balanceCacheSeconds + (dt or 0)
    if balanceCache and balanceCacheSeconds < (cfg.COMPETENCY_REFRESH_SECONDS or 0.5) then
        return balanceCache
    end

    balanceCacheSeconds = 0
    local competency, acro, agility, fatigueRatio, skillCompetency = readCompetency()

    if not cfg.COMPETENCY_ENABLED then
        balanceCache = {
            competency = competency,
            skillCompetency = skillCompetency,
            acrobatics = acro,
            agility = agility,
            fatigueRatio = fatigueRatio,
            maxHitDistance = cfg.MAX_VALID_HIT_XY_DISTANCE,
            rayLostGrace = cfg.RAY_LOST_GRACE_SECONDS,
            stickyDrift = cfg.MAX_STICKY_XY_DRIFT,
            driftDelay = cfg.DRIFT_DISMOUNT_AFTER_SECONDS,
        }
        return balanceCache
    end

    balanceCache = {
        competency = competency,
        skillCompetency = skillCompetency,
        acrobatics = acro,
        agility = agility,
        fatigueRatio = fatigueRatio,
        maxHitDistance = lerp(cfg.MAX_VALID_HIT_XY_DISTANCE_MIN or cfg.MAX_VALID_HIT_XY_DISTANCE, cfg.MAX_VALID_HIT_XY_DISTANCE_MAX or cfg.MAX_VALID_HIT_XY_DISTANCE, competency),
        rayLostGrace = lerp(cfg.RAY_LOST_GRACE_SECONDS_MIN or cfg.RAY_LOST_GRACE_SECONDS, cfg.RAY_LOST_GRACE_SECONDS_MAX or cfg.RAY_LOST_GRACE_SECONDS, competency),
        stickyDrift = lerp(cfg.MAX_STICKY_XY_DRIFT_MIN or cfg.MAX_STICKY_XY_DRIFT, cfg.MAX_STICKY_XY_DRIFT_MAX or cfg.MAX_STICKY_XY_DRIFT, competency),
        driftDelay = lerp(cfg.DRIFT_DISMOUNT_AFTER_SECONDS_MIN or cfg.DRIFT_DISMOUNT_AFTER_SECONDS, cfg.DRIFT_DISMOUNT_AFTER_SECONDS_MAX or cfg.DRIFT_DISMOUNT_AFTER_SECONDS, competency),
    }

    return balanceCache
end

local function balanceSummary(balance)
    if not balance then
        return ''
    end
    return '; competency=' .. string.format('%.0f', (balance.competency or 0) * 100) .. '%'
        .. ' skill=' .. string.format('%.0f', (balance.skillCompetency or balance.competency or 0) * 100) .. '%'
        .. ' fatigue=' .. string.format('%.0f', (balance.fatigueRatio or 1) * 100) .. '%'
        .. ' acro=' .. string.format('%.0f', balance.acrobatics or 0)
        .. ' agi=' .. string.format('%.0f', balance.agility or 0)
        .. ' grace=' .. string.format('%.2f', balance.rayLostGrace or 0)
        .. ' drift=' .. string.format('%.0f', balance.stickyDrift or 0)
end

local function movementMagnitude()
    local c = self.controls
    if not c then
        return 0
    end
    return math.max(math.abs(c.movement or 0), math.abs(c.sideMovement or 0))
end

local function isActuallyMoving()
    return movementMagnitude() >= (cfg.ACROBATICS_XP_MIN_MOVEMENT or 0.15)
end

local function isSneakHeld()
    return self.controls and self.controls.sneak == true
end

local function resetDormantTimers()
    -- Force immediate scan when the player next enters sneak, but keep all heavier
    -- work dormant while not sneaking.
    inactiveScanSeconds = 999
    balanceCacheSeconds = 999
    balanceCheckSeconds = 0
    xpSeconds = 0
    debugSnapshotSeconds = 999
end

local function shouldRunAcquisitionScan(dt)
    if lockActive then
        return true
    end

    inactiveScanSeconds = inactiveScanSeconds + (dt or 0)
    if inactiveScanSeconds < (cfg.INACTIVE_SCAN_INTERVAL_SECONDS or 0.15) then
        return false
    end

    inactiveScanSeconds = 0
    return true
end

local function castAtOffset(offset, detector)
    local base = self.position + offset
    local from = base + v3(0, 0, cfg.SCAN_UP)
    local to = base + v3(0, 0, -cfg.SCAN_DOWN)
    local hit = nearby.castRenderingRay(from, to, { ignore = self })

    if hit and hit.hit and hit.hitObject and hit.hitPos then
        local ok, why = detector.isRopeObject(hit.hitObject)
        if ok then
            return hit, why
        end
    end

    return nil, nil
end

local function scan(detector, maxHitDistance)
    local offsets = common.sampleOffsets(cfg.SAMPLE_RADII or cfg.SAMPLE_RADIUS)
    local bestHit = nil
    local bestWhy = nil
    local bestDistance = 999999

    for _, offset in ipairs(offsets) do
        local hit, why = castAtOffset(offset, detector)
        if hit and hit.hitPos then
            local dist = xyDistance(self.position, hit.hitPos)
            if dist <= (maxHitDistance or cfg.MAX_VALID_HIT_XY_DISTANCE) and dist < bestDistance then
                bestHit = hit
                bestWhy = why
                bestDistance = dist
            end
        end
    end

    return bestHit, bestWhy, bestDistance
end

local function showPlayerMessage(message)
    if not cfg.SHOW_FALL_MESSAGES or not message or message == '' then
        return
    end
    if messageCooldown > 0 then
        return
    end
    messageCooldown = cfg.MESSAGE_COOLDOWN_SECONDS or 1.25
    pcall(function()
        ui.showMessage(message)
    end)
end

local function showMountFailMessage(message)
    if cfg.SHOW_MOUNT_FAIL_MESSAGES == false then
        return
    end
    showPlayerMessage(message)
end

local function mountSuccessChance(balance)
    local competency = clamp(balance and balance.competency or 0, 0, 1)
    local zero = cfg.MOUNT_COMPETENCY_ZERO or 0.12
    local full = cfg.MOUNT_COMPETENCY_FULL or 0.65
    local span = full - zero
    if span <= 0 then
        span = 0.01
    end

    local t = clamp((competency - zero) / span, 0, 1)
    local curve = cfg.MOUNT_SUCCESS_CURVE or 0.55
    if curve <= 0 then
        curve = 1
    end

    local minChance = cfg.MOUNT_SUCCESS_CHANCE_MIN or 0.005
    local maxChance = cfg.MOUNT_SUCCESS_CHANCE_MAX or 0.985
    return clamp(lerp(minChance, maxChance, (t ^ curve)), 0, 1)
end

local function startingFailureCause(balance)
    if not balance then
        return 'skill'
    end

    local acro = tonumber(balance.acrobatics) or 0
    local agility = tonumber(balance.agility) or 0
    local fatigueMissing = 1 - clamp(balance.fatigueRatio or 1, 0, 1)

    if fatigueMissing >= 0.35 then
        return 'fatigue'
    end
    if acro < 20 and agility < 20 then
        return 'skill'
    end
    if acro < 20 and acro + 10 < agility then
        return 'acrobatics'
    end
    if agility < 20 and agility + 10 < acro then
        return 'agility'
    end
    return 'skill'
end

local function mountFailureMessage(cause, balance)
    local acro = balance and tonumber(balance.acrobatics) or nil
    local agility = balance and tonumber(balance.agility) or nil

    if cause == 'fatigue' then
        return tr('MessageMountFailFatigue')
    end
    if cause == 'acrobatics' then
        return tr('MessageMountFailAcrobatics')
    end
    if cause == 'agility' then
        return tr('MessageMountFailAgility')
    end
    if acro and agility and acro < 20 and agility < 20 then
        return tr('MessageMountFailBothLow')
    end
    return tr('MessageMountFailGeneric')
end

local function maybeFailMount(balance)
    if not cfg.MOUNT_FAILURE_ENABLED or lockActive then
        return false
    end

    local chance = mountSuccessChance(balance)
    local roll = math.random()
    local failed = roll > chance
    local cause = failed and startingFailureCause(balance) or 'none'

    if settings.logMountRolls() then
        log('mount roll=' .. string.format('%.3f', roll)
            .. ' success=' .. string.format('%.3f', chance)
            .. ' outcome=' .. (failed and ('failed:' .. tostring(cause)) or 'success')
            .. balanceSummary(balance))
    elseif failed and settings.logStateChanges() then
        log('mount failed: ' .. tostring(cause)
            .. '; roll=' .. string.format('%.3f', roll)
            .. ' success=' .. string.format('%.3f', chance)
            .. balanceSummary(balance))
    end

    if not failed then
        return false
    end
    showMountFailMessage(mountFailureMessage(cause, balance))
    balanceReacquireSuppression = cfg.MOUNT_RETRY_SUPPRESSION_SECONDS or 0.65
    return true
end

local function resetLockState()
    lockActive = false
    rayWasVisible = false
    rayLostLogged = false
    lastReason = nil
    lastRope = nil
    lastHitPos = nil
    lockSeconds = 0
    lostSeconds = 0
    balanceCheckSeconds = 0
    xpSeconds = 0
    debugSnapshotSeconds = 999
end

local function sendStop(reason, playerMessage)
    if lockActive then
        core.sendGlobalEvent('SlyRopes_StopCollision', { player = self, reason = reason })
        if settings.logStateChanges() then
            log('inactive: ' .. tostring(reason))
        end
        showPlayerMessage(playerMessage)
    end
    resetLockState()
end

local function applyControlOptions()
    if cfg.FORCE_WALK then
        self.controls.run = false
    end
    if cfg.ZERO_STRAFE then
        self.controls.sideMovement = 0
    end
    if cfg.BLOCK_JUMP then
        self.controls.jump = false
    end
end

local function supportFromLastHitOrPlayer()
    if lastHitPos then
        return lastHitPos
    end
    return v3(self.position.x, self.position.y, self.position.z)
end

local function sendMove(label, reason, hit, usingSticky, hitDistance)
    if elapsedSinceSend < cfg.SEND_INTERVAL then
        return
    end
    elapsedSinceSend = 0

    local supportPos
    if hit and hit.hitPos then
        supportPos = hit.hitPos
    else
        supportPos = supportFromLastHitOrPlayer()
    end

    core.sendGlobalEvent('SlyRopes_MoveCollision', {
        player = self,
        rope = lastRope,
        hitPos = hit and hit.hitPos or supportPos,
        supportPos = supportPos,
        reason = reason,
        detector = label,
        sticky = usingSticky == true,
        hitDistance = hitDistance,
    })
end

local function tryAwardAcrobaticsXP(dt, isSticky)
    if not cfg.ACROBATICS_XP_ENABLED or isSticky then
        return
    end
    if not isActuallyMoving() then
        xpSeconds = 0
        return
    end

    xpSeconds = xpSeconds + dt
    if xpSeconds < (cfg.ACROBATICS_XP_INTERVAL_SECONDS or 1.0) then
        return
    end
    xpSeconds = 0

    local skillProgression = I and I.SkillProgression
    if not skillProgression or type(skillProgression.skillUsed) ~= 'function' then
        if settings.debugEnabled() and not xpFallbackLogged then
            log('SkillProgression interface unavailable; Acrobatics tightrope XP disabled')
            xpFallbackLogged = true
        end
        return
    end

    local jumpUseType = skillProgression.SKILL_USE_TYPES and skillProgression.SKILL_USE_TYPES.Acrobatics_Jump or 0
    local ok, err = pcall(function()
        skillProgression.skillUsed('acrobatics', {
            useType = jumpUseType,
            scale = cfg.ACROBATICS_XP_SCALE or 0.12,
            source = 'slyropes_tightrope_walk',
        })
    end)

    if settings.logXpTicks() then
        if ok then
            log('Acrobatics XP tick: scale=' .. tostring(cfg.ACROBATICS_XP_SCALE or 0.12))
        else
            log('Acrobatics XP tick failed: ' .. tostring(err))
        end
    end
end

local function fallMessageFromCause(cause, balance)
    if cause == 'jump' then
        return tr('MessageFallJump')
    end
    if cause == 'fatigue' then
        return tr('MessageFallFatigue')
    end
    if cause == 'acrobatics' then
        return tr('MessageFallAcrobatics')
    end
    if cause == 'agility' then
        return tr('MessageFallAgility')
    end
    if cfg.SHOW_SKILL_FALL_MESSAGES and balance then
        return tr('MessageFallSkill')
    end
    return tr('MessageFallGeneric')
end

local function queueFallMessage(reason, message)
    pendingFallReason = reason
    pendingFallMessage = message
    pendingFallStartZ = self.position and self.position.z or nil
end

local function clearPendingFallMessage()
    pendingFallReason = nil
    pendingFallMessage = nil
    pendingFallStartZ = nil
end

local function flushPendingFallMessageIfRealFall()
    if not pendingFallMessage then
        return
    end

    local startZ = pendingFallStartZ
    local currentZ = self.position and self.position.z or startZ
    local drop = 0
    if startZ and currentZ then
        drop = startZ - currentZ
    end

    if drop >= (cfg.BALANCE_MESSAGE_MIN_FALL_Z or 0) then
        showPlayerMessage(pendingFallMessage)
    elseif settings.logBalanceRolls() then
        log('suppressed balance message; no actual fall observed after ' .. tostring(pendingFallReason))
    end

    clearPendingFallMessage()
end

local function balanceRisk(balance, hitDistance)
    if cfg.BALANCE_REQUIRE_MOVING and not isActuallyMoving() then
        return 0, 'skill', {
            risk = 0,
            skillMissing = 0,
            fatigueMissing = 0,
        }
    end

    local c = self.controls or {}
    local skillCompetency = clamp(balance.skillCompetency or balance.competency or 0, 0, 1)
    local effectiveCompetency = clamp(balance.competency or skillCompetency, 0, 1)
    local skillMissing = 1 - skillCompetency
    local fatigueMissing = 1 - clamp(balance.fatigueRatio or 1, 0, 1)

    local lowAcroThreshold = cfg.BALANCE_LOW_ACROBATICS_THRESHOLD or 40
    local acro = tonumber(balance.acrobatics) or lowAcroThreshold
    local lowAcroMissing = 0
    if lowAcroThreshold > 0 and acro < lowAcroThreshold then
        lowAcroMissing = clamp((lowAcroThreshold - acro) / lowAcroThreshold, 0, 1)
    end

    -- A strong single stat should be enough for mostly reliable rope walking.
    -- Low Acrobatics remains dangerous only when neither Acrobatics nor Agility is strong.
    local bestStat = math.max(tonumber(balance.acrobatics) or 0, tonumber(balance.agility) or 0)
    local compensationStart = cfg.BALANCE_LOW_STAT_COMPENSATION_START or 40
    local compensationEnd = cfg.BALANCE_LOW_STAT_COMPENSATION_END or 60
    local compensationSpan = compensationEnd - compensationStart
    if compensationSpan <= 0 then
        compensationSpan = 1
    end
    local compensation = clamp((bestStat - compensationStart) / compensationSpan, 0, 1)
    local compensatedMult = cfg.BALANCE_LOW_STAT_COMPENSATED_MULT or 0.08
    local lowAcroRiskMult = lerp(1.0, compensatedMult, compensation)

    local risk = cfg.BALANCE_BASE_RISK or 0
    risk = risk + ((skillMissing * skillMissing) * (cfg.BALANCE_SKILL_DEFICIT_RISK or 0))
    risk = risk + ((lowAcroMissing * lowAcroMissing) * (cfg.BALANCE_LOW_ACROBATICS_RISK or 0) * lowAcroRiskMult)
    risk = risk + ((fatigueMissing * fatigueMissing) * (cfg.BALANCE_LOW_FATIGUE_RISK or 0))

    if c.jump then
        risk = risk + (cfg.BALANCE_JUMP_RISK or 0)
    end

    -- Competency reduces only skill/fatigue failure rate. Movement input is deliberately ignored here.
    local mitigation = lerp(cfg.BALANCE_COMPETENCY_MITIGATION_LOW or 1.10, cfg.BALANCE_COMPETENCY_MITIGATION_HIGH or 0.12, effectiveCompetency)
    local failChance = clamp(risk * mitigation, cfg.BALANCE_FAIL_CHANCE_MIN or 0, cfg.BALANCE_FAIL_CHANCE_MAX or 0.22)

    local cause = 'skill'
    if c.jump then
        cause = 'jump'
    elseif fatigueMissing >= 0.35 and fatigueMissing >= (skillMissing * 0.75) then
        cause = 'fatigue'
    elseif (balance.acrobatics or 100) <= ((balance.agility or 100) - 5) then
        cause = 'acrobatics'
    elseif (balance.agility or 100) < ((balance.acrobatics or 100) - 5) then
        cause = 'agility'
    else
        cause = 'skill'
    end

    return failChance, cause, {
        risk = risk,
        skillMissing = skillMissing,
        lowAcroMissing = lowAcroMissing,
        fatigueMissing = fatigueMissing,
        effectiveCompetency = effectiveCompetency,
    }
end

local function maybeLogSkillSnapshot(dt, balance, hitDistance, phase)
    if not settings.logSkillSnapshots() or not balance then
        return
    end

    debugSnapshotSeconds = debugSnapshotSeconds + (dt or 0)
    if debugSnapshotSeconds < settings.skillSnapshotInterval() then
        return
    end
    debugSnapshotSeconds = 0

    local failChance, cause, detail = balanceRisk(balance, hitDistance)
    local mountChance = mountSuccessChance(balance)
    local distanceText = 'nil'
    if hitDistance ~= nil then
        distanceText = string.format('%.1f', hitDistance)
    end

    log('skill snapshot phase=' .. tostring(phase)
        .. ' mountSuccess=' .. string.format('%.3f', mountChance)
        .. ' balanceFail=' .. string.format('%.3f', failChance)
        .. ' cause=' .. tostring(cause)
        .. ' risk=' .. string.format('%.3f', detail.risk or 0)
        .. ' skillMissing=' .. string.format('%.2f', detail.skillMissing or 0)
        .. ' lowAcroMissing=' .. string.format('%.2f', detail.lowAcroMissing or 0)
        .. ' fatigueMissing=' .. string.format('%.2f', detail.fatigueMissing or 0)
        .. ' movement=' .. string.format('%.2f', movementMagnitude())
        .. ' hitDistance=' .. distanceText
        .. ' maxHitDistance=' .. string.format('%.1f', balance.maxHitDistance or 0)
        .. balanceSummary(balance))
end

local function maybeFailBalance(dt, balance, hitDistance)
    if not cfg.BALANCE_FAILURE_ENABLED or not lockActive then
        return false
    end

    balanceCheckSeconds = balanceCheckSeconds + dt
    if balanceCheckSeconds < (cfg.BALANCE_CHECK_INTERVAL_SECONDS or 0.4) then
        return false
    end
    balanceCheckSeconds = 0

    local failChance, cause, detail = balanceRisk(balance, hitDistance)
    local roll = math.random()

    if settings.logBalanceRolls() then
        log('balance roll=' .. string.format('%.3f', roll)
            .. ' fail=' .. string.format('%.3f', failChance)
            .. ' cause=' .. tostring(cause)
            .. ' skillMissing=' .. string.format('%.2f', detail.skillMissing or 0)
            .. ' lowAcroMissing=' .. string.format('%.2f', detail.lowAcroMissing or 0)
            .. ' fatigueMissing=' .. string.format('%.2f', detail.fatigueMissing or 0)
            .. balanceSummary(balance))
    end

    if roll < failChance then
        local reason = 'lost balance: ' .. tostring(cause)
        queueFallMessage(reason, fallMessageFromCause(cause, balance))
        sendStop(reason, nil)
        balanceReacquireSuppression = cfg.BALANCE_REACQUIRE_SUPPRESSION_SECONDS or 0.85
        return true
    end

    return false
end

function M.makeOnFrame(detector, label)
    return function(dt)
        settingsRefreshSeconds = settingsRefreshSeconds + dt
        if settingsRefreshSeconds >= 0.25 then
            if not settings.isRegistered() then
                settings.register('player-frame-retry')
            end
            settings.refresh()
            settingsRefreshSeconds = 0
        end

        elapsedSinceSend = elapsedSinceSend + dt
        if messageCooldown > 0 then
            messageCooldown = math.max(0, messageCooldown - dt)
        end

        -- Hard performance gate: outside sneak, this script is dormant except for this
        -- cheap controls check and cleanup if a rope helper was previously active.
        if cfg.REQUIRE_SNEAK_FOR_DETECTION ~= false and not isSneakHeld() then
            clearPendingFallMessage()
            balanceReacquireSuppression = 0
            resetDormantTimers()
            sendStop('sneak released')
            return
        end

        if balanceReacquireSuppression > 0 then
            balanceReacquireSuppression = math.max(0, balanceReacquireSuppression - dt)
            if balanceReacquireSuppression <= 0 then
                flushPendingFallMessageIfRealFall()
            end
            return
        end

        if not shouldRunAcquisitionScan(dt) then
            return
        end

        applyControlOptions()

        local balance = currentBalance(dt)
        local hit, why, hitDistance = scan(detector, balance.maxHitDistance)
        maybeLogSkillSnapshot(dt, balance, hitDistance, hit and (lockActive and 'active-hit' or 'mount-hit') or (lockActive and 'active-sticky' or 'scan-miss'))

        if hit then
            if not lockActive and maybeFailMount(balance) then
                return
            end

            lastRope = hit.hitObject
            lastHitPos = hit.hitPos
            lostSeconds = 0
            lockSeconds = 0
            rayLostLogged = false

            if maybeFailBalance(dt, balance, hitDistance) then
                return
            end

            if (not lockActive) or why ~= lastReason or not rayWasVisible then
                if settings.logStateChanges() then
                    log('active via ' .. tostring(label) .. ': ' .. tostring(why) .. '; distance=' .. string.format('%.1f', hitDistance or 0) .. balanceSummary(balance) .. '; ' .. common.objectSummary(hit.hitObject))
                end
            end

            lockActive = true
            rayWasVisible = true
            lastReason = why
            tryAwardAcrobaticsXP(dt, false)
            sendMove(label, why, hit, false, hitDistance)
            return
        end

        if not lockActive then
            return
        end

        lostSeconds = lostSeconds + dt
        lockSeconds = lockSeconds + dt

        local drift = xyDistance(self.position, lastHitPos)
        if drift > (balance.stickyDrift or cfg.MAX_STICKY_XY_DRIFT) and lostSeconds >= (balance.driftDelay or cfg.DRIFT_DISMOUNT_AFTER_SECONDS or 0) then
            sendStop('left rope', cfg.SHOW_OFF_ROPE_MESSAGES and tr('MessageStepTooFar') or nil)
            return
        end

        if lostSeconds > (balance.rayLostGrace or cfg.RAY_LOST_GRACE_SECONDS) then
            sendStop('rope lost / off rope', cfg.SHOW_OFF_ROPE_MESSAGES and tr('MessageLoseContact') or nil)
            return
        end

        if lockSeconds > cfg.MAX_LOCK_SECONDS then
            sendStop('rope lock timeout')
            return
        end

        if settings.logStateChanges() and cfg.LOG_RAY_LOST_TRANSITIONS and rayWasVisible and not rayLostLogged then
            log('rope ray lost; holding last local rope patch briefly while sneaking')
            rayLostLogged = true
        end
        rayWasVisible = false

        sendMove(label, lastReason or 'local sticky rope patch', nil, true, nil)
    end
end

local function registerSettingsForCurrentSession(source)
    settings.register(source)
    settings.refresh()
end

function M.makeHandlers(detector, label)
    return {
        onInit = function()
            registerSettingsForCurrentSession('player-init')
            log(label .. ' detector loaded; v0.20 release hygiene; no levitation and no player teleport; API revision ' .. tostring(core.API_REVISION))
        end,
        onLoad = function()
            -- Existing saves call onLoad, not necessarily onInit. Register here too,
            -- and retry from onFrame until OpenMW exposes the Settings interface.
            registerSettingsForCurrentSession('player-load')
        end,
        onFrame = M.makeOnFrame(detector, label),
        onSave = function()
            core.sendGlobalEvent('SlyRopes_StopCollision', { player = self, reason = 'save cleanup' })
            return {}
        end,
    }
end

return M
