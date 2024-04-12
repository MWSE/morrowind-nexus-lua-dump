local EasyMCM = require("EasyMCM.EasyMCM")
local config = require("omy1.AdjustableEnchantmentCapacity.config")
local template = EasyMCM.createTemplate("AdjustableEnchantmentCapacity")
template:saveOnClose("AdjustableEnchantmentCapacity", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
})

local settings = page:createCategory("Settings")

settings:createOnOffButton({
	label = "Mod Enabled",
	description = "Current Status of the mod. Restart the game after changing this option.",
	variable = EasyMCM.createTableVariable {
	  id = "modEnabled",
	  table = config
	}
  })

-- Enchantment Capacity
settings:createSlider({
    label = "Enchantment Capacity",
    description = "This setting adjusts the maximum amount of enchantment points that an item can hold. The higher the value, the bigger the enchantments an item can carry.",
    min = 0,
    max = 100000,
    step = 1,
    jump = 100,
    variable = EasyMCM:createTableVariable{
        id = "enchCap",
        table = config
    }
})

-- Enchantment Multiplier
settings:createSlider({
    label = "Enchantment Multiplier",
    description = "This setting adjusts the multiplier for enchantment points. What that means is that the value of Enchantment Capacity is going to be multiplied to the value of Enchantment Multiplier",
    min = 0,
    max = 1000,
    step = 0.1,
    jump = 1,
    variable = EasyMCM:createTableVariable{
        id = "FEnchantmentMult",
        table = config
    }
})