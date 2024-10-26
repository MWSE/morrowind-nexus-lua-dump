local core = require('openmw.core')
local T = require('openmw.types')

local mSettings = require('scripts.FairCare.settings')
local mActors = require('scripts.FairCare.actors')
local mData = require('scripts.FairCare.data')

local module = {}

local fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance")
local fEffectCostMult = core.getGMST("fEffectCostMult")
local iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin")
local iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax")
local fCombatDistance = core.getGMST("fCombatDistance")

module.restoreHealthModel = T.Static.record(core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].castStatic).model
module.healFailSound = core.stats.Skill.records['restoration'].school.failureSound
module.healHitSound = core.stats.Skill.records['restoration'].school.hitSound

local function hasAvailableEquipmentEffects(actor, filter)
    for _, itemType in ipairs({ T.Armor, T.Book, T.Clothing, T.Potion, T.Weapon }) do
        for _, item in ipairs(T.Actor.inventory(actor):getAll(itemType)) do
            if itemType == T.Book or itemType == T.Potion or T.Actor.hasEquipped(actor, item) then
                local record, effects, available = mActors.getRecord(item)
                if record.enchant then
                    local enchantment = core.magic.enchantments.records[record.enchant]
                    effects = enchantment.effects
                    available = T.Item.itemData(item).enchantmentCharge - enchantment.cost >= 0
                elseif record.effects then
                    effects = record.effects
                    available = true
                end
                if effects and available and filter(effects) then
                    mSettings.debugPrint(string.format("%s has an available %s \"%s\"", mActors.actorId(actor), mData.itemTypes[itemType], record.id))
                    return true
                end
            end
        end
    end
    return false
end
module.hasAvailableEquipmentEffects = hasAvailableEquipmentEffects

local function spellCostMagickaRatio(actor, spellId)
    local spell = core.magic.spells.records[spellId]
    local magicka = T.Actor.stats.dynamic.magicka(actor).current
    return magicka > 0 and spell.cost / magicka or math.huge
end
module.spellCostMagickaRatio = spellCostMagickaRatio

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

local function getActorSkillBase(actor, skillId)
    if actor.type == T.Creature then
        return T.Creature.record(actor).magicSkill
    else
        return T.NPC.stats.skills[skillId] and T.NPC.stats.skills[skillId](actor).base or nil
    end
end

local function getAverageRestoredHealth(spellId)
    local spell, hp = core.magic.spells.records[spellId], 0
    for _, effect in ipairs(spell.effects) do
        if effect.id == "restorehealth" then
            hp = hp + (effect.magnitudeMin + effect.magnitudeMax) / 2 * effect.duration
        end
    end
    return hp
end
module.getAverageRestoredHealth = getAverageRestoredHealth

local function hasSelfHealEffect(effects)
    for _, effect in ipairs(effects) do
        if effect.range == core.magic.RANGE.Self and effect.id == "restorehealth" then
            return true
        end
    end
    return false
end
module.hasSelfHealEffect = hasSelfHealEffect

local function getEasiestSelfHealSpellId(actor)
    local minCost, minSpellId = math.huge
    for _, spell in pairs(T.Actor.spells(actor)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            if spell.cost < minCost and hasSelfHealEffect(spell.effects) then
                minSpellId = spell.id
                minCost = spell.cost
            end
        end
    end
    return minSpellId
end
module.getEasiestSelfHealSpellId = getEasiestSelfHealSpellId

-- Dehardcoding of autoCalcPlayerSpells C++ implementation from openmw source code: apps/openmw/mwmechanics/autocalcspell.cpp

local function calcWeakestSchool(spell, actor)
    local minChance, skillTerm, effectiveSchool = math.huge, 0
    for _, effect in ipairs(spell.effects) do
        local minMagnitude, maxMagnitude = 1, 1
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
        ) * fEffectCostMult

        if effect.range == core.magic.RANGE.Target then
            x = x * 1.5
        end

        local s, skillBase = 0, getActorSkillBase(actor, effect.effect.school)
        if skillBase then
            s = 2 * skillBase
        end
        if s - x < minChance then
            minChance = s - x
            effectiveSchool = effect.effect.school
            skillTerm = s
        end
    end
    return effectiveSchool, skillTerm
end

local function calcAutoCastChance(spell, actor)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm = calcWeakestSchool(spell, actor)

    return skillTerm - spell.cost
            + 0.2 * T.Actor.stats.attributes.willpower(actor).base
            + 0.1 * T.Actor.stats.attributes.luck(actor).base
end
module.calcAutoCastChance = calcAutoCastChance

local function attrSkillCheck(spell, actor)
    for _, effect in ipairs(spell.effects) do
        if effect.affectedSkill then
            local skillBase = getActorSkillBase(actor, effect.affectedSkill)
            if not skillBase or skillBase < iAutoSpellAttSkillMin then
                return false
            end
        end
        if effect.affectedAttribute then
            local attribute = T.Actor.stats.attributes[effect.affectedAttribute]
            if not attribute or attribute(actor).base < iAutoSpellAttSkillMin then
                return false
            end
        end
        return true
    end
end

local function selectStarterSpell(spell, actor, context)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return end
    if context.reachedLimit and spell.cost <= context.minCost then return end
    if context.baseSpellIds[spell.id] then return end
    if context.baseMagicka < spell.cost then return end
    if calcAutoCastChance(spell, actor) < fAutoPCSpellChance then return end
    if not attrSkillCheck(spell, actor) then return end

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
        if #context.selectedSpells == iAutoPCSpellMax then
            context.reachedLimit = true
        end
    end
end

local function autoCalcPlayerSpells(player)
    local context = {
        baseMagicka = core.getGMST("fPCbaseMagickaMult") * T.Actor.stats.attributes.intelligence(player).base,
        reachedLimit = false,
        weakestSpell = nil,
        minCost = math.huge,
        baseSpellIds = getPlayerInnateSpellIds(player),
        selectedSpells = {},
    }
    for _, spell in ipairs(core.magic.spells.records) do
        if spell.starterSpellFlag then
            selectStarterSpell(spell, player, context)
        end
    end
    return context.selectedSpells
end
module.autoCalcPlayerSpells = autoCalcPlayerSpells

local function touchHealTargetDistance(actor, target)
    if target == nil then return math.huge end
    local actorBounds, targetBounds = actor:getBoundingBox(), target:getBoundingBox()
    return actorBounds.halfSize.y + targetBounds.halfSize.y + fCombatDistance
end
module.touchHealTargetDistance = touchHealTargetDistance

local function castChances(actor, spellId, castBonus)
    local autoCastChances = calcAutoCastChance(core.magic.spells.records[spellId], actor)
    return ((autoCastChances + castBonus) * mActors.getFatigueTerm(actor)) / 100
end
module.castChances = castChances

local castFailEffects = function(actor)
    local activeEffects = T.Actor.activeEffects(actor)
    return {
        paralyze = activeEffects:getEffect("paralyze").magnitude,
        silence = activeEffects:getEffect("silence").magnitude,
        sound = activeEffects:getEffect("sound").magnitude,
    }
end
module.castFailEffects = castFailEffects

return module