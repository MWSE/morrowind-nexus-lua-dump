local this = {}

local common = require('ngc.common')

local function executeDamage(damage, source, targetActor, executeMultiplier)
    local bonusDamage = 0

    if ((targetActor.health.current / targetActor.health.base) < common.config.executeThreshold) then
        bonusDamage = damage * executeMultiplier
        if (common.config.showDebugMessages and source == tes3.player) then
            tes3.messageBox({ message = "Execute!" })
        end
    end

    return bonusDamage
end


--[[ Perform critical strike (short blades)
--]]
function this.perform(damage, source, targetActor, weaponSkill)
    local damageDone
    local critDamage = 0

    local critChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.criticalStrikeChance >= critChanceRoll then
            critDamage = damage * common.config.criticalStrikeMultiplier
        end
        damageDone = critDamage + executeDamage(damage, source, targetActor, common.config.weaponTier4.executeDamageMultiplier)
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.criticalStrikeChance >= critChanceRoll then
            critDamage = damage * common.config.criticalStrikeMultiplier
        end
        damageDone = critDamage + executeDamage(damage, source, targetActor, common.config.weaponTier3.executeDamageMultiplier)
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.criticalStrikeChance >= critChanceRoll then
            critDamage = damage * common.config.criticalStrikeMultiplier
        end
        damageDone = critDamage + executeDamage(damage, source, targetActor, common.config.weaponTier2.executeDamageMultiplier)
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.criticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    end

    return damageDone, critDamage
end

return this