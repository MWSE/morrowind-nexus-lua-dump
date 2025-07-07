local defaultConfig = {
    -- general
    modEnabled = true,
    showToggleMenuButton = true,
    enableKeybindToggle = true,
    toggleMenuKeybind = {
        keyCode = tes3.scanCode.tab,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    showShoesBootsSlotsForBeastRaces = false,
    showEmptySlotsOnly = false,
    allowGlovesWithBracers = false,

    -- weapon
    showWeaponTable = true,
    showAmmoSlot = true,
    showWeaponHeader = true,
    showWeaponIconColumn = true,
    showWeaponSlotNameColumn = true,
    showWeaponConditionColumn = true,
    showWeaponConditionPercent = false,
    showWeaponEnchantmentChargeColumn = true,
    showWeaponEnchantmentChargePercent = false,
    showWeaponItemNameColumn = true,

    enableColorsWeaponCondition = true,

    weaponConditionColorExcellent = { r = 100 / 255, g = 255 / 255, b = 150 / 255, a = 1.0 },
    weaponConditionColorGood      = { r = 255 / 255, g = 255 / 255, b = 130 / 255, a = 1.0 },
    weaponConditionColorPoor      = { r = 255 / 255, g = 180 / 255, b =  80 / 255, a = 1.0 },
    weaponConditionColorBad       = { r = 255 / 255, g = 120 / 255, b = 120 / 255, a = 1.0 },

    enableColorsWeaponEnchantmentCharge = true,

    weaponEnchantmentChargeColorExcellent = { r = 100 / 255, g = 200 / 255, b = 255 / 255, a = 1.0 },
    weaponEnchantmentChargeColorGood      = { r = 130 / 255, g = 170 / 255, b = 255 / 255, a = 1.0 },
    weaponEnchantmentChargeColorPoor      = { r = 170 / 255, g = 130 / 255, b = 255 / 255, a = 1.0 },
    weaponEnchantmentChargeColorBad       = { r = 200 / 255, g = 100 / 255, b = 255 / 255, a = 1.0 },
    
    -- armor
    showArmorTable = true,
    showArmorHeader = true,
    showArmorIconColumn = true,
    showArmorSlotNameColumn = true,
    showArmorConditionColumn = true,
    showArmorConditionPercent = false,
    showArmorEnchantmentChargeColumn = true,
    showArmorEnchantmentChargePercent = false,
    showArmorItemNameColumn = true,

    enableColorsArmorCondition = true,

    armorConditionColorExcellent = { r = 100 / 255, g = 255 / 255, b = 150 / 255, a = 1.0 },
    armorConditionColorGood      = { r = 255 / 255, g = 255 / 255, b = 130 / 255, a = 1.0 },
    armorConditionColorPoor      = { r = 255 / 255, g = 180 / 255, b =  80 / 255, a = 1.0 },
    armorConditionColorBad       = { r = 255 / 255, g = 120 / 255, b = 120 / 255, a = 1.0 },

    enableColorsArmorEnchantmentCharge = true,

    armorEnchantmentChargeColorExcellent = { r = 100 / 255, g = 200 / 255, b = 255 / 255, a = 1.0 },
    armorEnchantmentChargeColorGood      = { r = 130 / 255, g = 170 / 255, b = 255 / 255, a = 1.0 },
    armorEnchantmentChargeColorPoor      = { r = 170 / 255, g = 130 / 255, b = 255 / 255, a = 1.0 },
    armorEnchantmentChargeColorBad       = { r = 200 / 255, g = 100 / 255, b = 255 / 255, a = 1.0 },
    
    excludedArmorSlots = {
        ["Left Bracer"] = true,
        ["Right Bracer"] = true,
    },

    -- clothing
    showClothingTable = true,
    showClothingHeader = true,
    showClothingIconColumn = true,
    showClothingSlotNameColumn = true,
    showClothingConditionColumn = true,
    showClothingConditionPercent = false,
    showClothingEnchantmentChargeColumn = true,
    showClothingEnchantmentChargePercent = false,
    showClothingItemNameColumn = true,

    enableColorsClothingCondition = true,

    clothingConditionColorExcellent = { r = 100 / 255, g = 255 / 255, b = 150 / 255, a = 1.0 },
    clothingConditionColorGood      = { r = 255 / 255, g = 255 / 255, b = 130 / 255, a = 1.0 },
    clothingConditionColorPoor      = { r = 255 / 255, g = 180 / 255, b =  80 / 255, a = 1.0 },
    clothingConditionColorBad       = { r = 255 / 255, g = 120 / 255, b = 120 / 255, a = 1.0 },

    enableColorsClothingEnchantmentCharge = true,

    clothingEnchantmentChargeColorExcellent = { r = 100 / 255, g = 200 / 255, b = 255 / 255, a = 1.0 },
    clothingEnchantmentChargeColorGood      = { r = 130 / 255, g = 170 / 255, b = 255 / 255, a = 1.0 },
    clothingEnchantmentChargeColorPoor      = { r = 170 / 255, g = 130 / 255, b = 255 / 255, a = 1.0 },
    clothingEnchantmentChargeColorBad       = { r = 200 / 255, g = 100 / 255, b = 255 / 255, a = 1.0 },

    excludedClothingSlots = {
        ["Shoes"] = true,
        ["Left Glove"] = true,
        ["Right Glove"] = true,
    },
}

return defaultConfig