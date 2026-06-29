local modName = "Target Inspector"

local configModule = require("TargetInspector.config")
local config       = configModule.current
local defaultConfig= configModule.default
local configPath   = configModule.path

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name          = modName,
        config        = config,
        defaultConfig = defaultConfig,
        showDefaultSetting = true,
    })

    local page = template:createSideBarPage({
        label       = "Settings",
        description =
            "Target Inspector\n\n" ..
            "Hold the configured key while hovering over an NPC or creature to show their stats.",
    })

    page:createYesNoButton({
        label       = "Enable Target Inspector",
        configKey   = "enabled",
        description = "Turns the inspector on or off.",
    })

    page:createKeyBinder({
        label            = "Inspector Key",
        configKey        = "inspectKey",
        keybindName      = "Target Inspector",
        allowCombinations= true,
        allowMouse       = false,
        description      = "Hold this key while hovering over a target to show the inspector window. Default is I.",
    })

    -- Display sections

    page:createYesNoButton({
        label       = "Show Vitals",
        configKey   = "showVitals",
        description = "Shows Type, Race, Gender, Class, Level, Health, Magicka, and Fatigue.",
    })

    page:createYesNoButton({
        label       = "Show Disposition",
        configKey   = "showDisposition",
        description = "Shows the NPC's current disposition toward the player. NPCs only.",
    })

    page:createYesNoButton({
        label       = "Show Faction",
        configKey   = "showFaction",
        description = "Shows the NPC's faction and rank. NPCs only.",
    })

    page:createYesNoButton({
        label       = "Show Combat Stats",
        configKey   = "showCombatStats",
        description = "Shows armor rating and attack bonus.",
    })

    page:createYesNoButton({
        label       = "Show Attributes",
        configKey   = "showAttributes",
        description = "Shows all eight actor attributes.",
    })

    page:createYesNoButton({
        label       = "Show Skills",
        configKey   = "showSkills",
        description = "Shows all 27 skills for NPCs. Shows Combat, Magic, and Stealth ratings for creatures.",
    })

    page:createYesNoButton({
        label       = "Show Active Magic Effects",
        configKey   = "showActiveMagicEffects",
        description = "Shows currently active magic effects and their magnitudes.",
    })

    -- Debug

    page:createYesNoButton({
        label       = "Debug Logging",
        configKey   = "debug",
        description = "Writes all inspector data to MWSE.log when the inspector opens for a new target.",
    })

    template:saveOnClose(configPath, config)
    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)
