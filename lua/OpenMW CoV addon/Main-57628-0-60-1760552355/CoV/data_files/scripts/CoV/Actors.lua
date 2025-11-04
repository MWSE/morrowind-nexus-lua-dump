local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local time=require('openmw_aux.time')
local Combat=require('openmw.interfaces').Combat


local Player
local LastHitted
local LastHealth=types.Actor.stats.dynamic.health(self).current

time.runRepeatedly(function() 	
	if I.AI.getActivePackage() and I.AI.getActivePackage().type~="Combat" and types.Actor.stats.ai.fight(self).modified>=60 then
		for i, actor in pairs(nearby.actors) do
			if types.Actor.isDead(actor)==false and types.Actor.stats.ai.fight(actor).modified==30 and (self.position-actor.position):length()<types.Actor.stats.ai.fight(self).modified*7 then
				--print((self.position-actor.position):length(),types.Actor.stats.ai.fight(self).modified*10)
				I.AI.startPackage({type="Combat", target=actor})
			end
		end
	end
	types.Actor.stats.dynamic.fatigue(self).current=types.Actor.stats.dynamic.fatigue(self).base
end,
0.5*time.second)

local function onUpdate(dt)
	local health=math.floor(types.Actor.stats.dynamic.health(self).current+0.5)
	if health<LastHealth then
		nearby.players[1]:sendEvent("ShowDamage",{Object=self,Value=LastHealth-health})
		LastHealth=health
	end


	if types.Actor.activeSpells(self) then
		for i, spell in pairs(types.Actor.activeSpells(self)) do
			if spell.caster~=self.object then
				LastHitted=spell.caster
			end
		end
	end

end

local function Died()
	if LastHitted then
		nearby.players[1]:sendEvent("CoVAddXp",{Avatar=LastHitted.recordId,Xp=types.Actor.stats.level(self).current})
	end
	if types.Actor.stats.ai.fight(self).modified>=60 then
		core.sendGlobalEvent("CoVEmptyInventory",{Object=self})
	end
end

I.Combat.addOnHitHandler(function(attack)
	if anim.isPlaying(self,"shield") or (anim.isPlaying(self,"handtohand") and types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and not(attack.ammo)) then
		local selfRotation=(self.rotation:getYaw()+2*math.pi)%(2*math.pi)+2*math.pi
		local angleHitShieldMax=selfRotation+core.getGMST("fCombatBlockRightAngle")/180*math.pi
		local angleHitShieldMin=selfRotation+core.getGMST("fCombatBlockLeftAngle")/180*math.pi
--		local angleHit=math.acos((self.position.x-attack.hitPos.x)/(util.vector2(self.position.x,self.position.y)-util.vector2(attack.hitPos.x,attack.hitPos.y)):length())*

--		local angleHit=math.acos((self.position.x-attack.hitPos.x)/(util.vector2(self.position.x,self.position.y)-util.vector2(attack.hitPos.x,attack.hitPos.y)):length())*
	local AngleTarget
	if self.position.x < attack.attacker.position.x then
		if self.position.y < attack.attacker.position.y then --ok
			AngleTarget =  
				math.acos((attack.attacker.position.y - self.position.y) / (self.position - attack.attacker.position):length())
		elseif self.position.y > attack.attacker.position.y then
			AngleTarget =  -1*
				math.acos((self.position.y - attack.attacker.position.y) / (self.position - attack.attacker.position):length()) - math.pi
		end
	elseif self.position.x > attack.attacker.position.x then --ok
		if self.position.y < attack.attacker.position.y then
			AngleTarget =  
				math.acos((self.position.y - attack.attacker.position.y) / (self.position - attack.attacker.position):length()) - math.pi
		elseif self.position.y > attack.attacker.position.y then
			AngleTarget =  -1*
				math.acos((attack.attacker.position.y - self.position.y) / (self.position - attack.attacker.position):length())
		end
	end	
	if AngleTarget<2*math.pi then
		AngleTarget=(AngleTarget)%(2*math.pi)+2*math.pi
	elseif AngleTarget>2*math.pi then
		AngleTarget=AngleTarget%(2*math.pi)
	end
--	print("NEW")
--	print("target "..AngleTarget)
--	print("self "..selfRotation)
--	print("Min "..angleHitShieldMin)
--	print("Max "..angleHitShieldMax)

		if AngleTarget>angleHitShieldMin and AngleTarget<angleHitShieldMax then
			anim.addVfx(self,"meshes/spark.nif",{boneName="shield bone"})
			core.sound.playSoundFile3d("sound/fx/item/shield.wav",self)
			return false
		end
	end
	if attack.successful==true and attack.damage.health  then
		LastHitted=attack.attacker
	end
end)


local function onActive()
	if types.NPC.objectIsInstance(self) then
		types.NPC.stats.skills.axe(self).base=100
		types.NPC.stats.skills.shortblade(self).base=100
		types.NPC.stats.skills.longblade(self).base=100
		types.NPC.stats.skills.bluntweapon(self).base=100
		types.NPC.stats.skills.marksman(self).base=100
		types.NPC.stats.skills.spear(self).base=100
		
		types.NPC.stats.skills.lightarmor(self).base=100
		types.NPC.stats.skills.mediumarmor(self).base=100
		types.NPC.stats.skills.heavyarmor(self).base=100


	elseif  types.Creature.objectIsInstance(self) then
	end
end




local function LevelUp()
	types.Actor.stats.dynamic.health(self).base=types.Actor.stats.dynamic.health(self).base+types.Actor.stats.attributes.endurance(self).base*0.1
	types.Actor.stats.level(self).current=types.Actor.stats.level(self).current+1
	types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).base
	types.Actor.stats.dynamic.magicka(self).current=types.Actor.stats.dynamic.magicka(self).base
end

local function SetAttribute(data)
	types.Actor.stats.attributes[data.Attribute](self).base=data.Value
end

return {
	eventHandlers = {	
						Died=Died,
						LevelUp=LevelUp,
						SetAttribute=SetAttribute,
					},
	engineHandlers = {
						onUpdate=onUpdate,
						onActive=onActive,

	}

}