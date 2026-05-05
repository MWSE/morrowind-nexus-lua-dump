local self = require('openmw.self')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local core = require('openmw.core')

local collisionMask = nearby.COLLISION_TYPE.Default - nearby.COLLISION_TYPE.Actor
local collisionEpsilon = 0.25
local slideIterations = 4
local maxCollisionSubsteps = 320
local collisionStepScale = 1.0

local function vectorLength(vector)
    return math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

local function normalizeVector(vector)
    local length = vectorLength(vector)
    if length <= 0.001 then
        return util.vector3(0, 0, 0)
    end
    return vector / length
end

local function getMaxCollisionStep()
    return math.max(collisionEpsilon * collisionStepScale, 0.001)
end

local function castCollision(startPos, targetPos, radius)
    local hit = nearby.castRay(startPos, targetPos, {
        radius = radius,
        collisionType = collisionMask,
    })
    if hit and hit.hit then
        return hit
    end
end

local function slideMoveStep(pos, velocity, dt, radius)
    local resolvedVelocity = velocity
    local remainingTime = dt

    for _ = 1, slideIterations do
        if remainingTime <= 0 then
            break
        end
        if vectorLength(resolvedVelocity) <= 0.001 then
            resolvedVelocity = util.vector3(0, 0, 0)
            break
        end

        local step = resolvedVelocity * remainingTime
        local stepLength = vectorLength(step)
        if stepLength <= 0.001 then
            break
        end

        local target = pos + step
        local hit = castCollision(pos, target, radius)

        if not hit or not hit.hit or not hit.hitPos then
            pos = target
            break
        end

        local hitOffset = hit.hitPos - pos
        local hitDistance = math.min(vectorLength(hitOffset), stepLength)
        local moveDistance = math.max(hitDistance - collisionEpsilon, 0.0)
        if moveDistance > 0 then
            pos = pos + normalizeVector(step) * moveDistance
        end

        local timeToHit = remainingTime * (hitDistance / stepLength)
        remainingTime = math.max(remainingTime - timeToHit, 0)

        local hitNormal = hit.hitNormal
        if not hitNormal then
            resolvedVelocity = util.vector3(0, 0, 0)
            break
        end

        local towardSurface = resolvedVelocity:dot(hitNormal)
        if towardSurface < 0 then
            resolvedVelocity = resolvedVelocity - hitNormal * towardSurface
        end

        pos = pos + hitNormal * collisionEpsilon
    end

    return pos, resolvedVelocity
end

local function fullSlideMove(startPos, moveVector, radius)
    local speed = vectorLength(moveVector)
    if speed <= 0.001 then
        return moveVector
    end

    local maxCollisionStep = getMaxCollisionStep()
    local totalDistance = speed
    local maxResolvableDistance = maxCollisionStep * maxCollisionSubsteps
    if totalDistance > maxResolvableDistance then
        moveVector = moveVector * (maxResolvableDistance / totalDistance)
        speed = vectorLength(moveVector)
        totalDistance = speed
    end

    local substeps = math.max(1, math.min(maxCollisionSubsteps, math.ceil(totalDistance / maxCollisionStep)))
    local stepDt = 1 / substeps
    local pos = startPos
    local resolvedVelocity = moveVector

    for _ = 1, substeps do
        pos, resolvedVelocity = slideMoveStep(pos, resolvedVelocity, stepDt, radius)
        if vectorLength(resolvedVelocity) <= 0.001 then
            resolvedVelocity = util.vector3(0, 0, 0)
            break
        end
    end

    return pos - startPos
end

local function doCollisionCheck(data)
    local moveZ = data.speed * data.dt
    local moveVector = util.vector3(0, 0, moveZ)
    local bbox = self:getBoundingBox()
    local center = util.vector3(bbox.center.x, bbox.center.y, bbox.center.z)
    local sweepRadius = math.max(math.min(bbox.halfSize.x, bbox.halfSize.y), 4)
    local newVector = fullSlideMove(center, moveVector, sweepRadius)

    core.sendGlobalEvent("TelRaloran_LevPadCollisionCheckResult", { vector = newVector, dt = data.dt })
end

return {
    eventHandlers = {
        TelRaloran_LevPadCollisionCheck = doCollisionCheck
    }
}