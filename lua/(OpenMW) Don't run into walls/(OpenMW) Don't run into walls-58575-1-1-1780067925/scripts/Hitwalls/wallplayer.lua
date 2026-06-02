-- Wall Stop Script for OpenMW
-- Prevents the player from running into walls by detecting collisions ahead
-- and zeroing out movement controls when a wall is detected.
-- Plays a looping animation while blocked; stops it the moment the key is released.

local self       = require('openmw.self')
local nearby     = require('openmw.nearby')
local util       = require('openmw.util')
local types      = require('openmw.types')
local core       = require('openmw.core')
local interfaces = require('openmw.interfaces')
local anim       = require('openmw.animation')

-- Configuration
local RAY_DISTANCE      = 50   -- How far ahead to check for walls (game units)
local RAY_HEIGHT_OFFSET = 40   -- Height offset from feet (roughly waist height)
local SIDE_RAY_ANGLE    = 0.6  -- Angle in radians for side movement rays (~34 degrees)
local MIN_RAY_DISTANCE  = 20   -- Minimum distance: if wall is closer than this, always block

local WALL_PRESS_ANIM = "hitwall"

-- Internal state
local wasBlocked = {
    forward  = false,
    backward = false,
    left     = false,
    right    = false,
}

local isPlayingWallAnim = false

--- Cast a ray in a given direction and check if a wall is hit within range.
local function isWallAhead(origin, direction, distance)
    local target = origin + direction * distance
    local result = nearby.castRay(origin, target, {
        collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
    })
    return result.hit
end

local function getForwardDir()
    local rot = self.object.rotation
    local yaw = rot:getYaw()
    return util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
end

local function getRightDir()
    local forward = getForwardDir()
    return util.vector3(forward.y, -forward.x, 0):normalize()
end

local function startWallAnimation()
    if isPlayingWallAnim then return end
    isPlayingWallAnim = true
    interfaces.AnimationController.playBlendedAnimation(
        WALL_PRESS_ANIM,
        {
            startKey    = 'start',
            stopKey     = 'stop',
            loops       = math.maxinteger,
            priority    = {
                [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
                [anim.BONE_GROUP.LeftArm]  = anim.PRIORITY.Weapon,
                [anim.BONE_GROUP.Torso]    = anim.PRIORITY.Weapon,
            },
            autoDisable = true,
            blendMask   = anim.BLEND_MASK.UpperBody,
            speed       = 1,
            forceLoop   = true,
        }
    )
end

local function stopWallAnimation()
    if not isPlayingWallAnim then return end
    isPlayingWallAnim = false
    anim.cancel(self, WALL_PRESS_ANIM)
end

local function onFrame(dt)
    local controls = self.controls

    -- -----------------------------------------------------------------------
    -- ORIGINAL wall-stop logic, completely unchanged
    -- -----------------------------------------------------------------------
    if controls.movement == 0 and controls.sideMovement == 0 then
        wasBlocked.forward  = false
        wasBlocked.backward = false
        wasBlocked.left     = false
        wasBlocked.right    = false
        -- key released → stop animation
        stopWallAnimation()
        return
    end

    local pos    = self.object.position
    local origin = util.vector3(pos.x, pos.y, pos.z + RAY_HEIGHT_OFFSET)

    local forward = getForwardDir()
    local right   = getRightDir()

    if controls.movement > 0 then
        if isWallAhead(origin, forward, RAY_DISTANCE) then
            controls.movement  = 0
            wasBlocked.forward = true
        else
            wasBlocked.forward = false
        end
    elseif controls.movement < 0 then
        local backward = forward * -1
        if isWallAhead(origin, backward, RAY_DISTANCE) then
            controls.movement   = 0
            wasBlocked.backward = true
        else
            wasBlocked.backward = false
        end
    end

    if controls.sideMovement > 0 then
        if isWallAhead(origin, right, RAY_DISTANCE) then
            controls.sideMovement = 0
            wasBlocked.right      = true
        else
            wasBlocked.right = false
        end
    elseif controls.sideMovement < 0 then
        local left = right * -1
        if isWallAhead(origin, left, RAY_DISTANCE) then
            controls.sideMovement = 0
            wasBlocked.left       = true
        else
            wasBlocked.left = false
        end
    end

    if controls.movement ~= 0 and controls.sideMovement ~= 0 then
        local diagDir = (forward * controls.movement + right * controls.sideMovement):normalize()
        if isWallAhead(origin, diagDir, RAY_DISTANCE) then
            controls.movement     = 0
            controls.sideMovement = 0
            wasBlocked.forward    = true
        end
    end

    -- -----------------------------------------------------------------------
    -- Animation: purely driven by wasBlocked flags set above
    -- -----------------------------------------------------------------------
    local blocked = wasBlocked.forward or wasBlocked.backward
                 or wasBlocked.left    or wasBlocked.right

    if blocked then
        startWallAnimation()
    else
        stopWallAnimation()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
    },
}
