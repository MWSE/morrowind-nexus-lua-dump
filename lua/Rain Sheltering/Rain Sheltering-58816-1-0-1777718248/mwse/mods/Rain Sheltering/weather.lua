local M = {}

local rainWeathers = {
	[tes3.weather.rain] = true,
	[tes3.weather.thunder] = true,
}

M.getWeatherIsRaining = function()
	local manager = tes3.worldController and tes3.worldController.weatherController
	if not manager then
		return false
	end
	local current = manager.currentWeather
	if not current then
		return false
	end
	return rainWeathers[current.index] == true
end

return M