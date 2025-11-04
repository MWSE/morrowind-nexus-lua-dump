local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'ModernMehrunesRazor',
    l10n = 'ModernMehrunesRazor',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsModernMehrunesRazor_onInstakill',
    page = 'ModernMehrunesRazor',
    l10n = 'ModernMehrunesRazor',
    name = 'onInstakill_group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'showMessage',
            name = 'showMessage_name',
            description = 'showMessage_description',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'playSFX',
            name = 'playSFX_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}
