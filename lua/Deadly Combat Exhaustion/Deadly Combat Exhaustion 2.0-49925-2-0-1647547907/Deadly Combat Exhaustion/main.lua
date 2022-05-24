event.register("calcHitChance", function(e)	--We detect when a "hit" is made (an attack of some sort).
	if e.targetMobile.fatigue.current <= 1 or e.targetMobile.paralyze > 0 then 	--If the actor being attacked is out of stamina or paralyzed then...
		e.hitChance = 100 	--...the attacker's chance to land a hit is set to 100%.
	end		--Close out the "if then" statement.
end)	--Close out the function.
