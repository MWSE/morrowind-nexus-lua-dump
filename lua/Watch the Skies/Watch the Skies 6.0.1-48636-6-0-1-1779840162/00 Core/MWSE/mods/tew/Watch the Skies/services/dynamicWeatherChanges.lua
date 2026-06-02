local dynamicWeatherChanges = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local defaultHoursBetweenWeatherChanges

function dynamicWeatherChanges.storeDefaults()
	if defaultHoursBetweenWeatherChanges then return end
	defaultHoursBetweenWeatherChanges = WtC.hoursBetweenWeatherChanges
	debugLog("Default hoursBetweenWeatherChanges stored: " .. defaultHoursBetweenWeatherChanges)
end

function dynamicWeatherChanges.restoreDefaults()
	if defaultHoursBetweenWeatherChanges then
		WtC.hoursBetweenWeatherChanges = defaultHoursBetweenWeatherChanges
		debugLog("hoursBetweenWeatherChanges restored to default: " .. defaultHoursBetweenWeatherChanges)
	end
end

function dynamicWeatherChanges.init()
	dynamicWeatherChanges.storeDefaults()
	dynamicWeatherChanges.randomise()
end

function dynamicWeatherChanges.randomise()
	local hours = math.random(3, 8)
	WtC.hoursBetweenWeatherChanges = hours
	debugLog("Current time between weather changes: " .. WtC.hoursBetweenWeatherChanges)
end

function dynamicWeatherChanges.startTimer()
	dynamicWeatherChanges.randomise()
	timer.start {
		duration = common.centralTimerDuration,
		callback = dynamicWeatherChanges.randomise,
		iterations = -1,
		type = timer.game,
	}
end

--------------------------------------------------------------------------------------

return dynamicWeatherChanges
