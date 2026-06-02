local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local l10n = core.l10n("pursuit", "en")
---------------------------------------------------------------------------------------------
local thisHandler = {}
---------------------------------------------------------------------------------------------
thisHandler.name = "vampireAvoidsDay"
---------------------------------------------------------------------------------------------
function thisHandler:fn(data)
    local settings = storage.globalSection("Settings!_PursuitExtra_!")
    local vampireAvoidsDay = settings:get("vampireAvoidsDay")

    if not vampireAvoidsDay
        or not isVampire(data.pursuer)
        or not cellIsExterior(data.target.cell)
        or not isDayTime()
    then
        return true
    end

    return false
end
---------------------------------------------------------------------------------------------
thisHandler.settings = {
    {
        key = "vampireAvoidsDay",
        renderer = "checkbox",
        name = l10n("settings_group2_setting3_name"),
        description = l10n("settings_group2_setting3_desc"),
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    },
}
---------------------------------------------------------------------------------------------
return thisHandler
