local I       = require('openmw.interfaces')
local shared  = require('scripts.vaults_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerGroup {
    key              = 'SettingsVaultsRestricted',
    page             = 'VaultsRestricted',
    l10n             = 'VaultsRestricted',
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
            key         = 'COUNTDOWN',
            renderer    = 'number',
            name        = 'countdown_name',
            description = 'countdown_desc',
            default     = DEFAULTS.COUNTDOWN,
            argument    = { integer = true, min = 1, max = 30 },
        },
        {
            key         = 'WITNESS_RADIUS',
            renderer    = 'number',
            name        = 'witness_radius_name',
            description = 'witness_radius_desc',
            default     = DEFAULTS.WITNESS_RADIUS,
            argument    = { integer = true, min = 100, max = 2000 },
        },
        {
            key         = 'BOUNTY_AMOUNT',
            renderer    = 'number',
            name        = 'bounty_amount_name',
            description = 'bounty_amount_desc',
            default     = DEFAULTS.BOUNTY_AMOUNT,
            argument    = { integer = true, min = 0, max = 5000 },
        },
        {
            key         = 'CHAMELEON_THRESHOLD',
            renderer    = 'number',
            name        = 'chameleon_threshold_name',
            description = 'chameleon_threshold_desc',
            default     = DEFAULTS.CHAMELEON_THRESHOLD,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'SNEAK_THRESHOLD',
            renderer    = 'number',
            name        = 'sneak_threshold_name',
            description = 'sneak_threshold_desc',
            default     = DEFAULTS.SNEAK_THRESHOLD,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'SIGN_COMPAT',
            renderer    = 'checkbox',
            name        = 'sign_compat_name',
            description = 'sign_compat_desc',
            default     = DEFAULTS.SIGN_COMPAT,
        },
    },
}