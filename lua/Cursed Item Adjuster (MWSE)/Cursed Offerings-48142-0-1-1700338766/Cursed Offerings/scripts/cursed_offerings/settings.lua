local I = require('openmw.interfaces')
local l10n = require("openmw.core").l10n("cursed_offerings")
local modInfo = require("scripts.cursed_offerings.modInfo")
I.Settings.registerPage {
    key = 'cursed_offerings_KINDI',
    l10n = 'cursed_offerings',
    name = 'settings_modName',
    description = l10n('settings_modDesc'):format(modInfo.MOD_VERSION)
}
