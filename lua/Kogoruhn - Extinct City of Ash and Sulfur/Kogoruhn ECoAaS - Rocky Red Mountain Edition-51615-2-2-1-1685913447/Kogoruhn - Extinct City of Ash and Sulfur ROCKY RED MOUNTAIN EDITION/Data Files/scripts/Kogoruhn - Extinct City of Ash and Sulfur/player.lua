local ui = require("openmw.ui")
local core = require("openmw.core")
local camera = require("openmw.camera")
local util = require("openmw.util")

local perlin = require("scripts.Kogoruhn - Extinct City of Ash and Sulfur.perlin")
local px = perlin(2 ^ 4)
local py = perlin(2 ^ 5)
local pz = perlin(2 ^ 6)

local function updateRotation(strength, time)
    -- maximum horizontal/vertical angles
    local maxHorz = math.rad(10)
    local maxVert = math.rad(10)

    local x = maxHorz * strength * px:noise(time) * 2
    local y = maxHorz * strength * py:noise(time) * 2
    local z = maxVert * strength * pz:noise(time) * 2

    camera.setExtraYaw(x)
    camera.setExtraPitch(y)
    camera.setRoll(z)
end

local function updatePosition(strength, time)
    -- maximum horizontal/vertical offsets
    local maxHorz = 20
    local maxVert = 10

    local x = maxHorz * strength * px:noise(time) * 2
    local y = maxHorz * strength * py:noise(time) * 2
    local z = maxVert * strength * pz:noise(time) * 2

    camera.setFirstPersonOffset(util.vector3(x, y, z))
    -- camera.setFocalPreferredOffset(util.vector2(x, y))
end

local function smoothstep(a, b, t)
    local x = math.max(0, math.min(1, (t - a) / (b - a)))
    return x * x * (3 - 2 * x)
end

local function lerp(a, b, t)
    return a + t * (b - a)
end

local duration = 0.0
local strength = 0.0
local remaining = 0.0

return {
    eventHandlers = {
        dm_k_qk_shake = function(args)
            duration, strength = unpack(args)
            -- ui.showMessage(string.format("duration: %.2f, strength: %.2f", duration, strength))
            remaining = duration
        end
    },
    engineHandlers = {
        onUpdate = function(dt)
            if remaining <= 0 then
                return
            end

            remaining = remaining - dt

            -- Calculate shake strength as a function of the remaining time
            local t = smoothstep(0, 1, math.abs(2 * remaining / duration - 1))
            local s = lerp(strength, 0, t)

            local time = core.getSimulationTime()
            updateRotation(s, time)
            updatePosition(s, time)
        end,
    }
}
