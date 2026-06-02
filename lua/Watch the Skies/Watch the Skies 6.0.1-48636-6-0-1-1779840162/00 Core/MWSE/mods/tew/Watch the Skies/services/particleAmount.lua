local particleAmount = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local allowedIndexes = { 5, 6, 9 }

local particleAmountData = {
	[5] = {
		500,
		800,
		1000,
		1200,

		1400,
		1600,
		1800,
		2000,

		2200,
		2400,
		2600,

		2800,
		3000,
		3200,
	},
	[6] = { 1600, 1650, 1700, 1750, 1800, 1850, 1900, 1950, 2000, 2050, 2100, 2150, 2200, 2300, 2400, 2500, 2600, 2750, 2800, 3000, 3500, 4000, 4500, 5000 },
	[9] = { 1500, 1700, 2100, 2300, 2800, 3000, 3300, 3500 },
}

local defaultValues = {}

--------------------------------------------------------------------------------------

function particleAmount.storeDefaults()
	if not table.empty(defaultValues) then return end
	for index, weather in ipairs(WtC.weathers) do
		if table.contains(allowedIndexes, index) then
			defaultValues[index] = {
				maxParticles = weather.maxParticles,
				particleRadius = weather.particleRadius,
			}
		end
	end
	debugLog("Default particle values stored.")
end

function particleAmount.restoreDefaults()
	for index, values in pairs(defaultValues) do
		if WtC.weathers[index] then
			WtC.weathers[index].maxParticles = values.maxParticles
			WtC.weathers[index].particleRadius = values.particleRadius
		end
	end

	debugLog("Particle values restored to defaults.")

	-- AURA interop
	event.trigger("WtS:maxParticlesChanged")
end

function particleAmount.init()
	particleAmount.storeDefaults()
	-- Make sure we have a baseline to start with --
	-- Compatible with MCP particle occlusion feature --
	WtC.weathers[5].particleRadius = 1500
	WtC.weathers[6].particleRadius = 1700
	WtC.weathers[9].particleRadius = 2000
	particleAmount.randomise()
end

function particleAmount.randomise()
	local currentWeatherIndex = WtC.currentWeather.index
	if WtC.nextWeather then return end

	for weather, values in pairs(particleAmountData) do
		if (currentWeatherIndex + 1 ~= weather) then
			WtC.weathers[weather].maxParticles = table.choice(values)
		end
	end

	debugLog("Particles amount randomised.")
	debugLog("Rain particles: " .. WtC.weathers[5].maxParticles)
	debugLog("Thunderstorm particles: " .. WtC.weathers[6].maxParticles)
	debugLog("Snow particles: " .. WtC.weathers[9].maxParticles)

	-- AURA interop
	event.trigger("WtS:maxParticlesChanged")
end

function particleAmount.startTimer()
	particleAmount.randomise()
	timer.start {
		duration = common.centralTimerDuration,
		callback = particleAmount.randomise,
		iterations = -1,
		type = timer.game,
	}
end

--------------------------------------------------------------------------------------

return particleAmount
