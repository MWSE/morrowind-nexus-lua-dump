local cloudSpeed = {}
local config = require("tew.Watch the Skies.config")

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local cloudSpeedData = {
	[1] = {
		50, 55, 60, 80, 98, 100, 110, 120, 130,
		150, 190, 200, 220,
		320, 340
	},
	[2] = {
		60, 72, 85, 90, 100, 120, 140,
		150, 170, 180, 200,
		320, 345,
	},
	[3] = {
		50, 60, 70, 100, 120, 140,
		150, 190, 240, 250, 270
	},
	[4] = {
		20, 30, 50, 60, 80, 100, 120, 140,
		150, 160, 200, 250
	},
	[5] = {
		100, 120,
		150, 190, 200, 250, 300,
		320, 375, 390, 400
	},
	[6] = {
		160, 180, 200, 230, 260, 300,
		360, 380, 450, 500
	},
	[7] = {
		600, 700, 800, 900, 1000, 1200, 1500
	},
	[8] = {
		750, 800, 900, 1000, 1250, 2360, 1470, 1600, 1800
	},
	[9] = {
		80, 100, 110, 125, 145,
		185, 196, 200, 270
	},
	[10] = {
		600, 760, 850, 920, 1100, 1250
	}
}

--------------------------------------------------------------------------------------


function cloudSpeed.init()
	cloudSpeed.randomise()
end

function cloudSpeed.randomise()
	local currentWeatherIndex = WtC.currentWeather.index
	for i, w in pairs(WtC.weathers) do
		if i == currentWeatherIndex then goto continue end
		local cloudSpeedDataForWeather = cloudSpeedData[i]
		local randomIndex = math.random(1, #cloudSpeedDataForWeather)
		w.cloudsSpeed = cloudSpeedDataForWeather[randomIndex] / config.cloudSpeedMode
		::continue::
	end
	debugLog("Cloud speed randomised.")
end

function cloudSpeed.startTimer()
	timer.start{
		duration = common.centralTimerDuration,
		callback = cloudSpeed.randomise,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return cloudSpeed