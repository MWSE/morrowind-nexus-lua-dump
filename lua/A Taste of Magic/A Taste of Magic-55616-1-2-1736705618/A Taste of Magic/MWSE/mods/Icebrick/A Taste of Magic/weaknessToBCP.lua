tes3.claimSpellEffectId("weaknessToBludgeoning", 24015)
tes3.claimSpellEffectId("weaknessToCutting", 24016)
tes3.claimSpellEffectId("weaknessToPiercing", 24017)

---@param tickParams tes3magicEffectTickEventData
local function weaknessToBludgeoningTick(tickParams)
    tickParams:trigger({
        
    })
end

---@param tickParams tes3magicEffectTickEventData
local function weaknessToCuttingTick(tickParams)
    tickParams:trigger({
        
    })
end

---@param tickParams tes3magicEffectTickEventData
local function weaknessToPiercingTick(tickParams)
    tickParams:trigger({
        
    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.weaknessToBludgeoning,
    name = "Weakness to Bludgeoning",
    description = ("Increases the damage the target takes from bludgeoning attacks. This includes most blunt weapons, and hand-to-hand attacks. Only applies to attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.destruction,

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
    isHarmful = true,
    hasContinuousVFX = false,
    targetsAttributes = false,
    targetsSkills = false,

    icon = "IB\\IB_s_wkns_to_bdgn.tga",
    particleTexture = "VFX_redglowalpha.tga",
    castSound = "destruction cast",
    castVFX = "VFX_DestructCast",
    boltSound = "destruction bolt",
    boltVFX = "VFX_DestructBolt",
    hitSound = "destruction hit",
    hitVFX = "VFX_DestructHit",
    areaSound = "destruction area",
    areaVFX = "VFX_DestructArea",
    lighting = { x = 0.96, y = 0.87, z = 0.72 },
    usesNegativeLighting = false,

    onTick = weaknessToBludgeoningTick
})
end)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.weaknessToCutting,
    name = "Weakness to Cutting",
    description = ("Increases the damage the target takes from cutting attacks. This includes slashing attacks from blades and axes. Only applies to attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.destruction,

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
    isHarmful = true,
    hasContinuousVFX = false,
    targetsAttributes = false,
    targetsSkills = false,

    icon = "IB\\IB_s_wkns_to_cutting.tga",
    particleTexture = "VFX_redglowalpha.tga",
    castSound = "destruction cast",
    castVFX = "VFX_DestructCast",
    boltSound = "destruction bolt",
    boltVFX = "VFX_DestructBolt",
    hitSound = "destruction hit",
    hitVFX = "VFX_DestructHit",
    areaSound = "destruction area",
    areaVFX = "VFX_DestructArea",
    lighting = { x = 0.96, y = 0.87, z = 0.72 },
    usesNegativeLighting = false,

    onTick = weaknessToCuttingTick
})
end)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    id = tes3.effect.weaknessToPiercing,
    name = "Weakness to Piercing",
    description = ("Increases the damage the target takes from piercing attacks. This includes thrust attacks with blades and spears. Only applies to attacks from weapons."),
    baseCost = 2,
    school = tes3.magicSchool.destruction,

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
    isHarmful = true,
    hasContinuousVFX = false,
    targetsAttributes = false,
    targetsSkills = false,

    icon = "IB\\IB_s_wkns_to_piercing.tga",
    particleTexture = "VFX_redglowalpha.tga",
    castSound = "destruction cast",
    castVFX = "VFX_DestructCast",
    boltSound = "destruction bolt",
    boltVFX = "VFX_DestructBolt",
    hitSound = "destruction hit",
    hitVFX = "VFX_DestructHit",
    areaSound = "destruction area",
    areaVFX = "VFX_DestructArea",
    lighting = { x = 0.96, y = 0.87, z = 0.72 },
    usesNegativeLighting = false,

    onTick = weaknessToPiercingTick
})
end)