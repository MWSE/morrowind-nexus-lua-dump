local config = require("ConsistentKeys.config")
local data = require("ConsistentKeys.data")
local modInfo = require("ConsistentKeys.modInfo")
local common = require("ConsistentKeys.common")

local titles = {
    overall = "Overall",
    names = "Names",
}

local blacklistDescription = {
    overall = "Blacklisted keys will not be touched by this mod at all.",
    names = "Blacklisted keys will not have their names changed by this mod (though any other enabled mod features will still be applied to them).",
}

local function blacklist()
    local list = {}

    for object in tes3.iterateObjects(tes3.objectType.miscItem) do
        if common.checkValidObject(object)
        and common.checkKey(object) then
            table.insert(list, object.id:lower())
        end
    end

    table.sort(list)
    return list
end

local function createMainPage(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod renames the keys in the game so they'll have a consistent naming scheme.\n" ..
            "\n" ..
            "Keys have been renamed such that their names start with \"Key, \". This means that all keys will now group together in the inventory, which is a definite improvement for convenience. Word order has also been adjusted in some cases so that the most important word comes first, for better sorting.\n" ..
            "\n" ..
            "The mod also has a couple of other options to tweak keys for consistency and convenience.\n" ..
            "\n" ..
            "In addition to all vanilla keys, almost all keys added by mods should be detected as keys and treated as such by the mod.\n" ..
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
        label = "Rename keys",
        description =
            "Renames all keys so they'll have a consistent naming scheme. If this option is disabled, key names will not be modified.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "changeNames",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Truncate names over length limit",
        description =
            "Morrowind has a limit of 31 characters for object names, and will poop its diaper if we try to set a name longer than that. For vanilla keys, and for keys added by many mods specifically accounted for in this mod's data tables, this limit is not a problem: care has been taken to ensure all names specified by this mod are within the limit.\n" ..
            "\n" ..
            "However, for keys added by other mods (not in this mod's data tables), this limit can potentially be an issue. This mod dynamically renames such keys to (mostly) use the same format as it uses for vanilla keys, and it's possible that this dynamic renaming process will bring the name above 31 characters. This setting controls what to do in this circumstance.\n" ..
            "\n" ..
            "If this setting is enabled, the names of such keys will be truncated. Characters will be removed from the end of the name as needed to bring the name down to 31 characters.\n" ..
            "\n" ..
            "If this setting is disabled, such keys will simply keep their original names (and therefore might not sort along with other keys in the inventory).\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "truncateLong",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Set value/weight of keys to 0",
        description =
            "If this option is enabled, all keys will have their value and weight set to 0.\n" ..
            "\n" ..
            "In the Construction Set, the value of almost all keys is 300, but only those that don't open anything can actually be sold. This is a consistency change so you can no longer sell a handful of keys for good money while the rest are valueless. Also, two vanilla keys have a weight above 0, which is also lowered to 0 for consistency.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "weightValue",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Set isKey flag for all keys",
        description =
            "If this option is enabled, all keys will have the \"isKey\" flag set to true.\n" ..
            "\n" ..
            "In vanilla Morrowind, any misc item that is set to open a lock has the \"isKey\" flag set. The major consequences of this are that the Detect Key effect will detect the item as a key, and merchants will refuse to buy the item from you, even if they normally buy misc items.\n" ..
            "\n" ..
            "But there are many keys - slave keys, for example - that aren't technically flagged as keys because they don't open anything. This means that Detect Key won't detect them, and merchants will buy them.\n" ..
            "\n" ..
            "This option flags these items as keys, so they will behave like other keys in these respects. Now Detect Key will detect all keys, including slave keys.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "isKeyFlag",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    page:createYesNoButton{
        label = "Enable logging",
        description =
            "Enables extensive logging to mwse.log.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "logging",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    return page
end

local function createBlacklistPage(template, listType)
    template:createExclusionsPage{
        label = titles[listType] .. " Blacklist",
        description = "This page can be used to blacklist specific keys. " .. blacklistDescription[listType] .. " Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted keys",
        rightListLabel = "Keys",
        variable = mwse.mcm.createTableVariable{
            id = listType,
            table = config.blacklists,
        },
        filters = {
            { callback = blacklist },
        },
    }
end

local template = mwse.mcm.createTemplate("Consistent Keys")
template:saveOnClose("ConsistentKeys", config)

createMainPage(template)

for _, listType in ipairs(data.mcmListTypes) do
    createBlacklistPage(template, listType)
end

mwse.mcm.register(template)