local data = require("WeatherChances.data")
local defaults = data.defaults

return mwse.loadConfig("WeatherChances", {
    weatherChances = defaults,
})