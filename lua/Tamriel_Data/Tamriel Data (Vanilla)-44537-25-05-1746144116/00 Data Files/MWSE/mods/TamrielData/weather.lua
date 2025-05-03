local this = {}

local common = require("tamrielData.common")
local config = require("tamrielData.config")

-- Default weather settings; set using findGMST instead?
local defaultSnowFog = { landFogDayDepth = 1, landFogNightDepth = 1.2 }
local defaultSnowFogMGE
local defaultSnowWind = 0
local defaultSnowWindMGE
local defaultSnowColors = {
	ambientSunriseColor = tes3vector3.new(0.36078432202339,0.32941177487373,0.32941177487373),
	ambientDayColor = tes3vector3.new(0.3647058904171,0.37647062540054,0.41176474094391),
	ambientSunsetColor = tes3vector3.new(0.27450981736183,0.3098039329052,0.34117648005486),
	ambientNightColor = tes3vector3.new(0.19215688109398,0.22745099663734,0.26666668057442),

	skySunriseColor = tes3vector3.new(0.41568630933762,0.35686275362968,0.35686275362968),
	skyDayColor = tes3vector3.new(0.60000002384186,0.61960786581039,0.65098041296005),
	skySunsetColor = tes3vector3.new(0.37647062540054,0.45098042488098,0.52549022436142),
	skyNightColor = tes3vector3.new(0.070588238537312,0.090196080505848,0.10980392992496),

	fogSunriseColor = tes3vector3.new(0.41568630933762,0.35686275362968,0.35686275362968),
	fogDayColor = tes3vector3.new(0.60000002384186,0.61960786581039,0.65098041296005),
	fogSunsetColor = tes3vector3.new(0.37647062540054,0.45098042488098,0.52549022436142),
	fogNightColor = tes3vector3.new(0.12156863510609,0.13725490868092,0.15294118225574),

	sunSunriseColor = tes3vector3.new(0.55294120311737,0.42745101451874,0.42745101451874),
	sunDayColor = tes3vector3.new(0.63921570777893,0.66274511814117,0.71764707565308),
	sunSunsetColor = tes3vector3.new(0.39607846736908,0.47450983524323,0.55294120311737),
	sunNightColor = tes3vector3.new(0.21568629145622,0.258823543787,0.30196079611778),

	sundiscSunsetColor = tes3vector3.new(0.50196081399918,0.50196081399918,0.50196081399918)
}
local defaultSnowSky = { cloudsMaxPercent = 1, cloudsSpeed = 1.5, cloudTexture = "Textures\\tx_bm_sky_snow.tga" }
local defaultSnowParticles = { maxParticles = 1500, particleEntranceSpeed = 6, particleHeightMax = 700, particleHeightMin = 400, particleRadius = 800,
									newParticle = "bm_snow_01.nif", precipitationFallSpeed = -575, isSnow = true, snowFallSpeedScale = 0.1 }	-- Of the numerical values, only maxParticles seems to be relevant for the snow controller
local defaultSnowSound = ""
if mge.enabled() then
	defaultSnowFogMGE = mgeWeatherConfig.getDistantFog(tes3.weather.snow)
	defaultSnowWindMGE = mgeWeatherConfig.getWind(tes3.weather.snow).speed
end
local defaultSnow = { fog = defaultSnowFog, fogMGE = defaultSnowFogMGE, wind = defaultSnowWind, windMGE = defaultSnowWindMGE,
						colors = defaultSnowColors, sky = defaultSnowSky, particles = defaultSnowParticles, sound = defaultSnowSound }

