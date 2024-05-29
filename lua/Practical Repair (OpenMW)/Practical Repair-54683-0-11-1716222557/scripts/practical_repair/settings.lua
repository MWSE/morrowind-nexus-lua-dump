local I = require("openmw.interfaces")
local core = require("openmw.core")

I.Settings.registerGroup {
    key = "Settings_practical_repair_main_option",
    page = "practical_repair_main_page",
    l10n = "practical_repair",
    name = "setings_modCategory1_name",
    description = "",
    permanentStorage = true,
    settings = {{
        key = "Mod Status",
        renderer = "checkbox",
        name = "setings_modCategory1_setting1_name",
        description = "setings_modCategory1_setting1_desc",
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    }, {
        key = "Repair Boost",
        renderer = "checkbox",
        name = "setings_modCategory1_setting2_name",
        description = "setings_modCategory1_setting2_desc",
        default = false,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo"),
            disabled = false
        }
    }, {
        key = "Boost Amount",
        renderer = "number",
        name = "setings_modCategory1_setting3_name",
        description = "setings_modCategory1_setting3_desc",
        default = 0,
        argument = {
            disabled = false
        }
    }, {
        key = "Notification",
        renderer = "checkbox",
        name = "setings_modCategory1_setting4_name",
        description = "setings_modCategory1_setting4_desc",
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    }}
}
