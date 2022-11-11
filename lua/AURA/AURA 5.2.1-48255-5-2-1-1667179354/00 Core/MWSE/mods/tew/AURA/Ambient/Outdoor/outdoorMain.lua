local climates = require("tew.AURA.Ambient.Outdoor.outdoorClimates")
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local sounds = require("tew.AURA.sounds")

local isOpenPlaza = tewLib.isOpenPlaza

local moduleAmbientOutdoor = config.moduleAmbientOutdoor
local moduleInteriorWeather = config.moduleInteriorWeather
local playSplash = config.playSplash
local OAvol = config.OAvol / 200
local splashVol = config.splashVol / 200
local playInteriorAmbient = config.playInteriorAmbient

local moduleName = "outdoor"

local climateLast, weatherLast, timeLast, cellLast
local climateNow, weatherNow, timeNow
local WtC
local windoors, interiorTimer

local debugLog = common.debugLog

-- Parse passed options to prepare dispatch to sounds module --
local function weatherParser(options)
	local volume, pitch, ref, immediate, playLast

	-- Fallback values --
	if not options then
		volume = OAvol
		pitch = 1
		immediate = false
		ref = tes3.mobilePlayer.reference
		playLast = false
	else
		volume = options.volume or OAvol
		pitch = options.pitch or 1
		immediate = options.immediate or false
		ref = options.reference or tes3.mobilePlayer.reference
		playLast = options.playLast or false
	end

	-- Determine if we should play the sound or not, depending on the weather --
	if weatherNow >= 0 and weatherNow < 4 then
		debugLog("Playing regular weather track.")
		if immediate then
			sounds.playImmediate { module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref, last = playLast }
		else
			sounds.play { module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref, last = playLast }
		end
	elseif weatherNow == 6 or weatherNow == 7 or weatherNow == 9 then
		debugLog("Extreme weather detected.")
		sounds.remove { module = moduleName, reference = ref, volume = OAvol }
		return
	else
		debugLog("Uneligible weather detected. Returning.")
		return
	end
end

