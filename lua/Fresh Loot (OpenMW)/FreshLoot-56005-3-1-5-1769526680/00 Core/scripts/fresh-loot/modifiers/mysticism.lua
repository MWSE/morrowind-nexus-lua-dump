local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

return {
    {
        id = "soultrap-onStrike",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Soultrap,
                range = RangeTypes.Touch,
                duration = { false, 1, 5, 10, 20 },
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
        id = "telekinesis-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = EffectTypes.Telekinesis,
                range = RangeTypes.Self,
                min = { 4, 8, 12, 16, 20 },
                max = { 8, 16, 24, 32, 40 },
                duration = { 5, 10, 15, 20, 25 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
        },
    },
    {
        id = "detect-constant",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.DetectAnimal,
                range = RangeTypes.Self,
                min = { false, 5, 10, 20, 40 },
                max = { false, 5, 10, 20, 40 },
            },
            {
                id = EffectTypes.DetectEnchantment,
                range = RangeTypes.Self,
                min = { false, 5, 10, 20, 40 },
                max = { false, 5, 10, 20, 40 },
            },
            {
                id = EffectTypes.DetectKey,
                range = RangeTypes.Self,
                min = { false, 5, 10, 20, 40 },
                max = { false, 5, 10, 20, 40 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = true,
        },
    },
    {
        id = "spellAbsorption-constant",
        affixType = mT.affixes.Suffix,
        value = 350,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.SpellAbsorption,
                range = RangeTypes.Self,
                min = { false, false, 5, 10, 15 },
                max = { false, false, 5, 10, 15 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Shield] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "reflect-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Reflect,
                range = RangeTypes.Self,
                min = { false, false, 5, 10, 15 },
                max = { false, false, 5, 10, 15 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Shield] = true,
            } },
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "absorbHealth-onStrike",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.AbsorbHealth,
                range = RangeTypes.Touch,
                min = { 1, 3, 5, 10, 20 },
                max = { 3, 5, 10, 20, 30 },
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
        id = "absorbMagicka-onStrike",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.AbsorbMagicka,
                range = RangeTypes.Touch,
                min = { 1, 3, 5, 10, 20 },
                max = { 3, 5, 10, 20, 40 },
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
        id = "absorbFatigue-onStrike",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.AbsorbFatigue,
                range = RangeTypes.Touch,
                min = { 10, 15, 20, 25, 30 },
                max = { 20, 30, 40, 50, 60 },
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