local defaultAshFog = { landFogDayDepth = 1.1, landFogNightDepth = 1.2 }
local defaultAshFogMGE
local defaultAshWind = 0.8	-- For other (storm) weathers to have characters hold their arm in front of their face to block the wind, the wind value must be at least 0.8 as it is here for the vanilla ashstorm weather
local defaultAshWindMGE
local defaultAshColors = {
	ambientSunriseColor = tes3vector3.new(0.21176472306252,0.16470588743687,0.14509804546833),
	ambientDayColor = tes3vector3.new(0.29411765933037,0.19215688109398,0.16078431904316),
	ambientSunsetColor = tes3vector3.new(0.18823531270027,0.15294118225574,0.13725490868092),
	ambientNightColor = tes3vector3.new(0.14117647707462,0.16470588743687,0.19215688109398),
	
	skySunriseColor = tes3vector3.new(0.35686275362968,0.21960785984993,0.20000001788139),
	skyDayColor = tes3vector3.new(0.48627454042435,0.28627452254295,0.22745099663734),
	skySunsetColor = tes3vector3.new(0.41568630933762,0.21568629145622,0.15686275064945),
	skyNightColor = tes3vector3.new(0.078431375324726,0.082352943718433,0.086274512112141),
	
	fogSunriseColor = tes3vector3.new(0.35686275362968,0.21960785984993,0.20000001788139),
	fogDayColor = tes3vector3.new(0.48627454042435,0.28627452254295,0.22745099663734),
	fogSunsetColor = tes3vector3.new(0.41568630933762,0.21568629145622,0.15686275064945),
	fogNightColor = tes3vector3.new(0.078431375324726,0.082352943718433,0.086274512112141),
	
	sunSunriseColor = tes3vector3.new(0.72156864404678,0.35686275362968,0.27843138575554),
	sunDayColor = tes3vector3.new(0.89411771297455,0.54509806632996,0.44705885648727),
	sunSunsetColor = tes3vector3.new(0.72549021244049,0.33725491166115,0.22352942824364),
	sunNightColor = tes3vector3.new(0.21176472306252,0.258823543787,0.29019609093666),
	
	sundiscSunsetColor = tes3vector3.new(0.50196081399918,0.50196081399918,0.50196081399918)
}
local defaultAshSky = { cloudsMaxPercent = 1, cloudsSpeed = 7, cloudTexture = "Textures\\tx_sky_ashstorm.tga" }
local defaultAshClouds = { stormRootIndex = 1, mesh = "ashcloud.nif" }
local defaultAshSound = "Ashstorm"
if mge.enabled() then
	defaultAshFogMGE = mgeWeatherConfig.getDistantFog(tes3.weather.ash)
	defaultAshWindMGE = mgeWeatherConfig.getWind(tes3.weather.ash).speed
end
local defaultAsh = { fog = defaultAshFog, fogMGE = defaultAshFogMGE, wind = defaultAshWind, windMGE = defaultAshWindMGE,
						colors = defaultAshColors, sky = defaultAshSky, clouds = defaultAshClouds, sound = defaultAshSound }

local defaultBlizzardFog = { landFogDayDepth = 2.8, landFogNightDepth = 3 }
local defaultBlizzardFogMGE
local defaultBlizzardWind = 0.9
local defaultBlizzardWindMGE
local defaultBlizzardColors = {
	ambientSunriseColor = tes3vector3.new(0.32941177487373,0.34509804844856,0.36078432202339),
	ambientDayColor = tes3vector3.new(0.3647058904171,0.37647062540054,0.41176474094391),
	ambientSunsetColor = tes3vector3.new(0.32549020648003,0.30196079611778,0.29411765933037),
	ambientNightColor = tes3vector3.new(0.20784315466881,0.24313727021217,0.27450981736183),

	fogSunriseColor = tes3vector3.new(0.35686275362968,0.38823533058167,0.41568630933762),
	fogDayColor = tes3vector3.new(0.47450983524323,0.52156865596771,0.5686274766922),
	fogSunsetColor = tes3vector3.new(0.42352944612503,0.45098042488098,0.47450983524323),
	fogNightColor = tes3vector3.new(0.082352943718433,0.094117656350136,0.10980392992496),
	
	skySunriseColor = tes3vector3.new(0.35686275362968,0.38823533058167,0.41568630933762),
	skyDayColor = tes3vector3.new(0.47450983524323,0.52156865596771,0.5686274766922),
	skySunsetColor = tes3vector3.new(0.42352944612503,0.45098042488098,0.47450983524323),
	skyNightColor = tes3vector3.new(0.10588236153126,0.11372549831867,0.12156863510609),
	
	sunSunriseColor = tes3vector3.new(0.44705885648727,0.50196081399918,0.57254904508591),
	sunDayColor = tes3vector3.new(0.63921570777893,0.66274511814117,0.71764707565308),
	sunSunsetColor = tes3vector3.new(0.41568630933762,0.44705885648727,0.53333336114883),
	sunNightColor = tes3vector3.new(0.22352942824364,0.258823543787,0.29019609093666),
	
	sundiscSunsetColor = tes3vector3.new(0.50196081399918,0.50196081399918,0.50196081399918),
}
local defaultBlizzardSky = { cloudsMaxPercent = 1, cloudsSpeed = 7.5, cloudTexture = "Textures\\tx_bm_sky_blizzard.tga" }
local defaultBlizzardSound = "BM Blizzard"
if mge.enabled() then
	defaultBlizzardFogMGE = mgeWeatherConfig.getDistantFog(tes3.weather.blizzard)
	defaultBlizzardWindMGE = mgeWeatherConfig.getWind(tes3.weather.blizzard).speed
end

local defaultStormOrigin = tes3vector2.new(25000, 70000)

