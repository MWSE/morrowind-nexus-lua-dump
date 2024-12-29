tes3.claimSpellEffectId("quicken", 24006)

---@param tickParams tes3magicEffectTickEventData
local function quickenTick(tickParams)
    -- Events are in spellMagickaUseEvent
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
        tes3.addMagicEffect({
        id = tes3.effect.quicken,
        name = "Quicken",
        description = ("When part of a spell, makes it cast faster. A higher magnitude increases the speed. Whether this effect is self, touch, or target affects only visuals."),
        school = tes3.magicSchool.mysticism,

        baseCost = 3.0,

        allowEnchanting = false,
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

        icon = "IB\\IB_s_quicken.tga",
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

        onTick = quickenTick
    })
end)