local common = require("Magicka Regen Suite.common")
local config = require("Magicka Regen Suite.config")
local regenType = require("Magicka Regen Suite.regenerationType")

local log = mwse.Logger.new()


-- Regenerate magicka for Player, NPCs and Creatures in active cells
-- based on time waited.
---@param e calcRestInterruptEventData
local function waitMagicka(e)
	if config.regenerationFormula == regenType.rest and e.resting then return end

	local hoursPassed = tes3.mobilePlayer.restHoursRemaining
	local restInterrupted = e.count > 0 and e.hour > 1
	if restInterrupted then
		hoursPassed = hoursPassed - (e.hour - 1)
	end
	local secondsPassed = hoursPassed * 3600
	log:debug("Restoring, time passed: %s", secondsPassed)

	common.processActors(secondsPassed, true)
	common.attemptRestore(tes3.player, secondsPassed, true)
end


event.register(tes3.event.calcRestInterrupt, waitMagicka)
