local core = require("openmw.core")
local self = require("openmw.self")
local I = require('openmw.interfaces')
local modInfo = require("scripts.transporter_lights.modInfo")
local l10n = core.l10n('transporter_lights')

I.Settings.registerPage {
    key = 'Transporter_Lights_KINDI',
    l10n = 'transporter_lights',
    name = 'settings_modName',
    description = l10n('settings_modDesc'):format(modInfo.MOD_VERSION)
}

return {
    engineHandlers = {
        onActive = function()
            assert(core.API_REVISION >= modInfo.MIN_API,
                string.format("[%s] mod requires OpenMW version 0.49 or newer!", modInfo.MOD_NAME))
        end
    }
}
