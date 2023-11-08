local log = require("colossus.log")

local this = {}

---@param min number
---@param max number
---@return number
function this.uniform(min, max)
    return min + (max - min) * math.random()
end

---@return mgeShaderHandle?
function this.getShader(name)
    local shader = mge.shaders.load({ name = name })
    if shader == nil then
        log:error("Failed to load shader: %s", name)
    end
    return shader
end

---@param hour number
function this.setCurrentHour(hour)
    tes3.advanceTime({
        hours = (24 - tes3.worldController.hour.value + hour) % 24,
        resting = false,
        updateEnvironment = false,
    })
end

return this
