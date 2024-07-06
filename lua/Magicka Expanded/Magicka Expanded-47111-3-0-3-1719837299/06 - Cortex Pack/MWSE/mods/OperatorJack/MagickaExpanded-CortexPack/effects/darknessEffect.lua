local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("darkness", 263)

local DISTANCE_MULT = 10

local vfxs = {}

local density = {}

local refs = {}

---@class fadeInFogParams
---@field fogId string Fog ID for the fog.
---@field serial number Magic Instance Serial number to identify the fog with.
---@field targetReference tes3reference | nil Optional. The reference's position to track with the fog. Must be provided if targetParameter is not provided.
---@field targetPosition tes3vector3 | nil Optional. The position to track with the fog. Must be provided if targetReference is not provided.
---@field distance number The 
---@field onComplete function Function to call when the fade in is completed.

---@param params fadeInFogParams
local function fadeInFog(params)
    local fogId = params.fogId
    local serial = params.serial
    local targetReference = params.targetReference
    local targetPosition = params.targetPosition
    local distance = params.distance
    local onComplete = params.onComplete

    timer.start({
        duration = .01,
        iterations = 100,
        ---@param e mwseTimerCallbackData 
        callback = function(e)
            local mistDensity = density[serial]

            ---@type fogParams
            local fogParams = {
                color = tes3vector3.new(0, 0, 0),
                center = targetPosition or targetReference and targetReference.position,
                radius = tes3vector3.new(distance, distance, distance),
                density = mistDensity
            }

            framework.vfx.shaders.fog.createOrUpdateFog(fogId, fogParams)
            vfxs[serial] = fogParams

            density[serial] = density[serial] + 1

            framework.log:debug(
                "Fading in darkness fog! Serial %s, Density: %s, Position %s. Timer Iterations: %s",
                serial, density[serial], fogParams.center, e.timer.iterations)

            if (e.timer.iterations == 1) then onComplete() end
        end
    })
end
---@class fadeOutFogParams
---@field fogId string Fog ID for the fog.
---@field serial number Magic Instance Serial number to identify the fog with.
---@field targetReference tes3reference | nil Optional. The reference's position to track with the fog. Must be provided if targetParameter is not provided.
---@field targetPosition tes3vector3 | nil Optional. The position to track with the fog. Must be provided if targetReference is not provided.

---@param params fadeOutFogParams
local function fadeOutFog(params)
    local fogId = params.fogId
    local serial = params.serial
    local targetReference = params.targetReference
    local targetPosition = params.targetPosition

    timer.start({
        duration = .01,
        iterations = 100,
        ---@param e mwseTimerCallbackData 
        callback = function(e)
            density[serial] = density[serial] - 1
            local fogParams = vfxs[serial]
            fogParams.density = density[serial]
            fogParams.center = targetPosition or targetReference and targetReference.position

            framework.vfx.shaders.fog.createOrUpdateFog(fogId, fogParams)

            framework.log:debug(
                "Fading out darkness fog! Serial %s, Density: %s, Position %s. Timer Iterations: %s",
                serial, density[serial], fogParams.center, e.timer.iterations)
        end
    })
    timer.start({
        duration = 1.01,
        iterations = 1,
        callback = function()
            framework.vfx.shaders.fog.deleteFog(fogId)
            vfxs[serial] = nil
            density[serial] = nil
            framework.log:debug("Deleted darkness fog! Serial %s, ", serial, density[serial])
        end
    })

end

---@param e tes3magicEffectCollisionEventData
local function onCollision(e)
    if e.collision then
        local serial = e.sourceInstance.serialNumber
        if (vfxs[serial]) then return end

        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.darkness)

        if (effect == nil) then
            framework.log:error("Unable to find effect in tick event. Logical error?")
            return
        end

        local fogId = "OJ_ME_Darkness" .. serial
        local caster = e.sourceInstance.caster
        local effectDuration = effect.duration
        local distance = framework.functions.getCalculatedMagnitudeFromEffect(effect) *
                             DISTANCE_MULT
        local mistPosition = e.collision.point:copy()

        if (not density[serial]) then
            framework.log:debug("Initializing darkness fog placement.")
            density[serial] = 0
            fadeInFog({
                fogId = fogId,
                serial = serial,
                targetPosition = mistPosition,
                distance = distance,
                onComplete = function()
                    -- Add a mechanic to the darkness.
                    timer.start({
                        duration = 1,
                        callback = function()
                            if (not refs[serial]) then refs[serial] = {} end
                            local actors = framework.functions.getActorsNearTargetPosition(
                                               caster.cell, mistPosition, distance)

                            -- For any actors near the darkness, remove the light effect if it exists.
                            for _, actor in pairs(actors) do
                                tes3.removeEffects({reference = actor, effect = tes3.effect.light})

                                if (not refs[serial][actor]) then

                                    tes3.applyMagicSource({
                                        name = "Dark Blindness",
                                        reference = actor,
                                        effects = {
                                            [0] = {
                                                id = tes3.effect.blind,
                                                rangeType = tes3.effectRange.self,
                                                duration = 5,
                                                min = 10,
                                                max = 20
                                            } ---@type tes3effect
                                        }
                                    })

                                    local result = tes3.triggerCrime({
                                        criminal = caster,
                                        type = tes3.crimeType.attack,
                                        victim = actor
                                    })

                                    refs[serial][actor] = true

                                end

                            end
                        end,
                        iterations = (effectDuration - 1)
                    })

                    timer.start({
                        duration = effectDuration,
                        callback = function()
                            refs[serial] = nil

                            if (density[serial]) then
                                fadeOutFog({
                                    fogId = fogId,
                                    serial = serial,
                                    targetPosition = mistPosition
                                })
                            end

                        end
                    })
                end
            })
        end

    end
