-- interactions/lectures/localRouteAssist.lua
---@omw-context none
-- NPC-local route-door assist state for station and lecture-audience paths.

local M = {}

local function actor(ctx)
    if ctx and type(ctx.actor) == "function" then return ctx.actor() end
    return ctx and ctx.actor or nil
end

local function doors(ctx)
    if ctx and type(ctx.doors) == "function" then return ctx.doors() end
    return ctx and ctx.doors or nil
end

local function now(ctx)
    if ctx and type(ctx.now) == "function" then return ctx.now() end
    return 0
end

local function debugLog(ctx, ...)
    if ctx and ctx.debugLog then ctx.debugLog(...) end
end

function M.create(ctx)
    ctx = ctx or {}
    local state = {
        path = nil,
        elapsed = 0,
        requested = {},
    }
    local controller = { state = state }

    function controller.setPath(path)
        state.path = path
        state.elapsed = 0
        state.requested = {}
    end

    function controller.clear()
        state.path = nil
        state.elapsed = 0
        state.requested = {}
    end

    function controller.path()
        return state.path
    end

    function controller.process(dt)
        local path = state.path
        local routeAssist = ctx.routeAssist
        local npc = actor(ctx)
        local nearbyDoors = doors(ctx)
        if not (path and path.finalPosition and routeAssist and nearbyDoors and ctx.sendGlobalEvent and npc) then return end
        state.elapsed = state.elapsed + (dt or 0)
        if state.elapsed < 0.45 then return end
        state.elapsed = 0

        local dest = path.approachPosition or path.finalPosition
        local actorPos = npc and npc.position or nil
        if not actorPos then return end
        if (actorPos - dest):length() <= 115 then
            controller.clear()
            return
        end
        if path.startedAt and now(ctx) - path.startedAt > 90 then
            debugLog(ctx, "station route assist expired", tostring(path.objectId), "slot", tostring(path.slotKey))
            controller.clear()
            return
        end

        local bestDoor, bestScore = nil, nil
        for _, door in ipairs(nearbyDoors) do
            local doorKey = tostring(door and (door.id or door.recordId) or "")
            local canOpen = false
            if doorKey ~= "" and not state.requested[doorKey] then
                canOpen = routeAssist.openability(door, npc, {
                    allowLockedDoorOverride = path.allowRouteDoorOverride == true,
                    debugLog = ctx.debugLog,
                    logPrefix = "station_route_door_assist",
                }) == true
            end
            if canOpen then
                local onRoute = routeAssist.doorOnRouteSegment(door, actorPos, dest, {
                    maxVertical = 160,
                    maxLineDistance = 165,
                    maxActorDistance = 900,
                    maxTargetDistance = 1000,
                })
                if onRoute then
                    local actorDist = (door.position - actorPos):length()
                    local targetDist = (door.position - dest):length()
                    local score = actorDist + targetDist * 0.15
                    if not bestScore or score < bestScore then
                        bestDoor, bestScore = door, score
                    end
                end
            end
        end

        if bestDoor then
            local doorKey = tostring(bestDoor.id or bestDoor.recordId or bestDoor)
            state.requested[doorKey] = true
            ctx.sendGlobalEvent("SitDownPleaseOpenStationRouteDoor", {
                npc = npc,
                door = bestDoor,
                destPosition = dest,
                reason = "station_route_assist",
                stationType = path.stationType,
                objectId = path.objectId,
                slotKey = path.slotKey,
                allowLockedDoorOverride = path.allowRouteDoorOverride == true,
            })
            debugLog(ctx, "station route door assist requested", tostring(bestDoor.recordId or bestDoor.id), "target", tostring(dest), "station", tostring(path.objectId))
        end
    end

    return controller
end

return M
