local core = require('openmw.core')
local T = require('openmw.types')

local log = require('scripts.FairCare.util.log')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

local fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance")
local fEffectCostMult = core.getGMST("fEffectCostMult")
local iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin")
local iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax")
local fCombatDistance = core.getGMST("fCombatDistance")
local fFatigueBase = core.getGMST("fFatigueBase")
local fFatigueMult = core.getGMST("fFatigueMult")

module.fFatigueBase = fFatigueBase
module.restoreHealthModel = T.Static.record(core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].castStatic).model
module.healCastSound = core.stats.Skill.records.restoration.school.castSound
module.hitHealthModel = T.Static.record(core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].hitStatic).model
module.healHitSound = core.stats.Skill.records.restoration.school.hitSound
module.healFailSound = core.stats.Skill.records.restoration.school.failureSound

local function getAvailableEquipmentWithEffects(actor, filter, effectName)
    local items = {}
    local count = 0
    for _, itemType in ipairs({ T.Armor, T.Book, T.Clothing, T.Potion, T.Weapon }) do
        for _, item in ipairs(T.Actor.inventory(actor):getAll(itemType)) do
            if itemType == T.Book or itemType == T.Potion or T.Actor.hasEquipped(actor, item) then
                local record, effects, available = item.type.record(item)
                if record.enchant then
                    local enchantment = core.magic.enchantments.records[record.enchant]
                    effects = enchantment.effects
                    available = T.Item.itemData(item).enchantmentCharge - module.getSpellCost(enchantment, true) >= 0
                elseif record.effects then
                    effects = record.effects
                    available = true
                end
                if effects and available and filter(effects) then
                    if not items[itemType] then
                        items[itemType] = {}
                    end
                    table.insert(items[itemType], item)
                    count = count + 1
                end
            end
        end
    end
    if count ~= 0 then
        log(string.format("%s has %d available items with %s effect", mTools.objectId(actor), count, effectName))
    end
    return items
end

module.spellCostMagickaRatio = function(actor, spellId)
    local spell = core.magic.spells.records[spellId]
    local magicka = T.Actor.stats.dynamic.magicka(actor).current
    return magicka > 0 and module.getSpellCost(spell) / magicka or math.huge
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

local function getActorSkillBase(actor, skillId)
    if actor.type == T.Creature then
        return T.Creature.record(actor).magicSkill
    else
        return T.NPC.stats.skills[skillId] and T.NPC.stats.skills[skillId](actor).base or nil
    end
end

local function getEffectsAverageRestoredHealth(effects)
    local hp = 0
    for _, effect in ipairs(effects) do
        if effect.id == core.magic.EFFECT_TYPE.RestoreHealth then
            hp = hp + (effect.magnitudeMin + effect.magnitudeMax) / 2 * effect.duration
        end
    end
    return hp
end

local function getEffectsAverageRestoredHealthPerSec(effects)
    local hp = 0
    for _, effect in ipairs(effects) do
        if effect.id == core.magic.EFFECT_TYPE.RestoreHealth then
            hp = hp + (effect.magnitudeMin + effect.magnitudeMax) / 2
        end
    end
    return hp
end

module.getPotionStats = function(potionId)
    local record = T.Potion.records[potionId]
    return {
        restoredHealth = getEffectsAverageRestoredHealth(record.effects),
        value = record.value,
    }
end

module.getSpellAverageRestoredHealth = function(spellId)
    return getEffectsAverageRestoredHealth(core.magic.spells.records[spellId].effects)
end

local function hasSelfHealEffect(effects)
    for _, effect in ipairs(effects) do
        if effect.range == core.magic.RANGE.Self and effect.id == core.magic.EFFECT_TYPE.RestoreHealth then
            return true
        end
    end
    return false
end

module.getSelfHealingEquipment = function(actor)
    return getAvailableEquipmentWithEffects(
            actor,
            function(effects) return hasSelfHealEffect(effects) end,
            "self restore health"
    )
end

