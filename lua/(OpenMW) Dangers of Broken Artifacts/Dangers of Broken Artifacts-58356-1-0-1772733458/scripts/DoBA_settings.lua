local I       = require('openmw.interfaces')
local shared  = require('scripts.DoBA_shared')
local DEFAULTS = shared.DEFAULTS

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
            default     = true,
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