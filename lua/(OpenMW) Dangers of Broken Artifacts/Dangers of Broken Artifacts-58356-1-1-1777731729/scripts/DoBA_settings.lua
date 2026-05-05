local I       = require('openmw.interfaces')
local shared  = require('scripts.DoBA_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'DoBA',
    l10n        = 'DoBA',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsDoBA',
    page             = 'DoBA',
    l10n             = 'DoBA',
    name             = 'settings_group',
    permanentStorage = true,
    settings = {
        {
            key         = 'MOD_ENABLED',
            renderer    = 'checkbox',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default     = DEFAULTS.MOD_ENABLED,
        },
        {
            key         = 'FOLLOWER_ENABLED',
            renderer    = 'checkbox',
            name        = 'follower_enabled_name',
            description = 'follower_enabled_desc',
            default     = DEFAULTS.FOLLOWER_ENABLED,
        },
        {
            key         = 'SCAN_INTERVAL',
            renderer    = 'number',
            name        = 'scan_interval_name',
            description = 'scan_interval_desc',
            default     = DEFAULTS.SCAN_INTERVAL,
            argument    = {
                min     = 1,
                max     = 300,
                integer = true,
            },
        },
    },
}