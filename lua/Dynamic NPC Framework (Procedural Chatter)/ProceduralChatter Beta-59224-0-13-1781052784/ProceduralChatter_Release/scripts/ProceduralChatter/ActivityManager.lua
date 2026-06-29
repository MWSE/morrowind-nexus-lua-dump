-- ActivityManager.lua (Global)
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')

local Activities = require("scripts.ProceduralChatter.data.ActivityLibrary")
local SittingGlobal = require("scripts.ProceduralChatter.SittingGlobal")
local TimeService = require("scripts.ProceduralChatter.TimeService")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local Utils = require("scripts.ProceduralChatter.Utils")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")

local ActivityManager = {}

local function normalizePosture(posture)
    if posture == "sitting" then return "sit" end
    if posture == "standing" then return "stand" end
    return posture or "both"
end

-- State
local busyNpcs = {} -- Set by ConversationManager / activity flow (id -> reason token)
local npcCooldowns = {} -- id -> gametime (when cooldown expires)
local pendingAssignments = {} -- npc.id -> { npc } (Waiting for Posture Check)
local pendingActivities = {} -- npc.id -> { npc, choice, isSitting, timer }
local activityStateSeenAt = {} -- npc.id -> simulation time first observed in activity/pending state
local updateTimer = 0
local UPDATE_INTERVAL = 8.0 -- Check periodically (User requested 8s)
local STALE_ACTIVITY_SECONDS = 60.0
local waitMenuActive = false
local dialogueMenuActive = false

-- Settings (Default)
local cooldownMin = 10
local cooldownMax = 30 
local chatterEnabled = true

-- Event: Received parameters from Player
local function onUpdateSettings(data)
    if data.min then cooldownMin = data.min end
    if data.max then cooldownMax = data.max end
    if data.enabled ~= nil then chatterEnabled = data.enabled end
    -- print(string.format("[ActivityManager] Settings Updated: Min=%d, Max=%d, Enabled=%s", cooldownMin, cooldownMax, tostring(chatterEnabled)))
end

-- Event: Debug toggle from settings menu
local function onUpdateDebugToggles(data)
    if data.activitiesEnabled ~= nil then
        ScheduleConfig.ACTIVITY_MANAGER_ENABLED = data.activitiesEnabled
    end
end

-- Helper: Check if NPC provides services
local function isServiceProvider(npc)
    local services = types.NPC.record(npc).services
    if not services then return false end
    for _, val in pairs(services) do
        if val then return true end
    end
    return false
end

-- Helper: Check if NPC is a Guard (Class or Name)
local function isGuard(npc)
    local record = types.NPC.record(npc)
    if not record then return false end
    
    local class = string.lower(record.class or "")
    local name = string.lower(record.name or "")
    
    if class == "guard" or string.find(name, "guard") then
        return true
    end
    return false
end

-- Helpers
local function isBusy(npc)
    if busyNpcs[npc.id] then return true end
    if NPCState.isSleeping(npc.id) or NPCState.isPendingSleep(npc.id) then return true end
    if NPCState.isInTransit(npc.id) then return true end
    return false
end

local function getBusyReason(npcId)
    return busyNpcs[npcId]
end

local function isActivityEligibleState(npcId)
    return NPCState.canActivity(npcId)
end

local function isPlayerActor(npc)
    if not npc then return false end
    local player = world.players and world.players[1]
    if not player then return false end
    if npc.id == player.id then return true end
    local rid = ""
    pcall(function() rid = string.lower(npc.recordId or "") end)
    return rid == "player"
end

local function dbg(msg)
    if ScheduleConfig.DEBUG_MODE then
        print("[ActivityManager] " .. tostring(msg))
    end
end

local function isOnCooldown(npc)
    if not npcCooldowns[npc.id] then return false end
    return true -- Cooldown exists (managed by onUpdate decrement)
end

