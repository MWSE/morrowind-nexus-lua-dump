local I = require('openmw.interfaces')
local input = require('openmw.input')
local menu = require('openmw.menu')

local nbrPlayers=4
local Keys={'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0',"&","#","(",")","[","]","$","%","^","?","!",";","/","{","}","+","="}
I.Settings.registerPage {
    key = 'CoVSettingsPage',
    l10n = 'CoVSettings',
    name = 'CoV  Settings',
    description = 'CoV settings.',
}


input.registerTrigger{
name = "",
description = '',
l10n = 'CoVSettings',
key = "RAZCamera",
}

for i=1,nbrPlayers do
    input.registerAction {
        key = 'P'..i..'MoveUp',
        type = input.ACTION_TYPE.Boolean,
        l10n = 'CoVSettings',
        name = '',
        description = '',
        defaultValue = true,
    }
    input.registerAction {
        key = 'P'..i..'MoveDown',
        type = input.ACTION_TYPE.Boolean,
        l10n = 'CoVSettings',
        name = '',
        description = '',
        defaultValue = true,
    }
    input.registerAction {
        key = 'P'..i..'MoveRight',
        type = input.ACTION_TYPE.Boolean,
        l10n = 'CoVSettings',
        name = '',
        description = '',
        defaultValue = true,
    }
    input.registerAction {
        key = 'P'..i..'MoveLeft',
        type = input.ACTION_TYPE.Boolean,
        l10n = 'CoVSettings',
        name = '',
        description = '',
        defaultValue = true,
    }
    input.registerAction {
        key = 'P'..i..'Block',
        type = input.ACTION_TYPE.Boolean,
        l10n = 'CoVSettings',
        name = '',
        description = '',
        defaultValue = true,
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."Hit",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."Cast",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."Use",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."SwitchWeapon",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."HealthPotion",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."MagickaPotion",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."Inventory",
    }
    input.registerTrigger{
    name = "",
    description = '',
    l10n = 'CoVSettings',
    key = "P"..i.."SwitchSpell",
    }
end

I.Settings.registerGroup {
    key = 'CoVGeneralSettings',
    page = 'CoVSettingsPage',
    l10n = 'CoVSettings',
    name = 'CoV general settings',
    description = 'CoV general Settings',
    permanentStorage = true,
    settings = {
        {
            key = 'ShowDamages',
            renderer = 'checkbox',
            name = 'Show damages',
            description = 'The damages are visible..',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        
        {
            key = "ButtonRAZCamera",
            renderer = "inputBinding",
            name = "RAZ Camera",
            description = 'Return Camera to default position. (Use the mouse to move camera)',
            default = "0",
            argument = {
                type = "trigger",
                key = "RAZCamera"
            },
        },
        
        {
            key = 'FriendlyFire',
            renderer = 'select',
            name = 'Friendly Fire',
            description = 'You can hit your allies.',
            default = "No",
			argument={disabled = false, l10n = 'CoVSettings', items={"Yes","No"}},
        },

   	},
}
----[[
for i=1,nbrPlayers do
    I.Settings.registerGroup {
        key = 'Player'..i..'Settings',
        page = 'CoVSettingsPage',
        l10n = 'Player'..i..'Settings',
        name = 'Player '..i..' controls',
        description = 'Player '..i..' controls',
        permanentStorage = true,
        settings = {
        
            {
                key = "ButtonMoveUp",
                renderer = "inputBinding",
                name = "Move Up",
                description = 'Move the player Up',
                default = Keys[(i-1)*13+1],
                argument = {
                    type = "action",
                    key = "P"..i.."MoveUp"
                },
            },
            {
                key = "ButtonMoveDown",
                renderer = "inputBinding",
                name = "Move Down",
                description = 'Move the player Down',
                default = Keys[(i-1)*13+2],
                argument = {
                    type = "action",
                    key = "P"..i.."MoveDown"
                },
            },
            {
                key = "ButtonMoveRight",
                renderer = "inputBinding",
                name = "Move Right",
                description = 'Move the player Right',
                default = Keys[(i-1)*13+3],
                argument = {
                    type = "action",
                    key = "P"..i.."MoveRight"
                },
            },
            {
                key = "ButtonMoveLeft",
                renderer = "inputBinding",
                name = "Move Left",
                description = 'Move the player Left',
                default = Keys[(i-1)*13+4],
                argument = {
                    type = "action",
                    key = "P"..i.."MoveLeft"
                },
            },
            {
                key = "ButtonBlock",
                renderer = "inputBinding",
                name = "Blockt",
                description = 'Block attacks',
                default = Keys[(i-1)*13+5],
                argument = {
                    type = "action",
                    key = "P"..i.."Block"
                },
            },
            {
                key = "ButtonHit",
                renderer = "inputBinding",
                name = "Hit",
                description = 'Hit',
                default = Keys[(i-1)*13+6],
                argument = {
                    type = "trigger",
                    key = "P"..i.."Hit"
                },
            },
            {
                key = "ButtonCast",
                renderer = "inputBinding",
                name = "Cast",
                description = 'Cast a spell / Drop an item in inventory / Switch buying and selling',
                default = Keys[(i-1)*13+7],
                argument = {
                    type = "trigger",
                    key = "P"..i.."Cast"
                },
            },
            {
                key = "ButtonUse",
                renderer = "inputBinding",
                name = "Use",
                description = 'Use',
                default = Keys[(i-1)*13+8],
                argument = {
                    type = "trigger",
                    key = "P"..i.."Use"
                },
            },
            {
                key = "ButtonSwitchWeapon",
                renderer = "inputBinding",
                name = "Switch Weapon",
                description = 'Switch close combat/marksman weapons',
                default = Keys[(i-1)*13+9],
                argument = {
                    type = "trigger",
                    key = "P"..i.."SwitchWeapon"
                },
            },
            {
                key = "ButtonMagickaPotion",
                renderer = "inputBinding",
                name = "Magicka Potion",
                description = 'Use a magicka potion',
                default = Keys[(i-1)*13+10],
                argument = {
                    type = "trigger",
                    key = "P"..i.."MagickaPotion"
                },
            },
            {
                key = "ButtonHealthPotion",
                renderer = "inputBinding",
                name = "Health Potion",
                description = 'Use a health potion',
                default = Keys[(i-1)*13+11],
                argument = {
                    type = "trigger",
                    key = "P"..i.."HealthPotion"
                },
            },
            {
                key = "ButtonInventory",
                renderer = "inputBinding",
                name = "Inventory",
                description = 'Open inventory',
                default = Keys[(i-1)*13+12],
                argument = {
                    type = "trigger",
                    key = "P"..i.."Inventory"
                },
            },
            {
                key = "ButtonSwitchSpell",
                renderer = "inputBinding",
                name = "Switch Spell",
                description = 'Switch the active spell',
                default = Keys[(i-1)*13+13],
                argument = {
                    type = "trigger",
                    key = "P"..i.."SwitchSpell"
                },
            },

        },
    }
end


local function CoVSaveGame()
    local Date=os.date("*t",os.time())
    local slotName=Date.sec..":"..Date.min..":"..Date.hour.." "..Date.month.."/"..Date.day.."/"..Date.year
    menu.saveGame(slotName, slotName)
end

return {
	eventHandlers = {	
						CoVSaveGame=CoVSaveGame
					},

}