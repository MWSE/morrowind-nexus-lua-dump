local T = require("openmw.types")

return {
    {
        id = "damagePlusMin",
        affixType = "prefix",
        value = 50,
        modifiers = {
            chopMinDamage = { false, 5, 10, 15, 20 },
            slashMinDamage = { false, 5, 10, 15, 20 },
            thrustMinDamage = { false, 5, 10, 15, 20 },
        },
        itemTypes = {
            [T.Weapon] = true,
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
            [T.Weapon] = true,
        },
    },
    {
        id = "damageMult",
        affixType = "prefix",
        value = 100,
        multipliers = {
            chopMinDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
            slashMinDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
            thrustMinDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
            chopMaxDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
            slashMaxDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
            thrustMaxDamage = { 1.2, 1.4, 1.6, 1.8, 2 },
        },
        itemTypes = {
            [T.Weapon] = true,
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
            baseArmor = { 1.25, 1.5, 1.75, 2, 2.25 },
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
            speed = { 1.15, 1.3, 1.45, 1.6, 1.75 }
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
            reach = { 0.2, 0.4, 0.6, 0.8, 1 },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
}