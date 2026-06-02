local modName = "Always Goodbye"

local configModule = require("AlwaysGoodbye.config")
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
            "Always Goodbye\n\n" ..
            "Allows the Goodbye button to close dialogue even when Morrowind is waiting for a dialogue choice.",
    })

    page:createYesNoButton({
        label = "Enable Always Goodbye",
        configKey = "enabled",
        description = "If enabled, Goodbye can close dialogue even during choice prompts.",
    })

    template:saveOnClose(configPath, config)
    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)