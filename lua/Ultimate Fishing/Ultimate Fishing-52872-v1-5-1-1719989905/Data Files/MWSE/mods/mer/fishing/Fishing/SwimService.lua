---Class for controlling the ripples of a fish moving towards a lure
---@class Fishing.SwimService
local SwimService = {}

local common = require("mer.fishing.common")
local logger = common.createLogger("SwimService")
local config = require("mer.fishing.config")
local RippleGenerator = require("mer.fishing.Fishing.RippleGenerator")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")

function SwimService.deepEnough(location)
    local ray = tes3.rayTest{
        position = location,
        direction = tes3vector3.new(0,0,-1),
        maxDistance = config.constants.MIN_DEPTH,
        ignore = FishingStateManager.getIgnoreRefs(),
    }
    if ray then
        logger:debug("Depth %s too shallow. Hit: %s", ray.distance, ray.reference)
        return false
    end
    return true
end

local function hasLineOfSight(startPosition, targetPosition)
    local direction = (targetPosition - startPosition):normalized()
    local maxDistance = startPosition:distance(targetPosition)
    logger:trace([[
        Class: SwimService
        Method: hasLineOfSight
        Params:
            startPosition: %s
            targetPosition: %s
            direction: %s
            maxDistance: %s
    ]], startPosition, targetPosition, direction, maxDistance)

    local ray = tes3.rayTest{
        position = startPosition,
        direction = direction,
        maxDistance = maxDistance,
        ignore = FishingStateManager.getIgnoreRefs()
    }
    if ray then
        logger:debug("Line of sight blocked by %s", ray.object)
        return false
    end
    return true
end

---Given a position, try and find a valid new position at a given distance in a given direction
---To be valid it has to be in the water and in the line of sight of the player
---@param startPosition tes3vector3 The position to start looking from
---@param direction tes3vector3 The direction to look in
---@param distance number The distance to look
---@return tes3vector3|nil # The position if unimpeded, nil if something blocked its path
local function findNewPosition(startPosition, direction, distance)
    local ignoreList = FishingStateManager.getIgnoreRefs()
    local ray = tes3.rayTest{
        position = startPosition,
        direction = direction,
        maxDistance = distance + config.constants.WATER_POSITION_PADDING,
        --useBackTriangles = true,
        ignore = ignoreList,
    }
    local hitSomething = ray ~= nil
    if not hitSomething then
        local targetPosition = startPosition + (direction * distance)
        --local rodEnd = FishingRod.getPoleEndPosition()

        local rodEnd = tes3.getPlayerEyePosition()
        if rodEnd and not hasLineOfSight(targetPosition, rodEnd) then
            logger:debug("Line of sight to rod is blocked")
            return nil
        end

        if not SwimService.deepEnough(targetPosition) then
            logger:debug("Too shallow")
            return nil
        end
        return startPosition + (direction * distance)
    else
        logger:debug("Hit something: %s", ray and ray.reference)
        return nil
    end
end


local m1 = tes3matrix33.new()

---@class SwimService.findTargetPosition.params
---@field origin tes3vector3 where to start looking from
---@field minDistance number minimum distance to look. Defaults to config.constants.FISH_POSITION_DISTANCE_MIN
---@field maxDistance number maximum distance to look. Defaults to config.constants.FISH_POSITION_DISTANCE_MAX
---@field ignoreList? table<tes3reference, boolean> references to ignore when raycasting

