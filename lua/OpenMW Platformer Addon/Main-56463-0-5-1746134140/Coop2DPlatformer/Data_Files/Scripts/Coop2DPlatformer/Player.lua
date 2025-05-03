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


input.registerAction {
	key = 'P1Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P1Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P2Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P2Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P3Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P3Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P4Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'P4Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'CoopPlayers',
	name = '',
	description = '',
	defaultValue = false,
}



input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P1Jump",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P1Activate",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P2Jump",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P2Activate",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P3Jump",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P3Activate",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P4Jump",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'CoopPlayers',
    key = "P4Activate",
})


I.Settings.registerPage {
    key = 'CoopPlayersSettingsPage',
    l10n = 'CoopPlayersSettings',
    name = 'Platformer  Settings',
    description = 'Control configurations.',
}

I.Settings.registerGroup {
    key = 'ControlsP1',
    page = 'CoopPlayersSettingsPage',
    l10n = 'CoopPlayerscontrols',
    name = 'Player 0ne controls',
    description = 'Configuration of controls for Player One.',
    permanentStorage = false,
    settings = {
        {
            key = "P1Right",
            renderer = "inputBinding",
            name = "Right",
            description = 'Move player one right.',
            default = "d",
            argument = {
                type = "action",
                key = "P1Right"
        	},
		},
        {
            key = "P1Left",
            renderer = "inputBinding",
            name = "Left",
            description = 'Move player one left.',
            default = "q",
            argument = {
                type = "action",
                key = "P1Left"
        	},
		},
        {
            key = "P1Jump",
            renderer = "inputBinding",
            name = "Jump",
            description = 'The player one Jump',
            default = "z",
            argument = {
                type = "trigger",
                key = "P1Jump"
        	},
		},
        {
            key = "P1Activate",
            renderer = "inputBinding",
            name = "Activate",
            description = 'The player one Activate',
            default = "s",
            argument = {
                type = "trigger",
                key = "P1Activate"
        	},
		},
   	},
}



I.Settings.registerGroup {
    key = 'ControlsP2',
    page = 'CoopPlayersSettingsPage',
    l10n = 'CoopPlayerscontrols',
    name = 'Player Two controls',
    description = 'Configuration of controls for Player Two.',
    permanentStorage = false,
    settings = {
		{
            key = "P2Right",
            renderer = "inputBinding",
            name = "Right",
            description = 'Move player two right.',
            default = "m",
            argument = {
                type = "action",
                key = "P2Right"
        	},
		},
        {
            key = "P2Left",
            renderer = "inputBinding",
            name = "Left",
            description = 'Move player two left.',
            default = "k",
            argument = {
                type = "action",
                key = "P2Left"
        	},
		},
        {
            key = "P2Jump",
            renderer = "inputBinding",
            name = "Jump",
            description = 'The player two Jump',
            default = "o",
            argument = {
                type = "trigger",
                key = "P2Jump"
        	},
		},
        {
            key = "P2Activate",
            renderer = "inputBinding",
            name = "Activate",
            description = 'The player two Activate',
            default = "l",
            argument = {
                type = "trigger",
                key = "P2Activate"
        	},
		},
   	},
}


I.Settings.registerGroup {
    key = 'ControlsP3',
    page = 'CoopPlayersSettingsPage',
    l10n = 'CoopPlayerscontrols',
    name = 'Player Three controls',
    description = 'Configuration of controls for Player Three.',
    permanentStorage = false,
    settings = {
		{
            key = "P3Right",
            renderer = "inputBinding",
            name = "Right",
            description = 'Move player three right.',
            default = "b",
            argument = {
                type = "action",
                key = "P3Right"
        	},
		},
        {
            key = "P3Left",
            renderer = "inputBinding",
            name = "Left",
            description = 'Move player three left.',
            default = "c",
            argument = {
                type = "action",
                key = "P3Left"
        	},
		},
        {
            key = "P3Jump",
            renderer = "inputBinding",
            name = "Jump",
            description = 'The player three Jump',
            default = "f",
            argument = {
                type = "trigger",
                key = "P3Jump"
        	},
		},
        {
            key = "P3Activate",
            renderer = "inputBinding",
            name = "Activate",
            description = 'The player three Activate',
            default = "v",
            argument = {
                type = "trigger",
                key = "P3Activate"
        	},
		},
   	},
}


