local M = {}

local DYNAMIC_SPELL_CATEGORIES = {
    'hunger',
    'thirst',
    'sleep',
    'hunger_learning',
    'thirst_learning',
    'sleep_learning',
    'temperature_hunger_misc',
    'temperature_thirst_misc',
    'temperature_slowness_misc',
    'temperature_health_misc',
    'temperature_weakness',
}

local function buildTrackedByCategory()
    local result = {}
    for _, category in ipairs(DYNAMIC_SPELL_CATEGORIES) do
        result[category] = {}
    end
    return result
end

local function buildNilByCategory()
    local result = {}
    for _, category in ipairs(DYNAMIC_SPELL_CATEGORIES) do
        result[category] = nil
    end
    return result
end

function M.create(deps)
    local temperatureDebug = assert(deps.temperatureDebug)
    local temperatureBalanceConfig = assert(deps.temperatureBalanceConfig)

    local function resolveCellInfoRequestIntervalSeconds()
        return math.max(
            0.05,
            tonumber(temperatureBalanceConfig.campfire.cellInfoRequestIntervalSeconds)
        )
    end

    local function resolveTemperatureUpdateIntervalSeconds()
        local configured = nil
        if type(temperatureBalanceConfig.modifierPipeline) == 'table' then
            configured = tonumber(temperatureBalanceConfig.modifierPipeline.temperatureUpdateIntervalSeconds)
        end
        return math.max(0.05, configured or 0.5)
    end

    local api = {}

    function api.createInitialState()
        return {
            hunger = 0,
            hungerTimeRemainder = 0,
            hungerLastUpdateTime = nil,
            thirst = 0,
            thirstTimeRemainder = 0,
            thirstLastUpdateTime = nil,
            sleep = 0,
            sleepTimeRemainder = 0,
            sleepLastUpdateTime = nil,
            temperature = 0,
            temperatureTimeRemainder = 0,
            temperatureLastUpdateTime = nil,
            temperatureWarmModifier = 0,
            temperatureColdModifier = 0,
            temperatureModifierEntries = {},
            temperatureTotalWarm = 0,
            temperatureTotalCold = 0,
            temperatureTotalModifier = 0,
            temperatureCappedModifier = 0,
            temperatureCurrentTickAmount = 0,
            temperatureCurrentTickMultiplier = 1.0,
            temperatureUsesInteriorBase = false,
            temperatureRegionCategory = 'neutral',
            sleepWellRestedBonusEligible = true,
            sleepWellRestedBonusMultiplier = 1.0,
            temperatureActiveWeatherKey = nil,
            temperatureModifierTrackedWeatherKey = '',
            temperatureModifierTrackedEquipmentSignature = '',
            temperaturemultiplier = temperatureDebug.createTemperaturemultiplier(),
            restUiSession = nil,
            travelUiSession = nil,
            isInCombat = false,
            isOrc = nil,
            needsDebuffSpellApplyFailures = {},
            knownNeedsDynamicSpellIds = {},
            trackedNeedsDynamicSpellIdsByCategory = buildTrackedByCategory(),
            appliedNeedsDynamicSpellByCategory = buildNilByCategory(),
            appliedNeedsDynamicStageByCategory = buildNilByCategory(),
            pendingNeedsDynamicRequestByCategory = buildNilByCategory(),
            restoreSkillEffectActive = false,
            skillDamageSnapshotById = {},
            skillDamageScanElapsedSeconds = 0,
            debuffUpdateElapsedSeconds = 0,
            sluggishUpdateJobIndex = 1,
            needsDynamicRequestCounter = 0,
            legacyNeedsSpellCleanupDone = false,
            runtimeModuleErrors = {},
            lastExteriorRegionTransitionKey = nil,
            regionTransitionElapsedRealSeconds = nil,
            regionTransitionAppliedWarmModifier = 0,
            regionTransitionAppliedColdModifier = 0,
            regionTransitionAppliedArmorWarmModifier = 0,
            regionTransitionAppliedClothingWarmModifier = 0,
            skipNextRegionTransitionDelay = false,
            lastHungerStageId = nil,
            lastThirstStageId = nil,
            lastSleepStageId = nil,
            lastTemperatureStageId = nil,
            lastHbfsDisableConjurationDrain = nil,
            lastDebugLoggingEnabled = nil,
            lastHungerSystemEnabled = nil,
            lastThirstSystemEnabled = nil,
            lastSleepSystemEnabled = nil,
            lastTemperatureSystemEnabled = nil,
            cellInfoLastRequestTime = -math.huge,
            cellInfoLastRequestedCellId = '',
            cellInfoLastRequestedCellCacheKey = '',
            cellInfoRequestCooldownSeconds = 0,
            cellInfoRequestIntervalSeconds = resolveCellInfoRequestIntervalSeconds(),
            temperatureUpdateIntervalSeconds = resolveTemperatureUpdateIntervalSeconds(),
        }
    end

    function api.resetDynamicSpellTracking(state)
        state.needsDebuffSpellApplyFailures = {}
        state.knownNeedsDynamicSpellIds = {}
        state.trackedNeedsDynamicSpellIdsByCategory = buildTrackedByCategory()
        state.appliedNeedsDynamicSpellByCategory = buildNilByCategory()
        state.appliedNeedsDynamicStageByCategory = buildNilByCategory()
        state.pendingNeedsDynamicRequestByCategory = buildNilByCategory()
        state.restoreSkillEffectActive = false
        state.skillDamageSnapshotById = {}
        state.skillDamageScanElapsedSeconds = 0
        state.needsDynamicRequestCounter = 0
        state.legacyNeedsSpellCleanupDone = false
    end

    function api.hydrateKnownNeedsDynamicSpellIds(state, savedDataKnownSpellIds, trim)
        state.knownNeedsDynamicSpellIds = {}
        if type(savedDataKnownSpellIds) ~= 'table' then
            return
        end

        for spellId, enabled in pairs(savedDataKnownSpellIds) do
            if enabled == true then
                local idString = trim(tostring(spellId or ''))
                if idString ~= '' then
                    state.knownNeedsDynamicSpellIds[idString] = true
                end
            end
        end
    end

    function api.resetRuntimeFlagsOnLoad(state)
        state.restUiSession = nil
        state.travelUiSession = nil
        state.isInCombat = false
        state.lastHungerStageId = nil
        state.lastThirstStageId = nil
        state.lastSleepStageId = nil
        state.lastTemperatureStageId = nil
        state.lastHbfsDisableConjurationDrain = nil
        state.lastDebugLoggingEnabled = nil
        state.lastHungerSystemEnabled = nil
        state.lastThirstSystemEnabled = nil
        state.lastSleepSystemEnabled = nil
        state.lastTemperatureSystemEnabled = nil
        state.restoreSkillEffectActive = false
        state.skillDamageSnapshotById = {}
        state.skillDamageScanElapsedSeconds = 0
        state.debuffUpdateElapsedSeconds = 0
        state.sluggishUpdateJobIndex = 1
        state.temperatureModifierTrackedWeatherKey = ''
        state.temperatureModifierTrackedEquipmentSignature = ''
        state.runtimeModuleErrors = {}
    end

    return api
