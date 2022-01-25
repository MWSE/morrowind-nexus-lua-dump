-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20220108) then
	mwse.log("[Magicka Regeneration Suite] Build date of %s does not meet minimum build date of 20220108.", mwse.buildDate)
	return
end

dofile("Magicka Regen Suite.modules.regeneration")
dofile("Magicka Regen Suite.modules.waitRegeneration")
dofile("Magicka Regen Suite.modules.travelRegeneration")

event.register("modConfigReady", function()
	dofile("Magicka Regen Suite.mcm")
end)
