-- Handles everything to do with the Weakness/Resistance to BPS spells.

--- @param e attackStartEventData
local function setDamageType(e)
    if e.attackType ~= tes3.physicalAttackType.thrust and e.attackType ~= tes3.physicalAttackType.slash and e.attackType ~= tes3.physicalAttackType.chop and e.attackType ~= tes3.physicalAttackType.projectile then
        return
    end

    local reference = e.reference
    local weapon = e.mobile.readiedWeapon
    reference.tempData.damageType = {}

    -- Default to bludgeoning if no weapon is found (for hand-to-hand).
    if weapon == nil then
        reference.tempData.damageType = "bludgeoning"
        return
    end

    -- Manual damageType exceptions
    -- Miner's Pick is piercing except thrust.
    if weapon.object.mesh == "w\\W_miner_pick.nif" and e.attackType ~= tes3.physicalAttackType.thrust then
        reference.tempData.damageType = "piercing"
        return
    end
    -- Daedric club is piercing except thrust.
    if weapon.object.mesh == "w\\w_club_daedric" and e.attackType ~= tes3.physicalAttackType.thrust then
        reference.tempData.damageType = "piercing"
        return
    end
    -- Spiked club is piercing except thrust
    if weapon.object.mesh == "w\\w_spikedclub.nif" and e.attackType ~= tes3.physicalAttackType.thrust then
        reference.tempData.damageType = "piercing"
        return
    end
    -- Deadric warhammer thrust is piercing
    if weapon.object.id == "w\\w_warhammer_daedric" and e.attackType == tes3.physicalAttackType.thrust then
        reference.tempData.damageType = "piercing"
        return
    end

    -- Default damageType based on weaponType and attack type.
    -- Blunt is always bludgeoning
    if weapon.object.type == tes3.weaponType.bluntOneHand or weapon.object.type == tes3.weaponType.bluntTwoClose or weapon.object.type == tes3.weaponType.bluntTwoWide then
        reference.tempData.damageType = "bludgeoning"
        return
    end
    -- Short and long blade is cutting, except thrusting which is piercing.
    if weapon.object.type == tes3.weaponType.shortBladeOneHand or weapon.object.type == tes3.weaponType.longBladeOneHand or weapon.object.type == tes3.weaponType.longBladeTwoClose then
        if e.attackType == tes3.physicalAttackType.thrust then
            reference.tempData.damageType = "piercing"
            return
        end
        reference.tempData.damageType = "cutting"
        return
    end
    -- Axe is cutting, except thrusting which is bludgeoning.
    if weapon.object.type == tes3.weaponType.axeOneHand or weapon.object.type == tes3.weaponType.axeTwoHand then
        if e.attackType == tes3.physicalAttackType.thrust then
            reference.tempData.damageType = "bludgeoning"
            return
        end
        reference.tempData.damageType = "cutting"
        return
    end
    -- Spear is cutting, except thrusting which is piercing
    if weapon.object.type == tes3.weaponType.spearTwoWide then
        if e.attackType == tes3.physicalAttackType.thrust then
            reference.tempData.damageType = "piercing"
            return
        end
        reference.tempData.damageType = "cutting"
        return
    end
    -- If it's none of the other damage types, it should be marksman and is set as piercing.
    reference.tempData.damageType = "piercing"
end
event.register(tes3.event.attackStart, setDamageType)

--- @param e damageEventData
local function damageCallback(e)
    if e.attacker ~= nil and e.source == tes3.damageSource.attack then
        local damageType = e.attackerReference.tempData.damageType
        if damageType ~= nil then
            local effectList = e.mobile.activeMagicEffectList
            local finalDamageMod = 1
            for u,effect in pairs(effectList) do
                if (effect.effectId == tes3.effect.weaknessToBludgeoning) and (damageType == "bludgeoning") then
                    finalDamageMod = finalDamageMod + (effect.magnitude/100)
                end
                if (effect.effectId == tes3.effect.weaknessToCutting) and (damageType == "cutting") then
                    finalDamageMod = finalDamageMod + (effect.magnitude/100)
                end
                if (effect.effectId == tes3.effect.weaknessToPiercing) and (damageType == "piercing") then
                    finalDamageMod = finalDamageMod + (effect.magnitude/100)
                end
                if (effect.effectId == tes3.effect.resistBludgeoning) and (damageType == "bludgeoning") then
                    finalDamageMod = finalDamageMod - (effect.magnitude/100)
                end
                if (effect.effectId == tes3.effect.resistCutting) and (damageType == "cutting") then
                    finalDamageMod = finalDamageMod - (effect.magnitude/100)
                end
                if (effect.effectId == tes3.effect.resistPiercing) and (damageType == "piercing") then
                    finalDamageMod = finalDamageMod - (effect.magnitude/100)
                end
            end
            if finalDamageMod <= 0.6 and e.attackerReference == tes3.player then
                tes3.messageBox("Target has heavy %s resistance!", damageType)
            end
            finalDamageMod = math.max(finalDamageMod, 0)
            e.damage = e.damage * finalDamageMod
        end
    end
end
event.register(tes3.event.damage, damageCallback)

--- @param e damageHandToHandEventData
local function damageHandToHandCallback(e)
    local effectList = e.mobile.activeMagicEffectList
    local finalDamageMod = 1
    for u,effect in pairs(effectList) do
        if (effect.effectId == tes3.effect.weaknessToBludgeoning) then
            finalDamageMod = finalDamageMod + (effect.magnitude/100)
        end
        if (effect.effectId == tes3.effect.resistBludgeoning) then
            finalDamageMod = finalDamageMod - (effect.magnitude/100)
        end
    end
    if finalDamageMod <= 0.6 and e.attackerReference == tes3.player then
        tes3.messageBox("Target has heavy bludgeoning resistance!")
    end
    finalDamageMod = math.max(finalDamageMod, 0)
    e.fatigueDamage = e.fatigueDamage * finalDamageMod
end
event.register(tes3.event.damageHandToHand, damageHandToHandCallback)