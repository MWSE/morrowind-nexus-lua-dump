local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key              = 'SettingsNWNB',
    page             = 'NoWitnessNoBounty',
    l10n             = 'NoWitnessNoBounty',
    name             = 'settings_group',
    permanentStorage = true,
    settings = {
        {
            key         = 'MOD_ENABLED',
            renderer    = 'checkbox',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default     = true,
        },
        {
            key         = 'DEBUG_ENABLED',
            renderer    = 'checkbox',
            name        = 'debug_enabled_name',
            description = 'debug_enabled_desc',
            default     = false,
        },
    },
}