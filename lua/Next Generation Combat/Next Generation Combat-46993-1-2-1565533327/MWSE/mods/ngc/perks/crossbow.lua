local this = {}

local common = require("ngc.common")

function this.criticalRangeDamage(damage, distance, weaponSkill)
    local damageDone

    if distance < common.config.crossbowCriticalRange then
        if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
            damageDone = damage * common.config.weaponTier4.crossbowCriticalDamageMultiplier
        elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
            damageDone = damage * common.config.weaponTier3.crossbowCriticalDamageMultiplier
        elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
            damageDone = damage * common.config.weaponTier2.crossbowCriticalDamageMultiplier
        elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
            damageDone = damage * common.config.weaponTier1.crossbowCriticalDamageMultiplier
        end
    end

    return damageDone
end

local function rollForRepeater(weaponSkill)
    local repeater = false
    local repeaterChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.repeaterChance >= repeaterChanceRoll then
            repeater = true
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.repeaterChance >= repeaterChanceRoll then
            repeater = true
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.repeaterChance >= repeaterChanceRoll then
            repeater = true
        end
    end

    if repeater then
        tes3.messageBox({ message = "Repeater!" })
    end

    return repeater
end

function this.attackPressed(e)
    if tes3.menuMode() then
        return
    end

    local player = tes3.mobilePlayer
    local weapon = player.readiedWeapon

    if (weapon and weapon.object.type == 10 and
        player.actionData.attackSwing > 0) then
        -- only do repeater on crossbows when we have an attack
        local weaponSkill = player.marksman.current

        if rollForRepeater(weaponSkill) then
            weapon.object.speed = 10
            timer.start({
                duration = 1,
                callback = function ()
                    weapon.object.speed = 1
                end,
                iterations = 1
            })
        end
    end
end

function this.attackReleased(e)
    if tes3.menuMode() then
        return
    end

    local player = tes3.mobilePlayer
    local weapon = player.readiedWeapon

    if (weapon and weapon.object.type == 10) then
        weapon.object.speed = 1
    end
end

return this