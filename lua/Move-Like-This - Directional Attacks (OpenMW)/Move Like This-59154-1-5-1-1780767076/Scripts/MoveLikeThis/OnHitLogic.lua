--Hit Test script--
local I = require("openmw.interfaces")
local core  = require("openmw.core")
local types = require("openmw.types")
local util = require("openmw.util")
local anim = require("openmw.animation")
local storage = require("openmw.storage")

local AttackEffects = require("scripts.MoveLikeThis.attackEffects")
local MLTConstants = require ("scripts.MoveLikeThis.constants")
local settingsMLT = storage.globalSection("Settings_MoveLikeThis")
test = nil
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
			if attack.weapon ~= nil then
				if attack.weapon:isValid() then
					weaponRecord = types.Weapon.record(attack.weapon)
					local weapType = weaponRecord.type
					if weapType == types.Weapon.TYPE.AxeOneHand then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								shieldBreakMult = settingsMLT:get("AX1H_ShieldBreak")
								AttackEffects.damageShieldOnHit(attack, victim, shieldBreakMult)
							end
							if attack.type == 1 then -- 1 = slash 
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("AX1H_CleaveType"))
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.AxeOneHand)
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.75 damage mult and 0.3 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								
							end
						end
					elseif weapType == types.Weapon.TYPE.AxeTwoHand then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								--if attack.successful then
								shieldBreakMult = settingsMLT:get("AX2H_ShieldBreak")
								AttackEffects.damageShieldOnHit(attack, victim, shieldBreakMult)
								--end
							end
							if attack.type == 1 then -- 1 = slash
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("AX1H_CleaveType"))
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.AxeTwoHand)
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.75 damage mult and 0.45 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								
							end
						end
					elseif weapType == types.Weapon.TYPE.BluntOneHand then
						slashType = settingsMLT:get("BW_SlashType")
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								
							end
							if attack.type == 1 then -- 1 = slash
								if slashType == MLTConstants.BWSlash.armorPierce then
									armorPierce = settingsMLT:get("BW1H_ArmorPierce")
									AttackEffects.ArmorPierce(attack, victim, armorPierce)
								elseif slashType == MLTConstants.BWSlash.cleave then			-- Cleave attack
									bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.BluntOneHand)
									AttackEffects.doCleaveAttack(attack, victim, 0.5, bonusRange)
								elseif slashType == MLTConstants.BWSlash.cleaveImp then			-- Improved Cleave attack
									bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.BluntOneHand)
									AttackEffects.doCleaveAttack(attack, victim, 0.75, bonusRange)
								end
							end
							if attack.type == 2 then -- 2 = thrust
								staggerChance = settingsMLT:get("BW1H_StaggerChance")
								if isPlayer and settingsMLT:get("PlayerAdvantage") then staggerChance = staggerChance - 10 end
								AttackEffects.staggerAttack(attack, victim, staggerChance)
							end
						end
					elseif weapType == types.Weapon.TYPE.BluntTwoClose then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								
							end
							if attack.type == 1 then -- 1 = slash
								armorPierce = settingsMLT:get("BW2H_ArmorPierce")
								AttackEffects.ArmorPierce(attack, victim, armorPierce)
							end
							if attack.type == 2 then -- 2 = thrust
								staggerChance = settingsMLT:get("BW2H_StaggerChance")
								if isPlayer and settingsMLT:get("PlayerAdvantage") then staggerChance = staggerChance - 10 end
								AttackEffects.staggerAttack(attack, victim, staggerChance)
							end
						end
					elseif weapType == types.Weapon.TYPE.BluntTwoWide then
						if (types.Actor.stats.dynamic.fatigue(victim).current > 0) then -- BW2HW_FatigueDamage
							if attack.damage.health then
								attack.damage.fatigue = attack.damage.health * settingsMLT:get("BW2HW_FatigueDamage")
							end
						end
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								stompMult = settingsMLT:get("BW2HW_StompDamage")
								AttackEffects.coupAttack(attack, victim, stompMult) --When target has zero stamina, deals *1.5 damage
							end
							if attack.type == 1 then -- 1 = slash
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.BluntTwoWide)
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("BW2HW_CleaveType"))
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.5 damage mult and 0.2 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								staggerChance = settingsMLT:get("BW2HW_StaggerChance")
								if isPlayer and settingsMLT:get("PlayerAdvantage") then staggerChance = staggerChance - 10 end
								AttackEffects.staggerAttack(attack, victim, staggerChance)
							end
						end
					elseif weapType == types.Weapon.TYPE.LongBladeOneHand then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop
								
							end
							if attack.type == 1 then -- 1 = slash
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("LB1H_CleaveType"))
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.LongBladeOneHand)
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.5 damage mult and 0.3 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								critChance = settingsMLT:get("LB1H_CritChance")
								critMult = settingsMLT:get("LB1H_CritMult")
								AttackEffects.criticalChanceWithSkill(attack, victim, critChance, critMult) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 3 settingsMLT:get()
							end
						end
					elseif weapType == types.Weapon.TYPE.LongBladeTwoHand then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 =
							end
							if attack.type == 1 then -- 1 = slash
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("LB2H_CleaveType"))
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.LongBladeTwoHand)
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.5 damage mult and 0.45 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								critChance = settingsMLT:get("LB2H_CritChance")
								critMult = settingsMLT:get("LB2H_CritMult")
								AttackEffects.criticalChanceWithSkill(attack, victim, critChance, critMult) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 3
							end
						end
					elseif weapType == types.Weapon.TYPE.ShortBladeOneHand then
						if attack.type == 0 then --0 = chop
							
						end
						if attack.type == 1 then -- 1 = slash
							slashType = settingsMLT:get("SB1H_SlashType")
							if slashType == MLTConstants.SBSlash.mobility then
								AttackEffects.shortBladeBuff(attack, victim) -- Mobility Buff
							elseif slashType == MLTConstants.SBSlash.blind then
								AttackEffects.shortBladeBlind(attack, victim) -- Blind Debuff
							elseif slashType == MLTConstants.SBSlash.cleave then			-- Cleave attack
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.ShortBladeOneHand)
								AttackEffects.doCleaveAttack(attack, victim, 0.5, bonusRange)
							elseif slashType == MLTConstants.SBSlash.cleaveImp then			-- Improved Cleave attack
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.ShortBladeOneHand)
								AttackEffects.doCleaveAttack(attack, victim, 0.75, bonusRange)
							end
						end
						if attack.type == 2 then -- 2 = thrust
							critChance = settingsMLT:get("SB1H_CritChance")
							critMult = settingsMLT:get("SB1H_CritMult")
							AttackEffects.criticalChanceWithSkill(attack, victim, critChance, critMult) --Critical strike, with 30% chance at 100 skill + luck/10, with a damage mult of 2
						end
					elseif weapType == types.Weapon.TYPE.SpearTwoWide then
						if attack.strength > 0.3 then
							if attack.type == 0 then --0 = chop 
								
							end
							if attack.type == 1 then -- 1 = slash
								bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.SpearTwoWide)
								cleaveMult = OnHitLogic.GetCleaveMult(settingsMLT:get("SP2H_CleaveType"))
								AttackEffects.doCleaveAttack(attack, victim, cleaveMult, bonusRange) --Cleave attack, with 0.5 damage mult and 0.1 extra cleave range
							end
							if attack.type == 2 then -- 2 = thrust
								firstStrikeMult = settingsMLT:get("SP2H_FirstStrike")
								AttackEffects.firstStrike(attack, victim, firstStrikeMult)
							end
						end
					end
				else
					--Weapon is not valid, probably because it does not exist
				end
			else
				if attack.type == 0 then --0 = chop (Right punch)
					stompMult = settingsMLT:get("BW2HW_StompDamage")
					AttackEffects.coupAttack(attack, victim, stompMult) --When target has zero stamina, deals *1.5 damage
				end
				if attack.type == 1 then -- 1 = slash (Right punch to head)
					slashType = settingsMLT:get("H2H_SlashType")
					if slashType == MLTConstants.SBSlash.mobility then
						AttackEffects.shortBladeBuff(attack, victim) -- Mobility Buff
					elseif slashType == MLTConstants.SBSlash.blind then
						AttackEffects.shortBladeBlind(attack, victim) -- Blind Debuff
					elseif slashType == MLTConstants.SBSlash.cleave then			-- Cleave attack
						bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.ShortBladeOneHand)
						AttackEffects.doCleaveAttack(attack, victim, 0.5, bonusRange)
					elseif slashType == MLTConstants.SBSlash.cleaveImp then			-- Improved Cleave attack
						bonusRange = OnHitLogic.GetCleaveBonus(types.Weapon.TYPE.ShortBladeOneHand)
						AttackEffects.doCleaveAttack(attack, victim, 0.75, bonusRange)
					end
				end
				if attack.type == 2 then -- 2 = thrust (Left punch)
					critChance = settingsMLT:get("H2H_CritChance")
					critMult = settingsMLT:get("H2H_CritMult")
					AttackEffects.criticalChanceWithSkill(attack, victim, critChance, critMult) --Critical strike, with 20% chance at 100 skill + luck/10, with a damage mult of 2
				end
			end
		else
			--Non-weapon attack
		end
	end
