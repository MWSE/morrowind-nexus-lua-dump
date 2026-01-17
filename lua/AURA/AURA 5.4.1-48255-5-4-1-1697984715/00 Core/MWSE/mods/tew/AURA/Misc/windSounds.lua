local cellData = require("tew.AURA.cellData")
local common = require("tew.AURA.common")
local config = require("tew.AURA.config")
local defaults = require("tew.AURA.defaults")
local moduleData = require("tew.AURA.moduleData")
local sounds = require("tew.AURA.sounds")
local volumeController = require("tew.AURA.volumeController")
local moduleName = "wind"
local playInteriorWind = config.playInteriorWind
local windoorVol, windoorPitch = 0, 0
local windType, cell
local windTypeLast, cellLast
local interiorTimer

local debugLog = common.debugLog

-- These have their own wind sounds --
local blockedWeathers = moduleData[moduleName].blockedWeathers

-- Determine wind type per cloud speed values, set in Watch the Skies --
local function getWindType(cSpeed)
    local cloudSpeed = cSpeed * 100
    if cloudSpeed < 150 then
        return "quiet"
    elseif cloudSpeed <= 320 then
        return "warm"
    elseif cloudSpeed <= 1800 then
        return "cold"
    else
        return nil
    end
end

local function updateConditions(resetTimerFlag)
	if resetTimerFlag
	and interiorTimer
	and cell.isInterior
	and not table.empty(cellData.windoors) then
		interiorTimer:reset()
	end
    windTypeLast = windType
    cellLast = cell
end

local function stopWindoors(immediateFlag)
    local remove = immediateFlag and sounds.removeImmediate or sounds.remove
	if not table.empty(cellData.windoors) then
		for _, windoor in ipairs(cellData.windoors) do
			if windoor ~= nil then
				remove { module = moduleName, reference = windoor }
			end
		end
	end
end

-- TODO: don't getVol every time
local function playWindoors(useLast)
	if table.empty(cellData.windoors) then return end
	debugLog("Updating interior doors and windows.")
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
                type = windType,
                volume = windoorVol,
                pitch = windoorPitch,
                newRef = windoor,
                last = playLast,
            }
		end
	end
end

