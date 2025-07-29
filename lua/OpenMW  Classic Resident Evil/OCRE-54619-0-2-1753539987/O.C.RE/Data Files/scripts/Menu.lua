local menu=require('openmw.menu')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')


local Saves={}
local SaveChecked=0


I.Settings.registerPage {
    key = 'RESettingsPage',
    l10n = 'RESettings',
    name = 'O.C.RE Settings',
    description = 'O.C.RE Settings.',
}

I.Settings.registerGroup {
    key = 'RESettings1',
    page = 'RESettingsPage',
    l10n = 'RESettings',
    name = 'Edit RE settings',
    description = 'Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'AutoAim',
            renderer = 'checkbox',
            name = 'AutoAim',
            description = 'Target ennemie or attack objects when targeting',
            default = true,
			argument={trueLabel = "Auto",falseLabel = "Manual"},
        },
        {
            key = 'Dodge',
            renderer = 'checkbox',
            name = 'Dodge',
            description = 'Ability to dodge (RE3)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'Drop',
            renderer = 'checkbox',
            name = 'Drop',
            description = 'Ability to drop object from the inventory (RE0)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'Reload',
            renderer = 'checkbox',
            name = 'Reload',
            description = 'Ability to reload weapon (draw weapon+run)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'FixedCamera',
            renderer = 'select',
            name = 'FixedCamera',
            description = 'Play with fixed cameras',
            default = "Yes",
			argument={disabled = false, l10n = 'LocalizationContext', items={"Yes","No for 3D Rooms","No for all Rooms"}},
        },
        {
            key = 'Check',
            renderer = 'checkbox',
            name = 'Check',
            description = 'How to check objects',
            default = true,
			argument={trueLabel = "RE1/RECV",falseLabel = "RE2/RE3"},
        },
        {
            key = 'PSXShader',
            renderer = 'checkbox',
            name = 'PSXShader',
            description = '',
            default = false,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'DoorTransition',
            renderer = 'checkbox',
            name = 'Door Transition',
            description = 'Door transition when activating a door',
            default = true,
			argument={trueLabel = "RE door transition",falseLabel = "Fade in / out"},
        },
    },
}





input.registerAction {
	key = 'R1',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'R2',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'L1',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'L2',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Up',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Down',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Cross',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Square',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Circle',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}


input.registerTrigger({
    name = "",
    description = '',
    l10n = 'Playercontrols',
    key = "Triangle",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'Playercontrols',
    key = "NextWeapon",
})







I.Settings.registerGroup {
    key = 'Controles',
    page = 'RESettingsPage',
    l10n = 'Controls',
    name = 'Controls',
    description = 'Configuration of controls.',
    permanentStorage = true,
    settings = {

        {
            key = "ButtonR1",
            renderer = "inputBinding",
            name = "Button R1",
            description = '-Draw weapon (locate ennemies only)\n-Navigate in menus (maps, containers)',
            default = "k",
            argument = {
                type = "action",
                key = "R1"
        	},
		},
        {
            key = "ButtonR2",
            renderer = "inputBinding",
            name = "Button R2",
            description = '-Draw weapon (locate targetable objects).',
            default = "l",
            argument = {
                type = "action",
                key = "R2"
        	},
		},
		{
            key = "ButtonL1",
            renderer = "inputBinding",
            name = "Button L1",
            description = '-Change Target\n-Dodge\n-Navigate in menus (maps, containers)',
            default = "h",
            argument = {
                type = "action",
                key = "L1"
            }
        },
		{
            key = "ButtonL2",
            renderer = "inputBinding",
            name = "Button L2",
            description = '-Acces Map screen',
            default = "m",
            argument = {
                type = "action",
                key = "L2"
            }
        },
        {
            key = "ButtonUp",
            renderer = "inputBinding",
            name = "Button Up",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "z",
            argument = {
                type = "action",
                key = "Up"
        	},
		},
        {
            key = "ButtonDown",
            renderer = "inputBinding",
            name = "Button Down",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "s",
            argument = {
                type = "action",
                key = "Down"
        	},
		},
        {
            key = "ButtonRight",
            renderer = "inputBinding",
            name = "Button Right",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "d",
            argument = {
                type = "action",
                key = "Right"
        	},
		},
        {
            key = "ButtonLeft",
            renderer = "inputBinding",
            name = "Button Left",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "q",
            argument = {
                type = "action",
                key = "Left"
        	},
		},
        {
            key = "ButtonCross",
            renderer = "inputBinding",
            name = "Button Cross",
            description = '-Action/Attack/Open doors',
            default = "j",
            argument = {
                type = "action",
                key = "Cross"
        	},
		},
        {
            key = "ButtonSquare",
            renderer = "inputBinding",
            name = "Button Square",
            description = '-Run. \n-Quick 180° turn (hold + press directional button / Left Stick)\n-Reload (with weapon drawn)',
            default = "n",
            argument = {
                type = "action",
                key = "Square"
        	},
		},
		{
            key = "ButtonCircle",
            renderer = "inputBinding",
            name = "Button Circle",
            description = '-Acces Statut Screen',
            default = "i",
            argument = {
                type = "action",
                key = "Circle"
            }
        },
		{
            key = "ButtonTriangle",
            renderer = "inputBinding",
            name = "Button Triangle",
            description = '-Cancel previous action',
            default = "u",
            argument = {
                type = "trigger",
                key = "Triangle"
            }
        },
		{
            key = "ButtonNextWeapon",
            renderer = "inputBinding",
            name = "Button Next Weapon",
            description = '-Equip Next Weapon',
            default = "y",
            argument = {
                type = "trigger",
                key = "NextWeapon"
            }
        },

   	},
}



local function AskSaves(data)
		for j, saves in pairs(menu.getAllSaves()) do
			for k, save in pairs(saves) do
				SaveChecked=SaveChecked+1
				if SaveChecked==11 then
					core.sendGlobalEvent('ReceiveSaves',{saves=Saves})
					SaveChecked=0
					--break
				else
					Saves[SaveChecked]={}
					Saves[SaveChecked]["directory"]=j
					Saves[SaveChecked]["slotName"]=k
					Saves[SaveChecked]["description"]=save.description
					--print(Saves[SaveChecked]["description"])
				end
			end
		end
		if SaveChecked<10 then
			for i=(SaveChecked+1),10 do
				Saves[i]={}
				Saves[i]["description"]="No Data"
				--print(Saves[i]["description"])
				if i==10 then
					--print(Saves[11])
					core.sendGlobalEvent('ReceiveSaves',{saves=Saves})
					SaveChecked=0
					break
				end
			end
		end
end

local function Save(data)
	menu.saveGame(data.value,data.value)
end

local function Load()

end

local function deleteSave(data)
	menu.deleteGame(data.directory, data.slotName)
end


return {
	eventHandlers = {AskSaves=AskSaves, Save=Save, Load=Load, deleteSave=deleteSave},

}


