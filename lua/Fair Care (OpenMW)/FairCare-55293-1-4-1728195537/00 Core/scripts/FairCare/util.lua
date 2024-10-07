local T = require('openmw.types')
local util = require("openmw.util")
local nearby = require('openmw.nearby')

local mSettings = require('scripts.FairCare.settings')

local module = {}

local itemTypes = {
    [T.Armor] = "Armor",
    [T.Book] = "Book",
    [T.Clothing] = "Clothing",
    [T.Potion] = "Potion",
    [T.Weapon] = "Weapon",
}
module.itemTypes = itemTypes

local function debugPrint(str)
    if mSettings.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end
module.debugPrint = debugPrint

local function getRecord(item)
    if item.type and item.type.record then
        return item.type.record(item)
    end
    return nil
end
module.getRecord = getRecord

local function isObjectDeleted(obj)
    return string.sub(tostring(obj), 1, 14) == "deleted object"
end
module.isObjectDeleted = isObjectDeleted

local function areObjectEquals(obj1, obj2)
    return (obj1 and obj1.id or "") == (obj2 and obj2.id or "")
end
module.areObjectEquals = areObjectEquals

local function getPath(actor, target)
    local status, path = nearby.findPath(actor.position, target.position, {
        agentBounds = T.Actor.getPathfindingAgentBounds(actor),
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
        destinationTolerance = 0,
    })
    if status ~= nearby.FIND_PATH_STATUS.Success or path == nil or #path == 0 then
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

local function getTravelTimeSec(actor, path)
    if #path == 1 then return 0 end

    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance / T.Actor.getRunSpeed(actor)
end
module.getTravelTimeSec = getTravelTimeSec

local function faceToPoint(controls, actor, targetPos)
    local pitch = actor.rotation:getPitch()
    if pitch ~= 0 then
        controls.pitchChange = -pitch
    else
        controls.pitchChange = 0.0
    end
    controls.sideMovement = 0
    local deltaPos = targetPos - (actor:getBoundingBox()).center
    local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(actor.rotation:getYaw())
    controls.yawChange = math.atan2(destVec.x, destVec.y)
end

local function travelToActor(controls, actor, path, target, pointDistanceTolerance, targetDistanceTolerance)
    if #path == 0 then
        controls.movement = 0
        return true
    end
    if #path == 1 then
        local targetBox = target:getBoundingBox()
        path[1] = targetBox.center - util.vector3(0, 0, targetBox.halfSize.z)
    end
    if (actor.position - path[#path]):length() < targetDistanceTolerance then
        faceToPoint(controls, actor, (target:getBoundingBox()).center)
        controls.movement = 0
        return true
    end
    if (actor.position - path[1]):length() < pointDistanceTolerance then
        table.remove(path, 1)
    end
    faceToPoint(controls, actor, path[1])
    controls.movement = 1
    return false
end
module.travelToActor = travelToActor

local function applyControls(controls, actor)
    actor.controls.run = controls.run
    actor.controls.jump = controls.jump
    actor.controls.sneak = controls.sneak
    actor.controls.movement = controls.movement
    actor.controls.sideMovement = controls.sideMovement
    actor.controls.yawChange = controls.yawChange
    actor.controls.pitchChange = controls.pitchChange
    actor.controls.use = controls.use
end
module.applyControls = applyControls

return module