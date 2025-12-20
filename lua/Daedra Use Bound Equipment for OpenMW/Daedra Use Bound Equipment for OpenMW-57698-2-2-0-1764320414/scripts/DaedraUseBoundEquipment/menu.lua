local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'SettingsPage_AR_DUBE',
    l10n = 'DaedraUseBoundEquipment',
    name = 'SettingsPageName',
    description = 'SettingsPageDescription'
}

I.Settings.registerGroup {
    key = 'SettingsGroup_AR_DUBE',
    page = 'SettingsPage_AR_DUBE',
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
        },
        {
            key = 'UseBlacklistsSetting',
            renderer = 'checkbox',
            name = 'UseBlacklistsSettingName',
            description = 'UseBlacklistsSettingDescription',
            default = true
        },
        {
            key = 'RemoveEquipmentFromUniqueAndRareDaedraSetting',
            renderer = 'checkbox',
            name = 'RemoveEquipmentFromUniqueAndRareDaedraSettingName',
            description = 'RemoveEquipmentFromUniqueAndRareDaedraSettingDescription',
            default = false
        },
        {
            key = 'ChanceOfRemovingWeaponsSetting',
            renderer = 'number',
            name = 'ChanceOfRemovingWeaponsSettingName',
            description = 'ChanceOfRemovingWeaponsSettingDescription',
            default = 100,
            argument = {
                integer = true,
                min = 0,
                max = 100
            }
        },
        {
            key = 'ChanceOfRemovingThrowingWeaponsSetting',
            renderer = 'number',
            name = 'ChanceOfRemovingThrowingWeaponsSettingName',
            description = 'ChanceOfRemovingThrowingWeaponsSettingDescription',
            default = 100,
            argument = {
                integer = true,
                min = 0,
                max = 100
            }
        },
        {
            key = 'ChanceOfRemovingArrowsAndBoltsSetting',
            renderer = 'number',
            name = 'ChanceOfRemovingArrowsAndBoltsSettingName',
            description = 'ChanceOfRemovingArrowsAndBoltsSettingDescription',
            default = 0,
            argument = {
                integer = true,
                min = 0,
                max = 100
            }
        },
        {
            key = 'ChanceOfRemovingArmorSetting',
            renderer = 'number',
            name = 'ChanceOfRemovingArmorSettingName',
            description = 'ChanceOfRemovingArmorSettingDescription',
            default = 100,
            argument = {
                integer = true,
                min = 0,
                max = 100
            }
        }
    }
}
