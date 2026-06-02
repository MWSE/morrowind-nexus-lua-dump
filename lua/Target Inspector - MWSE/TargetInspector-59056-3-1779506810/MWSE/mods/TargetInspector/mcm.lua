local modName = "Target Inspector"

local configModule = require("TargetInspector.config")
local config = configModule.current
local defaultConfig = configModule.default
local configPath = configModule.path

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = modName,
        config = config,
        defaultConfig = defaultConfig,
        showDefaultSetting = true,
    })

    local page = template:createSideBarPage({
        label = "Settings",
        description =
            "Target Inspector\n\n" ..
            "Shows actor stats in mouseover tooltips. Intended for testing/debugging.",
    })

    page:createYesNoButton({
        label = "Enable Target Inspector",
        configKey = "enabled",
        description = "Turns the inspector on or off.",
    })

	page:createKeyBinder({
		label = "Inspector Key",
		configKey = "inspectKey",
		keybindName = "Target Inspector",
		allowCombinations = true,
		allowMouse = false,
		description = "Hold this key while hovering over a target to show the inspector window. Default is I.",
	})

    page:createYesNoButton({
        label = "Show Vitals",
        configKey = "showVitals",
        description = "Shows Health, Magicka, Fatigue, and Level.",
    })

    page:createYesNoButton({
        label = "Show Attributes",
        configKey = "showAttributes",
        description = "Shows actor attributes.",
    })

    page:createYesNoButton({
        label = "Show Skills",
        configKey = "showSkills",
        description = "Shows actor skills.",
    })

    template:saveOnClose(configPath, config)
    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)