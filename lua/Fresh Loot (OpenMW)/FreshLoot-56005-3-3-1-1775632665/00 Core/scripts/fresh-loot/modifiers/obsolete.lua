local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

-- Modifiers used for enchantment generation in the addon file (for backward compatibility), but never picked for new conversions
return {
    {
        id = "waterBreathing-onUse",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = EffectTypes.WaterBreathing,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, 75 },
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
        },
    },
    {
        id = "waterWalking-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = EffectTypes.WaterWalking,
                range = RangeTypes.Self,
                duration = { false, false, false, 25, 30 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Pants] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Skirt] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
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
                min = { false, false, false, 25, 30 },
                max = { false, false, false, 25, 30 },
                duration = { false, false, false, 50, 60 },
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
                min = { false, false, false, 40, 50 },
                max = { false, false, false, 80, 100 },
                duration = { false, false, false, 25, 30 },
            },
            {
                id = EffectTypes.RallyCreature,
                range = RangeTypes.Target,
                min = { false, false, false, 40, 50 },
                max = { false, false, false, 80, 100 },
                duration = { false, false, false, 25, 30 },
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
    }
}