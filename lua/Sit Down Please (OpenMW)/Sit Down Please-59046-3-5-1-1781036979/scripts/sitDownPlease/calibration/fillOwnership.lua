---@omw-context none
local M = {}

function M.isAcceptedEvent(ev)
    return ev and (
        ev.calibrationFill == true
        or ev.calibrationTestNpc == true
        or ev.calibrationFillSource ~= nil
        or ev.calibrationFillLabel ~= nil
        or ev.calibrationFillSessionId ~= nil
    ) or false
end

return M
