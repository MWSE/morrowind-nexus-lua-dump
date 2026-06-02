-- Runtime-only global-to-local assignment handoff tracking.
-- Kept separate so interactionAssignment.lua stays below Lua's active-local
-- compile limit while preserving the Patch 5f retry/readiness behavior.

local core = require('openmw.core')

local M = {}

local ctx = {}
local pendingLocalResponses = {}
local readyNpcScripts = {}

local DEFAULT_MAX_ATTEMPTS = 4
local DEFAULT_TIMEOUT_SECONDS = 2.4
local MANUAL_MAX_ATTEMPTS = 8
local MANUAL_TIMEOUT_SECONDS = 6.0

function M.configure(newCtx)
    ctx = newCtx or {}
end

local function infoLog(...)
    if ctx.infoLog then ctx.infoLog(...) end
end

local function debugLog(...)
    if ctx.debugLog then ctx.debugLog(...) end
end

local function isObjValid(obj)
    return ctx.isObjValid and ctx.isObjValid(obj) or false
end

local function clearInitialHandoff(npcId)
    if ctx.clearInitialHandoff then ctx.clearInitialHandoff(npcId) end
end

local function settleInitialPlacementOverlay(reason, npcOrId)
    if ctx.settleInitialPlacementOverlay then ctx.settleInitialPlacementOverlay(reason, npcOrId) end
end

function M.reset()
    pendingLocalResponses = {}
    readyNpcScripts = {}
end

function M.track(npc, candidate, payload, now)
    if not (npc and npc.id) then return end
    pendingLocalResponses[npc.id] = {
        npc = npc,
        candidate = candidate,
        payload = payload,
        firstSentAt = now or core.getSimulationTime(),
        lastSentAt = now or core.getSimulationTime(),
        attempts = 1,
        lastLocalDecision = nil,
        lastLocalResultSent = nil,
    }
end

function M.releaseOnResult(npcId)
    if not npcId then return end
    local hadPending = pendingLocalResponses[npcId] ~= nil
    pendingLocalResponses[npcId] = nil
    return hadPending
end

function M.noteLocalTrace(data)
    if not (data and data.npcId) then return end
    local item = pendingLocalResponses[data.npcId]
    if not item then return end
    local stage = tostring(data.stage or "")
    local reason = tostring(data.reason or "")
    local summary = stage
    if reason ~= "" then summary = summary .. ":" .. reason end
    if stage == "sent" then
        item.lastLocalResultSent = summary
    else
        item.lastLocalDecision = summary
    end
end

function M.noteReady(data, settings)
    local npc = data and data.npc
    if not (npc and npc.id) then return end
    local previousReadyAt = readyNpcScripts[npc.id]
    readyNpcScripts[npc.id] = core.getSimulationTime()
    if settings and settings.debug == true and previousReadyAt == nil then
        debugLog("npc seeker ready", npc.recordId or npc.id, tostring(data and data.reason))
    end
end

local function releasePendingLocalResponse(npcId, reason)
    local item = npcId and pendingLocalResponses[npcId] or nil
    if not item then return end
    pendingLocalResponses[npcId] = nil
    clearInitialHandoff(npcId)

    local candidate = item.candidate
    if candidate and candidate.slotKey then
        if ctx.releaseOccupiedSlot then ctx.releaseOccupiedSlot(candidate.slotKey, npcId) end
        if candidate.interactionType == "sleeping" then
            if ctx.releaseSleepReservationBySlot then
                ctx.releaseSleepReservationBySlot(
                    candidate.slotKey,
                    reason or "local_response_timeout",
                    ctx.sleepReservationNpcId and ctx.sleepReservationNpcId(item.npc or npcId) or nil
                )
            end
            if candidate.initialPlacement == true and isObjValid(item.npc) and ctx.sleepLightControl then
                ctx.sleepLightControl.unregisterSleeper(item.npc, reason or "local_response_timeout", true)
                ctx.sleepLightControl.processPending(true)
            end
        end
        if ctx.clearRelevantObjectCache then ctx.clearRelevantObjectCache(reason or "local_response_timeout") end
    end
    settleInitialPlacementOverlay(reason or "pending_local_released", item.npc or npcId)
end

function M.process()
    local now = core.getSimulationTime()
    for npcId, item in pairs(pendingLocalResponses) do
        local npc = item and item.npc
        local candidate = item and item.candidate
        if not (item and isObjValid(npc) and candidate and candidate.object) then
            releasePendingLocalResponse(npcId, "pending_local_invalid")
        elseif ctx.assignedActorFor and ctx.assignedActorFor(npcId) then
            pendingLocalResponses[npcId] = nil
            clearInitialHandoff(npcId)
        else
            local age = now - (item.firstSentAt or now)
            local since = now - (item.lastSentAt or now)
            local manualAssign = candidate.manualAssign == true
            local maxAttempts = manualAssign and MANUAL_MAX_ATTEMPTS or DEFAULT_MAX_ATTEMPTS
            local timeoutSeconds = manualAssign and MANUAL_TIMEOUT_SECONDS or DEFAULT_TIMEOUT_SECONDS
            if (item.attempts or 1) < maxAttempts and since >= 0.45 then
                item.attempts = (item.attempts or 1) + 1
                item.lastSentAt = now
                npc:sendEvent("ConsiderInteractionObject", item.payload or {})
                infoLog(
                    "retrying local interaction handoff",
                    npc.recordId or npc.id,
                    "type", tostring(candidate.interactionType),
                    "object", tostring(candidate.objectId),
                    "slot", tostring(candidate.slotName),
                    "attempt", tostring(item.attempts),
                    "ready", tostring(readyNpcScripts[npcId] ~= nil),
                    "age", tostring(age)
                )
            elseif age >= timeoutSeconds then
                infoLog(
                    "local interaction handoff timed out",
                    npc.recordId or npc.id,
                    "type", tostring(candidate.interactionType),
                    "object", tostring(candidate.objectId),
                    "slot", tostring(candidate.slotName),
                    "attempts", tostring(item.attempts or 1),
                    "ready", tostring(readyNpcScripts[npcId] ~= nil),
                    "age", tostring(age)
                )
                if candidate.manualAssign == true then
                    infoLog(
                        "manual assignment handoff timeout diagnostics",
                        npc.recordId or npc.id,
                        "type", tostring(candidate.interactionType),
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName),
                        "lastLocalDecision", tostring(item.lastLocalDecision),
                        "lastLocalResultSent", tostring(item.lastLocalResultSent)
                    )
                    if ctx.onManualAssignTimeout then
                        ctx.onManualAssignTimeout(npc, candidate, "local_response_timeout")
                    end
                elseif candidate.interactionType == "sitting" then
                    infoLog(
                        "global sitting handoff timeout diagnostics",
                        npc.recordId or npc.id,
                        "type", tostring(candidate.interactionType),
                        "object", tostring(candidate.objectId),
                        "slot", tostring(candidate.slotName),
                        "lastLocalDecision", tostring(item.lastLocalDecision),
                        "lastLocalResultSent", tostring(item.lastLocalResultSent)
                    )
                end
                releasePendingLocalResponse(npcId, "local_response_timeout")
            end
        end
    end
end

return M
