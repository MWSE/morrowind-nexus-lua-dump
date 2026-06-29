-- assignment/settingsRescan.lua
---@omw-context none
-- Debounces full assignment rescans for text settings. In particular, blacklist
-- text boxes update on every keypress; rescanning the whole cell per character
-- is what makes typing into them feel like a freeze on heavier load orders.

local M = {}

local DEBOUNCED_SETTING_KEYS = {
    userNpcBlacklist = true,
    userFurnitureBlacklist = true,
    userCellBlacklist = true,
}

function M.newState()
    return { dueAt = nil, keys = {} }
end

function M.isDebouncedKey(key)
    return DEBOUNCED_SETTING_KEYS[tostring(key or "")] == true
end

function M.queue(state, now, key, delaySeconds)
    if not state then return nil end
    local text = tostring(key or "")
    if text == "" then return nil end
    state.keys = state.keys or {}
    state.keys[text] = true
    state.dueAt = (tonumber(now) or 0) + (tonumber(delaySeconds) or 0.85)
    return state.dueAt
end

local function joinedKeys(keys)
    local list = {}
    for key in pairs(keys or {}) do list[#list + 1] = key end
    table.sort(list)
    return table.concat(list, ",")
end

function M.process(state, now, env)
    if not (state and state.dueAt) then return false end
    now = tonumber(now) or 0
    if now < state.dueAt then return false end

    local keyText = joinedKeys(state.keys)
    state.dueAt = nil
    state.keys = {}
    env = env or {}
    if env.debugLog then env.debugLog("settings rescan debounced apply", tostring(keyText)) end
    if env.clearRelevantObjectCache then env.clearRelevantObjectCache("settings_debounced:" .. tostring(keyText)) end
    if env.onCellChange then env.onCellChange("settings_debounced") end
    return true
end

function M.reset(state)
    if not state then return end
    state.dueAt = nil
    state.keys = {}
end

return M