I.Settings.registerGroup {
    key = 'ControlsP4',
    page = 'CoopPlayersSettingsPage',
    l10n = 'CoopPlayerscontrols',
    name = 'Player Three controls',
    description = 'Configuration of controls for Player Three.',
    permanentStorage = false,
    settings = {
		{
            key = "P4Right",
            renderer = "inputBinding",
            name = "Right",
            description = 'Move player four right.',
            default = "j",
            argument = {
                type = "action",
                key = "P4Right"
        	},
		},
        {
            key = "P4Left",
            renderer = "inputBinding",
            name = "Left",
            description = 'Move player four left.',
            default = "g",
            argument = {
                type = "action",
                key = "P4Left"
        	},
		},
        {
            key = "P4Jump",
            renderer = "inputBinding",
            name = "Jump",
            description = 'The player four Jump',
            default = "y",
            argument = {
                type = "trigger",
                key = "P4Jump"
        	},
		},
        {
            key = "P4Activate",
            renderer = "inputBinding",
            name = "Activate",
            description = 'The player four Activate',
            default = "h",
            argument = {
                type = "trigger",
                key = "P4Activate"
        	},
		},
   	},
}

local PlayerOne={}
local PlayerTwo={}
local PlayerThree={}
local PlayerFour={}
local MinPosition=nil
local MaxPosition=nil
local Platformer=false


input.registerTriggerHandler("P1Jump", async:callback(function ()
    if Platformer==true and PlayerOne.position then
        PlayerOne:sendEvent("Jump",{})

    end
end))
input.registerTriggerHandler("P1Activate", async:callback(function ()
    if Platformer==true and PlayerOne.position then
        PlayerOne:sendEvent("Activate",{})
    end
end))
input.registerTriggerHandler("P2Jump", async:callback(function ()
    if Platformer==true and PlayerTwo.position then
        PlayerTwo:sendEvent("Jump",{})
    end
end))
input.registerTriggerHandler("P2Activate", async:callback(function ()
    if Platformer==true and PlayerTwo.position then
        PlayerTwo:sendEvent("Activate",{})
    end
end))
input.registerTriggerHandler("P3Jump", async:callback(function ()
    if Platformer==true and PlayerThree.position then
        PlayerThree:sendEvent("Jump",{})
    end
end))
input.registerTriggerHandler("P3Activate", async:callback(function ()
    if Platformer==true and PlayerThree.position then
        PlayerThree:sendEvent("Activate",{})
    end
end))
input.registerTriggerHandler("P4Jump", async:callback(function ()
    if Platformer==true and PlayerFour.position then
        PlayerFour:sendEvent("Jump",{})
    end
end))
input.registerTriggerHandler("P4Activate", async:callback(function ()
    if Platformer==true and PlayerFour.position then
        PlayerFour:sendEvent("Activate",{})
    end
end))




local function onSave()
	return{PlayerOne=PlayerOne, PlayerTwo=PlayerTwo, PlayerThree=PlayerThree}
end

local function onLoad(data)
	if data.PlayerOne then
		PlayerOne=data.PlayerOne
	end
	if data.PlayerTwo then
		PlayerTwo=data.PlayerTwo
	end
	if data.PlayerThree then
		PlayerThree=data.PlayerThree
	end
	if data.PlayerFour then
		PlayerFour=data.PlayerFour
	end
end

camera.setMode(camera.MODE.Static)
local P1Pos=util.vector3(0,0,0)
local P2Pos=util.vector3(0,0,0)
local P3Pos=util.vector3(0,0,0)
local P4Pos=util.vector3(0,0,0)


