---[[
--- TODO: Implement animations
--- TODO: Increase reach (optionally??)
---]]

local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
---@type nearby
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local Stats = self.type.stats

local DynamicStats = Stats.dynamic
local Fatigue = DynamicStats.fatigue(self)

local Attributes = Stats.attributes
local Agility = Attributes.agility(self)
local Speed = Attributes.speed(self)

local Skills = Stats.skills
local Athletics = Skills.athletics(self)
local Acrobatics = Skills.acrobatics(self)

--- @class ClimbMod
--- @field CLIMB_ACTIVATE_RANGE number The maximum range (in units) within which climbing can be activated.
--- @field CLIMB_SEARCH_STEP_RANGE number The step range (in units) used for searching for the top of climbable surfaces.

--- @class ClimbState
--- @field climbEngaged boolean Indicates whether the climbing state is currently active.
--- @field climbRisePos nil|util.vector3 The first stopping point during the climb, before moving forward. Nil if not climbing.
--- @field climbEndPos nil|util.vector3 The position where the climb ends. Nil if not climbing.
--- @field prevCamMode nil|number The previous camera mode before climbing was engaged. Nil if not climbing.

local ClimbMod = {
    CLIMB_ACTIVATE_RANGE = 64,
    CLIMB_SEARCH_STEP_RANGE = 2,
}

local ClimbState = {
    climbEngaged = false,
    climbRisePos = nil,
    climbEndPos = nil,
    prevCamMode = nil,
}


--- Toggles the override state for various control systems in the game.
--- 
--- This function enables or disables the override for movement, combat, 
--- and UI controls based on the provided state.
---
--- @param state boolean
---   A boolean value indicating whether to enable (`true`) or disable (`false`) 
---   the override for the controls.
function ClimbMod.switchControls(state)
    I.Controls.overrideMovementControls(state)
    I.Controls.overrideCombatControls(state)
    I.Controls.overrideUiControls(state)
end

--- Engages the climbing mode by setting the climb state to active and
--- storing the starting and ending positions of the climb.
--- Both will be sent as inputs to a global function
---
--- @param risePos util.vector3 The starting position of the climb, typically a vector or coordinate.
--- @param endPos util.vector3 The ending position of the climb, typically a vector or coordinate.
function ClimbMod.engage(risePos, endPos)
    ClimbMod.switchControls(true)

    ClimbState = {
        climbEngaged = true,
        climbRisePos = risePos,
        climbEndPos = endPos,
        prevCamMode = camera.getMode(),
    }

    camera.setMode(camera.MODE.FirstPerson)

    core.sendGlobalEvent('S3_ChimClimb_ClimbStart', {
        endPos = ClimbState.climbEndPos,
        fatigueDrain = ClimbMod.getFatigueDrain(),
        startPos = ClimbState.climbRisePos,
        speedMult = ClimbMod.getSpeedMult(),
        target = self.object,
    })
end

--- Disengages the climbing mode for the player.
---
--- This function resets the climbing state by setting `climbEngaged` to `false`
--- and clearing the positions (`climbRisePos` and `climbEndPos`) associated with
--- the climbing process.
---
--- Usage:
--- Call in an eventHandler when the player is no longer climbing
function ClimbMod.disengage()
    ClimbMod.switchControls(false)

    camera.setMode(ClimbState.prevCamMode or camera.MODE.ThirdPerson)

    ClimbState = {
        climbEngaged = false,
        climbRisePos = nil,
        climbEndPos = nil,
        prevCamMode = nil,
    }

    core.sendGlobalEvent('S3_ChimClimb_ClimbInterrupt', self.id)
end

--- Calculates the fatigue drain for climbing based on game settings and the player's encumbrance.
--- 
--- This function retrieves the base fatigue drain and the multiplier for fatigue drain from 
--- game settings (GMST). It then calculates the normalized encumbrance of the player as a 
--- ratio of their current encumbrance to their maximum capacity. The final fatigue drain 
--- is computed as the sum of the base fatigue drain and the product of the multiplier with 
--- the normalized encumbrance. 
--- https://wiki.openmw.org/index.php?title=Research:Movement#On_jumping
---
--- @return number The calculated fatigue drain value.
function ClimbMod.getFatigueDrain()
    local fatigueJumpBase = core.getGMST('fFatigueJumpBase')
    local fatigueJumpMult = core.getGMST('fFatigueJumpMult')
    local normalizedEncumbrance = self.type.getEncumbrance(self) / self.type.getCapacity(self)

    return fatigueJumpBase + (fatigueJumpMult * normalizedEncumbrance)
end

--- Calculates the flat value of a given stat, ensuring it does not exceed 100.
--- 
--- This function takes a stat object with a `modified` property and returns
--- the lesser of the `modified` value or 100. It is useful for clamping
--- stat values to a maximum threshold.
---
--- @param stat userdata A table representing the stat, which must contain a `modified` field.
--- @return number The clamped stat value, capped at 100.
local function getStatMult(stat)
---@diagnostic disable-next-line: undefined-field
    return math.min(stat.modified, 100) / 100
end

--- Calculates the climbing speed multiplier based on player attributes and skills.
--- TODO: Also account for normalized encumbrance, maybe
--- @return number The climbing speed multiplier.
function ClimbMod.getSpeedMult()
    local agilityFactor = getStatMult(Agility)
    local speedFactor = getStatMult(Speed)
    local athleticsFactor = getStatMult(Athletics)
    local acrobaticsFactor = getStatMult(Acrobatics)

    -- Weighted formula for climbing speed multiplier
    local multiplier = 1.0 + (0.4 * speedFactor) + (0.3 * athleticsFactor) + (0.1 * agilityFactor) + (0.2 * acrobaticsFactor)

    -- Clamp the multiplier to a reasonable range (e.g., 1.0 to 2.0)
    return math.min(math.max(multiplier, 1.0), 2.0)
