local self = require('openmw.self')
local types = require('openmw.types')


--=======================
--  Variable
--=======================
local sparemagicka = 0


--=======================
--  Function
--=======================
local function ApplySpellAbsorbtionToTargetActorLocal(Passed)
	--if the cost is less then 1 put it in our spare magic bucket, we'll subtract it when we get 1 whole magickaCost
	if Passed.magickaCost < 1 then
		sparemagicka = sparemagicka + Passed.magickaCost
	end
		
	
	if Passed.magickaCost >= 1 then
		-- Round the result for subtraction 
		local magickaInteger =math.floor(Passed.magickaCost)
		-- Reduce target magicka
		types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current+magickaInteger
		-- Grab the magickaCost we rounded off and put in the bucket as well
		sparemagicka = sparemagicka+Passed.magickaCost-magickaInteger
	end
	
	--check the bucket, if it has enough, send it
	if sparemagicka >= 1 then
		types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current + 1
		sparemagicka = sparemagicka-1
	end
	
	if types.Actor.stats.dynamic.magicka(self).current > types.Actor.stats.dynamic.magicka(self).base then
		types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).base
	end

end


--====================================================================================================================================================================================================
--  Event Handler
--====================================================================================================================================================================================================
return{

	eventHandlers = {
    ApplySpellAbsorbtionToTargetActor = ApplySpellAbsorbtionToTargetActorLocal
	}
	
}