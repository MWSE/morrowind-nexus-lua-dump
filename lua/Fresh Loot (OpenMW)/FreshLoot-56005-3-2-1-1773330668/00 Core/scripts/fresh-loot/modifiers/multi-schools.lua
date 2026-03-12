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
        cost = 20,
        charge = 100,
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
        cost = 10,
        charge = 100,
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
}