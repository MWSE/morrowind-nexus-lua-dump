-- copilot

local ui = require("openmw.ui")
local core = require("openmw.core")
local camera = require("openmw.camera")
local util = require("openmw.util")

local perlin = require("scripts.Red Mountain Tremors OpenMW.perlin")
local px = perlin(2 ^ 4)
local py = perlin(2 ^ 5)
local pz = perlin(2 ^ 6)

local function updateRotation(strength, time)
    local maxHorz = math.rad(0.2)
    local maxVert = math.rad(0.2)

    local jitter = (math.random() - 0.5) * 0.2

    local x = maxHorz * strength * 1.2 * (px:noise(time) + jitter) * 2
    local y = maxHorz * strength * 0.8 * (py:noise(time) + jitter) * 2
    local z = maxVert * strength * 1.5 * (pz:noise(time) + jitter) * 2

    camera.setExtraYaw(x)
    camera.setExtraPitch(y)
    camera.setRoll(z)
end

local function updatePosition(strength, time)
    local maxHorz = 0.2
    local maxVert = 0.2

    local jitter = (math.random() - 0.5) * 0.2

    local x = maxHorz * strength * 1.1 * (px:noise(time) + jitter) * 2
    local y = maxHorz * strength * 0.9 * (py:noise(time) + jitter) * 2
    local z = maxVert * strength * 1.3 * (pz:noise(time) + jitter) * 2

    camera.setFirstPersonOffset(util.vector3(x, y, z))
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
        tremors_dm_k_qk_shake = function(args)
            duration, strength = unpack(args)
            remaining = duration
        end
    },
    engineHandlers = {
        onUpdate = function(dt)
            if remaining <= 0 then
                return
            end

            remaining = remaining - dt

            local t = smoothstep(0, 1, math.abs(2 * remaining / duration - 1))
            -- el 7 es el valor default de strength, anteriormente usada aqui
            local s = lerp(7, 0, t) 

            -- Picos de intensidad aleatorios
            if math.random() < 0.1 then
                s = s * 1.5
            end

            local intensityScale = 1 / math.max(1, strength)
            local adjustedStrength = math.max(0.01, s * intensityScale)

            local time = core.getSimulationTime() * 5  -- frecuencia aumentada

            updateRotation(adjustedStrength, time * 1.3)  -- desincronizado
            updatePosition(adjustedStrength, time * 0.7)
        end,
    }
}
