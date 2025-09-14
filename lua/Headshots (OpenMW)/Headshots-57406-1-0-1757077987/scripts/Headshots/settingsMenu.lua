local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'Headshots',
    l10n = 'Headshots',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsHeadshots_onHeadshot',
    page = 'Headshots',
    l10n = 'Headshots',
    name = 'onHeadshot_group_name',
    order = 3,
    permanentStorage = true,
    settings = {
        {
            key = 'showMessage',
            name = 'showMessage_name',
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
