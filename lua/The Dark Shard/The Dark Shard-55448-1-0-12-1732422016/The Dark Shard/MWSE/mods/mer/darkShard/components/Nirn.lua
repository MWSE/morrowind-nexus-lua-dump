local common = require("mer.darkShard.common")
local CelestialObject = require("mer.darkShard.components.CelestialObject")

local nirnZDegrees = -25

local celestialObject = CelestialObject:new{
    id = "AFQ_NIRN",
    meshPath = "afq\\afq_nirn.nif",
    rotation = tes3vector3.new(0, 0, math.rad(nirnZDegrees)),
    scale = 1
}

---@class DarkShard.Nirn
local Nirn = {}

function Nirn.getCometNode()
    return celestialObject:getNode()
end

function Nirn.isEnabled()
    return celestialObject:isEnabled()
end

---@return boolean #True if the comet was enabled, false if it was already enabled
function Nirn.enable()
    return celestialObject:enable()
end

---@return boolean #True if the comet was disabled, false if it was already disabled
function Nirn.disable()
    return celestialObject:disable()
end

function Nirn.isInView()
    local targetVector = tes3vector3.new(0, 0.72, 0.70)
    local maxVariance = 0.01
    local lookDirection = tes3.getPlayerEyeVector()
    local dot = lookDirection:dot(targetVector)
    return dot > 1 - maxVariance
end

return Nirn