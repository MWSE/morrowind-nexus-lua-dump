local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'BootsWearDown',
    l10n = 'BootsWearDown',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsBootsWearDown_settings',
    page = 'BootsWearDown',
    l10n = 'BootsWearDown',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'walkingWearPoints',
            name = 'walkingWearPoints_name',
            description = "walkingWearPoints_desc",
            renderer = 'number',
            default = .5,
        },
        {
            key = 'runningWearPoints',
            name = 'runningWearPoints_name',
            description = "runningWearPoints_desc",
            renderer = 'number',
            default = 1.5,
        },
        {
            key = 'jumpWearPoints',
            name = 'jumpWearPoints_name',
            renderer = 'number',
            default = 5,
        },
        {
            key = 'wearPointsPerDurability',
            name = 'wearPointsPerDurability_name',
            description = "wearPointsPerDurability_desc",
            renderer = 'number',
            default = 100,
        },
    }
}
