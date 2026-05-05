local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')

local log = require('scripts.NCG.util.log')
local mCore = require('scripts.NCG.util.core')

local module = {}

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
    ) * mCore.GMSTs.fEffectCostMult

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

local function getSpellStats(spell, player)
    local minChance = math.huge
    local effectiveSchool
    local minSkillTerm = 0
    local schoolImpacts = {}
    for _, effect in ipairs(spell.effects) do
        local cost = getAutoCalcEffectCost(effect)
        schoolImpacts[effect.effect.school] = (schoolImpacts[effect.effect.school] or 0) + cost

        local skillTerm = 0
        local skill = T.NPC.stats.skills[effect.effect.school]
        if skill then
            skillTerm = 2 * skill(player).base;
        end
        if skillTerm - cost < minChance then
            minChance = skillTerm - cost
            effectiveSchool = effect.effect.school
            minSkillTerm = skillTerm
        end
    end
    return effectiveSchool, minSkillTerm, schoolImpacts
end

module.calcAutoCastChance = function(spell, player)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm, _ = getSpellStats(spell, player)

    return skillTerm - getSpellCost(spell)
            + 0.2 * T.Actor.stats.attributes.willpower(player).base
            + 0.1 * T.Actor.stats.attributes.luck(player).base
end

local function attrSkillCheck(spell, context)
    for _, effect in ipairs(spell.effects) do
        if effect.affectedSkill then
            local skill = T.NPC.stats.skills[effect.affectedSkill]
            if not skill or skill(context.player).base < mCore.GMSTs.iAutoSpellAttSkillMin then
                return false
            end
        end
        if effect.affectedAttribute then
            local attribute = T.Actor.stats.attributes[effect.affectedAttribute]
            if not attribute or attribute(context.player).base < mCore.GMSTs.iAutoSpellAttSkillMin then
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
    if module.calcAutoCastChance(spell, context.player) < mCore.GMSTs.fAutoPCSpellChance then return end
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
        if #context.selectedSpells == mCore.GMSTs.iAutoPCSpellMax then
            context.reachedLimit = true
        end
    end
end

local function getPlayerInnateSpellIds(player)
    local baseSpellIds = {}
    local birthSign = T.Player.birthSigns.record(T.Player.getBirthSign(player))
    if birthSign ~= nil then
        for _, spellId in pairs(birthSign.spells) do
            baseSpellIds[spellId] = true
        end
    end
    local race = T.Player.races.record(T.Player.record(player).race)
    for _, spellId in pairs(race.spells) do
        baseSpellIds[spellId] = true
    end
    return baseSpellIds
end

local function autoCalcPlayerSpells(player)
    local context = {
        player = player,
        baseMagicka = mCore.GMSTs.fPCbaseMagickaMult * T.Actor.stats.attributes.intelligence(player).base,
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

module.updateStarterSpells = function()
    local baseSpellIds = getPlayerInnateSpellIds(self)
    for _, spell in pairs(T.Player.spells(self)) do
        if spell.starterSpellFlag and not baseSpellIds[spell.id] then
            T.Player.spells(self):remove(spell.id)
            log(string.format("Removed existing starter spell: %s", spell.id))
        end
    end

    local starterSpells = autoCalcPlayerSpells(self)
    for _, spellId in ipairs(starterSpells) do
        T.Player.spells(self):add(spellId)
        log(string.format("Added starter spell: %s", spellId))
    end
end

return module