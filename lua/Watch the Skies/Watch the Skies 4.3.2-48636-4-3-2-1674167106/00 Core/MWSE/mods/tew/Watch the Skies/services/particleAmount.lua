local particleAmount = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local particleAmountData = {
	[4] = { 1500, 1600, 1800, 1950, 2000, 2200, 2500, 2600, 2700, 2800, 2900, 3000 },
	[5] = { 1700, 1600, 1800, 1950, 2000, 2200, 2500, 2600, 2750, 2800, 3000, 3500, 4000, 4500, 5000 },
	[8] = { 2000, 2200, 2500, 2600, 2800, 3000, 3200, 3400, 3600 }
}

--------------------------------------------------------------------------------------

function particleAmount.init()
	-- Make sure we have a baseline to start with --
	-- Compatible with MCP particle occlusion feature --
	WtC.weathers[5].particleRadius = 1500
	WtC.weathers[6].particleRadius = 1700
	WtC.weathers[9].particleRadius = 2000
end

function particleAmount.randomise()
	local currentWeatherIndex = WtC.currentWeather.index

	-- Match the weather index with lua array index --
	-- Don't want to change currentWeather here --
	for weather, values in ipairs(particleAmountData) do
		if (currentWeatherIndex + 1 ~= weather) then
			WtC.weathers[currentWeatherIndex + 1].maxParticles = table.choice(values)
		end
	end

	debugLog("Particles amount randomised.")
	debugLog("Rain particles: " .. WtC.weathers[5].maxParticles)
	debugLog("Thunderstorm particles: " .. WtC.weathers[6].maxParticles)
	debugLog("Snow particles: " .. WtC.weathers[9].maxParticles)

	event.trigger("WtS:maxParticlesChanged")
end

function particleAmount.startTimer()
	timer.start{
		duration = common.centralTimerDuration,
		callback = particleAmount.randomise,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return particleAmount