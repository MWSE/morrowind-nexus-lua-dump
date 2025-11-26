local core = require('openmw.core')

-- Map spell IDs → weather records
local weatherRecords = {
    detd_Clear_spell        = core.weather.records.Clear,
    detd_Cloudy_spell       = core.weather.records.Cloudy,
    detd_Foggy_spell        = core.weather.records.Foggy,
    detd_Overcast_spell     = core.weather.records.Overcast,
    detd_Rain_spell         = core.weather.records.Rain,
    detd_Thunder_spell      = core.weather.records.Thunderstorm,
    detd_Ashstorm_spell     = core.weather.records.Ashstorm,
    detd_Blight_spell       = core.weather.records.Blight,
    detd_Snow_spell         = core.weather.records.Snow,
    detd_Blizzard_spell     = core.weather.records.Blizzard,
}

-- Map weather *names* (as sent by player) → weather records
local weatherByName = {
    Clear        = core.weather.records.Clear,
    Cloudy       = core.weather.records.Cloudy,
    Foggy        = core.weather.records.Foggy,
    Overcast     = core.weather.records.Overcast,
    Rain         = core.weather.records.Rain,
    Thunderstorm = core.weather.records.Thunderstorm,
    Ashstorm     = core.weather.records.Ashstorm,
    Blight       = core.weather.records.Blight,
    Snow         = core.weather.records.Snow,
    Blizzard     = core.weather.records.Blizzard,
}

local lastRegion = nil
local lastWeather = nil

local function detd_UpdateWeather(data)
    if not data or not data.regionId or not data.weather then
        return
    end

    local regionId = data.regionId
    local weatherName = data.weather

    local weatherRecord = weatherByName[weatherName]
    if not weatherRecord then
      --  print(string.format('[WeatherSpell] Unknown weather name: %s', tostring(weatherName)))
        return
    end

    if lastRegion == regionId and lastWeather == weatherName then
        return
    end

    core.weather.changeWeather(regionId, weatherRecord)
    lastRegion = regionId
    lastWeather = weatherName

   -- print(string.format('[WeatherSpell] Weather in "%s" set to "%s"', regionId, weatherRecord))
end

return {
    eventHandlers = {
        detd_UpdateWeather = detd_UpdateWeather,
    }
}
