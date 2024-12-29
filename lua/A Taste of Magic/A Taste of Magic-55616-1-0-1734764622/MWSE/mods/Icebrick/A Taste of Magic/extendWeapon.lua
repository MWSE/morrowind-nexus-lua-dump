tes3.claimSpellEffectId("extendWeapon", 24010)

---@param tickParams tes3magicEffectTickEventData
local function extendWeaponTick(tickParams)
    local target = tickParams.effectInstance.target
    -- Check to see if the target has a weapon readied.
    if (target.mobile.readiedWeapon ~= nil) then
        local weapon = target.mobile.readiedWeapon
        if (target.data.initialReach) == nil then
            target.data.initialReach = {}
            target.data.initialReach = weapon.object.reach
        end
        local baseReach = target.data.initialReach
        local extension = (tickParams.effectInstance.magnitude)/45
        weapon.object.reach = baseReach + extension
    end
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.extendWeapon,
        name = "Extend Weapon",
        description = ("Increases the distance with which you can attack with a weapon."),
        school = tes3.magicSchool.alteration,

        baseCost = 1.25,

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

        icon = "IB\\IB_s_extend_weapon.tga",
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

        onTick = extendWeaponTick
})
end)
