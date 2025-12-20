local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

return {
    {
        id = "damageMinShortBladeAdd",
        affixType = mT.affixes.Suffix,
        value = 50,
        modifiers = {
            chopMinDamage = { 2, 4, 7, 11, 15 },
            slashMinDamage = { 2, 4, 7, 11, 15 },
            thrustMinDamage = { 2, 4, 7, 11, 15 },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
            } },
        },
    },
    {
        id = "damageMinCrossbowAdd",
        affixType = mT.affixes.Suffix,
        value = 50,
        modifiers = {
            chopMinDamage = { 3, 6, 10, 15, 20 },
            slashMinDamage = { 3, 6, 10, 15, 20 },
            thrustMinDamage = { 3, 6, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "damageMaxAdd",
        affixType = mT.affixes.Suffix,
        value = 50,
        modifiers = {
            chopMaxDamage = { 2, 5, 10, 15, 20 },
            slashMaxDamage = { 2, 5, 10, 15, 20 },
            thrustMaxDamage = { 2, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
                [T.Weapon.TYPE.SpearTwoWide] = true,
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "damageMaxAxeBluntAdd",
        affixType = mT.affixes.Suffix,
        value = 50,
        modifiers = {
            chopMaxDamage = { 2, 5, 10, 15, 20 },
            slashMaxDamage = { 2, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.AxeOneHand] = true,
                [T.Weapon.TYPE.AxeTwoHand] = true,
                [T.Weapon.TYPE.BluntTwoClose] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "damageMaxSpearAdd",
        affixType = mT.affixes.Suffix,
        value = 50,
        modifiers = {
            thrustMaxDamage = { 2, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.SpearTwoWide] = true,
            } },
        },
    },
    {
        id = "weightMult",
        affixType = mT.affixes.Prefix,
        value = 50,
        multipliers = {
            weight = { 0.9, 0.8, 0.7, 0.6, 0.5 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
            [T.Armor] = true,
        },
    },
    {
        id = "armorAdd",
        affixType = mT.affixes.Prefix,
        value = 75,
        modifiers = {
            baseArmor = { 3, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Armor] = true,
        },
    },
    {
        id = "healthMult",
        affixType = mT.affixes.Prefix,
        value = 25,
        multipliers = {
            health = { 1.2, 1.35, 1.5, 1.75, 2 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
            [T.Armor] = true,
        },
    },
    {
        id = "attackSpeedAdd",
        affixType = mT.affixes.Prefix,
        value = 75,
        modifiers = {
            speed = { 0.1, 0.2, 0.3, 0.4, 0.5 }
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "reachAdd",
        affixType = mT.affixes.Prefix,
        value = 75,
        modifiers = {
            reach = { 0.1, 0.2, 0.3, 0.4, 0.5 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
}