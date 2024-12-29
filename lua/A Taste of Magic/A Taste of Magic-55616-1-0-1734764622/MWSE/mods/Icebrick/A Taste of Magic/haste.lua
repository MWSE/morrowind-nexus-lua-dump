tes3.claimSpellEffectId("haste", 24011)

---@param tickParams tes3magicEffectTickEventData
local function hasteTick(tickParams)
    local target = tickParams.effectInstance.target
    -- Check to see if the target has a weapon.
    if (target.mobile.readiedWeapon ~= nil) then
        local weapon = target.mobile.readiedWeapon
        -- Then fetch that weapons base speed.
        if (target.data.initialSpeed) == nil then
            -- Sets initial speed if it's not there. For constant effect enchantments.
            target.data.initialSpeed = {}
            target.data.initialSpeed = weapon.object.speed
        end
        local baseSpeed = target.data.initialSpeed
        local speedIncrease = (tickParams.effectInstance.magnitude)/45
        weapon.object.speed = baseSpeed + speedIncrease
    end
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
