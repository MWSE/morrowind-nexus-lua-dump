local utils = require("firemoth.utils")

local MIN_DISTANCE = 8192 * 1.5
local MAX_DISTANCE = 8192 * 3.5

local shader = assert(mge.shaders.load({ name = "fm_tonemap" }))
shader.fogColor = tes3vector3.new(0.5, 0.0, 0.2)
shader.enabled = false

local exposure = 0.0
local saturation = -0.050
local defog = 0.1

local function toggleShader(enabled)
    if shader.enabled ~= enabled then
        shader.enabled = enabled
    end
end

local prevUpdate = 0
local function updateColors(dist)
    local f = math.clamp(dist, MIN_DISTANCE, MAX_DISTANCE)
    f = math.remap(f, MIN_DISTANCE, MAX_DISTANCE, 1.0, 0.0)
    if not math.isclose(f, prevUpdate, 0.001) then
        shader.exposure = exposure * f
        shader.saturation = saturation * f
        shader.defog = defog * f
    end
    prevUpdate = f
end

local function update(e)
    local currDist = utils.cells.getFiremothDistance()
    local prevDist = e.timer.data.prevDist or currDist
    if math.min(currDist, prevDist) <= MAX_DISTANCE
        and not math.isclose(currDist, prevDist, 0.001)
    then
        toggleShader(currDist <= MAX_DISTANCE)
        updateColors(currDist)
    end
    e.timer.data.prevDist = currDist
end
event.register(tes3.event.loaded, function()
    timer.start({
        iterations = -1,
        duration = 1 / 10,
        callback = update,
        data = { prevDist = -1 },
    })
end)
