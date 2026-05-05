local I       = require('openmw.interfaces')
local shared  = require('scripts.nightpatrol_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'NightPatrol',
    l10n        = 'NightPatrol',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsNightPatrol',
    page             = 'NightPatrol',
    l10n             = 'NightPatrol',
    name             = 'settings_group',
    permanentStorage = true,
    settings = {
        {
            key     = 'MOD_ENABLED',
            renderer = 'checkbox',
            name    = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default = DEFAULTS.MOD_ENABLED,
        },
        {
            key     = 'DETECTION_RANGE',
            renderer = 'number',
            name    = 'detection_range_name',
            description = 'detection_range_desc',
            default = DEFAULTS.DETECTION_RANGE,
            argument = { integer = true, min = 100, max = 2000 },
        },
        {
            key     = 'DOOR_SCAN_RANGE',
            renderer = 'number',
            name    = 'door_scan_range_name',
            description = 'door_scan_range_desc',
            default = DEFAULTS.DOOR_SCAN_RANGE,
            argument = { integer = true, min = 500, max = 5000 },
        },
        {
            key     = 'NIGHT_START',
            renderer = 'number',
            name    = 'night_start_name',
            description = 'night_start_desc',
            default = DEFAULTS.NIGHT_START,
            argument = { integer = true, min = 18, max = 23 },
        },
        {
            key     = 'NIGHT_END',
            renderer = 'number',
            name    = 'night_end_name',
            description = 'night_end_desc',
            default = DEFAULTS.NIGHT_END,
            argument = { integer = true, min = 1, max = 10 },
        },
        {
            key     = 'STRAY_DISTANCE',
            renderer = 'number',
            name    = 'stray_distance_name',
            description = 'stray_distance_desc',
            default = DEFAULTS.STRAY_DISTANCE,
            argument = { integer = true, min = 100, max = 1000 },
        },
        {
            key     = 'DOOR_ARRIVAL_DIST',
            renderer = 'number',
            name    = 'door_arrival_dist_name',
            description = 'door_arrival_dist_desc',
            default = DEFAULTS.DOOR_ARRIVAL_DIST,
            argument = { integer = true, min = 100, max = 800 },
        },
        {
            key     = 'DOOR_STRAY_DIST',
            renderer = 'number',
            name    = 'door_stray_dist_name',
            description = 'door_stray_dist_desc',
            default = DEFAULTS.DOOR_STRAY_DIST,
            argument = { integer = true, min = 100, max = 500 },
        },
        {
            key     = 'CHAMELEON_THRESHOLD',
            renderer = 'number',
            name    = 'chameleon_threshold_name',
            description = 'chameleon_threshold_desc',
            default = DEFAULTS.CHAMELEON_THRESHOLD,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key     = 'SNEAK_THRESHOLD',
            renderer = 'number',
            name    = 'sneak_threshold_name',
            description = 'sneak_threshold_desc',
            default = DEFAULTS.SNEAK_THRESHOLD,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key     = 'DISPOSITION_THRESHOLD',
            renderer = 'number',
            name    = 'disposition_threshold_name',
            description = 'disposition_threshold_desc',
            default = DEFAULTS.DISPOSITION_THRESHOLD,
            argument = { integer = true, min = 0, max = 100 },
        },
        {
            key     = 'SIGN_COMPAT',
            renderer = 'checkbox',
            name    = 'sign_compat_name',
            description = 'sign_compat_desc',
            default = DEFAULTS.SIGN_COMPAT,
        },
    },
}