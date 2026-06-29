---@omw-context none

local M = {}

local COALESCE_SECONDS = 0.5
local COALESCED_REASONS = {
    developer_test_npc_spawned = true,
    pending_local_invalid = true,
}

function M.new()
    local lastClearAt = {}

    local state = {}

    function state.shouldClear(reason, now)
        local reasonKey = tostring(reason or "unknown")
        if COALESCED_REASONS[reasonKey] ~= true then return true, reasonKey end

        now = tonumber(now) or 0
        local lastAt = lastClearAt[reasonKey]
        if lastAt and now >= lastAt and now - lastAt < COALESCE_SECONDS then return false, reasonKey end
        lastClearAt[reasonKey] = now
        return true, reasonKey
    end

    function state.reset()
        lastClearAt = {}
    end

    return state
end

return M
