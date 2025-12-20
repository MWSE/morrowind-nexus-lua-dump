local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = 'WriteSettingsPage',
    l10n = 'WriteSettings',
    name = 'Write Books and Scrolls Settings',
    description = 'Write Books and Scrolls settings.',
}

input.registerAction {
	key = 'Write',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'WriteSettings',
	name = '',
	description = '',
	defaultValue = true,
}

I.Settings.registerGroup {
    key = 'Writecontrols',
    page = 'WriteSettingsPage',
    l10n = 'WriteSettings',
    name = 'Write Books and Scrolls controls',
    description = 'Configuration of controls for Write Books and Scrolls.',
    permanentStorage = true,
    settings = {
      
        {
            key = "ButtonWrite",
            renderer = "inputBinding",
            name = "Write",
            description = 'Keep the key pressed when using a book to write.',
            default = "u",
            argument = {
                type = "action",
                key = "Write"
        	},
		},
        
   	},
}




