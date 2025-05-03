local T = require("openmw.types")

return {
    {
        id = "damagePlusMin",
        affixType = "prefix",
        value = 50,
        modifiers = {
            chopMinDamage = { 2, 5, 10, 15, 20 },
            slashMinDamage = { 2, 5, 10, 15, 20 },
            thrustMinDamage = { 2, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "damagePlusMax",
        affixType = "prefix",
        value = 50,
        modifiers = {
            chopMaxDamage = { 5, 10, 15, 20, 25 },
            slashMaxDamage = { 5, 10, 15, 20, 25 },
            thrustMaxDamage = { 5, 10, 15, 20, 25 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "damageMult",
        affixType = "prefix",
        value = 100,
        multipliers = {
            chopMinDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
            slashMinDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
            thrustMinDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
            chopMaxDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
            slashMaxDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
            thrustMaxDamage = { 1.1, 1.2, 1.3, 1.4, 1.5 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.ShortBladeOneHand] = true,
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "weightMult",
        affixType = "prefix",
        value = 25,
        multipliers = {
            weight = { 0.85, 0.7, 0.55, 0.4, 0.25 },
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
        id = "armorMult",
        affixType = "prefix",
        value = 100,
        multipliers = {
            baseArmor = { 1.1, 1.2, 1.3, 1.4, 1.5 },
        },
        itemTypes = {
            [T.Armor] = true,
        },
    },
    {
        id = "healthMult",
        affixType = "prefix",
        value = 25,
        multipliers = {
            health = { 1.5, 2, 2.5, 3, 3.5 },
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
        id = "attackSpeedMult",
        affixType = "suffix",
        value = 75,
        multipliers = {
            speed = { 1.1, 1.2, 1.3, 1.4, 1.5 }
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
        affixType = "suffix",
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