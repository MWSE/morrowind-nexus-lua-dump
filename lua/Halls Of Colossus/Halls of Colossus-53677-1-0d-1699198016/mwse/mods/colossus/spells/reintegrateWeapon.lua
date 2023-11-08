tes3.claimSpellEffectId("ggwReintegrateWeapon", 1701)

event.register("magicEffectsResolved", function(e)
    tes3.addMagicEffect({
        id = tes3.effect.ggwReintegrateWeapon,
        name = "Reintegrate Weapon",
        school = tes3.magicSchool.restoration,
        description = "This effect restores the health rating of equipped weapons.",
        baseMagickaCost = 6.0,
        icon = "ggw\\s\\tx_reinteg_weap.dds",
        particleTexture = "vfx_bluecloud.tga",
        castSound = "restoration cast",
        castVFX = "VFX_RestorationCast",
        boltSound = "restoration bolt",
        boltVFX = "VFX_RestorationBolt",
        hitSound = "restoration hit",
        hitVFX = "VFX_RestorationHit",
        areaSound = "restoration area",
        areaVFX = "VFX_RestorationArea",
        allowSpellmaking = true,
        allowEnchanting = false,
        appliesOnce = false,
        canCastSelf = true,
        canCastTarget = true,
        canCastTouch = true,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = false,
        hasNoMagnitude = false,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = false,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = false,
        usesNegativeLighting = false,

        onTick = function(e)
            e:trigger()

            local magnitude = e.effectInstance.effectiveMagnitude
            if magnitude == 0 then
                return
            end

            e.effectInstance.state = tes3.spellState.retired

            local target = e.effectInstance.target
            local mobile = target and target.mobile
            local weapon = mobile and mobile.readiedWeapon
            if weapon == nil then
                return
            end

            local condition = weapon.itemData.condition
            local maxCondition = weapon.object.maxCondition

            local effect = e.sourceInstance.sourceEffects[e.effectIndex + 1]
            magnitude = magnitude * math.max(effect.duration, 1)

            weapon.itemData.condition = math.min(condition + magnitude, maxCondition)
        end,
    })
end)
