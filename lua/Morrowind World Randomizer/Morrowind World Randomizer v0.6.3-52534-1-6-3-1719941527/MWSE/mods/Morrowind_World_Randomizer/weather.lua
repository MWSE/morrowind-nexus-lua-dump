local config = include("Morrowind_World_Randomizer.config")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local log = include("Morrowind_World_Randomizer.log")

local this = {}

---@class mwr.weatherColorPreset
---@field ambientDayColor tes3vector3
---@field ambientNightColor tes3vector3
---@field ambientSunriseColor tes3vector3
---@field ambientSunsetColor tes3vector3
---@field fogDayColor tes3vector3
---@field fogNightColor tes3vector3
---@field fogSunriseColor tes3vector3
---@field fogSunsetColor tes3vector3
---@field skyDayColor tes3vector3
---@field skyNightColor tes3vector3
---@field skySunriseColor tes3vector3
---@field skySunsetColor tes3vector3
---@field sunDayColor tes3vector3
---@field sundiscSunsetColor tes3vector3
---@field sunNightColor tes3vector3
---@field sunSunriseColor tes3vector3
---@field sunSunsetColor tes3vector3

---@class mwr.weatherColors
---@field day tes3vector3
---@field night tes3vector3
---@field sunrise tes3vector3
---@field sunset tes3vector3

---@type mwr.weatherColorPreset[]
this.basePresets = {}
---@type mwr.weatherColors
this.baseColors = {}

function this.getRandomWeatherChances()
    local weatherChances = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local sum = 100
    while sum > 0 do
        local pos = math.random(1, 10)
        local val = math.random(1, math.min(sum, 50))
        weatherChances[pos] = weatherChances[pos] + val
        sum = sum - val
    end
    return weatherChances
end

---@param region tes3region
function this.randomizeChances(region, chances)
    if not region and not this.config.data.weather.randomize then return end
    local weatherChances = chances or this.getRandomWeatherChances()
    region.weatherChanceAsh = weatherChances[1]
    region.weatherChanceBlight = weatherChances[2]
    region.weatherChanceBlizzard = weatherChances[3]
    region.weatherChanceClear = weatherChances[4]
    region.weatherChanceCloudy = weatherChances[5]
    region.weatherChanceFoggy = weatherChances[6]
    region.weatherChanceOvercast = weatherChances[7]
    region.weatherChanceRain = weatherChances[8]
    region.weatherChanceSnow = weatherChances[9]
    region.weatherChanceThunder = weatherChances[10]
end

function this.newRandomColorPreset()
    local configData = config.data.weather
    local randomColor = function()
        return tes3vector3.new(math.clamp(math.random(), configData.base.color.min, configData.base.color.max),
            math.clamp(math.random(), configData.base.color.min, configData.base.color.max),
            math.clamp(math.random(), configData.base.color.min, configData.base.color.max))
    end
    ---@type mwr.weatherColorPreset
    local preset = {}
    local day = randomColor()
    local night = randomColor()
    local sunrise = randomColor()
    local sunset = randomColor()
    ---@type mwr.weatherColors
    local colors = {day = day, night = night, sunrise = sunrise, sunset = sunset}
    preset.ambientDayColor = day
    preset.ambientNightColor = night
    preset.ambientSunriseColor = sunrise
    preset.ambientSunsetColor = sunset
    preset.fogDayColor = day
    preset.fogNightColor = night
    preset.fogSunriseColor = sunrise
    preset.fogSunsetColor = sunset
    preset.skyDayColor = day
    preset.skyNightColor = night
    preset.skySunriseColor = sunrise
    preset.skySunsetColor = sunset
    preset.sunDayColor = day
    preset.sundiscSunsetColor = sunset
    preset.sunNightColor = night
    preset.sunSunriseColor = sunrise
    preset.sunSunsetColor = sunset
    return preset, colors
end

for _, id in pairs(tes3.weather) do
    this.basePresets[id], this.baseColors[id] = this.newRandomColorPreset()
end

