local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'SneakFatigueDrain',
    l10n = 'SneakFatigueDrain',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsSneakFatigueDrain',
    page = 'SneakFatigueDrain',
    l10n = 'SneakFatigueDrain',
    name = 'settings_groupName',
    description = "settings_groupDesc",
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'baseDrain',
            name = 'baseDrain_name',
            renderer = 'number',
            default = 7.5,
        },
        {
            key = 'sneakMod',
            name = 'sneakMod_name',
            renderer = 'number',
            default = -.04,
        },
        {
            key = 'encumbranceMod',
            name = 'encumbranceMod_name',
            description = 'encumbranceMod_desc',
            renderer = 'number',
            default = 2,
        },
        {
            key = 'drainWhileNotMoving',
            name = 'drainWhileNotMoving_name',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = 'logging',
            name = 'logging_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}