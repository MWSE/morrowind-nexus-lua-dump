local log = require("leeches.log")
local utils = require("leeches.utils")

local PHYSICS_FPS = 1 / 60

local UP = tes3vector3.new(0, 0, 1)
local DOWN = tes3vector3.new(0, 0, -1)

local SPIN = tes3matrix33.new()
SPIN:toRotationZ(math.rad(120) * PHYSICS_FPS)

---@type table<tes3reference, niNode>
local fallingLeeches = {}


--- Get the falling particle for this vfx effectNode.
---
---@param effectNode niNode
---@return niParticles, niPerParticleData
local function getParticle(effectNode)
    local particles = effectNode:getObjectByName("Particles") --[[@as niParticles]]
    local particle = particles.controller.particleData[1] ---@diagnostic disable-line
    return particles, particle
end


--- Create a vfx consisting of a single falling particle.
---
--- The initial position and velocity are calculated from the given reference.
---
---@param ref tes3reference
local function createLeechVFX(ref)
    local vfx = tes3.createVisualEffect({
        object = "VFX_Leech",
        position = ref.position,
        lifespan = 10,
    })

    -- initial velocity (30 to 60)
    local velocity = utils.rand(30, 60)

    -- upward bias (15% to 30%)
    local bias = utils.rand(0.15, 0.30)
    local direction = ref.rightDirection:lerp(UP, bias)

    -- apply initial particle velocity
    local particles, particle = getParticle(vfx.effectNode)
    local r = particles.worldTransform.rotation:transpose()
    particle.velocity = r * direction * velocity

    return vfx
end


--- Handle expired and falling leeches.
---
local function cleanupReference(ref)
    -- Ignore manually-placed leeches from other mods.
    if ref.sourceMod then
        return
    end

    -- Only interested in references with custom data.
    local data = ref.data
    if data == nil then
        return
    end

    -- Handle expired leeches.
    if data.leech_expireTime then
        if tes3.getSimulationTimestamp() > data.leech_expireTime then
            log:debug("Expired leech detected.")

            ref:disable()
            ref:delete()

            fallingLeeches[ref] = nil
            return false
        end
    end

    -- Handle falling leeches.
    if data.leech_falling then
        data.leech_falling = nil
        log:debug("Suspended leech detected.")

        local rayhit = tes3.rayTest({
            position = ref.position,
            direction = DOWN,
            ignore = { tes3.game.worldPickRoot, tes3.player.sceneNode },
        })
        if rayhit then
            ref.position = rayhit.intersection
        end

        fallingLeeches[ref] = nil
    end
end


--- Handle expired and falling leeches after loading or resting.
---
--- This is done to avoid bloating save files with too many leaches.
---
local function cleanupCells()
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.ingredient) do
            cleanupReference(ref)
        end
    end
end
event.register("loaded", cleanupCells, { priority = -1 })
event.register("calcRestInterrupt", cleanupCells, { priority = -1 })


--- Handle expired and falling leeches after being activated.
---
--- This usually occurs when returning to a previously visited cell.
--- Time may have passed or the vfx expired, so a cleanup is needed.
---
---@param e referenceActivatedEventData
event.register("referenceActivated", function(e)
    cleanupReference(e.reference)
end, { priority = 1e7 })


--- Remove reference data when acquiring leeches so inventory stacking works.
---
event.register("activate", function(e)
    if e.target.supportsLuaData then
        local data = e.target.data
        data.leech_expireTime = nil
        data.leech_falling = nil
    end
end, { priority = -1000 })


--- Stop tracking references if they get deactivated.
---
---@param e referenceDeactivatedEventData
event.register("referenceDeactivated", function(e)
    fallingLeeches[e.reference] = nil
end)


--- Implements leeches visually falling.
---
local function onPhysicsTick()
    for ref, vfxNode in pairs(fallingLeeches) do
        -- Bail if the scene node has been orphaned.
        if vfxNode.parent == nil then
            log:warn("VFX node has been detatched.")
            cleanupReference({ reference = ref })
            return
        end

        -- Get position of gravity-driven particle.
        local particles = vfxNode:getObjectByName("Particles")
        local position = vfxNode.worldTransform * particles.data.vertices[1]

        -- Get orientation with some random spin added.
        local orientation = (SPIN * ref.sceneNode.rotation):toEulerXYZ()

        -- Detect if the reference has collided with the ground.
        local rayhit = tes3.rayTest({
            position = position,
            direction = DOWN,
            ignore = { tes3.game.worldPickRoot, tes3.player.sceneNode },
        })

        -- Assume it is ground level if there was no intersection.
        local intersection = rayhit and rayhit.intersection or position

        -- If close to the ground snap it there and stop tracking.
        if position:distance(intersection) <= 1 then
            position.z = position.z - ref.object.boundingBox.min.z
            ref.data.leech_falling = nil
            fallingLeeches[ref] = nil
        end

        -- Apply updates
        ref.position = position
        ref.orientation = orientation
    end
end
event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = PHYSICS_FPS,
        callback = onPhysicsTick,
    })
end)


---
---

---
--- Public API
---

local this = {}

---@param reference tes3reference
---@param leech Leech
function this.createFallingLeech(reference, leech)
    local sceneNode = leech:getSceneNode(reference)
    if sceneNode == nil then
        return
    end

    -- Save the leeches world transform.
    local t = sceneNode.worldTransform

    -- Don't bother for far away leeches.
    if tes3.getPlayerEyePosition():distance(t.translation) > 4096 then
        return
    end

    -- Create ingredient leech reference.
    local ref = tes3.createReference({
        object = "leech_ingred",
        cell = reference.cell,
        position = t.translation,
        orientation = t.rotation:toEulerXYZ(),
    })

    -- Add a flag indicating this leech is falling.
    ref.data.leech_falling = true

    -- Add a timestamp for when this leech expires.
    ref.data.leech_expireTime = tes3.getSimulationTimestamp() + 12

    -- Create a VFX for gravity falling.
    local vfx = createLeechVFX(ref)

    -- Track the reference with its associated vfx.
    fallingLeeches[ref] = vfx.effectNode
end

return this