-- Custom Weather Settings
local othrelethSporefallFog = { landFogDayDepth = 1.1, landFogNightDepth = 1.3 }
local othrelethSporefallFogMGE = { distance = .16, offset = 10 }
local othrelethSporefallWind = 0.4			-- Higher than MGE's wind so that it can blow the spores around without making grass look like a thunderstorm is present
local othrelethSporefallWindMGE = 0.1
local othrelethSporefallColors = {
	ambientSunriseColor = tes3vector3.new(0.27294388413429,0.20933870971203,0.11750064045191),
	ambientDayColor = tes3vector3.new(0.33694046735764,0.30483055114746,0.21058352291584),
	ambientSunsetColor = tes3vector3.new(0.24061198532581,0.19484589993954,0.10204297304153),
	ambientNightColor = tes3vector3.new(0.14370784163475,0.1271006911993,0.067252717912197),

	skySunriseColor = tes3vector3.new(0.81255954504013,0.62385624647141,0.36805811524391),
	skyDayColor = tes3vector3.new(0.65067648887634,0.64906567335129,0.35700508952141),
	skySunsetColor = tes3vector3.new(0.72385734319687,0.56822526454926,0.3271227478981),
	skyNightColor = tes3vector3.new(0.10392910987139,0.086770243942738,0.03624227270484),

	fogSunriseColor = tes3vector3.new(0.75838434696198,0.63241970539093,0.31937465071678),
	fogDayColor = tes3vector3.new(0.74217289686203,0.64066410064697,0.32276219129562),
	fogSunsetColor = tes3vector3.new(0.64377784729004,0.4962210059166,0.22626619040966),
	fogNightColor = tes3vector3.new(0.11429940909147,0.088800229132175,0.032750491052866),

	sunSunriseColor = tes3vector3.new(0.69411766529083,0.63529413938522,0.53725492954254),
	sunDayColor = tes3vector3.new(0.4966846704483,0.51434928178787,0.42396208643913),
	sunSunsetColor = tes3vector3.new(0.56242853403091,0.50337612628937,0.42783063650131),
	sunNightColor = tes3vector3.new(0.14676041901112,0.17843659222126,0.21117457747459),

	sundiscSunsetColor = tes3vector3.new(0.87450987100601,0.87450987100601,0.87450987100601)
}
local othrelethSporefallSky = { cloudsMaxPercent = 1, cloudsSpeed = 1, cloudTexture = "Textures\\tx_sky_foggy.dds" }
local othrelethSporefallParticles = { maxParticles = 1000, particleEntranceSpeed = 6, particleHeightMax = 700, particleHeightMin = 400, particleRadius = 3600,
											newParticle = "td\\td_weather_ow_spore.nif", precipitationFallSpeed = -575, isSnow = true, snowFallSpeedScale = 0.075 }
local othrelethSporefallSound = ""
local othrelethSporefall = { fog = othrelethSporefallFog, fogMGE = othrelethSporefallFogMGE, wind = othrelethSporefallWind, windMGE = othrelethSporefallWindMGE,
								colors = othrelethSporefallColors, sky = othrelethSporefallSky, particles = othrelethSporefallParticles, sound = othrelethSporefallSound }

local shipalSandstormFog = { landFogDayDepth = 1.2, landFogNightDepth = 1.2 }
local shipalSandstormFogMGE = { distance = .14, offset = 85 }
local shipalSandstormWind = 0.8
local shipalSandstormWindMGE = 0.4
local shipalSandstormColors = {
	ambientSunriseColor = tes3vector3.new(0.21530009806156,0.14550277590752,0.11051461100578),
	ambientDayColor = tes3vector3.new(0.29153820872307,0.19568987190723,0.12980020046234),
	ambientSunsetColor = tes3vector3.new(0.15863129496574,0.13118956983089,0.10972380638123),
	ambientNightColor = tes3vector3.new(0.1754819303751,0.14343112707138,0.12481042742729),
	
	skySunriseColor = tes3vector3.new(0.37871468067169,0.21166057884693,0.14759901165962),
	skyDayColor = tes3vector3.new(0.50329428911209,0.24587486684322,0.064963988959789),
	skySunsetColor = tes3vector3.new(0.38184657692909,0.22245298326015,0.11584800481796),
	skyNightColor = tes3vector3.new(0.10468325763941,0.076288469135761,0.056556653231382),
	
	fogSunriseColor = tes3vector3.new(0.37871468067169,0.21166057884693,0.14759904146194),
	fogDayColor = tes3vector3.new(0.47953671216965,0.25145751237869,0.098600476980209),
	fogSunsetColor = tes3vector3.new(0.38184657692909,0.22245298326015,0.11584800481796),
	fogNightColor = tes3vector3.new(0.10807107388973,0.075333394110203,0.051505777984858),
	
	sunSunriseColor = tes3vector3.new(0.6495099067688,0.31365808844566,0.20876568555832),
	sunDayColor = tes3vector3.new(0.83064413070679,0.50800108909607,0.33096680045128),
	sunSunsetColor = tes3vector3.new(0.66355347633362,0.34237751364708,0.1470145881176),
	sunNightColor = tes3vector3.new(0.25221019983292,0.20912343263626,0.18309138715267),
	
	sundiscSunsetColor = tes3vector3.new(0.50196081399918,0.50196081399918,0.50196081399918)
}
local shipalSandstormSky = { cloudsMaxPercent = 1, cloudsSpeed = 7, cloudTexture = "Textures\\tx_sky_ashstorm.tga" }
local shipalSandstormClouds = { stormRootIndex = 1, mesh = "td\\td_sh_sand_cloud.nif" }
local shipalSandstormSound = "T_SndEnv_SandStorm"
local shipalSandstorm = { fog = shipalSandstormFog, fogMGE = shipalSandstormFogMGE, wind = shipalSandstormWind, windMGE = shipalSandstormWindMGE,
						colors = shipalSandstormColors, sky = shipalSandstormSky, clouds = shipalSandstormClouds, sound = shipalSandstormSound }

