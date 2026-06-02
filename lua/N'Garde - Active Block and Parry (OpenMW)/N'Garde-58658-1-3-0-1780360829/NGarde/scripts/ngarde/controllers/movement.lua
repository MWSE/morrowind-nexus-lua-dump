---@omw-context local
local util              = require('openmw.util')
local core              = require('openmw.core')
local targetRaycast     = require('scripts.ngarde.helpers.target_raycast')
local settingsConstants = require('scripts.ngarde.helpers.settings_constants')
local logging           = require('scripts.ngarde.helpers.logger').new()

local sin               = math.sin
local cos               = math.cos
local rad               = math.rad
local min               = math.min

local getGMST           = core.getGMST

MovementController      = {}


---@enum MEASURE
MovementController.MEASURE = {
    TooClose = 0,
    InMeasure = 1,
    WalkInDistance = 2,
    RunInDistance = 3,
}

MovementController.measureManagement = {
    [MovementController.MEASURE.TooClose] = function(possibleDirections, actor)
        actor.controls.run = false
        if possibleDirections.back.allowed then
            actor.controls.movement = -1
        else
            if possibleDirections.right.allowed then
                actor.controls.sideMovement = 1
            else
                if possibleDirections.left.allowed then
                    actor.controls.sideMovement = -1
                else
                    actor.controls.movement = 1
                end
            end
        end
    end,
    [MovementController.MEASURE.InMeasure] = function(_, _)
        return
    end,
    [MovementController.MEASURE.WalkInDistance] = function(_, actor)
        actor.controls.run = false
        return
    end,
    [MovementController.MEASURE.RunInDistance] = function(_, actor)
        return
    end,
}

MovementController.keepMeasureDistance = function(actorSelf, threatActor, parryController)
    if parryController.activeParryConfig then
        local measureDistance = parryController.recordEquippedR.reach * getGMST("fCombatDistance")
        local keep = MovementController.measureManagement
            [MovementController.isInMeasure(actorSelf, threatActor.position, measureDistance)]
        if keep then
            keep(MovementController.getAllowedDirections(actorSelf), actorSelf)
        end
    end
end

MovementController.getAllowedDirections = function(actorSelf)
    local moveDirections = {
        back = { name = "back", allowed = false, vector = nil, offset = util.vector3(0, -settingsConstants.obstacleDetectionRange, 0) },
        right = { name = "right", allowed = false, vector = nil, offset = util.vector3(settingsConstants.obstacleDetectionRange, 0, 0) },
        left = { name = "left", allowed = false, vector = nil, offset = util.vector3(-settingsConstants.obstacleDetectionRange, 0, 0) },
        forward = { name = "forward", allowed = false, vector = nil, offset = util.vector3(0, settingsConstants.obstacleDetectionRange, 0) },
    }
    for direction, directionData in pairs(moveDirections) do
        moveDirections[direction] = MovementController.processDirection(actorSelf, directionData)
    end
    return moveDirections
end

MovementController.isInMeasure = function(actorSelf, threatActorPosition, measureDistance)
    local inverseRotation = actorSelf.rotation:inverse()                                  -- converting to local frame of reference
    local relativePosition = inverseRotation * (threatActorPosition - actorSelf.position) -- relative position
    local currentDistSq = relativePosition.x ^ 2 + relativePosition.y ^ 2

    local halfSize = actorSelf:getBoundingBox().halfSize.y
    local maxMeasureDistance = measureDistance + halfSize
    local minMeasureDistance = measureDistance


    if currentDistSq >= maxMeasureDistance ^ 2 + halfSize ^ 2 then
        return MovementController.MEASURE.RunInDistance
    elseif currentDistSq >= maxMeasureDistance ^ 2 then
        return MovementController.MEASURE.WalkInDistance
    elseif currentDistSq < minMeasureDistance ^ 2 then
        return MovementController.MEASURE.TooClose
    else
        return MovementController.MEASURE.InMeasure
    end
end

MovementController.processDirection = function(actorSelf, direction)
    local flank = MovementController.getFlankingPosition(actorSelf, direction.offset)
    targetRaycast:setRayType("castRay")
    local vertOffset = util.vector3(0, 0, 10)
    local result = targetRaycast:castFromToTarget(actorSelf, actorSelf.position + vertOffset, flank + vertOffset)
    if not result.hit then
        local navMeshResult = targetRaycast:castNavigationRay(actorSelf.position, flank)
        if navMeshResult then
            direction.vector = result
            direction.allowed = true
        end
    end
    return direction
