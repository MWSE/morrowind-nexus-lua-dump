local Actor = require('openmw.types').Actor
local core = require('openmw.core')
local debug = require('openmw.debug')
local types = require('openmw.types')

local ZStats = require('scripts.ZModUtils.Utility.Stats')

-- Ported (roughly) from https://github.com/OpenMW/openmw/blob/9ea1afedcc5793adec7d6143eb8f827d469ada49/apps/openmw/mwmechanics/spellutil.cpp#L42
local function calcEffectCost(effectParams, isPotion)
    if (not effectParams) then return nil end

    local effect = core.magic.effects.records[effectParams.id]

    if (not effect) then return nil end

    local hasMagnitude = effect.hasMagnitude
    local hasDuration = effect.hasDuration
    local appliedOnce = effect.isAppliedOnce

    local minMagnitude = hasMagnitude and effectParams.magnitudeMin or 1.0
    local maxMagnitude = hasMagnitude and effectParams.magnitudeMax or 1.0

    -- NOTE Only Applied when EffectCostMethod is PlayerSpell or GameSpell ? Can this be checked from Lua?
    minMagnitude = math.max(1.0, minMagnitude)
    maxMagnitude = math.max(1.0, maxMagnitude)

    local duration = hasDuration and effectParams.duration or 1.0
    if not appliedOnce then
        duration = math.max(1.0, duration)
    end

    local fEffectCostMult = core.getGMST('fEffectCostMult')
    local iAlchemyMod = core.getGMST('iAlchemyMod')

    if (not fEffectCostMult) or ((not iAlchemyMod) and isPotion) then return nil end

    local durationOffset = 0
    local minArea = 0
    local costMult = fEffectCostMult

    local isPlayerSpell = false

    -- EffectCostMethod comes in here again..just guessing.
    if isPotion then
        minArea = 1.0
        costMult = iAlchemyMod
    elseif isPlayerSpell then
        durationOffset = 1.0
        minArea = 1.0
    end

    local x = 0.5 * (minMagnitude + maxMagnitude)
    x = x * (0.1 * effect.baseCost)
    x = x * (durationOffset + duration)
    x = x + (0.05 * math.max(minArea, effectParams.area) * effect.baseCost)

    return x * costMult
end

local function getTotalEffectsCost(effects, isPotion)
    local cost = 0.0
    for i=1,#effects do
        local effectCost = math.max(0.0, calcEffectCost(effects[i], isPotion))
        if effects[i].range == core.magic.RANGE.Target then
            effectCost = effectCost * 1.5
        end

        cost = cost + effectCost
    end

    return cost
end

local function getSkillForEffect(player, effect)
    local skills = types.NPC.stats.skills
    local skill = skills[effect.school](player).modified
    return skill
end

local function getSpellCost(spell)
    if not spell.autocalcFlag then
        return spell.cost
    end

    local cost = getTotalEffectsCost(spell.effects, false)
    
    -- Equivalent to round
    return math.floor(cost + 0.5)
end

