local core = require("openmw.core")
local async = require('openmw.async')
local input = require("openmw.input")
local ui = require("openmw.ui")
local settings = require("scripts.mapkey.mk_settings")
local Debug = require("scripts.mapkey.mk_debug")
local I = require("openmw.interfaces")
local self = require("openmw.self")

-- Main MapKey module
local MapKey = {}

-- Function to toggle the map (open/close)
local function toggleMap()
    Debug.log("Map toggle triggered via hotkey")

    -- Check current UI mode
    local currentMode = I.UI.getMode()

    -- If we're already in Interface mode with Map window, close it
    if currentMode == "Interface" then
        -- Close all windows by setting no mode (equivalent to none)
        I.UI.setMode()
        Debug.log("Map closed")
    else
        -- Only open map if not in combat or other restricted UI modes
        if not currentMode or currentMode == "MenuMode" then
            -- Set Interface mode with only the Map window showing
            I.UI.setMode("Interface", { windows = { "Map" } })
            Debug.log("Map opened successfully")
        else
            Debug.log("Cannot open map in UI mode: " .. currentMode)
        end
    end
end


local function toggleInventory()
    Debug.log("Map toggle triggered via hotkey")

    -- Check current UI mode
    local currentMode = I.UI.getMode()

    -- If we're already in Interface mode with Map window, close it
    if currentMode == "Interface" then
        -- Close all windows by setting no mode (equivalent to none)
        I.UI.setMode()
        Debug.log("Map closed")
    else
        -- Only open map if not in combat or other restricted UI modes
        if not currentMode or currentMode == "MenuMode" then
            -- Set Interface mode with only the Map window showing
            I.UI.setMode("Interface", {
                windows = {
                    "Inventory",
                    "Stats",
                    "Magic"
                }
            })
            Debug.log("Map opened successfully")
        else
            Debug.log("Cannot open map in UI mode: " .. currentMode)
        end
    end
end

-- Initialize function
local function onInit()
    Debug.log("Map Key mod initialized!")

    -- Get debug setting from storage
    local debugMode = settings:get("enableDebugLogging")
    Debug.setDebug(debugMode)

    -- Register the OpenMap trigger in the input system
    input.registerTrigger {
        key = "OpenMap",
        l10n = "SettingsMapKey", -- Use same context as our settings
        name = "Open Map",
        description = "Opens the map screen with a single key press"
    }

    -- Register the OpenInventory trigger in the input system
    input.registerTrigger {
        key = "OpenInventory",
        l10n = "SettingsMapKey", -- Use same context as our settings
        name = "Open Inventory",
        description = "Opens the inventory without the map"
    }

    -- Register our handlers using async:callback pattern
    input.registerTriggerHandler("OpenMap", async:callback(toggleMap))
    input.registerTriggerHandler("OpenInventory", async:callback(toggleInventory))
end

-- Clean up function for when script is unloaded
local function onSave()
    Debug.log("Map Key onSave called")
    return {}
end

-- Load function to restore state
local function onLoad(data)
    Debug.log("Map Key onLoad called")
    -- Initialize when loading a save
    onInit()
    return {}
end

return {
    interfaceName = "MapKey",
    interface = MapKey,
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad
    }
}
