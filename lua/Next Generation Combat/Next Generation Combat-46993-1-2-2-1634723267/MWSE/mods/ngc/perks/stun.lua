local this = {}

local common = require('ngc.common')

local function bonusArmorDamage(target, damageDone, arMod)
    -- calculate the bonus armor damage
    local bonusDamage
    local totalAR = common.currentArmorCache[target.id]
    if totalAR == nil then
        -- no cache, calculate total armor
        totalAR = common.getARforTarget(target)
        -- prime cache
        common.currentArmorCache[target.id] = totalAR
    end

    bonusDamage = damageDone * ((totalAR * arMod) / 100)
    return bonusDamage
end

local function castStun(targetActor)
    -- attempt to paralyze the target if they aren't already
    if targetActor.paralyze == 0 then
        targetActor.paralyze = 1
        timer.start({
            duration = 1,
            callback = function ()
                targetActor.paralyze = 0
            end,
        })
    end
end

--[[ Perform a stun and bonus armor damage (blunt weapon)
--]]
function this.perform(damage, target, targetActor, weaponSkill)
    local damageDone
    local stunned = false

    local stunChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier4.bonusArmorDamageMultiplier)
        if common.config.weaponTier4.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier3.bonusArmorDamageMultiplier)
        if common.config.weaponTier3.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        damageDone = bonusArmorDamage(target, damage, common.config.weaponTier2.bonusArmorDamageMultiplier)
        if common.config.weaponTier2.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.stunChance >= stunChanceRoll then
            castStun(targetActor)
            stunned = true
        end
    end

    return stunned, damageDone
end

return this