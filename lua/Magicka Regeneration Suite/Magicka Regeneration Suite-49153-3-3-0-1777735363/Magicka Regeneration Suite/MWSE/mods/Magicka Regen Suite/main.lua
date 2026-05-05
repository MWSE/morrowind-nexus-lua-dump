local config = require("Magicka Regen Suite.config")
local gmst = require("Magicka Regen Suite.modules.gmst")

local log = mwse.Logger.new({
	name = "Magicka Regen Suite",
	level = config.logLevel
})

dofile("Magicka Regen Suite.modules.regeneration")
dofile("Magicka Regen Suite.modules.waitRegeneration")
dofile("Magicka Regen Suite.modules.travelRegeneration")
dofile("Magicka Regen Suite.mcm")

event.register(tes3.event.initialized, function()
	gmst.updateGMSTs()

	local stuntedEffect = tes3.getMagicEffect(tes3.effect.stuntedMagicka)
	stuntedEffect.description = "Prevents the target from regenerating Magicka for the duration of the effect."
end, { priority = -30 })
