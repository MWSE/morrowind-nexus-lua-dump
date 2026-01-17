--[[
    NPC Parameters Module
    Handles reading and modifying NPC statistics: disposition, fight, alarm, flee
    Provides safe clamping and returns whether values actually changed
    Includes decay system for temporary disposition and alarm effects
]]

local logger = require("logging.logger")
local log = logger.new{
    name = "SmoothTalker.NpcParams",
    logLevel = "INFO"
}

local npcCustomData = require("SmoothTalker.npcCustomData")
local config = require("SmoothTalker.config")

local npcParams = {}

-- Stat type IDs for UI properties (must be integers)
npcParams.STAT_TYPE = {
	DISPOSITION = 1,
	ALARM = 2,
	FIGHT = 3,
	FLEE = 4,
	PATIENCE = 5
}

--- Clamp a value between min and max
--- @param value number
--- @param min number
--- @param max number
--- @return number
local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

--- Calculate new total and temporary values with overflow handling
--- @param current number Current stat value
--- @param oldTemporary number Current temporary modifier
--- @param amount number Amount to modify
--- @param temporary boolean|nil Whether this is a temporary modification
--- @return number newTotal The new clamped total value
--- @return number newTemporary The new temporary modifier
local function calculateNewValues(current, oldTemporary, amount, temporary)
    local newTotal = current + amount
    local clampedTotal = clamp(newTotal, 0, 100)
    local newTemporary

    if temporary then
        -- Temporary change: add to both current and temporary tracker
        newTemporary = oldTemporary + amount

        -- Adjust temporary for overflow/underflow
        local overflow = newTotal - clampedTotal
        newTemporary = newTemporary - overflow

        -- Clamp temporary to valid range
        newTemporary = clamp(newTemporary, 0, 100)
    else
        -- Permanent change: clamp permanent, adjust temporary to fit
        local newPermanent = clamp(newTotal - oldTemporary, 0, 100)
        newTemporary = clampedTotal - newPermanent
    end

    return clampedTotal, newTemporary
end

--- Internal: Modify NPC disposition without decay check (to avoid circular calls)
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @param temporary boolean|nil Whether this is a temporary effect (uses decay system)
--- @return boolean True if value changed, false if already at limit
local function modDispositionInternal(npcRef, amount, temporary)
    -- Force temporary to false if NPC doesn't support lua data
    if not npcRef.supportsLuaData then
        temporary = false
    end

    -- Get current values
    local current = npcParams.getDisposition(npcRef)
    local oldTemporary = npcRef.supportsLuaData and npcCustomData.getTemporaryDisposition(npcRef) or 0

    -- Calculate new values using helper
    local clampedTotal, newTemporary = calculateNewValues(current, oldTemporary, amount, temporary)

    -- Check if anything changed (total or temporary)
    local totalChanged = clampedTotal ~= current
    local temporaryChanged = newTemporary ~= oldTemporary

    if not totalChanged and not temporaryChanged then
        return false
    end

    -- Apply changes
    if totalChanged then
        local actualChange = clampedTotal - current
        tes3.modDisposition{reference = npcRef, value = actualChange}
    end

    if temporaryChanged and npcRef.supportsLuaData then
        npcCustomData.setTemporaryDisposition(npcRef, newTemporary)

        -- Refresh timer if we have any temporary effects
        if newTemporary ~= 0 then
            npcCustomData.refreshDecayTimer(npcRef)
        end
    end

    return true
end

--- Internal: Modify NPC alarm without decay check (to avoid circular calls)
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @param temporary boolean|nil Whether this is a temporary effect (uses decay system)
--- @return boolean True if value changed, false if already at limit
local function modAlarmInternal(npcRef, amount, temporary)
    -- Force temporary to false if NPC doesn't support lua data
    if not npcRef.supportsLuaData then
        temporary = false
    end

    -- Get current values
    local current = npcRef.mobile.alarm
    local oldTemporary = npcRef.supportsLuaData and npcCustomData.getTemporaryAlarm(npcRef) or 0

    -- Calculate new values using helper
    local newTotal, newTemporary = calculateNewValues(current, oldTemporary, amount, temporary)

    -- Check if anything changed (total or temporary)
    local totalChanged = newTotal ~= current
    local temporaryChanged = newTemporary ~= oldTemporary

    if not totalChanged and not temporaryChanged then
        return false
    end

    -- Apply changes
    if totalChanged then
        npcRef.mobile.alarm = newTotal
    end

    if temporaryChanged and npcRef.supportsLuaData then
        npcCustomData.setTemporaryAlarm(npcRef, newTemporary)

        -- Refresh timer if we have any temporary effects
        if newTemporary ~= 0 then
            npcCustomData.refreshDecayTimer(npcRef)
        end
    end

    return true
