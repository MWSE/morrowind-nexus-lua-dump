local I = require("openmw.interfaces")
local core = require("openmw.core")
local modInfo = require("scripts.roaming_creeper.modInfo")
local l10n = core.l10n("roaming_creeper")

I.Settings.registerPage {
    key = 'roaming_creeper',
    l10n = 'roaming_creeper',
    name = 'settings_modName',
    description = l10n('settings_modDesc'):format(modInfo.MOD_VERSION)
}



return {
    eventHandlers = {
        RoamingCreeper_debug_eqnx = function(cell)
            require("openmw.ui").showMessage("[Debug Roaming Creeper] " .. cell)
        end
    }
}
