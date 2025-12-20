local function onAttackHitCallback(e)
    -- Attacker and target mobiles.
    local attackerMobile = e.mobile
    local targetMobile   = e.targetMobile
    if not targetMobile then
        tes3.messageBox("No target")
        return
    end

    -- Get target reference and base ID.
    local targetRef = e.targetReference or targetMobile.reference
    if not targetRef then
        tes3.messageBox("No target ref")
        return
    end

    local id = targetRef.baseObject.id:lower()
    if id ~= "tbd_necromancer" then
        -- Not our boss, ignore.
        return
    end

    -- Bossfight stage check
    local global = tes3.findGlobal("dhac_bossfight_stage").value
    if global >= 6 then
        -- After stage 6, stop clamping.
        return
    end

    -- Incoming physical damage from this attack.
    local damage = attackerMobile.actionData.physicalDamage or 0
    if damage <= 0 then
        return
    end

    -- Current health of the *target* (the necromancer).
    local currentHP = targetMobile.health.current

    -- If this hit would drop HP below 20, clamp it.
    if (currentHP - damage) < 20 then
        local newDamage = currentHP - 20
        if newDamage < 1 then
            newDamage = 1    -- minimal chip damage
        end

        -- Apply clamped damage.
        attackerMobile.actionData.physicalDamage = 1

        -- Optionally force boss HP floor to 20 in case of rounding issues.
        targetMobile.health.current = 20
    end
end

event.register(tes3.event.attackHit, onAttackHitCallback)
