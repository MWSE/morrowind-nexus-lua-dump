-- Local-script helper for ProceduralChatter-owned targeted Travel packages.
-- It deliberately avoids jump arcs, levitation, fatigue changes, water logic,
-- and Wander packages. It only asks the global script for tiny, validated
-- same-cell nudges when an owned Travel target stops making progress.

local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")

local TargetedTravelUnstuck = {}

local function cfg(name, fallback)
    local value = ScheduleConfig and ScheduleConfig[name]
    if value == nil then return fallback end
    return value
end

local function safeLength(vec)
    if not vec then return math.huge end
    local ok, len = pcall(function() return vec:length() end)
    return ok and len or math.huge
end

local function copyVec(pos)
    if not pos then return nil end
    return util.vector3(pos.x, pos.y, pos.z)
end

local function normalize2d(vec)
    if not vec then return nil end
    local x, y = vec.x or 0, vec.y or 0
    local len = math.sqrt(x * x + y * y)
    if len <= 0.001 then return nil end
    return util.vector3(x / len, y / len, 0)
end

local function actorIsSwimming(actor)
    if not (types and types.Actor and types.Actor.isSwimming) then return false end
    local ok, swimming = pcall(types.Actor.isSwimming, actor)
    return ok and swimming == true
end

local function actorCanMove(actor)
    if not (types and types.Actor and types.Actor.canMove) then return true end
    local ok, canMove = pcall(types.Actor.canMove, actor)
    return not ok or canMove == true
end

local function activePackageIsTravel(ai)
    if not (ai and ai.getActivePackage) then return false end
    local ok, pkg = pcall(ai.getActivePackage)
    return ok and pkg and pkg.type == "Travel"
end

local function rayClear(fromPos, toPos, actor)
    if not (fromPos and toPos and nearby and nearby.castRay) then return false end
    local collisionType = nearby.COLLISION_TYPE.Default or 0
    if nearby.COLLISION_TYPE.VisualOnly then
        collisionType = collisionType + nearby.COLLISION_TYPE.VisualOnly
    end
    local ok, result = pcall(nearby.castRay, fromPos, toPos, {
        collisionType = collisionType,
        ignore = actor,
    })
    return ok and not (result and result.hit)
end

local function snapToNavmesh(pos)
    if not (pos and nearby and nearby.findNearestNavMeshPosition) then return pos end
    local ok, navPos = pcall(nearby.findNearestNavMeshPosition, pos, {
        searchAreaHalfExtents = util.vector3(80, 80, 80),
    })
    if ok and navPos and safeLength(navPos - pos) <= 75 then
        return navPos
    end
    return pos
end

local function hasGround(pos, actor)
    local fromPos = pos + util.vector3(0, 0, 40)
    local toPos = pos - util.vector3(0, 0, 90)
    local ok, result = pcall(nearby.castRay, fromPos, toPos, {
        collisionType = nearby.COLLISION_TYPE.World,
        ignore = actor,
    })
    return ok and result and result.hit == true
end

