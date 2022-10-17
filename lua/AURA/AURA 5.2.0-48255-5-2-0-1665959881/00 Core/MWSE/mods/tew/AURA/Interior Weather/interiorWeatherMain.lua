local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local sounds = require("tew.AURA.sounds")

local IWvol = config.IWvol / 200

local cellLast, thunRef, windoors, thunder, interiorTimer, thunderTimerBig, thunderTimerSmall, thunderTime, interiorType, weather, weatherLast, scalarTimer
local thunArray = common.thunArray
local blockedWeathers = {
	[0] = true,
	[1] = true,
	[2] = true,
	[3] = true,
	[8] = true,
}

local soundData = {
	["sma"] = {
		[4] = {
			volume = 0.7,
			pitch = 1.0
		},
		[5] = {
			volume = 0.65,
			pitch = 1.0
		},
		[6] = {
			volume = 0.35,
			pitch = 0.6
		},
		[7] = {
			volume = 0.35,
			pitch = 0.6
		},
		[9] = {
			volume = 0.35,
			pitch = 0.6
		}
	},
	["big"] = {
		[4] = {
			volume = 0.8,
			pitch = 1.0
		},
		[5] = {
			volume = 0.8,
			pitch = 1.0
		},
		[6] = {
			volume = 0.4,
			pitch = 0.75
		},
		[7] = {
			volume = 0.4,
			pitch = 0.75
		},
		[9] = {
			volume = 0.4,
			pitch = 0.75
		}
	},
    ["ten"] = {
        [4] = {
            volume = 0.9,
            pitch = 1.0
        },
        [5] = {
            volume = 1.0,
            pitch = 1.0
        },
        [6] = {
            volume = 0.4,
            pitch = 0.8
        },
        [7] = {
            volume = 0.4,
            pitch = 0.8
        },
        [9] = {
            volume = 0.4,
            pitch = 0.8
        }
    }
}

local debugLog = common.debugLog
local isOpenPlaza = tewLib.isOpenPlaza
local moduleName = "interiorWeather"

local immediate = false

-- Check script scope variable or function param to determine whether we should play immediately of fade in --
local function immediateParser(options)
	immediate = immediate or options.immediate
	if immediate then
		sounds.playImmediate { weather = options.weather, module = moduleName, volume = options.volume, type = options.type, reference = options.reference, pitch = options.pitch }
	else
		sounds.play { weather = options.weather, module = moduleName, volume = options.volume, type = options.type, reference = options.reference, pitch = options.pitch }
	end
end

