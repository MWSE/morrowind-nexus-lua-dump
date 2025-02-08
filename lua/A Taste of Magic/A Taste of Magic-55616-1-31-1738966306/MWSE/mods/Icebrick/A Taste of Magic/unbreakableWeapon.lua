tes3.claimSpellEffectId("unbreakableWeapon", 24004)

---@param tickParams tes3magicEffectTickEventData
local function onUnbreakableWeaponTick(tickParams)
    local target = tickParams.effectInstance.target
    local mobile = target.mobile
    -- There has got to be a better way. But in the meantime let's just check if there is a readied weapon...
    if (mobile.readiedWeapon ~= nil) then
        -- Then check if that weapon has data...
        if (target.mobile.readiedWeapon.itemData) ~= nil then
            -- Set initialCondition if it's lacking.
            if target.data.initialCondition == nil then
                target.data.initialCondition = {}
                target.data.initialCondition = target.mobile.readiedWeapon.itemData.condition
            end
            local initialCondition = target.data.initialCondition
            target.mobile.readiedWeapon.itemData.condition = initialCondition
        end
    end
    tickParams:trigger({

    })
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.unbreakableWeapon,
        name = "Unbreakable Weapon",
        description = "Makes a weapon take no damage.",
        school = tes3.magicSchool.alteration,

        baseCost = 25.0,

        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = false,
        canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        hasNoDuration = false,
        hasNoMagnitude = true,
        nonRecastable = false,
        unreflectable = false,
        isHarmful = false,
        hasContinuousVFX = false,
        targetsAttributes = false,
        targetsSkills = false,

        icon = "IB\\IB_s_unbreakable_weapon.tga",
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

        onTick = onUnbreakableWeaponTick
    })
end)
