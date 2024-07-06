local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("weatherBlizzard", 312)
tes3.claimSpellEffectId("weatherSnow", 313)
tes3.claimSpellEffectId("weatherThunderstorm", 314)
tes3.claimSpellEffectId("weatherAsh", 315)
tes3.claimSpellEffectId("weatherBlight", 316)
tes3.claimSpellEffectId("weatherClear", 317)
tes3.claimSpellEffectId("weatherCloudy", 318)
tes3.claimSpellEffectId("weatherFoggy", 319)
tes3.claimSpellEffectId("weatherOvercast", 320)
tes3.claimSpellEffectId("weatherRain", 321)

local function getDescription(weather)
    return "Commune with the spirits of nature to change the weather to " .. weather .. "."
end

framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherBlizzard,
    name = "Weather: Blizzard",
    description = getDescription("a Blizzard"),
    baseCost = 1500,
    weather = tes3.weather.blizzard,
    icon = "RFD\\RFD_wth_blizz.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherSnow,
    name = "Weather: Snow",
    description = getDescription("Snow"),
    baseCost = 1500,
    weather = tes3.weather.snow,
    icon = "RFD\\RFD_wth_snow.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherThunderstorm,
    name = "Weather: Thunderstorm",
    description = getDescription("Thunderstorms"),
    baseCost = 1500,
    weather = tes3.weather.thunder,
    icon = "RFD\\RFD_wth_storm.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherAsh,
    name = "Weather: Ashstorm",
    description = getDescription("an Ash storm"),
    baseCost = 1600,
    weather = tes3.weather.ash,
    icon = "RFD\\RFD_wth_ash.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherBlight,
    name = "Weather: Blightstorm",
    description = getDescription("a Blight storm"),
    baseCost = 1700,
    weather = tes3.weather.blight,
    icon = "RFD\\RFD_wth_blight.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherClear,
    name = "Weather: Clear",
    description = getDescription("a clear sky"),
    baseCost = 1500,
    weather = tes3.weather.clear,
    icon = "RFD\\RFD_wth_clear.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherCloudy,
    name = "Weather: Cloudy",
    description = getDescription("a cloudy sky"),
    baseCost = 1500,
    weather = tes3.weather.cloudy,
    icon = "RFD\\RFD_wth_cloud.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherFoggy,
    name = "Weather: Foggy",
    description = getDescription("a foggy sky"),
    baseCost = 1500,
    weather = tes3.weather.foggy,
    icon = "RFD\\RFD_wth_fog.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherOvercast,
    name = "Weather: Overcast",
    description = getDescription("an overcast sky"),
    baseCost = 1500,
    weather = tes3.weather.overcast,
    icon = "RFD\\RFD_wth_over.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherRain,
    name = "Weather: Rain",
    description = getDescription("a moderate rain"),
    baseCost = 1500,
    weather = tes3.weather.rain,
    icon = "RFD\\RFD_wth_rain.dds"
})
