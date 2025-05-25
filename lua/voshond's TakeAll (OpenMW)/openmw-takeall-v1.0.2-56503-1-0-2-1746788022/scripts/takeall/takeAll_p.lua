local core = require("openmw.core")
local async = require('openmw.async')
local input = require("openmw.input")
local ui = require("openmw.ui")
local types = require("openmw.types")
local settings = require("scripts.TakeAll.takeAll_settings")
local Debug = require("scripts.TakeAll.takeAll_debug")
local I = require("openmw.interfaces")
local self = require("openmw.self")

-- Main TakeAll module
local TakeAll = {}

-- Variable to store the currently opened container
local currentContainer = nil
-- Variable to store the currently opened book or scroll
local currentBook = nil

-- Test global script communication
local function testGlobalScript()
    Debug.log("TakeAll", "Testing global script communication")
    core.sendGlobalEvent("TakeAll_test", { "Test message from player script" })
end

-- Create the handler for the TakeAll trigger
local function onTakeAll()
    Debug.log("TakeAll", "--------------------------------")
    Debug.log("TakeAll", "TakeAll trigger activated!")

    if currentContainer then
        local containerName = currentContainer.type.records[currentContainer.recordId].name
        Debug.log("TakeAll", "Container detected: " .. containerName)

        -- Use the global script to take all items
        local player = self
            .object                       -- Make sure we're sending the player object
        local disposeCorpse = input.isShiftPressed() and
            settings:get("disposeCorpse") -- Check if Shift is pressed and disposal is enabled

        -- First, close the container interface if it's open
        if I.UI.getMode() == "Container" then
            -- Proper way to close UI in OpenMW
            I.UI.setMode()
        end

        -- Animate container opening first
        currentContainer:sendEvent("TakeAll_openAnimation", player)

        -- Process the items
        local itemCount = core.sendGlobalEvent("TakeAll_takeAll", { player, currentContainer, disposeCorpse }) or 0

        -- Make sure to notify global script that we've closed the UI
        core.sendGlobalEvent("TakeAll_closeGUI", player)

        -- Log item count but don't show UI messages
        if itemCount > 0 then
            Debug.log("TakeAll", "Took " .. itemCount .. " items from " .. containerName)
            if disposeCorpse and types.Actor.objectIsInstance(currentContainer) and types.Actor.isDead(currentContainer) then
                Debug.log("TakeAll", "Disposed of corpse: " .. containerName)
            end
        else
            Debug.log("TakeAll", "No items taken from container")
        end

        -- Reset container reference
        currentContainer = nil
    elseif currentBook ~= nil and settings:get("takeBooks") then
        Debug.log("TakeAll", "Book or scroll detected, taking it")

        -- Close the book/scroll interface
        if I.UI.getMode() == "Book" or I.UI.getMode() == "Scroll" then
            I.UI.setMode()
        end

        -- Take the book or scroll using the global script
        core.sendGlobalEvent("TakeAll_takeBook", { self.object, currentBook })

        -- Reset book reference
        currentBook = nil
    else
        Debug.log("TakeAll", "No container or book is currently open")
    end
end

-- Function to handle UI mode changes (detect when containers are opened/closed)
local function UiModeChanged(data)
    Debug.log("TakeAll", "UI Mode changed from " .. (data.oldMode or "none") .. " to " .. (data.newMode or "none"))

    -- Container is being opened
    if data.newMode == "Container" and data.arg then
        Debug.log("TakeAll", "Container opened: " .. data.arg.type.records[data.arg.recordId].name)
        currentContainer = data.arg
        currentBook = nil

        -- Notify global script that we've opened the UI
        core.sendGlobalEvent("TakeAll_openGUI", self.object)

        -- Send open animation event when container UI opens normally
        -- This doesn't prevent the UI from showing since it's already showing at this point
        if currentContainer then
            currentContainer:sendEvent("TakeAll_openAnimation", self.object)
        end
        -- Book is being opened
    elseif data.newMode == "Book" and data.arg then
        Debug.log("TakeAll", "Book opened: " .. data.arg.type.records[data.arg.recordId].name)
        currentBook = data.arg
        currentContainer = nil

        -- Notify global script that we've opened the UI
        core.sendGlobalEvent("TakeAll_openGUI", self.object)
        -- Scroll is being opened
    elseif data.newMode == "Scroll" and data.arg then
        Debug.log("TakeAll", "Scroll opened: " .. data.arg.type.records[data.arg.recordId].name)
        currentBook = data.arg
        currentContainer = nil

        -- Notify global script that we've opened the UI
        core.sendGlobalEvent("TakeAll_openGUI", self.object)
        -- Container is being closed
    elseif data.oldMode == "Container" then
        Debug.log("TakeAll", "Container closed")

        -- Only send the close animation if we have a valid container
        if currentContainer then
            -- Send close animation event
            currentContainer:sendEvent("TakeAll_closeAnimation", self.object)

            -- Notify global script that we've closed the UI
            core.sendGlobalEvent("TakeAll_closeGUI", self.object)

            -- Reset container reference
            currentContainer = nil
        end
        -- Book is being closed
    elseif data.oldMode == "Book" then
        Debug.log("TakeAll", "Book closed")

        -- Notify global script that we've closed the UI
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)

        -- Reset book reference
        currentBook = nil
        -- Scroll is being closed
    elseif data.oldMode == "Scroll" then
        Debug.log("TakeAll", "Scroll closed")

        -- Notify global script that we've closed the UI
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)

        -- Reset book reference
        currentBook = nil
    end
end

-- Initialize function for the TakeAll module
local function onInit()
    Debug.log("TakeAll", "TakeAll mod initialized!")

    -- Register the TakeAll trigger in the input system
    input.registerTrigger {
        key = "TakeAll",
        l10n = "SettingsTakeAll", -- Use same context as our settings
        name = "Take All",
        description = "Take all items from containers with a single key press"
    }

    -- Register our handler using async:callback pattern from QuickLoot
    input.registerTriggerHandler("TakeAll", async:callback(onTakeAll))

    -- Test global script communication on init
    testGlobalScript()
end

-- Clean up function for when script is unloaded
local function onSave()
    -- Reset the container reference when saving
    if currentContainer then
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)
    end
    if currentBook then
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)
    end
    currentContainer = nil
    currentBook = nil
    return {}
end

-- Load function to restore state
local function onLoad(data)
    -- Initialize the TakeAll system when loading a save
    onInit()
    -- Reset container reference on load
    if currentContainer then
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)
    end
    if currentBook then
        core.sendGlobalEvent("TakeAll_closeGUI", self.object)
    end
    currentContainer = nil
    currentBook = nil
    return {}
end

return {
    interfaceName = "TakeAll",
    interface = TakeAll,
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}
