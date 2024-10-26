local core = require('openmw.core')
local T = require('openmw.types')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mTools = require('scripts.FairCare.tools')
local mActors = require('scripts.FairCare.actors')
local mData = require('scripts.FairCare.data')
local mMagic = require('scripts.FairCare.magic')

local module = {}

local function newHealChances()
    return { chances = {}, chance = 0, none = false, aborted = false, isSuccess = false }
end
module.newHealChances = newHealChances

local function add(healChances, type, value)
    healChances.chances[type.key] = mTools.clamp(value, 0, 1)
    if healChances.chances[type.key] == 0 then
        healChances.none = true
    end
end

local function getChanceImpact(typeKey)
    if mData.chanceTypes[typeKey].action == mData.actions.selfHeal then
        return mCfg.chanceImpacts[mSettings.woundedImpactsStorage:get(mSettings.getHealChanceImpactKey(typeKey))]
    else
        return mCfg.chanceImpacts[mSettings.healerImpactsStorage:get(mSettings.getHealChanceImpactKey(typeKey))]
    end
end

local function getChanceBase(healChances, monitoredOnly)
    local chance = 1
    for typeKey, value in pairs(healChances.chances) do
        if not monitoredOnly or mData.chanceTypes[typeKey].monitored then
            chance = chance * value ^ getChanceImpact(typeKey).power
        end
    end
    return chance
end

local function getChanceForClearAnswerDelay(healChances)
    return getChanceBase(healChances, true)
end
module.getChanceForClearAnswerDelay = getChanceForClearAnswerDelay

local function setChance(healChances)
    healChances.chance = getChanceBase(healChances, false)
    healChances.isSuccess = math.random() < healChances.chance
end
module.setChance = setChance

local function areChancesBetter(healChances1, healChances2)
    return healChances1 ~= 0 and healChances2 == 0
            or healChances1 / healChances2 > mCfg.betterChancesToBeHealedRatio
end
module.areChancesBetter = areChancesBetter

local function toString(healChances)
    local msg = {}
    for typeKey, chance in pairs(healChances.chances) do
        table.insert(msg, string.format("%s = %s%% (%s)", typeKey, math.floor(chance * 100 + 0.5), getChanceImpact(typeKey).key))
    end

    return string.format("\nFinal chances=%s%%, aborted=%s\nDetailed chances: ",
            math.floor(healChances.chance * 100 + 0.5), healChances.aborted)
            .. table.concat(msg, " ; ")
end
module.toString = toString

local function setSelfHealingChances(state, wounded, healChances)
    -- MAGICKA
    local magickaCostRatio = mMagic.spellCostMagickaRatio(wounded, state.healSpellId)
    if magickaCostRatio >= 1 then
        return false
    end

    -- PARALYZE and SILENCE
    local castFailEffects = mMagic.castFailEffects(wounded)
    if castFailEffects.paralyze > 0 or castFailEffects.silence > 0 then
        mSettings.debugPrint(string.format("%s cannot self heal. Paralyze = %s, Silence = %s",
                mActors.actorId(wounded), castFailEffects.paralyze, castFailEffects.silence))
        return false
    end

    -- KNOCK OUT
    local fatigue = T.Actor.stats.dynamic.fatigue(wounded)
    if fatigue.current <= 0 or fatigue.base == 0 then
        mSettings.debugPrint(string.format("%s seems to be knocked out, he cannot self heal", mActors.actorId(wounded)))
        return false
    end

    -- CAST CHANCES
    local castChances = mMagic.castChances(wounded, state.healSpellId, -castFailEffects.sound)
    if castChances <= 0 then
        mSettings.debugPrint(string.format("%s cannot self heal. Fatigue = %s/%s, Sound = %s",
                mActors.actorId(wounded), fatigue.current, fatigue.base, castFailEffects.sound))
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
    if healChances.aborted then return end
    -- PARALYZE and SILENCE
    local castFailEffects = mMagic.castFailEffects(healer)
    if castFailEffects.paralyze > 0 or castFailEffects.silence > 0 then
        mSettings.debugPrint(string.format("%s cannot heal %s. Paralyze = %s, Silence = %s",
                mActors.actorId(healer), mActors.actorId(wounded), castFailEffects.paralyze, castFailEffects.silence))
        return false
    end

    -- KNOCK OUT
    local fatigue = T.Actor.stats.dynamic.fatigue(healer)
    if fatigue.current <= 0 or fatigue.base == 0 then
        mSettings.debugPrint(string.format("%s seems to be knocked out, he cannot heal %s",
                mActors.actorId(healer), mActors.actorId(wounded)))
        return false
    end

    -- KNOCK DOWN
    local overEncumbered = mActors.isOverEncumbered(healer)
    if not overEncumbered and not T.Actor.canMove(healer) then
        mSettings.debugPrint(string.format("%s seems to be knocked down, he cannot heal %s",
                mActors.actorId(healer), mActors.actorId(wounded)))
        return false
    end

    -- CAST CHANCES
    local castChances = mMagic.castChances(healer, spellId, -castFailEffects.sound)
    if castChances <= 0 then
        mSettings.debugPrint(string.format("%s cannot heal %s. Fatigue = %s/%s, Sound = %s",
                mActors.actorId(healer), mActors.actorId(wounded), fatigue.current, fatigue.base, castFailEffects.sound))
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
    add(healChances, mData.chanceTypes.healerSpellIntensity, mMagic.getAverageRestoredHealth(spellId) / partnerHealth.base)

    -- HEALER HEALTH
    local healerHealth = T.Actor.stats.dynamic.health(healer)
    add(healChances, mData.chanceTypes.healerHealth, healerHealth.current / healerHealth.base)

    -- DISPOSITION
    add(healChances, mData.chanceTypes.healerDisposition, mActors.getDisposition(healer, wounded) / 100)

    -- TRAVEL TIME
    if overEncumbered then
        local touchHealTargetDistance = mMagic.touchHealTargetDistance(healer, wounded)
        if (healer:getBoundingBox().center - wounded:getBoundingBox().center):length() > touchHealTargetDistance then
            mSettings.debugPrint(string.format("%s is over encumbered and too far to heal %s", mActors.actorId(healer), mActors.actorId(wounded)))
            return false
        else
            mSettings.debugPrint(string.format("%s is over encumbered but close enough to heal %s", mActors.actorId(healer), mActors.actorId(wounded)))
        end
    else
        local path = healerState and healerState.pathToFriend or mActors.getPath(healer, wounded)
        if not path then
            return false
        end
        local travelTime = mActors.getTravelTimeSec(healer, path)
        add(healChances, mData.chanceTypes.healerTravelTime, 1 - travelTime / mSettings.healingTweaksStorage:get("travelTimeToHealMinChances"))
    end

    return true
end
module.setHealerChances = setHealerChances

local function selectActorsChances(wounded, actor, healChances)
    for _, spellId in ipairs(mData.selfSpellIds) do
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