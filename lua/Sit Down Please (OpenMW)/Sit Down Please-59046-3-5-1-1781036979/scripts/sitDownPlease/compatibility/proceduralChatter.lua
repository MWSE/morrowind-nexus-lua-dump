-- compatibility/proceduralChatter.lua
---@omw-context all
--
-- Lightweight cooperation with ProceduralChatter without replacing its files or
-- writing its settings. ProceduralChatter persists active NPC ownership in
-- PC_NPCStates; SDP reads that section only when ProceduralChatter.omwscripts
-- is present in load order, then yields to active PC ownership states. Some PC
-- setup states are transient, so SDP's global script also mirrors observed
-- PC_StateChanged events into a short-lived SDP-owned section for local scripts.

local storage = require('openmw.storage')

local M = {}

local CONTENT_FILES = {
    ["proceduralchatter.omwscripts"] = true,
}

local NPC_STATES_SECTION = "PC_NPCStates"
local TRANSIENT_STATES_SECTION = "SDP_ProceduralChatterTransientStates"
local TRANSIENT_STATE_TTL = 5.0

local ASSIGNMENT_BLOCK_STATES = {
    pending_conversation = true,
    conversation = true,
    pending_activity = true,
    activity = true,
    traveling_to_destination = true,
    -- PC keeps these states while schedule-owned actors are settled at a
    -- destination/home. They are not active animation control, but they should
    -- reserve the actor from new SDP assignments.
    at_destination = true,
    traveling_home = true,
    at_home = true,
    pending_sleep = true,
    sleeping = true,
    waking = true,
    sitting = true,
    traveling_to_seat = true,
    departing = true,
    transitioning = true,
    arriving = true,
    walking = true,
    returning = true,
    hostile = true,
}

local PHYSICAL_CONTROL_STATES = {
    pending_activity = true,
    activity = true,
    traveling_to_destination = true,
    traveling_home = true,
    pending_sleep = true,
    sleeping = true,
    waking = true,
    sitting = true,
    traveling_to_seat = true,
    departing = true,
    transitioning = true,
    arriving = true,
    walking = true,
    returning = true,
    hostile = true,
}

local detected = nil
local stateSection = nil
local transientSection = nil

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function contentFileLooksLikeProceduralChatter(fileName)
    local name = lower(fileName)
    if name == "" then return false end
    return CONTENT_FILES[name] == true
        or name:find("proceduralchatter", 1, true) ~= nil
end

function M.detectContent(core)
    if not (core and core.contentFiles) then return false, "missing_contentfiles_api" end

    if core.contentFiles.has then
        for fileName in pairs(CONTENT_FILES) do
            local ok, present = pcall(core.contentFiles.has, fileName)
            if ok and present == true then return true, fileName end
        end
    end

    local list = core.contentFiles.list
    if type(list) == "table" then
        for _, fileName in ipairs(list) do
            if contentFileLooksLikeProceduralChatter(fileName) then
                return true, tostring(fileName)
            end
        end
    end

    return false, "not_in_load_order"
end

function M.active(core)
    if detected ~= nil then return detected == true end
    local present = M.detectContent(core)
    detected = present == true
    return detected == true
end

local function section(core)
    if not M.active(core) then return nil end
    if stateSection ~= nil then return stateSection end
    local ok, result = pcall(function()
        return storage.globalSection(NPC_STATES_SECTION)
    end)
    if ok then stateSection = result end
    return stateSection
end

local function transientStateSection(core)
    if not M.active(core) then return nil end
    if transientSection ~= nil then return transientSection end
    local ok, result = pcall(function()
        return storage.globalSection(TRANSIENT_STATES_SECTION)
    end)
    if ok then transientSection = result end
    return transientSection
end

local function simulationTime(core)
    if not (core and core.getSimulationTime) then return nil end
    local ok, now = pcall(core.getSimulationTime)
    if ok and type(now) == "number" then return now end
    return nil
end

local function clearTransient(actorId, core)
    local store = transientStateSection(core)
    if not store then return end
    pcall(function() store:set(tostring(actorId), nil) end)
end

local function transientState(actor, core)
    if not (actor and actor.id) then return nil end
    local store = transientStateSection(core)
    if not store then return nil end

    local key = tostring(actor.id)
    local ok, value = pcall(function()
        return store:get(key)
    end)
    if not ok or value == nil then return nil end

    local state = nil
    local observedAt = nil
    if type(value) == "table" then
        state = lower(value.state)
        observedAt = tonumber(value.observedAt)
    else
        state = lower(value)
    end

    if ASSIGNMENT_BLOCK_STATES[state] ~= true then
        clearTransient(key, core)
        return nil
    end

    local now = simulationTime(core)
    if observedAt and now and (now - observedAt) > TRANSIENT_STATE_TTL then
        clearTransient(key, core)
        return nil
    end

    return state
end

function M.noteStateChanged(data, core)
    if not (data and data.npcId) then return end
    local store = transientStateSection(core)
    if not store then return end

    local key = tostring(data.npcId)
    local state = lower(data.state)
    if ASSIGNMENT_BLOCK_STATES[state] ~= true then
        pcall(function() store:set(key, nil) end)
        return
    end

    pcall(function()
        store:set(key, {
            state = state,
            observedAt = simulationTime(core),
        })
    end)
end

function M.state(actor, core)
    if not (actor and actor.id) then return nil end
    local store = section(core)
    if store then
        local ok, value = pcall(function()
            return store:get(tostring(actor.id))
        end)
        if ok then
            local state = lower(value)
            if state ~= "" and state ~= "idle" then return state end
        end
    end
    return transientState(actor, core)
end

function M.assignmentBlockReason(actor, core)
    local state = M.state(actor, core)
    if state and ASSIGNMENT_BLOCK_STATES[state] == true then
        return "procedural_chatter_" .. state
    end
    return nil
end

function M.physicalControlReason(actor, core)
    local state = M.state(actor, core)
    if state and PHYSICAL_CONTROL_STATES[state] == true then
        return "procedural_chatter_" .. state
    end
    return nil
end

return M
