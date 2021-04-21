local H = {}
local config = require("OEA.OEA8 Craft.config")
local damageFile = require("OEA.OEA8 Craft.damage")

function H.TestResist(eRef, AmmoWeapon, Weapon, WeaponData, AmmoTarget)
	if (tes3.player.data.OEA8 == nil) then
		tes3.player.data.OEA8 = {}
	end

	if (tes3.player.data.OEA8[900] ~= nil) and (tes3.player.data.OEA8[900] == 1) then
		return
	end

	local Class = eRef.baseObject.class
	if (Class == nil) then
		if (Weapon ~= nil) and (WeaponData ~= nil) and (Weapon.enchantment ~= nil) then
			damageFile.WeaponDamage(Weapon, WeaponData, AmmoWeapon)
		elseif (Weapon ~= nil) and (WeaponData == nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (Weapon.enchantment ~= nil) then
			damageFile.ThrowingDamage(Weapon, AmmoWeapon, AmmoTarget)
		elseif (AmmoWeapon ~= nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (AmmoWeapon.enchantment ~= nil) then
			damageFile.AmmoDamage(Weapon, WeaponData, AmmoWeapon, AmmoTarget)
		end
		return
	end

	local ChanceVar = (("Resist_%s"):format(Class.id))
	local Chance = config[ChanceVar]
	if (Chance == nil) then
		if (Weapon ~= nil) and (WeaponData ~= nil) and (Weapon.enchantment ~= nil) then
			damageFile.WeaponDamage(Weapon, WeaponData, AmmoWeapon)
		elseif (Weapon ~= nil) and (WeaponData == nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (Weapon.enchantment ~= nil) then
			damageFile.ThrowingDamage(Weapon, AmmoWeapon, AmmoTarget)
		elseif (AmmoWeapon ~= nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (AmmoWeapon.enchantment ~= nil) then
			damageFile.AmmoDamage(Weapon, WeaponData, AmmoWeapon, AmmoTarget)
		end
		return
	end

	local Roll = math.random(100)
	if (Weapon ~= nil) and (WeaponData ~= nil) and (Weapon.enchantment ~= nil) then
		if (Chance >= Roll) then
			for i, effect in ipairs(Weapon.enchantment.effects) do
				tes3.runLegacyScript({ command = ("RemoveEffects, %s"):format(effect.id), reference = eRef })
			end
			tes3.messageBox("The eneny has resisted your poison!")
			tes3.player.data.OEA8[900] = 1
		end
		damageFile.WeaponDamage(Weapon, WeaponData, AmmoWeapon)
	elseif (Weapon ~= nil) and (WeaponData == nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (Weapon.enchantment ~= nil) then
		if (Chance >= Roll) then
			for i, effect in ipairs(Weapon.enchantment.effects) do
				tes3.runLegacyScript({ command = ("RemoveEffects, %s"):format(effect.id), reference = eRef })
			end
			tes3.messageBox("The eneny has resisted your poison!")
			tes3.player.data.OEA8[900] = 1
		end
		damageFile.ThrowingDamage(Weapon, AmmoWeapon, AmmoTarget)
	elseif (AmmoWeapon ~= nil) and (AmmoTarget ~= nil) and (AmmoTarget ~= 0) and (AmmoWeapon.enchantment ~= nil) then
		if (Chance >= Roll) then
			for i, effect in ipairs(AmmoWeapon.enchantment.effects) do
				tes3.runLegacyScript({ command = ("RemoveEffects, %s"):format(effect.id), reference = eRef })
			end
			tes3.messageBox("The eneny has resisted your poison!")
			tes3.player.data.OEA8[900] = 1
		end
		damageFile.AmmoDamage(Weapon, WeaponData, AmmoWeapon, AmmoTarget)
	end
end

return H