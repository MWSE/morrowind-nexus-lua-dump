local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local OriginPos


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

local function Climb(data)
    if string.find(types.Container.record(self).mwscript,"climbable")~=nil and self.position.z+10>=data.position.z then
        core.sendGlobalEvent('Teleport', {object=data, position=util.vector3((data.position.x+self.position.x)/2,(data.position.y+self.position.y)/2,nearby.castRay(self.position,util.transform.move(0,0,200)*self.position).hitPos.z+10),rotation=nil})
    end
end


local function onUpdate()

    --print(types.Container.record(self).mwscript)
    if string.find(types.Container.record(self).mwscript,"pushable") then
        local XPchecker = nearby.castRay(util.transform.move(2,0,0)*nearby.castRay(self.position,util.transform.move(200,0,0)*self.position).hitPos,util.transform.move(10,0,0)*nearby.castRay(self.position,util.transform.move(200,0,0)*self.position).hitPos,{radius=40})
        local YPchecker=nearby.castRay(util.transform.move(0,2,0)*nearby.castRay(self.position,util.transform.move(0,200,0)*self.position).hitPos,util.transform.move(0,10,0)*nearby.castRay(self.position,util.transform.move(0,200,0)*self.position).hitPos,{radius=40})
        local XMchecker=nearby.castRay(util.transform.move(-2,0,0)*nearby.castRay(self.position,util.transform.move(-200,0,0)*self.position).hitPos,util.transform.move(-10,0,0)*nearby.castRay(self.position,util.transform.move(-200,0,0)*self.position).hitPos,{radius=40})
        local YMchecker =nearby.castRay(util.transform.move(0,-2,0)*nearby.castRay(self.position,util.transform.move(0,-200,0)*self.position).hitPos,util.transform.move(0,-10,0)*nearby.castRay(self.position,util.transform.move(0,-200,0)*self.position).hitPos,{radius=40})
        

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
        onActivated=Climb,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
