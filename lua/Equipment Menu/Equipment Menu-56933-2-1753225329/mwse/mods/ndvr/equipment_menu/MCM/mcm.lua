local config = require("ndvr.equipment_menu.config.config")
local defaultConfig = require("ndvr.equipment_menu.config.defaultConfig")

local utils = require("ndvr.equipment_menu.utils")
local i18n = mwse.loadTranslations("ndvr.equipment_menu")

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ 
		name = i18n("modName"),
		config = config,
		defaultConfig = defaultConfig,
    	showDefaultSetting = true,
		onClose =(
			function()
				mwse.saveConfig("ndvr.equipment_menu", config)
				if equipWindow then
					refreshMenu()
				end
			end
		)
	})

	template:register()

	-- general settings

    local page = template:createSideBarPage({
        label = i18n("mcm_General_PageName"),
        description = i18n("mcm_General_PageDescription")
    })

	page:createYesNoButton({
        label = i18n("mcm_General_modEnabled"),
        description = i18n("mcm_General_modEnabled_Description"),
        configKey = "modEnabled"
    })

    page:createYesNoButton({
        label = i18n("mcm_General_showToggleMenuButton"),
        description = i18n("mcm_General_showToggleMenuButton_Description"),
        configKey = "showToggleMenuButton"
    })

    page:createYesNoButton({
        label = i18n("mcm_General_enableKeybindToggle"),
        description = i18n("mcm_General_enableKeybindToggle_Description"),
        configKey = "enableKeybindToggle"
    })

    page:createKeyBinder{
		label = i18n("mcm_General_toggleMenuKeybind"),
		allowCombinations = false,
		variable = mwse.mcm.createTableVariable { id = "toggleMenuKeybind", table = config },
	}

	page:createYesNoButton({
        label = i18n("mcm_General_showShoesBootsSlotsForBeastRaces"),
        description = i18n("mcm_General_showShoesBootsSlotsForBeastRaces_Description"),
        configKey = "showShoesBootsSlotsForBeastRaces"
    })

	page:createYesNoButton({
        label = i18n("mcm_General_showEmptySlotsOnly"),
        description = i18n("mcm_General_showEmptySlotsOnly_Description"),
        configKey = "showEmptySlotsOnly"
    })

    -- deprecated: automatically enables if MCP patch detected (thanks, C3pa!)
    -- page:createYesNoButton({
    --     label = "Allow gloves with bracers (MCP)",
    --     description = "When set to 'Yes,' items equipped in the Gloves slot will no longer duplicate in the Bracers slot, allowing the Bracers to display correctly.\n\nBy default, you can only equip either Gauntlets, Bracers, or Gloves. However, when using MCP's 'Allow gloves with bracers' option, you can equip both Bracers and Gloves at the same time, or just Gauntlets.\n\nNOTE! This option only adjusts how slots are displayed in Equipment Menu. In order to allow equipping both bracers and gloves simultaneously you have to install this patch in MCP!",
    --     configKey = "allowGlovesWithBracers"
    -- })

    -- weapon page

	local pageWeapon = template:createSideBarPage({
        label = i18n("mcm_Weapon_PageName"),
        description = i18n("mcm_Weapon_PageDescription"),
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponTable"),
        description = i18n("mcm_Weapon_showWeaponTable_Description"),
        configKey = "showWeaponTable"
    })

    pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showAmmoSlot"),
        description = i18n("mcm_Weapon_showAmmoSlot_Description"),
        configKey = "showAmmoSlot"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponHeader"),
        description = i18n("mcm_Weapon_showWeaponHeader_Description"),
        configKey = "showWeaponHeader"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponIconColumn"),
        description = i18n("mcm_Weapon_showWeaponIconColumn_Description"),
        configKey = "showWeaponIconColumn"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponSlotNameColumn"),
        description = i18n("mcm_Weapon_showWeaponSlotNameColumn_Description"),
        configKey = "showWeaponSlotNameColumn"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponConditionColumn"),
        description = i18n("mcm_Weapon_showWeaponConditionColumn_Description"),
        configKey = "showWeaponConditionColumn"
    })

    pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponConditionPercent"),
        description = i18n("mcm_Weapon_showWeaponConditionPercent_Description"),
        configKey = "showWeaponConditionPercent"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponEnchantmentChargeColumn"),
        description = i18n("mcm_Weapon_showWeaponEnchantmentChargeColumn_Description"),
        configKey = "showWeaponEnchantmentChargeColumn"
    })

    pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponEnchantmentChargePercent"),
        description = i18n("mcm_Weapon_showWeaponEnchantmentChargePercent_Description"),
        configKey = "showWeaponEnchantmentChargePercent"
    })

	pageWeapon:createYesNoButton({
        label = i18n("mcm_Weapon_showWeaponItemNameColumn"),
        description = i18n("mcm_Weapon_showWeaponItemNameColumn_Description"),
        configKey = "showWeaponItemNameColumn"
    })

	-- weapon condition colors page

	local pageWeaponConditionColorPickers = template:createSideBarPage({
        label = i18n("mcm_WeaponConditionColors_PageName"),
        description = i18n("mcm_WeaponConditionColors_PageDescription"),
    })

    pageWeaponConditionColorPickers:createYesNoButton({
        label = i18n("mcm_WeaponConditionColors_enableColorsWeaponCondition"),
        description = i18n("mcm_WeaponConditionColors_enableColorsWeaponCondition_Description"),
        configKey = "enableColorsWeaponCondition"
    })

    local weaponConditionColorResetButton = pageWeaponConditionColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description")
    }

	local weaponConditionColorExcellentPicker = pageWeaponConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponConditionColors_weaponConditionColorExcellent"),
        description = i18n("mcm_WeaponConditionColors_weaponConditionColorExcellent_Description"),
        configKey = "weaponConditionColorExcellent",
        defaultSetting = defaultConfig.weaponConditionColorExcellent
    })

	local weaponConditionColorGoodPicker = pageWeaponConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponConditionColors_weaponConditionColorGood"),
        description = i18n("mcm_WeaponConditionColors_weaponConditionColorGood_Description"),
        configKey = "weaponConditionColorGood",
        defaultSetting = defaultConfig.weaponConditionColorGood
    })

	local weaponConditionColorPoorPicker = pageWeaponConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponConditionColors_weaponConditionColorPoor"),
        description = i18n("mcm_WeaponConditionColors_weaponConditionColorPoor_Description"),
        configKey = "weaponConditionColorPoor",
        defaultSetting = defaultConfig.weaponConditionColorPoor
    })

	local weaponConditionColorBadPicker = pageWeaponConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponConditionColors_weaponConditionColorBad"),
        description = i18n("mcm_WeaponConditionColors_weaponConditionColorBad_Description"),
        configKey = "weaponConditionColorBad",
        defaultSetting = defaultConfig.weaponConditionColorBad
    })

    weaponConditionColorResetButton.callback = function()
        weaponConditionColorExcellentPicker:resetToDefault()
        weaponConditionColorGoodPicker:resetToDefault()
        weaponConditionColorPoorPicker:resetToDefault()
        weaponConditionColorBadPicker:resetToDefault()
    end

	-- weapon enchantment charge colors page

	local pageWeaponEnchantmentChargeColorPickers = template:createSideBarPage({
        label = i18n("mcm_WeaponEnchantmentChargeColors_PageName"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_PageDescription"),
    })

    pageWeaponEnchantmentChargeColorPickers:createYesNoButton({
        label = i18n("mcm_WeaponEnchantmentChargeColors_enableColorsWeaponEnchantmentCharge"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_enableColorsWeaponEnchantmentCharge_Description"),
        configKey = "enableColorsWeaponEnchantmentCharge"
    })

    local weaponEnchantmentChargeColorResetButton = pageWeaponEnchantmentChargeColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description"),
    }

	local weaponEnchantmentChargeColorExcellentPicker = pageWeaponEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorExcellent"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorExcellent_Description"),
        configKey = "weaponEnchantmentChargeColorExcellent",
        defaultSetting = defaultConfig.weaponEnchantmentChargeColorExcellent
    })

	local weaponEnchantmentChargeColorGoodPicker = pageWeaponEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorGood"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorGood_Description"),
        configKey = "weaponEnchantmentChargeColorGood",
        defaultSetting = defaultConfig.weaponEnchantmentChargeColorGood
    })

	local weaponEnchantmentChargeColorPoorPicker = pageWeaponEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorPoor"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorPoor_Description"),
        configKey = "weaponEnchantmentChargeColorPoor",
        defaultSetting = defaultConfig.weaponEnchantmentChargeColorPoor
    })

	local weaponEnchantmentChargeColorBadPicker = pageWeaponEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorBad"),
        description = i18n("mcm_WeaponEnchantmentChargeColors_weaponEnchantmentChargeColorBad_Description"),
        configKey = "weaponEnchantmentChargeColorBad",
        defaultSetting = defaultConfig.weaponEnchantmentChargeColorBad
    })

    weaponEnchantmentChargeColorResetButton.callback = function()
        weaponEnchantmentChargeColorExcellentPicker:resetToDefault()
        weaponEnchantmentChargeColorGoodPicker:resetToDefault()
        weaponEnchantmentChargeColorPoorPicker:resetToDefault()
        weaponEnchantmentChargeColorBadPicker:resetToDefault()
    end

	-- armor page

	local pageArmor = template:createSideBarPage({
        label = i18n("mcm_Armor_PageName"),
        description = i18n("mcm_Armor_PageDescription"),
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorTable"),
        description = i18n("mcm_Armor_showArmorTable_Description"),
        configKey = "showArmorTable"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorHeader"),
        description = i18n("mcm_Armor_showArmorHeader_Description"),
        configKey = "showArmorHeader"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorIconColumn"),
        description = i18n("mcm_Armor_showArmorIconColumn_Description"),
        configKey = "showArmorIconColumn"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorSlotNameColumn"),
        description = i18n("mcm_Armor_showArmorSlotNameColumn_Description"),
        configKey = "showArmorSlotNameColumn"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorConditionColumn"),
        description = i18n("mcm_Armor_showArmorConditionColumn_Description"),
        configKey = "showArmorConditionColumn"
    })

    pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorConditionPercent"),
        description = i18n("mcm_Armor_showArmorConditionPercent_Description"),
        configKey = "showArmorConditionPercent"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorEnchantmentChargeColumn"),
        description = i18n("mcm_Armor_showArmorEnchantmentChargeColumn_Description"),
        configKey = "showArmorEnchantmentChargeColumn"
    })

    pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorEnchantmentChargePercent"),
        description = i18n("mcm_Armor_showArmorEnchantmentChargePercent_Description"),
        configKey = "showArmorEnchantmentChargePercent"
    })

	pageArmor:createYesNoButton({
        label = i18n("mcm_Armor_showArmorItemNameColumn"),
        description = i18n("mcm_Armor_showArmorItemNameColumn_Description"),
        configKey = "showArmorItemNameColumn"
    })

	-- armor condition colors page

	local pageArmorConditionColorPickers = template:createSideBarPage({
        label = i18n("mcm_ArmorConditionColors_PageName"),
        description = i18n("mcm_ArmorConditionColors_PageDescription"),
    })

    pageArmorConditionColorPickers:createYesNoButton({
        label = i18n("mcm_ArmorConditionColors_enableColorsArmorCondition"),
        description = i18n("mcm_ArmorConditionColors_enableColorsArmorCondition_Description"),
        configKey = "enableColorsArmorCondition"
    })

    local armorConditionColorResetButton = pageArmorConditionColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description"),
    }

	local armorConditionColorExcellentPicker = pageArmorConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorConditionColors_armorConditionColorExcellent"),
        description = i18n("mcm_ArmorConditionColors_armorConditionColorExcellent_Description"),
        configKey = "armorConditionColorExcellent",
        defaultSetting = defaultConfig.armorConditionColorExcellent
    })

	local armorConditionColorGoodPicker = pageArmorConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorConditionColors_armorConditionColorGood"),
        description = i18n("mcm_ArmorConditionColors_armorConditionColorGood_Description"),
        configKey = "armorConditionColorGood",
        defaultSetting = defaultConfig.armorConditionColorGood
    })

	local armorConditionColorPoorPicker = pageArmorConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorConditionColors_armorConditionColorPoor"),
        description = i18n("mcm_ArmorConditionColors_armorConditionColorPoor_Description"),
        configKey = "armorConditionColorPoor",
        defaultSetting = defaultConfig.armorConditionColorPoor
    })

	local armorConditionColorBadPicker = pageArmorConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorConditionColors_armorConditionColorBad"),
        description = i18n("mcm_ArmorConditionColors_armorConditionColorBad_Description"),
        configKey = "armorConditionColorBad",
        defaultSetting = defaultConfig.armorConditionColorBad
    })

    armorConditionColorResetButton.callback = function()
        armorConditionColorExcellentPicker:resetToDefault()
        armorConditionColorGoodPicker:resetToDefault()
        armorConditionColorPoorPicker:resetToDefault()
        armorConditionColorBadPicker:resetToDefault()
    end

	-- armor enchantment charge colors page

	local pageArmorEnchantmentChargeColorPickers = template:createSideBarPage({
        label = i18n("mcm_ArmorEnchantmentChargeColors_PageName"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_PageDescription"),
    })

    pageArmorEnchantmentChargeColorPickers:createYesNoButton({
        label = i18n("mcm_ArmorEnchantmentChargeColors_enableColorsArmorEnchantmentCharge"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_enableColorsArmorEnchantmentCharge_Description"),
        configKey = "enableColorsArmorEnchantmentCharge"
    })

    local armorEnchantmentChargeColorResetButton = pageArmorEnchantmentChargeColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description"),
    }

	local armorEnchantmentChargeColorExcellentPicker = pageArmorEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorExcellent"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorExcellent_Description"),
        configKey = "armorEnchantmentChargeColorExcellent",
        defaultSetting = defaultConfig.armorEnchantmentChargeColorExcellent
    })

	local armorEnchantmentChargeColorGoodPicker = pageArmorEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorGood"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorGood_Description"),
        configKey = "armorEnchantmentChargeColorGood",
        defaultSetting = defaultConfig.armorEnchantmentChargeColorGood
    })

	local armorEnchantmentChargeColorPoorPicker = pageArmorEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorPoor"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorPoor_Description"),
        configKey = "armorEnchantmentChargeColorPoor",
        defaultSetting = defaultConfig.armorEnchantmentChargeColorPoor
    })

	local armorEnchantmentChargeColorBadPicker = pageArmorEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorBad"),
        description = i18n("mcm_ArmorEnchantmentChargeColors_armorEnchantmentChargeColorBad_Description"),
        configKey = "armorEnchantmentChargeColorBad",
        defaultSetting = defaultConfig.armorEnchantmentChargeColorBad
    })

    armorEnchantmentChargeColorResetButton.callback = function()
        armorEnchantmentChargeColorExcellentPicker:resetToDefault()
        armorEnchantmentChargeColorGoodPicker:resetToDefault()
        armorEnchantmentChargeColorPoorPicker:resetToDefault()
        armorEnchantmentChargeColorBadPicker:resetToDefault()
    end

    -- exclusions, armor

	template:createExclusionsPage({
		label = i18n("mcm_ArmorExcludedSlots_PageName"),
		description = i18n("mcm_ArmorExcludedSlots_PageDescription"),
		leftListLabel = i18n("mcm_ArmorExcludedSlots_leftListLabel"),
		rightListLabel = i18n("mcm_ArmorExcludedSlots_rightListLabel"),
		variable = mwse.mcm.createTableVariable{
			id = "excludedArmorSlots",
			table = config,
		},
		filters = {
			{
				label = i18n("mcm_ArmorExcludedSlots_armor"),
				callback = function()
					local armorSlots = utils.getArmorSlots()

					-- names only, saving order
					local armorSlotNames = {}
					for _, slot in ipairs(armorSlots) do
						table.insert(armorSlotNames, slot.name)
					end

					return armorSlotNames
				end
			},
		},
	})

	-- clothing page

	local pageClothing = template:createSideBarPage({
        label = i18n("mcm_Clothing_PageName"),
        description = i18n("mcm_Clothing_PageDescription"),
    })

	pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingTable"),
        description = i18n("mcm_Clothing_showClothingTable_Description"),
        configKey = "showClothingTable"
    })

    pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingHeader"),
        description = i18n("mcm_Clothing_showClothingHeader_Description"),
        configKey = "showClothingHeader"
    })

	pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingIconColumn"),
        description = i18n("mcm_Clothing_showClothingIconColumn_Description"),
        configKey = "showClothingIconColumn"
    })

	pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingSlotNameColumn"),
        description = i18n("mcm_Clothing_showClothingSlotNameColumn_Description"),
        configKey = "showClothingSlotNameColumn"
    })

    pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingConditionColumn"),
        description = i18n("mcm_Clothing_showClothingConditionColumn_Description"),
        configKey = "showClothingConditionColumn"
    })

    pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingConditionPercent"),
        description = i18n("mcm_Clothing_showClothingConditionPercent_Description"),
        configKey = "showClothingConditionPercent"
    })

	pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingEnchantmentChargeColumn"),
        description = i18n("mcm_Clothing_showClothingEnchantmentChargeColumn_Description"),
        configKey = "showClothingEnchantmentChargeColumn"
    })

    pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingEnchantmentChargePercent"),
        description = i18n("mcm_Clothing_showClothingEnchantmentChargePercent_Description"),
        configKey = "showClothingEnchantmentChargePercent"
    })

	pageClothing:createYesNoButton({
        label = i18n("mcm_Clothing_showClothingItemNameColumn"),
        description = i18n("mcm_Clothing_showClothingItemNameColumn_Description"),
        configKey = "showClothingItemNameColumn"
    })

    -- clothing condition colors page

	local pageClothingConditionColorPickers = template:createSideBarPage({
        label = i18n("mcm_ClothingConditionColors_PageName"),
        description = i18n("mcm_ClothingConditionColors_PageDescription"),
    })

    pageClothingConditionColorPickers:createYesNoButton({
        label = i18n("mcm_ClothingConditionColors_enableColorsClothingCondition"),
        description = i18n("mcm_ClothingConditionColors_enableColorsClothingCondition_Description"),
        configKey = "enableColorsClothingCondition"
    })

    local clothingConditionColorResetButton = pageClothingConditionColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description"),
    }

	local clothingConditionColorExcellentPicker = pageClothingConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingConditionColors_clothingConditionColorExcellent"),
        description = i18n("mcm_ClothingConditionColors_clothingConditionColorExcellent_Description"),
        configKey = "clothingConditionColorExcellent",
        defaultSetting = defaultConfig.clothingConditionColorExcellent
    })

	local clothingConditionColorGoodPicker = pageClothingConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingConditionColors_clothingConditionColorGood"),
        description = i18n("mcm_ClothingConditionColors_clothingConditionColorGood_Description"),
        configKey = "clothingConditionColorGood",
        defaultSetting = defaultConfig.clothingConditionColorGood
    })

	local clothingConditionColorPoorPicker = pageClothingConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingConditionColors_clothingConditionColorPoor"),
        description = i18n("mcm_ClothingConditionColors_clothingConditionColorPoor_Description"),
        configKey = "clothingConditionColorPoor",
        defaultSetting = defaultConfig.clothingConditionColorPoor
    })

	local clothingConditionColorBadPicker = pageClothingConditionColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingConditionColors_clothingConditionColorBad"),
        description = i18n("mcm_ClothingConditionColors_clothingConditionColorBad_Description"),
        configKey = "clothingConditionColorBad",
        defaultSetting = defaultConfig.clothingConditionColorBad
    })

    clothingConditionColorResetButton.callback = function()
        clothingConditionColorExcellentPicker:resetToDefault()
        clothingConditionColorGoodPicker:resetToDefault()
        clothingConditionColorPoorPicker:resetToDefault()
        clothingConditionColorBadPicker:resetToDefault()
    end

    -- clothing enchantment charge colors page

	local pageClothingEnchantmentChargeColorPickers = template:createSideBarPage({
        label = i18n("mcm_ClothingEnchantmentChargeColors_PageName"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_PageDescription"),
    })

    pageClothingEnchantmentChargeColorPickers:createYesNoButton({
        label = i18n("mcm_ClothingEnchantmentChargeColors_enableColorsClothingEnchantmentCharge"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_enableColorsClothingEnchantmentCharge_Description"),
        configKey = "enableColorsClothingEnchantmentCharge"
    })

    local clothingEnchantmentChargeColorResetButton = pageClothingEnchantmentChargeColorPickers:createButton{
		buttonText = i18n("mcm_resetButton_ButtonText"),
        description = i18n("mcm_resetButton_Description"),
    }

	local clothingEnchantmentChargeColorExcellentPicker = pageClothingEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorExcellent"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorExcellent_Description"),
        configKey = "clothingEnchantmentChargeColorExcellent",
        defaultSetting = defaultConfig.clothingEnchantmentChargeColorExcellent
    })

	local clothingEnchantmentChargeColorGoodPicker = pageClothingEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorGood"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorGood_Description"),
        configKey = "clothingEnchantmentChargeColorGood",
        defaultSetting = defaultConfig.clothingEnchantmentChargeColorGood
    })

	local clothingEnchantmentChargeColorPoorPicker = pageClothingEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorPoor"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorPoor_Description"),
        configKey = "clothingEnchantmentChargeColorPoor",
        defaultSetting = defaultConfig.clothingEnchantmentChargeColorPoor
    })

	local clothingEnchantmentChargeColorBadPicker = pageClothingEnchantmentChargeColorPickers:createColorPickerButton({
        label = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorBad"),
        description = i18n("mcm_ClothingEnchantmentChargeColors_clothingEnchantmentChargeColorBad_Description"),
        configKey = "clothingEnchantmentChargeColorBad",
        defaultSetting = defaultConfig.clothingEnchantmentChargeColorBad
    })

    clothingEnchantmentChargeColorResetButton.callback = function()
        clothingEnchantmentChargeColorExcellentPicker:resetToDefault()
        clothingEnchantmentChargeColorGoodPicker:resetToDefault()
        clothingEnchantmentChargeColorPoorPicker:resetToDefault()
        clothingEnchantmentChargeColorBadPicker:resetToDefault()
    end

	-- exclusions, clothing

	template:createExclusionsPage({
		label = i18n("mcm_ClothingExcludedSlots_PageName"),
		description = i18n("mcm_ClothingExcludedSlots_PageDescription"),
		leftListLabel = i18n("mcm_ClothingExcludedSlots_leftListLabel"),
		rightListLabel = i18n("mcm_ClothingExcludedSlots_rightListLabel"),
		variable = mwse.mcm.createTableVariable{
			id = "excludedClothingSlots",
			table = config,
		},
		filters = {
			{
				label = i18n("mcm_ClothingExcludedSlots_clothing"),
				callback = function()
					local clothingSlots = utils.getClothingSlots()

					local clothingSlotNames = {}
					for _, slot in ipairs(clothingSlots) do
						table.insert(clothingSlotNames, slot.name)
					end

					return clothingSlotNames
				end
			},
		},
	})
end

event.register("modConfigReady", registerModConfig)