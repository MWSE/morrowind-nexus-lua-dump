local mistShader = {}

-- Imports
local shader = require("tew.Vapourmist.components.shader")
local util = require("tew.Vapourmist.components.util")
local debugLog = util.debugLog
local config = require("tew.Vapourmist.config")

-- Constants
local FOG_ID = "tew_mist"
local MAX_DISTANCE = 8192 * 3
local BASE_DEPTH = 8192 / 8
local TIMER_DURATION = 0.3

local FADE_SECONDS = 20 -- Fade duration in seconds for visual smoothness

local WtC = tes3.worldController.weatherController
local WorldC = tes3.worldController

local mistDensity = 0
local currentRadiusZ = BASE_DEPTH

local mistDeployed = false

local toWeather, postRainMist

local recolourRegistered

local conditionTimer, deployRainMistTimer, removeRainMistTimer

local wetWeathers = {
    ["Rain"] = true,
    ["Thunderstorm"] = true,
}

local radiusFactors = {
    ["Clear"] = 1.2,
    ["Cloudy"] = 1.2,
    ["Foggy"] = 1,
    ["Overcast"] = 1.2,
    ["Rain"] = 1,
    ["Thunderstorm"] = 1,
    ["Ashstorm"] = 1,
    ["Blight"] = 1,
    ["Snow"] = 1,
    ["Blizzard"] = 1,
}

local densities = {
    ["Clear"] = 11,
    ["Cloudy"] = 12,
    ["Foggy"] = 13,
    ["Overcast"] = 12,
    ["Rain"] = 10,
    ["Thunderstorm"] = 10,
    ["Ashstorm"] = 10,
    ["Blight"] = 10,
    ["Snow"] = 10,
    ["Blizzard"] = 10,
}

local fogParams = {
    color = tes3vector3.new(),
    center = tes3vector3.new(),

    radius = tes3vector3.new(
        MAX_DISTANCE,
        MAX_DISTANCE,
        BASE_DEPTH
    ),

    density = mistDensity,
}

-- Fade parameters

local fadeStart = 0
local fadeTarget = 0

local radiusFadeStart = BASE_DEPTH
local radiusFadeTarget = BASE_DEPTH

local fadeElapsed = 0
local fadeDuration = FADE_SECONDS

local isFading = false

-- Check if mist should appear

local function isAvailable(weather, gameHour)
    local weatherName = weather.name

    if config.blockedMist[weatherName] then
        return false
    end

    return
        (
            (
                (
                    gameHour > WtC.sunriseHour - 1
                    and gameHour < WtC.sunriseHour + 1.5
                )
                or
                (
                    gameHour >= WtC.sunsetHour - 0.4
                    and gameHour < WtC.sunsetHour + 2
                )
            )
            and not wetWeathers[weatherName]
        )
        or
        config.mistyWeathers[weatherName]
end

-- Colour helpers

local function getMistColourMix(fogComp, skyComp)
    return math.lerp(fogComp, skyComp, 0.2)
end

local function getModifiedColour(comp)
    return math.clamp(
        math.lerp(comp, 1.0, 0.013),
        0.03,
        0.9
    )
end

local function getOutputValues()
    local currentFogColor =
        WtC.currentFogColor:copy()

    local currentSkyColor =
        WtC.currentSkyColor:copy()

    local weatherColour = {
        r = getMistColourMix(
            currentFogColor.r,
            currentSkyColor.r
        ),

        g = getMistColourMix(
            currentFogColor.g,
            currentSkyColor.g
        ),

        b = getMistColourMix(
            currentFogColor.b,
            currentSkyColor.b
        ),
    }

    return tes3vector3.new(
        getModifiedColour(weatherColour.r),
        getModifiedColour(weatherColour.g),
        getModifiedColour(weatherColour.b)
    )
end

-- Start fade

