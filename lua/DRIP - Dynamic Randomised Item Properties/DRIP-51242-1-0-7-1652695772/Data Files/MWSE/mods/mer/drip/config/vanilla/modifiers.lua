local modifiers = {

    --Weapon multipliers
    {
        prefix = "Quality",
        value = 50,
        description = "+5 Max Damage",
        modifications = {
            chopMax = 5,
            slashMax = 5,
            thrustMax = 5,
        },
        icon = "Icons/diabloot/multiplier.dds",
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    --Sharp weapons only
    {
        prefix = "Sharp",
        value = 100,
        description = "+10 Max Damage",
        modifications = {
            chopMax = 10,
            slashMax = 10,
            thrustMax = 10,
        },
        icon = "Icons/diabloot/multiplier.dds",
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
        --blunt weapons only
        prefix = "Cruel",
        value = 100,
        description = "+10 Max Damage",
        modifications = {
            chopMax = 10,
            slashMax = 10,
            thrustMax = 10,
        },
        icon = "Icons/diabloot/multiplier.dds",
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
        icon = "Icons/diabloot/multiplier.dds",
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
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
        icon = "Icons/diabloot/multiplier.dds",
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
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
        icon = "Icons/diabloot/multiplier.dds",
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
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
        icon = "Icons/diabloot/multiplier.dds",
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },


    --Weight multipliers\
    {
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
        icon = "Icons/diabloot/multiplier.dds",
    },

    {
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
        icon = "Icons/diabloot/multiplier.dds",
    },

    --Armor Multipliers
    {
        prefix = "Fortified",
        valueMulti = 1.5,
        description = "1.5x Armor Rating",
        multipliers = {
            armorRating = 1.5
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        icon = "Icons/diabloot/multiplier.dds",
    },
    {
        prefix = "Glorious",
        valueMulti = 2.0,
        description = "2x Armor Rating",
        multipliers = {
            armorRating = 2,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
        icon = "Icons/diabloot/multiplier.dds",
    },

    --Vanilla effects

    --drainAttribute
    {
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
                min = 3,
                max = 7,
                duration = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true,
        },
    },



    -- waterBreathing
    --weak
    {
        prefix = "Mudcrab's",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 50,
        effects = {
            {
                id = tes3.effect.waterBreathing,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Argonian's",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.waterBreathing,
                rangeType = tes3.effectRange.self,
                duration = 60,
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
        suffix = "the Fish",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.swiftSwim,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        suffix = "the Dreugh",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.swiftSwim,
                rangeType = tes3.effectRange.self,
                duration = 60,
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

    -- waterWalking
    --weak
    {
        suffix = "Buoyancy",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.waterWalking,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        suffix = "Ocean-Striding",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.waterWalking,
                rangeType = tes3.effectRange.self,
                duration = 60,
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

    -- shield
    --weak
    {
        prefix = "Protector's",
        value = 50,
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
    },
    --strong
    {
        prefix = "Guardian's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.shield,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- fireShield
    {
        suffix = "Flameguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fireShield,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- lightningShield
    {
        suffix = "Stormguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.lightningShield,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- frostShield
    {
        suffix = "Frostguard",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.frostShield,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- burden
    {
        suffix = "Heavystep",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.burden,
                rangeType = tes3.effectRange.touch,
                min = 20,
                max = 20,
                duration = 30,
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
        suffix = "Lightstep",
        value = 50,
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
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    --strong
    {
        prefix = "Ulm Juicedaw's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.feather,
                rangeType = tes3.effectRange.self,
                min = 25,
                max = 25,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- jump
    --weak
    {
        suffix = "the Frog",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.jump,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 15,
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
    --strong
    {
        suffix = "the Toad",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.jump,
                rangeType = tes3.effectRange.self,
                min = 25,
                max = 25,
                duration = 20,
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
        suffix = "Floating",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.levitate,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
                duration = 20,
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
        suffix = "Soaring",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.levitate,
                rangeType = tes3.effectRange.self,
                min = 25,
                max = 25,
                duration = 30,
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
        suffix = "Slowfall",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.slowFall,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
                duration = 20,
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
        prefix = "Burgler's",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.open,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 20,
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
        prefix = "Locksmith's",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.open,
                rangeType = tes3.effectRange.touch,
                min = 25,
                max = 50,
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
        prefix = "Firey",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 3,
                max = 7,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --strong
    {
        prefix = "Blazing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.fireDamage,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --Slow
    {
        suffix = "Flames",
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
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- shockDamage
    --weak
    {
        prefix = "Arching",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 3,
                max = 7,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --strong
    {
        prefix = "Shocking",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.shockDamage,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --Slow
    {
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
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- frostDamage
    --weak
    {
        prefix = "Chilling",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 3,
                max = 7,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --strong
    {
        prefix = "Freezing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.frostDamage,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --Slow
    {
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
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },


    -- poison
    --weak
    {
        prefix = "Viper's",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.poison,
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
    },
    --strong
    {
        prefix = "Foul",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.poison,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 10,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- disintegrateWeapon/disintegrateArmor

    --weak
    {
        prefix = "Corrosive",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
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
    },
    --strong
    {
        prefix = "Acidic",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.disintegrateWeapon,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 20,
            },
            {
                id = tes3.effect.disintegrateArmor,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- invisibility
    {
        suffix = "Hiding",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.invisibility,
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
    {
        suffix = "Shadows",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.invisibility,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        suffix = "Camoflauge",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.chameleon,
                rangeType = tes3.effectRange.self,
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

    {
        prefix = "Astral",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.chameleon,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- light
    {
        prefix = "Glowing",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.light,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- sanctuary
    --weak
    {
        prefix = "Elusive",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.sanctuary,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    --strong
    {
        prefix = "Watcher's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.sanctuary,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- nightEye
    {
        suffix = "the Cat",
        value = 30,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.nightEye,
                rangeType = tes3.effectRange.self,
                min = 15,
                max = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- charm
    {
        suffix = "Befriending",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.charm,
                rangeType = tes3.effectRange.touch,
                min = 20,
                max = 30,
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

    -- paralyze
    --weak
    {
        prefix = "Jink",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.paralyze,
                rangeType = tes3.effectRange.touch,
                duration = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    --strong
    {
        prefix = "Paralyzing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.paralyze,
                rangeType = tes3.effectRange.touch,
                duration = 15,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- silence
    --weak
    {
        suffix = "Tongue-Tying",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
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
    },
    --strong
    {
        suffix = "Silence",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.silence,
                rangeType = tes3.effectRange.touch,
                duration = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- blind
    {
        suffix = "Blinding",
        value = 25,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.blind,
                rangeType = tes3.effectRange.touch,
                duration = 5,
                min = 1,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    {
        suffix = "Eye-Gouging",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.blind,
                rangeType = tes3.effectRange.touch,
                duration = 10,
                min = 1,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- sound
    {
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
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },
    -- soultrap
    {
        suffix = "Soul-Stealing",
        value = 30,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.soultrap,
                rangeType = tes3.effectRange.touch,
                duration = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- telekinesis
    {
        suffix = "Far-Reaching",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.telekinesis,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- detectAnimal/detectEnchantment/detectKey
    {
        suffix = "the Seeker",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.detectAnimal,
                rangeType = tes3.effectRange.self,
                min = 40,
                max = 40,
            },
            {
                id = tes3.effect.detectEnchantment,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20,
            },
            {
                id = tes3.effect.detectKey,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },


    -- spellAbsorption
    {
        suffix = "Absorbing",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.spellAbsorption,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- reflect
    {
        suffix = "Mirrors",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.reflect,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- cureCommonDisease
    {
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
                duration = 10
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.speed,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 10
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.endurance,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 10
            },
            {
                id = tes3.effect.restoreAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1,
                duration = 10
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
        suffix = "Healing",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 5,
        maxCharge = 50,
        effects = {
            {
                id = tes3.effect.restoreHealth,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 20,
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
        suffix = "Recovery",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreHealth,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 10,
                duration = 20,
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
        suffix = "Meditation",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreMagicka,
                rangeType = tes3.effectRange.self,
                duration = 10,
                min = 1,
                max = 2,
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
        suffix = "Stamina",
        value = 25,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.restoreFatigue,
                rangeType = tes3.effectRange.self,
                duration = 10,
                min = 3,
                max = 7,
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
        suffix = "the Bear",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.strength,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        suffix = "the Owl",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.intelligence,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        suffix = "Faith",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.willpower,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        suffix = "the Nix-Hound",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        suffix = "the Hare",
        value = 50,
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
    },
    {
        prefix = "Ogrim's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.endurance,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        prefix = "Scamp's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Celestial",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.luck,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    --fortifyAttribute combos
    {
        prefix = "King's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.personality,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.endurance,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },


    -- fortifySkill

    {
        prefix = "Defender's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.block,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
        prefix = "Blacksmith's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.armorer,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Fitted",
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
        prefix = "Fitted",
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
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.bluntWeapon,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.longBlade,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.axe,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
        prefix = "Balanced",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.spear,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
        prefix = "Runner's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.athletics,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Enchanter's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.enchant,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Wizard's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.destruction,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Warlock's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alteration,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Mesmer's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.illusion,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Summoner's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.conjuration,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Mystic's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mysticism,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Angel's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.restoration,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Alchemist's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.alchemy,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Devious",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.sneak,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Gymnast's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.acrobatics,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Fitted",
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
        prefix = "Balanced",
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
        prefix = "Balanced",
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
        prefix = "Merchant's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.mercantile,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },
    {
        prefix = "Wordsmith's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            }
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    {
        prefix = "Pugilist's",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },
    {
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
            [tes3.objectType.clothing] = true,
        },
    },

    --Other multiskill
    {
        prefix = "Cunning",
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
    },
    {
        prefix = "Feral",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.unarmored,
                min = 3,
                max = 3,
            },
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.handToHand,
                min = 3,
                max = 3,
            },
        },
        validObjectTypes = {
            [tes3.objectType.clothing] = true,
        },
    },




    -- fortifyMaximumMagicka
    {
        prefix = "Drake's",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyMaximumMagicka,
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

    {
        prefix = "Dragon's",
        value = 100,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.fortifyMaximumMagicka,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },


    -- absorbAttribute


    -- absorbHealth
    {
        suffix = "the Vampire",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbHealth,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 1,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- absorbMagicka
    {
        prefix = "Magekiller's",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbMagicka,
                rangeType = tes3.effectRange.touch,
                min = 2,
                max = 5,
                duration = 1,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- absorbFatigue
    {
        prefix = "Taxing",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.absorbFatigue,
                rangeType = tes3.effectRange.touch,
                min = 5,
                max = 10,
                duration = 1,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    -- resistFire
    {
        prefix = "Burgundy",
        value = 25,
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
    },
    {
        prefix = "Crimson",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- resistFrost
    {
        prefix = "Cobalt",
        value = 25,
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
    },
    {
        prefix = "Azure",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- resistShock
    {
        prefix = "Coral",
        value = 25,
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
    },
    {
        prefix = "Amber",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    --Resist Elements

    {
        prefix = "Chromatic",
        value = 50,
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
    },
    {
        prefix = "Prismatic",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistFire,
                rangeType = tes3.effectRange.self,
                min = 7,
                max = 7,
            },
            {
                id = tes3.effect.resistFrost,
                rangeType = tes3.effectRange.self,
                min = 7,
                max = 7,
            },
            {
                id = tes3.effect.resistShock,
                rangeType = tes3.effectRange.self,
                min = 7,
                max = 7,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- resistMagicka
    {
        suffix = "Magickguard",
        value = 50,
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
    },
    {
        prefix = "Lord's",
        value = 100,
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
    },

    -- resistCommonDisease/resistBlightDisease/resistPoison
    {
        prefix = "Medic's",
        value = 75,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistCommonDisease,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.resistBlightDisease,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
            {
                id = tes3.effect.resistPoison,
                rangeType = tes3.effectRange.self,
                min = 5,
                max = 5,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        },
    },

    -- resistNormalWeapons
    {
        prefix = "Ghostly",
        value = 50,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistNormalWeapons,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },


    -- resistParalysis
    {
        suffix = "Freedom",
        value = 25,
        castType = tes3.enchantmentType.constant,
        effects = {
            {
                id = tes3.effect.resistParalysis,
                rangeType = tes3.effectRange.self,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },

    -- turnUndead
    {
        prefix = "Blessed",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.turnUndead,
                rangeType = tes3.effectRange.onTouch,
                duration = 5,
                min = 10,
                max = 10,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },

    {
        prefix = "Holy",
        value = 75,
        castType = tes3.enchantmentType.onStrike,
        chargeCost = 20,
        maxCharge = 200,
        effects = {
            {
                id = tes3.effect.turnUndead,
                rangeType = tes3.effectRange.onTouch,
                duration = 5,
                min = 20,
                max = 20,
            },
        },
        validObjectTypes = {
            [tes3.objectType.weapon] = true,
            [tes3.objectType.ammunition] = true
        },
    },



    -- summonScamp
    {
        suffix = "Summon Scamp",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 10,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.summonScamp,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Clannfear",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonClannfear,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Daedroth",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonDaedroth,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Dremora",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 500,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonDremora,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Ancestral Ghost",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonAncestralGhost,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Skeletal Minion",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonSkeletalMinion,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Bonewalker",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonBonewalker,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Greater Bonewalker",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonGreaterBonewalker,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Bonelord",
        value = 150,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonBonelord,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Winged Twilight",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 500,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonWingedTwilight,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Hunger",
        value = 200,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 250,
        maxCharge = 1000,
        effects = {
            {
                id = tes3.effect.summonHunger,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Golden Saint",
        value = 300,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 1000,
        maxCharge = 2000,
        effects = {
            {
                id = tes3.effect.summonGoldenSaint,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Flamecalling",
        value = 75,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 50,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonFlameAtronach,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Frostcalling",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonFrostAtronach,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Stormcalling",
        value = 125,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonStormAtronach,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Summon Centurion Sphere",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 100,
        maxCharge = 500,
        effects = {
            {
                id = tes3.effect.summonCenturionSphere,
                rangeType = tes3.effectRange.self,
                duration = 20,
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
        suffix = "Taming",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.commandCreature,
                rangeType = tes3.effectRange.onTouch,
                min = 1,
                max = 10,
                duration = 30,
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
        suffix = "Command",
        value = 100,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.commandHumanoid,
                rangeType = tes3.effectRange.onTouch,
                min = 1,
                max = 10,
                duration = 20,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundDagger,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundLongsword,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundMace,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundBattleAxe,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundSpear,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundLongbow,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundCuirass,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundHelm,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundBoots,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundShield,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Devil",
        value = 50,
        castType = tes3.enchantmentType.onUse,
        chargeCost = 20,
        maxCharge = 100,
        effects = {
            {
                id = tes3.effect.boundGloves,
                rangeType = tes3.effectRange.self,
                duration = 30,
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
        prefix = "Howling",
        value = 50,
        castType = tes3.enchantmentType.onStrike,
        effects = {
            {
                id = tes3.effect.demoralizeCreature,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 10,
            },
            {
                id = tes3.effect.demoralizeHumanoid,
                rangeType = tes3.effectRange.touch,
                min = 10,
                max = 10,
            },
        },
    }
}


return modifiers