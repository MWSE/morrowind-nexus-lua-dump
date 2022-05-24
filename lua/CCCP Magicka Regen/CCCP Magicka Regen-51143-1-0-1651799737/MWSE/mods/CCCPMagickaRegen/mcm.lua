local config = require("CCCPMagickaRegen.config")
local modInfo = require("CCCPMagickaRegen.modInfo")

local onlyChargen = "This value is used only during the mod's initial calculations upon completing chargen. Changing this value after chargen is complete will have no effect."

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod implements the magicka regen functionality of Class-Conscious Character Progression (CCCP), without any of that mod's other features.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it.",
    }

    page:createYesNoButton{
        label = "Magicka regen enabled",
        description =
            "This setting can be used to disable magicka regen entirely. If turned off, magicka will not regenerate.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "magickaRegen",
            table = config,
        },
        defaultSetting = true,
    }

    page:createSlider{
        label = "Base regen rate",
        description =
            "A simple modifier to the base rate of magicka regen, as a percentage of the normal rate. The higher this setting, the faster magicka will regenerate.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenBaseRate",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    page:createSlider{
        label = "Initial magic skill offset",
        description =
            "One of the things that contributes to determining how fast your magicka regenerates is your starting values in the magic-related skills. The higher these eight skills start out, the faster your magicka will regenerate.\n" ..
            "\n" ..
            "This setting determines how much influence the starting value of the magic skills will have. The higher the offset, the less difference there will be in terms of magicka regen rate between high and low initial magic skill values.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenStartOffset",
            table = config,
        },
        min = -40,
        max = 100,
        jump = 10,
        defaultSetting = 0,
    }

    page:createSlider{
        label = "Regen rate progression",
        description =
            "As you increase your magic-related skills, the rate your magicka regenerates will increase. This setting determines the rate of progression of magicka regen rate due to magic skill increases.\n" ..
            "\n" ..
            "Changing this setting will have an immediate effect on regen rate.\n" ..
            "\n" ..
            "Default: 70",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenProgress",
            table = config,
        },
        max = 100,
        defaultSetting = 70,
    }

    page:createSlider{
        label = "Neutral willpower value",
        description =
            "Your rate of magicka regeneration is also influenced by your current willpower attribute.\n" ..
            "\n" ..
            "This setting is the willpower value that will result in a \"normal\" magicka regen rate. Magicka will regen faster when your willpower is higher than this value, and slower when your willpower is lower.\n" ..
            "\n" ..
            "Default: 60",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenWilValue",
            table = config,
        },
        max = 100,
        defaultSetting = 60,
    }

    page:createSlider{
        label = "Willpower influence on regen rate",
        description =
            "Determines the extent to which willpower influences magicka regen rate.\n" ..
            "\n" ..
            "If this setting were set to 0, willpower would have no influence on regen rate. If set to 100, regen rate would be directly proportional to willpower.\n" ..
            "\n" ..
            "Default: 60",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenWilInfluence",
            table = config,
        },
        max = 100,
        defaultSetting = 60,
    }

    page:createSlider{
        label = "Neutral fatigue ratio",
        description =
            "Your fatigue ratio (ratio of current to max fatigue) also affects magicka regen rate.\n" ..
            "\n" ..
            "This setting is the fatigue ratio, as a percentage, that will result in a \"normal\" magicka regen rate. Magicka will regen faster when your fatigue ratio is higher than this value, and slower when your fatigue ratio is lower.\n" ..
            "\n" ..
            "Setting this very low can have pretty crazy results, especially if \"fatigue influence on regen rate\" is set very high.\n" ..
            "\n" ..
            "Default: 80",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenFatValue",
            table = config,
        },
        max = 100,
        defaultSetting = 80,
    }

    page:createSlider{
        label = "Fatigue influence on regen rate",
        description =
            "Determines the extent to which fatigue ratio influences magicka regen rate.\n" ..
            "\n" ..
            "If this setting were set to 0, fatigue would have no influence on regen rate. If set to 100, regen rate would be directly proportional to fatigue ratio.\n" ..
            "\n" ..
            "Default: 80",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenFatInfluence",
            table = config,
        },
        max = 100,
        defaultSetting = 80,
    }

    page:createOnOffButton{
        label = "Debug mode",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config,
        },
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("CCCP Magicka Regen")
template:saveOnClose("CCCPMagickaRegen", config)

createPage(template)

mwse.mcm.register(template)