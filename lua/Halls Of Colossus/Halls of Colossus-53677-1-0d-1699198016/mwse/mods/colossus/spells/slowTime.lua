tes3.claimSpellEffectId("ggwSlowTime", 1704)

local TIME_SCALAR = 0.1
local PC_TIME_SCALAR = 0.5 / TIME_SCALAR

event.register("magicEffectsResolved", function(e)
    tes3.addMagicEffect({
        id = tes3.effect.ggwSlowTime,
        name = "Slow Time",
        school = tes3.magicSchool.alteration,
        description = "This effect restores the health rating of equipped weapons.",
        baseMagickaCost = 6.0,
        icon = "ggw\\s\\tx_time_slow.dds",
        particleTexture = "vfx_electricblue.tga",
        castSound = "alteration cast",
        castVFX = "VFX_AlterationCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_AlterationBolt",
        hitSound = "alteration hit",
        hitVFX = "VFX_AlterationHit",
        areaSound = "alteration area",
        areaVFX = "VFX_AlterationArea",
        allowSpellmaking = false,
        allowEnchanting = false,
        appliesOnce = false,
        canCastSelf = true,
        canCastTarget = false,
        canCastTouch = false,
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
    })


    ---@param value number
    local function setPlayerCastSpeed(value)
        tes3.player.attachments.animation.castSpeed = value
        tes3.player1stPerson.attachments.animation.castSpeed = value
    end

    ---@param e spellCastedEventData
    event.register("spellCasted", function(e)
        if e.caster ~= tes3.player then
            return
        elseif e.source.id ~= "ggw_slow_time" then
            return
        end

        local context = table.getset(tes3.player.data, "ggw_slowTimeContext", {})
        table.copymissing(context, {
            timeScalar = tes3.worldController.simulationTimeScalar,
            castSpeed = tes3.player.attachments.animation.castSpeed,
        })

        tes3.worldController.simulationTimeScalar = TIME_SCALAR
        setPlayerCastSpeed(PC_TIME_SCALAR)

        local motionblur = require("colossus.shaders.motionblur")
        motionblur.start()

        tes3.playSound({
            reference = tes3.player,
            sound = "ggw_sound_slow_time",
            mixChannel = tes3.soundMix.master,
        })
    end)

    ---@param e magicEffectRemovedEventData
    event.register("magicEffectRemoved", function(e)
        if e.effect.id ~= tes3.effect.ggwSlowTime then
            return
        end

        local context = tes3.player.data.ggw_slowTimeContext
        tes3.player.data.ggw_slowTimeContext = nil

        tes3.worldController.simulationTimeScalar = context.timeScalar or 1.0
        setPlayerCastSpeed(context.castSpeed or 1.0)

        local motionblur = require("colossus.shaders.motionblur")
        motionblur.stop()

        tes3.playSound({
            reference = tes3.player,
            sound = "ggw_sound_resume_time",
            mixChannel = tes3.soundMix.master,
        })
    end)

    ---@param e calcMoveSpeedEventData
    event.register("calcMoveSpeed", function(e)
        if e.reference == tes3.player
            and e.reference.data.ggw_slowTimeContext
        then
            e.speed = e.speed * PC_TIME_SCALAR
        end
    end)

    ---@param e attackStartEventData
    event.register("attackStart", function(e)
        if e.reference == tes3.player
            and e.reference.data.ggw_slowTimeContext
        then
            e.attackSpeed = e.attackSpeed * PC_TIME_SCALAR
        end
    end)

    ---@param e activateEventData
    event.register("activate", function(e)
        if e.activator == tes3.player
            and e.activator.data.ggw_slowTimeContext
        then
            tes3.messageBox("You can't use this while time is slowed.")
            return false
        end
    end, { priority = 1704 })

    event.register("loaded", function()
        tes3.removeEffects({ reference = tes3.player, effect = tes3.effect.ggwSlowTime })
    end)
end)
