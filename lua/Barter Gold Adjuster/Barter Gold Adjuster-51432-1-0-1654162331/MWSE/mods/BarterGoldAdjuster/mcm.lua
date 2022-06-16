local modInfo = require("BarterGoldAdjuster.modInfo")
local config = require("BarterGoldAdjuster.config")
local common = require("BarterGoldAdjuster.common")
local list

local function checkActor(actor)
    if common.isMerchant(actor) then
        table.insert(list, actor.id:lower())
    end
end

-- Returns a list of the ID of every merchant in the game, to populate the blacklist.
local function blacklist()
    list = {}

    for actor in tes3.iterateObjects(tes3.objectType.npc) do
        checkActor(actor)
    end

    for actor in tes3.iterateObjects(tes3.objectType.creature) do
        checkActor(actor)
    end

    table.sort(list)
    return list
end

local function createPage(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod allows you to customize how much barter gold merchants have to trade with.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it.",
    }

    page:createTextField{
        label = "Multiplier",
        description =
            "Merchants' vanilla barter gold (or that set by any plugins that change it) will be multiplied by this value before the floor and cap are applied.\n" ..
            "\n" ..
            "Fractional values are allowed. Negative values will be treated as 0.\n" ..
            "\n" ..
            "Default: 1",
        variable = mwse.mcm.createTableVariable{
            id = "mult",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 1,
        restartRequired = true,
    }

    page:createTextField{
        label = "Floor",
        description =
            "If a merchant's barter gold, after the multiplier is applied, is below this value, it will be increased to this value.\n" ..
            "\n" ..
            "Fractional values will be rounded down. A value greater than the cap will be lowered internally to be equal to the cap. Negative values will be treated as 0.\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "floor",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 0,
        restartRequired = true,
    }

    page:createTextField{
        label = "Cap",
        description =
            "If a merchant's barter gold, after the multiplier is applied, is above this value, it will be decreased to this value.\n" ..
            "\n" ..
            "Fractional values will be rounded down. A negative value for this setting has a special function: it means there will be no cap to barter gold.\n" ..
            "\n" ..
            "Default: -1 (i.e. no cap)",
        variable = mwse.mcm.createTableVariable{
            id = "cap",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = -1,
        restartRequired = true,
    }

    return page
end

local function createBlacklistPage(template)
    template:createExclusionsPage{
        label = "Blacklist",
        description = "This page can be used to blacklist specific merchants. Blacklisted merchants' barter gold will not be affected by this mod. Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted merchants",
        rightListLabel = "Merchants",
        variable = mwse.mcm.createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            { callback = blacklist },
        },
    }
end

local template = mwse.mcm.createTemplate("Barter Gold Adjuster")
template:saveOnClose("BarterGoldAdjuster", config)

createPage(template)
createBlacklistPage(template)

mwse.mcm.register(template)