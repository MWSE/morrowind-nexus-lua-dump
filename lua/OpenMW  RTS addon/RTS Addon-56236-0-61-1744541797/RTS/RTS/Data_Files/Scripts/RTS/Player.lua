local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ambient = require('openmw.ambient')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local interfaces = require('openmw.interfaces')
local time=require('openmw_aux.time')
local storage = require('openmw.storage')

I.Settings.registerPage {
    key = 'RTSEngineSettingsPage',
    l10n = 'RTSEngineSettings',
    name = 'RTSEngine  Settings',
    description = 'RTS settings.',
}


input.registerAction {
	key = 'Up',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'Down',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'ZoomIn',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'ZoomOut',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'CamAngle',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'ButtonPlayer',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'ButtonTeamAdd',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerAction {
	key = 'Select',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'RTSControls',
	name = '',
	description = '',
	defaultValue = true,
}
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "Start",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "Action",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "DefendStance",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "AttackStance",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "NothingStance",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "Patrol",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "ForceAttack",
})input.registerTrigger({
    name = "",
    description = '',
    l10n = 'RTSControls',
    key = "Guard",
})input.registerTrigger({
    name = "Team1",
    description = '',
    l10n = 'RTSControls',
    key = "Team1",
})input.registerTrigger({
    name = "Team2",
    description = '',
    l10n = 'RTSControls',
    key = "Team2",
})input.registerTrigger({
    name = "Team3",
    description = '',
    l10n = 'RTSControls',
    key = "Team3",
})input.registerTrigger({
    name = "Team4",
    description = '',
    l10n = 'RTSControls',
    key = "Team4",
})input.registerTrigger({
    name = "Team5",
    description = '',
    l10n = 'RTSControls',
    key = "Team5",
})input.registerTrigger({
    name = "Team6",
    description = '',
    l10n = 'RTSControls',
    key = "Team6",
})input.registerTrigger({
    name = "Team7",
    description = '',
    l10n = 'RTSControls',
    key = "Team7",
})input.registerTrigger({
    name = "Team8",
    description = '',
    l10n = 'RTSControls',
    key = "Team8",
})input.registerTrigger({
    name = "Team9",
    description = '',
    l10n = 'RTSControls',
    key = "Team9",
})input.registerTrigger({
    name = "Team0",
    description = '',
    l10n = 'RTSControls',
    key = "Team0",
})

I.Settings.registerGroup {
    key = 'RTSEnginecontrols',
    page = 'RTSEngineSettingsPage',
    l10n = 'RTSEngineSettings',
    name = 'RTSEngine controls',
    description = 'Configuration of controls for RTSEngine.',
    permanentStorage = false,
    settings = {
        {
            key = 'Faction',
            renderer = 'select',
            name = 'Faction',
            description = 'The Faction you want to control',
            default = "imperial legion",
			argument={disabled = false, l10n = 'LocalizationContext', items={"1","3"}},
        },
        {
            key = 'EnemyFaction',
            renderer = 'select',
            name = 'EnemyFaction',
            description = 'The Faction you want to fight again',
            default = "sixth house",
			argument={disabled = false, l10n = 'LocalizationContext', items={"1","3"}},
        },
        {
            key = 'MinimapQuality',
            renderer = 'select',
            name = 'Minimap',
            description = 'The resolution of the minimap (resource heavy)',
            default = "Low",
			argument={disabled = false, l10n = 'LocalizationContext', items={"Low","Standard","High"}},
        },
        {
            key = "Start",
            renderer = "inputBinding",
            name = "Start",
            description = "Start/Stop RTS",
            default = "p",
            argument = {
                type = "trigger",
                key = "Start"
        	},
		},
        {
            key = "ButtonUp",
            renderer = "inputBinding",
            name = "Up",
            description = 'Move Camera Up.',
            default = "u",
            argument = {
                type = "action",
                key = "Up"
        	},
		},
        {
            key = "ButtonDown",
            renderer = "inputBinding",
            name = "Down",
            description = 'Move Camera Down.',
            default = "d",
            argument = {
                type = "action",
                key = "Down"
        	},
		},
        {
            key = "ButtonRight",
            renderer = "inputBinding",
            name = "Right",
            description = 'Move the Camera to right.',
            default = "r",
            argument = {
                type = "action",
                key = "Right"
        	},
		},
        {
            key = "ButtonLeft",
            renderer = "inputBinding",
            name = "Left",
            description = 'Move the Camera to left.',
            default = "l",
            argument = {
                type = "action",
                key = "Left"
        	},
		},
        {
            key = "ButtonZoomOut",
            renderer = "inputBinding",
            name = "ZoomOut",
            description = 'Zoom Out.',
            default = "e",
            argument = {
                type = "action",
                key = "ZoomOut"
        	},
		},
        {
            key = "ButtonZoomIn",
            renderer = "inputBinding",
            name = "ZoomIn",
            description = 'Zoom In.',
            default = "i",
            argument = {
                type = "action",
                key = "ZoomIn"
        	},
		},
        {
            key = "ButtonCamAngle",
            renderer = "inputBinding",
            name = "CamAngle",
            description = 'Move the Camera angle.',
            default = "y",
            argument = {
                type = "action",
                key = "CamAngle"
        	},
		},
        {
            key = "Select",
            renderer = "inputBinding",
            name = "Select",
            description = 'Select in RTS mode.',
            default = "s",
            argument = {
                type = "action",
                key = "Select"
        	},
		},
        {
            key = "Action",
            renderer = "inputBinding",
            name = "Action",
            description = "Play iddle4's actor",
            default = "a",
            argument = {
                type = "trigger",
                key = "Action"
        	},
		},
        {
            key = "ButtonPlayer",
            renderer = "inputBinding",
            name = "ButtonPlayer",
            description = 'Button to Activate with player (Doors,Dialogues).',
            default = "h",
            argument = {
                type = "action",
                key = "ButtonPlayer"
        	},
		},
        {
            key = "DefendStance",
            renderer = "inputBinding",
            name = "Shortcut : DefendStance",
            description = "DEFEND STANCE : Only attack near ennemies.",
            default = "w",
            argument = {
                type = "trigger",
                key = "DefendStance"
        	},
		},
        {
            key = "AttackStance",
            renderer = "inputBinding",
            name = "Shortcut : AttackStance",
            description = "ATTACK STANCE : Attack ennemies on sight.",
            default = "x",
            argument = {
                type = "trigger",
                key = "AttackStance"
        	},
		},
        {
            key = "NothingStance",
            renderer = "inputBinding",
            name = "Shortcut : NothingStance",
            description = "NOTHING STANCE : Only attack when attacked.",
            default = "c",
            argument = {
                type = "trigger",
                key = "NothingStance"
        	},
		},
        {
            key = "Patrol",
            renderer = "inputBinding",
            name = "Shortcut : Patrol",
            description = "PATROL : Patrol from positon to target position.",
            default = "v",
            argument = {
                type = "trigger",
                key = "Patrol"
        	},
		},
        {
            key = "ForceAttack",
            renderer = "inputBinding",
            name = "Shortcut : ForceAttack",
            description = "FORCE ATTACK : Attack the actor even if it's not an ennemie.",
            default = "b",
            argument = {
                type = "trigger",
                key = "ForceAttack"
        	},
		},
        {
            key = "Guard",
            renderer = "inputBinding",
            name = "Shortcut : Guard",
            description = "GUARD : Follow and protect target actor.",
            default = "n",
            argument = {
                type = "trigger",
                key = "Guard"
        	},
		},
        {
            key = "ButtonTeamAdd",
            renderer = "inputBinding",
            name = "ButtonTeamAdd",
            description = 'Button to choose a Team or add to selection.',
            default = "ctrl",
            argument = {
                type = "action",
                key = "ButtonTeamAdd"
        	},
		},
        {
            key = "Team1",
            renderer = "inputBinding",
            name = "Team1",
            description = "Key for the Team 1",
            default = "1",
            argument = {
                type = "trigger",
                key = "Team1"
        	},
		},
        {
            key = "Team2",
            renderer = "inputBinding",
            name = "Team2",
            description = "Key for the Team 2",
            default = "2",
            argument = {
                type = "trigger",
                key = "Team2"
        	},
		},
        {
            key = "Team3",
            renderer = "inputBinding",
            name = "Team3",
            description = "Key for the Team 3",
            default = "3",
            argument = {
                type = "trigger",
                key = "Team3"
        	},
		},
        {
            key = "Team4",
            renderer = "inputBinding",
            name = "Team4",
            description = "Key for the Team 4",
            default = "4",
            argument = {
                type = "trigger",
                key = "Team4"
        	},
		},
        {
            key = "Team5",
            renderer = "inputBinding",
            name = "Team5",
            description = "Key for the Team 5",
            default = "5",
            argument = {
                type = "trigger",
                key = "Team5"
        	},
		},
        {
            key = "Team6",
            renderer = "inputBinding",
            name = "Team6",
            description = "Key for the Team 6",
            default = "6",
            argument = {
                type = "trigger",
                key = "Team6"
        	},
		},
        {
            key = "Team7",
            renderer = "inputBinding",
            name = "Team7",
            description = "Key for the Team 7",
            default = "7",
            argument = {
                type = "trigger",
                key = "Team7"
        	},
		},
        {
            key = "Team8",
            renderer = "inputBinding",
            name = "Team8",
            description = "Key for the Team 8",
            default = "8",
            argument = {
                type = "trigger",
                key = "Team8"
        	},
		},
        {
            key = "Team9",
            renderer = "inputBinding",
            name = "Team9",
            description = "Key for the Team 9",
            default = "9",
            argument = {
                type = "trigger",
                key = "Team9"
        	},
		},
        {
            key = "Team0",
            renderer = "inputBinding",
            name = "Team0",
            description = "Key for the Team 0",
            default = "0",
            argument = {
                type = "trigger",
                key = "Team0"
        	},
		},

   	},
}


