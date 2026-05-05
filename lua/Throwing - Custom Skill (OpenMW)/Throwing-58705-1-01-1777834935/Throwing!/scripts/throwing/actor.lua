local core = require('openmw.core')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local self = require('openmw.self')
local types = require('openmw.types')

local config = require('scripts.throwing.config')

local runtimeSection = storage.globalSection('Runtime_Throwing')

local function featureEnabled(key, default)
    local value = runtimeSection:get(key)
    if value == nil then return default end
    return value
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

local function getThrownWeaponDamageRange(recordId)
    if not recordId then return nil end
    local record = types.Weapon.records[recordId]
    if not record then return nil end

    local minDamage = math.max(
        tonumber(record.chopMinDamage) or 0,
        tonumber(record.slashMinDamage) or 0,
        tonumber(record.thrustMinDamage) or 0
    )
    local maxDamage = math.max(
        tonumber(record.chopMaxDamage) or 0,
        tonumber(record.slashMaxDamage) or 0,
        tonumber(record.thrustMaxDamage) or 0
    )

    if maxDamage <= 0 then return nil end
    if minDamage > maxDamage then
        minDamage, maxDamage = maxDamage, minDamage
    end

    return minDamage, maxDamage
end

local function getThrowChargeProfile(strength, skill, weight)
    local chargeStrength = clamp(tonumber(strength) or 0, 0, 1)
    local heavyT = clamp(
        ((weight or 0) - config.combat.lightWeightThreshold) /
        math.max(0.001, config.combat.heavyWeightThreshold - config.combat.lightWeightThreshold),
        0,
        1
    )
    local floor = lerp(
        config.combat.quickThrowDamageFloorLight,
        config.combat.quickThrowDamageFloorHeavy,
        heavyT
    )
    floor = floor + clamp((skill or 0) / 100, 0, 1) * config.combat.quickThrowDamageFloorSkillBonusAt100
    local fullCap = clamp(config.combat.throwFullChargeCap or 0.85, 0.05, 1.0)
    floor = clamp(floor, 0, fullCap - 0.01)

    local curvedStrength = floor + (fullCap - floor) * math.pow(chargeStrength, config.combat.throwChargeExponent)
    return clamp(curvedStrength, 0, 1), chargeStrength, floor
end

local function getThrownBaseDamage(recordId, strength, skill, weight)
    local minDamage, maxDamage = getThrownWeaponDamageRange(recordId)
    if not minDamage or not maxDamage then return nil end

    local effectiveStrength, rawStrength, floor = getThrowChargeProfile(strength, skill, weight)
    return lerp(minDamage, maxDamage, effectiveStrength), {
        rawStrength = rawStrength,
        effectiveStrength = effectiveStrength,
        floor = floor,
        minDamage = minDamage,
        maxDamage = maxDamage,
    }
end

local function getRecentPendingThrow()
    local active = runtimeSection:get('active')
    local recordId = runtimeSection:get('recordId')
    local releasedAt = runtimeSection:get('releasedAt')
    if not active or not recordId or releasedAt == nil then return nil end

    local age = core.getSimulationTime() - releasedAt
    if age > config.pendingWindow then
        return nil
    end

    return {
        token = runtimeSection:get('token'),
        recordId = recordId,
        weight = runtimeSection:get('weight') or 0,
        throwingSkill = runtimeSection:get('throwingSkill') or config.startLevel,
        effectiveSkill = runtimeSection:get('effectiveSkill') or config.startLevel,
        strength = runtimeSection:get('strength') or 0,
        age = age,
    }
end

local function getSkillT(skill, unlock)
    return clamp((skill - unlock) / math.max(1, 100 - unlock), 0, 1)
end

local function criticalChance(skill)
    local p = config.perks.critical
    if skill < p.level then return 0 end
    return p.chance or 0.05
end

local function twinFlightChance(skill)
    local p = config.perks.twinFlight
    return lerp(p.chanceAtUnlock, p.chanceAt100, getSkillT(skill, p.level))
end

local function bleedChance(skill)
    local p = config.perks.bleed
    return lerp(p.chanceAtUnlock, p.chanceAt100, getSkillT(skill, p.level))
end

local function paralyzeChance(skill)
    local p = config.perks.paralyze
    return lerp(p.chanceAtUnlock, p.chanceAt100, getSkillT(skill, p.level))
end

local function paralyzeDuration(skill)
    local p = config.perks.paralyze
    return p.baseDuration + math.floor(lerp(0, p.bonusDurationAt100, getSkillT(skill, p.level)))
end

local function shortRangeDamageBonus(distance)
    if distance == nil then return 0 end
    local full = config.combat.shortRangeFullDistance
    local maxd = config.combat.shortRangeMaxDistance
    if distance <= full then
        return config.combat.shortRangeBonusAtFull
    end
    if distance >= maxd then
        return 0
    end
    local t = 1 - ((distance - full) / math.max(1, maxd - full))
    return config.combat.shortRangeBonusAtFull * clamp(t, 0, 1)
end

