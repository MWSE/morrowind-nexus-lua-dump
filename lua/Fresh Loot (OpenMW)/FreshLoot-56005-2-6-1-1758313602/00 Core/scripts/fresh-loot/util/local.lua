local nearby = require("openmw.nearby")
local util = require("openmw.util")
local T = require("openmw.types")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mStats = require("scripts.fresh-loot.loot.stats")

local module = {}

local function castRay(from, to, actor)
    local result = nearby.castRay(from, to, {
        collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
        ignore = actor,
    })
    if not result.hit then
        return false, nil
    end
    return true, result.hitPos
end

module.trySeeDestination = function(actor, destination)
    local actorBox = actor:getBoundingBox()
    local target = destination + util.vector3(0, 0, actorBox.halfSize.z)
    local hit, hitPos = castRay(actorBox.center, target, actor)
    if not hit then
        return true
    end
    return (hitPos - actorBox.center):length() >= (target - actorBox.center):length()
end

local function getPath(actor, object, tolerance, includeFlags)
    local status, path = nearby.findPath(
            actor.position,
            object.position,
            {
                agentBounds = T.Actor.getPathfindingAgentBounds(actor),
                includeFlags = includeFlags,
            })
    if status == nearby.FIND_PATH_STATUS.PartialPath then
        if (object.position - path[#path]):length() > tolerance then
            return nil
        end
    elseif status ~= nearby.FIND_PATH_STATUS.Success then
        return nil
    end
    -- path is userdata, needs to convert it to a proper table to allow serialization
    local points = {}
    for _, point in ipairs(path) do
        table.insert(points, point)
    end
    return points
end
module.getPath = getPath

module.getTravelStats = function(actor, path)
    if #path == 1 then return 0 end
    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance, distance / T.Actor.getRunSpeed(actor)
end

local function getDoorsInPath(path)
    local doors = {}
    local lastDoor
    -- from each path point to the next one, check if there is a door, and if it's locked or trapped
    for i = 1, #path - 1 do
        local result = nearby.castRay(path[i], path[i + 1], { collisionType = nearby.COLLISION_TYPE.Door, ignore = lastDoor })
        local door = result.hitObject
        if door and door.type == T.Door and (path[i + 1] - path[i]):length() > (door.position - path[i]):length() then
            table.insert(doors, door)
            path[i] = door.position
            lastDoor = door
            i = i - 1
        else
            lastDoor = nil
        end
    end
    return doors
end

module.getDoorsBoosts = function(actor, container, allDoorStats)
    local doorsBoosts = {}
    -- is there a path without doors to the container?
    if getPath(actor, container, 0, nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim + nearby.NAVIGATOR_FLAGS.UsePathgrid) then
        return doorsBoosts
    end
    -- is there a path to the container, or close enough, ignoring doors
    local path = getPath(actor, container, mCfg.lootLevel.maxKeepersReachLootDistance)
    if not path then
        return doorsBoosts
    end

    for _, door in ipairs(getDoorsInPath(path)) do
        local boosts = allDoorStats[door.id]
        local hasBoosts = boosts
        if not hasBoosts then
            boosts, hasBoosts = mStats.getLockableLevelBoosts(door)
        end
        if hasBoosts then
            doorsBoosts[door.id] = boosts
        end
    end

    return doorsBoosts
end

return module