local RTS=false
local CursorTexture=ui.texture { path = 'textures/cursor.png' }
local AttackTexture=ui.texture { path = 'textures/attack.png' }
local MoveTexture=ui.texture { path = 'textures/move.png' }
local PickTexture=ui.texture { path = 'textures/pick.png' }
local DoorTexture=ui.texture { path = 'textures/takedoor.png' }
local SpeakTexture=ui.texture { path = 'textures/speak.png' }
local GuardTexture=ui.texture { path = 'textures/guardicon.png' }
local Cursor=ui.create({ layer = 'Console', type = ui.TYPE.Image, props = {State="",color=util.color.rgb(1,1,1),visible=false, relativeSize = util.vector2(1/25, 1/20), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), resource = CursorTexture, }, })
local SelectedArea=ui.create({ layer = 'HUD', type = ui.TYPE.Image, Point0={}, props = {visible=false, relativeSize = util.vector2(0, 0), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/selected.png' }, }, })
local SelectedActors={}
local SelectTrigger=false
local Ray
local DoubleClick={Duration=0.3,Timer=0.3}
local TeamDoubleClick={Duration=0.3,Timer=0.3,Team=""}
local ObjectToActivate=nil
local Teams={}
local SaveTeams=nil
local FontSize=8/1350*ui.screenSize().x
local enemyFactions={}
local NumberSpeakingActors=5
local LastCell

local function CheckPointInSquare(PUI1,UI2)
    local Ratio={X=0,Y=0}
	local P0=UI2.layout.props.relativePosition
	local P2=UI2.layout.props.relativePosition+UI2.layout.props.relativeSize
	if PUI1.y>=P0.y and PUI1.y<=P2.y and PUI1.x<=P2.x and PUI1.x>=P0.x then
        Ratio.X=PUI1.x/(P2.x-P0.x)
        Ratio.Y=PUI1.y/(P2.y-P0.y)
		return(Ratio)
	end

end

local function Collision(UI1,UI2)
	local PointCollision={}
	if CheckPointInSquare(UI1.layout.props.relativePosition,UI2) then
		PointCollision.UL=CheckPointInSquare(UI1.layout.props.relativePosition,UI2)
	end
	if CheckPointInSquare(util.vector2(UI1.layout.props.relativePosition.x+UI1.layout.props.relativeSize.x,UI1.layout.props.relativePosition.y),UI2) then
		PointCollision.UR=CheckPointInSquare(util.vector2(UI1.layout.props.relativePosition.x+UI1.layout.props.relativeSize.x,UI1.layout.props.relativePosition.y),UI2) 
	end
	if CheckPointInSquare(UI1.layout.props.relativePosition+UI1.layout.props.relativeSize,UI2) then
		PointCollision.DR=CheckPointInSquare(UI1.layout.props.relativePosition+UI1.layout.props.relativeSize,UI2)
	end
	if CheckPointInSquare(util.vector2(UI1.layout.props.relativePosition.x,UI1.layout.props.relativePosition.y+UI1.layout.props.relativeSize.y),UI2) then
		PointCollision.DL=CheckPointInSquare(util.vector2(UI1.layout.props.relativePosition.x,UI1.layout.props.relativePosition.y+UI1.layout.props.relativeSize.y),UI2)
	end

--	if PointCollision.UL or PointCollision.UR or PointCollision.DL or PointCollision.DR then
		return(PointCollision)
--	end

end	

local function RAZSelectedActors()
    for i, selected in ipairs(SelectedActors) do
        if selected[1] then
            selected[1]:sendEvent("IsSelected",{Player=nil})
        end
        if selected[2] then
            selected[2]:destroy()
        end
        if selected[3] then
            selected[3]:destroy()
        end
    end
    SelectedActors={}
    Cursor.layout.props.resource = CursorTexture
    Cursor.layout.props.color=util.color.rgb(1,1,1)
    Cursor:update()
end



local function CreateSelected()
    return(ui.create({ layer = 'HUD', type = ui.TYPE.Image, props = {visible=true, relativeSize = util.vector2(1/25, 1/20), relativePosition = util.vector2(-1, -1), anchor = util.vector2(0.5, 1), resource = ui.texture { path = 'textures/selected.png' }, }, }))
end

local function CreateLifeBar()
    return(ui.create({ layer = 'HUD', type = ui.TYPE.Image, props = {color=util.color.rgb(1,0.2,0.2),visible=true, relativeSize = util.vector2(0.08, 0.01), relativePosition = util.vector2(-1,-1), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image, props = {color=util.color.rgb(0,0.8,0),visible=true, relativeSize = util.vector2(2, 2), relativePosition = util.vector2(0, 0), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, }}} }))
end

local function CreateNumberTeam(num)
    return(ui.create({ layer = 'HUD', type = ui.TYPE.Text, props = {text=num, visible=true, textSize=FontSize, relativeSize = util.vector2(1/25, 1/20), relativePosition = util.vector2(0, 1), anchor = util.vector2(4-tonumber(num)/1.5, 1), textColor = util.color.rgb(1, 1, 1), }, }))
end

local Describ=ui.create({ layer = 'Windows', type = ui.TYPE.Image, Actor=nil, props = {color=util.color.rgb(0.5,0.5,0.5),visible=false, relativeSize = util.vector2(0.3, 0.1), relativePosition = util.vector2(0, 1), anchor = util.vector2(0, 1), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{ {name="Class", layer = 'HUD', type = ui.TYPE.Text, props = {text="", visible=true, wordWrap=true, textSize=3*FontSize, relativeSize = util.vector2(0.3, 0.5), relativePosition = util.vector2(0.2, 0.3), anchor = util.vector2(0.5, 0.5), textColor = util.color.rgb(1, 1, 1), }, },
                                            {name="Statut", layer = 'HUD', type = ui.TYPE.Text, props = {text="Statut", visible=true, textSize=2.5*FontSize, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.05, 0.6), anchor = util.vector2(0, 0), textColor = util.color.rgb(1, 1, 1), }, },
                                            {name="Lifebar", type = ui.TYPE.Image, props = {color=util.color.rgb(1,0.2,0.2),visible=true, relativeSize = util.vector2(0.3, 0.15), relativePosition = util.vector2(0.5, 0.2), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, },
                                                content=ui.content{{type = ui.TYPE.Image, props = {color=util.color.rgb(0,0.8,0),visible=true, relativeSize = util.vector2(2, 2), relativePosition = util.vector2(0, 0), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, }}} },
                                                {name="Health", layer = 'HUD', type = ui.TYPE.Text, props = {text="", visible=true, textSize=3*FontSize, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textColor = util.color.rgb(1, 1, 1), }, },                    
                    } })

local ShowInventory=ui.create({ layer = 'Windows', type = ui.TYPE.Image, Actor=nil, props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(.1, 0.05), relativePosition = util.vector2(0.2, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{layer = 'HUD', type = ui.TYPE.Text, props = {text="Show Inventory", textSize=2*FontSize, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textColor = util.color.rgb(1, 1, 1), }, },
                    
                    } })

local ActorQuickInfos=ui.create({ layer = 'HUD', type = ui.TYPE.Image, Actor=nil, props = {color=util.color.rgb(0.5,0.5,0.5),visible=false, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 1), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{name="Name", layer = 'HUD', type = ui.TYPE.Text, props = {autoSize=true, text="", visible=true, textSize=1.5*FontSize, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.5, 0.3), anchor = util.vector2(0.5, 0.5), textColor = util.color.rgb(1, 1, 1), wordWrap=true }, },
                                           {name="Lifebar", type = ui.TYPE.Image, props = {color=util.color.rgb(1,0.2,0.2),visible=true, relativeSize = util.vector2(0.9, 0.15), relativePosition = util.vector2(0.5, 0.9), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, },
                                           content=ui.content{{type = ui.TYPE.Image, props = {color=util.color.rgb(0,0.8,0),visible=true, relativeSize = util.vector2(2, 2), relativePosition = util.vector2(0, 0), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/white.png' }, }}} },
                                           {name="Health", layer = 'HUD', type = ui.TYPE.Text, props = {text="", visible=true, textSize=3*FontSize, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.5, 0.8), anchor = util.vector2(0.5, 0.5), textColor = util.color.rgb(1, 1, 1), }, },

                    } })


local Minimap=ui.create({ layer = 'Windows', type = ui.TYPE.Image, Actor=nil, props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.15, 0.25), relativePosition = util.vector2(0.845, 0.74), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{},
                     })



local DefendStance=ui.create({ Explaination="DEFEND STANCE : Only attack near ennemies.", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.32, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/shield.png' }}, },
                    }})
local AttackStance=ui.create({ Explaination="ATTACK STANCE : Attack ennemies on sight.", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.36, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/sword.png' }}, },
                    }})
local NothingStance=ui.create({ Explaination="NOTHING STANCE : Only attack when attacked.", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.4, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/forbidden.png' }}, },
                    }})
