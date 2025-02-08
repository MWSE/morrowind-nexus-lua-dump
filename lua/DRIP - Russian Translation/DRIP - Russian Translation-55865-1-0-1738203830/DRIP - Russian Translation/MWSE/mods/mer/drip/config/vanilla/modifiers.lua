---@type Drip.Modifier.Data[]
local modifiers = {
    --Attack Speed
    {
        id = "readiness",
        suffix = " [Ск.I]",
        valueMulti = 1.25,
        description = "Скорость I: небольшое увеличение частоты атаки",
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
        suffix = " [Ск.II]",
        valueMulti = 1.5,
        description = "Скорость II: частота атаки увеличена на четверть",
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
        prefix = " [З.I]",
        value = 100,
        description = "Заточка I: небольшое увеличение максимального урона",
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
        prefix = " [З.II]",
        value = 100,
        description = "Заточка II: увеличенный максимальный урон",
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
        prefix = " [Р.I]",
        value = 100,
        description = "Разрушительность I: небольшое увеличение максимального урона",
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
        prefix = " [Р.II]",
        value = 100,
        description = "Разрушительность II: увеличенный максимальный урон",
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
        prefix = " [См.I]",
        valueMulti = 1.25,
        description = "Смертоностность I: урон увеличен на четверть",
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
        prefix = " [См.II]",
        valueMulti = 1.5,
        description = "Смертоностность II: урон увеличен на половину",
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
        prefix = " [См.III]",
        valueMulti = 1.75,
        description = "Смертоностность III: урон увеличен на три четверти",
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
        prefix = " [См.IV]",
        valueMulti = 2.0,
        description = "Смертоностность IV: урон увеличен вдвое",
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
        prefix = " [Л.I]",
        valueMulti = 1.25,
        castType = tes3.enchantmentType.constant,
        description = "Легкость I: вес предмета уменьшен на чертверть",
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
        prefix = " [Л.II]",
        valueMulti = 1.5,
        castType = tes3.enchantmentType.constant,
        description = "Легкость II: вес предмета уменьшен вдвое",
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
        prefix = " [З.I]",
        valueMulti = 1.25,
        description = "Защита I: показатель брони увеличен на чертверть",
        multipliers = {
            armorRating = 1.25
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },
	    {
        id = "fortified2",
        prefix = " [З.II]",
        valueMulti = 1.5,
        description = "Защита II: показатель брони увеличен на половину",
        multipliers = {
            armorRating = 1.5
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },
    {
        id = "glorious",
        prefix = " [З.III]",
        valueMulti = 1.75,
        description = "Защита III: показатель брони увеличен на три четверти",
        multipliers = {
            armorRating = 1.75,
        },
        validObjectTypes = {
            [tes3.objectType.armor] = true,
        },
    },
    {
        id = "glorious2",
        prefix = " [З.IV]",
        valueMulti = 2.0,
        description = "Защита IV: показатель брони увеличен вдвое",
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
        suffix = " [Н.I]",
        valueMulti = 1.25,
        description = "Неразрушимость I: прочность предмета увеличена на половину",
        multipliers = {
            maxCondition = 1.5,
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
	{
        id = "superior2",
        suffix = " [Н.II]",
        valueMulti = 1.25,
        description = "Неразрушимость II: прочность предмета увеличена вдвое",
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
        suffix = ", м.: помрачение",
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
        prefix = " проклинающего",
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
        prefix = " замедления",
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
        prefix = " ослабления",
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
        prefix = " живодера",
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
        prefix = " опустошителя",
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
        prefix = " истощения",
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
        prefix = " кровопускателя",
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
        prefix = " кровопийцы",
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
        suffix = ", м.: грязекраб",
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
        suffix = ", м.: аргонианин",
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
        prefix = " пловца",
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
        prefix = " дреуга",
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
        prefix = " плавучести",
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
        prefix = " морехода",
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
        suffix = ", м.: барьер",
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
        suffix = ", м.: барьер",
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
        suffix = ", м.: огн. страж",
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
        suffix = ", м.: гроз. страж",
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
        suffix = ", м.: лед. страж",
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
        prefix = " обременителя",
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
        suffix = ", м.: ноша",
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
        suffix = ", м.: ноша",
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
        prefix = " лягушки",
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
			[tes3.clothingSlot.shoes] = true,
        }
    },
    --strong
    {
        id = "toad",
        prefix = " жабы",
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
			[tes3.clothingSlot.shoes] = true,
        }
    },

    -- levitate
    --weak
    {
        id = "floating",
        prefix = " окрыленного",
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
        prefix = " полета",
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
        prefix = " невесомости",
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
        prefix = " ключника",
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
        suffix = ", м.: взлом",
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
        suffix = ", м.: отмычка",
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
        suffix = ", м.: ожог",
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
        suffix = ", м.: пламя",
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
        prefix = " поджигателя",
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
        suffix = ", м.: разряд",
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
        suffix = ", м.: молния",
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
        prefix = " громовержца",
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
        suffix = ", м.: изморозь",
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
        suffix = ", м.: холод",
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
        prefix = " криоманта",
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
        prefix = " разрушителя",
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
        suffix = ", м.: отрава",
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
        suffix = ", м.: яд",
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
        prefix = " изтязателя",
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
        suffix = ", м.: коррозия",
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
        suffix = ", м.: кислота",
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
        prefix = " невидимки",
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
        prefix = " теней",
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
        prefix = " хамелеона",
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
        suffix = ", м.: маскировка",
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
        suffix = ", м.: факел",
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
        suffix = ", м.: свет",
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
        suffix = ", м.: оберег",
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
        suffix = ", м.: охранитель",
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
        prefix = " хаджита",
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
        prefix = " соблазнителя",
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
        prefix = " скриба",
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
        prefix = " парализации",
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
        prefix = " библиотекаря",
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
        prefix = " языкодера",
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
        prefix = " ослепителя",
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
        prefix = " глазодава",
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
        prefix = " крикуна",
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
        prefix = " душелова",
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
        prefix = " длинных пальцев",
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
        prefix = " искателя",
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
        prefix = " поглотителя",
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
        prefix = " отражателя",
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
        prefix = " аптекаря",
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
        prefix = " святой Рилмс",
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
        prefix = " Балины",
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
        prefix = " свободы действия",
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
        prefix = " возрождения",
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
        prefix = " здоровья",
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
        prefix = " сприггана",
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
        prefix = " подмастерья",
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
        prefix = " неутомимости",
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
        prefix = " силача",
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
        prefix = " умника",
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
        prefix = " фанатика",
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
        prefix = " ловкача",
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
        prefix = " бегуна",
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
        prefix = " торопыги",
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
        prefix = " здоровяка",
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
        prefix = " льстеца",
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
        suffix = ", м.: удача",
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
        suffix = ", м.: выправка",
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
        suffix = ", м.: реакция",
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
        prefix = " кузнеца",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: эксперт",
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
        suffix = ", м.: мастер",
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
        suffix = ", м.: эксперт",
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
        suffix = ", м.: мастер",
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
        suffix = ", м.: эксперт",
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
        suffix = ", м.: мастер",
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
        suffix = ", м.: эксперт",
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
        suffix = ", м.: мастер",
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
        prefix = " атлета",
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
        suffix = ", м.: чары",
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
        suffix = ", м.: разрушение",
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
        suffix = ", м.: изменение",
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
        suffix = ", м.: иллюзия",
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
        suffix = ", м.: колдовство",
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
        suffix = ", м.: мистицизм",
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
        suffix = ", м.: восстановление",
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
        suffix = ", м.: алхимия",
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
        suffix = ", м.: плутовство",
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
        suffix = ", м.: гимнастика",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: броня",
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
        suffix = ", м.: эксперт",
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
        suffix = ", м.: мастер",
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
        suffix = ", м.: стрелок",
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
        suffix = ", м.: снайпер",
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
        suffix = ", м.: купец",
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
        suffix = ", м.: харизма",
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
        suffix = ", м.: борец",
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
        prefix = " акробата",
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
        prefix = " шпиона",
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
        prefix = " лучника",
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
        prefix = " ассасина",
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
        prefix = " варвара",
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
        prefix = " барда",
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
        prefix = " жреца",
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
        prefix = " паладина",
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
        prefix = " целителя",
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
        prefix = " рыцаря",
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
        prefix = " заклинателя",
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
        prefix = " монаха",
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
        prefix = " ночного клинка",
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
        prefix = " пилигрима",
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
        prefix = " жулика",
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
        prefix = " разведчика",
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
        prefix = " чародея",
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
        prefix = " воина слова",
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
        prefix = " вора",
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
        prefix = " воителя",
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
        prefix = " инквизитора",
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
        prefix = " арканиста",
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
        prefix = " похотливой девы",
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
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.shoes] = true,
            [tes3.clothingSlot.shirt] = true,
            [tes3.clothingSlot.belt] = true,
            [tes3.clothingSlot.robe] = true,
            [tes3.clothingSlot.rightGlove] = true,
            [tes3.clothingSlot.leftGlove] = true,
        }
    },
    {
        id = "courtesan2",
        prefix = " похотливой девы",
        value = 75,
        castType = tes3.enchantmentType.constant,
		description = "Моя пышечка. Такие сильные ноги и красивый хвост!",
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
            [tes3.objectType.clothing] = true,
        },
        validClothingSlots = {
            [tes3.clothingSlot.pants] = true,
            [tes3.clothingSlot.skirt] = true,
        }
    },
    {
        id = "diplomat",
        prefix = " словоблуда",
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
        prefix = " трех школ",
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
        prefix = " дуэлянта",
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
        prefix = " шулера",
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
        prefix = " драчуна",
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
        prefix = " шута",
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
        prefix = " ловкача",
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
        prefix = " поэта",
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
        suffix = ", м.: хитрость",
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
        suffix = ", м.: проворство",
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
        suffix = ", м.: магия",
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
        suffix = ", м.: магия",
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
        prefix = " пиявки",
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
        prefix = " вампира",
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
        suffix = ", м.: убийца магов",
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
        suffix = ", м.: натиск",
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
        suffix = ", м.: огнеустойчивость",
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
        suffix = ", м.: огнеустойчивость",
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
        suffix = ", м.: холодоустойчивость",
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
        suffix = ", м.: холодоустойчивость",
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
        suffix = ", м.: заземление",
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
        suffix = ", м.: заземление",
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
        suffix = ", м.: устойчивость",
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
        suffix = ", м.: устойчивость",
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
        prefix = " бретона",
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
        suffix = ", м.: антимагия",
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
        suffix = ", м.: иммунность",
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
        suffix = ", м.: чуждость",
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
        prefix = " освободителя",
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
        suffix = ", м.: святость",
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
        suffix = ", м.: святость",
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
        prefix = " скампа",
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
        prefix = " ужаса клана",
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
        prefix = " даэдрота",
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
        prefix = " дреморы",
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
        prefix = " духа предков",
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
        prefix = " скелета",
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
        prefix = " трупа",
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
        prefix = " крупного трупа",
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
        prefix = " кост. лорда",
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
        prefix = " кр. сумрака",
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
        prefix = " алчущего",
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
        prefix = " зол. святоши",
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
        prefix = " огн. атронаха",
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
        prefix = " ин. атронаха",
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
        prefix = " гроз. атронаха",
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
        prefix = " двемеролога",
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
        prefix = " укротителя",
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
        prefix = " коммандира",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        prefix = " демона",
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
        suffix = ", м.: угроза",
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
        suffix = ", м.: устрашение",
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