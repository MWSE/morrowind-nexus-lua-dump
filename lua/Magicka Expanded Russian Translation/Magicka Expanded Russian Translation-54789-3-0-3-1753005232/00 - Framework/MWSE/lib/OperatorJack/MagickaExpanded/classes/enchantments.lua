local common = require("OperatorJack.MagickaExpanded.common")

--- Enchantments module for interacting with enchantment objects.
---@class MagickaExpanded.Enchantments
local this = {}

---@class MagickaExpanded.Enchantments.createBasicEnchantmentParams
---@field id string Enchantment ID
---@field effect tes3.effect Effect ID
---@field rangeType tes3.effectRange Effect Range
---@field min number?
---@field max number?
---@field duration number?
---@field radius number?
---@field skill tes3.skill?
---@field attribute tes3.attribute?
---@field chargeCost number?
---@field maxCharge number?
---@field castType tes3.enchantmentType

--[[
    Updates an Enchantment based on the given @params,
        and adds it to the framework's list of managed Enchantments. Accepts one
        magic effect.

    @params: A table of parameters used to configure the Enchantment. @params
        must be in the following format:

    example = {
        id = "exampleEnchantmentId",
        effect = tes3.effect.*,
        rangeType = tes3.effectRange.* | nil,
        min = [int] | nil,
        max = [int] | nil,
        duration = [int] | nil,
        radius = [int] | nil
    }

    Table parameter options marked as | nil are optional. Table parameter options marked
        with .* must use a value found in the table set. Table parameter options marked
        with [int] must be an integer.
]]
---@param params MagickaExpanded.Enchantments.createBasicEnchantmentParams
---@return tes3enchantment
this.createBasicEnchantment = function(params)
    local enchantment = tes3.createObject({
        id = params.id,
        objectType = tes3.objectType.enchantment,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1,
        maxCharge = 1
    }) --[[@as tes3enchantment]]

    local effect = enchantment.effects[1]
    effect.id = params.effect
    effect.rangeType = params.rangeType or params.range or tes3.effectRange.self
    effect.min = params.min or 0
    effect.max = params.max or 0
    effect.duration = params.duration or 0
    effect.radius = params.radius or 0
    effect.skill = params.skill or -1
    effect.attribute = params.attribute or -1

    enchantment.chargeCost = params.chargeCost or 0
    enchantment.maxCharge = params.maxCharge or 0
    enchantment.castType = params.castType or tes3.enchantmentType.onUse

    common.addEnchantmentToEnchantmentsList(enchantment)

    return enchantment
end

---@class MagickaExpanded.Enchantments.createComplexEnchantmentParams
---@field id string Enchantment ID
---@field effects MagickaExpanded.Effects.Effect[]
---@field chargeCost number?
---@field maxCharge number?
---@field castType tes3.enchantmentType

--[[
    Creates or updates a Enchantment based on the given @params,
        and adds it to the framework's list of managed Enchantments. Accepts multiple
        magic effects.

    @params: A table of parameters used to configure the Enchantment. @params
        must be in the following format:

    example = {
        id = "exampleEnchantmentId",
        effects = {
            [1] = {
                id = tes3.effect.*,
                rangeType = tes3.effectRange.* | nil,
                min = [int] | nil,
                max = [int] | nil,
                duration = [int] | nil,
                radius = [int] | nil
            },
            [2] = {
                id = tes3.effect.*,
                rangeType = tes3.effectRange.* | nil,
                min = [int] | nil,
                max = [int] | nil,
                duration = [int] | nil,
                radius = [int] | nil
            }
            ...
            [8] = {}
        }
    }

    Table parameter options marked as | nil are optional. Table parameter options marked
        with .* must use a value found in the table set. Table parameter options marked
        with [int] must be an integer. @params.effects may only contain up to 8 entries.
]]
---@param params MagickaExpanded.Enchantments.createComplexEnchantmentParams
---@return tes3enchantment
this.createComplexEnchantment = function(params)
    local enchantment = tes3.createObject({
        id = params.id,
        objectType = tes3.objectType.enchantment,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1,
        maxCharge = 1
    }) --[[@as tes3enchantment]]

    for i = 1, #params.effects do
        local effect = enchantment.effects[i]
        local newEffect = params.effects[i]

        effect.id = newEffect.id
        effect.rangeType = newEffect.rangeType or newEffect.range or tes3.effectRange.self
        effect.min = newEffect.min or 0
        effect.max = newEffect.max or 0
        effect.duration = newEffect.duration or 0
        effect.radius = newEffect.radius or 0
        effect.skill = newEffect.skill or -1
        effect.attribute = newEffect.attribute or -1
    end

    enchantment.chargeCost = params.chargeCost or 0
    enchantment.maxCharge = params.maxCharge or 0
    enchantment.castType = params.castType or tes3.enchantmentType.onUse

    common.addEnchantmentToEnchantmentsList(enchantment)

    return enchantment
end

return this