local Patrol=ui.create({ Explaination="PATROL : Patrol from positon to target position", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.44, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/patrol.png' }}, },
                    }})
local ForceAttack=ui.create({ Explaination="FORCE ATTACK : Attack the actor even if it's not an ennemie", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.48, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/forceattack.png' }}, },
                    }})
local Guard=ui.create({ Explaination="GUARD : Follow and protect target actor", layer = 'Windows', type = ui.TYPE.Image,  props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.03, 0.05), relativePosition = util.vector2(0.52, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{type = ui.TYPE.Image,  props = {color=util.color.rgb(1,1,1), relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0,0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/guard.png' }}, },
                    }})
local StanceExplainations=ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(0.4,0.4,0.4),visible=false, relativeSize = util.vector2(0.1, 0.15), relativePosition = util.vector2(0.2, 0.93), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/white.png' }, },
                        content=ui.content{{layer = 'HUD', type = ui.TYPE.Text, props = {text="Show Inventory", textSize=2*FontSize, wordWrap=true,  relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.05, 0.05), anchor = util.vector2(0, 0), textColor = util.color.rgb(1, 1, 1), }, },
                    } })




                     
local Factions={}
local ActiveFaction="imperial legion"
for i, faction in ipairs(core.factions.records) do
	table.insert(Factions,faction.id)
end
I.Settings.updateRendererArgument('RTSEnginecontrols', 'Faction', {disabled = false, l10n = 'LocalizationContext', items=Factions})

local MaybeEnemyFactions={}
local EnemyFaction="sith house"
for i, faction in ipairs(core.factions.records) do
	table.insert(MaybeEnemyFactions,faction.id)
end
table.insert(MaybeEnemyFactions,"none")
I.Settings.updateRendererArgument('RTSEnginecontrols', 'EnemyFaction', {disabled = false, l10n = 'LocalizationContext', items=MaybeEnemyFactions})

 

local function SelectSame()
--    print("selecteSame")

    for i, actor in ipairs(nearby.actors) do
        if types.Actor.isDead(actor)==false and 
            ((actor.type==types.NPC and Ray.hitObject.type==types.NPC and
            types.NPC.getFactions(actor)[1]==ActiveFaction and types.NPC.record(actor).class and
            types.NPC.record(actor).class==types.NPC.record(Ray.hitObject).class)
            or ((actor.type==types.Creature or actor.type==types.NPC) and types.Actor.spells(actor)[ActiveFaction.." spellflag"] and actor.recordId==Ray.hitObject.recordId)) then

            if      camera.worldToViewportVector(actor.position).x/ui.screenSize().x>=0 and
                    camera.worldToViewportVector(actor.position).x/ui.screenSize().x<=1 and 
                    camera.worldToViewportVector(actor.position).y/ui.screenSize().y>=0 and 
                    camera.worldToViewportVector(actor.position).y/ui.screenSize().y<=1 then
 --                       print(actor.recordId.." selected")
                table.insert(SelectedActors, {actor,CreateSelected(),CreateLifeBar()})
                SelectedActors[1][1]:sendEvent("IsSelected",{Player=self})
                
                Cursor.layout.props.resource = MoveTexture
                
                local ActorSpeaks=NumberSpeakingActors
                for i, selected in ipairs(SelectedActors) do
                    if selected.type==types.NPC then
                        ActorSpeaks=ActorSpeaks-1
                        for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                            if dialogue.filterActorRace==types.NPC.record(selected[1]).race and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                                ambient.playSoundFile(dialogue.sound)
                                break
                            end
                        end
                        if ActorSpeaks==0 then
                            break
                        end
                    end
                end
            end
        end
    end
end


local function selectArea()
    local Xmin=SelectedArea.layout.P0.x
    local Xmax=Cursor.layout.props.relativePosition.x
    local Ymin=SelectedArea.layout.P0.y
    local Ymax=Cursor.layout.props.relativePosition.y

    if SelectedArea.layout.P0.x>Cursor.layout.props.relativePosition.x then
        Xmin=Cursor.layout.props.relativePosition.x
        Xmax=SelectedArea.layout.P0.x
    end

    if SelectedArea.layout.P0.y>Cursor.layout.props.relativePosition.y then
        Ymin=Cursor.layout.props.relativePosition.y
        Ymax=SelectedArea.layout.P0.y
    end

    for i, actor in ipairs(nearby.actors) do
        --print(actor)
        local selected=false
        if types.Actor.isDead(actor)==false  and ((actor.type==types.NPC and types.NPC.getFactions(actor)[1]==ActiveFaction) or types.Actor.spells(actor)[ActiveFaction.." spellflag"]) then
            if  camera.worldToViewportVector(actor.position).x/ui.screenSize().x>=(Xmin) and
                camera.worldToViewportVector(actor.position).x/ui.screenSize().x<=(Xmax) and 
                camera.worldToViewportVector(actor.position).y/ui.screenSize().y>=(Ymin) and 
                camera.worldToViewportVector(actor.position).y/ui.screenSize().y<=(Ymax)  then
--                print(actor.recordId.." selected")
                table.insert(SelectedActors, {actor,CreateSelected(),CreateLifeBar()})
                                
                SelectedActors[1][1]:sendEvent("IsSelected",{Player=self})
                Cursor.layout.props.resource = MoveTexture
                local ActorSpeaks=NumberSpeakingActors
                for k, selected in ipairs(SelectedActors) do
                    if selected.type==types.NPC then
                        ActorSpeaks=ActorSpeaks-1
                        for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                            if dialogue.filterActorRace==types.NPC.record(selected[1]).race and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                                ambient.playSoundFile(dialogue.sound)
                                    break
                            end
                           end
                        if ActorSpeaks==0 then
                            break
                        end
                    end
                end
            end
        end
    end 
    
    SelectedArea.layout.props.visible=false
    SelectedArea.layout.props.relativeSize = util.vector2(0, 0)
    SelectedArea:update()
end

local MinimapBaseContent=ui.content{
    { name="Background", type = ui.TYPE.Widget, props = {visible=true,relativeSize = util.vector2(1,1), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0) },
    content=ui.content{},
 },
    { name="Actors",type = ui.TYPE.Widget, props = {relativeSize = util.vector2(1,1), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0) },
        content=ui.content{},
    }
}




local function DeepRay(StartPos,Vector3)
    local NewStartPos=StartPos
    local NewRay
    local LastRay=nearby.castRay(NewStartPos,NewStartPos+Vector3)
    while (true) do
        NewRay=nearby.castRay(NewStartPos,NewStartPos+Vector3)
        if NewRay.hitPos then
            NewStartPos=NewRay.hitPos+Vector3*0.001
        else
            NewStartPos=nil
        end
        if NewStartPos then
            LastRay=NewRay
        end
        if NewStartPos==nil or (LastRay.hitObject and ( LastRay.hitObject.type==types.Activator or 
                                                        LastRay.hitObject.type==types.Door or 
                                                        LastRay.hitObject.type==types.Creature or 
                                                        LastRay.hitObject.type==types.Container or 
                                                        LastRay.hitObject.type==types.NPC)) then
            break
        end
    end
    return(LastRay)
end



