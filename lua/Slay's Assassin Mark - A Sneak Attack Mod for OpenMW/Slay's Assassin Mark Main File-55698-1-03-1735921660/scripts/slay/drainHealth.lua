local nearby = require("openmw.nearby")
local self = require("openmw.self")
local async = require("openmw.async")
local types = require("openmw.types")
local core = require("openmw.core")
local anim = require('openmw.animation')
local time = require('openmw_aux.time')

local isActorHealthDrained = false	--resets the tag to allow drain to function 
local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.DamageHealth].areaStatic --magic effect tag to apply to vfx
local model = types.Static.record("SLAY_Assassin's_Mark").model --vfx model
local player --needed to send back events to the player


local function healthDrainEnded(drainValue) --function to return the health back to the actor if the mark ends
	local healValue = drainValue
	local baseHealth = types.Actor.stats.dynamic.health(self).base
	local hpToHeal
	
	--print('isActorHealthDrained is: ' ..tostring(isActorHealthDrained))
	local hpCurrentValue = types.Actor.stats.dynamic.health(self).current  --get the current hp of the target, it's liable to have changed between initial drain and the drain end function
	--print('The current hp value of the enemy is:'.. tostring(hpCurrentValue))
			hpCurrentValue = types.Actor.stats.dynamic.health(self).current
			hpToHeal = hpCurrentValue + healValue
			if hpCurrentValue > 0 then --if the actor is still alive
				if hpToHeal > baseHealth then
					types.Actor.stats.dynamic.health(self).current = baseHealth
					vfx() --stop vfx
					player:sendEvent("stopHeartSound")
				else
					types.Actor.stats.dynamic.health(self).current = hpCurrentValue + healValue
					vfx() --stop vfx
					player:sendEvent("stopHeartSound")
					--print('We returned:'..tostring(drainValue)..' hp.')
					--print('Current hpCurrentvalue:' ..tostring(hpCurrentValue))
					--print('Current written hpvalue: ' ..tostring(types.Actor.stats.dynamic.health(self).current))
										
				end
			
			end
end

local healthDrainEnded = async:registerTimerCallback("healthDrainEnded", healthDrainEnded) --For me to me in the future: remember no () in the function here for async timers, (string, function name)


local function applyHealthDrain(data) 	--receives a value determined by the playerscript, and the player as an object, then changes the current health of the actor accordingly
	--print('We made it to the applyHealthDrain function')
	--print(tostring(damageValue))
	local damageValue = data.mult
	player = data.player
	local actorStartingHealthValue = types.Actor.stats.dynamic.health(self).current	--get current health of the target
	local drainedHealthTotal 
	
	if isActorHealthDrained == false then --check to make sure the actor hasn't gotten drained before
			local drainValue = actorStartingHealthValue * damageValue 		--How much to subtract from current health pool 	
				if actorStartingHealthValue > 0 then 	--if the target is alive, important as this would be called on corpses otherwise
					player:sendEvent("playWhooshSound")
					vfx = time.runRepeatedly(function()
						anim.addVfx(self, model, {boneName = '', loop = false, vfxId="SLAY_Assassin's_Mark"})
						
						if types.Actor.stats.dynamic.health(self).current < 1 then 
							player:sendEvent("stopHeartSound")
							vfx()
						end
						end, 1.7*time.second)
						
					drainedHealthTotal = actorStartingHealthValue - drainValue
					types.Actor.stats.dynamic.health(self).current = drainedHealthTotal
					isActorHealthDrained = true
					
					player:sendEvent("startHeartSound")
					
										
					async:newSimulationTimer(10, healthDrainEnded, drainValue) --Mark lasts for 10 seconds, could possibly make this mutable, calls the above function to end the mark
					--print('We drained the actors health:' .. tostring(drainedHealthTotal))
				end
	end
end
		
	
	return {
		eventHandlers = { 
		applyHealthDrain = applyHealthDrain,
		
		
		}
}
