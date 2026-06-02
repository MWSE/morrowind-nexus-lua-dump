---@omw-context local
local Combat           = require('openmw.interfaces').Combat
local core             = require("openmw.core")
local types            = require('openmw.types')
local Helpers          = require('scripts.ngarde.helpers.helpers')
local logging          = require('scripts.ngarde.helpers.logger').new()
local getWeaponRecord  = types.Weapon.record
local random           = math.random
local actorSelf        = require('openmw.self')
local activeEffects    = types.Actor.activeEffects(actorSelf)
local skills           = types.NPC.stats.skills
local constants        = require('scripts.ngarde.helpers.constants')
local AttackController = {}


AttackController.processFumble                 = function(actSelf,
                                                          attack,
                                                          isH2HAttack,
                                                          isThrown,
                                                          attackerIsCreature,
                                                          attackerIsWeaponUser,
                                                          enemyAttackData)
    local attackerRecordId = attack.attacker.recordId
    local attackerRecord = types.NPC.record(attackerRecordId) or types.Creature.record(attackerRecordId)
    logging:debug("entered fumble handler")

    local attackWeaponRecord = nil
    local attackAmmoRecord = nil
    if attack.weapon and not isThrown then
        attackWeaponRecord = getWeaponRecord(attack.weapon.recordId)
    end
    if attack.ammo then
        attackAmmoRecord = getWeaponRecord(attack.ammo)
    end
    ---@diagnostic disable-next-line missing-parameter
    local normalWeaponResistance = activeEffects:getEffect(core.magic.EFFECT_TYPE.ResistNormalWeapons).magnitude or 0
    normalWeaponResistance = normalWeaponResistance / 100 -- ratio
    logging:debug("attackerIsWeaponUser:" .. tostring(attackerIsWeaponUser))
    logging:debug("attackerIsCreature:" .. tostring(attackerIsCreature))
    logging:debug("attackWeaponRecord:" .. tostring(attackWeaponRecord))
    logging:debug("attackAmmoRecord:" .. tostring(attackAmmoRecord))
    logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
    local damageTable = {
        0,
        0,
        0,
        0,
        0,
        0,
    }

    if not isH2HAttack then
        if attackerIsCreature then
            ---@diagnostic disable-next-line undefined-fields
            damageTable = attackerRecord.attack
        elseif attackerIsWeaponUser and attackWeaponRecord then
            damageTable[1] = damageTable[1] + attackWeaponRecord.chopMaxDamage
            damageTable[2] = damageTable[2] + attackWeaponRecord.slashMinDamage
            damageTable[3] = damageTable[3] + attackWeaponRecord.slashMaxDamage
            damageTable[4] = damageTable[4] + attackWeaponRecord.thrustMinDamage
            damageTable[5] = damageTable[5] + attackWeaponRecord.thrustMaxDamage
            damageTable[6] = damageTable[6] + attackWeaponRecord.chopMinDamage
        end
    elseif isH2HAttack then
        logging:debug("did we get here somehow?")
        local h2h = skills.handtohand(attack.attacker).modified
        local minH2HDamage = core.getGMST("fMinHandToHandMult") * h2h
        local maxH2HDamage = core.getGMST("fMaxHandToHandMult") * h2h
        damageTable[1] = damageTable[1] + minH2HDamage
        damageTable[2] = damageTable[2] + maxH2HDamage
        damageTable[3] = damageTable[3] + minH2HDamage
        damageTable[4] = damageTable[4] + maxH2HDamage
        damageTable[5] = damageTable[5] + minH2HDamage
        damageTable[6] = damageTable[6] + maxH2HDamage
    end
    if attackAmmoRecord then
        damageTable[1] = damageTable[1] + attackAmmoRecord.chopMinDamage
        damageTable[2] = damageTable[2] + attackAmmoRecord.chopMaxDamage
        damageTable[3] = damageTable[3] + attackAmmoRecord.slashMinDamage
        damageTable[4] = damageTable[4] + attackAmmoRecord.slashMaxDamage
        damageTable[5] = damageTable[5] + attackAmmoRecord.thrustMinDamage
        damageTable[6] = damageTable[6] + attackAmmoRecord.thrustMaxDamage
    end

    attack.successful = true
    attack.strength = 0
    attack.damage = { health = 0, fatigue = 0 }

    -- logging:debug("damageTable")
    -- logging:debug(damageTable)
    -- logging:debug("attack")
    -- logging:debug(attack)
    logging:debug("attack.sourceType:" .. tostring(attack.sourceType))

    local attackMinDamage = 0
    local attackMaxDamage = 0

    if attack.type == constants.TRUE_ATTACK_TYPE.Chop then
        attackMinDamage = damageTable[1]
        attackMaxDamage = damageTable[2]
    elseif attack.type == constants.TRUE_ATTACK_TYPE.Slash then
        attackMinDamage = damageTable[3]
        attackMaxDamage = damageTable[4]
    elseif attack.type == constants.TRUE_ATTACK_TYPE.Thrust then
        attackMinDamage = damageTable[5]
        attackMaxDamage = damageTable[6]
    end
    logging:debug("attackMinDamage:" .. attackMinDamage)
    logging:debug("attackMaxDamage:" .. attackMaxDamage)
    local factor, shifted = Helpers.decimalShiftToIntCommonFactor({ attackMinDamage, attackMaxDamage })
    -- local attackStrength = enemyAttackData.currentCharge
    -- local resultDamage = (((shifted[2]-shifted[1]) * attackStrength) + shifted[1]) * 0.20
    local resultDamage = (random(shifted[1], shifted[2]) / factor) * 0.20
    if isH2HAttack then -- can't get launcher setting so no strength multiplier. fumbles hence don't get strength boost if it's enabled, But only reducing fatigue damage from h2h by x2 instead of by x4
        attack.damage.fatigue = resultDamage * 2
    else
        attack.damage.health = resultDamage
    end
    if Combat then Combat.applyArmor(attack) end
    attack = AttackController.processNormalWeaponResistance(attack, normalWeaponResistance, attackWeaponRecord,
        attackAmmoRecord, isH2HAttack)
    logging:debug("attackMinDamage:" .. tostring(attackMinDamage / factor))
    logging:debug("attackMaxDamage:" .. tostring(attackMaxDamage / factor))
    logging:debug("result:" .. tostring(resultDamage))
    logging:debug("attack.damage.health" .. attack.damage.health)
    logging:debug("attack.damage.fatigue" .. attack.damage.fatigue)

    return attack
