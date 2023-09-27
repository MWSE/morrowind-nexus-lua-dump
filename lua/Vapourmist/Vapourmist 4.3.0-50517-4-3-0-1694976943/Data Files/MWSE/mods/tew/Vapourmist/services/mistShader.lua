-- Imports
local shader = require("tew.Vapourmist.components.shader")
local util = require("tew.Vapourmist.components.util")
local debugLog = util.debugLog
local config = require("tew.Vapourmist.config")

-- Constants
local FOG_ID = "tew_mist"
local MAX_DISTANCE = 8192 * 3
local BASE_DEPTH = 8192 / 10
local TIMER_DURATION = 0.3
local FADE_DURATION = 0.02
local STEPS = 100

local WtC = tes3.worldController.weatherController
local WorldC = tes3.worldController
local mistDensity = 0
local mistDeployed = false

local toWeather, postRainMist, lastRegion, fogTimer, fadeInTimer, fadeOutTimer, fadeOutRemoveTimer

local wetWeathers = {
    ["Rain"] = true,
    ["Thunderstorm"] = true
}

local radiusFactors = {
    ["Clear"] = 1.4,
    ["Cloudy"] = 1.3,
    ["Foggy"] = 1,
    ["Overcast"] = 1.2,
    ["Rain"] = 1,
    ["Thunderstorm"] = 1,
    ["Ashstorm"] = 1,
    ["Blight"] = 1,
    ["Snow"] = 1,
    ["Blizzard"] = 1
}

local densities = {
    ["Clear"] = 12,
    ["Cloudy"] = 13,
    ["Foggy"] = 12,
    ["Overcast"] = 11,
    ["Rain"] = 10,
    ["Thunderstorm"] = 10,
    ["Ashstorm"] = 10,
    ["Blight"] = 10,
    ["Snow"] = 10,
    ["Blizzard"] = 10
}

local mistShader = {}

local fogParams = {
    color = tes3vector3.new(),
    center = tes3vector3.new(),
    radius = tes3vector3.new(MAX_DISTANCE, MAX_DISTANCE, BASE_DEPTH),
    density = mistDensity,
}

local function stopTimer(timerVal)
    if timerVal and timerVal.state ~= timer.expired then
        timerVal:pause()
        timerVal:cancel()
        debugLog("Timer paused and cancelled.")
    end
end

local function isAvailable(weather, gameHour)
    local weatherName = weather.name

    if config.blockedMist[weatherName] then return false end

    return
    ((
        (gameHour > WtC.sunriseHour - 1 and gameHour < WtC.sunriseHour + 1.5)
    or
        (gameHour >= WtC.sunsetHour - 0.4 and gameHour < WtC.sunsetHour + 2))
    and not
        wetWeathers[weatherName])
    or
    (
        config.mistyWeathers[weatherName]
    )
end

local function getMistColourMix(fogComp, skyComp)
    return math.lerp(fogComp, skyComp, 0.1)
end

local function getModifiedColour(comp)
    return math.clamp(math.lerp(comp, 1.0, 0.012), 0.03, 0.9)
end

-- Calculate output colours from current fog colour --
local function getOutputValues()
    local currentFogColor = WtC.currentFogColor:copy()
    local currentSkyColor = WtC.currentSkyColor:copy()
    local weatherColour = {
        r = getMistColourMix(currentFogColor.r, currentSkyColor.r),
        g = getMistColourMix(currentFogColor.g, currentSkyColor.g),
        b = getMistColourMix(currentFogColor.b, currentSkyColor.b)
    }

    return tes3vector3.new(
    getModifiedColour(weatherColour.r),
    getModifiedColour(weatherColour.g),
    getModifiedColour(weatherColour.b)
)
end

local function fadeIn()
    local density = densities[toWeather.name]
    if mistDensity >= density then
        mistDensity = density
        return
    end
    mistDensity = mistDensity + (density/STEPS)
end

local function fadeOut()
    local density = densities[toWeather.name]
    if mistDensity <= 0 then
        mistDensity = 0
        return
    end
    mistDensity = mistDensity - (density/STEPS)
end

