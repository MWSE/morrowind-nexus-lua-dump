local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local moduleName = "wind"
local windPlaying = false
local config = require("tew.AURA.config")
local playInteriorWind = config.playInteriorWind
local windVol = (config.windVol / 200)
local windType, cell
local windTypeLast, cellLast
local interiorTimer
local windoors = {}

local debugLog = common.debugLog

local WtC

-- These have their own wind sounds --
local blockedWeathers = {
    [7] = true,
    [8] = true,
    [10] = true
}

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

local function playWind(ref, useLast, vol, pitch)
    debugLog("Wind type: " .. windType)
    if not vol then vol = windVol end
    sounds.play { module = moduleName, type = windType, volume = vol, pitch = pitch, reference = ref, last = useLast }
    windPlaying = true
    windTypeLast = windType
    cellLast = cell
end

local function updateInteriorBig()
    debugLog("Updating interior doors and windows.")
    local playerPos = tes3.player.position
    for _, windoor in ipairs(windoors) do
        if playerPos:distance(windoor.position:copy()) > 900 -- Less then cutoff, just to be sure. Shouldn't be too jarring --
            and windoor ~= nil then
            local windoorVol = (0.4 * windVol) - (0.005 * #windoors)
            playWind(windoor, true, windoorVol, 0.8)
        end
    end
end

-- Resolve data and play or remove wind sounds --
local function windCheck(e)
    -- Gets messy otherwise --
    local mp = tes3.mobilePlayer
    if (not mp) or (mp and (mp.waiting or mp.traveling)) then
        return
    end

    -- Getting rid of timers on cell check --
    if not interiorTimer then
        interiorTimer = timer.start({ duration = 1, iterations = -1, callback = updateInteriorBig, type = timer.real })
        interiorTimer:pause()
    else
        interiorTimer:pause()
    end

    cell = tes3.getPlayerCell()

    if (not cell) then
		debugLog("No cell detected. Returning.")
        sounds.remove { module = moduleName, volume = windVol }
        windPlaying = false
		return
	end
	debugLog("Cell: " .. cell.editorName)

    -- Determine if we're transitioning --
    local weather
    if e and e.to then
        weather = e.to
    else
        -- We need proper weather/cloudsSpeed resolution if cell is interior.
        -- Otherwise, WtC data won't update unless you step outside.
        if cell.isInterior then
            weather = tes3.getRegion({ useDoors = true }).weather
        else
            weather = WtC.currentWeather
        end
    end

    -- Bugger off if weather is blocked --
    if blockedWeathers[weather.index] then
        debugLog("Weather is blocked. Returning.")
        sounds.remove { module = moduleName, volume = windVol }
        windPlaying = false
        return
    end

    -- Get wind type after resolving clouds speed --
    local cloudsSpeed = weather.cloudsSpeed
    debugLog("Current clouds speed: " .. tostring(cloudsSpeed))
    windType = getWindType(cloudsSpeed)

    -- If it's super slow then bugger off, no sound for ya --
    if not windType then
        debugLog("Wind type is nil. Returning.")
        sounds.remove { module = moduleName, volume = windVol }
        windPlaying = false
        return
    end

    local useLast = (cellLast and common.checkCellDiff(cell, cellLast) == true and windType == windTypeLast) or false

    if not (windPlaying) or (windTypeLast ~= windType) or (common.checkCellDiff(cell, cellLast)) then

        if (cell.isOrBehavesAsExterior) then
            if useLast then
                -- Using the same track when entering int/ext in same area; time/weather change will randomise it again --
                debugLog("Found same cell. Using last sound.")
                sounds.removeImmediate { module = moduleName }
                playWind(nil, useLast, nil, nil)
            else
                debugLog("Found different exterior cell. Using new sound.")
                sounds.remove { module = moduleName, volume = windVol }
                playWind(nil, useLast, nil, nil)
            end
        else
            debugLog("Not in an exterior cell. Returning.")
            if not playInteriorWind then
                debugLog("Removing wind sound.")
                sounds.removeImmediate { module = moduleName }
                windPlaying = false
                return
            else
                debugLog("Playing interior wind sound.")
                sounds.removeImmediate { module = moduleName }
                if common.getCellType(cell, common.cellTypesSmall) == true
                    or common.getCellType(cell, common.cellTypesTent) == true then
                    debugLog("Found small interior cell. Playing interior loops.")
                    playWind(nil, useLast, 0.4 * windVol, 0.8)
                else
                    debugLog("Found big interior cell. Playing interior loops.")
                    windoors = nil
                    windoors = common.getWindoors(cell)
                    if windoors ~= nil then
                        local windoorVol = (0.4 * windVol) - (0.005 * #windoors)
                        for i, windoor in ipairs(windoors) do
                            sounds.removeImmediate { module = moduleName, reference = windoor }
                            if i == 1 then
                                playWind(windoor, useLast, windoorVol, 0.8)
                            else
                                playWind(windoor, true, windoorVol, 0.8)
                            end
                        end
                        interiorTimer:resume()
                    end
                end
            end
        end
    end
end

-- Reset on load --
local function onLoad()
    windPlaying = false
end

-- Check every half an hour --
local function runHourTimer()
    timer.start({ duration = 0.5, callback = windCheck, iterations = -1, type = timer.game })
end

-- Waiting/travelling check --
local function waitCheck(e)
    local element = e.element
    element:registerAfter("destroy", function()
        timer.start {
            type = timer.game,
            duration = 0.01,
            callback = windCheck
        }
    end)
end

-- Timer here so that sky textures can work ok... something fishy with weatherTransitionStarted event for sure --
local function transitionStartedWrapper()
    timer.start {
        duration = 0.1,
        type = timer.game,
        callback = windCheck
    }
end

WtC = tes3.worldController.weatherController

event.register("weatherChangedImmediate", windCheck, { priority = -100 })
event.register("weatherTransitionImmediate", windCheck, { priority = -100 })
event.register("weatherTransitionStarted", transitionStartedWrapper, { priority = -100 })
event.register("weatherTransitionFinished", windCheck, { priority = -100 })
event.register("load", onLoad)
event.register("loaded", runHourTimer, { priority = -160 })
event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = 10 })
event.register("cellChanged", windCheck, { priority = -100 })