-- Play thunder sounds on a timer --
local function playThunder()
	local thunVol, thunPitch
	if thunRef == nil then return end
	thunVol = (math.random(1, 5)) / 10
	thunPitch = (math.random(5, 15)) / 10

	thunder = thunArray[math.random(1, #thunArray)]
	debugLog("Playing thunder: " .. thunder)

	local result = event.trigger("AURA:thunderPlayed", { sound = thunder, reference = thunRef, windoors = windoors, delay = 1.0 })
	local delay = table.get(result, "delay", 1.0)

	timer.start {
		duration = delay,
		type = timer.real,
		callback = function()
			tes3.playSound { sound = thunder, volume = thunVol, pitch = thunPitch, reference = thunRef }
		end
	}

	thunderTime = math.random(3, 20)

	if interiorType == "big" then
		if thunderTimerBig then
			thunderTimerBig:pause()
			thunderTimerBig:cancel()
			thunderTimerBig = nil
		end
		thunRef = windoors[math.random(1, #windoors)]
		thunderTimerBig = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
	elseif interiorType == "sma" or interiorType == "ten" then
		if thunderTimerSmall then
			thunderTimerSmall:pause()
			thunderTimerSmall:cancel()
			thunderTimerSmall = nil
		end
		thunderTimerBig = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
	end
end

-- For shacks, small huts etc. --
local function playInteriorSmall(cell)
	local volBoost = 0
	thunRef = cell
	if isOpenPlaza(cell) == true then
		volBoost = 0.2
		thunRef = nil
		debugLog("Found open plaza. Applying volume boost and removing thunder timer.")
	end

	immediateParser {
		weather = weather,
		module  = moduleName,
		volume  = soundData[interiorType][weather].volume * IWvol + volBoost,
		pitch   = soundData[interiorType][weather].pitch,
		type    = interiorType
	}
end

-- For bigger interiors, proper buildings and that --
local function playInteriorBig(windoor, updateImmediate)
	if windoor == nil then debugLog("Dodging an empty ref.") return end
	immediateParser {
		weather   = weather,
		module    = moduleName,
		volume    = (soundData[interiorType][weather].volume * IWvol) - (0.005 * #windoors),
		pitch     = soundData[interiorType][weather].pitch,
		type      = interiorType,
		immediate = updateImmediate,
		reference = windoor,
	}
end

-- Will be yeeeeeeeeeeeeeeeeet otherwise --
local function updateInteriorBig()
	debugLog("Updating interior doors and windows.")
	local playerPos = tes3.player.position:copy()
	for _, windoor in ipairs(windoors) do
		if playerPos:distance(windoor.position:copy()) > 2000
			and windoor ~= nil then
			playInteriorBig(windoor, true)
		end
	end
end

local function clearTimers()
	if thunderTimerBig then
		thunderTimerBig:pause()
		thunderTimerBig:cancel()
		thunderTimerBig = nil
	end
	if thunderTimerSmall then
		thunderTimerSmall:pause()
		thunderTimerSmall:cancel()
		thunderTimerSmall = nil
	end
	if scalarTimer then
		scalarTimer:pause()
		scalarTimer:cancel()
		scalarTimer = nil
	end
end

local function cellCheck()

	-- Gets messy otherwise --
	-- We don't want to reset sounds when the player is waiting for a longer time --
	-- We'll resolve conditions after UI waiting element is destroyed --
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		return
	end

	weather = tes3.getRegion({ useDoors = true }).weather.index
	local cell = tes3.getPlayerCell()
	immediate = false

	debugLog("Starting cell check for module: " .. moduleName)

	-- Get out if the weather is the same as last time --
	if weather == weatherLast and cellLast == cell then
		debugLog("Same weather and cell detected. Returning.")
		return
	end

	if common.checkCellDiff(cell, cellLast) then
		debugLog("Cell type changed, resetting module sounds.")
		sounds.removeImmediate { module = moduleName }
		if windoors ~= {} and windoors ~= nil then
			for _, windoor in ipairs(windoors) do
				sounds.removeImmediate { module = moduleName, reference = windoor }
			end
		end
	end

	IWvol = config.IWvol / 200
	thunderTime = math.random(5, 10)

	-- Start the interior timer for windoor updates if not started already --
	if not interiorTimer then
		interiorTimer = timer.start({ duration = 1, iterations = -1, callback = updateInteriorBig, type = timer.real })
		interiorTimer:pause()
	else
		interiorTimer:pause()
	end

	if not cell then debugLog("No cell detected. Returning.") return end

	-- If exterior - bugger off and stop timers --
	if (cell.isOrBehavesAsExterior)
		and not (isOpenPlaza(cell)) then
		debugLog("Found exterior cell. Removing sounds and returning.")
		cellLast = cell
		clearTimers()
		return
	end

	-- Remove sounds from small type of interior if the weather has changed --
	if weather ~= weatherLast then
		sounds.removeImmediate { module = moduleName, type = "small" }
		clearTimers()
	end

	-- If the weather is clear or snowy, let's bugger off --
	if (blockedWeathers[weather]) or ((WtC.nextWeather) and (blockedWeathers[WtC.nextWeather])) then
		debugLog("Uneligible weather detected. Returning.")
		sounds.remove { module = moduleName }
		if windoors ~= {} and windoors ~= nil then
			for _, windoor in ipairs(windoors) do
				sounds.removeImmediate { module = moduleName, reference = windoor }
			end
		end
		clearTimers()
		return
	end

	-- Important for Glass Domes --
	-- We don't want it here, GD will use regular weather sounds since it's an int-as-ext --
	if (isOpenPlaza(cell) == true)
		and (weather == 6
			or weather == 7) then
		return
	end

	-- Resolve if we're transitioning, play the interior sound only after the particles appear (roughly) --

	if (WtC.nextWeather and WtC.transitionScalar) then
		local timerDuration = math.max(0.5 - (WtC.transitionScalar), 0.0)
		if WtC.transitionScalar <= 0.5 then
			scalarTimer = timer.start {
				duration = timerDuration,
				type = timer.game,
				iterations = 1,
				callback = cellCheck
			}
			return
		end
	end

	debugLog("Weather: " .. weather)
	debugLog("Immediate flag: " .. tostring(immediate))

	-- Determine cell type --
	if common.getCellType(cell, common.cellTypesSmall) == true then
		interiorType = "sma"
	elseif common.getCellType(cell, common.cellTypesTent) == true then
		interiorType = "ten"
	else
		interiorType = "big"
	end

	-- Get doors and windows --
	windoors = {}
	windoors = common.getWindoors(cell)

	-- Play according to cell type --
	debugLog("Found interior cell.")
	if interiorType == "sma" then
		debugLog("Playing small interior sounds.")
		if isOpenPlaza(cell) == true then
			tes3.getSound("Rain").volume = 0
			tes3.getSound("rain heavy").volume = 0
		else
			if weather == 5 then
				thunRef = cell
				thunderTimerSmall = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
			end
		end
		playInteriorSmall(cell)
	elseif interiorType == "ten" then
		debugLog("Playing tent interior sounds.")
		playInteriorSmall(cell)
		if weather == 5 then
			thunRef = cell
			thunderTimerSmall = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
		end
	else
		interiorType = "big"
		if windoors and windoors[1] ~= nil then
			debugLog("Playing big interior sounds.")
			for _, windoor in ipairs(windoors) do
				sounds.removeImmediate { module = moduleName, reference = windoor }
				playInteriorBig(windoor)
			end
			interiorTimer:resume()
			thunRef = windoors[math.random(1, #windoors)]
			if weather == 5 then
				thunderTimerBig = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
			end
		end
	end

	weatherLast = weather
	cellLast = cell
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

-- Suck it Java --
local function runResetter()
	cellLast, thunRef, windoors, thunder, interiorTimer, thunderTimerBig, thunderTimerSmall, thunderTime, interiorType, weather, weatherLast, scalarTimer = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
	immediate = false
end

WtC = tes3.worldController.weatherController

event.register("cellChanged", cellCheck, { priority = -165 })
event.register("weatherTransitionFinished", cellCheck, { priority = -165 })
event.register("weatherTransitionStarted", cellCheck, { priority = -165 })
event.register("weatherChangedImmediate", cellCheck, { priority = -165 })
event.register("weatherTransitionImmediate", cellCheck, { priority = -165 })
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -15 })
event.register("load", runResetter)
debugLog("Interior Weather module initialised.")
