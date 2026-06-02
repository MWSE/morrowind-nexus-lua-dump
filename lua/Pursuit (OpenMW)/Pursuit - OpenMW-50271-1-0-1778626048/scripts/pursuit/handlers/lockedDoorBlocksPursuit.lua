local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local l10n = core.l10n("pursuit", "en")
---------------------------------------------------------------------------------------------
local thisHandler = {}
---------------------------------------------------------------------------------------------
thisHandler.name = "lockedDoorBlocksPursuit"
---------------------------------------------------------------------------------------------
function thisHandler:fn(data)
    local settings = storage.globalSection("Settings!_PursuitExtra_!")
    if not settings:get("lockedDoorBlocksPursuit") then return true end
    return not doorLocked(data.doorToTargetCell)
    -- local hasKey = actorHasKeyForDoor(data.pursuer, data.doorToTargetCell)
end
---------------------------------------------------------------------------------------------
thisHandler.settings = {
    {
        key = "lockedDoorBlocksPursuit",
        renderer = "checkbox",
        name = l10n("settings_group2_setting4_name"),
        description = l10n("settings_group2_setting4_desc"),
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    },
}
---------------------------------------------------------------------------------------------
return thisHandler
