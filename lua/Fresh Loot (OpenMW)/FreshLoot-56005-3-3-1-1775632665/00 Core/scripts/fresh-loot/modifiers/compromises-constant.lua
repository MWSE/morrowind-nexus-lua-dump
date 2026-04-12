local core = require("openmw.core")
local T = require("openmw.types")

local mT = require("scripts.fresh-loot.config.types")

local Attributes = core.stats.Attribute.records
local Skills = core.stats.Skill.records
local EffectTypes = core.magic.EFFECT_TYPE
local EnchantTypes = core.magic.ENCHANTMENT_TYPE
local RangeTypes = core.magic.RANGE

return {
    {
        id = "fortifyStrength-weaknessCommonBlightDiseases-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.strength.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 5, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.WeaknessToCommonDisease,
                range = RangeTypes.Self,
                min = { 25, 35, 50, 65, 100 },
                max = { 25, 35, 50, 65, 100 },
            },
            {
                id = EffectTypes.WeaknessToBlightDisease,
                range = RangeTypes.Self,
                min = { 25, 35, 50, 65, 100 },
                max = { 25, 35, 50, 65, 100 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
        },
    },
    {
        id = "sanctuary-fortifyAttack-weaknessWeaponsMagickaCommonBlightDiseases-constant",
        affixType = mT.affixes.Prefix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Sanctuary,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.FortifyAttack,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.WeaknessToNormalWeapons,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.WeaknessToMagicka,
                range = RangeTypes.Self,
                min = { false, 15, 20, 30, 40 },
                max = { false, 15, 20, 30, 40 },
            },
            {
                id = EffectTypes.WeaknessToCommonDisease,
                range = RangeTypes.Self,
                min = { false, 35, 50, 70, 100 },
                max = { false, 35, 50, 70, 100 },
            },
            {
                id = EffectTypes.WeaknessToBlightDisease,
                range = RangeTypes.Self,
                min = { false, 35, 50, 70, 100 },
                max = { false, 35, 50, 70, 100 },
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
                [T.Weapon.TYPE.MarksmanThrown] = true,
            } },
        },
    },
    {
        id = "chameleon-shield-sunDamage-weaknessCommonDisease-constant",
        affixType = mT.affixes.Suffix,
        value = 200,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Chameleon,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.Shield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
            },
            {
                id = EffectTypes.SunDamage,
                range = RangeTypes.Self,
                min = { false, 1, 1, 1, 1 },
                max = { false, 1, 2, 3, 5 },
            },
            {
                id = EffectTypes.WeaknessToCommonDisease,
                range = RangeTypes.Self,
                min = { false, 35, 50, 70, 100 },
                max = { false, 35, 50, 70, 100 },
            },
        },
        itemTypes = {
            [T.Armor] = true,
            [T.Clothing] = true,
        },
    },
    {
        id = "restoreMagicka-weaknessMagicka-damageFatigue-constant",
        affixType = mT.affixes.Suffix,
        value = 300,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.RestoreMagicka,
                range = RangeTypes.Self,
                min = { false, false, 1, 1, 2 },
                max = { false, false, 1, 2, 3 },
            },
            {
                id = EffectTypes.WeaknessToMagicka,
                range = RangeTypes.Self,
                min = { false, false, 30, 40, 50 },
                max = { false, false, 30, 40, 50 },
            },
            {
                id = EffectTypes.DamageFatigue,
                range = RangeTypes.Self,
                min = { false, false, 1, 1, 2 },
                max = { false, false, 1, 2, 2 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Ring] = true,
                [T.Clothing.TYPE.Amulet] = true,
            } },
        },
    },
    {
        id = "resistFire-fireShield-weaknessFrostShockPoison-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { false, 15, 20, 25, 35 },
                max = { false, 15, 20, 25, 35 },
            },
            {
                id = EffectTypes.FireShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
            },
            {
                id = EffectTypes.WeaknessToFrost,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToShock,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToPoison,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Boots] = true,
            } },
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Shoes] = true,
            } },
        },
    },
    {
        id = "resistFrost-frostShield-weaknessFireShockPoison-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFrost,
                range = RangeTypes.Self,
                min = { false, 15, 20, 25, 35 },
                max = { false, 15, 20, 25, 35 },
            },
            {
                id = EffectTypes.FrostShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
            },
            {
                id = EffectTypes.WeaknessToFire,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToShock,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToPoison,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Shield] = true,
            } },
        },
    },
    {
        id = "resistShock-lightningShield-weaknessFrostFirePoison-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistShock,
                range = RangeTypes.Self,
                min = { false, 15, 20, 25, 35 },
                max = { false, 15, 20, 25, 35 },
            },
            {
                id = EffectTypes.LightningShield,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
            },
            {
                id = EffectTypes.WeaknessToFrost,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToFire,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToPoison,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Cuirass] = true,
            } },
        },
    },
    {
        id = "resistWeapons-fortifySpeed-weaknessMagickaPoisonBlight-sound-damageFatigue-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistNormalWeapons,
                range = RangeTypes.Self,
                min = { false, 15, 25, 35, 50 },
                max = { false, 15, 25, 35, 50 },
            },
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.speed.id,
                range = RangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 10, 20, 30, 40 },
            },
            {
                id = EffectTypes.WeaknessToMagicka,
                range = RangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 10, 20, 30, 40 },
            },
            {
                id = EffectTypes.WeaknessToPoison,
                range = RangeTypes.Self,
                min = { false, 10, 20, 30, 40 },
                max = { false, 10, 20, 30, 40 },
            },
            {
                id = EffectTypes.WeaknessToBlightDisease,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 50 },
                max = { false, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.Sound,
                range = RangeTypes.Self,
                min = { false, 5, 8, 10, 15 },
                max = { false, 5, 8, 10, 15 },
            },
            {
                id = EffectTypes.DamageFatigue,
                range = RangeTypes.Self,
                min = { false, 1, 1, 1, 2 },
                max = { false, 1, 1, 2, 2 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Robe] = true,
            } },
        },
    },
    {
        id = "fortifyStrength-burden-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.strength.id,
                range = RangeTypes.Self,
                min = { 5, 10, 15, 20, 30 },
                max = { 5, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.Burden,
                range = RangeTypes.Self,
                min = { 50, 100, 150, 200, 250 },
                max = { 50, 100, 150, 200, 250 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.LGlove] = true,
                [T.Clothing.TYPE.RGlove] = true,
            } },
            [T.Armor] = { types = {
                [T.Armor.TYPE.LBracer] = true,
                [T.Armor.TYPE.RBracer] = true,
                [T.Armor.TYPE.LGauntlet] = true,
                [T.Armor.TYPE.RGauntlet] = true,
            } },
        },
    },
    {
        id = "reflect-sound-stuntedMagicka-constant",
        affixType = mT.affixes.Suffix,
        value = 400,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.Reflect,
                range = RangeTypes.Self,
                min = { false, false, 10, 20, 30 },
                max = { false, false, 10, 20, 30 },
            },
            {
                id = EffectTypes.Sound,
                range = RangeTypes.Self,
                min = { false, false, 10, 20, 30 },
                max = { false, false, 10, 20, 30 },
            },
            {
                id = EffectTypes.StuntedMagicka,
                range = RangeTypes.Self,
            },
        },
        itemTypes = {
            [T.Weapon] = { notTypes = {
                [T.Weapon.TYPE.MarksmanThrown] = true,
                [T.Weapon.TYPE.Arrow] = true,
                [T.Weapon.TYPE.Bolt] = true,
            } },
        },
    },
    {
        id = "resistFire-weaknessShock-constant",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistFire,
                range = RangeTypes.Self,
                min = { 10, 20, 30, 40, 50 },
                max = { 10, 20, 30, 40, 50 },
            },
            {
                id = EffectTypes.WeaknessToShock,
                range = RangeTypes.Self,
                min = { 20, 40, 60, 80, 100 },
                max = { 20, 40, 60, 80, 100 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.LPauldron] = true,
                [T.Armor.TYPE.RPauldron] = true,
            } },
        },
    },
    {
        id = "resistParalysis-fortifyEndurance-burden-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.ResistParalysis,
                range = RangeTypes.Self,
                min = { false, 20, 35, 50, 75 },
                max = { false, 20, 35, 50, 75 },
            },
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.endurance.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.Burden,
                range = RangeTypes.Self,
                min = { false, 20, 40, 60, 80 },
                max = { false, 20, 40, 60, 80 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Greaves] = true,
            } },
        },
    },
    {
        id = "restoreFatigue-feather-weaknessWeapons-constant",
        affixType = mT.affixes.Prefix,
        value = 150,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.RestoreFatigue,
                range = RangeTypes.Self,
                min = { 1, 1, 2, 3, 4 },
                max = { 1, 2, 3, 4, 5 },
            },
            {
                id = EffectTypes.Feather,
                range = RangeTypes.Self,
                min = { 20, 40, 60, 80, 100 },
                max = { 20, 40, 60, 80, 100 },
            },
            {
                id = EffectTypes.WeaknessToNormalWeapons,
                range = RangeTypes.Self,
                min = { 20, 30, 40, 50, 60 },
                max = { 20, 30, 40, 50, 60 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Belt] = true,
                [T.Clothing.TYPE.Pants] = true,
            } },
        },
    },
    {
        id = "fortifyUnarmored-weaknessShockFrost-constant",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifySkill,
                skill = Skills.unarmored.id,
                range = RangeTypes.Self,
                min = { 10, 15, 20, 30, 40 },
                max = { 10, 15, 20, 30, 40 },
            },
            {
                id = EffectTypes.WeaknessToShock,
                range = RangeTypes.Self,
                min = { 15, 25, 35, 45, 55 },
                max = { 15, 25, 35, 45, 55 },
            },
            {
                id = EffectTypes.WeaknessToFrost,
                range = RangeTypes.Self,
                min = { 15, 25, 35, 45, 55 },
                max = { 15, 25, 35, 45, 55 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Shirt] = true,
            } },
        },
    },
    {
        id = "fortifySpeechcraftEndurance-burden-weaknessCommonDisease-constant",
        affixType = mT.affixes.Prefix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifySkill,
                skill = Skills.speechcraft.id,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 25 },
                max = { false, 10, 15, 20, 25 },
            },
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.endurance.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.Burden,
                range = RangeTypes.Self,
                min = { false, 20, 40, 60, 80 },
                max = { false, 20, 40, 60, 80 },
            },
            {
                id = EffectTypes.WeaknessToCommonDisease,
                range = RangeTypes.Self,
                min = { false, 20, 40, 60, 80 },
                max = { false, 20, 40, 60, 80 },
            },
        },
        itemTypes = {
            [T.Clothing] = { types = {
                [T.Clothing.TYPE.Skirt] = true,
            } },
        },
    },
    {
        id = "fortifyIntelligenceWillpower-blind-constant",
        affixType = mT.affixes.Suffix,
        value = 100,
        castType = EnchantTypes.ConstantEffect,
        effects = {
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.intelligence.id,
                range = RangeTypes.Self,
                min = { false, 10, 15, 20, 30 },
                max = { false, 10, 15, 20, 30 },
            },
            {
                id = EffectTypes.FortifyAttribute,
                attribute = Attributes.willpower.id,
                range = RangeTypes.Self,
                min = { false, 5, 10, 15, 20 },
                max = { false, 5, 10, 15, 20 },
            },
            {
                id = EffectTypes.Blind,
                range = RangeTypes.Self,
                min = { false, 20, 30, 40, 60 },
                max = { false, 20, 30, 40, 60 },
            },
        },
        itemTypes = {
            [T.Armor] = { types = {
                [T.Armor.TYPE.Helmet] = true,
            } },
        },
    },
}