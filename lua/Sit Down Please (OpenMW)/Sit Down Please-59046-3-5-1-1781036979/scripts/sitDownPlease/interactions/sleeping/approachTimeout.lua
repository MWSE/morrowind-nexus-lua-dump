-- Sleep-route timeout policy for actors walking to a bed.
---@omw-context none

local M = {}

local DEFAULT_SLEEP_APPROACH_MAX_SECONDS = 24
local DEFAULT_SLEEP_STUCK_REROUTE_SECONDS = 10
local DEFAULT_SLEEP_DOOR_STUCK_REROUTE_SECONDS = 9

local function numeric(value)
    local n = tonumber(value)
    if n ~= nil then return n end
    return nil
end

function M.reason(data)
    if not data or data.interactionType ~= "sleeping" then return nil end
    if data.manualAssignOverrideTesting == true or data.calibrationAction == true then return nil end
    if data.reachedValidSleepApproach == true then return nil end

    local profile = data.profile or {}
    local maxSeconds = numeric(profile.sleepApproachMaxSeconds)
        or numeric(profile.sleepRouteMaxSeconds)
        or numeric(profile.approachSleepHardTimeout)
        or DEFAULT_SLEEP_APPROACH_MAX_SECONDS

    local stuckSeconds = numeric(profile.sleepStuckRerouteSeconds)
        or numeric(profile.sleepRouteStuckSeconds)
        or DEFAULT_SLEEP_STUCK_REROUTE_SECONDS
    if data.sleepRouteNeedsDoorAssist == true then
        stuckSeconds = numeric(profile.sleepDoorStuckRerouteSeconds)
            or numeric(profile.sleepRouteDoorStuckSeconds)
            or math.min(stuckSeconds, DEFAULT_SLEEP_DOOR_STUCK_REROUTE_SECONDS)
    end
    if stuckSeconds > 0 and (tonumber(data.approachStuckElapsed) or 0) >= stuckSeconds then
        return "sleep_route_incomplete", stuckSeconds
    end

    if (tonumber(data.approachElapsed) or 0) >= maxSeconds then
        return "sleep_route_incomplete", maxSeconds
    end

    return nil
end

return M
