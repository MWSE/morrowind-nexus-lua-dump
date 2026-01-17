local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'HeartAttack',
    l10n = 'HeartAttack',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsHeartAttack_settings',
    page = 'HeartAttack',
    l10n = 'HeartAttack',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'deathChance',
            name = 'deathChance_name',
            description = "deathChance_desc",
            renderer = 'number',
            integer = true,
            default = 0,
            min = 0,
        },
    }
}