local tropicalStormFog = { landFogDayDepth = 1.7, landFogNightDepth = 1.9 }
local tropicalStormFogMGE = { distance = .13, offset = 100 }
local tropicalStormWind = 2
local tropicalStormWindMGE = 0.6
local tropicalStormColors = {
	ambientSunriseColor = tes3vector3.new(0.19833926856518,0.19834020733833,0.19834034144878),
	ambientDayColor = tes3vector3.new(0.26627615094185,0.266282081604,0.26628294587135),
	ambientSunsetColor = tes3vector3.new(0.21176472306252,0.21176472306252,0.21176472306252),
	ambientNightColor = tes3vector3.new(0.1051777228713,0.11253328621387,0.12334341555834),
	
	skySunriseColor = tes3vector3.new(0.3021180331707,0.30640208721161,0.31970238685608),
	skyDayColor = tes3vector3.new(0.43943184614182,0.46728873252869,0.51149290800095),
	skySunsetColor = tes3vector3.new(0.3021180331707,0.30640208721161,0.31970238685608),
	skyNightColor = tes3vector3.new(0.087008163332939,0.090532593429089,0.097644492983818),
	
	fogSunriseColor = tes3vector3.new(0.2162476927042,0.23177614808083,0.27332815527916),
	fogDayColor = tes3vector3.new(0.32280033826828,0.34984081983566,0.39182490110397),
	fogSunsetColor = tes3vector3.new(0.20606455206871,0.21729429066181,0.24860291182995),
	fogNightColor = tes3vector3.new(0.07522377371788,0.07911616563797,0.086906954646111),
	
	sunSunriseColor = tes3vector3.new(0.10468751192093,0.13780814409256,0.21113251149654),
	sunDayColor = tes3vector3.new(0.19020310044289,0.21166664361954,0.24804016947746),
	sunSunsetColor = tes3vector3.new(0.10052275657654,0.14052282273769,0.19936349987984),
	sunNightColor = tes3vector3.new(0.038123168051243,0.063679918646812,0.11018896102905),
	
	sundiscSunsetColor = tes3vector3.new(0.50196081399918,0.50196081399918,0.50196081399918),
}
local tropicalStormSky = { cloudsMaxPercent = 1, cloudsSpeed = 10, cloudTexture = "Textures\\tx_sky_ashstorm.tga" }
local tropicalStormStormClouds = { stormRootIndex = 1, mesh = "td\\td_tropical_cloud.nif" }
local tropicalStormSound = "T_SndEnv_TropicalStorm"
local tropicalStorm = { fog = tropicalStormFog, fogMGE = tropicalStormFogMGE, wind = tropicalStormWind, windMGE = tropicalStormWindMGE,
						colors = tropicalStormColors, sky = tropicalStormSky, clouds = tropicalStormStormClouds, sound = tropicalStormSound }

local rainParticles = { "Raindrop" }
local snowParticles = { "Snowflake", "BM_Snow_01", "tr_weather_ow_spore" }

