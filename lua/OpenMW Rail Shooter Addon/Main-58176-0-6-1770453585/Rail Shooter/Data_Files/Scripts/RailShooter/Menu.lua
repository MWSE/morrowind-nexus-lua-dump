local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = 'RailShooterSettingsPage',
    l10n = 'RailShooterSettings',
    name = 'Rail Shooter  Settings',
    description = 'Rail Shooter settings.',
}


input.registerAction {
	key = 'Shoot',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RailShooterControls',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'ShootJ2',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RailShooterControls',
	name = '',
	description = '',
	defaultValue = false,
}


input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RailShooterSettings',
    key = "Start",
})

input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RailShooterSettings',
    key = "StartJ2",
})

input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RailShooterSettings',
    key = "ReloadJ2",
})


I.Settings.registerGroup {
    key = 'RailShootercontrols',
    page = 'RailShooterSettingsPage',
    l10n = 'RailShooterSettings',
    name = 'RailShooter controls',
    description = 'Configuration of controls for RailShooter.',
    permanentStorage = true,
    settings = {
        {
            key = "Start",
            renderer = "inputBinding",
            name = "Start key",
            description = 'Start key',
            default = "s",
            argument = {
                type = "trigger",
                key = "Start"
        	},
		},
        {
            key = "Shoot",
            renderer = "inputBinding",
            name = "Shoot",
            description = "Key to shoot",
            default = "0",
            argument = {
                type = "action",
                key = "Shoot"
        	},
		},
        {
            key = "StartJ2",
            renderer = "inputBinding",
            name = "Start key for Player2",
            description = 'Start key for Player 2',
            default = "d",
            argument = {
                type = "trigger",
                key = "StartJ2"
        	},
		},
        {
            key = "ShootJ2",
            renderer = "inputBinding",
            name = "ShootJ2",
            description = "Key to shoot for player 2",
            default = "9",
            argument = {
                type = "action",
                key = "ShootJ2"
        	},
		},
        {
            key = 'Lifes',
            renderer = 'select',
            name = 'Lifes',
            description = 'Number of lifes starting the game with',
            default = "3",
			argument={disabled = false, l10n = 'LocalizationContext', items={"1","3","5","7"}},
        },
        {
            key = 'Credits',
            renderer = 'select',
            name = 'Credits',
            description = 'Number of credits starting the game with',
            default = "3",
			argument={disabled = false, l10n = 'LocalizationContext', items={"1","3","5","10","15"}},
        },

   	},
}

