local core = require("openmw.core")
local T = require("openmw.types")

local attributes = core.stats.Attribute.records
local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

local modifiers = {
    {
        id = "elementalDamage-onStrike",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.FireDamage,
                range = rangeTypes.Touch,
                min = { false, 1, 2, 4, 8 },
                max = { false, 2, 4, 8, 16 },
                duration = { false, 1, 1, 1, 1 },
            },
            {
                id = effectTypes.FrostDamage,
                range = rangeTypes.Touch,
                min = { false, 1, 2, 4, 8 },
                max = { false, 2, 4, 8, 16 },
                duration = { false, 1, 1, 1, 1 },
            },
            {
                id = effectTypes.ShockDamage,
                range = rangeTypes.Touch,
                min = { false, 1, 2, 4, 8 },
                max = { false, 2, 4, 8, 16 },
                duration = { false, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "magicalWeaknesses-onUse",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.WeaknessToFire,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = effectTypes.WeaknessToFrost,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = effectTypes.WeaknessToShock,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = effectTypes.WeaknessToPoison,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = effectTypes.WeaknessToMagicka,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "disintegrate-onStrike",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.DisintegrateWeapon,
                range = rangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = effectTypes.DisintegrateArmor,
                range = rangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
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

local drainAttrFactors = {
    [attributes.strength] = 2,
    [attributes.willpower] = 2,
    [attributes.agility] = 1,
    [attributes.speed] = 1,
    [attributes.luck] = 1,
}

for attribute, factor in pairs(drainAttrFactors) do
    table.insert(modifiers, {
        id = "drain-" .. attribute.id .. "-onStrike",
        affixType = "prefix",
        value = 25 * factor,
        castType = enchantTypes.CastOnStrike,
        cost = 5 * factor,
        charge = 50 * factor,
        effects = {
            {
                id = effectTypes.DrainAttribute,
                attribute = attribute.id,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 5, 10, 15, 20, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    })
end

local drainDynamicStatsFactors = {
    [effectTypes.DrainHealth] = { factor = 3, min = 5, max = 10 },
    [effectTypes.DrainMagicka] = { factor = 2, min = 5, max = 10 },
    [effectTypes.DrainFatigue] = { factor = 1, min = 10, max = 20 },
}

for effectId, props in pairs(drainDynamicStatsFactors) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = "suffix",
        value = 25 * props.factor,
        castType = enchantTypes.CastOnStrike,
        cost = 5 * props.factor,
        charge = 50 * props.factor,
        effects = {
            {
                id = effectId,
                range = rangeTypes.Touch,
                min = { props.min, props.min * 2, props.min * 4, props.min * 8, props.min * 12 },
                max = { props.max, props.max * 2, props.max * 4, props.max * 8, props.max * 12 },
                duration = { 5, 10, 15, 20, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    })
end

local damageDynamicStatsFactors = {
    [effectTypes.DamageHealth] = { factor = 3, min = 2, max = 5 },
    [effectTypes.DamageMagicka] = { factor = 2, min = 2, max = 5 },
    [effectTypes.DamageFatigue] = { factor = 1, min = 5, max = 10 },
}

for effectId, props in pairs(damageDynamicStatsFactors) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = "suffix",
        value = 25 * props.factor,
        castType = enchantTypes.CastOnStrike,
        cost = 5 * props.factor,
        charge = 50 * props.factor,
        effects = {
            {
                id = effectId,
                range = rangeTypes.Touch,
                min = { props.min, props.min * 2, props.min * 4, props.min * 6, props.min * 8 },
                max = { props.max, props.max * 2, props.max * 4, props.max * 6, props.max * 8 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    })
end

local magicDamageEffects = { effectTypes.FireDamage, effectTypes.FrostDamage, effectTypes.ShockDamage, effectTypes.Poison }

for _, effectId in ipairs(magicDamageEffects) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectId,
                range = rangeTypes.Touch,
                min = { 2, 4, 8, 16, 32 },
                max = { 3, 6, 12, 24, 48 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    })
    table.insert(modifiers, {
        id = effectId .. "-slow-onStrike",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectId,
                range = rangeTypes.Touch,
                min = { 1, 2, 3, 4, 5 },
                max = { 2, 4, 6, 8, 10 },
                duration = { 5, 5, 5, 5, 5 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
            } },
        },

    })
end

return modifiers