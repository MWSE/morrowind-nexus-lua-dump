local core = require('openmw.core')
local Player = require('openmw.types').Player

local function getPlayerInnateSpellIds(player)
    local baseSpellIds = {}
    local birthSign = Player.birthSigns.record(Player.getBirthSign(player))
    if birthSign ~= nil then
        for _, spellId in pairs(birthSign.spells) do
            baseSpellIds[spellId] = true
        end
    end
    local race = Player.races.record(Player.record(player).race)
    for _, spellId in pairs(race.spells) do
        baseSpellIds[spellId] = true
    end
    return baseSpellIds
end

-- Dehardcoding of autoCalcPlayerSpells C++ implementation from openmw source code: apps/openmw/mwmechanics/autocalcspell.cpp

local function calcWeakestSchool(spell, context)
    local minChance = math.huge
    local effectiveSchool
    local skillTerm = 0
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

        local x = (0.5 * (math.max(1, minMagnitude) + math.max(1, maxMagnitude))
                * 0.1 * effect.effect.baseCost
                * (1 + duration)
                + 0.05 * math.max(1, effect.area) * effect.effect.baseCost
        ) * context.fEffectCostMult

        if effect.range == core.magic.RANGE.Target then
            x = x * 1.5
        end

        local s = 0
        local skill = Player.stats.skills[effect.effect.school]
        if skill then
            s = 2 * skill(context.player).base;
        end
        if s - x < minChance then
            minChance = s - x
            effectiveSchool = effect.effect.school
            skillTerm = s
        end
    end
    return effectiveSchool, skillTerm
end

local function calcAutoCastChance(spell, context)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm = calcWeakestSchool(spell, context)

    return skillTerm - spell.cost
            + 0.2 * Player.stats.attributes.willpower(context.player).base
            + 0.1 * Player.stats.attributes.luck(context.player).base
end

local function attrSkillCheck(spell, context)
    for _, effect in ipairs(spell.effects) do
        if effect.affectedSkill then
            local skill = Player.stats.skills[effect.affectedSkill]
            if not skill or skill(context.player).base < context.iAutoSpellAttSkillMin then
                return false
            end
        end
        if effect.affectedAttribute then
            local attribute = Player.stats.attributes[effect.affectedAttribute]
            if not attribute or attribute(context.player).base < context.iAutoSpellAttSkillMin then
                return false
            end
        end
        return true
    end
end

local function selectStarterSpell(spell, context)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return end
    if context.reachedLimit and spell.cost <= context.minCost then return end
    if context.baseSpellIds[spell.id] then return end
    if context.baseMagicka < spell.cost then return end
    if calcAutoCastChance(spell, context) < context.fAutoPCSpellChance then return end
    if not attrSkillCheck(spell, context) then return end

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
            if testSpell.cost < context.minCost then
                context.minCost = testSpell.cost
                context.weakestSpell = testSpell
            end
        end
    else
        if (spell.cost < context.minCost) then
            context.weakestSpell = spell
            context.minCost = spell.cost
        end
        if #context.selectedSpells == context.iAutoPCSpellMax then
            context.reachedLimit = true
        end
    end
end

local function autoCalcPlayerSpells(player)
    local context = {
        player = player,
        fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance"),
        fEffectCostMult = core.getGMST("fEffectCostMult"),
        iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin"),
        iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax"),
        baseMagicka = core.getGMST("fPCbaseMagickaMult") * Player.stats.attributes.intelligence(player).base,
        reachedLimit = false,
        weakestSpell = nil,
        minCost = math.huge,
        baseSpellIds = getPlayerInnateSpellIds(player),
        selectedSpells = {},
    }
    for _, spell in ipairs(core.magic.spells.records) do
        if spell.starterSpellFlag then
            selectStarterSpell(spell, context)
        end
    end
    return context.selectedSpells
end

return {
    getPlayerInnateSpellIds = getPlayerInnateSpellIds,
    autoCalcPlayerSpells = autoCalcPlayerSpells,
}