local function getHitDistance(attack)
    if not attack or not attack.attacker then return nil end
    local impactPos = attack.hitPos or self.position
    if not impactPos or not attack.attacker.position then return nil end
    return (impactPos - attack.attacker.position):length()
end

local function damageMultiplier(skill, strength, weight)
    local skillBonus = (skill / 100) * config.combat.skillDamageBonusAt100
    local strengthBonus = (strength / 100) * config.combat.strengthDamageBonusAt100

    local heavyT = clamp(
        (weight - config.combat.lightWeightThreshold) /
        math.max(0.001, config.combat.heavyWeightThreshold - config.combat.lightWeightThreshold),
        0,
        1
    )
    local strengthT = clamp(strength / 100, 0, 1)
    local weightPenalty = heavyT * lerp(
        config.combat.heavyWeightPenaltyAt0Strength,
        config.combat.heavyWeightPenaltyAt100Strength,
        strengthT
    )

    return math.max(0.65, 1.0 + skillBonus + strengthBonus - weightPenalty)
end

local function onHit(attack)
    if not featureEnabled('enabled', true) then return end
    if not attack or attack.successful == false then return end
    if not attack.attacker or not types.Player.objectIsInstance(attack.attacker) then return end
    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Ranged then return end
    if not attack.damage or type(attack.damage.health) ~= 'number' then return end

    local pending = getRecentPendingThrow()
    if not pending then return end

    local throwingSkill = pending.throwingSkill
    local strength = pending.strength
    local weight = pending.weight

    local distance = getHitDistance(attack)
    local shortRangeBonus = 0
    if featureEnabled('shortRangeBonusEnabled', true) then
        shortRangeBonus = shortRangeDamageBonus(distance)
    end

    local damageSource = tonumber(attack.damage.health) or 0
    local throwProfile = nil
    local customBaseDamage, profile = getThrownBaseDamage(pending.recordId, attack.strength, throwingSkill, weight)
    if customBaseDamage then
        damageSource = math.max(damageSource, customBaseDamage)
        throwProfile = profile
    end

    local damage = damageSource * damageMultiplier(throwingSkill, strength, weight)
    damage = damage * (1 + shortRangeBonus)

    local procTwin = false
    local procCrit = false
    local procBleed = false
    local procParalyze = false

    if featureEnabled('criticalEnabled', true)
        and throwingSkill >= config.perks.critical.level
        and math.random() <= criticalChance(throwingSkill) then
        damage = damage * config.perks.critical.damageMultiplier
        procCrit = true
    end

    if featureEnabled('twinFlightEnabled', true)
        and throwingSkill >= config.perks.twinFlight.level
        and math.random() <= twinFlightChance(throwingSkill) then
        damage = damage * config.perks.twinFlight.damageMultiplier
        procTwin = true
    end

    if procCrit and config.perks.critical.sound then
        self:sendEvent('PlaySound3d', { sound = config.perks.critical.sound })
    end

    if procTwin and config.perks.twinFlight.extraHitSound then
        core.sendGlobalEvent('Throwing_PlayDelayedSound', {
            target = self,
            sound = config.perks.twinFlight.extraHitSound,
            delay = config.perks.twinFlight.extraHitDelay or 0.20,
        })
    end

    attack.damage.health = damage

    if featureEnabled('bleedEnabled', true)
        and throwingSkill >= config.perks.bleed.level
        and math.random() <= bleedChance(throwingSkill) then
        core.sendGlobalEvent('Throwing_ApplyBleed', {
            target = self,
            attacker = attack.attacker,
            duration = config.perks.bleed.duration,
            magnitudeMin = config.perks.bleed.magnitudeMin,
            magnitudeMax = config.perks.bleed.magnitudeMax,
        })
        procBleed = true
        if config.perks.bleed.sound then
            self:sendEvent('PlaySound3d', { sound = config.perks.bleed.sound })
        end
    end

    if featureEnabled('paralyzeEnabled', true)
        and throwingSkill >= config.perks.paralyze.level
        and math.random() <= paralyzeChance(throwingSkill) then
        core.sendGlobalEvent('Throwing_ApplyParalyze', {
            target = self,
            attacker = attack.attacker,
            duration = paralyzeDuration(throwingSkill),
        })
        procParalyze = true
    end

    attack.attacker:sendEvent('Throwing_ResolvedHit', {
        token = pending.token,
        weaponRecordId = pending.recordId,
        weight = weight,
        throwingSkill = throwingSkill,
        didCrit = procCrit,
        procTwin = procTwin,
        procBleed = procBleed,
        procParalyze = procParalyze,
        damage = damage,
        distance = distance,
        shortRangeBonus = shortRangeBonus,
        chargeStrength = throwProfile and throwProfile.rawStrength or attack.strength,
        effectiveChargeStrength = throwProfile and throwProfile.effectiveStrength or attack.strength,
        quickThrowFloor = throwProfile and throwProfile.floor or nil,
        damageRangeMin = throwProfile and throwProfile.minDamage or nil,
        damageRangeMax = throwProfile and throwProfile.maxDamage or nil,
        baseDamageSource = damageSource,
    })
end

return {
    eventHandlers = {
        Hit = onHit,
    },
}
