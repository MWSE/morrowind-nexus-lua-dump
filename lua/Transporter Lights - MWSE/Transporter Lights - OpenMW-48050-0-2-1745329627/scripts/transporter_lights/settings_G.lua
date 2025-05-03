local I = require("openmw.interfaces")
local core = require("openmw.core")

I.Settings.registerGroup {
    key = "Settings_Transporter_Lights_Options_Key_KINDI",
    page = "Transporter_Lights_KINDI",
    l10n = "transporter_lights",
    name = "setings_modCategory1_name",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "Mod Status",
            renderer = "checkbox",
            name = "setings_modCategory1_setting1_name",
            description = "setings_modCategory1_setting1_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo"),
                disabled = not next(require("scripts.transporter_lights.constants").lights)
            }
        },
        {
            key = "Alternate Lights",
            renderer = "select", -- probably better to use custom renderer, select looks broken until refreshed; issue #8451
            name = "setings_modCategory1_setting2_name",
            description = "setings_modCategory1_setting2_desc",
            default = "randomize",
            argument = {
                l10n = "transporter_lights",
                items = {
                    core.getGMST("sOff"),
                    "randomize",
                    "cycle"
                },
                disabled = not next(require("scripts.transporter_lights.constants").alternateLights)
            }
        },
        {
            key = "Debug",
            renderer = "checkbox",
            name = "setings_modCategory1_setting3_name",
            description = "setings_modCategory1_setting3_desc",
            default = false,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        }
    }
}
