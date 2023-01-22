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
	"Sheogorad"
}

--------------------------------------------------------------------------------------

function seasonalWeather.init()
	seasonalWeather.calculate()
end

function seasonalWeather.checkVv(region)
	return table.find(vvRegions, region) ~= nil
end

function seasonalWeather.getMQState()
	local journalEntries = {
		["C3_DestroyDagoth"] = 0,
		["A1_2_AntabolisInformant"] = 1,
		["A1_11_ZainsubaniInformant"] = 2,
		["A2_2_6thHouse"] = 3,
		["A2_3_CorprusCure"] = 4,
		["A2_6_Incarnate"] = 5,
		["B8_MeetVivec"] = 6,
		["CX_BackPath"] = 6
	}

	local questStage = 0
	for id, stage in pairs(journalEntries) do
		local index = tes3.getJournalIndex { id = id }
		if index >= 50 then
			questStage = math.max(questStage, stage)
		end
	end
	return questStage
end

function seasonalWeather.calculate()
	-- Get month and region and buzz off if there's no change --
	local month = tes3.worldController.month.value + 1
	local regionNow = tes3.getRegion(true)
	if (month == monthLast) and (regionNow == regionLast) then debugLog("Same month and region. Returning.") return end

	-- If either month or region has changes, we need to reapply values--
	-- Get the current MQ state to use in Blight calculations --
	local questStage = seasonalWeather.getMQState()
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
	timer.start{
		duration = common.centralTimerDuration,
		callback = seasonalWeather.calculate,
		iterations = -1,
		type = timer.game
	}
end

--------------------------------------------------------------------------------------

return seasonalWeather