local M = {}

function M.create(deps)
    local state = assert(deps.state)
    local core = assert(deps.core)
    local self = assert(deps.self)
    local types = assert(deps.types)
    local clamp = assert(deps.clamp)
    local normalizeKey = assert(deps.normalizeKey)
    local temperature = assert(deps.temperature)
    local temperatureDebug = assert(deps.temperatureDebug)
    local temperatureBalanceConfig = deps.temperatureBalanceConfig
    local wetnessSystem = assert(deps.wetnessSystem)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local isTemperatureBasedHealthPenaltiesEnabled = assert(deps.isTemperatureBasedHealthPenaltiesEnabled)
    local getDynamicMaxValue = assert(deps.getDynamicMaxValue)
    local clearNeedDynamicCategories = assert(deps.clearNeedDynamicCategories)
    local resetNeedIconState = assert(deps.resetNeedIconState)
    local now = assert(deps.now)
    local trim = assert(deps.trim)

    local api = {}
    local CELL_INFO_REQUEST_EVENT = 'SurvivalNeeds_RequestCellInfo'
    local UPSERT_DYNAMIC_HEAT_SOURCE_EVENT = 'SurvivalNeeds_UpsertDynamicHeatSource'
    local REMOVE_DYNAMIC_HEAT_SOURCE_EVENT = 'SurvivalNeeds_RemoveDynamicHeatSource'
    local DEFAULT_MODIFIER_REFRESH_INTERVAL_REAL_SECONDS = 0.25
    local MIN_MODIFIER_REFRESH_INTERVAL_REAL_SECONDS = 0.05
    local modifierStateCache = nil
    local modifierBuildElapsedAccumulator = 0
    local modifierRefreshCooldownRealSeconds = 0
    local modifierRefreshPending = true
    local modifierTrackedCellCacheKey = ''
    local modifierTrackedWeatherKey = ''
    local modifierTrackedEquipmentSignature = ''
    local observedCellObject = nil
    local observedCellCacheKey = ''
    local teleportTransitionBypassQueued = false
    local teleportTransitionBypassExpiresAt = -math.huge

    local function getCellCacheKey(cell)
        if cell == nil then
            return ''
        end

        local gridX = nil
        local gridY = nil
        pcall(function()
            gridX = tonumber(cell.gridX)
            gridY = tonumber(cell.gridY)
        end)
        if gridX ~= nil and gridY ~= nil then
            return string.format('grid:%d:%d', math.floor(gridX), math.floor(gridY))
        end

        local cellId = ''
        pcall(function()
            cellId = normalizeKey(trim(tostring(cell.id or '')))
        end)
        if cellId ~= '' then
            return cellId
        end

        local fallback = ''
        pcall(function()
            fallback = normalizeKey(trim(tostring(cell)))
        end)
        return fallback
    end

    local function buildEmptyModifierState()
        return {
            entries = {},
            warm = 0,
            cold = 0,
            total = 0,
            cappedTotal = 0,
            currentTickAmount = 0,
            usesInteriorBase = false,
            regionCategory = 'neutral',
            targetTemperatureBeforeArmorBonus = 0,
            campfireWarmModifier = 0,
            campfireDominantSourceType = '',
        }
    end

    local function resolveModifierRefreshIntervalRealSeconds()
        local configuredInterval = nil
        if type(temperatureBalanceConfig) == 'table' then
            local modifierPipeline = temperatureBalanceConfig.modifierPipeline
            if type(modifierPipeline) == 'table' then
                configuredInterval = tonumber(modifierPipeline.refreshIntervalSeconds)
            end
        end

        return math.max(
            MIN_MODIFIER_REFRESH_INTERVAL_REAL_SECONDS,
            configuredInterval or DEFAULT_MODIFIER_REFRESH_INTERVAL_REAL_SECONDS
        )
    end

    local modifierRefreshIntervalRealSeconds = resolveModifierRefreshIntervalRealSeconds()

    local function getCellSnapshot()
        local currentCell = self.cell
        local currentCellId = ''
        local currentCellCacheKey = ''
        if currentCell ~= nil then
            local idOk = pcall(function()
                currentCellId = normalizeKey(trim(tostring(currentCell.id or '')))
            end)
            if not idOk then
                currentCellId = ''
            end
            currentCellCacheKey = getCellCacheKey(currentCell)
        end
        return currentCell, currentCellId, currentCellCacheKey
    end

    local function getCurrentCellId()
        local _, currentCellId = getCellSnapshot()
        return currentCellId
    end

    local function getCurrentCellCacheKey()
        local _, _, currentCellCacheKey = getCellSnapshot()
        return currentCellCacheKey
    end

    local function normalizeElapsedSeconds(elapsedSeconds)
        local elapsed = tonumber(elapsedSeconds) or 0
        if elapsed < 0 then
            return 0
        end
        return elapsed
    end

    local function getCurrentWeatherKey()
        if type(temperatureDebug.getCurrentWeatherRecord) ~= 'function'
            or type(temperatureDebug.getCanonicalWeatherKey) ~= 'function' then
            return normalizeKey(state.temperatureActiveWeatherKey)
        end

        local weatherRecordOk, weatherRecord = pcall(temperatureDebug.getCurrentWeatherRecord)
        if not weatherRecordOk then
            return normalizeKey(state.temperatureActiveWeatherKey)
        end
        if weatherRecord == nil then
            return ''
        end

        local weatherKeyOk, weatherKey = pcall(temperatureDebug.getCanonicalWeatherKey, weatherRecord)
        if not weatherKeyOk then
            return normalizeKey(state.temperatureActiveWeatherKey)
        end
        return normalizeKey(weatherKey)
    end

    local function getEquippedItemSignature(equippedItem)
        if equippedItem == nil then
            return ''
        end

        local idCandidates = {}
        local recordIdOk, recordIdValue = pcall(function()
            return equippedItem.recordId
        end)
        if recordIdOk and recordIdValue ~= nil then
            idCandidates[#idCandidates + 1] = tostring(recordIdValue)
        end

        local idOk, idValue = pcall(function()
            return equippedItem.id
        end)
        if idOk and idValue ~= nil then
            idCandidates[#idCandidates + 1] = tostring(idValue)
        end

        local nameOk, nameValue = pcall(function()
            return equippedItem.name
        end)
        if nameOk and nameValue ~= nil then
            idCandidates[#idCandidates + 1] = tostring(nameValue)
        end

        for _, candidate in ipairs(idCandidates) do
            local normalized = normalizeKey(trim(candidate))
            if normalized ~= '' then
                return normalized
            end
        end

        return ''
    end

    local function buildEquipmentSignature()
        if type(types.Actor) ~= 'table'
            or type(types.Actor.objectIsInstance) ~= 'function'
            or type(types.Actor.getEquipment) ~= 'function'
            or not types.Actor.objectIsInstance(self) then
            return ''
        end

        local equipmentOk, equipmentTable = pcall(types.Actor.getEquipment, self)
        if not equipmentOk or (type(equipmentTable) ~= 'table' and type(equipmentTable) ~= 'userdata') then
            return ''
        end

        local signatureParts = {}
        for slotId, equippedItem in pairs(equipmentTable) do
            local slotKey = tostring(slotId)
            local itemSignature = getEquippedItemSignature(equippedItem)
            signatureParts[#signatureParts + 1] = slotKey .. '=' .. itemSignature
        end
        table.sort(signatureParts)
        return table.concat(signatureParts, '|')
    end

    local function toRealElapsedSeconds(elapsedSeconds)
        local elapsed = normalizeElapsedSeconds(elapsedSeconds)
        if elapsed <= 0 then
            return 0
        end
        if type(temperatureDebug.toRealSeconds) == 'function' then
            return math.max(0, tonumber(temperatureDebug.toRealSeconds(elapsed)) or 0)
        end
        return elapsed
    end

    local function markModifierRefreshPending()
        modifierRefreshPending = true
        modifierRefreshCooldownRealSeconds = 0
    end

    local function resetModifierRefreshScheduler()
        modifierStateCache = nil
        modifierBuildElapsedAccumulator = 0
        modifierRefreshCooldownRealSeconds = 0
        modifierRefreshPending = true
        modifierTrackedCellCacheKey = getCurrentCellCacheKey()
        modifierTrackedWeatherKey = getCurrentWeatherKey()
        modifierTrackedEquipmentSignature = buildEquipmentSignature()
        state.temperatureModifierTrackedWeatherKey = modifierTrackedWeatherKey
        state.temperatureModifierTrackedEquipmentSignature = modifierTrackedEquipmentSignature
    end

    local function resetRuntimeDerivedState()
        state.temperatureWarmModifier = 0
        state.temperatureColdModifier = 0
        state.temperatureModifierEntries = {}
        state.temperatureTotalWarm = 0
        state.temperatureTotalCold = 0
        state.temperatureTotalModifier = 0
        state.temperatureCappedModifier = 0
        state.temperatureCurrentTickAmount = 0
        state.temperatureCurrentTickMultiplier = 1.0
        state.temperatureUsesInteriorBase = false
        state.temperatureRegionCategory = 'neutral'
        state.temperatureModifierTrackedWeatherKey = ''
        state.temperatureModifierTrackedEquipmentSignature = ''
        state.temperaturemultiplier = temperatureDebug.createTemperaturemultiplier()
        resetModifierRefreshScheduler()
    end

    local function getTemperatureMinValue()
        return tonumber(temperature.system.TEMPERATURE_MIN) or -400
    end

    local function getTemperatureMaxValue()
        return tonumber(temperature.system.TEMPERATURE_MAX) or 400
    end

    local function resetLatestCellInfoCache()
        if temperature ~= nil
            and type(temperature.config) == 'table'
            and type(temperature.config.resetLatestCellInfo) == 'function' then
            temperature.config.resetLatestCellInfo()
        end
    end

    function api.applyHealthDrain(temperatureStage, elapsedSeconds, ignorePause)
        if not isTemperatureSystemEnabled()
            or not isTemperatureBasedHealthPenaltiesEnabled()
            or type(temperatureStage) ~= 'table'
            or not types.Actor.objectIsInstance(self) then
            return
        end

        if (ignorePause ~= true and core.isWorldPaused()) or types.Actor.isDead(self) then
            return
        end

        if state.restUiSession ~= nil and state.restUiSession.active == true then
            return
        end

        local step = tonumber(elapsedSeconds) or 0
        if step > 0 then
            step = temperatureDebug.toRealSeconds(step)
        end
        if step <= 0 then
            return
        end

        local healthStat = types.Actor.stats.dynamic.health(self)
        if healthStat == nil then
            return
        end

        local currentHealth = tonumber(healthStat.current) or 0
        if currentHealth <= 0 then
            return
        end

        local maxHealth = getDynamicMaxValue(healthStat)
        if maxHealth <= 0 then
            return
        end

        local temperatureValue = tonumber(state.temperature) or 0
        local healthLossPct, drainPerSecond =
            temperatureDebug.getTemperatureHealthDrainProfile(temperatureValue, temperatureStage)
        if healthLossPct <= 0 then
            return
        end
        local floorPct = 100 - healthLossPct
        local minimumHealth = maxHealth * (floorPct / 100)
        if currentHealth <= minimumHealth then
            return
        end

        local drainPointsPerSecond = maxHealth * (drainPerSecond / 100)
        local nextHealth = currentHealth - (drainPointsPerSecond * step)
        if floorPct > 0 then
            nextHealth = math.max(minimumHealth, nextHealth)
        else
            nextHealth = math.max(0, nextHealth)
        end

        if nextHealth < currentHealth then
            healthStat.current = nextHealth
        end
    end

    function api.resetRuntimeState()
        state.temperatureTimeRemainder = 0
        resetRuntimeDerivedState()
    end

    function api.resetTemperatureToDefault(currentTime)
        state.temperature = 0
        state.temperatureTimeRemainder = 0
        state.temperatureLastUpdateTime = currentTime
        state.temperatureActiveWeatherKey = nil
        resetRuntimeDerivedState()
    end

    function api.loadTemperatureState(savedData, currentTime)
        state.temperature = clamp(tonumber(savedData and savedData.temperature) or 0, getTemperatureMinValue(), getTemperatureMaxValue())
        state.temperatureTimeRemainder = math.max(0, tonumber(savedData and savedData.temperatureTimeRemainder) or 0)
        state.temperatureLastUpdateTime = tonumber(savedData and savedData.temperatureLastUpdateTime) or currentTime
        state.temperatureActiveWeatherKey = normalizeKey(savedData and savedData.temperatureActiveWeatherKey)
        if state.temperatureActiveWeatherKey == '' then
            state.temperatureActiveWeatherKey = nil
        end
        resetRuntimeDerivedState()
        state.temperaturemultiplier = temperatureDebug.hydrateTemperaturemultiplier(savedData and savedData.temperaturemultiplier)
    end

    function api.saveTemperatureState()
        return {
            temperature = state.temperature,
            temperatureTimeRemainder = state.temperatureTimeRemainder,
            temperatureLastUpdateTime = state.temperatureLastUpdateTime,
            temperatureActiveWeatherKey = state.temperatureActiveWeatherKey,
            temperaturemultiplier = state.temperaturemultiplier,
        }
    end

    function api.resetRegionTransitionState(skipNextTransitionDelay)
        state.lastExteriorRegionTransitionKey = nil
        state.regionTransitionElapsedRealSeconds = nil
        state.regionTransitionAppliedWarmModifier = 0
        state.regionTransitionAppliedColdModifier = 0
        state.regionTransitionAppliedArmorWarmModifier = 0
        state.regionTransitionAppliedClothingWarmModifier = 0
        state.skipNextRegionTransitionDelay = skipNextTransitionDelay == true
    end

    function api.markSkipNextRegionTransitionDelay()
        state.skipNextRegionTransitionDelay = true
    end

    function api.clearSystemState(currentTime)
        state.temperatureLastUpdateTime = currentTime
        state.lastTemperatureStageId = nil
        resetNeedIconState('temperature')
        api.resetRuntimeState()
        clearNeedDynamicCategories({
            'temperature_hunger_misc',
            'temperature_thirst_misc',
            'temperature_slowness_misc',
            'temperature_health_misc',
            'temperature_weakness',
        })
        resetLatestCellInfoCache()
        api.resetCellInfoTracking()
    end

    function api.resetCellInfoTracking()
        state.cellInfoLastRequestTime = -math.huge
        state.cellInfoLastRequestedCellId = ''
        state.cellInfoLastRequestedCellCacheKey = ''
        state.cellInfoRequestCooldownSeconds = 0
        teleportTransitionBypassQueued = false
        teleportTransitionBypassExpiresAt = -math.huge
        observedCellObject, _, observedCellCacheKey = getCellSnapshot()
        markModifierRefreshPending()
    end

    function api.resetCellInfoState()
        resetLatestCellInfoCache()
        api.resetCellInfoTracking()
    end

    function api.requestCellInfoFromGlobal(force)
        local currentTime = now()
        local _, currentCellId, currentCellCacheKey = getCellSnapshot()

        if force ~= true then
            local configuredInterval = math.max(0.05, tonumber(state.cellInfoRequestIntervalSeconds) or 0.5)
            local elapsedSinceLastRequest = currentTime - (tonumber(state.cellInfoLastRequestTime) or -math.huge)
            local lastRequestedCellCacheKey = normalizeKey(state.cellInfoLastRequestedCellCacheKey)
            local cellChanged = currentCellCacheKey ~= '' and currentCellCacheKey ~= lastRequestedCellCacheKey
            if not cellChanged and elapsedSinceLastRequest < configuredInterval then
                return
            end
        end

        local playerObject = self.object or self
        local ok = pcall(function()
            core.sendGlobalEvent(CELL_INFO_REQUEST_EVENT, {
                player = playerObject,
                cellId = currentCellId,
                cellCacheKey = currentCellCacheKey,
            })
        end)
        if not ok then
            return
        end

        state.cellInfoLastRequestTime = currentTime
        if currentCellId ~= '' then
            state.cellInfoLastRequestedCellId = currentCellId
        end
        if currentCellCacheKey ~= '' then
            state.cellInfoLastRequestedCellCacheKey = currentCellCacheKey
        end
    end

    function api.tickCellInfoRequestCooldown(step)
        local currentCell, _, currentCellCacheKey = getCellSnapshot()
        if currentCell == nil or currentCellCacheKey == '' then
            observedCellObject = nil
            observedCellCacheKey = ''
            state.cellInfoRequestCooldownSeconds = 0
            return
        end

        if currentCell ~= observedCellObject or currentCellCacheKey ~= observedCellCacheKey then
            observedCellObject = currentCell
            observedCellCacheKey = currentCellCacheKey
            if teleportTransitionBypassQueued then
                if now() < teleportTransitionBypassExpiresAt then
                    api.markSkipNextRegionTransitionDelay()
                end
                teleportTransitionBypassQueued = false
                teleportTransitionBypassExpiresAt = -math.huge
            end
            api.requestCellInfoFromGlobal(true)
        else
            state.cellInfoRequestCooldownSeconds = 0
        end
    end

    function api.queueTeleportRegionTransitionBypass()
        teleportTransitionBypassQueued = true
        teleportTransitionBypassExpiresAt = now() + 2.0
    end

    function api.upsertDynamicHeatSource(source, cellCacheKey)
        if type(source) ~= 'table' then
            return
        end
        local playerObject = self.object or self
        local _, currentCellId, currentCellCacheKey = getCellSnapshot()
        local resolvedCellCacheKey = normalizeKey(cellCacheKey)
        if resolvedCellCacheKey == '' then
            resolvedCellCacheKey = currentCellCacheKey
        end
        pcall(function()
            core.sendGlobalEvent(UPSERT_DYNAMIC_HEAT_SOURCE_EVENT, {
                player = playerObject,
                cellId = currentCellId,
                cellCacheKey = resolvedCellCacheKey,
                source = source,
            })
        end)
    end

    function api.removeDynamicHeatSource(source, cellCacheKey)
        if type(source) ~= 'table' then
            return
        end
        local playerObject = self.object or self
        local _, currentCellId, currentCellCacheKey = getCellSnapshot()
        local resolvedCellCacheKey = normalizeKey(cellCacheKey)
        if resolvedCellCacheKey == '' then
            resolvedCellCacheKey = currentCellCacheKey
        end
        pcall(function()
            core.sendGlobalEvent(REMOVE_DYNAMIC_HEAT_SOURCE_EVENT, {
                player = playerObject,
                cellId = currentCellId,
                cellCacheKey = resolvedCellCacheKey,
                source = source,
            })
        end)
    end

    function api.setLatestCellInfo(data)
        if type(data) ~= 'table' then
            return
        end
        if temperature ~= nil
            and type(temperature.config) == 'table'
            and type(temperature.config.setLatestCellInfo) == 'function' then
            temperature.config.setLatestCellInfo(data)
        end
        markModifierRefreshPending()
    end

    function api.markModifierStateDirty()
        markModifierRefreshPending()
    end

    function api.applyTravelTemperatureCatchup(elapsedSeconds)
        if not isTemperatureSystemEnabled() then
            return
        end

        local elapsed = tonumber(elapsedSeconds) or 0
        if elapsed <= 0 then
            return
        end

        api.advanceByElapsed(elapsed, api.refreshModifierState(elapsed, true), true)

        local snappedTargetTemperature = tonumber(state.temperatureCappedModifier)
            or tonumber(state.temperatureTotalModifier)
            or tonumber(state.temperature)
            or 0
        state.temperature = clamp(
            snappedTargetTemperature,
            getTemperatureMinValue(),
            getTemperatureMaxValue()
        )
        state.temperatureTimeRemainder = 0
        temperatureDebug.clearTemperaturemultiplier()
        state.temperatureCurrentTickMultiplier = 1.0
    end

    function api.applyModifierState(temperatureModifierState)
        local modifierState = type(temperatureModifierState) == 'table' and temperatureModifierState or {}
        state.temperatureModifierEntries = modifierState.entries or {}
        state.temperatureTotalWarm = tonumber(modifierState.warm) or 0
        state.temperatureTotalCold = tonumber(modifierState.cold) or 0
        state.temperatureTotalModifier = tonumber(modifierState.total) or 0
        state.temperatureCappedModifier = tonumber(modifierState.cappedTotal) or 0
        state.temperatureCurrentTickAmount = tonumber(modifierState.currentTickAmount) or 0
        state.temperatureUsesInteriorBase = modifierState.usesInteriorBase == true
        state.temperatureRegionCategory = normalizeKey(modifierState.regionCategory)
        if state.temperatureRegionCategory == '' then
            state.temperatureRegionCategory = 'neutral'
        end
        state.temperatureWarmModifier = state.temperatureTotalWarm
        state.temperatureColdModifier = state.temperatureTotalCold
    end

    function api.refreshModifierState(elapsedSeconds, forceRefresh)
        if not isTemperatureSystemEnabled() then
            api.resetRuntimeState()
            modifierStateCache = buildEmptyModifierState()
            return modifierStateCache
        end

        local elapsed = normalizeElapsedSeconds(elapsedSeconds)
        local realElapsed = toRealElapsedSeconds(elapsed)
        modifierBuildElapsedAccumulator = modifierBuildElapsedAccumulator + elapsed
        modifierRefreshCooldownRealSeconds = math.max(0, modifierRefreshCooldownRealSeconds - realElapsed)

        local currentCellCacheKey = getCurrentCellCacheKey()
        if currentCellCacheKey ~= modifierTrackedCellCacheKey then
            modifierTrackedCellCacheKey = currentCellCacheKey
            markModifierRefreshPending()
        end
        if type(wetnessSystem.hasPendingImmediateTemperatureTick) == 'function'
            and wetnessSystem.hasPendingImmediateTemperatureTick() then
            markModifierRefreshPending()
        end

        local shouldCheckDynamicSignatures = forceRefresh == true
            or modifierStateCache == nil
            or modifierRefreshPending
            or modifierRefreshCooldownRealSeconds <= 0
        if shouldCheckDynamicSignatures then
            local currentWeatherKey = getCurrentWeatherKey()
            if currentWeatherKey ~= modifierTrackedWeatherKey then
                modifierTrackedWeatherKey = currentWeatherKey
                markModifierRefreshPending()
            end

            local equipmentSignature = buildEquipmentSignature()
            if equipmentSignature ~= modifierTrackedEquipmentSignature then
                modifierTrackedEquipmentSignature = equipmentSignature
                markModifierRefreshPending()
            end

            state.temperatureModifierTrackedWeatherKey = modifierTrackedWeatherKey
            state.temperatureModifierTrackedEquipmentSignature = modifierTrackedEquipmentSignature
        end

        local shouldRefresh = forceRefresh == true
            or modifierStateCache == nil
            or modifierRefreshPending
            or modifierRefreshCooldownRealSeconds <= 0
        if shouldRefresh then
            local elapsedForBuild = modifierBuildElapsedAccumulator
            modifierBuildElapsedAccumulator = 0
            modifierRefreshPending = false
            modifierRefreshCooldownRealSeconds = modifierRefreshIntervalRealSeconds
            local temperatureModifierState = temperatureDebug.buildModifierState(elapsedForBuild)
            api.applyModifierState(temperatureModifierState)
            modifierStateCache = temperatureModifierState
            return temperatureModifierState
        end

        if type(modifierStateCache) ~= 'table' then
            modifierStateCache = buildEmptyModifierState()
        end
        api.applyModifierState(modifierStateCache)
        return modifierStateCache
    end

    function api.advanceByElapsed(elapsedSeconds, temperatureModifierState, allowBurstTicks)
        if not isTemperatureSystemEnabled() then
            api.resetRuntimeState()
            return
        end
        local elapsed = tonumber(elapsedSeconds) or 0
        if elapsed < 0 then
            elapsed = 0
        end
        local shouldAllowBurstTicks = allowBurstTicks == true

        if elapsed <= 0 and not (type(wetnessSystem.hasPendingImmediateTemperatureTick) == 'function'
            and wetnessSystem.hasPendingImmediateTemperatureTick()) then
            return
        end

        if type(temperatureModifierState) == 'table' then
            api.applyModifierState(temperatureModifierState)
        else
            local hasPendingImmediateTick = type(wetnessSystem.hasPendingImmediateTemperatureTick) == 'function'
                and wetnessSystem.hasPendingImmediateTemperatureTick()
            api.refreshModifierState(elapsed, hasPendingImmediateTick)
        end

        local immediateTickCount = 0
        local isTemperatureDecreasing = (tonumber(state.temperatureCurrentTickAmount) or 0) < 0
        if type(wetnessSystem.consumeImmediateTemperatureTicks) == 'function' then
            immediateTickCount = math.max(0, math.floor(tonumber(wetnessSystem.consumeImmediateTemperatureTicks()) or 0))
            if not isTemperatureDecreasing then
                immediateTickCount = 0
            end
        end

        if elapsed <= 0 and immediateTickCount <= 0 then
            return
        end

        local tickMultiplier = temperatureDebug.getCurrentTemperatureTickMultiplier(elapsed)
        local maxTicksPerAdvance = nil
        if not shouldAllowBurstTicks then
            maxTicksPerAdvance = 1
        end
        if elapsed > 0 then
            state.temperature, state.temperatureTimeRemainder = temperature.system.advanceTemperature(
                state.temperature,
                state.temperatureTimeRemainder,
                elapsed,
                state.temperatureWarmModifier,
                state.temperatureColdModifier,
                tickMultiplier,
                maxTicksPerAdvance
            )
        end

        if immediateTickCount > 0 then
            local tickSeconds = tonumber(temperature.system.TEMPERATURE_TICK_SECONDS) or 0
            if tickSeconds > 0 then
                for _ = 1, immediateTickCount do
                    state.temperature, state.temperatureTimeRemainder = temperature.system.advanceTemperature(
                        state.temperature,
                        state.temperatureTimeRemainder,
                        tickSeconds,
                        state.temperatureWarmModifier,
                        state.temperatureColdModifier,
                        1.0,
                        1
                    )
                end
            end
        end
    end

    function api.runSystemSection(sectionName, fn)
        local ok, err = pcall(fn)
        if ok then
            if type(state.runtimeModuleErrors) ~= 'table' then
                state.runtimeModuleErrors = {}
            end
            state.runtimeModuleErrors[sectionName] = nil
            return true
        end

        local errText = tostring(err)
        if type(state.runtimeModuleErrors) ~= 'table' then
            state.runtimeModuleErrors = {}
        end
        if state.runtimeModuleErrors[sectionName] ~= errText then
            state.runtimeModuleErrors[sectionName] = errText
            print(string.format('[SurvivalMode] %s failed: %s', tostring(sectionName), errText))
        end
        return false
    end

    function api.applyMovementScale()
        if core.isWorldPaused() then
            local hudFrameUpdate = state.runHudFrameUpdate
            if type(hudFrameUpdate) == 'function' then
                pcall(hudFrameUpdate, 1 / 60)
            end
        end

        if not types.Actor.objectIsInstance(self) or types.Actor.isDead(self) then
            return
        end
        if not isTemperatureSystemEnabled() then
            return
        end

        local controls = self.controls
        if controls == nil then
            return
        end

        if temperature == nil
            or type(temperature.system) ~= 'table'
            or type(temperature.system.getStageByValue) ~= 'function' then
            return
        end

        local stage = temperature.system.getStageByValue(state.temperature)
        if type(stage) ~= 'table' then
            return
        end

        local slownessPct = math.max(0, tonumber(stage.slownessPct) or 0)
        if slownessPct <= 0 then
            return
        end

        local speedScale = math.max(0, 1 - (slownessPct / 100))
        controls.movement = controls.movement * speedScale
        controls.sideMovement = controls.sideMovement * speedScale
    end

    return api
end

return M
