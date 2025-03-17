local core = require("openmw.core")
local T = require("openmw.types")

local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

return {
    {
        id = "turnundead-onStrike",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnStrike,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.TurnUndead,
                range = rangeTypes.Touch,
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
        id = "commandcreature-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 50,
        effects = {
            {
                id = effectTypes.CommandCreature,
                range = rangeTypes.Touch,
                min = { 2, 4, 6, 8, 10 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "commandhumanoid-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 50,
        effects = {
            {
                id = effectTypes.CommandHumanoid,
                range = rangeTypes.Touch,
                min = { 2, 4, 6, 8, 10 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 10, 15, 20, 25, 30 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonskeletalminion-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { 20, 40, 60, false, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonancestralghost-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.SummonAncestralGhost,
                range = rangeTypes.Self,
                duration = { 20, 40, 60, false, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonbonewalker-onUse",
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.SummonBonewalker,
                range = rangeTypes.Self,
                duration = { 20, 40, 60, false, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonscamp-onUse",
        affixType = "suffix",
        value = 75,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.SummonScamp,
                range = rangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "summongreaterbonewalker-onUse",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = effectTypes.SummonGreaterBonewalker,
                range = rangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonbonelord-onUse",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = effectTypes.SummonBonelord,
                range = rangeTypes.Self,
                duration = { false, 20, 40, 60, false },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonclannfear-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = effectTypes.SummonClannfear,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonflameatronach-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 30,
        charge = 120,
        effects = {
            {
                id = effectTypes.SummonFlameAtronach,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonfrostatronach-onUse",
        affixType = "suffix",
        value = 175,
        castType = enchantTypes.CastOnUse,
        cost = 35,
        charge = 140,
        effects = {
            {
                id = effectTypes.SummonFrostAtronach,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonstormatronach-onUse",
        affixType = "suffix",
        value = 200,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonStormAtronach,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summoncenturionsphere-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonCenturionSphere,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summondremora-onUse",
        affixType = "suffix",
        value = 200,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonDremora,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summondaedroth-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonDaedroth,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonhunger-onUse",
        affixType = "suffix",
        value = 250,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonHunger,
                range = rangeTypes.Self,
                duration = { false, false, 20, 40, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonwingedtwilight-onUse",
        affixType = "suffix",
        value = 250,
        castType = enchantTypes.CastOnUse,
        cost = 60,
        charge = 120,
        effects = {
            {
                id = effectTypes.SummonWingedTwilight,
                range = rangeTypes.Self,
                duration = { false, false, false, 30, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summongoldensaint-onUse",
        affixType = "suffix",
        value = 300,
        castType = enchantTypes.CastOnUse,
        cost = 80,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonGoldenSaint,
                range = rangeTypes.Self,
                duration = { false, false, false, 30, 60 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
        },
    },
    {
        id = "summonskeletalminion-2-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, 20, false, false, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, 20, false, false, false },
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
        id = "summonskeletalminion-4-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, 40, false, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, 40, false, false },
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
        id = "summonskeletalminion-6-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, 60, false },
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
        id = "summonskeletalminion-8-onUse",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
            },
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
                duration = { false, false, false, false, 120 },
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
        id = "summonskeletalminion-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonSkeletalMinion,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonancestralghost-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonAncestralGhost,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonbonewalker-constant",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonBonewalker,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonscamp-constant",
        affixType = "suffix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonScamp,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summongreaterbonewalker-constant",
        affixType = "suffix",
        value = 200,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonGreaterBonewalker,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonbonelord-constant",
        affixType = "suffix",
        value = 200,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.SummonBonelord,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonclannfear-constant",
        affixType = "suffix",
        value = 300,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonClannfear,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonflameatronach-constant",
        affixType = "suffix",
        value = 300,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonFlameAtronach,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonfrostatronach-constant",
        affixType = "suffix",
        value = 350,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonFrostAtronach,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonstormatronach-constant",
        affixType = "suffix",
        value = 400,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonStormAtronach,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summoncenturionsphere-constant",
        affixType = "suffix",
        value = 300,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonCenturionSphere,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summondremora-constant",
        affixType = "suffix",
        value = 400,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonDremora,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summondaedroth-constant",
        affixType = "suffix",
        value = 300,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonDaedroth,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonhunger-constant",
        affixType = "suffix",
        value = 500,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, 4, false },
        effects = {
            {
                id = effectTypes.SummonHunger,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summonwingedtwilight-constant",
        affixType = "suffix",
        value = 500,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, false, 5 },
        effects = {
            {
                id = effectTypes.SummonWingedTwilight,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "summongoldensaint-constant",
        affixType = "suffix",
        value = 600,
        castType = enchantTypes.ConstantEffect,
        levels = { false, false, false, false, 5 },
        effects = {
            {
                id = effectTypes.SummonGoldenSaint,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "bounddagger-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundDagger,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
            } },
        },
    },
    {
        id = "boundlongsword-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundLongsword,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.LongBladeOneHand] = true,
            } },
        },
    },
    {
        id = "boundmace-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundMace,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntOneHand] = true,
            } },
        },
    },
    {
        id = "boundbattleaxe-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundBattleAxe,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.AxeTwoHand] = true,
            } },
        },
    },
    {
        id = "boundspear-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundSpear,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.SpearTwoWide] = true,
            } },
        },
    },
    {
        id = "boundlongbow-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundLongbow,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
            } },
        },
    },
    {
        id = "boundcuirass-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundCuirass,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = {
                types = {
                    [T.Armor.TYPE.Cuirass] = true,
                },
                classes = {
                    Heavy = true,
                }
            },
        },
    },
    {
        id = "boundhelm-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundHelm,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = {
                types = {
                    [T.Armor.TYPE.Helmet] = true,
                },
                classes = {
                    Heavy = true,
                }
            },
        },
    },
    {
        id = "boundboots-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundBoots,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = {
                types = {
                    [T.Armor.TYPE.Boots] = true,
                    [T.Armor.TYPE.Greaves] = true,
                },
                classes = {
                    Heavy = true,
                }
            },
        },
    },
    {
        id = "boundshield-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundShield,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = {
                types = {
                    [T.Armor.TYPE.Shield] = true,
                },
                classes = {
                    Heavy = true,
                }
            },
        },
    },
    {
        id = "boundgloves-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.BoundGloves,
                range = rangeTypes.Self,
                duration = { false, false, 30, 60, 120 },
            },
        },
        itemTypes = {
            [T.Armor] = {
                types = {
                    [T.Armor.TYPE.LBracer] = true,
                    [T.Armor.TYPE.RBracer] = true,
                    [T.Armor.TYPE.LGauntlet] = true,
                    [T.Armor.TYPE.RGauntlet] = true,
                },
                classes = {
                    Heavy = true,
                }
            },
        },
    },
}