local dynamicWeatherChanges = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

function dynamicWeatherChanges.init()
	dynamicWeatherChanges.randomise()
end

function dynamicWeatherChanges.randomise()
	local hours = math.random(3, 10)
	WtC.hoursBetweenWeatherChanges = hours
	debugLog("Current time between weather changes: " .. WtC.hoursBetweenWeatherChanges)
end

function dynamicWeatherChanges.startTimer()
	timer.start{
		duration = common.centralTimerDuration,
		callback = dynamicWeatherChanges.randomise,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return dynamicWeatherChanges