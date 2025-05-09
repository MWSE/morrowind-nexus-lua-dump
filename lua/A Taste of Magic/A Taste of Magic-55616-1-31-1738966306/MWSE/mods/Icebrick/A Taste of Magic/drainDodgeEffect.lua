tes3.claimSpellEffectId("drainDodge", 24003)

local drainDodgeEffect

-- ...Is this how you do it??
---@param tickParams tes3magicEffectTickEventData
local function drainDodgeTick(tickParams)
    local target = tickParams.effectInstance.target
    target.data.drainDodgeTracker = {}
    target.data.drainDodgeTracker = tickParams.effectInstance.magnitude
    tickParams:trigger({
        
    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
    -- Base information.
    id = tes3.effect.drainDodge,
    name = "Drain Dodge",
    description = ("Reduces the target's chance to avoid attacks, making them easier to hit."),
    baseCost = 1.0,
    school = tes3.magicSchool.illusion,

    -- Flags
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
    hasContinuousVFX = true,
    targetsAttributes = false,
    targetsSkills = false,

    -- Graphics / sounds.
    icon = "IB\\IB_s_drain_dodge.tga",
    particleTexture = "vfx_grnflare.tga",
    castSound = "illusion cast",
    castVFX = "VFX_IllusionCast",
    boltSound = "illusion bolt",
    boltVFX = "VFX_IllusionBolt",
    hitSound = "illusion hit",
    hitVFX = "VFX_IllusionHit",
    areaSound = "illusion area",
    areaVFX = "VFX_IllusionArea",
    lighting = { x = 0, y = 0.95, z = 0.74 },
    usesNegativeLighting = false,

    -- Callbacks
    onTick = drainDodgeTick
})
end)