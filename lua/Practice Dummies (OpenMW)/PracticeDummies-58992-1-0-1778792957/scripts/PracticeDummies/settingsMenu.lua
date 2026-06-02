local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'PracticeDummies',
    l10n = 'PracticeDummies',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsPracticeDummies',
    page = 'PracticeDummies',
    l10n = 'PracticeDummies',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'maxHits',
            name = 'maxHits_name',
            description = 'maxHits_desc',
            renderer = 'number',
            integer = true,
            default = 10,
            min = -1,
        },
        {
            key = 'cooldown',
            name = 'cooldown_name',
            renderer = 'number',
            integer = false,
            default = 24,
            min = 0,
        },
        {
            key = 'skillGain',
            name = 'skillGain_name',
            description = 'skillGain_desc',
            renderer = 'number',
            integer = false,
            default = 0,
            min = 0,
        },
        {
            key = 'scale',
            name = 'scale_name',
            description = 'scale_desc',
            renderer = 'number',
            integer = false,
            default = 2,
            min = 0,
        },
        {
            key = 'maxSkill',
            name = 'maxSkill_name',
            renderer = 'number',
            integer = true,
            default = 50,
            min = 0,
        },
    }
}