local H = {}

function H.PoisonApply(potionName, Weapon, WeaponData)
	local Check
	local Append = " (Poisoned)"
	local j
	local k
	local Length
	local TableLength
	local tempName
	local tempChant
	local MaxCharge
	local ChargeCost

	local tes3iterator = tes3.player.object.inventory
	for _, tes3iteratorNode in pairs(tes3iterator) do
		if (tes3iteratorNode.object.name:lower() == potionName:lower()) then
			if (tes3iteratorNode.object.objectType ~= tes3.objectType.alchemy) then
				Check = 2
				tes3.messageBox("This item is not a potion. Please re-equip the weapon and try again.")
				break
			else
				Check = 1
				if (tes3.player.data.OEA8 == nil) then
					tes3.player.data.OEA8 = {}
				end

				if (Weapon.enchantment ~= nil) then
					tempName = Weapon.name
					tempChant = Weapon.enchantment
					tes3.player.data.OEA8[Weapon.id] = {
						oldName = tempName,
						enchantment = tempChant
					}
				else
					tempName = Weapon.name
					tes3.player.data.OEA8[Weapon.id] = {
						oldName = tempName
					}
				end
				TableLength = table.size(tes3.player.data.OEA8)
				if (Weapon.enchantment ~= nil) then
					MaxCharge = Weapon.enchantment.maxCharge
					ChargeCost = Weapon.enchantment.chargeCost
				else
					MaxCharge = nil
					ChargeCost = nil
				end
				if (Weapon.enchantment ~= nil) and (Weapon.enchantment.castType == tes3.enchantmentType.onStrike) then
					if (WeaponData ~= nil) and (ChargeCost ~= nil) and (WeaponData.charge >= ChargeCost) then
						local Ench = tes3enchantment.create({
							id = string.sub(("OEA8_%s_%s"):format(TableLength, Weapon.id), 1, 31),
							castType = tes3.enchantmentType.onStrike,
							chargeCost = ChargeCost or 1,
							maxCharge = MaxCharge or 20
						})
						if (Ench == nil) then
							Ench = tes3.getObject(("OEA8_%s_%s"):format(TableLength, Weapon.id))
						end

						local PotionEffects = tes3iteratorNode.object.effects
						j = 0
						for i, effect in ipairs(PotionEffects) do
							Ench.effects[i].id = effect.id
							Ench.effects[i].rangeType = tes3.effectRange.touch
							Ench.effects[i].min = effect.min
							Ench.effects[i].max = effect.max
							Ench.effects[i].duration = effect.duration
							Ench.effects[i].radius = effect.radius
							Ench.effects[i].skill = effect.skill
							Ench.effects[i].attribute = effect.attribute
							if (effect.id >= 0) then
								j = i
							end
						end

						for i, effect in ipairs(Weapon.enchantment.effects) do
							k = i + j
							if (k < 9) then
								Ench.effects[k].id = effect.id
								Ench.effects[k].rangeType = effect.rangeType
								Ench.effects[k].min = effect.min
								Ench.effects[k].max = effect.max
								Ench.effects[k].duration = effect.duration
								Ench.effects[k].radius = effect.radius
								Ench.effects[k].skill = effect.skill
								Ench.effects[k].attribute = effect.attribute
							end
						end
						tes3.player.data.OEA8[Weapon.id].newEnchantment = Ench.id
						Weapon.enchantment = Ench

						Length = string.len(Weapon.name)
						if (Length > 20) then
							Weapon.name = string.sub(Weapon.name, 1, 20)
						end
						Weapon.name = string.format("%s%s", Weapon.name, Append)
					elseif (WeaponData ~= nil) and (ChargeCost ~= nil) and (WeaponData.charge < ChargeCost) then
						TableLength = table.size(tes3.player.data.OEA8)
						local Ench2 = tes3enchantment.create({
							id = string.sub(("OEA8_%s_%s"):format(TableLength, Weapon.id), 1, 31),
							castType = tes3.enchantmentType.onStrike,
							chargeCost = 1,
							maxCharge = MaxCharge or 20
						})
						if (Ench2 == nil) then
							Ench2 = tes3.getObject(("OEA8_%s_%s"):format(TableLength, Weapon.id))
						end

						local PotionEffects2 = tes3iteratorNode.object.effects
						for i, effect in ipairs(PotionEffects2) do
							Ench2.effects[i].id = effect.id
							Ench2.effects[i].rangeType = tes3.effectRange.touch
							Ench2.effects[i].min = effect.min
							Ench2.effects[i].max = effect.max
							Ench2.effects[i].duration = effect.duration
							Ench2.effects[i].radius = effect.radius
							Ench2.effects[i].skill = effect.skill
							Ench2.effects[i].attribute = effect.attribute
						end

						tes3.player.data.OEA8[Weapon.id].newEnchantment = Ench2.id
						Weapon.enchantment = Ench2
						if (WeaponData ~= nil) then
							WeaponData.charge = WeaponData.charge + 1
						end

						Length = string.len(Weapon.name)
						if (Length > 20) then
							Weapon.name = string.sub(Weapon.name, 1, 20)
						end
						Weapon.name = string.format("%s%s", Weapon.name, Append)
					end
				else
					TableLength = table.size(tes3.player.data.OEA8)
					local Ench3 = tes3enchantment.create({
						id = string.sub(("OEA8_%s_%s"):format(TableLength, Weapon.id), 1, 31),
						castType = tes3.enchantmentType.onStrike,
						chargeCost = 1,
						maxCharge = MaxCharge or 20
					})
					if (Ench3 == nil) then
						Ench3 = tes3.getObject(("OEA8_%s_%s"):format(TableLength, Weapon.id))
					end

					local PotionEffects3 = tes3iteratorNode.object.effects
					for i, effect in ipairs(PotionEffects3) do
						Ench3.effects[i].id = effect.id
						Ench3.effects[i].rangeType = tes3.effectRange.touch
						Ench3.effects[i].min = effect.min
						Ench3.effects[i].max = effect.max
						Ench3.effects[i].duration = effect.duration
						Ench3.effects[i].radius = effect.radius
						Ench3.effects[i].skill = effect.skill
						Ench3.effects[i].attribute = effect.attribute
					end

					tes3.player.data.OEA8[Weapon.id].newEnchantment = Ench3.id
					Weapon.enchantment = Ench3
					if (WeaponData ~= nil) and (MaxCharge == nil) then
						WeaponData.charge = 20
					end

					Length = string.len(Weapon.name)
					if (Length > 20) then
						Weapon.name = string.sub(Weapon.name, 1, 20)
					end
					Weapon.name = string.format("%s%s", Weapon.name, Append)
				end
				tes3.messageBox("The poison has been successfully applied.")
				local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
				if (menu ~= nil) then
					local child = menu:findChild(tes3ui.registerID("MenuMulti_enchantment_icon"))
					if (child ~= nil) then
						child.color = tes3ui.getPalette("fatigue_color")
						child.visible = true
					end
				end
				mwscript.removeItem({ reference = tes3.player, item = tes3iteratorNode.object.id, count = 1 })
				break
			end
		end
	end
	if (Check == nil) or (Check == 0) then
		tes3.messageBox("No such potion was found.")
	end
	Check = 0
