local core = require('openmw.core')
local T = require('openmw.types')

local mCore = require('scripts.skill-evolution.util.core')

local module = {}

module.getPotentialHitInfo = function(player, actor, animGroup, animKey, werewolfClawMult)

    -- Damage

    local damageMax, weapon, weaponRecord
    local record = actor.type.record(actor)
    if actor.type == T.Creature and not record.isBiped then
        damageMax = mCore.getMaxDamage(record, animGroup, animKey)
    else
        weapon = T.Actor.getEquipment(actor, T.Actor.EQUIPMENT_SLOT.CarriedRight)
        if weapon then
            weaponRecord = weapon.type.record(weapon)
            damageMax = mCore.getMaxDamage(weaponRecord, animGroup, animKey)
        end
    end
    if weapon then
        if weaponRecord.type == T.Weapon.TYPE.MarksmanBow or weaponRecord.type == T.Weapon.TYPE.MarksmanCrossbow then
            local ammo = T.Actor.getEquipment(actor, T.Actor.EQUIPMENT_SLOT.CarriedLeft)
            if ammo then
                damageMax = damageMax + mCore.getMaxDamage(ammo.type.record(ammo), animGroup, animKey)
            end
        elseif weaponRecord.type == T.Weapon.TYPE.MarksmanThrown then
            damageMax = 2 * damageMax
        end
    elseif actor.type ~= T.Creature then
        local handToHandSkill = T.NPC.stats.skills.handtohand(actor).modified
        local factor = T.NPC.isWerewolf(actor) and werewolfClawMult or 1
        damageMax = math.floor(mCore.GMSTs.fMaxHandToHandMult * handToHandSkill * factor)
    end

    if weapon then
        damageMax = damageMax * (mCore.GMSTs.fDamageStrengthBase + 0.1 * mCore.GMSTs.fDamageStrengthMult * T.Actor.stats.attributes.strength(actor).modified)
        local condition = T.Item.itemData(weapon).condition
        damageMax = damageMax * (weaponRecord.health == 0 and 0 or condition / weaponRecord.health)
    end

    -- Hit chance

    local skill
    if actor.type == T.Creature then
        skill = record.combatSkill
    elseif weapon then
        skill = T.NPC.stats.skills[mCore.weaponTypeToSkill[weaponRecord.type]](actor).modified
    else
        skill = T.NPC.stats.skills.handtohand(actor).modified
    end
    local attackerEffects = T.Actor.activeEffects(actor)
    local attackTerm = mCore.agilityTerm(actor, false, skill) * mCore.fatigueTerm(actor)
    attackTerm = attackTerm
            + attackerEffects:getEffect(core.magic.EFFECT_TYPE.FortifyAttack).magnitude
            - attackerEffects:getEffect(core.magic.EFFECT_TYPE.Blind).magnitude

    local defenderEffects = T.Actor.activeEffects(player)
    local defenseTerm = mCore.agilityTerm(player) * mCore.fatigueTerm(player)
    defenseTerm = defenseTerm
            + math.min(100, defenderEffects:getEffect(core.magic.EFFECT_TYPE.Sanctuary).magnitude)
            + math.min(100, mCore.GMSTs.fCombatInvisoMult * defenderEffects:getEffect(core.magic.EFFECT_TYPE.Chameleon).magnitude)
            + math.min(100, mCore.GMSTs.fCombatInvisoMult * defenderEffects:getEffect(core.magic.EFFECT_TYPE.Invisibility).magnitude)

    local hitChance = math.floor(0.5 + attackTerm - defenseTerm) / 100

    return damageMax, hitChance
end

return module