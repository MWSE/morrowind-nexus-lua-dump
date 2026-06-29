---@omw-context none

local M = {}

function M.new(env)
    env = env or {}
    local util = assert(env.util, "ui.calibrationActionState requires util")
    local state = {
        externalClaimed = false,
        hasActor = false,
        hasFurniture = false,
        sdpOwned = false,
        interactionType = nil,
        nudgeEnabled = false,
        fillOrTestExists = false,
        actionButtons = nil,
    }

    function state.clear()
        state.nudgeEnabled = false
        state.externalClaimed = false
        state.hasActor = false
        state.hasFurniture = false
        state.sdpOwned = false
        state.interactionType = nil
    end

    function state.setFillOrTestExists(value)
        state.fillOrTestExists = value == true
    end

    function state.setNudgeEnabled(value)
        state.nudgeEnabled = value == true
    end

    function state.isNudgeEnabled()
        return state.nudgeEnabled == true
    end

    function state.update(data, rows, resolvedType)
        rows = rows or {}
        state.interactionType = data and data.interactionType or resolvedType
        if data then
            state.externalClaimed = data.externalPhysicalClaimed == true
                or data.hardBlockerReason == "external_furniture_claimed"
                or data.rejectionReason == "external_furniture_claimed"
            if data.sdpOwnedAssignment ~= nil then
                state.sdpOwned = data.sdpOwnedAssignment == true
            end
            if data.fillOrTestExists ~= nil then
                state.fillOrTestExists = data.fillOrTestExists == true
            end
            if data.nudgeEnabled ~= nil then
                state.nudgeEnabled = data.nudgeEnabled == true
            end
        end
        state.hasActor = tostring(rows.actor or "") ~= ""
        state.hasFurniture = tostring(rows.furniture or "") ~= ""
    end

    function state.enabled(action, context)
        context = context or {}
        action = tostring(action or "")
        if action == "capture" or action == "spawn_test" or action == "fill_furniture" or action == "cycle_target" then return true end
        if action == "remove_test" then return state.fillOrTestExists == true end
        if action == "assign_nearest" then return state.externalClaimed ~= true end
        if tostring(context.targetLabel or "") == "" then return false end
        if action == "clear" then return true end

        local interactionType = state.interactionType or context.displayType
        if interactionType == "station" then
            return state.hasFurniture == true and state.externalClaimed ~= true
        end

        local ownedActorTarget = state.sdpOwned == true and state.hasActor == true and state.externalClaimed ~= true
        if action == "send" then
            return state.hasActor == true and state.hasFurniture == true and state.externalClaimed ~= true
        end
        if action == "resume" or action == "reapply" or action == "print" or action == "reset" then
            return ownedActorTarget
        end
        if action == "nudge" then return state.nudgeEnabled == true end
        return true
    end

    function state.refreshButton(button)
        if not button then return end
        local enabled = true
        if button.enabled then
            local ok, value = pcall(button.enabled)
            enabled = ok and value == true
        end
        if button.background and button.background.props then
            button.background.props.color = enabled
                and util.color.rgb(0.08, 0.065, 0.045)
                or util.color.rgb(0.035, 0.032, 0.030)
        end
        if button.textLayout and button.textLayout.props then
            button.textLayout.props.textColor = enabled
                and util.color.rgb(0.94, 0.92, 0.84)
                or util.color.rgb(0.42, 0.40, 0.36)
        end
    end

    function state.refreshButtons(buttons)
        for _, button in pairs(buttons or {}) do
            state.refreshButton(button)
        end
    end

    return state
end

return M
