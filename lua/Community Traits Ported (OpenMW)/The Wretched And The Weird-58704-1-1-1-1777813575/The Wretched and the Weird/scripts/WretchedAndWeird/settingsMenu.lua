local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'WretchedAndWeird',
    l10n = 'WretchedAndWeird',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsWretchedAndWeird_drunk',
    page = 'WretchedAndWeird',
    l10n = 'WretchedAndWeird',
    name = 'drunk_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'drunkTime',
            name = 'drunkTime_name',
            description = 'drunkTime_desc',
            renderer = 'number',
            default = 8,
        },
        {
            key = 'recoveryTime',
            name = 'recoveryTime_name',
            description = 'recoveryTime_desc',
            renderer = 'number',
            default = 7.5,
        },
    }
}
