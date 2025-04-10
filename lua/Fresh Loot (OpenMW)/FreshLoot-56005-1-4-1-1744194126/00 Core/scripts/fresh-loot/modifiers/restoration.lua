local core = require("openmw.core")
local T = require("openmw.types")

local attributes = core.stats.Attribute.records
local skills = core.stats.Skill.records
local effectTypes = core.magic.EFFECT_TYPE
local enchantTypes = core.magic.ENCHANTMENT_TYPE
local rangeTypes = core.magic.RANGE

local modifiers = {
    {
        id = "curecommondisease-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        levels = { false, 2, false, false, false },
        effects = {
            {
                id = effectTypes.CureCommonDisease,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "cureblightdisease-onUse",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 40,
        charge = 160,
        levels = { false, false, 3, false, false },
        effects = {
            {
                id = effectTypes.CureBlightDisease,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "curepoison-onUse",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        levels = { false, 2, false, false, false },
        effects = {
            {
                id = effectTypes.CurePoison,
                range = rangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "restorehealth-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.RestoreHealth,
                range = rangeTypes.Self,
                min = { 2, 4, 8, 12, 16 },
                max = { 4, 8, 12, 16, 20 },
                duration = { 5, 5, 5, 5, 5 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "restoremagicka-onUse",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.RestoreMagicka,
                range = rangeTypes.Self,
                min = { 1, 2, 4, 8, 12 },
                max = { 2, 4, 8, 12, 16 },
                duration = { 5, 5, 5, 5, 5 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "restorefatigue-onUse",
        affixType = "suffix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 5,
        charge = 100,
        effects = {
            {
                id = effectTypes.RestoreFatigue,
                range = rangeTypes.Self,
                min = { 4, 8, 16, 24, 32 },
                max = { 8, 16, 24, 32, 40 },
                duration = { 5, 5, 5, 5, 5 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
            } },
        },
    },
    {
        id = "fortifyattribute-speed-boots-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FortifyAttribute,
                attribute = attributes.speed.id,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
    },
    {
        id = "fortifymaximummagicka-constant",
        affixType = "prefix",
        value = 200,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FortifyMaximumMagicka,
                range = rangeTypes.Self,
                min = { false, 2, 4, 6, 8 },
                max = { false, 2, 4, 6, 8 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = { notTypes = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "resistfire-onUse",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.ResistFire,
                range = rangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistfire-constant",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistFire,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistfrost-onUse",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.ResistFrost,
                range = rangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistfrost-constant",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistFrost,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistshock-onUse",
        affixType = "prefix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.ResistShock,
                range = rangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 30, 40, 50, 60, 70 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistshock-constant",
        affixType = "prefix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistShock,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistElements-onUse",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 200,
        effects = {
            {
                id = effectTypes.ResistFire,
                range = rangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
            },
            {
                id = effectTypes.ResistFrost,
                range = rangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
            },
            {
                id = effectTypes.ResistShock,
                range = rangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 20, 30, 40, 50, 60 },
                duration = { 20, 30, 40, 50, 60 },
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
        id = "resistElements-constant",
        affixType = "prefix",
        value = 150,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistFire,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = effectTypes.ResistFrost,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = effectTypes.ResistShock,
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
        id = "resistmagicka-constant",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistMagicka,
                range = rangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
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
        id = "resistSicknesses-constant",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistCommonDisease,
                range = rangeTypes.Self,
                min = { 15, 30, 45, 60, 75 },
                max = { 15, 30, 45, 60, 75 },
            },
            {
                id = effectTypes.ResistBlightDisease,
                range = rangeTypes.Self,
                min = { 10, 25, 40, 55, 70 },
                max = { 10, 25, 40, 55, 70 },
            },
            {
                id = effectTypes.ResistPoison,
                range = rangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 10, 20, 30, 50, 50 },
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
        id = "resistnormalweapons-constant",
        affixType = "prefix",
        value = 25,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistNormalWeapons,
                range = rangeTypes.Self,
                min = { false, 10, 20, 30, 50 },
                max = { false, 10, 20, 30, 50 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "resistparalysis-onUse",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.CastOnUse,
        cost = 10,
        charge = 100,
        effects = {
            {
                id = effectTypes.ResistParalysis,
                range = rangeTypes.Self,
                min = { 50, 60, 70, 80, 90 },
                max = { 60, 70, 80, 90, 100 },
                duration = { 10, 20, 30, 40, 60 }
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
                [T.Clothing.TYPE.Belt] = true,
            } },
            [T.Weapon] = { types = {
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    },
    {
        id = "resistparalysis-constant",
        affixType = "suffix",
        value = 50,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.ResistParalysis,
                range = rangeTypes.Self,
                min = { false, 20, 40, 60, 80 },
                max = { false, 20, 40, 60, 80 },
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

local restoreAttrEffects = {}
for _, attribute in pairs(attributes) do
    table.insert(restoreAttrEffects, {
        id = effectTypes.RestoreAttribute,
        attribute = attribute.id,
        range = rangeTypes.Self,
        min = { false, 1, 2, 3, 4 },
        max = { false, 1, 2, 3, 4 },
        duration = { false, 5, 5, 5, 5 }
    })
end

table.insert(modifiers, {
    id = "restoreattribute-all-onUse",
    affixType = "suffix",
    value = 75,
    castType = enchantTypes.CastOnUse,
    cost = 20,
    charge = 100,
    effects = restoreAttrEffects,
    itemTypes = {
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.Ring] = true,
            [T.Clothing.TYPE.Amulet] = true,
            [T.Clothing.TYPE.Belt] = true,
        } },
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.BluntTwoWide] = true,
        } },
    },
})

local fortifyAttrAffixes = {
    [attributes.strength] = "suffix",
    [attributes.intelligence] = "suffix",
    [attributes.willpower] = "suffix",
    [attributes.agility] = "suffix",
    [attributes.speed] = "prefix",
    [attributes.endurance] = "prefix",
    [attributes.personality] = "prefix",
    [attributes.luck] = "prefix",
}

for attribute, affix in pairs(fortifyAttrAffixes) do
    table.insert(modifiers, {
        id = "fortifyattribute-" .. attribute.id .. "-onUse",
        affixType = affix,
        value = 25,
        castType = enchantTypes.CastOnUse,
        cost = 20,
        charge = 100,
        effects = {
            {
                id = effectTypes.FortifyAttribute,
                attribute = attribute.id,
                range = rangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 10, 15, 20, 25, 40 },
                duration = { 20, 30, 40, 50, 60 },
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
    })
    table.insert(modifiers, {
        id = "fortifyattribute-" .. attribute.id .. "-constant",
        affixType = affix,
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FortifyAttribute,
                attribute = attribute.id,
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
                [T.Weapon.TYPE.BluntTwoWide] = true,
                [T.Weapon.TYPE.MarksmanBow] = true,
                [T.Weapon.TYPE.MarksmanCrossbow] = true,
            } },
        },
    })
end

local fortifySkillTypes = {
    [skills.athletics] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.Boots] = true,
            [T.Armor.TYPE.Greaves] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.Shoes] = true,
        } },
    },
    [skills.block] = {
        [T.Armor] = { types = { [T.Armor.TYPE.Shield] = true } },
        [T.Clothing] = true,
    },
    [skills.armorer] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LGauntlet] = true,
            [T.Armor.TYPE.RGauntlet] = true,
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [skills.security] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [skills.lightarmor] = {
        [T.Armor] = { classes = { Light = true } },
    },
    [skills.mediumarmor] = {
        [T.Armor] = { classes = { Medium = true } },
    },
    [skills.heavyarmor] = {
        [T.Armor] = { classes = { Heavy = true } },
    },
    [skills.handtohand] = {
        [T.Armor] = { types = {
            [T.Armor.TYPE.LGauntlet] = true,
            [T.Armor.TYPE.RGauntlet] = true,
            [T.Armor.TYPE.LBracer] = true,
            [T.Armor.TYPE.RBracer] = true,
        } },
        [T.Clothing] = { types = {
            [T.Clothing.TYPE.LGlove] = true,
            [T.Clothing.TYPE.RGlove] = true,
        } },
    },
    [skills.shortblade] = {
        [T.Weapon] = { types = { [T.Weapon.TYPE.ShortBladeOneHand] = true } },
    },
    [skills.longblade] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.LongBladeOneHand] = true,
            [T.Weapon.TYPE.LongBladeTwoHand] = true,
        } },
    },
    [skills.bluntweapon] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.BluntOneHand] = true,
            [T.Weapon.TYPE.BluntTwoClose] = true,
            [T.Weapon.TYPE.BluntTwoWide] = true,
        } },
    },
    [skills.axe] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.AxeOneHand] = true,
            [T.Weapon.TYPE.AxeTwoHand] = true
        } },
    },
    [skills.spear] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.SpearTwoWide] = true,
        } },
    },
    [skills.marksman] = {
        [T.Weapon] = { types = {
            [T.Weapon.TYPE.MarksmanBow] = true,
            [T.Weapon.TYPE.MarksmanCrossbow] = true,
            [T.Weapon.TYPE.MarksmanThrown] = true,
        } },
    },
    [skills.unarmored] = { [T.Clothing] = true },
    [skills.acrobatics] = { [T.Clothing] = true },
    [skills.sneak] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.mercantile] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.speechcraft] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.alchemy] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.alteration] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.conjuration] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.destruction] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.enchant] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.illusion] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.mysticism] = { [T.Armor] = true, [T.Clothing] = true },
    [skills.restoration] = { [T.Armor] = true, [T.Clothing] = true },
}

