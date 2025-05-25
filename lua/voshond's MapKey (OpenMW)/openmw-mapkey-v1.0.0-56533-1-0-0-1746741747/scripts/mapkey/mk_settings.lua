local core = require("openmw.core")
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

-- Create a settings section for our mod
local settings = storage.playerSection("SettingsMapKey")

-- Register a settings page for our mod
I.Settings.registerPage {
    key = "SettingsMapKey",
    l10n = "SettingsMapKey",
    name = "voshond's Map Hotkey",
    description = "Settings for the Map Hotkey mod."
}

-- Register settings group with our options
I.Settings.registerGroup {
    key = "SettingsMapKey",
    page = "SettingsMapKey",
    l10n = "SettingsMapKey",
    name = "Main Settings",
    permanentStorage = true,
    description = [[
    These settings allow you to modify the Map Hotkey mod.
    ]],
    settings = {
        {
            key = "enableDebugLogging",
            renderer = "checkbox",
            name = "Enable Debug Logging",
            description = "If enabled, debug messages will be shown in the console. Useful for troubleshooting but may impact performance.",
            default = false
        },
        {
            key = "mapHotkey",
            renderer = "inputBinding",
            name = "Map Hotkey",
            description = "Key binding to open the map.",
            default = "M",
            argument = {
                key = "OpenMap",
                type = "trigger"
            }
        },
        {
            key = "inventoryHotkey",
            renderer = "inputBinding",
            name = "Inventory Hotkey",
            description = "Key binding to open the inventory without the map.",
            default = "L",
            argument = {
                key = "OpenInventory",
                type = "trigger"
            }
        }
    },
}

return settings
