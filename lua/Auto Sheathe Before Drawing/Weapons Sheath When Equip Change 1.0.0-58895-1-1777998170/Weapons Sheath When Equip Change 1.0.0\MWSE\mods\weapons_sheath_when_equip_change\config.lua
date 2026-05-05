---@diagnostic disable: undefined-global

local configPath = "weapons_sheath_when_equip_change\\config"
local currentSchemaVersion = 3

local defaultConfig = {
    featureFlags = {
        enabled = true,
        debugLogging = false,
    },
    schemaVersion = currentSchemaVersion,
}

local state

local M = {}

local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, nestedValue in pairs(value) do
        result[key] = clone(nestedValue)
    end

    return result
end

function M.getDefaults()
    return clone(defaultConfig)
end

local function normalize(loadedState)
    local normalizedState = loadedState or {}

    normalizedState.featureFlags = normalizedState.featureFlags or clone(defaultConfig.featureFlags)
    normalizedState.featureFlags.enableScriptedFallbackReplay = nil
    normalizedState.timing = nil

    normalizedState.schemaVersion = currentSchemaVersion
    return normalizedState
end

function M.load()
    state = normalize(mwse.loadConfig(configPath, M.getDefaults()))
    mwse.saveConfig(configPath, state)
    return state
end

function M.get()
    if not state then
        return M.load()
    end

    return state
end

function M.save(newState)
    state = newState or M.get()
    mwse.saveConfig(configPath, state)
end

return M