local types = require("openmw.types")
local self = require("openmw.self")

-- =========================
-- CONFIG
-- =========================
local HEALTH_MIN = 0.002
local HEALTH_MAX = 0.01

local MAGICKA_MIN = 0.005
local MAGICKA_MAX = 0.01

local REGEN_MULT = 0.5
local MAGICKA_DROP_THRESHOLD = 1

-- DAMAGE / CAST BEHAVIOUR
local DAMAGE_PAUSE = 5
local CAST_PAUSE = 5

local DAMAGE_RAMP_DURATION = 30
local CAST_RAMP_DURATION = 30

-- OUT OF COMBAT BONUS
local OOC_RAMP_DURATION = 30
local OOC_MAX_MULT = 2.0

-- FATIGUE BREAKPOINT
local NEAR_FULL_FATIGUE_THRESHOLD = 0.999
local NEAR_FULL_FATIGUE_MULT = 0.5

local DEBUG = true
local DEBUG_INTERVAL = 2.0

-- =========================
-- STATE
-- =========================
local lastHealth = nil
local lastMagicka = nil
local damageTimer = 0
local castTimer = 0
local debugTimer = 0
local oocTimer = 0

-- =========================
-- HELPERS
-- =========================
local function debugPrint(msg)
    if DEBUG then
        print("[RegenDebug] " .. msg)
    end
end

local function getFatiguePercent()
    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    if fatigue.base <= 0 then return 0 end
    return fatigue.current / fatigue.base
end

local function getRegenRate(min, max, fatiguePct)
    fatiguePct = math.max(0, math.min(1, fatiguePct))
    return min + (max - min) * (fatiguePct ^ 2)
end

local function hasStuntedMagicka()
    local effects = types.Actor.activeEffects(self)
    for _, effect in pairs(effects) do
        if effect.id == "stunted_magicka" or effect.id == "stuntedmagicka" then
            return true
        end
    end
    return false
end

local function toPercent(rate)
    return rate * 100
end

-- DAMAGE / CAST RAMP
local function getRampMultiplier(timer, duration)
    if timer <= 0 then return 1 end
    local t = 1 - (timer / duration)
    return REGEN_MULT + (1 - REGEN_MULT) * t
end

-- OUT OF COMBAT RAMP
local function getOOCMultiplier(fatiguePct, dt)
    if fatiguePct >= NEAR_FULL_FATIGUE_THRESHOLD then
        oocTimer = math.min(oocTimer + dt, OOC_RAMP_DURATION)
    else
        oocTimer = 0
        return 1
    end

    local t = oocTimer / OOC_RAMP_DURATION
    return 1 + (OOC_MAX_MULT - 1) * t
end

-- FATIGUE BREAKPOINT PENALTY
local function getNearFullFatigueMultiplier(fatiguePct)
    if fatiguePct >= NEAR_FULL_FATIGUE_THRESHOLD then
        return 1
    else
        return NEAR_FULL_FATIGUE_MULT
    end
end

-- =========================
-- MAIN
-- =========================
return {
    engineHandlers = {
        onUpdate = function(dt)

            local health = types.Actor.stats.dynamic.health(self)
            local magicka = types.Actor.stats.dynamic.magicka(self)

            if not lastHealth then
                lastHealth = health.current
                lastMagicka = magicka.current
                debugPrint("Initialised")
                return
            end

            local fatiguePct = getFatiguePercent()
            local oocMult = getOOCMultiplier(fatiguePct, dt)
            local nearFullMult = getNearFullFatigueMultiplier(fatiguePct)

            -- BASE RATES
            local baseHealthRate = getRegenRate(HEALTH_MIN, HEALTH_MAX, fatiguePct) * oocMult * nearFullMult
            local baseMagickaRate = getRegenRate(MAGICKA_MIN, MAGICKA_MAX, fatiguePct) * oocMult * nearFullMult

            -- DAMAGE DETECTION
            if health.current < lastHealth then
                damageTimer = DAMAGE_PAUSE + DAMAGE_RAMP_DURATION

                local reduced = baseHealthRate * REGEN_MULT
                debugPrint(string.format(
                    "Damage → HP regen %.2f%% → %.2f%%",
                    toPercent(baseHealthRate),
                    toPercent(reduced)
                ))
            end
            lastHealth = health.current

            -- MAGICKA DROP DETECTION
            local magickaDrop = lastMagicka - magicka.current
            if magickaDrop > MAGICKA_DROP_THRESHOLD then
                castTimer = CAST_PAUSE + CAST_RAMP_DURATION

                local reduced = baseMagickaRate * REGEN_MULT
                debugPrint(string.format(
                    "Cast → MP regen %.2f%% → %.2f%% (drop %.1f)",
                    toPercent(baseMagickaRate),
                    toPercent(reduced),
                    magickaDrop
                ))
            end
            lastMagicka = magicka.current

            -- TIMERS
            if damageTimer > 0 then
                damageTimer = damageTimer - dt
            end

            if castTimer > 0 then
                castTimer = castTimer - dt
            end

            -- =========================
            -- HEALTH REGEN
            -- =========================
            local healthRate = baseHealthRate

            if damageTimer > 0 then
                if damageTimer > DAMAGE_RAMP_DURATION then
                    healthRate = 0
                else
                    healthRate = healthRate * getRampMultiplier(damageTimer, DAMAGE_RAMP_DURATION)
                end
            end

            local healthGain = health.base * healthRate * dt
            local newHealth = math.min(health.current + healthGain, health.base)
            types.Actor.stats.dynamic.health(self).current = newHealth

            -- =========================
            -- MAGICKA REGEN
            -- =========================
            local magickaRate = 0

            if not hasStuntedMagicka() then
                magickaRate = baseMagickaRate

                if castTimer > 0 then
                    if castTimer > CAST_RAMP_DURATION then
                        magickaRate = 0
                    else
                        magickaRate = magickaRate * getRampMultiplier(castTimer, CAST_RAMP_DURATION)
                    end
                end

                local magickaGain = magicka.base * magickaRate * dt
                local newMagicka = math.min(magicka.current + magickaGain, magicka.base)
                types.Actor.stats.dynamic.magicka(self).current = newMagicka
            end

            -- =========================
            -- DEBUG
            -- =========================
            debugTimer = debugTimer + dt
            if DEBUG and debugTimer >= DEBUG_INTERVAL then
                debugTimer = 0

                debugPrint(string.format(
                    "HP regen: %.2f%% | MP regen: %.2f%% | dmgT: %.1f | castT: %.1f | OOC: %.2fx | fatigue: %.3f",
                    toPercent(healthRate),
                    toPercent(magickaRate),
                    damageTimer,
                    castTimer,
                    oocMult,
                    fatiguePct
                ))
            end
        end
    }
}