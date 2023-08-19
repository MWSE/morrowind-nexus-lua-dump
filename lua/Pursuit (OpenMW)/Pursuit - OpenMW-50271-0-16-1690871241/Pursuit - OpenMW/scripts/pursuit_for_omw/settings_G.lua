local I = require("openmw.interfaces")
local core = require("openmw.core")
local bL = require("scripts.pursuit_for_omw.blacklist")

I.Settings.registerGroup {
    key = "SettingsPursuitMain",
    page = "pursuit_for_omw",
    l10n = "pursuit_for_omw",
    name = "setings_modCategory1_name",
    permanentStorage = false,
    order = 0,
    settings = {
        {
            key = "Mod Status",
            renderer = "checkbox",
            name = "setings_modCategory1_setting1_name",
            description = "setings_modCategory1_setting1_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        },
        {
            key = "Pursue Time",
            renderer = "number",
            name = "setings_modCategory1_setting2_name",
            description = "setings_modCategory1_setting2_desc",
            default = 15
        },
        {
            key = "Creature Pursuit",
            renderer = "checkbox",
            name = "setings_modCategory1_setting3_name",
            description = "setings_modCategory1_setting3_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        },
        {
            key = "Navmesh Check",
            renderer = "checkbox",
            name = "setings_modCategory1_setting4_name",
            description = "setings_modCategory1_setting4_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        },
        {
            key = "Actor Return",
            renderer = "checkbox",
            name = "setings_modCategory1_setting6_name",
            description = "setings_modCategory1_setting6_desc",
            default = true,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        }
    }
}
I.Settings.registerGroup {
    key = "SettingsPursuitBlacklist",
    page = "pursuit_for_omw",
    l10n = "pursuit_for_omw",
    name = "setings_modCategory2_name",
    description = (function()
        local header = core.l10n("pursuit_for_omw")("setings_modCategory2_desc") .. "\n------------------\n"

        for actor in pairs(bL) do
            header = header .. string.format("%s", actor) .. "\n"
        end

        return header
    end)(),
    permanentStorage = false,
    order = 1,
    settings = {}
}
I.Settings.registerGroup {
    key = "SettingsPursuitDebug",
    page = "pursuit_for_omw",
    l10n = "pursuit_for_omw",
    name = "setings_modCategory3_name",
    permanentStorage = false,
    order = 2,
    settings = {
        {
            key = "Debug",
            renderer = "checkbox",
            name = "setings_modCategory3_setting1_name",
            description = "setings_modCategory3_setting1_desc",
            default = false,
            argument = {
                trueLabel = core.getGMST("sYes"),
                falseLabel = core.getGMST("sNo")
            }
        }
    }
}