local function setCooldown(npc)
    local duration = math.random(cooldownMin, cooldownMax)
    npcCooldowns[npc.id] = { timer = duration }
end

local function collectCellNpcs(cell)
    return Utils.collectCellNpcs(cell)
end

local function getSimulationTime()
    local ok, now = pcall(core.getSimulationTime)
    if ok and now then return now end
    return 0
end

local function clearActivityTracking(npcId)
    busyNpcs[npcId] = nil
    pendingAssignments[npcId] = nil
    pendingActivities[npcId] = nil
    activityStateSeenAt[npcId] = nil
end

local function reconcileStaleActivityState(npc)
    if not npc or not npc.id then return end
    local npcId = npc.id
    local state = NPCState.get(npcId)
    if state ~= "activity" and state ~= "pending_activity" then
        activityStateSeenAt[npcId] = nil
        return
    end

    local now = getSimulationTime()
    local seenAt = activityStateSeenAt[npcId]
    if not seenAt then
        activityStateSeenAt[npcId] = now
        return
    end

    if now - seenAt < STALE_ACTIVITY_SECONDS then return end

    print(string.format("[ActivityManager] Clearing stale %s state for %s reason=%s age=%.1fs",
        tostring(state), tostring(npc.recordId), tostring(busyNpcs[npcId]), now - seenAt))
    clearActivityTracking(npcId)
    NPCState.clear(npcId)
    pcall(function()
        npc:sendEvent("PC_StopActivity", {
            silent = true,
            forceClearAll = true,
            reason = "stale_activity_watchdog",
        })
    end)
    setCooldown(npc)
end

