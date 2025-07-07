local config = require("ndvr.equipment_menu.config.config")
local defaultConfig = require("ndvr.equipment_menu.config.defaultConfig")

local utils = require("ndvr.equipment_menu.utils")

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ 
		name = "Equipment Menu",
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
        label = "General",
        description = "General settings."
    })

	page:createYesNoButton({
        label = "Enable mod",
        description = "When set to 'No', disables Equipment Menu and mod functionality.",
        configKey = "modEnabled"
    })

    page:createYesNoButton({
        label = "Show 'Toggle Equipment menu' button",
        description = "When set to 'Yes', displays small '+' button in inventory, left-top corner of character's portrait, which toggles Equipment menu.",
        configKey = "showToggleMenuButton"
    })

    page:createYesNoButton({
        label = "Enable keybind to toggle menu",
        description = "When set to 'Yes', allows to open Equipment menu in inventory by pressing keybind.\n\nIn case you don't want to use button and/or it displays incorrectly.",
        configKey = "enableKeybindToggle"
    })

    page:createKeyBinder{
		label = "Assign 'Toggle Equipment menu' Hotkey",
		allowCombinations = false,
		variable = mwse.mcm.createTableVariable { id = "toggleMenuKeybind", table = config },
	}

	page:createYesNoButton({
        label = "Show boots/shoes slot for Beast races",
        description = "In vanilla Morrowind beast races (Khajiit and Argonian) can't equip shoes or boots, so this mod doesn't show this slots for Khajiit/Argonian characters.\n\nIf you have a mod, which allowes them to wear shoes, you can set this option to 'Yes' to show shoes/boots slots in Equipment window.",
        configKey = "showShoesBootsSlotsForBeastRaces"
    })

	page:createYesNoButton({
        label = "Show empty slots only",
        description = "When set to 'Yes', slots with items equipped in them will not be shown.\n\nThis way you can use Equipment Menu to track which slots left to fill with equipment.",
        configKey = "showEmptySlotsOnly"
    })

    page:createYesNoButton({
        label = "Allow gloves with bracers (MCP)",
        description = "When set to 'Yes,' items equipped in the Gloves slot will no longer duplicate in the Bracers slot, allowing the Bracers to display correctly.\n\nBy default, you can only equip either Gauntlets, Bracers, or Gloves. However, when using MCP's 'Allow gloves with bracers' option, you can equip both Bracers and Gloves at the same time, or just Gauntlets.\n\nNOTE! This option only adjusts how slots are displayed in Equipment Menu. In order to allow equipping both bracers and gloves simultaneously you have to install this patch in MCP!",
        configKey = "allowGlovesWithBracers"
    })

    -- weapon page

	local pageWeapon = template:createSideBarPage({
        label = "Weapon",
        description = "Weapon table settings.",
    })

	pageWeapon:createYesNoButton({
        label = "Show weapon table in Equipment menu",
        description = "When set to 'Yes', displays Weapon table in Equipment Menu.",
        configKey = "showWeaponTable"
    })

    pageWeapon:createYesNoButton({
        label = "Show ammo (arrows/bolts) slot",
        description = "When set to 'Yes', displays Ammo slot in Weapon table.",
        configKey = "showAmmoSlot"
    })

	pageWeapon:createYesNoButton({
        label = "Show table header",
        description = "When set to 'Yes', displays table header with column names in Weapon table.",
        configKey = "showWeaponHeader"
    })

	pageWeapon:createYesNoButton({
        label = "Show icon column",
        description = "When set to 'Yes', displays item's icon in Weapon table.",
        configKey = "showWeaponIconColumn"
    })

	pageWeapon:createYesNoButton({
        label = "Show slot column",
        description = "When set to 'Yes', displays item's slot in Weapon table.",
        configKey = "showWeaponSlotNameColumn"
    })

	pageWeapon:createYesNoButton({
        label = "Show condition column",
        description = "When set to 'Yes', displays item's condition in Weapon table.",
        configKey = "showWeaponConditionColumn"
    })

    pageWeapon:createYesNoButton({
        label = "Show condition value as percentage",
        description = "When set to 'Yes', the item's condition is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showWeaponConditionPercent"
    })

	pageWeapon:createYesNoButton({
        label = "Show enchantment charge column",
        description = "When set to 'Yes', displays item's enchantment charge in Weapon table.",
        configKey = "showWeaponEnchantmentChargeColumn"
    })

    pageWeapon:createYesNoButton({
        label = "Show enchantment charge value as percentage",
        description = "When set to 'Yes', the item's enchantment charge value is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showWeaponEnchantmentChargePercent"
    })

	pageWeapon:createYesNoButton({
        label = "Show item name column",
        description = "When set to 'Yes', displays item's name in Weapon table.",
        configKey = "showWeaponItemNameColumn"
    })

	-- weapon condition colors page

	local pageWeaponConditionColorPickers = template:createSideBarPage({
        label = "Weapon - Condition - Colors",
        description = "Weapon condition - label colors settings.",
    })

    pageWeaponConditionColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsWeaponCondition"
    })

	pageWeaponConditionColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values.\n\nNOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.weaponConditionColorExcellent = table.copy(defaultConfig.weaponConditionColorExcellent)
			config.weaponConditionColorGood = table.copy(defaultConfig.weaponConditionColorGood)
			config.weaponConditionColorPoor = table.copy(defaultConfig.weaponConditionColorPoor)
			config.weaponConditionColorBad = table.copy(defaultConfig.weaponConditionColorBad)
        end
    }

	pageWeaponConditionColorPickers:createColorPicker({
        label = "Weapon - Condition color: >= 80%",
        description = "If the item's condition >= 80%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "weaponConditionColorExcellent",
			table = config
		}
    })

	pageWeaponConditionColorPickers:createColorPicker({
        label = "Weapon - Condition color: >= 50%",
        description = "If the item's condition >= 50%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponConditionColorGood",
            table = config
        }
    })

	pageWeaponConditionColorPickers:createColorPicker({
        label = "Weapon - Condition color: >= 25%",
        description = "If the item's condition >= 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponConditionColorPoor",
            table = config
        }
    })

	pageWeaponConditionColorPickers:createColorPicker({
        label = "Weapon - Condition color: < 25%",
        description = "If the item's condition < 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponConditionColorBad",
            table = config
        }
    })

	-- weapon enchantment charge colors page

	local pageWeaponEnchantmentChargeColorPickers = template:createSideBarPage({
        label = "Weapon - Enchantment Charge - Colors",
        description = "Weapon enchantment charge - label colors settings.",
    })

    pageWeaponEnchantmentChargeColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsWeaponEnchantmentCharge"
    })

	pageWeaponEnchantmentChargeColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values.\n\nNOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.weaponEnchantmentChargeColorExcellent = table.copy(defaultConfig.weaponEnchantmentChargeColorExcellent)
			config.weaponEnchantmentChargeColorGood = table.copy(defaultConfig.weaponEnchantmentChargeColorGood)
			config.weaponEnchantmentChargeColorPoor = table.copy(defaultConfig.weaponEnchantmentChargeColorPoor)
			config.weaponEnchantmentChargeColorBad = table.copy(defaultConfig.weaponEnchantmentChargeColorBad)
        end
    }

	pageWeaponEnchantmentChargeColorPickers:createColorPicker({
        label = "Weapon - Enchantment charge color: >= 80%",
        description = "If the item's charge >= 80%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "weaponEnchantmentChargeColorExcellent",
			table = config
		}
    })

	pageWeaponEnchantmentChargeColorPickers:createColorPicker({
        label = "Weapon - Enchantment charge color: >= 50%",
        description = "If the item's charge >= 50%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponEnchantmentChargeColorGood",
            table = config
        }
    })

	pageWeaponEnchantmentChargeColorPickers:createColorPicker({
        label = "Weapon - Enchantment charge color: >= 25%",
        description = "If the item's charge >= 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponEnchantmentChargeColorPoor",
            table = config
        }
    })

	pageWeaponEnchantmentChargeColorPickers:createColorPicker({
        label = "Weapon - Enchantment charge color: < 25%",
        description = "If the item's charge < 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponEnchantmentChargeColorBad",
            table = config
        }
    })

	-- armor page

	local pageArmor = template:createSideBarPage({
        label = "Armor",
        description = "Armor table settings.",
    })

	pageArmor:createYesNoButton({
        label = "Show armor in Equipment menu",
        description = "When set to 'Yes', displays Armor table in Equipment Menu.",
        configKey = "showArmorTable"
    })

	pageArmor:createYesNoButton({
        label = "Show table header",
        description = "When set to 'Yes', displays table header with column names in Armor table.",
        configKey = "showArmorHeader"
    })

	pageArmor:createYesNoButton({
        label = "Show icon column",
        description = "When set to 'Yes', displays item's icon in Armor table.",
        configKey = "showArmorIconColumn"
    })

	pageArmor:createYesNoButton({
        label = "Show slot column",
        description = "When set to 'Yes', displays item's slot in Armor table.",
        configKey = "showArmorSlotNameColumn"
    })

	pageArmor:createYesNoButton({
        label = "Show condition column",
        description = "When set to 'Yes', displays item's condition in Armor table.",
        configKey = "showArmorConditionColumn"
    })

    pageArmor:createYesNoButton({
        label = "Show condition value as percentage",
        description = "When set to 'Yes', the item's condition is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showArmorConditionPercent"
    })

	pageArmor:createYesNoButton({
        label = "Show enchantment charge column",
        description = "When set to 'Yes', displays item's enchantment charge in Armor table.",
        configKey = "showArmorEnchantmentChargeColumn"
    })

    pageArmor:createYesNoButton({
        label = "Show enchantment charge value as percentage",
        description = "When set to 'Yes', the item's enchantment charge value is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showArmorEnchantmentChargePercent"
    })

	pageArmor:createYesNoButton({
        label = "Show item name column",
        description = "When set to 'Yes', displays item's name in Armor table.",
        configKey = "showArmorItemNameColumn"
    })

	-- armor condition colors page

	local pageArmorConditionColorPickers = template:createSideBarPage({
        label = "Armor - Condition - Colors",
        description = "Armor condition - label colors settings.",
    })

    pageArmorConditionColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsArmorCondition"
    })

	pageArmorConditionColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values.\n\nNOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.armorConditionColorExcellent = table.copy(defaultConfig.armorConditionColorExcellent)
			config.armorConditionColorGood = table.copy(defaultConfig.armorConditionColorGood)
			config.armorConditionColorPoor = table.copy(defaultConfig.armorConditionColorPoor)
			config.armorConditionColorBad = table.copy(defaultConfig.armorConditionColorBad)
        end
    }

	pageArmorConditionColorPickers:createColorPicker({
        label = "Armor - Condition color: >= 80%",
        description = "If the item's condition >= 80%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "armorConditionColorExcellent",
			table = config
		}
    })

	pageArmorConditionColorPickers:createColorPicker({
        label = "Armor - Condition color: >= 50%",
        description = "If the item's condition >= 50%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorConditionColorGood",
            table = config
        }
    })

	pageArmorConditionColorPickers:createColorPicker({
        label = "Armor - Condition color: >= 25%",
        description = "If the item's condition >= 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorConditionColorPoor",
            table = config
        }
    })

	pageArmorConditionColorPickers:createColorPicker({
        label = "Armor - Condition color: < 25%",
        description = "If the item's condition < 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorConditionColorBad",
            table = config
        }
    })

	-- armor enchantment charge colors page

	local pageArmorEnchantmentChargeColorPickers = template:createSideBarPage({
        label = "Armor - Enchantment Charge - Colors",
        description = "Armor enchantment charge - label colors settings.",
    })

    pageArmorEnchantmentChargeColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsArmorEnchantmentCharge"
    })

	pageArmorEnchantmentChargeColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values.\n\nNOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.armorEnchantmentChargeColorExcellent = table.copy(defaultConfig.armorEnchantmentChargeColorExcellent)
			config.armorEnchantmentChargeColorGood = table.copy(defaultConfig.armorEnchantmentChargeColorGood)
			config.armorEnchantmentChargeColorPoor = table.copy(defaultConfig.armorEnchantmentChargeColorPoor)
			config.armorEnchantmentChargeColorBad = table.copy(defaultConfig.armorEnchantmentChargeColorBad)
        end
    }

	pageArmorEnchantmentChargeColorPickers:createColorPicker({
        label = "Armor - Enchantment charge color: >= 80%",
        description = "If the item's charge >= 80%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "armorEnchantmentChargeColorExcellent",
			table = config
		}
    })

	pageArmorEnchantmentChargeColorPickers:createColorPicker({
        label = "Armor - Enchantment charge color: >= 50%",
        description = "If the item's charge >= 50%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorEnchantmentChargeColorGood",
            table = config
        }
    })

	pageArmorEnchantmentChargeColorPickers:createColorPicker({
        label = "Armor - Enchantment charge color: >= 25%",
        description = "If the item's charge >= 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorEnchantmentChargeColorPoor",
            table = config
        }
    })

	pageArmorEnchantmentChargeColorPickers:createColorPicker({
        label = "Armor - Enchantment charge color: < 25%",
        description = "If the item's charge < 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "armorEnchantmentChargeColorBad",
            table = config
        }
    })

    -- exclusions, armor

	template:createExclusionsPage({
		label = "Excluded Slots (Armor)",
		description = "These slots will not appear in the Equipment Menu.\n\nThis is useful for mods like Onion that add many new equipment slots, especially when you don't have items installed for all of them.",
		leftListLabel = "Excluded Armor slots",
		rightListLabel = "Allowed Armor slots",
		variable = mwse.mcm.createTableVariable{
			id = "excludedArmorSlots",
			table = config,
		},
		filters = {
			{
				label = "Armor",
				callback = function()
					local armorSlots = utils.getArmorSlots()

					-- Получаем список только имён (name), сохранив порядок сортировки
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
        label = "Clothing",
        description = "Clothing table settings."
    })

	pageClothing:createYesNoButton({
        label = "Show clothing in Equipment menu",
        description = "When set to 'Yes', displays table with clothing in Equipment Menu.",
        configKey = "showClothingTable"
    })

    pageClothing:createYesNoButton({
        label = "Show table header",
        description = "When set to 'Yes', displays table header with column names in Clothing table.",
        configKey = "showClothingHeader"
    })

	pageClothing:createYesNoButton({
        label = "Show icon column",
        description = "When set to 'Yes', displays item's icon in Clothing table.",
        configKey = "showClothingIconColumn"
    })

	pageClothing:createYesNoButton({
        label = "Show slot column",
        description = "When set to 'Yes', displays item's slot in Clothing table.",
        configKey = "showClothingSlotNameColumn"
    })

    pageClothing:createYesNoButton({
        label = "Show condition column",
        description = "When set to 'Yes,' the item's condition will be displayed in the Clothing table.\n\nAlthough clothing items don't have a condition value, this column will show the condition of equipped armor pieces that share the same slots - such as Boots/Shoes or Gauntlets/Gloves.",
        configKey = "showClothingConditionColumn"
    })

    pageClothing:createYesNoButton({
        label = "Show condition value as percentage",
        description = "When set to 'Yes', the item's condition is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showClothingConditionPercent"
    })

	pageClothing:createYesNoButton({
        label = "Show enchantment charge column",
        description = "When set to 'Yes', displays item's enchantment charge in Clothing table.",
        configKey = "showClothingEnchantmentChargeColumn"
    })

    pageClothing:createYesNoButton({
        label = "Show enchantment charge value as percentage",
        description = "When set to 'Yes', the item's enchantment charge value is displayed as a percentage (e.g. 85%) instead of an absolute value (e.g. 850/1000).",
        configKey = "showClothingEnchantmentChargePercent"
    })

	pageClothing:createYesNoButton({
        label = "Show item name column",
        description = "When set to 'Yes', displays item's name in Clothing table.",
        configKey = "showClothingItemNameColumn"
    })

    -- clothing condition colors page

	local pageClothingConditionColorPickers = template:createSideBarPage({
        label = "Clothing - Condition - Colors",
        description = "Clothing condition - label colors settings.",
    })

    pageClothingConditionColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsClothingCondition"
    })

	pageClothingConditionColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values. NOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.clothingConditionColorExcellent = table.copy(defaultConfig.clothingConditionColorExcellent)
			config.clothingConditionColorGood = table.copy(defaultConfig.clothingConditionColorGood)
			config.clothingConditionColorPoor = table.copy(defaultConfig.clothingConditionColorPoor)
			config.clothingConditionColorBad = table.copy(defaultConfig.clothingConditionColorBad)
        end
    }

	pageClothingConditionColorPickers:createColorPicker({
        label = "Clothing - Condition color: >= 80%",
        description = "If the item's condition >= 80%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "clothingConditionColorExcellent",
			table = config
		}
    })

	pageClothingConditionColorPickers:createColorPicker({
        label = "Clothing - Condition color: >= 50%",
        description = "If the item's condition >= 50%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingConditionColorGood",
            table = config
        }
    })

	pageClothingConditionColorPickers:createColorPicker({
        label = "Clothing - Condition color: >= 25%",
        description = "If the item's condition >= 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingConditionColorPoor",
            table = config
        }
    })

	pageClothingConditionColorPickers:createColorPicker({
        label = "Clothing - Condition color: < 25%",
        description = "If the item's condition < 25%, the condition value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingConditionColorBad",
            table = config
        }
    })

    -- clothing enchantment charge colors page

	local pageClothingEnchantmentChargeColorPickers = template:createSideBarPage({
        label = "Clothing - Enchantment Charge - Colors",
        description = "Clothing enchantment charge - label colors settings.",
    })

    pageClothingEnchantmentChargeColorPickers:createYesNoButton({
        label = "Enable colors",
        description = "When set to 'Yes', the item's condition values will be displayed using the colors selected on this page.\n\nWhen set to 'No', all condition values will use the same font and color as the rest of the menu text.",
        configKey = "enableColorsClothingEnchantmentCharge"
    })

	pageClothingEnchantmentChargeColorPickers:createButton{
        label = "NOTE: changes to UI won't show until menu re-opened",
		buttonText = "Reset all colors",
        description = "Resets all colors to default values. NOTE: changes to UI won't show until menu is re-opened.",
        callback = function()
            config.clothingEnchantmentChargeColorExcellent = table.copy(defaultConfig.clothingEnchantmentChargeColorExcellent)
			config.clothingEnchantmentChargeColorGood = table.copy(defaultConfig.clothingEnchantmentChargeColorGood)
			config.clothingEnchantmentChargeColorPoor = table.copy(defaultConfig.clothingEnchantmentChargeColorPoor)
			config.clothingEnchantmentChargeColorBad = table.copy(defaultConfig.clothingEnchantmentChargeColorBad)
        end
    }

	pageClothingEnchantmentChargeColorPickers:createColorPicker({
        label = "Clothing - Enchantment charge color: >= 80%",
        description = "If the item's charge >= 80%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
			id = "clothingEnchantmentChargeColorExcellent",
			table = config
		}
    })

	pageClothingEnchantmentChargeColorPickers:createColorPicker({
        label = "Clothing - Enchantment charge color: >= 50%",
        description = "If the item's charge >= 50%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingEnchantmentChargeColorGood",
            table = config
        }
    })

	pageClothingEnchantmentChargeColorPickers:createColorPicker({
        label = "Clothing - Enchantment charge color: >= 25%",
        description = "If the item's charge >= 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingEnchantmentChargeColorPoor",
            table = config
        }
    })

	pageClothingEnchantmentChargeColorPickers:createColorPicker({
        label = "Clothing - Enchantment charge color: < 25%",
        description = "If the item's charge < 25%, the enchantment charge value will be displayed in this color.",
        variable = mwse.mcm.createTableVariable{
            id = "clothingEnchantmentChargeColorBad",
            table = config
        }
    })

	-- exclusions, clothing

	template:createExclusionsPage({
		label = "Excluded Slots (Clothing)",
		description = "These slots will not appear in the Equipment Menu.\n\nThis is useful for mods like Onion that add many new equipment slots, especially when you don't have items installed for all of them.",
		leftListLabel = "Excluded Clothing slots",
		rightListLabel = "Allowed Clothing slots",
		variable = mwse.mcm.createTableVariable{
			id = "excludedClothingSlots",
			table = config,
		},
		-- This filters the right list by ingredient object
		filters = {
			{
				label = "Clothing",
				callback = function()
					local clothingSlots = utils.getClothingSlots()

					-- Получаем список только имён (name), сохранив порядок сортировки
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