end

function M.createRuntimeInit(deps)
    local state = assert(deps.state)
    local now = assert(deps.now)
    local hungerSystemApi = assert(deps.hungerSystemApi)
    local thirstSystemApi = assert(deps.thirstSystemApi)
    local getInitialNeedValue = assert(deps.getInitialNeedValue)
    local hungerStages = assert(deps.hungerStages)
    local thirstStages = assert(deps.thirstStages)
    local sleepStages = assert(deps.sleepStages)
    local hungerInitialValueFallback = assert(tonumber(deps.hungerInitialValueFallback))
    local thirstInitialValueFallback = assert(tonumber(deps.thirstInitialValueFallback))
    local sleepInitialValueFallback = assert(tonumber(deps.sleepInitialValueFallback))
    local clamp = assert(deps.clamp)
    local sleepMax = assert(tonumber(deps.sleepMax))
    local selfObject = assert(deps.self)
    local types = assert(deps.types)

    local api = {}

    function api.ensureInitialized()
        local currentTime = now()
        local needsRuntimeUninitialized = state.hungerLastUpdateTime == nil
            and state.thirstLastUpdateTime == nil
            and state.sleepLastUpdateTime == nil
            and state.temperatureLastUpdateTime == nil

        if needsRuntimeUninitialized then
            hungerSystemApi.resetToInitialState(
                currentTime,
                getInitialNeedValue,
                hungerStages,
                hungerInitialValueFallback
            )
            thirstSystemApi.resetToInitialState(
                currentTime,
                getInitialNeedValue,
                thirstStages,
                thirstInitialValueFallback
            )
            state.sleep = clamp(getInitialNeedValue(sleepStages, sleepInitialValueFallback), 0, sleepMax)
            state.temperature = 0
            state.sleepTimeRemainder = 0
            state.temperatureTimeRemainder = 0
        end

        if state.hungerLastUpdateTime == nil then
            state.hungerLastUpdateTime = currentTime
        end

        if state.thirstLastUpdateTime == nil then
            state.thirstLastUpdateTime = currentTime
        end

        if state.sleepLastUpdateTime == nil then
            state.sleepLastUpdateTime = currentTime
        end

        if state.temperatureLastUpdateTime == nil then
            state.temperatureLastUpdateTime = currentTime
        end

        if state.isOrc == nil then
            local raceId = ''
            if types.NPC.objectIsInstance(selfObject) then
                local record = types.NPC.record(selfObject)
                if record ~= nil and record.race ~= nil then
                    raceId = string.lower(tostring(record.race))
                end
            end

            state.isOrc = raceId == 'orc'
        end
    end

    return api
end

return M
