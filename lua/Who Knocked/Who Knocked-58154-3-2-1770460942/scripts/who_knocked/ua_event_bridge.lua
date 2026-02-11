-- =============================================================================
-- WHO KNOCKED EVENT BRIDGE v2.1
-- Bridges Who Knocked player events to global scripts
-- Listens to UA_DoorUnlocked events and forwards them globally
-- Enhanced with S3 Framework for professional-grade features
-- Fixed: Moved bounty application to global context
-- =============================================================================

print("DEBUG: ua_event_bridge.lua is loading!")

local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local MOD_ID = "EventBridge"

-- S3 Framework Integration
local success, ScriptContext = pcall(function() return require('scripts.s3.scriptContext') end)
local success2, LogMessage = pcall(function() return require('scripts.s3.logmessage') end)
local success3, ProtectedTableModule = pcall(function() return require('scripts.s3.protectedTable') end)

-- Context detection
local context = success and ScriptContext.get() or nil

-- Settings management (if S3 available)
local settings = nil
if success3 and ProtectedTableModule and ProtectedTableModule.new then
    settings = ProtectedTableModule.new({
        logPrefix = '[EventBridge]',
        inputGroupName = 'EventBridgeSettings'
    })
end

-- Helper functions with S3 integration
local function msg(message)
    if success2 and LogMessage then
        -- Use S3 context-aware logging
        LogMessage("[" .. MOD_ID .. "] " .. message)
    else
        -- Fallback to regular print
        print("[" .. MOD_ID .. "] " .. message)
    end
end

local function debugLog(message)
    if settings and settings.DebugLog then
        settings:debugLog(message)
    end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function onDoorUnlocked(data)
    if not data or not data.method then return end
    
    msg("Bridging door unlock event: " .. data.method)
    
    -- Skip forwarding for speechcraft methods (handled by dialogue system)
    if data.method == "admire" or data.method == "intimidate" or data.method == "bribe" then
        msg("Skipping bridge for speechcraft method: " .. data.method)
        return
    end
    
    -- Forward to global scripts
    core.sendGlobalEvent("UA_DoorUnlocked", {
        door = data.door,
        method = data.method,
        message = data.message
    })
end

local function onAddBounty(data)
    if not data or not data.bounty then return end
    
    debugLog("Processing bounty request: " .. data.bounty .. " for " .. (data.method or "unknown"))
    
    -- Get bounty multiplier from settings (if available)
    local multiplier = 1.0
    if settings then
        multiplier = settings.bountyMultiplier or 1.0
        debugLog("Using bounty multiplier: " .. multiplier)
    end
    
    -- Calculate final bounty
    local finalBounty = math.floor(data.bounty * multiplier)
    
    -- Add bounty to player
    local currentBounty = 0
    if types.Player.getBounty then
        currentBounty = types.Player.getBounty(self) or 0
    elseif types.Player.getCrimeLevel then
        currentBounty = types.Player.getCrimeLevel(self) or 0
    end
    
    local newBounty = currentBounty + finalBounty
    
    -- Send bounty application request to global script (player scripts can't apply bounty)
    debugLog("Sending bounty application request to global script: " .. finalBounty)
    msg("Requesting bounty addition: " .. finalBounty .. " gold for " .. data.method .. " unlock")
    
    -- Send global event for bounty application
    core.sendGlobalEvent("UA_ApplyBounty", {
        method = data.method,
        bounty = finalBounty,
        originalBounty = data.bounty,
        multiplier = multiplier,
        door = data.door,
        location = data.door and data.door.position
    })
    
    -- Show player notification (if enabled in settings)
    if settings and settings.MessageEnable and settings.showBountyNotifications then
        settings:notifyPlayer("Bounty: " .. finalBounty .. " gold for " .. data.method .. " unlock")
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Log initialization with context information
if success then
    msg("Who Knocked Event Bridge loaded with S3 Framework support")
    if context then
        local contextNames = {
            [1] = "Local",
            [2] = "Global", 
            [3] = "Player",
            [4] = "Menu"
        }
        msg("Running in context: " .. (contextNames[context] or "Unknown"))
    end
else
    msg("Who Knocked Event Bridge loaded (S3 Framework not available)")
end

if settings then
    msg("Settings management initialized")
    debugLog("EventBridge initialized with debug logging")
else
    msg("Settings management not available")
end

return {
    eventHandlers = {
        UA_DoorUnlocked = onDoorUnlocked,
        UA_AddBounty = onAddBounty
    }
}
