local I      = require('openmw.interfaces')
local shared  = require('scripts.necro_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerGroup {
    key              = 'SettingsNecro',
    page             = 'IllegalNecromancy',
    l10n             = 'IllegalNecromancy',
    name             = 'settings_groupName',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'MOD_ENABLED',
            renderer    = 'checkbox',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default     = DEFAULTS.MOD_ENABLED,
        },
        {
            key         = 'FACTION_EXEMPT_ENABLED',
            renderer    = 'checkbox',
            name        = 'faction_exempt_enabled_name',
            description = 'faction_exempt_enabled_desc',
            default     = DEFAULTS.FACTION_EXEMPT_ENABLED,
        },
        {
            key         = 'SNEAK_THRESHOLD',
            name        = 'sneak_threshold_name',
            description = 'sneak_threshold_desc',
            renderer    = 'number',
            default     = DEFAULTS.SNEAK_THRESHOLD,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'CHAMELEON_THRESHOLD',
            name        = 'chameleon_threshold_name',
            description = 'chameleon_threshold_desc',
            renderer    = 'number',
            default     = DEFAULTS.CHAMELEON_THRESHOLD,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'WITNESS_RADIUS',
            name        = 'witness_radius_name',
            description = 'witness_radius_desc',
            renderer    = 'number',
            default     = DEFAULTS.WITNESS_RADIUS,
            argument    = { integer = true, min = 100, max = 2000 },
        },
        {
            key         = 'SIGN_COMPAT',
            renderer    = 'checkbox',
            name        = 'sign_compat_name',
            description = 'sign_compat_desc',
            default     = DEFAULTS.SIGN_COMPAT,
        },
    }
}