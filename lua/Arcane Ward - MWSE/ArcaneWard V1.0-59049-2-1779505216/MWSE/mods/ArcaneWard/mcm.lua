--[[
    ArcaneWard/mcm.lua

    Adds Arcane Ward to MWSE's Mod Config menu.
]]

local modName = "Arcane Ward"

local configModule = require("ArcaneWard.config")
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
            "Arcane Ward\n\n" ..
            "A robe-mage defensive ward based on Unarmored and Alteration.\n\n" ..
            "Unarmored and Alteration increase the ward. Armor reduces Ward Power.",
    })

    page:createYesNoButton({
        label = "Enable Arcane Ward",
        configKey = "enabled",
        description = "Turns the whole mod on or off.",
    })

    page:createYesNoButton({
        label = "Show in Stats Menu",
        configKey = "showInStatsMenu",
        description = "Shows Ward Power, Chance, and Absorb in the player stats menu.",
    })

    page:createSlider({
        label = "Minimum Unarmored: %s",
        configKey = "minUnarmored",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        decimalPlaces = 0,
        description = "Arcane Ward will not trigger unless Unarmored skill is at least this high.",
    })

    page:createSlider({
        label = "Minimum Alteration: %s",
        configKey = "minAlteration",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        decimalPlaces = 0,
        description = "Arcane Ward will not trigger unless Alteration skill is at least this high.",
    })

    page:createSlider({
        label = "Maximum Ward Chance: %s%%",
        configKey = "maxChance",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        decimalPlaces = 0,
        description = "Caps the maximum possible ward chance before armor penalties.",
    })

    page:createYesNoButton({
        label = "Allow Magic Damage",
        configKey = "allowMagicDamage",
        description = "If enabled, Arcane Ward can trigger against magic damage too.",
    })

    page:createYesNoButton({
        label = "Only Combat Damage",
        configKey = "onlyCombatDamage",
        description = "If enabled, Arcane Ward only triggers from combat-like damage. Ignores things like fall damage.",
    })

    page:createYesNoButton({
        label = "Apply to Player",
        configKey = "applyToPlayer",
        description = "If enabled, the player can use Arcane Ward.",
    })

    page:createYesNoButton({
        label = "Apply to NPCs",
        configKey = "applyToNPCs",
        description = "If enabled, NPCs can use Arcane Ward if they meet the skill and armor requirements.",
    })

    page:createYesNoButton({
        label = "Apply to Creatures",
        configKey = "applyToCreatures",
        description = "If enabled, creatures can use Arcane Ward. Disabled by default.",
    })

    page:createYesNoButton({
        label = "Play Ward Sound",
        configKey = "playProcSound",
        description = "Plays a sound when Arcane Ward successfully deflects damage.",
    })

    page:createYesNoButton({
        label = "Play Ward Visual Effect",
        configKey = "playProcVFX",
        description = "Plays a brief magic visual effect when Arcane Ward successfully deflects damage.",
    })

    page:createYesNoButton({
        label = "Debug Logging",
        configKey = "debug",
        description = "Writes troubleshooting info to MWSE.log.",
    })

    page:createYesNoButton({
        label = "Debug Messages",
        configKey = "debugMessages",
        description = "Shows in-game messages when damage happens, when the ward fails, and when the ward succeeds.",
    })

    template:saveOnClose(configPath, config)
    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)