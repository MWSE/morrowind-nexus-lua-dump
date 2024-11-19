local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')


local function Activate(data)
    print("door")
    if types.Lockable.getLockLevel(self)>0 and types.Lockable.getKeyRecord(self) and types.Lockable.isLocked(self)==true and types.Actor.inventory(data.actor):findAll("lockpick")[1]~=nil then
        if types.Lockable.getKeyRecord(self).name=="ToLockpick" then
            core.sendGlobalEvent("Lockpick",{Lockable=self,Actor=data.actor,Value=types.Lockable.getLockLevel(self)})
            print("door activated")
        end
    end
end


local function onUpdate()


end


return {
    eventHandlers = {onActivated=Activate},
	engineHandlers = {
        --onActivated=Activate,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
