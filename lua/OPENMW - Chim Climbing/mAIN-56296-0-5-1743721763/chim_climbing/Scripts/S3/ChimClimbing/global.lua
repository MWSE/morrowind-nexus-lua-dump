local util = require('openmw.util')
local types = require('openmw.types')

local ActorType = types.Actor
local Fatigue = ActorType.stats.dynamic.fatigue

local ClimbQueue = {}

local ZHeightBuffer = 10
local FatigueFailCost = -300

---@class ClimbData
---@field didDrainFatigue nil|boolean Indicates whether fatigue has been drained during the climb.
---@field endPos util.vector3 The ending position of the climb.
---@field fatigueDrain number The amount of fatigue drained during the climb.
---@field startPos util.vector3 The starting position of the climb.
---@field speedMult number The speed multiplier for the climb.
---@field target GameObject The entity that is performing the climb.

---@class GameObject userdata
---@field position util.vector3
---@field getBoundingBox function(): userdata
---@field teleport function(cell: userdata, position: util.vector3, options: table)
---@field sendEvent function(eventName: string, eventData: any)
---@field id string The unique identifier for the object.
---@field cell userdata The cell in which the object is located.

--- Calculates a buffered position for a given object by adjusting its Z-coordinate.
--- The buffered position is determined by adding the half-size of the object's bounding box
--- along the Z-axis to the object's current position.
---
--- @param object GameObject The object for which the buffered position is calculated.
---                      It is expected to have a `position` property (a vector3 with x, y, z fields)
---                      and a `getBoundingBox` method that returns a bounding box with a `halfSize.z` field.
--- @return util.vector3 vector3 table representing the buffered position with adjusted Z-coordinate.
local function BufferedPosition(object)
    local vector = object.position
    return util.vector3(vector.x, vector.y, vector.z + object:getBoundingBox().halfSize.z)
end

--- Helper function to handle movement logic
--- @param target table The target object to move.
--- @param targetPos util.vector3 The target position to move toward.
--- @param dt number Delta time for the frame.
--- @param speedMult number Speed multiplier for the movement.
--- @return boolean True if the target was moved, false if the movement is complete.
local function moveTargetTowards(target, targetPos, dt, speedMult)
    local moveDistance = (targetPos - target.position) * dt * speedMult
    if moveDistance:length() > 0.1 then
        target:teleport(target.cell, target.position + moveDistance)
        return true
    end
    return false
end

--- Handles the fatigue drain during a mantle action in the climbing system.
--- This function ensures that fatigue is properly drained from the target
--- and determines whether the mantle action fails due to insufficient fatigue.
---
--- @param climbData ClimbData A table containing data related to the current climb.
--- @return boolean `true` if the mantle action fails due to insufficient fatigue, `false` otherwise.
--- @throws Error if `didDrainFatigue` is already `true`, indicating fatigue has already been drained.
local function handleMantleFatigue(climbData)
    assert(not climbData.didDrainFatigue, "Fatigue already drained for this climb.")

    local targetFatigue = Fatigue(climbData.target)

    local fatigueAfterMantle = targetFatigue.current - climbData.fatigueDrain
    local didFail = fatigueAfterMantle < 0
    local newFatigue = (didFail and FatigueFailCost) or fatigueAfterMantle

    climbData.target:sendEvent('S3_ChimClimb_DrainFatigue', newFatigue)
    climbData.didDrainFatigue = true

    return didFail
end

--- Handles the per-frame climbing logic for a target.
--- This function moves the target towards specified positions (startPos or endPos)
--- and updates the climbing state accordingly. If the target reaches the end of
--- the climb, it sends a climb end event and clears the climb queue for the target.
---
--- @param dt number The delta time since the last frame, used to calculate movement.
--- @param climbData ClimbData
---
--- The function performs the following steps:
--- 1. If `startPos` exists, it moves the target towards it. Once reached, `startPos` is cleared.
--- 2. If `startPos` is nil and `endPos` exists, it moves the target towards `endPos`.
---    Once reached, the target is teleported to a buffered position, and `endPos` is cleared.
--- 3. If both `startPos` and `endPos` are nil, it sends a climb end event and removes
---    the target from the climb queue.
local function handlePerFrameClimb(dt, climbData)
    local startPos = climbData.startPos
    local endPos = climbData.endPos
    local speedMult = climbData.speedMult
    local target = climbData.target
    local targetId = target.id

    if startPos then
        if not moveTargetTowards(target, startPos, dt, speedMult) then
            ClimbQueue[targetId].startPos = nil
        end
    elseif endPos then
        if not climbData.didDrainFatigue then
            local didFail = handleMantleFatigue(climbData)
            if didFail then
                target:sendEvent('S3_ChimClimb_ClimbEnd')
                ClimbQueue[targetId] = nil
                return
            end
        end

        if not moveTargetTowards(target, endPos, dt, speedMult) then
            target:teleport(target.cell, BufferedPosition(target), { onGround = true })
            ClimbQueue[targetId].endPos = nil
        end
    else
        target:sendEvent('S3_ChimClimb_ClimbEnd')
        ClimbQueue[targetId] = nil
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            for _, climbData in pairs(ClimbQueue) do
                handlePerFrameClimb(dt, climbData)
            end
        end,
    },
    eventHandlers = {
        ---@param climbData ClimbData
        S3_ChimClimb_ClimbStart = function(climbData)
            local climberId = climbData.target.id
            if not ClimbQueue[climberId]then
                ClimbQueue[climberId] = climbData
            end
        end,
        S3_ChimClimb_ClimbInterrupt = function(targetId)
            if ClimbQueue[targetId] then ClimbQueue[targetId] = nil end
        end,
    }
}
