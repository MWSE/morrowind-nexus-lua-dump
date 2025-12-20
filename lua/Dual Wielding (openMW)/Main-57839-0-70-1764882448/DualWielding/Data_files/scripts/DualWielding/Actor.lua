local self=require('openmw.self')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local time=require('openmw_aux.time')



local function BlockSucces(attacker,defender,weapon,attackSwing,attackerWeapon)
local Block=false
  local attackerFatigueTerm = core.getGMST("fFatigueBase") - core.getGMST("fFatigueMult")*(1 - types.Actor.stats.dynamic.fatigue(attacker).current/types.Actor.stats.dynamic.fatigue(attacker).base)
  local defenderFatigueTerm = core.getGMST("fFatigueBase") - core.getGMST("fFatigueMult")*(1 - types.Actor.stats.dynamic.fatigue(defender).current/types.Actor.stats.dynamic.fatigue(defender).base)
  local skills={}
  skills[types.Weapon.TYPE.ShortBladeOneHand]=types.NPC.stats.skills.shortblade
  skills[types.Weapon.TYPE.LongBladeOneHand]=types.NPC.stats.skills.longblade
  skills[types.Weapon.TYPE.LongBladeTwoHand]=types.NPC.stats.skills.longblade
  skills[types.Weapon.TYPE.BluntOneHand]=types.NPC.stats.skills.bluntweapon
  skills[types.Weapon.TYPE.BluntTwoClose]=types.NPC.stats.skills.bluntweapon
  skills[types.Weapon.TYPE.BluntTwoWide]=types.NPC.stats.skills.bluntweapon
  skills[types.Weapon.TYPE.SpearTwoWide]=types.NPC.stats.skills.spear
  skills[types.Weapon.TYPE.AxeOneHand]=types.NPC.stats.skills.axe
  skills[types.Weapon.TYPE.AxeTwoHand]=types.NPC.stats.skills.axe
  skills[types.Weapon.TYPE.MarksmanBow]=types.NPC.stats.skills.marksman
  skills[types.Weapon.TYPE.MarksmanCrossbow]=types.NPC.stats.skills.marksman
  skills[types.Weapon.TYPE.MarksmanThrown]=types.NPC.stats.skills.marksman

  if types.Actor.canMove(defender)==true and types.Actor.getStance(defender)~=types.Actor.STANCE.Nothing then
	local AngleTarget
	local selfRotation=(self.rotation:getYaw()+2*math.pi)%(2*math.pi)+2*math.pi
	local angleHitShieldMax=selfRotation+core.getGMST("fCombatBlockRightAngle")/180*math.pi
	local angleHitShieldMin=selfRotation+core.getGMST("fCombatBlockLeftAngle")/180*math.pi
	if defender.position.x < attacker.position.x then
		if defender.position.y < attacker.position.y then --ok
			AngleTarget =  
				math.acos((attacker.position.y - defender.position.y) / (defender.position - attacker.position):length())
		elseif defender.position.y > attacker.position.y then
			AngleTarget =  -1*
				math.acos((defender.position.y - attacker.position.y) / (defender.position - attacker.position):length()) - math.pi
		end
	elseif defender.position.x > attacker.position.x then --ok
		if defender.position.y < attacker.position.y then
			AngleTarget =  
				math.acos((defender.position.y - attacker.position.y) / (defender.position - attacker.position):length()) - math.pi
		elseif self.position.y > attacker.position.y then
			AngleTarget =  -1*
				math.acos((attacker.position.y - defender.position.y) / (defender.position - attacker.position):length())
		end
	end	
	if AngleTarget<2*math.pi then
		AngleTarget=(AngleTarget)%(2*math.pi)+2*math.pi
	elseif AngleTarget>2*math.pi then
		AngleTarget=AngleTarget%(2*math.pi)
	end
	if AngleTarget>angleHitShieldMin and AngleTarget<angleHitShieldMax then
		local blockTerm = (types.NPC.stats.skills.block(defender).modified + skills[types.Weapon.records[weapon.recordId].type](self).modified)/2 + 0.2 * types.Actor.stats.attributes.agility(defender).modified + 0.1 * types.Actor.stats.attributes.luck(defender).modified
		local swingTerm = attackSwing * core.getGMST("fSwingBlockMult") + core.getGMST("fSwingBlockBase")
		local playerTerm = blockTerm * swingTerm
		if self.controls.movement==-1 then
			playerTerm = playerTerm * 1.25 
		end
		playerTerm = playerTerm * defenderFatigueTerm
		local npcSkill 
		if types.Creature.objectIsInstance(attacker)==true then
			npcSkill=types.Creature.records[attacker.recordId].combatSkill
		elseif attackerWeapon then
			npcSkill= skills[types.Weapon.records[attackerWeapon.recordId].type](attacker).modified
		else
			npcSkill= types.NPC.stats.skills.handtohand(attacker).modified
		end


		local npcTerm = npcSkill + 0.2 * types.Actor.stats.attributes.agility(defender).modified + 0.1 * types.Actor.stats.attributes.luck(defender).modified
		npcTerm = npcTerm * attackerFatigueTerm
		local x=math.abs(playerTerm-npcTerm)
		local iBlockMaxChance=core.getGMST("iBlockMaxChance")
		if x < core.getGMST("iBlockMinChance") then x= core.getGMST("iBlockMinChance") end
		if x > iBlockMaxChance then x= iBlockMaxChance end
		if math.random(100)<x then
			Block=true
		end
	end
  end
	return(Block)
