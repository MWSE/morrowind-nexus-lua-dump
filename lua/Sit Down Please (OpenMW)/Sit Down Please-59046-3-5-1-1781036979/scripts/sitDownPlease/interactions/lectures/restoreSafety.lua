-- interactions/lectures/restoreSafety.lua
---@omw-context none
-- Hard-yield checks for restoring persisted lecture sessions after load.

local M = {}

local function callReason(fn, npc)
    if type(fn) ~= "function" then return nil end
    local ok, reason = pcall(fn, npc)
    if ok and reason then return reason end
    return nil
end

function M.actorYieldReason(ctx, npc)
    if not npc then return "missing_presenter" end
    if ctx and ctx.actorDeadReason then
        local dead, reason = ctx.actorDeadReason(npc)
        if dead then return reason or "dead_actor" end
    end

    local followerReason = callReason(ctx and ctx.followerBlockReason, npc)
    if followerReason then return followerReason end

    local incapacitationReason = callReason(ctx and ctx.externalIncapacitationReason, npc)
    if incapacitationReason then return incapacitationReason end

    local controlScriptReason = callReason(ctx and ctx.externalControlScriptReason, npc)
    if controlScriptReason then return controlScriptReason end

    local stanceReason = callReason(ctx and ctx.activeNonIdleStanceReason, npc)
    if stanceReason then return stanceReason end

    local animationReason = callReason(ctx and ctx.externalAnimationNpcReason, npc)
    if animationReason then return animationReason end

    return nil
end

M.presenterYieldReason = M.actorYieldReason

return M