-- Custom Region Weather Chances
-- region id, ash chance, blight chance, blizzard chance, clear chance, cloudy chance, foggy chance, overcast chance, rain chance, snow chance, thunder chance
local region_weather_chances = {
	{ "Othreleth Woods Region", 0, 0, 0, 25, 25, 6, 10, 15, 14, 5 },	-- Ash chance is set to 0 to prevent interference with sandstorms in SH
	{ "Shipal-Shin Region", 8, 0, 0, 54, 18, 10, 5, 3, 0, 2 },
	{ "Abecean Sea Region", 3, 0, 0, 72, 10, 5, 0, 0, 0, 10 },
	{ "Stirk Isle Region", 3, 0, 0, 72, 10, 5, 0, 0, 0, 10 },
	{ "Gilded Hills Region", 3, 0, 0, 55, 20, 0, 4, 10, 0, 8 },
	{ "Gold Coast Region", 3, 0, 0, 67, 15, 0, 0, 5, 0, 10 },
}

-- region id, origin x-coordinate, origin y-coordinate, y-cell top bound, y-cell bottom bound
local region_storm_origins = {
	-- Armun ashstorms
	{ "Armun Ashlands Region", -132386.328, -200454.234 },	-- Should eventually be set to the large volcano west of Armun once it is made
	{ "Velothi Mountains Region", -132386.328, -200454.234 },	-- Should be changed to Kartur Dale's ID in WBM
	{ "Othreleth Woods Region", -132386.328, -200454.234, -29, -38 },	-- These extra regions are necessary for the same reason as the weather transition condition; leaving AA during an ashstorm without them would immediately set the origin to be Red Mountain
	{ "Aanthirin Region", -132386.328, -200454.234 },
	{ "Roth Roryn Region", -132386.328, -200454.234 },

	-- Shipal-Shin dust storms; perhaps these should actually be tied to a function that effectively plots a circle a curve?
	{ "Shipal-Shin Region", -18932, -448768 },
	{ "Othreleth Woods Region", -18932, -448768, -39, -50 },
	{ "Thirr Valley Region", -18932, -448768, -39, -50 },

	-- Abecean tropical storms
	{ "Abecean Sea Region", -1347424.000, -490135.000 },
	{ "Colovian Highlands Region", -1347424.000, -490135.000 },
	{ "Dasek Marsh Region", -1347424.000, -490135.000 },
	{ "Gilded Hills Region", -1347424.000, -490135.000 },
	{ "Gold Coast Region", -1347424.000, -490135.000 },
	{ "Kvetchi Pass Region", -1347424.000, -490135.000 },
	{ "Stirk Isle Region", -1347424.000, -490135.000 },
}

---@param weather tes3weather
---@param vanillaFog table
---@param mgeFog table
local function changeWeatherFog(weather, vanillaFog, mgeFog)
	weather.landFogDayDepth = vanillaFog.landFogDayDepth
	weather.landFogNightDepth = vanillaFog.landFogNightDepth

	if mge.enabled() then
		mge.weather.setDistantFog({ weather = weather.index, distance = mgeFog.distance, offset = mgeFog.offset })
	end
end

---@param weather tes3weather
---@param windVanilla number
---@param windMGE number
local function changeWeatherWind(weather, windVanilla, windMGE)
	weather.windSpeed = windVanilla

	if mge.enabled() then
		mge.weather.setWind({ weather = weather.index, speed = windMGE })
	end
end

