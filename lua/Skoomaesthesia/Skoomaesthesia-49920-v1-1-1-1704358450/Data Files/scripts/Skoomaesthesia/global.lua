local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsSkoomaesthesia_Addiction',
    page = 'Skoomaesthesia',
    l10n = 'Skoomaesthesia',
    name = 'addictionGroupName',
    permanentStorage = false,
    settings = {
        {
            key = 'withdrawalIntensity',
            name = 'withdrawalIntensity_name',
            description = 'withdrawalIntensity_description',
            renderer = 'number',
            default = 20,
            argument = {
                min = 0,
            },
        },
        {
            key = 'hoursToWithdrawal',
            name = 'hoursToWithdrawal_name',
            description = 'hoursToWithdrawal_description',
            renderer = 'number',
            default = 2 * 24,
            argument = {
                min = 1,
            },
        },
        {
            key = 'hoursToRecovery',
            name = 'hoursToRecovery_name',
            description = 'hoursToRecovery_description',
            renderer = 'number',
            default = 5 * 24,
            argument = {
                min = 1,
            },
        },
        {
            key = 'baseChance',
            name = 'baseChance_name',
            description = 'baseChance_description',
            renderer = 'number',
            default = 1,
            argument = {
                min = 0,
                max = 1,
            },
        },
        {
            key = 'minResistance',
            name = 'minResistance_name',
            description = 'minResistance_description',
            renderer = 'number',
            default = 1,
            argument = {
                min = 1,
            },
        },
        {
            key = 'maxResistance',
            name = 'maxResistance_name',
            description = 'maxResistance_description',
            renderer = 'number',
            default = 5,
            argument = {
                min = 1,
            },
        },
    }
}
