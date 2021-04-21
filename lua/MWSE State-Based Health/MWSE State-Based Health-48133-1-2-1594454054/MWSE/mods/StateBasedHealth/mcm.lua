local mod = "State-Based Health"
local version = "1.2"

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
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This is a retroactive, state-based health mod. Your health will now be calculated based on your current strength, endurance and level.\n" ..
            "\n" ..
            "Anything that influences your strength or endurance, such as any Fortify or Drain effects (or attribute damage) will affect your health. Any Fortify Health effects are taken into account.\n" ..
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

    page:createOnOffButton{
        label = "Max health safety net",
        description =
            "If enabled, this setting will prevent the mod from setting your max health to less than 1.\n" ..
            "\n" ..
            "If your endurance and strength are both drained or damaged to 0 (which can happen as a result of Black-Heart Blight, for example), your max health will normally be set to 0, which will kill you.\n" ..
            "\n" ..
            "This setting acts as a safety net, preventing such a severe drain from killing you outright at full health. Note that your current health can still be set to less than 1, if you're not at full health when your endurance and strength are drained.\n" ..
            "\n" ..
            "Default: off",
        variable = createTableVar("maxHealthSafety"),
        defaultSetting = false,
    }

    page:createOnOffButton{
        label = "Current health safety net",
        description =
            "If enabled, this setting will prevent the mod from setting your current health to less than 1. This will only be effective if the \"max health safety net\" and \"maintain health difference\" settings are also enabled.\n" ..
            "\n" ..
            "For example, let's say your health is 10/50 when hit with Black-Heart Blight, which drains your endurance and strength both to 0. With \"max health safety net\" and \"maintain health difference\" enabled, your max health will be set to 1 rather than 0, but your current health will be set to -39 (to maintain the difference of 40), which will kill you.\n" ..
            "\n" ..
            "However, with this setting enabled, your current health will also be set to 1. This ensures that no Drain or Damage effect can be lethal by itself.\n" ..
            "\n" ..
            "This setting is disabled by default because it's exploitable. When this safety net is triggered, it will reduce the difference between your max and current health. To continue the above example, the difference changes from 40 (10/50) to 0 (1/1). When your blight disease is cured and your max health raised back to 50, your current health will also be set to 50, maintaining the new difference. This means you get free healing.\n" ..
            "\n" ..
            "Default: off",
        variable = createTableVar("currentHealthSafety"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("State-Based Health")
template:saveOnClose("StateBasedHealth", config)

createPage(template)

mwse.mcm.register(template)