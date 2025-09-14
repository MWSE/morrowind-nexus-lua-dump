local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'NoMoneyNoBooks_settings',
    page = 'NoMoneyNoBooks',
    l10n = 'NoMoneyNoBooks',
    name = 'settings_groupName',
    permanentStorage = true,
    settings = {
        {
            key = 'mode',
            name = 'mode_name',
            description = 'mode_description',
            renderer = 'select',
            argument = {
                l10n = "NoMoneyNoBooks",
                items = {
                    "None",
                    "Only buyable",
                    "Any owned",
                },
            },
            default = "Only buyable"
        },
        {
            key = 'showMessages',
            name = 'showMessages_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}