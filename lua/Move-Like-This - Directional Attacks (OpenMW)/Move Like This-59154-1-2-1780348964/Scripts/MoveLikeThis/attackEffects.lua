local I = require('openmw.interfaces')
local core  = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')
local nearby = require('openmw.nearby')

AttackEffects = {}

function AttackEffects.doCleaveAttack(attackInfo, mainTargetActor, cleaveDamageMult, cleaveRangeBonus)
	--Ideally this effect should be something attacker handles, waiting until the attack attempt itself gets dehardcoded
	if attacker.type == types.Player and (attackInfo.MLT_IsCleave == nil) then -- Only the player can do cleave attacks to prevent friendly fire
		-- Get cleave center point
		pos1 = attackInfo.attacker.position
		pos2 = mainTargetActor.position
		centerDistanceAdjust = 0.2
		posDistance = (pos1 - pos2):length()
		weaponRecord = types.Weapon.record(attackInfo.weapon)
		cleaveCenterDistance = ((weaponRecord.reach / 2) - centerDistanceAdjust) * 100
		distanceMult = cleaveCenterDistance / posDistance
		vx = (pos1.x + ((pos2.x - pos1.x) * distanceMult))
		vy = (pos1.y + ((pos2.y - pos1.y) * distanceMult))
		vz = (pos1.z + ((pos2.z - pos1.z) * distanceMult))
		centerPoint = util.vector3(vx, vy, vz)
		
		-- Hit all actors in radius
		newAttack = AttackEffects.copyTable(attackInfo)
		--newAttack.damage = AttackEffects.copyTable(newAttack.damage)
		newAttack.damage = {}
		newAttack.damage.health = attackInfo.damage.health * cleaveDamageMult
		if attackInfo.damage.fatigue ~= nil then
			newAttack.damage.fatigue = attackInfo.damage.fatigue * cleaveDamageMult
		end
		if attackInfo.damage.magicka ~= nil then
			newAttack.damage.magicka = attackInfo.damage.magicka * cleaveDamageMult
		end
		newAttack.MLT_IsCleave = true
		hitRadius = ((weaponRecord.reach / 2) + cleaveRangeBonus + centerDistanceAdjust) * 100
		nearActors = nearby.actors
		weaponRecord = types.Weapon.record(attackInfo.weapon)
		attackerToHitChance = AttackEffects.getToHitChance(attackInfo.attacker, weaponRecord.type)
		for _, actor in pairs(nearActors) do
			distance = (actor.position - centerPoint):length()
			if distance < hitRadius then
				if not (actor.type == types.Player or actor.id == mainTargetActor.id or types.Actor.isDead(actor)) then
					if AttackEffects.IsWeaponEffective(attackInfo.weapon, actor) then
						attackHit = AttackEffects.doShortToHitRoll(attackerToHitChance, actor)
						thisAttack = AttackEffects.copyTable(newAttack)
						if attackHit then
							thisAttack.successful = true
							if attackInfo.ngarde_damageRemainingRatio == nil then
								AttackEffects.attemptBlock(thisAttack, actor)
							end
							actor:sendEvent('Hit', thisAttack)
						else
							thisAttack.successful = false
							actor:sendEvent('Hit', thisAttack)
						end
					end
				end
			end
		end
	end
end


