local configPath = "DynamicItemWeights"
local cfg = {}  -- Initialize the cfg table
---@class DynamicWeights
local defaults = {
    weaponDivision = 3,
    AppWeight = 2,
    enableWeapons = true,
    enableThrowing = true,  -- Added missing key to defaults
    enableDarts = true,     -- Added missing key to defaults
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

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createYesNoButton({
		label = "Disable Weapon Changes",
		description = [[Default: Yes.
        Enable Weapon Weight Change to Initial Weight / 3.]],
		configKey = "enableWeapons"
	})

    settings:createSlider({
        label = "How Much to Divide Initial Weapon Weight By.",
        configKey = "weaponDivision",
        min = 2, max = 5, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Disable Throwing Star Changes",
		description = [[Default: Yes.
        Enable Throwing Star Weight to 0.1.]],
		configKey = "enableThrowing"
	})

    settings:createYesNoButton({
		label = "Disable Dart Changes",
		description = [[Default: Yes.
        Enable Dart Weight to 0.1.]],
		configKey = "enableDarts"
	})

    settings:createYesNoButton({
		label = "Disable Arrows Changes",
		description = [[Default: Yes.
        Enable Arrow Weight to 0.]],
		configKey = "enableAmmunition"
	})

    settings:createYesNoButton({
		label = "Disable Potion Changes",
		description = [[Default: Yes.
        Enable Potion Weight to 1.]],
		configKey = "enableAlchemy"
	})

    settings:createYesNoButton({
		label = "Disable Apparatus Changes",
		description = [[Default: Yes.
        Enable Apparatus Weight Change to Initial Weight / 2.]],
		configKey = "enableApparatus"
	})

    settings:createSlider({
        label = "How Much to Divide Initial Apparatus Weight By.",
        configKey = "AppWeight",
        min = 2, max = 5, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Disable Clothing Changes",
		description = [[Default: Yes.
        Enable Clothing Weight Change. Shirts/Pants/Skirt to 0.5, Robes/Shoes to 1, Amulets/Gloves/Belts to 0.1, Rings to 0.]],
		configKey = "enableClothing"
	})

    settings:createYesNoButton({
		label = "Disable Lockpick Changes",
		description = [[Default: Yes.
        Enable Lockpick Weight Change to 0.]],
		configKey = "enableLockpicks"
	})

    settings:createYesNoButton({
		label = "Disable Probe Changes",
		description = [[Default: Yes.
        Enable Probe Weight Change to 0.]],
		configKey = "enableProbes"
	})

    settings:createYesNoButton({
		label = "Disable Key Changes",
		description = [[Default: Yes.
        Enable Key Weight Change to 0.]],
		configKey = "enableKeys"
	})

    settings:createYesNoButton({
		label = "Disable Soul Gem Changes",
		description = [[Default: Yes.
        Enable Soul Gem Weight Change to 0.]],
		configKey = "enableSouGems"
	})

    settings:createYesNoButton({
		label = "Disable Repair Items Changes",
		description = [[Default: Yes.
        Enable Repair Items Weight Change to 1.]],
		configKey = "enableRepairItems"
	})

    settings:createYesNoButton({
		label = "Disable Book Changes",
		description = [[Default: Yes.
        Enable Book Weight Change to 0.5. Scrolls to 0.1.]],
		configKey = "enableBooks"
	})

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config