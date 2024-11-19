local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI

DamageLocTimer=0
DamageLocPlayer=nil


local function DamageEffects(data)
    print(self)
    print("life1"..types.Actor.stats.dynamic.health(self).current)
    --print(data.enchant)
    --print(data.damages)
    types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).current-data.damages
    
    print("life2"..types.Actor.stats.dynamic.health(self).current)
    --if core.magic.enchantments[data.enchant].type==1 then  --onStrike enchantment
    --    for i, effect in ipairs(data.enchant.effects) do 
    --        print(effect)
    --        types.Actor.activeEffects(self):modify(effect.magnitudeMax,effect.effect)
    --    end
    --end
end


local function Damagelocalisation(data)
    DamageLocTimer=core.getRealTime()
    DamageLocPlayer=data.Player
    --print(data.Hitpos.z/(self:getBoundingBox().halfSize.z*2-self.position.z)*100)
    core.sendGlobalEvent("ReturnLocalScriptVariable",{Player=data.Player, GameObject=self,Variable="DamageLoc",value=data.Hitpos.z/(self:getBoundingBox().halfSize.z*2-self.position.z)*100})
end




local function Died()
	for j,object in ipairs(types.Actor.inventory(self):getAll()) do
		core.sendGlobalEvent('Teleport',
		{
			object = object,
			position =self.position,
            rotation = self.rotation
		})	
	end
end



return {
	eventHandlers = {Damagelocalisation=Damagelocalisation,DamageEffects=DamageEffects,Died=Died },
	engineHandlers = {
        onUpdate = function()
            if DamageLocPlayer and (core.getRealTime()-DamageLocTimer)>0.1 then
                --print("Stop localisation")
                core.sendGlobalEvent("ReturnLocalScriptVariable",{Player=DamageLocPlayer, GameObject=self,Variable="DamageLoc",value=-5})
                DamageLocPlayer=nil
            elseif DamageLocPlayer then
                --print("localisation")
            end

            for i, actor in pairs(nearby.actors) do
                if actor.id~=self.id and actor.type==types.NPC and types.Actor.isDead(actor)==false and actor.recordId~="playeractor" then
                    if AI.getActivePackage().target then
                        if ((actor.position-self.position):length()<(AI.getActivePackage().target.position-self.position):length() or types.Actor.isDead(actor)==false) and actor~=AI.getActivePackage().target  then
                            AI.startPackage({type='Combat',target=actor})
                        elseif types.Actor.isDead(AI.getActivePackage().target) and  (actor.position-self.position):length()<2000 then
                            AI.startPackage({type='Combat',target=actor})
                        end
                    elseif (actor.position-self.position):length()<3000 then
                        AI.startPackage({type='Combat',target=actor})
                    end
                end
            end
            
	end
    ,
	}
}