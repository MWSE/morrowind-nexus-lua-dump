local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'BruteForce',
    l10n = 'BruteForce',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsBruteForce_unlocking',
    page = 'BruteForce',
    l10n = 'BruteForce',
    name = 'unlocking_group_name',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'strBonus',
            name = 'strBonus_name',
            description = 'strBonus_description',
            renderer = 'number',
            integer = false,
            default = 25,
        },
        {
            key = 'jamChance',
            name = 'jamChance_name',
            description = 'jamChance_description',
            renderer = 'number',
            integer = false,
            default = .15,
            min = 0,
            max = 1,
        },
        {
            key = 'enableXpReward',
            name = 'enableXpReward_name',
            description = 'enableXpReward_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'damageContentsOnUnlock',
            name = 'damageContentsOnUnlock_name',
            description = 'damageContentsOnUnlock_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'damageOnH2h',
            name = 'damageOnH2h_name',
            description = 'damageOnH2h_description',
            renderer = 'number',
            integer = true,
            default = 7,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBruteForce_alerting',
    page = 'BruteForce',
    l10n = 'BruteForce',
    name = 'alerting_group_name',
    description = 'alerting_group_description',
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 'bounty',
            name = 'bounty_name',
            description = 'bounty_description',
            renderer = 'number',
            integer = true,
            default = 500,
            min = 0,
        },
        {
            key = 'losMaxDistBase',
            name = 'losMaxDistBase_name',
            renderer = 'number',
            integer = false,
            default = 1500,
            min = 0,
        },
        {
            key = 'losMaxDistSneakModifier',
            name = 'losMaxDistSneakModifier_name',
            renderer = 'number',
            integer = false,
            default = 7.5,
            min = 0,
        },
        {
            key = 'soundRangeBase',
            name = 'soundRangeBase_name',
            renderer = 'number',
            integer = false,
            default = 500,
            min = 0,
        },
        {
            key = 'soundRangeWeaponSkillModifier',
            name = 'soundRangeWeaponSkillModifier_name',
            renderer = 'number',
            integer = false,
            default = 1,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBruteForce_debug',
    page = 'BruteForce',
    l10n = 'BruteForce',
    name = 'debug_group_name',
    order = 100,
    permanentStorage = true,
    settings = {
        {
            key = 'modEnabled',
            name = 'modEnabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'alwaysHit',
            name = 'alwaysHit_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
