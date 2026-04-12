-- Wall Stop Script for OpenMW
-- Prevents the player from running into walls by detecting collisions ahead
-- and zeroing out movement controls when a wall is detected.

local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local core = require('openmw.core')
local interfaces = require('openmw.interfaces')

-- Configuration
local RAY_DISTANCE = 50          -- How far ahead to check for walls (game units)
local RAY_HEIGHT_OFFSET = 40     -- Height offset from feet (roughly waist height)
local SIDE_RAY_ANGLE = 0.6       -- Angle in radians for side movement rays (~34 degrees)
local MIN_RAY_DISTANCE = 20      -- Minimum distance: if wall is closer than this, always block

-- Internal state
local wasBlocked = {
    forward = false,
    backward = false,
    left = false,
    right = false,
}

--- Cast a ray in a given direction and check if a wall is hit within range.
-- @param origin  Starting position (Vector3)
-- @param direction  Normalized direction vector (Vector3)
-- @param distance  Maximum ray distance
-- @return boolean  true if a wall was hit within distance
local function isWallAhead(origin, direction, distance)
    local target = origin + direction * distance
    local result = nearby.castRay(origin, target, {
        collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
    })
    return result.hit
end

--- Get the player's forward direction on the horizontal plane.
-- Uses the object's rotation around the Z axis (yaw).
local function getForwardDir()
    local rot = self.object.rotation
    -- rotation:getYaw() gives the heading; build a horizontal direction from it
    local yaw = rot:getYaw()
    return util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
end

--- Get the player's right direction on the horizontal plane.
local function getRightDir()
    local forward = getForwardDir()
    -- Right is perpendicular to forward in the horizontal plane
    return util.vector3(forward.y, -forward.x, 0):normalize()
end

local function onFrame(dt)
    local controls = self.controls

    -- Only process when the player is actually trying to move
    if controls.movement == 0 and controls.sideMovement == 0 then
        wasBlocked.forward = false
        wasBlocked.backward = false
        wasBlocked.left = false
        wasBlocked.right = false
        return
    end

    local pos = self.object.position
    local origin = util.vector3(pos.x, pos.y, pos.z + RAY_HEIGHT_OFFSET)

    local forward = getForwardDir()
    local right = getRightDir()

    -- Check forward movement
    if controls.movement > 0 then
        if isWallAhead(origin, forward, RAY_DISTANCE) then
            controls.movement = 0
            wasBlocked.forward = true
        else
            wasBlocked.forward = false
        end
    elseif controls.movement < 0 then
        -- Check backward movement
        local backward = forward * -1
        if isWallAhead(origin, backward, RAY_DISTANCE) then
            controls.movement = 0
            wasBlocked.backward = true
        else
            wasBlocked.backward = false
        end
    end

    -- Check side movement
    if controls.sideMovement > 0 then
        if isWallAhead(origin, right, RAY_DISTANCE) then
            controls.sideMovement = 0
            wasBlocked.right = true
        else
            wasBlocked.right = false
        end
    elseif controls.sideMovement < 0 then
        local left = right * -1
        if isWallAhead(origin, left, RAY_DISTANCE) then
            controls.sideMovement = 0
            wasBlocked.left = true
        else
            wasBlocked.left = false
        end
    end

    -- Also check diagonal movement direction when both axes are active
    if controls.movement ~= 0 and controls.sideMovement ~= 0 then
        local diagDir = (forward * controls.movement + right * controls.sideMovement):normalize()
        if isWallAhead(origin, diagDir, RAY_DISTANCE) then
            -- Block whichever component is pushing into the wall more
            -- by re-checking each axis independently; the individual checks
            -- above may have already handled this, but this catches edge cases
            -- where the diagonal hits a corner
            controls.movement = 0
            controls.sideMovement = 0
        end
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
    },
}