end

local tickDensities = {}
---@param e tes3magicEffectTickEventData
local function onTick(e)

    local target = e.effectInstance.target or e.sourceInstance.target or e.sourceInstance.caster
    local serial = e.sourceInstance.serialNumber

    if (target) then
        local serial = e.sourceInstance.serialNumber
        local fogId = "OJ_ME_Darkness" .. serial

        local distance = e.effectInstance.effectiveMagnitude * DISTANCE_MULT

        -- Check if the effect is just starting, or if we're reloading a save game and no longer tracking VFX.
        if (e.effectInstance.state == tes3.spellState.working) then
            if (not tickDensities[serial]) then
                tickDensities[serial] = 0
                timer.start({
                    duration = .01,
                    iterations = 100,
                    ---@param e mwseTimerCallbackData 
                    callback = function(e)
                        tickDensities[serial] = tickDensities[serial] + 1
                    end
                })
            end

            ---@type fogParams
            local fogParams = {
                color = tes3vector3.new(0, 0, 0),
                center = target.position,
                radius = tes3vector3.new(distance, distance, distance),
                density = tickDensities[serial]
            }

            vfxs[serial] = framework.vfx.shaders.fog.createOrUpdateFog(fogId, fogParams)
        end

        if (e.effectInstance.state == tes3.spellState.ending) then
            timer.start({
                duration = .01,
                iterations = 100,
                ---@param e mwseTimerCallbackData 
                callback = function(e)
                    local target = target
                    tickDensities[serial] = tickDensities[serial] - 1

                    ---@type fogParams
                    local fogParams = {
                        color = tes3vector3.new(0, 0, 0),
                        center = target.position,
                        radius = tes3vector3.new(distance, distance, distance),
                        density = tickDensities[serial]
                    }

                    framework.vfx.shaders.fog.createOrUpdateFog(fogId, fogParams)

                    framework.log:debug(
                        "Fading out darkness fog! Serial %s, Density: %s, Position %s. Timer Iterations: %s",
                        serial, tickDensities[serial], fogParams.center, e.timer.iterations)
                end
            })
            timer.start({
                duration = 1.01,
                iterations = 1,
                callback = function()
                    framework.vfx.shaders.fog.deleteFog(fogId)
                    vfxs[serial] = nil
                    tickDensities[serial] = nil
                    framework.log:debug("Deleted darkness fog! Serial %s, ", serial,
                                        tickDensities[serial])
                end
            })
        end
    else
        framework.log:error("Invalid target! Target not found.")
    end

    -- Trigger into the spell system.
    if (not e:trigger()) then return end
end

local VFX_BOLT_PATH = "OJ\\ME\\cp\\vfx_darkness_bolt.nif"
local VFX_CAST_PATH = "OJ\\ME\\cp\\vfx_darkness_cast.nif"

local vfxBolt = tes3.createObject({
    id = "oj_me_vfx_darkness_bolt",
    objectType = tes3.objectType.weapon,
    mesh = VFX_BOLT_PATH,
    type = tes3.weaponType.arrow
})
---@cast vfxBolt tes3weapon

local vfxCast = tes3.createObject({
    id = "oj_me_vfx_darkness_cast",
    objectType = tes3.objectType.static,
    mesh = VFX_CAST_PATH
})
---@cast vfxCast tes3static

framework.effects.illusion.createBasicEffect({
    -- Base information.
    id = tes3.effect.darkness,
    name = "Darkness",
    description = "Create a sphere of darkness around the target, negating any lights and blinding those within.",

    -- Basic dials.
    baseCost = 3.0,

    -- Various flags.
    allowEnchanting = true,
    allowSpellmaking = true,
    canCastTarget = true,
    canCastTouch = true,
    canCastSelf = true,
    unreflectable = false,
    usesNegativeLighting = true,
    isHarmful = true,
    nonRecastable = false,

    -- Graphics/sounds.
    icon = "RFD\\RFD_lf_darkness.dds",
    particleTexture = "OJ\\ME\\cp\\particle_black.dds",
    boltVFX = vfxBolt,
    areaVFX = framework.data.ids.objects.static.vfxEmpty,
    hitVFX = framework.data.ids.objects.static.vfxEmpty,
    castVFX = vfxCast,
    lighting = {0, 0, 0},

    -- Required callbacks.
    onTick = onTick,
    onCollision = onCollision
})

