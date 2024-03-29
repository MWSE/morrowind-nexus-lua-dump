--[[
    Wetness mechanics
]]--
local this = {}
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("wetness")
local config = require("mer.ashfall.config").config
local wetness = common.staticConfigs.conditionConfig.wetness

--register temp effects
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("wetTemp")
temperatureController.registerRateMultiplier{ id = "wetCoolingRate", coolingOnly = true }
temperatureController.registerRateMultiplier{ id = "wetWarmingRate", warmingOnly = true }



--How much rain and thunder increase wetness per game hour (without armor
local rainEffect = 250
local thunderEffect = 600
local DRYING_MULTI = 150 --dry per hour at max heat

--Boundaries for wetEffects
this.dampLevel = common.staticConfigs.conditionConfig.wetness.states.damp.min
this.wetLevel = common.staticConfigs.conditionConfig.wetness.states.wet.min
this.soakedLevel = common.staticConfigs.conditionConfig.wetness.states.soaked.min

--Height at which Player gets wetEfects
local soakedHeight = 110

--How Cold 100% wetness is
local wetTempMax = -35
function this.checkForShelter(e)
    local ref = e and e.reference or tes3.player
    logger:trace("Checking for Shelter")
    if common.helper.getInTent() then
        common.data.isSheltered = true
        return
    end

    local sheltered = common.helper.checkRefSheltered(ref)
    if sheltered ~= nil then
        common.data.isSheltered = sheltered
    end
end
event.register("Ashfall:CheckForShelter", this.checkForShelter)
event.register(tes3.event.loaded, function()
    logger:debug("Starting shelter timer")
    timer.start{
        duration = 1,
        iterations = -1,
        type = timer.simulate,
        callback = this.checkForShelter
    }
end)

--[[
    Called by tempTimer
]]--
function this.calculateWetTemp(interval)
    if not common.data then
        return
    end
    --Check if Ashfall is disabled
    if not config.enableTemperatureEffects then
        common.data.wetness = 0
        common.data.wetTemp = 0
        common.data.wetCoolingRate = 1
        common.data.wetWarmingRate = 1
        return
    end
    local currentWetness = wetness:getValue()

    --Check if player is submerged
    -- does not care about coverage
    local cell = tes3.getPlayerCell()
    if cell.hasWater then
        local heightBelowWater = common.helper.getDepthUnderwater(tes3.player)
        local minWetness = math.remap(heightBelowWater, 0, soakedHeight, 0, 100)
        minWetness = math.clamp(minWetness, 0, 100)
        currentWetness = math.max(minWetness, currentWetness)
    end

    --increase wetness if it's raining, otherwise reduce wetness over time
    -- wetness decreased by coverage
    local weather = tes3.getCurrentWeather()
    local playerTemp = common.staticConfigs.conditionConfig.temp:getValue()

    local coverage = math.remap( common.data.coverageRating, 0, 1,  0, 0.85 )

    local isSheltered = common.data.isSheltered or common.helper.getInside(tes3.player)
    local isRaining = weather and weather.rainActive == true

    --Drying off
    if isSheltered or not isRaining then
        local dryCoverageEffect = math.remap(common.data.coverageRating, 0, 1.0, 1.0, 0.5)
        local tempMultiplier = math.remap(math.max(playerTemp, 0), 0, 100, 1.0, 3.0)
        local dryChange = ( tempMultiplier * interval * dryCoverageEffect * DRYING_MULTI )
        currentWetness = currentWetness - dryChange
    else
        --Raining
        if weather.index == tes3.weather.rain then
            currentWetness = currentWetness + rainEffect * interval * ( 1.0 - coverage )

        --Thunder
        elseif weather.index == tes3.weather.thunder then
            currentWetness = currentWetness + thunderEffect * interval * ( 1.0 - coverage )
        end
    end

    --assert min/max values
    currentWetness = currentWetness < 0 and 0 or currentWetness
    currentWetness = currentWetness > 100 and 100 or currentWetness

    --Update wetness and wetTemp on player data
    common.data.wetness = currentWetness
    common.data.wetTemp = (currentWetness / 100) * wetTempMax

    common.data.wetCoolingRate = math.remap( currentWetness, 0, 100, 1.0, 2 )
    common.data.wetWarmingRate = math.remap( currentWetness, 0, 100, 1.0, 0.5 )
end



return this