end

AttackController.processNormalWeaponResistance = function(attack,
                                                          normalWeaponResistance,
                                                          attackWeaponRecord,
                                                          attackAmmoRecord,
                                                          isH2HAttack)
    local isMagical = false
    logging:debug("normalWeaponResistance:" .. tostring(normalWeaponResistance))
    logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
    if attackAmmoRecord then
        if attackAmmoRecord.isMagical or attackAmmoRecord.isSilver then
            isMagical = true
        end
    end
    if attackWeaponRecord then
        if attackWeaponRecord.isMagical or attackWeaponRecord.isSilver then
            isMagical = true
        end
    end
    if isH2HAttack then
        isMagical = true
    end
    if not isMagical then
        if normalWeaponResistance == 1 then
            attack.successful = false
        end
        attack.damage.health = attack.damage.health * (1 - normalWeaponResistance)
        attack.damage.fatigue = attack.damage.fatigue * (1 - normalWeaponResistance)
    end
    attack.ngarde_glancing = true
    return attack
end

AttackController.getAttackDetails              = function(attack)
    local isH2HAttack = false
    local isThrown = false
    if attack.weapon then
        isThrown = (attack.weapon.id == "@0x0") -- weapon is a null pointer, not even a proper nil - the weapon is likely thrown
    end
    local attackerRecord = types.NPC.record(attack.attacker.recordId) or
        types.Creature.record(attack.attacker.recordId)
    ---@diagnostic disable-next-line undefined-fields
    local attackerIsCreature = (attack.attacker.type == types.Creature and not attackerRecord.canUseWeapons)
    logging:debug("attack.attacker.type:" .. tostring(attack.attacker.type))
    ---@diagnostic disable-next-line undefined-fields
    local attackerIsWeaponUser = ((attack.attacker.type == types.NPC or attack.attacker.type == types.Player) or (attack.attacker.type == types.Creature and attackerRecord.canUseWeapons))
    logging:debug("Attacker Is Weapon User:" .. tostring(attackerIsWeaponUser))
    if not (attackerIsCreature or (attackerIsWeaponUser and attack.weapon)) then
        isH2HAttack = true
    end
    isH2HAttack = not (attackerIsCreature or (attackerIsWeaponUser and attack.weapon))
    logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
    logging:debug("successful:" .. tostring(attack.successful))
    local attackerName = attackerRecord and attackerRecord.name or "None"
    return isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, attackerName
end


--shelved until https://gitlab.com/OpenMW/openmw/-/work_items/8101 is resolved
AttackController.processDirectionalAttack = function(attack)
    if not attack.successful then return end
    if attack.type == constants.TRUE_ATTACK_TYPE.Chop then
        attack.damage.health = attack.damage.health * 1.10
        attack.damage.fatigue = attack.damage.fatigue * 1.10
    elseif attack.type == constants.TRUE_ATTACK_TYPE.Slash then
        attack.damage.health = attack.damage.health * 1.10
        attack.damage.fatigue = attack.damage.fatigue * 1.10
    elseif attack.type == constants.TRUE_ATTACK_TYPE.Thrust then
        attack.damage.health = attack.damage.health * 1.10
        attack.damage.fatigue = attack.damage.fatigue * 1.10
    end
    return attack
end

AttackController.getWindupDuration = function(parent)
    local windupMin = 350 --ms
    local wundupMax = 500 --ms
    if parent.quickMode then
        windupMin = windupMin / 2
    end
    local windup = random(windupMin, wundupMax) / 1000
    return windup
end

AttackController.startAttackWindup = function(parent, use)
    parent.localTimers.attackWindupTimer:startTimer(AttackController.getWindupDuration, { parent })
    parent.windup = use
end

---callback of the timer started in the method above, defined when timer was created
AttackController.releaseAttackWindup = function(actSelf)
    if actSelf.controls.use ~= actSelf.ATTACK_TYPE.NoAttack then
        actSelf.controls.use = actSelf.ATTACK_TYPE.NoAttack
    end
end

return AttackController
