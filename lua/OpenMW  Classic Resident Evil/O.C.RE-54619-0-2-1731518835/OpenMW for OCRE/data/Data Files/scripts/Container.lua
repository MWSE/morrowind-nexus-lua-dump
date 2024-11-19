local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local OriginPos
local OpenTimer=1
local Player


local function Start()
    if string.find(types.Container.record(self).mwscript,"pushable")~=nil then
        OriginPos=self.position
    end
end 

local function End()
    if string.find(types.Container.record(self).mwscript,"pushable")~=nil then
        core.sendGlobalEvent('PushContainer', {Container=self.object, Way=nil, startPos=OriginPos})
    end
end

local function Activate(data)
    if string.find(types.Container.record(self).mwscript,"climbable")~=nil and self.position.z+10>=data.position.z then
        core.sendGlobalEvent('Teleport', {object=data, position=util.vector3((data.position.x+self.position.x)/2,(data.position.y+self.position.y)/2,nearby.castRay(self.position,util.transform.move(0,0,200)*self.position).hitPos.z+10),rotation=nil})
    elseif types.Lockable.getLockLevel(self)>0 and types.Lockable.getKeyRecord(self).name=="ToLockpick" and types.Lockable.isLocked(self)==true and types.Actor.inventory(data.actor):findAll("lockpick")[1]~=nil then
        core.sendGlobalEvent("Lockpick",{Lockable=self,Actor=data.actor,Value=types.Lockable.getLockLevel(self)})
        print("container activated")
    elseif types.Container.record(self).mwscript=="_container_linked" then
        OpenTimer=core.getGameTime()
        Player=data
    elseif string.find(types.Container.record(self).mwscript,"climbable")==nil then
        data:sendEvent('ActiveContainer',{container=self}) 
    end
end


local function onUpdate()


    if OpenTimer>0 and core.getGameTime()-OpenTimer>16 then
        OpenTimer=0
        core.sendGlobalEvent('Container', {container=self, player=Player, action="activate"})
    end

    --print(types.Container.record(self).mwscript)
    if string.find(types.Container.record(self).mwscript,"pushable") then
        local XPchecker = nearby.castRay(util.vector3(2,0,0)+nearby.castRay(self.position,util.vector3(200,0,0)+self.position).hitPos,util.vector3(10,0,0)+nearby.castRay(self.position,util.vector3(200,0,0)+self.position).hitPos,{radius=40})
        local YPchecker = nearby.castRay(util.transform.move(0,2,0)*nearby.castRay(self.position,util.transform.move(0,200,0)*self.position).hitPos,util.transform.move(0,10,0)*nearby.castRay(self.position,util.transform.move(0,200,0)*self.position).hitPos,{radius=40})
        local XMchecker = nearby.castRay(util.transform.move(-2,0,0)*nearby.castRay(self.position,util.transform.move(-200,0,0)*self.position).hitPos,util.transform.move(-10,0,0)*nearby.castRay(self.position,util.transform.move(-200,0,0)*self.position).hitPos,{radius=40})
        local YMchecker = nearby.castRay(util.transform.move(0,-2,0)*nearby.castRay(self.position,util.transform.move(0,-200,0)*self.position).hitPos,util.transform.move(0,-10,0)*nearby.castRay(self.position,util.transform.move(0,-200,0)*self.position).hitPos,{radius=40})
        

        if XPchecker.hit == true and XMchecker.hit == false and XPchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="X+", startPos=nil})
            --print(XPchecker.hitObject)
        end
        if XMchecker.hit == true and XPchecker.hit == false and XMchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="X-", startPos=nil})
            --print(XMchecker.hitObject)
        end
        if YPchecker.hit == true and YMchecker.hit == false and YPchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="Y+", startPos=nil})
            --print(YPchecker.hitObject)
        end
        if YMchecker.hit == true and YPchecker.hit ==false and YMchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="Y-", startPos=nil})
            --print(YMchecker.hitObject)
        end
    end

end


return {
	engineHandlers = {
        onActive=Start,
        onInactive=End,
        onActivated=Activate,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
