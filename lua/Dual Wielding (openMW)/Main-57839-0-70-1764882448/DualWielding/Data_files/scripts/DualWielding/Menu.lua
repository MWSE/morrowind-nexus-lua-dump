local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = 'DualWieldingSettingsPage',
    l10n = 'DualWieldingsSettings',
    name = 'Dual Wielding  Settings',
    description = 'Dual Wielding settings.',
}

input.registerAction {
	key = 'EquipSecondWeapon',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'DualWieldingSettings',
	name = '',
	description = '',
	defaultValue = true,
}

I.Settings.registerGroup {
    key = 'DualWieldingscontrols',
    page = 'DualWieldingSettingsPage',
    l10n = 'DualWieldingSettings',
    name = 'Dual Wielding controls',
    description = 'Configuration of controls for Dual Wieldings.',
    permanentStorage = true,
    settings = {
      
        {
            key = "ButtonEquipSecondWeapon",
            renderer = "inputBinding",
            name = "EquipSecondWeapon",
            description = 'Keep the key pressed when equiping a weapon (one hand) to use it as a second weapon.',
            default = "u",
            argument = {
                type = "action",
                key = "EquipSecondWeapon"
        	},
		},
        
        {
            key = 'SecondWeaponUIX',
            renderer = 'number', 
            name = 'Second Weapon UI X size',
            description = 'The X size (in pixels) of the SecondWeapon UI.',
            default = '50',
        },
        
        {
            key = 'SecondWeaponUIY',
            renderer = 'number', 
            name = 'Second Weapon UI Y size',
            description = 'The X size (in pixels) of the SecondWeapon UI.',
            default = '50',
        },


   	},
}