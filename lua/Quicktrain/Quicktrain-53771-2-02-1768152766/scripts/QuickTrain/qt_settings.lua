local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")

local bms = core.contentFiles.has("bms.omwscripts")

if core.API_REVISION < 68 then
    I.Settings.registerPage {
        key = "Quicktrain",
        l10n = "Quicktrain",
        name = "Quicktrain",
        description = "Quicktrain is enabled, but your engine version is too old. Please download a new version of OpenMW Develppment or 0.49+.(Newer than December 6, 2024)"
    }
    return
end
I.Settings.registerPage {
    key = "Quicktrain",
    l10n = "Quicktrain",
    name = "Quicktrain",
    description = "Quicktrain "
}
local replaceUI = {
            key = "enableTrainingUIReplace",
            renderer = "checkbox",
            name = "Enable Training UI Replacement",
            description =
            "If enabled, the mod will replace the training list UI with a menu with more information.",
            default = true
        }
if bms then
    replaceUI.description = "BetterMechantSkill conflicts with the replacement training UI, it has been disabled."
end

I.Settings.registerGroup {
    key = "SettingsQuicktrain",
    page = "Quicktrain",
    l10n = "Quicktrain",
    name = "Quicktrain",
    description = "",
    permanentStorage = true,
    settings = {
        replaceUI,
        {
            key = "trainingAttributeInfo",
            renderer = "select",
            name = "Free Placement Mode",
            default = "Free in God Mode",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = { "Don't show Attribute", "Show Attribute", "Show Attribute and Multiplier" },
            },
        },

    }
}