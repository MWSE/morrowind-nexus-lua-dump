tes3.claimSpellEffectId("pierce", 24005)

---@param tickParams tes3magicEffectTickEventData
local function pierceTick(tickParams)
    -- This does nothing. It's all in the magicReflect event.
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
        tes3.addMagicEffect({
        id = tes3.effect.pierce,
        name = "Pierce",
        description = ("When part of a spell, gives it a chance to ignore spell reflection effects. This chance is equal to the magnitude. Whether this effect is self, touch, or target has no effect."),
        school = tes3.magicSchool.mysticism,

        baseCost = 5.0,

        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = false,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        hasNoDuration = true,
        hasNoMagnitude = false,
        nonRecastable = false,
        unreflectable = false,
        isHarmful = false,
        hasContinuousVFX = false,
        targetsAttributes = false,
        targetsSkills = false,

        icon = "IB\\IB_s_pierce.tga",
        particleTexture = "vfx_myst_flare01.tga",
        size = 1.25,
        sizeCap = 50,
        lighting = {0.83, 0.92, 0.97},
        usesNegativeLighting = false,
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",

        onTick = pierceTick
    })
end)
