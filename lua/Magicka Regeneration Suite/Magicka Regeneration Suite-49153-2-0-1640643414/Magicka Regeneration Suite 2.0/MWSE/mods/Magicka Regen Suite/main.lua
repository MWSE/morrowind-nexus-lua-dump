local common = include("Magicka Regen Suite.common")
dofile("Magicka Regen Suite.modules.regeneration")
dofile("Magicka Regen Suite.modules.waitRegeneration")
dofile("Magicka Regen Suite.modules.travelRegeneration")

event.register("modConfigReady", function()
	require("Magicka Regen Suite.mcm")
end)
event.register("initialized", function()
	-- Disable vanilla magicka restoration on resting since this mod has its own calculation
	tes3.findGMST(tes3.gmst.fRestMagicMult).value = 0
end)
