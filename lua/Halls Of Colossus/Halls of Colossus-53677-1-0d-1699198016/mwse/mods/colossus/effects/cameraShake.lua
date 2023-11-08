local perlin = require("colossus.effects.perlin")
local px = perlin(2 ^ 4)
local py = perlin(2 ^ 5)
local pz = perlin(2 ^ 6)

local function calcTranslation(intensity, time)
    -- maximum horizontal/vertical offsets
    local maxHorz = 10
    local maxVert = 5

    local translation = tes3vector3.new(
        maxHorz * intensity * px:noise(time) * 2,
        maxHorz * intensity * py:noise(time) * 2,
        maxVert * intensity * pz:noise(time) * 2
    )

    return translation
end

local function calcRotation(intensity, time)
    -- maximum horizontal/vertical angles
    local maxHorz = math.rad(5)
    local maxVert = math.rad(5)

    local rotation = tes3matrix33.new()
    rotation:fromEulerXYZ(
        maxHorz * intensity * px:noise(time) * 2,
        maxHorz * intensity * py:noise(time) * 2,
        maxVert * intensity * pz:noise(time) * 2
    )

    return rotation
end

local function smoothstep(a, b, t)
    local x = math.max(0, math.min(1, (t - a) / (b - a)))
    return x * x * (3 - 2 * x)
end

local START_TIME = 0.0
local INTENSITY = 0.0
local DURATION = 0.0

---@param e cameraControlEventData
local function update(e)
    local time = tes3.getSimulationTimestamp(false)
    local elapsed = time - START_TIME

    if elapsed > DURATION then
        event.unregister(tes3.event.cameraControl, update)
        return
    end

    -- Transition from (0.0 -> 1.0 -> 0.0) over the duration.
    local f = smoothstep(0, 1, math.abs(2 * elapsed / DURATION - 1))
    local intensity = math.lerp(INTENSITY, 0, f)

    local t = e.cameraTransform
    t.translation = t.translation + calcTranslation(0.5, time)
    t.rotation = t.rotation * calcRotation(0.5, time)
end
event.register(tes3.event.loaded, function()
    event.unregister(tes3.event.cameraControl, update)
end)

--[[
    LUA API
--]]
local this = {}

---@class cameraShakeParams
---@field intensity number
---@field duration number

---@param params cameraShakeParams
function this.start(params)
    START_TIME = tes3.getSimulationTimestamp(false)
    INTENSITY = params.intensity
    DURATION = params.duration
    event.register(tes3.event.cameraControl, update)
end

function this.stop()
    START_TIME = 0.0
    INTENSITY = 0.0
    DURATION = 0.0
    event.unregister(tes3.event.cameraControl, update)
end

return this
