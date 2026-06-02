local variableFog         = {}

--------------------------------------------------------------------------------------
local common              = require("tew.Watch the Skies.components.common")
local debugLog            = common.debugLog
local seasonalChances     = require("tew.Watch the Skies.components.seasonalChances")
local lastRegion

--------------------------------------------------------------------------------------
-- BASE FOG
--------------------------------------------------------------------------------------
local defaultFog          = {
    [0] = { distance = 1.0, offset = 0 },
    [1] = { distance = 0.9, offset = 0 },
    [2] = { distance = 0.2, offset = 30 },
    [3] = { distance = 0.7, offset = 0 },
    [4] = { distance = 0.5, offset = 10 },
    [5] = { distance = 0.5, offset = 20 },
    [6] = { distance = 0.25, offset = 45 },
    [7] = { distance = 0.25, offset = 50 },
    [8] = { distance = 0.5, offset = 40 },
    [9] = { distance = 0.16, offset = 100 },
}

local weatherCurveProfile = {
    [0] = 0.90,
    [1] = 0.95,
    [2] = 1.35,
    [3] = 1.05,
    [4] = 1.10,
    [5] = 1.15,
    [6] = 1.25,
    [7] = 1.30,
    [8] = 1.00,
    [9] = 1.45,
}

--------------------------------------------------------------------------------------
-- REGION CURVE MODIFIER
--------------------------------------------------------------------------------------
local function computeRegionCurve(region)
    if not region then return 1.0 end

    local score =
        (region.weatherChanceFoggy or 0) * 0.6 +
        (region.weatherChanceAsh or 0) * 0.8 +
        (region.weatherChanceBlight or 0) * 0.8

    local normalized = score / 300

    return 1.0 + math.max(-0.25, math.min(0.25, normalized))
end

--------------------------------------------------------------------------------------
-- SEASONAL CURVE MODIFIER
--------------------------------------------------------------------------------------
local function computeSeasonCurve(region, weatherIndex)
    if not region then return 1.0 end

    local regionData = seasonalChances[region.id]
    if not regionData then return 1.0 end

    local month = tes3.worldController.month.value + 1
    local monthData = regionData[month]
    if not monthData then return 1.0 end

    local fogChance = (monthData[weatherIndex + 1] or 0) / 100

    local bias = fogChance
    local influence = (bias - 0.5) * 0.6

    return 1.0 + influence
end

--------------------------------------------------------------------------------------
-- CURVE APPLICATION
--------------------------------------------------------------------------------------
local function applyFogCurve(distance, curve)
    return distance ^ curve
end

--------------------------------------------------------------------------------------
-- RANDOM VARIATION
--------------------------------------------------------------------------------------
local function applyRandomVariation(value, variationPercent)
    local variation = value * variationPercent
    return value + (math.random() * 2 - 1) * variation
end

--------------------------------------------------------------------------------------
-- APPLY FOG
--------------------------------------------------------------------------------------
local function applyFogToWeather(weatherIndex, region)
    local preset = defaultFog[weatherIndex]
    if not preset then return end

    ----------------------------------------------------------------------------------
    -- BASE VALUE
    ----------------------------------------------------------------------------------
    local distance    = preset.distance
    local offset      = preset.offset

    ----------------------------------------------------------------------------------
    -- CURVES
    ----------------------------------------------------------------------------------
    local baseCurve   = weatherCurveProfile[weatherIndex] or 1.0
    local regionCurve = computeRegionCurve(region)
    local seasonCurve = computeSeasonCurve(region, weatherIndex)

    local curve       =
        baseCurve
        + (regionCurve - 1.0) * 1.65
        + (seasonCurve - 1.0) * 1.75

    ----------------------------------------------------------------------------------
    -- APPLY CURVE FIRST
    ----------------------------------------------------------------------------------
    distance          = applyFogCurve(distance, curve)

    ----------------------------------------------------------------------------------
    -- SUBTLE POST-CURVE VARIATION
    ----------------------------------------------------------------------------------
    distance          = applyRandomVariation(distance, 0.08)

    ----------------------------------------------------------------------------------
    -- OFFSET MODEL
    ----------------------------------------------------------------------------------
    local baseOffset  = offset + (1 - distance) * 234.57
    baseOffset        = applyRandomVariation(baseOffset, 0.08)

    if weatherIndex == 0 or weatherIndex == 1 then
        baseOffset = math.min(baseOffset, 40)
    elseif weatherIndex == 2 then
        baseOffset = math.min(baseOffset, 750 * distance)
    else
        baseOffset = math.min(baseOffset, 190)
    end

    ----------------------------------------------------------------------------------
    -- FINAL SAFETY CLAMPS
    ----------------------------------------------------------------------------------
    local finalDistance = math.max(math.min(distance, 1.25), 0.05)
    local finalOffset   = math.max(math.min(baseOffset, 750 * finalDistance), 0)

    ----------------------------------------------------------------------------------
    -- APPLY
    ----------------------------------------------------------------------------------
    mge.weather.setDistantFog({
        weather  = weatherIndex,
        distance = finalDistance,
        offset   = finalOffset,
    })

    debugLog(("Applied fog: weather=%d distance=%.3f offset=%.3f region=%s")
        :format(
            weatherIndex,
            finalDistance,
            finalOffset,
            region and region.id or "unknown"
        ))
end

--------------------------------------------------------------------------------------
-- WEATHER CHANGE HANDLER
--------------------------------------------------------------------------------------
function variableFog.applyFog()
    local region = tes3.getRegion(true)

    for weatherIndex in pairs(defaultFog) do
        applyFogToWeather(weatherIndex, region)
    end
end

function variableFog.onCellChanged(e)
    if not (e and e.cell) then return end
    local region = tes3.getRegion(true)
    if region ~= lastRegion then
        variableFog.applyFog()
        lastRegion = region
    end
end

--------------------------------------------------------------------------------------
-- RESTORE DEFAULTS
--------------------------------------------------------------------------------------
function variableFog.restoreDefaults()
    for weatherIndex, preset in pairs(defaultFog) do
        mge.weather.setDistantFog({
            weather  = weatherIndex,
            distance = preset.distance,
            offset   = preset.offset,
        })
    end

    debugLog("All fog presets restored to default values.")
end

--------------------------------------------------------------------------------------
return variableFog
