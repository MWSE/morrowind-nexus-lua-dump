local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'JustSimplyMagickaRegen',
    l10n = 'JustSimplyMagickaRegen',
    name = 'page_name',
    description = 'page_description',
})


I.Settings.registerGroup({
    key = 'SettingsJustSimplyMagickaRegen',
    page = 'JustSimplyMagickaRegen',
    l10n = 'JustSimplyMagickaRegen',
    name = "simple_settings",
    permanentStorage = false,
    settings = {
        {
            key = 'magicka_per_second',
            name = 'magicka_per_second_name',
            description = 'magicka_per_second_description',
            default = 0.5,
            renderer = 'number',
            argument = {
                min = 0,
                max = 10,
            },
        },
        {
            key = 'delay_before_regeneration',
            name = 'delay_before_regeneration_name',
            description = 'delay_before_regeneration_description',
            default = 0,
            renderer = 'number',
            argument = {
                min = 0,
                max = 100,
            },
        },
    },
})
