local skyTexture = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local config = require("tew.Watch the Skies.config")
local WtSdir = "Data Files\\Textures\\tew\\Watch the Skies"
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local weathers = {}
weathers.vanillaWeathers = {
	[0] = "tx_sky_clear.dds",
	[1] = "tx_sky_cloudy.dds",
	[2] = "tx_sky_foggy.dds",
	[3] = "tx_sky_overcast.dds",
	[4] = "tx_sky_rainy.dds",
	[5] = "tx_sky_thunder.dds",
	[6] = "tx_sky_ashstorm.dds",
	[7] = "tx_sky_blight.dds",
	[8] = "tx_bm_sky_snow.dds",
	[9] = "tx_bm_sky_blizzard.dds"
}

weathers.customWeathers = {}
for i = 0, 9 do
	weathers.customWeathers[i] = {}
end

--------------------------------------------------------------------------------------

function skyTexture.randomise()
	local weatherNow
	if WtC then
		weatherNow = WtC.currentWeather
	end
	if (WtC.nextWeather) then return end

	debugLog("Starting cloud texture randomisation.")
	for index, weather in ipairs(WtC.weathers) do
		if (weatherNow) and (weatherNow.index == index) then goto continue end
		local textureList = weathers.customWeathers[index-1]
		math.randomseed(os.time())
		local texturePath = textureList[math.random(#textureList)]
		weather.cloudTexture = texturePath
		debugLog("Cloud texture path set: " .. weather.name .. " >> " .. weather.cloudTexture)
		::continue::
	end
end

function skyTexture.init()
	-- Populate data tables with cloud textures --
	for name, index in pairs(tes3.weather) do
		local weatherPath = WtSdir .. "\\" .. name
		for sky in lfs.dir(weatherPath) do
			if sky ~= ".." and sky ~= "." then
				local texturePath = weatherPath .. "\\" .. sky
				if string.endswith(sky, ".dds") or string.endswith(sky, ".tga") then
					table.insert(weathers.customWeathers[index], texturePath)
					debugLog("File added: " .. texturePath)
				end
			end
		end
	end

	-- Also pull vanilla textures if needed --
	if config.useVanillaSkyTextures then
		for index, sky in pairs(weathers.vanillaWeathers) do
			local texturePath = "Data Files\\Textures\\" .. sky
			if lfs.fileexists(texturePath) then
				table.insert(weathers.customWeathers[index], texturePath)
				debugLog("File added: " .. texturePath)
			else
				mwse.log("[Watch the Skies: ERROR] Vanilla sky texture not found: " .. texturePath)
			end
		end
	end

	-- Initially shuffle the cloud textures --
	skyTexture.randomise()
end

function skyTexture.startTimer()
	timer.start{
		duration = common.centralTimerDuration,
		callback = skyTexture.randomise,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return skyTexture