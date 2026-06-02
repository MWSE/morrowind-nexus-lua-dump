local I        = require('openmw.interfaces')
local shared   = require('scripts.prayer_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'Prayer',
    l10n        = 'PrayingA',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'Settings_Prayer_General',
    page             = 'Prayer',
    l10n             = 'PrayingA',
    name             = 'settings_group_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'DELAY',
            name        = 'delay_name',
            description = 'delay_desc',
            renderer    = 'number',
            default     = DEFAULTS.DELAY,
            argument    = { min = 0.0, max = 10.0 },
        },
        {
            key         = 'DURATION',
            name        = 'duration_name',
            description = 'duration_desc',
            renderer    = 'number',
            default     = DEFAULTS.DURATION,
            argument    = { min = 0.5, max = 30.0 },
        },
        {
            key         = 'SHRINE_ACTIVATOR',
            name        = 'shrine_activator_name',
            description = 'shrine_activator_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.SHRINE_ACTIVATOR,
        },
        {
            key         = 'ALLOW_IMPERIAL',
            name        = 'allow_imperial_name',
            description = 'allow_imperial_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.ALLOW_IMPERIAL,
        },
        {
            key         = 'ALLOW_DAEDRA',
            name        = 'allow_daedra_name',
            description = 'allow_daedra_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.ALLOW_DAEDRA,
        },
        {
            key         = 'MURMUR_SOUND',
            name        = 'murmur_sound_name',
            description = 'murmur_sound_desc',
            renderer    = 'checkbox',
            default     = DEFAULTS.MURMUR_SOUND,
        },
        {
            key         = 'VOLUME',
            name        = 'volume_name',
            description = 'volume_desc',
            renderer    = 'number',
            default     = DEFAULTS.VOLUME,
            argument    = { min = 0, max = 400 }, 
        },
    }
}