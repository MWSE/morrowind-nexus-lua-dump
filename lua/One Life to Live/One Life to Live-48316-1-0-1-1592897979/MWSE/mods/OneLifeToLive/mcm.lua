local mod = "One Life to Live"
local version = "1.0.1"

local config = require("OneLifeToLive.config")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod allows you to implement permadeath for new characters. Once a character has expended all of their available lives, you will no longer be able to load any saves for that character.\n" ..
            "\n" ..
            "Hover over an option to learn more about it.",
    }

    page:createYesNoButton{
        label = "Enable permadeath for new characters",
        description =
            "New characters created with this setting enabled will be subject to permadeath.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("enabledForNew"),
        defaultSetting = true,
    }

    page:createSlider{
        label = "Number of lives for new characters",
        description =
            "New characters created with permadeath enabled will have this number of lives.\n" ..
            "\n" ..
            "Default: 1",
        variable = createTableVar("livesForNew"),
        min = 1,
        max = 10,
        jump = 2,
        defaultSetting = 1,
    }

    page:createYesNoButton{
        label = "Display messages",
        description =
            "If enabled, a message will be displayed on loading a game and when a character dies showing the number of lives remaining for that character.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("displayMessages"),
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Enable debug mode",
        description =
            "If enabled, the mod will log extensive information about its operation to mwse.log.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("debugMode"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("One Life to Live")
template:saveOnClose("OneLifeToLive", config)

createPage(template)

mwse.mcm.register(template)