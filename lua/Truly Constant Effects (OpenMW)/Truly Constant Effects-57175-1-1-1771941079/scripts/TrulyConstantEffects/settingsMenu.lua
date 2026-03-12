local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'TrulyConstantEffects',
    l10n = 'TrulyConstantEffects_HUDSettings',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsTrulyConstantEffects',
    page = 'TrulyConstantEffects',
    l10n = 'TrulyConstantEffects_HUDSettings',
    name = 'group_name',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'reapplyInvis',
            name = 'reapplyInvis_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'reapplySummons',
            name = 'reapplySummons_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'cooldown',
            name = 'cooldown_name',
            description = "cooldown_desc",
            renderer = 'number',
            default = .2,
            min = 0,
        },
        {
            key = 'showMessages',
            name = 'showMessages_name',
            renderer = 'checkbox',
            default = false,
        },
    },
}
