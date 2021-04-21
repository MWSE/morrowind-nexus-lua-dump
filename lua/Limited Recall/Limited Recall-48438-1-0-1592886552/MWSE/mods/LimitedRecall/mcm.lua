local mod = "Limited Recall"
local version = "1.0"

local config = require("LimitedRecall.config")

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
            "This mod can be used to limit the casting of Recall in various ways.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it.",
    }

    page:createSlider{
        label = "Recalls per day",
        description =
            "The number of times you're able to cast Recall per day. Note that \"day\" here refers to a calendar day, midnight to midnight.\n" ..
            "\n" ..
            "Default: 1",
        variable = createTableVar("recallLimit"),
        max = 10,
        jump = 2,
        defaultSetting = 1,
    }

    page:createYesNoButton{
        label = "Limit applies to items/scrolls/potions",
        description =
            "If this option is enabled, the Recall limitation will also apply to enchanted items, scrolls and potions that provide the Recall effect. Otherwise, the limit applies only to spells.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("limitAllSources"),
        defaultSetting = false,
    }

    page:createYesNoButton{
        label = "Limit Recalls per real-life day",
        description =
            "If this option is enabled, the per-day Recall limit will be applied per real-life day. Otherwise, the limit will apply per in-game day.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("realLifeDayLimit"),
        defaultSetting = false,
    }

    page:createYesNoButton{
        label = "Enable lifetime Recall limit",
        description =
            "If this option is enabled, the total number of times any given character can ever cast Recall will be limited by the lifetime Recall limit. Otherwise, the lifetime limit will not be enforced.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("enableLifetimeLimit"),
        defaultSetting = false,
    }

    page:createSlider{
        label = "Lifetime Recall limit",
        description =
            "The number of times any given character is able to ever cast Recall, if the lifetime limit is enabled. Note that the option to limit enchanted items/scrolls/potions will apply to the lifetime limit as well.\n" ..
            "\n" ..
            "Default: 10",
        variable = createTableVar("recallLifetimeLimit"),
        max = 100,
        defaultSetting = 10,
    }

    page:createYesNoButton{
        label = "Display messages",
        description =
            "If this option is enabled, a message will be displayed upon a successful casting of Recall, showing how many Recalls are remaining. Otherwise, these messages will not be shown, though you will still see a message when this mod blocks you from casting Recall.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("displayMessages"),
        defaultSetting = true,
    }

    return page
end

local template = mwse.mcm.createTemplate("Limited Recall")
template:saveOnClose("LimitedRecall", config)

createPage(template)

mwse.mcm.register(template)