local common = require("OperatorJack.MagickaExpanded.common")

local this = {}

local function getEffectCost(effect)
    local minMagnitude = effect.min or 0
    if (minMagnitude == 0) then
        minMagnitude = 1
    end

    local maxMagnitude = effect.max or 0
    if (maxMagnitude == 0) then
        maxMagnitude = 1
    end

    local duration = effect.duration or 0
    if (duration == 0) then
        duration = 1
    end

    local area = effect.radius or 0
    if (area == 0 and effect.rangeType == tes3.effectRange.self) then
        area = 1
    end
    local baseMagickaCost = effect.object.baseMagickaCost

    local effectCost = math.floor(((minMagnitude + maxMagnitude) * (duration + 1) + area) * baseMagickaCost / 40.0)

    if (effect.rangeType == tes3.effectRange.target) then
        effectCost = effectCost * 1.5
    end

    return effectCost
end

--[[
    Description: Calculates the Spell Cost for the given @spell.

    TES3Spell @spell: The spell to calculate the spell cost for. Type = TES3Spell.
]]
this.getSpellCost = function(spell)
    local spellCost = 0
	for i=1, spell:getActiveEffectCount() do
		local effect = spell.effects[i]
        if (effect ~= nil) then
            spellCost = spellCost + getEffectCost(effect)
		end
    end

	return spellCost
end

--[[
    Description: Creates or updates a spell based on the given @params,
        and adds it to the framework's list of managed spells. Accepts one
        magic effect.

    @params: A table of parameters used to configure the spell. @params
        must be in the following format:

    example = {
        id = "exampleSpellId",
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
this.createBasicSpell = function(params)
    local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name)
    tes3.setSourceless(spell)

    spell.name = params.name

    local effect = spell.effects[1]
    effect.id = params.effect
    effect.rangeType = params.range or tes3.effectRange.self
    effect.min = params.min or 0
    effect.max = params.max or 0
    effect.duration = params.duration or 0
    effect.radius = params.radius or 0
    effect.skill = params.skill or -1
    effect.attribute = params.attribute or -1

    spell.magickaCost = params.magickaCost or this.getSpellCost(spell)

    common.addSpellToSpellsList(spell)

    return spell
end

--[[
    Description: Creates or updates a spell based on the given @params,
        and adds it to the framework's list of managed spells. Accepts multiple
        magic effects.

    @params: A table of parameters used to configure the spell. @params
        must be in the following format:

    example = {
        id = "exampleSpellId",
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
this.createComplexSpell = function(params)
    local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name)
    tes3.setSourceless(spell)

    spell.name = params.name

    for i=1, #params.effects do
        local effect = spell.effects[i]
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

    spell.magickaCost = params.magickaCost or this.getSpellCost(spell)

    common.addSpellToSpellsList(spell)

    return spell
end

return this