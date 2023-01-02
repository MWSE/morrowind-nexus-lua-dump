local log = require("logging.logger").new({ name = "Ossuaries of the Ghostfence", logLevel = "INFO" })

local done

local function lightsOut()
	if tes3.player.cell.id ~= "Ghostfence, Western Catacombs" then
		return
	end
	if done then
		return
	end
	if tes3.getReference("GG_sc_invisibility_west").disabled then
		local equippedLight = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light })
		if equippedLight then
			log:debug("%s unequipped", equippedLight.object.id)
			tes3.player.mobile:unequip({ type = tes3.objectType.light })
		end
		done = true
	end
end
event.register("simulate", lightsOut)
