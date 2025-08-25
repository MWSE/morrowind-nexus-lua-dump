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
    settings = {
        {
            key = 'reapplyInvis',
            name = 'reapplyInvis_name',
            description = 'reapplyInvis_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'reapplySummons',
            name = 'reapplySummons_name',
            description = 'reapplySummons_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'showMessages',
            name = 'showMessages_name',
            description = 'showMessages_description',
            renderer = 'checkbox',
            default = false,
        },
    },
}