time.runRepeatedly(function() 	
    if RTS==true then
        core.sendGlobalEvent("Teleport",{object=self,cell=self.cell.name,position=camera.getPosition()})

        if enemyFactions then
            for i, actor in ipairs(nearby.actors) do
                if types.Actor.isDead(actor)==false then
                    actor:sendEvent("DeclareFactions",{PlayerFaction=ActiveFaction, enemyFactions=enemyFactions})
                end
            end
        end

        
        if LastCell~=self.cell then
--            print("NewCell")
            LastCell=self.cell
            local MinZ
            local MaxZ
            MinimapBaseContent=ui.content{
                { name="Background", type = ui.TYPE.Widget, props = {visible=true,relativeSize = util.vector2(1,1), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0) },
                content=ui.content{},
             },
                { name="Actors",type = ui.TYPE.Widget, props = {relativeSize = util.vector2(1,1), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0) },
                    content=ui.content{},
                }
            }

            local TakeValueOnce=false
            for i, Nearby in pairs(nearby) do 
                if type(Nearby)=="userdata" then 
                    for j, object in ipairs(Nearby) do
                        if object~=self then
                            if TakeValueOnce==false then
                                Minimap.layout.MinX=object.position.x
                                Minimap.layout.MaxX=object.position.x
                                Minimap.layout.MinY=object.position.y
                                Minimap.layout.MaxY=object.position.y
                                MinZ=object.position.z
                                MaxZ=object.position.z
                                TakeValueOnce=true
                            end
                            if object.position.x<Minimap.layout.MaxX then
                                Minimap.layout.MaxX=object.position.x
                            end
                            if object.position.x>Minimap.layout.MinX then
                                Minimap.layout.MinX=object.position.x
                            end
                            if object.position.y<Minimap.layout.MinY then
                                Minimap.layout.MinY=object.position.y
                            end
                            if object.position.y>Minimap.layout.MaxY then
                                Minimap.layout.MaxY=object.position.y
                            end

                            
                            if object.position.z>MaxZ then
                                MaxZ=object.position.z
                            end
                            if object.position.z<MinZ then
                                MinZ=object.position.z
                            end
                        end
                    end 
                end 
            end


            Minimap.layout.MinX=Minimap.layout.MinX-(Minimap.layout.MaxX-Minimap.layout.MinX)*0.1
            Minimap.layout.MaxX=Minimap.layout.MaxX+(Minimap.layout.MaxX-Minimap.layout.MinX)*0.09090909
            Minimap.layout.MinY=Minimap.layout.MinY-(Minimap.layout.MaxY-Minimap.layout.MinY)*0.1
            Minimap.layout.MaxY=Minimap.layout.MaxY+(Minimap.layout.MaxY-Minimap.layout.MinY)*0.09090909

            local SizeRatioDiv=30
            local DotSize=0.08

            if storage.playerSection('RTSEnginecontrols'):get('MinimapQuality')=="Low" then
                SizeRatioDiv=30
                DotSize=0.08
            elseif storage.playerSection('RTSEnginecontrols'):get('MinimapQuality')=="Standard" then
                SizeRatioDiv=60
                DotSize=0.04

            elseif storage.playerSection('RTSEnginecontrols'):get('MinimapQuality')=="High" then
                SizeRatioDiv=100
                DotSize=0.02
            end

            local SizeRatio = (Minimap.layout.MaxY-Minimap.layout.MinY)/SizeRatioDiv

            for x=util.round(Minimap.layout.MaxX/SizeRatio),util.round(Minimap.layout.MinX/SizeRatio) do
                for y=util.round(Minimap.layout.MinY/SizeRatio),util.round(Minimap.layout.MaxY/SizeRatio) do   
                    local Ray={}
                    local WorldRay=nearby.castRay(util.vector3(x*SizeRatio,y*SizeRatio,MaxZ+5000),util.vector3(x*SizeRatio,y*SizeRatio,MaxZ-15000),{collisionType=nearby.COLLISION_TYPE.World})
                    local HeightMapRay=nearby.castRay(util.vector3(x*SizeRatio,y*SizeRatio,MaxZ+5000),util.vector3(x*SizeRatio,y*SizeRatio,MaxZ-15000),{collisionType=nearby.COLLISION_TYPE.HeightMap})
                    if (WorldRay.hitPos and HeightMapRay.hitPos and WorldRay.hitPos.z>HeightMapRay.hitPos.z) or (WorldRay.hitPos and HeightMapRay.hitPos==nil) then
                        Ray=WorldRay
                    elseif (WorldRay.hitPos and HeightMapRay.hitPos and WorldRay.hitPos.z<HeightMapRay.hitPos.z) or (WorldRay.hitPos==nil and HeightMapRay.hitPos) then
                        Ray=HeightMapRay
                    end

                    local Z=0
                    local color

                    if Ray.hitPos then
                        Z=Ray.hitPos.z
                        if self.cell.hasWater==true and Z<=self.cell.waterLevel then
                            color=util.color.rgb(0,0,0.5)
                        else 
                            color=util.color.rgb(1-(Z-MinZ)/(MaxZ-MinZ),0.5-(Z-MinZ)/(MaxZ-MinZ)/2,0)
                        end
                    else
                        color=util.color.rgb(0.5,0.5,0.5)
                    end

                    MinimapBaseContent.Background.content:add({type = ui.TYPE.Image, props = { color=color,visible=true, relativeSize = util.vector2(DotSize, DotSize),
                     relativePosition = util.vector2((x*SizeRatio-Minimap.layout.MinX)/(Minimap.layout.MaxX-Minimap.layout.MinX),(y*SizeRatio-Minimap.layout.MinY)/(Minimap.layout.MaxY-Minimap.layout.MinY)), 
                     anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/dot.png' }, }})
                 
                end
            end
        end



        MinimapBaseContent.Actors.content=ui.content{}


        for i , actor in ipairs(nearby.actors) do
            if types.Actor.isDead(actor)==false then
                local color=util.color.rgb(1,1,1)
                local size=util.vector2(0.03, 0.03)
                local texture=ui.texture { path = 'textures/dot.png' }
                if actor.type==types.Player then
                    color=util.color.rgb(1,1,0)
                    size=util.vector2(0.15, 0.15)
                    texture=ui.texture { path = 'textures/PlayerArrow/'..(util.round(camera.getYaw()/math.pi/2*36)+18)..'.png' }
                elseif (actor.type==types.NPC or actor.type==types.Creature) and actor~=self and 
                ((actor.type==types.NPC and types.NPC.getFactions(actor)[1]==ActiveFaction) or 
                ((actor.type==types.Creature or actor.type==types.NPC) and types.Actor.spells(actor)[ActiveFaction.." spellflag"])) then
                    color=util.color.rgb(0,1,0)
                
                elseif enemyFactions then
                    for i, faction in pairs(enemyFactions) do
                        if (actor.type==types.NPC or actor.type==types.Creature) and types.Actor.isDead(actor)==false and actor~=self and 
                            ((actor.type==types.NPC and types.NPC.getFactions(actor)[1]==faction) or 
                            ((actor.type==types.Creature or actor.type==types.NPC) and types.Actor.spells(actor)[faction.." spellflag"])) then
                            color=util.color.rgb(1,0,0)
                        end
                    end
                end
                    
                MinimapBaseContent.Actors.content:add({type = ui.TYPE.Image, props = { color=color,visible=true, relativeSize = size,
                                                                            relativePosition = util.vector2((actor.position.x-Minimap.layout.MinX)/(Minimap.layout.MaxX-Minimap.layout.MinX),(actor.position.y-Minimap.layout.MinY)/(Minimap.layout.MaxY-Minimap.layout.MinY)), 
                                                                            anchor = util.vector2(0.5, 0.5), resource = texture, }})
                end
            end
        Minimap.layout.content=MinimapBaseContent
    end
end
,0.5*time.second)



input.registerTriggerHandler("Start", async:callback(function ()
	if RTS==false then
		RTS=true
		camera.setMode(camera.MODE.Static)
		camera.setStaticPosition(camera.getPosition()+util.vector3(0,0,500))
		camera.setPitch(camera.getPitch())
		camera.setYaw(camera.getYaw())
		interfaces.Controls.overrideMovementControls(true)
		interfaces.Controls.overrideCombatControls(true)
	--	interfaces.Controls.overrideUiControls(true)
        types.Actor.activeEffects(self):set(1000,"Chameleon")
        types.Actor.activeEffects(self):set(1000,"Invisibility")
        types.Actor.activeEffects(self):set(1000,"Levitate")
        types.Actor.activeEffects(self):set(1000,"Sanctuary")
        types.Actor.activeEffects(self):set(1000,"WaterBreathing")
        types.Actor.activeEffects(self):set(1000,"Invisibility")
        core.sendGlobalEvent("StartRTS",{Player=self})
        Cursor.layout.props.visible=true
        Cursor:update()
        Minimap.layout.props.visible=true
        Minimap:update()

        for j=0,9 do
            if Teams[tostring(j)] then
                for i, selected in ipairs(Teams[tostring(j)]) do
                    if selected[2] then
                        selected[2].layout.props.visible=true
                        selected[2]:update()
                    end
                end
            end
        end

	elseif RTS==true then
        if nearby.castRay(self.position,self.position+util.vector3(0,0,-camera.getBaseViewDistance())).hitPos then
            RTS=false
            RAZSelectedActors()
            camera.setMode(camera.MODE.ThirdPerson)
            interfaces.Controls.overrideMovementControls(false)
            interfaces.Controls.overrideCombatControls(false)
 --           interfaces.Controls.overrideUiControls(false)
            types.Actor.activeEffects(self):set(0,"Chameleon")
            types.Actor.activeEffects(self):set(0,"Invisibility")
            types.Actor.activeEffects(self):set(0,"Levitate")
            types.Actor.activeEffects(self):set(0,"Sanctuary")
            types.Actor.activeEffects(self):set(0,"WaterBreathing")
            types.Actor.activeEffects(self):set(0,"Invisibility")
            core.sendGlobalEvent("StopRTS",{Player=self,Position=nearby.castRay(self.position,self.position+util.vector3(0,0,-camera.getBaseViewDistance())).hitPos})
            
            Cursor.layout.props.visible=false
            Cursor:update()

            SelectedArea.layout.props.visible=false
            SelectedArea:update()

            ActorQuickInfos.layout.props.visible=false
            ActorQuickInfos:update()

            Describ.layout.props.visible=false
            Describ:update()

            DefendStance.layout.props.visible=false
            DefendStance:update()

            AttackStance.layout.props.visible=false
            AttackStance:update()

            NothingStance.layout.props.visible=false
            NothingStance:update()

            Patrol.layout.props.visible=false
            Patrol:update()

            ForceAttack.layout.props.visible=false
            ForceAttack:update()

            Guard.layout.props.visible=false
            Guard:update()

            ShowInventory.layout.props.visible=false            
            ShowInventory:update()

            Minimap.layout.props.visible=false
            Minimap:update()

            for j=0,9 do
                if Teams[tostring(j)] then
                    for i, selected in ipairs(Teams[tostring(j)]) do
                        if selected[2] then
                            selected[2]:destroy()
                        end
                        Teams[tostring(j)]={}
                    end
                end
            end

        else
            ui.showMessage("There is no ground above, you better stop at a better place.")
        end
	end
end))



input.registerTriggerHandler("Action", async:callback(function ()
    
    if Cursor.layout.props.resource==DoorTexture then
        if Ray.hitObject.type==types.Door and types.Lockable.isLocked(Ray.hitObject)==false and types.Door.destPosition(Ray.hitObject) then
            camera.setStaticPosition(camera.getPosition()-Ray.hitObject.position+types.Door.destPosition(Ray.hitObject))
        end
--        print("Activate door")
--        print(Ray.hitObject)
        Ray.hitObject:activateBy(self)
    elseif Cursor.layout.props.resource==SpeakTexture then
        
        Ray.hitObject:activateBy(self)
        I.UI.addMode("Dialogue",{target=Ray.hitObject})
 --       print("speak")
    else
        local ActorSpeaks=NumberSpeakingActors
        for i, selected in ipairs(SelectedActors) do
            if Cursor.layout.props.resource == MoveTexture and Ray.hitPos and Cursor.layout.props.color==util.color.rgb(1,1,1) then
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race  and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                selected[1]:sendEvent("Move",{Cell=self.cell.name, Position=Ray.hitPos})
            
            elseif Cursor.layout.props.resource == MoveTexture and Ray.hitPos and Cursor.layout.props.color==util.color.rgb(1,1,0) then
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race  and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                selected[1]:sendEvent("Patrol",{Cell=self.cell.name, Position=Ray.hitPos})



            elseif Cursor.layout.props.resource == AttackTexture and Ray.hitObject and Cursor.layout.props.color==util.color.rgb(1,1,0)  then
                print("Send ForceAttack")
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[2].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                selected[1]:sendEvent("Attack",{Target=Ray.hitObject})

                if enemyFactions==nil then
                    enemyFactions={}
                end
                for j, faction in ipairs(core.factions.records) do
                    if enemyFactions[faction.id]==nil then
                        if types.Actor.isDead(Ray.hitObject)==false and 
                        ((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject) and types.NPC.getFactions(Ray.hitObject)[1]==faction.id)
                          or ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC)and types.Actor.spells(Ray.hitObject)[faction.id.." spellflag"])) 
                        and not(((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject) and types.NPC.getFactions(Ray.hitObject)[1]==ActiveFaction)
                        or ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC)and types.Actor.spells(Ray.hitObject)[ActiveFaction.." spellflag"]))) then
                            enemyFactions[faction.id]=faction.id
                        end
                    end
                end
                

            elseif Cursor.layout.props.resource == GuardTexture and Ray.hitObject then
                print("Send Guard")
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race  and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                selected[1]:sendEvent("Guard",{Target=Ray.hitObject})




            elseif Cursor.layout.props.resource == AttackTexture and Ray.hitObject then
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[2].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                selected[1]:sendEvent("Attack",{Target=Ray.hitObject})
                if enemyFactions==nil then
                    enemyFactions={}
                end
                for j, faction in ipairs(core.factions.records) do
                    if enemyFactions[faction.id]==nil then
                        if types.Actor.isDead(Ray.hitObject)==false and 
                        ((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject) and types.NPC.getFactions(Ray.hitObject)[1]==faction.id)
 --                       or (Ray.hitObject.type==types.Creature and types.Actor.spells(Ray.hitObject)[faction.id.." spellflag"])) then
                          or ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC)and types.Actor.spells(Ray.hitObject)[faction.id.." spellflag"])) then
                            enemyFactions[faction.id]=faction.id
                        end
                    end
                end

            elseif Cursor.layout.props.resource == PickTexture then
                ActorSpeaks=ActorSpeaks-1
                if selected[1].type==types.NPC and ActorSpeaks>0 then
                    for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race  and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                            ambient.playSoundFile(dialogue.sound)
                            break
                        end
                    end
                end
                if Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type.inventory then
                    ObjectToActivate=Ray.hitObject
                end
                if Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type==types.Door then
                    ObjectToActivate=Ray.hitObject
                end
                if Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type==types.Activator then
                    ObjectToActivate=Ray.hitObject
                end
                selected[1]:sendEvent("ActivateObject",{Object=ObjectToActivate})
            end
        end
        Cursor.layout.props.State=""
        
        Cursor.layout.props.resource =MoveTexture
        if Cursor.layout.props.color==util.color.rgb(1,1,0) then
            Cursor.layout.props.color=util.color.rgb(1,1,1)
        end
    end
    
