tes3.claimSpellEffectId("ggwElsweyrPortal", 1703)

event.register("magicEffectsResolved", function()
    tes3.addMagicEffect({
        id = tes3.effect.ggwElsweyrPortal,
        name = "Elsweyr Portal",
        school = tes3.magicSchool.mysticism,
        description = "Conjure a portal to Elsweyr.",
        baseMagickaCost = 6.0,
        icon = "ggw\\s\\tx_elsweyr_portal.dds",
        particleTexture = "vfx_bluecloud.tga",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",
        allowSpellmaking = false,
        allowEnchanting = false,
        appliesOnce = false,
        canCastSelf = true,
        canCastTarget = false,
        canCastTouch = false,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = false,
        hasNoMagnitude = true,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = false,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = false,
        usesNegativeLighting = false,
    })

    local function calculatePosition()
        local eyepos = tes3.getPlayerEyePosition()
        local eyevec = tes3.getPlayerEyeVector()
        local distance = 256

        local rayhit = tes3.rayTest({
            position = eyepos,
            direction = eyevec,
            ignore = { tes3.player },
            maxDistance = distance,
        })
        if rayhit then
            distance = rayhit.distance
        end

        local position = eyepos + eyevec * distance
        position.z = eyepos.z

        return position
    end

    --- Create a portal when the spell is cast.
    ---
    ---@param e spellCastedEventData
    event.register("spellCasted", function(e)
        if e.caster ~= tes3.player then
            return
        elseif e.source.id ~= "ggw_create_portal" then
            return
        end

        -- Prevent casting if already in Elsweyr
        if tes3.player.cell.id:find("Elsweyr, Oasis") then
            tes3.messageBox("The portal is already open.")
            return
        end

        local gmst = tes3.findGMST("sTeleportDisabled")

        -- Prevent casting if teleporting is disabled.
        if tes3.worldController.flagTeleportingDisabled then
            tes3.messageBox(gmst.value)
            return
        end

        -- Prevent casting if teleporting is disabled.
        local noTeleport = tes3.getGlobal("cdc_noteleport")
        if noTeleport ~= nil and noTeleport < 0 then
            tes3.messageBox(gmst.value)
            return
        end

        -- Position 256 units forward at eye level.
        local ref = tes3.createReference({
            object = "ggw_portal_door_desert",
            position = calculatePosition(),
            orientation = tes3.player.orientation,
            cell = tes3.player.cell,
        })

        -- Travel destination.
        tes3.setDestination({
            reference = ref,
            position = { 3538.351, 12984.434, 3853.576 },
            orientation = { 0.0, 0.0, 182.4 },
            cell = " Elsweyr, Oasis",
        })

        -- Return destination.
        tes3.setDestination({
            reference = tes3.getReference("ggw_portal_door_desert_exit"),
            position = ref.position,
            orientation = ref.orientation,
            cell = ref.cell,
        })
    end)

    --- Remove the portal when the effect ends.
    ---
    ---@param e magicEffectRemovedEventData
    event.register("magicEffectRemoved", function(e)
        if e.effect.id ~= tes3.effect.ggwElsweyrPortal then
            return
        end
        local ref = tes3.getReference("ggw_portal_door_desert")
        if ref then
            ref:disable()
            ref:delete()
        end
    end)
end)
