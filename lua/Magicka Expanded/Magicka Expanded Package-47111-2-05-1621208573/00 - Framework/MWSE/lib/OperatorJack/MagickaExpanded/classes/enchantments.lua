local common = require("OperatorJack.MagickaExpanded.common")

local this = {}

--[[
    Description: Updates an Enchantment based on the given @params,
        and adds it to the framework's list of managed Enchantments. Accepts one
        magic effect.

    @params: A table of parameters used to configure the Enchantment. @params
        must be in the following format:

    example = {
        id = "exampleEnchantmentId",
        effect = tes3.effect.*,
        range = tes3.effectRange.* | nil,
        min = [int] | nil,
        max = [int] | nil,
        duration = [int] | nil,
        radius = [int] | nil
    }

    Table parameter options marked as | nil are optional. Table parameter options marked
        with .* must use a value found in the table set. Table parameter options marked
        with [int] must be an integer.
]]
this.createBasicEnchantment = function(params)
    local enchantment = tes3.getObject(params.id) or tes3enchantment.create({
        id = params.id,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1,
        maxCharge = 1
    })

    local effect = enchantment.effects[1]
    effect.id = params.effect
    effect.rangeType = params.range or tes3.effectRange.self
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

--[[
    Description: Creates or updates a Enchantment based on the given @params,
        and adds it to the framework's list of managed Enchantments. Accepts multiple
        magic effects.

    @params: A table of parameters used to configure the Enchantment. @params
        must be in the following format:

    example = {
        id = "exampleEnchantmentId",
        effects = {
            [1] = {
                id = tes3.effect.*,
                range = tes3.effectRange.* | nil,
                min = [int] | nil,
                max = [int] | nil,
                duration = [int] | nil,
                radius = [int] | nil
            },
            [2] = {
                id = tes3.effect.*,
                range = tes3.effectRange.* | nil,
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
this.createComplexEnchantment = function(params)
    local enchantment = tes3.getObject(params.id) or tes3enchantment.create({
        id = params.id,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1,
        maxCharge = 1
    })

    for i=1, #params.effects do
        local effect = enchantment.effects[i]
        local newEffect = params.effects[i]

        effect.id = newEffect.id
        effect.rangeType = newEffect.range or tes3.effectRange.self
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