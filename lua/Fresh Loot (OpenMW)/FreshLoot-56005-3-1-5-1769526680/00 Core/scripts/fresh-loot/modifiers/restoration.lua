local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local Attributes = core.stats.Attribute.records
local Skills = core.stats.Skill.records
local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

local modifiers = {
    {
        id = "cureCommonDisease-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        levels = { false, 2, false, false, false },
        effects = {
            {
                id = EffectTypes.CureCommonDisease,
                range = RangeTypes.Self,
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
        id = "cureBlightDisease-onUse",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.CureBlightDisease,
                range = RangeTypes.Self,
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
        id = "curePoison-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        levels = { false, 2, false, false, false },
        effects = {
            {
                id = EffectTypes.CurePoison,
                range = RangeTypes.Self,
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
        id = "restoreHealth-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.RestoreHealth,
                range = RangeTypes.Self,
                min = { 2, 4, 8, 12, 16 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 5, 5, 5, 5, 5 },
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
        id = "restoreMagicka-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.RestoreMagicka,
                range = RangeTypes.Self,
                min = { 1, 2, 4, 8, 12 },
                max = { 2, 4, 8, 12, 16 },
                duration = { 5, 5, 5, 5, 5 },
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
        id = "restoreFatigue-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = EffectTypes.RestoreFatigue,
                range = RangeTypes.Self,
                min = { 4, 8, 16, 24, 32 },
                max = { 8, 16, 24, 32, 40 },
                duration = { 5, 5, 5, 5, 5 },
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
        id = "fortifySpeed-boots-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.speed.id,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
        },
    },
    {
        id = "fortifyMaximumMagicka-constant",
        affixType = mT.affixes.Prefix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyMaximumMagicka,
                range = RangeTypes.Self,
                min = { false, 2, 4, 6, 8 },
                max = { false, 2, 4, 6, 8 },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
        },
    },
    {
        id = "resistFire-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistFire-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistFrost-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.ResistFrost,
                range = RangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistFrost-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFrost,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistShock-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.ResistShock,
                range = RangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistShock-constant",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistShock,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistElements-onUse",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
            },
            {
                id = EffectTypes.ResistFrost,
                range = RangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
            },
            {
                id = EffectTypes.ResistShock,
                range = RangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistElements-constant",
        affixType = mT.affixes.Prefix,
        value = 300,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.ResistFrost,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.ResistShock,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
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
        id = "resistMagicka-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistMagicka,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistSicknesses-constant",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistCommonDisease,
                range = RangeTypes.Self,
                min = { 15, 30, 45, 60, 75 },
                max = { 15, 30, 45, 60, 75 },
            },
            {
                id = EffectTypes.ResistBlightDisease,
                range = RangeTypes.Self,
                min = { 10, 25, 40, 55, 70 },
                max = { 10, 25, 40, 55, 70 },
            },
            {
                id = EffectTypes.ResistPoison,
                range = RangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 10, 20, 30, 50, 50 },
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
        id = "resistNormalWeapons-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistNormalWeapons,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 5, 10, 15, 20, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "resistParalysis-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.ResistParalysis,
                range = RangeTypes.Self,
                min = { 50, 60, 70, 80, 90 },
                max = { 60, 70, 80, 90, 100 },
                duration = { 10, 20, 30, 40, 60 }
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "resistParalysis-constant",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistParalysis,
                range = RangeTypes.Self,
                min = { false, 20, 40, 60, 80 },
                max = { false, 20, 40, 60, 80 },
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
        id = "fortify-agility-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.agility.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "fortify-strength-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.strength.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "fortify-speed-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.speed.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fortify-intelligence-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.intelligence.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "fortify-endurance-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.endurance.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.LongBladeOneHand] = true,
                [T.Weapon.TYPE.BluntOneHand] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "fortify-willpower-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.willpower.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "fortify-personality-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.personality.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fortify-luck-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.luck.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "fortify-agility-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.agility.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.BluntOneHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "fortify-strength-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.strength.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "fortify-speed-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.speed.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fortify-intelligence-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.intelligence.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "fortify-endurance-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.endurance.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fortify-willpower-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.willpower.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "fortify-personality-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.personality.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = true,
        },
    },
    {
        id = "fortify-luck-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.luck.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
            [T.Weapon] = true,
        },
    },
}

local restoreAttrEffects = {}
for _, attribute in pairs(Attributes) do
    table.insert(restoreAttrEffects, {
        id = EffectTypes.RestoreAttribute,
        attribute = attribute.id,
        range = RangeTypes.Self,
        min = { false, 1, 2, 3, 4 },
        max = { false, 1, 2, 3, 4 },
        duration = { false, 5, 5, 5, 5 }
    })
end