---Given a position, try and find a position in a random direction
---that is unimpeded
---@param e SwimService.findTargetPosition.params
function SwimService.findTargetPosition(e)
    local origin = e.origin
    local ABSOLUTE_MIN = 100
    local minDistance = math.max(ABSOLUTE_MIN, e.minDistance)
    local maxDistance = math.remap(math.random(), 0, 1, e.minDistance, e.maxDistance)
    maxDistance = math.max(ABSOLUTE_MIN, maxDistance)

    logger:debug("Target position: %s", origin)
    logger:debug("Finding start position")
    for i=1, config.constants.FISH_POSITION_ATTEMPTS do
        --Every failed attempts, reduce the distance

        local distanceReductionPerAttempt = (maxDistance - minDistance) / config.constants.FISH_POSITION_ATTEMPTS
        local min = math.max(ABSOLUTE_MIN, minDistance - (distanceReductionPerAttempt * i))
        local max = math.max(ABSOLUTE_MIN, maxDistance - (distanceReductionPerAttempt * i))
        local distance = math.random(min, max)

        logger:trace("Distance: %s", distance)
        local zDir = math.random(0, 360)
        --use trig to create vector with XY values representing
        -- the direction
        local direction = tes3vector3.new(
            math.cos(zDir),
            math.sin(zDir),
            0
        )

        local targetPosition = findNewPosition(origin, direction, distance)
        if targetPosition then
            logger:debug("Found target position %s, distance: %s", targetPosition, distance)
            return targetPosition
        end
    end
end

---Given a position, try to find a valid position closer to the player
---@param startPosition tes3vector3 The position to start looking from
---@param distance number The distance towards the player
function SwimService.findPositionTowardsPlayer(startPosition, distance)
    local playerPos = tes3vector3.new(
        tes3.player.position.x,
        tes3.player.position.y,
        startPosition.z
    )
    local direction = (playerPos - startPosition):normalized()
    logger:debug("Direction: %s", direction)

    local targetPosition = findNewPosition(startPosition, direction, distance)
    if targetPosition then
        return targetPosition
    end
end

---@class Fishing.FishPhysics
---@field heading number
---@field bodyHeading number
---@field velocity tes3vector3


---@class Fishing.SwimService.startSwimming.params
---@field from tes3vector3
---@field to tes3vector3
---@field callback function
---@field lure? tes3reference
---@field speed number
---@field physics? Fishing.FishPhysics
---@field turnSpeed number
---@field grounded? boolean



---@param heading number
local function rotateFishForwards(heading)
    local lure = FishingStateManager.getLure()
    if not lure then
        logger:error("No lure found")
        return
    end
    local fishAttachNode = lure.sceneNode:getObjectByName("ATTACH_FISH")
    if not fishAttachNode then
        logger:error("No fish attach node found")
        return
    end
    --Rotate the attach node in the direction of movement
    local matrix = tes3matrix33.new()
    local radians = -heading
    matrix:toRotationZ(radians)

    fishAttachNode.rotation = matrix
end

