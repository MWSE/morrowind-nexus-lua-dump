local cellData = require("tew.AURA.cellData")
local climates = require("tew.AURA.Ambient.Outdoor.outdoorClimates")
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local defaults = require("tew.AURA.defaults")
local sounds = require("tew.AURA.sounds")

local isOpenPlaza = common.isOpenPlaza

local moduleAmbientOutdoor = config.moduleAmbientOutdoor
local moduleInteriorWeather = config.moduleInteriorWeather
local playInteriorAmbient = config.playInteriorAmbient
local OAvol, bigMult, smaMult

local moduleName = "outdoor"

local climateLast, weatherLast, timeLast
local climateNow, weatherNow, timeNow
local interiorTimer
local cell, cellLast
local WtC

local debugLog = common.debugLog

local blockedWeathers = {
    [5] = true,
    [6] = true,
    [7] = true,
    [9] = true,
}

local function updateConditions(resetTimerFlag)
	if resetTimerFlag
	and interiorTimer
	and cell.isInterior
	and not table.empty(cellData.windoors) then
		interiorTimer:reset()
	end
	timeLast = timeNow
	climateLast = climateNow
	weatherLast = weatherNow
	cellLast = cell
end

local function stopWindoors()
	if not table.empty(cellData.windoors) then
		for _, windoor in ipairs(cellData.windoors) do
			sounds.removeImmediate { module = moduleName, reference = windoor }
		end
	end
end

