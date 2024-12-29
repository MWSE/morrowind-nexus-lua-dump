tes3.claimSpellEffectId("frostAura", 24013)

local fireAuraEffect

-- There's got to be a better way! Unfortunely, I do not know it.
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
                tickParams:trigger({
                    type = tes3.effectEventType.modStatistic,
                    -- The resistance attribute against Fire Damage should be Resist Fire
                    attribute = tes3.effectAttribute.resistFrost,
                    
                    -- The variable this effect affects
                    value = nearbyActorHealth,
                    negateOnExpiry = false,
                    isUncapped = true,
                })
                -- Does create an effect around hit targets... but they don't quite look right.
                local vfx = tes3.createVisualEffect ({reference = nearbyActor.reference, object = "VFX_FrostHit", lifespan = 1})
                -- local executed = tes3.playSound ({sound = "frost_hit", reference = nearbyActor.reference, volume = 0.5})
            end
        end
    end
    tickParams:trigger({})
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        -- Base information.
        id = tes3.effect.frostAura,
        name = "Frost Aura",
        description = ("Surrounds the target in a storm of elemental forces, inflicting frost damage in a small radius that follows the target. Only damages those hostile to the target. Magnitude affects both the amount of damage dealt, and the size of the radius."),
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

        icon = "IB\\IB_s_frost_aura.tga",
        particleTexture = "vfx_alpha_steam00.tga",
        hitVFX = "VFX_FrostShield",
        hitSound = "alteration hit",
        castSound = "alteration cast",
        castVFX = "VFX_FrostCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_FrostBolt",
        areaSound = "frost area",
        areaVFX = "VFX_FrostArea",
        lighting = { x = 0.87, y = 0.82, z = 0.85 },
        usesNegativeLighting = false,

        onTick = onFireAuraTick
    })
end)