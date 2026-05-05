local I = require('openmw.interfaces')
local S = require('scripts.fire_shared')

I.Settings.registerGroup {
    key              = 'SettingsFireDamage',
    page             = 'PlayerOnFire',
    l10n             = 'PlayerOnFire',
    name             = 'settings_groupName',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'MOD_ENABLED',
            renderer    = 'checkbox',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default     = S.DEFAULTS.MOD_ENABLED,
        },
        {
            key         = 'DAMAGE_TICK',
            name        = 'damage_tick_name',
            description = 'damage_tick_desc',
            renderer    = 'number',
            default     = S.DEFAULTS.DAMAGE_TICK,
            argument    = { min = 0.1, max = 10 },
        },
        {
            key         = 'BASE_DAMAGE',
            name        = 'base_damage_name',
            description = 'base_damage_desc',
            renderer    = 'number',
            default     = S.DEFAULTS.BASE_DAMAGE,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'BURN_RADIUS',
            name        = 'burn_radius_name',
            description = 'burn_radius_desc',
            renderer    = 'number',
            default     = S.DEFAULTS.BURN_RADIUS,
            argument    = { integer = true, min = 1, max = 200 },
        },
        {
            key         = 'BURN_HEIGHT',
            name        = 'burn_height_name',
            description = 'burn_height_desc',
            renderer    = 'number',
            default     = S.DEFAULTS.BURN_HEIGHT,
            argument    = { integer = true, min = 1, max = 500 },
        },
        {
            key         = 'ANIMATIONS_ENABLED',
            name        = 'animations_enabled_name',
            description = 'animations_enabled_desc',
            renderer    = 'checkbox',
            default     = S.DEFAULTS.ANIMATIONS_ENABLED,
        },
        {
            key         = 'PRINT_LOG',
            name        = 'print_log_name',
            description = 'print_log_desc',
            renderer    = 'checkbox',
            default     = S.DEFAULTS.PRINT_LOG,
        },
    }
}