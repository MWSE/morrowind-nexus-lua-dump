local core = require("openmw.core")
local storage = require("openmw.storage")
local settings = require("scripts.mapkey.mk_settings")
local I = require("openmw.interfaces")

local Debug = {}

local debug = false

function Debug.setDebug(value)
    debug = value
end

function Debug.isDebug()
    return debug
end

-- Function to print debug messages from the Map Key mod
function Debug.log(message)
    -- Only print if debug logging is enabled in settings
    if settings:get("enableDebugLogging") then
        print("[MapKey]: " .. message)
    end
end

-- Print available UI modes
function Debug.printUIModes()
    print("[MapKey] Available UI modes:")
    for mode, _ in pairs(I.UI.MODE) do
        print("  - " .. mode)
    end
end

-- Log version information on startup
Debug.log("Map Key Debug Module Loaded")

return Debug
