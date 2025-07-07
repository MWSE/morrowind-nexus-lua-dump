local configPath = "Hammer and Prongs"
local cfg = {}  -- Initialize the cfg table
local defaults = {
    jewelry = true,
    OAAB = true,
    TRData = true,
    daedric = false,
    skillMessage = true
}

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
		label = "Include Jewelry Recipes",
		description = "Game restart required. Default: Yes",
		configKey = "jewelry"
	})

    settings:createYesNoButton({
		label = "Include OAAB Recipes",
		description = "Game restart required. Default: Yes",
		configKey = "OAAB"
	})

    settings:createYesNoButton({
		label = "Include Tamriel_Data Recipes",
		description = "Game restart required. Default: Yes",
		configKey = "TRData"
	})

    settings:createYesNoButton({
		label = "Include Daedric Recipes",
		description = "Game restart required. Default: No",
		configKey = "daedric"
	})

    settings:createYesNoButton({
		label = "Show Notification on Skill Requirement Met",
		description = "Shows a message when you meet the required skill level for new recipes. Default: Yes",
		configKey = "skillMessage"
	})

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config