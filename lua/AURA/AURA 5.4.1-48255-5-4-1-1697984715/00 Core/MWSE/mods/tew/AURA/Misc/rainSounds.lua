local cellData = require("tew.AURA.cellData")
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local soundData = require("tew.AURA.soundData")

local debugLog = common.debugLog

local WtC

local vanillaRain = tes3.getSound("Rain")
local vanillaStorm = tes3.getSound("rain heavy")

-- Resolve rain type per particle amount set in Watch the Skies --
local function getRainType(particleAmount)
    if particleAmount < 2000 then
        return "light"
    elseif particleAmount < 2600 then
        return "medium"
    elseif particleAmount <= 5000 then
        return "heavy"
    else
        return "light"
    end
end

-- Set proper rain sounds --
local function changeRainSounds()

    -- Resolve max particles --
    local rainy = WtC.weathers[5]
    local rainyType = getRainType(rainy.maxParticles)
    local stormy = WtC.weathers[6]
    local stormyType = getRainType(stormy.maxParticles)

    debugLog("Rain type: " .. rainyType)
    debugLog("Storm type: " .. stormyType)

    cellData.rainType[4] = rainyType
    cellData.rainType[5] = stormyType

    -- Remove vanilla sound if present, the next step will add the new sound --
    if WtC.currentWeather
    and WtC.currentWeather.rainLoopSound
    and (WtC.currentWeather.rainLoopSound == vanillaRain
        or WtC.currentWeather.rainLoopSound == vanillaStorm)
    and WtC.currentWeather.rainLoopSound:isPlaying()
    then
        WtC.currentWeather.rainLoopSound:stop()
    end

    -- Load sounds --
    rainy.rainLoopSound = soundData.rainLoops["Rain"][rainyType]
    stormy.rainLoopSound = soundData.rainLoops["Thunderstorm"][stormyType]

    -- Also change interior rain sounds --
    if config.moduleInteriorWeather then
        for interiorType, array in pairs(soundData.interiorWeather) do
            array[4] = soundData.interiorRainLoops[interiorType][rainyType]
            array[5] = soundData.interiorRainLoops[interiorType][stormyType]
        end
    end

end

WtC = tes3.worldController.weatherController

-- Also make sure we're setting these on loaded --
event.register("loaded", changeRainSounds, { priority = -233 })
-- Use custom event from Watch the Skies - no much sense otherwise, who else changes these? :-) --
event.register("WtS:maxParticlesChanged", changeRainSounds, { priority = -233 })