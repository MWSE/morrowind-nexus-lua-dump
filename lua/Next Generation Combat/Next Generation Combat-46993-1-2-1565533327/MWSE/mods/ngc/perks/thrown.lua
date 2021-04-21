local this = {}

local common = require('ngc.common')

--[[ Perform critical strike (thrown weapon)
--]]
function this.performCritical(damage, weaponSkill)
    local damageDone

    local critChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.thrownCriticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.thrownCriticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.thrownCriticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.thrownCriticalStrikeChance >= critChanceRoll then
            damageDone = damage * common.config.criticalStrikeMultiplier
        end
    end

    return damageDone
end

function this.getThrownRecoverChance(weaponSkill)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        return common.config.weaponTier4.thrownChanceToRecover
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        return common.config.weaponTier3.thrownChanceToRecover
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        return common.config.weaponTier2.thrownChanceToRecover
    end
end

function this.agilityBonusMod(damage, agility)
    return damage * ((agility * common.config.thrownAgilityModifier) / 100)
end


return this