local interiorTransitions = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController
local intWeatherTimer

--------------------------------------------------------------------------------------

-- Main function controlling weather changes in interiors --
function interiorTransitions.progress()
	if WtC.nextWeather then return end

	local currentWeather = WtC.currentWeather.index
	local newWeather = nil
	debugLog("Weather before randomisation: " .. currentWeather)

	-- Use regional weather chances --
	local region = tes3.getRegion(true)
	local regionChances = region.weatherChances

	-- Get the new weather --
	for weather, chance in pairs(regionChances) do
		if (chance == 100) or (chance / 100 > math.random()) then
			newWeather = weather
			break
		end
	end

	if newWeather == currentWeather then
		interiorTransitions.progress()
		return
	end

	-- Switch to the new weather --
	WtC:switchTransition(newWeather)
	debugLog("Weather randomised. New weather: " .. WtC.nextWeather.index)
end


function interiorTransitions.onCellChanged(e)
	local cell = e.cell
	if not cell then return end
	if (cell.isOrBehavesAsExterior) then
		if intWeatherTimer then
			intWeatherTimer:pause()
			debugLog("Player in exterior. Pausing interior timer.")
		end
	-- Refresh the timer in interiors --
	else
		if intWeatherTimer then
			intWeatherTimer:pause()
			intWeatherTimer:cancel()
			intWeatherTimer = nil
		end

		intWeatherTimer = timer.start {
			duration = WtC.hoursBetweenWeatherChanges,
			callback = interiorTransitions.progress,
			type = timer.game,
			iterations = -1
		}

		debugLog("Player in interior. Resuming interior timer. Hours to weather change: " .. WtC.hoursBetweenWeatherChanges)
	end
end

--------------------------------------------------------------------------------------

return interiorTransitions