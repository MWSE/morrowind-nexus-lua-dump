local I      = require('openmw.interfaces')
local input  = require('openmw.input') 
local shared = require('scripts.bh_shared')
local D      = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'BountyHunter',
    l10n        = 'BountyHunter',
    name        = 'page_name',
    description = 'page_desc',
}

input.registerTrigger {
    key  = 'ToggleFortStatus',
    l10n = 'BountyHunter',
}

I.Settings.registerGroup {
    key              = 'SettingsBH',
    page             = 'BountyHunter',
    l10n             = 'BountyHunter',
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
            key         = 'ESCAPE_CHANCE',
            name        = 'escape_chance_name',
            description = 'escape_chance_desc',
            renderer    = 'number',
            default     = D.ESCAPE_CHANCE,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'MIN_PRISONER_LEVEL',
            name        = 'min_prisoner_level_name',
            description = 'min_prisoner_level_desc',
            renderer    = 'number',
            default     = D.MIN_PRISONER_LEVEL,
            argument    = { integer = true, min = 1 },
        },
        {
            key         = 'SHOW_DEATH_TAUNT',
            name        = 'show_death_taunt_name',
            description = 'show_death_taunt_desc',
            renderer    = 'checkbox',
            default     = D.SHOW_DEATH_TAUNT,
        },
        {
            key         = 'SHOW_ALREADY_ESCORTING',
            name        = 'show_already_escorting_name',
            description = 'show_already_escorting_desc',
            renderer    = 'checkbox',
            default     = D.SHOW_ALREADY_ESCORTING,
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

I.Settings.registerGroup {
    key              = 'SettingsBHInput',
    page             = 'BountyHunter',
    l10n             = 'BountyHunter',
    name             = 'bh_input_name',
    permanentStorage = true,
    order            = 2,
    settings = {
        {
            key         = 'FORT_STATUS_KEY',
            renderer    = 'inputBinding',
            name        = 'fort_status_key_name',
            description = 'fort_status_key_desc',
            default     = 'bh_fort_status_binding',
            argument    = {
                type = 'trigger',
                key  = 'ToggleFortStatus',
            },
        },
    },
}