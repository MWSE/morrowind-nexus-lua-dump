local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'Backstabs',
    l10n = 'Backstabs',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsBackstabs_onBackstab',
    page = 'Backstabs',
    l10n = 'Backstabs',
    name = 'onBackstab_group_name',
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
