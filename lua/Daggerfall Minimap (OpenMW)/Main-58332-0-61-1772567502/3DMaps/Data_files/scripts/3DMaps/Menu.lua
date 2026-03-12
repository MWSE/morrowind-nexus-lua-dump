local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = '3DMapWindowSettingsPage',
    l10n = '3DMapWindowSettings',
    name = '3DMap Window  Settings',
    description = '3DMap Window settings.',
}


input.registerTrigger({
    name = "",
    description = '',
    l10n = '3DMapWindowControls',
    key = "Open",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = '3DMapWindowControls',
    key = "ZoomIn",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = '3DMapWindowControls',
    key = "ZoomOut",
})

input.registerAction {
	key = 'RotateMap',
	type = input.ACTION_TYPE.Boolean,
	l10n = '3DMapWindowControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'MoveMap',
	type = input.ACTION_TYPE.Boolean,
	l10n = '3DMapWindowControls',
	name = '',
	description = '',
	defaultValue = true,
}

I.Settings.registerGroup {
    key = '3DMapWindowcontrols',
    page = '3DMapWindowSettingsPage',
    l10n = '3DMapWindowSettings',
    name = '3DMap Window controls',
    description = 'Configuration of controls for 3DMap.',
    permanentStorage = true,
    settings = {
 
        {
            key = "Open",
            renderer = "inputBinding",
            name = "Open/Close",
            description = "Open/Close the custom 3DMap window",
            default = "a",
            argument = {
                type = "trigger",
                key = "Open"
        	},
		},
        {
            key = "ZoomIn",
            renderer = "inputBinding",
            name = "ZoomIn",
            description = "Zoom in the custom 3DMap window",
            default = "^",
            argument = {
                type = "trigger",
                key = "ZoomIn"
        	},
		},
        {
            key = "ZoomOut",
            renderer = "inputBinding",
            name = "ZoomOut",
            description = "Zoom out the custom 3DMap window",
            default = "$",
            argument = {
                type = "trigger",
                key = "ZoomOut"
        	},
		},
        {
            key = "RotateMap",
            renderer = "inputBinding",
            name = "RotateMap",
            description = 'Kepp pressed while moving the mouse to rotate.',
            default = "u",
            argument = {
                type = "action",
                key = "RotateMap"
        	},
		},
        {
            key = "MoveMap",
            renderer = "inputBinding",
            name = "MoveMap",
            description = 'Kepp pressed while moving the mouse to move.',
            default = "i",
            argument = {
                type = "action",
                key = "MoveMap"
        	},
		},
        {
            key = 'Distance',
            renderer = 'number', 
            name = 'Distance detection',
            description = 'The distance for objects to appear in the map.',
            default = '1500',
        },
   	},
}

