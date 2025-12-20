local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsBruteForce_onHit',
    page = 'BruteForce',
    l10n = 'BruteForce',
    name = 'onHit_group_name',
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
            key = 'unlockWithBrokenWeapon',
            name = 'unlockWithBrokenWeapon_name',
            description = 'unlockWithBrokenWeapon_description',
            renderer = 'checkbox',
            default = false,
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
        {
            key = 'damageOnH2hMisses',
            name = 'damageOnH2hMisses_name',
            description = 'damageOnH2hMisses_description',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBruteForce_onUnlock',
    page = 'BruteForce',
    l10n = 'BruteForce',
    name = 'onUnlock_group_name',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'enableXpReward',
            name = 'enableXpReward_name',
            description = 'enableXpReward_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'damageContents',
            name = 'damageContents_name',
            description = 'damageContents_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'weaponWearModifier',
            name = 'weaponWearModifier_name',
            description = 'weaponWearModifier_description',
            renderer = 'number',
            integer = false,
            default = 10,
            min = 0,
        },
        {
            key = 'enableWeaponWearAgainstBentLocks',
            name = 'enableWeaponWearAgainstBentLocks_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'bounty',
            name = 'bounty_name',
            description = 'bounty_description',
            renderer = 'number',
            integer = true,
            default = 500,
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
            key = 'enableMisses',
            name = 'enableMisses_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableMessages',
            name = 'enableMessages_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'ignoreBentLocks',
            name = 'ignoreBentLocks_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}