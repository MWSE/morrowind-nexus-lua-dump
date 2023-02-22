local config = require("DesignedForWhom.config")

-- blocklistToggle, alwaysLog, showInGame, blocklist

local function createMainSettingsPage(template)

    local page = template:createSideBarPage({
        label = "General Settings",
        description = "Designed for Whom v1.0\nby C89C\n\nThis mod is intended to serve as both a debugging tool and a warning tool for players.\nIt logs instances where a player equips an item that doesn't appear to be adapted to their mesh.\nIt can also show an in game warning."
    })

    page:createOnOffButton({
        label = "Ignore Blocked Plugins?",
        description = "If enabled, objects and bodyParts from the list of blocked plugins will be skipped. Unless Always Log Information is enabled, this means no entry will be made in the log.",
        variable = mwse.mcm.createTableVariable{
            id = "blocklistToggle",
            table = config
        }
    })

    page:createOnOffButton({
        label = "Always Log Information?",
        description = "If enabled, we will add a log message about any skipped objects and bodyParts along with their source plugin. This does not show up in game.",
        variable = mwse.mcm.createTableVariable{
            id = "alwaysLog",
            table = config
        }
    })

    page:createOnOffButton({
        label = "Show in game toast notifications?",
        description = "If enabled, a messageBox will show in game warning you when you equip an item that may not match your body mesh. This message is meant for players and has no technical information.",
        variable = mwse.mcm.createTableVariable{
            id = "showInGame",
            table = config
        }
    })

    page:createOnOffButton({
        label = "Clean plugin blocklist on start?",
        description = "If enabled, the plugin blocklist will be purged of any unloaded plugins at start.",
        variable = mwse.mcm.createTableVariable{
            id = "cleanPlugins",
            table = config
        }
    })

    page:createOnOffButton({
        label = "Log into a separate log file?",
        description = "If enabled, all output will be logged to DesignedForWhom.log instead of mwse.log. Useful if you want to keep the warnings in one place. This takes effect immediately for any future logging calls.",
        variable = mwse.mcm.createTableVariable{
            id = "separateLog",
            table = config
        }
    })

end

local function createPluginBlocklistPage(template)

    template:createExclusionsPage{
        label = "Blocked Plugins List",
        description = "If Ignore Blocked Plugins is enabled, bodyParts and objects from the blocked plugins list will be ignored. If Always Log Information is enabled, you will still get a short message indicating what was skipped and where it came from.",
        leftListLabel = "Blocked Plugins",
        rightListLabel = "Currently Enabled Plugins",
        variable = mwse.mcm.createTableVariable{
            id = "blocklist",
            table = config
        },
        filters = {
            {
                label = "Plugins",
                type = "Plugin"
            }
        },
    }

end

local template = mwse.mcm.createTemplate("Designed For Whom")
template:saveOnClose("Designed For Whom", config)

createMainSettingsPage(template)
createPluginBlocklistPage(template)

mwse.mcm.register(template)