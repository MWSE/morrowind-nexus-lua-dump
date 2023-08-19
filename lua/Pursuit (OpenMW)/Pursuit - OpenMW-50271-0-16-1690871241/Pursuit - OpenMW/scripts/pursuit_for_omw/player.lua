local core = require("openmw.core")
local ui = require("openmw.ui")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local modInfo = require("scripts.pursuit_for_omw.modInfo")

I.Settings.registerPage {
    key = "pursuit_for_omw",
    l10n = "pursuit_for_omw",
    name = "settings_modName",
    description = "settings_modDesc"
}

local function showMessage(_, ...)
    ui.showMessage(tostring(_):format(...))
end

return {
    engineHandlers = {
        onActive = function()
            assert(core.API_REVISION >= modInfo.MIN_API, "[Pursuit] mod requires OpenMW version 0.48 or newer!")
            self:sendEvent("Pursuit_IsInstalled_eqnx", {
                isInstalled = true
            })
        end
    },
    eventHandlers = {
        Pursuit_Debug_Pursuer_Details_eqnx = function(e)
            if storage.globalSection("SettingsPursuitDebug"):get("Debug") and e.target and e.target.type == types.Player then
                local far = e.canReachTarget and "Ok" or "Too far"
                local see = e.canSeeTarget and "Ok" or "No sight"
                local path = e.canPathTarget and "Ok" or "No path"
                showMessage("\"%s[%s]\" chases \"%s[%s]\"\nStatus:\nDist: %s[%.1f]\nSight: %s\nPath: %s\nTime: %.1f", e.actor.recordId, e.actor.cell.name,
                e.target.recordId, e.target.cell.name, far, e.distance, see, path, e.delay)
            end
        end
    }
}
