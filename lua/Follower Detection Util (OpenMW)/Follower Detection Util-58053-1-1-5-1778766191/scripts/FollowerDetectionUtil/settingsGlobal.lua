local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsFollowerDetectionUtil_settings',
    page = 'FollowerDetectionUtil',
    l10n = 'FollowerDetectionUtil',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'checkFollowersEvery',
            name = 'checkFollowersEvery_name',
            renderer = 'number',
            integer = false,
            default = .2,
            min = .001,
        },
    }
}