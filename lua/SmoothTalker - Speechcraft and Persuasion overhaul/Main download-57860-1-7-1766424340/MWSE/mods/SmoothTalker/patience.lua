--[[
    SmoothTalker Patience System
    Centralized patience management for NPCs
]]

local npcCustomData = require("SmoothTalker.npcCustomData")
local npcParams = require("SmoothTalker.npcParams")
local persuasionModifiers = require("SmoothTalker.persuasionModifiers")
local config = require("SmoothTalker.config")

local patience = {}

-- ============================================================================
-- INITIAL PATIENCE CALCULATION
-- ============================================================================

--- Calculate initial patience value for an NPC
--- @param npcRef tes3reference The NPC reference
--- @return number The calculated initial patience value
local function calculateInitialPatience(npcRef)
	local multipliers = persuasionModifiers.initialPatienceMultipliers
	local playerMobile = tes3.mobilePlayer
	local disposition = npcParams.getDisposition(npcRef) or 0

	local patienceValue = multipliers.base
	patienceValue = patienceValue + math.floor(disposition * multipliers.disposition)
	patienceValue = patienceValue + math.floor(playerMobile.speechcraft.current * multipliers.speechcraft)
	patienceValue = patienceValue + math.floor(playerMobile.personality.current * multipliers.personality)
	patienceValue = patienceValue + math.floor(tes3.player.object.reputation * multipliers.reputation)

	-- Add faction bonus if NPC has a faction and player is a member
	if npcRef.object.faction and npcRef.object.faction.playerJoined then
		patienceValue = patienceValue + multipliers.sameFaction
	end

	return math.max(multipliers.minPatience, patienceValue)
end

-- ============================================================================
-- PATIENCE HANDLING
-- ============================================================================

--- Start patience timer if not already running
--- @param npcRef tes3reference
--- @return boolean True if timer was started or already running
local function startPatienceTimer(npcRef)
    -- Check if timer is already running
    local timerRunning = npcCustomData.isPatienceTimerRunning(npcRef, config.patienceRegenHours)

    if not timerRunning then
        npcCustomData.resetPatienceTimer(npcRef)
        return true
    end

    return false
end

--- Get patience value
--- Automatically handles initialization and timer expiry
--- @param npcRef tes3reference
--- @return number|nil Patience value, or nil if NPC doesn't support data
function patience.getPatience(npcRef)
    if not npcRef or not npcRef.supportsLuaData then
        return nil
    end

    -- Check if timer has expired or patience not set
    local timerExpired = npcCustomData.isPatienceTimerExpired(npcRef, config.patienceRegenHours)
    local currentPatience = npcCustomData.getNPCPatience(npcRef)

    -- Regenerate/initialize if needed
    if timerExpired or currentPatience == nil then
        local newPatience = calculateInitialPatience(npcRef)
        npcCustomData.setNPCPatience(npcRef, newPatience)
        npcCustomData.clearPatienceTimer(npcRef)
        return newPatience
    end

    return currentPatience
end

--- Set patience value
--- Optionally starts the regeneration timer
--- @param npcRef tes3reference
--- @param value number Patience value to set
--- @param startTimer boolean|nil Whether to start the regeneration timer (default false)
function patience.setPatience(npcRef, value, startTimer)
    if not npcRef or not npcRef.supportsLuaData then
        return
    end

    npcCustomData.setNPCPatience(npcRef, value)

    if startTimer then
        startPatienceTimer(npcRef)
    end
end

--- Modify patience value
--- Uses getPatience to handle initialization/regeneration, then applies the modification
--- Starts timer if not already running
--- @param npcRef tes3reference
--- @param amount number Amount to change (can be negative)
function patience.modPatience(npcRef, amount)
    if not npcRef or not npcRef.supportsLuaData then
        return
    end

    -- Get current patience (handles initialization/regeneration automatically)
    local oldPatience = patience.getPatience(npcRef)

    -- Apply modification
    npcCustomData.modNPCPatience(npcRef, amount)
    local newPatience = npcCustomData.getNPCPatience(npcRef) or 0

    -- Start timer if not already running
    startPatienceTimer(npcRef)

    -- Trigger event if patience just became depleted
    if oldPatience > 0 and newPatience == 0 then
        local persuasionMenuOpen = tes3ui.findMenu("MenuPersuasionImproved") ~= nil

        --- @class SmoothTalkerPatienceDepletedEventData
        local eventData = {
            npcRef = npcRef,
            persuasionMenuOpen = persuasionMenuOpen
        }
        event.trigger("SmoothTalker:PatienceDepleted", eventData)
    end
end

--- Check if patience is depleted
--- Returns false if not initialized or if timer expired (regenerated patience is never 0)
--- @param npcRef tes3reference
--- @return boolean True if patience is depleted (0)
function patience.isDepleted(npcRef)
    if not npcRef or not npcRef.supportsLuaData then
        return false
    end

    -- If timer expired, patience regenerates, so not depleted
    if npcCustomData.isPatienceTimerExpired(npcRef, config.patienceRegenHours) then
        return false
    end

    -- If not initialized, not depleted
    if not npcCustomData.hasNPCPatience(npcRef) then
        return false
    end

    local patienceValue = npcCustomData.getNPCPatience(npcRef)
    return patienceValue ~= nil and patienceValue <= 0
end

return patience