local function calcSpellBaseChance(actor, spell)
    local fEffectCostMult = core.getGMST('fEffectCostMult')
    local y = 3.40282347e+38 -- shameless steal from C++ limits
    local school = nil
    local lowestSkill = nil

    if spell.type ~= core.magic.SPELL_TYPE.Spell then
        return nil
    end

    for k, effectParams in ipairs(spell.effects) do
        local effect = core.magic.effects.records[effectParams.id]

        local val = effectParams.duration
        if not effect.isAppliedOnce then
            val = math.max(1.0, val)
        end

        val = val * 0.1 * effect.baseCost
        val = val * 0.5 * (effectParams.magnitudeMin + effectParams.magnitudeMax)
        val = val + (effectParams.area * 0.05 * effect.baseCost)
        if effect.range == core.magic.RANGE.Target then
            val = val * 1.5
        end

        val = val * fEffectCostMult
        local s = 2.0 * getSkillForEffect(actor, effect)
        if s - val < y then
            y = s - val
            school = effect.school
            lowestSkill = s
        end
    end

    if (school) then
        local first = string.sub(school, 1, 1)
        school = string.upper(first) .. string.sub(school, 2, #school)
    end

    local willpower = ZStats.getActorAttribute(actor, 'willpower')
    local luck = ZStats.getActorAttribute(actor, 'luck')

    local castChance = (lowestSkill - getSpellCost(spell) + 0.2 * willpower + 0.1 * luck)

    return school, castChance
end

-- This is essentially translated from the C++ code on OpenMW's Github.
local function getSpellSchoolAndCastChance(actor, spell, checkMagicka)

    if (not actor) or (not spell) then return nil, nil end

    local school, baseChance = calcSpellBaseChance(actor, spell)
    baseChance = baseChance

    -- Check for silenced
    local activeEffects = types.Actor.activeEffects(actor)
    local silenceEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence)
    if silenceEffect and silenceEffect.magnitude > 0 then
        return school, 0.0
    end

    local actorSpells = types.Actor.spells(actor)
    if actorSpells and spell.type == core.magic.SPELL_TYPE.Power then
        return school, (actorSpells:canUsePower(spell) and 100.0 or 0.0)
    end

    if debug.isGodMode() then return school, 100.0 end

    if spell.type ~= core.magic.SPELL_TYPE.Spell then return school, 100.0 end

    -- nil considered to be true
    if checkMagicka ~= false then
        local spellCost = getSpellCost(spell)
        local mStat = ZStats.getActorDynamicStat(actor, 'magicka')
        if (mStat and mStat.current) and (mStat.current < spellCost) then return school, 0.0 end
    end

    if spell.alwaysSucceedFlag then return school, 100.0 end

    local castBonus = 0.0
    local soundEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound)
    castBonus = -(soundEffect and soundEffect.magnitude or 0.0)
    local castChance = baseChance + castBonus
    castChance = castChance * ZStats.getFatigueTerm(actor)

    -- Always cap for our purposes
    castChance = math.min(100.0, math.max(0.0, castChance))

    return school, castChance
end

local lib = {

    -- converts a path to an effect icon into the larger version that is fit for larger icons on the UI.
    getSpellEffectBigIconPath = function(fullPath)
        if not fullPath then return nil end
        
        local pattern = "[%w_]+.dds"
        
        local b, e = string.find(fullPath, pattern)
        if b and e then
            local fileLocation = string.sub(fullPath, 1, b - 1)
            local filename = string.sub(fullPath, b, e)
            return string.format("%sb_%s", fileLocation, filename)
        end

        -- Failed to make the path, return the original
        return fullPath
    end,

    -- Takes in actor, spell and checkMagicka(bool)
    -- if checkMagicka is false, actors magicka will not be taken into account.
    -- If you need both, prefer using this since it's a non-trivial calculation.
    getSpellSchoolAndCastChance = getSpellSchoolAndCastChance,

    -- returns the spell school for a spell, the actor is required since it depends
    -- on the actors skills.
    getSpellSchool = function(actor, spell)
        if (not actor) or (not spell) then return nil end
        local school, _ = getSpellSchoolAndCastChance(actor, spell)
        return school
    end,

    -- returns the spell cast chance between [0.0, 100.0].
    getSpellCastChance = function(actor, spell)
        if (not actor) or (not spell) then return nil end
        local _, chance = getSpellSchoolAndCastChance(actor, spell)
        return chance
    end,

    -- Returns the magicka cost to cast a spell.
    -- takes a core.magic.spell as parameter.
    getSpellCost = getSpellCost,

    -- Returns a non-localized display text based on enchantment type.
    getEnchantTypeText = function(enchantment)
        if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            return "Cast on Strike"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
            return "Cast on Use"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
            return "Cast Once"
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            return "Constant Effect"
        end
        return nil
    end,
}

return lib