---@param weather tes3weather
---@param colorTable table
local function changeWeatherColors(weather, colorTable)
	weather.ambientSunriseColor.r = colorTable.ambientSunriseColor.r
	weather.ambientSunriseColor.g = colorTable.ambientSunriseColor.g
	weather.ambientSunriseColor.b = colorTable.ambientSunriseColor.b
	weather.ambientDayColor.r = colorTable.ambientDayColor.r
	weather.ambientDayColor.g = colorTable.ambientDayColor.g
	weather.ambientDayColor.b = colorTable.ambientDayColor.b
	weather.ambientSunsetColor.r = colorTable.ambientSunsetColor.r
	weather.ambientSunsetColor.g = colorTable.ambientSunsetColor.g
	weather.ambientSunsetColor.b = colorTable.ambientSunsetColor.b
	weather.ambientNightColor.r = colorTable.ambientNightColor.r
	weather.ambientNightColor.g = colorTable.ambientNightColor.g
	weather.ambientNightColor.b = colorTable.ambientNightColor.b

	weather.skySunriseColor.r = colorTable.skySunriseColor.r
	weather.skySunriseColor.g = colorTable.skySunriseColor.g
	weather.skySunriseColor.b = colorTable.skySunriseColor.b
	weather.skyDayColor.r = colorTable.skyDayColor.r
	weather.skyDayColor.g = colorTable.skyDayColor.g
	weather.skyDayColor.b = colorTable.skyDayColor.b
	weather.skySunsetColor.r = colorTable.skySunsetColor.r
	weather.skySunsetColor.g = colorTable.skySunsetColor.g
	weather.skySunsetColor.b = colorTable.skySunsetColor.b
	weather.skyNightColor.r = colorTable.skyNightColor.r
	weather.skyNightColor.g = colorTable.skyNightColor.g
	weather.skyNightColor.b = colorTable.skyNightColor.b

	weather.fogSunriseColor.r = colorTable.fogSunriseColor.r
	weather.fogSunriseColor.g = colorTable.fogSunriseColor.g
	weather.fogSunriseColor.b = colorTable.fogSunriseColor.b
	weather.fogDayColor.r = colorTable.fogDayColor.r
	weather.fogDayColor.g = colorTable.fogDayColor.g
	weather.fogDayColor.b = colorTable.fogDayColor.b
	weather.fogSunsetColor.r = colorTable.fogSunsetColor.r
	weather.fogSunsetColor.g = colorTable.fogSunsetColor.g
	weather.fogSunsetColor.b = colorTable.fogSunsetColor.b
	weather.fogNightColor.r = colorTable.fogNightColor.r
	weather.fogNightColor.g = colorTable.fogNightColor.g
	weather.fogNightColor.b = colorTable.fogNightColor.b

	weather.sunSunriseColor.r = colorTable.sunSunriseColor.r
	weather.sunSunriseColor.g = colorTable.sunSunriseColor.g
	weather.sunSunriseColor.b = colorTable.sunSunriseColor.b
	weather.sunDayColor.r = colorTable.sunDayColor.r
	weather.sunDayColor.g = colorTable.sunDayColor.g
	weather.sunDayColor.b = colorTable.sunDayColor.b
	weather.sunSunsetColor.r = colorTable.sunSunsetColor.r
	weather.sunSunsetColor.g = colorTable.sunSunsetColor.g
	weather.sunSunsetColor.b = colorTable.sunSunsetColor.b
	weather.sunNightColor.r = colorTable.sunNightColor.r
	weather.sunNightColor.g = colorTable.sunNightColor.g
	weather.sunNightColor.b = colorTable.sunNightColor.b

	weather.sundiscSunsetColor.r = colorTable.sundiscSunsetColor.r
	weather.sundiscSunsetColor.g = colorTable.sundiscSunsetColor.g
	weather.sundiscSunsetColor.b = colorTable.sundiscSunsetColor.b
end

---@param weather tes3weather
---@param cloudSettings table
local function changeWeatherSky(weather, cloudSettings)
	weather.cloudsMaxPercent = cloudSettings.cloudsMaxPercent
	weather.cloudsSpeed = cloudSettings.cloudsSpeed
	weather.cloudTexture = cloudSettings.cloudTexture
end

---@param weather tes3weather
---@param newSoundID string
local function changeWeatherSound(weather, newSoundID)
	if weather.ambientLoopSoundId ~= newSoundID then
		if weather.ambientLoopSound then
			weather.ambientLoopSound:stop()
		end
		
		weather.ambientLoopSoundId = newSoundID
	end
end

--- @param particle tes3weatherControllerParticle
--- @param newParticleMesh niAVObject
--- @param isSnow boolean
local function swapNode(particle, newParticleMesh, isSnow)
	if isSnow then								-- Prevent changing rain particles to snow particles
		for _,v in pairs(rainParticles) do
			if v == particle.object.name then
				return
			end
		end
	else
		for _,v in pairs(snowParticles) do
			if v == particle.object.name then
				return
			end
		end
	end

    local old = particle.object
    particle.rainRoot:detachChild(old)

    local new = newParticleMesh:clone()
    particle.rainRoot:attachChild(new)
    new.appCulled = old.appCulled
	
    particle.object = new
end

--- @param meshPath string
local function loadParticle(meshPath)
	local particle = tes3.loadMesh(meshPath)

	-- Strip all properties except for texturing for uniform lighting
	for _,child in pairs(particle.children) do
		child:detachProperty(ni.propertyType.alpha)
		child:detachProperty(ni.propertyType.dither)
		child:detachProperty(ni.propertyType.fog)
		child:detachProperty(ni.propertyType.material)
		child:detachProperty(ni.propertyType.shade)
		child:detachProperty(ni.propertyType.specular)
		child:detachProperty(ni.propertyType.stencil)
		child:detachProperty(ni.propertyType.vertexColor)
		child:detachProperty(ni.propertyType.wireframe)
		child:detachProperty(ni.propertyType.zBuffer)
	end

	return particle
end

