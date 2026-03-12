local mp = "scripts/MaxYari/MercyCAO/"

local core = require("openmw.core")
local omwself = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local gutils = require(mp .. "scripts/gutils")
local moveutils = require(mp .. "scripts/movementutils")

local selfActor = gutils.Actor:new(omwself)



-- Local obstacle avoidance class --------------------------------------------------------
Obstacle = {}
Obstacle.__index = Obstacle


-- Constructor
function Obstacle:new(obstacle)
    local obstacleHS = gutils.diagonalFlatHalfSize(types.Actor.getPathfindingAgentBounds(obstacle))
    local actorHS = gutils.diagonalFlatHalfSize(selfActor:getPathfindingAgentBounds())
    local threshold = obstacleHS + actorHS

    local obj = {
        obstacle = obstacle,
        threshold = threshold,
        maxEffectiveDistance = threshold + actorHS * 2,
        distance = function(self)
            return (self.obstacle.position - omwself.position):length()
        end
    }
    setmetatable(obj, Obstacle)

    return obj
end

-- Method to check if the obstacle is passed
function Obstacle:isValid(desiredDirection)
    local distanceVector = self.obstacle.position - omwself.position
    local distance = distanceVector:length()
    -- Calculate the projection of desired velocity onto the distance vector
    local projection = desiredDirection:dot(distanceVector:normalize())
    -- Return true if projection is less than 0
    return distance < self.maxEffectiveDistance and projection > 0
end

-- Method to calculate the avoidance force
function Obstacle:calculateAvoidanceDirection(desiredDirection, lastDirection)
    local distanceVector = self.obstacle.position - omwself.position
    local distance = distanceVector:length()
    local normalizedDistance = distanceVector:normalize()
    local meanDesiredDirection = lastDirection
    -- local meanDesiredDirection = (desiredDirection + lastDirection) / 2
    local avoidanceDirection

    if not self.avoidanceSide then
        -- Normalize the distance vector
        local crossProduct = meanDesiredDirection:cross(normalizedDistance)

        -- Determine side of avoidance based on cross product
        if crossProduct.z < 0 then
            self.avoidanceSide = -1
        else
            self.avoidanceSide = 1
        end
    end

    avoidanceDirection = util.vector3(normalizedDistance.y, -normalizedDistance.x, 0) * self.avoidanceSide

    --print("Mean desired:", meanDesiredDirection, "To obstacel:", normalizedDistance, "Avoidance:",
    --    avoidanceDirection)

    -- Linear interpolation
    local alpha = (self.maxEffectiveDistance - distance) / (self.maxEffectiveDistance - self.threshold)
    alpha = math.max(alpha, 0) -- Ensure alpha is not negative

    local interpolatedDirection = meanDesiredDirection * (1 - alpha) + avoidanceDirection * alpha

    --print("Intepolated:", interpolatedDirection)

    return interpolatedDirection
end

function Obstacle:flipAvoidanceDirection()
    if not self.avoidanceSide then return end
    self.avoidanceSide = self.avoidanceSide * -1
end

----------------------------------------------------------------------------------------------




