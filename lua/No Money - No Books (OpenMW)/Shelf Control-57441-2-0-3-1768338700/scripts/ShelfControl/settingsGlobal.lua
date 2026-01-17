local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsShelfControl_buyable',
    page = 'ShelfControl',
    l10n = 'ShelfControl_settings',
    name = 'buyable_groupName',
    description = 'buyable_groupDescription',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'supress',
            name = 'supressBuyable_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'minDisposition',
            name = 'buyableMinimumDisposition_name',
            description = 'buyableMinimumDisposition_description',
            renderer = 'number',
            integer = true,
            default = 101,
            min = 1,
            max = 101,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsShelfControl_owned',
    page = 'ShelfControl',
    l10n = 'ShelfControl_settings',
    name = 'owned_groupName',
    description = 'owned_groupDescription',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'supress',
            name = 'supressOwned_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'minDisposition',
            name = 'ownedMinimumDisposition_name',
            description = 'ownedMinimumDisposition_description',
            renderer = 'number',
            integer = true,
            default = 80,
            min = 1,
            max = 101,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsShelfControl_misc',
    page = 'ShelfControl',
    l10n = 'ShelfControl_settings',
    name = 'misc_groupName',
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'modEnabled',
            name = 'modEnabled_name',
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
            key = 'enableCellWhitelist',
            name = 'enableCellWhitelist_name',
            description = 'enableCellWhitelist_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'ignoreBooksWithMWScripts',
            name = 'ignoreBooksWithMWScripts_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'ignoreScrolls',
            name = 'ignoreScrolls_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'enableDebug',
            name = 'enableDebug_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
