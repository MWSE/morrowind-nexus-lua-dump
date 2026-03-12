local I = require('openmw.interfaces')

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
            default     = true,
        },
        {
            key         = 'DAMAGE_TICK',
            name        = 'damage_tick_name',
            description = 'damage_tick_desc',
            renderer    = 'number',
            default     = 1,
            argument    = { min = 0.1, max = 10 },
        },
        {
            key         = 'BASE_DAMAGE',
            name        = 'base_damage_name',
            description = 'base_damage_desc',
            renderer    = 'number',
            default     = 5,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'BURN_RADIUS',
            name        = 'burn_radius_name',
            description = 'burn_radius_desc',
            renderer    = 'number',
            default     = 32,
            argument    = { integer = true, min = 1, max = 200 },
        },
        {
            key         = 'BURN_HEIGHT',
            name        = 'burn_height_name',
            description = 'burn_height_desc',
            renderer    = 'number',
            default     = 200,
            argument    = { integer = true, min = 1, max = 500 },
        },
    }
}