local blink = require("JosephMcKean.MistyStep.blink")
local constants = require("JosephMcKean.MistyStep.constants")
local log = require("JosephMcKean.MistyStep.log")

tes3.claimSpellEffectId("mistyStep", 8377)

---Misty Step: Blink forward (60 ft at most), stopping before collision
---@param e tes3magicEffectTickEventData
local function onTickMistyStep(e)
    if (not e:trigger()) then return end -- Only trigger on the first tick of the effect

    local casterRef = e.sourceInstance.caster
    if not casterRef then
        log:error("onTickMistyStep: missing caster reference, aborting")
        return
    end
    log:debug("onTickMistyStep called for %s",
              casterRef and (casterRef.id or "unknown-id") or "unknown-ref")
    local caster = casterRef.mobile
    if not caster then
        log:error("onTickMistyStep: casterRef.mobile is nil, aborting")
        return
    end
    log:debug("caster state: position=%s height=%.3f cell=%s", caster.position,
              caster.height or 0,
              caster.cell and (caster.cell.name or "unnamed") or "nil")
    ---@cast caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
    local ray = blink.getBlinkRay(caster)
    -- debug.mark(ray.position)
    log:debug("computed blink ray: origin=%s direction=%s", ray.position,
              ray.direction)

    local candidatePosition = blink.findLandingPosition(casterRef, ray)
    if not candidatePosition then
        log:warn(
            "onTickMistyStep: unable to find valid landing surface, cancelling cast")
        if casterRef == tes3.player then
            tes3.messageBox(constants.NO_LANDING_MESSAGE)
        end
        e.effectInstance.state = tes3.spellState.retired
        return
    end

    if blink.performTeleport(casterRef, candidatePosition) then
        log:debug("teleport executed for %s",
                  casterRef and (casterRef.id or "unknown-id") or "unknown-ref")
    end

    e.effectInstance.state = tes3.spellState.retired -- Retire the effect
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.mistyStep,
        name = "Misty Step",
        description = ("This spell effect allows the caster to teleport a short distance."),

        school = tes3.magicSchool.mysticism,
        baseCost = 3,

        canCastTarget = false,
        canCastTouch = false,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = true,
        hasNoMagnitude = true,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = true,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = false,
        usesNegativeLighting = false,

        icon = "jsmk\\ms\\Tx_S_misty_step.dds",
        bigIcon = "jsmk\\ms\\B_Tx_S_misty_step.dds",
        lighting = tes3vector3.new(0.66, 0.85, 0.98),
        particleTexture = "vfx_particle064.tga",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",

        onTick = onTickMistyStep
    })
end)

return nil
