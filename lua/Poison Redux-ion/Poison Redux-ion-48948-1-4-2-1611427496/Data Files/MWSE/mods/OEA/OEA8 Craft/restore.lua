local H = {}

local colorFile = require("OEA.OEA8 Craft.color")
local config = require("OEA.OEA8 Craft.config")

function H.Restoration(Weapon, AmmoWeapon)
	local Append = " (Poisoned)"
	local Length

	if (tes3.player.data.OEA8 == nil) or (config.Startup == false) then
		colorFile.ReplaceColor(Weapon, AmmoWeapon)
		return
	end

	tes3.player.data.OEA8[23] = 1

	local tes3iterator = tes3.player.object.inventory
	for _, tes3iteratorNode in pairs(tes3iterator) do
		if (tes3.player.data.OEA8[tes3iteratorNode.object.id] ~= nil) then
			if (tes3iteratorNode.object.objectType == tes3.objectType.weapon) or (tes3iteratorNode.object.objectType == tes3.objectType.ammunition) then
				Length = string.len(tes3iteratorNode.object.name)
				if (string.sub(tes3iteratorNode.object.name, Length - 10, Length) ~= Append) then
					if (Length > 20) then
						tes3iteratorNode.object.name = string.sub(tes3iteratorNode.object.name, 1, 20)
					end
					tes3iteratorNode.object.name = string.format("%s%s", tes3iteratorNode.object.name, Append)
				end
				tes3iteratorNode.object.enchantment = tes3.getObject(tes3.player.data.OEA8[tes3iteratorNode.object.id].newEnchantment)
			end
		else
			Length = string.len(tes3iteratorNode.object.name)
			if (string.sub(tes3iteratorNode.object.name, Length - 10, Length) == Append) then
				tes3iteratorNode.object.name = string.sub(tes3iteratorNode.object.name, 1, Length - 11)
			end
		end
	end
	colorFile.ReplaceColor(Weapon, AmmoWeapon)
end

return H