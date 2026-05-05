local self = require('openmw.self')
local types = require('openmw.types')


--=======================
--  Variable
--=======================
local DamageVar = nil
local spareDamage = 0


--=======================
--  Function
--=======================
local function ApplyDamageToTargetActorLocal(Passed)
	--if the cost is less then 1 put it in our spare magic bucket, we'll subtract it when we get 1 whole damage
	if Passed.Damage < 1 then
		spareDamage = spareDamage + Passed.Damage
	end
		
	
	if Passed.Damage >= 1 then
		-- Round the result for subtraction 
		local DamageInteger =math.floor(Passed.Damage)
		-- Reduce target health
		types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current-DamageInteger
		-- Grab the Damage we rounded off and put in the bucket as well
		spareDamage = spareDamage+Passed.Damage-DamageInteger
	end
	
	--check the bucket, if it has enough, send it
	if spareDamage >= 1 then
		types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - 1
		spareDamage = spareDamage-1
	end
	
end


--====================================================================================================================================================================================================
--  Event Handler
--====================================================================================================================================================================================================
return{

	eventHandlers = {
    ApplyDamageToTargetActor = ApplyDamageToTargetActorLocal
	}
	
}