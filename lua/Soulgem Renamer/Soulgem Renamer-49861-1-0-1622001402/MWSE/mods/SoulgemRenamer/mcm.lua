local modInfo = require("SoulgemRenamer.modInfo")
local config = require("SoulgemRenamer.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod renames soulgems so they'll group together in the inventory. The new naming format is \"Soulgem, (Quality)\".\n" ..
            "\n" ..
            "Hover over each option to learn more about it.",
    }

    page:createYesNoButton{
        label = "Enable mod",
        description =
            "Use this button to enable or disable the mod.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "enable",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Rename Azura's Star",
        description =
            "If this option is enabled, the unique soulgem Azura's Star will be renamed with the same format as other soulgems (\"Soulgem, Azura's Star\"), so it will group with other soulgems in the inventory.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "azura",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    return page
end

local template = mwse.mcm.createTemplate("Soulgem Renamer")
template:saveOnClose("SoulgemRenamer", config)

createPage(template)

mwse.mcm.register(template)