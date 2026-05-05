local common = require("Magicka Regen Suite.common")
local config = require("Magicka Regen Suite.config")
local regenType = require("Magicka Regen Suite.regenerationType")


local timeBeforeTravel

-- Regenerate magicka for Player during traveling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from the last destination are to be unloaded.
-- Player's companions do get regeneration if the player has any.
---@param e calcTravelPriceEventData
local function travelMagicka(e)
	if config.regenerationFormula == regenType.rest then return end

	if not tes3.mobilePlayer.traveling then -- Get time before traveling
		timeBeforeTravel = tes3.getSimulationTimestamp()
	end

	if tes3.mobilePlayer.traveling then -- Travel finished
		local hoursPassed = tes3.getSimulationTimestamp() - timeBeforeTravel
		timeBeforeTravel = nil

		common.attemptRestore(tes3.player, hoursPassed * 3600, true)

		for _, companion in ipairs(e.companions or {}) do
			common.attemptRestore(companion.reference, hoursPassed * 3600, true)
		end
	end
end


event.register(tes3.event.calcTravelPrice, travelMagicka)
