local core = require("openmw.core")
local T = require("openmw.types")

local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

return {
    {
        id = "soultrap-onStrike",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.Soultrap,
                range = rangeTypes.Touch,
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
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = effectTypes.Telekinesis,
                range = rangeTypes.Self,
                min = { 4, 8, 12, 16, 20 },
                max = { 8, 16, 24, 32, 40 },
                duration = { 5, 10, 15, 20, 25 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "detect-constant",
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.DetectAnimal,
                range = rangeTypes.Self,
                min = { false, 5, 10, 20, 40 },
                max = { false, 5, 10, 20, 40 },
            },
            {
                id = effectTypes.DetectEnchantment,
                range = rangeTypes.Self,
                min = { false, 5, 10, 20, 40 },
                max = { false, 5, 10, 20, 40 },
            },
            {
                id = effectTypes.DetectKey,
                range = rangeTypes.Self,
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
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "spellabsorption-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.SpellAbsorption,
                range = rangeTypes.Self,
                min = { false, false, 5, 10, 15 },
                max = { false, false, 5, 10, 15 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "reflect-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Reflect,
                range = rangeTypes.Self,
                min = { false, false, 5, 10, 15 },
                max = { false, false, 5, 10, 15 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "absorbhealth-onStrike",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.AbsorbHealth,
                range = rangeTypes.Touch,
                min = { 1, 2, 5, 10, 20 },
                max = { 2, 5, 10, 20, 40 },
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
        id = "absorbmagicka-onStrike",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.AbsorbMagicka,
                range = rangeTypes.Touch,
                min = { 1, 2, 5, 10, 20 },
                max = { 2, 5, 10, 20, 40 },
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
        id = "absorbfatigue-onStrike",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.AbsorbFatigue,
                range = rangeTypes.Touch,
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