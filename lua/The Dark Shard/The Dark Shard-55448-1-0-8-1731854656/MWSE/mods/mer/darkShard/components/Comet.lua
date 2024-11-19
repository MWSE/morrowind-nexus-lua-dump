local common = require("mer.darkShard.common")
local CelestialObject = require("mer.darkShard.components.CelestialObject")

local celestialObject = CelestialObject:new{
    id = "AFQ_COMET",
    meshPath = "afq\\afq_comet.nif",
    position = tes3vector3.new(0, 1200, 1200),
    scale = 2
}

---@class DarkShard.Comet
local Comet = {}

function Comet.getCometNode()
    return celestialObject:getNode()
end

function Comet.isEnabled()
    return celestialObject:isEnabled()
end

---@return boolean #True if the comet was enabled, false if it was already enabled
function Comet.enable()
    return celestialObject:enable()
end

---@return boolean #True if the comet was disabled, false if it was already disabled
function Comet.disable()
    return celestialObject:disable()
end

function Comet.isInView()
    local targetVector = tes3vector3.new(0, 0.72, 0.70)
    local maxVariance = 0.01
    local lookDirection = tes3.getPlayerEyeVector()
    local dot = lookDirection:dot(targetVector)
    return dot > 1 - maxVariance
end

return Comet