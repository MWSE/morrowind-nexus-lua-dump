local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local async = require('openmw.async')


local function Activate(data)
    print("door")
    if types.Lockable.getLockLevel(self)>0 and types.Lockable.getKeyRecord(self) and types.Lockable.isLocked(self)==true and types.Actor.inventory(data.actor):findAll("lockpick")[1]~=nil and types.Lockable.getKeyRecord(self) and types.Lockable.getKeyRecord(self).name=="ToLockpick" then
        core.sendGlobalEvent("Lockpick",{Lockable=self,Actor=data.actor,Value=types.Lockable.getLockLevel(self)})
    elseif types.Lockable.getLockLevel(self)>0 and types.Lockable.isLocked(self)==true then
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="blowtorch"})
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="hacpuzzle"})
    elseif types.Lockable.isLocked(self)==false and types.Door.isTeleport(self)==true and data.type=="DoorTransition" then
   		core.sendGlobalEvent('Teleport',
			{ object = data.actor, DestCell="DoorStransition", position = util.vector3(0,-400,0), rotation = nil})
    end

    
    self:activateBy(data.actor)

end


local function onUpdate()


end


return {
    eventHandlers = {onActivated=Activate
    },
	engineHandlers = {
        --onActivated=Activate,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