-- Resolve data and play or remove wind sounds --
local function windCheck(e)
    -- Gets messy otherwise --
    local mp = tes3.mobilePlayer
    if (not mp) or (mp and (mp.waiting or mp.traveling or mp.sleeping)) then
        return
    end

    debugLog("Cell changed or time check triggered. Running cell check.")

    -- Cell resolution --
    cell = tes3.getPlayerCell()
    if (not cell) then
		debugLog("No cell detected. Returning.")
        sounds.remove { module = moduleName }
		return
	end
	debugLog("Cell: " .. cell.editorName)

    -- Weather resolution --
    local regionObject = tes3.getRegion(true)
    if not regionObject then regionObject = common.getFallbackRegion() end
    local weather
    if e and e.to then
        debugLog("Weather transitioning.")
        weather = e.to
    else
        weather = regionObject.weather
    end

    debugLog("Weather: " .. weather.index)

    -- Bugger off if weather is blocked --
    if blockedWeathers[weather.index] then
        debugLog("Uneligible weather detected. Removing sounds.")
        stopWindoors(true)
        sounds.remove { module = moduleName }
        updateConditions()
        return
    end

    -- Get wind type after resolving clouds speed --
    local cloudsSpeed = weather.cloudsSpeed
    debugLog("Current clouds speed: " .. tostring(cloudsSpeed))
    windType = getWindType(cloudsSpeed)

    -- If it's super slow then bugger off, no sound for ya --
    if not windType then
        debugLog("Wind type is nil. Returning.")
        sounds.remove { module = moduleName }
        updateConditions()
        return
    end
    debugLog("Wind type: " .. windType)

    local useLast = (windType == windTypeLast) or false

    -- Transition filter chunk --
    if (windType == windTypeLast)
    and (common.checkCellDiff(cell, cellLast) == false)
    and not (cell ~= cellLast) then
        debugLog("Same conditions. Returning.")
        updateConditions(true)
        return
    end
    if common.checkCellDiff(cell, cellLast) then
		debugLog("Cell type changed. Removing module sounds.")
		sounds.removeImmediate { module = moduleName }
	end

    if (windTypeLast ~= windType) or (cell ~= cellLast) then

        if (cell.isOrBehavesAsExterior) then
            -- Using the same track when entering int/ext in same area; time/weather change will randomise it again --
            debugLog(string.format("Found exterior cell. useLast: %s", useLast))
            if not useLast then sounds.remove { module = moduleName } end
            sounds.play { module = moduleName, type = windType, last = useLast }
        else
            debugLog("Found interior cell.")
            stopWindoors(true)
            if (cell ~= cellLast) then
                sounds.removeImmediate { module = moduleName } -- Needed to catch previous interior cell sounds --
            end
            if not playInteriorWind then
                debugLog("Found interior cell and playInteriorWind off. Removing sounds.")
                sounds.removeImmediate { module = moduleName }
                updateConditions()
                return
            end
            if common.getCellType(cell, common.cellTypesSmall) == true
            or common.getCellType(cell, common.cellTypesTent) == true then
                debugLog(string.format("Found small interior cell. useLast: %s", useLast))
                sounds.play{
                    module = moduleName,
                    type = windType,
                    last = useLast
                }
            else
                debugLog("Found big interior cell.")
                if not table.empty(cellData.windoors) then
                    debugLog("Found " .. #cellData.windoors .. " windoor(s). Playing interior loops.")
                    windoorVol = volumeController.getVolume(moduleName)
                    windoorPitch = volumeController.getPitch(moduleName)
                    playWindoors(useLast)
                    updateConditions(true)
                    return
                end
            end
        end
    end
    updateConditions()
    debugLog("Cell check complete.")
end

-- Pause interior timer on condition change trigger --
local function onConditionChanged(e)
    if interiorTimer then interiorTimer:pause() end
    windCheck(e)
end

-- Check every half an hour --
local function runHourTimer()
    timer.start({ duration = 0.5, callback = windCheck, iterations = -1, type = timer.game })
end

-- Run hour timer, start and pause interiorTimer on loaded --
local function onLoaded()
    runHourTimer()
	if playInteriorWind then
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

-- Waiting/travelling check --
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

-- Reset windoors when exiting underwater --
local function resetWindoors(e)
    if table.empty(cellData.windoors)
    or not playInteriorWind
    or not sounds.currentlyPlaying(moduleName) then
        return
    end
    if interiorTimer then interiorTimer:pause() end
    debugLog("Resetting windoors.")
    stopWindoors(true)
    windoorVol = volumeController.getVolume(moduleName)
    windoorPitch = volumeController.getPitch(moduleName)
    if interiorTimer then interiorTimer:reset() end
end

-- Timer here so that sky textures can work ok... something fishy with weatherTransitionStarted event for sure --
local function transitionStartedWrapper(e)
    timer.start {
        duration = 1.5, -- Can be increased if not enough for sky texture pop-in
        type = timer.simulate, -- Switched to simulate b/c 0.1 duration is a bit too much if using timer.game along with a low timescale tes3globalVariable. E.g.: With a timescale of 10, a 0.1 timer.game timer will actually kick in AFTER weatherTransitionFinished, which is too late
        iterations = 1,
        callback = function()
            onConditionChanged(e)
        end
    }
end

local function runResetter()
    cell, cellLast, windType, windTypeLast = nil, nil, nil, nil
end

event.register("weatherChangedImmediate", onConditionChanged, { priority = -100 })
event.register("weatherTransitionImmediate", onConditionChanged, { priority = -100 })
event.register("weatherTransitionStarted", transitionStartedWrapper, { priority = -100 })
event.register("weatherTransitionFinished", onConditionChanged, { priority = -100 })
event.register("AURA:exitedUnderwater", resetWindoors, { priority = -100 })
event.register("loaded", onLoaded, { priority = -160 })
event.register("load", runResetter)
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = 10 })
event.register("cellChanged", onConditionChanged, { priority = -100 })