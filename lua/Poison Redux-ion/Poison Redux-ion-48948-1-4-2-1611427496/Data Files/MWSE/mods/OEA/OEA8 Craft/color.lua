local H = {}

function H.ReplaceColor(Weapon, AmmoWeapon)
	local OldColor

	if (tes3.player == nil) then
		return
	end

	if (Weapon == nil) and (AmmoWeapon == nil) then
		return
	end

	OldColor = 0

	if (Weapon ~= nil) then
		local Length = string.len(Weapon.name)
		if (string.sub(Weapon.name, Length - 10, Length) == " (Poisoned)") then
			OldColor = 1
		end	
	end
	if (AmmoWeapon ~= nil) then
		local Length2 = string.len(AmmoWeapon.name)
		if (string.sub(AmmoWeapon.name, Length2 - 10, Length2) == " (Poisoned)") then
			if (Weapon == nil) then
				OldColor = 1
			end
		end
	end

	local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	if (menu ~= nil) then
		local child = menu:findChild(tes3ui.registerID("MenuMulti_enchantment_icon"))
		if (child ~= nil) then
			if (OldColor == nil) or (OldColor == 0) then
				if (Weapon ~= nil) and (Weapon.enchantment ~= nil) then
					child.visible = true
					child.color = {1, 1, 1, 1}
				else
					child.visible = false
				end
			elseif (OldColor == 1) then
				child.visible = true
				child.color = tes3ui.getPalette("fatigue_color")
			end
		end
	end
end

return H