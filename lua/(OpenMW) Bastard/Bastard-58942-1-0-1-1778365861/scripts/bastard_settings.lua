-- Bastard - Settings page

local I      = require('openmw.interfaces')
local shared = require('scripts.bastard_shared')
local D      = shared.DEFAULTS

I.Settings.registerPage {
    key         = 'BastardOutlander',
    l10n        = 'BastardOutlander',
    name        = 'page_name',
    description = 'page_desc',
}

I.Settings.registerGroup {
    key              = 'SettingsBastardGeneral',
    page             = 'BastardOutlander',
    l10n             = 'BastardOutlander',
    name             = 'group_general_name',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'MOD_ENABLED',
            renderer    = 'checkbox',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            default     = D.MOD_ENABLED,
        },
        {
            key         = 'PLAY_VOICELINES',
            renderer    = 'checkbox',
            name        = 'play_voicelines_name',
            description = 'play_voicelines_desc',
            default     = D.PLAY_VOICELINES,
        },
        {
            key         = 'SIMPLE_MODE',
            renderer    = 'checkbox',
            name        = 'simple_mode_name',
            description = 'simple_mode_desc',
            default     = D.SIMPLE_MODE,
        },
        {
            key         = 'GUARD_WITNESS_RADIUS',
            renderer    = 'number',
            name        = 'guard_witness_radius_name',
            description = 'guard_witness_radius_desc',
            default     = D.GUARD_WITNESS_RADIUS,
            argument    = { integer = true, min = 0, max = 5000 },
        },
        {
            key         = 'LOG',
            renderer    = 'checkbox',
            name        = 'log_name',
            description = 'log_desc',
            default     = D.LOG,
        },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsBastardFormulas',
    page             = 'BastardOutlander',
    l10n             = 'BastardOutlander',
    name             = 'group_formulas_name',
    permanentStorage = true,
    order            = 2,
    settings = {
        {
            key         = 'THEFT_BOUNTY_BONUS',
            renderer    = 'number',
            name        = 'theft_bounty_bonus_name',
            description = 'theft_bounty_bonus_desc',
            default     = D.THEFT_BOUNTY_BONUS,
            argument    = { integer = true, min = 0, max = 1000 },
        },
        {
            key         = 'FATIGUE_WEIGHT',
            renderer    = 'number',
            name        = 'fatigue_weight_name',
            description = 'fatigue_weight_desc',
            default     = D.FATIGUE_WEIGHT,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'LEVEL_DIFF_WEIGHT',
            renderer    = 'number',
            name        = 'level_diff_weight_name',
            description = 'level_diff_weight_desc',
            default     = D.LEVEL_DIFF_WEIGHT,
            argument    = { integer = true, min = 0, max = 20 },
        },
        {
            key         = 'LEVEL_DIFF_CAP',
            renderer    = 'number',
            name        = 'level_diff_cap_name',
            description = 'level_diff_cap_desc',
            default     = D.LEVEL_DIFF_CAP,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'COMBAT_DIVISOR',
            renderer    = 'number',
            name        = 'combat_divisor_name',
            description = 'combat_divisor_desc',
            default     = D.COMBAT_DIVISOR,
            argument    = { integer = true, min = 1, max = 20 },
        },
        {
            key         = 'SOCIAL_DIVISOR',
            renderer    = 'number',
            name        = 'social_divisor_name',
            description = 'social_divisor_desc',
            default     = D.SOCIAL_DIVISOR,
            argument    = { integer = true, min = 1, max = 20 },
        },
        {
            key         = 'RANK_FIGHT_BONUS_PER_RANK',
            renderer    = 'number',
            name        = 'rank_fight_per_rank_name',
            description = 'rank_fight_per_rank_desc',
            default     = D.RANK_FIGHT_BONUS_PER_RANK,
            argument    = { integer = true, min = 0, max = 20 },
        },
        {
            key         = 'RANK_FIGHT_BONUS_CAP',
            renderer    = 'number',
            name        = 'rank_fight_cap_name',
            description = 'rank_fight_cap_desc',
            default     = D.RANK_FIGHT_BONUS_CAP,
            argument    = { integer = true, min = 0, max = 100 },
        },
    },
}

I.Settings.registerGroup {
    key              = 'SettingsBastardLoot',
    page             = 'BastardOutlander',
    l10n             = 'BastardOutlander',
    name             = 'group_loot_name',
    permanentStorage = true,
    order            = 3,
    settings = {
        {
            key         = 'VALUABLES_MIN',
            renderer    = 'number',
            name        = 'valuables_min_name',
            description = 'valuables_min_desc',
            default     = D.VALUABLES_MIN,
            argument    = { integer = true, min = 0, max = 10 },
        },
        {
            key         = 'VALUABLES_MAX',
            renderer    = 'number',
            name        = 'valuables_max_name',
            description = 'valuables_max_desc',
            default     = D.VALUABLES_MAX,
            argument    = { integer = true, min = 0, max = 10 },
        },
        {
            key         = 'DROP_GEAR_CHANCE',
            renderer    = 'number',
            name        = 'drop_gear_chance_name',
            description = 'drop_gear_chance_desc',
            default     = D.DROP_GEAR_CHANCE,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'SHOW_LOOT_SUMMARY',
            renderer    = 'checkbox',
            name        = 'show_loot_summary_name',
            description = 'show_loot_summary_desc',
            default     = D.SHOW_LOOT_SUMMARY,
        },
    },
}