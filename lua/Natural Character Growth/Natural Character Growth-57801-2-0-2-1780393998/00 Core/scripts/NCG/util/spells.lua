local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')

local mSkills = require('scripts.NCG.core.skills')
local log = require('scripts.NCG.util.log')

local module = {}

local GMSTs = {
    fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance"),
    fEffectCostMult = core.getGMST("fEffectCostMult"),
    iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin"),
    iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax"),
    fPCbaseMagickaMult = core.getGMST("fPCbaseMagickaMult"),
}

local autoCalcSpellCostCache = {}

local function getAutoCalcEffectCost(effect)
    local minMagnitude = 1
    local maxMagnitude = 1
    if effect.effect.hasMagnitude then
        minMagnitude = effect.magnitudeMin
        maxMagnitude = effect.magnitudeMax
    end
    local duration = 1
    if effect.effect.hasDuration then
        duration = effect.duration
    end
    if not effect.effect.isAppliedOnce then
        duration = math.max(1, effect.duration)
    end

    local cost = (0.5 * (math.max(1, minMagnitude) + math.max(1, maxMagnitude))
            * 0.1 * effect.effect.baseCost
            * duration
            + 0.05 * math.max(1, effect.area) * effect.effect.baseCost
    ) * GMSTs.fEffectCostMult

    if effect.range == core.magic.RANGE.Target then
        cost = cost * 1.5
    end
    return math.max(0, cost)
end

local function getSpellCost(spell)
    if not spell.autocalcFlag then
        return spell.cost
    end
    if autoCalcSpellCostCache[spell.id] then
        return autoCalcSpellCostCache[spell.id]
    end
    local cost = 0
    for _, effect in ipairs(spell.effects) do
        cost = cost + getAutoCalcEffectCost(effect)
    end
    cost = math.floor(0.5 + cost)
    autoCalcSpellCostCache[spell.id] = cost
    return cost
end

local function getSpellStats(spell)
    local minChance = math.huge
    local effectiveSchool
    local minSkillTerm = 0
    local schoolImpacts = {}
    for _, effect in ipairs(spell.effects) do
        local cost = getAutoCalcEffectCost(effect)
        schoolImpacts[effect.effect.school] = (schoolImpacts[effect.effect.school] or 0) + cost

        local skillTerm = 0
        local skill = mSkills.getStat(effect.effect.school)
        if skill then
            skillTerm = 2 * skill.base;
        end
        if skillTerm - cost < minChance then
            minChance = skillTerm - cost
            effectiveSchool = effect.effect.school
            minSkillTerm = skillTerm
        end
    end
    return effectiveSchool, minSkillTerm, schoolImpacts
end

local function calcAutoCastChance(spell)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm, _ = getSpellStats(spell)

    return skillTerm - getSpellCost(spell)
            + 0.2 * T.Actor.stats.attributes.willpower(self).base
            + 0.1 * T.Actor.stats.attributes.luck(self).base
end

local function attrSkillCheck(spell)
    for _, effect in ipairs(spell.effects) do
        if effect.affectedSkill then
            local skill = mSkills.getStat(effect.affectedSkill)
            if not skill or skill.base < GMSTs.iAutoSpellAttSkillMin then
                return false
            end
        end
        if effect.affectedAttribute then
            local getter = T.Actor.stats.attributes[effect.affectedAttribute]
            if not getter or getter(self).base < GMSTs.iAutoSpellAttSkillMin then
                return false
            end
        end
        return true
    end
end

local function selectStarterSpell(spell, context)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return end
    local cost = getSpellCost(spell)
    if context.reachedLimit and cost <= context.minCost then return end
    if context.baseSpellIds[spell.id] then return end
    if context.baseMagicka < cost then return end
    if calcAutoCastChance(spell) < GMSTs.fAutoPCSpellChance then return end
    if not attrSkillCheck(spell) then return end

    table.insert(context.selectedSpells, spell.id)

    if context.reachedLimit then
        for i, spellId in ipairs(context.selectedSpells) do
            if spellId == context.weakestSpell.id then
                table.remove(context.selectedSpells, i)
            end
        end

        context.minCost = math.huge
        for _, spellId in ipairs(context.selectedSpells) do
            local testSpell = core.magic.spells.records[spellId]
            if getSpellCost(testSpell) < context.minCost then
                context.minCost = getSpellCost(testSpell)
                context.weakestSpell = testSpell
            end
        end
    else
        if (cost < context.minCost) then
            context.weakestSpell = spell
            context.minCost = cost
        end
        if #context.selectedSpells == GMSTs.iAutoPCSpellMax then
            context.reachedLimit = true
        end
    end
end

local function getPlayerInnateSpellIds()
    local baseSpellIds = {}
    local birthSign = T.Player.birthSigns.record(T.Player.getBirthSign(self))
    if birthSign ~= nil then
        for _, spellId in pairs(birthSign.spells) do
            baseSpellIds[spellId] = true
        end
    end
    local race = T.Player.races.record(T.Player.record(self).race)
    for _, spellId in pairs(race.spells) do
        baseSpellIds[spellId] = true
    end
    return baseSpellIds
end

local function autoCalcPlayerSpells()
    local context = {
        baseMagicka = GMSTs.fPCbaseMagickaMult * T.Actor.stats.attributes.intelligence(self).base,
        reachedLimit = false,
        weakestSpell = nil,
        minCost = math.huge,
        baseSpellIds = getPlayerInnateSpellIds(),
        selectedSpells = {},
    }
    for _, spell in ipairs(core.magic.spells.records) do
        if spell.starterSpellFlag then
            selectStarterSpell(spell, context)
        end
    end
    return context.selectedSpells
end

module.updateStarterSpells = function()
    local baseSpellIds = getPlayerInnateSpellIds()
    for _, spell in pairs(T.Player.spells(self)) do
        if spell.starterSpellFlag and not baseSpellIds[spell.id] then
            T.Player.spells(self):remove(spell.id)
            log(string.format("Removed existing starter spell: %s", spell.id))
        end
    end

    local starterSpells = autoCalcPlayerSpells()
    for _, spellId in ipairs(starterSpells) do
        T.Player.spells(self):add(spellId)
        log(string.format("Added starter spell: %s", spellId))
    end
end

return module