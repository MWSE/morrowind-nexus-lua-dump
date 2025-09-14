local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = 'PoisonWeaponsSettingsPage',
    l10n = 'PoisonWeaponsSettings',
    name = 'Poison Weapons  Settings',
    description = 'Poison Weapons settings.',
}

input.registerAction {
	key = 'ApplyPoison',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'PoisonWeaponsSettings',
	name = '',
	description = '',
	defaultValue = true,
}

I.Settings.registerGroup {
    key = 'PoisonWeaponscontrols',
    page = 'PoisonWeaponsSettingsPage',
    l10n = 'PoisonWeaponsSettings',
    name = 'Poison Weapons controls',
    description = 'Configuration of controls for Poiso nWeapons.',
    permanentStorage = true,
    settings = {
      
        {
            key = "ButtonApplyPoison",
            renderer = "inputBinding",
            name = "ApplyPoison",
            description = 'Keep the key pressed when consumming a potion or an ingredient to apply effects to equipped weapon.',
            default = "u",
            argument = {
                type = "action",
                key = "ApplyPoison"
        	},
		},
        
        {
            key = 'PoisonUIX',
            renderer = 'number', 
            name = 'Poison UI X size',
            description = 'The X size (in pixels) of the poison UI.',
            default = '50',
        },
        
        {
            key = 'PoisonUIY',
            renderer = 'number', 
            name = 'Poison UI Y size',
            description = 'The X size (in pixels) of the poison UI.',
            default = '50',
        },

   	},
}