local function updateMist()
    local player = tes3.player
    if not player then return end
    if player.cell.isInterior then
        return
    end

    local playerPos = tes3.mobilePlayer.position:copy()

    local mistCenter = tes3vector3.new(
        (playerPos.x),
        (playerPos.y),
        0
    )

    fogParams.radius.z = BASE_DEPTH * radiusFactors[toWeather.name]
    fogParams.density = mistDensity
    fogParams.center = mistCenter
    fogParams.color = getOutputValues()
    shader.createOrUpdateFog(FOG_ID, fogParams)
end

function mistShader.onLoaded()
    if not tes3.player then return end

    fogTimer = timer.start{
        iterations = -1,
        duration = 0.01,
        callback = updateMist,
        type = timer.game,
        persist = false
    }

    timer.start{
		duration = TIMER_DURATION,
		callback = mistShader.conditionCheck,
		iterations = -1,
		type = timer.game,
		persist = false
	}
    mistShader.conditionCheck()
end

function mistShader.removeMist()
    stopTimer(fadeOutTimer)
    stopTimer(fadeOutRemoveTimer)
    stopTimer(fadeInTimer)
    mistDensity = 0
    shader.deleteFog(FOG_ID)
    debugLog("Mist shader removed.")
end

local function waitingCheck()
	debugLog("Starting waiting check.")
	local mp = tes3.mobilePlayer
    local gameHour = WorldC.hour.value
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		toWeather = WtC.nextWeather or WtC.currentWeather
		if not isAvailable(toWeather, gameHour) then
			debugLog("Player waiting or travelling and mist not available.")
			mistShader.removeMist()
		end
	end
	mistShader.conditionCheck()
end

function mistShader.onWaitMenu(e)
	local element = e.element
	element:registerAfter(tes3.uiEvent.destroy, function()
		waitingCheck()
	end)
end

function mistShader.onWeatherChanged(e)
    local fromWeather = e.from
    toWeather = e.to

	if wetWeathers[fromWeather.name] and config.blockedMist[toWeather.name] ~= true then
		debugLog("Adding post-rain mistShader.")

		-- Slight offset so it makes sense --
		timer.start {
			type = timer.game,
			iterations = 1,
			duration = 0.06,
			callback = function()
                postRainMist = true
                mistDensity = 0
                updateMist()
                mistShader.conditionCheck()
            end
		}

        timer.start {
			type = timer.game,
			iterations = 1,
			duration = 1,
			callback = function()
                postRainMist = false
            end
		}
	end
end

function mistShader.immediateCheck()
    local region = tes3.getPlayerCell().region

    if (lastRegion ~= region) or (not region) then
        debugLog("Player switched regions.")
        mistShader.removeMist()
        lastRegion = region
        return
    end
    lastRegion = region
end

function mistShader.onWeatherChangedImmediate(e)
    local gameHour = WorldC.hour.value
    if not isAvailable(e.to, gameHour) then
        debugLog("Weather changed immediate but mist not available.")
        mistShader.removeMist()
        return
    end
    mistShader.immediateCheck()
end

function mistShader.conditionCheck()
    debugLog("Starting condition check.")
    local cell = tes3.getPlayerCell()
    if not cell then return end
    if not cell.isOrBehavesAsExterior then
        fogTimer:pause()
        shader.deleteFog(FOG_ID)
    end

    mistShader.immediateCheck()

    toWeather = WtC.nextWeather or WtC.currentWeather
    local gameHour = WorldC.hour.value

    if isAvailable(toWeather, gameHour) or postRainMist then
        if not mistDeployed then
            debugLog("Mist available.")
            updateMist()
            fogTimer:resume()
            stopTimer(fadeOutTimer)
            stopTimer(fadeOutRemoveTimer)
            fadeInTimer = timer.start{
                duration = FADE_DURATION,
                callback = fadeIn,
                iterations = STEPS,
                type = timer.game,
                persist = false
            }
            mistDeployed = true
        end
    else
        if mistDeployed then
            debugLog("Mist not available.")
            stopTimer(fadeInTimer)
            fadeOutTimer = timer.start{
                duration = FADE_DURATION,
                callback = fadeOut,
                iterations = STEPS,
                type = timer.game,
                persist = false
            }
            fadeOutRemoveTimer = timer.start{
                duration = (FADE_DURATION * STEPS) + FADE_DURATION,
                callback = mistShader.removeMist,
                iterations = 1,
                type = timer.game,
                persist = false
            }
            mistDeployed = false
        end
    end
end

return mistShader