end

MovementController.getFlankingPosition = function(actor, offset)
    local worldOffset = actor.rotation * offset
    return actor.position + worldOffset
end

MovementController.getAllFlankingPositions = function(actorSelf, distance)
    local offsetRight   = util.vector3(distance, 0, 0)
    local offsetLeft    = util.vector3(-distance, 0, 0)
    local offsetBack    = util.vector3(0, -distance, 0)
    local offsetForward = util.vector3(0, distance, 0)

    local worldRight    = actorSelf.rotation * offsetRight
    local worldLeft     = actorSelf.rotation * offsetLeft
    local worldBack     = actorSelf.rotation * offsetBack
    local worldForward  = actorSelf.rotation * offsetForward

    return {
        right   = actorSelf.position + worldRight,
        left    = actorSelf.position + worldLeft,
        back    = actorSelf.position + worldBack,
        forward = actorSelf.position + worldForward,
    }
end

MovementController.processMoveSpeedPenalty = function(actorSelf, moveSpeedMultiplier)
    local movement = actorSelf.controls.movement
    local sideMovement = actorSelf.controls.sideMovement
    if movement ~= 0 then
        local absMove = min(math.abs(movement), moveSpeedMultiplier)
        if actorSelf.controls.movement < 0 then
            actorSelf.controls.movement = -absMove
        else
            actorSelf.controls.movement = absMove
        end
    end
    if sideMovement ~= 0 then
        local absSideMove = min(math.abs(sideMovement), moveSpeedMultiplier)
        if actorSelf.controls.sideMovement < 0 then
            actorSelf.controls.sideMovement = -absSideMove
        else
            actorSelf.controls.sideMovement = absSideMove
        end
    end
end

MovementController.allowedThreatDirection = function(actorSelf, threatActor, arc, offset, maxDistance)
    -- Directional Check (N deg Arc, skewed M deg Left)
    local maxDst = maxDistance or nil
    local inverseRotation = actorSelf.rotation:inverse()                         -- converting to local frame of reference
    local relPos = inverseRotation * (threatActor.position - actorSelf.position) -- relative position
    -- sqare of distance to avoid sqrt. we'll need it later. But calculating now to allow earlier out if distance is over max
    local distSq = relPos.x * relPos.x + relPos.y * relPos.y
    -- early out if max distance is specified (e.g. for threat reaction to a charge). If we are too far - no reason to check direction, just return false
    if maxDst then
        maxDst = (maxDst + actorSelf:getBoundingBox().halfSize.y + threatActor:getBoundingBox().halfSize.y) *
            1.1 -- good enough, I suppose
        -- logging:debug(maxDst)
        -- logging:debug(maxDst * maxDst)
        -- logging:debug(distSq)
        if (maxDst ^ 2) < distSq then --if current distance is bigger than max distance
            return false
        end
    end

    -- Apply N deg Left Skew to the facing
    -- cos(7deg) * relative Y - sin(7deg) * relative X
    -- substraction moves it left, addition will move it right
    local skewAngle = rad(offset)
    -- rotating relative position axis by offset degrees left
    local skewY = (cos(skewAngle) * relPos.y) - (sin(skewAngle) * relPos.x)

    -- Check N degree half-angle
    -- Condition: dot / distance(magnitude) > cos(theta)
    -- multiplying both sides by mag to simplify:
    -- dot > cos(theta) * mag
    -- squaring both sides to avoid square root in magnitude(distance)
    -- becomes dot^2 > cos^2 * mag^2
    local halfAngle = rad(arc / 2) -- taking half angle of the possible threat/parry arc. checking n/2 degrees in each direction from front facing axis:  "N/2<--|-->N/2"
    local halfAngleCosSquared = cos(halfAngle) * cos(halfAngle)
    -- skewY > 0 - only forward.
    -- actual condition - skewY^2 > (cos(N deg)^2 * distance squared)
    local isFrontHitWithinTheArc = (skewY > 0)               -- is in front
        and (skewY * skewY > (halfAngleCosSquared * distSq)) -- is within the arc
    return isFrontHitWithinTheArc
end

return MovementController
