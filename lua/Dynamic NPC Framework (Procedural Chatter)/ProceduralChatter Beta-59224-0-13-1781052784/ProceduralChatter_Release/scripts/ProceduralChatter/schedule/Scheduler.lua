-- Scheduler.lua  (Rebuilt — JSON Schedule System)
-- Minimal scheduler: single module, no batching, no handoffs, no window management.
--
-- Responsibilities:
--   • Trigger evaluation (PlayerCell:Whitelist)
--   • Candidate collection from the player's cell
--   • Assignment tracking (authoritative source for who is dispatched where)
--   • Dispatch proposals through Relocator
--   • Route onArrivedDoor / releaseAssignment callbacks to the active module
--
-- Called by:
--   global.lua onUpdate  -> Scheduler.tick(dt, hour, player)
--   Relocator            -> Scheduler.onArrivedDoor(ev)
--                        -> Scheduler.releaseAssignment(npcId, reason)
--   JSONScheduleModule   -> Scheduler.getAssignment(npcId)
--                        -> Scheduler.registerAssignment(...)
--                        -> Scheduler.releaseAssignment(npcId, reason)

local core     = require("openmw.core")
local types    = require("openmw.types")
local world    = require("openmw.world")

local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local NPCState       = require("scripts.ProceduralChatter.NPCState")
local Blacklist      = require("scripts.ProceduralChatter.Blacklist")

local DEBUG = ScheduleConfig.DEBUG_MODE
local function dbg(msg)
    if DEBUG then print("[Scheduler] " .. tostring(msg)) end
end

-- =============================================================================
-- Internal state
-- =============================================================================

-- The single registered module (JSONScheduleModule).
local activeModule = nil

-- Registered triggers (evaluated each tick).
local triggers = {}

-- Assignment tracking: [npcId] = { moduleName, phase, dest, npc }
-- Authoritative record of which NPCs are currently under schedule control.
local assignments = {}

-- =============================================================================
-- Public API
-- =============================================================================

local Scheduler = {}

