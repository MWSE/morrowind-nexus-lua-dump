-- ======================================================
-- Scripts/seasonalSwitcher/player.lua
-- ======================================================
-- OpenMW Dynamic Seasons player script.
-- Handles:
--   1. Season computation and texture swapping
--   2. globalSeason uniform push to terrain/groundcover shaders
--   3. Rain/snow accumulation and weather-driven effects
--
-- This version reads per-region climates from climates.yaml and
-- computes season phases based on each climate's custom schedule.
-- ======================================================

local core           = require('openmw.core')
local async          = require('openmw.async')
local I              = require('openmw.interfaces')
local storage        = require('openmw.storage')
local postprocessing = require('openmw.postprocessing')
local calendar       = require('openmw_aux.calendar')
local vfs            = require('openmw.vfs')
local markup         = require('openmw.markup')
local self           = require('openmw.self')

local S = select('sandbox.bypass')
local ffi = S.require('ffi')
ffi.cdef[[
    void SwapTextureByPath(const char* targetTexture, const char* replacementTexture);
    void TriggerDistantLandRefresh();
    void DumpTrackedTextures();
    void DumpTrackedTexturesFiltered(const char* filter);
    void DumpSceneGraphTextures();
    void SetUniform1f(const char* name, float value);
    void SetUniform3f(const char* name, float x, float y, float z);
    void SetUniform4f(const char* name, float x, float y, float z, float w);
]]
local swapper = ffi.load('TextureSwapper.dll')

-- ============================================================================
-- Data Loading (climates, regions, textures)
-- ============================================================================

local climates = {}
local regions = {}
local texMap = {}
local schedules = {}

local function loadData()
    if vfs.fileExists("scripts/seasonalSwitcher/data/climates.yaml") then
        local data = vfs.open("scripts/seasonalSwitcher/data/climates.yaml"):read("*all")
        climates = markup.decodeYaml(data)
    end
    if vfs.fileExists("scripts/seasonalSwitcher/data/regions.yaml") then
        local data = vfs.open("scripts/seasonalSwitcher/data/regions.yaml"):read("*all")
        regions = markup.decodeYaml(data)
    end
    if vfs.fileExists("scripts/seasonalSwitcher/data/texture_replacements.yaml") then
         local data = vfs.open("scripts/seasonalSwitcher/data/texture_replacements.yaml"):read("*all")
         local parsed = markup.decodeYaml(data)
         if parsed and parsed.seasonal_texture_replacements then
             local rep = parsed.seasonal_texture_replacements
             -- New grouped format: sections with nested textures
             for key, value in pairs(rep) do
                 if key == "textures" then
                     -- Explicit textures block
                     for orig, entry in pairs(value) do
                         texMap[orig] = entry
                     end
                 elseif not key:match("^textures[/$]") and type(value) == "table" then
                     -- Section key (e.g. cyrodiil, morrowind_mid) with nested textures
                     for orig, entry in pairs(value) do
                         if type(entry) == "table" then
                             entry._section = key
                             texMap[orig] = entry
                         end
                     end
                 else
                     -- Old flat format or explicit textures block
                     texMap[key] = value
                 end
             end
         end
    end
    if vfs.fileExists("scripts/seasonalSwitcher/data/texture_swap_schedule.yaml") then
         local data = vfs.open("scripts/seasonalSwitcher/data/texture_swap_schedule.yaml"):read("*all")
         local parsed = markup.decodeYaml(data)
         if parsed and parsed.swap_schedules then
             schedules = parsed.swap_schedules
         end
    end
end
loadData()

local function normalizeTexPath(path)
    if not path or path == "" then return "" end
    path = path:lower()
    if not path:match("%.%w+$") then return path .. ".dds" end
    return path
end

