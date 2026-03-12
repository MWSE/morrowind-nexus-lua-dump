--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.7
]]--

local LoopablePerlinNoise = {}

-- Localized math functions for faster access
local math_floor = math.floor
local math_random = math.random
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi

-- Utilities
local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(a, b, alpha)
    return a + (b - a) * alpha
end

-- Gradient directions
local grad2 = {
    {1, 1}, {-1, 1}, {1, -1}, {-1, -1},
    {1, 0}, {-1, 0}, {0, 1}, {0, -1}
}

local function grad(hash, x, y)
    local g = grad2[hash % #grad2 + 1]
    return g[1] * x + g[2] * y
end

-- Permutation table
local perm = {}
for i = 0, 255 do perm[i] = i end
for i = 255, 1, -1 do
    local j = math_random(i + 1) - 1
    perm[i], perm[j] = perm[j], perm[i]
end
for i = 0, 255 do perm[i + 256] = perm[i] end

-- Perlin noise function
local function perlin2D(x, y)
    local xi = math_floor(x) % 256
    local yi = math_floor(y) % 256
    local xf = x - math_floor(x)
    local yf = y - math_floor(y)

    local u = fade(xf)
    local v = fade(yf)

    local pyi = perm[yi]
    local pyi1 = perm[yi + 1]

    local aa = grad(perm[xi + pyi], xf, yf)
    local ab = grad(perm[xi + pyi1], xf, yf - 1)
    local ba = grad(perm[xi + 1 + pyi], xf - 1, yf)
    local bb = grad(perm[xi + 1 + pyi1], xf - 1, yf - 1)

    local result = lerp(lerp(aa, ba, u), lerp(ab, bb, u), v)

    return (result + 1) * 0.5
end

-- Loop settings and angle strip
local angleStrip = {}
local loopDuration = 2
local numSamples = 256

-- Configure loop settings
function LoopablePerlinNoise.configure(options)
    loopDuration = options.loopDuration or loopDuration
    numSamples = options.numSamples or numSamples

    angleStrip = {}
    for i = 0, numSamples - 1 do
        local angle = (i / numSamples) * 2 * math_pi
        angleStrip[i] = { cos = math_cos(angle), sin = math_sin(angle) }
    end
end

-- Live sampling with dynamic scale/amplitude
function LoopablePerlinNoise.sample(timeOffset, config)
    local t = (timeOffset % loopDuration) / loopDuration
    local index = math_floor(t * numSamples)
    local nextIndex = (index + 1) % numSamples
    local alpha = (t * numSamples) % 1

    local strip1 = angleStrip[index]
    local strip2 = angleStrip[nextIndex]
    local scale = config.noiseScale
    local amp = config.noiseAmplitude

    local n1 = perlin2D(strip1.cos * scale, strip1.sin * scale) * amp
    local n2 = perlin2D(strip2.cos * scale, strip2.sin * scale) * amp

    return lerp(n1, n2, alpha)
end

-- Optional dual-axis sampling with phase offset
function LoopablePerlinNoise.sampleOffset(timeOffset, offsetRatio, config)
    local shiftedTime = timeOffset + loopDuration * offsetRatio
    return LoopablePerlinNoise.sample(shiftedTime, config)
end

return LoopablePerlinNoise