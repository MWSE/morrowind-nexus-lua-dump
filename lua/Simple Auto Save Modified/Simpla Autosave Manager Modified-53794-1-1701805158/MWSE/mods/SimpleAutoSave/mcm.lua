local config = require("SimpleAutoSave.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            "Simple Auto Save\n" ..
            "v1.0.0\n" ..
            "\n" ..
            "Simply auto save your game every N minutes or upon changing cells. " ..
            "It literally does nothing else but hit the autosave key so you don't have to remember.\n" ..
            "\n" ..
            "You need to reload the game for these changes to take effect." ..
            "\n" ..
            "Hover over an option to learn more about it.",
    }

    page:createTextField{
        label = "Autosave period",
        description =
            "Minutes between autosaves.\n" ..
            "\n" ..
            "Default: 1",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable{ id = "autoSavePeriod", table = config, numbersOnly = true },
        defaultSetting = 1,
    }

    page:createYesNoButton{
        label = "Autosave on cell change",
        description =
            "If enabled, autosave will be triggered when changing cells (door, travel, recall etc.)\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{ id = "saveOnCellChange", table = config },
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Don't save on exterior cell changes",
        description =
            "If enabled, autosave will not be triggered when transitioning between exterior cells.\n" ..
            "Recommended, since when running around the exteriors would trigger autosaves all the time.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{ id = "dontSaveOnExtTransitions", table = config },
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Do not autosave in combat",
        description =
            "If enabled, no autosaves will be made if the player is in combat.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{ id = "dontSaveInCombat", table = config },
        defaultSetting = true,
    }
end

local template = mwse.mcm.createTemplate("Simple Auto Save")
template:saveOnClose("SimpleAutoSave", config)
createPage(template)
mwse.mcm.register(template)