end))


local function SelectedStatut(data)
    Describ.layout.content.Statut.props.text=data.String
    Describ:update()
end

input.registerTriggerHandler("DefendStance", async:callback(function ()
    if SelectedActors[1] then
        for i, selected in ipairs(SelectedActors) do
            selected[1]:sendEvent("DefendStance")
        end
    end
    DefendStance.layout.content[1].props.color=util.color.rgb(1,1,0)
    DefendStance:update()
end))
input.registerTriggerHandler("AttackStance", async:callback(function ()
    if SelectedActors[1] then
        for i, selected in ipairs(SelectedActors) do
            selected[1]:sendEvent("AttackStance")
        end
    end
    AttackStance.layout.content[1].props.color=util.color.rgb(1,1,0)
    AttackStance:update()
end))
input.registerTriggerHandler("NothingStance", async:callback(function ()
    if SelectedActors[1] then
        for i, selected in ipairs(SelectedActors) do
            selected[1]:sendEvent("NothingStance")
        end
    end
    NothingStance.layout.content[1].props.color=util.color.rgb(1,1,0)
    NothingStance:update()
end))
input.registerTriggerHandler("Patrol", async:callback(function ()
    if SelectedActors[1] then
        Cursor.layout.props.resource=MoveTexture
        Cursor.layout.props.color=util.color.rgb(1,1,0)
        Cursor.layout.props.State="Patrol"
        Patrol.layout.content[1].props.color=util.color.rgb(1,1,0)
        Patrol:update()
    end
end))
input.registerTriggerHandler("ForceAttack", async:callback(function ()
    if SelectedActors[1] then
        Cursor.layout.props.resource=AttackTexture
        Cursor.layout.props.color=util.color.rgb(1,1,0)
        Cursor.layout.props.State="ForceAttack"
        ForceAttack.layout.content[1].props.color=util.color.rgb(1,1,0)
        ForceAttack:update()
    end
end))
input.registerTriggerHandler("Guard", async:callback(function ()
    if SelectedActors[1] then
        Cursor.layout.props.resource=GuardTexture
        Cursor.layout.props.color=util.color.rgb(1,1,0)
        Cursor.layout.props.State="Guard"
        Guard.layout.content[1].props.color=util.color.rgb(1,1,0)
        Guard:update()
    end
end))



local function onUpdate(dt)

	if RTS==true then

        if SaveTeams then
            for num, ActorTable in pairs(SaveTeams) do
                Teams[num]={}
                for j, ActorId in ipairs(ActorTable) do
--                    print(ActorId)
                    for k, actor in ipairs(nearby.actors) do
                        if actor.id==ActorId then
                            table.insert(Teams[num], {actor,CreateNumberTeam(num)})
                        end
                    end
                 end
            end
            SaveTeams=nil
        end


        if camera.getMode()~=camera.MODE.Static then
            camera.setMode(camera.MODE.Static)
        end

        dt=tonumber(string.format("%.4f", dt))  
        ActiveFaction=storage.playerSection('RTSEnginecontrols'):get('Faction')
        if storage.playerSection('RTSEnginecontrols'):get('EnemyFaction')~="none" and enemyFactions[storage.playerSection('RTSEnginecontrols'):get('EnemyFaction')]==nil then
            enemyFactions[storage.playerSection('RTSEnginecontrols'):get('EnemyFaction')]=storage.playerSection('RTSEnginecontrols'):get('EnemyFaction')
        end

        if Cursor.layout.props.visible==false then
            Cursor.layout.props.visible=true
        end
        if Minimap.layout.props.visible==false then
            Minimap.layout.props.visible=true
        end
        Ray=nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(Cursor.layout.props.relativePosition),camera.viewportToWorldVector(Cursor.layout.props.relativePosition)*camera.getBaseViewDistance())
        if DeepRay(camera.getPosition()+camera.viewportToWorldVector(Cursor.layout.props.relativePosition),camera.viewportToWorldVector(Cursor.layout.props.relativePosition)*camera.getBaseViewDistance()).hitPos then
            Ray=DeepRay(camera.getPosition()+camera.viewportToWorldVector(Cursor.layout.props.relativePosition),camera.viewportToWorldVector(Cursor.layout.props.relativePosition)*camera.getBaseViewDistance())
        end
            --print(Ray.hitPos) 
		local CameraMove=dt*600

		Up = input.getBooleanActionValue('Up')
		Down = input.getBooleanActionValue('Down')
		
		Right = input.getBooleanActionValue('Right')
		Left = input.getBooleanActionValue('Left')

        
		ZoomOut = input.getBooleanActionValue('ZoomOut')
		ZoomIn = input.getBooleanActionValue('ZoomIn')

        CamAngle = input.getBooleanActionValue('CamAngle')

        
        PlayerAction = input.getBooleanActionValue('ButtonPlayer')

        TeamAdd = input.getBooleanActionValue('ButtonTeamAdd')
		Select = input.getBooleanActionValue('Select')


        if Up==true or Cursor.layout.props.relativePosition.y<0.02 then	
           camera.setStaticPosition(camera.getPosition()+util.vector3(math.sin(camera.getYaw()), math.cos(camera.getYaw()), 0) * CameraMove)
        end
		if Down==true or Cursor.layout.props.relativePosition.y>0.98 then		
           camera.setStaticPosition(camera.getPosition()+util.vector3(math.sin(camera.getYaw()), math.cos(camera.getYaw()), 0) * -CameraMove)
        end
		if Right==true or Cursor.layout.props.relativePosition.x>0.98 then	
            camera.setStaticPosition(camera.getPosition()+util.vector3(math.sin(math.pi/2+camera.getYaw()),  math.cos(math.pi/2+camera.getYaw()), 0) * CameraMove)
        end
		if Left==true or Cursor.layout.props.relativePosition.x<0.02 then	
            camera.setStaticPosition(camera.getPosition()+util.vector3( math.sin(math.pi/2+camera.getYaw()), math.cos(math.pi/2+camera.getYaw()), 0) * -CameraMove)
        end

        if SelectedActors[1]==nil and PlayerAction==true and Cursor.layout.props.color==util.color.rgb(1,1,1) then
            Cursor.layout.props.color=util.color.rgb(0.1,0.8,0.1)
        elseif PlayerAction==false and Cursor.layout.props.color==util.color.rgb(0.1,0.8,0.1) then
            Cursor.layout.props.color=util.color.rgb(1,1,1)
        end


        
		if ZoomIn==true then		
			camera.setStaticPosition(camera.getPosition()+util.vector3(math.cos(camera.getPitch()) * math.sin(camera.getYaw()), math.cos(camera.getPitch()) * math.cos(camera.getYaw()), -math.sin(camera.getPitch())) * CameraMove)
        end

		if ZoomOut==true then	
			camera.setStaticPosition(camera.getPosition()+util.vector3(math.cos(camera.getPitch()) * math.sin(camera.getYaw()), math.cos(camera.getPitch()) * math.cos(camera.getYaw()), -math.sin(camera.getPitch())) * -CameraMove)
        end
             

        if PlayerAction==false then
            if Select==true and SelectTrigger==false then
                Cursor.layout.props.State=""
                if Cursor.layout.props.visible==true then
                    if Collision(Cursor,ShowInventory).UL then
                        Cursor.layout.props.visible=false
                        Cursor:update()
                        
                        I.UI.addMode('Companion', {target = SelectedActors[1][1]})
                    elseif Collision(Cursor,Minimap).UL then
                        --SelectTrigger=true
                        local PositionX=(Collision(Cursor,Minimap).UL.X-5.6)*(Minimap.layout.MaxX-Minimap.layout.MinX)+Minimap.layout.MinX
                        local PositionY=(Collision(Cursor,Minimap).UL.Y-3)*(Minimap.layout.MaxY-Minimap.layout.MinY)+Minimap.layout.MinY
                        if nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5)),
                        camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance()).hitPos then
                            camera.setStaticPosition(camera.getPosition()-nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5)),
                                                    camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance()
                                                    ).hitPos
                                                    +util.vector3(PositionX,PositionY,nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5)),
                                                    camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance()).hitPos.z))
                            core.sendGlobalEvent("Teleport",{object=self,cell=self.cell.name,position=camera.getPosition()})
                        else
