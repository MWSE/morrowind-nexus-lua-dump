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
    return "Обратитесь к духам природы, что бы изменить погоду на " .. weather .. "."
end

framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherBlizzard,
    name = "Погода: Метель",
    description = getDescription("метель"),
    baseCost = 1500,
    weather = tes3.weather.blizzard,
    icon = "RFD\\RFD_wth_blizz.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherSnow,
    name = "Погода: Снег",
    description = getDescription("снег"),
    baseCost = 1500,
    weather = tes3.weather.snow,
    icon = "RFD\\RFD_wth_snow.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherThunderstorm,
    name = "Погода: Гроза",
    description = getDescription("грозу"),
    baseCost = 1500,
    weather = tes3.weather.thunder,
    icon = "RFD\\RFD_wth_storm.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherAsh,
    name = "Погода: Пепельная буря",
    description = getDescription("пепельную бурю"),
    baseCost = 1600,
    weather = tes3.weather.ash,
    icon = "RFD\\RFD_wth_ash.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherBlight,
    name = "Погода: Моровая буря",
    description = getDescription("моровую бурю"),
    baseCost = 1700,
    weather = tes3.weather.blight,
    icon = "RFD\\RFD_wth_blight.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherClear,
    name = "Погода: Ясно",
    description = getDescription("ясную"),
    baseCost = 1500,
    weather = tes3.weather.clear,
    icon = "RFD\\RFD_wth_clear.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherCloudy,
    name = "Погода: Облачо",
    description = getDescription("облачную"),
    baseCost = 1500,
    weather = tes3.weather.cloudy,
    icon = "RFD\\RFD_wth_cloud.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherFoggy,
    name = "Погода: Туманно",
    description = getDescription("туманную"),
    baseCost = 1500,
    weather = tes3.weather.foggy,
    icon = "RFD\\RFD_wth_fog.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherOvercast,
    name = "Погода: Пасмурно",
    description = getDescription("пасмурную"),
    baseCost = 1500,
    weather = tes3.weather.overcast,
    icon = "RFD\\RFD_wth_over.dds"
})
framework.effects.conjuration.createBasicWeatherEffect({
    id = tes3.effect.weatherRain,
    name = "Погода: Дождь",
    description = getDescription("дождливую"),
    baseCost = 1500,
    weather = tes3.weather.rain,
    icon = "RFD\\RFD_wth_rain.dds"
})
