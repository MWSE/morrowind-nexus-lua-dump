local core = require("openmw.core")
local T = require("openmw.types")

local attributes = core.stats.Attribute.records
local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

-- Modifiers available in the addon but no more picked for new conversions
local modifiers = {
    {
        id = "damageFatigue-touch-damageLuck-self-onStrike",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.DamageFatigue,
                range = rangeTypes.Touch,
                min = { 5, 15, 25, 35, 50 },
                max = { 25, 35, 45, 60, 75 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = effectTypes.DamageAttribute,
                attribute = attributes.luck.id,
                range = rangeTypes.Touch,
                min = { 1, 1, 1, 1, 1 },
                max = { 1, 2, 3, 4, 5 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = effectTypes.DamageAttribute,
                attribute = attributes.luck.id,
                range = rangeTypes.Self,
                min = { 1, 1, 1, 1, 1 },
                max = { 1, 2, 3, 4, 5 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
}

for _, modifier in ipairs(modifiers) do
    modifier.deprecated = true
end

return modifiers