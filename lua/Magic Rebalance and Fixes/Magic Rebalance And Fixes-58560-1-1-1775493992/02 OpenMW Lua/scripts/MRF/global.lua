local core = require('openmw.core')
local async = require('openmw.async')
local T = require("openmw.types")
local I = require("openmw.interfaces")

local mStore = require("scripts.MRF.config.store")
mStore.registerGroups()
local mDef = require("scripts.MRF.config.definition")
local mTypes = require("scripts.MRF.config.types")
local mH = require("scripts.MRF.util.helpers")
local log = require("scripts.MRF.util.log")

local function getResistEffects(effects)
    local resistList = {}
    for _, effect in ipairs(effects) do
        local resistEffect = mTypes.resistedEffects[effect.id]
        if resistEffect then
            resistList[resistEffect] = true
        end
    end
    return resistList
end

local refreshActiveSpellCallback = async:registerTimerCallback(mDef.callbacks.refreshActiveSpell, function(data)
    if not mStore.settings.enforceConstantEnchantmentDebuffs.value then return end
    local actor, item, effectCount = data.actor, data.item, data.effectCount
    if not T.Actor.hasEquipped(actor, item) then
        log(string.format("Item \"%s\" is no longer equipped", item.recordId))
        return
    end
    local activeSpells = T.Actor.activeSpells(actor)
    if activeSpells:isSpellActive(item.recordId) then
        activeSpells:remove(item.recordId)
    end
    activeSpells:add({ id = item.recordId, effects = mH.countToList(effectCount), item = item, caster = actor })
    log(string.format("Spell \"%s\" has been refreshed", item.recordId))
end)

local function onEquip(item, actor)
    if not mStore.settings.enforceConstantEnchantmentDebuffs.value then return end
    if actor.type ~= T.Player then return end
    local record = item.type.record(item)
    if not record.enchant then return end
    local enchant = core.magic.enchantments.records[record.enchant]
    if not enchant then
        print("Missing enchant " .. record.enchant)
        return
    end
    if enchant.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then return end
    local resistEffects = getResistEffects(enchant.effects)
    if not next(resistEffects) then return end
    local durations = {}
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.temporary then
            for _, effect in ipairs(spell.effects) do
                if resistEffects[effect.id] then
                    local duration = math.floor(0.5 + effect.durationLeft * 10) / 10
                    durations[tostring(duration)] = duration + 0.1
                end
            end
        end
    end
    for _, duration in pairs(durations) do
        async:newSimulationTimer(duration, refreshActiveSpellCallback, { actor = actor, item = item, effectCount = #enchant.effects })
    end
end

I.ItemUsage.addHandlerForType(T.Armor, onEquip)
I.ItemUsage.addHandlerForType(T.Clothing, onEquip)
I.ItemUsage.addHandlerForType(T.Weapon, onEquip)