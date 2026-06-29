-- interactions/sleeping/routeStartTravel.lua
---@omw-context none
-- Chooses the first travel package for accepted sleep routes.

local M = {}

function M.packageForAcceptedSleep(ev, data)
    local dest = ev and (ev.approachPos or ev.hitPos) or nil
    local tolerance = nil
    local usedDoorStage = false

    if ev
        and data
        and ev.interactionType == "sleeping"
        and data.sleepRouteNeedsDoorAssist == true
        and data.sleepRouteStartPosition then
        dest = data.sleepRouteStartPosition
        tolerance = 24
        usedDoorStage = true
    end

    return {
        type = "Travel",
        destPosition = dest,
        isRepeat = false,
        cancelOther = ev and ev.manualAssignOverrideTesting == true or false,
        destinationTolerance = tolerance,
        usedDoorStage = usedDoorStage,
    }
end

return M