-- Play outdoor ambient on doors and windows --
local function playInteriorBig(windoor, playOld)
	if windoor == nil then debugLog("Dodging an empty ref.") return end
	local bigVolume = (0.25 * OAvol) - (0.005 * #windoors)
	weatherParser { reference = windoor, volume = bigVolume, pitch = 0.8, immediate = false, playLast = playOld }
end

-- Because MW engine will otherwise scrap the sound and not put it up again. Dumb thing --
local function updateInteriorBig()
	debugLog("Updating interior doors and windows.")
	local playerPos = tes3.player.position
	for _, windoor in ipairs(windoors) do
		if playerPos:distance(windoor.position:copy()) > 900 -- A bit less then cutoff, just to be sure. Shouldn't be too jarring --
			and windoor ~= nil then
			playInteriorBig(windoor, true)
		end
	end
end

-- Play on the whole thing for shacks etc. --
local function playInteriorSmall(playOld)
	weatherParser { volume = 0.2 * OAvol, pitch = 0.85, immediate = false, playLast = playOld }
end

local function cellCheck()

	-- Gets messy otherwise --
	-- We don't want to reset sounds when the player is waiting for a longer time --
	-- We'll resolve conditions after UI waiting element is destroyed --
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		return
	end

	debugLog("Cell changed or time check triggered. Running cell check.")
	local region
	OAvol = config.OAvol / 200

	-- Getting rid of timers on cell check --
	if not interiorTimer then
		interiorTimer = timer.start({ duration = 1, iterations = -1, callback = updateInteriorBig, type = timer.real })
		interiorTimer:pause()
	else
		interiorTimer:pause()
	end

	local cell = tes3.getPlayerCell()
	if (not cell) then
		debugLog("No cell detected. Returning.")
		return
	end
	debugLog("Cell: " .. cell.editorName)

	-- Proper region resolution depending on whether we've just loaded the game or not --
	-- Initially the game will not properly use region stuff unless you step outside --
	if cell.isInterior then
		local regionObject = tes3.getRegion({ useDoors = true }) -- If we're inside we need to scan doors to get the proper region --
		region = regionObject.id
		weatherNow = regionObject.weather.index
	else
		region = tes3.getRegion().id -- Otherwise we can just get the region from the cell --
		if WtC.nextWeather then
			weatherNow = WtC.nextWeather.index
		else
			weatherNow = WtC.currentWeather.index
		end
	end

	debugLog("Weather: " .. weatherNow)
	if region == nil then
		debugLog("No region detected. Returning.")
		return
	end

	-- Checking climate --
	for kRegion, vClimate in pairs(climates.regions) do
		if kRegion == region then
			climateNow = vClimate
		end
	end

	if not climateNow then debugLog("Blacklisted region - no climate detected. Returning.")
		return
	end
	debugLog("Climate: " .. climateNow)

	-- Checking time --
	local gameHour = tes3.worldController.hour.value
	if (gameHour >= WtC.sunriseHour - 1.5) and (gameHour < WtC.sunriseHour + 1.5) then
		timeNow = "sr"
	elseif (gameHour >= WtC.sunriseHour + 1.5) and (gameHour < WtC.sunsetHour - 1.5) then
		timeNow = "d"
	elseif (gameHour >= WtC.sunsetHour - 1.5) and (gameHour < WtC.sunsetHour + 1.5) then
		timeNow = "ss"
	elseif (gameHour >= WtC.sunsetHour + 1.5) or (gameHour < WtC.sunriseHour - 1.5) then
		timeNow = "n"
	end
	debugLog("Time: " .. timeNow)


	-- Transition filter chunk --
	if timeNow == timeLast
		and climateNow == climateLast
		and weatherNow == weatherLast
		and (common.checkCellDiff(cell, cellLast) == false
			or cell == cellLast) then
		debugLog("Same conditions. Returning.")
		return
	elseif timeNow ~= timeLast
		and weatherNow == weatherLast
		and (common.checkCellDiff(cell, cellLast) == false)
		and ((weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8)) then
		debugLog("Time changed but weather didn't. Returning.")
		return
	end

	debugLog("Different conditions. Resetting sounds.")

	-- In case someone dislikes my interior weather module - bah! --
	if (moduleInteriorWeather == false) and (windoors) and (weatherNow < 4) or (weatherNow == 8) then
		for _, windoor in ipairs(windoors) do
			sounds.removeImmediate { module = moduleName, reference = windoor }
		end
		debugLog("Clearing windoors.")
	end

	local useLast = false
	-- Exterior cells --
	if (cell.isOrBehavesAsExterior and not isOpenPlaza(cell)) then
		if cellLast and common.checkCellDiff(cell, cellLast) == true and timeNow == timeLast
			and weatherNow == weatherLast and climateNow == climateLast
			and not ((weatherNow >= 4 and weatherNow <= 6) or (weatherNow == 8)) then
			-- Using the same track when entering int/ext in same area; time/weather change will randomise it again --
			debugLog("Found same cell. Using last sound.")
			useLast = true
			sounds.play { module = moduleName, last = useLast, volume = OAvol }
		else
			debugLog("Found different exterior cell. Using new sound.")
			sounds.remove { module = moduleName, volume = OAvol }
			weatherParser { volume = OAvol }
		end
		-- Interior cells --
		-- Remove main outdoor sound and play the same sound for interiors, either big or small --
	elseif cell.isInterior then
		if cellLast and common.checkCellDiff(cell, cellLast) == true and timeNow == timeLast
			and weatherNow == weatherLast and climateNow == climateLast
			and not ((weatherNow >= 4 and weatherNow <= 6) or (weatherNow == 8)) then
			useLast = true
		else
			useLast = false
		end
		if (not playInteriorAmbient) or (playInteriorAmbient and isOpenPlaza(cell) and weatherNow == 3) then
			debugLog("Found interior cell and playInteriorAmbient off. Removing sounds.")
			sounds.removeImmediate { module = moduleName }
			return
		end
		debugLog("Found interior cell.")
		if common.getCellType(cell, common.cellTypesSmall) == true
			or common.getCellType(cell, common.cellTypesTent) == true then
			debugLog("Found small interior cell. Playing interior loops.")
			playInteriorSmall(useLast)
		else
			debugLog("Found big interior cell. Playing interior loops.")
			sounds.removeImmediate { module = moduleName } -- Needed to catch previous OA refs --
			windoors = nil
			windoors = common.getWindoors(cell)
			if windoors and not table.empty(windoors) then
				for i, windoor in ipairs(windoors) do
					sounds.removeImmediate { module = moduleName, reference = windoor }
					if i == 1 then
						playInteriorBig(windoor, useLast)
					else
						playInteriorBig(windoor, true)
					end
				end
				interiorTimer:resume()
			end
		end
	end

	-- Setting last values --
	timeLast = timeNow
	climateLast = climateNow
	weatherLast = weatherNow
	cellLast = cell
	debugLog("Cell check complete.")
end

-- To check whether we're underwater --
-- This doesn't work with water breathing (no UI element), so eventually will need to be migrated to a new method --
local function positionCheck(e)
	local cell = tes3.getPlayerCell()
	local element = e.element
	debugLog("Player underwater. Stopping AURA sounds.")
	if (not cell.isInterior) or (cell.behavesAsExterior) then
		sounds.removeImmediate { module = moduleName }
		sounds.playImmediate { module = moduleName, last = true, volume = 0.4 * OAvol, pitch = 0.5 }
	end
	if playSplash and moduleAmbientOutdoor then
		tes3.playSound { sound = "splash_lrg", volume = 0.5 * splashVol, pitch = 0.6 }
	end
	element:registerAfter("destroy", function()
		debugLog("Player above water level. Resetting AURA sounds.")
		if (not cell.isInterior) or (cell.behavesAsExterior) then
			sounds.removeImmediate { module = moduleName }
			sounds.playImmediate { module = moduleName, last = true, volume = OAvol }
		end
		timer.start({ duration = 1, callback = cellCheck, type = timer.real })
		if playSplash and moduleAmbientOutdoor then
			tes3.playSound { sound = "splash_sml", volume = 0.6 * splashVol, pitch = 0.7 }
		end
	end)
end

-- After waiting/travelling --
local function waitCheck(e)
	local element = e.element
	element:registerAfter("destroy", function()
		timer.start {
			type = timer.game,
			duration = 0.01,
			callback = cellCheck
		}
	end)
end

-- Reset stuff on load to not pollute our logic --
local function runResetter()
	climateLast, weatherLast, timeLast = nil, nil, nil
	climateNow, weatherNow, timeNow = nil, nil, nil
	windoors = {}
	timer.start {
		type = timer.game,
		duration = 0.01,
		callback = cellCheck
	}
end

-- Check for time changes --
local function runHourTimer()
	timer.start({ duration = 0.5, callback = cellCheck, iterations = -1, type = timer.game })
end

-- Fix for sky texture pop-in - believe it or not :| --
local function onWeatherTransistionStarted()
	timer.start(
		{
		duration = 0.1, callback = cellCheck, iterations = 1, type = timer.game
	}
	)
end

WtC = tes3.worldController.weatherController
event.register("loaded", runHourTimer, { priority = -160 })
event.register("load", runResetter, { priority = -160 })
event.register("cellChanged", cellCheck, { priority = -160 })
event.register("weatherTransitionStarted", onWeatherTransistionStarted, { priority = -160 })
event.register("weatherTransitionFinished", cellCheck, { priority = -160 })
event.register("weatherTransitionImmediate", cellCheck, { priority = -160 })
event.register("weatherChangedImmediate", cellCheck, { priority = -160 })
event.register("uiActivated", positionCheck, { filter = "MenuSwimFillBar", priority = -5 })
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -5 })
debugLog("Outdoor Ambient Sounds module initialised.")
