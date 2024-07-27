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
					local effect = types.Actor.activeSpells(world.players[1]):isSpellActive("kokosz_animate_skeleton")
					if effect == true then
						local isDead = types.Actor.isDead(actor)
						if isDead == true then
							for i, Spellid in pairs(types.Actor.activeSpells(world.players[1])) do 																if Spellid.id == "kokosz_animate_skeleton" then
									local BlackSoulGem = types.Actor.inventory(world.players[1]):findAll('AB_Misc_SoulGemBlack_Filled')
									local count = types.Actor.inventory(world.players[1]):countOf('AB_Misc_SoulGemBlack_Filled')
									if  count == 0 then
										world.players[1]:sendEvent("ShowMessage", "You don't have right ingridients")
										types.Actor.activeSpells(world.players[1]):remove(Spellid.activeSpellId)
										return
									end
									for i, gems in ipairs(BlackSoulGem) do
										gems:remove(1)
										types.Actor.activeSpells(world.players[1]):remove(Spellid.activeSpellId)
										zombie = world.createObject('_Skeleton', 1)
										ReanimEffect = world.createObject('sprigganup', 1)
										zombie:teleport(actor.cell.name, actor.position)
											for i, Items in ipairs(types.Actor.inventory(actor):getAll()) do
												Items:moveInto(types.Actor.inventory(zombie))
											end
										zombie:sendEvent('StartAIPackage', {type='Follow', target=world.players[1]})
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
end

return { engineHandlers = {onUpdate = OnUpdate} }
