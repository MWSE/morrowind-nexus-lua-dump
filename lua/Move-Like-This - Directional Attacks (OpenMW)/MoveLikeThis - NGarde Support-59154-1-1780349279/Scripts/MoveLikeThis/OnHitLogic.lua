--Hit Test script--
local I = require('openmw.interfaces')
local core  = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local anim = require('openmw.animation')

local AttackEffects = require('scripts.MoveLikeThis.attackEffects')

OnHitLogic = {}

function OnHitLogic.DoOnHit(attack, victim, isPlayer)
	if attack.attacker ~= nil then
		attacker = attack.attacker
		local isWeaponAttack = true
		if attacker.type == types.Creature then
			local attackerRcrd = types.Creature.record(attack.attacker.recordId)
			isWeaponAttack = attackerRcrd.canUseWeapons
		end
		if isWeaponAttack then
			if attack.weapon then
				local weaponRecord = types.Weapon.record(attack.weapon)
				local weapType = weaponRecord.type
				if weapType == types.Weapon.TYPE.AxeOneHand then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							--if attack.successful then
							AttackEffects.damageShieldOnHit(attack, victim, 1)
							--end
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.doCleaveAttack(attack, victim, 0.75, 0.3) --Cleave attack, with 0.75 damage mult and 0.3 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							
						end
					end
				elseif weapType == types.Weapon.TYPE.AxeTwoHand then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							--if attack.successful then
							AttackEffects.damageShieldOnHit(attack, victim, 1)
							--end
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.doCleaveAttack(attack, victim, 0.75, 0.45) --Cleave attack, with 0.75 damage mult and 0.3 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							
						end
					end
				elseif weapType == types.Weapon.TYPE.BluntOneHand then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.ArmorPierce(attack, victim, 0.5)
						end
						if attack.type == 2 then -- 2 = thrust
							if isPlayer then --Stagger is not a very fun mechanic for the player, so they get less chance of being stunned
								AttackEffects.staggerAttack(attack, victim, 0)
							else
								AttackEffects.staggerAttack(attack, victim, 10)
							end
						end
					end
				elseif weapType == types.Weapon.TYPE.BluntTwoClose then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.ArmorPierce(attack, victim, 0.5)
						end
						if attack.type == 2 then -- 2 = thrust
							if isPlayer then
								AttackEffects.staggerAttack(attack, victim, 10)
							else
								AttackEffects.staggerAttack(attack, victim, 20)
							end
						end
					end
				elseif weapType == types.Weapon.TYPE.BluntTwoWide then
					if (types.Actor.stats.dynamic.fatigue(victim).current > 0) then
						attack.damage.fatigue = attack.damage.health
					end
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							AttackEffects.coupAttack(attack, victim, 1.5) --When target has zero stamina, deals *1.5 damage
						end
						if attack.type == 1 then -- 1 = slash
								AttackEffects.doCleaveAttack(attack, victim, 0.75, 0.2) --Cleave attack, with 0.5 damage mult and 0.2 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							if isPlayer then
								AttackEffects.staggerAttack(attack, victim, 40)
							else
								AttackEffects.staggerAttack(attack, victim, 50)
							end
						end
					end
				elseif weapType == types.Weapon.TYPE.LongBladeOneHand then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop
							
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.doCleaveAttack(attack, victim, 0.5, 0.3) --Cleave attack, with 0.5 damage mult and 0.3 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							AttackEffects.criticalChanceWithSkill(attack, victim, 20, 2) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 3
						end
					end
				elseif weapType == types.Weapon.TYPE.LongBladeTwoHand then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 =
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.doCleaveAttack(attack, victim, 0.5, 0.45) --Cleave attack, with 0.5 damage mult and 0.45 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							AttackEffects.criticalChanceWithSkill(attack, victim, 20, 3) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 3
						end
					end
				elseif weapType == types.Weapon.TYPE.ShortBladeOneHand then
					if attack.type == 0 then --0 = chop
						
					end
					if attack.type == 1 then -- 1 = slash
						AttackEffects.shortBladeBuff(attack, victim)
					end
					if attack.type == 2 then -- 2 = thrust
						AttackEffects.criticalChanceWithSkill(attack, victim, 30, 2.5) --Critical strike, with 30% chance at 100 skill + luck/10, with a damage mult of 2
					end
				elseif weapType == types.Weapon.TYPE.SpearTwoWide then
					if attack.strength > 0.3 then
						if attack.type == 0 then --0 = chop 
							
						end
						if attack.type == 1 then -- 1 = slash
							AttackEffects.doCleaveAttack(attack, victim, 0.5, 0.2) --Cleave attack, with 0.5 damage mult and 0.1 extra cleave range
						end
						if attack.type == 2 then -- 2 = thrust
							AttackEffects.firstStrike(attack, victim, 1.5)
						end
					end
				end
			else
				if attack.type == 0 then --0 = chop (Right punch)
					AttackEffects.coupAttack(attack, victim, 1.5) --When target has zero stamina, deals *1.5 damage
				end
				if attack.type == 1 then -- 1 = slash (Right punch to head)
					
				end
				if attack.type == 2 then -- 2 = thrust (Left punch)
					AttackEffects.criticalChanceWithSkill(attack, victim, 20, 2) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 2
				end
			end
		else
			--Non-weapon attack
		end
	end
end




return OnHitLogic


--core.sound.playSound3d("heavy armor hit", victim)


