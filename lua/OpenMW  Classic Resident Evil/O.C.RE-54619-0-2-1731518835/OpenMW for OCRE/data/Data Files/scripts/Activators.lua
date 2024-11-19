local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
Player=nil



local function Activate(data)
    print("activator")
    core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="crowbarvalue"})
    Player=data.actor

end


local function onUpdate()
    if Player then
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=Player,Variable="electricalpanelpuzzle"})
    end

end


return {
    eventHandlers = {onActivated=Activate},
	engineHandlers = {
        --onActivated=Activate,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
