local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local l10n = core.l10n('SmartInterfaceMenuOpening')
local versionString = "1.0.0"

-- inputSelection inspired by Pharis
I.Settings.registerRenderer(
	"inputSelection",
	function(value, set)
		local name = "No Key Set"
		if value then
			name = input.getKeyName(value)
		end
		return {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true
            },
			content = ui.content {
                {
                    type = ui.TYPE.Container,
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textEditLine,
                            props = {
                                text = name,
                            },
                            events = {
                                keyPress = async:callback(function(e)
                                    if e.code == input.KEY.Escape then return end
                                    set(e.code)
                                end),
                            },
                        },                                                                        
                    }
                },
                {
                    type = ui.TYPE.Widget,
                    template = I.MWUI.templates.interval
                },
                {
                    type = ui.TYPE.Widget,
                    template = I.MWUI.templates.interval
                },
                {
                    type = ui.TYPE.Widget,
                    template = I.MWUI.templates.interval
                },
                {
                    type = ui.TYPE.Container,
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textNormal,
                            props = {
                                text = " Use Tab ",
                            },
                            events = {
                                mousePress = async:callback(function(e)
                                    set(input.KEY.Tab)
                                end),
                            },
                        }				
                    }
                },
			},            
		}
	end
)

-- Settings page
I.Settings.registerPage {
    key = 'SmartInterfaceMenuOpening',
    l10n = 'SmartInterfaceMenuOpening',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}

I.Settings.registerGroup {
    key = 'Settings/SmartInterfaceMenuOpening/KeyBindings/Atoms',
    page = 'SmartInterfaceMenuOpening',
    l10n = 'SmartInterfaceMenuOpening',
    name = 'ConfigKeybindingsAtoms',
    description = "ConfigKeybindingsAtomsDesc",
    permanentStorage = true,
    settings = {        
        {
            key = 's_Key_Inventory',
            renderer = 'inputSelection',            
            name = 'Key_Inventory',
            description = 'Inventory',
            default = 0,
        },
        {
            key = 's_Key_Map',
            renderer = 'inputSelection',            
            name = 'Key_Map',
            description = 'Map',
            default = 0,
        },
        {
            key = 's_Key_Magic',
            renderer = 'inputSelection',            
            name = 'Key_Magic',
            description = 'Magic',
            default = 0,
        },
        {
            key = 's_Key_Stats',
            renderer = 'inputSelection',            
            name = 'Key_Stats',
            description = 'Stats',
            default = 0,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/SmartInterfaceMenuOpening/KeyBindings/Switch',
    page = 'SmartInterfaceMenuOpening',
    l10n = 'SmartInterfaceMenuOpening',
    name = 'ConfigKeybindingsSwitch',
    permanentStorage = true,
    settings = {        
        {
            key = 's_Key_Switch',
            renderer = 'inputSelection',            
            name = 'Key_Switch',
            description = 'Switch',
            default = 0,
        },
        {
            key = 's_Switch_Order',
            renderer = 'textLine',
            name = 'Switch_Order',
            description = 'SwitchOrder',            
            default = 'Map-Inventory-Magic-Stats',
        },
        {
            key = 'b_Switch_Loop',
            renderer = 'checkbox',            
            name = 'Switch_Loop',
            description = 'SwitchLoop',
            default = true,
        },
    },
}

I.Settings.registerGroup {
    key = 'Settings/SmartInterfaceMenuOpening/PauseMenu',
    page = 'SmartInterfaceMenuOpening',
    l10n = 'SmartInterfaceMenuOpening',
    name = 'ConfigPauseMenus',
    description = 'ConfigPauseMenusDesc',
    permanentStorage = true,
    settings = {                
        {
            key = 'b_Pause_Inventory',
            renderer = 'checkbox',            
            name = 'Pause_Inventory',
            default = true,
        },
        {
            key = 'b_Pause_Map',
            renderer = 'checkbox',            
            name = 'Pause_Map',
            default = true,
        },
        {
            key = 'b_Pause_Magic',
            renderer = 'checkbox',            
            name = 'Pause_Magic',
            default = true,
        },
        {
            key = 'b_Pause_Stats',
            renderer = 'checkbox',            
            name = 'Pause_Stats',
            default = true,
        },
        {
            key = 'b_Pause_Journal',
            renderer = 'checkbox',            
            name = 'Pause_Journal',
            default = true,
        },
        {
            key = 'b_Pause_Book',
            renderer = 'checkbox',            
            name = 'Pause_Book',
            default = true,
        },
        {
            key = 'b_Pause_Scroll',
            renderer = 'checkbox',            
            name = 'Pause_Scroll',
            default = true,
        },
        {
            key = 'b_Pause_Alchemy',
            renderer = 'checkbox',            
            name = 'Pause_Alchemy',
            default = true,
        },
        {
            key = 'b_Pause_QuickKeysMenu',
            renderer = 'checkbox',            
            name = 'Pause_QuickKeysMenu',
            default = true,
        },
        {
            key = 'b_Pause_Repair',
            renderer = 'checkbox',            
            name = 'Pause_Repair',
            default = true,
        },        
    },
    
}

I.Settings.registerGroup {
    key = 'Settings/SmartInterfaceMenuOpening/MovementsMovementsDuringMenu',
    page = 'SmartInterfaceMenuOpening',
    l10n = 'SmartInterfaceMenuOpening',
    name = 'ConfigMovementsDuringMenus',    
    description = 'ConfigMovementsDuringMenusDesc',
    permanentStorage = true,
    settings = {                
        {
            key = 'b_Movements_Allowed',
            renderer = 'checkbox',            
            name = 'Movements_Allowed',
            description = 'MovementsAllowed',
            default = false,
        },       
    },
    
}