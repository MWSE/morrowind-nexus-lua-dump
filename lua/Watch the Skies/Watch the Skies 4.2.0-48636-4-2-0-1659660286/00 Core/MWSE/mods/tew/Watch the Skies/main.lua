local weathers = require("tew\\Watch the Skies\\weathers")
local config = require("tew\\Watch the Skies\\config")
local seasonalChances = require("tew\\Watch the Skies\\seasonalChances")
local debugLogOn = config.debugLogOn
local WtSdir = "Data Files\\Textures\\tew\\Watch the Skies\\"
local modversion = require("tew\\Watch the Skies\\version")
local version = modversion.version
local WtC, intWeatherTimer, monthLast, regionLast
local tewLib = require("tew\\tewLib\\tewLib")
local isOpenPlaza = tewLib.isOpenPlaza

local function debugLog(message)
	if debugLogOn then
		mwse.log("[Watch the Skies " .. version .. "] " .. string.format("%s", message))
	end
end

-- Mod scope variable so we can change rain colours without scenegraph iteration --
local newParticleMesh

local particlesPath = "Data Files\\Meshes\\tew\\Watch the Skies\\particles"
local particles = {
	["rain"] = {},
	["snow"] = {}
}
local weatherChecklist = {
	["Rain"] = "rain",
	["Thunderstorm"] = "rain",
	["Snow"] = "snow"
}

-- Define regions affected by the Blight --
local vvRegions = { "Bitter Coast Region", "Azura's Coast Region", "Molag Mar Region", "Ashlands Region", "West Gash Region", "Ascadian Isles Region", "Grazelands Region", "Sheogorad" }

-- Check if the region passed is the Vvardenfel region--
local function checkVv(region)
	for _, v in ipairs(vvRegions) do
		if region == v then
			return true
		end
	end
end

-- Define particle and clouds values for randomisation --
-- Hard-coded values ensure better variety than range --
local particleAmount = {
	-- ["rain"] = { 300, 360, 400, 450, 500, 550, 600, 650, 700, 740, 800, 900, 950, 1000, 1100, 1200, 1300 },
	-- ["thunder"] = { 350, 400, 450, 500, 600, 700, 800, 900, 1000, 1200, 1300, 1400, 1550, 1700 },
	-- ["snow"] = { 500, 560, 600, 650, 700, 780, 800 }
	["rain"] = { 1500, 1600, 1800, 1950, 2000, 2200, 2500, 2600, 2700, 2800, 2900, 3000 },
	["thunder"] = { 1700, 1600, 1800, 1950, 2000, 2200, 2500, 2600, 2750, 2800, 3000, 3500, 4000, 4500, 5000 },
	["snow"] = { 2000, 2200, 2500, 2600, 2800, 3000, 3200, 3400, 3600 }
	
}

local cloudSpeed = {
	[1] = {
		50, 55, 60, 80, 98, 100, 110, 120, 130,
		150, 190, 200, 220,
		320, 340
	},
	[2] = {
		60, 72, 85, 90, 100, 120, 140,
		150, 170, 180, 200,
		320, 345,
	},
	[3] = {
		50, 60, 70, 100, 120, 140,
		150, 190, 240, 250, 270
	},
	[4] = {
		20, 30, 50, 60, 80, 100, 120, 140,
		150, 160, 200, 250
	},
	[5] = {
		100, 120,
		150, 190, 200, 250, 300,
		320, 375, 390, 400
	},
	[6] = {
		160, 180, 200, 230, 260, 300,
		360, 380, 450, 500
	},
	[7] = { 600, 700, 800, 900, 1000, 1200, 1500 },
	[8] = { 750, 800, 900, 1000, 1250, 2360, 1470, 1600, 1800 },
	[9] = {
		80, 100, 110, 125, 145,
		185, 196, 200, 270
	},
	[10] = { 600, 760, 850, 920, 1100, 1250 }

}

