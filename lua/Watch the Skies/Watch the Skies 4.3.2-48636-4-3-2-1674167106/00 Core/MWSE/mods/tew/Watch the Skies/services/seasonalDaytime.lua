local seasonalDaytime = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------


function seasonalDaytime.init()
	seasonalDaytime.calculate()
end

-- The following function uses slightly amended sveng's calculations from their old ESP mod: nexusmods.com/morrowind/mods/44375 --
-- The function changes sunrise/sunset hours based on world latitude --
function seasonalDaytime.calculate()
	local month = tes3.worldController.month.value
	local day = tes3.worldController.day.value

	--- Constants --
	local southY = -400000 -- Max "south pole" value - default -400000 (approximately Old Morrowind-Argonia border) --
	local northY = 225000 -- Max "north pole" value - 225000 is slightly north of Castle Karstaag
	local minDaytime = 4.0 -- Minimum daytime duration
	local solsticeSunrise = 6.0 -- Sunrise hours at 0 world position for solstice
	local solsticeSunset = 18.0 -- Sunset hour at 0 world position for solstice
	local durSunrise = 2.0 -- Sunrise duration
	local durSunset = 2.0 -- Sunset duration

	-- Local variables --
	local adjustedSunrise, adjustedSunset, l1, f1, f2, f3 -- Adjusted values and coefficients

	-- Player position --
	local playerY = tes3.player.position.y -- Player y (latitude) position

	-- sveng's smart equation to determine applicable values --
	l1 = ((((month * 3042) / 100) + day) + 9)
	if (l1 > 365) then
		l1 = (l1 - 365)
	end
	l1 = (l1 - 182)
	if (l1 < 0) then
		l1 = (0 - l1)
	end

	f1 = ((l1 - 91.0) / 91.0)
	if (f1 < -1.0) then
		f1 = -1.0
	elseif (f1 > 1.0) then
		f1 = 1.0
	end

	f2 = ((playerY - southY) / (northY - southY))
	if (f2 < 0.0) then
		f2 = 0.0
	elseif (f2 > 1.0) then
		f2 = 1.0
	end

	f3 = ((solsticeSunset - solsticeSunrise)) -- -0.0 [???]
	if (minDaytime > f3) then
		minDaytime = f3
	end

	f3 = (0.0 - (f1 * f2))
	f1 = ((solsticeSunset - solsticeSunrise) - minDaytime)
	f1 = (((f1 * f3) + solsticeSunset) - solsticeSunrise)
	if (f1 < minDaytime) then
		f1 = minDaytime
	end

	f2 = (24.0 - minDaytime)
	if (f1 > f2) then
		f1 = f2
	end

	f2 = (solsticeSunset - solsticeSunrise)
	adjustedSunrise = (solsticeSunrise - ((f1 - f2) / 2))
	adjustedSunset = (solsticeSunset + ((f1 - f2) / 2))
	adjustedSunset = (adjustedSunset - durSunset)

	-- Adjust values only if we need to, i.e. if different from current values --
	if WtC.sunriseHour == math.ceil(adjustedSunrise) and
		WtC.sunsetHour == math.ceil(adjustedSunset) and
		WtC.sunriseDuration == math.ceil(durSunrise) and
		WtC.sunsetDuration == math.ceil(durSunset) then
		debugLog("No change in daytime hours. Returning.")
	else
		debugLog("Previous values: " .. WtC.sunriseHour .. " " .. WtC.sunriseDuration .. " " .. WtC.sunsetHour .. " " .. WtC.sunsetDuration)
		WtC.sunriseHour = math.ceil(adjustedSunrise)
		WtC.sunsetHour = math.ceil(adjustedSunset)
		WtC.sunriseDuration = math.ceil(durSunrise)
		WtC.sunsetDuration = math.ceil(durSunset)
		debugLog("Current values: " .. WtC.sunriseHour .. " " .. WtC.sunriseDuration .. " " .. WtC.sunsetHour .. " " .. WtC.sunsetDuration)
	end
end

function seasonalDaytime.startTimer()
	timer.start{
		duration = common.centralTimerDuration,
		callback = seasonalDaytime.calculate,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return seasonalDaytime