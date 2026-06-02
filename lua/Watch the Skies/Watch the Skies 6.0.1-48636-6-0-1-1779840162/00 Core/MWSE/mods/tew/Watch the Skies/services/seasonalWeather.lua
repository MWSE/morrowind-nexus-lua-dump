local seasonalWeather = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local seasonalChances = require("tew.Watch the Skies.components.seasonalChances")
local monthLast, regionLast

--------------------------------------------------------------------------------------

local vvRegions = {
	"Bitter Coast Region",
	"Azura's Coast Region",
	"Molag Mar Region",
	"Ashlands Region",
	"West Gash Region",
	"Ascadian Isles Region",
	"Grazelands Region",
	"Sheogorad",
}

--------------------------------------------------------------------------------------

-- Store original region weather chances to allow reverting later --
local defaultWeatherChances = {}

function seasonalWeather.storeDefaults()
	if not table.empty(defaultWeatherChances) then return end
	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		defaultWeatherChances[region.id] = {
			clear = region.weatherChanceClear,
			cloudy = region.weatherChanceCloudy,
			foggy = region.weatherChanceFoggy,
			overcast = region.weatherChanceOvercast,
			rain = region.weatherChanceRain,
			thunder = region.weatherChanceThunder,
			ash = region.weatherChanceAsh,
			blight = region.weatherChanceBlight,
			snow = region.weatherChanceSnow,
			blizzard = region.weatherChanceBlizzard,
		}
	end
	debugLog("Stored default regional weather chances.")
end

function seasonalWeather.restoreDefaults()
	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		local defaults = defaultWeatherChances[region.id]
		if defaults then
			region.weatherChanceClear = defaults.clear
			region.weatherChanceCloudy = defaults.cloudy
			region.weatherChanceFoggy = defaults.foggy
			region.weatherChanceOvercast = defaults.overcast
			region.weatherChanceRain = defaults.rain
			region.weatherChanceThunder = defaults.thunder
			region.weatherChanceAsh = defaults.ash
			region.weatherChanceBlight = defaults.blight
			region.weatherChanceSnow = defaults.snow
			region.weatherChanceBlizzard = defaults.blizzard
		end
	end
	debugLog("Restored default regional weather chances.")
end

--------------------------------------------------------------------------------------

function seasonalWeather.init()
	seasonalWeather.storeDefaults()
	seasonalWeather.calculate()
end

function seasonalWeather.checkVv(region)
	return table.find(vvRegions, region) ~= nil
end

function seasonalWeather.getMQState()
	local journalEntries = {
		[1] = {
			id = "C3_DestroyDagoth",
			blightChance = 0,
		},
		[2] = {
			id = "B8_MeetVivec",
			blightChance = 50,
		},
		[3] = {
			id = "CX_BackPath",
			blightChance = 50,
		},
		[4] = {
			id = "A2_6_Incarnate",
			blightChance = 30,
		},
		[5] = {
			id = "A2_4_MiloGone",
			blightChance = 15,
		},
		[6] = {
			id = "A2_3_CorprusCure",
			blightChance = 10,
		},
		[7] = {
			id = "A2_2_6thHouse",
			blightChance = 8,
		},
		[8] = {
			id = "A2_1_MeetSulMatuul",
			blightChance = 5,
		},
		[9] = {
			id = "A1_11_ZainsubaniInformant",
			blightChance = 3,
		},
		[10] = {
			id = "A1_2_AntabolisInformant",
			blightChance = 2,
		},
	}

	local blightChance = 0
	for _, entry in ipairs(journalEntries) do
		debugLog("Quest: " .. entry.id .. ", blight chance: " .. entry.blightChance)
		local index = tes3.getJournalIndex { id = entry.id }
		if index >= 50 then
			blightChance = entry.blightChance
			break
		end
	end
	return blightChance
end

function seasonalWeather.calculate()
	-- Get month and region and buzz off if there's no change --
	local month = tes3.worldController.month.value + 1
	local regionNow = tes3.getRegion(true)
	if not regionNow then return end
	if (month == monthLast) and (regionNow == regionLast) then
		debugLog("Same month and region. Returning.")
		return
	end

	-- If either month or region has changed, we need to reapply values--
	-- Get the current MQ state to use in Blight calculations --
	local questStage = seasonalWeather.getMQState()
	debugLog("Selected blight chance: " .. questStage)

	-- Iterate over all current regions and amend values if we get a match against our table --
	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		-- Special handling for Red Mountain - use either full Blight or normal regional weather after MQ --
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
			if seasonalWeather.checkVv(region.id) == true then
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
	debugLog(
		string.format(
			"Current chances for region: %s are %s, %s, %s, %s, %s, %s, %s, %s, %s, %s",
			regionNow.name,
			regionNow.weatherChanceClear,
			regionNow.weatherChanceCloudy,
			regionNow.weatherChanceFoggy,
			regionNow.weatherChanceOvercast,
			regionNow.weatherChanceRain,
			regionNow.weatherChanceThunder,
			regionNow.weatherChanceAsh,
			regionNow.weatherChanceBlight,
			regionNow.weatherChanceSnow,
			regionNow.weatherChanceBlizzard
		)
	)
end

function seasonalWeather.startTimer()
	monthLast, regionLast = nil, nil
	seasonalWeather.calculate()
	timer.start {
		duration = common.centralTimerDuration,
		callback = seasonalWeather.calculate,
		iterations = -1,
		type = timer.game,
	}
end

--------------------------------------------------------------------------------------

return seasonalWeather