end


local fatigue = self.type.stats.dynamic.fatigue(self)

function BlockFatigueLoss(weapon, attackStrength)
    local fatigueLoss = core.getGMST('fFatigueBlockBase') + types.Actor.getEncumbrance(self)/types.Actor.getCapacity(self) * core.getGMST('fFatigueBlockMult')

    if weapon then
        local weaponWeight = weapon.type.records[weapon.recordId].weight
        fatigueLoss = fatigueLoss + (weaponWeight * attackStrength * core.getGMST('fWeaponFatigueBlockMult'))

    end

    fatigue.current = fatigue.current - fatigueLoss
end


I.Combat.addOnHitHandler(function(attack)
-------------
	if attack.successful==true and I.DualWielding and I.DualWielding.SecondWeapon() and types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
		if BlockSucces(attack.attacker,self,I.DualWielding.SecondWeapon(),attack.strength, attack.weapon) and attack.damage.health then
			attack.successful=false
			I.AnimationController.playBlendedAnimation('shield',{startPoint=0, speed=1,startKey="block start", stopKey="block hit",priority=anim.PRIORITY.Block})
			core.sound.playSound3d("heavy armor hit",self)
			BlockFatigueLoss(attack.weapon,attack.strength)

			core.sendGlobalEvent('ModifyItemCondition', {actor = self, item = I.DualWielding.SecondWeapon(), amount= -attack.damage.health*5})-- x5 because weapons have more health than shields


			WeaponRec=types.Weapon.records[I.DualWielding.SecondWeapon().recordId]
			local skill = (WeaponRec.type == types.Weapon.TYPE.ShortBladeOneHand) and 'shortblade'
                     or (WeaponRec.type == types.Weapon.TYPE.LongBladeOneHand)  and 'longblade'
                     or (WeaponRec.type == types.Weapon.TYPE.AxeOneHand)        and 'axe'
                     or (WeaponRec.type == types.Weapon.TYPE.BluntOneHand)      and 'bluntweapon'
                     or nil
          	if skill and I.SkillProgression and I.SkillProgression.skillUsed then
				if math.random(2)==1 then
            		I.SkillProgression.skillUsed(skill, { useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit })
				else
            		I.SkillProgression.skillUsed("block", { useType = I.SkillProgression.SKILL_USE_TYPES.Block_Success })
				end
          	end


			--add block+weapon type experience
			if types.Player.objectIsInstance(self)==false then-----------Better find some better to solve the NPC only idle1h after the left attack
				local CombatTarget=I.AI.getActiveTarget("Combat")
				I.AI.startPackage({type="Wander"})
				if CombatTarget then
					I.AI.startPackage({type="Combat",target=CombatTarget})
				end
			end
		end
	end
----------------
	if attack.weapon and attack.weapon~=types.Actor.getEquipment(attack.attacker)[types.Actor.EQUIPMENT_SLOT.CarriedRight] then
		local DamageCondition=1
		local WeaponRecord=types.Weapon.records[attack.weapon.recordId]
		if attack.successful==true then
			if core.getGMST("fWeaponDamageMult")*attack.damage.health>DamageCondition then
				DamageCondition=core.getGMST("fWeaponDamageMult")*attack.damage.health
			end
			local EnchantRecord
			if WeaponRecord.enchant and core.magic.enchantments.records[WeaponRecord.enchant] then
				EnchantRecord=core.magic.enchantments.records[WeaponRecord.enchant]
			end
--				print(EnchantRecord,EnchantRecord.type,core.magic.ENCHANTMENT_TYPE.CastOnUse)
			if EnchantRecord and EnchantRecord.type==core.magic.ENCHANTMENT_TYPE.CastOnStrike then
				local effectiveCost=math.floor(EnchantRecord.cost*(1.1-types.NPC.stats.skills.enchant(attack.attacker).modified/100)+0.5)
				if effectiveCost<1 then effectiveCost=1 end
				if types.Item.itemData(attack.weapon).enchantmentCharge>effectiveCost then
					core.sendGlobalEvent("OnStrikesetCharge", {Item=attack.weapon, Charge=types.Item.itemData(attack.weapon).enchantmentCharge-effectiveCost})
					
					local effestsnum={}
					for i, effect in pairs(EnchantRecord.effects) do
						anim.addVfx(self,types.Static.records[effect.effect.hitStatic].model)
						core.sound.playSound3d(effect.effect.school.." hit",self)
						effestsnum[i]=i-1
					end
					types.Actor.activeSpells(self):add({id=WeaponRecord.id, effects=effestsnum, caster=attack.attacker})
				else
					attack.attacker:sendEvent('ShowMessage', {message = "Item does not have enough charge."})
					attack.attacker:sendEvent("BACOSPlaySound",{Sound="spell failure "..EnchantRecord.effects[1].effect.school})
				end
			end
		end
		core.sendGlobalEvent('ModifyItemCondition', {actor = attack.attacker, item = attack.weapon, amount= -DamageCondition})

		local Damage=attack.damage.health
		if types.NPC.objectIsInstance(self)==true and types.NPC.isWerewolf(self)==true and WeaponRecord.isSilver==true then
			Damage=Damage*core.getGMST("fWerewolfSilverWeaponDamageMult")
		end
		local ResistNormalWeapons=types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.ResistNormalWeapons).magnitude
		if ResistNormalWeapons>0 and WeaponRecord.isMagical==false then
			Damage=Damage-Damage*ResistNormalWeapons/100
			if Damage<0 then Damage=0 end
			if ResistNormalWeapons>=100 then
				attack.attacker:sendEvent('ShowMessage', {message = core.getGMST("sMagicTargetResistsWeapons")})
			end
		end
		attack.damage.health=Damage
	end
end)

--[[
local function EquipSecondWeapon(data)
	SecondWeapon=data.Weapon
end

local function RemoveSecondWeapon()
	SecondWeapon=nil
end



local function onSave()
    return{SecondWeaponSaved=SecondWeapon}
end


local function onLoad(data)
    if data and data.SecondWeaponSaved then
      SecondWeapon=data.SecondWeaponSaved
    end
end
]]--

return {
	eventHandlers = {EquipSecondWeapon=EquipSecondWeapon,
                	RemoveSecondWeapon=RemoveSecondWeapon
					},
	engineHandlers = {	onSave=onSave,
                    	onLoad=onLoad,
	}

}