-- Initial Eligibility Scan
local function scanAndAssign(dt)
    if not chatterEnabled then return end

    -- DECREMENT COOLDOWNS
    -- DECREMENT COOLDOWNS (Handled in onUpdate now)

    -- Random Chance to Skip Update (Throttle)
    -- Also only pick RANDOM % of NPCs.
    
    local players = world.players
    if #players == 0 then return end
    local cell = players[1].cell -- simplified: only active cell of player 1 for now
    
    -- Filter Candidates
    local candidates = {}
    local cellNpcs = collectCellNpcs(cell)
    dbg(string.format("SCAN INPUT npcCountInCell=%d", #cellNpcs))
    for _, npc in ipairs(cellNpcs) do
        reconcileStaleActivityState(npc)
        local npcName = (types.NPC.record(npc) and types.NPC.record(npc).name) or npc.recordId or tostring(npc.id)
        local state = NPCState.get(npc.id)
        local dead = types.Actor.stats.dynamic.health(npc).current <= 0
        local busy = isBusy(npc)
        local cooldown = isOnCooldown(npc)
        local eligibleState = isActivityEligibleState(npc.id)
        local enabled = false
        pcall(function() enabled = npc.enabled end)

        -- Skip Guards
        if isPlayerActor(npc) then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=player", npcName, state))
        elseif not enabled then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=disabled", npcName, state))
        elseif Blacklist.isActorBlacklisted(npc, "activity") then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=blacklisted", npcName, state))
        elseif isGuard(npc) then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=guard", npcName, state))
        elseif dead then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=dead", npcName, state))
        elseif busy then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=busy(%s)",
                npcName, state, tostring(getBusyReason(npc.id))))
        elseif cooldown then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=cooldown", npcName, state))
        elseif not eligibleState then
            dbg(string.format("SCAN SKIP %-28s state=%-22s reason=ineligible_state", npcName, state))
        else
            dbg(string.format("SCAN CAND %-28s state=%-22s", npcName, state))
            table.insert(candidates, npc)
        end
    end

    -- Process Random %
    local processCount = math.ceil(#candidates * 0.20) -- 20% per pass
    if processCount < 1 and #candidates > 0 then processCount = 1 end
    
    -- Shuffle
    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    -- Assign (Async Step 1: Query)
    dbg(string.format("SCAN RESULT candidates=%d processCount=%d", #candidates, processCount))
    for i = 1, processCount do
        local npc = candidates[i]
        if npc then
             -- We need to check posture (Sitting vs Standing) before choosing activity.
             -- Procedural sitters are known by SittingGlobal, but Vanilla sitters need check.
             -- Send Query to NPC (Async).
             pendingAssignments[npc.id] = { npc = npc }
             npc:sendEvent("PC_QueryPosture") -- Request status
        end
    end
    if #candidates > processCount then
        for i = processCount + 1, #candidates do
            local npc = candidates[i]
            if npc then
                local npcName = (types.NPC.record(npc) and types.NPC.record(npc).name) or npc.recordId or tostring(npc.id)
                dbg(string.format("SCAN DEFER %-27s reason=not_selected_this_pass", npcName))
            end
        end
    end
end

-- Async Assignment Logic (Step 2: Receive Report)
local function onReturnPosture(data)
    -- data: { npc = object, isSitting = bool }
    if not data.npc then return end

    -- Drop stale posture results for hostile NPCs
    if NPCState.isHostile(data.npc.id) then
        pendingAssignments[data.npc.id] = nil
        return
    end
    
    local pending = pendingAssignments[data.npc.id]
    if pending then
         -- Clear pending
         pendingAssignments[data.npc.id] = nil

         local npc = data.npc

         -- Re-check availability: the NPC may have been assigned a bed or
         -- started sleeping between the posture query and this response.
         local enabled = false
         pcall(function() enabled = npc.enabled end)
         if not enabled or isBusy(npc) or not isActivityEligibleState(npc.id) then
             dbg(string.format("POSTURE DROP %-28s reason=state_changed_or_busy state=%s",
                (types.NPC.record(npc) and types.NPC.record(npc).name) or npc.recordId or tostring(npc.id),
                tostring(NPCState.get(npc.id))))
             return
         end

         local isSitting = data.isSitting
         local validActs = {}
         local rejectCounts = {
            posture = 0,
            location = 0,
            condition = 0,
            class = 0,
            time = 0,
            disabled = 0
         }
         local period = TimeService.getPeriod()

         for _, act in pairs(Activities) do
             local p = normalizePosture(act.posture)
             local loc = act.location or "both"
             local isExterior = npc.cell.isExterior

             local validLoc = (loc == "both")
                or (loc == "interior" and not isExterior)
                or (loc == "exterior" and isExterior)

             local validCond = (not act.condition or act.condition(npc))

             -- Class restriction check
             local validClass = true
             if act.class then
                 local npcRecord = types.NPC.record(npc)
                 validClass = (tostring(npcRecord.class) == act.class)
             end

             -- Time window check: activities with timeWindows only fire during allowed periods.
             -- Activities without timeWindows are unrestricted.
             local validTime = true
             if act.timeWindows then
                 validTime = act.timeWindows[period] == true
             end

             local validPosture = (p == "both")
                or (p == "sit" and isSitting)
                or (p == "stand" and not isSitting)

             if act.enabled ~= false and validLoc and validCond and validClass and validTime and validPosture then
                 table.insert(validActs, act)
             else
                 if act.enabled == false then rejectCounts.disabled = rejectCounts.disabled + 1 end
                 if not validLoc then rejectCounts.location = rejectCounts.location + 1 end
                 if not validCond then rejectCounts.condition = rejectCounts.condition + 1 end
                 if not validClass then rejectCounts.class = rejectCounts.class + 1 end
                 if not validTime then rejectCounts.time = rejectCounts.time + 1 end
                 if not validPosture then rejectCounts.posture = rejectCounts.posture + 1 end
             end
         end
         
         if #validActs > 0 then
             local totalWeight = 0
             for _, act in ipairs(validActs) do
                 totalWeight = totalWeight + (act.frequency or 1.0)
             end
             local r = math.random() * totalWeight
             local choice
             for _, act in ipairs(validActs) do
                 r = r - (act.frequency or 1.0)
                 if r <= 0 then choice = act break end
             end
             if not choice then choice = validActs[#validActs] end
             
             print(string.format("[ActivityManager] Pending assignment of %s to %s (Sitting: %s) for 1s", choice.id, npc.recordId, tostring(isSitting)))
             
             NPCState.set(npc.id, "pending_activity")
             busyNpcs[npc.id] = "pending_activity"
             pendingActivities[npc.id] = {
                 npc = npc,
                 choice = choice,
                 isSitting = isSitting,
                 timer = 1.0
             }
         else
            local name = (types.NPC.record(npc) and types.NPC.record(npc).name) or npc.recordId or tostring(npc.id)
            dbg(string.format(
                "NO_ASSIGN %-24s sitting=%s period=%s state=%s rejects{posture=%d,location=%d,condition=%d,class=%d,time=%d,disabled=%d}",
                name,
                tostring(isSitting),
                tostring(period),
                tostring(NPCState.get(npc.id)),
                rejectCounts.posture,
                rejectCounts.location,
                rejectCounts.condition,
                rejectCounts.class,
                rejectCounts.time,
                rejectCounts.disabled
            ))
         end
    end
end


local function onUpdate(dt)
    if not ScheduleConfig.ACTIVITY_MANAGER_ENABLED then return end
    if waitMenuActive then return end

    -- Update pending activity timers
    for id, pending in pairs(pendingActivities) do
        pending.timer = pending.timer - dt
        if pending.timer <= 0 then
            if dialogueMenuActive then
                -- Defer promotion until dialogue closes
                pending.timer = 0.5
            else
                pendingActivities[id] = nil
                local npc = pending.npc
                local choice = pending.choice
                
                -- Re-check availability: if a higher-priority event (like sitting, sleeping,
                -- relocation, or combat) overrode the activity, state in NPCState will no longer be "pending_activity".
                local state = NPCState.get(id)
                if state == "pending_activity" then
                    -- Promote to active activity state!
                    NPCState.set(id, "activity")
                    -- No conflict! Start the activity
                    busyNpcs[id] = choice.id
                    print(string.format("[ActivityManager] Starting pending activity %s for %s", choice.id, npc.recordId))
                    if not choice.compatibleWithWandering then
                        npc:sendEvent("PC_StopWander")
                    end
                    npc:sendEvent("PC_StartActivity", { 
                        activityId = choice.id,
                        minLoops = choice.minLoops,
                        maxLoops = choice.maxLoops
                    })
                else
                    -- Conflict! Overridden by higher priority state
                    print(string.format("[ActivityManager] Activity %s for %s overridden by higher priority state (%s). Aborting.",
                        choice.id, npc.recordId, tostring(state)))
                    busyNpcs[id] = nil
                end
            end
        end
    end

    updateTimer = updateTimer + dt
    if not dialogueMenuActive and updateTimer > UPDATE_INTERVAL then
         scanAndAssign(updateTimer) -- pass elapsed real time for cooldowns? No.
         updateTimer = 0
    end
    
    -- Decrement Cooldowns (Roughly)
    if dt > 0 then
        for id, data in pairs(npcCooldowns) do
            data.timer = data.timer - dt
            if data.timer <= 0 then npcCooldowns[id] = nil end
        end
    end
end

-- Handlers
local function onSetBusy(data)
    -- data: { npc = object?, npcId = id?, busy = bool }
    if not data then return end
    local npcId = data.npcId or (data.npc and data.npc.id)
    if not npcId then return end
    if data.busy then
        busyNpcs[npcId] = "conversation"
        -- Force End Activity? 
        -- ConversationManager sends StopActivity separately to local script.
        -- But Global should know they are unavailable.
    else
        busyNpcs[npcId] = nil
        -- Set Cooldown?
        -- If conversation ends, maybe give them a break before sweeping?
        if data.npc then
            setCooldown(data.npc)
        end
    end
end

local function onActivityStarted(data)
    -- data: { npc = object, activityId = string }
    if not data or not data.npc then return end
    if data.activityId then
        busyNpcs[data.npc.id] = data.activityId
    else
        busyNpcs[data.npc.id] = true -- Fallback
    end
    activityStateSeenAt[data.npc.id] = getSimulationTime()
end

local function onActivityFinished(data)
    -- data: { npc = object }
    if not data.npc then return end
    clearActivityTracking(data.npc.id)
    setCooldown(data.npc) -- Start 10-30s cooldown
    local state = NPCState.get(data.npc.id)
    if state == "activity" or state == "pending_activity" then
        NPCState.clear(data.npc.id)
    end
    print(string.format("[ActivityManager] Activity Finished for %s. Cooldown started.", data.npc.recordId))
end

function ActivityManager.clearForNpc(npcOrId, reason)
    local npc = type(npcOrId) == "table" and npcOrId or nil
    local npcId = npc and npc.id or npcOrId
    if not npcId then return end

    pendingAssignments[npcId] = nil
    pendingActivities[npcId] = nil
    busyNpcs[npcId] = nil
    activityStateSeenAt[npcId] = nil

    local state = NPCState.get(npcId)
    if state == "activity" or state == "pending_activity" then
        NPCState.clear(npcId)
    end

    if npc then
        pcall(function()
            npc:sendEvent("PC_StopActivity", {
                silent = true,
                forceClearAll = true,
                reason = reason or "global_cleanup",
            })
        end)
    end
end

local function onTeleport(data)
    if data.npc and data.position then
        local player = world and world.players and world.players[1]
        if player and data.npc.id == player.id then
            print("[ActivityManager] PC_Teleport ignored for player")
            return
        end
        -- Optional: Validate cell
        local destCell = data.cell or data.npc.cell
        local options = {}
        if data.rotation then options.rotation = data.rotation end
        
        data.npc:teleport(destCell, data.position, options)
    end
end

--- Returns true if the NPC is currently tracked as doing an activity.
function ActivityManager.isActive(npcId)
    local reason = busyNpcs[npcId]
    return reason ~= nil and reason ~= "conversation"
end

--- Teleport-resolve all in-progress activities in the player's cell after wait time elapses.
function ActivityManager.wrapUpInstantForWait()
    local player = world and world.players and world.players[1]
    if not player or not player.cell then return end

    pendingActivities = {}
    pendingAssignments = {}

    local count = 0
    pcall(function()
        for _, npc in ipairs(player.cell:getAll(types.NPC)) do
            if npc and npc.id then
                local state = NPCState.get(npc.id)
                if state == "activity" or state == "pending_activity" or busyNpcs[npc.id] then
                    count = count + 1
                    clearActivityTracking(npc.id)
                    NPCState.clear(npc.id)
                    pcall(function()
                        npc:sendEvent("PC_StopActivity", { instant = true })
                    end)
                end
            end
        end
    end)
    if count > 0 then
        print(string.format("[ActivityManager] wrapUpInstantForWait: stopped %d activity/activities", count))
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        PC_UpdateSettings = onUpdateSettings,
        PC_UpdateDebugToggles = onUpdateDebugToggles,
        PC_SetBusy = onSetBusy,
        PC_ActivityStarted = onActivityStarted,
        PC_ActivityFinished = onActivityFinished,
        PC_ClearActivityForNpc = function(data)
            if data then
                ActivityManager.clearForNpc(data.npc or data.npcId, data.reason)
            end
        end,
        PC_ReturnPosture = onReturnPosture,
        PC_Teleport = onTeleport,
        PC_WaitMenuState = function(ev)
            waitMenuActive = ev and ev.active == true
        end,
        PC_DialogueMenuState = function(ev)
            dialogueMenuActive = ev and ev.active == true
        end,
    }
}
