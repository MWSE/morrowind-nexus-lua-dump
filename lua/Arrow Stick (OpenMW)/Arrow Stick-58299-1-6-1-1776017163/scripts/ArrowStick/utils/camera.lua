local util = require("openmw.util")
local camera = require("openmw.camera")
local nearby = require("openmw.nearby")

local camUtil = {}

camUtil.anglesToV = function(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end

camUtil.getRotation = function(rot, angle)
    local z, y, x = rot:getAnglesZYX()
    return { x = x, y = y, z = z }
end

camUtil.getCameraDirData = function(sourcePos, scatter)
    local pos = sourcePos
    local pitch, yaw

    pitch = -(camera.getPitch() + camera.getExtraPitch())
    yaw = (camera.getYaw() + camera.getExtraYaw())

    if scatter then
        pitch = pitch + math.random(-15, 15) / 1000
        yaw = yaw + math.random(-15, 15) / 1000
    end

    return pos, camUtil.anglesToV(pitch, yaw)
end

camUtil.getObjInCrosshairs = function(ignoredObj, mdist, alwaysPost, sourcePos, scatter)
    if not sourcePos then
        sourcePos = camera.getPosition()
    end
    local pos, v = camUtil.getCameraDirData(sourcePos, scatter)

    local dist = 8500
    if (mdist ~= nil) then dist = mdist end

    local destPos = (pos + v * dist)
    local ret = nearby.castRenderingRay(pos, destPos, { ignore = ignoredObj })
    local ret2 = nearby.castRay(pos, destPos, { ignore = ignoredObj })
    local ret3 = nearby.castRay(pos, destPos, { collisionType = nearby.COLLISION_TYPE.Water })

    return ret, ret2, ret3, destPos
end

camUtil.createRotation = function(x, y, z)
    local rotate = util.transform.rotateZ(z)
    local rotateX = util.transform.rotateX(x)
    local rotateY = util.transform.rotateY(y)
    ---@diagnostic disable-next-line: undefined-field
    rotate = rotate:__mul(rotateY)
    rotate = rotate:__mul(rotateX)

    return rotate
end

return camUtil
