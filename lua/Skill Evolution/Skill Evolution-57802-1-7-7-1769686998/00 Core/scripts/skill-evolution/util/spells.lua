local core = require('openmw.core')
local T = require('openmw.types')

local mCore = require('scripts.skill-evolution.util.core')

local module = {}

local function getSpellStats(spell, player)
    local minChance = math.huge
    local effectiveSchool
    local minSkillTerm = 0
    local schoolImpacts = {}
    for _, effect in ipairs(spell.effects) do
        local minMagnitude = 1
        local maxMagnitude = 1
        if effect.effect.hasMagnitude then
            minMagnitude = effect.magnitudeMin
            maxMagnitude = effect.magnitudeMax
        end
        local duration = 0
        if effect.effect.hasDuration then
            duration = effect.duration
        end
        if effect.effect.isAppliedOnce then
            duration = math.max(1, effect.duration)
        end

        local baseCost = (0.5 * (math.max(1, minMagnitude) + math.max(1, maxMagnitude))
                * 0.1 * effect.effect.baseCost
                * (1 + duration)
                + 0.05 * math.max(1, effect.area) * effect.effect.baseCost
        ) * mCore.GMSTs.fEffectCostMult

        if effect.range == core.magic.RANGE.Target then
            baseCost = baseCost * 1.5
        end
        schoolImpacts[effect.effect.school] = (schoolImpacts[effect.effect.school] or 0) + baseCost

        local skillTerm = 0
        local skill = T.NPC.stats.skills[effect.effect.school]
        if skill then
            skillTerm = 2 * skill(player).base;
        end
        if skillTerm - baseCost < minChance then
            minChance = skillTerm - baseCost
            effectiveSchool = effect.effect.school
            minSkillTerm = skillTerm
        end
    end
    return effectiveSchool, minSkillTerm, schoolImpacts
end

module.getSchoolRatios = function(spell, player)
    local _, _, schoolImpacts = getSpellStats(spell, player)
    local sum = 0
    for _, impact in pairs(schoolImpacts) do
        sum = sum + impact
    end
    local ratios = {}
    for school, impact in pairs(schoolImpacts) do
        ratios[school] = impact / sum
    end
    return ratios
end

module.calcAutoCastChance = function(spell, player)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm, _ = getSpellStats(spell, player)

    return skillTerm - spell.cost
            + 0.2 * T.Actor.stats.attributes.willpower(player).base
            + 0.1 * T.Actor.stats.attributes.luck(player).base
end

return module