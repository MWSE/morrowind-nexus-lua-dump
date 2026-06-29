-- interactions/lectures/trace.lua
---@omw-context none
-- Focused trace tags for lecture lifecycle smoke testing.

local M = {}

function M.log(debugLog, tag, ...)
    if type(debugLog) ~= "function" then return end
    debugLog("lecture trace", tostring(tag or "event"), ...)
end

function M.ctx(ctx, tag, ...)
    if not ctx then return end
    M.log(ctx.debugLog, tag, ...)
end

return M