end

--- Apply decay to NPC if timer has expired
--- Reduces disposition and alarm by their temporary amounts and clears temporary tracking
--- @param npcRef tes3reference
local function applyDecayIfExpired(npcRef)
    if not npcRef or not npcRef.supportsLuaData then
        return
    end

    -- Check if decay timer has expired
    local timerExpired = npcCustomData.isDecayTimerExpired(npcRef, config.decayHours or 24)
    if not timerExpired then
        return
    end

    -- Get temporary values
    local tempDisposition = npcCustomData.getTemporaryDisposition(npcRef)
    local tempAlarm = npcCustomData.getTemporaryAlarm(npcRef)

    -- Apply decay to disposition (using internal version to avoid circular call)
    if tempDisposition ~= 0 then
        modDispositionInternal(npcRef, -tempDisposition)
        npcCustomData.setTemporaryDisposition(npcRef, 0)
    end

    -- Apply decay to alarm (using internal version to avoid circular call)
    if tempAlarm ~= 0 then
        modAlarmInternal(npcRef, -tempAlarm)
        npcCustomData.setTemporaryAlarm(npcRef, 0)
    end

    -- Clear the decay timer
    npcCustomData.clearDecayTimer(npcRef)
end

-- ============================================================================
-- DISPOSITION
-- ============================================================================

--- Get NPC disposition
--- @param npcRef tes3reference
--- @return number|nil Disposition value (0-100), or nil if not available
function npcParams.getDisposition(npcRef)
    if not npcRef or not npcRef.object then
        return nil
    end
    return npcRef.object.disposition
end

--- Modify NPC disposition with clamping and optional temporary/permanent tracking
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @param temporary boolean|nil Whether this is a temporary effect (uses decay system)
--- @return boolean True if value changed, false if already at limit
function npcParams.modDisposition(npcRef, amount, temporary)
    -- Apply decay first if timer expired
    applyDecayIfExpired(npcRef)

    -- Use internal version to do the actual modification
    return modDispositionInternal(npcRef, amount, temporary)
end

--- Set NPC disposition to a specific value
--- @param npcRef tes3reference
--- @param value number Value to set (0-100)
--- @return boolean True if successful
function npcParams.setDisposition(npcRef, value)
    local clamped = clamp(value, 0, 100)
    local current = npcRef.object.disposition
    local delta = clamped - current

    if delta == 0 then
        return false
    end

    tes3.modDisposition{reference = npcRef, value = delta}
    return true
end

-- ============================================================================
-- FIGHT
-- ============================================================================

