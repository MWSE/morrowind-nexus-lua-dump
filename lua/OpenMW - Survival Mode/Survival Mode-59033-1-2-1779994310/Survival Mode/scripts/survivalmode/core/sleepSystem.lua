local M = {}

local COMBAT_SLEEP_ACCUMULATION_SCALE = 0.25
local DEFAULT_SLEEP_ACCUMULATION_SCALE = 1.0
local TRAVEL_MODE = 'Travel'
local BARTER_MODE = 'Barter'
local LOADING_MODE = 'Loading'
local LOADING_WALLPAPER_MODE = 'LoadingWallpaper'

function M.create(deps)
    local state = assert(deps.state)
    local core = assert(deps.core)
    local selfObject = assert(deps.self)
    local types = assert(deps.types)
    local clamp = assert(deps.clamp)
    local isSleepSystemEnabled = assert(deps.isSleepSystemEnabled)
    local isHungerSystemEnabled = assert(deps.isHungerSystemEnabled)
    local isThirstSystemEnabled = assert(deps.isThirstSystemEnabled)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local getHungerStage = assert(deps.getHungerStage)
    local getThirstStage = assert(deps.getThirstStage)
    local getWellRestedStaminiaRegenBonusPct = assert(deps.getWellRestedStaminiaRegenBonusPct)
    local sleepTickSeconds = assert(tonumber(deps.sleepTickSeconds))
    local sleepMax = assert(tonumber(deps.sleepMax))
    local sleepStepDefault = assert(tonumber(deps.sleepStepDefault))
    local sleepAccumulationPerHour = tonumber(deps.sleepAccumulationPerHour) or 0
    local sleepRecoveryPerHourMenu = tonumber(deps.sleepRecoveryPerHourMenu) or 0
    local sleepRecoveryPerHourBed = tonumber(deps.sleepRecoveryPerHourBed) or 0
    local temperature = deps.temperature
    local ui = deps.ui
    local interfaces = deps.interfaces
    local now = deps.now
    local restSleepNeedsMultiplier = tonumber(deps.restSleepNeedsMultiplier) or 1.0
    local sleepTravelMultiplier = tonumber(deps.sleepTravelMultiplier) or 1.0
    local advanceHungerByElapsed = deps.advanceHungerByElapsed
    local advanceThirstByElapsed = deps.advanceThirstByElapsed
    local updateSystems = deps.updateSystems
    local getInitialNeedValue = deps.getInitialNeedValue
    local sleepStages = deps.sleepStages
    local getSleepWellRestedBonusMultiplierOnSleep = deps.getSleepWellRestedBonusMultiplierOnSleep
    local isCurrentSleepWellRestedBonusEligible = deps.isCurrentSleepWellRestedBonusEligible
    local temperatureDebug = deps.temperatureDebug
    local sendGlobalEvent = deps.sendGlobalEvent
    local invalidateHud = deps.invalidateHud
    local markSkipNextRegionTransitionDelay = deps.markSkipNextRegionTransitionDelay
    local applyTravelTemperatureCatchup = deps.applyTravelTemperatureCatchup

    local api = {}

    function api.getSleepAccumulationScale()
        if state.isInCombat == true then
            return COMBAT_SLEEP_ACCUMULATION_SCALE
        end

        return DEFAULT_SLEEP_ACCUMULATION_SCALE
    end

    function api.updatePlayerCombatState(eventData, playerObject)
        if type(eventData) ~= 'table' or playerObject == nil then
            return
        end

        if eventData.actor ~= playerObject then
            return
        end

        state.isInCombat = type(eventData.targets) == 'table' and next(eventData.targets) ~= nil
    end

    function api.setRuntimeDeps(runtimeDeps)
        if type(runtimeDeps) ~= 'table' then
            return
        end
        if runtimeDeps.ui ~= nil then
            ui = runtimeDeps.ui
        end
        if runtimeDeps.interfaces ~= nil then
            interfaces = runtimeDeps.interfaces
        end
        if runtimeDeps.now ~= nil then
            now = runtimeDeps.now
        end
        if runtimeDeps.sleepTravelMultiplier ~= nil then
            sleepTravelMultiplier = tonumber(runtimeDeps.sleepTravelMultiplier) or sleepTravelMultiplier
        end
        if runtimeDeps.advanceHungerByElapsed ~= nil then
            advanceHungerByElapsed = runtimeDeps.advanceHungerByElapsed
        end
        if runtimeDeps.advanceThirstByElapsed ~= nil then
            advanceThirstByElapsed = runtimeDeps.advanceThirstByElapsed
        end
        if runtimeDeps.updateSystems ~= nil then
            updateSystems = runtimeDeps.updateSystems
        end
        if runtimeDeps.getInitialNeedValue ~= nil then
            getInitialNeedValue = runtimeDeps.getInitialNeedValue
        end
        if runtimeDeps.sleepStages ~= nil then
            sleepStages = runtimeDeps.sleepStages
        end
        if runtimeDeps.getSleepWellRestedBonusMultiplierOnSleep ~= nil then
            getSleepWellRestedBonusMultiplierOnSleep = runtimeDeps.getSleepWellRestedBonusMultiplierOnSleep
        end
        if runtimeDeps.isCurrentSleepWellRestedBonusEligible ~= nil then
            isCurrentSleepWellRestedBonusEligible = runtimeDeps.isCurrentSleepWellRestedBonusEligible
        end
        if runtimeDeps.temperatureDebug ~= nil then
            temperatureDebug = runtimeDeps.temperatureDebug
        end
        if runtimeDeps.sendGlobalEvent ~= nil then
            sendGlobalEvent = runtimeDeps.sendGlobalEvent
        end
        if runtimeDeps.invalidateHud ~= nil then
            invalidateHud = runtimeDeps.invalidateHud
        end
        if runtimeDeps.markSkipNextRegionTransitionDelay ~= nil then
            markSkipNextRegionTransitionDelay = runtimeDeps.markSkipNextRegionTransitionDelay
        end
        if runtimeDeps.applyTravelTemperatureCatchup ~= nil then
            applyTravelTemperatureCatchup = runtimeDeps.applyTravelTemperatureCatchup
        end
    end

    function api.getSleepStepPerTick()
        return sleepStepDefault
    end

    function api.advanceSleep(currentTime)
        if not isSleepSystemEnabled() then
            state.sleepLastUpdateTime = currentTime
            return
        end
        local elapsed = currentTime - state.sleepLastUpdateTime
        if elapsed <= 0 then
            return
        end

        state.sleepLastUpdateTime = currentTime

        local combatSleepScale = api.getSleepAccumulationScale()
        local total = state.sleepTimeRemainder + (elapsed * combatSleepScale)
        local ticks = math.floor(total / sleepTickSeconds)
        if ticks > 0 then
            local increment = api.getSleepStepPerTick() * ticks
            state.sleep = clamp(state.sleep + increment, 0, sleepMax)
            total = total - (ticks * sleepTickSeconds)
        end

        state.sleepTimeRemainder = total
    end

    function api.advanceSleepByElapsed(elapsedSeconds, multiplier)
        if not isSleepSystemEnabled() then
            return
        end
        local elapsed = tonumber(elapsedSeconds) or 0
        if elapsed <= 0 then
            return
        end

        local scale = tonumber(multiplier) or 1
        if scale <= 0 then
            return
        end

        local combatSleepScale = api.getSleepAccumulationScale()
        local total = state.sleepTimeRemainder + (elapsed * scale * combatSleepScale)
        local ticks = math.floor(total / sleepTickSeconds)
        if ticks > 0 then
            local increment = api.getSleepStepPerTick() * ticks
            state.sleep = clamp(state.sleep + increment, 0, sleepMax)
            total = total - (ticks * sleepTickSeconds)
        end

        state.sleepTimeRemainder = total
    end

    local function getEnduranceModifiedValue()
        if not types.NPC.objectIsInstance(selfObject) then
            return 0
        end

        local enduranceStat = types.NPC.stats.attributes.endurance(selfObject)
        if enduranceStat == nil then
            return 0
        end

        if type(enduranceStat.modified) == 'number' then
            return math.max(0, enduranceStat.modified)
        end

        local baseValue = tonumber(enduranceStat.base) or 0
        local modifierValue = tonumber(enduranceStat.modifier) or 0
        local damageValue = tonumber(enduranceStat.damage) or 0
        return math.max(0, baseValue + modifierValue - damageValue)
    end

    local function getFatigueMaxValue(fatigueStat)
        if fatigueStat == nil then
            return 0
        end

        local baseValue = tonumber(fatigueStat.base) or 0
        local modifierValue = tonumber(fatigueStat.modifier) or 0
        return math.max(0, baseValue + modifierValue)
    end

    local function getVanillaFatigueRegenPerSecond()
        if not types.Actor.objectIsInstance(selfObject) then
            return 0
        end

        local regenBase = tonumber(core.getGMST('fFatigueReturnBase')) or 0
        local regenMult = tonumber(core.getGMST('fFatigueReturnMult')) or 0
        local endurance = getEnduranceModifiedValue()
        local fatigueRegenPerSecond = regenBase + (regenMult * endurance)
        if fatigueRegenPerSecond <= 0 then
            return 0
        end

        local capacity = tonumber(types.Actor.getCapacity(selfObject)) or 0
        if capacity <= 0 then
            return 0
        end

        local encumbrance = tonumber(types.Actor.getEncumbrance(selfObject)) or 0
        local encumbranceFactor = clamp(1 - (encumbrance / capacity), 0, 1)
        if encumbranceFactor <= 0 then
            return 0
        end

        return fatigueRegenPerSecond * encumbranceFactor
    end

    function api.applyWellRestedStaminiaRegeneration(dt)
        if not types.Actor.objectIsInstance(selfObject) then
            state.lastObservedFatigueCurrent = nil
            return
        end

        if core.isWorldPaused() or types.Actor.isDead(selfObject) then
            state.lastObservedFatigueCurrent = nil
            return
        end

        local step = tonumber(dt) or 0
        if step <= 0 then
            return
        end

        local fatigueStat = types.Actor.stats.dynamic.fatigue(selfObject)
        if fatigueStat == nil then
            state.lastObservedFatigueCurrent = nil
            return
        end

        local currentFatigue = tonumber(fatigueStat.current) or 0
        local previousFatigue = tonumber(state.lastObservedFatigueCurrent)
        if previousFatigue == nil then
            previousFatigue = currentFatigue
        end

        local maxFatigue = getFatigueMaxValue(fatigueStat)
        if maxFatigue <= 0 then
            state.lastObservedFatigueCurrent = currentFatigue
            return
        end

        local bonusPct = getWellRestedStaminiaRegenBonusPct()
        local temperatureStaminiaDrainPct = 0
        local hungerStaminaDrainPct = 0
        local thirstStaminaRegenPenaltyPct = 0
        local hungerStage = isHungerSystemEnabled() and getHungerStage(state.hunger) or nil
        local thirstStage = isThirstSystemEnabled() and getThirstStage(state.thirst) or nil
        if type(hungerStage) == 'table' then
            hungerStaminaDrainPct = math.max(
                0,
                tonumber(hungerStage.staminiaDrainPct)
                    or tonumber(hungerStage.staminaDrainPct)
                    or 0
            )
        end
        if type(thirstStage) == 'table' then
            thirstStaminaRegenPenaltyPct = math.max(
                0,
                tonumber(thirstStage.staminiaRegenPenaltyPct)
                    or tonumber(thirstStage.staminaRegenPenaltyPct)
                    or 0
            )
        end
        if isTemperatureSystemEnabled()
            and temperature ~= nil
            and type(temperature.system) == 'table'
            and type(temperature.system.getStageByValue) == 'function' then
            local temperatureStage = temperature.system.getStageByValue(state.temperature)
            if type(temperatureStage) == 'table' then
                temperatureStaminiaDrainPct = math.max(
                    0,
                    tonumber(temperatureStage.staminiaDrainPct)
                        or tonumber(temperatureStage.staminaDrainPct)
                        or 0
                )
            end
        end
        if bonusPct <= 0
            and temperatureStaminiaDrainPct <= 0
            and hungerStaminaDrainPct <= 0
            and thirstStaminaRegenPenaltyPct <= 0 then
            state.lastObservedFatigueCurrent = currentFatigue
            return
        end

        local observedFatigueGain = math.max(0, currentFatigue - previousFatigue)
        local bonusRegenDelta = 0
        if bonusPct > 0 then
            local baseRegenPerSecond = getVanillaFatigueRegenPerSecond()
            if baseRegenPerSecond > 0 then
                bonusRegenDelta = baseRegenPerSecond * bonusPct * step
            end
        end

        local observedFatigueLoss = math.max(0, previousFatigue - currentFatigue)
        local extraDrainDelta = 0
        local totalStaminaDrainPct = math.max(0, temperatureStaminiaDrainPct + hungerStaminaDrainPct)
        if totalStaminaDrainPct > 0 and observedFatigueLoss > 0 then
            extraDrainDelta = observedFatigueLoss * (totalStaminaDrainPct / 100)
        end
        local thirstRegenReductionDelta = 0
        if thirstStaminaRegenPenaltyPct > 0 and observedFatigueGain > 0 then
            thirstRegenReductionDelta = observedFatigueGain * (thirstStaminaRegenPenaltyPct / 100)
        end

        if bonusRegenDelta == 0 and extraDrainDelta == 0 and thirstRegenReductionDelta == 0 then
            state.lastObservedFatigueCurrent = currentFatigue
            return
        end

        local nextFatigue = clamp(currentFatigue + bonusRegenDelta - extraDrainDelta - thirstRegenReductionDelta, 0, maxFatigue)
        if nextFatigue ~= currentFatigue then
            fatigueStat.current = nextFatigue
        end
        state.lastObservedFatigueCurrent = nextFatigue
    end

    local function parseBoolLike(value)
        if type(value) == 'boolean' then
            return value
        end

        if type(value) == 'number' then
            return value ~= 0
        end

        if type(value) == 'string' then
            local lowered = string.lower(value)
            if lowered == 'true' or lowered == '1' or lowered == 'yes' then
                return true
            end
            if lowered == 'false' or lowered == '0' or lowered == 'no' then
                return false
            end
        end

        return nil
    end

    local function parseActionString(value)
        if type(value) ~= 'string' then
            return nil
        end

        local action = string.lower(value)
        if action:find('wait', 1, true) ~= nil then
            return false
        end
        if action:find('sleep', 1, true) ~= nil then
            return true
        end

        return nil
    end

    local function isValidObject(obj)
        if obj == nil then
            return false
        end
        local ok, valid = pcall(function() return obj:isValid() end)
        return ok and valid == true
    end

    local function isLikelySleepingDialog(arg)
        if isValidObject(arg) then
            return true
        end

        local cell = selfObject.cell
        if cell == nil then
            return false
        end

        if cell.hasTag and cell:hasTag('NoSleep') then
            return false
        end

        local ok, werewolf = pcall(function() return types.NPC.isWerewolf(selfObject) end)
        if ok and werewolf then
            return false
        end

        return true
    end

    local function markActionFromArg(arg, session, depth)
        if session == nil then
            return
        end
        if depth == nil then
            depth = 0
        end
        if depth > 4 then
            return
        end

        if type(arg) == 'table' then
            for key, value in pairs(arg) do
                local keyName = ''
                if type(key) == 'string' then
                    keyName = string.lower(key)
                end

                if keyName == 'wait' then
                    local waitByKey = parseBoolLike(value)
                    if waitByKey == true then
                        session.sawWaitAction = true
                    end
                elseif keyName == 'sleep' then
                    local sleepByKey = parseBoolLike(value)
                    if sleepByKey == true then
                        session.sawSleepAction = true
                    end
                end

                if type(value) == 'string' then
                    local actionValue = parseActionString(value)
                    if actionValue == true then
                        session.sawSleepAction = true
                    elseif actionValue == false then
                        session.sawWaitAction = true
                    end
                elseif type(value) == 'table' then
                    markActionFromArg(value, session, depth + 1)
                end
            end

            if arg.wait ~= nil then
                local waitFlag = parseBoolLike(arg.wait)
                if waitFlag == true then
                    session.sawWaitAction = true
                end
            end

            if arg.sleep ~= nil then
                local sleepFlag = parseBoolLike(arg.sleep)
                if sleepFlag == true then
                    session.sawSleepAction = true
                end
            end
        else
            local actionValue = parseActionString(arg)
            if actionValue == true then
                session.sawSleepAction = true
            elseif actionValue == false then
                session.sawWaitAction = true
            end
        end
    end

    function api.handleRestUiModeChanged(data)
        if type(data) ~= 'table'
            or type(now) ~= 'function'
            or type(advanceHungerByElapsed) ~= 'function'
            or type(advanceThirstByElapsed) ~= 'function'
            or type(updateSystems) ~= 'function'
            or type(getInitialNeedValue) ~= 'function'
            or type(getSleepWellRestedBonusMultiplierOnSleep) ~= 'function'
            or type(isCurrentSleepWellRestedBonusEligible) ~= 'function' then
            return
        end

        local REST_MODE = 'Rest'
        local LOADING_MODE = 'Loading'
        local LOADING_WALLPAPER_MODE = 'LoadingWallpaper'

        local function getStackState()
            local stackOk, stack = pcall(function() return ui._getUiModeStack() end)
            local restInStack = false
            local loadingInStack = false

            if stackOk and type(stack) == 'table' then
                for _, mode in ipairs(stack) do
                    if mode == REST_MODE then
                        restInStack = true
                    elseif mode == LOADING_MODE or mode == LOADING_WALLPAPER_MODE then
                        loadingInStack = true
                    end
                end
                return restInStack, loadingInStack
            end

            local oldModeFallback = tostring(data.oldMode or '')
            local newModeFallback = tostring(data.newMode or '')
            restInStack = newModeFallback == REST_MODE
                or oldModeFallback == REST_MODE
                or (state.restUiSession ~= nil and state.restUiSession.active == true)
            loadingInStack = newModeFallback == LOADING_MODE
                or oldModeFallback == LOADING_MODE
                or newModeFallback == LOADING_WALLPAPER_MODE
                or oldModeFallback == LOADING_WALLPAPER_MODE
            return restInStack, loadingInStack
        end

        local newMode = tostring(data.newMode or '')
        local restInStack, loadingInStack = getStackState()

        if newMode == REST_MODE and state.restUiSession == nil then
            state.restUiSession = {
                startTime = now(),
                sawSleepAction = false,
                sawWaitAction = false,
                openedFromObject = isValidObject(data.arg),
                sleepDialogContext = isLikelySleepingDialog(data.arg),
                active = true,
            }
        end

        if state.restUiSession ~= nil then
            markActionFromArg(data.arg, state.restUiSession)
            state.restUiSession.active = restInStack or loadingInStack
        end

        if state.restUiSession ~= nil and not restInStack and not loadingInStack then
            local session = state.restUiSession
            state.restUiSession = nil

            local currentTime = now()
            local startTime = tonumber(session.startTime)
            if startTime ~= nil and currentTime > startTime then
                local elapsed = currentTime - startTime
                local explicitSleep = session.sawSleepAction == true
                local explicitWait = session.sawWaitAction == true
                local inferredSleepFromObject = session.openedFromObject == true and explicitWait ~= true
                local inferredSleepFromDialog = session.sleepDialogContext == true
                    and explicitSleep ~= true
                    and explicitWait ~= true
                local didSleep = explicitSleep or inferredSleepFromObject or inferredSleepFromDialog

                local needsElapsedScale = didSleep and restSleepNeedsMultiplier or 1.0
                local projectedTotal = state.sleepTimeRemainder + (elapsed * needsElapsedScale)
                local projectedTicks = math.floor(projectedTotal / sleepTickSeconds)
                local progressedAmount = 0
                if projectedTicks > 0 then
                    progressedAmount = api.getSleepStepPerTick() * projectedTicks
                end

                state.hungerLastUpdateTime = currentTime
                state.thirstLastUpdateTime = currentTime
                state.sleepLastUpdateTime = currentTime
                state.temperatureLastUpdateTime = currentTime
                advanceHungerByElapsed(elapsed, needsElapsedScale)
                advanceThirstByElapsed(elapsed, needsElapsedScale)
                api.advanceSleepByElapsed(elapsed, needsElapsedScale)
                if isTemperatureSystemEnabled() and temperatureDebug ~= nil then
                    local remainingTemperatureElapsed = math.max(0, tonumber(elapsed) or 0)
                    local temperatureTickSeconds = tonumber(temperature.system.TEMPERATURE_TICK_SECONDS) or 0
                    if temperatureTickSeconds > 0 then
                        local restTemperatureModifierState =
                            temperatureDebug.refreshModifierState(remainingTemperatureElapsed, true)
                        while remainingTemperatureElapsed > 0 do
                            local elapsedChunk = math.min(remainingTemperatureElapsed, temperatureTickSeconds)
                            temperatureDebug.advanceByElapsed(elapsedChunk, restTemperatureModifierState, true)
                            state.applyTemperatureHealthDrain(
                                temperature.system.getStageByValue(state.temperature),
                                elapsedChunk,
                                true
                            )
                            remainingTemperatureElapsed = remainingTemperatureElapsed - elapsedChunk
                        end
                    else
                        temperatureDebug.advanceByElapsed(elapsed, nil, true)
                        state.applyTemperatureHealthDrain(temperature.system.getStageByValue(state.temperature), elapsed, true)
                    end
                end

                if didSleep and progressedAmount > 0 then
                    local recoveryPerHour = sleepRecoveryPerHourMenu
                    if session.openedFromObject == true then
                        recoveryPerHour = sleepRecoveryPerHourBed
                    end
                    local recoveryMultiplier = 1.0 + (recoveryPerHour / sleepAccumulationPerHour)
                    local recoveryAmount = progressedAmount * recoveryMultiplier
                    state.sleep = clamp(state.sleep - recoveryAmount, 0, sleepMax)

                    if session.openedFromObject ~= true then
                        local refreshedFloor = getInitialNeedValue(sleepStages, 42)
                        state.sleep = math.max(state.sleep, refreshedFloor)
                    end
                    state.sleepWellRestedBonusMultiplier = getSleepWellRestedBonusMultiplierOnSleep()
                    state.sleepWellRestedBonusEligible = isCurrentSleepWellRestedBonusEligible()
                end

                state.hudSignature = nil
                updateSystems()
            end
        end
    end

    local function modeMatchesInterface(mode, interfaceModeName)
        if interfaces ~= nil
            and interfaces.UI ~= nil
            and interfaces.UI.MODE ~= nil
            and interfaces.UI.MODE[interfaceModeName] ~= nil
            and mode == interfaces.UI.MODE[interfaceModeName] then
            return true
        end
        return false
    end

    local function isTravelMode(mode)
        return modeMatchesInterface(mode, TRAVEL_MODE) or tostring(mode or '') == TRAVEL_MODE
    end

    local function isBarterMode(mode)
        return modeMatchesInterface(mode, BARTER_MODE) or tostring(mode or '') == BARTER_MODE
    end

    local function isLoadingMode(mode)
        if modeMatchesInterface(mode, LOADING_MODE) or modeMatchesInterface(mode, LOADING_WALLPAPER_MODE) then
            return true
        end

        local modeName = tostring(mode or '')
        return modeName == LOADING_MODE or modeName == LOADING_WALLPAPER_MODE
    end

    function api.handleUiModeChanged(data)
        if type(data) ~= 'table' then
            return
        end

        if type(sendGlobalEvent) == 'function' and isBarterMode(data.newMode) and not isBarterMode(data.oldMode) then
            pcall(sendGlobalEvent, 'SurvivalNeeds_MerchantBarterUiModeChanged', {
                oldMode = data.oldMode,
                newMode = data.newMode,
                merchant = data.arg,
            })
        end

        if state.travelUiSession == nil and isTravelMode(data.newMode) and type(now) == 'function' then
            state.travelUiSession = {
                startTime = now(),
                active = true,
            }
        end

        if state.travelUiSession ~= nil then
            local stillInTravelFlow = isTravelMode(data.newMode) or isLoadingMode(data.newMode)
            if stillInTravelFlow then
                state.travelUiSession.active = true
            else
                local session = state.travelUiSession
                state.travelUiSession = nil
                if type(markSkipNextRegionTransitionDelay) == 'function' then
                    markSkipNextRegionTransitionDelay()
                end
                local startTime = tonumber(session.startTime)
                local currentTime = type(now) == 'function' and now() or nil
                if startTime ~= nil and currentTime ~= nil and currentTime > startTime then
                    local elapsed = currentTime - startTime
                    state.sleepLastUpdateTime = currentTime
                    state.temperatureLastUpdateTime = currentTime
                    api.advanceSleepByElapsed(elapsed, sleepTravelMultiplier)
                    if type(applyTravelTemperatureCatchup) == 'function' then
                        applyTravelTemperatureCatchup(elapsed)
                    end
                    state.hudSignature = nil
                    if type(invalidateHud) == 'function' then
                        invalidateHud()
                    end
                    if type(updateSystems) == 'function' then
                        updateSystems()
                    end
                end
            end
        end

        api.handleRestUiModeChanged(data)
    end

    return api
end

return M
