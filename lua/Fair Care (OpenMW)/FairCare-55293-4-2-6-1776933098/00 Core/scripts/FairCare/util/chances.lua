local util = require("openmw.util")
local T = require('openmw.types')

local log = require('scripts.FairCare.util.log')
local mStore = require('scripts.FairCare.config.store')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mActors = require('scripts.FairCare.util.actors')
local mMagic = require('scripts.FairCare.util.magic')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

module.newHealChances = function()
    return { chances = {}, chance = 0, zeroed = false, aborted = false, isSuccess = false }
end

local function add(healChances, type, value)
    healChances.chances[type.key] = mTools.clamp(value, 0, 1)
    if healChances.chances[type.key] == 0 then
        healChances.zeroed = true
    end
end

local function getChanceImpact(typeKey)
    return mStore.settings[mStore.getHealChanceImpactKey(
            mTypes.chanceTypes[typeKey].action == mTypes.actions.selfHeal and mStore.sections.woundedImpacts or mStore.sections.healerImpacts,
            typeKey)].value
end

module.setChance = function(healChances)
    local chance = 1
    for typeKey, value in pairs(healChances.chances) do
        chance = chance * value ^ getChanceImpact(typeKey)
    end
    healChances.chance = chance
    healChances.isSuccess = math.random() < healChances.chance
end

module.areNewChancesGoodEnough = function(healChances1, healChances2)
    return healChances1 / healChances2 >= mCfg.minNewChancesToContinueHealingRatio
end

module.toString = function(healChances)
    local msg = {}
    for typeKey, chance in pairs(healChances.chances) do
        table.insert(msg, string.format("%s = %s%% (%.3f)", typeKey, util.round(chance * 100), getChanceImpact(typeKey)))
    end

    return string.format("\n---- Final chances=%s%%, aborted=%s\n---- Detailed chances: ",
            util.round(healChances.chance * 100), healChances.aborted)
            .. table.concat(msg, " ; ")
end

module.setSelfHealingChances = function(state, wounded, healChances)
    -- MAGICKA
    local magickaCostRatio = mMagic.spellCostMagickaRatio(wounded, state.selfHealSpellId)
    if magickaCostRatio >= 1 then
        return false
    end

    -- SILENCE
    if mMagic.isSilenced(wounded) then
        log(string.format("%s cannot self-heal because he is silenced", mTools.objectId(wounded)))
        return false
    end

    -- CAST CHANCES
    local sound = mMagic.getSoundEffect(wounded)
    local castChances = mMagic.castChances(wounded, state.selfHealSpellId, -sound)
    if castChances <= 0 then
        log(string.format("%s cannot self-heal because cast chances are nul. Sound=%s", mTools.objectId(wounded), sound))
        return false
    end
    add(healChances, mTypes.chanceTypes.woundedCastChances, castChances)

    -- HEALTH
    add(healChances, mTypes.chanceTypes.woundedHealth, 1 - state.health.current / state.health.base)

    return true
end

module.setHealerChances = function(spellId, wounded, healer, healerState, healChances)
    -- SILENCE
    if mMagic.isSilenced(wounded) then
        log(string.format("%s cannot heal %s because he is silenced", mTools.objectId(healer), mTools.objectId(wounded)))
        return false
    end

    -- CAST CHANCES
    local sound = mMagic.getSoundEffect(healer)
    local castChances = mMagic.castChances(healer, spellId, -sound)
    if castChances <= 0 then
        log(string.format("%s cannot heal %s. Sound = %s", mTools.objectId(healer), mTools.objectId(wounded), sound))
        return false
    end
    add(healChances, mTypes.chanceTypes.healerCastChances, castChances)

    -- MAGICKA
    local magickaCostRatio = mMagic.spellCostMagickaRatio(healer, spellId)
    if magickaCostRatio >= 1 then
        return false
    end
    add(healChances, mTypes.chanceTypes.healerMagickaCost, 1 - magickaCostRatio)

    -- PARTNER HEALTH
    local partnerHealth = T.Actor.stats.dynamic.health(wounded)
    add(healChances, mTypes.chanceTypes.healerPartnerHealth, 1 - partnerHealth.current / partnerHealth.base)

    -- SPELL INTENSITY
    add(healChances, mTypes.chanceTypes.healerSpellIntensity, mMagic.getSpellAverageRestoredHealth(spellId) / partnerHealth.base)

    -- HEALER HEALTH
    local healerHealth = T.Actor.stats.dynamic.health(healer)
    add(healChances, mTypes.chanceTypes.healerHealth, healerHealth.current / healerHealth.base)

    -- DISPOSITION
    add(healChances, mTypes.chanceTypes.healerDisposition, mActors.getDisposition(healer, wounded) / 100)

    -- TRAVEL TIME
    if mActors.isOverEncumbered(healer) then
        if not mActors.isCloseEnough(healer, wounded, healerState and healerState.travel.touchHealDistance or mMagic.touchHealDistance(healer, wounded)) then
            log(string.format("%s is over encumbered and too far to heal %s", mTools.objectId(healer), mTools.objectId(wounded)))
            return false
        else
            log(string.format("%s is over encumbered but close enough to heal %s", mTools.objectId(healer), mTools.objectId(wounded)))
        end
    else
        local path = healerState and healerState.travel.path or mActors.getPathToTarget(healer, wounded, mMagic.touchHealDistance(healer, wounded))
        if path then
            local travelTime = mActors.getPathTravelTime(healer, path)
            add(healChances, mTypes.chanceTypes.healerTravelTime, 1 - travelTime / mStore.settings.travelTimeToHealMinChances.value)
        else
            log(string.format("%s cannot find a path to %s", mTools.objectId(healer), mTools.objectId(wounded)))
            return false
        end
    end

    return true
end

module.selectActorsChances = function(wounded, actor, healChances)
    for _, spellId in ipairs(mTypes.selfTouchSpellIds) do
        if T.Actor.spells(actor)[spellId] then
            return module.setHealerChances(spellId, wounded, actor, nil, healChances)
        end
    end
    return false
end

return module