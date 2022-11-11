local camera = require("firemoth.weather.camera")
local utils = require("firemoth.utils")

local this = {}

local VFX_EXPLODE = assert(tes3.getObject("fm_lightn_expl_vfx")) ---@cast VFX_EXPLODE tes3static
local VFX_EXPLODE_DURATION = 0.20

local VFX_EXPLODE_LIGHT = assert(tes3.getObject("fm_lightn_expl_lit")) ---@cast VFX_EXPLODE_LIGHT tes3light
local VFX_CHILDREN_COUNT = 4

local VFX_STRIKE = assert(tes3.getObject("fm_lightn_strike_vfx")) ---@cast VFX_STRIKE tes3static
local VFX_STRIKE_DURATION = 0.15

local UP = tes3vector3.new(0, 0, 1)
local SIMULATION_TIME = require("ffi").cast("float*", 0x7C6708)

local THUNDER_SOUNDS = {}
local DISTANT_THUNDER_SOUNDS = {}
for i = 1, 6 do
    table.insert(THUNDER_SOUNDS, tes3.getSound("tew_fm_thunder" .. i))
    table.insert(DISTANT_THUNDER_SOUNDS, tes3.getSound("tew_fm_thunderdist" .. i))
end

local randomThunderSound = utils.math.nonRepeatTableRNG(THUNDER_SOUNDS)
local randomDistantThunderSound = utils.math.nonRepeatTableRNG(DISTANT_THUNDER_SOUNDS)

local function toggleThunderSounds(enabled)
    mwse.memory.writeByte({ address = 0x44CC99, byte = enabled and 0x84 or 0x85 }) ---@diagnostic disable-line
end

function this.createLightningFlash()
    local weather = tes3.getCurrentWeather()
    if weather and weather.index == tes3.weather.thunder then
        local f = weather.thunderFrequency
        weather.thunderFrequency = 1e+6
        toggleThunderSounds(false)
        timer.delayOneFrame(function()
            weather.thunderFrequency = f
            toggleThunderSounds(true)
        end)
    end
end

---@param position tes3vector3
---@param direction tes3vector3
---@param scale number
---@param curveDir tes3vector3
function this.createExplosionVFX(position, direction, scale, curveDir)
    local rayhit = tes3.rayTest({
        position = position,
        direction = direction,
        maxDistance = 1024,
        root = tes3.game.worldObjectRoot,
        ignore = { tes3.player },
    })

    local distance = rayhit and rayhit.distance
    local intersection = rayhit and rayhit.intersection

    -- if we didn't hit any object, use some randomized intersection
    if not (distance and intersection) then
        distance = math.random(256, 1024)
        intersection = position + direction * distance
    end

    -- center point of the lightning, bias this upwards so we curve
    local curveCenter = position + direction * (distance / 3)
    local curveUpward = curveCenter + curveDir * (distance / 6)

    local vfx = tes3.createVisualEffect({
        object = VFX_EXPLODE,
        lifespan = VFX_EXPLODE_DURATION,
        position = position,
    })
    local sceneNode = vfx.effectNode
    sceneNode.scale = scale

    -- controls the lightning strikes "grow" animation
    local anim = sceneNode:getObjectByName("Animation")
    anim.scale = distance

    -- controls the mid point of the lightning strike
    local bone2 = sceneNode:getObjectByName("2") ---@cast bone2 niNode
    utils.math.setWorldTranslation(bone2, curveUpward)

    -- controls the end point of the lightning strike
    local bone3 = sceneNode:getObjectByName("3") ---@cast bone3 niNode
    utils.math.setWorldTranslation(bone3, intersection)

    -- controls which lightning texture is used
    local switch = sceneNode:getObjectByName("LightningSwitch")
    switch.switchIndex = math.random(0, VFX_CHILDREN_COUNT - 1)

    -- ensure controllers start from beginning
    local phase = -SIMULATION_TIME[0]
    anim.children[1].controller.phase = phase
end

---@param position tes3vector3
function this.createLightningSound(position)
    local clip = 8192 * 2
    local dist = tes3.getPlayerEyePosition():distance(position)
    local volume = math.remap(math.min(dist, clip), 0, clip, 0.8, 0.3)

    if volume < 0.5 then
        tes3.playSound({
            sound = randomDistantThunderSound(),
            reference = tes3.player,
            volume = volume + 0.3,
            mixChannel = tes3.soundMix.master,
        })
    else
        tes3.playSound({
            sound = randomThunderSound(),
            reference = tes3.player,
            volume = volume,
            mixChannel = tes3.soundMix.master,
        })
    end
end

---@param position tes3vector3
function this.createLightningLight(position)
    for _, cell in ipairs(tes3.getActiveCells()) do
        if cell:isPointInCell(position.x, position.y) then
            local modified = cell.modified
            local light = tes3.createReference({ object = VFX_EXPLODE_LIGHT, position = position, cell = cell })
            light.modified = false
            cell.modified = modified
            return light
        end
    end
end

---@param position tes3vector3
function this.createLightningExplosion(position)
    -- avoid intersections inside mesh geometry
    position = position + UP * 32

    -- spawn multiple vfx objects
    for _ = 1, math.random(3, 12) do
        local direction = utils.math.getRandomRotation(70, 70, 360) * UP
        local scale = (math.random() + 1.0) * 0.75 -- random(0.75, 1.5)
        this.createExplosionVFX(position, direction, scale, UP)
    end
end

---@param position tes3vector3
---@param strength number|nil
---@param explode boolean|nil
function this.createLightningStrike(position, strength, explode)
    local vfx = tes3.createVisualEffect({
        object = VFX_STRIKE,
        lifespan = VFX_STRIKE_DURATION + VFX_EXPLODE_DURATION,
        position = position,
    })
    local sceneNode = vfx.effectNode

    -- controls which lightning texture is used
    local switch = sceneNode:getObjectByName("LightningSwitch")
    local randIndex = math.random(1, VFX_CHILDREN_COUNT)
    local nextIndex = (randIndex + math.random(0, 2)) % VFX_CHILDREN_COUNT + 1

    local s1 = switch.children[randIndex]
    local s2 = switch.children[nextIndex]

    local c1 = switch.controller
    local c2 = c1.nextController
    local c3 = c2.nextController
    local c4 = c3.nextController

    local phase = -SIMULATION_TIME[0]

    c1:setTarget(s1)
    c1.phase = phase
    c1.active = true

    c2:setTarget(s2)
    c2.phase = phase
    c2.active = true

    c3:setTarget(s1)
    c3.phase = phase
    c3.active = true

    c4:setTarget(s2)
    c4.phase = phase
    c4.active = true

    if explode ~= false then
        timer.start({
            duration = VFX_STRIKE_DURATION,
            iterations = 1,
            callback = function()
                this.createLightningExplosion(position)
                this.createLightningSound(position)
                this.createLightningLight(position)
                this.createLightningFlash()
                camera.startCameraShake(--[[duration]] 2.0, --[[strength]] strength or 1.0)
            end,
        })
    end
end

return this
