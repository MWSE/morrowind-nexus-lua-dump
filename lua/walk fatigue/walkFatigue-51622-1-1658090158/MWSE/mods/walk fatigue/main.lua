local config = require("walk fatigue.config")

local function walkCheck()
	if tes3.mobilePlayer.isWalking then
		local staminaModifier
		if tes3.mobilePlayer.fatigue.current < config.staminaLoss then
			staminaModifier = (tes3.mobilePlayer.fatigue.current * (-1))
		else
			staminaModifier = (config.staminaLoss * (-1))
		end
		tes3.modStatistic{
			reference = tes3.mobilePlayer,
			name = "fatigue",
			current = staminaModifier
		}
	end
end

local function onLoaded()
	timer.start({iterations = -1, duration = 1, callback = walkCheck, type = timer.simulate })
end
event.register("loaded", onLoaded)

local function registerModConfig()
	require("walk fatigue.mcm")
end
event.register("modConfigReady", registerModConfig)