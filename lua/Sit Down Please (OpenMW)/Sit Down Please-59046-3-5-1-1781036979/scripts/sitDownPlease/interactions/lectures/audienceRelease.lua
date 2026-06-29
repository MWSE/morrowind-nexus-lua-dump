-- interactions/lectures/audienceRelease.lua
---@omw-context none
-- Hidden audience return helper. The global script owns queueing/wiring; this
-- module owns the policy for returning lecture audience actors to their origin.

local M = {}

local function label(npc)
    return npc and (npc.recordId or npc.id) or "<npc>"
end

local function afterWaitRelease(reason)
    local text = tostring(reason or "")
    return text == "station_duration_complete_after_wait"
        or text:find("after_wait", 1, true) ~= nil
end

function M.tryHiddenOriginReturn(ctx, npc, origin, rotation, reason)
    if not (ctx and npc and origin and ctx.tryTeleport) then return false, "missing_context" end
    if not (ctx.settings and ctx.settings.disguiseInitialPlacement == true) then return false, "overlay_disabled" end
    if not afterWaitRelease(reason) then return false, "visible_release" end

    local ok, err = ctx.tryTeleport(npc, npc.cell, origin, {
        rotation = rotation or npc.rotation,
        onGround = true,
    })
    if ok then
        if ctx.debugLog then
            ctx.debugLog(
                "audience hidden origin teleport",
                "actor", tostring(label(npc)),
                "origin", tostring(origin),
                "reason", tostring(reason or "lecture_ended")
            )
        end
        return true, "hidden_teleport"
    end
    if ctx.debugLog then
        ctx.debugLog(
            "audience hidden origin teleport failed",
            "actor", tostring(label(npc)),
            "origin", tostring(origin),
            "reason", tostring(reason or "lecture_ended"),
            "error", tostring(err)
        )
    end
    return false, err or "teleport_failed"
end

function M.shouldSuppressStandExitAfterHiddenReturn(data, reason)
    if not (data and data.lectureAudienceTarget == true) then return false end
    if data.lectureAudienceReturnMode ~= "origin_hidden_teleport" then return false end
    return afterWaitRelease(reason) or tostring(reason or "") == "sitting_lifecycle_return_origin"
end

return M
