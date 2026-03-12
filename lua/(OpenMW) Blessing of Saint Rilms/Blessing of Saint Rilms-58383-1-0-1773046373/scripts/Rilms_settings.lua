local I = require('openmw.interfaces')
I.Settings.registerPage {
    key         = 'BlessingRilms',
    l10n        = 'BlessingRilms',
    name        = 'page_name',
    description = 'page_desc',
}
I.Settings.registerGroup {
    key              = 'SettingsRilms',
    page             = 'BlessingRilms',
    l10n             = 'BlessingRilms',
    name             = 'settings_groupName',
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = 'DONATE_CHANCE',
            name        = 'donate_chance_name',
            description = 'donate_chance_desc',
            renderer    = 'number',
            default     = 0.01,
            argument    = { min = 0.01, max = 0.05 },
        },
        {
            key         = 'MAX_DONATIONS',
            name        = 'max_donations_name',
            description = 'max_donations_desc',
            renderer    = 'number',
            default     = 3,
            argument    = { integer = true, min = 1, max = 10 },
        },
    }
}