---@diagnostic disable: undefined-global

local config = require("weapons_sheath_when_equip_change.config")

local logger = mwse.Logger.new("Weapons Sheath When Equip Change")

local M = {}

local function isDebugEnabled()
    local state = config.get()
    local featureFlags = state.featureFlags or {}
    return featureFlags.debugLogging == true
end

function M.get()
    return logger
end

function M.debug(...)
    if isDebugEnabled() then
        logger:debug(...)
    end
end

function M.info(...)
    logger:info(...)
end

function M.warn(...)
    logger:warn(...)
end

function M.error(...)
    logger:error(...)
end

return M