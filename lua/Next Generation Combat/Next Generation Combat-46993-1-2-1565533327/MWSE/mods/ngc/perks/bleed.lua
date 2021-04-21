local this = {}

local common = require('ngc.common')

local function bleedTick(damage, targetActor)
    -- Apply bleed tick damage
    targetActor:applyHealthDamage(damage, false, true, false)
    if common.config.showMessages and common.config.showDamageNumbers then
        tes3.messageBox({ message = "Bleed tick for " .. math.round(damage, 2) })
    end
end

local function calcBleedDamage(damage)
    return damage * common.config.bleedMultiplier
end

--[[ Perform bleed (axe)
--]]
function this.perform(damage, target, targetActor, weaponSkill)
    local damageDone
    local maxStacks = 1

    local bleedChanceRoll = math.random(100)
    if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
        if common.config.weaponTier4.bleedChance >= bleedChanceRoll then
            damageDone = calcBleedDamage(damage)
            maxStacks = common.config.weaponTier4.maxBleedStack
        end
    elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
        if common.config.weaponTier3.bleedChance >= bleedChanceRoll then
            damageDone = calcBleedDamage(damage)
            maxStacks = common.config.weaponTier3.maxBleedStack
        end
    elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
        if common.config.weaponTier2.bleedChance >= bleedChanceRoll then
            damageDone = calcBleedDamage(damage)
            maxStacks = common.config.weaponTier2.maxBleedStack
        end
    elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
        if common.config.weaponTier1.bleedChance >= bleedChanceRoll then
            damageDone = calcBleedDamage(damage)
        end
    else
        return
    end

    if damageDone ~= nil then
        if common.currentlyBleeding[target.id] == nil then
            -- we don't have any bleed at all, start one
            local damageTick = damageDone / 5
            common.currentlyBleeding[target.id] = {
                stacks = 1,
                timer = timer.start({
                    duration = 1,
                    callback = function ()
                        if targetActor then
                            bleedTick(damageTick, targetActor)
                        end
                    end,
                    iterations = 5
                })
            }
        elseif common.currentlyBleeding[target.id].timer.state == timer.expired then
            -- this bleed has finished, start a new one
            local damageTick = damageDone / 5
            common.currentlyBleeding[target.id] = {
                stacks = 1,
                timer = timer.start({
                    duration = 1,
                    callback = function ()
                        if targetActor then
                            bleedTick(damageTick, targetActor)
                        end
                    end,
                    iterations = 5
                })
            }
        else
            -- we have an active bleed timer, increment stacks if not max and restart timer
            if common.currentlyBleeding[target.id].stacks < maxStacks then
                local newStacks = common.currentlyBleeding[target.id].stacks + 1
                common.currentlyBleeding[target.id].timer:cancel()
                damageDone = damageDone * newStacks
                local damageTick = damageDone / 5
                common.currentlyBleeding[target.id].stacks = newStacks
                common.currentlyBleeding[target.id].timer = timer.start({
                    duration = 1,
                    callback = function ()
                        if targetActor then
                            bleedTick(damageTick, targetActor)
                        end
                    end,
                    iterations = 5
                })
            end
        end

        return damageDone
    else
        return
    end
end

return this