--                            ui.showMessage("You have to look at something to move with minimap.")
                            camera.setStaticPosition(util.vector3(PositionX,PositionY,camera.getPosition().z))
                            core.sendGlobalEvent("Teleport",{object=self,cell=self.cell.name,position=camera.getPosition()})
                        end
                    elseif Collision(Cursor,DefendStance).UL then
                        DefendStance.layout.content[1].props.color=util.color.rgb(1,1,0)
                    elseif Collision(Cursor,AttackStance).UL then
                        AttackStance.layout.content[1].props.color=util.color.rgb(1,1,0)
                    elseif Collision(Cursor,NothingStance).UL then
                        NothingStance.layout.content[1].props.color=util.color.rgb(1,1,0)
                    elseif Collision(Cursor,Patrol).UL then
                        Patrol.layout.content[1].props.color=util.color.rgb(1,1,0)
                    elseif Collision(Cursor,ForceAttack).UL then
                        ForceAttack.layout.content[1].props.color=util.color.rgb(1,1,0)
                    elseif Collision(Cursor,Guard).UL then
                        Guard.layout.content[1].props.color=util.color.rgb(1,1,0)
                    else
                        SelectTrigger=true
                    end
                end
            elseif DefendStance.layout.content[1].props.color==util.color.rgb(1,1,0) then
                DefendStance.layout.content[1].props.color=util.color.rgb(1,1,1) 
                for i, selected in ipairs(SelectedActors) do
                    selected[1]:sendEvent("DefendStance")
                end
            elseif AttackStance.layout.content[1].props.color==util.color.rgb(1,1,0) then
                AttackStance.layout.content[1].props.color=util.color.rgb(1,1,1) 
                for i, selected in ipairs(SelectedActors) do
                    selected[1]:sendEvent("AttackStance")
                end
            elseif NothingStance.layout.content[1].props.color==util.color.rgb(1,1,0) then
                NothingStance.layout.content[1].props.color=util.color.rgb(1,1,1) 
                for i, selected in ipairs(SelectedActors) do
                    selected[1]:sendEvent("NothingStance")
                end
            elseif Patrol.layout.content[1].props.color==util.color.rgb(1,1,0) then
                Patrol.layout.content[1].props.color=util.color.rgb(1,1,1)
                Cursor.layout.props.resource=MoveTexture
                Cursor.layout.props.color=util.color.rgb(1,1,0)
                Cursor.layout.props.State="Patrol"
            elseif ForceAttack.layout.content[1].props.color==util.color.rgb(1,1,0) then
                ForceAttack.layout.content[1].props.color=util.color.rgb(1,1,1)
                Cursor.layout.props.resource=AttackTexture
                Cursor.layout.props.color=util.color.rgb(1,1,0)
                Cursor.layout.props.State="ForceAttack"
            elseif Guard.layout.content[1].props.color==util.color.rgb(1,1,0) then
                Guard.layout.content[1].props.color=util.color.rgb(1,1,1)
                Cursor.layout.props.resource=GuardTexture
                Cursor.layout.props.color=util.color.rgb(1,1,0)
                Cursor.layout.props.State="Guard"
            elseif Select==false and SelectTrigger==true then
                SelectTrigger=false
                
                if SelectedArea.layout.props.visible==true then

                    if TeamAdd==false then
                        RAZSelectedActors()
                    end

                    selectArea()


                elseif Ray.hitObject then

                    if (Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature) and types.Actor.isDead(Ray.hitObject)==false and Ray.hitObject~=self and 
                    ((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject)[1]==ActiveFaction) or 
--                    (Ray.hitObject.type==types.Creature and types.Actor.spells(Ray.hitObject)[ActiveFaction.." spellflag"])) then
                      ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC) and types.Actor.spells(Ray.hitObject)[ActiveFaction.." spellflag"])) then
                
                        if DoubleClick.Timer<DoubleClick.Duration then
                            if TeamAdd==false then
                                RAZSelectedActors()
                            end
--                            print("DoubleClick")
                            SelectSame()
                            DoubleClick.Timer=0
                        else
                            DoubleClick.Timer=0

                            if TeamAdd==false then
                                RAZSelectedActors()
                            end
                            table.insert(SelectedActors, {Ray.hitObject,CreateSelected(),CreateLifeBar()})
                            SelectedActors[1][1]:sendEvent("IsSelected",{Player=self})
                            
                            local ActorSpeaks=NumberSpeakingActors
                            for i, selected in ipairs(SelectedActors) do
                                ActorSpeaks=ActorSpeaks-1
                                if selected.type==types.NPC then
                                    for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                                        if dialogue.filterActorRace==types.NPC.record(selected[1]).race and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(selected[1]).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(selected[1]).isMale==true))  then
                                            ambient.playSoundFile(dialogue.sound)
                                            break
                                        end
                                    end
                                end
                                if ActorSpeaks==0 then
                                    break
                                end
                            end
                            Cursor.layout.props.resource = MoveTexture
                        end
                    else
                        RAZSelectedActors()
                        Cursor.layout.props.resource = CursorTexture
                    end
                else
                    RAZSelectedActors()
                    Cursor.layout.props.resource = CursorTexture
                end

            elseif Select==true and SelectTrigger==true and (input.getMouseMoveX()~=0 or input.getMouseMoveY()~=0) then
                if SelectedArea.layout.props.visible==false then
                    SelectedArea.layout.props.visible=true
                    SelectedArea.layout.props.relativePosition=Cursor.layout.props.relativePosition
                    SelectedArea.layout.P0=Cursor.layout.props.relativePosition

                end 


                if SelectedArea.layout.P0.x<Cursor.layout.props.relativePosition.x and SelectedArea.layout.P0.y<Cursor.layout.props.relativePosition.y then
                    SelectedArea.layout.props.relativeSize=Cursor.layout.props.relativePosition-SelectedArea.layout.P0
                    SelectedArea.layout.props.relativePosition=SelectedArea.layout.P0
                elseif SelectedArea.layout.P0.x>Cursor.layout.props.relativePosition.x and SelectedArea.layout.P0.y>Cursor.layout.props.relativePosition.y then
                    SelectedArea.layout.props.relativeSize=SelectedArea.layout.P0-Cursor.layout.props.relativePosition
                    SelectedArea.layout.props.relativePosition=Cursor.layout.props.relativePosition
                elseif SelectedArea.layout.P0.x<Cursor.layout.props.relativePosition.x and SelectedArea.layout.P0.y>Cursor.layout.props.relativePosition.y then
                    SelectedArea.layout.props.relativeSize=util.vector2(Cursor.layout.props.relativePosition.x-SelectedArea.layout.P0.x,SelectedArea.layout.P0.y-Cursor.layout.props.relativePosition.y)
                    SelectedArea.layout.props.relativePosition=SelectedArea.layout.P0-util.vector2(0,SelectedArea.layout.P0.y-Cursor.layout.props.relativePosition.y)
                elseif SelectedArea.layout.P0.x>Cursor.layout.props.relativePosition.x and SelectedArea.layout.P0.y<Cursor.layout.props.relativePosition.y then
                    SelectedArea.layout.props.relativeSize=util.vector2(SelectedArea.layout.P0.x-Cursor.layout.props.relativePosition.x,Cursor.layout.props.relativePosition.y-SelectedArea.layout.P0.y)
                    SelectedArea.layout.props.relativePosition=SelectedArea.layout.P0-util.vector2(SelectedArea.layout.P0.x-Cursor.layout.props.relativePosition.x,0)
                end

                SelectedArea:update()


            end
        end


        if DoubleClick.Timer< DoubleClick.Duration then
            DoubleClick.Timer=DoubleClick.Timer+dt
        end
        if TeamDoubleClick.Timer>0 then
            TeamDoubleClick.Timer=TeamDoubleClick.Timer-dt
        end

        for i, selected in ipairs(SelectedActors) do
            if types.Actor.isDead(selected[1])==true then
                if selected[1] then
                    selected[1]:sendEvent("IsSelected",{Player=nil})
                end
                if selected[2] then
                    selected[2]:destroy()
                end
                if selected[3] then
                    selected[3]:destroy()
                end
                table.remove(SelectedActors,i)
