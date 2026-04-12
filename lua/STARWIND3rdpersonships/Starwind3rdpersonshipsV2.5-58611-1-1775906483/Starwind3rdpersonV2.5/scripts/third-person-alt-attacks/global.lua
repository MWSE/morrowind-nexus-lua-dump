local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsThirdPersonAltAttacksVFX',
    page = 'third-person-alt-attacks',
    l10n = 'ThirdPersonAltAttacksVFX',
    name = 'VFX',
    description = '',
    permanentStorage = true,
    settings = {
        {
            key = 'disable-vfx-for-1st-person',
            default = false,
            renderer = 'checkbox',
            name = 'Disable spell VFX for 1st person',
            description = '',
        },
    },
}
