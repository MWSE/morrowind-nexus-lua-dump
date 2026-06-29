-- PostArrivalCoordinator.lua
-- Lightweight behavior resolver that decides what an NPC should do after
-- materialization, wake, stand-up, activity end, or conversation end.
-- Prevents the schedule/sleep/sit/activity systems from fighting over NPC state.

local TimeService    = require("scripts.ProceduralChatter.TimeService")
local NPCState       = require("scripts.ProceduralChatter.NPCState")
local Scheduler      = require("scripts.ProceduralChatter.schedule.Scheduler")
local SittingGlobal  = require("scripts.ProceduralChatter.SittingGlobal")

local PostArrivalCoordinator = {}

function PostArrivalCoordinator.evaluate(npc, context)
    local npcId = npc.id
    local period = TimeService.getPeriod()
    local state = NPCState.get(npcId)
    print(string.format("[PostArrivalCoordinator] evaluate npc=%s context=%s state=%s period=%s", tostring(npc.recordId), tostring(context), tostring(state), tostring(period)))

    -- Priority 1: Schedule departure pending?
    local schedAssign = Scheduler.getAssignment(npcId)
    if schedAssign and schedAssign.phase == "traveling_to_destination" then
        print(string.format("[PostArrivalCoordinator] SKIP %s (schedule traveling)", tostring(npc.recordId)))
        return
    end
    -- "at_destination" / "at_home" are steady states, not movement states.
    -- Post-arrival behavior is exactly what should run after Scheduler marks an
    -- NPC at_destination, so only suppress while actual movement is still active.
    if NPCState.isInTransit(npcId) then
        print(string.format("[PostArrivalCoordinator] SKIP %s (schedule state=%s)", tostring(npc.recordId), tostring(state)))
        return
    end

    -- Priority 2: Already assigned to sit?
    if SittingGlobal.isAssigned and SittingGlobal.isAssigned(npcId) then
        print(string.format("[PostArrivalCoordinator] SKIP %s (sitting assigned)", tostring(npc.recordId)))
        return
    end

    -- Priority 3: Night time — let SleepManager handle bed assignment.
    -- Use requestScan instead of scanAndAssignBeds directly so that
    -- SleepManager can coalesce scans and avoid the double-scan race
    -- where onCellChange and PostArrivalCoordinator both send
    -- PC_ConsiderBeds to a newly materialised NPC.
    if period == "night" then
        print(string.format("[PostArrivalCoordinator] REQUEST sleep scan for %s (night)", tostring(npc.recordId)))
        local ok, SleepManager = pcall(require, "scripts.ProceduralChatter.SleepManager")
        if ok and SleepManager and SleepManager.requestScan then
            pcall(function()
                SleepManager.requestScan(npc.cell)
            end)
        end
        return
    end

    -- Priority 4: NPCs in their native home cell should NOT be sent wander.
    -- They will naturally return to their pre-activity position and resume nativeHome.wander.
    local homeCell = NPCState.loadNativeHome(npc)
    if homeCell then
        local sameCell = false
        pcall(function()
            sameCell = npc.cell and npc.cell.name == homeCell
        end)
        if sameCell then
            print(string.format("[PostArrivalCoordinator] SKIP %s (in native home cell)", tostring(npc.recordId)))
            return
        end
    end

    -- Priority 5: Displaced NPC (not in native cell) — start wander so they have
    -- baseline behavior. The local script uses savedWanderPackage if available,
    -- otherwise it falls back to a local ambient wander.
    print(string.format("[PostArrivalCoordinator] SEND PC_StartWander to %s", tostring(npc.recordId)))
    npc:sendEvent("PC_StartWander", {})
end

return PostArrivalCoordinator