---@param weather tes3weatherRain
---@param particleSettings table
local function changeWeatherPrecipitation(weather, particleSettings)
	weather.maxParticles = particleSettings.maxParticles
	weather.particleEntranceSpeed = particleSettings.particleEntranceSpeed
	weather.particleHeightMax = particleSettings.particleHeightMax
	weather.particleHeightMin = particleSettings.particleHeightMin
	weather.particleRadius = particleSettings.particleRadius

	local weatherController = weather.controller
	weatherController.precipitationFallSpeed = particleSettings.precipitationFallSpeed
	if particleSettings.isSnow then
		weatherController.snowFallSpeedScale = particleSettings.snowFallSpeedScale
	end

	local newParticle = loadParticle(particleSettings.newParticle)

	if (not weatherController.particlesActive[1] or weatherController.particlesActive[1].object.name ~= newParticle.name) and
		(not weatherController.particlesInactive[1] or weatherController.particlesInactive[1].object.name ~= newParticle.name) then	-- Done for optimization, prevents iterating through all particles on every cell change that this function is called
		for _,particle in pairs(weatherController.particlesActive) do
			swapNode(particle, newParticle, particleSettings.isSnow)
		end
	
		for _,particle in pairs(weatherController.particlesInactive) do
			swapNode(particle, newParticle, particleSettings.isSnow)
		end
	end
end

---@param weather tes3weather
---@param stormClouds table
local function changeWeatherStormClouds(weather, stormClouds)
	local clouds = tes3.loadMesh(stormClouds.mesh, false)	-- If useCache is true, then running this function twice with the same stormClouds will result in sceneStormRoot having nil children attached to it

	weather.controller.sceneStormRoot.children[stormClouds.stormRootIndex]:detachAllChildren()
	
	for _,child in pairs(clouds.children) do
		weather.controller.sceneStormRoot.children[stormClouds.stormRootIndex]:attachChild(child, true)
	end

	weather.controller.sceneStormRoot.children[stormClouds.stormRootIndex]:updateEffects()	-- Required for the particle lighting to work correctly
end

-- Checks whether the player is loading into a cell with a suitable custom weather active so that particle settings are actually applied; this change is visible to the player, but is necessary and unavoidable until MWSE has proper support for custom weathers
---@param customWeather tes3weather
---@param isNext boolean
local function fixParticlesOnLoad(customWeather, isNext)
	local controller = customWeather.controller

	if not isNext then
		controller:switchImmediate(tes3.weather.clear)
		controller:updateVisuals()
		controller:switchImmediate(customWeather.index)
		controller:updateVisuals()
	else
        local ts = controller.transitionScalar
		controller:switchImmediate(controller.currentWeather.index)
		controller:updateVisuals()
        controller:switchTransition(customWeather.index)
        controller.transitionScalar = ts
	end
end

---@param weather tes3weatherRain
---@param replacement table
local function changeWeather(weather, replacement)
	changeWeatherFog(weather, replacement.fog, replacement.fogMGE)
	changeWeatherWind(weather, replacement.wind, replacement.windMGE)
	changeWeatherColors(weather, replacement.colors)
	changeWeatherSky(weather, replacement.sky)
	changeWeatherSound(weather, replacement.sound)
	if replacement.particles then
		changeWeatherPrecipitation(weather, replacement.particles)
	elseif replacement.clouds then
		changeWeatherStormClouds(weather, replacement.clouds)
	end
end

