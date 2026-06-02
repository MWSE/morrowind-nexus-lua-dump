local M = {}
local vampire = require('scripts.survivalmode.core.vampire')

function M.create(deps)
    local state = assert(deps.state)
    local clamp = assert(deps.clamp)
    local isThirstSystemEnabled = assert(deps.isThirstSystemEnabled)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local temperature = deps.temperature
    local thirstTickSeconds = assert(tonumber(deps.thirstTickSeconds))
    local thirstStepDefault = assert(tonumber(deps.thirstStepDefault))
    local thirstStepOrc = assert(tonumber(deps.thirstStepOrc))
    local thirstMax = assert(tonumber(deps.thirstMax))
    local thirstFlashDuration = tonumber(deps.thirstFlashDuration) or 0
    local thirstNeutralValue = tonumber(deps.thirstNeutralValue) or 52

    local api = {}

    local function applyVampireOverride(currentTime)
        if not vampire.isPlayerVampire() then
            state.isVampire = false
            return false
        end

        state.isVampire = true
        state.thirst = clamp(thirstNeutralValue, 0, thirstMax)
        state.thirstTimeRemainder = 0
        if currentTime ~= nil then
            state.thirstLastUpdateTime = currentTime
        end
        return true
    end

    function api.getInitialThirstValue(getInitialNeedValue, thirstStages, fallback)
        local initialValue = fallback
        if type(getInitialNeedValue) == 'function' then
            initialValue = getInitialNeedValue(thirstStages, fallback)
        end
        return clamp(tonumber(initialValue) or fallback or 0, 0, thirstMax)
    end

    function api.resetToInitialState(currentTime, getInitialNeedValue, thirstStages, fallback)
        state.thirst = api.getInitialThirstValue(getInitialNeedValue, thirstStages, fallback)
        state.thirstTimeRemainder = 0
        state.thirstLastUpdateTime = currentTime
    end

    function api.clearRuntimeState(currentTime)
        state.thirstTimeRemainder = 0
        state.thirstLastUpdateTime = currentTime
    end

    function api.loadState(savedData, currentTime, getInitialNeedValue, thirstStages, fallback)
        local initialValue = api.getInitialThirstValue(getInitialNeedValue, thirstStages, fallback)
        state.thirst = clamp(tonumber(savedData and savedData.thirst) or initialValue, 0, thirstMax)
        state.thirstTimeRemainder = math.max(0, tonumber(savedData and savedData.thirstTimeRemainder) or 0)
        state.thirstLastUpdateTime = tonumber(savedData and savedData.thirstLastUpdateTime) or currentTime
    end

    function api.saveState()
        return {
            thirst = state.thirst,
            thirstTimeRemainder = state.thirstTimeRemainder,
            thirstLastUpdateTime = state.thirstLastUpdateTime,
        }
    end

    function api.getThirstStepPerTick()
        local step = thirstStepDefault
        if state.isOrc then
            step = thirstStepOrc
        end

        if isTemperatureSystemEnabled()
            and temperature ~= nil
            and type(temperature.system) == 'table'
            and type(temperature.system.getStageByValue) == 'function' then
            local temperatureStage = temperature.system.getStageByValue(state.temperature)
            if type(temperatureStage) == 'table' then
                local thirstIncreasePct = tonumber(temperatureStage.thirstIncreasePct) or 0
                if thirstIncreasePct > 0 then
                    step = step * (1 + (thirstIncreasePct / 100))
                end
            end
        end

        return step
    end

    function api.advanceThirst(currentTime)
        if applyVampireOverride(currentTime) then
            return
        end
        if not isThirstSystemEnabled() then
            state.thirstLastUpdateTime = currentTime
            return
        end
        local elapsed = currentTime - state.thirstLastUpdateTime
        if elapsed <= 0 then
            return
        end

        state.thirstLastUpdateTime = currentTime

        local total = state.thirstTimeRemainder + elapsed
        local ticks = math.floor(total / thirstTickSeconds)
        if ticks > 0 then
            local increment = api.getThirstStepPerTick() * ticks
            state.thirst = clamp(state.thirst + increment, 0, thirstMax)
            total = total - (ticks * thirstTickSeconds)
        end

        state.thirstTimeRemainder = total
    end

    function api.advanceThirstByElapsed(elapsedSeconds, multiplier)
        if applyVampireOverride(nil) then
            return
        end
        if not isThirstSystemEnabled() then
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

        local total = state.thirstTimeRemainder + (elapsed * scale)
        local ticks = math.floor(total / thirstTickSeconds)
        if ticks > 0 then
            local increment = api.getThirstStepPerTick() * ticks
            state.thirst = clamp(state.thirst + increment, 0, thirstMax)
            total = total - (ticks * thirstTickSeconds)
        end

        state.thirstTimeRemainder = total
    end

    function api.applyConsumedItem(item, getThirstDrinkRestoreAmount, flashDuration)
        if applyVampireOverride(nil) then
            return 0
        end
        local restoreAmount = 0
        if type(getThirstDrinkRestoreAmount) == 'function' then
            restoreAmount = tonumber(getThirstDrinkRestoreAmount(item)) or 0
        end
        if restoreAmount > 0 then
            state.thirst = clamp(state.thirst - restoreAmount, 0, thirstMax)
            state.thirstFlashTimeRemaining = tonumber(flashDuration) or thirstFlashDuration
        end
        return restoreAmount
    end

    return api
end

return M
