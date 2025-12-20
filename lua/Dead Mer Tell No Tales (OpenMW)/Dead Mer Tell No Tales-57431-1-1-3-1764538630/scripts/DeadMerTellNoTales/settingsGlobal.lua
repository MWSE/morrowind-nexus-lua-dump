local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsDeadMerTellNoTales_recording',
    page = 'DeadMerTellNoTales',
    l10n = 'DeadMerTellNoTales',
    name = 'recording_groupName',
    description = 'recording_groupDescription',
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'recordKilled',
            name = 'recordKilled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'recordDisabled',
            name = 'recordDisabled_name',
            description = 'recordDisabled_description',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsDeadMerTellNoTales_objectTypes',
    page = 'DeadMerTellNoTales',
    l10n = 'DeadMerTellNoTales',
    name = 'objectTypes_groupName',
    description = 'objectTypes_groupDescription',
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 'disownItems',
            name = 'disownItems_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'disownContainers',
            name = 'disownContainers_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'disownActivators',
            name = 'disownActivators_name',
            description = 'disownActivators_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'disownDoors',
            name = 'disownDoors_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsDeadMerTellNoTales_debug',
    page = 'DeadMerTellNoTales',
    l10n = 'DeadMerTellNoTales',
    name = 'debug_groupName',
    order = 100,
    permanentStorage = true,
    settings = {
        {
            key = 'debugEnabled',
            name = 'debugEnabled_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
