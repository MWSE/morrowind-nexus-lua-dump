local core = require("openmw.core")
local types = require("openmw.types")
local omw_self = require("openmw.self")

require("scripts.TrulyConstantEffects.general_utils.tables")

RelevantEffectIds = {
    [core.magic.EFFECT_TYPE.Invisibility] = true,

    [core.magic.EFFECT_TYPE.SummonAncestralGhost] = true,
    [core.magic.EFFECT_TYPE.SummonBear] = true,
    [core.magic.EFFECT_TYPE.SummonBonelord] = true,
    [core.magic.EFFECT_TYPE.SummonBonewalker] = true,
    [core.magic.EFFECT_TYPE.SummonBonewolf] = true,
    [core.magic.EFFECT_TYPE.SummonCenturionSphere] = true,
    [core.magic.EFFECT_TYPE.SummonClannfear] = true,
    [core.magic.EFFECT_TYPE.SummonDaedroth] = true,
    [core.magic.EFFECT_TYPE.SummonDremora] = true,
    [core.magic.EFFECT_TYPE.SummonFabricant] = true,
    [core.magic.EFFECT_TYPE.SummonFlameAtronach] = true,
    [core.magic.EFFECT_TYPE.SummonFrostAtronach] = true,
    [core.magic.EFFECT_TYPE.SummonGoldenSaint] = true,
    [core.magic.EFFECT_TYPE.SummonGreaterBonewalker] = true,
    [core.magic.EFFECT_TYPE.SummonHunger] = true,
    [core.magic.EFFECT_TYPE.SummonScamp] = true,
    [core.magic.EFFECT_TYPE.SummonSkeletalMinion] = true,
    [core.magic.EFFECT_TYPE.SummonStormAtronach] = true,
    [core.magic.EFFECT_TYPE.SummonWingedTwilight] = true,
    [core.magic.EFFECT_TYPE.SummonWolf] = true,
}

---Wrapper for RelevantEffectIds to ensure boolean result with no nils
---@param effectId string
---@return boolean
function EffectIsRelevant(effectId)
    if RelevantEffectIds[effectId] == nil then return false end
    return true
end

---Returns a list of all spells wich are contant effect
---@return table
function GetActiveConstSpells()
    local constEquipmentSpells = {}

    -- for whatever reason dead summons and broken invis still count as active spells
    for _, spell in pairs(types.Actor.activeSpells(omw_self)) do
        local item = spell.item

        -- if spell source is an item
        if item ~= nil then
            local itemRecord = item.type.records[item.recordId]
            local enchantmentRecord = core.magic.enchantments.records[itemRecord.enchant]

            -- if enchantment on the item is constant
            if enchantmentRecord.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                -- check if its a relevant effect for us
                for _, effect in ipairs(enchantmentRecord.effects) do
                    if RelevantEffectIds[effect.id] then
                        table.insert(constEquipmentSpells, spell)
                        break
                    end
                end
            end
        end
    end

    return constEquipmentSpells
end

---Designed to work with only GetActiveConstSpells()
---@param activeConstSpells table
function PrintConstEquipmentSpellsInfo(activeConstSpells)
    for id, params in ipairs(activeConstSpells) do
        print('active spell ' .. tostring(id) .. ':')
        print('  name: ' .. tostring(params.name))
        print('  id: ' .. tostring(params.id))
        print('  item: ' .. tostring(params.item))
        print('  caster: ' .. tostring(params.caster))
        print('  effects: ' .. tostring(params.effects))
        if not TableIsEmpty(params.effects) then
            for _, effect in pairs(params.effects) do
                print('  -> effects[' .. tostring(effect) .. ']:')
                print('       id: ' .. tostring(effect.id))
                print('       name: ' .. tostring(effect.name))
                print('       affectedSkill: ' .. tostring(effect.affectedSkill))
                print('       affectedAttribute: ' .. tostring(effect.affectedAttribute))
                print('       magnitudeThisFrame: ' .. tostring(effect.magnitudeThisFrame))
                print('       minMagnitude: ' .. tostring(effect.minMagnitude))
                print('       maxMagnitude: ' .. tostring(effect.maxMagnitude))
                print('       duration: ' .. tostring(effect.duration))
                print('       durationLeft: ' .. tostring(effect.durationLeft))
                print("\n")
            end
        else
            print('  -> No effects in the list :(')
        end
    end
    print("\n\n\n")
end

---Counts all effects from active const spells (including TCE semi-constant ones)
---and constant spells from equipment
---@return { spellEffectCounts: table, enchEffectCounts: table }
function CountEffects()
    local spellEffectCounts = {}
    local enchEffectCounts = {}

    for _, spell in ipairs(GetActiveConstSpells()) do
        -- r e a d a b i l i t y
        local item = spell.item
        local itemRecord = item.type.records[item.recordId]
        local enchantmentRecord = core.magic.enchantments.records[itemRecord.enchant]

        -- count active spells
        for _, effect in pairs(spell.effects) do
            if EffectIsRelevant(effect.id) then
                if spellEffectCounts[effect.id] == nil then
                    spellEffectCounts[effect.id] = 1
                else
                    spellEffectCounts[effect.id] = spellEffectCounts[effect.id] + 1
                end
            end
        end
        -- count enchantment spells
        for _, effect in pairs(enchantmentRecord.effects) do
            if EffectIsRelevant(effect.id) then
                if enchEffectCounts[effect.id] == nil then
                    enchEffectCounts[effect.id] = 1
                else
                    enchEffectCounts[effect.id] = enchEffectCounts[effect.id] + 1
                end
            end
        end
    end

    -- add TCE spells to the enchantmentCount
    for _, spell in pairs(types.Actor.activeSpells(omw_self)) do
        if string.find(spell.id, "^tce_") then
            local effect = spell.effects[1]
            
            -- no clue how a spell can have no effects, but sure
            if effect == nil then goto continue end

            if spellEffectCounts[effect.id] == nil then
                spellEffectCounts[effect.id] = 1
            else
                spellEffectCounts[effect.id] = spellEffectCounts[effect.id] + 1
            end
        end
        ::continue::
    end

    return {
        spellEffectCounts = spellEffectCounts,
        enchEffectCounts = enchEffectCounts
    }
end
