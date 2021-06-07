local mod = "Consistent Keys"
local version = "2.1.1"

local config = require("ConsistentKeys.config")
local data = require("ConsistentKeys.data")

local function keyList()
    local list = {}

    for _, dataKey in ipairs(data.keys) do
        list[#list + 1] = dataKey.id
    end

    return list
end

local function createMainPage(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod renames the keys in the game so they'll have a consistent naming scheme.\n" ..
            "\n" ..
            "Keys have been renamed such that their names start with \"Key, \". This means that all keys will now group together in the inventory, which is a definite improvement for convenience.\n" ..
            "\n" ..
            "The mod also sets the value and weight of all keys to zero, for consistency.",
    }

    page:createYesNoButton{
        label = "Enable mod",
        description =
            "Use this button to enable or disable the mod. This will require restarting Morrowind.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "enable",
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
        description = "This page can be used to blacklist specific keys. Blacklisted keys will not be renamed. Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted keys",
        rightListLabel = "Keys",
        variable = mwse.mcm.createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            {callback = keyList},
        },
    }
end

local template = mwse.mcm.createTemplate("Consistent Keys")
template:saveOnClose("ConsistentKeys", config)

createMainPage(template)
createBlacklistPage(template)

mwse.mcm.register(template)