local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'SettingsPage_AR_AM',
    l10n = 'AlarmedMorrowind',
    name = 'SettingsPageName',
    description = 'SettingsPageDescription'
}

I.Settings.registerGroup {
    key = 'SettingsGroup_AR_AM',
    page = 'SettingsPage_AR_AM',
    l10n = 'AlarmedMorrowind',
    name = 'SettingsGroupName',
    description = 'SettingsGroupDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'EnableSetting',
            renderer = 'checkbox',
            name = 'EnableSettingName',
            description = 'EnableSettingDescription',
            default = true
        },
        {
            key = 'DebugSetting',
            renderer = 'checkbox',
            name = 'DebugSettingName',
            description = 'DebugSettingDescription',
            default = false
        },
        {
            key = 'UseBlacklistSetting',
            renderer = 'checkbox',
            name = 'UseBlacklistSettingName',
            description = 'UseBlacklistSettingDescription',
            default = true
        },
        {
            key = 'AlarmedSlavesSetting',
            renderer = 'checkbox',
            name = 'AlarmedSlavesSettingName',
            description = 'AlarmedSlavesSettingDescription',
            default = true
        },
        {
            key = 'AlarmValueSetting',
            renderer = 'select',
            name = 'AlarmValueSettingName',
            description = 'AlarmValueSettingDescription',
            default = 'AlarmValueSetting100',
            argument = {
                l10n = 'AlarmedMorrowind',
                items = {
                    'AlarmValueSetting90',
                    'AlarmValueSetting100'
                }
            }
        }
    }
}