local function StartPlatformer()
    print("Start")

    for i, actor in ipairs(nearby.actors) do
        print(actor.recordId)
        if actor.recordId=="playerone" then
            PlayerOne=actor
            MinPosition=PlayerOne.position+util.vector3(0,-200,-200)
            MaxPosition=PlayerOne.position+util.vector3(0,200,200)
        elseif actor.recordId=="playertwo" then
            PlayerTwo=actor
        elseif actor.recordId=="playerthree" then
            PlayerThree=actor
        elseif actor.recordId=="playerfour" then
            PlayerFour=actor
        end
    end


    if PlayerOne.position then 
        interfaces.Controls.overrideMovementControls(true)
        interfaces.Controls.overrideCombatControls(true)
        interfaces.Controls.overrideUiControls(true)
        types.Actor.activeEffects(self):set(1000,"Chameleon")
        types.Actor.activeEffects(self):set(1000,"Invisibility")
        types.Actor.activeEffects(self):set(1000,"Levitate")
        types.Actor.activeEffects(self):set(1000,"Sanctuary")
        types.Actor.activeEffects(self):set(1000,"WaterBreathing")
        types.Actor.activeEffects(self):set(1000,"Invisibility")
        core.sendGlobalEvent("Players",{P1=PlayerOne,P2=PlayerTwo,P3=PlayerThree,P4=PlayerFour})
        Platformer=true
    else
        ui.showMessage("You need a \"PlayerOne\" NPC to start.")
    end
end


local function StopPlatformer()
    interfaces.Controls.overrideMovementControls(false)
    interfaces.Controls.overrideCombatControls(false)
    interfaces.Controls.overrideUiControls(false)
    types.Actor.activeEffects(self):set(0,"Chameleon")
    types.Actor.activeEffects(self):set(0,"Invisibility")
    types.Actor.activeEffects(self):set(0,"Levitate")
    types.Actor.activeEffects(self):set(0,"Sanctuary")
    types.Actor.activeEffects(self):set(0,"WaterBreathing")
    types.Actor.activeEffects(self):set(0,"Invisibility")
    print("Stop")
    core.sendGlobalEvent("Teleport",{object=self,position=PlayerOne.position})
    PlayerOne={}
    PlayerTwo={}
    PlayerThree={}
    PlayerFour={}
    camera.setMode(camera.MODE.ThirdPerson)
    Platformer=false
end

