local configPath = "DynamicItemWeights"
local cfg = {}  -- Initialize the cfg table
---@class DynamicWeights
local defaults = {
    weaponDivision = 3,
    AppWeight = 2,
    enableWeapons = true,
    enableThrowing = true,
    enableDarts = true,
    enableAmmunition = true,
    enableAlchemy = true,
    enableApparatus = true,
    enableClothing = true,
    enableLockpicks = true,
    enableProbes = true,
    enableRepairItems = true,
    enableBooks = true,
    enableKeys = true,
    enableSoulGems = true,
    enableIngredients = true
}

---@class DynamicWeights
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createSideBarPage({ label = "Settings" })
    settings.showReset = true

    settings:createYesNoButton({
		label = "Enable Weapon Changes",
		description = "Default: Yes. Requires game restart. Enable Weapon Weight Change to Initial Weight / 3",
		configKey = "enableWeapons"
	})

    settings:createSlider({
        label = "How Much to Divide Initial Weapon Weight By.",
        configKey = "weaponDivision",
        min = 2, max = 5, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Enable Throwing Star Changes",
		description = "Default: Yes. Requires game restart. Enable Throwing Star Weight to 0.1",
		configKey = "enableThrowing"
	})

    settings:createYesNoButton({
		label = "Enable Dart Changes",
		description = "Default: Yes. Requires game restart. Enable Dart Weight to 0.1",
		configKey = "enableDarts"
	})

    settings:createYesNoButton({
		label = "Enable Arrow Changes",
		description = "Default: Yes. Requires game restart. Enable Arrow Weight to 0",
		configKey = "enableAmmunition"
	})

    settings:createYesNoButton({
		label = "Enable Potion Changes",
		description = "Default: Yes. Requires game restart. Enable Potion Weight to 1",
		configKey = "enableAlchemy"
	})

    settings:createYesNoButton({
		label = "Enable Apparatus Changes",
		description = "Default: Yes. Requires game restart. Enable Apparatus Weight Change to Initial Weight / 2",
		configKey = "enableApparatus"
	})

    settings:createSlider({
        label = "How Much to Divide Initial Apparatus Weight By.",
        configKey = "AppWeight",
        min = 2, max = 5, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Enable Clothing Changes",
		description = "Default: Yes. Requires game restart. Enable Clothing Weight Change. Shirts/Pants/Skirt to 0.5, Robes/Shoes to 1, Amulets/Gloves/Belts to 0.1, Rings to 0",
		configKey = "enableClothing"
	})

    settings:createYesNoButton({
		label = "Enable Lockpick Changes",
		description = "Default: Yes. Requires game restart. Enable Lockpick Weight Change to 0",
		configKey = "enableLockpicks"
	})

    settings:createYesNoButton({
		label = "Enable Probe Changes",
		description = "Default: Yes. Requires game restart. Enable Probe Weight Change to 0",
		configKey = "enableProbes"
	})

    settings:createYesNoButton({
		label = "Enable Key Changes",
		description = "Default: Yes. Requires game restart. Enable Key Weight Change to 0",
		configKey = "enableKeys"
	})

    settings:createYesNoButton({
		label = "Enable Soul Gem Changes",
		description = "Default: Yes. Requires game restart. Enable Soul Gem Weight Change to 0",
		configKey = "enableSouGems"
	})

    settings:createYesNoButton({
		label = "Enable Repair Items Changes",
		description = "Default: Yes. Requires game restart. Enable Repair Items Weight Change to 1",
		configKey = "enableRepairItems"
	})

    settings:createYesNoButton({
		label = "Enable Book Changes",
		description = "Default: Yes. Requires game restart. Enable Book Weight Change to 0.5. Scrolls to 0.1",
		configKey = "enableBooks"
	})

    settings:createYesNoButton({
		label = "Enable Ingredient Changes",
		description = "Default: Yes. Requires game restart. Changes ingredient weights to 0.1",
		configKey = "enableIngredients"
	})

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config