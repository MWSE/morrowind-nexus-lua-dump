local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local async = require('openmw.async')
local anim = require('openmw.animation')
local LocalizedDamage  = require('scripts.railshooter.localizeddamage')


local function Died()

	if  types.Creature.records[self.recordId] and types.Creature.records[self.recordId].name=="RSMagicBolt" then
		core.sendGlobalEvent("RSRemove",{object=self})
	end
	if types.Actor.stats.ai.fight(self).modified>=90 then
		nearby.players[1]:sendEvent("FoeKilled")
	end

end

local Hitted=false


I.Combat.addOnHitHandler(function(attack)
   	if attack.successful==true then
		if  self.recordId=="medkit" and Hitted==false then
			if attack.attacker and attack.attacker.type==types.Player then
				nearby.players[1]:sendEvent("Heal",{RSPlayer=attack.RSPlayer})
				Hitted=true
			else
				return(false)
			end
		elseif  self.recordId=="bulletbonus+1" and Hitted==false then
			if attack.attacker and attack.attacker.type==types.Player then
				nearby.players[1]:sendEvent("BonusBullets",{Number=1,RSPlayer=attack.RSPlayer})
				Hitted=true
			else
				return(false)
			end
		elseif  self.recordId=="bulletbonus+2" and Hitted==false then
			if attack.attacker and attack.attacker.type==types.Player then
				nearby.players[1]:sendEvent("BonusBullets",{Number=2,RSPlayer=attack.RSPlayer})
				Hitted=true
			else
				return(false)
			end
		elseif  self.recordId=="damagebonus" and Hitted==false then
			if attack.attacker and attack.attacker.type==types.Player then
				nearby.players[1]:sendEvent("DamageBonus",{RSPlayer=attack.RSPlayer})
				Hitted=true
			else
				return(false)
			end
		elseif  string.find(self.recordId,"newweapon_") and Hitted==false then
			if attack.attacker and attack.attacker.type==types.Player then
				nearby.players[1]:sendEvent("EquipWeapon",{Weapon=string.gsub(self.recordId,"newweapon_",""),RSPlayer=attack.RSPlayer})
				Hitted=true
			else
				return(false)
			end
		else
			if attack.spellOnHitRecord then
				if attack.spellOnHitRecordEffect then
					local Effect=core.magic.spells.records[attack.spellOnHitRecord].effects[attack.spellOnHitRecordEffect]
					if Effect.effect.hitStatic then
						anim.addVfx(self,types.Static.records[Effect.effect.hitStatic].model)
					end
					core.sound.playSound3d(Effect.effect.school.." hit",self)
					types.Actor.activeSpells(self):add({id=core.magic.spells.records[attack.spellOnHitRecord].id, effects={attack.spellOnHitRecordEffect-1}, caster=attack.Attacker, ignoreReflect=true})
				else
					local effestsnum={}
					local NearbyActors={}
					for i, effect in pairs(core.magic.spells.records[attack.spellOnHitRecord].effects) do
						if effect.area>1 then
							core.sendGlobalEvent("SpawnVfx",{model=types.Static.records[effect.effect.areaStatic].model, position=attack.hitPos, options={scale=effect.area}})
							if not(NearbyActors[1]) then
								for j, actor in pairs(nearby.actors) do
									if actor.id~=self.id and actor.type~=types.Player and types.Actor.isDead(actor)==false then
										table.insert(NearbyActors,actor)
									end
								end							
								for j, actor in pairs(NearbyActors) do
									if (self.position-actor.position):length()<effect.area*80 then
										local attack = {
											attacker = attack.attacker,
											weapon = nil,
											sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
											strength = 1,
											type = self.ATTACK_TYPE.Chop,
											hitPos=actor.position,
											damage = {
												health = 0,
											},
											successful = true,
											spellOnHitRecord=attack.spellOnHitRecord,
											spellOnHitRecordEffect=i,
											RSPlayer=Player,
										}
										actor:sendEvent('Hit', attack)
									end
								end

							end
						end
						if effect.effect.hitStatic then
							anim.addVfx(self,types.Static.records[effect.effect.hitStatic].model)
						end
						core.sound.playSound3d(effect.effect.school.." hit",self)
						effestsnum[i]=i-1
					end
					types.Actor.activeSpells(self):add({id=core.magic.spells.records[attack.spellOnHitRecord].id, effects=effestsnum, caster=attack.Attacker, ignoreReflect=true})
				end
			end


			if LocalizedDamage[self.recordId] then
				attack.damage.health=LocalizedDamage[self.recordId](attack)
			end
		end 
	end
end)



local SilenceTempo=0

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
 
	if key=="target start" then
--		local MagicBoltStatic=core.magic.spells.records[types.Actor.getSelectedSpell(self).id].effects[1].effect.bolt
--		print(MagicBoltStatic)
--		local MagicBolt="magicbolt"
--		if types.Creature.records["magicbolt"..MagicBoltStatic] then
--			MagicBolt="magicbolt"..MagicBoltStatic
--		end
--		core.sendGlobalEvent("RSCreateObject",{RecordId=MagicBolt,CellName=self.cell.name,Position=self.position+util.vector3(math.sin(self.rotation:getYaw())*50, math.cos(self.rotation:getYaw())*50,self:getBoundingBox().halfSize.z*3/2)})
		core.sendGlobalEvent("RSCReateMagicBolt",{MagicRecordId=core.magic.spells.records[types.Actor.getSelectedSpell(self).id].effects[1].effect.id,CellName=self.cell.name,Position=self.position+util.vector3(math.sin(self.rotation:getYaw())*50, math.cos(self.rotation:getYaw())*50,self:getBoundingBox().halfSize.z*3/2)})
		types.Actor.activeEffects(self):modify(100,"silence")
		SilenceTempo=1

	end
end)






types.Actor.activeEffects(self):modify(-1*types.Actor.activeEffects(self):getEffect("silence").magnitude,"silence")
local function onUpdate(dt)
	if dt>0 then
		if SilenceTempo>0 then
			SilenceTempo=SilenceTempo-dt
			if SilenceTempo<0 then
				types.Actor.activeEffects(self):modify(-1*types.Actor.activeEffects(self):getEffect("silence").magnitude,"silence")
			end
		end
		
		if types.Creature.records[self.recordId] and types.Creature.records[self.recordId].name=="RSMagicBolt" then
			if (self.position-nearby.players[1].position):length()<160 then
				local attack = {
								attacker = self,
								weapon = nil,
								sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
								strength = 1,
								type = self.ATTACK_TYPE.Chop,
								damage = {health = 1,},
								successful = true,
								}
				nearby.players[1]:sendEvent('Hit', attack)
			end
		end
	end
end



return {
	eventHandlers = {Died =Died 	},
	engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
		onFrame=onFrame,
		onUpdate=onUpdate

	}
}
