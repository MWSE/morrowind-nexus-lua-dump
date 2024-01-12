local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI
local input = require('openmw.input')

local regenAmount = 0
local maxRegenerableMagicka = 0
local positiveModifier = 0
local negativeModifier = 1


local settings = {
    base = storage.playerSection('NMRSettingsA'),
    addons = storage.playerSection('NMRSettingsB'),
}

local fatiguePenalties = {
    { threshold = 20, multiplier = 0.5},
    { threshold = 40, multiplier = 0.7},
    { threshold = 60, multiplier = 0.8},
    { threshold = 80, multiplier = 0.9},
}

local tick_time = 0.1
local tick_timer = 0

local SECOND = 1

local function calcPositives()
    return positiveModifier
end

local function calcNegatives()
    return negativeModifier
end

local function calculateMax()
    local current = types.Actor.stats.dynamic.magicka(self).current
    local max = types.Actor.stats.dynamic.magicka(self).base

    local maxRegenPercent = settings.base:get('NMRMaxRegenPercentage')
    maxRegenPercent = math.min(maxRegenPercent + (I.NMR_ART.getArtifactBonuses().regenPercent * 100), 100)
    print(maxRegenPercent)
    local maxRegenAmount = maxRegenPercent / 100
    maxRegenerableMagicka = max * maxRegenAmount
    return maxRegenerableMagicka

end

local function calculateBase(tick_time)
    local current = types.Actor.stats.dynamic.magicka(self).current
    local max = types.Actor.stats.dynamic.magicka(self).base
    local isIntelligence = settings.addons:get('NMRIntRegen')
    local regenStat

    -- checking if we should calculate regeneration speed on Intelligence or Willpower based on user setting
    if settings.addons:get('NMRIntRegen') then
        regenStat = types.Actor.stats.attributes.intelligence(self).modified
    else
        regenStat = types.Actor.stats.attributes.willpower(self).modified
    end

    if regenStat <= 0 or current >= max or settings.base:get('NMRisActive') == false then
        --print('Что-то происходит')
        return
    end

    local BASE_REGEN_TIME = settings.base:get('NMRbaseRegenTime')
    --print(BASE_REGEN_TIME)
    local FAST_REGEN_TIME = settings.base:get('NMRfastRegenTime')
    --print(FAST_REGEN_TIME)

    local regenTime = ((BASE_REGEN_TIME - FAST_REGEN_TIME) / 99) * (100 - regenStat) + FAST_REGEN_TIME

    if regenTime < FAST_REGEN_TIME then
        regenTime = FAST_REGEN_TIME
    end

    if regenTime > BASE_REGEN_TIME then
        regenTime = BASE_REGEN_TIME
    end
    --print(regenTime)
    local regenPercent = (tick_time / SECOND) / regenTime
    regenAmount = max * regenPercent
    return regenAmount
end

local function calculatePositives()
    positiveModifier = 0
    local current = types.Actor.stats.dynamic.magicka(self).current
    local max = types.Actor.stats.dynamic.magicka(self).base

    local artifactThreshold = I.NMR_ART.getArtifactBonuses().lowMultThresh
    if I.NMR_ART.getArtifactBonuses().lowMultThresh ~= 0 then
        if current < max * artifactThreshold then
            local lowMagickaArtMult = I.NMR_ART.getArtifactBonuses().lowMultiplier
            --print('Получили бонусы для низкой магии: ' ..lowMagickaArtMult)
            positiveModifier = positiveModifier + lowMagickaArtMult
        end
    end

    local artifactMult = I.NMR_ART.getArtifactBonuses().multiplier
    positiveModifier = positiveModifier + artifactMult
    --print('Позитивный множитель: ' .. negativeModifier)
    return positiveModifier
end

local function calculateNegatives()
    local fatigueMultiplier = 1
    negativeModifier = 1
    if settings.addons:get('NMRFatigueMult') then
        local fatiguePercent = (types.Actor.stats.dynamic.fatigue(self).current / types.Actor.stats.dynamic.fatigue(self).base) * 100

        for _, penalty in ipairs(fatiguePenalties) do
            if fatiguePercent < penalty.threshold then
                fatigueMultiplier = penalty.multiplier
                local artFatigueBonus = I.NMR_ART.getArtifactBonuses().fatigue
                fatigueMultiplier = fatigueMultiplier + artFatigueBonus
                break
            end
        end
        
        fatigueMultiplier = math.min(fatigueMultiplier, 1)
        --print('Fatigue modifier with arts: ' .. fatigueMultiplier)
    end

    negativeModifier = negativeModifier * fatigueMultiplier
    --print('Негативный множитель: ' .. negativeModifier)
    return negativeModifier

end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    interfaceName = "NMR_CALC",
    interface = {
        calculatePositives = calculatePositives,
        calculateNegatives = calculateNegatives,
        calculateBase = calculateBase,
        calculateMax = calculateMax,
    },
}