-- Radiant Shield gives armor and blinds melee attackers onHit

G.onMgefAdded["t_alteration_radshield"] = function(key, eff, activeSpell, entry)
	activeEffects:modify(entry.avgMagnitude, "shield")
end

G.onMgefRemoved["t_alteration_radshield"] = function(key, entry)
	activeEffects:modify(-entry.avgMagnitude, "shield")
end

G.onHitJobs["t_alteration_radshield"] = function(attack)
	if not attack.successful then return end
	local shieldMagnitude = activeEffects:getEffect("t_alteration_radshield").magnitude
	if shieldMagnitude <= 0 then return end
	if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
	if not attack.attacker then return end
	
	core.sendGlobalEvent('TD_ApplyBlind', {
		target = attack.attacker,
		magnitude = shieldMagnitude,
		duration = 1.5,
	})
end