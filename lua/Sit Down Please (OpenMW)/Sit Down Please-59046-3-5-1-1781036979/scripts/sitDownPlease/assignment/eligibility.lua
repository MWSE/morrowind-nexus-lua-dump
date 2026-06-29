-- assignment/eligibility.lua
---@omw-context none
-- Shared actor eligibility checks that must stay consistent between global
-- assignment, local seeker validation, and calibration/manual assignment.

local M = {}
local externalAnimationCompat = require('scripts/sitDownPlease/compatibility/externalAnimations')
local questSafety = require('scripts/sitDownPlease/compatibility/questSafety')

local function callActorPredicate(types, fnName, actor)
    local actorType = types and types.Actor or nil
    local fn = actorType and actorType[fnName] or nil
    if type(fn) ~= "function" or actor == nil then return false end
    local ok, result = pcall(fn, actor)
    return ok and result == true
end

local function actorCellName(npc, options)
    if npc == nil then return "" end
    local cell = npc.cell
    local cellNameFn = options and options.cellName or nil
    if cell and type(cellNameFn) == "function" then
        local ok, name = pcall(cellNameFn, cell)
        if ok and name ~= nil then return string.lower(tostring(name)) end
    end
    local ok, name = pcall(function()
        return cell and (cell.name or cell.id) or nil
    end)
    if ok and name ~= nil then return string.lower(tostring(name)) end
    return ""
end

local function bossCritoGeometryRisk(recordId, cellName)
    if recordId ~= "boss crito" and recordId ~= "boss_crito" then return false end
    if cellName == "arkngthand, hall of centrifuge" then return true end
    return cellName:find("arkngthand", 1, true) ~= nil and cellName:find("centrifuge", 1, true) ~= nil
end

function M.actorDeadReason(actor, types)
    if actor == nil then return false, nil end
    if callActorPredicate(types, "isDead", actor) then return true, "dead_actor" end
    if callActorPredicate(types, "isDeathFinished", actor) then return true, "dead_actor" end
    return false, nil
end

function M.slotOccupiedByTestNpc(occupiedSlots, assignedActors, slotKey)
    if not slotKey then return false, nil end
    local npcId = occupiedSlots and occupiedSlots[slotKey] or nil
    if not npcId then return false, nil end
    local data = assignedActors and assignedActors[npcId] or nil
    if data and (
        data.calibrationTestNpc == true
        or data.calibrationFill == true
        or data.calibrationFillSource ~= nil
        or data.calibrationFillLabel ~= nil
        or data.calibrationFillSessionId ~= nil
    ) then return true, data end
    return false, data
end

function M.hiddenOrStagedNpcReason(npc, options)
    local recordId = npc and npc.recordId and string.lower(tostring(npc.recordId)) or ""
    if recordId == "" then return nil end
    local questReason = questSafety.questActorReason(npc, options and options.types, options and options.player)
    if questReason then return questReason end
    local cellName = actorCellName(npc, options)
    if bossCritoGeometryRisk(recordId, cellName) then
        return "quest_combat_geometry_risk"
    end
    if recordId == "q_dras" and cellName == "balmora, hlaalu council manor" then
        return "modded_q_dras_hlaalu_council_manor_guard"
    end
    if recordId:find("roht_mg_balmora_guard", 1, true) or recordId:find("roht_balmora_guard", 1, true) then
        return "hidden_or_staged_actor"
    end
    if recordId:find("_invisible", 1, true) or recordId:find("hidden", 1, true) then
        return "hidden_or_staged_actor"
    end
    return nil
end

function M.sendWakeCleanupProbe(npc, reason, source, assignedActors, isObjValid, debugLog)
    if not (npc and npc.id) then return false end
    if type(isObjValid) == "function" and not isObjValid(npc) then return false end
    if assignedActors and assignedActors[npc.id] then return false end
    local externalReason = externalAnimationCompat.externalAnimationNpcReason(npc)
    if externalReason then
        if type(debugLog) == "function" then
            debugLog("wake cleanup probe skipped", npc.recordId or npc.id, "reason", tostring(externalReason), "source", tostring(source))
        end
        return false
    end
    local text = tostring(reason or "")
    if text ~= "sleep_after_actor_wake_time" and text ~= "outside_allowed_time_window" and text ~= "sleep_before_start_hour" then
        return false
    end
    npc:sendEvent('StopInteractionObject', {
        reason = "unassigned_wake_cleanup_probe_" .. text,
        interactionType = "sleeping",
        forceClearSleepAnimation = true,
        wakeCleanupOnly = true,
    })
    if type(debugLog) == "function" then
        debugLog("wake cleanup probe sent", npc.recordId or npc.id, "reason", text, "source", tostring(source))
    end
    return true
end

function M.sendStaleSleepCleanupProbe(npc, reason, source, assignedActors, isObjValid, debugLog)
    if not (npc and npc.id) then return false end
    if type(isObjValid) == "function" and not isObjValid(npc) then return false end
    if assignedActors and assignedActors[npc.id] then return false end
    local externalReason = externalAnimationCompat.externalAnimationNpcReason(npc)
    if externalReason then
        if type(debugLog) == "function" then
            debugLog("stale sleep cleanup probe skipped", npc.recordId or npc.id, "reason", tostring(externalReason), "source", tostring(source))
        end
        return false
    end
    local scanSource = tostring(source or "")
    if scanSource ~= "initial_load" and scanSource ~= "cell_change" and scanSource ~= "cell_change_event" and scanSource ~= "settings" then
        return false
    end
    npc:sendEvent('StopInteractionObject', {
        reason = "unassigned_stale_sleep_cleanup_probe_" .. tostring(reason or "ineligible"),
        interactionType = "sleeping",
        forceClearSleepAnimation = true,
        wakeCleanupOnly = true,
    })
    if type(debugLog) == "function" then
        debugLog("stale sleep cleanup probe sent", npc.recordId or npc.id, "reason", tostring(reason), "source", scanSource)
    end
    return true
end

return M
