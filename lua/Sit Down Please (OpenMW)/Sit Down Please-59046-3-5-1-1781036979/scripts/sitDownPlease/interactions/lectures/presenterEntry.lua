-- interactions/lectures/presenterEntry.lua
---@omw-context none
-- Smooth final station entry for lectern presenters after live pathing arrives.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local REQUEST_INTERVAL = 0.16
local MIN_STEP_DISTANCE = 10

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function yawFromRotation(rotation, fallback)
    local ok, yaw = pcall(function() return rotation and rotation:getYaw() end)
    if ok and type(yaw) == "number" then return yaw end
    return fallback or 0
end

local function smoothstep(t)
    t = clamp(t, 0, 1)
    return t * t * (3 - (2 * t))
end

local function distance(a, b)
    if not (a and b) then return 0 end
    local ok, value = pcall(function() return (a - b):length() end)
    if ok and value then return value end
    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    local dz = (tonumber(a.z) or 0) - (tonumber(b.z) or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.start(actor, data, now, util)
    if not (data and data.presenterEntrySmooth == true and actor and actor.position and data.finalPosition) then
        return nil
    end

    local startPos = actor.position
    local targetPos = data.finalPosition
    local stationType = lower(data.stationType)
    if stationType == "lectern" and util and util.vector3 and targetPos and startPos then
        local dz = math.abs((tonumber(targetPos.z) or 0) - (tonumber(startPos.z) or 0))
        if dz > 4 then
            -- Lectern presenter entry should slide across the floor into place.
            -- Interpolating the raw station Z can create a visible vertical pop
            -- when the lectern object origin differs from the floor.
            targetPos = util.vector3(targetPos.x or 0, targetPos.y or 0, startPos.z or 0)
        end
    end
    local dist = distance(startPos, targetPos)
    if dist <= 6 then return nil end

    local targetYaw = tonumber(data.finalRotation) or yawFromRotation(actor.rotation, 0)
    local startYaw = yawFromRotation(actor.rotation, targetYaw)
    local duration = clamp((dist / 130) + 0.22, 0.45, 1.35)
    return {
        active = true,
        startedAt = tonumber(now) or 0,
        elapsed = 0,
        requestTimer = 0,
        requestInterval = REQUEST_INTERVAL,
        minStepDistance = MIN_STEP_DISTANCE,
        startPosition = startPos,
        lastRequestedPosition = startPos,
        targetPosition = targetPos,
        startYaw = startYaw,
        targetYaw = targetYaw,
        duration = duration,
        distance = dist,
        objectId = data.objectId,
        slotKey = data.slotKey,
        smoothRequested = false,
    }
end

function M.active(state)
    return state and state.active == true
end

function M.step(state, dt, ctx)
    if not M.active(state) then return false, false end
    state.elapsed = (tonumber(state.elapsed) or 0) + (tonumber(dt) or 0)
    state.requestTimer = (tonumber(state.requestTimer) or 0) + (tonumber(dt) or 0)

    local rawProgress = clamp(state.elapsed / math.max(tonumber(state.duration) or 0.45, 0.01), 0, 1)
    local progress = smoothstep(rawProgress)
    local done = rawProgress >= 1

    if not state.smoothRequested and ctx and ctx.requestPose then
        state.smoothRequested = true
        state.lastRequestedPosition = state.targetPosition
        ctx.requestPose(state.targetPosition, state.targetYaw, "station_presenter_entry", {
            smoothDuration = state.duration,
        })
    end

    if done then
        -- Do not spam global teleport-style pose restores during entry.  The
        -- actor should path to the marker; this final request only settles yaw
        -- and sub-tile position once the entry interval completes.  Repeated
        -- intermediate station pose requests looked like visible teleport/jitter.
        state.requestTimer = 0
        local pos = state.targetPosition
        local yaw = state.targetYaw
        if ctx and ctx.requestPose then
            state.lastRequestedPosition = pos
            ctx.requestPose(pos, yaw, "station_presenter_entry_complete")
        end
    end

    if done then
        state.active = false
        return false, true
    end
    return true, false
end

return M
