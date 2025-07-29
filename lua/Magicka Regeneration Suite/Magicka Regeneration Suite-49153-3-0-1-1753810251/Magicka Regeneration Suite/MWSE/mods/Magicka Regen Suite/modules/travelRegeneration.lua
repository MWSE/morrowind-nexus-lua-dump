local common = require("Magicka Regen Suite.common")

local timeBeforeTravel

-- Regenerate magicka for Player during traveling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from the last destination are to be unloaded.
-- Player's companions do get regeneration if the player has any.
---@param e calcTravelPriceEventData
local function travelMagicka(e)
	if not tes3.mobilePlayer.traveling then -- Get time before traveling
		timeBeforeTravel = tes3.getSimulationTimestamp()
	end

	if tes3.mobilePlayer.traveling then -- Travel finished
		local hoursPassed = tes3.getSimulationTimestamp() - timeBeforeTravel
		timeBeforeTravel = nil

		common.restoreIf(tes3.player, hoursPassed * 3600, true)

		for _, companion in ipairs(e.companions or {}) do
			common.restoreIf(companion.reference, hoursPassed * 3600, true)
		end
	end
end


event.register(tes3.event.calcTravelPrice, travelMagicka)
