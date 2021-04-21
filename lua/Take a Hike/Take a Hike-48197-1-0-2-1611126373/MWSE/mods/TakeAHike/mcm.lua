local mod = "Take a Hike"
local version = "1.0.2"

local config = require("TakeAHike.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod disables almost all methods of travel besides your own two feet. The mod includes an MWSE component and a plugin, and both are required for the mod to function as intended." .. "\n" ..
            "\n" ..
            "These settings allow you to disable the features of the MWSE component of the mod. Hover over each option for details.",
    }

    page:createYesNoButton{
        label = "Disable teleportation",
        description =
            "If yes, teleportation magic effects (Almsivi Intervention, Divine Intervention and Recall) will no longer function.\n" ..
            "\n" ..
            "This applies to all sources of these effects, including spells, enchantments and potions.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "disableTeleport",
            table = config,
        },
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Disable jail transport",
        description =
            "If yes, you will not be left outside the nearest jail after serving a sentence.\n" ..
            "\n" ..
            "Instead, the guards will take you back to where you were arrested. This prevents you from using a jail sentence as a form of one-way fast travel.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "disableJailTransport",
            table = config,
        },
        defaultSetting = true,
    }

    return page
end

local template = mwse.mcm.createTemplate("Take a Hike")
template:saveOnClose("TakeAHike", config)

createPage(template)

mwse.mcm.register(template)