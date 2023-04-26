local particleAmount = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local particleAmountData = {
	[4] = { 1400, 1500, 1600, 1650, 1700, 1750, 1800, 1850, 1900, 1950, 2000, 2050, 2100, 2150, 2200, 2250, 2300, 2350, 2400, 2500, 2600, 2700, 2800, 3000 },
	[5] = { 1600, 1650, 1700, 1750, 1800, 1850, 1900, 1950, 2000, 2050, 2100, 2150, 2200, 2300, 2400, 2500, 2600, 2750, 2800, 3000, 3500, 4000, 4500, 5000 },
	[8] = { 1500, 1700, 2100, 2300, 2800, 3000, 3300, 3500 }
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
	for weather, values in pairs(particleAmountData) do
		if (currentWeatherIndex ~= weather) then
			WtC.weathers[weather + 1].maxParticles = table.choice(values)
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