end


function H.AmmoPoisonApply(potionName, AmmoWeapon)
	local Check
	local Append = " (Poisoned)"
	local j
	local k
	local Length
	local TableLength
	local tempName
	local tempChant

	local tes3iterator = tes3.player.object.inventory
	for _, tes3iteratorNode in pairs(tes3iterator) do
		if (tes3iteratorNode.object.name:lower() == potionName:lower()) then
			if (tes3iteratorNode.object.objectType ~= tes3.objectType.alchemy) then
				Check = 2
				tes3.messageBox("This item is not a potion. Please re-equip the weapon and try again.")
				break
			else
				Check = 1
				if (tes3.player.data.OEA8 == nil) then
					tes3.player.data.OEA8 = {}
				end

				if (AmmoWeapon.enchantment ~= nil) then
					tempName = AmmoWeapon.name
					tempChant = AmmoWeapon.enchantment
					tes3.player.data.OEA8[AmmoWeapon.id] = {
						oldName = tempName,
						enchantment = tempChant
					}
				else
					tempName = AmmoWeapon.name
					tes3.player.data.OEA8[AmmoWeapon.id] = {
						oldName = tempName
					}
				end
				if (AmmoWeapon.enchantment ~= nil) and (AmmoWeapon.enchantment.castType == tes3.enchantmentType.onStrike) then
					TableLength = table.size(tes3.player.data.OEA8)
					local Ench = tes3enchantment.create({
						id = string.sub(("OEA8_%s_%s"):format(TableLength, AmmoWeapon.id), 1, 31),
						castType = tes3.enchantmentType.onStrike,
						chargeCost = 1,
						maxCharge = 20
					})
					if (Ench == nil) then
						Ench = tes3.getObject(("OEA8_%s_%s"):format(TableLength, AmmoWeapon.id))
					end

					local PotionEffects = tes3iteratorNode.object.effects
					j = 0
					for i, effect in ipairs(PotionEffects) do
						Ench.effects[i].id = effect.id
						Ench.effects[i].rangeType = tes3.effectRange.touch
						Ench.effects[i].min = effect.min
						Ench.effects[i].max = effect.max
						Ench.effects[i].duration = effect.duration
						Ench.effects[i].radius = effect.radius
						Ench.effects[i].skill = effect.skill
						Ench.effects[i].attribute = effect.attribute
						if (effect.id >= 0) then
							j = i
						end
					end

					for i, effect in ipairs(AmmoWeapon.enchantment.effects) do
						k = i + j
						if (k < 9) then
							Ench.effects[k].id = effect.id
							Ench.effects[k].rangeType = effect.rangeType
							Ench.effects[k].min = effect.min
							Ench.effects[k].max = effect.max
							Ench.effects[k].duration = effect.duration
							Ench.effects[k].radius = effect.radius
							Ench.effects[k].skill = effect.skill
							Ench.effects[k].attribute = effect.attribute
						end
					end
					tes3.player.data.OEA8[AmmoWeapon.id].newEnchantment = Ench.id
					AmmoWeapon.enchantment = Ench

					Length = string.len(AmmoWeapon.name)
					if (Length > 20) then
						AmmoWeapon.name = string.sub(AmmoWeapon.name, 1, 20)
					end
					AmmoWeapon.name = string.format("%s%s", AmmoWeapon.name, Append)
				else
					TableLength = table.size(tes3.player.data.OEA8)
					local Ench2 = tes3enchantment.create({
						id = string.sub(("OEA8_%s_%s"):format(TableLength, AmmoWeapon.id), 1, 31),
						castType = tes3.enchantmentType.onStrike,
						chargeCost = 1,
						maxCharge = 20
					})
					if (Ench2 == nil) then
						Ench2 = tes3.getObject(("OEA8_%s_%s"):format(TableLength, AmmoWeapon.id))
					end

					local PotionEffects2 = tes3iteratorNode.object.effects
					for i, effect in ipairs(PotionEffects2) do
						Ench2.effects[i].id = effect.id
						Ench2.effects[i].rangeType = tes3.effectRange.touch
						Ench2.effects[i].min = effect.min
						Ench2.effects[i].max = effect.max
						Ench2.effects[i].duration = effect.duration
						Ench2.effects[i].radius = effect.radius
						Ench2.effects[i].skill = effect.skill
						Ench2.effects[i].attribute = effect.attribute
					end

					tes3.player.data.OEA8[AmmoWeapon.id].newEnchantment = Ench2.id
					AmmoWeapon.enchantment = Ench2

					Length = string.len(AmmoWeapon.name)
					if (Length > 20) then
						AmmoWeapon.name = string.sub(AmmoWeapon.name, 1, 20)
					end
					AmmoWeapon.name = string.format("%s%s", AmmoWeapon.name, Append)
				end
				tes3.messageBox("The poison has been successfully applied.")
				local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
				if (menu ~= nil) then
					local child = menu:findChild(tes3ui.registerID("MenuMulti_enchantment_icon"))
					if (child ~= nil) then
						child.color = tes3ui.getPalette("fatigue_color")
						child.visible = true
					end
				end
				mwscript.removeItem({ reference = tes3.player, item = tes3iteratorNode.object.id, count = 1 })
				break
			end
		end
	end
	if (Check == nil) or (Check == 0) then
		tes3.messageBox("No such potion was found.")
	end
	Check = 0
end

return H