-- interactions/sitting/localRejectRetry.lua
---@omw-context none
-- Retry normal sitting against another slot after a local safety rejection.

local cooldowns = require('scripts/sitDownPlease/interactions/sitting/cooldowns')

local M = {}

local function settingsFrom(ctx)
    if ctx and type(ctx.settings) == "function" then return ctx.settings() end
    return ctx and ctx.settings or {}
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

local function isToolOrLectureResult(ev)
    return ev.manualAssign == true
        or ev.calibrationFill == true
        or ev.calibrationTestNpc == true
        or ev.calibrationFillSource ~= nil
        or ev.calibrationFillLabel ~= nil
        or ev.lectureAudienceTarget == true
end

function M.retry(ctx, ev)
    if not (ctx and ev and ev.interactionType == "sitting" and ev.npc and ev.npc.cell and ev.slotKey) then return false end
    if isToolOrLectureResult(ev) then return false end
    if cooldowns.isRetryableLocalReject(ev.reason) ~= true then return false end
    if not (ctx.buildCandidateSlots and ctx.chooseCandidateForNpc and ctx.sendConsiderInteraction and ctx.setLocalRejectCooldown) then return false end

    local opts = settingsFrom(ctx)
    ctx.setLocalRejectCooldown(
        ev.npc,
        ev.slotKey,
        opts.sittingLocalRejectRetryCooldownSeconds or 75,
        ev.reason
    )

    local candidates = ctx.buildCandidateSlots(ev.npc.cell, "sitting")
    local candidate = ctx.chooseCandidateForNpc(ev.npc, candidates, "sitting", { avoidSlotKey = ev.slotKey })
    if not candidate then
        debugLog(
            ctx,
            "sitting local rejection alternate unavailable",
            ev.npc.recordId or ev.npc.id,
            "fromObject", tostring(ev.objectId),
            "slot", tostring(ev.slotName),
            "reason", tostring(ev.reason)
        )
        return false
    end

    if ev.initialPlacement == true then
        if ctx.shallowCopy then candidate = ctx.shallowCopy(candidate) end
        candidate.initialPlacement = true
        candidate.suppressInitialPlacementOverlay = ev.suppressInitialPlacementOverlay == true
    end

    local sentOk, sentReason = ctx.sendConsiderInteraction(ev.npc, candidate)
    if sentOk then
        debugLog(
            ctx,
            "sitting local rejection alternate",
            ev.npc.recordId or ev.npc.id,
            "fromObject", tostring(ev.objectId),
            "toObject", tostring(candidate.objectId),
            "slot", tostring(candidate.slotName),
            "reason", tostring(ev.reason)
        )
        return true
    end

    debugLog(
        ctx,
        "sitting local rejection alternate not sent",
        ev.npc.recordId or ev.npc.id,
        "fromObject", tostring(ev.objectId),
        "toObject", tostring(candidate.objectId),
        "slot", tostring(candidate.slotName),
        "reason", tostring(sentReason)
    )
    return false
end

return M
