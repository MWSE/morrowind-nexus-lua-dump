local core = require("openmw.core")
local T = require("openmw.types")

local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

return {
    {
        id = "waterbreathing-onUse",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = effectTypes.WaterBreathing,
                range = rangeTypes.Self,
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
        conflicts = {
            effects = {
                [effectTypes.WaterWalking] = true,
                [effectTypes.Levitate] = true,
                [effectTypes.SlowFall] = true,
                [effectTypes.Jump] = true,
            },
        }
    },
    {
        id = "swiftswim-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.SwiftSwim,
                range = rangeTypes.Self,
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
        conflicts = {
            effects = {
                [effectTypes.WaterWalking] = true,
                [effectTypes.Levitate] = true,
                [effectTypes.SlowFall] = true,
                [effectTypes.Jump] = true,
            },
        }
    },
    {
        id = "swiftswim-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.SwiftSwim,
                range = rangeTypes.Self,
                min = { false, 25, 50, 75, 100 },
                max = { false, 25, 50, 75, 100 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
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
        conflicts = {
            effects = {
                [effectTypes.WaterWalking] = true,
                [effectTypes.Levitate] = true,
                [effectTypes.SlowFall] = true,
                [effectTypes.Jump] = true,
            },
        }
    },
    {
        id = "waterwalking-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = effectTypes.WaterWalking,
                range = rangeTypes.Self,
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
        },
        conflicts = {
            effects = {
                [effectTypes.WaterBreathing] = true,
                [effectTypes.SwiftSwim] = true,
                [effectTypes.Levitate] = true,
            },
        }
    },
    {
        id = "waterwalking-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.WaterWalking,
                range = rangeTypes.Self,
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
        conflicts = {
            effects = {
                [effectTypes.WaterBreathing] = true,
                [effectTypes.SwiftSwim] = true,
                [effectTypes.Levitate] = true,
            },
        }
    },
    {
        id = "burden-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.Burden,
                range = rangeTypes.Touch,
                min = { 50, 100, 200, 300, 400 },
                max = { 100, 200, 300, 400, 500 },
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
        id = "feather-constant",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Feather,
                range = rangeTypes.Self,
                min = { false, 25, 50, 100, 150 },
                max = { false, 25, 50, 100, 150 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Pants] = true,
                [T.Clothing.TYPE.Shirt] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Skirt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "jump-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = effectTypes.Jump,
                range = rangeTypes.Self,
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
        conflicts = {
            effects = {
                [effectTypes.WaterBreathing] = true,
                [effectTypes.SwiftSwim] = true,
                [effectTypes.Levitate] = true,
            },
        }
    },
    {
        id = "levitate-onUse",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = effectTypes.Levitate,
                range = rangeTypes.Self,
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
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
        conflicts = {
            effects = {
                [effectTypes.WaterBreathing] = true,
                [effectTypes.WaterWalking] = true,
                [effectTypes.SwiftSwim] = true,
                [effectTypes.Jump] = true,
            },
        }
    },
    {
        id = "slowfall-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 50,
        effects = {
            {
                id = effectTypes.SlowFall,
                range = rangeTypes.Self,
                min = { 1, 2, 4, false, false },
                max = { 2, 4, 8, false, false },
                duration = { 10, 15, 20, false, false },
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
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
        conflicts = {
            effects = {
                [effectTypes.WaterBreathing] = true,
                [effectTypes.WaterWalking] = true,
                [effectTypes.SwiftSwim] = true,
                [effectTypes.Jump] = true,
            },
        }
    },
    {
        id = "lock-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.Lock,
                range = rangeTypes.Touch,
                min = { false, 1, false, false, false },
                max = { false, 10, false, false, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
        },
        conflicts = {
            ranges = {
                [rangeTypes.Touch] = true,
                [rangeTypes.Target] = true,
            },
        }
    },
    {
        id = "open-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.Open,
                range = rangeTypes.Touch,
                min = { 10, 20, 30, 50, 80 },
                max = { 20, 30, 50, 80, 100 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
        },
        conflicts = {
            ranges = {
                [rangeTypes.Touch] = true,
                [rangeTypes.Target] = true,
            },
        }
    },
    {
        id = "shield-onUse",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.Shield,
                range = rangeTypes.Self,
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
        affixType = "prefix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.Shield,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
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
        id = "fireshield-constant",
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FireShield,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
        id = "frostshield-constant",
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FrostShield,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
        id = "lightningshield-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.LightningShield,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
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
}