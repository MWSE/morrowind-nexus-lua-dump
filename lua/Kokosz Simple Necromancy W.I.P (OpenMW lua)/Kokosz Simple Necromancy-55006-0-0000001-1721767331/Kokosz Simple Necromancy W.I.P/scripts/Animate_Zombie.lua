local types = require('openmw.types')
local core = require('openmw.core')
local anim = require('openmw.animation')
local world = require('openmw.world')
local PlayerInventory = world.players[1]
local function OnUpdate()
	for i, actor in ipairs(world.activeActors) do 	
		local isNpc = types.NPC.objectIsInstance(actor) 
			if isNpc == true then
				local dist = (world.players[1].position - actor.position):length()
        			if dist < 200 then
					local effect = types.Actor.activeSpells(world.players[1]):isSpellActive("Kokosz_Animate_Zombie")
					if effect == true then
						local isDead = types.Actor.isDead(actor)
						if isDead == true then
							for i, Spellid in pairs(types.Actor.activeSpells(world.players[1])) do 																if Spellid.id == "kokosz_animate_zombie" then
									types.Actor.activeSpells(world.players[1]):remove(Spellid.activeSpellId)
									zombie = world.createObject('Ab_und_Zombie_Summon', 1)
									ReanimEffect = world.createObject('sprigganup', 1)
									zombie:teleport(actor.cell.name, actor.position)
									zombie:sendEvent('StartAIPackage', {type='Follow', target=world.players[1]})
									for i, Items in ipairs(types.Actor.inventory(actor):getAll()) do
										Items:moveInto(types.Actor.inventory(zombie))
									end
									ReanimEffect:teleport(actor.cell.name, actor.position)
									actor:remove()
									return
								
								end 
							end
							
						end

							
							

					end
				end
			end
		end
end

return { engineHandlers = {onUpdate = OnUpdate} }