---@param e weatherChangedImmediateEventData
function this.manageWeathers(e)
	if e.cell and not e.cell.isOrBehavesAsExterior then
		return	-- Don't bother with anything below if the player is entering a normal interior cell
	end

	local weather
	local nextWeather
	
	if not e.to then
		weather = tes3.getCurrentWeather()
		if weather.controller.nextWeather then
			nextWeather = weather.controller.nextWeather
		end
	else
		weather = e.to
	end

	local extCell = common.getExteriorCell(tes3.player.cell)	-- Should be more reliable than getRegion

	if extCell.region then
		if weather.name == "Snow" or (nextWeather and nextWeather.name == "Snow") then
			if extCell.region.id == "Othreleth Woods Region" or extCell.region.id == "Thirr Valley Region" or extCell.region.id == "Aanthirin Region" or extCell.region.id == "Shipal-Shin Region" then	   -- Regions that either are OW or border it without (currently) bordering a region with normal snow (like VM)
				if weather.name == "Snow" then	-- This setup is kind of stupid, but I just didn't want for the region checks above to be present in two different places
					changeWeather(weather, othrelethSporefall)
					if not e.to and not e.previousCell then
						fixParticlesOnLoad(weather, false)
					end
				else	-- Exists to change the next weather if the player loads a game where the weather should be changing to the spore storm
					changeWeather(nextWeather, othrelethSporefall)
					if not e.to and not e.previousCell then
						fixParticlesOnLoad(nextWeather, true)
					end
				end
			elseif extCell.region.id == "Armun Ashlands Region" and extCell.gridX > -11 then	-- This is a very temporary solution for weather transitions that will work until the WBM release; MWSE will need actual support for custom weathers in order for transitions to work at that point
				changeWeather(weather, othrelethSporefall)
			else
				if weather.name == "Snow" then
					changeWeather(weather, defaultSnow)
				else
					changeWeather(nextWeather, defaultSnow)
				end
			end
		elseif weather.name == "Ashstorm" or (nextWeather and nextWeather.name == "Ashstorm") then
			if extCell.region.id == "Shipal-Shin Region" then
				if weather.name == "Ashstorm" then
					changeWeather(weather, shipalSandstorm)
				else
					changeWeather(nextWeather, shipalSandstorm)
				end
			elseif (extCell.region.id == "Othreleth Woods Region" or extCell.region.id == "Thirr Valley Region") and extCell.gridY < -39 then	-- Another temporary solution for weather transitions
				changeWeather(weather, shipalSandstorm)
			elseif extCell.region.id == "Abecean Sea Region" or extCell.region.id == "Stirk Isle Region" or extCell.region.id == "Gold Coast Region" or extCell.region.id == "Gilded Hills Region" or extCell.region.id == "Dasek Marsh Region" or extCell.region.id == "Kvetchi Pass Region" or extCell.region.id == "Colovian Highlands Region" then
				if weather.name == "Ashstorm" then
					changeWeather(weather, tropicalStorm)
				else
					changeWeather(nextWeather, tropicalStorm)
				end
			else
				if weather.name == "Ashstorm" then
					changeWeather(weather, defaultAsh)
				else
					changeWeather(nextWeather, defaultAsh)
				end
			end
		end
	end
end

function this.changeRegionWeatherChances()
	for _,v in pairs(region_weather_chances) do
		local regionID, weatherChanceAsh, weatherChanceBlight, weatherChanceBlizzard, weatherChanceClear, weatherChanceCloudy, weatherChanceFoggy, weatherChanceOvercast, weatherChanceRain, weatherChanceSnow, weatherChanceThunder = unpack(v)
		local region = tes3.findRegion(regionID)
		
		if region then
			region.weatherChanceAsh = weatherChanceAsh
			region.weatherChanceBlight = weatherChanceBlight
			region.weatherChanceBlizzard = weatherChanceBlizzard
			region.weatherChanceClear = weatherChanceClear
			region.weatherChanceCloudy = weatherChanceCloudy
			region.weatherChanceFoggy = weatherChanceFoggy
			region.weatherChanceOvercast = weatherChanceOvercast
			region.weatherChanceRain = weatherChanceRain
			region.weatherChanceSnow = weatherChanceSnow
			region.weatherChanceThunder = weatherChanceThunder
		end
	end
end

-- Ideally the following function could just be run on cell changes, but trying to access the weather field of the weather controller seems to be unreliable
---@param e weatherChangedImmediateEventData
function this.changeStormOrigin(e)
	local weather
	if not e.to then
		weather = tes3.getCurrentWeather()
	else
		weather = e.to
	end

	if weather and weather.index == tes3.weather.ash or weather.index == tes3.weather.blight then
		for _,v in pairs(region_storm_origins) do
			local regionID, xCoord, yCoord, yUpperLimit, yLowerLimit = unpack(v, 1, 5)

			local extCell = common.getExteriorCell(tes3.player.cell)
			if extCell and extCell.region and extCell.region.id == regionID and (not yUpperLimit or (extCell.gridY <= yUpperLimit and extCell.gridY >= yLowerLimit)) then	-- I would like to just use getRegion, but *noooooo*, I have to account for regions between ones with different ashstorm origins like OW
				weather.stormOrigin = tes3vector2.new(xCoord, yCoord)
				return
			end
		end

		weather.stormOrigin = defaultStormOrigin	-- This kind of solution shouldn't be necessary, but MWSE doesn't allow for weathers to be nicely reset to their default settings
	end
end

---@param e soundObjectPlayEventData
function this.silenceCreatures(e)
	if e.sound.id == "T_SndCrea_SeagullScream1" or e.sound.id == "T_SndCrea_SeagullScream2" or e.sound.id == "T_SndCrea_SeagullFlap" then	-- Could also account for T_SndCrea_MastreeveMoan, T_SndCrea_MastreeveRoar, T_SndCrea_MastreeveScream?
		if tes3.getCurrentWeather().index == tes3.weather.ash then
			return false	-- Seeing the birds fly in a tropical storm is bad enough, having to hear them as well is just insulting
		end
	end
end

return this