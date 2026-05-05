-- Reflects physical dmg (multiplicative) from onHit melee and range

local reflectMult = 1.0

G.onAggregateReset["t_mysticism_reflectdmg"] = function()
	reflectMult = 1.0
end

G.onAggregateEffect["t_mysticism_reflectdmg"] = function(key, eff, activeSpell)
	local pct = (eff.magnitudeThisFrame or 0) / 100
	if pct > 0 then
		reflectMult = reflectMult * (1 - pct)
	end
end

G.onHitJobs["t_mysticism_reflectdmg"] = function(attack)
	if not attack.successful then return end
	if reflectMult >= 1 then return end
	if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee
		and attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Ranged then return end
	if not attack.damage then return end
	
	if not attack.attacker or not attack.attacker:isValid() then return end
	local healthIn  = attack.damage.health  or 0
	local fatigueIn = attack.damage.fatigue or 0
	if healthIn <= 0 and fatigueIn <= 0 then return end
	
	local reflectFrac = 1 - reflectMult
	local reflected = {}
	if healthIn > 0 then
		attack.damage.health = healthIn * reflectMult
		reflected.health = healthIn * reflectFrac
	end
	if fatigueIn > 0 then
		attack.damage.fatigue = fatigueIn * reflectMult
		reflected.fatigue = fatigueIn * reflectFrac
	end
	
	attack.attacker:sendEvent('Hit', {
		attacker   = self.object,
		damage     = reflected,
		sourceType = I.Combat.ATTACK_SOURCE_TYPES.Unspecified,
		successful = true,
		strength   = 1,
	})
end