tes3.claimSpellEffectId("resistBludgeoning", 24018)
tes3.claimSpellEffectId("resistCutting", 24019)
tes3.claimSpellEffectId("resistPiercing", 24020)

---@param tickParams tes3magicEffectTickEventData
local function resistBludgeoningTick(tickParams)
    tickParams:trigger({
        
    })
end

---@param tickParams tes3magicEffectTickEventData
local function resistCuttingTick(tickParams)
    tickParams:trigger({
        
    })
end

---@param tickParams tes3magicEffectTickEventData
local function resistPiercingTick(tickParams)
    tickParams:trigger({
        
    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.resistBludgeoning,
    name = "Resist Bludgeoning",
    description = ("Decreases the damage the target takes from bludgeoning attacks. This includes most blunt weapons, and hand-to-hand attacks. Only applies to unarmed attacks and attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.restoration,

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

    icon = "IB\\IB_s_resist_bludgeoning.tga",
    particleTexture = "vfx_bluecloud.tga",
    castSound = "restoration cast",
    castVFX = "VFX_RestorationCast",
    boltSound = "restoration bolt",
    boltVFX = "VFX_RestoreBolt",
    hitSound = "restoration hit",
    hitVFX = "VFX_RestorationHit",
    areaSound = "restoration area",
    areaVFX = "VFX_RestorationArea",
    lighting = { x = 0.5, y = 0.5, z = 0.5 },
    usesNegativeLighting = false,

    onTick = resistBludgeoningTick
})
end)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.resistCutting,
    name = "Resist Cutting",
    description = ("Decreases the damage the target takes from cutting attacks. This includes slashing attacks from blades and axes. Only applies to attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.restoration,

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

    icon = "IB\\IB_s_resist_cutting.tga",
    particleTexture = "vfx_bluecloud.tga",
    castSound = "restoration cast",
    castVFX = "VFX_RestorationCast",
    boltSound = "restoration bolt",
    boltVFX = "VFX_RestoreBolt",
    hitSound = "restoration hit",
    hitVFX = "VFX_RestorationHit",
    areaSound = "restoration area",
    areaVFX = "VFX_RestorationArea",
    lighting = { x = 0.5, y = 0.5, z = 0.5 },
    usesNegativeLighting = false,

    onTick = resistCuttingTick
})
end)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.resistPiercing,
    name = "Resist Piercing",
    description = ("Decreases the damage the target takes from piercing attacks. This includes thrust attacks with blades and spears. Only applies to attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.restoration,

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

    icon = "IB\\IB_s_resist_piercing.tga",
    particleTexture = "vfx_bluecloud.tga",
    castSound = "restoration cast",
    castVFX = "VFX_RestorationCast",
    boltSound = "restoration bolt",
    boltVFX = "VFX_RestoreBolt",
    hitSound = "restoration hit",
    hitVFX = "VFX_RestorationHit",
    areaSound = "restoration area",
    areaVFX = "VFX_RestorationArea",
    lighting = { x = 0.5, y = 0.5, z = 0.5 },
    usesNegativeLighting = false,

    onTick = resistPiercingTick
})
end)