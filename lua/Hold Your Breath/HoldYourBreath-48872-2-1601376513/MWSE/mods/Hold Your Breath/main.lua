local config = require("Hold Your Breath.config")
local prevBreath
local function calcBreath()
	local breath = (config.breathBase + (tes3.mobilePlayer.endurance.current * config.breathMult))
	if breath == prevBreath then return end
	prevBreath = breath
	tes3.findGMST(972).value = breath
	--tes3.messageBox("Breath %s", breath)
end
local function onLoaded()
	timer.start{type=timer.simulate, duration=1, iterations=-1, callback=calcBreath}
end
event.register("loaded", onLoaded)
local function registerModConfig()
	require("Hold Your Breath.mcm")
end
event.register("modConfigReady", registerModConfig)
