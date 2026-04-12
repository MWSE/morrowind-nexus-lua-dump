local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

return {
    {
        id = "demoralize-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 50,
        charge = 200,
        effects = {
            {
                id = EffectTypes.DemoralizeCreature,
                range = RangeTypes.Target,
                area = { 10, 15, 15, 20, 25 },
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 60, 80 },
                duration = { 30, 30, 30, 35, 40 },
            },
            {
                id = EffectTypes.DemoralizeHumanoid,
                range = RangeTypes.Target,
                area = { 10, 15, 15, 20, 25 },
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 60, 80 },
                duration = { 30, 30, 30, 35, 40 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
                [T.Armor.TYPE.Shield] = true,
                [T.Armor.TYPE.Cuirass] = true,
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Robe] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "demoralize-onStrike",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.DemoralizeCreature,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
            },
            {
                id = EffectTypes.DemoralizeHumanoid,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 40, 60, 80, 100 },
                duration = { 10, 15, 20, 25, 30 },
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
        id = "sunDamage-light-onStrike",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.CastOnStrike,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.SunDamage,
                range = RangeTypes.Touch,
                min = { 2, 4, 8, 16, 32 },
                max = { 3, 6, 12, 24, 48 },
                duration = { 1, 1, 1, 1, 1 },
            },
            {
                id = EffectTypes.Light,
                range = RangeTypes.Touch,
                min = { 5, 5, 5, 5, 5 },
                max = { 5, 5, 5, 5, 5 },
                duration = { 3, 3, 3, 3, 3 },
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
        id = "fortifyHealthFatigue-restoreDamageFatigue-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 25,
        charge = 150,
        effects = {
            {
                id = EffectTypes.FortifyHealth,
                range = RangeTypes.Self,
                min = { 20, 25, 35, 40, 50 },
                max = { 25, 35, 40, 50, 60 },
                duration = { 30, 30, 30, 30, 30 },
            },
            {
                id = EffectTypes.FortifyFatigue,
                range = RangeTypes.Self,
                min = { 40, 50, 60, 70, 80 },
                max = { 50, 60, 70, 80, 100 },
                duration = { 30, 30, 30, 30, 30 },
            },
            {
                id = EffectTypes.RestoreFatigue,
                range = RangeTypes.Self,
                min = { 4, 5, 6, 8, 10 },
                max = { 4, 5, 6, 8, 10 },
                duration = { 15, 15, 15, 15, 15 },
            },
            {
                id = EffectTypes.DamageFatigue,
                range = RangeTypes.Self,
                min = { 4, 5, 6, 8, 10 },
                max = { 4, 5, 6, 8, 10 },
                duration = { 30, 30, 30, 30, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
            } },
        },
    },
}