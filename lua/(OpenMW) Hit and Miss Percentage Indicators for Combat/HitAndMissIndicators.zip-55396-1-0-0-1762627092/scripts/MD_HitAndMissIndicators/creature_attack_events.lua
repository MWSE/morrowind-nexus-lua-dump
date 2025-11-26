local self = require("openmw.self")
local types = require("openmw.types")
local I = require('openmw.interfaces')
local hitchance = require("scripts.MD_HitAndMissIndicators.lib.hitchance")

I.Combat.addOnHitHandler(function(attack)
	if not types.Player.objectIsInstance(attack.attacker) then
		return
	end

	if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged then
	   if not attack.successful then 
			attack.attacker:sendEvent('MD_OnAttackMiss', {
				target = self,
				chanceToHit =  hitchance.calculate(attack.attacker, self)
			})
		elseif attack.damage.health then
			attack.attacker:sendEvent('MD_OnAttackHit', {
				target = self,
				damage = attack.damage.health,
				chanceToHit =  hitchance.calculate(attack.attacker, self)
			})
		elseif attack.damage.fatigue then
			attack.attacker:sendEvent('MD_OnPunchHit', {
				target = self,
				damage = attack.damage.fatigue,
				chanceToHit =  hitchance.calculate(attack.attacker, self)
			})
	   end
	end
end)
