-- Volume Wonderland - A place for everything volume-related --

local this = {}

local cellData = require("tew.AURA.cellData")
local common = require("tew.AURA.common")
local defaults = require("tew.AURA.defaults")
local moduleData = require("tew.AURA.moduleData")
local soundData = require("tew.AURA.soundData")
local debugLog = common.debugLog

local MAX = 1
local MIN = 0

function this.setVolume(track, volume)
    local magicMaths = math.clamp(math.round(volume, 2), MIN, MAX)
    debugLog(string.format("Setting volume for track %s to %s", track.id, magicMaths))
    track.volume = magicMaths
end

function this.getCurrentWeatherConfig(moduleName)
    local regionObject = common.getRegion()

    if not regionObject then return {} end

    local weather = regionObject.weather.index
    local rainType = cellData.rainType[weather] or "light"
    local interiorType = common.getInteriorType(cellData.cell)
    local soundConfig = moduleData[moduleName].soundConfig

    return (soundConfig[interiorType] and soundConfig[interiorType][weather])
    or (soundConfig[rainType] and soundConfig[rainType][weather])
    or {}
end

function this.getPitch(moduleName)
    local cwConfig = this.getCurrentWeatherConfig(moduleName)
    local pitch = cwConfig.pitch or MAX

    if (not cellData.cell) or (cellData.cell.isOrBehavesAsExterior) then pitch = MAX end

    if cellData.playerUnderwater then pitch = 0.5 end

    debugLog(string.format("Got pitch for %s: %s", moduleName, pitch))
    return pitch
end

function this.getVolume(moduleName, conf)
    local volume = MAX
    local config = conf or mwse.loadConfig("AURA", defaults)
    local moduleVol = config.volumes.modules[moduleName].volume / 100
    local cwConfig = this.getCurrentWeatherConfig(moduleName)
    local weatherMult = cwConfig.mult or 1

    local regionObject = common.getRegion()
    local weather = regionObject and regionObject.weather.index
    local blockedWeathers = moduleData[moduleName].blockedWeathers
    local isEligibleWeather = (weather) and not (blockedWeathers and blockedWeathers[weather])

    local interiorType = common.getInteriorType(cellData.cell)
    local rainType = cellData.rainType[weather] or "light"
    local windoorsMult = (moduleData[moduleName].playWindoors == true) and 0.005 or 0

    if not isEligibleWeather then
        debugLog(string.format("[%s] Not an eligible weather: %s", moduleName, weather))
        volume = 0
    else
        debugLog(string.format("[%s] Weather: %s. Applying weatherMult: %s", moduleName, weather, weatherMult))
        volume = moduleVol * weatherMult
    end

    if cellData.cell.isInterior
    and (moduleName == "interiorWeather")
    and (interiorType == "sma")
    and common.isOpenPlaza(cellData.cell) then
        if isEligibleWeather and (weather == 6 or weather == 7) then
            volume = 0
        else
            debugLog(string.format("[%s] Applying open plaza volume boost.", moduleName))
            volume = math.min(volume + 0.2, 1)
            this.setVolume(tes3.getSound("Rain"), 0)
            this.setVolume(tes3.getSound("rain heavy"), 0)
        end
    end

    if cellData.cell.isInterior then
        if (interiorType == "big") then
            debugLog(string.format("[%s] Applying big interior mult.", moduleName))
            volume = (config.volumes.modules[moduleName].big * volume) - (windoorsMult * #cellData.windoors)
        elseif (interiorType == "sma") or (interiorType == "ten") then
            debugLog(string.format("[%s] Applying small interior mult.", moduleName))
            volume = config.volumes.modules[moduleName].sma * volume
        end
    end

    if cellData.playerUnderwater then
        debugLog(string.format("[%s] Applying underwater nerf.", moduleName))
        volume = config.volumes.modules[moduleName].und * volume
    end

    volume = math.max(math.floor(volume * 100) / 100, 0)
    debugLog(string.format("Got volume for %s: %s", moduleName, volume))
    return volume
end

function this.adjustVolume(options)
    local moduleName = options.module
    local track = options.track or moduleData[moduleName].new
    local targetRef = options.reference
    local targetVolume = options.volume
    local config = options.config
    local inOrOut = options.inOrOut or ""
    local function adjust(reference)
        if not (track and reference) then return end
        if tes3.getSoundPlaying{sound = track, reference = reference} then
            local volume = targetVolume or this.getVolume(moduleName, config)
            local msgPrefix = string.format("Adjusting volume %s", inOrOut):gsub("%s+$", "")
            debugLog(string.format("%s for module %s: %s -> %s | %.2f", msgPrefix, moduleName, track.id, tostring(reference), volume))
            tes3.adjustSoundVolume{
                sound = track,
                reference = reference,
                volume = volume,
            }
            moduleData[moduleName].lastVolume = volume
        end
    end
    local function adjustAllWindoors()
        debugLog("Adjusting all windoors.")
        for _, windoor in ipairs(cellData.windoors) do
            adjust(windoor)
        end
    end

    if targetRef then
        adjust(targetRef)
    elseif moduleData[moduleName].playWindoors and not table.empty(cellData.windoors) then
        adjustAllWindoors()
    else
        adjust(moduleData[moduleName].newRef)
    end
end

function this.setConfigVolumes()
    local config = mwse.loadConfig("AURA", defaults)

    debugLog("Setting config weather volumes.")

    for _, sound in pairs(soundData.weatherLoops) do
        local id = sound.id:lower()
        if id == "rain" or id == "rain heavy" then
            this.setVolume(sound, config.rainSounds and 0 or sound.volume)
        elseif id == "ashstorm" then
            this.setVolume(sound, config.volumes.extremeWeather["Ashstorm"] / 100)
        elseif id == "blight" then
            this.setVolume(sound, config.volumes.extremeWeather["Blight"] / 100)
        elseif id == "bm blizzard" then
            this.setVolume(sound, config.volumes.extremeWeather["Blizzard"] / 100)
        end
    end

    for weatherName, data in pairs(soundData.rainLoops) do
        for rainType, track in pairs(data) do
            if track then
                this.setVolume(track, config.volumes.rain[weatherName][rainType] / 100)
            end
        end
    end
end

function this.printConfigVolumes()
    local config = mwse.loadConfig("AURA", defaults)
    debugLog("Printing config volumes.")
    for configKey, volumeTable in pairs(config.volumes) do
        if configKey == "modules" then
            for moduleName, moduleVol in pairs(volumeTable) do
                debugLog(string.format("[%s] vol: %s, big: %s, sma: %s, und: %s", moduleName, moduleVol.volume, moduleVol.big, moduleVol.sma, moduleVol.und))
            end
        elseif configKey == "rain" then
            for weatherName, weatherData in pairs(volumeTable) do
                debugLog(string.format("[%s] light: %s, medium: %s, heavy: %s", weatherName, weatherData.light, weatherData.medium, weatherData.heavy))
            end
        else
            for volumeTableKey, volumeTableValue in pairs(volumeTable) do
                debugLog(string.format("[%s] %s: %s", configKey, volumeTableKey, volumeTableValue))
            end
        end
    end
end

event.register(tes3.event.load, this.setConfigVolumes)

return this