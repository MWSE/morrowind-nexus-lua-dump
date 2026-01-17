local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsLuckyStrike_settings',
    page = 'LuckyStrike',
    l10n = 'LuckyStrike',
    name = 'settings_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'baseHpCritMult',
            name = 'baseHpCritMult_name',
            renderer = 'number',
            integer = false,
            default = 3,
            min = 0,
        },
        {
            key = 'baseFatCritMult',
            name = 'baseFatCritMult_name',
            renderer = 'number',
            integer = false,
            default = 3,
            min = 0,
        },
        {
            key = 'baseMagCritMult',
            name = 'baseMagCritMult_name',
            renderer = 'number',
            integer = false,
            default = 3,
            min = 0,
        },
    }
}