end


function OnHitLogic.GetCleaveBonus(weaponType)
	rangeBonustype = settingsMLT:get("CleaveRangeBonus")
	if weaponType == types.Weapon.TYPE.AxeOneHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.5
		end
	elseif weaponType == types.Weapon.TYPE.AxeTwoHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.6
		end
	elseif weaponType == types.Weapon.TYPE.BluntOneHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.3
		end
	elseif weaponType == types.Weapon.TYPE.BluntTwoClose then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.5
		end
	elseif weaponType == types.Weapon.TYPE.BluntTwoWide then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.2
		end
	elseif weaponType == types.Weapon.TYPE.LongBladeOneHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.5
		end
	elseif weaponType == types.Weapon.TYPE.LongBladeTwoHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.5
		end
	elseif weaponType == types.Weapon.TYPE.ShortBladeOneHand then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.2
		end
	elseif weaponType == types.Weapon.TYPE.SpearTwoWide then
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.2
		end
	else --Hand to Hand
		if MLTConstants.CleaveBonusRangeTypes.default then
			return 0.3
		end
	end
	return 0
end

function OnHitLogic.GetCleaveMult(cleaveType)
	if cleaveType == MLTConstants.CleaveTypeVals[MLTConstants.CleaveType.normal] then
		return 0.5
	elseif cleaveType == MLTConstants.CleaveTypeVals[MLTConstants.CleaveType.improved] then
		return 0.75
	end
	return 0
end



return OnHitLogic


--core.sound.playSound3d("heavy armor hit", victim)


