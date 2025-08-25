--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.3.1
]]--

local LoopablePerlinNoise = {}

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
    local j = math.random(i + 1) - 1
    perm[i], perm[j] = perm[j], perm[i]
end
for i = 0, 255 do perm[i + 256] = perm[i] end

-- Perlin noise function
local function perlin2D(x, y)
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256
    local xf = x - math.floor(x)
    local yf = y - math.floor(y)

    local u = fade(xf)
    local v = fade(yf)

    local aa = grad(perm[(xi    + perm[yi   ]) % 256], xf,     yf)
    local ab = grad(perm[(xi    + perm[yi+1]) % 256], xf,     yf-1)
    local ba = grad(perm[(xi+1  + perm[yi   ]) % 256], xf-1,   yf)
    local bb = grad(perm[(xi+1  + perm[yi+1]) % 256], xf-1,   yf-1)

    local result = lerp(lerp(aa, ba, u), lerp(ab, bb, u), v)

    return (result + 1) / 2
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
        angleStrip[i] = (i / numSamples) * 2 * math.pi
    end
end

-- Live sampling with dynamic scale/amplitude
function LoopablePerlinNoise.sample(timeOffset, config)
    local t = (timeOffset % loopDuration) / loopDuration
    local index = math.floor(t * numSamples)
    local nextIndex = (index + 1) % numSamples
    local alpha = (t * numSamples) % 1

    local angle1 = angleStrip[index]
    local angle2 = angleStrip[nextIndex]

    local x1 = math.cos(angle1) * config.noiseScale
    local y1 = math.sin(angle1) * config.noiseScale
    local x2 = math.cos(angle2) * config.noiseScale
    local y2 = math.sin(angle2) * config.noiseScale

    local n1 = perlin2D(x1, y1) * config.noiseAmplitude
    local n2 = perlin2D(x2, y2) * config.noiseAmplitude

    return lerp(n1, n2, alpha)
end

-- Optional dual-axis sampling with phase offset
function LoopablePerlinNoise.sampleOffset(timeOffset, offsetRatio, config)
    local shiftedTime = timeOffset + loopDuration * offsetRatio
    return LoopablePerlinNoise.sample(shiftedTime, config)
end

return LoopablePerlinNoise