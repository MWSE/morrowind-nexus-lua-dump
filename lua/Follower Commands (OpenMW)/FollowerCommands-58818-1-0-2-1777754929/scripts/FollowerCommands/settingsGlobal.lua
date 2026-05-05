local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsFollowerCommands_debug',
    page = 'FollowerCommands',
    l10n = 'FollowerCommands',
    name = 'debug_groupName',
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'enableMessages',
            name = 'enableMessages_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}