-- injector ids = rev_pois_pick for pick


function onCommand()

	local poisonee = tes3.getPlayerTarget()
	

	if tes3.getPlayerTarget() then
	
	
		local playerHidden
		local menu = tes3ui.findMenu("MenuMulti")
		  if menu then
			 local sneak = menu:findChild("MenuMulti_sneak_icon") 
			  if sneak.visible then
				 playerHidden = true
			  else 
				playerHidden = false
			  end
		  end
		
		--[[if tes3.player.mobile.isPlayerDetected then
			tes3.messageBox("You must not be detected to be able to perform injections.")
			return false
		end]]--
		
		if not playerHidden then
			tes3.messageBox("People that can detect you won't let you inject them with malicious potions.")
		end
	
		local stack = false
		
		if tes3.getItemCount({reference = tes3.player, item = "rev_pois_pick"}) > 0 then
			stack = true
		end
	
		if not stack then
			tes3.messageBox("You require an injector to perform injections.")
			return false
		end
	
		tes3ui.showInventorySelectMenu({ reference = tes3.player, title = "Select poison to apply:", noResultsText = "You have no potions.",
		
			leaveMenuMode = true,
		
			filter = function(e)
			if e.item.objectType == tes3.objectType.alchemy then
				return true
			end
			return false
			end,
			
			callback = function(e)
			
				if not playerHidden then
				
					negativeEffects = { tes3.effect.burden, tes3.effect.drainAttribute, tes3.effect.drainHealth, tes3.effect.fireDamage, tes3.effect.frostDamage, tes3.effect.shockDamage, tes3.effect.drainMagicka, tes3.effect.drainFatigue, tes3.effect.drainSkill, tes3.effect.damageAttribute, tes3.effect.damageHealth, tes3.effect.damageMagicka, tes3.effect.damageFatigue, tes3.effect.damageSkill, tes3.effect.poison, tes3.effect.weaknesstoFire, tes3.effect.weaknesstoFrost, tes3.effect.weaknesstoShock, tes3.effect.weaknesstoMagicka, tes3.effect.weaknesstoCommonDisease, tes3.effect.weaknesstoBlightDisease, tes3.effect.weaknesstoPoison, tes3.effect.weaknesstoNormalWeapons, tes3.effect.disintegrateWeapon, tes3.effect.disintegrateArmor, tes3.effect.charm, tes3.effect.paralyze, tes3.effect.silence, tes3.effect.blind, tes3.effect.sound, tes3.effect.calmHumanoid, tes3.effect.calmCreature, tes3.effect.frenzyHumanoid, tes3.effect.frenzyCreature, tes3.effect.demoralizeHumanoid, tes3.effect.demoralizeCreature, tes3.effect.soultrap, tes3.effect.divineIntervention, tes3.effect.almsiviIntervention, tes3.effect.absorbAttribute, tes3.effect.absorbHealth, tes3.effect.absorbMagicka, tes3.effect.absorbFatigue, tes3.effect.absorbSkill, tes3.effect.turnUndead, tes3.effect.commandCreature, tes3.effect.commandHumanoid, tes3.effect.corprus, tes3.effect.vampirism, tes3.effect.sunDamage, tes3.effect.stuntedMagicka,}
				
					for k, v in pairs(e.item.effects) do
						for index, value in ipairs(negativeEffects)do 
							if value == v.id then
								tes3.messageBox({ message = "This potion has a negative effect - people that can detect you won't let you inject poisons into them, only positive potions.", buttons = {tes3.findGMST("sOK").value}, callback = function(msgBox) 
									tes3ui.leaveMenuMode()
								end})
								return false
							end
						end
					end
				end
			
				if e.item then
					
					if stack then
						tes3.removeItem({
							reference = tes3.player,
							item = "rev_pois_pick",
							count = 1,
						})
					end

					tes3ui.forcePlayerInventoryUpdate()
					tes3.applyMagicSource({
						reference = poisonee,
						target = poisonee,
						effects = e.item.effects,
						castChance = 100,
						name = e.item.name,
						
					})
					tes3.player.object.inventory:removeItem{
						mobile = tes3.mobilePlayer,
						item = e.item,
					}
				end
			end,
		})
	end
end

event.register(tes3.event.keyDown, onCommand, { filter = tes3.scanCode.y })