---@param weather tes3weather|tes3weatherSnow|tes3weatherBlight|tes3weatherOvercast|tes3weatherThunder|tes3weatherCloudy|tes3weatherRain|tes3weatherClear|tes3weatherFoggy|tes3weatherAsh
---@param preset mwr.weatherColorPreset|nil
function this.setWeatherBase(weather, preset)
    if not preset then preset = this.basePresets[weather.index] end
    local updateRGB = function(c, value)
        c.r = value.r
        c.g = value.g
        c.b = value.b
    end
    updateRGB(weather.ambientDayColor, preset.ambientDayColor)
    updateRGB(weather.ambientNightColor, preset.ambientNightColor)
    updateRGB(weather.ambientSunriseColor, preset.ambientSunriseColor)
    updateRGB(weather.ambientSunsetColor, preset.ambientSunsetColor)
    updateRGB(weather.fogDayColor, preset.fogDayColor)
    updateRGB(weather.fogNightColor, preset.fogNightColor)
    updateRGB(weather.fogSunriseColor, preset.fogSunriseColor)
    updateRGB(weather.fogSunsetColor, preset.fogSunsetColor)
    updateRGB(weather.skyDayColor, preset.skyDayColor)
    updateRGB(weather.skyNightColor, preset.skyNightColor)
    updateRGB(weather.skySunriseColor, preset.skySunriseColor)
    updateRGB(weather.skySunsetColor, preset.skySunsetColor)
    updateRGB(weather.sunDayColor, preset.sunDayColor)
    updateRGB(weather.sundiscSunsetColor, preset.sundiscSunsetColor)
    updateRGB(weather.sunNightColor, preset.sunNightColor)
    updateRGB(weather.sunSunriseColor, preset.sunSunriseColor)
    updateRGB(weather.sunSunsetColor, preset.sunSunsetColor)
end

---@param c tes3vector3
function this.transitColor(c, value)
    local configData = config.data.weather
    if not value then value = configData.base.transitionValue end
    c.r = math.clamp(c.r - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max)
    c.g = math.clamp(c.g - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max)
    c.b = math.clamp(c.b - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max)
end

---@return tes3vector3
function this.getTransitedColor(c, value)
    local configData = config.data.weather
    if not value then value = configData.base.transitionValue end
    return tes3vector3.new(math.clamp(c.r - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max),
        math.clamp(c.g - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max),
        math.clamp(c.b - value + 2 * math.random() * value, configData.base.color.min, configData.base.color.max))
end

---@param colors mwr.weatherColors
function this.transitWeatherColors(colors)
    for _, val in pairs(colors) do
        this.transitColor(val)
    end
end

---@param preset mwr.weatherColorPreset
---@param colors mwr.weatherColors
function this.transitPresetColors(preset, colors)
    local configData = config.data.weather
    local variationValue = configData.base.transitionValue / 2
    local day = colors.day
    local night = colors.night
    local sunrise = colors.sunrise
    local sunset = colors.sunset
    preset.ambientDayColor = this.getTransitedColor(day, variationValue)
    preset.ambientNightColor = this.getTransitedColor(night, variationValue)
    preset.ambientSunriseColor = this.getTransitedColor(sunrise, variationValue)
    preset.ambientSunsetColor = this.getTransitedColor(sunset, variationValue)
    preset.fogDayColor = this.getTransitedColor(day, variationValue)
    preset.fogNightColor = this.getTransitedColor(night, variationValue)
    preset.fogSunriseColor = this.getTransitedColor(sunrise, variationValue)
    preset.fogSunsetColor = this.getTransitedColor(sunset, variationValue)
    preset.skyDayColor = this.getTransitedColor(day, variationValue)
    preset.skyNightColor = this.getTransitedColor(night, variationValue)
    preset.skySunriseColor = this.getTransitedColor(sunrise, variationValue)
    preset.skySunsetColor = this.getTransitedColor(sunset, variationValue)
    preset.sunDayColor = this.getTransitedColor(day, variationValue)
    preset.sundiscSunsetColor = this.getTransitedColor(sunset, variationValue)
    preset.sunNightColor = this.getTransitedColor(night, variationValue)
    preset.sunSunriseColor = this.getTransitedColor(sunrise, variationValue)
    preset.sunSunsetColor = this.getTransitedColor(sunset, variationValue)
end

return this