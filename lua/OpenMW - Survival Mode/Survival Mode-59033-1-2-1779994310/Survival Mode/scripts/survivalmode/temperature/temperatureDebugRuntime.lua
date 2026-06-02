local M = {}

function M.create(deps)
    local state = assert(deps.state)
    local core = assert(deps.core)
    local temperature = assert(deps.temperature)
    local temperatureDebug = assert(deps.temperatureDebug)
    local temperatureRuntimeApi = assert(deps.temperatureRuntimeApi)
    local isOverlayEnabled = assert(deps.isOverlayEnabled)
    local debugLoggingEventName = assert(deps.debugLoggingEventName)

    local api = {}

    function api.bindRuntimeBridge()
        function temperatureDebug.applyModifierState(temperatureModifierState)
            return temperatureRuntimeApi.applyModifierState(temperatureModifierState)
        end

        function temperatureDebug.refreshModifierState(elapsedSeconds)
            return temperatureRuntimeApi.refreshModifierState(elapsedSeconds)
        end

        function temperatureDebug.advanceByElapsed(elapsedSeconds, temperatureModifierState, allowBurstTicks)
            return temperatureRuntimeApi.advanceByElapsed(elapsedSeconds, temperatureModifierState, allowBurstTicks)
        end

        function temperatureDebug.runSystemSection(sectionName, fn)
            return temperatureRuntimeApi.runSystemSection(sectionName, fn)
        end
    end

    function api.syncDebugLoggingState(force)
        local debugEnabled = isOverlayEnabled() == true
        if force ~= true and state.lastDebugLoggingEnabled == debugEnabled then
            return
        end
        state.lastDebugLoggingEnabled = debugEnabled

        if temperature ~= nil
            and type(temperature.config) == 'table'
            and type(temperature.config.setTraversalDebugLoggingEnabled) == 'function' then
            pcall(function()
                temperature.config.setTraversalDebugLoggingEnabled(debugEnabled)
            end)
        end

        pcall(function()
            core.sendGlobalEvent(debugLoggingEventName, {
                enabled = debugEnabled,
            })
        end)
    end

    return api
end

return M
