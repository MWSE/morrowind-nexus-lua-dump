-- =============================================================================
-- WHO KNOCKED BOUNTY MONITOR
-- Bridge between Who Knocked events and vanilla bounty system
-- Listens to door unlock events and applies appropriate vanilla bounties
-- Enhanced with S3 Framework for professional-grade features
-- =============================================================================

print("DEBUG: ua_bounty_monitor.lua is loading!")

local world = require('openmw.world')
local MOD_ID = "BountyMonitor"

-- S3 Framework Integration
local success, ScriptContext = pcall(function() return require('scripts.s3.scriptContext') end)
local success2, LogMessage = pcall(function() return require('scripts.s3.logmessage') end)
local success3, ProtectedTable = pcall(function() return require('scripts.s3.protectedTable') end)

-- Context detection
local context = success and ScriptContext.get() or nil

-- Settings management (if S3 available)
local settings = nil
if success3 then
    settings = ProtectedTable.new({
        logPrefix = '[BountyMonitor]',
        inputGroupName = 'BountyMonitorSettings'
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

-- Bounty amounts for different unlock methods
local bountyAmounts = {
    force = 20,  -- Forcing locks is loud and obvious
    pick = 10,   -- Lockpicking is quieter but still illegal
    magic = 15   -- Magic unlock is suspicious
}

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function onDoorUnlocked(data)
    if not data or not data.method then return end
    
    debugLog("Received door unlock method: '" .. data.method .. "'")
    
    -- Skip bounty for speechcraft methods (handled by dialogue system)
    if data.method == "admire" or data.method == "intimidate" or data.method == "bribe" then
        debugLog("Skipping bounty for speechcraft method: " .. data.method)
        return
    end
    
    debugLog("Processing door unlock: " .. data.method)
    
    -- Get bounty amounts from settings (fallback to defaults)
    local bounty = 10
    if settings then
        -- Use custom bounty amounts if configured
        bounty = settings[data.method .. "Bounty"] or bountyAmounts[data.method] or 10
        debugLog("Bounty from settings: " .. bounty .. " for method: " .. data.method)
    else
        bounty = bountyAmounts[data.method] or 10
    end
    
    -- Apply global multiplier if configured
    local multiplier = 1.0
    if settings then
        multiplier = settings.globalBountyMultiplier or 1.0
        bounty = math.floor(bounty * multiplier)
        debugLog("Applied global multiplier: " .. multiplier .. ", final bounty: " .. bounty)
    end
    
    local player = world.players[1]
    
    if player then
        -- Send event to player script to add bounty
        player:sendEvent("UA_AddBounty", {
            bounty = bounty,
            method = data.method,
            door = data.door,
            message = data.message,
            originalBounty = bountyAmounts[data.method] or 10,
            multiplier = multiplier
        })
        
        msg("[BountyMonitor] Sent bounty request: " .. bounty .. " gold for " .. data.method .. " unlock")
        
        -- Log detailed info for debugging
        debugLog("Bounty request sent - method: " .. data.method .. ", amount: " .. bounty .. ", door: " .. (data.door and data.door.id or "unknown"))
    else
        msg("[BountyMonitor] ERROR: No player found to send bounty request")
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Log initialization with context information
if success then
    msg("[BountyMonitor] Who Knocked Bounty Monitor loaded with S3 Framework support")
    if context then
        local contextNames = {
            [1] = "Local",
            [2] = "Global", 
            [3] = "Player",
            [4] = "Menu"
        }
        msg("[BountyMonitor] Running in context: " .. (contextNames[context] or "Unknown"))
    end
else
    msg("[BountyMonitor] Who Knocked Bounty Monitor loaded (S3 Framework not available)")
end

if settings then
    msg("[BountyMonitor] Settings management initialized")
    debugLog("[BountyMonitor] Initialized with debug logging")
else
    msg("[BountyMonitor] Settings management not available")
end

return {
    eventHandlers = {
        UA_DoorUnlocked = onDoorUnlocked
    }
}