function AttackEffects.attemptBlock(attackInfo, victim)
	canUseShield = false
	if victim.type == types.Creature then
		local victimRcrd = types.Creature.record(victim.recordId)
		canUseShield = victimRcrd.canUseWeapons
	else
		canUseShield = true
	end
	if canUseShield then
		offHand = types.Actor.getEquipment(victim, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
		if offHand ~= nil and offHand.type == types.Armor then
			armorRecord = types.Armor.record(offHand)
			if armorRecord.type == types.Armor.TYPE.Shield then
				if AttackEffects.blockAttackRoll(attackInfo, victim) then
					blockedDamage = attackInfo.damage.health
					attackInfo.damage.health = 0
					attackInfo.damage.fatigue = 0
					attackInfo.damage.magicka = 0
					params = {}
					params.item = offHand
					params.actor = victim
					params.damage = blockedDamage
					core.sendGlobalEvent("MLT_DirAttack_damageShield", params)
					victim:sendEvent("MLT_DirAttack_blockAnimSound")
				end
			end
		end
	end
end


function AttackEffects.blockAttackRoll(attackInfo, victim)
	blockSkill = 0
	if not victim.type == types.Creature then
		blockSkill = types.NPC.stats.skills.block(actor)
	end
	victimFatigue = types.Actor.stats.dynamic.fatigue(victim)
	
	blockChance = (blockSkill + (types.Actor.stats.attributes.agility(victim).modified / 5) + (types.Actor.stats.attributes.luck(victim).modified / 10)) * (0.75 + (0.5 * (victimFatigue.current / victimFatigue.base)))
	randomRoll = math.random(100)
	return randomRoll <= blockChance
	--return true
end



function AttackEffects.damageShieldOnHit(attackInfo, victim, damageMultiplier)
	if attackInfo.successful or AttackEffects.NGardeIsWeakParry(attackInfo) then
		if (attackInfo.damage.health == 0 or AttackEffects.NGardeIsWeakParry(attackInfo)) and AttackEffects.IsWeaponEffective(attackInfo.weapon, victim) then
			
			weaponRecord = types.Weapon.record(attackInfo.weapon)
			offHand = types.Actor.getEquipment(victim, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
			if offHand ~= nil and offHand.type == types.Armor then
				armorRecord = types.Armor.record(offHand)
				if armorRecord.type == types.Armor.TYPE.Shield then
					if attackInfo.damage.health ~= nil then
						toDamage = attackInfo.damage.health * damageMultiplier
					end
					averageDamage = ((weaponRecord.chopMaxDamage - weaponRecord.chopMinDamage) / 2) + weaponRecord.chopMinDamage
					toDamage = math.max(toDamage, averageDamage)
					params = {}
					params.item = offHand
					params.actor = victim
					params.damage = toDamage
					core.sendGlobalEvent("MLT_DirAttack_damageShield", params)
				end
			end
		end
	end
end

function AttackEffects.shortBladeBuff(attackInfo, victim)
	attacker = attackInfo.attacker
	if attackInfo.attacker.type == types.Player then
		attacker:sendEvent("MLT_shortBladeBuff", params)
	end
end

function AttackEffects.criticalChanceWithSkill(attackInfo, victim, critChance, critMult)
	if attackInfo.successful and AttackEffects.NGardeHitCheck(attackInfo)  then
		if attackInfo.attacker.type == types.Creature then
			adjustedChance = critChance * (types.Creature.record(attacker).combatSkill / 100)
		else
			adjustedChance = critChance * (AttackEffects.getSkillStatForWeaponType(attacker, weaponType).modified / 100)
		end
		AttackEffects.criticalChance(attackInfo, victim, adjustedChance, critMult)
	end
end


function AttackEffects.criticalChance(attackInfo, victim, critChance, critMult) --
	if attackInfo.successful and AttackEffects.NGardeHitCheck(attackInfo) then
		victimActiveEffects = types.Actor.activeEffects(victim)
		normalResist = (victimActiveEffects:getEffect(core.magic.EFFECT_TYPE.ResistNormalWeapons).magnitude) / 100
		if not (normalResist >= 1 and not AttackEffects.IsWeaponEffective(attackInfo.weapon, victim)) then
			attacker = attackInfo.attacker
			randomRoll = math.random(100)
			chanceLuck = critChance + (types.Actor.stats.attributes.luck(attacker).modified / 10)
			attackNotBlocked = false
			if randomRoll <= chanceLuck then
				if attackInfo.damage.health ~= nil then
					attackInfo.damage.health = attackInfo.damage.health * critMult
					attackNotBlocked = attackInfo.damage.health > 0
				end
				if attackInfo.damage.fatigue ~= nil then
					attackInfo.damage.fatigue = attackInfo.damage.fatigue * critMult
					attackNotBlocked = (attackInfo.damage.fatigue > 0) or attackNotBlocked
				end
				if attackInfo.damage.magicka ~= nil then
					attackInfo.damage.magicka = attackInfo.damage.magicka * critMult
				end
				if attacker.type == types.Player and attackNotBlocked then
					attacker:sendEvent("MLT_DirAttack_criticalHit", params)
				end
			end
		end
	end
end


function AttackEffects.firstStrike(attackInfo, victim, damageMult) --
	if attackInfo.successful and AttackEffects.NGardeHitCheck(attackInfo) then
		victimHealth = types.Actor.stats.dynamic.health(victim)
		if (victimHealth.current >= (victimHealth.base + victimHealth.modifier)) then
			attackInfo.damage.health = attackInfo.damage.health * damageMult
			if attackInfo.damage.fatigue ~= nil then
				attackInfo.damage.fatigue = attackInfo.damage.fatigue * damageMult
			end
			if attackInfo.damage.magicka ~= nil then
				attackInfo.damage.magicka = attackInfo.damage.magicka * damageMult
			end
		end
	end
end


function AttackEffects.doToHitRoll(attacker, victim, weaponType)
	evasion = AttackEffects.getEvasion(victim) --Evasion
	toHitChance = AttackEffects.getToHitChance(attacker, weaponType) --Hit rate
	rollUnder = toHitChance - evasion --Actual roll
	randomRoll = math.random(100)
	return randomRoll <= rollUnder
end


function AttackEffects.coupAttack(attackInfo, victim, mult)
	if attackInfo.successful and AttackEffects.NGardeHitCheck(attackInfo) then
		victimFatigue = types.Actor.stats.dynamic.fatigue(victim)
		if victimFatigue.current <= 0 then
			if attackInfo.damage.health ~= nil then
				attackInfo.damage.health = attackInfo.damage.health * mult
			end
		end
	end
end


function AttackEffects.doToHitRoll(attacker, victim, weaponType)
	evasion = AttackEffects.getEvasion(victim) --Evasion
	toHitChance = AttackEffects.getToHitChance(attacker, weaponType) --Hit rate
	rollUnder = toHitChance - evasion --Actual roll
	randomRoll = math.random(100)
	return randomRoll <= rollUnder
end

function AttackEffects.doShortToHitRoll(attackerToHit, victim)
	evasion = AttackEffects.getEvasion(victim) --Evasion
	rollUnder = attackerToHit - evasion --Actual roll
	randomRoll = math.random(100)
	return randomRoll <= rollUnder
end

function AttackEffects.getEvasion(victim)
	victimFatigue = types.Actor.stats.dynamic.fatigue(victim)
	baseEvasion = ((types.Actor.stats.attributes.agility(victim).modified / 5) + (types.Actor.stats.attributes.luck(victim).modified / 10)) * (0.75 + (0.5 * (victimFatigue.current / victimFatigue.base)))
	victimActiveEffects = types.Actor.activeEffects(victim)
	sanctuaryEvasion = math.min(victimActiveEffects:getEffect(core.magic.EFFECT_TYPE.Sanctuary).magnitude, 100)
	chameleonEvasion = math.min((victimActiveEffects:getEffect(core.magic.EFFECT_TYPE.Chameleon).magnitude / 5), 100)
	evasion = baseEvasion + sanctuaryEvasion + chameleonEvasion
	return evasion
end

function AttackEffects.getToHitChance(attacker, weaponType)
	combatSkill = 0
	if attacker.type == types.Creature then
		combatSkill = types.Creature.record(attacker).combatSkill
	else
		skillStat = AttackEffects.getSkillStatForWeaponType(attacker, weaponType)
		combatSkill = skillStat.modified
	end
	attackerFatigue = types.Actor.stats.dynamic.fatigue(attacker)
	baseToHit = (combatSkill + (types.Actor.stats.attributes.agility(attacker).modified / 5) + (types.Actor.stats.attributes.luck(attacker).modified / 10)) * (0.75 + (0.5 * (attackerFatigue.current / attackerFatigue.base)))
	attackerActiveEffects = types.Actor.activeEffects(attacker)
	fortifyAttack = attackerActiveEffects:getEffect(core.magic.EFFECT_TYPE.FortifyAttack).magnitude
	blindMagnitude = attackerActiveEffects:getEffect(core.magic.EFFECT_TYPE.Blind).magnitude
	toHitChance = baseToHit + fortifyAttack - blindMagnitude
	return toHitChance
end



function AttackEffects.staggerAttack(attackInfo, victim, baseStaggerChance)
	if attackInfo.successful and (not AttackEffects.IsWeaponEffective(attackInfo.weapon, victim)) and AttackEffects.NGardeHitCheck(attackInfo) then
		staggerResist = 20 + ((types.Actor.stats.attributes.agility(victim).modified / 5) + (types.Actor.stats.attributes.luck(victim).modified / 10))
		attackerCombatSkill = 0
		if attackInfo.attacker.type == types.Creature then
			attackerCombatSkill = types.Creature.record(attackInfo.attacker).combatSkill
		else
			if attackInfo.weapon == nil then
				attackerCombatSkill = types.NPC.stats.skills.handtohand(actor).modified
			else
				weaponRecord = types.Weapon.record(attackInfo.weapon)
				skillStat = AttackEffects.getSkillStatForWeaponType(attackInfo.attacker, weaponRecord.type)
				attackerCombatSkill = skillStat.modified
			end
		end
		attackerCombatSkill = attackerCombatSkill / 5
		staggerChance = baseStaggerChance + (attackerCombatSkill / 10) + (types.Actor.stats.attributes.luck(attackInfo.attacker).modified / 10)
		rollUnder = staggerChance - staggerResist
		params = {}
		if rollUnder > 0 then
			knockdownChance = rollUnder / 4
			randomRoll = math.random(100)
			if randomRoll <= rollUnder then
				params.knockdown = randomRoll <= knockdownChance
				victim:sendEvent("MLT_DirAttack_doStagger", params)
			end
		end
	end
end


function AttackEffects.ArmorPierce(attackInfo, victim, pierceFraction)
	if attackInfo.successful and AttackEffects.IsWeaponEffective(attackInfo.weapon, victim) and AttackEffects.NGardePiercingHitCheck(attackInfo) then
		pierceHealth = attackInfo.damage.health * pierceFraction
		attackInfo.damage.health = attackInfo.damage.health - pierceHealth
		actorHealth = types.Actor.stats.dynamic.health(victim).current
		types.Actor.stats.dynamic.health(victim).current = math.max(actorHealth - pierceHealth, 0)
		if attackInfo.damage.fatigue ~= nil then
			pierceFatigue = attackInfo.damage.fatigue * pierceFraction
			attackInfo.damage.fatigue = attackInfo.damage.fatigue - pierceFatigue
		end
		if attackInfo.damage.magicka ~= nil then
			pierceMagicka = attackInfo.damage.magicka * pierceFraction
			attackInfo.damage.magicka = attackInfo.damage.magicka - pierceMagicka
		end
	end
end




function AttackEffects.IsWeaponEffective(weapon, victim)
	if weapon == nil then
		return true
	end
	weaponRecord = types.Weapon.record(weapon)
	victimActiveEffects = types.Actor.activeEffects(victim)
	normalResist = victimActiveEffects:getEffect(core.magic.EFFECT_TYPE.ResistNormalWeapons).magnitude
	if normalResist >= 100 then
		return weaponRecord.isMagical
	end
	return true
end


function AttackEffects.NGardeHitCheck(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	toReturn = true
	if attackInfo.ngarde_glancing then --A glancing hit is not clean enough to trigger an effect
		toReturn = false
	end
	if attackInfo.ngarde_perfectParry then -- A perfect parry should suffer no effects
		toReturn = false
	end
	if attackInfo.ngarde_parry then -- A parry blocks
		toReturn = false
	end
	return toReturn
end

function AttackEffects.NGardePiercingHitCheck(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	toReturn = true
	if attackInfo.ngarde_glancing then --A glancing hit is not clean enough to trigger an effect
		toReturn = false
	end
	if attackInfo.ngarde_perfectParry then -- A perfect parry should suffer no effects
		toReturn = false
	end
	if attackInfo.ngarde_parry then -- A parry can't block armor piercing
		toReturn = true
	end
	return toReturn
end


function AttackEffects.NGardeIsWeakParry(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	if attackInfo.ngarde_parry ~= nil and attackInfo.ngarde_parry then
		if attackInfo.ngarde_perfectParry ~= nil and attackInfo.ngarde_perfectParry then
			return false --No damage on perfect parries
		else
			return true
		end
	end
	return false
end


function AttackEffects.getSkillStatForWeaponType(actor, weaponType)
	if weaponType == types.Weapon.TYPE.AxeOneHand then
		return types.NPC.stats.skills.axe(actor)
	elseif weaponType == types.Weapon.TYPE.AxeTwoHand then
		return types.NPC.stats.skills.axe(actor)
	elseif weaponType == types.Weapon.TYPE.BluntOneHand then
		return types.NPC.stats.skills.bluntweapon(actor)
	elseif weaponType == types.Weapon.TYPE.BluntTwoClose then
		return types.NPC.stats.skills.bluntweapon(actor)
	elseif weaponType == types.Weapon.TYPE.BluntTwoWide then
		return types.NPC.stats.skills.bluntweapon(actor)
	elseif weaponType == types.Weapon.TYPE.LongBladeOneHand then
		return types.NPC.stats.skills.longblade(actor)
	elseif weaponType == types.Weapon.TYPE.LongBladeTwoHand then
		return types.NPC.stats.skills.longblade(actor)
	elseif weaponType == types.Weapon.TYPE.ShortBladeOneHand then
		return types.NPC.stats.skills.shortblade(actor)
	elseif weaponType == types.Weapon.TYPE.SpearTwoWide then
		return types.NPC.stats.skills.spear(actor)
	elseif weaponType == types.Weapon.TYPE.MarksmanThrown or weaponType == types.Weapon.TYPE.MarksmanBow or  weaponType == types.Weapon.TYPE.MarksmanCrossbow then
		return types.NPC.stats.skills.marksman(actor)
	elseif weaponType == types.Weapon.TYPE.Arrow or weaponType == types.Weapon.TYPE.Bolt then
		return types.NPC.stats.skills.marksman(actor)
	else --Hand to Hand
		return types.NPC.stats.skills.handtohand(actor)
	end
end

function AttackEffects.getSkillIDForWeaponType(weaponType)
	if weaponType == types.Weapon.TYPE.AxeOneHand then
		return "Axe"
	elseif weaponType == types.Weapon.TYPE.AxeTwoHand then
		return "Axe"
	elseif weaponType == types.Weapon.TYPE.BluntOneHand then
		return "BluntWeapon"
	elseif weaponType == types.Weapon.TYPE.BluntTwoClose then
		return "BluntWeapon"
	elseif weaponType == types.Weapon.TYPE.BluntTwoWide then
		return "BluntWeapon"
	elseif weaponType == types.Weapon.TYPE.LongBladeOneHand then
		return "LongBlade"
	elseif weaponType == types.Weapon.TYPE.LongBladeTwoHand then
		return "LongBlade"
	elseif weaponType == types.Weapon.TYPE.ShortBladeOneHand then
		return "ShortBlade"
	elseif weaponType == types.Weapon.TYPE.SpearTwoWide then
		return "Spear"
	elseif weaponType == types.Weapon.TYPE.MarksmanThrown or weaponType == types.Weapon.TYPE.MarksmanBow or  weaponType == types.Weapon.TYPE.MarksmanCrossbow then
		return "Marksman"
	elseif weaponType == types.Weapon.TYPE.Arrow or weaponType == types.Weapon.TYPE.Bolt then
		return "Marksman"
	else --Hand to Hand
		return "HandToHand"
	end
end

function AttackEffects.copyTable(info1)
	info2 = {}
	for key, value in pairs(info1) do
		info2[key] = value
	end
	return info2
end

return AttackEffects