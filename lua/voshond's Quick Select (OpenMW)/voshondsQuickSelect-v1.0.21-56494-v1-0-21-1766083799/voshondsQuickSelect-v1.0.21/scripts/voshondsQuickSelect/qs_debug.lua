local storage = nil
local settings = nil

pcall(function()
    storage = require('openmw.storage')
    if storage then
        settings = storage.playerSection("SettingsVoshondsQuickSelect")
    end
end)

-- Debug module to centralize all logging functionality
local Debug = {}

-- Main logging function that checks if debug is enabled before printing
function Debug.log(module, message)
    if settings and settings:get("enableDebugLogging") then
        print("[" .. module .. "] " .. tostring(message))
    end
end

-- Frame-based logging for high-frequency updates (UI refreshes, animations, etc.)
-- This is separate from regular debug logging to avoid spamming the console
function Debug.frameLog(module, message)
    if settings and settings:get("enableFrameLogging") then
        print("[FRAME:" .. module .. "] " .. tostring(message))
    end
end

-- Shorthand for specific module logs
function Debug.hotbar(message)
    Debug.log("HOTBAR DEBUG", message)
end

function Debug.quickSelect(message)
    Debug.log("QuickSelect", message)
end

function Debug.storage(message)
    Debug.log("QuickSelect_Storage", message)
end

function Debug.items(message)
    Debug.log("QuickSelect_Items", message)
end

-- Function for enchantment charge updates
function Debug.enchantCharge(message)
    -- Use a separate setting to control enchantment charge logging
    if settings and settings:get("enableEnchantChargeLogging") then
        print("[EnchantCharge] " .. tostring(message))
    end
end

-- Function to report errors that will always print regardless of debug setting
function Debug.error(module, message)
    print("[ERROR:" .. module .. "] " .. tostring(message))
end

-- Function to report warnings that will always print regardless of debug setting
function Debug.warning(module, message)
    print("[WARNING:" .. module .. "] " .. tostring(message))
end

-- Utility function to create a conditional print function
-- This can be used to replace direct print() calls
function Debug.createPrinter(module)
    return function(message)
        Debug.log(module, message)
    end
end

-- Function to check if debug logging is enabled
function Debug.isEnabled()
    return settings and settings:get("enableDebugLogging") or false
end

-- Function to check if frame logging is enabled
function Debug.isFrameLoggingEnabled()
    return settings and settings:get("enableFrameLogging") or false
end

-- Function to check if enchantment charge logging is enabled
function Debug.isEnchantChargeLoggingEnabled()
    return settings and settings:get("enableEnchantChargeLogging") or false
end

return Debug
