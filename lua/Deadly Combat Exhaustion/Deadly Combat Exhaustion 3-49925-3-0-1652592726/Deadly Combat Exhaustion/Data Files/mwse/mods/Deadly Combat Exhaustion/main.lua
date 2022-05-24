--Define a function that triggers every "calcHitChance" event (e.g. an attack of some sort).
event.register("calcHitChance", function(e)

	--If the actor being attacked is out of stamina or paralyzed or over-encumbered...
	if e.targetMobile.fatigue.current <= 1 or e.targetMobile.paralyze > 0 or e.targetMobile.encumbrance.normalized >= 1.00 then
	
		--...then set the attacker's chance to hit to 100%.
		e.hitChance = 100
		
	--Close out the "if then" statement.
	end		

--Close out the function.
end)	
