local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

return {
    {
        id = "turnUndead-onStrike",
        affixType = mT.affixes.Prefix,
        value = 25,
        castType = EnchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = EffectTypes.TurnUndead,
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
        id = "commandCreature-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 50,
        effects = {
            {
                id = EffectTypes.CommandCreature,
                range = RangeTypes.Touch,
                min = { 2, 4, 6, 8, 10 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
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
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "commandHumanoid-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 10,
        charge = 50,
        effects = {
            {
                id = EffectTypes.CommandHumanoid,
                range = RangeTypes.Touch,
                min = { 2, 4, 6, 8, 10 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 10, 15, 20, 25, 30 },
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
        id = "summonSkeletalMinion-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { 20, 40, 60, false, false },
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
        id = "summonAncestralGhost-onUse",
        affixType = mT.affixes.Suffix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.SummonAncestralGhost,
                range = RangeTypes.Self,
                duration = { 20, 40, 60, false, false },
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
        id = "summonBonewalker-onUse",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.SummonBonewalker,
                range = RangeTypes.Self,
                duration = { 20, 40, 60, false, false },
            },
        },
        itemTypes = {
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
        id = "summonScamp-onUse",
        affixType = mT.affixes.Suffix,
        value = 75,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.SummonScamp,
                range = RangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
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
        id = "summonGreaterBonewalker-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonGreaterBonewalker,
                range = RangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
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
        id = "summonBonelord-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonBonelord,
                range = RangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
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
        id = "summonClannfear-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonClannfear,
                range = RangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonCenturionSphere-onUse",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonCenturionSphere,
                range = RangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonFlameAtronach-onUse",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonFlameAtronach,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonFrostAtronach-onUse",
        affixType = mT.affixes.Suffix,
        value = 175,
        castType = EnchantTypes.CastOnUse,
        cost = 35,
        charge = 140,
        effects = {
            {
                id = EffectTypes.SummonFrostAtronach,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonStormAtronach-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonStormAtronach,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonDremora-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonDremora,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonHunger-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonHunger,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonDaedroth-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonDaedroth,
                range = RangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
                [T.Clothing.TYPE.Shoes] = true,
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonWingedTwilight-onUse",
        affixType = mT.affixes.Suffix,
        value = 250,
        castType = EnchantTypes.CastOnUse,
        cost = 60,
        charge = 120,
        effects = {
            {
                id = EffectTypes.SummonWingedTwilight,
                range = RangeTypes.Self,
                duration = { false, false, false, 30, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonGoldenSaint-onUse",
        affixType = mT.affixes.Suffix,
        value = 300,
        castType = EnchantTypes.CastOnUse,
        cost = 80,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonGoldenSaint,
                range = RangeTypes.Self,
                duration = { false, false, false, 30, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonSkeletalMinion-2-onUse",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, 20, false, false, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, 20, false, false, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Pants] = true,
                [T.Clothing.TYPE.Shirt] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Robe] = true,
                [T.Clothing.TYPE.Skirt] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            }},
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonSkeletalMinion-4-onUse",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Shirt] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            }},
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonSkeletalMinion-6-onUse",
        affixType = mT.affixes.Suffix,
        value = 250,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            }},
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonSkeletalMinion-8-onUse",
        affixType = mT.affixes.Suffix,
        value = 300,
        castType = EnchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            }},
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonSkeletalMinion-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonSkeletalMinion,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonAncestralGhost-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonAncestralGhost,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonBonewalker-constant",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonBonewalker,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonScamp-constant",
        affixType = mT.affixes.Suffix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonScamp,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonGreaterBonewalker-constant",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonGreaterBonewalker,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonBonelord-constant",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonBonelord,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonClannfear-constant",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonClannfear,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonCenturionSphere-constant",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = EffectTypes.SummonCenturionSphere,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonFlameAtronach-constant",
        affixType = mT.affixes.Suffix,
        value = 300,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonFlameAtronach,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonFrostAtronach-constant",
        affixType = mT.affixes.Suffix,
        value = 350,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonFrostAtronach,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonStormAtronach-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonStormAtronach,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonDremora-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonDremora,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonHunger-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonHunger,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonDaedroth-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = EffectTypes.SummonDaedroth,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonWingedTwilight-constant",
        affixType = mT.affixes.Suffix,
        value = 500,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, false, 5 },
        effects = {
            {
                id = EffectTypes.SummonWingedTwilight,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonGoldenSaint-constant",
        affixType = mT.affixes.Suffix,
        value = 600,
        castType = EnchantTypes.ConstantEffect,
        levels = { false, false, false, false, 5 },
        effects = {
            {
                id = EffectTypes.SummonGoldenSaint,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "boundDagger-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundDagger,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
            } },
        },
    },
    {
        id = "boundLongSword-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundLongsword,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeOneHand] = true,
            } },
        },
    },
    {
        id = "boundMace-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundMace,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "boundBattleAxe-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundBattleAxe,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.AxeTwoHand] = true,
            } },
        },
    },
    {
        id = "boundSpear-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundSpear,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.SpearTwoWide] = true,
            } },
        },
    },
    {
        id = "boundLongBow-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundLongbow,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
            } },
        },
    },
    {
        id = "boundCuirass-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundCuirass,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Cuirass] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "boundHelm-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundHelm,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
            }, },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "boundBoots-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundBoots,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
                [T.Armor.TYPE.Greaves] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "boundShield-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundShield,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Shield] = true,
            }, },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "boundGloves-onUse",
        affixType = mT.affixes.Prefix,
        value = 50,
        castType = EnchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = EffectTypes.BoundGloves,
                range = RangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
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
            } },
        },
    },
}