-- Determine current MQ state --
-- This I got from Creeping Blight by Necrolesian --
-- The values control Blight percent chance for all Vvardenfell regions --
local function getMQState()

	-- Receiving index 20 for this quest changes the weather at Red Mountain. Also resets questStage to 0.
	local endGameIndex = tes3.getJournalIndex { id = "C3_DestroyDagoth" }

	-- Give the Dwemer Puzzle Box to Hasphat Antabolis. Triggers questStage 1.
	local antabolisIndex = tes3.getJournalIndex { id = "A1_2_AntabolisInformant" }

	-- Receive notes on the Ashlanders from Hassour Zainsubani. Triggers questStage 2.
	local zainsubaniIndex = tes3.getJournalIndex { id = "A1_11_ZainsubaniInformant" }

	-- Defeat Dagoth Gares. Triggers questStage 3.
	local garesIndex = tes3.getJournalIndex { id = "A2_2_6thHouse" }

	-- Take the cure from Divayth Fyr. Triggers questStage 4.
	local cureIndex = tes3.getJournalIndex { id = "A2_3_CorprusCure" }

	-- Receive Moon-and-Star from Azura. Triggers questStage 5.
	local incarnateIndex = tes3.getJournalIndex { id = "A2_6_Incarnate" }

	-- Receive a working Wraithguard from Vivec or Yagrum Bagarn. Triggers questStage 6.
	local vivecIndex = tes3.getJournalIndex { id = "B8_MeetVivec" }
	local backPathIndex = tes3.getJournalIndex { id = "CX_BackPath" }

	local questStage

	-- Determine the current stage of the Main Quest.
	if endGameIndex >= 20 then
		questStage = 0
	elseif vivecIndex >= 50 or backPathIndex >= 50 then
		questStage = 6
	elseif incarnateIndex >= 50 then
		questStage = 5
	elseif cureIndex >= 50 then
		questStage = 4
	elseif garesIndex >= 50 then
		questStage = 3
	elseif zainsubaniIndex >= 50 then
		questStage = 2
	elseif antabolisIndex >= 10 then
		questStage = 1
	else
		questStage = 0
	end
	return questStage
end

-- Change particle mesh colours in real-time --
local function reColourParticleMesh()

	-- Bugger off if we don't have all the data needed --
	if not (WtC.currentWeather.name == "Rain" or WtC.currentWeather.name == "Thunderstorm" or WtC.currentWeather.name == "Snow")
		or ((WtC.nextWeather) and not (WtC.nextWeather.name == "Rain" or WtC.nextWeather.name == "Thunderstorm" or WtC.nextWeather.name == "Snow"))
		or not newParticleMesh then
		return
	end

	-- Get fog colour to make the particles match the scene look --
	local weatherColour = WtC.currentFogColor

	-- Preprocess colours a bit, snow should be lighter, rain should look a bit colder --
	local colours
	if (WtC.currentWeather.name) == "Snow" or (WtC.nextWeather and WtC.nextWeather.name == "Snow") then
		colours = {
			r = math.clamp(weatherColour.r + 0.2, 0.1, 0.9),
			g = math.clamp(weatherColour.g + 0.2, 0.1, 0.9),
			b = math.clamp(weatherColour.b + 0.2, 0.1, 0.9)
		}
	else
		colours = {
			r = math.clamp(weatherColour.r + 0.11, 0.1, 0.9),
			g = math.clamp(weatherColour.g + 0.12, 0.1, 0.9),
			b = math.clamp(weatherColour.b + 0.13, 0.1, 0.9)
		}
	end

	-- Set the particle mesh colour via mesh material property --
	local materialProperty = newParticleMesh:getObjectByName("tew_particle").materialProperty
	materialProperty.emissive = colours
	materialProperty.specular = colours
	materialProperty.diffuse = colours
	materialProperty.ambient = colours
end

