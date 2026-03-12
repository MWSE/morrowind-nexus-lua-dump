local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key              = 'SettingsNMEH',
    page             = 'NoMoreExcessiveHealing',
    l10n             = 'NoMoreExcessiveHealing',
    name             = 'settings_groupName',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'MOD_ENABLED',
            name        = 'mod_enabled_name',
            description = 'mod_enabled_desc',
            renderer    = 'checkbox',
            default     = true,
        },
        {
            key         = 'HP_RESTORE',
            name        = 'hp_restore_name',
            description = 'hp_restore_desc',
            renderer    = 'checkbox',
            default     = true,
        },
        {
            key         = 'HEAL_THRESHOLD',
            name        = 'heal_threshold_name',
            description = 'heal_threshold_desc',
            renderer    = 'number',
            default     = 10,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'HP_PENALTY',
            name        = 'hp_penalty_name',
            description = 'hp_penalty_desc',
            renderer    = 'number',
            default     = 1,
            argument    = { integer = true, min = 1, max = 50 },
        },
        {
            key         = 'MIN_BASE_HP',
            name        = 'min_base_hp_name',
            description = 'min_base_hp_desc',
            renderer    = 'number',
            default     = 1,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'DAMAGE_THRESHOLD',
            name        = 'damage_threshold_name',
            description = 'damage_threshold_desc',
            renderer    = 'number',
            default     = 10,
            argument    = { integer = true, min = 1, max = 100 },
        },
        {
            key         = 'ATTR_PENALTY',
            name        = 'attr_penalty_name',
            description = 'attr_penalty_desc',
            renderer    = 'number',
            default     = 3,
            argument    = { integer = true, min = 1, max = 20 },
        },
        {
            key         = 'PERSONALITY_PENALTY',
            name        = 'personality_penalty_name',
            description = 'personality_penalty_desc',
            renderer    = 'number',
            default     = 6,
            argument    = { integer = true, min = 1, max = 20 },
        },
    }
}

I.Settings.registerGroup {
    key              = 'SettingsNMEH_CE',
    page             = 'NoMoreExcessiveHealing',
    l10n             = 'NoMoreExcessiveHealing',
    name             = 'ce_groupName',
    permanentStorage = true,
    order            = 2,
    settings = {
        {
            key         = 'CE_IGNORE',
            name        = 'ce_ignore_name',
            description = 'ce_ignore_desc',
            renderer    = 'checkbox',
            default     = true,
        },
        {
            key         = 'CE_INTERVAL',
            name        = 'ce_interval_name',
            description = 'ce_interval_desc',
            renderer    = 'number',
            default     = 10,
            argument    = { integer = true, min = 5, max = 60 },
        },
    }
}

I.Settings.registerGroup {
    key              = 'SettingsNMEH_Wisdom',
    page             = 'NoMoreExcessiveHealing',
    l10n             = 'NoMoreExcessiveHealing',
    name             = 'wisdom_groupName',
    permanentStorage = true,
    order            = 3,
    settings = {
        {
            key         = 'WISDOM_ENABLED',
            name        = 'wisdom_enabled_name',
            description = 'wisdom_enabled_desc',
            renderer    = 'checkbox',
            default     = false,
        },
        {
            key         = 'WISDOM_CHANCE',
            name        = 'wisdom_chance_name',
            description = 'wisdom_chance_desc',
            renderer    = 'number',
            default     = 30,
            argument    = { integer = true, min = 0, max = 100 },
        },
        {
            key         = 'WISDOM_GAIN',
            name        = 'wisdom_gain_name',
            description = 'wisdom_gain_desc',
            renderer    = 'number',
            default     = 1,
            argument    = { integer = true, min = 1, max = 10 },
        },
    }
}

I.Settings.registerGroup {
    key              = 'SettingsNMEH_Recovery',
    page             = 'NoMoreExcessiveHealing',
    l10n             = 'NoMoreExcessiveHealing',
    name             = 'recovery_groupName',
    permanentStorage = true,
    order            = 4,
    settings = {
        {
            key         = 'RECOVERY_ENABLED',
            name        = 'recovery_enabled_name',
            description = 'recovery_enabled_desc',
            renderer    = 'checkbox',
            default     = false,
        },
        {
            key         = 'RECOVERY_PARTIAL',
            name        = 'recovery_partial_name',
            description = 'recovery_partial_desc',
            renderer    = 'checkbox',
            default     = false,
        },
        {
            key         = 'RECOVERY_DAYS',
            name        = 'recovery_days_name',
            description = 'recovery_days_desc',
            renderer    = 'number',
            default     = 7,
            argument    = { integer = true, min = 1, max = 365 },
        },
    }
}