for skill, types in pairs(fortifySkillTypes) do
    table.insert(modifiers, {
        id = "fortifyskill-" .. skill.id .. "-constant",
        affixType = "prefix",
        value = 75,
        castType = enchantTypes.ConstantEffect,
        effects = {
            {
                id = effectTypes.FortifySkill,
                skill = skill.id,
                range = rangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            }
        },
        itemTypes = types,
    })
end

local dressing = {
    [T.Armor] = true,
    [T.Clothing] = { notTypes = {
        [T.Clothing.TYPE.Ring] = true,
        [T.Clothing.TYPE.Amulet] = true,
    } }
}

local fortifyTypes = {
    { skills = { skills.marksman, skills.lightarmor },
      types = {
          [T.Armor] = { classes = { Light = true } },
          [T.Clothing] = true,
      }
    },
    { skills = { skills.axe, skills.mediumarmor },
      types = {
          [T.Armor] = { classes = { Medium = true } },
          [T.Clothing] = true,
      }
    },
    { skills = { skills.conjuration, skills.heavyarmor },
      types = {
          [T.Armor] = { classes = { Heavy = true } },
          [T.Clothing] = true,
      }
    },
    { skills = { skills.longblade, skills.heavyarmor },
      types = {
          [T.Armor] = { classes = { Heavy = true } },
          [T.Clothing] = true,
      }
    },
    { skills = { skills.handtohand, skills.unarmored },
      types = { [T.Clothing] = true }
    },
    { skills = { skills.athletics, skills.mediumarmor },
      types = {
          [T.Armor] = { classes = { Medium = true } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Ring] = true,
              [T.Clothing.TYPE.Amulet] = true,
          } } }
    },
    { skills = { skills.unarmored, skills.handtohand, skills.lightarmor },
      types = {
          [T.Armor] = { classes = { Light = true } },
          [T.Clothing] = { notTypes = {
              [T.Clothing.TYPE.Ring] = true,
              [T.Clothing.TYPE.Amulet] = true,
          } } }
    },
    { skills = { skills.shortblade, skills.alchemy }, types = dressing },
    { skills = { skills.bluntweapon, skills.destruction }, types = dressing },
    { skills = { skills.restoration, skills.mysticism }, types = dressing },
    { skills = { skills.sneak, skills.illusion }, types = dressing },
    { skills = { skills.speechcraft, skills.illusion }, types = dressing },
    { skills = { skills.speechcraft, skills.mercantile }, types = dressing },
    { skills = { skills.shortblade, skills.mercantile }, types = dressing },
    { skills = { skills.acrobatics, skills.athletics }, types = dressing },
    { skills = { skills.speechcraft, skills.sneak }, types = dressing },
    { skills = { skills.enchant, skills.conjuration }, types = dressing },
    { skills = { skills.longblade, skills.destruction }, types = dressing },
    { skills = { skills.sneak, skills.security }, types = dressing },
    { skills = { skills.longblade, skills.block }, types = dressing },
    { skills = { skills.conjuration, skills.alchemy }, types = dressing },
    { skills = { skills.destruction, skills.alteration }, types = dressing },
    { skills = { skills.alteration, skills.mysticism, skills.illusion }, types = dressing },
    { skills = { skills.mercantile, skills.security }, types = dressing },
    { skills = { skills.unarmored, skills.handtohand }, types = dressing },
    { attributes = { attributes.personality },
      skills = { skills.speechcraft, skills.mercantile }, types = dressing },
    { attributes = { attributes.personality, attributes.willpower },
      skills = { skills.speechcraft }, types = dressing },
    { attributes = { attributes.luck },
      skills = { skills.mercantile }, types = dressing },
    { attributes = { attributes.agility },
      skills = { skills.marksman }, types = dressing },
    { attributes = { attributes.intelligence },
      skills = { skills.speechcraft }, types = dressing },
    { attributes = { attributes.personality, attributes.endurance }, types = dressing },
    { attributes = { attributes.agility, attributes.personality }, types = dressing },
}

for _, cfg in ipairs(fortifyTypes) do
    local effects = {}
    local ids = {}
    for _, attribute in ipairs(cfg.attributes or {}) do
        table.insert(ids, attribute.id)
        table.insert(effects, {
            id = effectTypes.FortifyAttribute,
            attribute = attribute.id,
            range = rangeTypes.Self,
            min = { false, 3, 8, 12, 16 },
            max = { false, 3, 8, 12, 16 },
        })
    end
    for _, skill in ipairs(cfg.skills or {}) do
        table.insert(ids, skill.id)
        table.insert(effects, {
            id = effectTypes.FortifySkill,
            skill = skill.id,
            range = rangeTypes.Self,
            min = { false, 3, 8, 12, 16 },
            max = { false, 3, 8, 12, 16 },
        })
    end
    table.insert(modifiers, {
        id = "fortify-" .. table.concat(ids, "-") .. "-constant",
        affixType = "suffix",
        value = 100,
        castType = enchantTypes.ConstantEffect,
        effects = effects,
        itemTypes = cfg.types,
    })
end

return modifiers