--[[
    Beginning at start position, move towards target position,
    generating ripples along the way at a rate of 0.05 seconds
    until the fish reaches the target position, then execute
    fish caught logic
]]
---@param e Fishing.SwimService.startSwimming.params
function SwimService.startSwimming(e)
    logger:debug("Starting to swim")
    logger:debug("Grounded? %s", e.grounded)
    local currentPosition = e.from:copy()
    local currentState = FishingStateManager.getCurrentState()
    local safeLure
    if e.lure then
        safeLure = tes3.makeSafeObjectHandle(e.lure)
    end

    local movementSimulate
    local timePassed = 0
    local two_pi = 2 * math.pi
    local physics = e.physics or {}
    if not physics.heading then
        physics.heading = math.atan2(e.to.y - currentPosition.y, e.to.x - currentPosition.x)
    end
    physics.bodyHeading = physics.bodyHeading or physics.heading
    if not physics.velocity then physics.velocity = tes3vector3.new() end

    ---@param simulateEventData simulateEventData
    movementSimulate = function(simulateEventData)
        logger:trace("targetPosition: %s", e.to)
        if not FishingStateManager.isState(currentState) then
            logger:trace("State changed, cancelling")
            event.unregister("simulate", movementSimulate)
            return
        end
        local distance = currentPosition:distance(tes3vector3.new(e.to.x, e.to.y, currentPosition.z))
        if distance < 30 then
            logger:trace("Reached target position")
            event.unregister("simulate", movementSimulate)
            e.callback()
            return
        end

        --Simulate limited turning rate
        local targetHeading = math.atan2(e.to.y - currentPosition.y, e.to.x - currentPosition.x)
        local turnLeft = targetHeading - physics.heading
        local turnRight = -turnLeft
        if turnLeft < 0 then turnLeft = turnLeft + two_pi end
        if turnRight < 0 then turnRight = turnRight + two_pi end
        --Increase turn rate when near the destination, to avoid getting stuck circling the destination point
        local turn = e.turnSpeed * (1 + math.max(0, 0.02 * (200 - distance))) * simulateEventData.delta
        if turnLeft < turnRight then
            --Turn left
            local newHeading = physics.heading + turn
            if newHeading > math.pi then
                newHeading = newHeading - two_pi
            end
            --Clamp angle to prevent turning past target
            if newHeading > targetHeading and physics.heading <= targetHeading then
                physics.heading = targetHeading
            else
                physics.heading = newHeading
            end
        else
            --Turn right
            local newHeading = physics.heading - turn
            if newHeading < -math.pi then
                newHeading = newHeading + two_pi
            end
            --Clamp angle to prevent turning past target
            if newHeading < targetHeading and physics.heading >= targetHeading then
                physics.heading = targetHeading
            else
                physics.heading = newHeading
            end
        end

        --Update velocity
        ---@diagnostic disable
        physics.velocity.x = math.cos(physics.heading) * e.speed
        physics.velocity.y = math.sin(physics.heading) * e.speed
        ---@diagnostic enable
        physics.velocity.z = 0
        --Update position
        ---@type tes3vector3
        local deltaPos = physics.velocity * simulateEventData.delta
        logger:trace("delta: %s", deltaPos)
        local distanceTravelled = deltaPos:length()
        logger:trace("distanceTravelled: %s", distanceTravelled)
        local newPosition = currentPosition + deltaPos
        logger:trace("new position: %s", newPosition, distanceTravelled)
        currentPosition = newPosition

        local lurePosition = newPosition
        if e.grounded then
            local waterLevel = tes3.player.cell.waterLevel or 0
            --raytest down to find ocean floor
            local ray = tes3.rayTest{
                position = tes3vector3.new(
                    newPosition.x,
                    newPosition.y,
                    waterLevel
                ),
                direction = tes3vector3.new(0,0,-1),
                maxDistance = 2000,
                ignore = FishingStateManager.getIgnoreRefs()
            }
            if ray and ray.intersection then
                logger:debug("Found ground, lowering grounded fish")
                lurePosition = tes3vector3.new(
                    newPosition.x,
                    newPosition.y,
                    ray.intersection.z + 15
                )
            end
        end

        if safeLure and safeLure:valid() then
            logger:trace("Updating lure position to: %s", lurePosition)
            safeLure.position = lurePosition
        end

        --check if time to generate ripple
        timePassed = timePassed + simulateEventData.delta
        if timePassed > config.constants.FISH_RIPPLE_INTERVAL then
            RippleGenerator.generateRipple{
                position = newPosition,
                scale = SwimService.rippleScale(),
                -- duration = 1.0,
                -- amount = 20,
            }
            timePassed = 0
        end

        --Rotate the fish to face the direction of movement
        local offset = (math.pi / 2) --to account for fish mesh orientation
        local bodyTurn = physics.heading - physics.bodyHeading - offset
        if bodyTurn < -math.pi then bodyTurn = bodyTurn + two_pi end
        if bodyTurn > math.pi then bodyTurn = bodyTurn - two_pi end
        local bodyTurnSpeed = e.speed / 100
        physics.bodyHeading = physics.bodyHeading + bodyTurn * bodyTurnSpeed * simulateEventData.delta
        --double wrap so it always rotates around the shortest way
        if physics.bodyHeading > math.pi then
            physics.bodyHeading = physics.bodyHeading - two_pi
        end
        if physics.bodyHeading < -math.pi then
            physics.bodyHeading = physics.bodyHeading + two_pi
        end

        rotateFishForwards(physics.bodyHeading)
    end
    event.register("simulate", movementSimulate)
end

function SwimService.rippleScale()
    local fish = FishingStateManager.getCurrentFish()
    if not fish then
        logger:error("rippleScale() No fish found")
        return 1.0
    end
    local variance = math.random(90, 110) / 100
    local scale = fish.fishType.size * variance
    logger:debug("rippleScale() scale: %s", scale)
    return scale
end



return SwimService