-- Because MW engine will otherwise scrap the sound and not put it up again. Dumb thing --
local function playWindoors(useLast)
	if table.empty(cellData.windoors) then return end
	debugLog("Updating interior doors and windows.")
	local windoorVol = (bigMult * OAvol) - (0.005 * #cellData.windoors)
	local playerPos = tes3.player.position:copy()
	local playLast
	for i, windoor in ipairs(cellData.windoors) do
		if windoor ~= nil and playerPos:distance(windoor.position:copy()) < 1800 then
			if i == 1 then
				playLast = useLast
			else
				playLast = true
			end
            sounds.play{
                module = moduleName,
                climate = climateNow,
                time = timeNow,
                volume = windoorVol,
                pitch = 0.8,
                newRef = windoor,
                last = playLast,
            }
		end
	end
end

local function cellCheck(e)

	-- Gets messy otherwise --
	-- We don't want to reset sounds when the player is waiting for a longer time --
	-- We'll resolve conditions after UI waiting element is destroyed --
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling or mp.sleeping)) then
		return
	end

	debugLog("Cell changed or time check triggered. Running cell check.")

	cell = tes3.getPlayerCell()
	if (not cell) then
		debugLog("No cell detected. Returning.")
		return
	end
	debugLog("Cell: " .. cell.editorName)

	if common.checkCellDiff(cell, cellLast) then
		debugLog("Cell type changed. Removing module sounds.")
		sounds.removeImmediate { module = moduleName }
	end

	local regionObject = tes3.getRegion(true)

	-- Fallback
	if not regionObject then
		regionObject = common.getFallbackRegion()
	end

	local region = regionObject.id

    if e and e.to then
		debugLog("Weather transitioning.")
        weatherNow = e.to.index
    else
		weatherNow = regionObject.weather.index
    end
	debugLog("Weather: " .. weatherNow)

	-- Bugger off if weather is blocked --
	if blockedWeathers[weatherNow] then
		debugLog("Uneligible weather detected. Removing sounds.")
		stopWindoors()
		sounds.remove { module = moduleName }
		updateConditions()
		return
	end

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

	if not climateNow then
		debugLog("Blacklisted region - no climate detected. Returning.")
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

	-- Randomising every time any of these change --
	local useLast = (timeNow == timeLast and weatherNow == weatherLast and climateNow == climateLast) or false

	-- Transition filter chunk --
	if useLast and (cell == cellLast) then
		debugLog("Found same cell, same conditions. Returning.")
		updateConditions(true)
		return
    end

    config = mwse.loadConfig("AURA", defaults)
	OAvol = config.volumes.modules[moduleName].volume / 100
    bigMult = config.volumes.modules[moduleName].big
    smaMult = config.volumes.modules[moduleName].sma

	-- Exterior cells --
	if (cell.isOrBehavesAsExterior and not isOpenPlaza(cell)) then
		debugLog(string.format("Found exterior cell. useLast: %s", useLast))
		if not useLast then sounds.remove { module = moduleName } end
		sounds.play{
			module = moduleName,
			climate = climateNow,
			time = timeNow,
			last = useLast,
		}
	-- Interior cells --
	elseif cell.isInterior then
		debugLog("Found interior cell.")
		stopWindoors()
		if (cell ~= cellLast) then
			sounds.removeImmediate { module = moduleName } -- Needed to catch previous interior cell sounds --
		end
		if (not playInteriorAmbient) or (playInteriorAmbient and isOpenPlaza(cell) and weatherNow == 3) then
			debugLog("Found interior cell and playInteriorAmbient off. Removing sounds.")
			sounds.removeImmediate { module = moduleName }
			updateConditions()
			return
		end
		if common.getCellType(cell, common.cellTypesSmall) == true
		or common.getCellType(cell, common.cellTypesTent) == true then
			debugLog("Found small interior cell.")
			debugLog("Playing regular weather track. useLast: " .. tostring(useLast))
			sounds.play{
				module = moduleName,
				climate = climateNow,
				time = timeNow,
				volume = smaMult * OAvol,
				pitch = 0.85,
				last = useLast,
			}
		else
			debugLog("Found big interior cell.")
			if not moduleInteriorWeather then updateConditions() return end
			if not table.empty(cellData.windoors) then
				debugLog("Found " .. #cellData.windoors .. " windoor(s). Playing interior loops.")
				playWindoors(useLast)
				updateConditions(true)
				return
			end
		end
	end

	updateConditions()
	debugLog("Cell check complete.")
end

-- Pause interior timer on condition change trigger --
local function onConditionChanged(e)
    if interiorTimer then interiorTimer:pause() end
    cellCheck(e)
end

-- After waiting/travelling --
local function waitCheck(e)
	local element = e.element
	element:registerAfter("destroy", function()
		timer.start {
			type = timer.game,
			duration = 0.01,
			callback = onConditionChanged
		}
	end)
end

-- Reset stuff on load to not pollute our logic --
local function runResetter()
	climateLast, weatherLast, timeLast = nil, nil, nil
	climateNow, weatherNow, timeNow = nil, nil, nil
end

-- Check for time changes --
local function runHourTimer()
	timer.start({ duration = 0.5, callback = cellCheck, iterations = -1, type = timer.game })
end

-- Run hour timer, start and pause interiorTimer on loaded --
local function onLoaded()
	runHourTimer()
	if moduleInteriorWeather then
		if not interiorTimer then
			interiorTimer = timer.start{
				duration = 1,
				iterations = -1,
				callback = playWindoors,
				type = timer.simulate
			}
		end
		interiorTimer:pause()
	end
end

-- Fix for sky texture pop-in - believe it or not :| --
local function transitionStartedWrapper(e)
	timer.start{
		duration = 1.5, -- Can be increased if not enough for sky texture pop-in
		type = timer.simulate, -- Switched to simulate b/c 0.1 duration is a bit too much if using timer.game along with a low timescale tes3globalVariable. E.g.: With a timescale of 10, a 0.1 timer.game timer will actually kick in AFTER weatherTransitionFinished, which is too late
		iterations = 1,
		callback = function()
            onConditionChanged(e)
        end
	}
end

WtC = tes3.worldController.weatherController
event.register("loaded", onLoaded, { priority = -160 })
event.register("load", runResetter, { priority = -160 })
event.register("cellChanged", onConditionChanged, { priority = -160 })
event.register("weatherTransitionStarted", transitionStartedWrapper, { priority = -160 })
event.register("weatherTransitionFinished", onConditionChanged, { priority = -160 })
event.register("weatherTransitionImmediate", onConditionChanged, { priority = -160 })
event.register("weatherChangedImmediate", onConditionChanged, { priority = -160 })
event.register("AURA:aboveOrUnderwater", onConditionChanged, { priority = -160 })
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -5 })
debugLog("Outdoor Ambient Sounds module initialised.")