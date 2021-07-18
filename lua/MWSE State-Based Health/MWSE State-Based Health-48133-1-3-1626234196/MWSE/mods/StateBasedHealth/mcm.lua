local modInfo = require("StateBasedHealth.modInfo")
local config = require("StateBasedHealth.config")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod calculates your health based on your current endurance, strength and level.\n" ..
            "\n" ..
            "Anything that influences your endurance or strength, such as any fortify or drain effects (or attribute damage) will affect your health. Any Fortify Health effects are taken into account.\n" ..
            "\n" ..
            "Hover over a setting to learn more about it.",
    }

    page:createOnOffButton{
        label = "Maintain health difference",
        description =
            "By default, whenever this mod changes your health, it will maintain the ratio of your current and max health.\n" ..
            "\n" ..
            "For example, let's say your health is 10/60 (a ratio of 1/6) when you're subject to a Drain Endurance effect that lowers your max health to 30. The ratio of 1/6 will be maintained, and your new health will be 5/30.\n" ..
            "\n" ..
            "If this setting is enabled, the mod will maintain the difference between your current and max health, rather than the ratio.\n" ..
            "\n" ..
            "To use the example above, with a health of 10/60, the difference is 50. When your max health is lowered to 30 due to the Drain Endurance effect, that difference of 50 will be maintained, and your new health will be -20/30 (in other words, you're dead).\n" ..
            "\n" ..
            "This setting is beneficial when your health is being increased, but detrimental (and dangerous) when your health is being decreased.\n" ..
            "\n" ..
            "Default: off",
        variable = createTableVar("maintainDifference"),
        defaultSetting = false,
    }

    page:createSlider{
        label = "Minimum max health",
        description =
            "This setting will prevent the mod from setting your maximum health below the specified value. It acts as a safety net to prevent a bad attribute drain (for example, Black-Heart Blight can drain both your endurance and strength to 0) from killing you outright.\n" ..
            "\n" ..
            "This will not prevent you from being killed when your endurance/strength is lowered if you're maintaining difference rather than ratio, and you've taken enough damage to be lethal with your new maximum health.\n" ..
            "\n" ..
            "Default: 0",
        variable = createTableVar("minMaxHealth"),
        max = 20,
        defaultSetting = 0,
    }

    page:createOnOffButton{
        label = "Logging",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: off",
        variable = createTableVar("logging"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("State-Based Health")
template:saveOnClose("StateBasedHealth", config)

createPage(template)

mwse.mcm.register(template)