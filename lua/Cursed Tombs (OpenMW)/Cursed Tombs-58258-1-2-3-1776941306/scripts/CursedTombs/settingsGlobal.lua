local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsCursedTombs_checks',
    page = 'CursedTombs',
    l10n = 'CursedTombs',
    name = 'checks_groupName',
    description = 'checks_groupDesc',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'minBaseSafeChance',
            name = 'minBaseSafeChance_name',
            renderer = 'number',
            default = 70,
        },
        {
            key = 'maxBaseSafeChance',
            name = 'maxBaseSafeChance_name',
            renderer = 'number',
            default = 75,
        },
        {
            key = 'luckModifier',
            name = 'luckModifier_name',
            renderer = 'number',
            default = .1,
        },
        {
            key = 'agilityModifier',
            name = 'agilityModifier_name',
            renderer = 'number',
            default = .1,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsCursedTombs_revenants',
    page = 'CursedTombs',
    l10n = 'CursedTombs',
    name = 'revenants_groupName',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'spawnDistance',
            name = 'spawnDistance_name',
            renderer = 'number',
            default = 300,
            min = 0,
        },
        {
            key = 'useLeveledLists',
            name = 'useLeveledLists_name',
            description = 'useLeveledLists_desc',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'minRevenantCount',
            name = 'minRevenantCount_name',
            renderer = 'number',
            default = 1,
            min = 1,
        },
        {
            key = 'maxRevenantCount',
            name = 'maxRevenantCount_name',
            renderer = 'number',
            default = 3,
            min = 1,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsCursedTombs_other',
    page = 'CursedTombs',
    l10n = 'CursedTombs',
    name = 'other_groupName',
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'enableMessages',
            name = 'enableMessages_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableSfx',
            name = 'enableSfx_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}
