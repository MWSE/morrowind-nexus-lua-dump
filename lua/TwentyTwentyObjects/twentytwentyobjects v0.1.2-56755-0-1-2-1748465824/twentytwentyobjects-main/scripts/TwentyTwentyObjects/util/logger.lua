-- logger.lua: Debug logging wrapper for Interactable Highlight mod
-- Provides conditional logging based on debug setting

-- local async = require('openmw.async') -- No longer strictly needed for core logging print
-- print("[TTO DEBUG LOGGER] Inside logger.lua - openmw.async type: " .. type(async) .. ", value: " .. tostring(async))

local M = {}

-- Log levels
M.LEVEL = {
    DEBUG = 'DEBUG',
    INFO = 'INFO',
    WARN = 'WARN',
    ERROR = 'ERROR'
}

-- Cache debug state
local currentDebugEnabled = false
-- local storage = nil -- No longer needed by logger directly

-- Initialize logger with the current debug state
function M.init(debugState) -- Expects a boolean
    currentDebugEnabled = debugState
    -- No longer subscribes here; init will be called by the managing script when state changes.
    -- For initial load, print a message indicating the logger's state.
    -- We can't use M.info/M.debug here as it might lead to recursion if called during init itself.
    print(string.format('[IH][LOGGER] Logger initialized. Debug mode: %s', tostring(currentDebugEnabled)))
end

-- Internal logging function
local function doLog(level, message)
    if level == M.LEVEL.ERROR or level == M.LEVEL.WARN or currentDebugEnabled then
        -- Use direct print for more robustness during initial script loading
        print(string.format('[IH][%s] %s', level, tostring(message)))
        -- async:runAfter(0, function() -- Deferring can be problematic if async is not ready
        --     print(string.format('[IH][%s] %s', level, tostring(message)))
        -- end)
    end
end

-- Public logging methods
function M.debug(message)
    doLog(M.LEVEL.DEBUG, message)
end

function M.info(message)
    doLog(M.LEVEL.INFO, message)
end

function M.warn(message)
    doLog(M.LEVEL.WARN, message)
end

function M.error(message)
    doLog(M.LEVEL.ERROR, message)
end

-- Log a table (useful for debugging)
function M.table(name, tbl)
    if not currentDebugEnabled then return end
    
    local function tableToString(t, indent)
        indent = indent or 0
        local spaces = string.rep("  ", indent)
        local result = "{\n"
        
        for k, v in pairs(t) do
            result = result .. spaces .. "  " .. tostring(k) .. " = "
            if type(v) == "table" then
                result = result .. tableToString(v, indent + 1)
            else
                result = result .. tostring(v)
            end
            result = result .. ",\n"
        end
        
        result = result .. spaces .. "}"
        return result
    end
    
    doLog(M.LEVEL.DEBUG, name .. ": " .. tableToString(tbl))
end

return M