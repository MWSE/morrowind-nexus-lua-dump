local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local anim = require('openmw.animation')
local AI = require('openmw.interfaces').AI
local I = require('openmw.interfaces')

DamageLocTimer=0
DamageLocPlayer=nil


local function DamageSpecialAmmo(data)
    
    Ammo=types.Weapon.records[data.Ammo.recordId]
    --print(self)
    --print("life1"..types.Actor.stats.dynamic.health(self).current)
    --print(data.enchant)
    --print(data.damages)
    types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).current-Ammo.thrustMinDamage
    --print(Ammo.enchant)
    if Ammo.enchant then
        types.Actor.activeSpells(self):add({id=data.Ammo.recordId,effects={(0)}})
        --print("Enchant")
    end
    --print("life2"..types.Actor.stats.dynamic.health(self).current)
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


local function DamageEffect(data)
    types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).current-data.damages
    --print(self)
    --print(types.Actor.stats.dynamic.health(self).current)
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

local DamageEffects={Effects={damagehealth=0,frostdamage=0,poison=0,firedamage=0,shockdamage=0,sundamage=0},Hit=false}
local LastCurrentHealth=0
local HitAnims=0
for i=1,5 do
    if anim.hasGroup(self,"hit"..i) then
        HitAnims=i
    else
        break
    end
end

local function PlayHitAnim()
    if HitAnims>0 then
        I.AnimationController.playBlendedAnimation( "hit"..math.random(0,HitAnims), { loops = 0, forceLoop = true, priority = anim.PRIORITY.Scripted })
    end
end

return {
	eventHandlers = {Damagelocalisation=Damagelocalisation,DamageSpecialAmmo=DamageSpecialAmmo,Died=Died, DamageEffects=DamageEffect },
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
                    elseif (actor.position-self.position):length()<500 then
                        AI.startPackage({type='Combat',target=actor})
                    end
                end
            end

            DamageEffects.Hit=false
            for i, effect in pairs(DamageEffects.Effects) do 
--                print("effect "..effect)
--                print("magnitude "..types.Actor.activeEffects(self):getEffect(i).magnitude)
                if types.Actor.activeEffects(self):getEffect(i).magnitude>effect then
                    PlayHitAnim()
                end
                if types.Actor.activeEffects(self):getEffect(i).magnitude>0 then
                    DamageEffects.Hit=true
                end
                DamageEffects.Effects[i]=types.Actor.activeEffects(self):getEffect(i).magnitude
            end 
            if DamageEffects.Hit==false and types.Actor.stats.dynamic.health(self).current<LastCurrentHealth then
               PlayHitAnim()
            end
            LastCurrentHealth=types.Actor.stats.dynamic.health(self).current
            
            if types.Actor.activeEffects(self):getEffect("FireDamage").magnitude>0 and CustommEffects~="FireDamage" then
                if anim.hasBone(self,"Main") then
                    anim.addVfx(self,"meshes/firehit.nif" ,{boneName = 'Main', loop=true,vfxId = "Fire"})
                else
                    anim.addVfx(self,types.Static.records["FireHit"].model,{loop=true,vfxId = "Fire"})
                end
                CustommEffects="FireDamage"
            elseif types.Actor.activeEffects(self):getEffect("FireDamage").magnitude==0 and CustommEffects=="FireDamage" and types.Actor.stats.dynamic.health(self).current>0 then
                anim.removeVfx(self, "Fire")
                CustommEffects=nil
            end



--        self.controls.run=false
	end
    ,
	}
}