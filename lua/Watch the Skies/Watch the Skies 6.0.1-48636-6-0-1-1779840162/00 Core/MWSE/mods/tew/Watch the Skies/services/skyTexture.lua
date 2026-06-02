local skyTexture = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local config = require("tew.Watch the Skies.config")
local WtSdir = "Data Files\\Textures\\tew\\Watch the Skies"
local WtC = tes3.worldController.weatherController
local util = require("tew.Watch the Skies.util")
local variableRain = require("tew.Watch the Skies.services.variableRain")

--------------------------------------------------------------------------------------

local skyTextures = {}
for i = 1, 10 do
	skyTextures[i] = {}
end

local rainTextures = {
	["light"] = {},
	["medium"] = {},
	["heavy"] = {},
}

local defaultSkyTextures = {}
for i = 1, 10 do
	defaultSkyTextures[i] = ""
end

--------------------------------------------------------------------------------------

function skyTexture.storeDefaults()
	for i, w in ipairs(WtC.weathers) do
		if defaultSkyTextures[i] == "" then
			defaultSkyTextures[i] = w.cloudTexture
		end
	end
	debugLog("Default sky textures stored.")
end

function skyTexture.restoreDefaults()
	skyTexture.storeDefaults()
	for i, w in ipairs(WtC.weathers) do
		if defaultSkyTextures[i] then
			w.cloudTexture = defaultSkyTextures[i]
			debugLog("Restored default texture for weather: " .. w.name .. " - " .. defaultSkyTextures[i])
		end
	end
	util.updateController()
	debugLog("All sky textures restored to defaults.")
end

function skyTexture.addVanillaTextures()
	for index, texturePath in ipairs(defaultSkyTextures) do
		local list = skyTextures[index]
		for i = #list, 1, -1 do
			if list[i] == texturePath then
				table.remove(list, i)
			end
		end
		table.insert(list, texturePath)
		debugLog("Vanilla texture added: " .. texturePath)
	end
end

function skyTexture.removeVanillaTextures()
	for index, texturePath in ipairs(defaultSkyTextures) do
		local list = skyTextures[index]
		for i = #list, 1, -1 do
			if list[i] == texturePath then
				table.remove(list, i)
				debugLog("Vanilla texture removed: " .. texturePath)
			end
		end
	end
end

local function getNonRepeating(currentTexture, textureList)
	if #textureList == 1 then
		return textureList[1]
	end

	local texturePath

	repeat
		local i = math.random(#textureList)
		texturePath = textureList[i]
	until texturePath ~= currentTexture

	return texturePath
end

--------------------------------------------------------------------------------------

function skyTexture.randomise(immediate)
	local weatherNow = WtC and WtC.currentWeather
	if WtC.nextWeather then return end

	debugLog("Starting cloud texture randomisation.")

	local currentTexture = weatherNow.cloudTexture

	for index, weather in ipairs(WtC.weathers) do
		-- Skip the currently active weather if not immediate
		if weatherNow and weatherNow.index == index and not immediate then
			goto continue
		end

		local textureList = skyTextures[index]

		if config.variableRain then
			if index == 5 then
				-- Rain weather
				local rainType, glare = variableRain.getRainType(weather.maxParticles or 0)
				debugLog("Detected rain type: " .. rainType .. ", setting glare to: " .. tostring(glare))
				common.rainType = rainType -- For interop
				textureList = rainTextures[rainType]
				weather.glareView = glare
				variableRain.adjustColours(rainType)
			else
			end
		end

		-- Log which list and its size
		local listUsed = (index == 5) and ("rainTextures[" .. variableRain.getRainType(weather.maxParticles or 0) .. "]") or
			"skyTextures"
		debugLog(string.format(
			"Weather: %s | Using: %s | Texture count: %d",
			weather.name, listUsed, #textureList
		))

		-- Apply a random texture if available
		if #textureList > 0 then
			local texturePath = getNonRepeating(currentTexture, textureList)
			weather.cloudTexture = texturePath
			debugLog("Cloud texture path set: " .. weather.name .. " >> " .. weather.cloudTexture)
		end

		::continue::
	end

	if immediate then
		util.updateController()
	end
end

--------------------------------------------------------------------------------------

function skyTexture.init(params)
	skyTexture.storeDefaults()

	local immediate = params and params.immediate or false

	-- Helper: add valid texture files from a directory if it exists
	local function addTexturesFromDir(dirPath, list)
		local attr = lfs.attributes(dirPath, "mode")
		if attr ~= "directory" then
			debugLog("Directory not found or inaccessible: " .. tostring(dirPath))
			return
		end

		for file in lfs.dir(dirPath) do
			if file ~= "." and file ~= ".." then
				local lower = file:lower()
				if lower:endswith(".dds") or lower:endswith(".tga") then
					local fullPath = dirPath .. "\\" .. file
					table.insert(list, fullPath)
					debugLog("File added: " .. fullPath)
				end
			end
		end
	end

	-- Populate texture tables if empty
	if table.empty(skyTextures, true) then
		for name, index in pairs(tes3.weather) do
			local weatherPath = WtSdir .. "\\" .. name
			local skyList = skyTextures[index + 1]
			local lowerName = name:lower()

			if lowerName == "rain" then
				-- Add rain/common textures
				local commonDir = weatherPath .. "\\common"
				addTexturesFromDir(commonDir, skyList)

				-- Add variable rain textures (rain/light, rain/medium, rain/heavy)

				for rainType, rainList in pairs(rainTextures) do
					local rainDir = weatherPath .. "\\" .. rainType
					addTexturesFromDir(rainDir, rainList)
				end
			else
				-- Normal weather textures
				addTexturesFromDir(weatherPath, skyList)
			end
		end
	end

	-- Handle vanilla textures according to config
	if config.useVanillaSkyTextures then
		skyTexture.addVanillaTextures()
	else
		skyTexture.removeVanillaTextures()
	end

	skyTexture.randomise(immediate)
end

function skyTexture.startTimer()
	-- skyTexture.randomise() -- auto switch bug?
	timer.start {
		duration = common.centralTimerDuration,
		callback = skyTexture.randomise,
		iterations = -1,
		type = timer.game,
	}
end

--------------------------------------------------------------------------------------

return skyTexture
