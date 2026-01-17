local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'TargetTheLeader',
    l10n = 'TargetTheLeader',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsTargetTheLeader_settings',
    page = 'TargetTheLeader',
    l10n = 'TargetTheLeader',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'ignoreSummons',
            name = 'ignoreSummons_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
