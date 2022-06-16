event.register("calcHitChance", function(e)
	local attackerZ = e.attacker.position.z
	local targetZ = e.target.position.z
	if attackerZ > targetZ then
		local hitChanceBonus = (attackerZ - targetZ)
		e.hitChance = (e.hitChance + hitChanceBonus)
	end
end)