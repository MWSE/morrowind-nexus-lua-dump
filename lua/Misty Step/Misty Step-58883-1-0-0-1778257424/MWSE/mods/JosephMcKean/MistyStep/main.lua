local constants = require("JosephMcKean.MistyStep.constants")
local log = require("JosephMcKean.MistyStep.log")
local blink = require("JosephMcKean.MistyStep.blink")

require("JosephMcKean.MistyStep.effects")

event.register(tes3.event.initialized, function()
    require("JosephMcKean.MistyStep.spell")
    log:info("%s initialized", constants.MOD_NAME)
end)

-- Cache failed validations between `spellMagickaUse` and `spellCast` events.
local pendingFailedCasts = {}

-- Pre-validate landing during spellMagickaUse and prevent magicka spending on failure.
event.register(tes3.event.spellMagickaUse, function(e)
    local spell = e.spell
    if not spell or not spell:hasEffect(tes3.effect.mistyStep) then return end
    log:debug("spellMagickaUse event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then
        log:debug("spellMagickaUse: missing caster reference")
        return
    end

    local mobile = casterRef.mobile
    if not mobile then
        log:debug("spellMagickaUse: caster has no mobile component")
        return
    end
    ---@cast mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer

    local magickaCost = e.cost or 0
    if mobile.magicka and mobile.magicka.current and mobile.magicka.current <
        magickaCost then
        log:debug(
            "spellMagickaUse: insufficient magicka (have=%.0f need=%.0f), skipping landing validation",
            mobile.magicka.current, magickaCost)
        return
    end

    local ray = blink.getBlinkRay(mobile)
    local landing = blink.findLandingPosition(casterRef, ray)
    if not landing then
        log:info(
            "spellMagickaUse: no valid landing, preventing magicka cost for %s",
            casterRef.id or "unknown")
        e.cost = 0
        pendingFailedCasts[casterRef] = "no-landing"
    end
end)

-- Cancel the cast in spellCast if pre-validation failed, and show player-facing message.
event.register(tes3.event.spellCast, function(e)
    local source = e.source
    if not source or not source:hasEffect(tes3.effect.mistyStep) then return end
    log:debug("spellCast event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then return end

    log:debug("spellCast: source=%s castChance=%.2f",
              source and (source.id or "unknown") or "nil", e.castChance or 0)
    local reason = pendingFailedCasts[casterRef]
    if reason then
        pendingFailedCasts[casterRef] = nil
        log:info("spellCast: cancelling Misty Step cast for %s due to %s",
                 casterRef.id or "unknown", tostring(reason))
        if casterRef == tes3.player then
            tes3.messageBox(constants.NO_LANDING_MESSAGE)
        end
        e.castChance = 0
    else
        if (e.castChance or 0) == 0 then
            log:warn(
                "spellCast: castChance is 0 for %s but no pre-validation flag set; cast failed for another reason",
                casterRef.id or "unknown")
        end
    end
end)

-- Validate landing during resistance calculation so scrolls/enchant casts don't apply when there's no safe landing.
event.register(tes3.event.spellResist, function(e)
    if not e.effect or e.effect.id ~= tes3.effect.mistyStep then return end
    log:debug("spellResist event for Misty Step detected.")
    local casterRef = e.caster
    if not casterRef then return end

    local caster = casterRef.mobile
    if not caster then return end
    ---@cast caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer

    local ray = blink.getBlinkRay(caster)
    local landing = blink.findLandingPosition(casterRef, ray)
    if not landing then
        log:info("spellResist: no valid landing for %s, resisting effect",
                 casterRef.id or "unknown")
        e.resistedPercent = 100

        -- If this originated from a one-shot enchantment (common for scrolls), try to restore the scroll
        local source = e.source
        if source and source.objectType == tes3.objectType.enchantment and
            source.castType == tes3.enchantmentType.castOnce and
            caster.inventory then
            local scroll = tes3.getObject(constants.SCROLL_ID) ---@cast scroll tes3book
            if scroll then
                tes3.addItem({
                    reference = caster,
                    item = scroll,
                    playSound = false
                })
                log:debug(
                    "Restored Misty Step scroll to %s's inventory (spellResist)",
                    casterRef.id or "unknown")
            end
        end

        if casterRef == tes3.player then
            tes3.messageBox(constants.NO_LANDING_MESSAGE)
        end
    end
end)

require("JosephMcKean.MistyStep.mcm")