--- Register a trigger object.
-- Trigger must implement: { id=string, evaluate(ctx)->bool }
function Scheduler.registerTrigger(trigger)
    if not trigger or not trigger.id or type(trigger.evaluate) ~= "function" then return end
    for _, t in ipairs(triggers) do
        if t.id == trigger.id then return end
    end
    triggers[#triggers + 1] = trigger
    dbg("Registered trigger: " .. trigger.id)
end

--- Register the active destination module.
-- Only one module is active at a time (JSONScheduleModule).
function Scheduler.registerModule(module)
    if not module or not module.id then return end
    activeModule = module
    dbg("Registered module: " .. module.id)
end

--- Get the current assignment for an NPC.
-- Returns nil if not assigned, otherwise:
--   { moduleName=string, phase=string, dest=table, npc=object }
function Scheduler.getAssignment(npcId)
    return assignments[npcId]
end

--- Explicitly register an assignment without going through tick().
-- Used by reconcileCell's ADMIT pass when it dispatches NPCs directly via
-- Relocator, bypassing the normal tick -> shouldEngage -> dispatch path.
function Scheduler.registerAssignment(npcId, moduleName, dest, npcObj)
    print(string.format("[Scheduler] registerAssignment npc=%s module=%s dest='%s' npcValid=%s",
        tostring(npcId), tostring(moduleName), tostring(dest and dest.destCellName or "?"),
        tostring(npcObj ~= nil)))
    assignments[npcId] = {
        moduleName = moduleName,
        phase      = "traveling_to_destination",
        dest       = dest,
        npc        = npcObj,
    }
    NPCState.set(npcId, "traveling_to_destination")
end

--- Release an NPC from their current assignment.
-- Fires activeModule.onDepart before clearing so the module can run teardown.
function Scheduler.releaseAssignment(npcId, reason)
    local a = assignments[npcId]
    if not a then
        print(string.format("[Scheduler] releaseAssignment SKIP npc=%s (no assignment)", tostring(npcId)))
        return
    end
    print(string.format("[Scheduler] releaseAssignment npc=%s module=%s reason=%s",
        tostring(npcId), tostring(a.moduleName), tostring(reason or "unspecified")))
    if activeModule and type(activeModule.onDepart) == "function" then
        local npc = a.npc
        if npc then
            local ok, err = pcall(activeModule.onDepart, npc, a)
            if not ok then
                print(string.format("[Scheduler] onDepart ERROR npc=%s: %s", tostring(npcId), tostring(err)))
            else
                print(string.format("[Scheduler] onDepart ok npc=%s", tostring(npcId)))
            end
        else
            print(string.format("[Scheduler] onDepart SKIP no npc object npc=%s", tostring(npcId)))
        end
    end
    assignments[npcId] = nil
    NPCState.clear(npcId)
    print(string.format("[Scheduler] releaseAssignment DONE npc=%s", tostring(npcId)))
end

--- Clear an assignment without firing module.onDepart.
-- Used when reconcile is immediately replacing a stale assignment with the
-- current schedule target; releaseAssignment would route the NPC home first.
function Scheduler.clearAssignment(npcId, reason)
    if not assignments[npcId] then
        print(string.format("[Scheduler] clearAssignment SKIP npc=%s (no assignment)", tostring(npcId)))
        return
    end
    assignments[npcId] = nil
    NPCState.clear(npcId)
    print(string.format("[Scheduler] clearAssignment DONE npc=%s reason=%s",
        tostring(npcId), tostring(reason or "unspecified")))
end

--- Called by Relocator when an NPC materialises at their destination.
-- Advances the assignment phase and fires activeModule.onArrived.
function Scheduler.onArrivedDoor(ev)
    if not ev or not ev.npc then
        print("[Scheduler] onArrivedDoor ABORT no npc")
        return
    end
    local npcId = ev.npc.id
    local a = assignments[npcId]
    if not a then
        print(string.format("[Scheduler] onArrivedDoor SKIP no assignment npc=%s", tostring(npcId)))
        return
    end
    print(string.format("[Scheduler] onArrivedDoor npc=%s module=%s", tostring(npcId), tostring(a.moduleName)))
    a.phase = "at_destination"
    NPCState.set(npcId, "at_destination")
    if activeModule and type(activeModule.onArrived) == "function" then
        local ok, err = pcall(activeModule.onArrived, ev.npc, a.dest)
        if not ok then
            print(string.format("[Scheduler] onArrived ERROR npc=%s: %s", tostring(npcId), tostring(err)))
        end
    end
end

-- =============================================================================
-- tick()
-- =============================================================================

--- Main scheduler tick, called from global.lua onUpdate every frame.
-- Evaluates triggers, collects candidates, asks the module for proposals,
-- and dispatches each proposal immediately through Relocator.
function Scheduler.tick(dt, gameHour, player)
    if not ScheduleConfig.SCHEDULE_MOVEMENT_ENABLED then
        return
    end
    if not activeModule then
        print("[Scheduler] tick SKIP no activeModule")
        return
    end

    -- -----------------------------------------------------------------
    -- 1. Evaluate triggers
    -- -----------------------------------------------------------------
    local triggerState = {}
    local ctx = { gameHour = gameHour, player = player }
    for _, trigger in ipairs(triggers) do
        local ok, result = pcall(trigger.evaluate, ctx)
        triggerState[trigger.id] = ok and result or false
    end

    -- Check the module's required triggers are all active.
    if activeModule.requiredTriggers then
        for _, tid in ipairs(activeModule.requiredTriggers) do
            if not triggerState[tid] then
                print(string.format("[Scheduler] tick SKIP trigger '%s' inactive", tid))
                return
            end
        end
    end

    -- -----------------------------------------------------------------
    -- 2. Collect candidates from the player's cell
    -- -----------------------------------------------------------------
    local candidates = {}
    if player and player.cell then
        local ok, result = pcall(function() return player.cell:getAll(types.NPC) end)
        if ok and result then
            for _, npc in ipairs(result) do
                local alive = true
                pcall(function() alive = not types.Actor.isDead(npc) end)
                if not alive then goto skip end

                if Blacklist.isScheduleBlacklisted(npc) then goto skip end
                if Blacklist.isQuestLocked(npc, player) then goto skip end

                -- Already assigned — skip.
                if assignments[npc.id] then goto skip end

                candidates[#candidates + 1] = npc
                ::skip::
            end
        end
    end

    -- -----------------------------------------------------------------
    -- 3. Ask the module for proposals
    -- -----------------------------------------------------------------
    local proposals = {}
    if type(activeModule.shouldEngage) == "function" then
        local ok, result = pcall(activeModule.shouldEngage, triggerState, candidates)
        if ok and result then
            proposals = result
            if #proposals > 0 then
                print(string.format("[Scheduler] tick proposals=%d", #proposals))
            end
        elseif not ok then
            print(string.format("[Scheduler] shouldEngage ERROR: %s", tostring(result)))
        end
    end

    -- -----------------------------------------------------------------
    -- 4. Dispatch each proposal immediately via Relocator
    -- -----------------------------------------------------------------
    local Relocator = nil
    pcall(function()
        Relocator = require("scripts.ProceduralChatter.schedule.Relocator")
    end)
    if not Relocator then
        print("[Scheduler] tick SKIP no Relocator")
        return
    end

    for _, proposal in ipairs(proposals) do
        local npc   = proposal.npc
        local npcId = npc and npc.id
        if npcId then
            print(string.format("[Scheduler] tick dispatching npc=%s dest='%s'", tostring(npcId),
                tostring(proposal.dest and proposal.dest.destCellName or "?")))
            -- Record assignment BEFORE dispatch so Relocator can query it
            assignments[npcId] = {
                moduleName = activeModule.id,
                phase      = "traveling_to_destination",
                dest       = proposal.dest,
                npc        = npc,
            }
            NPCState.set(npcId, "traveling_to_destination")

            local dispOk, dispErr = pcall(Relocator.dispatchSmooth, npc, proposal.dest, activeModule.id)
            if not dispOk then
                print(string.format("[Scheduler] dispatchSmooth ERROR npc=%s: %s", tostring(npcId), tostring(dispErr)))
                assignments[npcId] = nil
                NPCState.clear(npcId)
            else
                print(string.format("[Scheduler] dispatchSmooth ok npc=%s", tostring(npcId)))
            end
        end
    end
end

-- =============================================================================
-- Debug
-- =============================================================================

function Scheduler.dumpState()
    if not DEBUG then return end
    print("[Scheduler] === State Dump ===")
    local count = 0
    for npcId, a in pairs(assignments) do
        count = count + 1
        print(string.format("[Scheduler]   NPC=%s module=%s phase=%s",
            tostring(npcId), tostring(a.moduleName), tostring(a.phase)))
    end
    print(string.format("[Scheduler] Total: %d assigned", count))
    print("[Scheduler] === End Dump ===")
end

return Scheduler
