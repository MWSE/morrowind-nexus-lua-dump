local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local anim = require('openmw.animation')
local AI = require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local LastWeapon
local StepSounds={}

local currentVFXWeapon
local Cell


for _, sound in pairs(core.sound.records) do
	if string.find(sound.id,"stepsound") then
		StepSounds[sound.id]=sound.id
	end
end

local StepLeft=false
local StepRight=false
local function StepSoundSurface()
	if core.sound.isSoundPlaying("footbareleft",self)==true and StepLeft==false then
		StepLeft=true
		if nearby.castRay(self.position,self.position+util.vector3(0,0,-10)).hitObject and string.find(nearby.castRay(self.position,self.position+util.vector3(0,0,-30)).hitObject.recordId,("stepsound"))~=nil then
			core.sound.stopSound3d("footbareleft",self)
			for i,stepsound in pairs(StepSounds) do
				if string.find(nearby.castRay(self.position,self.position+util.vector3(0,0,-10)).hitObject.recordId,stepsound) then
					if StepSounds[stepsound.."l"] then
						core.sound.playSound3d(stepsound.."l",self)	
					else
						core.sound.playSound3d(stepsound,self)
					end
				end
			end
		end
	elseif StepLeft==true and core.sound.isSoundPlaying("footbareleft",self)==false then
		StepLeft=false
	end
	if core.sound.isSoundPlaying("footbareright",self)==true and StepRight==false then
		StepRight=true
		if nearby.castRay(self.position,self.position+util.vector3(0,0,-10)).hitObject and string.find(nearby.castRay(self.position,self.position+util.vector3(0,0,-30)).hitObject.recordId,("stepsound"))~=nil then
			core.sound.stopSound3d("footbareright",self)
			for i,stepsound in pairs(StepSounds) do
				if string.find(nearby.castRay(self.position,self.position+util.vector3(0,0,-10)).hitObject.recordId,stepsound) then
					if StepSounds[stepsound.."r"] then
						core.sound.playSound3d(stepsound.."r",self)
					else
						core.sound.playSound3d(stepsound,self)
					end
				end
			end
		end
	elseif StepRight==true and core.sound.isSoundPlaying("footbareright",self)==false then
		StepRight=false
	end
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
local CustommEffects
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



local function onUpdate()


	
	StepSoundSurface()
	
	types.Actor.stats.attributes.speed(self).modifier=types.Actor.stats.attributes.speed(self).base*types.Actor.getEncumbrance(self)/types.NPC.getCapacity(self)
		if self.type~=types.Player and self.recordId~="playeractor" then
		--	print("attack")
		for i, actor in pairs(nearby.actors) do
			if actor.id~=self.id and actor.type==types.Creature and types.Actor.isDead(actor)==false then
				if AI.getActivePackage().target then
					if ((actor.position-self.position):length()<(AI.getActivePackage().target.position-self.position):length() or types.Actor.isDead(actor)==false) and actor~=AI.getActivePackage().target  then
						AI.startPackage({type='Combat',target=actor})
					elseif types.Actor.isDead(AI.getActivePackage().target) and  (actor.position-self.position):length()<500 then
						AI.startPackage({type='Combat',target=actor})
					end
				elseif (actor.position-self.position):length()<3000 then
					AI.startPackage({type='Combat',target=actor})
				end
			end
		end
	end



	
	DamageEffects.Hit=false
	for i, effect in pairs(DamageEffects.Effects) do 
--      print("effect "..effect)
--      print("magnitude "..types.Actor.activeEffects(self):getEffect(i).magnitude)
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




	  if LastWeapon~=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) then
    	LastWeapon=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight)
		I.AnimationController.playBlendedAnimation( "throwweapon", {startKey="equip attach", stopKey="equip stop", priority = anim.PRIORITY.Scripted })
  	end

end

return {
	eventHandlers={Died=Died},
	engineHandlers = {onUpdate=onUpdate}
}


