local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'ModPage',
    l10n = 'DaedraUseBoundEquipment',
    name = 'ModPageName',
    description = 'ModPageDescription'
}

I.Settings.registerGroup {
    key = 'SettingsGroup',
    page = 'ModPage',
    l10n = 'DaedraUseBoundEquipment',
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
        }
    }
}
