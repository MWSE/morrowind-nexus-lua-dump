local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

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
                duration = { 15, 30, 45, 60, 75 },
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
        id = "swiftSwim-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.SwiftSwim,
                range = RangeTypes.Self,
                min = { 20, 40, 60, 80, 100 },
                max = { 30, 60, 90, 120, 150 },
                duration = { 15, 30, 45, 60, 75 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
        },
    },
    {
        id = "swiftSwim-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.SwiftSwim,
                range = RangeTypes.Self,
                min = { false, 25, 50, 75, 100 },
                max = { false, 25, 50, 75, 100 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
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
                duration = { 10, 15, 20, 25, 30 },
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
        id = "waterWalking-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.WaterWalking,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
        },
    },
    {
        id = "burden-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Burden,
                range = RangeTypes.Touch,
                min = { 50, 100, 200, 300, 400 },
                max = { 100, 200, 300, 400, 500 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
        }
    },
    {
        id = "burden-onStrike",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 20,
        effects = {
            {
                id = EffectTypes.Burden,
                range = RangeTypes.Touch,
                min = { 50, 100, 200, 300, 400 },
                max = { 100, 200, 300, 400, 500 },
                duration = { 2, 4, 6, 8, 10 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "feather-constant",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Feather,
                range = RangeTypes.Self,
                min = { false, 25, 50, 100, 150 },
                max = { false, 25, 50, 100, 150 },
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
        id = "jump-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Jump,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 25 },
                max = { 10, 20, 30, 40, 50 },
                duration = { 5, 10, 15, 20, 25 },
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
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "levitate-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.Levitate,
                range = RangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 20, 40, 60, 80 },
                duration = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Pants] = true,
                [T.Clothing.TYPE.Shirt] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Skirt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Shield] = true,
            } },
        },
    },
    {
        id = "slowFall-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = EffectTypes.SlowFall,
                range = RangeTypes.Self,
                min = { 1, 2, 4, false, false },
                max = { 2, 4, 8, false, false },
                duration = { 10, 15, 20, false, false },
            },
        },
        itemTypes = {
            [T.Clothing] = true,
            [T.Armor] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "lock-onUse",
        affixType = mT.affixes.Suffix,
        value = 25,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Lock,
                range = RangeTypes.Touch,
                min = { false, 1, false, false, false },
                max = { false, 10, false, false, false },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
        },
    },
    {
        id = "open-onUse",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.Open,
                range = RangeTypes.Touch,
                min = { 10, 20, 30, 50, 80 },
                max = { 20, 30, 50, 80, 100 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
        },
    },
    {
        id = "shield-onUse",
        affixType = mT.affixes.Prefix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = EffectTypes.Shield,
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
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "shield-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Shield,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeTwoHand] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "fireShield-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FireShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
        id = "frostShield-constant",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FrostShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
        id = "lightningShield-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.LightningShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
}