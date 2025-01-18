tes3.claimSpellEffectId("haste", 24011)

---@param tickParams tes3magicEffectTickEventData
local function hasteTick(tickParams)
    -- Handled in attackStart
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
        tes3.addMagicEffect({
        id = tes3.effect.haste,
        name = "Haste",
        description = ("Increases how fast a weapon attacks."),
        schoool = tes3.magicSchool.alteration,

        baseCost = 8,

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
        hasContinuousVFX = false,
        targetsAttributes = false,
        targetsSkills = false,

        icon = "IB\\IB_s_haste.tga",
        particleTexture = "vfx_alt_glow.tga",
        castSound = "alteration cast",
        castVFX = "VFX_AlterationCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_AlterationBolt",
        hitSound = "alteration hit",
        hitVFX = "VFX_AlterationHit",
        areaSound = "alteration area",
        areaVFX = "VFX_AlterationArea",
        lighting = { x = 0.76, y = 0.44, z = 0.88 },
        usesNegativeLighting = false,

        onTick = hasteTick
    })
end)
