local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local Attributes = core.stats.Attribute.records
local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

local modifiers = {
    {
        id = "elementalDamage-onStrike",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.FireDamage,
                range = RangeTypes.Touch,
                min = { false, 1, 2, 4, 8 },
                max = { false, 2, 4, 8, 16 },
                duration = { false, 1, 1, 1, 1 },
            },
            {
                id = EffectTypes.FrostDamage,
                range = RangeTypes.Touch,
                min = { false, 1, 2, 4, 8 },
                max = { false, 2, 4, 8, 16 },
                duration = { false, 1, 1, 1, 1 },
            },
            {
                id = EffectTypes.ShockDamage,
                range = RangeTypes.Touch,
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
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.WeaknessToFire,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = EffectTypes.WeaknessToFrost,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = EffectTypes.WeaknessToShock,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = EffectTypes.WeaknessToPoison,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = EffectTypes.WeaknessToMagicka,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 15, 15, 15, 15, 15 },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "disintegrate-onStrike",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.DisintegrateWeapon,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = EffectTypes.DisintegrateArmor,
                range = RangeTypes.Touch,
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
    [Attributes.strength] = 2,
    [Attributes.willpower] = 1,
    [Attributes.agility] = 1,
    [Attributes.speed] = 1,
    [Attributes.luck] = 1,
}

for attribute, factor in pairs(drainAttrFactors) do
    table.insert(modifiers, {
        id = "drain-" .. attribute.id .. "-onStrike",
        affixType = mT.affixes.Prefix,
        value = 25 * factor,
        castType = EnchantTypes.CastOnStrike,
        cost = 5 * factor,
        charge = 50 * factor,
        effects = {
            {
                id = EffectTypes.DrainAttribute,
                attribute = attribute.id,
                range = RangeTypes.Touch,
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
    [EffectTypes.DrainHealth] = { factor = 3, min = 5, max = 10 },
    [EffectTypes.DrainMagicka] = { factor = 2, min = 5, max = 10 },
    [EffectTypes.DrainFatigue] = { factor = 1, min = 10, max = 20 },
}

for effectId, props in pairs(drainDynamicStatsFactors) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = mT.affixes.Suffix,
        value = 25 * props.factor,
        castType = EnchantTypes.CastOnStrike,
        cost = 5 * props.factor,
        charge = 50 * props.factor,
        effects = {
            {
                id = effectId,
                range = RangeTypes.Touch,
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
    [EffectTypes.DamageHealth] = { factor = 3, min = 2, max = 5 },
    [EffectTypes.DamageMagicka] = { factor = 2, min = 2, max = 5 },
    [EffectTypes.DamageFatigue] = { factor = 1, min = 5, max = 10 },
}

for effectId, props in pairs(damageDynamicStatsFactors) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = mT.affixes.Suffix,
        value = 25 * props.factor,
        castType = EnchantTypes.CastOnStrike,
        cost = 5 * props.factor,
        charge = 50 * props.factor,
        effects = {
            {
                id = effectId,
                range = RangeTypes.Touch,
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

local magicDamageEffects = { EffectTypes.FireDamage, EffectTypes.FrostDamage, EffectTypes.ShockDamage, EffectTypes.Poison }

for _, effectId in ipairs(magicDamageEffects) do
    table.insert(modifiers, {
        id = effectId .. "-onStrike",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectId,
                range = RangeTypes.Touch,
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
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectId,
                range = RangeTypes.Touch,
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