-- Randomise particle mesh --
local function changeParticleMesh(particleType)

	-- Timer here to actually allow background data to be available --
	timer.start {
		type = timer.game,
		duration = 0.00001,
		callback = function()

			-- Get particle mesh from pre-filled array and load it --
			local randomParticleMesh = table.choice(particles[particleType])
			newParticleMesh = tes3.loadMesh("tew\\Watch the Skies\\particles\\" .. particleType .. "\\" .. randomParticleMesh):clone()

			-- Simple inline function to swap the nodes, preserving visibility --
			local function swapNode(particle)
				local old = particle.object
				particle.rainRoot:detachChild(old)

				local new = newParticleMesh:clone()
				particle.rainRoot:attachChild(new)
				new.appCulled = old.appCulled

				particle.object = new
			end

			-- Swap both active and inactive particles to ward off sudden changes --
			for _, particle in pairs(WtC.particlesActive) do
				swapNode(particle)
			end
			for _, particle in pairs(WtC.particlesInactive) do
				swapNode(particle)
			end

			-- Update the root node to reflect the changes made --
			WtC.sceneRainRoot:updateEffects()
			debugLog("Rain mesh changed to " .. randomParticleMesh)
		end
	}
end

-- Randomise particle amount --
local function changeMaxParticles()
	local currentWeather = WtC.currentWeather.index

	-- Match the weather index with lua array index --
	if currentWeather ~= 4 then
		WtC.weathers[5].maxParticles = table.choice(particleAmount["rain"])
	end
	if currentWeather ~= 5 then
		WtC.weathers[6].maxParticles = table.choice(particleAmount["thunder"])
	end
	if currentWeather ~= 8 then
		WtC.weathers[9].maxParticles = table.choice(particleAmount["snow"])
	end
	debugLog("Particles amount randomised.")
	debugLog("Rain particles: " .. WtC.weathers[5].maxParticles)
	debugLog("Thunderstorm particles: " .. WtC.weathers[6].maxParticles)
	debugLog("Snow particles: " .. WtC.weathers[9].maxParticles)
	event.trigger("WtS:maxParticlesChanged")
end

-- Change cloud speed --
local function changeCloudsSpeed()
	local currentWeather = WtC.currentWeather.index
	for i, w in pairs(WtC.weathers) do
		if i == currentWeather then goto continue end
		w.cloudsSpeed = table.choice(cloudSpeed[i]) / 100
		::continue::
	end
	debugLog("Clouds speed randomised.")
end

