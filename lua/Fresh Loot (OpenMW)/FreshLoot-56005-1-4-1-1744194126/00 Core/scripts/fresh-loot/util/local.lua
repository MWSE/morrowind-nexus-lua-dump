local nearby = require("openmw.nearby")
local T = require("openmw.types")

local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local requests = {
    data = {},
    counter = 0,
}

local function requestActorsStats(actors, requestEvent)
    requests.counter = requests.counter + 1
    for _, actor in pairs(actors) do
        actor:sendEvent(mDef.events.getActorStats, mTypes.new.requestEvent(
                mDef.events.returnActorStats,
                requestEvent.object,
                mTypes.new.actorStatsRequest(requests.counter, mHelpers.mapSize(actors), requestEvent)))
    end
end
module.requestActorsStats = requestActorsStats

local function gatherActorsStats(data)
    requests.data[data.requestId] = requests.data[data.requestId] or {}
    table.insert(requests.data[data.requestId], data.stats)
    if #requests.data[data.requestId] < data.requestCount then return end
    data.requestEvent.object:sendEvent(
            data.requestEvent.name,
            mTypes.new.actorsStatsResponse(
                    mHelpers.arraysToMap(requests.data[data.requestId], function(stats) return stats.actor.id end),
                    data.requestEvent.input))
    requests.data[data.requestId] = nil
end

local function castRay(from, to, actor, object)
    local result = nearby.castRay(from, to, {
        collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
        ignore = actor,
    })
    if not result.hit then
        return false, nil
    end
    if result.hitObject and result.hitObject.id == object.id then
        return true, result.hitPos
    end
    return false, result.hitPos
end

local function trySeeObject(actor, object)
    return castRay(actor:getBoundingBox().center, object:getBoundingBox().center, actor, object)
end
module.trySeeObject = trySeeObject

local function getPath(actor, object)
    local status, path = nearby.findPath(actor.position, object.position,
            { agentBounds = T.Actor.getPathfindingAgentBounds(actor) })
    if status == nearby.FIND_PATH_STATUS.PartialPath then
        if (object.position - path[#path]):length() > mCfg.lootLevel.maxKeepersClosestDistance then
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

local function getTravelStats(actor, path)
    if #path == 1 then return 0 end
    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance, distance / T.Actor.getRunSpeed(actor)
end
module.getTravelStats = getTravelStats

module.callbackEvents = {
    [mDef.events.returnActorStats] = gatherActorsStats
}

return module