end

--- Calculates the climbing range for the player based on their bounding box.
---
--- This function determines the center of the player's bounding box and a point
--- directly above it at a height equal to twice the bounding box's half-size along the z-axis.
---
--- @return number minHeight The center of the player's bounding box. Objects lower than this can't be climbed.
--- @return number topPoint Z position of player's center + 2X z halfSize. Objects higher than this can't be climbed.
function ClimbMod.climbRanges()
    local box = self:getBoundingBox()
    local height = box.halfSize.z * 2
    return box.center.z, box.center.z + height
end

--- Perform a raycast to find the maximum climbable height.
--- @param center util.vector3 The starting position of the raycast.
--- @param scanPos util.vector3 The ending position of the raycast.
--- @return RayCastingResult|nil The highest hit object or nil if no valid hit is found.
function ClimbMod.findMaxClimbableHeight(center, scanPos)
    local upwardHit
    while true do
        -- Increment Z position of both start and end points
        center = center + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)
        scanPos = scanPos + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)

        -- Perform raycast at the new height
        local currentHit = nearby.castRay(center, scanPos, { ignore = { self } })

        if not currentHit.hit then
            print("No hit detected at height:", center.z)
            break
        end

        print("Hit detected at height:", center.z, "Object was:", currentHit.hitObject)
        upwardHit = currentHit
    end

    return upwardHit
end

--- Validate if the hit object is climbable based on height constraints.
--- @param upwardHit RayCastingResult The hit object from the raycast.
--- @return boolean True if the object is climbable, false otherwise.
function ClimbMod.isClimbable(upwardHit)
    if not upwardHit or not upwardHit.hit then
        print("No upward hit detected.")
        return false
    end

    local climbMin, climbMax = ClimbMod.climbRanges()
    print(upwardHit.hitPos.z, climbMin, climbMax) 

    -- Check if the hit object is within climbable height range
    if upwardHit.hitPos.z < climbMin or upwardHit.hitPos.z > climbMax then
        print("Hit object is too high or too low to climb.")
        return false
    end

    return true
end

--- Calculate the final destination for the climb.
--- @param upwardHit table The highest hit object.
--- @param zTransform table The player's Z rotation transform.
--- @return util.vector3 The final destination position.
local function calculateFinalDestination(upwardHit, zTransform)
    -- Use the original position, bumped up a bit
    local firstStopPoint = util.vector3(upwardHit.hitPos.x, upwardHit.hitPos.y, upwardHit.hitPos.z + 5)
    print("Vertical destination is", upwardHit.hitObject, upwardHit.hitPos)

    -- Determine the final destination after moving forward
    local forwardStep = self:getBoundingBox().halfSize.y / 2
    local forwardVec = zTransform:apply(util.vector3(0, forwardStep, 0))
    local finalStopPoint = firstStopPoint + forwardVec

    local finalHit = nearby.castRay(firstStopPoint, finalStopPoint, { ignore = { self } })

    -- If no hit, move to the final position; otherwise, use the collision point
    if finalHit.hit then
        print("Hit detected at final destination:", finalHit.hitObject)
        return finalHit.hitPos
    else
        print("No hit detected at final destination.")
        return finalStopPoint
    end
end

input.registerTriggerHandler(
    "Jump",
    async:callback(function()
        if ClimbState.climbEngaged then
            return ClimbMod.disengage()
        end

        -- Transform encompassing player's current Z Rotation
        local zTransform = util.transform.rotateZ(self.rotation:getYaw())
        local center = self:getBoundingBox().center
        local scanPos = center + zTransform:apply(util.vector3(0, ClimbMod.CLIMB_ACTIVATE_RANGE, 0))

        local waistHit = nearby.castRay(center, scanPos, { ignore = { self } })
        if not waistHit.hit then
            print("No hit detected at waist level.")
            return
        elseif not waistHit.hitObject then
            error("No hit object detected, but something was hit! Is the collisionType correct?")
        end

        print('\n', "Center is:", center, '\n', 'scanPos is:', scanPos, '\n', 'zTransform is', zTransform, '\n\n\n')

        local upwardHit = ClimbMod.findMaxClimbableHeight(center, scanPos)

        if not upwardHit then
            error('No upward hit detected.')
        end

        if not ClimbMod.isClimbable(upwardHit) then
            print("Hit object is not climbable.")
            return
        end

        local finalDestination = calculateFinalDestination(upwardHit, zTransform)

        print("Final destination is", finalDestination)

        ClimbMod.engage(
            upwardHit.hitPos,
            finalDestination
        )
    end)
)

return {
    engineHandlers = {
        onFrame = function(dt)
            if ClimbState.climbEngaged then
                self.controls.jump = false
                if camera.getMode() ~= camera.MODE.FirstPerson then
                    camera.setMode(camera.MODE.FirstPerson)
                end
            end
        end,
        onSave = function()
            return ClimbState
        end,
        onLoad = function(data)
            ClimbState = data or {
                climbEngaged = false,
                climbRisePos = nil,
                climbEndPos = nil,
                prevCamMode = nil,
            }
        end,
    },
    eventHandlers = {
        S3_ChimClimb_ClimbEnd = ClimbMod.disengage,
        S3_ChimClimb_DrainFatigue = function(newFatigue)
            Fatigue.current = newFatigue
        end,
    },
}
