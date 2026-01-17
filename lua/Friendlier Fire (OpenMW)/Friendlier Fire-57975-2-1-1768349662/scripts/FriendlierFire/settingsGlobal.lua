local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsFriendlierFire_playerToFollowers',
    page = 'FriendlierFire',
    l10n = 'FriendlierFire',
    name = 'playerToFollowers_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'hpDamageMultiplier',
            name = 'hpDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
        {
            key = 'fatDamageMultiplier',
            name = 'fatDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
        {
            key = 'magDamageMultiplier',
            name = 'magDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsFriendlierFire_followersToPlayer',
    page = 'FriendlierFire',
    l10n = 'FriendlierFire',
    name = 'followersToPlayer_groupName',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'hpDamageMultiplier',
            name = 'hpDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
        {
            key = 'fatDamageMultiplier',
            name = 'fatDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
        {
            key = 'magDamageMultiplier',
            name = 'magDamageMultiplier_name',
            renderer = 'number',
            integer = false,
            default = .33,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsFriendlierFire_other',
    page = 'FriendlierFire',
    l10n = 'FriendlierFire',
    name = 'other_groupName',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'disableAggro',
            name = 'disableAggro_name',
            description = "disableAggro_description",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'disableSpells',
            name = 'disableSpells_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}