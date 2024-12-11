local util = require("openmw.util")
local T = require('openmw.types')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mTools = require('scripts.FairCare.tools')
local mActors = require('scripts.FairCare.actors')
local mData = require('scripts.FairCare.data')
local mMagic = require('scripts.FairCare.magic')

local module = {}

local function newHealChances()
    return { chances = {}, chance = 0, zeroed = false, aborted = false, isSuccess = false }
end
module.newHealChances = newHealChances

local function add(healChances, type, value)
    healChances.chances[type.key] = mTools.clamp(value, 0, 1)
    if healChances.chances[type.key] == 0 then
        healChances.zeroed = true
    end
end

local function getChanceImpact(typeKey)
    if mData.chanceTypes[typeKey].action == mData.actions.selfHeal then
        return mCfg.chanceImpacts[mSettings.getStorage(mSettings.woundedImpactsKey):get(mSettings.getHealChanceImpactKey(typeKey))]
    else
        return mCfg.chanceImpacts[mSettings.getStorage(mSettings.healerImpactsKey):get(mSettings.getHealChanceImpactKey(typeKey))]
    end
end

local function setChance(healChances)
    local chance = 1
    for typeKey, value in pairs(healChances.chances) do
        chance = chance * value ^ getChanceImpact(typeKey).power
    end
    healChances.chance = chance
    healChances.isSuccess = math.random() < healChances.chance
end
module.setChance = setChance

local function areNewChancesGoodEnough(healChances1, healChances2)
    return healChances1 / healChances2 >= mCfg.minNewChancesToContinueHealingRatio
end
module.areNewChancesGoodEnough = areNewChancesGoodEnough

local function toString(healChances)
    local msg = {}
    for typeKey, chance in pairs(healChances.chances) do
        table.insert(msg, string.format("%s = %s%% (%s)", typeKey, util.round(chance * 100), getChanceImpact(typeKey).key))
    end

    return string.format("\n---- Final chances=%s%%, aborted=%s\n---- Detailed chances: ",
            util.round(healChances.chance * 100), healChances.aborted)
            .. table.concat(msg, " ; ")
end
module.toString = toString

local function setSelfHealingChances(spellId, wounded, healChances)
    -- MAGICKA
    local magickaCostRatio = mMagic.spellCostMagickaRatio(wounded, spellId)
    if magickaCostRatio >= 1 then
        return false
    end

    -- SILENCE
    if mMagic.isSilenced(wounded) then
        mTools.debugPrint(string.format("%s cannot self-heal because he is silenced", mTools.actorId(wounded)))
        return false
    end

    -- CAST CHANCES
    local sound = mMagic.getSoundEffect(wounded)
    local castChances = mMagic.castChances(wounded, spellId, -sound)
    if castChances <= 0 then
        mTools.debugPrint(string.format("%s cannot self-heal because cast chances are nul. Sound=%s", mTools.actorId(wounded), sound))
        return false
    end
    add(healChances, mData.chanceTypes.woundedCastChances, castChances)

    -- HEALTH
    local health = T.Actor.stats.dynamic.health(wounded)
    add(healChances, mData.chanceTypes.woundedHealth, 1 - health.current / health.base)

    return true
end
module.setSelfHealingChances = setSelfHealingChances

local function setHealerChances(spellId, wounded, healer, healerState, healChances)
    -- SILENCE
    if mMagic.isSilenced(wounded) then
        mTools.debugPrint(string.format("%s cannot heal %s because he is silenced", mTools.actorId(healer), mTools.actorId(wounded)))
        return false
    end

    -- CAST CHANCES
    local sound = mMagic.getSoundEffect(healer)
    local castChances = mMagic.castChances(healer, spellId, -sound)
    if castChances <= 0 then
        mTools.debugPrint(string.format("%s cannot heal %s. Sound = %s", mTools.actorId(healer), mTools.actorId(wounded), sound))
        return false
    end
    add(healChances, mData.chanceTypes.healerCastChances, castChances)

    -- MAGICKA
    local magickaCostRatio = mMagic.spellCostMagickaRatio(healer, spellId)
    if magickaCostRatio >= 1 then
        return false
    end
    add(healChances, mData.chanceTypes.healerMagickaCost, 1 - magickaCostRatio)

    -- PARTNER HEALTH
    local partnerHealth = T.Actor.stats.dynamic.health(wounded)
    add(healChances, mData.chanceTypes.healerPartnerHealth, 1 - partnerHealth.current / partnerHealth.base)

    -- SPELL INTENSITY
    add(healChances, mData.chanceTypes.healerSpellIntensity, mMagic.getSpellAverageRestoredHealth(spellId) / partnerHealth.base)

    -- HEALER HEALTH
    local healerHealth = T.Actor.stats.dynamic.health(healer)
    add(healChances, mData.chanceTypes.healerHealth, healerHealth.current / healerHealth.base)

    -- DISPOSITION
    add(healChances, mData.chanceTypes.healerDisposition, mActors.getDisposition(healer, wounded) / 100)

    -- TRAVEL TIME
    if mActors.isOverEncumbered(healer) then
        if not mActors.isCloseEnough(healer, wounded, healerState and healerState.travel.touchHealDistance or mMagic.touchHealDistance(healer, wounded)) then
            mTools.debugPrint(string.format("%s is over encumbered and too far to heal %s", mTools.actorId(healer), mTools.actorId(wounded)))
            return false
        else
            mTools.debugPrint(string.format("%s is over encumbered but close enough to heal %s", mTools.actorId(healer), mTools.actorId(wounded)))
        end
    else
        local path = healerState and healerState.travel.path or mActors.getPathToTarget(healer, wounded, mMagic.touchHealDistance(healer, wounded))
        if path then
            local travelTime = mActors.getPathTravelTime(healer, path)
            add(healChances, mData.chanceTypes.healerTravelTime, 1 - travelTime / mSettings.getStorage(mSettings.healingTweaksKey):get("travelTimeToHealMinChances"))
        else
            mTools.debugPrint(string.format("%s cannot find a path to %s", mTools.actorId(healer), mTools.actorId(wounded)))
            return false
        end
    end

    return true
end
module.setHealerChances = setHealerChances

local function selectActorsChances(wounded, actor, healChances)
    for _, spellId in ipairs(mData.selfTouchSpellIds) do
        if T.Actor.spells(actor)[spellId] then
            if not setHealerChances(spellId, wounded, actor, nil, healChances) then
                healChances.aborted = true
            end
            return
        end
    end
    healChances.aborted = true
end
module.selectActorsChances = selectActorsChances

return module