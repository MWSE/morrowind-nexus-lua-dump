-- interactions/lectures/presenterApproach.lua
---@omw-context none
-- Computes a walkable approach point for presenters before the final station settle.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function flatLen(x, y)
    return math.sqrt((x or 0) * (x or 0) + (y or 0) * (y or 0))
end

local function flatUnitFromObjectToStation(obj, stationPos)
    if not (obj and obj.position and stationPos) then return nil, nil end
    local dx = (stationPos.x or 0) - (obj.position.x or 0)
    local dy = (stationPos.y or 0) - (obj.position.y or 0)
    local len = flatLen(dx, dy)
    if len <= 1 then return nil, nil end
    return dx / len, dy / len
end

local function numberOrHuge(value)
    local n = tonumber(value)
    if n == nil then return math.huge end
    return n
end

local function presenterSideProgress(obj, stationPos, actorPos)
    local ux, uy = flatUnitFromObjectToStation(obj, stationPos)
    if not ux then return nil end
    local ax = (actorPos.x or 0) - (stationPos.x or 0)
    local ay = (actorPos.y or 0) - (stationPos.y or 0)
    return (ax * ux) + (ay * uy)
end

function M.approachPosition(obj, profile, stationPos, util, options)
    if not (obj and obj.position and profile and stationPos and util and util.vector3) then return stationPos end
    if lower(profile.stationType) ~= "lectern" then return stationPos end
    local ux, uy = flatUnitFromObjectToStation(obj, stationPos)
    if not ux then return stationPos end
    local approachDistance = tonumber(options and options.distance) or 88
    -- Ask pathfinding to go slightly past the final presenter marker, on the same
    -- usable side of the lectern.  The actor then does a short controlled settle
    -- into the calibrated station spot instead of stopping at the side/front and
    -- being visibly snapped into place.
    return stationPos + util.vector3(ux * approachDistance, uy * approachDistance, 0)
end

function M.arrivalState(obj, stationPos, actorPos, distances, elapsed, options)
    options = options or {}
    local elapsedSeconds = tonumber(elapsed) or 0
    local stationDistance = numberOrHuge(distances and distances.station)
    local objectDistance = numberOrHuge(distances and distances.object)
    local approachDistance = numberOrHuge(distances and distances.approach)
    local markerRadius = tonumber(options.markerRadius) or 18
    local approachRadius = tonumber(options.approachRadius) or 96
    local settleRadius = tonumber(options.settleRadius) or 180
    local objectRadius = tonumber(options.objectRadius) or 160
    local stableSeconds = tonumber(options.stableSeconds) or 8
    local approachSlack = tonumber(options.approachSlack) or 48
    local usableSideSlack = tonumber(options.usableSideSlack) or 64
    local sideProgress = actorPos and presenterSideProgress(obj, stationPos, actorPos) or nil

    if stationDistance <= markerRadius and elapsedSeconds >= 0.35 then
        return true, "near_marker", sideProgress
    end
    if approachDistance <= approachRadius and elapsedSeconds >= 0.6 then
        return true, "near_approach", sideProgress
    end
    if elapsedSeconds >= 2.0
        and sideProgress ~= nil
        and sideProgress >= -8
        and stationDistance <= settleRadius
        and approachDistance <= (approachRadius + usableSideSlack) then
        return true, "usable_side_close", sideProgress
    end
    if elapsedSeconds >= stableSeconds
        and stationDistance <= settleRadius
        and (
            approachDistance <= (approachRadius + approachSlack)
            or objectDistance <= objectRadius
        ) then
        return true, "stable_close_path_stop", sideProgress
    end
    return false, "waiting", sideProgress
end

return M
