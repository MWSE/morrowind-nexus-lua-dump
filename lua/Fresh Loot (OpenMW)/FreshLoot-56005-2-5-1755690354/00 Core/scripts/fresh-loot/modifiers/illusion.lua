local core = require("openmw.core")
local T = require("openmw.types")

local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

return {
    {
        id = "invisibility-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.Invisibility,
                range = rangeTypes.Self,
                duration = { false, 5, 10, 30, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "chameleon-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.Chameleon,
                range = rangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 10, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },

    {
        id = "chameleon-constant",
        affixType = "prefix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Chameleon,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "light-onUse",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = effectTypes.Light,
                range = rangeTypes.Target,
                min = { 3, 5, 10, false, false },
                max = { 5, 10, 15, false, false },
                duration = { 30, 60, 120, false, false },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "light-constant",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Light,
                range = rangeTypes.Self,
                min = { 2, 4, 8, 12, false },
                max = { 2, 4, 8, 12, false },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "sanctuary-onUse",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.Sanctuary,
                range = rangeTypes.Self,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 15, 20, 25, 30 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "sanctuary-constant",
        affixType = "prefix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Sanctuary,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "nightEye-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.NightEye,
                range = rangeTypes.Self,
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
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.NightEye,
                range = rangeTypes.Self,
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
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.Charm,
                range = rangeTypes.Touch,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 10, 15, 20, 25, 30 },
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
        id = "paralyze-onStrike",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.Paralyze,
                range = rangeTypes.Touch,
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
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.Silence,
                range = rangeTypes.Touch,
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
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.Blind,
                range = rangeTypes.Touch,
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
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.Sound,
                range = rangeTypes.Touch,
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
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.FrenzyHumanoid,
                range = rangeTypes.Touch,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 5, 10, 15, 20 },
            },
            {
                id = effectTypes.FrenzyCreature,
                range = rangeTypes.Touch,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 30, 40, 50 },
                duration = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
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
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.RallyHumanoid,
                range = rangeTypes.Target,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
            {
                id = effectTypes.RallyCreature,
                range = rangeTypes.Target,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "rally-onStrike",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.RallyHumanoid,
                range = rangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
            {
                id = effectTypes.RallyCreature,
                range = rangeTypes.Touch,
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