--                SelectedActors[selected]=nil
            end
            if selected[2] and selected[2].layout then
                selected[2].layout.props.relativeSize=util.vector2(50/(selected[1].position-camera.getPosition()):length(),150/(selected[1].position-camera.getPosition()):length())
                selected[2].layout.props.relativePosition=util.vector2(camera.worldToViewportVector(selected[1].position).x/ui.screenSize().x,camera.worldToViewportVector(selected[1].position).y/ui.screenSize().y)
                selected[3].layout.props.relativeSize=util.vector2(50/(selected[1].position-camera.getPosition()):length(),10/(selected[1].position-camera.getPosition()):length())
                selected[3].layout.props.relativePosition=util.vector2(camera.worldToViewportVector(selected[1].position).x/ui.screenSize().x,camera.worldToViewportVector(selected[1].position).y/ui.screenSize().y)
                selected[3].layout.content[1].props.relativeSize=util.vector2(2*types.Actor.stats.dynamic.health(selected[1]).current/types.Actor.stats.dynamic.health(selected[1]).base,2)
                selected[2]:update()
                selected[3]:update()
            end
        end


        if SelectedActors[1] and SelectedActors[1][1] then

            if SelectedActors[1][1].cell~=self.cell and SelectedActors[1][1].cell.name~="" and self.cell.name~="" then
                RAZSelectedActors()
            end
            
            ObjectToActivate=nil
            for i, item in ipairs(nearby.items) do
                if Ray.hitPos and (item.position-Ray.hitPos):length()<20 and item.type~=types.Light then
                    ObjectToActivate=item
                    break
                end
            end
            if (Collision(Cursor,ShowInventory).UL or Collision(Cursor,Minimap).UL or Collision(Cursor,DefendStance).UL or Collision(Cursor,AttackStance).UL or Collision(Cursor,NothingStance).UL or Collision(Cursor,Patrol).UL or Collision(Cursor,ForceAttack).UL or Collision(Cursor,Guard).UL ) and Cursor.layout.props.resource~=CursorTexture then
                Cursor.layout.props.resource=CursorTexture

                if Collision(Cursor,DefendStance).UL or Collision(Cursor,AttackStance).UL or Collision(Cursor,NothingStance).UL or Collision(Cursor,Patrol).UL or Collision(Cursor,ForceAttack).UL or Collision(Cursor,Guard).UL then
                    if Collision(Cursor,DefendStance).UL then
                        StanceExplainations.layout.content[1].props.text=DefendStance.layout.Explaination
                    elseif Collision(Cursor,AttackStance).UL then
                        StanceExplainations.layout.content[1].props.text=AttackStance.layout.Explaination
                    elseif Collision(Cursor,NothingStance).UL then
                        StanceExplainations.layout.content[1].props.text=NothingStance.layout.Explaination
                    elseif Collision(Cursor,Patrol).UL then
                        StanceExplainations.layout.content[1].props.text=Patrol.layout.Explaination
                    elseif Collision(Cursor,ForceAttack).UL then
                        StanceExplainations.layout.content[1].props.text=ForceAttack.layout.Explaination
                    elseif Collision(Cursor,Guard).UL then
                        StanceExplainations.layout.content[1].props.text=Guard.layout.Explaination
                    end

                    if StanceExplainations.layout.props.visible==false then
                        StanceExplainations.layout.props.relativePosition=Cursor.layout.props.relativePosition-util.vector2(0,StanceExplainations.layout.props.relativeSize.y)
                        StanceExplainations.layout.props.visible=true
                    end

                end

            elseif Collision(Cursor,ShowInventory).UL==nil and Collision(Cursor,Minimap).UL==nil and Collision(Cursor,DefendStance).UL==nil and Collision(Cursor,AttackStance).UL==nil and Collision(Cursor,NothingStance).UL==nil and Collision(Cursor,Patrol).UL==nil and Collision(Cursor,ForceAttack).UL==nil and Collision(Cursor,Guard).UL==nil  then
                if Ray.hitObject and Ray.hitObject.type and (Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature ) and types.Actor.isDead(Ray.hitObject)==false then
                    if Cursor.layout.props.State~="Guard" and Cursor.layout.props.State~="Patrol" then 
                        for i,faction in pairs(enemyFactions) do
                            if  ((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject)[1]==faction) or 
                                ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC) and types.Actor.spells(Ray.hitObject)[faction.." spellflag"])) then
                                Cursor.layout.props.resource = AttackTexture
                                break
                            end
                        end
                    end   
                    
                elseif  ObjectToActivate or
                        (Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type==types.Activator) or   
                        (Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type==types.Door) or    
                        (Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type.inventory and Ray.hitObject.type.inventory(Ray.hitObject):getAll()[1] and ((Ray.hitObject.type~=types.NPC and Ray.hitObject.type~=types.Creature) or types.Actor.isDead(Ray.hitObject)==true))  then                        
                    Cursor.layout.props.resource = PickTexture
                elseif Cursor.layout.props.State == "Guard" then
                    Cursor.layout.props.resource = GuardTexture
                elseif Cursor.layout.props.State == "ForceAttack" then
                    Cursor.layout.props.resource = AttackTexture
                elseif Cursor.layout.props.resource ~= MoveTexture then                        
                    Cursor.layout.props.resource = MoveTexture
                end
            end
        elseif PlayerAction==true and Ray.hitObject and Ray.hitObject.type and Ray.hitObject.type==types.Door and types.Door.isTeleport(Ray.hitObject) then
            Cursor.layout.props.resource =DoorTexture
        elseif  PlayerAction==true and Ray.hitObject and Ray.hitObject.type and (Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature) and types.Actor.isDead(Ray.hitObject)==false then
            Cursor.layout.props.resource =SpeakTexture
        elseif Cursor.layout.props.resource~=CursorTexture then
            Cursor.layout.props.resource=CursorTexture
        end

        for j=0,9 do
            if Teams[tostring(j)] then
                for i, selected in ipairs(Teams[tostring(j)]) do
                    if types.Actor.isDead(selected[1])==true then
                        if selected[1] then
                            selected[1]:sendEvent("IsSelected",{Player=nil})
                        end
                        if selected[2] then
                            selected[2]:destroy()
                        end
