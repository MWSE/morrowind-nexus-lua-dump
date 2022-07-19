local common = require("OperatorJack.MagickaExpanded.common")

local this = {}

--[[
    Description: Creates or updates a potion based on the given @params,
        and adds it to the framework's list of managed potions. Accepts one
        magic effect.

    @params: A table of parameters used to configure the potion. @params
        must be in the following format:

    example = {
        id = "examplePotionId",
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
this.createBasicPotion = function(params)
    local potion = tes3.getObject(params.id) or tes3alchemy.create({
        id = params.id,
        name = params.name,
    })

    potion.name = params.name

    local effect = potion.effects[1]
    effect.id = params.effect
    effect.rangeType = params.range or tes3.effectRange.self
    effect.min = params.min or 0
    effect.max = params.max or 0
    effect.duration = params.duration or 0
    effect.radius = params.radius or 0
    effect.skill = params.skill or -1
    effect.attribute = params.attribute or -1

    common.addPotionToPotionsList(potion)

    return potion
end

--[[
    Description: Creates or updates a potion based on the given @params,
        and adds it to the framework's list of managed potions. Accepts multiple
        magic effects.

    @params: A table of parameters used to configure the potion. @params
        must be in the following format:

example = {
    id = "examplePotionId",
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
this.createComplexPotion = function(params)
    local potion = tes3.getObject(params.id) or tes3alchemy.create({
        id = params.id,
        name = params.name,
    })

    potion.name = params.name

    for i=1, #params.effects do
        local effect = potion.effects[i]
        local newEffect = params.effects[i]

        effect.id = newEffect.id
        effect.rangeType = newEffect.range or tes3.effectRange.target
        effect.min = newEffect.min or 0
        effect.max = newEffect.max or 0
        effect.duration = newEffect.duration or 0
        effect.radius = newEffect.radius or 0
        effect.skill = newEffect.skill or -1
        effect.attribute = newEffect.attribute or -1
    end

    common.addPotionToPotionsList(potion)

    return potion
end

return this