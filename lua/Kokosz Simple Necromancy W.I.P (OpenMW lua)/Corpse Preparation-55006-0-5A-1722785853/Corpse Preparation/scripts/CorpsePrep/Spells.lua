local types = require('openmw.types')
local core = require('openmw.core')
local anim = require('openmw.animation')
local world = require('openmw.world')
local PlayerInventory = world.players[1]
local ActorToReanimate = nil
local WasAnimationPlayed = false
local function OnUpdate()

	if ActorToReanimate and WasAnimationPlayed == false then
		anim.playQueued(ActorToReanimate, 'knockout', {startkey = 'loop stop', stopkey = 'stop', loops = 0})
		WasAnimationPlayed = true
		ActorToReanimate:sendEvent('StartAIPackage', {type='Follow', target=world.players[1]})
		local effect = types.Actor.activeEffects(ActorToReanimate)
		effect:getEffect("paralyze")
		effect:remove("paralyze")
		ActorToReanimate = nil
		
	end
	

	for i, actor in ipairs(world.activeActors) do 	 
			if actor.recordId == "ksn_zombie_summon_prop" or actor.recordId == "ksn_skeleton_weak_prop" then
					local effect = types.Actor.activeSpells(actor):isSpellActive("ksn_reanimate")
					if effect == true then
							if anim.isPlaying(actor, "knockout") then
								for i, Spellid in pairs(types.Actor.activeSpells(actor)) do 																	if Spellid.id == "ksn_reanimate" then
										types.Actor.activeSpells(actor):remove(Spellid.activeSpellId)
										ReanimEffect = world.createObject('sprigganup', 1)
										ReanimEffect:teleport(actor.cell.name, actor.position)
										ActorToReanimate = actor
										WasAnimationPlayed = false
										return
									
								
									end 
								end
							end

							
							

					end
				
			end





	end
end

return { engineHandlers = {onUpdate = OnUpdate} }
