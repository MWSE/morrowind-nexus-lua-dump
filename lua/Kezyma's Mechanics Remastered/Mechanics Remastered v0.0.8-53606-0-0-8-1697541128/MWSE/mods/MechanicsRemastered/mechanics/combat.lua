local config = require('MechanicsRemastered.config')

-- Combat Overhaul

local combatPlayerId = "PlayerSaveGame"
local combatLastPlayerChance = nil
local combatLastNPCChance = nil
local combatHitChances = {}
local combatAttackSkills = {
    4, --tes3.skill.bluntWeapon,
    5, --tes3.skill.longBlade,
    6, --tes3.skill.axe,
    7, --tes3.skill.spear,
    22, --tes3.skill.shortBlade,
    23, --tes3.skill.marksman,
    26 --tes3.skill.handToHand
}
local combatDefenceSkills = {
    2, --tes3.skill.mediumArmor,
    3, --tes3.skill.heavyArmor,
    17, --tes3.skill.unarmored,
    21 --tes3.skill.lightArmor,
}

--- @param e calcHitChanceEventData
local function calcHitChanceCallback(e)
    if (config.CombatEnabled == true) then
        -- Record the hit chance for this attack.
        combatHitChances[e.attacker.id] = e.hitChance
        if (e.attacker.id == combatPlayerId) then
            combatLastPlayerChance = e.hitChance
        else
            combatLastNPCChance = e.hitChance
        end
        
        -- Return 100 for a guaranteed hit, unless chance is 0.
        if (e.hitChance > 0) then
            e.hitChance = 100
        end
    end
end

--- @param e damageEventData
local function damageCallback(e)
    if (config.CombatEnabled == true and e.source == tes3.damageSource.attack) then
        -- Modify the damage based on the hit chance.
        local hitChance = combatHitChances[e.attackerReference.id]
        if (hitChance) then
            if (hitChance > 0) then
                e.damage = (e.damage * hitChance) / 100
            else 
                e.damage = 0
            end
        end
    end
end

--- @param e damageHandToHandEventData
local function damageHandToHandCallback(e)
    if (config.CombatEnabled == true) then
        -- Modify the damage based on the hit chance.
        local hitChance = combatHitChances[e.attackerReference.id]
        if (hitChance) then
            if (hitChance > 0) then
                e.fatigueDamage = (e.fatigueDamage * hitChance) / 100
            else 
                e.fatigueDamage = 0
            end
        end
    end
end

--- @param e damagedEventData
local function damagedCallback(e)
    if (config.CombatEnabled == true and e.source == tes3.damageSource.attack) then
        local hitChance = combatHitChances[e.attackerReference.id]
        if (hitChance) then
            local rollStun = math.random(100) > hitChance
            if (rollStun == false) then
                e.mobile:hitStun({ cancel = true })
            end
        end
    end
end
--- @param e damagedHandToHandEventData
local function damagedHandToHandCallback(e)
    if (config.CombatEnabled == true) then
        local hitChance = combatHitChances[e.attackerReference.id]
        if (hitChance) then
            local rollStun = math.random(100) > hitChance
            if (rollStun == false) then
                e.mobile:hitStun({ cancel = true })
            end
        end
    end
end

--- @param e exerciseSkillEventData
local function exerciseSkillCallback(e)
    if (config.CombatEnabled == true) then
        if (combatLastPlayerChance ~= nil) then
            for ix, val in ipairs(combatAttackSkills) do
                if (val == e.skill) then
                    if (combatLastPlayerChance > 0 and e.progress > 0) then
                        e.progress = (e.progress * combatLastPlayerChance) / 100
                    else
                        e.progress = 0
                    end
                    combatLastPlayerChance = nil
                end
            end
        end
        if (combatLastNPCChance ~= nil) then
            for ix, val in ipairs(combatDefenceSkills) do
                if (val == e.skill) then
                    if (combatLastNPCChance > 0 and e.progress > 0) then
                        e.progress = (e.progress * combatLastNPCChance) / 100
                    else
                        e.progress = 0
                    end
                    combatLastNPCChance = nil
                end
            end
        end
    end
end

--- @param e enchantChargeUseEventData
local function enchantChargeUseCallback(e)
    if (config.CombatEnabled == true and e.isCast) then
        if (e.source.castType == tes3.enchantmentType.onStrike) then
            -- Increase charge cost for on-strike based on hit chance.
            local hitChance = combatHitChances[e.caster.id]
            if (hitChance) then
                local chargeMod = 100 / hitChance
                e.charge = e.charge * chargeMod
            end
        end
    end
end

event.register(tes3.event.damagedHandToHand, damagedHandToHandCallback)
event.register(tes3.event.damaged, damagedCallback)
event.register(tes3.event.enchantChargeUse, enchantChargeUseCallback)
event.register(tes3.event.calcHitChance, calcHitChanceCallback)
event.register(tes3.event.damage, damageCallback)
event.register(tes3.event.damageHandToHand, damageHandToHandCallback)
event.register(tes3.event.exerciseSkill, exerciseSkillCallback)
mwse.log(config.Name .. ' Combat Module Initialised.')