table.insert(modifiers, {
    id = "restoreAttribute-all-onUse",
    affixType = mT.affixes.Suffix,
    value = 100,
    castType = EnchantTypes.CastOnUse,
    cost = 20,
    charge = 100,
    effects = restoreAttrEffects,
    itemTypes = {
        [T.Clothing] = true,
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.BluntTwoWide] = true,
        } },
    },
})

local fortifySkillTypes = {
    [Skills.athletics] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.Boots] = true,
            [T.Armor.TYPE.Greaves] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.Shoes] = true,
        } },
    },
    [Skills.block] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.Shield] = true,
            [T.Armor.TYPE.LGauntlet] = true,
            [T.Armor.TYPE.LBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.Ring] = true,
            [T.Clothing.TYPE.Amulet] = true,
        } },
    },
    [Skills.armorer] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LGauntlet] = true,
            [T.Armor.TYPE.RGauntlet] = true,
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [Skills.security] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [Skills.lightarmor] = {
        [T.Armor] = { classes = { Light = true } },
    },
    [Skills.mediumarmor] = {
        [T.Armor] = { classes = { Medium = true } },
    },
    [Skills.heavyarmor] = {
        [T.Armor] = { classes = { Heavy = true } },
    },
    [Skills.handtohand] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LGauntlet] = true,
            [T.Armor.TYPE.RGauntlet] = true,
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [Skills.shortblade] = {
        [T.Weapon] = { types = { [T.Weapon.TYPE.ShortBladeOneHand] = true } },
    },
    [Skills.longblade] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.LongBladeOneHand] = true,
            [T.Weapon.TYPE.LongBladeTwoHand] = true,
        } },
    },
    [Skills.bluntweapon] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.BluntOneHand] = true,
            [T.Weapon.TYPE.BluntTwoClose] = true,
            [T.Weapon.TYPE.BluntTwoWide] = true,
        } },
    },
    [Skills.axe] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.AxeOneHand] = true,
            [T.Weapon.TYPE.AxeTwoHand] = true
        } },
    },
    [Skills.spear] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.SpearTwoWide] = true,
        } },
    },
    [Skills.marksman] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.MarksmanBow] = true,
            [T.Weapon.TYPE.MarksmanCrossbow] = true,
        } },
    },
    [Skills.unarmored] = { [T.Clothing] = true },
    [Skills.acrobatics] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.Boots] = true,
        }, classes = {
            [mT.armorClasses.Light] = true,
        } },
        [T.Clothing] = true,
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.MarksmanBow] = true,
            [T.Weapon.TYPE.MarksmanCrossbow] = true,
        } },
    },
    [Skills.sneak] = {
        [T.Armor] = { classes = {
            [mT.armorClasses.Light] = true
        } },
        [T.Clothing] = true,
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.ShortBladeOneHand] = true,
        } }
    },
    [Skills.mercantile] = { [T.Clothing] = true },
    [Skills.speechcraft] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.alchemy] = { [T.Clothing] = true },
    [Skills.alteration] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.conjuration] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.destruction] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.enchant] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.illusion] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.mysticism] = { [T.Armor] = true, [T.Clothing] = true },
    [Skills.restoration] = { [T.Armor] = true, [T.Clothing] = true },
}

for skill, types in pairs(fortifySkillTypes) do
    table.insert(modifiers, {
        id = "fortify-" .. skill.id .. "-constant",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifySkill,
                skill = skill.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            }
        },
        itemTypes = types,
    })
end

local dressing = {
    [T.Armor] = true,
    [T.Clothing] = true,
}

local mageDressing = {
    [T.Armor] = true,
    [T.Clothing] = true,
    [T.Weapon] = { types = {
        [T.Weapon.TYPE.BluntTwoWide] = true,
    } },
}

