-- interactions/sitting/lifecycle.lua
---@omw-context none
local M = {}

local MIN_GAME_HOURS = 4
local SPREAD_GAME_HOURS = 4
local MOVE_SEAT_CHANCE = 0.35

local function actorLabel(npc)
    return npc and (npc.recordId or npc.id) or "<npc>"
end

function M.gameHoursSince(a, b)
    if a == nil or b == nil then return nil end
    if b >= a then return b - a end
    return (b - a) % 24
end

local function intervalGameHours(profiles, npc, seed)
    local maxHours = MIN_GAME_HOURS + SPREAD_GAME_HOURS
    local key = tostring(actorLabel(npc)) .. "::sitlife::" .. tostring(seed or 0)
    return MIN_GAME_HOURS + ((maxHours - MIN_GAME_HOURS) * profiles.stableUnitInterval(key))
end

local function currentGameHours(profiles)
    if profiles and profiles.getGameTime then
        local gameTime = profiles.getGameTime()
        if gameTime then return gameTime / 3600 end
    end
    return profiles and profiles.getGameHour and profiles.getGameHour() or nil
end

function M.schedule(data, ctx, reason)
    if not (ctx and ctx.settings and ctx.settings.sittingLifecycleEnabled == true) then return end
    if not (data and data.interactionType == "sitting" and data.npc) then return end
    if data.calibrationAction == true then return end
    local profiles = ctx.profiles
    if not (profiles and profiles.stableUnitInterval) then return end

    data.sittingLifecycleGeneration = (data.sittingLifecycleGeneration or 0) + 1
    data.sittingLifecycleStartGameTimeHours = currentGameHours(profiles)
    data.sittingLifecycleStartGameHour = profiles.getGameHour and profiles.getGameHour() or nil
    data.sittingLifecycleIntervalGameHours = intervalGameHours(profiles, data.npc, data.sittingLifecycleGeneration)
    data.sittingLifecycleDeferredUntil = nil
    data.sittingLifecycleNextAt = nil
    if ctx.debugLog then
        ctx.debugLog("sitting lifecycle scheduled", actorLabel(data.npc), tostring(reason or "scheduled"), "gameHours", tostring(data.sittingLifecycleIntervalGameHours))
    end
end

function M.defer(data, ctx, seconds)
    if not (data and ctx and ctx.core and ctx.core.getSimulationTime) then return end
    data.sittingLifecycleDeferredUntil = ctx.core.getSimulationTime() + (tonumber(seconds) or 0)
end

function M.action(data, ctx)
    if not (ctx and ctx.settings and ctx.settings.sittingLifecycleEnabled == true) then return nil end
    if not (data and data.interactionType == "sitting" and data.state == ctx.interactingState) then return nil end
    if data.calibrationAction == true then return nil end
    if ctx.calibrationHoldActive and ctx.calibrationHoldActive(data) then
        M.defer(data, ctx, 30)
        return nil
    end

    local now = ctx.core and ctx.core.getSimulationTime and (ctx.core.getSimulationTime() or 0) or 0
    if data.sittingLifecycleDeferredUntil and now < data.sittingLifecycleDeferredUntil then return nil end
    data.sittingLifecycleDeferredUntil = nil

    local profiles = ctx.profiles
    local startHour = data.sittingLifecycleStartGameTimeHours
    local currentHour = currentGameHours(profiles)
    if not startHour then
        startHour = data.sittingLifecycleStartGameHour
        currentHour = profiles and profiles.getGameHour and profiles.getGameHour() or nil
    end
    local intervalHours = data.sittingLifecycleIntervalGameHours
    if not (profiles and profiles.stableUnitInterval and startHour and currentHour and intervalHours) then
        M.schedule(data, ctx, "missing_game_timer")
        return nil
    end

    local elapsedHours = M.gameHoursSince(startHour, currentHour)
    if not elapsedHours or elapsedHours < intervalHours then return nil end

    local key = tostring(actorLabel(data.npc)) .. "::sitlife-action::" .. tostring(data.sittingLifecycleGeneration or 0)
    if profiles.stableUnitInterval(key) < MOVE_SEAT_CHANCE then
        return "sitting_lifecycle_change_seat"
    end
    return "sitting_lifecycle_return_origin"
end

return M
