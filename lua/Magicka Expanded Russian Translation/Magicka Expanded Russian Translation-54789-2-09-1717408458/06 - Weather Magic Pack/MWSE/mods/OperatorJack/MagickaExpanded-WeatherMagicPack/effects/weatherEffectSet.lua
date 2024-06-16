local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

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
    return "Этот эффект меняет погоду на ".. weather .."."
end
local function addWeatherEffects()
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherBlizzard,
		name = "Погода: Метель",
		description = getDescription("Метель"),
		baseCost = 1500,
		weather = tes3.weather.blizzard,
		icon = "RFD\\RFD_wth_blizz.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherSnow,
		name = "Погода: Снег",
		description = getDescription("Снег"),
		baseCost = 1500,
		weather = tes3.weather.snow,
		icon = "RFD\\RFD_wth_snow.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherThunderstorm,
		name = "Погода: Гроза",
		description = getDescription("Гроза"),
		baseCost = 1500,
		weather = tes3.weather.thunder,
		icon = "RFD\\RFD_wth_storm.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherAsh,
		name = "Погода: Пепельная буря",
		description = getDescription("Пепельная буря"),
		baseCost = 1600,
		weather = tes3.weather.ash,
		icon = "RFD\\RFD_wth_ash.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherBlight,
		name = "Погода: Моровая буря",
		description = getDescription("Моровая буря"),
		baseCost = 1700,
		weather = tes3.weather.blight,
		icon = "RFD\\RFD_wth_blight.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherClear,
		name = "Погода: Ясно",
		description = getDescription("Ясно"),
		baseCost = 1500,
		weather = tes3.weather.clear,
		icon = "RFD\\RFD_wth_clear.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherCloudy,
		name = "Погода: Облачо",
		description = getDescription("Облачо"),
		baseCost = 1500,
		weather = tes3.weather.cloudy,
		icon = "RFD\\RFD_wth_cloud.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherFoggy,
		name = "Погода: Туманно",
		description = getDescription("Туманно"),
		baseCost = 1500,
		weather = tes3.weather.foggy,
		icon = "RFD\\RFD_wth_fog.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherOvercast,
		name = "Погода: Пасмурно",
		description = getDescription("Пасмурно"),
		baseCost = 1500,
		weather = tes3.weather.overcast,
		icon = "RFD\\RFD_wth_over.dds"
	})
	framework.effects.alteration.createBasicWeatherEffect({
		id = tes3.effect.weatherRain,
		name = "Погода: Дождь",
		description = getDescription("Дождь"),
		baseCost = 1500,
		weather = tes3.weather.rain,
		icon = "RFD\\RFD_wth_rain.dds"
	})
end

event.register("magicEffectsResolved", addWeatherEffects)