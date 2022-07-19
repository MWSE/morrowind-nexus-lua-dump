local modversion = require("tew.AURA.version")
local version = modversion.version
local config = require("tew.AURA.config")
local sounds=require("tew.AURA.sounds")
local common=require("tew.AURA.common")

local debugLog = common.debugLog

local WtC

local rainLoops = {
    ["Rain"] = {
        ["light"] = "tew_rain_light",
        ["medium"] = "tew_rain_medium",
        ["heavy"] = "tew_rain_heavy"
    },
    ["Thunderstorm"] = {
        ["light"] = "tew_thunder_light",
        ["medium"] = "tew_thunder_medium",
        ["heavy"] = "tew_thunder_heavy"
    }
}

local interiorRainLoops = {
    ["big"] = {
        ["light"] = "tew_b_rainlight",
        ["medium"] = "tew_b_rainmedium",
        ["heavy"] = "tew_b_rainheavy",
        ["thunder"] = "tew_b_thunderheavy"
    },
    ["sma"] = {
        ["light"] = "tew_s_rainlight",
        ["medium"] = "tew_s_rainmedium",
        ["heavy"] = "tew_s_rainheavy",
        ["thunder"] = "tew_s_thunderheavy"
    },
    ["ten"] = {
        ["light"] = "tew_t_rainlight",
        ["medium"] = "tew_t_rainmedium",
        ["heavy"] = "tew_t_rainheavy",
        ["thunder"] = "tew_t_thunderheavy"
    }
}

local function getRainType(particleAmount)
    if particleAmount < 500 then
        return "light"
    elseif particleAmount < 950 then
        return "medium"
    elseif particleAmount <= 1700 then
        return "heavy"
    else
        return "light"
    end
end

local function changeRainSounds(e)
    if (WtC.currentWeather.name == "Rain" or WtC.currentWeather.name == "Thunderstorm") or (WtC.nextWeather and (WtC.nextWeather.name == "Rain" or WtC.nextWeather.name == "Thunderstorm")) then
        local weather
        if e and e.to then
            weather = e.to
        else
            weather = WtC.currentWeather
        end

        debugLog("Current particle amount: "..tostring(weather.maxParticles))

        local rainy = WtC.weathers[5]
        local rainyType = getRainType(rainy.maxParticles)
        local stormy = WtC.weathers[6]
        local stormyType = getRainType(stormy.maxParticles)

        debugLog("Rain type: "..rainyType)
        debugLog("Storm type: "..stormyType)

        if WtC.currentWeather.name == "Rain" then
            rainy.rainLoopSound = tes3.getSound(rainLoops["Rain"][rainyType])
        elseif WtC.currentWeather.name == "Thunderstorm" then
            rainy.rainLoopSound = tes3.getSound(rainLoops["Thunderstorm"][rainyType])
        end

        if weather.maxParticles then
            local interiorRainType = getRainType(weather.maxParticles)
            if config.moduleInteriorWeather then
                if weather.name == "Thunderstorm" then interiorRainType = "thunder" end
                for interiorType, array in pairs(sounds.interiorWeather) do
                    array[4] = tes3.getSound(interiorRainLoops[interiorType][interiorRainType])
                    array[5] = tes3.getSound(interiorRainLoops[interiorType][interiorRainType])
                end
            end
        end
	end
end

local function rainStartCheck(e)
    if e.to.name == "Rain" or e.to.name == "Thunderstorm" then
        changeRainSounds(e)
    end
end

print("[AURA "..version.."] Rain sounds initialised.")
WtC=tes3.worldController.weatherController
event.register("weatherChangedImmediate", changeRainSounds, {priority=-233})
event.register("weatherTransitionImmediate", changeRainSounds, {priority=-233})
event.register("weatherTransitionStarted", rainStartCheck, {priority=-233})