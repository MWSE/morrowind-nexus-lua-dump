local modInfo = require("PropylonRenamer.modInfo")
local config = require("PropylonRenamer.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod renames propylon indexes so they'll group together in the inventory. The new naming format is \"Propylon Index, (Stronghold)\".\n" ..
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
        label = "Rename the Master Index",
        description =
            "If this option is enabled, and you're using the official plugin Master Index, the Master Propylon Index will be renamed with the same format as other indexes (\"Propylon Index, Master\").\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "master",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    return page
end

local template = mwse.mcm.createTemplate("Propylon Index Renamer")
template:saveOnClose("PropylonRenamer", config)

createPage(template)

mwse.mcm.register(template)