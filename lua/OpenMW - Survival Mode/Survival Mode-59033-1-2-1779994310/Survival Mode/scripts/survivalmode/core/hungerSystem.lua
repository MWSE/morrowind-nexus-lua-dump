local M = {}
local vampire = require('scripts.survivalmode.core.vampire')

function M.create(deps)
    local state = assert(deps.state)
    local clamp = assert(deps.clamp)
    local isHungerSystemEnabled = assert(deps.isHungerSystemEnabled)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local temperature = deps.temperature
    local hungerTickSeconds = assert(tonumber(deps.hungerTickSeconds))
    local hungerStepDefault = assert(tonumber(deps.hungerStepDefault))
    local hungerStepOrc = assert(tonumber(deps.hungerStepOrc))
    local hungerMax = assert(tonumber(deps.hungerMax))
    local hungerFlashDuration = tonumber(deps.hungerFlashDuration) or 0
    local hungerNeutralValue = tonumber(deps.hungerNeutralValue) or 52

    local api = {}

    local function applyVampireOverride(currentTime)
        if not vampire.isPlayerVampire() then
            state.isVampire = false
            return false
        end

        state.isVampire = true
        state.hunger = clamp(hungerNeutralValue, 0, hungerMax)
        state.hungerTimeRemainder = 0
        if currentTime ~= nil then
            state.hungerLastUpdateTime = currentTime
        end
        return true
    end

    function api.getInitialHungerValue(getInitialNeedValue, hungerStages, fallback)
        local initialValue = fallback
        if type(getInitialNeedValue) == 'function' then
            initialValue = getInitialNeedValue(hungerStages, fallback)
        end
        return clamp(tonumber(initialValue) or fallback or 0, 0, hungerMax)
    end

    function api.resetToInitialState(currentTime, getInitialNeedValue, hungerStages, fallback)
        state.hunger = api.getInitialHungerValue(getInitialNeedValue, hungerStages, fallback)
        state.hungerTimeRemainder = 0
        state.hungerLastUpdateTime = currentTime
    end

    function api.clearRuntimeState(currentTime)
        state.hungerTimeRemainder = 0
        state.hungerLastUpdateTime = currentTime
    end

    function api.loadState(savedData, currentTime, getInitialNeedValue, hungerStages, fallback)
        local initialValue = api.getInitialHungerValue(getInitialNeedValue, hungerStages, fallback)
        state.hunger = clamp(tonumber(savedData and savedData.hunger) or initialValue, 0, hungerMax)
        state.hungerTimeRemainder = math.max(0, tonumber(savedData and savedData.hungerTimeRemainder) or 0)
        state.hungerLastUpdateTime = tonumber(savedData and savedData.hungerLastUpdateTime) or currentTime
    end

    function api.saveState()
        return {
            hunger = state.hunger,
            hungerTimeRemainder = state.hungerTimeRemainder,
            hungerLastUpdateTime = state.hungerLastUpdateTime,
        }
    end

    function api.getHungerStepPerTick()
        if state.isOrc then
            return hungerStepOrc
        end

        return hungerStepDefault
    end

    local function resolveTemperatureHungerScale()
        if isTemperatureSystemEnabled()
            and temperature ~= nil
            and type(temperature.system) == 'table'
            and type(temperature.system.getStageByValue) == 'function' then
            local temperatureStage = temperature.system.getStageByValue(state.temperature)
            if type(temperatureStage) == 'table' then
                local hungerIncreasePct = tonumber(temperatureStage.hungerIncreasePct) or 0
                if hungerIncreasePct > 0 then
                    return 1 + (hungerIncreasePct / 100)
                end
            end
        end

        return 1.0
    end

    function api.advanceHunger(currentTime)
        if applyVampireOverride(currentTime) then
            return
        end
        if not isHungerSystemEnabled() then
            state.hungerLastUpdateTime = currentTime
            return
        end
        local elapsed = currentTime - state.hungerLastUpdateTime
        if elapsed <= 0 then
            return
        end

        state.hungerLastUpdateTime = currentTime

        local total = state.hungerTimeRemainder + elapsed
        local ticks = math.floor(total / hungerTickSeconds)
        if ticks > 0 then
            local increment = api.getHungerStepPerTick() * ticks
            increment = increment * resolveTemperatureHungerScale()
            state.hunger = clamp(state.hunger + increment, 0, hungerMax)
            total = total - (ticks * hungerTickSeconds)
        end

        state.hungerTimeRemainder = total
    end

    function api.advanceHungerByElapsed(elapsedSeconds, multiplier)
        if applyVampireOverride(nil) then
            return
        end
        if not isHungerSystemEnabled() then
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

        scale = scale * resolveTemperatureHungerScale()

        local total = state.hungerTimeRemainder + (elapsed * scale)
        local ticks = math.floor(total / hungerTickSeconds)
        if ticks > 0 then
            local increment = api.getHungerStepPerTick() * ticks
            state.hunger = clamp(state.hunger + increment, 0, hungerMax)
            total = total - (ticks * hungerTickSeconds)
        end

        state.hungerTimeRemainder = total
    end

    function api.applyConsumedItem(item, getFoodHungerReduction, flashDuration)
        if applyVampireOverride(nil) then
            return 0
        end
        local reduction = 0
        if type(getFoodHungerReduction) == 'function' then
            reduction = tonumber(getFoodHungerReduction(item)) or 0
        end
        if reduction > 0 then
            state.hunger = clamp(state.hunger - reduction, 0, hungerMax)
            state.hungerFlashTimeRemaining = tonumber(flashDuration) or hungerFlashDuration
        end
        return reduction
    end

    return api
end

return M