-- Main function controlling cloud texture swap --
local function skyChoice()
	local weatherNow = WtC.currentWeather
	if WtC.nextWeather then return end

	-- Check against config chances, do nothing if dice roll determines we should use vanilla instead --
	debugLog("Starting cloud texture randomisation.")
	local texPath, sArray
	for _, weather in pairs(WtC.weathers) do
		if (weatherNow.index == weather.index) then goto continue end
		if config.vanChance < math.random() then
			for index, _ in pairs(weathers.customWeathers) do
				if weather.index == index then
					for w, i in pairs(tes3.weather) do
						if index == i then
							sArray = weathers.customWeathers[weather.index]
							texPath = w
							break
						end
					end
				end
			end
			if texPath ~= nil and sArray[1] ~= nil then
				weather.cloudTexture = WtSdir .. texPath .. "\\" .. sArray[math.random(1, #sArray)]
				debugLog("Cloud texture path set to: " .. weather.cloudTexture)
			end
		else
			texPath = weathers.vanillaWeathers[weather.index]
			weather.cloudTexture = "Data Files\\Textures\\" .. texPath
			debugLog("Using vanilla texture: " .. weather.cloudTexture)
		end
		::continue::
	end

	-- Change hours between weather changes --
	local alterChanges = config.alterChanges
	if alterChanges then
		WtC.hoursBetweenWeatherChanges = math.random(3, 10)
		debugLog("Current time between weather changes: " .. WtC.hoursBetweenWeatherChanges)
	end

	-- Randomise particles --
	local randomiseParticles = config.randomiseParticles
	if randomiseParticles then
		changeMaxParticles()
	end

	-- Randomise cloud speed --
	local randomiseCloudsSpeed = config.randomiseCloudsSpeed
	if randomiseCloudsSpeed then
		changeCloudsSpeed()
	end

end

-- Main function controlling weather changes in interiors --
local function changeInteriorWeather()
	if WtC.nextWeather then return end

	local currentWeather = WtC.currentWeather.index
	local newWeather
	debugLog("Weather before randomisation: " .. currentWeather)

	-- Use regional weather chances --
	local region = tes3.getRegion({ useDoors = true })
	local regionChances = {
		[0] = region.weatherChanceClear,
		[1] = region.weatherChanceCloudy,
		[2] = region.weatherChanceFoggy,
		[3] = region.weatherChanceOvercast,
		[4] = region.weatherChanceRain,
		[5] = region.weatherChanceThunder,
		[6] = region.weatherChanceAsh,
		[7] = region.weatherChanceBlight,
		[8] = region.weatherChanceSnow,
		[9] = region.weatherChanceBlizzard
	}

	-- Get the new weather --
	while newWeather == nil do
		for weather, chance in pairs(regionChances) do
			if chance / 100 > math.random() then
				newWeather = weather
				break
			end
		end
	end

	if newWeather == currentWeather then changeInteriorWeather() return end

	-- Switch to the new weather --
	WtC:switchTransition(newWeather)
	debugLog("Weather randomised. New weather: " .. WtC.nextWeather.index)
end

-- Main function controlling seasonal weather chances --
local function changeSeasonal()

	-- Get month and region and buzz off if there's no change --
	local month = tes3.worldController.month.value + 1
	local regionNow = tes3.getRegion({ useDoors = true })
	if (month == monthLast) and (regionNow == regionLast) then debugLog("Same month and region. Returning.") return end

	-- If either month or region has changes, we need to reapply values--
	-- Get the current MQ state to use in Blight calculations --
	local questStage = getMQState()
	debugLog("Main quest stage: " .. questStage)

	-- Iterate over all current regions and amend values if we get a much against our table --
	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		-- Special handling for Red Mountain - use eithre full Blight or normal regional weather after MQ --
		if region.id == "Red Mountain Region" then
			if tes3.getJournalIndex { id = "C3_DestroyDagoth" } < 20 then
				debugLog("Dagoth Ur is alive. Using full blight values for Red Mountain.")
				region.weatherChanceClear = 0
				region.weatherChanceCloudy = 0
				region.weatherChanceFoggy = 0
				region.weatherChanceOvercast = 0
				region.weatherChanceRain = 0
				region.weatherChanceThunder = 0
				region.weatherChanceAsh = 0
				region.weatherChanceBlight = 100
				region.weatherChanceSnow = 0
				region.weatherChanceBlizzard = 0
			else
				debugLog("Dagoth Ur is dead. Reverting to regular RM weather. Removing blight cloud.")
				region.weatherChanceClear = seasonalChances[region.id][month][1]
				region.weatherChanceCloudy = seasonalChances[region.id][month][2]
				region.weatherChanceFoggy = seasonalChances[region.id][month][3]
				region.weatherChanceOvercast = seasonalChances[region.id][month][4]
				region.weatherChanceRain = seasonalChances[region.id][month][5]
				region.weatherChanceThunder = seasonalChances[region.id][month][6]
				region.weatherChanceAsh = seasonalChances[region.id][month][7]
				region.weatherChanceBlight = seasonalChances[region.id][month][8]
				region.weatherChanceSnow = seasonalChances[region.id][month][9]
				region.weatherChanceBlizzard = seasonalChances[region.id][month][10]

				-- Disable the blight cloud object from Dagoth Ur volcano --
				mwscript.disable { reference = "blight cloud" }
			end
			-- Special handling of Mournhold weather machine --
		elseif region.id == "Mournhold Region"
			and tes3.findGlobal("MournWeather").value == 1
			or tes3.findGlobal("MournWeather").value == 2
			or tes3.findGlobal("MournWeather").value == 3
			or tes3.findGlobal("MournWeather").value == 4
			or tes3.findGlobal("MournWeather").value == 5
			or tes3.findGlobal("MournWeather").value == 6
			or tes3.findGlobal("MournWeather").value == 7 then
			debugLog("Weather machine running: " .. tes3.findGlobal("MournWeather").value)
			region.weatherChanceClear = 0
			region.weatherChanceCloudy = 0
			region.weatherChanceFoggy = 0
			region.weatherChanceOvercast = 0
			region.weatherChanceRain = 0
			region.weatherChanceThunder = 0
			region.weatherChanceAsh = 0
			region.weatherChanceBlight = 0
			region.weatherChanceSnow = 0
			region.weatherChanceBlizzard = 0
			if tes3.findGlobal("MournWeather").value == 1 then
				region.weatherChanceClear = 100
			elseif tes3.findGlobal("MournWeather").value == 2 then
				region.weatherChanceCloudy = 100
			elseif tes3.findGlobal("MournWeather").value == 3 then
				region.weatherChanceFoggy = 100
			elseif tes3.findGlobal("MournWeather").value == 4 then
				region.weatherChanceOvercast = 100
			elseif tes3.findGlobal("MournWeather").value == 5 then
				region.weatherChanceRain = 100
			elseif tes3.findGlobal("MournWeather").value == 6 then
				region.weatherChanceThunder = 100
			elseif tes3.findGlobal("MournWeather").value == 7 then
				region.weatherChanceAsh = 100
			end
		else
			-- If we detect a Vvardenfell region, adjust Blight values per current MQ state --
			if checkVv(region.id) == true then
				region.weatherChanceClear = (seasonalChances[region.id][month][1]) - questStage
				region.weatherChanceCloudy = seasonalChances[region.id][month][2]
				region.weatherChanceFoggy = seasonalChances[region.id][month][3]
				region.weatherChanceOvercast = seasonalChances[region.id][month][4]
				region.weatherChanceRain = seasonalChances[region.id][month][5]
				region.weatherChanceThunder = seasonalChances[region.id][month][6]
				region.weatherChanceAsh = seasonalChances[region.id][month][7]
				region.weatherChanceBlight = (seasonalChances[region.id][month][8]) + questStage
				region.weatherChanceSnow = seasonalChances[region.id][month][9]
				region.weatherChanceBlizzard = seasonalChances[region.id][month][10]
			elseif seasonalChances[region.id] then
				-- Otherwise just use regular stored values --
				region.weatherChanceClear = seasonalChances[region.id][month][1]
				region.weatherChanceCloudy = seasonalChances[region.id][month][2]
				region.weatherChanceFoggy = seasonalChances[region.id][month][3]
				region.weatherChanceOvercast = seasonalChances[region.id][month][4]
				region.weatherChanceRain = seasonalChances[region.id][month][5]
				region.weatherChanceThunder = seasonalChances[region.id][month][6]
				region.weatherChanceAsh = seasonalChances[region.id][month][7]
				region.weatherChanceBlight = seasonalChances[region.id][month][8]
				region.weatherChanceSnow = seasonalChances[region.id][month][9]
				region.weatherChanceBlizzard = seasonalChances[region.id][month][10]
			end
		end
	end

	-- Write month and region off for later comparison --
	monthLast = month
	regionLast = regionNow

	debugLog("Current chances for region: " .. regionNow.name .. ": " .. regionNow.weatherChanceClear .. ", " .. regionNow.weatherChanceCloudy .. ", " .. regionNow.weatherChanceFoggy .. ", " .. regionNow.weatherChanceOvercast .. ", " .. regionNow.weatherChanceRain .. ", " .. regionNow.weatherChanceThunder .. ", " .. regionNow.weatherChanceAsh .. ", " .. regionNow.weatherChanceBlight .. ", " .. regionNow.weatherChanceSnow .. ", " .. regionNow.weatherChanceBlizzard)

end

-- The following function uses slightly amended sveng's calculations from their old ESP mod: nexusmods.com/morrowind/mods/44375 --
-- The function changes sunrise/sunset hours based on world latitude --
local function changeDaytime()

	local month = tes3.worldController.month.value
	local day = tes3.worldController.day.value

	---
	local southY = -400000 -- Max "south pole" value - default -400000 (approximately Old Morrowind-Argonia border) --
	local northY = 225000 -- Max "north pole" value - 225000 is slightly north of Castle Karstaag
	local minDaytime = 4.0 -- Minimum daytime duration
	local solsticeSunrise = 6.0 -- Sunrise hours at 0 world position for solstice
	local solsticeSunset = 18.0 -- Sunset hour at 0 world position for solstice
	local durSunrise = 2.0 -- Sunrise duration
	local durSunset = 2.0 -- Sunset duration
	local playerY = tes3.player.position.y -- Player y (latitude) position
	local adjustedSunrise, adjustedSunset, l1, f1, f2, f3 -- Adjusted values and coefficients

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

-- We need to change stuff on cell change --
local function onCellChanged(e)
	debugLog("Cell changed.")
	local cell = e.cell or tes3.getPlayerCell()
	if not cell then return end

	-- To ensure Glass Domes don't get rain particles inside --
	if isOpenPlaza(cell) == true then
		WtC.weathers[5].maxParticles = 1500
		WtC.weathers[6].maxParticles = 3000
		WtC.weathers[5].particleRadius = 1200
		WtC.weathers[6].particleRadius = 1200
	end

	-- Run seasonal weather check --
	if config.seasonalWeather then
		changeSeasonal()
	end

	-- Run daytime check --
	if config.daytime then
		changeDaytime()
	end

	-- Pause the interior weather timer if the player is in exterior --
	if (cell.isOrBehavesAsExterior) then
		if intWeatherTimer then
			intWeatherTimer:pause()
			debugLog("Player in exterior. Pausing interior timer.")
		end
		-- Refresh the timer in interiors --
	else
		if intWeatherTimer then
			intWeatherTimer:pause()
			intWeatherTimer:cancel()
			intWeatherTimer = nil
		end
		intWeatherTimer = timer.start {
			duration = WtC.hoursBetweenWeatherChanges,
			callback = changeInteriorWeather,
			type = timer.game,
			iterations = -1
		}
		debugLog("Player in interior. Resuming interior timer. Hours to weather change: " .. WtC.hoursBetweenWeatherChanges)
	end
end

-- Run seasonal timer on loaded --
-- Just to be extra sure if the player stays in the same cell for a really long time --
local function seasonalTimer()
	monthLast = nil
	changeSeasonal()
	timer.start({ duration = 7, callback = changeSeasonal, iterations = -1, type = timer.game })
end

-- Run daytime timer on loaded --
local function daytimeTimer()
	monthLast = nil
	changeDaytime()
	timer.start({ duration = 6, callback = changeDaytime, iterations = -1, type = timer.game })
end

-- Shuffle texture every two hours --
local function skyChoiceTimer()
	timer.start({ duration = 6, callback = skyChoice, iterations = -1, type = timer.game })
end

-- Check if we have the weather that warrants particle change --
local function particleMeshChecker()
	timer.start{
		type=timer.game,
		duration = 0.001,
		callback = function()
			local weatherNow
			-- Also check if we're transitioning to next weather --
			if WtC.nextWeather then
				weatherNow = WtC.nextWeather
				-- Match rain and thunderstorm with rain particles, and snow with snow particles --
				local checked = weatherChecklist[weatherNow.name]
				if checked ~= nil then
					timer.start {
						duration = 0.25,
						callback = function()
							changeParticleMesh(checked)
						end,
						type = timer.game,
					}
				end
			else
				weatherNow = WtC.currentWeather
				local checked = weatherChecklist[weatherNow.name]
				if checked ~= nil then
					changeParticleMesh(checked)
				end
			end
		end
	}
end

-- Change values also on initialised to ensure we won't end up with vanilla on load --
local function init()

	WtC = tes3.worldController.weatherController

	-- Get available raindrops --
	if config.randomiseParticleMeshes then
		for particleType in lfs.dir(particlesPath) do
			if particleType and particleType ~= ".." and particleType ~= "." then
				for particle in lfs.dir(particlesPath .. "\\" .. particleType) do
					if particle and particle ~= ".." and particle ~= "." and string.endswith(particle:lower(), ".nif") then
						table.insert(particles[particleType], particle)
					end
				end
			end
		end

		-- Register events to change particle meshes in --
		event.register("weatherTransitionStarted", particleMeshChecker, { priority = -250 })
		event.register("weatherTransitionFinished", particleMeshChecker, { priority = -250 })
		event.register("weatherTransitionImmediate", particleMeshChecker, { priority = -250 })
		event.register("weatherChangedImmediate", particleMeshChecker, { priority = -250 })
		event.register("loaded", particleMeshChecker, { priority = -250 })
		event.register("enterFrame", reColourParticleMesh)
	end

	-- Populate data tables with cloud textures --
	if config.alterClouds then
		for weather, index in pairs(tes3.weather) do
			debugLog("Weather: " .. weather)
			for sky in lfs.dir(WtSdir .. weather) do
				if sky ~= ".." and sky ~= "." then
					if string.endswith(sky, ".dds") or string.endswith(sky, ".tga") then
						table.insert(weathers.customWeathers[index], sky)
						debugLog("File added: " .. sky)
					end
				end
			end
		end

		-- Initially shuffle the cloud textures --
		local vanChance = config.vanChance / 100
		local texPath, sArray
		debugLog("Initially shuffling textures.")
		for _, weather in pairs(WtC.weathers) do
			if vanChance < math.random() then
				for index, _ in pairs(weathers.customWeathers) do
					if weather.index == index then
						for w, i in pairs(tes3.weather) do
							if index == i then
								sArray = weathers.customWeathers[weather.index]
								texPath = w
								break
							end
						end
					end
				end
				if texPath ~= nil and sArray[1] ~= nil then
					weather.cloudTexture = WtSdir .. texPath .. "\\" .. sArray[math.random(1, #sArray)]
					debugLog("Cloud texture path set to: " .. weather.cloudTexture)
				end
			else
				texPath = weathers.vanillaWeathers[weather.index]
				weather.cloudTexture = "Data Files\\Textures\\" .. texPath
				debugLog("Using vanilla texture: " .. weather.cloudTexture)
			end
		end

		-- Start texture change timer --
		event.register("loaded", skyChoiceTimer)
	end

	-- Initially shuffle hours between weather changes --
	if config.alterChanges then
		WtC.hoursBetweenWeatherChanges = math.random(3, 10)
	end

	-- Initially shuffle particle amounts --
	if config.randomiseParticles then		
		WtC.weathers[5].particleRadius = 1400
		WtC.weathers[6].particleRadius = 1400
		WtC.weathers[9].particleRadius = 1800
		changeMaxParticles()
	end

	-- Initially shuffle clouds speed --
	if config.randomiseCloudsSpeed then
		changeCloudsSpeed()
	end

	-- Register other events per MCM config --
	if config.seasonalWeather then
		event.register("loaded", seasonalTimer)
	end
	if config.daytime then
		event.register("loaded", daytimeTimer)
	end
	if config.interiorTransitions then
		event.register("cellChanged", onCellChanged, { priority = -150 })
	end

	mwse.log("[Watch the Skies] Version " .. version .. " initialised.")
end

event.register("initialized", init, { priority = -150 })

-- Registers MCM menu --
event.register("modConfigReady", function()
	dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\mcm.lua")
end)
