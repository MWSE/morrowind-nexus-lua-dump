-- interactions/sleeping/wakeCleanup.lua
---@omw-context none
local M = {}

local function noopLog(...)
end

function M.handleWakeCleanupOnly(data, state)
    if not (data and data.wakeCleanupOnly == true) then return false end
    if state and state.currentInteractionType == "sleeping" then return false end

    local active = state and (
        state.isInteracting == true
        or state.interactionAssigned == true
        or state.currentAnimationQueued == true
    )
    if active == true then return false end

    local stopReason = data.reason or "wake_cleanup"
    local debugLog = state and state.debugLog or noopLog
    local animation = state and state.animation
    if animation and type(animation.forceClearQueue) == "function" then
        animation.forceClearQueue(debugLog, stopReason, true, state and state.selfRef)
    end
    if animation and type(animation.forceCancelSleepGroups) == "function" then
        animation.forceCancelSleepGroups(debugLog, stopReason, state and state.selfRef)
    end
    debugLog(
        "wake cleanup probe cleared sleep-only state",
        "reason", tostring(stopReason),
        "currentType", tostring(state and state.currentInteractionType)
    )
    return true
end

return M
