local mp = "scripts/MaxYari/animated_lanterns/"

local I = require('openmw.interfaces')

local SettingsHelper = require(mp .. "utils/settings_helper")


I.Settings.registerPage {
    key = 'AnimatedLanternsPage',
    l10n = 'AnimatedLanterns',
    name = 'Animated Lanterns and Signs',
    description = "They swing in the wind! For these settings to take effect - reload a save game.",
}

return {
 
}


