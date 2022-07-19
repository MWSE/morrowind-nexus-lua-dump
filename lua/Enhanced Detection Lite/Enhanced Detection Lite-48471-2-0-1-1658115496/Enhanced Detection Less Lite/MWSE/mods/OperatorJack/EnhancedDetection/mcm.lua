local mod = "Enhanced Detection (Less Lite)"
local version = "2.0.1"

local config = require("OperatorJack.EnhancedDetection.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod is a lite version of Enhanced Detection, which implements visual effects for detect spells. While the original ED implemented many new detect effects, this version adds only two new effects: Detect Trap and Detect Door.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it. Any changes will require restarting Morrowind.",
    }

    page:createYesNoButton{
        label = "Enable Detect Trap",
        description =
            "If enabled, the Detect Trap effect will be added to the vanilla Detect Key spell. It will also be added to the Beggar's Nose spell associated with the birthsign The Tower.\n" ..
            "\n" ..
            "This effect is available for spellmaking and enchanting.\n" ..
            "\n" ..
            "Disabling this setting will not remove any custom spells or enchantments you have already created.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "enableTrap",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Enable Detect Door",
        description =
            "If enabled, a new spell with the Detect Door effect will be added to a number of spell merchants.\n" ..
            "\n" ..
            "This effect is available for spellmaking and enchanting.\n" ..
            "\n" ..
            "Disabling this setting will not remove any custom spells or enchantments you have already created.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "enableDoor",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createOnOffButton{
        label = "BTBGI Mode",
        description =
            "If enabled, the mod's changes to certain vanilla spells will be adjusted for consistency with BTB's Game Improvements.\n" ..
            "\n" ..
            "If Detect Trap is enabled, the Detect Key spell will have both effects at a higher radius and duration for a lower magicka cost, in line with BTBGI's changes.\n" ..
            "\n" ..
            "Also, the Beggar's Nose spell will not be modified, even with Detect Trap enabled - BTBGI changes this spell into a permanent ability and removes Detect Key.\n" ..
            "\n" ..
            "If Detect Door is enabled, the new spell added by that option will last longer and be cheaper, consistent with BTBGI's changes to the other detect spells.\n" ..
            "\n" ..
            "Finally, the base cost of the new effects is drastically lowered to equal BTBGI's base cost of the other detect effects.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "btbgiMode",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("Enhanced Detection")
template:saveOnClose("EnhancedDetection", config)

createPage(template)

mwse.mcm.register(template)