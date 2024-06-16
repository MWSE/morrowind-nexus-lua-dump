local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local function NSS_OutOfDate()
    I.Settings.registerPage {
        key = "NoSneakySleeping",
        l10n = "NoSneakySleeping",
        name = "NoSneakySleeping",
        description = "NoSneakySleeping is enabled, but your engine version is too old. Please download a new version of OpenMW Develppment or 0.49+.(Newer than October 24, 2023)"
    }
end
if (core.API_REVISION < 50) then
   NSS_OutOfDate()
 error("Newer version of OpenMW is required")
end
return {
    eventHandlers = {
        NSS_showMessage = function(message)
            ui.showMessage(message)
        end,
        NSS_OutOfDate = NSS_OutOfDate,
        
    }
}
