local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'BACOSSettingsPage',
    l10n = 'BACOSSettings',
    name = 'BACOS  Settings',
    description = 'BACOS settings.',
}

I.Settings.registerGroup {
    key = 'BACOSGeneralSettings',
    page = 'BACOSSettingsPage',
    l10n = 'BACOSSettings',
    name = 'Bow And Crossbow On Strike general settings',
    description = 'BACOS general Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'OnlyOnstrike',
            renderer = 'checkbox',
            name = 'Use only on strike enchantments',
            description = "Allow the mod to use only on strike enchantments or on strike and on use enchantments. (on strike enchatments can't be created with Morrowind. You have to use the construction set or transfer enchantments with lua)",
            default = false,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
   	},
}
