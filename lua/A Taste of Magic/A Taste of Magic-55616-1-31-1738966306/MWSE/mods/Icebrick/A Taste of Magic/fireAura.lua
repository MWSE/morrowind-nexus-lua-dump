tes3.claimSpellEffectId("fireAura", 24002)

local fireAuraEffect

-- This cannot be ideal.
---@param tickParams tes3magicEffectTickEventData
local function onFireAuraTick(tickParams)
    local target = tickParams.effectInstance.target
    local mobileList = tes3.findActorsInProximity({reference = target, range = 190 + tickParams.effectInstance.magnitude})
    local hostileList = target.mobile.hostileActors
    for i = 1, #mobileList do
        for k = 1, #hostileList do
            if mobileList[i].object.id == hostileList[k].object.id then
                local nearbyActor = mobileList[i]
                local nearbyActorHealth = mobileList[i].health
                local damage = tickParams.effectInstance.magnitude/60
                --Creates the visual effect. Doesn't actually work right now..
                -- tes3.applyMagicSource({
                    -- reference = nearbyActor.reference,
                    -- name = "Fire Aura Damage",
                    --effects = {{
                    --    id = tes3.effect.fireDamage,
                    --    duration = 5,
                    --    min = 0,
                    --    max = 0,
                    -- }},
                    -- bypassResistances = false})
                tickParams:trigger({
                    type = tes3.effectEventType.modStatistic,
                    -- The resistance attribute against Fire Damage should be Resist Fire
                    attribute = tes3.effectAttribute.resistFire,
                    
                    -- The variable this effect affects
                    value = nearbyActorHealth,
                    negateOnExpiry = false,
                    isUncapped = true,
                })
                -- Does create an effect around hit targets... but they don't quite look right.
                local vfx = tes3.createVisualEffect ({reference = nearbyActor.reference, object = "VFX_DestructHit", lifespan = 1})
                -- local executed = tes3.playSound ({sound = "destruction hit", reference = nearbyActor.reference, volume = 0.5})
            end
        end
    end
    tickParams:trigger({})
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.fireAura,
        name = "Fire Aura",
        description = ("Surrounds the target in a storm of elemental forces, inflicting fire damage in a small radius that follows the target. Only damages those hostile to the target. Magnitude affects both the amount of damage dealt, and the size of the radius."),
        school = tes3.magicSchool.destruction,

        baseCost = 7.0,

        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = false,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        hasNoDuration = false,
        hasNoMagnitude = false,
        nonRecastable = false,
        unreflectable = false,
        isHarmful = false,
        hasContinuousVFX = true,
        targetsAttributes = false,
        targetsSkills = false,

        icon = "IB\\IB_s_fire_aura.tga",
        particleTexture = "vfx_firealpha00A.tga",
        hitVFX = "VFX_FireShield",
        hitSound = "alteration hit",
        castSound = "alteration cast",
        castVFX = "VFX_DestructCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_DestructBolt",
        areaSound = "alteration area",
        areaVFX = "VFX_DestructArea",
        lighting = { x = 0.99, y = 0.26, z = 0.53 },
        usesNegativeLighting = false,

        onTick = onFireAuraTick
    })
end)