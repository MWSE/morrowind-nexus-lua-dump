--[[
ErnEnchantersRecharge for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local core = require('openmw.core')
--- Get the charge multiplier for an enchantment type from game settings.
--- These multipliers determine how many charge points are added per base cost point.
---
--- @param enchantmentType any The enchantment type (one of core.magic.ENCHANTMENT_TYPE values)
---@return number The charge multiplier
local function getChargeMultiplier(enchantmentType)
    if enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnce then
        return core.getGMST('iMagicItemChargeOnce') or 1
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
        return core.getGMST('iMagicItemChargeStrike') or 1
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnUse then
        return core.getGMST('iMagicItemChargeUse') or 1
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return core.getGMST('iMagicItemChargeConst') or 1
    end

    return 1
end

--- Calculate the cost of a single magic effect within an enchantment context.
--- Uses the enchantment cost formula which differs from spell and potion costs.
---
--- @param effect any The magic effect with parameters (mData field)
--- @param enchantmentType any The enchantment type for context
--- @return number The calculated cost of this effect
local function getEffectCost(effect, enchantmentType)
    if not effect then
        print("no effect data")
        return 0
    end

    local fEffectCostMult = core.getGMST('fEffectCostMult') or 1.0
    local fEnchantmentConstantDurationMult = core.getGMST('fEnchantmentConstantDurationMult') or 1.0

    -- Get magic effect base cost
    local magicEffect = core.magic.effects.records[effect.id]
    -- magicEffect is a MagicEffect
    if not magicEffect then
        print("unknown magic effect")
        return 0
    end

    local baseCost = magicEffect.baseCost or 0

    -- Ensure min/max magnitude and area are at least 1
    local magMin = math.max(1, effect.magnitudeMin or 0)
    local magMax = math.max(1, effect.magnitudeMax or 0)
    local area = math.max(1, effect.area or 0)

    local duration = effect.duration or 0
    if enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        duration = fEnchantmentConstantDurationMult
    end

    -- Vanilla enchant cost formula:
    -- ((min + max) * duration + area) * baseCost * fEffectCostMult * 0.05
    local cost = ((magMin + magMax) * duration + area) * baseCost * fEffectCostMult * 0.05

    -- Ensure minimum cost of 1
    cost = math.max(1.0, cost)

    -- Apply target range multiplier
    if effect.range == 2 then -- ESM::RT_Target
        cost = cost * 1.5
    end

    return cost
end

--- Calculate the maximum enchantment points available on an item.
--- This is the capacity of an item to be enchanted, based on its type and base properties.
---
--- @param item any The item object (enchantable item)
--- @return number The maximum enchantment points available
local function getMaxEnchantmentPoints(item)
    if not item then
        return 0
    end

    -- Get the enchantment points from the item class
    local enchantPoints = item.enchantmentPoints or 0

    -- Multiply by the enchantment multiplier setting
    local fEnchantmentMult = core.getGMST('fEnchantmentMult') or 1.0

    return math.floor(enchantPoints * fEnchantmentMult)
end

--- Calculate the maximum charge capacity for an enchanted item.
---
--- The maximum charge depends on three factors:
--- 1. The enchantment record's charge capacity (from enchantment.charge)
--- 2. Whether the enchantment uses autocalc
--- 3. The enchantment type (CastOnce, WhenStrikes, WhenUsed, ConstantEffect)
---
--- For autocalc enchantments, the charge is calculated based on effect costs and game settings.
--- For constant effect enchantments, the maximum charge is 0 (they don't consume charge).
--- For other types, the charge multiplier from game settings determines the final capacity.
---
--- @param enchantment any The enchantment record (from core.magic.enchantments.records)
--- @return number The maximum charge capacity for this enchantment
local function getMaxEnchantmentCharge(enchantment)
    if not enchantment then
        return 0
    end

    -- Constant effect enchantments have no charge
    if enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return 0
    end

    -- If autocalc flag is set, calculate charge from effect costs
    if enchantment.isAutocalc then
        local baseCost = 0

        -- Sum up all effect costs
        for _, effect in ipairs(enchantment.effects) do
            -- effect is a MagicEffectWithParams
            baseCost = baseCost + getEffectCost(effect, enchantment.type)
        end

        -- Round to nearest integer
        baseCost = math.floor(baseCost + 0.5)

        -- Apply type-specific multiplier from game settings
        local chargeMultiplier = getChargeMultiplier(enchantment.type)
        return baseCost * chargeMultiplier
    end

    -- Otherwise, use the stored charge value from the enchantment record
    return enchantment.charge
end

return {
    getMaxEnchantmentCharge = getMaxEnchantmentCharge,
    getChargeMultiplier = getChargeMultiplier,
    getEffectCost = getEffectCost,
    getMaxEnchantmentPoints = getMaxEnchantmentPoints,
}
