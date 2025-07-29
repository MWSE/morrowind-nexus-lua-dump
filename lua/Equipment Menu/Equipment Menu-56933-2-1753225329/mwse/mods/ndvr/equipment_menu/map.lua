local config = require("ndvr.equipment_menu.config.config")

local function createSlotMap(config)
	local map = {
		armorOverrideSlotMap = {
			[tes3.armorSlot.leftGauntlet] = {
				{ type = tes3.objectType.clothing, id = tes3.clothingSlot.leftGlove },
				{ type = tes3.objectType.armor, id = tes3.armorSlot.leftBracer },
			},
			[tes3.armorSlot.rightGauntlet] = {
				{ type = tes3.objectType.clothing, id = tes3.clothingSlot.rightGlove },
				{ type = tes3.objectType.armor, id = tes3.armorSlot.rightBracer },
			},
			[tes3.armorSlot.leftBracer] = {
				{ type = tes3.objectType.armor, id = tes3.armorSlot.leftGauntlet }
			},
			[tes3.armorSlot.rightBracer] = {
				{ type = tes3.objectType.armor, id = tes3.armorSlot.rightGauntlet }
			},
			[tes3.armorSlot.boots] = {
				{ type = tes3.objectType.clothing, id = tes3.clothingSlot.shoes }
			},
		},

		clothingOverrideSlotMap = {
			[tes3.clothingSlot.leftGlove] = {
				{ type = tes3.objectType.armor, id = tes3.armorSlot.leftGauntlet }
			},
			[tes3.clothingSlot.rightGlove] = {
				{ type = tes3.objectType.armor, id = tes3.armorSlot.rightGauntlet }
			},
			[tes3.clothingSlot.shoes] = {
				{ type = tes3.objectType.armor, id = tes3.armorSlot.boots }
			},
		}
	}

	if not tes3.hasCodePatchFeature(tes3.codePatchFeature.allowGlovesWithBracers) then
		table.insert(map.armorOverrideSlotMap[tes3.armorSlot.leftBracer], { type = tes3.objectType.clothing, id = tes3.clothingSlot.leftGlove })
		table.insert(map.armorOverrideSlotMap[tes3.armorSlot.rightBracer], { type = tes3.objectType.clothing, id = tes3.clothingSlot.rightGlove })

		table.insert(map.clothingOverrideSlotMap[tes3.clothingSlot.leftGlove], { type = tes3.objectType.armor, id = tes3.armorSlot.leftBracer })
		table.insert(map.clothingOverrideSlotMap[tes3.clothingSlot.rightGlove], { type = tes3.objectType.armor, id = tes3.armorSlot.rightBracer })
	end

	return map
end

return createSlotMap