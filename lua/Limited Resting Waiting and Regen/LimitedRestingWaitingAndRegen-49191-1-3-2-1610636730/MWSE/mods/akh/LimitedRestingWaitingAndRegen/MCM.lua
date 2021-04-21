local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')
local config = require("akh.LimitedRestingWaitingAndRegen.Config")

local function registerModConfig()

    local template = mwse.mcm.createTemplate{
        name = modInfo.modName,
        headerImagePath="\\Textures\\akh\\LimitedRestingWaitingAndRegen\\logo.tga"
    }
    template:saveOnClose(modInfo.modName, config)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = modInfo.modDescription

    settings:createDropdown{
        label = "Resting Preset",
        description = "Waiting preset. Specifies where player can rest.",
        options = {
            { label = "Vanilla", value = constants.config.restingPreset.VANILLA},
            { label = "Only beds and scripted", value = constants.config.restingPreset.BEDS_AND_SCRIPTED}
        },
        defaultSetting = constants.config.restingPreset.BEDS_AND_SCRIPTED,
        variable = mwse.mcm.createTableVariable{
            id = "restingPreset",
            table = config
        }
    }

    settings:createDropdown{
        label = "Contextual Rest Button Preset",
        description = "Specifies how the 'Until Healed' button, visible when player's health is not full, behaves. If replaced with another preset it will always be visible regardless of player's health.",
        options = {
            { label = "Vanilla", value = constants.config.contextualRestButtonPreset.VANILLA},
            { label = "Until Morning", value = constants.config.contextualRestButtonPreset.UNTIL_MORNING},
            { label = "Until Morning / Until Evening", value = constants.config.contextualRestButtonPreset.UNTIL_MORNING_EVENING}
        },
        defaultSetting = constants.config.contextualRestButtonPreset.UNTIL_MORNING,
        variable = mwse.mcm.createTableVariable{
            id = "contextualRestButtonPreset",
            table = config
        }
    }

    settings:createDropdown{
        label = "Waiting Preset",
        description = "Waiting preset. Specifies where player can wait.",
        options = {
            { label = "Vanilla", value = constants.config.waitingPreset.VANILLA},
            { label = "Same as vanilla resting", value = constants.config.waitingPreset.VANILLA_RESTING},
            { label = "Same as vanilla resting + inns", value = constants.config.waitingPreset.VANILLA_RESTING_AND_INNS},
        },
        defaultSetting = constants.config.waitingPreset.VANILLA_RESTING_AND_INNS,
        variable = mwse.mcm.createTableVariable{
            id = "waitingPreset",
            table = config
        }
    }

    settings:createDropdown{
        label = "Health Regen Preset",
        description = "Health regen preset. Specifies how and when player's health can regenerate.",
        options = {
            { label = "Vanilla", value = constants.config.healthRegenPreset.VANILLA},
            { label = "No regen on travel. Regen on rest.", value = constants.config.healthRegenPreset.NO_REGEN_ON_TRAVEL},
            { label = "No regen", value = constants.config.healthRegenPreset.NO_REGEN}
        },
        defaultSetting = constants.config.healthRegenPreset.NO_REGEN_ON_TRAVEL,
        variable = mwse.mcm.createTableVariable{
            id = "healthRegenPreset",
            table = config
        }
    }

    settings:createDropdown{
        label = "Magicka Regen Preset",
        description = "Magicka regen preset. Specifies how and when player's magicka can regenerate.",
        options = {
            { label = "Vanilla", value = constants.config.magickaRegenPreset.VANILLA},
            { label = "No regen on travel", value = constants.config.magickaRegenPreset.NO_REGEN_ON_TRAVEL}
        },
        defaultSetting = constants.config.magickaRegenPreset.NO_REGEN_ON_TRAVEL,
        variable = mwse.mcm.createTableVariable{
            id = "magickaRegenPreset",
            table = config
        }
    }

    settings:createOnOffButton{
        label = "Resting/Waiting Anti-Spam",
        description = "When enabled, prevents consecutive resting/waiting. Once rested, at least one hour of in-game time will have to pass to be able to rest or wait again. If waited, player won't be able to wait for another hour but will be able to rest.",
        defaultSetting = true,
        variable = mwse.mcm.createTableVariable{
            id = "restingWaitingAntiSpam",
            table = config
        }
    }

end

event.register("modConfigReady", registerModConfig)