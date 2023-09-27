local cellData = require("tew.AURA.cellData")
local common = require("tew.AURA.common")
local defaults = require("tew.AURA.defaults")
local moduleData = require("tew.AURA.moduleData")
local sounds = require("tew.AURA.sounds")
local soundData = require("tew.AURA.soundData")

local moduleName = "interiorWeather"
local soundConfig = moduleData[moduleName].soundConfig

local IWvol
local transitionScalarThreshold = 0.65
local volume, pitch, sound

local interiorTimer, scalarTimer, transitionScalarLast
local cell, cellLast, interiorType, weather, weatherLast
local thunRef, thunder, thunderTimer, thunderTime
local thunArray = common.thunArray
local blockedWeathers = {
	[0] = true,
	[1] = true,
	[2] = true,
	[3] = true,
	[8] = true,
}

local debugLog = common.debugLog
local isOpenPlaza = common.isOpenPlaza

-- Play thunder sounds on a timer --
local function playThunder()
	local thunVol, thunPitch
	if thunRef == nil then return end
	thunVol = (math.random(1, 5)) / 10
	thunPitch = (math.random(5, 15)) / 10

	thunder = thunArray[math.random(1, #thunArray)]
	debugLog("Playing thunder: " .. thunder)

	-- Exposing thunderPlayed event for GitD --
	local result = event.trigger("AURA:thunderPlayed", { sound = thunder, reference = thunRef, windoors = cellData.windoors, delay = 1.0 })
	local delay = table.get(result, "delay", 1.0)

	timer.start {
		duration = delay,
		type = timer.real,
		callback = function()
			tes3.playSound { sound = thunder, volume = thunVol, pitch = thunPitch, reference = thunRef }
		end
	}

	thunderTime = math.random(3, 20)

	thunderTimer:pause()
	thunderTimer:cancel()
	thunderTimer = nil
	if not table.empty(cellData.windoors) then
		thunRef = cellData.windoors[math.random(1, #cellData.windoors)]
	end
	thunderTimer = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
end

-- Not too proud of this --
local function updateConditions(resetTimerFlag)
	if resetTimerFlag
	and interiorTimer
	and cell.isInterior
	and not table.empty(cellData.windoors) then
		interiorTimer:reset()
	end
	weatherLast = weather
	cellLast = cell
end

-- No need to pass volume. volumeController.getVolume() will take care of the details --
local function playSmall()
    sounds.play{
        module = moduleName,
        weather = weather,
        type = interiorType,
        pitch = pitch,
    }
end

local function stopWindoors()
	if not table.empty(cellData.windoors) then
		for _, windoor in ipairs(cellData.windoors) do
			if windoor ~= nil then
				sounds.remove { module = moduleName, reference = windoor }
			end
		end
	end
end

local function playWindoors()
	if table.empty(cellData.windoors) then return end
	debugLog("Updating interior doors and windows.")
	local windoorVol = volume - (0.005 * #cellData.windoors)
	local playerPos = tes3.player.position:copy()
	for i, windoor in ipairs(cellData.windoors) do
		if windoor ~= nil and playerPos:distance(windoor.position:copy()) < 1800 then
            sounds.play{
                module = moduleName,
                newTrack = sound,
                newRef = windoor,
                volume = windoorVol,
                pitch = pitch,
            }
		end
	end
end

local function clearTimers()
	if thunderTimer then
		thunderTimer:pause()
		thunderTimer:cancel()
		thunderTimer = nil
	end
	if scalarTimer then
		scalarTimer:pause()
		scalarTimer:cancel()
		scalarTimer = nil
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

	debugLog("Starting cell check for module: " .. moduleName)

	-- Cell resolution --
	cell = e and e.cell or tes3.getPlayerCell()
	if not cell then debugLog("No cell detected. Returning.") return end

	-- If exterior - bugger off and stop timers --
	if (cell.isOrBehavesAsExterior)
	and not (isOpenPlaza(cell)) then
		debugLog("Found exterior cell. Removing sounds and returning.")
		cellLast = cell
		sounds.removeImmediate { module = moduleName }
		clearTimers()
		return
	end

	local regionObject = tes3.getRegion(true)
	if not regionObject then regionObject = common.getFallbackRegion() end
	local transitionScalarNow = regionObject.weather.controller.transitionScalar

	weather = regionObject.weather.index

	-- If the weather is clear or snowy, let's bugger off --
	if blockedWeathers[weather] then
		debugLog("Uneligible weather detected. Returning.")
		sounds.remove { module = moduleName }
		stopWindoors()
		clearTimers()
		updateConditions()
		return
	end

	-- Get out if the weather is the same as last time --
	if weather == weatherLast and cellLast == cell then
		debugLog("Same weather and cell detected.")
		updateConditions(true)
		return
	end

	-- Important for Glass Domes --
	-- We don't want it here, GD will use regular weather sounds since it's an int-as-ext --
	if (isOpenPlaza(cell) == true)
		and (weather == 6
			or weather == 7) then
        updateConditions()
		return
	end

	-- Resolve if we're transitioning, play the interior sound only after the particles appear (roughly) --

	if transitionScalarLast
	and transitionScalarNow
	and (transitionScalarNow > 0)
	and (transitionScalarNow <= transitionScalarThreshold)
	and (transitionScalarLast ~= transitionScalarNow) then
		debugLog(string.format("Weather transitioning. Scalar: %.2f | Threshold: %.2f", transitionScalarNow, transitionScalarThreshold))
		scalarTimer = timer.start{
			iterations = 1,
			type = timer.simulate,
			duration = 2,
			callback = cellCheck
		}
		return
	end
	transitionScalarLast = nil

	debugLog("Cell: " .. cell.editorName)
	debugLog("Weather: " .. weather)

	-- Determine cell type --
	interiorType = common.getInteriorType(cell)
	debugLog("Interior type: " .. interiorType)

	-- Resolve track early since we're going to reuse it when updating windoors --
    local config = mwse.loadConfig("AURA", defaults)
	IWvol = config.volumes.modules[moduleName].volume / 100
	volume = soundConfig[interiorType][weather].mult * IWvol
	pitch = soundConfig[interiorType][weather].pitch
	sound = soundData.interiorWeather[interiorType][weather]

	-- Remove sounds from small type of interior if the weather has changed --
	if weatherLast and (not blockedWeathers[weatherLast]) and (weatherLast ~= weather) then
		if interiorType ~= "big" then
			debugLog("Different weather detected. Removing sounds.")
			sounds.remove { module = moduleName }
			clearTimers()
		end
	end

	-- Conditions should be different at this point. We're free to reset stuff --
	thunRef = nil

	-- Play according to cell type --
	if interiorType == "sma" then
		debugLog("Playing small interior sounds.")
		if isOpenPlaza(cell) == true then
			debugLog("Found open plaza. Removing thunder timer.")
			clearTimers()
			thunRef = nil
		else
			thunRef = cell
		end
        playSmall()
	elseif interiorType == "ten" then
		debugLog("Playing tent interior sounds.")
		thunRef = cell
        playSmall()
	else
		if not table.empty(cellData.windoors) then
			debugLog("Found " .. #cellData.windoors .. " windoor(s). Playing interior loops.")
			playWindoors()
			interiorTimer:reset()
			thunRef = cellData.windoors[math.random(1, #cellData.windoors)]
		end
	end

	thunderTime = math.random(5, 10)
	if thunRef and (weather == 5) and not common.isTimerAlive(thunderTimer) then
		debugLog("Starting thunder timer.")
		thunderTimer = timer.start({ duration = thunderTime, iterations = 1, callback = playThunder, type = timer.real })
	end

	updateConditions()
	debugLog("Cell check complete.")
end


--[[
Pause interior timer on condition change trigger and check if transitioning.
There are cases when transitionScalar may be stuck on a value > 0 after a
condition change. One example is after loading a save in an interior where
weather transition was in progress at the time the save was made.
--]]
local function onConditionChanged(e)
    if interiorTimer then interiorTimer:pause() end
	transitionScalarLast = nil
	local transitionScalar = tes3.worldController.weatherController.transitionScalar
	if transitionScalar and transitionScalar > 0 then
		-- Apparently transitioning. cellCheck() will determine if we really are
		transitionScalarLast = transitionScalar
		timer.start{
			iterations = 1,
			duration = 0.5,
			type = timer.simulate,
			callback = function()
				cellCheck(e)
			end
		}
		return
	else
		-- Not transitioning. Carry on as usual.
		cellCheck(e)
	end
end

-- Make sure we catch previous IW refs on cell change --
local function onCellChanged(e)
	if e.cell and (e.cell.isInterior or (isOpenPlaza(e.cell) == true)) then
		debugLog("Cell changed, removing sounds.")
		sounds.removeImmediate { module = moduleName }
		clearTimers()
	end
	onConditionChanged(e)
end

-- Start and pause interiorTimer on loaded --
local function onLoaded()
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

-- Suck it Java --
local function runResetter()
	cell, cellLast, thunRef, thunder, interiorTimer, scalarTimer, thunderTimer, thunderTime, interiorType, weather, weatherLast, volume, pitch, sound = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
	transitionScalarLast = nil
end

event.register("cellChanged", onCellChanged, { priority = -165 })
event.register("weatherTransitionFinished", onConditionChanged, { priority = -165 })
--event.register("weatherTransitionStarted", onConditionChanged, { priority = -165 }) -- As per MWSE documentation, weather will not start transitioning in interiors, and since we only work with interiors in this module, we can do away with this event
event.register("weatherChangedImmediate", onConditionChanged, { priority = -165 })
event.register("weatherTransitionImmediate", onConditionChanged, { priority = -165 })
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -15 })
event.register("load", runResetter)
event.register("loaded", onLoaded, { priority = -160 })
debugLog("Interior Weather module initialised.")