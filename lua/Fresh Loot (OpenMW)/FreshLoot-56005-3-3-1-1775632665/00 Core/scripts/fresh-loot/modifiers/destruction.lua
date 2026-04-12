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
        value = 75,
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
    {
        id = "drainHealth-damageFatigue-onStrike",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.DrainHealth,
                range = RangeTypes.Touch,
                min = { 10, 15, 20, 30, 40 },
                max = { 15, 20, 25, 35, 45 },
                duration = { 1, 2, 3, 4, 5 },
            },
            {
                id = EffectTypes.DamageFatigue,
                range = RangeTypes.Touch,
                min = { 5, 10, 20, 25, 30 },
                max = { 10, 20, 25, 30, 40 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntOneHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
            } },
        },
    },
    {
        id = "poison-damageMagicka-drainSpeed-onStrike",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 20,
        effects = {
            {
                id = EffectTypes.Poison,
                range = RangeTypes.Touch,
                min = { false, false, 5, 7, 8 },
                max = { false, false, 6, 8, 10 },
                duration = { false, false, 5, 5, 5 },
                area = { false, false, 5, 8, 10 },
            },
            {
                id = EffectTypes.DamageMagicka,
                range = RangeTypes.Touch,
                min = { false, false, 9, 10, 12 },
                max = { false, false, 10, 12, 15 },
                duration = { false, false, 5, 5, 5 },
                area = { false, false, 5, 8, 10 },
            },
            {
                id = EffectTypes.DrainAttribute,
                attribute = Attributes.speed.id,
                range = RangeTypes.Touch,
                min = { false, false, 10, 20, 30 },
                max = { false, false, 15, 25, 35 },
                duration = { false, false, 5, 5, 5 },
                area = { false, false, 5, 8, 10 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "drainFatigueAgility-onStrike",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 20,
        effects = {
            {
                id = EffectTypes.DrainFatigue,
                range = RangeTypes.Touch,
                min = { false, false, 100, 150, 200 },
                max = { false, false, 150, 200, 250 },
                duration = { false, false, 5, 5, 5 },
                area = { false, false, 5, 8, 10 },
            },
            {
                id = EffectTypes.DrainAttribute,
                attribute = Attributes.agility.id,
                range = RangeTypes.Touch,
                min = { false, false, 20, 25, 30 },
                max = { false, false, 25, 30, 40 },
                duration = { false, false, 5, 5, 5 },
                area = { false, false, 5, 8, 10 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "fireDamage-target-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.FireDamage,
                range = RangeTypes.Target,
                min = { 3, 6, 10, 15, 20 },
                max = { 5, 8, 14, 18, 24 },
                duration = { 10, 10, 10, 10, 10 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fireDamage-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.FireDamage,
                range = RangeTypes.Touch,
                min = { 5, 25, 40, 60, 85 },
                max = { 20, 30, 50, 80, 100 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "frostDamage-target-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.FrostDamage,
                range = RangeTypes.Target,
                min = { 2, 4, 7, 10, 15 },
                max = { 4, 6, 9, 14, 18 },
                duration = { 20, 20, 20, 20, 20 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "frostDamage-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.FrostDamage,
                range = RangeTypes.Touch,
                min = { 4, 6, 10, 15, 21 },
                max = { 5, 8, 13, 20, 25 },
                duration = { 5, 5, 5, 5, 5 },
                area = { 5, 8, 10, 12, 15 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "shockDamage-target-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.ShockDamage,
                range = RangeTypes.Target,
                min = { 5, 25, 40, 60, 85 },
                max = { 20, 30, 50, 80, 100 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "shockDamage-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.ShockDamage,
                range = RangeTypes.Touch,
                min = { 1, 15, 30, 50, 70 },
                max = { 15, 20, 40, 65, 80 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = EffectTypes.Paralyze,
                range = RangeTypes.Touch,
                duration = { 1, 2, 2, 3, 4 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "poison-target-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.Poison,
                range = RangeTypes.Target,
                min = { 2, 4, 7, 10, 15 },
                max = { 4, 6, 9, 14, 18 },
                duration = { 20, 20, 20, 20, 20 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "poison-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.Poison,
                range = RangeTypes.Touch,
                min = { 3, 5, 7, 10, 15 },
                max = { 4, 6, 8, 13, 20 },
                duration = { 10, 10, 10, 10, 10 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "damageHealth-target-onUse",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.DamageHealth,
                range = RangeTypes.Target,
                min = { 3, 6, 10, 15, 20 },
                max = { 5, 8, 14, 18, 24 },
                duration = { 10, 10, 10, 10, 10 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "damageHealth-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 150,
        effects = {
            {
                id = EffectTypes.DamageHealth,
                range = RangeTypes.Touch,
                min = { 5, 25, 40, 60, 85 },
                max = { 20, 30, 50, 80, 100 },
                duration = { 1, 1, 1, 1, 1 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
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