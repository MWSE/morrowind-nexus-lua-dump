local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsFriendlierFire_settings',
    page = 'FriendlierFire',
    l10n = 'FriendlierFire',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'damageMult',
            name = 'damageMult_name',
            description = "damageMult_desc",
            renderer = 'number',
            integer = false,
            default = -1,
            min = -1,
        },
        {
            key = 'disableSpells',
            name = 'disableSpells_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'disableAggro',
            name = 'disableAggro_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'protectSummons',
            name = 'protectSummons_name',
            description = 'protectSummons_desc',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'commandDisablesProtection',
            name = 'commandDisablesProtection_name',
            description = 'commandDisablesProtection_desc',
            renderer = 'checkbox',
            default = true,
        },
    }
}