local function buildOffsets(actor, target, distance)
    local yaw = 0
    pcall(function() yaw = actor.rotation:getYaw() end)
    local actorTransform = util.transform.move(actor.position) * util.transform.rotateZ(yaw)
    local toTarget = normalize2d(target - actor.position)
    local offsets = {
        util.vector3(0, distance, 0),
        util.vector3(distance, 0, 0),
        util.vector3(-distance, 0, 0),
        util.vector3(distance * 0.7, -distance * 0.7, 0),
        util.vector3(-distance * 0.7, -distance * 0.7, 0),
    }

    local candidates = {}
    if toTarget then
        candidates[#candidates + 1] = actor.position + toTarget * distance
        local right = util.vector3(toTarget.y, -toTarget.x, 0)
        candidates[#candidates + 1] = actor.position + right * distance
        candidates[#candidates + 1] = actor.position - right * distance
    end
    for _, offset in ipairs(offsets) do
        candidates[#candidates + 1] = actorTransform * offset
    end
    return candidates
end

local function findNudgePosition(actor, target, distance)
    local fromHead = actor.position + util.vector3(0, 0, 60)
    for _, candidate in ipairs(buildOffsets(actor, target, distance)) do
        local snapped = snapToNavmesh(candidate)
        local toHead = snapped + util.vector3(0, 0, 60)
        if rayClear(fromHead, toHead, actor) and hasGround(snapped, actor) then
            return snapped
        end
    end
    return nil
end

function TargetedTravelUnstuck.create(ctx)
    local actor = ctx.actor
    local ai = ctx.ai
    local dbg = ctx.debug or function() end
    local state = nil

    local function clear()
        state = nil
    end

    local function register(target, opts)
        if cfg("TARGETED_TRAVEL_UNSTUCK_ENABLED", true) == false then return end
        if not target then return end
        opts = opts or {}
        local dist = safeLength(actor.position - target)
        state = {
            target = copyVec(target),
            label = opts.label or "travel",
            stopDist = opts.stopDist or 50,
            sampleTimer = 0,
            stuckTimer = 0,
            nudgeCooldown = 0,
            nudges = 0,
            bestDist = dist,
            lastPos = copyVec(actor.position),
            pendingRequest = nil,
        }
        dbg("NPC %s targeted travel watchdog armed label=%s target=%s", actor.recordId, state.label, tostring(state.target))
    end

    local function restartTravel()
        if not (state and state.target and ai and ai.startPackage) then return end
        pcall(function() ai.removePackages("Travel") end)
        pcall(function()
            ai.startPackage({ type = "Travel", destPosition = state.target })
        end)
    end

    local function onNudgeResult(data)
        if not (state and data) then return end
        if data.requestId ~= state.pendingRequest then return end
        state.pendingRequest = nil
        state.nudgeCooldown = cfg("TARGETED_TRAVEL_NUDGE_COOLDOWN", 1.5)
        state.sampleTimer = 0
        state.stuckTimer = 0
        state.bestDist = safeLength(actor.position - state.target)
        state.lastPos = copyVec(actor.position)
        if data.ok then
            dbg("NPC %s targeted travel nudge applied label=%s", actor.recordId, state.label)
            restartTravel()
        else
            dbg("NPC %s targeted travel nudge failed label=%s reason=%s", actor.recordId, state.label, tostring(data.reason))
        end
    end

    local function update(dt)
        if not state then return end
        if cfg("TARGETED_TRAVEL_UNSTUCK_ENABLED", true) == false then
            clear()
            return
        end
        if state.pendingRequest then return end
        if actorIsSwimming(actor) or not actorCanMove(actor) then
            state.stuckTimer = 0
            state.lastPos = copyVec(actor.position)
            return
        end
        if not activePackageIsTravel(ai) then
            clear()
            return
        end

        state.nudgeCooldown = math.max(0, (state.nudgeCooldown or 0) - dt)
        state.sampleTimer = (state.sampleTimer or 0) + dt
        local interval = cfg("STUCK_CHECK_INTERVAL", 0.5)
        if state.sampleTimer < interval then return end
        state.sampleTimer = 0

        local dist = safeLength(actor.position - state.target)
        if dist <= (state.stopDist or 50) then
            clear()
            return
        end

        local progressEpsilon = cfg("STUCK_MOVE_THRESHOLD", 30)
        local moved = state.lastPos and safeLength(actor.position - state.lastPos) or math.huge
        local improved = (state.bestDist - dist) >= progressEpsilon
        if improved then
            state.bestDist = dist
            state.stuckTimer = 0
        elseif moved < progressEpsilon then
            state.stuckTimer = (state.stuckTimer or 0) + interval
        else
            state.stuckTimer = math.max(0, (state.stuckTimer or 0) - interval)
        end
        state.lastPos = copyVec(actor.position)

        if state.stuckTimer < cfg("STUCK_WINDOW", 5.0) then return end
        if state.nudgeCooldown > 0 then return end
        if state.nudges >= cfg("TARGETED_TRAVEL_MAX_NUDGES", 3) then return end

        local nudgePos = findNudgePosition(actor, state.target, cfg("TARGETED_TRAVEL_NUDGE_DISTANCE", 35))
        if not nudgePos then
            state.nudgeCooldown = cfg("TARGETED_TRAVEL_NUDGE_COOLDOWN", 1.5)
            state.stuckTimer = 0
            return
        end

        state.nudges = state.nudges + 1
        state.pendingRequest = string.format("%s:%d", actor.id, state.nudges)
        core.sendGlobalEvent("PC_TargetedTravelNudge", {
            actor = actor,
            npcId = actor.id,
            requestId = state.pendingRequest,
            position = nudgePos,
            target = state.target,
            label = state.label,
        })
    end

    return {
        register = register,
        clear = clear,
        update = update,
        onNudgeResult = onNudgeResult,
    }
end

return TargetedTravelUnstuck