-- Determine which season a schedule is currently in based on globalSeason (0.0-1.0).
-- Schedules define ordered swap points around the year.
local function getSeasonForSchedule(scheduleName, globalSeason)
    local sched = schedules[scheduleName]
    if not sched or not sched.swaps then return nil end
    local swaps = sched.swaps
    -- Find last swap whose start_global_season <= current globalSeason
    for i = #swaps, 1, -1 do
        if globalSeason >= swaps[i].start_global_season then
            return swaps[i].season
        end
    end
    -- Wrap around: before first swap means we're in the last season of the cycle
    return swaps[#swaps].season
end

-- Derive home landmass from section name
local function getHomeFromSection(section)
    if not section then return nil end
    if section == "cyrodiil" then return "cyrodiil" end
    if section == "skyrim" then return "skyrim" end
    if section:match("^morrowind_") then return "morrowind" end
    return nil
end

local function applyTextureSwaps(playerSeason, landmass, globalSeason, isForced)
    landmass = landmass or "morrowind"
    for original, entry in pairs(texMap) do
        local replacement = nil
        local texSeason = playerSeason

        -- Determine effective schedule for this texture
        if not isForced then
            local section = entry._section
            local home = getHomeFromSection(section)
            local effectiveSchedule = nil

            if home and landmass == home and section and schedules[section] then
                -- In texture's home landmass: use its section schedule
                effectiveSchedule = section
            elseif schedules[landmass] then
                -- In a different landmass: use that landmass's schedule
                effectiveSchedule = landmass
            end

            if effectiveSchedule then
                texSeason = getSeasonForSchedule(effectiveSchedule, globalSeason) or playerSeason
            end
        end

        -- Look up replacement
        if entry[landmass] and type(entry[landmass]) == "table" then
            -- Landmass-gated replacements
            replacement = entry[landmass][texSeason]
        elseif entry[texSeason] and type(entry[texSeason]) == "string" then
            -- Top-level season replacement
            replacement = entry[texSeason]
        end

        if not replacement then
            -- No entry for this season/landmass/schedule: revert to original texture
            replacement = original
        end
        local normOriginal = normalizeTexPath(original)
        local normReplacement = normalizeTexPath(replacement)
        swapper.SwapTextureByPath(normOriginal, normReplacement)
    end
end

local textureSwapPending = false
local lastSeason
local lastClimate
local executePendingSwaps

-- Registered timer callback for onTeleported deferred swap
local onTeleportedTimer = async:registerTimerCallback('SeasonalSwitcher_OnTeleported', function()
    print('[SeasonalSwitcher] onTeleportedTimer fired, pending=' .. tostring(textureSwapPending))
    if textureSwapPending and executePendingSwaps then
        executePendingSwaps()
    end
end)

-- ============================================================================
-- Calendar & Season Helpers
-- ============================================================================

local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function getDayOfYear(month, day)
    local doy = 0
    for i = 1, month - 1 do doy = doy + MONTH_DAYS[i] end
    return doy + day
end

local SEASON_NAMES = { "spring", "summer", "autumn", "winter" }
local SEASON_ORDER = { spring = 1, summer = 2, autumn = 3, winter = 4 }

-- Rain weather intensity mapping (recordId -> wetness 0-1)
-- Snow/blizzard are NOT wetness — they have their own snow accumulator.
local RAIN_MAP = {
    rain = 1.0,
    thunderstorm = 1.0,
    ashstorm = 0.0,
    blight = 0.0,
}

-- Snow weather mapping (recordId -> accumulation multiplier)
local SNOW_MAP = {
    snow = 1.0,
    blizzard = 2.5,
}

-- ============================================================================
-- Procedural Environment Sky — Weather color tables (extracted from sky dump)
-- ============================================================================

local SKY_COLORS = {
    Ashstorm = {
        Sunrise = {0.3569, 0.2196, 0.2000},
        Day = {0.4863, 0.2863, 0.2275},
        Sunset = {0.4157, 0.2157, 0.1569},
        Night = {0.0784, 0.0824, 0.0863},
    },
    Blight = {
        Sunrise = {0.3529, 0.1373, 0.1373},
        Day = {0.3529, 0.1373, 0.1373},
        Sunset = {0.3608, 0.1294, 0.1294},
        Night = {0.1725, 0.0549, 0.0549},
    },
    Blizzard = {
        Sunrise = {0.3569, 0.3882, 0.4157},
        Day = {0.4745, 0.5216, 0.5686},
        Sunset = {0.4235, 0.4510, 0.4745},
        Night = {0.1059, 0.1137, 0.1216},
    },
    Clear = {
        Sunrise = {0.4588, 0.5529, 0.6431},
        Day = {0.3725, 0.5294, 0.7961},
        Sunset = {0.2196, 0.3490, 0.5059},
        Night = {0.0353, 0.0392, 0.0431},
    },
    Cloudy = {
        Sunrise = {0.4941, 0.6196, 0.6784},
        Day = {0.4588, 0.6275, 0.8431},
        Sunset = {0.4353, 0.4471, 0.6235},
        Night = {0.0353, 0.0392, 0.0431},
    },
    Foggy = {
        Sunrise = {0.7725, 0.7451, 0.7059},
        Day = {0.7216, 0.8275, 0.8941},
        Sunset = {0.5569, 0.6235, 0.6902},
        Night = {0.0706, 0.0902, 0.1098},
    },
    Overcast = {
        Sunrise = {0.3569, 0.3882, 0.4157},
        Day = {0.5608, 0.5725, 0.5843},
        Sunset = {0.4235, 0.4510, 0.4745},
        Night = {0.0745, 0.0863, 0.0980},
    },
    Rain = {
        Sunrise = {0.2784, 0.2902, 0.2941},
        Day = {0.4549, 0.4706, 0.4784},
        Sunset = {0.2863, 0.2863, 0.2863},
        Night = {0.0941, 0.0980, 0.1020},
    },
    Snow = {
        Sunrise = {0.4157, 0.3569, 0.3569},
        Day = {0.6000, 0.6196, 0.6510},
        Sunset = {0.3765, 0.4510, 0.5255},
        Night = {0.1216, 0.1373, 0.1529},
    },
    Thunderstorm = {
        Sunrise = {0.1373, 0.1412, 0.1529},
        Day = {0.3804, 0.4078, 0.4510},
        Sunset = {0.1373, 0.1412, 0.1529},
        Night = {0.0745, 0.0784, 0.0863},
    },
}

local function mixColors(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

-- Returns sunColor, awayColor for the given weather and hour.
-- Day/Night: sun == away. Sunrise/Sunset: sun = sunrise/sunset color, away = night color.
local function getEnvSkyColors(weather, hour)
    local w = SKY_COLORS[weather]
    if not w then
        -- Unknown weather — fall back to a neutral gray
        return {0.5, 0.55, 0.65}, {0.5, 0.55, 0.65}
    end

    local day    = w.Day    or {0.5, 0.55, 0.65}
    local night  = w.Night  or {0.05, 0.05, 0.06}
    local rise   = w.Sunrise or day
    local set    = w.Sunset  or day

    local sunColor, awayColor

    if hour >= 7.0 and hour < 18.0 then
        -- Pure day
        sunColor  = day
        awayColor = day
    elseif hour >= 20.5 or hour < 5.0 then
        -- Pure night
        sunColor  = night
        awayColor = night
    elseif hour >= 5.0 and hour < 7.0 then
        -- Sunrise: sun blends Night→Sunrise→Day, away stays Night
        awayColor = night
        if hour < 6.0 then
            local t = hour - 5.0
            sunColor = mixColors(night, rise, t)
        else
            local t = hour - 6.0
            sunColor = mixColors(rise, day, t)
        end
    else
        -- Sunset (18:00-20:30): sun blends Day→Sunset→Night, away stays Night
        awayColor = night
        if hour < 19.25 then
            local t = (hour - 18.0) / 1.25
            sunColor = mixColors(day, set, t)
        else
            local t = (hour - 19.25) / 1.25
            sunColor = mixColors(set, night, t)
        end
    end

    return sunColor, awayColor
end

-- Season uniform target value
local targetShaderSeason = 0.25

-- Rain / Snow accumulators (persisted in onSave/onLoad)
local rainAccumulator = 0.0
local snowAccumulator = 0.0

-- Cache last exterior cell so interiors can keep tracking weather
local lastExteriorCell = nil

-- Forced-season weight tables: {spring, summer, autumn, winter}
local FORCED_WEIGHTS = {
    spring = { 1.0, 0.0, 0.0, 0.0 },
    summer = { 0.0, 1.0, 0.0, 0.0 },
    autumn = { 0.0, 0.0, 1.0, 0.0 },
    winter = { 0.0, 0.0, 0.0, 1.0 },
}

-- Resolve which climate a region uses.
local function getClimateForRegion(regionName)
    if regionName and regions[regionName] then
        return regions[regionName]
    end
    return "temperate"
end

-- Resolve which landmass (morrowind, cyrodiil, skyrim) the player is in.
-- Bounding boxes extracted from region_data.glsl. Default is morrowind.
local function getLandmassForPosition(x, y)
    -- Region 0: Cyrodil  box(-1138688.0, -483328.0, -876544.0, -303104.0)
    if x >= -1138688.0 and x <= -876544.0 and y >= -483328.0 and y <= -303104.0 then
        return "cyrodiil"
    end
    -- Region 5: Skyrim  box(-983040.0, 0.0, -794624.0, 180224.0)
    if x >= -983040.0 and x <= -794624.0 and y >= 0.0 and y <= 180224.0 then
        return "skyrim"
    end
    -- Default: Morrowind (covers regions 1-4 + everything else)
    return "morrowind"
end

-- Get the active season for a specific climate on a given date.
-- Returns: seasonName, seasonInfoTable
local function getSeasonInfoForDate(climateData, month, day)
    if not climateData then
        return "summer", { index = 2, phase = 1.0, duration = 91, nextName = "autumn", nextIndex = 3 }
    end

    -- Backward compatibility: old climates.yaml used direct month maps.
    if not climateData.seasons then
        -- Legacy fallback: pretend standard temperate schedule
        climateData = {
            seasons = {
                { name = "spring", startMonth = 3, startDay = 1 },
                { name = "summer", startMonth = 6, startDay = 1 },
                { name = "autumn", startMonth = 9, startDay = 1 },
                { name = "winter", startMonth = 12, startDay = 1 },
            }
        }
    end

    local seasons = climateData.seasons
    local n = #seasons
    if n == 0 then
        return "summer", { index = 2, phase = 1.0, duration = 91, nextName = "autumn", nextIndex = 3 }
    end

    local currentDoy = getDayOfYear(month, day)

    for i, season in ipairs(seasons) do
        local startDoy = getDayOfYear(season.startMonth, season.startDay)
        local nextIdx = (i % n) + 1
        local nextSeason = seasons[nextIdx]
        local endDoy = getDayOfYear(nextSeason.startMonth, nextSeason.startDay) - 1

        local dur
        if endDoy < startDoy then
            -- Wraps around year end
            dur = (365 - startDoy + 1) + endDoy
            if currentDoy >= startDoy or currentDoy <= endDoy then
                local progress
                if currentDoy >= startDoy then
                    progress = currentDoy - startDoy
                else
                    progress = (365 - startDoy + 1) + currentDoy - 1
                end
                return season.name, {
                    index = i,
                    phase = (i - 1) + progress / dur,
                    duration = dur,
                    nextName = nextSeason.name,
                    nextIndex = nextIdx,
                    progress = progress / dur,
                }
            end
        else
            dur = endDoy - startDoy + 1
            if currentDoy >= startDoy and currentDoy <= endDoy then
                local progress = currentDoy - startDoy
                return season.name, {
                    index = i,
                    phase = (i - 1) + progress / dur,
                    duration = dur,
                    nextName = nextSeason.name,
                    nextIndex = nextIdx,
                    progress = progress / dur,
                }
            end
        end
    end

    -- Fallback to last season
    local last = seasons[n]
    local first = seasons[1]
    local startDoy = getDayOfYear(last.startMonth, last.startDay)
    local endDoy = getDayOfYear(first.startMonth, first.startDay) - 1
    local dur
    if endDoy < startDoy then
        dur = (365 - startDoy + 1) + endDoy
    else
        dur = endDoy - startDoy + 1
    end
    return last.name, { index = n, phase = n - 1, duration = dur, nextName = first.name, nextIndex = 1, progress = 0 }
end

-- Compute {spring, summer, autumn, winter} blend weights [0,1] summing to 1
-- for the given climate and calendar date.
local function computeWeightsForClimate(climateData, month, day, transitionDays)
    local seasonName, info = getSeasonInfoForDate(climateData, month, day)

    local weights = { 0.0, 0.0, 0.0, 0.0 }
    local dur = info.duration
    if dur <= 0 then dur = 30 end

    local transitionFrac = math.min(transitionDays / dur, 0.499)
    local t = info.progress  -- 0.0 at season start, -> 1.0 at season end

    local blendFactor = 0.0
    if t >= (1.0 - transitionFrac) then
        blendFactor = (t - (1.0 - transitionFrac)) / transitionFrac
        blendFactor = math.max(0.0, math.min(1.0, blendFactor))
    end

    local currentWeightIdx = SEASON_ORDER[seasonName] or 2
    local nextWeightIdx = SEASON_ORDER[info.nextName] or 2

    weights[currentWeightIdx] = 1.0 - blendFactor
    weights[nextWeightIdx] = weights[nextWeightIdx] + blendFactor

    return weights, seasonName
end

-- ============================================================================
-- Player Region Detection
-- ============================================================================

local function isPlayerInInterior()
    local cell = self.object and self.object.cell
    if not cell then return true end
    if cell.isInterior == true then return true end
    -- Fallback: some OpenMW builds return nil for isInterior in both
    -- exteriors and certain interiors. Exteriors have a region; interiors don't.
    if cell.isInterior == nil and cell.region == nil then return true end
    return false
end

local function getPlayerRegion()
    if not isPlayerInInterior() then
        return self.object.cell.region
    end
    return nil
end

-- ============================================================================
-- Settings
-- ============================================================================

I.Settings.registerPage({
    key         = 'OpenMWDynamicSeasons',
    l10n        = 'OpenMWDynamicSeasons',
    name        = 'OpenMW Dynamic Seasons',
    description = 'Settings for OpenMW Dynamic Seasons',
})

local DEFAULT_TRANSITION_DAYS = 14

-- ============================================================================
-- Group 1: Main Toggles
-- ============================================================================
I.Settings.registerGroup({
    key              = 'Settings01_OpenMWDynamicSeasons_Main',
    page             = 'OpenMWDynamicSeasons',
    l10n             = 'OpenMWDynamicSeasons',
    name             = 'Main Toggles',
    permanentStorage = false,
    settings = {
        {
            key         = 'TransitionDays',
            renderer    = 'number',
            name        = 'Season Transition Days',
            description = 'Number of days over which seasons transition between adjacent periods.',
            default     = 14,
            argument    = { min = 1, max = 60 },
        },
        {
            key         = 'EnableTextureSwaps',
            renderer    = 'checkbox',
            name        = 'Enable Texture Swaps',
            description = 'Enable live texture replacement for seasonal foliage. Disable to use shader effects only.',
            default     = true,
        },
        {
            key         = 'EnableShaderSeasons',
            renderer    = 'checkbox',
            name        = 'Enable Terrain Season Shaders',
            description = 'Enable seasonal color shifts and snow accumulation in terrain/groundcover/object shaders.',
            default     = true,
        },
        {
            key         = 'EnableRealRain',
            renderer    = 'checkbox',
            name        = 'Enable Real Rain Wetness',
            description = 'Drive rainIntensity from actual weather with gradual accumulation.',
            default     = true,
        },
        {
            key         = 'EnableSnowShader',
            renderer    = 'checkbox',
            name        = 'Enable Snow Shader',
            description = 'Drive snowIntensity from actual snowfall with gradual accumulation.',
            default     = true,
        },
    },
})

-- ============================================================================
-- Group 2: Accumulation Values
-- ============================================================================
I.Settings.registerGroup({
    key              = 'Settings02_OpenMWDynamicSeasons_Accumulation',
    page             = 'OpenMWDynamicSeasons',
    l10n             = 'OpenMWDynamicSeasons',
    name             = 'Accumulation Values',
    permanentStorage = false,
    settings = {
        {
            key         = 'RainAccumulationRate',
            renderer    = 'number',
            name        = 'Rain Accumulation Rate',
            description = 'How fast surfaces get wet during rain (per second).',
            default     = 0.08,
            argument    = { min = 0.001, max = 0.5 },
        },
        {
            key         = 'RainDryingRate',
            renderer    = 'number',
            name        = 'Rain Drying Rate',
            description = 'How fast surfaces dry when it stops raining (per second).',
            default     = 0.025,
            argument    = { min = 0.001, max = 0.5 },
        },
        {
            key         = 'SnowAccumulationRate',
            renderer    = 'number',
            name        = 'Snow Accumulation Rate',
            description = 'How fast snow builds up during snowfall (per second).',
            default     = 0.04,
            argument    = { min = 0.001, max = 0.5 },
        },
        {
            key         = 'BlizzardAccumulationRate',
            renderer    = 'number',
            name        = 'Blizzard Accumulation Rate',
            description = 'How fast snow builds up during blizzards (per second).',
            default     = 0.10,
            argument    = { min = 0.001, max = 0.5 },
        },
        {
            key         = 'SnowMeltRate',
            renderer    = 'number',
            name        = 'Snow Melt Rate',
            description = 'How fast snow melts when it stops snowing (per second).',
            default     = 0.008,
            argument    = { min = 0.0001, max = 0.1 },
        },
        {
            key         = 'ShoulderWinterMultiplier',
            renderer    = 'number',
            name        = 'Shoulder Winter Multiplier',
            description = 'Snow accumulation multiplier at the start and end of winter.',
            default     = 2,
            argument    = { min = 1, max = 10 },
        },
        {
            key         = 'PeakWinterMultiplier',
            renderer    = 'number',
            name        = 'Peak Winter Multiplier',
            description = 'Snow accumulation multiplier at mid-winter.',
            default     = 5,
            argument    = { min = 1, max = 20 },
        },
    },
})

-- ============================================================================
-- Group 3: Debug Overrides
-- ============================================================================
I.Settings.registerGroup({
    key              = 'Settings03_OpenMWDynamicSeasons_Debug',
    page             = 'OpenMWDynamicSeasons',
    l10n             = 'OpenMWDynamicSeasons',
    name             = 'Debug Overrides',
    permanentStorage = false,
    settings = {
        {
            key         = 'forceSeason',
            renderer    = 'select',
            name        = 'Force Season Debug',
            description = 'Overrides the natural date to force a specific season globally.',
            default     = 'none',
            argument    = {
                l10n  = 'OpenMWDynamicSeasons',
                items = {'none', 'spring', 'summer', 'autumn', 'winter'},
            },
        },
        {
            key         = 'DebugRainMode',
            renderer    = 'select',
            name        = 'Debug Rain Mode',
            description = 'Override rain accumulator for testing.',
            default     = 'auto',
            argument    = {
                l10n  = 'OpenMWDynamicSeasons',
                items = {'auto', 'force_wet', 'force_dry'},
            },
        },
        {
            key         = 'DebugSnowMode',
            renderer    = 'select',
            name        = 'Debug Snow Mode',
            description = 'Override snow accumulator for testing.',
            default     = 'auto',
            argument    = {
                l10n  = 'OpenMWDynamicSeasons',
                items = {'auto', 'force_wet', 'force_dry'},
            },
        },
    },
})

local playerSettings = storage.playerSection('Settings01_OpenMWDynamicSeasons_Main')
local accumulationSettings = storage.playerSection('Settings02_OpenMWDynamicSeasons_Accumulation')
local debugSettings = storage.playerSection('Settings03_OpenMWDynamicSeasons_Debug')

executePendingSwaps = function()
    print('[SeasonalSwitcher] executePendingSwaps called, pending=' .. tostring(textureSwapPending))
    if not textureSwapPending then
        core.sendGlobalEvent('SeasonalSwitcher_ExecuteQueuedSwap')
        return
    end

    local forceSeason = debugSettings:get('forceSeason') or 'none'
    local seasonName
    local landmassName
    if forceSeason ~= 'none' then
        seasonName = forceSeason
        local pos = self.object.position
        landmassName = getLandmassForPosition(pos.x, pos.y)
    else
        local date = calendar.formatGameTime('*t')
        local pos = self.object.position
        landmassName = getLandmassForPosition(pos.x, pos.y)
        local climateName = getClimateForRegion(getPlayerRegion())
        local climateData = climates[climateName]
        local _, computedSeason = computeWeightsForClimate(climateData, date.month, date.day,
            playerSettings:get('TransitionDays') or DEFAULT_TRANSITION_DAYS)
        seasonName = computedSeason
    end

    if playerSettings:get('EnableTextureSwaps') ~= false then
        applyTextureSwaps(seasonName, landmassName, targetShaderSeason, forceSeason ~= 'none')
        core.sendGlobalEvent('SeasonalSwitcher_ExecuteQueuedSwap')
    end
    textureSwapPending = false
end

-- ============================================================================
-- Shader Handles
-- ============================================================================

-- DEPRECATED: LUT and snowworld post-processing shaders removed.
-- Season tint is now applied directly in terrain/groundcover fragment shaders.
-- local shaderSeasonalLUT = postprocessing.load('seasonal_lut')
-- local shaderSnowWorld   = postprocessing.load('snowworld')

-- ============================================================================
-- Main Update Logic
-- ============================================================================

local lastGameDay = -1
local lastRegion = nil
lastSeason = nil
local lastForceSeason = 'none'
local lastWasInterior = nil

local function updateSeasons()
    local forceSeason    = debugSettings:get('forceSeason') or 'none'
    local transitionDays = playerSettings:get('TransitionDays') or DEFAULT_TRANSITION_DAYS

    -- Determine current game day
    local currentDay = math.floor(core.getGameTime() / 86400)

    -- Determine player region and interior state
    local region = getPlayerRegion()
    local isInterior = isPlayerInInterior()

    -- Throttle: recalculate at most once per game day unless region, forced season, or interior state changes
    if currentDay == lastGameDay and region == lastRegion and forceSeason == lastForceSeason and isInterior == lastWasInterior then
        return
    end
    lastGameDay = currentDay
    lastRegion = region
    lastForceSeason = forceSeason
    lastWasInterior = isInterior

    local climateName = getClimateForRegion(region)
    local landmassName
    if not isInterior then
        local pos = self.object.position
        landmassName = getLandmassForPosition(pos.x, pos.y)
    else
        landmassName = lastClimate or "morrowind"
    end
    if landmassName ~= lastClimate then
        textureSwapPending = true
        lastClimate = landmassName
        print('[SeasonalSwitcher] queued texture swap for landmass change: ' .. tostring(landmassName))
    end

    -- Look up climate data for season computation
    local climateData = climates[climateName]

    -- Determine dominant season for texture swaps
    local seasonName
    if forceSeason ~= 'none' then
        seasonName = forceSeason
    else
        local date = calendar.formatGameTime('*t')
        local _, computedSeason = computeWeightsForClimate(climateData, date.month, date.day, transitionDays)
        seasonName = computedSeason
    end

    -- Queue texture swap when the dominant season or climate changes
    if seasonName ~= lastSeason then
        textureSwapPending = true
        lastSeason = seasonName
        print('[SeasonalSwitcher] queued texture swap for season: ' .. tostring(seasonName))
    end

    -- Compute target shader season as day-of-year fraction (0.0 = Jan 1, 1.0 = Dec 31).
    -- The GLSL curves map this timeline to per-region season strength.
    -- Forced seasons map to the middle of that season.
    local FORCED_SEASON_DOY = { spring = 80, summer = 172, autumn = 264, winter = 355 }
    if isInterior then
        targetShaderRain = 0.0
    end
    -- targetShaderSeason is always computed so it's ready when exiting interiors
    if forceSeason ~= 'none' and FORCED_SEASON_DOY[forceSeason] then
        targetShaderSeason = FORCED_SEASON_DOY[forceSeason] / 365.0
    else
        local date = calendar.formatGameTime('*t')
        targetShaderSeason = getDayOfYear(date.month, date.day) / 365.0
    end
end

-- ============================================================================
-- Weather-Driven Rain & Snow Accumulators
-- ============================================================================

local function getWeatherCell()
    local cell = self.object.cell
    if not isPlayerInInterior() then
        lastExteriorCell = cell
        return cell
    end
    -- Interior: use cached exterior cell if we have one
    if lastExteriorCell then
        return lastExteriorCell
    end
    return cell
end

-- ============================================================================
-- Snow Season Multiplier (peak winter = faster accumulation, slower melting)
-- ============================================================================

local SPRING_START  = 0.10
local SUMMER_START  = 0.3125
local AUTUMN_START  = 0.525
local WINTER_START  = 0.775
local MID_WINTER    = 0.9375

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function getSnowSeasonMultiplier(globalSeason, shoulderMult, peakMult)
    local gs = globalSeason
    -- Spring: shoulder -> 1.0
    if gs >= SPRING_START and gs < SUMMER_START then
        local t = (gs - SPRING_START) / (SUMMER_START - SPRING_START)
        return lerp(shoulderMult, 1.0, t)
    -- Summer: 1.0
    elseif gs >= SUMMER_START and gs < AUTUMN_START then
        return 1.0
    -- Autumn: 1.0 -> shoulder
    elseif gs >= AUTUMN_START and gs < WINTER_START then
        local t = (gs - AUTUMN_START) / (WINTER_START - AUTUMN_START)
        return lerp(1.0, shoulderMult, t)
    -- Winter: shoulder -> peak -> shoulder (wraps around year boundary)
    else
        local winterGs = (gs >= WINTER_START) and gs or (gs + 1.0)
        if winterGs < MID_WINTER then
            local t = (winterGs - WINTER_START) / (MID_WINTER - WINTER_START)
            return lerp(shoulderMult, peakMult, t)
        else
            local t = (winterGs - MID_WINTER) / ((1.0 + SPRING_START) - MID_WINTER)
            return lerp(peakMult, shoulderMult, t)
        end
    end
end

local function updateAccumulators(dt)
    local cell = getWeatherCell()
    local current = core.weather.getCurrent(cell)
    local nextW = core.weather.getNext(cell)
    local t = core.weather.getTransition(cell) or 0

    local currId = current and current.recordId or nil
    local nextId = nextW and nextW.recordId or currId

    -- Blend current and next weather for smooth transitions
    local rainCurr = currId and RAIN_MAP[currId] or 0.0
    local rainNext = nextId and RAIN_MAP[nextId] or rainCurr
    local rainValue = rainCurr * (1.0 - t) + rainNext * t

    local snowCurr = currId and SNOW_MAP[currId] or 0.0
    local snowNext = nextId and SNOW_MAP[nextId] or snowCurr
    local snowValue = snowCurr * (1.0 - t) + snowNext * t

    -- Rain accumulation
    local rainAccRate = accumulationSettings:get('RainAccumulationRate') or 0.08
    local rainDryRate = accumulationSettings:get('RainDryingRate') or 0.025
    local debugRain = debugSettings:get('DebugRainMode') or 'auto'

    if debugRain == 'force_wet' then
        rainAccumulator = math.min(1.0, rainAccumulator + rainAccRate * dt)
    elseif debugRain == 'force_dry' then
        rainAccumulator = math.max(0.0, rainAccumulator - rainDryRate * dt)
    elseif rainValue > 0.0 then
        local multiplier = (currId == 'thunderstorm') and 1.5 or 1.0
        rainAccumulator = math.min(1.0, rainAccumulator + rainValue * rainAccRate * multiplier * dt)
    else
        rainAccumulator = math.max(0.0, rainAccumulator - rainDryRate * dt)
    end

    -- Snow accumulation (with seasonal multiplier)
    local snowAccRate = accumulationSettings:get('SnowAccumulationRate') or 0.04
    local blizAccRate = accumulationSettings:get('BlizzardAccumulationRate') or 0.10
    local snowMeltRate = accumulationSettings:get('SnowMeltRate') or 0.008
    local shoulderMult = accumulationSettings:get('ShoulderWinterMultiplier') or 2
    local peakMult = accumulationSettings:get('PeakWinterMultiplier') or 5
    local debugSnow = debugSettings:get('DebugSnowMode') or 'auto'

    local snowSeasonMult = getSnowSeasonMultiplier(targetShaderSeason, shoulderMult, peakMult)

    if debugSnow == 'force_wet' then
        snowAccumulator = math.min(1.0, snowAccumulator + snowAccRate * snowSeasonMult * dt)
    elseif debugSnow == 'force_dry' then
        snowAccumulator = math.max(0.0, snowAccumulator - snowMeltRate / snowSeasonMult * dt)
    elseif snowValue > 0.0 then
        local rate = (currId == 'blizzard') and blizAccRate or snowAccRate
        snowAccumulator = math.min(1.0, snowAccumulator + snowValue * rate * snowSeasonMult * dt)
    else
        snowAccumulator = math.max(0.0, snowAccumulator - snowMeltRate / snowSeasonMult * dt)
    end
end

local function updateShaderUniforms(dt)
    local enableSeason = playerSettings:get('EnableShaderSeasons')
    local enableRain   = playerSettings:get('EnableRealRain')
    local enableSnow   = playerSettings:get('EnableSnowShader')
    local isInterior   = isPlayerInInterior()

    -- globalSeason is raw day-of-year; curves in GLSL are inherently smooth.
    swapper.SetUniform1f("globalSeason", targetShaderSeason)

    -- Binary flags: 1.0 = active, 0.0 = inactive (shaders default to 0 if not pushed)
    -- Interiors disable both season coloring and weather accumulation.
    swapper.SetUniform1f("seasonEnabled", (enableSeason and not isInterior) and 1.0 or 0.0)
    swapper.SetUniform1f("weatherAccumEnabled", ((enableRain or enableSnow) and not isInterior) and 1.0 or 0.0)

    -- Accumulators always update (even in interiors) so weather tracks while inside
    updateAccumulators(dt)

    if enableRain then
        swapper.SetUniform1f("rainIntensity", isInterior and 0.0 or rainAccumulator)
    else
        swapper.SetUniform1f("rainIntensity", 0.0)
    end

    if enableSnow then
        swapper.SetUniform1f("snowIntensity", isInterior and 0.0 or snowAccumulator)
    else
        swapper.SetUniform1f("snowIntensity", 0.0)
    end

    -- Procedural Environment Sky
    local envSkyStrength = 0.0
    local sunColor = {0.5, 0.55, 0.65}
    local awayColor = {0.5, 0.55, 0.65}
    if not isInterior then
        local cell = self.object.cell
        local current = core.weather.getCurrent(cell)
        local nextW   = core.weather.getNext(cell)
        local t       = core.weather.getTransition(cell) or 0
        local currName = current and current.recordId or 'clear'
        local nextName = nextW and nextW.recordId or currName
        -- Capitalize first letter to match sky dump keys
        currName = currName:sub(1,1):upper() .. currName:sub(2)
        nextName = nextName:sub(1,1):upper() .. nextName:sub(2)
        local hour = calendar.formatGameTime('*t').hour
        local sunCurr, awayCurr = getEnvSkyColors(currName, hour)
        local sunNext, awayNext = getEnvSkyColors(nextName, hour)
        sunColor = mixColors(sunCurr, sunNext, t)
        awayColor = mixColors(awayCurr, awayNext, t)
        envSkyStrength = 1.0
    end
    swapper.SetUniform3f("envSkySunColor",  sunColor[1],  sunColor[2],  sunColor[3])
    swapper.SetUniform3f("envSkyAwayColor", awayColor[1], awayColor[2], awayColor[3])
    swapper.SetUniform1f("envSkyStrength", envSkyStrength)
end

-- ============================================================================
-- Setting Change Handler
-- ============================================================================

local function onSettingChanged(section, key)
    if key == 'forceSeason' then
        core.sendGlobalEvent('SeasonalSwitcher_SetForcedSeason', debugSettings:get('forceSeason'))
        lastGameDay = -1  -- force season recalculate on next frame
        lastForceSeason = 'none'
    end
end

playerSettings:subscribe(async:callback(onSettingChanged))
accumulationSettings:subscribe(async:callback(onSettingChanged))
debugSettings:subscribe(async:callback(onSettingChanged))

-- ============================================================================
-- Engine Handlers
-- ============================================================================

return {
    interfaceName = "TextureSwapper",
    interface = {
        version = 1,
        swap = function(oldTex, newTex)
            swapper.SwapTextureByPath(normalizeTexPath(oldTex), normalizeTexPath(newTex))
        end,
        dump = function()
            swapper.DumpTrackedTextures()
        end,
        dumpScene = function()
            swapper.DumpSceneGraphTextures()
        end,
        find = function(filter)
            swapper.DumpTrackedTexturesFiltered(filter)
        end,

        refresh = function()
            swapper.TriggerDistantLandRefresh()
        end,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if data.oldMode == I.UI.MODE.Rest and data.newMode ~= I.UI.MODE.Rest then
                async:newSimulationTimer(0.2, onTeleportedTimer)
            end
        end,
    },
    engineHandlers = {
        onActive = function()
            -- Sync forced season to global script on load/cell change
            local forceSeason = debugSettings:get('forceSeason') or 'none'
            core.sendGlobalEvent('SeasonalSwitcher_SetForcedSeason', forceSeason)
            lastGameDay = -1  -- ensure season updates on first frame
            lastRegion = nil
            lastSeason = nil
            lastClimate = nil
            lastForceSeason = 'none'
            lastWasInterior = nil
            targetShaderSeason = 0.25
            lastExteriorCell = nil

            -- Trigger initial texture swap
            if forceSeason ~= 'none' then
                local FORCED_SEASON_DOY = { spring = 80, summer = 172, autumn = 264, winter = 355 }
                targetShaderSeason = (FORCED_SEASON_DOY[forceSeason] or 172) / 365.0
                if playerSettings:get('EnableTextureSwaps') ~= false then
                    local pos = self.object.position
                    applyTextureSwaps(forceSeason, getLandmassForPosition(pos.x, pos.y), targetShaderSeason, true)
                end
                lastSeason = forceSeason
            else
                updateSeasons()
                if textureSwapPending then
                    executePendingSwaps()
                end
            end
        end,
        onUpdate = function(dt)
            updateSeasons()
            updateShaderUniforms(dt)
        end,
        onTeleported = function()
            print('[SeasonalSwitcher] onTeleported fired, pending=' .. tostring(textureSwapPending))
            async:newSimulationTimer(0.2, onTeleportedTimer)
        end,
        onSave = function()
            return {
                rainAccumulator = rainAccumulator,
                snowAccumulator = snowAccumulator,
            }
        end,
        onLoad = function(data)
            if data then
                if data.rainAccumulator then rainAccumulator = data.rainAccumulator end
                if data.snowAccumulator then snowAccumulator = data.snowAccumulator end
            end
        end,
    },
}
