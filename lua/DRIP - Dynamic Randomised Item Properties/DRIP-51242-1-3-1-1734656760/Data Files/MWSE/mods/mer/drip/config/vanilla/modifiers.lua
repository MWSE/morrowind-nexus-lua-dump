---@type Drip.Modifier.Data[]
local modifiers = {
    --Attack Speed
    {
        id = "readiness",
        suffix = "Readiness",
        valueMulti = 1.25,
        description = "1.10x Attack Speed",
        multipliers = {
            speed = 1.10
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
            [tes3.weaponType.marksmanBow] = true,
            [tes3.weaponType.marksmanCrossbow] = true,
        },
    },
    {
        id = "swiftness",
        suffix = "Swiftness",
        valueMulti = 1.5,
        description = "1.25x Attack Speed",
        multipliers = {
            speed = 1.25
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
            [tes3.weaponType.marksmanBow] = true,
            [tes3.weaponType.marksmanCrossbow] = true,
        },
    },

    --Sharp weapons only
    {
        id = "jagged",
        prefix = "Jagged",
        value = 100,
        description = "+5 Max Damage",
        modifications = {
            chopMax = 5,
            slashMax = 5,
            thrustMax = 5,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
            [tes3.weaponType.marksmanThrown] = true,
        },
    },
    {
        id = "sharp",
        prefix = "Sharp",
        value = 100,
        description = "+10 Max Damage",
        modifications = {
            chopMax = 10,
            slashMax = 10,
            thrustMax = 10,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
            [tes3.weaponType.marksmanThrown] = true,
        },
    },

    --blunt weapon + max
    {

        id = "cruel",
        prefix = "Cruel",
        value = 100,
        description = "+5 Max Damage",
        modifications = {
            chopMax = 5,
            slashMax = 5,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
        },
    },
    {

        id = "merciless",
        prefix = "Merciless",
        value = 100,
        description = "+10 Max Damage",
        modifications = {
            chopMax = 10,
            slashMax = 10,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
        },
    },


    {
        id = "ferocious",
        prefix = "Ferocious",
        valueMulti = 1.25,
        description = "1.25x Damage",
        multipliers = {
            chopMin = 1.25,
            slashMin = 1.25,
            thrustMin = 1.25,
            chopMax = 1.25,
            slashMax = 1.25,
            thrustMax = 1.25,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
        id = "brutal",
        prefix = "Brutal",
        valueMulti = 1.5,
        description = "1.5x Damage",
        multipliers = {
            chopMin = 1.5,
            slashMin = 1.5,
            thrustMin = 1.5,
            chopMax = 1.5,
            slashMax = 1.5,
            thrustMax = 1.5,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
        id = "vicious",
        prefix = "Vicious",
        valueMulti = 1.75,
        description = "1.75x Damage",
        multipliers = {
            chopMin = 1.75,
            slashMin = 1.75,
            thrustMin = 1.75,
            chopMax = 1.75,
            slashMax = 1.75,
            thrustMax = 1.75,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
        id = "deadly",
        prefix = "Deadly",
        valueMulti = 2.0,
        description = "2x Damage",
        multipliers = {
            chopMin = 2,
            slashMin = 2,
            thrustMin = 2,
            chopMax = 2,
            slashMax = 2,
            thrustMax = 2,
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },


    --Weight multipliers\
    {
        id = "condensed",
        prefix = "Condensed",
        valueMulti = 1.25,
        castType = tes3.enchantmentType.constant,
        description = "0.75x Weight",
        multipliers = {
            weight = 0.75,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.weapon] = true,
        },
    },

    {
        id = "compact",
        prefix = "Compact",
        valueMulti = 1.5,
        castType = tes3.enchantmentType.constant,
        description = "0.5x Weight",
        multipliers = {
            weight = 0.5,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.weapon] = true,
        },
    },

    --Armor Multipliers
    {
        id = "fortified",
        prefix = "Fortified",
        valueMulti = 1.5,
        description = "1.5x Armor Rating",
        multipliers = {
            armorRating = 1.5
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },
    {
        id = "glorious",
        prefix = "Glorious",
        valueMulti = 2.0,
        description = "2x Armor Rating",
        multipliers = {
            armorRating = 2,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },

    --Condition Muiltipliers

    {
        id = "superior",
        prefix = "Superior",
        valueMulti = 1.25,
        description = "2x Max Condition",
        multipliers = {
            maxCondition = 2,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
            [tes3.weaponType.marksmanBow] = true,
            [tes3.weaponType.marksmanCrossbow] = true,
        },
    },
    --Vanilla effects

    --drainAttribute
    {
        id = "shaming",
        prefix = "Shaming",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.intelligence,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "misfortune",
        suffix = "Misfortune",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.luck,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "maiming",
        suffix = "Maiming",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.speed,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "weakening",
        suffix = "Weakening",
        value = 100,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.strength,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    --DrainHealth
    {
        id = "wounding",
        suffix = "Wounding",
        value = 100,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainHealth,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "draining",
        suffix = "Draining",
        value = 100,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainMagicka,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "exhaustion",
        suffix = "Exhaustion",
        value = 75,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.drainFatigue,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    --damageHealth
    {
        id = "bleeding",
        suffix = "Bleeding",
        value = 100,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.damageHealth,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 1,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "Spirit knife",
        suffix = "Spirit Knife",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.damageHealth,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- waterBreathing
    --weak
    {
        id = "mudcrab",
        prefix = "Mudcrab's",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 50,
        effects = {
            {
                id = tes3.effect.waterBreathing,
                rangeType = tes3.effectRange.self,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        },
    },
    --strong
    {
        id = "argonian",
        prefix = "Argonian's",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.waterBreathing,
                rangeType = tes3.effectRange.self,
                duration = 25,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- swiftSwim
    --weak
    {
        id = "fish",
        suffix = "the Fish",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.swiftSwim,
                rangeType = tes3.effectRange.self,
                duration = 25,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "dreugh",
        suffix = "the Dreugh",
        value = 100,
        castType = tes3.enchantmentType.constant,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.swiftSwim,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
            [tes3.objectType.armor] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.shoes] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.boots] = true,
        }
    },

    -- waterWalking
    --weak
    {
        id = "buoyancy",
        suffix = "Buoyancy",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.waterWalking,
                rangeType = tes3.effectRange.self,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "Ocean-striding",
        suffix = "Ocean-Striding",
        value = 100,
        castType = tes3.enchantmentType.constant,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.waterWalking,
                rangeType = tes3.effectRange.self,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
            [tes3.objectType.armor] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.shoes] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.boots] = true,
        }
    },

    -- shield
    --weak
    {
        id = "protector",
        prefix = "Protector's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.shield,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    --strong
    {
        id = "guardian",
        prefix = "Guardian's",
        value = 300,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.shield,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- fireShield
    {
        id = "flameguard",
        suffix = "Flameguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fireShield,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- lightningShield
    {
        id = "stormguard",
        suffix = "Stormguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.lightningShield,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- frostShield
    {
        id = "frostguard",
        suffix = "Frostguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.frostShield,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- burden
    {
        id = "heavystep",
        suffix = "Heavystep",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.burden,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 5,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- feather
    --weak
    {
        id = "pocketed",
        prefix = "Pocketed",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.feather,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    --strong
    {
        id = "hoarder",
        prefix = "Hoarder's",
        value = 150,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.feather,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- jump
    --weak
    {
        id = "frog",
        suffix = "the Frog",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.jump,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 10,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "toad",
        suffix = "the Toad",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.jump,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- levitate
    --weak
    {
        id = "floating",
        suffix = "Floating",
        value = 75,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.levitate,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "soaring",
        suffix = "Soaring",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.levitate,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- slowFall
    --weak
    {
        id = "slowfall",
        suffix = "Slowfall",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.slowFall,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    -- lock
    --weak
    {
        id = "jamming",
        suffix = "Jamming",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.lock,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 1,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- open
    --weak
    {
        id = "burgler",
        prefix = "Burgler's",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.open,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "locksmith",
        prefix = "Locksmith's",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.open,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- fireDamage
    --weak
    {
        id = "firey",
        prefix = "Firey",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "blazing",
        prefix = "Blazing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --Slow
    {
        id = "burning",
        suffix = "Burning",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- shockDamage
    --weak
    {
        id = "arching",
        prefix = "Arching",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "shocking",
        prefix = "Shocking",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --Slow
    {
        id = "electricity",
        suffix = "Electricity",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- frostDamage
    --weak
    {
        id = "chilling",
        prefix = "Chilling",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "freezing",
        prefix = "Freezing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --Slow
    {
        id = "icicles",
        suffix = "Icicles",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    --3 elements
    {
        id = "maelstrom",
        suffix = "the Maelstrom",
        value = 200,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 5
            },
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 5
            },
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 5
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },


    -- poison
    --weak
    {
        id = "viper",
        prefix = "Viper's",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.poison,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "toxic",
        prefix = "Toxic",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.poison,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 5,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    --weaknesstoFire/weaknesstoFrost/weaknesstoShock/weaknesstoMagicka
    {
        id = "exposing",
        suffix = "Exposing",
        value = 75,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.weaknesstoFire,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 15,
            },
            {
                id = tes3.effect.weaknesstoFrost,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 15,
            },
            {
                id = tes3.effect.weaknesstoShock,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 15,
            },
            {
                id = tes3.effect.weaknesstoMagicka,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- disintegrateWeapon/disintegrateArmor

    --weak
    {
        id = "corrosive",
        prefix = "Corrosive",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.disintegrateWeapon,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
            },
            {
                id = tes3.effect.disintegrateArmor,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "acidic",
        prefix = "Acidic",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.disintegrateWeapon,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 10,
            },
            {
                id = tes3.effect.disintegrateArmor,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- invisibility
    {
        id = "hiding",
        suffix = "Hiding",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.invisibility,
                rangeType = tes3.effectRange.self,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    {
        id = "shadows",
        suffix = "Shadows",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.invisibility,
                rangeType = tes3.effectRange.self,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- chameleon
    {
        id = "camoflauge",
        suffix = "Camoflauge",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.chameleon,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    {
        id = "astral",
        prefix = "Astral",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.chameleon,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 2,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- light
    {
        id = "glowing",
        prefix = "Glowing",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.light,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        id = "illuminating",
        prefix = "Illuminating",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        effects = {
            {
                id = tes3.effect.light,
                rangeType = tes3.effectRange.target,
                min = 5,
                max = 10,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- sanctuary
    --weak
    {
        id = "elusive",
        prefix = "Elusive",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.sanctuary,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    --strong
    {
        id = "watcher",
        prefix = "Watcher's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.sanctuary,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- nightEye
    {
        id = "cat",
        suffix = "the Cat",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.nightEye,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- charm
    {
        id = "befriending",
        suffix = "Befriending",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.charm,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 10,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- paralyze
    --weak
    {
        id = "jink",
        prefix = "Jink",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.paralyze,
                rangeType = tes3.effectRange.touch,
                duration = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "paralyzing",
        prefix = "Paralyzing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.paralyze,
                rangeType = tes3.effectRange.touch,
                duration = 8,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- silence
    --weak
    {
        id = "tongueTying",
        suffix = "Tongue-Tying",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.silence,
                rangeType = tes3.effectRange.touch,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    --strong
    {
        id = "muting",
        suffix = "Muting",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.silence,
                rangeType = tes3.effectRange.touch,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- blind
    {
        id = "blinding",
        suffix = "Blinding",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.blind,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 5,
                duration = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "eyeGouging",
        suffix = "Eye-Gouging",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.blind,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 7,
                duration = 6,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- sound
    {
        id = "echoes",
        suffix = "Echoes",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.sound,
                rangeType = tes3.effectRange.touch,
                duration = 5,
                min = 1,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    -- soultrap
    {
        id = "soulStealing",
        suffix = "Soul-Stealing",
        value = 30,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.soultrap,
                rangeType = tes3.effectRange.touch,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- telekinesis
    {
        id = "farReaching",
        suffix = "Far-Reaching",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.telekinesis,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- detectAnimal/detectEnchantment/detectKey
    {
        id = "seeker",
        suffix = "the Seeker",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.detectAnimal,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.detectEnchantment,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.detectKey,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },


    -- spellAbsorption
    {
        id = "absorbing",
        suffix = "Absorbing",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.spellAbsorption,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- reflect
    {
        id = "mirrors",
        suffix = "Mirrors",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.reflect,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- cureCommonDisease
    {
        id = "curing",
        suffix = "Curing",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.cureCommonDisease,
                rangeType = tes3.effectRange.self,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- cureBlightDisease
    {
        id = "rilm",
        prefix = "Rilm's",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 200,
        effects = {

            {
                id = tes3.effect.cureBlightDisease,
                rangeType = tes3.effectRange.self,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- curePoison
    {
        id = "balyna",
        prefix = "Balyna's",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.curePoison,
                rangeType = tes3.effectRange.self,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- cureParalyzation
    {
        id = "freeAction",
        suffix = "Free Action",
        value = 20,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.cureParalyzation,
                rangeType = tes3.effectRange.self,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- restoreAttribute
    {
        id = "restoration",
        suffix = "Restoration",
        value = 75,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.strength,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 5
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.speed,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 5
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.endurance,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 5
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 5
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- restoreHealth
    --weak
    {
        id = "healing",
        suffix = "Healing",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 5,
        maxCharge = 50,
        effects = {
            {
                id = tes3.effect.restoreHealth,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 5,
                duration = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    --strong
    {
        id = "recovery",
        suffix = "Recovery",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreHealth,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 4,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- restoreMagicka
    {
        id = "meditation",
        suffix = "Meditation",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreMagicka,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 2,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- restoreFatigue
    {
        id = "stamina",
        suffix = "Stamina",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreFatigue,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 4,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- fortifyAttribute
    {
        id = "bear",
        suffix = "the Bear",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.strength,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "owl",
        suffix = "the Owl",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.intelligence,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "faith",
        suffix = "Faith",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.willpower,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "nixHound",
        suffix = "the Nix-Hound",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "hare",
        suffix = "the Hare",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.speed,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    { --boots only
    id = "haste",
        suffix = "Haste",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.speed,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {

            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,

        },
        validClothingSlots = {
            [tes3.clothingSlot.shoes] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.boots] = true,
        }
    },
    {
        id = "ogrim",
        prefix = "Ogrim's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.endurance,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        id = "scamp",
        prefix = "Scamp's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "celestial",
        prefix = "Celestial",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.luck,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    --fortifyAttribute combos
    {
        id = "king",
        prefix = "King's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                min = 2,
                max = 2,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.endurance,
                min = 2,
                max = 2,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },


    -- fortifySkill

    {
        id = "defender",
        prefix = "Defender's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.block,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.shield] = true
        }
    },

    {
        id = "blacksmith",
        prefix = "Blacksmith's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.armorer,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "fitted_medium",
        prefix = "Fitted",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mediumArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.medium] = true
        }
    },
    {
        id = "exceptional_medium",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mediumArmor,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.medium] = true
        }
    },

    {
        id = "fitted_heavy",
        prefix = "Fitted",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.heavyArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true
        }
    },
    {
        id = "exceptional_heavy",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.heavyArmor,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true
        }
    },

    {
        id = "balanced_blunt",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.bluntWeapon,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
        }
    },
    {
        id = "exceptional_blunt",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.bluntWeapon,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
        }
    },
    {
        id = "balanced_longBlade",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.longBladeOneHand] = true,
        }
    },
    {
        id = "exceptional_longBlade",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.longBladeOneHand] = true,
        }
    },
    {
        id = "balanced_axe",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.axe,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true
        }
    },
    {
        id = "exceptional_axe",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.axe,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true
        }
    },
    {
        id = "balanced_spear",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.spear,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.spearTwoWide] = true,
        }
    },
    {
        id = "exceptional_spear",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.spear,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.spearTwoWide] = true,
        }
    },

    {
        id = "runner",
        prefix = "Runner's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.athletics,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
            [tes3.objectType.armor] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.shoes] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.boots] = true,
        }
    },

    {
        id = "enchanter",
        prefix = "Enchanter's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.enchant,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "wizard",
        prefix = "Wizard's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "warlock",
        prefix = "Warlock's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alteration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "mesmer",
        prefix = "Mesmer's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.illusion,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "summoner",
        prefix = "Summoner's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.conjuration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "mystic",
        prefix = "Mystic's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mysticism,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "angel",
        prefix = "Angel's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.restoration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "alchemist",
        prefix = "Alchemist's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alchemy,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "devious",
        prefix = "Devious",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.sneak,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "gymnast",
        prefix = "Gymnast's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.acrobatics,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "fitted_light",
        prefix = "Fitted",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.lightArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.light] = true,
        }
    },
    {
        id = "exceptional_light",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.lightArmor,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.light] = true,
        }
    },

    {
        id = "balanced_shortBlade",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.shortBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
        },
    },
    {
        id = "exceptional_shortBlade",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.shortBlade,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
        },
    },

    {
        id = "balanced_marksman",
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.marksman,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.marksmanBow] = true,
            [tes3.weaponType.marksmanCrossbow] = true,
        },
    },
    {
        id = "exceptional_marksman",
        prefix = "Exceptional",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.marksman,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.marksmanBow] = true,
            [tes3.weaponType.marksmanCrossbow] = true,
        },
    },

    {
        id = "merchant",
        prefix = "Merchant's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        id = "wordsmith",
        prefix = "Wordsmith's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        id = "pugilist",
        prefix = "Pugilist's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.leftBracer] = true,
            [tes3.armorSlot.rightBracer] = true,
            [tes3.armorSlot.leftGauntlet] = true,
            [tes3.armorSlot.rightGauntlet] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.rightGlove] = true,
        },
    },

    --multi skill (each vanilla class)
    {
        id = "acrobat",
        suffix = "the Acrobat",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.acrobatics,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.athletics,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "agent",
        suffix = "the Agent",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.sneak,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "archer",
        suffix = "the Archer",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.marksman,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.lightArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.light] = true,
        },
    },
    {
        id = "assassin",
        suffix = "the Assassin",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.shortBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alchemy,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "barbarian",
        suffix = "the Barbarian",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.axe,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mediumArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.medium] = true
        }
    },
    {
        id = "bard",
        suffix = "the Bard",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.illusion,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "battlemage",
        suffix = "the Battlemage",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.conjuration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.heavyArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },
    {
        id = "crusader",
        suffix = "the Crusader",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.bluntWeapon,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "healer",
        suffix = "the Healer",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.restoration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mysticism,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "knight",
        suffix = "the Knight",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.heavyArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        }
    },
    {
        id = "mage",
        suffix = "the Mage",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alteration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "monk",
        suffix = "the Monk",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.unarmored,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
    },
    {
        id = "nightblade",
        suffix = "the Nightblade",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.sneak,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.illusion,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "pilgrim",
        suffix = "the Pilgrim",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "rogue",
        suffix = "the Rogue",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.shortBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "scout",
        suffix = "the Scout",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.athletics,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mediumArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.medium] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "sorcerer",
        suffix = "the Sorcerer",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.enchant,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.conjuration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "spellsword",
        suffix = "the Spellsword",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "thief",
        suffix = "the Thief",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.sneak,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.security,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "warrior",
        suffix = "the Warrior",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.block,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "witchhunter",
        suffix = "the Witchhunter",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.conjuration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alchemy,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    --Other multiskill
    {
        id = "arcanist",
        suffix = "the Arcanist",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alteration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "courtesan",
        suffix = "the Courtesan",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "diplomat",
        suffix = "the Diplomat",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "druid",
        suffix = "the Druid",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alteration,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mysticism,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },

            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.illusion,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "duelist",
        suffix = "the Duelist",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.shortBlade,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "gambler",
        suffix = "the Gambler",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.luck,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "brawler",
        suffix = "the Brawler",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.unarmored,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },

            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.lightArmor,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.light] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "jester",
        suffix = "the Jester",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "juggler",
        suffix = "the Juggler",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.marksman,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "poet",
        suffix = "the Poet",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.intelligence,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 2,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    {
        id = "cunning",
        prefix = "Cunning",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 2,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.security,
                rangeType = tes3.effectRange.self,
                min = 2,
                max = 2,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "feral",
        prefix = "Feral",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.unarmored,
                min = 2,
                max = 2,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                min = 2,
                max = 2,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- fortifyMaximumMagicka
    {
        id = "drake",
        prefix = "Drake's",
        value = 200,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyMaximumMagicka,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "dragon",
        prefix = "Dragon's",
        value = 500,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyMaximumMagicka,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- absorbAttribute

    -- absorbHealth
    {
        id = "leech",
        suffix = "the Leech",
        value = 75,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbHealth,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "vampire",
        suffix = "the Vampire",
        value = 150,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbHealth,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 4,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- absorbMagicka
    {
        id = "magekiller",
        prefix = "Magekiller's",
        value = 150,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbMagicka,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- absorbFatigue
    {
        id = "taxing",
        prefix = "Taxing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbFatigue,
                rangeType = tes3.effectRange.touch,
                min = 1,
                max = 3,
                duration = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    -- resistFire
    {
        id = "burgundy",
        prefix = "Burgundy",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "crimson",
        prefix = "Crimson",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- resistFrost
    {
        id = "cobalt",
        prefix = "Cobalt",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "azure",
        prefix = "Azure",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- resistShock
    {
        id = "coral",
        prefix = "Coral",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "amber",
        prefix = "Amber",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    --Resist Elements

    {
        id = "chromatic",
        prefix = "Chromatic",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "prismatic",
        prefix = "Prismatic",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- resistMagicka
    {
        id = "magickguard",
        suffix = "Magickguard",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistMagicka,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "lord",
        prefix = "Lord's",
        value = 200,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistMagicka,
                rangeType = tes3.effectRange.self,
                min = 7,
                max = 7,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- resistCommonDisease/resistBlightDisease/resistPoison
    {
        id = "medic",
        prefix = "Medic's",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistCommonDisease,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.resistBlightDisease,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.resistPoison,
                rangeType = tes3.effectRange.self,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },

    -- resistNormalWeapons
    {
        id = "ghostly",
        prefix = "Ghostly",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistNormalWeapons,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },


    -- resistParalysis
    {
        id = "freedom",
        suffix = "Freedom",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistParalysis,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },

    -- turnUndead
    {
        id = "blessed",
        prefix = "Blessed",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.turnUndead,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 5,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },

    {
        id = "holy",
        prefix = "Holy",
        value = 75,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.turnUndead,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 10,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },



    -- summonScamp
    {
        id = "summonScamp",
        suffix = "Summon Scamp",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.summonScamp,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonClannfear
    {
        id = "summonClannfear",
        suffix = "Summon Clannfear",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonClannfear,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- summonDaedroth
    {
        id = "summonDaedroth",
        suffix = "Summon Daedroth",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonDaedroth,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonDremora
    {
        id = "summonDremora",
        suffix = "Summon Dremora",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 500,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonDremora,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonAncestralGhost
    {
        id = "summonAncestral ghost",
        suffix = "Summon Ancestral Ghost",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonAncestralGhost,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonSkeletalMinion
    {
        id = "summonSkeletalMinion",
        suffix = "Summon Skeletal Minion",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonSkeletalMinion,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonBonewalker
    {
        id = "summonBonewalker",
        suffix = "Summon Bonewalker",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonBonewalker,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonGreaterBonewalker
    {
        id = "summonGreaterBonewalker",
        suffix = "Summon Greater Bonewalker",
        value = 300,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonGreaterBonewalker,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonBonelord
    {
        id = "summonBonelord",
        suffix = "Summon Bonelord",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonBonelord,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- summonWingedTwilight
    {
        id = "summonWingedTwilight",
        suffix = "Summon Winged Twilight",
        value = 300,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 500,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonWingedTwilight,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonHunger
    {
        id = "summonHunger",
        suffix = "Summon Hunger",
        value = 300,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonHunger,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonGoldenSaint
    {
        id = "summonGoldenSaint",
        suffix = "Summon Golden Saint",
        value = 400,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1000,
        maxCharge = 2000,
        effects = {
            {
                id = tes3.effect.summonGoldenSaint,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonFlameAtronach
    {
        id = "flamecalling",
        suffix = "Flamecalling",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonFlameAtronach,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- summonFrostAtronach
    {
        id = "frostcalling",
        suffix = "Frostcalling",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonFrostAtronach,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- summonStormAtronach
    {
        id = "stormcalling",
        suffix = "Stormcalling",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonStormAtronach,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },
    -- summonCenturionSphere
    {
        id = "summonCenturion sphere",
        suffix = "Summon Centurion Sphere",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonCenturionSphere,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- commandCreature
    {
        id = "taming",
        suffix = "Taming",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.commandCreature,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },

    -- commandHumanoid
    {
        id = "command",
        suffix = "Command",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.commandHumanoid,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.ring] = true,
            [tes3.clothingSlot.amulet] = true,
        }
    },


    -- boundDagger
    {
        id = "devil_dagger",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundDagger,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
        },
    },

    -- boundLongsword
    {
        id = "devil_longsword",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundLongsword,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.longBladeOneHand] = true,
        },
    },


    -- boundMace
    {
        id = "devil_mace",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundMace,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.bluntOneHand] = true,
        },
    },


    -- boundBattleAxe
    {
        id = "devil_battleaxe",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundBattleAxe,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.axeTwoHand] = true,
        },
    },


    -- boundSpear
    {
        id = "devil_spear",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundSpear,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.spearTwoWide] = true,
        },
    },


    -- boundLongbow
    {
        id = "devil_longbow",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundLongbow,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
        },
        validWeaponTypes = {
            [tes3.weaponType.marksmanBow] = true,
        },
    },


    -- boundCuirass
    {
        id = "devil_cuirass",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundCuirass,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.cuirass] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },

    -- boundHelm
    {
        id = "devil_helm",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundHelm,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.helmet] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },

    -- boundBoots
    {
        id = "devil_boots",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundBoots,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.boots] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },

    -- boundShield
    {
        id = "devil_shield",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundShield,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.shield] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },

    -- boundGloves
    {
        id = "devil_gloves",
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundGloves,
                rangeType = tes3.effectRange.self,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        validArmorSlots = {
            [tes3.armorSlot.leftGauntlet] = true,
            [tes3.armorSlot.rightGauntlet] = true,
        },
        validWeightClasses = {
            [tes3.armorWeightClass.heavy] = true,
        },
    },

    {
        id = "howling",
        prefix = "Howling",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        effects = {
            {
                id = tes3.effect.demoralizeCreature,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.demoralizeHumanoid,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
    {
        id = "wailing",
        prefix = "Wailing",
        value = 75,
        castType = tes3.enchantmentType.onStrike,
        effects = {
            {
                id = tes3.effect.demoralizeCreature,
                rangeType = tes3.effectRange.touch,
                min = 15,
                max = 15,
            },
            {
                id = tes3.effect.demoralizeHumanoid,
                rangeType = tes3.effectRange.touch,
                min = 15,
                max = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
        validWeaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = true,
            [tes3.weaponType.longBladeOneHand] = true,
            [tes3.weaponType.longBladeTwoClose] = true,
            [tes3.weaponType.bluntOneHand] = true,
            [tes3.weaponType.bluntTwoClose] = true,
            [tes3.weaponType.bluntTwoWide] = true,
            [tes3.weaponType.spearTwoWide] = true,
            [tes3.weaponType.axeOneHand] = true,
            [tes3.weaponType.axeTwoHand] = true,
        },
    },
}

return modifiers