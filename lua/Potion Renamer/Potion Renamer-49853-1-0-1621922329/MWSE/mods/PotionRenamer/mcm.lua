local modInfo = require("PotionRenamer.modInfo")
local config = require("PotionRenamer.config")
local data = require("PotionRenamer.data")

local function potionList()
    local list = {}

    for _, potion in ipairs(data.potions) do
        list[#list + 1] = potion.id
    end

    return list
end

local function createMainPage(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod renames most potions in the game so they'll sort rationally in the inventory, first by effect and then by quality.\n" ..
            "\n" ..
            "Standard potion names are now in the format \"(effect), (quality)\" - for example, \"Restore Health, Bargain\" - enabling you to easily find the potion you're looking for. Quality terms have also been tweaked so that potions of each effect will sort from lowest to highest quality.\n" ..
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
        label = "Rename alcohol",
        description =
            "If this option is enabled, alcohol potions will be renamed so that they all sort together in the inventory. The format is \"Alcohol, (name)\" - for example, \"Alcohol, Sujamma\".\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "alcohol",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Rename spoiled potions",
        description =
            "If this option is enabled, spoiled potions will be renamed so that they sort with other potions of their (positive) effect. The format is \"(effect), Spoiled\" - for example, \"Swift Swim, Spoiled\".\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "spoiled",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    return page
end

local function createBlacklistPage(template)
    template:createExclusionsPage{
        label = "Blacklist",
        description = "This page can be used to blacklist specific potions. Blacklisted potions will not be renamed. Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted potions",
        rightListLabel = "Potions",
        variable = mwse.mcm.createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            {callback = potionList},
        },
    }
end

local template = mwse.mcm.createTemplate("Potion Renamer")
template:saveOnClose("PotionRenamer", config)

createMainPage(template)
createBlacklistPage(template)

mwse.mcm.register(template)