local config = require("OEA.OEA8 Craft.config")
local colorFile = require("OEA.OEA8 Craft.color")
local mainFile = require("OEA.OEA8 Craft.main")
local H = {}

function H.ThrowingDamage(Weapon, AmmoWeapon, AmmoTarget)
	if (Weapon == nil) then
		return
	end

	local Length = string.len(Weapon.name)
	if (string.sub(Weapon.name, Length - 10, Length) ~= " (Poisoned)") then
		return
	end

	if (tes3.player.data.OEA8[Weapon.id].FireCounter == nil) then
		tes3.player.data.OEA8[Weapon.id].FireCounter = 0
	end
	if (tes3.player.data.OEA8[Weapon.id].FireCounter < tonumber(config.Batchings)) then
		if (mwscript.getItemCount({ reference = tes3.player, item = Weapon.id }) > 0) then
			if (AmmoTarget ~= nil) and (AmmoTarget ~= 1) and ((tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0)) then
				tes3.messageBox("The enemy has been poisoned!")
			end
			tes3.player.data.OEA8[900] = 0
			return
		end
	end	
	tes3.player.data.OEA8[Weapon.id].FireCounter = nil

	Weapon.name = tes3.player.data.OEA8[Weapon.id].oldName
	if (tes3.player.data.OEA8[Weapon.id] ~= nil) and (tes3.player.data.OEA8[Weapon.id].enchantment ~= nil) then
		Weapon.enchantment = tes3.player.data.OEA8[Weapon.id].enchantment
	else
		Weapon.enchantment = nil
	end
	tes3.player.data.OEA8[Weapon.id] = nil

	colorFile.ReplaceColor(Weapon, AmmoWeapon)
	if (AmmoTarget ~= nil) and (AmmoTarget ~= 1) and ((tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0)) then
		tes3.messageBox("The enemy has been poisoned!")
		if (Weapon == nil) or ((Weapon ~= nil) and (string.sub(Weapon.name, Length - 10, Length) ~= " (Poisoned)")) then
			tes3.messageBox("Your poisoned thrower(s) have been used up.")
		end
	elseif (AmmoTarget ~= nil) and (AmmoTarget == 1) then
		AmmoTarget = 0
		mainFile.AmmoTargetZero()
		if (Weapon == nil) or ((Weapon ~= nil) and (string.sub(Weapon.name, Length - 10, Length) ~= " (Poisoned)")) then
			tes3.messageBox("Your poisoned thrower(s) have been used up.")
		end
	end
	tes3.player.data.OEA8[900] = 0
end

function H.AmmoDamage(Weapon, WeaponData, AmmoWeapon, AmmoTarget)
	if (Weapon ~= nil) and (WeaponData == nil) then
		H.ThrowingDamage(Weapon, AmmoWeapon, AmmoTarget)
		return
	end

	if (AmmoWeapon == nil) then
		return
	end

	local Length = string.len(AmmoWeapon.name)
	if (string.sub(AmmoWeapon.name, Length - 10, Length) ~= " (Poisoned)") then
		return
	end

	if (tes3.player.data.OEA8[Weapon.id].FireCounter == nil) then
		tes3.player.data.OEA8[Weapon.id].FireCounter = 0
	end
	if (tes3.player.data.OEA8[AmmoWeapon.id].FireCounter < tonumber(config.Batchings)) then
		if (mwscript.getItemCount({ reference = tes3.player, item = AmmoWeapon.id }) > 0) then
			if (AmmoTarget ~= nil) and (AmmoTarget ~= 1) and ((tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0)) then
				tes3.messageBox("The enemy has been poisoned!")
			end
			tes3.player.data.OEA8[900] = 0
			return
		end
	end	
	tes3.player.data.OEA8[Weapon.id].FireCounter = nil

	AmmoWeapon.name = tes3.player.data.OEA8[AmmoWeapon.id].oldName
	if (tes3.player.data.OEA8[AmmoWeapon.id] ~= nil) and (tes3.player.data.OEA8[AmmoWeapon.id].enchantment ~= nil) then
		AmmoWeapon.enchantment = tes3.player.data.OEA8[AmmoWeapon.id].enchantment
	else
		AmmoWeapon.enchantment = nil
	end
	tes3.player.data.OEA8[AmmoWeapon.id] = nil

	colorFile.ReplaceColor(Weapon, AmmoWeapon)
	if (AmmoTarget ~= nil) and (AmmoTarget ~= 1) and ((tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0)) then
		tes3.messageBox("The enemy has been poisoned!")
		if (AmmoWeapon == nil) or ((AmmoWeapon ~= nil) and (string.sub(AmmoWeapon.name, Length - 10, Length) ~= " (Poisoned)")) then
			tes3.messageBox("Your poisoned arrow(s) have been used up.")
		end
	elseif (AmmoTarget ~= nil) and (AmmoTarget == 1) then
		AmmoTarget = 0
		mainFile.AmmoTargetZero()
		if (AmmoWeapon == nil) or ((AmmoWeapon ~= nil) and (string.sub(AmmoWeapon.name, Length - 10, Length) ~= " (Poisoned)")) then
			tes3.messageBox("Your poisoned arrow(s) have been used up.")
		end
	end
	tes3.player.data.OEA8[900] = 0
end

function H.WeaponDamage(Weapon, WeaponData, AmmoWeapon)
	if (tes3.mobilePlayer.readiedWeapon == nil) or (Weapon == nil) then
		return
	end

	if (tes3.mobilePlayer.readiedWeapon == nil) or (Weapon == nil) then
		return
	end

	local Length = string.len(Weapon.name)
	if (string.sub(Weapon.name, Length - 10, Length) ~= " (Poisoned)") then
		return
	end

	if (tes3.player.data.OEA8[Weapon.id] == nil) then
		return
	end

	if (tes3.player.data.OEA8[Weapon.id].HitCounter == nil) then
		tes3.player.data.OEA8[Weapon.id].HitCounter = 0
	end
	tes3.player.data.OEA8[Weapon.id].HitCounter = tes3.player.data.OEA8[Weapon.id].HitCounter + 1
	if (tes3.player.data.OEA8[Weapon.id].HitCounter < config.MultiHit) and (WeaponData.charge > 0) then
		if (tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0) then
			tes3.messageBox("The enemy has been poisoned!")
		end
		tes3.player.data.OEA8[900] = 0
		return
	end
	tes3.player.data.OEA8[Weapon.id].HitCounter = nil

	Weapon.name = tes3.player.data.OEA8[Weapon.id].oldName
	if (tes3.player.data.OEA8[Weapon.id].enchantment ~= nil) then
		Weapon.enchantment = tes3.player.data.OEA8[Weapon.id].enchantment
	else
		Weapon.enchantment = nil
		WeaponData.charge = -1
	end
	tes3.player.data.OEA8[Weapon.id] = nil

	colorFile.ReplaceColor(Weapon, AmmoWeapon)
	if (tes3.player.data.OEA8[900] == nil) or (tes3.player.data.OEA8[900] == 0) then
		tes3.messageBox("The enemy has been poisoned!")
		tes3.messageBox("Your weapon has lost all of its poison.")
	end
	tes3.player.data.OEA8[900] = 0
end

return H