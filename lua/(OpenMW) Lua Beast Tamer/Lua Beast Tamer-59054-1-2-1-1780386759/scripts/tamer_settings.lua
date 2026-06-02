local I      = require('openmw.interfaces')
local input  = require('openmw.input')
local shared = require('scripts.tamer_shared')
local D      = shared.DEFAULTS


I.Settings.registerPage {
    key         = 'Tamer',
    l10n        = 'Tamer',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsTamer',
    page             = 'Tamer',
    l10n             = 'Tamer',
    name             = 'settings_group_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'MOD_ENABLED',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            renderer    = 'checkbox',
            default     = D.MOD_ENABLED,
        },
        {
            key         = 'MAX_TAMED',
            name        = 'max_tamed_name',
            description = 'max_tamed_desc',
            renderer    = 'number',
            default     = D.MAX_TAMED,
            argument    = { integer = true, min = 1, max = 20 },
        },
        {
            key         = 'KNOCKOUT_ENABLED',
            name        = 'knockout_enabled_name',
            description = 'knockout_enabled_desc',
            renderer    = 'checkbox',
            default     = D.KNOCKOUT_ENABLED,
        },
        {
            key         = 'KNOCKOUT_DURATION',
            name        = 'knockout_duration_name',
            description = 'knockout_duration_desc',
            renderer    = 'number',
            default     = D.KNOCKOUT_DURATION,
            argument    = { integer = true, min = 3, max = 30 },
        },
        {
            key         = 'BLUNT_ONLY',
            name        = 'blunt_only_name',
            description = 'blunt_only_desc',
            renderer    = 'checkbox',
            default     = D.BLUNT_ONLY,
        },
        {
            key         = 'ALLOW_WAIT',
            name        = 'allow_wait_name',
            description = 'allow_wait_desc',
            renderer    = 'checkbox',
            default     = D.ALLOW_WAIT,
        },
        {
            key         = 'STAT_GAIN_PERCENT',
            name        = 'stat_gain_percent_name',
            description = 'stat_gain_percent_desc',
            renderer    = 'number',
            default     = D.STAT_GAIN_PERCENT,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'LOSE_DISTANCE',
            name        = 'lose_distance_name',
            description = 'lose_distance_desc',
            renderer    = 'number',
            default     = D.LOSE_DISTANCE,
            argument    = { integer = true, min = 1000, max = 50000 },
        },
        {
            key         = 'TOOLTIP_ENABLED',
            name        = 'tooltip_enabled_name',
            description = 'tooltip_enabled_desc',
            renderer    = 'checkbox',
            default     = D.TOOLTIP_ENABLED,
        },
        {
            key         = 'FULL_MESSAGE',
            name        = 'full_message_name',
            description = 'full_message_desc',
            renderer    = 'checkbox',
            default     = D.FULL_MESSAGE,
        },
        {
            key         = 'RENAME_ON_TAME',
            name        = 'rename_on_tame_name',
            description = 'rename_on_tame_desc',
            renderer    = 'checkbox',
            default     = D.RENAME_ON_TAME,
        },
        {
            key         = 'SWAP_ACTIONS',
            name        = 'swap_actions_name',
            description = 'swap_actions_desc',
            renderer    = 'checkbox',
            default     = D.SWAP_ACTIONS,
        },
        {
            key         = 'ENABLE_LOGS',
            name        = 'enable_logs_name',
            description = 'enable_logs_desc',
            renderer    = 'checkbox',
            default     = D.ENABLE_LOGS,
        },
    },
}