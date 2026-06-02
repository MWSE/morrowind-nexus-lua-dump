local M = {}

function M.create(deps)
    local state = assert(deps.state)
    local now = assert(deps.now)
    local clamp = assert(deps.clamp)
    local trim = assert(deps.trim)
    local getInitialNeedValue = assert(deps.getInitialNeedValue)
    local hungerSystemApi = assert(deps.hungerSystemApi)
    local thirstSystemApi = assert(deps.thirstSystemApi)
    local temperatureRuntimeApi = assert(deps.temperatureRuntimeApi)
    local playerStateApi = assert(deps.playerStateApi)
    local playerHudControllerApi = assert(deps.playerHudControllerApi)
    local wetnessSystem = assert(deps.wetnessSystem)
    local abilitiesApi = assert(deps.abilitiesApi)
    local syncDebugLoggingState = assert(deps.syncDebugLoggingState)
    local updateSystems = assert(deps.updateSystems)
    local invalidateHud = assert(deps.invalidateHud)
    local resetWarmthAbility = assert(deps.resetWarmthAbility)
    local resetWetnessHud = assert(deps.resetWetnessHud)
    local resetTemperatureScreenEffect = assert(deps.resetTemperatureScreenEffect)
    local hungerStages = assert(deps.hungerStages)
    local thirstStages = assert(deps.thirstStages)
    local sleepStages = assert(deps.sleepStages)
    local sleepMax = assert(tonumber(deps.sleepMax))
    local hungerInitialValueFallback = assert(tonumber(deps.hungerInitialValueFallback))
    local thirstInitialValueFallback = assert(tonumber(deps.thirstInitialValueFallback))
    local sleepInitialValueFallback = assert(tonumber(deps.sleepInitialValueFallback))

    local api = {}

    function api.resetNeedsAfterJail()
        local currentTime = now()
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
        state.sleepTimeRemainder = 0
        state.sleepLastUpdateTime = currentTime
        state.sleepWellRestedBonusMultiplier = 1.0
        temperatureRuntimeApi.resetTemperatureToDefault(currentTime)
        wetnessSystem.reset()
        resetWetnessHud()
        resetTemperatureScreenEffect()
        invalidateHud()
        updateSystems()
    end

    function api.onSave()
        local hungerSaveData = hungerSystemApi.saveState()
        local thirstSaveData = thirstSystemApi.saveState()
        local temperatureSaveData = temperatureRuntimeApi.saveTemperatureState()
        return {
            hunger = hungerSaveData.hunger,
            hungerTimeRemainder = hungerSaveData.hungerTimeRemainder,
            hungerLastUpdateTime = hungerSaveData.hungerLastUpdateTime,
            thirst = thirstSaveData.thirst,
            thirstTimeRemainder = thirstSaveData.thirstTimeRemainder,
            thirstLastUpdateTime = thirstSaveData.thirstLastUpdateTime,
            sleep = state.sleep,
            sleepTimeRemainder = state.sleepTimeRemainder,
            sleepLastUpdateTime = state.sleepLastUpdateTime,
            sleepWellRestedBonusEligible = state.sleepWellRestedBonusEligible,
            sleepWellRestedBonusMultiplier = state.sleepWellRestedBonusMultiplier,
            temperature = temperatureSaveData.temperature,
            temperatureTimeRemainder = temperatureSaveData.temperatureTimeRemainder,
            temperatureLastUpdateTime = temperatureSaveData.temperatureLastUpdateTime,
            temperatureActiveWeatherKey = temperatureSaveData.temperatureActiveWeatherKey,
            temperaturemultiplier = temperatureSaveData.temperaturemultiplier,
            wetness = wetnessSystem.onSave(),
            knownNeedsDynamicSpellIds = state.knownNeedsDynamicSpellIds,
        }
    end

    function api.onLoad(savedData)
        local currentTime = now()
        temperatureRuntimeApi.resetCellInfoState()
        playerStateApi.resetRuntimeFlagsOnLoad(state)
        temperatureRuntimeApi.resetRegionTransitionState(true)

        if type(savedData) ~= 'table' then
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
            state.sleepTimeRemainder = 0
            state.sleepLastUpdateTime = currentTime
            state.sleepWellRestedBonusEligible = true
            state.sleepWellRestedBonusMultiplier = 1.0
            temperatureRuntimeApi.resetTemperatureToDefault(currentTime)
            playerStateApi.resetDynamicSpellTracking(state)
            playerHudControllerApi.resetTransientState()
            wetnessSystem.onLoad(nil)
            resetWetnessHud()
            resetTemperatureScreenEffect()
            resetWarmthAbility(state.knownNeedsDynamicSpellIds)
            syncDebugLoggingState(true)
            temperatureRuntimeApi.requestCellInfoFromGlobal(true)
            updateSystems()
            return
        end

        hungerSystemApi.loadState(
            savedData,
            currentTime,
            getInitialNeedValue,
            hungerStages,
            hungerInitialValueFallback
        )
        thirstSystemApi.loadState(
            savedData,
            currentTime,
            getInitialNeedValue,
            thirstStages,
            thirstInitialValueFallback
        )

        state.sleep = clamp(
            tonumber(savedData.sleep) or getInitialNeedValue(sleepStages, sleepInitialValueFallback),
            0,
            sleepMax
        )
        state.sleepTimeRemainder = math.max(0, tonumber(savedData.sleepTimeRemainder) or 0)
        state.sleepLastUpdateTime = tonumber(savedData.sleepLastUpdateTime) or currentTime
        state.sleepWellRestedBonusEligible = savedData.sleepWellRestedBonusEligible ~= false
        state.sleepWellRestedBonusMultiplier = math.max(1.0, tonumber(savedData.sleepWellRestedBonusMultiplier) or 1.0)
        temperatureRuntimeApi.loadTemperatureState(savedData, currentTime)
        playerStateApi.resetDynamicSpellTracking(state)
        playerStateApi.hydrateKnownNeedsDynamicSpellIds(state, savedData.knownNeedsDynamicSpellIds, trim)
        playerHudControllerApi.resetTransientState()
        wetnessSystem.onLoad(savedData.wetness)
        resetWetnessHud()
        resetTemperatureScreenEffect()
        resetWarmthAbility(state.knownNeedsDynamicSpellIds)
        abilitiesApi.resetLearningAndTemperatureCategories()

        syncDebugLoggingState(true)
        temperatureRuntimeApi.requestCellInfoFromGlobal(true)
        updateSystems()
    end

    return api
end

return M