local fortifyTypes = {
    { skills = { Skills.conjuration, Skills.heavyarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Heavy] = true,
          } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Shoes] = true,
              [T.Clothing.TYPE.LGlove] = true,
              [T.Clothing.TYPE.RGlove] = true,
          } },
      },
    },
    { skills = { Skills.unarmored, Skills.handtohand, Skills.lightarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = true,
      },
    },
    { skills = { Skills.acrobatics, Skills.athletics },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = true,
      },
    },
    { skills = { Skills.unarmored, Skills.handtohand },
      types = {
          [T.Clothing] = true,
      },
    },
    { skills = { Skills.handtohand, Skills.unarmored },
      types = {
          [T.Clothing] = true,
      },
    },
    { skills = { Skills.shortblade, Skills.alchemy },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.ShortBladeOneHand] = true,
          } },
      },
    },
    { skills = { Skills.sneak, Skills.illusion },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.ShortBladeOneHand] = true,
          } },
      },
    },
    { skills = { Skills.shortblade, Skills.mercantile },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.ShortBladeOneHand] = true,
          } },
      },
    },
    { skills = { Skills.speechcraft, Skills.sneak },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.ShortBladeOneHand] = true,
          } },
      },
    },
    { skills = { Skills.sneak, Skills.security },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = true,
      },
    },
    { skills = { Skills.longblade, Skills.destruction },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.LongBladeOneHand] = true,
              [T.Weapon.TYPE.LongBladeTwoHand] = true,
          } },
      },
    },
    { skills = { Skills.longblade, Skills.block },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.LongBladeOneHand] = true,
              [T.Weapon.TYPE.LongBladeTwoHand] = true,
          } },
      },
    },
    { skills = { Skills.longblade, Skills.heavyarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Heavy] = true,
          } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Shoes] = true,
              [T.Clothing.TYPE.LGlove] = true,
              [T.Clothing.TYPE.RGlove] = true,
          } },
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.LongBladeOneHand] = true,
              [T.Weapon.TYPE.LongBladeTwoHand] = true,
          } },
      }
    },
    { skills = { Skills.axe, Skills.mediumarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Medium] = true,
          } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Shoes] = true,
              [T.Clothing.TYPE.LGlove] = true,
              [T.Clothing.TYPE.RGlove] = true,
          } },
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.AxeOneHand] = true,
              [T.Weapon.TYPE.AxeTwoHand] = true,
          } },
      }
    },
    { skills = { Skills.bluntweapon, Skills.destruction },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.BluntOneHand] = true,
              [T.Weapon.TYPE.BluntTwoClose] = true,
              [T.Weapon.TYPE.BluntTwoWide] = true,
          } },
      },
    },
    { skills = { Skills.marksman, Skills.lightarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Light] = true,
          } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Shoes] = true,
              [T.Clothing.TYPE.LGlove] = true,
              [T.Clothing.TYPE.RGlove] = true,
          } },
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.MarksmanBow] = true,
              [T.Weapon.TYPE.MarksmanCrossbow] = true,
          } },
      },
    },
    { skills = { Skills.athletics, Skills.mediumarmor },
      types = {
          [T.Armor] = { classes = {
              [mT.armorClasses.Medium] = true,
          } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Shoes] = true,
              [T.Clothing.TYPE.LGlove] = true,
              [T.Clothing.TYPE.RGlove] = true,
          } },
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.MarksmanBow] = true,
              [T.Weapon.TYPE.MarksmanCrossbow] = true,
          } },
      },
    },
    { attributes = { Attributes.agility },
      skills = { Skills.marksman },
      types = {
          [T.Armor] = true,
          [T.Clothing] = true,
          [T.Weapon] = { types = {
              [T.Weapon.TYPE.MarksmanBow] = true,
              [T.Weapon.TYPE.MarksmanCrossbow] = true,
          } },
      },
    },
    { skills = { Skills.speechcraft, Skills.mercantile }, types = mageDressing },
    { skills = { Skills.enchant, Skills.conjuration }, types = mageDressing },
    { skills = { Skills.speechcraft, Skills.illusion }, types = mageDressing },
    { skills = { Skills.restoration, Skills.mysticism }, types = mageDressing },
    { skills = { Skills.destruction, Skills.alteration }, types = mageDressing },
    { skills = { Skills.conjuration, Skills.alchemy }, types = mageDressing },
    { skills = { Skills.alteration, Skills.mysticism, Skills.illusion }, types = mageDressing },
    { skills = { Skills.mercantile, Skills.security }, types = dressing },
    { attributes = { Attributes.personality }, skills = { Skills.speechcraft, Skills.mercantile }, types = dressing },
    { attributes = { Attributes.personality, Attributes.willpower }, skills = { Skills.speechcraft }, types = dressing },
    { attributes = { Attributes.luck }, skills = { Skills.mercantile }, types = dressing },
    { attributes = { Attributes.intelligence }, skills = { Skills.speechcraft }, types = dressing },
    { attributes = { Attributes.personality, Attributes.endurance }, types = dressing },
    { attributes = { Attributes.agility, Attributes.personality }, types = dressing },
}

for _, cfg in ipairs(fortifyTypes) do
    local effects = {}
    local ids = {}
    for _, attribute in ipairs(cfg.attributes or {}) do
        table.insert(ids, attribute.id)
        table.insert(effects, {
            id = EffectTypes.FortifyAttribute,
            attribute = attribute.id,
            range = RangeTypes.Self,
            min = { false, 3, 8, 12, 16 },
            max = { false, 3, 8, 12, 16 },
        })
    end
    for _, skill in ipairs(cfg.skills or {}) do
        table.insert(ids, skill.id)
        table.insert(effects, {
            id = EffectTypes.FortifySkill,
            skill = skill.id,
            range = RangeTypes.Self,
            min = { false, 3, 8, 12, 16 },
            max = { false, 3, 8, 12, 16 },
        })
    end
    table.insert(modifiers, {
        id = "fortify-" .. table.concat(ids, "-") .. "-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = effects,
        itemTypes = cfg.types,
    })
end

return modifiers