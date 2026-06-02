local I        = require('openmw.interfaces')
local shared   = require('scripts.npcschedule_shared')
local DEFAULTS = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'NPCSchedule',
    l10n        = 'NPCSchedule',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsNPCSchedule',
    page             = 'NPCSchedule',
    l10n             = 'NPCSchedule',
    name             = 'settings_group',
    permanentStorage = true,
    settings = {
        {
            key = 'HARD_RESET', renderer = 'checkbox',
            name = 'hard_reset_name', description = 'hard_reset_desc',
            default = DEFAULTS.HARD_RESET,
        },
        {
            key = 'GO_HOME_BAD_WEATHER', renderer = 'checkbox',
            name = 'go_home_bad_weather_name', description = 'go_home_bad_weather_desc',
            default = DEFAULTS.GO_HOME_BAD_WEATHER,
        },
        {
            key = 'WEATHER_CHECK_INTERVAL', renderer = 'number',
            name = 'weather_check_interval_name', description = 'weather_check_interval_desc',
            default = DEFAULTS.WEATHER_CHECK_INTERVAL,
            argument = { integer = true, min = 5, max = 120 },
        },
        {
            key = 'NIGHT_START', renderer = 'number',
            name = 'night_start_name', description = 'night_start_desc',
            default = DEFAULTS.NIGHT_START,
            argument = { integer = true, min = 18, max = 23 },
        },
        {
            key = 'NIGHT_END', renderer = 'number',
            name = 'night_end_name', description = 'night_end_desc',
            default = DEFAULTS.NIGHT_END,
            argument = { integer = true, min = 6, max = 10 },
        },
        {
            key = 'DOOR_SCAN_RANGE', renderer = 'number',
            name = 'door_scan_range_name', description = 'door_scan_range_desc',
            default = DEFAULTS.DOOR_SCAN_RANGE,
            argument = { integer = true, min = 3000, max = 10000 },
        },
        {
            key = 'FAR_TELEPORT_DIST', renderer = 'number',
            name = 'far_teleport_dist_name', description = 'far_teleport_dist_desc',
            default = DEFAULTS.FAR_TELEPORT_DIST,
            argument = { integer = true, min = 3000, max = 100000 },
        },
        {
            key = 'DOOR_ARRIVAL_DIST', renderer = 'number',
            name = 'door_arrival_dist_name', description = 'door_arrival_dist_desc',
            default = DEFAULTS.DOOR_ARRIVAL_DIST,
            argument = { integer = true, min = 100, max = 400 },
        },
        {
            key = 'CHECK_INTERVAL', renderer = 'number',
            name = 'check_interval_name', description = 'check_interval_desc',
            default = DEFAULTS.CHECK_INTERVAL,
            argument = { integer = false, min = 1, max = 10 },
        },
        {
            key = 'MAX_SAFE_OCCUPANTS', renderer = 'number',
            name = 'max_safe_occupants_name', description = 'max_safe_occupants_desc',
            default = DEFAULTS.MAX_SAFE_OCCUPANTS,
            argument = { integer = true, min = 1, max = 20 },
        },
        {
            key = 'MAX_DELAY', renderer = 'number',
            name = 'max_delay_name', description = 'max_delay_desc',
            default = DEFAULTS.MAX_DELAY,
            argument = { integer = true, min = 1, max = 120 },
        },
        {
            key = 'MORNING_BATCH_SIZE', renderer = 'number',
            name = 'morning_batch_size_name', description = 'morning_batch_size_desc',
            default = DEFAULTS.MORNING_BATCH_SIZE,
            argument = { integer = true, min = 1, max = 50 },
        },
        {
            key = 'MORNING_BATCH_DELAY', renderer = 'number',
            name = 'morning_batch_delay_name', description = 'morning_batch_delay_desc',
            default = DEFAULTS.MORNING_BATCH_DELAY,
            argument = { integer = false, min = 1, max = 5.0 },
        },
{
            key = 'ENABLE_DOOR_SOUNDS', renderer = 'checkbox',
            name = 'enable_door_sounds_name',
            description = 'enable_door_sounds_desc',
            default = DEFAULTS.ENABLE_DOOR_SOUNDS,
        },
        {
            key = 'DOOR_SOUND_COOLDOWN', renderer = 'number',
            name = 'door_sound_cooldown_name',
            description = 'door_sound_cooldown_desc',
            default = DEFAULTS.DOOR_SOUND_COOLDOWN,
            argument = { integer = false, min = 0.1, max = 5.0 },
        },
        {
            key = 'UNLOCK_HOME_DOORS', renderer = 'checkbox',
            name = 'unlock_home_doors_name', description = 'unlock_home_doors_desc',
            default = DEFAULTS.UNLOCK_HOME_DOORS,
        },
        {
            key = 'EXCLUDE_TRAVEL_CLASSES', renderer = 'checkbox',
            name = 'exclude_travel_classes_name', description = 'exclude_travel_classes_desc',
            default = DEFAULTS.EXCLUDE_TRAVEL_CLASSES,
        },
        {
            key = 'CITY_WHITELIST', renderer = 'checkbox',
            name = 'city_whitelist_name', description = 'city_whitelist_desc',
            default = DEFAULTS.CITY_WHITELIST,
        },
        {
            key = 'ENABLE_SHOP_VISITS', renderer = 'checkbox',
            name = 'enable_shop_visits_name', description = 'enable_shop_visits_desc',
            default = DEFAULTS.ENABLE_SHOP_VISITS,
        },
        {
            key = 'SHOP_VISIT_CHANCE', renderer = 'number',
            name = 'shop_visit_chance_name', description = 'shop_visit_chance_desc',
            default = DEFAULTS.SHOP_VISIT_CHANCE,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key = 'ENABLE_TEMPLE_VISITS', renderer = 'checkbox',
            name = 'enable_temple_visits_name', description = 'enable_temple_visits_desc',
            default = DEFAULTS.ENABLE_TEMPLE_VISITS,
        },
        {
            key = 'TEMPLE_VISIT_CHANCE', renderer = 'number',
            name = 'temple_visit_chance_name', description = 'temple_visit_chance_desc',
            default = DEFAULTS.TEMPLE_VISIT_CHANCE,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key = 'SHOP_VISIT_START', renderer = 'number',
            name = 'shop_visit_start_name', description = 'shop_visit_start_desc',
            default = DEFAULTS.SHOP_VISIT_START,
            argument = { integer = true, min = 6, max = 16 },
        },
        {
            key = 'SHOP_VISIT_END', renderer = 'number',
            name = 'shop_visit_end_name', description = 'shop_visit_end_desc',
            default = DEFAULTS.SHOP_VISIT_END,
            argument = { integer = true, min = 12, max = 22 },
        },
        {
            key = 'ENABLE_LOGS', renderer = 'checkbox',
            name = 'enable_logs_name', description = 'enable_logs_desc',
            default = DEFAULTS.ENABLE_LOGS,
        },
    },
}