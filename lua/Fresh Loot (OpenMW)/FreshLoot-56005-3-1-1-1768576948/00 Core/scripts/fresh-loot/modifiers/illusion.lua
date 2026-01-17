local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

return {
    {
        id = "invisibility-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Invisibility,
                range = RangeTypes.Self,
                duration = { false, 5, 10, 30, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.Greaves] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Shield] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "chameleon-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Chameleon,
                range = RangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 10, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = { notTypes = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },

    {
        id = "chameleon-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Chameleon,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.Greaves] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Shield] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "light-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Light,
                range = RangeTypes.Target,
                min = { 3, 5, 10, false, false },
                max = { 5, 10, 15, false, false },
                duration = { 30, 60, 120, false, false },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "light-constant",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Light,
                range = RangeTypes.Self,
                min = { 2, 4, 8, 12, false },
                max = { 2, 4, 8, 12, false },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = true,
        },
    },
    {
        id = "sanctuary-onUse",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Sanctuary,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 15, 20, 25, 30 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "sanctuary-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Sanctuary,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.Greaves] = true,
                [T.Armor.TYPE.Boots] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "nightEye-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.NightEye,
                range = RangeTypes.Self,
                min = { 10, 15, 20, 25, 30 },
                max = { 10, 15, 20, 25, 30 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "nightEye-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.NightEye,
                range = RangeTypes.Self,
                min = { false, false, 10, 20, 30 },
                max = { false, false, 10, 20, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "charm-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Charm,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "paralyze-onStrike",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.Paralyze,
                range = RangeTypes.Touch,
                duration = { false, false, 3, 6, 10 },
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
        id = "silence-onStrike",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.Silence,
                range = RangeTypes.Touch,
                duration = { false, 5, 10, 15, 20 },
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
        id = "blind-onStrike",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Blind,
                range = RangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 4, 8, 12, 16, 20 },
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
        id = "sound-onStrike",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.Sound,
                range = RangeTypes.Touch,
                min = { 10, 15, 20, 25, 30 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 4, 8, 12, 16, 20 },
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
        id = "frenzy-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FrenzyHumanoid,
                range = RangeTypes.Touch,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.FrenzyCreature,
                range = RangeTypes.Touch,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
        },
    },
    {
        id = "rally-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.RallyHumanoid,
                range = RangeTypes.Target,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
            {
                id = EffectTypes.RallyCreature,
                range = RangeTypes.Target,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "rally-onStrike",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.RallyHumanoid,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
            {
                id = EffectTypes.RallyCreature,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
            } },
        },
    },
}