local function startFade(
    targetDensity,
    targetRadiusFactor
)
    local targetRadius =
        BASE_DEPTH * targetRadiusFactor

    if
        fadeTarget == targetDensity
        and radiusFadeTarget == targetRadius
        and isFading
    then
        return
    end

    fadeStart = mistDensity
    fadeTarget = targetDensity

    radiusFadeStart = currentRadiusZ
    radiusFadeTarget = targetRadius

    fadeElapsed = 0
    isFading = true
end

-- Calculate mist Z using lowest third of statics

local function getMistPosition(cell)
    local zValues = {}

    for stat in cell:iterateReferences() do
        table.insert(zValues, stat.position.z)
    end

    if #zValues == 0 then
        return tes3.player.position.z
    end

    table.sort(zValues)

    local count = math.ceil(#zValues / 3)

    local sum = 0

    for i = 1, count do
        sum = sum + zValues[i]
    end

    return sum / count
end

-- Main simulate update

local function updateMist(e)
    local player = tes3.player

    if not player then
        return
    end

    local cell = player.cell

    if cell.isInterior then
        mistDensity = 0

        shader.deleteFog(FOG_ID)

        debugLog(
            "Cell is interior. Mist shader removed."
        )

        return
    end

    -- Smooth fade update
    if isFading then
        fadeElapsed = fadeElapsed + e.delta

        -- debugLog("fadeElapsed: " .. fadeElapsed)

        local progress =
            math.clamp(
                fadeElapsed / fadeDuration,
                0,
                1
            )

        -- debugLog("progress: " .. progress)

        mistDensity =
            math.lerp(
                fadeStart,
                fadeTarget,
                progress
            )

        currentRadiusZ =
            math.lerp(
                radiusFadeStart,
                radiusFadeTarget,
                progress
            )

        -- debugLog("mistDensity: " .. mistDensity)

        -- debugLog(
        --     "currentRadiusZ: "
        --     .. currentRadiusZ
        -- )

        if progress >= 1 then
            mistDensity = fadeTarget
            currentRadiusZ = radiusFadeTarget

            isFading = false

            if mistDensity <= 0.001 then
                shader.deleteFog(FOG_ID)

                mistDeployed = false

                return
            end
        end
    end

    local playerPos =
        tes3.mobilePlayer.position:copy()

    local mistCenter = tes3vector3.new(
        playerPos.x,
        playerPos.y,
        0
    -- getMistPosition(cell)
    )

    -- local currentWeather =
    --     toWeather or WtC.currentWeather

    fogParams.center = mistCenter

    fogParams.radius.z = currentRadiusZ

    fogParams.density = mistDensity

    fogParams.color = getOutputValues()

    -- debugLog(
    --     "Weather: "
    --     .. tostring(
    --         currentWeather and currentWeather.name
    --     )
    -- )

    -- debugLog(
    --     "Radius factor: "
    --     .. tostring(
    --         radiusFactors[currentWeather.name]
    --     )
    -- )

    -- debugLog(
    --     "Current radius Z: "
    --     .. tostring(currentRadiusZ)
    -- )

    -- debugLog(
    --     "Density: "
    --     .. tostring(mistDensity)
    -- )

    shader.createOrUpdateFog(
        FOG_ID,
        fogParams
    )
end

-- Deploy mist

function mistShader.deployMist()
    local targetDensity = densities[toWeather.name]

    if
        mistDeployed
        and fadeTarget == targetDensity
    then
        return
    end

    mistDeployed = true

    startFade(
        targetDensity,
        radiusFactors[toWeather.name] or 1
    )

    if not recolourRegistered then
        event.register(tes3.event.simulate, updateMist)

        recolourRegistered = true
    end
end

-- Fade removal

function mistShader.removeMist()
    if not mistDeployed and fadeTarget == 0 then
        return
    end

    local currentWeather =
        toWeather or WtC.currentWeather

    startFade(
        0,
        radiusFactors[currentWeather.name] or 1
    )
end

-- Immediate removal

function mistShader.removeMistImmediate()
    mistDeployed = false

    mistDensity = 0

    currentRadiusZ = BASE_DEPTH

    isFading = false

    fadeElapsed = 0

    fadeTarget = 0

    radiusFadeTarget = BASE_DEPTH

    shader.deleteFog(FOG_ID)

    debugLog(
        "Mist shader removed immediately."
    )
end

-- Condition check

function mistShader.conditionCheck(options)
    debugLog("Starting condition check.")

    local cell = tes3.getPlayerCell()

    if not cell then
        return
    end

    local options = options or nil

    if
        options
        and options.immediate
        and not isAvailable(
            options.to,
            options.gameHour
        )
    then
        debugLog(
            "Weather changed immediate "
            .. "but mist not available."
        )

        mistShader.removeMistImmediate()
    end

    if not cell.isOrBehavesAsExterior then
        debugLog(
            "Interior detected, removing mist."
        )

        mistShader.removeMistImmediate()

        return
    end

    toWeather =
        WtC.nextWeather
        or WtC.currentWeather

    local gameHour = WorldC.hour.value

    if
        isAvailable(toWeather, gameHour)
        or postRainMist
    then
        debugLog("Deploying mist...")

        mistShader.deployMist()
    else
        debugLog("Removing mist...")

        mistShader.removeMist()
    end
end

-- Weather change events

function mistShader.onWeatherChanged(e)
    local fromWeather = e.from

    toWeather = e.to

    if
        wetWeathers[fromWeather.name]
        and not config.blockedMist[toWeather.name]
    then
        debugLog("Adding post-rain mist.")

        deployRainMistTimer = timer.start {
            type = timer.game,
            iterations = 1,
            duration = 0.06,

            callback = function()
                postRainMist = true

                mistDensity = 0

                updateMist({ delta = 0 })

                mistShader.conditionCheck()
            end,
        }

        removeRainMistTimer = timer.start {
            type = timer.game,
            iterations = 1,
            duration = 0.6,

            callback = function()
                postRainMist = false
            end,
        }
    end

    mistShader.conditionCheck()
end

function mistShader.onWeatherChangedImmediate(e)
    local gameHour = WorldC.hour.value

    mistShader.conditionCheck({
        immediate = true,
        to = e.to,
        gameHour = gameHour,
    })
end

-- Wait menu handling

local function waitingCheck()
    debugLog("Starting waiting check.")

    local mp = tes3.mobilePlayer

    local gameHour = WorldC.hour.value

    if
        not mp
        or mp.waiting
        or mp.sleeping
        or mp.traveling
    then
        toWeather =
            WtC.nextWeather
            or WtC.currentWeather

        if not isAvailable(toWeather, gameHour) then
            debugLog(
                "Player waiting/traveling "
                .. "and mist not available."
            )

            mistShader.removeMistImmediate()
        end
    end

    mistShader.conditionCheck()
end

function mistShader.onWaitMenu(e)
    local element = e.element

    element:registerAfter(
        tes3.uiEvent.destroy,
        function()
            waitingCheck()
        end
    )
end

-- Initialization

function mistShader.onLoaded()
    if not tes3.player then
        return
    end

    if not recolourRegistered then
        event.register(tes3.event.simulate, updateMist)

        recolourRegistered = true
    end

    conditionTimer = timer.start {
        duration = TIMER_DURATION,
        callback = mistShader.conditionCheck,
        iterations = -1,
        type = timer.game,
        persist = false,
    }

    mistShader.conditionCheck()
end

function mistShader.removeRegisters()

end

function mistShader.cleanup()
    mistShader.removeMistImmediate()
    util.removeTimers({ conditionTimer, deployRainMistTimer, removeRainMistTimer })
    if recolourRegistered then
        event.unregister(tes3.event.simulate, updateMist)
        recolourRegistered = false
    end
    mistDensity = 0
    currentRadiusZ = BASE_DEPTH
    mistDeployed = false
    toWeather, postRainMist = nil, nil
    conditionTimer, deployRainMistTimer, removeRainMistTimer = nil, nil, nil
end

return mistShader
