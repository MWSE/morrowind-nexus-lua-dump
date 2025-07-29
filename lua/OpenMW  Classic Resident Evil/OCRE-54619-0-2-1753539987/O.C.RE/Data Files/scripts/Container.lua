local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local OriginPos
local OpenTimer=1
local Player


local function Start()
    if string.find(types.Container.records[self.recordId].mwscript,"pushable")~=nil then
        OriginPos=self.position
    end
end 

local function End()
    if string.find(types.Container.records[self.recordId].mwscript,"pushable")~=nil then
        core.sendGlobalEvent('PushContainer', {Container=self.object, Way=nil, startPos=OriginPos})
    end
end

local function Activate(data)
    print("activate")
    if string.find(types.Container.records[self.recordId].mwscript,"climbable")~=nil then--and self.position.z+10>=data.position.z then
 --       core.sendGlobalEvent('Teleport', {object=data, position=self.position+util.vector3(0,0,self:getBoundingBox().halfSize.z*2),rotation=nil})
        core.sendGlobalEvent('Teleport', {object=data, position=data.position+util.vector3(math.sin(data.rotation:getYaw())*30, math.cos(data.rotation:getYaw())*30,self:getBoundingBox().halfSize.z*2),rotation=nil})

        
--        core.sendGlobalEvent('Teleport', {object=data, position=util.vector3((data.position.x+self.position.x)/2,(data.position.y+self.position.y)/2,nearby.castRay(self.position,util.transform.move(0,0,200)*self.position).hitPos.z+10),rotation=nil})
    elseif types.Lockable.getLockLevel(self)>0 and types.Lockable.getKeyrecords[self.recordId].name=="ToLockpick" and types.Lockable.isLocked(self)==true and types.Actor.inventory(data.actor):findAll("lockpick")[1]~=nil then
        core.sendGlobalEvent("Lockpick",{Lockable=self,Actor=data.actor,Value=types.Lockable.getLockLevel(self)})
        print("container activated")
    elseif types.Container.records[self.recordId].mwscript=="_container_linked" then
        OpenTimer=core.getSimulationTime()
        Player=data
    elseif string.find(types.Container.records[self.recordId].mwscript,"climbable")==nil then
        data:sendEvent('ActiveContainer',{container=self}) 
    elseif types.Lockable.getLockLevel(self)>0 and types.Lockable.isLocked(self)==true then
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="blowtorch"})
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="hacpuzzle"})
    end
end


local function onUpdate()

    if OpenTimer>0 and core.getSimulationTime()-OpenTimer>0.8 then
        OpenTimer=0
        core.sendGlobalEvent('Container', {container=self, player=Player, action="activate"})
    end


    if string.find(types.Container.records[self.recordId].mwscript,"pushable") then
        local StartPos=nearby.castRay(self.position+util.vector3(0,0,30),self.position+util.vector3(200,0,30)).hitPos
        local XPchecker = nearby.castRay(util.vector3(1,0,0)+StartPos,
                                            util.vector3(2,0,0)+StartPos,{radius=20})

        StartPos=nearby.castRay(self.position+util.vector3(0,0,30),util.vector3(0,200,30)+self.position).hitPos                                    
        local YPchecker = nearby.castRay(util.vector3(0,1,0)+StartPos,
                                            util.vector3(0,2,0)+StartPos,{radius=20})

        StartPos=nearby.castRay(self.position+util.vector3(0,0,30),util.vector3(-200,0,30)+self.position).hitPos
        local XMchecker = nearby.castRay(util.vector3(-1,0,0)+StartPos,
                                            util.vector3(-2,0,0)+StartPos,{radius=20})

        StartPos=nearby.castRay(self.position+util.vector3(0,0,30),util.vector3(0,-200,30)+self.position).hitPos
        local YMchecker = nearby.castRay(util.vector3(0,-1,0)+StartPos,
                                            util.vector3(0,-2,0)+StartPos,{radius=20})

        StartPos=nearby.castRay(self.position,util.vector3(0,0,-200)+self.position).hitPos
        local ZMchecker = nearby.castRay(util.vector3(0,0,-1)+StartPos,util.vector3(0,0,-4)+StartPos)

        if XPchecker.hit == true and XMchecker.hit == false and XPchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="X+", startPos=nil})
            print("X+")
        end
        if XMchecker.hit == true and XPchecker.hit == false and XMchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="X-", startPos=nil})
            print("X-")
        end
        if YPchecker.hit == true and YMchecker.hit == false and YPchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="Y+", startPos=nil})
            print("Y+")
        end
        if YMchecker.hit == true and YPchecker.hit ==false and YMchecker.hitObject.type==types.Player then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="Y-", startPos=nil})
            print("Y-")
        end
        if ZMchecker.hit == false then
            core.sendGlobalEvent('PushContainer', {Container=self, Way="Z-", startPos=nil})
            print("Z-")
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
