local core = require('openmw.core')
local T = require("openmw.types")

local mTypes = require("scripts.MRF.config.types")
local log = require("scripts.MRF.util.log")

local Attributes = core.stats.Attribute.records
local Skills = core.stats.Skill.records
local EffectTypes = core.magic.EFFECT_TYPE

local module = {}

local realTimeEffects = {
    [EffectTypes.AbsorbAttribute] = { affectedAttribute = { Attributes.personality.id, Attributes.luck.id } },
    [EffectTypes.AbsorbFatigue] = {},
    [EffectTypes.AbsorbSkill] = { affectedSkill = { Skills.mercantile.id, Skills.speechcraft.id } },
    [EffectTypes.Charm] = {},
    [EffectTypes.DrainAttribute] = { affectedAttribute = { Attributes.personality.id, Attributes.luck.id } },
    [EffectTypes.DrainFatigue] = {},
    [EffectTypes.DrainSkill] = { affectedSkill = { Skills.mercantile.id, Skills.speechcraft.id } },
    [EffectTypes.FortifyAttribute] = { affectedAttribute = { Attributes.personality.id, Attributes.luck.id } },
    [EffectTypes.FortifyFatigue] = {},
    [EffectTypes.FortifySkill] = { affectedSkill = { Skills.mercantile.id, Skills.speechcraft.id } },
    [EffectTypes.FrenzyHumanoid] = {},
}

local absorbEffects = {
    { EffectTypes.AbsorbAttribute, Attributes.personality.id },
    { EffectTypes.AbsorbAttribute, Attributes.luck.id },
    { EffectTypes.AbsorbFatigue },
    { EffectTypes.AbsorbSkill, Skills.mercantile.id },
    { EffectTypes.AbsorbSkill, Skills.speechcraft.id },
}

module.getConstantEffects = function(item)
    local record = item.type.record(item)
    if not record.enchant then return end
    local enchant = core.magic.enchantments.records[record.enchant]
    if not enchant then
        print("Missing enchant " .. record.enchant)
        return
    end
    if enchant.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then return end
    return enchant.effects
end

module.getResistEffectsForEffects = function(effects)
    local resistList = {}
    for i = 1, #effects do
        local resistEffect = mTypes.resistedEffects[effects[i].id]
        if resistEffect then
            resistList[resistEffect] = true
        end
    end
    return resistList
end

module.getActorSpecificEffectDurations = function(actor, effectSelection)
    local durations = {}
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.temporary then
            local effect
            for i = 1, #spell.effects do
                effect = spell.effects[i]
                if effectSelection[effect.id] then
                    local duration = math.floor(0.5 + effect.durationLeft * 10) / 10
                    durations[tostring(duration)] = duration + 0.1 -- +0.1 to be sure the effect has expired
                end
            end
        end
    end
    return durations
end

module.refreshActiveItemSpell = function(actor, item, effectIndexes)
    if not T.Actor.hasEquipped(actor, item) then
        log(string.format("Item \"%s\" is no longer equipped", item.recordId))
        return
    end
    local activeSpells = T.Actor.activeSpells(actor)
    if activeSpells:isSpellActive(item.recordId) then
        activeSpells:remove(item.recordId)
    end
    activeSpells:add({ id = item.recordId, effects = effectIndexes, item = item, caster = actor })
    log(string.format("Spell \"%s\" has been refreshed", item.recordId))
end

local function newTrackedEffect(effect, realTime, tracked, minDuration)
    return {
        id = effect.id,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
        index = effect.index,
        expireAt = realTime + effect.durationLeft - minDuration,
        tracked = tracked,
    }
end

module.getActiveSpellEffectExpirations = function(trackedEffects, otherEffects, minDuration)
    local effectDurations = {}
    local realTime = core.getRealTime()
    for i = 1, #trackedEffects do
        effectDurations[#effectDurations + 1] = newTrackedEffect(trackedEffects[i], realTime, true, minDuration)
    end
    for i = 1, #otherEffects do
        effectDurations[#effectDurations + 1] = newTrackedEffect(otherEffects[i], realTime, false, 0)
    end
    return effectDurations
end

module.effectsToExpirations = function(effects, realTime)
    local exp = {}
    for i = 1, #effects do
        exp[#exp + 1] = string.format("%s: %.2fs", effects[i].id, effects[i].expireAt - realTime)
    end
    return table.concat(exp, ", ")
end

module.isRealTimeEffect = function(effect)
    local conditions = realTimeEffects[effect.id]
    if not conditions then return false end
    if not next(conditions) then return true end
    for field, values in pairs(conditions) do
        for i = 1, #values do
            if effect[field] == values[i] then
                return true
            end
        end
    end
    return false
end

module.getRealTimeEffects = function(spell)
    local trackedEffects = {}
    local otherEffects = {}
    for i = 1, #spell.effects do
        local effect = spell.effects[i]
        if module.isRealTimeEffect(effect) then
            trackedEffects[#trackedEffects + 1] = effect
        else
            otherEffects[#otherEffects + 1] = effect
        end
    end
    return trackedEffects, otherEffects
end

module.hasTrackedEffects = function(actor)
    local activeEffects = T.Actor.activeEffects(actor)
    for _, effect in ipairs(absorbEffects) do
        if activeEffects:getEffect(effect[1], effect[2]).magnitude > 0 then
            return true
        end
    end
    return false
end

return module