local function onUpdate(dt)
    if Platformer==true then
        MinPosition=camera.getPosition()+util.vector3(-camera.getPosition().x+PlayerOne.position.x,0,0)
        MaxPosition=camera.getPosition()+util.vector3(-camera.getPosition().x+PlayerOne.position.x,0,0)
        self.controls.jump=true


        P1Right = input.getBooleanActionValue('P1Right')
        P1Left = input.getBooleanActionValue('P1Left')
        P2Right = input.getBooleanActionValue('P2Right')
        P2Left = input.getBooleanActionValue('P2Left')
        P3Right = input.getBooleanActionValue('P3Right')
        P3Left = input.getBooleanActionValue('P3Left')
        P4Right = input.getBooleanActionValue('P4Right')
        P4Left = input.getBooleanActionValue('P4Left')

        if P1Right and PlayerOne.position then
            PlayerOne:sendEvent("Right",{})
        elseif P1Left and PlayerOne.position then
            PlayerOne:sendEvent("Left",{})
        end

        if P2Right and PlayerTwo.position then
            PlayerTwo:sendEvent("Right",{})
        elseif P2Left and PlayerTwo.position then
            PlayerTwo:sendEvent("Left",{})
        end

        if P3Right and PlayerThree.position then
            PlayerThree:sendEvent("Right",{})
        elseif P3Left and PlayerThree.position then
            PlayerThree:sendEvent("Left",{})
        end

        if P4Right and PlayerFour.position then
            PlayerFour:sendEvent("Right",{})
        elseif P4Left and PlayerFour.position then
            PlayerFour:sendEvent("Left",{})
        end



        if PlayerOne.count>0 then
            P1Pos=PlayerOne.position
        end
        
        --print(PlayerOne.count)
        --print(P1Pos)
        
        
        if PlayerOne.position then
            if PlayerOne.position.y<MinPosition.y then
                MinPosition=util.vector3(MinPosition.x,PlayerOne.position.y,MinPosition.z)
            elseif PlayerOne.position.y>MaxPosition.y then
                MaxPosition=util.vector3(MaxPosition.x,PlayerOne.position.y,MaxPosition.z)
            end
            if PlayerOne.position.z<MinPosition.z then
                MinPosition=util.vector3(MinPosition.x,MinPosition.y,PlayerOne.position.z)
            elseif PlayerOne.position.z>MaxPosition.z then
                MaxPosition=util.vector3(MaxPosition.x,MaxPosition.y,PlayerOne.position.z)
            end
        end

        if PlayerTwo.position then
            if PlayerTwo.position.y<MinPosition.y then
                MinPosition=util.vector3(MinPosition.x,PlayerTwo.position.y,MinPosition.z)
            elseif PlayerTwo.position.y>MaxPosition.y then
                MaxPosition=util.vector3(MaxPosition.x,PlayerTwo.position.y,MaxPosition.z)
            end
            if PlayerTwo.position.z<MinPosition.z then
                MinPosition=util.vector3(MinPosition.x,MinPosition.y,PlayerTwo.position.z)
            elseif PlayerTwo.position.z>MaxPosition.z then
                MaxPosition=util.vector3(MaxPosition.x,MaxPosition.y,PlayerTwo.position.z)
            end
        end

        if PlayerThree.position then
            if PlayerThree.position.y<MinPosition.y then
                MinPosition=util.vector3(MinPosition.x,PlayerThree.position.y,MinPosition.z)
            elseif PlayerThree.position.y>MaxPosition.y then
                MaxPosition=util.vector3(MaxPosition.x,PlayerThree.position.y,MaxPosition.z)
            end
            if PlayerThree.position.z<MinPosition.z then
                MinPosition=util.vector3(MinPosition.x,MinPosition.y,PlayerThree.position.z)
            elseif PlayerThree.position.z>MaxPosition.z then
                MaxPosition=util.vector3(MaxPosition.x,MaxPosition.y,PlayerThree.position.z)
            end
        end
        
        if PlayerFour.position then
            if PlayerFour.position.y<MinPosition.y then
                MinPosition=util.vector3(MinPosition.x,PlayerFour.position.y,MinPosition.z)
            elseif PlayerFour.position.y>MaxPosition.y then
                MaxPosition=util.vector3(MaxPosition.x,PlayerFour.position.y,MaxPosition.z)
            end
            if PlayerFour.position.z<MinPosition.z then
                MinPosition=util.vector3(MinPosition.x,MinPosition.y,PlayerFour.position.z)
            elseif PlayerFour.position.z>MaxPosition.z then
                MaxPosition=util.vector3(MaxPosition.x,MaxPosition.y,PlayerFour.position.z)
            end
        end

        camera.setMode(camera.MODE.Static)
        
        camera.setStaticPosition((MinPosition+MaxPosition)/2+util.vector3(-400-(MinPosition-MaxPosition):length()*0.5,0,250))

        camera.setPitch(math.pi/10)
        camera.setYaw(math.pi/2)
    end

end


local function onFrame()
    if Platformer==true then
        if PlayerOne.position then
            PlayerOne:sendEvent("CheckPlatform",{})
        end
        if PlayerTwo.position then
            PlayerTwo:sendEvent("CheckPlatform",{})
        end
        if PlayerThree.position then
            PlayerThree:sendEvent("CheckPlatform",{})
        end
        if PlayerFour.position then
            PlayerFour:sendEvent("CheckPlatform",{})
        end
    end
end

return {
	eventHandlers = { StartPlatformer=StartPlatformer, StopPlatformer=StopPlatformer},
	engineHandlers = {

		onUpdate = onUpdate,
        onFrame = onFrame,
	}

}