local this = {}

---@diagnostic disable: assign-type-mismatch

local SIMULATION_TIME = require("ffi").cast("float*", 0x7C6708)

local perlin = require("firemoth.utils.perlin")
local px = perlin(2 ^ 4)
local py = perlin(2 ^ 5)
local pz = perlin(2 ^ 6)

--- @param name string
--- @param target niNode|niCamera
local function createAdjuster(name, target)
    local adjuster = target.parent
    if adjuster.name ~= name then
        adjuster = niNode.new()
        adjuster.name = name

        local parent = target.parent
        adjuster:attachChild(target, true)
        parent:attachChild(adjuster, true)
        adjuster:update()
    end
    return adjuster
end
local wc = assert(tes3.worldController)
local cameraAdjuster = createAdjuster("firemoth:cameraAdjuster", wc.worldCamera.cameraData.camera)
local skyAdjuster = createAdjuster("firemoth:skyAdjuster", wc.weatherController.sceneSkyRoot)


local function updatePosition(strength, time)
    local maxHorz = 10
    local maxVert = 5

    local translation = tes3vector3.new(
        maxHorz * strength * px:noise(time) * 2,
        maxHorz * strength * py:noise(time) * 2,
        maxVert * strength * pz:noise(time) * 2
    )

    cameraAdjuster.translation = translation
    cameraAdjuster:update()

    skyAdjuster.translation = translation
    skyAdjuster:update()

    -- TODO: probably need to fix shadow camera also?
end

local inv = cameraAdjuster.worldTransform.rotation:transpose()
local function updateRotation(strength, time)
    local maxHorz = math.rad(10)
    local maxVert = math.rad(10)

    local rot = tes3matrix33.new()
    rot:fromEulerXYZ(
        maxHorz * strength * px:noise(time) * 2,
        maxHorz * strength * py:noise(time) * 2,
        maxVert * strength * pz:noise(time) * 2
    )

    cameraAdjuster.rotation = inv * rot
end

local function update(e)
    local duration, strength = unpack(e.timer.data)
    local remaining = e.timer.iterations * e.timer.duration + e.timer.timeLeft

    local t = 1.0 - remaining / duration
    strength = math.lerp(strength, 0, t)

    local time = SIMULATION_TIME[0]
    updatePosition(strength, time)
    updateRotation(strength, time)
end
timer.register("firemoth:cameraUpdate", update)

local shakeTimer
function this.startCameraShake(duration, strength)
    if shakeTimer and not shakeTimer.expired then
        shakeTimer:cancel()
    end

    local tickRate = 0.005
    shakeTimer = timer.start({
        duration = tickRate,
        iterations = duration / tickRate,
        callback = "firemoth:cameraUpdate",
        data = { duration, strength },
        persist = true,
    })
end

-- Ensure camera is reset when loading a new save file.
event.register(tes3.event.loaded, function()
    updatePosition(0, 0)
    updateRotation(0, 0)
end)

return this
