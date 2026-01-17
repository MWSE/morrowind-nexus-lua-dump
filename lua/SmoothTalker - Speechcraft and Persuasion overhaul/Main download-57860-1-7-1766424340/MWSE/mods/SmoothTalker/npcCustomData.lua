--[[
    NPC Custom Data Management Module
    Provides safe accessor functions for NPC persistent custom data
    Only handles mod-specific data stored in npcRef.data.SmoothTalker
]]

local npcCustomData = {}

--[[
    SmoothTalker NPC Custom Data Structure
    =======================================
    npcRef.data.SmoothTalker = {
        -- Patience System Fields
        patience = number,                    -- Current patience value (0-100)
        lastInteractionTime = timestamp|nil,  -- Timer for patience regeneration (nil = not running)

        -- Decay System Fields
        temporaryDisposition = number,        -- Temporary disposition modifier
        temporaryAlarm = number,              -- Temporary alarm modifier
        decayTimer = timestamp|nil            -- Timer for temporary effect decay (nil = not running)
    }
]]

--- Get NPC name for logging
--- @param npcRef tes3reference
--- @return string
local function getNpcName(npcRef)
    return npcRef.object.name or npcRef.object.id or "unknown"
end

--- Internal: Get data table (creates if needed, doesn't initialize fields)
--- @param npcRef tes3reference
--- @return table|nil The NPC's SmoothTalker data table, or nil if not supported
local function getDataTable(npcRef)
    if not npcRef or not npcRef.supportsLuaData then
        return nil
    end

    -- Initialize the data table if it doesn't exist
    if not npcRef.data.SmoothTalker then
        npcRef.data.SmoothTalker = {}
        npcRef.modified = true
    end

    return npcRef.data.SmoothTalker
end

-- ============================================================================
-- PATIENCE TIMER
-- ============================================================================

--- Check if patience timer has expired
--- @param npcRef tes3reference
--- @param thresholdHours number Number of hours before timer expires
--- @return boolean True if timer expired, false if still running or not started
function npcCustomData.isPatienceTimerExpired(npcRef, thresholdHours)
    local data = getDataTable(npcRef)
    if not data then
        return false
    end

    local lastTime = data.lastInteractionTime
    if lastTime == nil then
        return false
    end

    local currentTime = tes3.getSimulationTimestamp()
    local timePassed = currentTime - lastTime
    return timePassed >= thresholdHours
end

--- Check if patience timer is currently running (started but not expired)
--- @param npcRef tes3reference
--- @param thresholdHours number Number of hours before timer expires
--- @return boolean True if timer is running and not expired
function npcCustomData.isPatienceTimerRunning(npcRef, thresholdHours)
    local data = getDataTable(npcRef)
    if not data then
        return false
    end

    -- Timer is running if it's started but not expired
    return data.lastInteractionTime ~= nil and not npcCustomData.isPatienceTimerExpired(npcRef, thresholdHours)
end

--- Reset the patience regeneration timer
--- @param npcRef tes3reference
--- @return boolean True if successful
function npcCustomData.resetPatienceTimer(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end

    local timestamp = tes3.getSimulationTimestamp()
    data.lastInteractionTime = timestamp
    npcRef.modified = true
    return true
end

--- Clear the patience regeneration timer (stop timer)
--- @param npcRef tes3reference
--- @return boolean True if successful
function npcCustomData.clearPatienceTimer(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end

    data.lastInteractionTime = nil
    npcRef.modified = true
    return true
end

-- ============================================================================
-- PATIENCE
-- ============================================================================

--- Get NPC patience value
--- @param npcRef tes3reference
--- @return number|nil Patience value, or nil if not initialized
function npcCustomData.getNPCPatience(npcRef)
    local data = getDataTable(npcRef)
    if not data then return nil end

    return data.patience
end

--- Set NPC patience value
--- @param npcRef tes3reference
--- @param value number Patience value to set
--- @return boolean True if successful
function npcCustomData.setNPCPatience(npcRef, value)
    local data = getDataTable(npcRef)
    if not data then return false end

    data.patience = value
    npcRef.modified = true
    return true
end

--- Check if NPC patience is initialized
--- @param npcRef tes3reference
--- @return boolean True if patience exists
function npcCustomData.hasNPCPatience(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end
    return data.patience ~= nil
end

--- Modify NPC patience value
--- @param npcRef tes3reference
--- @param amount number Amount to add (can be negative)
--- @return boolean True if successful
function npcCustomData.modNPCPatience(npcRef, amount)
    local data = getDataTable(npcRef)
    if not data then return false end

    local oldValue = data.patience or 0
    local newValue = math.max(0, math.min(100, oldValue + amount))
    data.patience = newValue
    npcRef.modified = true
    return true
end

-- ============================================================================
-- DECAY TIMER
-- ============================================================================

--- Check if decay timer has expired
--- @param npcRef tes3reference
--- @param thresholdHours number Number of hours before timer expires
--- @return boolean True if timer expired, false if still running or not started
function npcCustomData.isDecayTimerExpired(npcRef, thresholdHours)
    local data = getDataTable(npcRef)
    if not data then return false end

    local decayTime = data.decayTimer
    if decayTime == nil then
        return false
    end

    local currentTime = tes3.getSimulationTimestamp()
    local timePassed = currentTime - decayTime
    return timePassed >= thresholdHours
end

--- Check if decay timer is currently running (started but not expired)
--- @param npcRef tes3reference
--- @param thresholdHours number Number of hours before timer expires
--- @return boolean True if timer is running and not expired
function npcCustomData.isDecayTimerRunning(npcRef, thresholdHours)
    local data = getDataTable(npcRef)
    if not data then
        return false
    end

    -- Timer is running if it's started but not expired
    return data.decayTimer ~= nil and not npcCustomData.isDecayTimerExpired(npcRef, thresholdHours)
end

--- Start or reset the decay timer
--- @param npcRef tes3reference
--- @return boolean True if successful
function npcCustomData.refreshDecayTimer(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end

    local timestamp = tes3.getSimulationTimestamp()
    data.decayTimer = timestamp
    npcRef.modified = true
    return true
end

--- Clear the decay timer (stop timer)
--- @param npcRef tes3reference
--- @return boolean True if successful
function npcCustomData.clearDecayTimer(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end

    data.decayTimer = nil
    npcRef.modified = true
    return true
end

-- ============================================================================
-- TEMPORARY STATS
-- ============================================================================

--- Get temporary disposition modifier
--- @param npcRef tes3reference
--- @return number Temporary disposition modifier (0 if not set)
function npcCustomData.getTemporaryDisposition(npcRef)
    local data = getDataTable(npcRef)
    if not data then return 0 end
    return data.temporaryDisposition or 0
end

--- Get temporary alarm modifier
--- @param npcRef tes3reference
--- @return number Temporary alarm modifier (0 if not set)
function npcCustomData.getTemporaryAlarm(npcRef)
    local data = getDataTable(npcRef)
    if not data then return 0 end
    return data.temporaryAlarm or 0
end

--- Set temporary disposition modifier
--- @param npcRef tes3reference
--- @param value number Temporary disposition modifier
--- @return boolean True if successful
function npcCustomData.setTemporaryDisposition(npcRef, value)
    local data = getDataTable(npcRef)
    if not data then return false end

    data.temporaryDisposition = value
    npcRef.modified = true
    return true
end

--- Set temporary alarm modifier
--- @param npcRef tes3reference
--- @param value number Temporary alarm modifier
--- @return boolean True if successful
function npcCustomData.setTemporaryAlarm(npcRef, value)
    local data = getDataTable(npcRef)
    if not data then return false end

    data.temporaryAlarm = value
    npcRef.modified = true
    return true
end

--- Modify temporary disposition modifier
--- @param npcRef tes3reference
--- @param amount number Amount to add
--- @return boolean True if successful
function npcCustomData.modTemporaryDisposition(npcRef, amount)
    local data = getDataTable(npcRef)
    if not data then return false end

    local oldValue = data.temporaryDisposition or 0
    local newValue = oldValue + amount
    data.temporaryDisposition = newValue
    npcRef.modified = true
    return true
end

--- Modify temporary alarm modifier
--- @param npcRef tes3reference
--- @param amount number Amount to add
--- @return boolean True if successful
function npcCustomData.modTemporaryAlarm(npcRef, amount)
    local data = getDataTable(npcRef)
    if not data then return false end

    local oldValue = data.temporaryAlarm or 0
    local newValue = oldValue + amount
    data.temporaryAlarm = newValue
    npcRef.modified = true
    return true
end

--- Check if any temporary disposition is tracked
--- @param npcRef tes3reference
--- @return boolean True if temporary disposition exists
function npcCustomData.hasTemporaryDisposition(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end
    return data.temporaryDisposition ~= nil and data.temporaryDisposition ~= 0
end

--- Check if any temporary alarm is tracked
--- @param npcRef tes3reference
--- @return boolean True if temporary alarm exists
function npcCustomData.hasTemporaryAlarm(npcRef)
    local data = getDataTable(npcRef)
    if not data then return false end
    return data.temporaryAlarm ~= nil and data.temporaryAlarm ~= 0
end

return npcCustomData