--                        Teams[tostring(j)][selected]=nil
                        table.remove(Teams[tostring(j)],i)

                    end
                    if selected and selected[2]and selected[2].layout then
                        selected[2].layout.props.textSize=FontSize/(selected[1].position-camera.getPosition()):length()
                        ---------------------------------------------------------
                        selected[2].layout.props.relativePosition=util.vector2(camera.worldToViewportVector(selected[1].position).x/ui.screenSize().x,camera.worldToViewportVector(selected[1].position).y/ui.screenSize().y)
                        --------------------------------------------------------------------------
                        selected[2]:update()
                    end
                end
            end
        end


        if StanceExplainations.layout.props.visible==true and Collision(Cursor,DefendStance).UL==nil and Collision(Cursor,AttackStance).UL==nil and Collision(Cursor,NothingStance).UL==nil and Collision(Cursor,Patrol).UL==nil and Collision(Cursor,ForceAttack).UL==nil and Collision(Cursor,Guard).UL==nil then
            StanceExplainations.layout.props.visible=false
        end

        if CamAngle==true then
            camera.setPitch(camera.getPitch()+input.getMouseMoveY()*dt/10)
            camera.setYaw(camera.getYaw()+input.getMouseMoveX()*dt/10)
        elseif Cursor.layout.props.relativePosition.x+input.getMouseMoveX()*dt/10<1.1 and Cursor.layout.props.relativePosition.x+input.getMouseMoveX()*dt/10>-0.1 and Cursor.layout.props.relativePosition.y+input.getMouseMoveY()*dt/10<1.1 and Cursor.layout.props.relativePosition.y+input.getMouseMoveY()*dt/10>-0.1 then
            Cursor.layout.props.relativePosition=Cursor.layout.props.relativePosition+util.vector2(input.getMouseMoveX()/1000,input.getMouseMoveY()/1000) 
        end


        if SelectedActors[1] and SelectedActors[1][1] then
            Describ.layout.content.Lifebar.content[1].props.relativeSize=util.vector2(2*types.Actor.stats.dynamic.health(SelectedActors[1][1]).current/types.Actor.stats.dynamic.health(SelectedActors[1][1]).base,2)
            Describ.layout.content.Health.props.text=string.format("%.0f", types.Actor.stats.dynamic.health(SelectedActors[1][1]).current).."/"..types.Actor.stats.dynamic.health(SelectedActors[1][1]).base
            if Describ.layout.Actor~=SelectedActors[1][1] or Describ.layout.props.visible==false then
                Describ.layout.Actor=SelectedActors[1][1]
                Describ.layout.props.visible=true
                ShowInventory.layout.props.visible=true
                DefendStance.layout.props.visible=true
                AttackStance.layout.props.visible=true
                NothingStance.layout.props.visible=true
                Patrol.layout.props.visible=true
                ForceAttack.layout.props.visible=true
                Guard.layout.props.visible=true
                if SelectedActors[1][1].type==types.NPC then
                    Describ.layout.content.Class.props.text=types.NPC.record(SelectedActors[1][1]).class:gsub("^%l", string.upper)
                else
                    Describ.layout.content.Class.props.text=types.Creature.record(SelectedActors[1][1]).name:gsub("^%l", string.upper)
                end
            end

        elseif  SelectedActors[1]==nil and Describ.layout.props.visible==true then
            Describ.layout.props.visible=false
            ShowInventory.layout.props.visible=false
            DefendStance.layout.props.visible=false
            AttackStance.layout.props.visible=false
            NothingStance.layout.props.visible=false
            Patrol.layout.props.visible=false
            ForceAttack.layout.props.visible=false
            Guard.layout.props.visible=false
        end

--[[        if Ray.hitObject and Ray.hitObject.type and (Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature) and 
        ((Ray.hitObject.type==types.NPC and (types.NPC.getFactions(Ray.hitObject)[1]~=ActiveFaction or types.Actor.isDead(Ray.hitObject)==true )) 
        or (Ray.hitObject.type==types.Creature and (types.Actor.spells(Ray.hitObject)[ActiveFaction.." spellflag"]==nil or types.Actor.isDead(Ray.hitObject)==true ))) then
]]--
        if Ray.hitObject and Ray.hitObject.type and (Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature) and types.Actor.isDead(Ray.hitObject)==false and
                (not((Ray.hitObject.type==types.NPC and types.NPC.getFactions(Ray.hitObject)[1]==ActiveFaction ) 
                    or ((Ray.hitObject.type==types.Creature or Ray.hitObject.type==types.NPC) and (types.Actor.spells(Ray.hitObject)[ActiveFaction.." spellflag"])))
                or Cursor.layout.props.State=="Guard" or Cursor.layout.props.State=="ForceAttack") then
            if ActorQuickInfos.layout.props.visible==false or (ActorQuickInfos.layout.props.visible==true and ActorQuickInfos.layout.Actor~=Ray.hitObject) then
                ActorQuickInfos.layout.props.visible=true
                ActorQuickInfos.layout.Actor=Ray.hitObject
                if Ray.hitObject.type.record(Ray.hitObject).name~="" then
                    ActorQuickInfos.layout.content.Name.props.text=Ray.hitObject.type.record(Ray.hitObject).name
                else
                    ActorQuickInfos.layout.content.Name.props.text=Ray.hitObject.type.record(Ray.hitObject).id
                end
            end
            ActorQuickInfos.layout.content.Lifebar.content[1].props.relativeSize=util.vector2(2*types.Actor.stats.dynamic.health(Ray.hitObject).current/types.Actor.stats.dynamic.health(Ray.hitObject).base,2)
            ActorQuickInfos.layout.props.relativePosition=Cursor.layout.props.relativePosition
        elseif ActorQuickInfos.layout.props.visible==true then
            ActorQuickInfos.layout.props.visible=false
        end



        Cursor:update()
        ActorQuickInfos:update()
        Describ:update()
        DefendStance:update()
        AttackStance:update()
        NothingStance:update()
        Patrol:update()
        ForceAttack:update()
        Guard:update()
        StanceExplainations:update()
        ShowInventory:update()
        Minimap:update()


	end
end









local function CreateTeam(num)
--    print("choose team")
    if Teams[num] and Teams[num][1] then
        for i , actor in ipairs(Teams[num]) do
            actor[2]:destroy()  
        end
    end
    Teams[num]={}
    for i, actor in ipairs(SelectedActors) do
        table.insert(Teams[num], {actor[1],CreateNumberTeam(num)})
    end
end

local function SelecteTeam(num)

--    print("select team")
    RAZSelectedActors()

    TeamDoubleClick.Timer=TeamDoubleClick.Duration
    TeamDoubleClick.Team=num
    if Teams[num] then
        local ActorSpeaks=NumberSpeakingActors
        for i, actor in ipairs(Teams[num]) do
            table.insert(SelectedActors, {actor[1],CreateSelected(),CreateLifeBar()})     
            ActorSpeaks=ActorSpeaks-1
            if actor.type==types.NPC and ActorSpeaks>0 then
                for j, dialogue in ipairs(core.dialogue.voice.records[4].infos) do
                    if dialogue.filterActorRace==types.NPC.record(actor).race and dialogue.filterActorDisposition==90 and ((dialogue.filterActorGender=="female" and types.NPC.record(actor).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(actor).isMale==true))  then
                        ambient.playSoundFile(dialogue.sound)
                        break
                    end
                end
            end
            Cursor.layout.props.resource = MoveTexture
        end
    end
end


local function TeamsSelections(num)
    if TeamAdd==true then
        CreateTeam(num)
    elseif TeamDoubleClick.Timer>0 and TeamDoubleClick.Team==num and SelectedActors[1] then
        if nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5)),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance()).hitPos then
            camera.setStaticPosition(camera.getPosition()-nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5)),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance()).hitPos+SelectedActors[1][1].position)
            core.sendGlobalEvent("Teleport",{object=self,cell=self.cell.name,position=camera.getPosition()})
        else
            camera.setStaticPosition(util.vector3(SelectedActors[1][1].position.x,SelectedActors[1][1].position.y,camera.getPosition().z))
            core.sendGlobalEvent("Teleport",{object=self,cell=self.cell.name,position=camera.getPosition()})
        end
    else
        SelecteTeam(num)
    end
end

input.registerTriggerHandler("Team1", async:callback(function ()
    if RTS==true then
        TeamsSelections("1")
    end
end))

input.registerTriggerHandler("Team2", async:callback(function ()
    if RTS==true then
        TeamsSelections("2")
    end
end))

input.registerTriggerHandler("Team3", async:callback(function ()
    if RTS==true then
        TeamsSelections("3")
    end
end))

input.registerTriggerHandler("Team4", async:callback(function ()
    if RTS==true then
        TeamsSelections("4")
    end
    
end))

input.registerTriggerHandler("Team5", async:callback(function ()
    if RTS==true then
        TeamsSelections("5")
    end 
end))

input.registerTriggerHandler("Team6", async:callback(function ()
    if RTS==true then
        TeamsSelections("6")
    end 
end))

input.registerTriggerHandler("Team7", async:callback(function ()
    if RTS==true then
        TeamsSelections("7")
    end  
end))

input.registerTriggerHandler("Team8", async:callback(function ()
    if RTS==true then
        TeamsSelections("8")
    end 
end))

input.registerTriggerHandler("Team9", async:callback(function ()
    if RTS==true then
        TeamsSelections("9")
    end 
end))

input.registerTriggerHandler("Team0", async:callback(function ()
    if RTS==true then
        TeamsSelections("0")
    end  
end))



local function onSave()
    SaveTeams={}
    for j=0,9 do
--        print(j)
        if Teams[tostring(j)] then
            SaveTeams[tostring(j)]={}
            for i, ActorTable in ipairs(Teams[tostring(j)]) do
                table.insert(SaveTeams[tostring(j)],ActorTable[1].id)
--                print(ActorTable[1].id)
            end
        end
    end
	return{SaveRTS=RTS,SaveTeams=SaveTeams,enemyFactions=enemyFactions}
end

local function onLoad(data)
    if data.SaveTeams then
        SaveTeams=data.SaveTeams
    end
    if data.enemyFactions then
        enemyFactions=data.enemyFactions
    end
    if data.SaveRTS and data.SaveRTS==true then
        camera.setMode(camera.MODE.Static)
        interfaces.Controls.overrideMovementControls(true)
        interfaces.Controls.overrideCombatControls(true)
        core.sendGlobalEvent("StartRTS",{Player=self})
        Cursor.layout.props.visible=true
        Cursor:update()
        RTS=data.SaveRTS
    end
end

local function onTeleported()
    ---Doesn't works, self.cell== unloading cell -_-
    if LastCell~=self.cell and self.cell.isExterior==false then
        camera.setMode(camera.MODE.Static)
		camera.setStaticPosition(camera.getPosition()+util.vector3(0,0,500))
		camera.setPitch(camera.getPitch())
		camera.setYaw(camera.getYaw()) 
--        print("OK")
    end
end


return {
	eventHandlers = {SelectedStatut=SelectedStatut},
	engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
		onUpdate = onUpdate,
        onTeleported=onTeleported
	}

}