-- Navigation service handles calculation of a nav path from self to targetPos in an optimised cached manner --
---------------------------------------------------------------------------------------------------------------
local function NavigationService(config)
    if not config then config = {} end

    local NavData = {
        path = nil,
        findPathStatus = nil,
        doorStuck = false,
        targetPos = nil,
        pathPointIndex = 1,
        nextPathPoint = nil,
        runSpeed = selfActor:getRunSpeed(),
        walkSpeed = selfActor:getWalkSpeed(),
        bounds = selfActor:getPathfindingAgentBounds(),
        lastDirection = nil,
        posToVelSampler = gutils.PosToVelSampler:new(1)
    }


    -- Navmesh point validity checker ----------------------------------
    function NavData:canMoveTo(movePos)
        -- Check nearest navmesh pos
        local moveVec = movePos - omwself.position
        local navMeshPosition = nearby.findNearestNavMeshPosition(movePos)

        if not navMeshPosition then
            return false, "No nearest navmesh point"
        end

        local navMeshMoveVec = navMeshPosition - omwself.position
        local navMeshDist = navMeshMoveVec:dot(moveVec:normalize()) -- Projection onto a move vector

        local endPosDifference = (movePos - navMeshPosition):length()

        if navMeshDist < moveVec:length() * 0.9 then
            return false, "Navmesh position is too close to the current position"
        elseif endPosDifference > gutils.minHorizontalHalfSize(self.bounds) * 0.9 then
            return false, "Navmesh position is too far from the desired move position"
        end

        return true
    end

    function NavData:canMoveInDirection(direction, lookAhead)
        if not lookAhead then lookAhead = 10 end
        return self:canMoveTo(omwself.position + direction * lookAhead)
    end

    ----------------------------------------------------------------------------



    -- Pathing functions -------------------------------------------------------
    function NavData:getfindPathStatusVerbose()
        if self.findPathStatus == nil then return nil end
        return gutils.findField(nearby.FIND_PATH_STATUS, self.findPathStatus)
    end

    function NavData:isPathCompleted()
        return self.path and #self.path > 0 and self.pathPointIndex > #self.path
    end

    function NavData:calculatePathLength()
        if not self.path then return 0 end

        local pathLength = 0
        for i = 1, #self.path - 1 do
            -- Calculate the distance between consecutive points
            local segmentLength = (self.path[i + 1] - self.path[i]):length()
            pathLength = pathLength + segmentLength
        end
        return pathLength
    end

    local function findPath()
        NavData.findPathStatus, NavData.path = nearby.findPath(omwself.object.position, NavData.targetPos, {
            agentBounds = selfActor:getPathfindingAgentBounds(),
        })
        NavData.pathPointIndex = 1
        return NavData.findPathStatus, NavData.path
    end

    local findPathCached = gutils.cache(findPath, config.cacheDuration)

    function NavData:setTargetPos(pos)
        if not self.targetPos or (self.targetPos - pos):length() > config.targetPosDeadzone then
            self.targetPos = pos
            findPath()
        end
    end

    local function positionReached(pos1, pos2)
        return (pos1 - pos2):length() <= config.pathingDeadzone
    end

    function NavData:run(opts)
        -- Setting up defaults
        if opts.desiredSpeed == -1 then
            opts.desiredSpeed = selfActor:getRunSpeed()
        end

        -- Fetching a new path if necessary
        if self.targetPos then
            local findPathStatus, path, cacheStatus = findPathCached()
            self.findPathStatus = findPathStatus
        end

        -- Find shortcuts
        local startI = self.pathPointIndex + 1
        local i = startI
        while i <= #self.path and i <= startI + 2 do
            local pathPoint = self.path[i]
            local position = nearby.castNavigationRay(omwself.position, pathPoint, {
                agentBounds = selfActor:getPathfindingAgentBounds(),
            })
            if position and (position - pathPoint):length() < 10 then
                self.pathPointIndex = i
            end
            i = i + 1
        end

        -- Updating path progress
        if self.path and self.pathPointIndex <= #self.path then
            -- Check if the actor reached the current target point
            while self.pathPointIndex <= #self.path do
                if positionReached(omwself.object.position, self.path[self.pathPointIndex]) then
                    self.pathPointIndex = self.pathPointIndex + 1
                else
                    break;
                end
            end
            if self.pathPointIndex <= #self.path then
                self.nextPathPoint = self.path[self.pathPointIndex]
            else
                self.nextPathPoint = nil
                -- Reached path end
            end
        end

        -- Calculating movement
        local movement, sideMovement
        local desiredDirection

        if self.nextPathPoint then
            desiredDirection = (self.nextPathPoint - omwself.position):normalize()
            movement, sideMovement = moveutils.calculateMovement(omwself,
                desiredDirection)
        else
            movement, sideMovement = 0, 0
        end

        -- Raycast ahead, if door is hit - open it, if can't - fail
        if desiredDirection then
            local rayFro = gutils.getActorLookRayPos(omwself)
            local rayTo = rayFro + desiredDirection * 100
            local raycast = nearby.castRay(rayFro,
                rayTo, { ignore = omwself, collisionType = nearby.COLLISION_TYPE.Door })
            local door = raycast.hitObject
            -- We stumbled upon a door, maybe we can open it?
            if door then
                if not types.Door.isTeleport(door) and selfActor:canOpenDoor(door) then
                    if types.Door.getDoorState(door) ~= types.Door.STATE.Opening then
                        core.sendGlobalEvent("openTheDoor", { actorObject = omwself, doorObject = door })
                    end
                    self.doorStuck = false
                else
                    self.doorStuck = true
                end
            else
                self.doorStuck = false
            end
        end


        -- Detecting obstacles and adjusting movement if necessary
        if desiredDirection and self.lastDirection then
            -- Checking if last obstacle is still valid
            if self.closestObs and not self.closestObs:isValid(desiredDirection) then
                self.closestObs = nil
            end
            -- Looking for nearby obstacles
            for index, gameObject in ipairs(nearby.actors) do
                if opts.ignoredObstacleObject and opts.ignoredObstacleObject.id == gameObject.id then goto continue end
                if gameObject.id == omwself.id then goto continue end
                if types.Actor.isDead(gameObject) then goto continue end

                local obstacle = Obstacle:new(gameObject)
                if obstacle:isValid(desiredDirection) then
                    if not self.closestObs or obstacle:distance() < self.closestObs:distance() then
                        self.closestObs = obstacle
                    end
                end

                ::continue::
            end
            -- Trying to avoid the obstacle
            if self.closestObs then
                --print("Colliding with " .. self.closestObs.obstacle.recordId)
                local avoidanceDirection = self.closestObs:calculateAvoidanceDirection(desiredDirection,
                    self.lastDirection)

                if self:canMoveInDirection(avoidanceDirection) then
                    desiredDirection = avoidanceDirection
                    movement, sideMovement = moveutils.calculateMovement(omwself, desiredDirection)
                end

                -- Detecting being stuck and changing avoidance irection
                self.posToVelSampler:sample(omwself.position)
                if self.posToVelSampler.warmedUp and self.posToVelSampler:mean():length() < opts.desiredSpeed * 0.1 then
                    gutils.print("It seems like we are stuck in here, canging obstacle avoidance direction", 1)
                    self.closestObs:flipAvoidanceDirection()
                    self.posToVelSampler = gutils.PosToVelSampler:new(self.posToVelSampler.time_window)
                end
            end
        end

        self.lastDirection = desiredDirection

        -- adjusting and returning movement
        local lookDirection = desiredDirection
        local speedMult, shouldRun = moveutils.calcSpeedMult(opts.desiredSpeed, self.walkSpeed, self.runSpeed)

        return movement * speedMult, sideMovement * speedMult, shouldRun, lookDirection
    end

    ----------------------------------------------------------------------------------------



    return NavData
end


return NavigationService