--- Get NPC fight rating
--- @param npcRef tes3reference
--- @return number|nil Fight value (0-100), or nil if not available
function npcParams.getFight(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.fight
end

--- Modify NPC fight rating with clamping
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @return boolean True if value changed, false if already at limit
function npcParams.modFight(npcRef, amount)
    local fight = npcRef.mobile.fight
    local newFight = clamp(fight + amount, 0, 100)

    if newFight == fight then
        return false
    end

    npcRef.mobile.fight = newFight
    return true
end

--- Set NPC fight rating to a specific value
--- @param npcRef tes3reference
--- @param value number Value to set (0-100)
--- @return boolean True if successful
function npcParams.setFight(npcRef, value)
    local clamped = clamp(value, 0, 100)
    npcRef.mobile.fight = clamped
    return true
end

-- ============================================================================
-- ALARM
-- ============================================================================

--- Get NPC alarm rating
--- @param npcRef tes3reference
--- @return number|nil Alarm value (0-100), or nil if not available
function npcParams.getAlarm(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.alarm
end

--- Modify NPC alarm rating with clamping and optional temporary/permanent tracking
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @param temporary boolean|nil Whether this is a temporary effect (uses decay system)
--- @return boolean True if value changed, false if already at limit
function npcParams.modAlarm(npcRef, amount, temporary)
    -- Apply decay first if timer expired
    if npcRef.supportsLuaData then
        applyDecayIfExpired(npcRef)
    end

    -- Use internal version to do the actual modification
    return modAlarmInternal(npcRef, amount, temporary)
end

--- Set NPC alarm rating to a specific value
--- @param npcRef tes3reference
--- @param value number Value to set (0-100)
--- @return boolean True if successful
function npcParams.setAlarm(npcRef, value)
    local clamped = clamp(value, 0, 100)
    npcRef.mobile.alarm = clamped
    return true
end

-- ============================================================================
-- FLEE
-- ============================================================================

--- Get NPC flee rating
--- @param npcRef tes3reference
--- @return number|nil Flee value (0-100), or nil if not available
function npcParams.getFlee(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.flee
end

--- Modify NPC flee rating with clamping
--- @param npcRef tes3reference
--- @param amount number Amount to modify (positive or negative)
--- @return boolean True if value changed, false if already at limit
function npcParams.modFlee(npcRef, amount)
    local flee = npcRef.mobile.flee
    local newFlee = clamp(flee + amount, 0, 100)

    if newFlee == flee then
        return false
    end

    npcRef.mobile.flee = newFlee
    return true
end

--- Set NPC flee rating to a specific value
--- @param npcRef tes3reference
--- @param value number Value to set (0-100)
--- @return boolean True if successful
function npcParams.setFlee(npcRef, value)
    local clamped = clamp(value, 0, 100)
    npcRef.mobile.flee = clamped
    return true
end

-- ============================================================================
-- BASIC ATTRIBUTES
-- ============================================================================

--- Get NPC level
--- @param npcRef tes3reference
--- @return number|nil Level value, or nil if not available
function npcParams.getLevel(npcRef)
    if not npcRef or not npcRef.object then
        return nil
    end
    return npcRef.object.level
end

--- Get NPC personality
--- @param npcRef tes3reference
--- @return number|nil Personality value, or nil if not available
function npcParams.getPersonality(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.personality.current
end

--- Get NPC willpower
--- @param npcRef tes3reference
--- @return number|nil Willpower value, or nil if not available
function npcParams.getWillpower(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.willpower.current
end

--- Get NPC strength
--- @param npcRef tes3reference
--- @return number|nil Strength value, or nil if not available
function npcParams.getStrength(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.strength.current
end

--- Get NPC speechcraft
--- @param npcRef tes3reference
--- @return number|nil Speechcraft value, or nil if not available
function npcParams.getSpeechcraft(npcRef)
    if not npcRef or not npcRef.mobile then
        return nil
    end
    return npcRef.mobile.speechcraft.current
end

-- ============================================================================
-- FACTION AND HOSTILITY
-- ============================================================================

--- Get faction rank difference when player outranks NPC in same faction
--- @param npcRef tes3reference
--- @return number Rank difference (0 if not in same faction or player doesn't outrank)
function npcParams.getSameFactionRankDiff(npcRef)
    if not npcRef or not npcRef.object or not npcRef.object.faction then
        return 0
    end

    local npcFaction = npcRef.object.faction
    local npcRank = npcRef.object.factionRank or 0

    if not npcFaction.playerJoined then
        return 0
    end

    local rankDiff = npcFaction.playerRank - npcRank
    return math.max(0, rankDiff)
end

--- Check if NPC is hostile to player
--- @param npcRef tes3reference
--- @return boolean True if NPC is hostile to player
function npcParams.isNPCHostile(npcRef)
    if not npcRef or not npcRef.mobile then
        return false
    end

    for mobile in tes3.iterate(npcRef.mobile.hostileActors) do
        if mobile == tes3.mobilePlayer then
            return true
        end
    end

    return false
end

-- ============================================================================
-- DECAY SYSTEM
-- ============================================================================

--- Apply decay to NPC if timer has expired (public interface)
--- @param npcRef tes3reference
function npcParams.checkAndApplyDecay(npcRef)
    applyDecayIfExpired(npcRef)
end

return npcParams
