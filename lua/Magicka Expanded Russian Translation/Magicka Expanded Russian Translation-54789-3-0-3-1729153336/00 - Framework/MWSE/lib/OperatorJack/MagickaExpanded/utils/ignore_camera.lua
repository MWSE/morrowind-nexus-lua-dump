local this = {}

local perlin = require("OperatorJack.MagickaExpanded.utils.perlin")
local px = perlin(2 ^ 4)
local py = perlin(2 ^ 5)
local pz = perlin(2 ^ 6)

--- Create an "adjuster" node that we can manipulate to shake our camera.
--- This is needed because the engine overwrites the camera's transforms every frame.
---@param name string
---@param node niNode|niCamera
local function createAdjuster(name, node)
    -- If an adjuster with this name already exists, return it.
    local adjuster = node.parent
    while adjuster and adjuster.name ~= name do adjuster = adjuster.parent end
    -- Otherwise, create a new one inbetween the node and its parent.
    if adjuster == nil then
        adjuster = niNode.new()
        adjuster.name = name
        local parent = node.parent
        adjuster:attachChild(node, true)
        parent:attachChild(adjuster, true)
        adjuster:update()
    end
    return adjuster
end
local wc = assert(tes3.worldController)
local skyAdjuster = createAdjuster("magickaExpanded:skyAdjuster", wc.weatherController.sceneSkyRoot)
local cameraAdjuster = createAdjuster("magickaExpanded:cameraAdjuster",
                                      wc.worldCamera.cameraData.camera)
local shadowAdjuster = createAdjuster("magickaExpanded:shadowAdjuster",
                                      wc.shadowCamera.cameraData.camera)

local function updatePosition(strength, time)
    -- maximum horizontal/vertical offsets
    local maxHorz = 10
    local maxVert = 5

    local translation = tes3vector3.new(maxHorz * strength * px:noise(time) * 2,
                                        maxHorz * strength * py:noise(time) * 2,
                                        maxVert * strength * pz:noise(time) * 2)

    cameraAdjuster.translation = translation
    cameraAdjuster:update()

    shadowAdjuster.translation = translation
    shadowAdjuster:update()

    skyAdjuster.translation = (cameraAdjuster.worldTransform.translation -
                                  tes3.getPlayerEyePosition())
    skyAdjuster:update()
end

local function updateRotation(strength, time)
    -- maximum horizontal/vertical angles
    local maxHorz = math.rad(10)
    local maxVert = math.rad(10)

    local rotation = tes3matrix33.new()
    rotation:fromEulerXYZ(maxHorz * strength * px:noise(time) * 2,
                          maxHorz * strength * py:noise(time) * 2,
                          maxVert * strength * pz:noise(time) * 2)

    cameraAdjuster.rotation = rotation
    shadowAdjuster.rotation = rotation
end

local function smoothstep(a, b, t)
    local x = math.max(0, math.min(1, (t - a) / (b - a)))
    return x * x * (3 - 2 * x)
end

local function update(e)
    local duration, strength = unpack(e.timer.data)
    local remaining = e.timer.iterations * e.timer.duration + e.timer.timeLeft

    -- Calculate the shake strength as a function of the remaining time
    local t = smoothstep(0, 1, math.abs(2 * remaining / duration - 1))
    strength = math.lerp(strength, 0, t)

    local time = tes3.getSimulationTimestamp(false)
    updateRotation(strength, time)
    updatePosition(strength, time)

    cameraAdjuster:update()
    shadowAdjuster:update()
    skyAdjuster:update()
end
timer.register("magickaExpanded:update", update)

---@type mwseTimer
local shakeTimer

---@param duration number
---@param strength number
function this.startCameraShake(duration, strength)
    -- How often the camera updates (in secs).
    local tickRate = 0.005

    -- Cancel any existing pre-existing shake.
    if shakeTimer then shakeTimer:cancel() end

    shakeTimer = timer.start({
        duration = tickRate,
        iterations = duration / tickRate,
        callback = "magickaExpanded:update",
        data = {duration, strength},
        persist = true
    })
end

-- Ensure camera is reset when loading a new save file.
event.register(tes3.event.loaded, function()
    updateRotation(0, 0)
    updatePosition(0, 0)
end)

return this