module.getEasiestSelfHealSpellId = function(actor)
    local minCost, minSpellId = math.huge
    for _, spell in pairs(T.Actor.spells(actor)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            if module.getSpellCost(spell) < minCost and hasSelfHealEffect(spell.effects) then
                minSpellId = spell.id
                minCost = module.getSpellCost(spell)
            end
        end
    end
    return minSpellId
end

module.getBestPotion = function(potions)
    local bestValue = 0
    local bestPotion
    for _, potion in ipairs(potions) do
        local value = getEffectsAverageRestoredHealthPerSec(potion.type.record(potion).effects)
        if value > bestValue then
            bestValue = value
            bestPotion = potion
        end
    end
    return bestPotion
end

local autoCalcSpellCostCache = {}

local function getAutoCalcEffectCost(effect, isEnchant)
    local minMagnitude = effect.effect.hasMagnitude and effect.magnitudeMin or 1
    local maxMagnitude = effect.effect.hasMagnitude and effect.magnitudeMax or 1
    if not isEnchant then
        minMagnitude = math.max(1, minMagnitude)
        maxMagnitude = math.max(1, maxMagnitude)
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
    ) * fEffectCostMult

    if effect.range == core.magic.RANGE.Target then
        cost = cost * 1.5
    end
    return math.max(0, cost)
end

module.getSpellCost = function(spell, isEnchant)
    if not spell.autocalcFlag then
        return spell.cost
    end
    if autoCalcSpellCostCache[spell.id] then
        return autoCalcSpellCostCache[spell.id]
    end
    local cost = 0
    for _, effect in ipairs(spell.effects) do
        cost = cost + getAutoCalcEffectCost(effect, isEnchant)
    end
    cost = math.floor(0.5 + cost)
    autoCalcSpellCostCache[spell.id] = cost
    return cost
end

local function calcWeakestSchool(spell, actor)
    local minChance, skillTerm, effectiveSchool = math.huge, 0
    for _, effect in ipairs(spell.effects) do
        local cost = getAutoCalcEffectCost(effect)
        local minSkillTerm, skillBase = 0, getActorSkillBase(actor, effect.effect.school)
        if skillBase then
            minSkillTerm = 2 * skillBase
        end
        if minSkillTerm - cost < minChance then
            minChance = minSkillTerm - cost
            effectiveSchool = effect.effect.school
            skillTerm = minSkillTerm
        end
    end
    return effectiveSchool, skillTerm
end

module.calcAutoCastChance = function(spell, actor)
    if spell.type ~= core.magic.SPELL_TYPE.Spell then return 100 end
    if spell.alwaysSucceedFlag then return 100 end

    local _, skillTerm = calcWeakestSchool(spell, actor)

    return skillTerm - module.getSpellCost(spell)
            + 0.2 * T.Actor.stats.attributes.willpower(actor).base
            + 0.1 * T.Actor.stats.attributes.luck(actor).base
end

module.touchHealDistance = function(actor, target)
    if not target then return math.huge end
    local actorBounds, targetBounds = T.Actor.getPathfindingAgentBounds(actor), T.Actor.getPathfindingAgentBounds(target)
    return actorBounds.halfExtents.x + targetBounds.halfExtents.x + fCombatDistance
end

local function getFatigueTerm(actor)
    local fatigue = T.Actor.stats.dynamic.fatigue(actor)
    local normalised = math.floor(fatigue.base) == 0 and 1 or math.max(0, fatigue.current / fatigue.base)
    return fFatigueBase - fFatigueMult * (1 - normalised);
end

module.castChances = function(actor, spellId, castBonus)
    local autoCastChances = module.calcAutoCastChance(core.magic.spells.records[spellId], actor)
    return ((autoCastChances + castBonus) * getFatigueTerm(actor)) / 100
end

module.isParalyzed = function(actor)
    return T.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0
end

module.isSilenced = function(actor)
    return T.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Silence).magnitude > 0
end

module.getSoundEffect = function(actor)
    return T.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Sound).magnitude
end

return module