local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local AI = require('openmw.interfaces').AI


local StepSounds={}
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

local function onUpdate()

	StepSoundSurface()
	
	if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
		self.controls.movement=0
	end
	
	types.Actor.stats.attributes.speed(self).modifier=types.Actor.stats.attributes.speed(self).base*types.Actor.getEncumbrance(self)/types.NPC.getCapacity(self)
		if self.type~=types.Player and self.recordId~="playeractor" then
			print("attack")
		for i, actor in pairs(nearby.actors) do
			if actor.id~=self.id and actor.type==types.Creature and types.Actor.isDead(actor)==false then
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
end

return {
	eventHandlers={Died=Died},
	engineHandlers = {onUpdate=onUpdate}
}


