event.register("calcHitChance", function(e) 			--We detect when a "hit" is made (an attack of some sort).
	if e.targetMobile.fatigue.current <= 1 then 		--If the actor being attacked is out of stamina then...
		e.hitChance = 100 														--...the attacker's chance to land an attack is set to 100%.
	end 																						--Close out the "if then" statement.
end)																							--Close out the function.
