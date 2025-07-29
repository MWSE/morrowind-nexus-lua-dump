local common = require("OperatorJack.MagickaExpanded.common")

--- Alchemy module for interacting with potion objects.
---@class MagickaExpanded.Alchemy
local this = {}

---@class MagickaExpanded.Alchemy.createBasicPotionParams
---@field id string Potion ID
---@field effect tes3.effect Effect ID
---@field name string Potion Name
---@field rangeType tes3.effectRange Effect Range
---@field min number?
---@field max number?
---@field duration number?
---@field radius number?
---@field skill tes3.skill?
---@field attribute tes3.attribute?
---@field magickaCost number?
--[[
    Creates or updates a potion based on the given @params,
        and adds it to the framework's list of managed potions. Accepts one
        magic effect.

    @params: A table of parameters used to configure the potion. @params
        must be in the following format:

    example = {
        id = "examplePotionId",
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
---@param params MagickaExpanded.Alchemy.createBasicPotionParams
---@return tes3alchemy
this.createBasicPotion = function(params)
    local potion = tes3.createObject({id = params.id, objectType = tes3.objectType.alchemy}) --[[@as tes3alchemy]]

    potion.name = params.name

    local effect = potion.effects[1]
    effect.id = params.effect
    effect.rangeType = params.rangeType or params.range or tes3.effectRange.self
    effect.min = params.min or 0
    effect.max = params.max or 0
    effect.duration = params.duration or 0
    effect.radius = params.radius or 0
    effect.skill = params.skill or -1
    effect.attribute = params.attribute or -1

    common.addPotionToPotionsList(potion)

    return potion
end

---@class MagickaExpanded.Alchemy.createComplexPotionParams
---@field id string Potion ID
---@field name string
---@field magickaCost number?
---@field effects MagickaExpanded.Effects.Effect[]
--[[
    Creates or updates a potion based on the given @params,
        and adds it to the framework's list of managed potions. Accepts multiple
        magic effects.

    @params: A table of parameters used to configure the potion. @params
        must be in the following format:

example = {
    id = "examplePotionId",
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
---@param params MagickaExpanded.Alchemy.createComplexPotionParams
---@return tes3alchemy
this.createComplexPotion = function(params)
    local potion = tes3.createObject({id = params.id, objectType = tes3.objectType.alchemy}) --[[@as tes3alchemy]]

    potion.name = params.name

    for i = 1, #params.effects do
        local effect = potion.effects[i]
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

    common.addPotionToPotionsList(potion)

    return potion
end

return this
