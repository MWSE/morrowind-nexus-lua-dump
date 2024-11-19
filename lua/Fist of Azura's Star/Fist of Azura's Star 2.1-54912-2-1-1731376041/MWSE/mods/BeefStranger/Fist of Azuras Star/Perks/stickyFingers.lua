local bs = require("BeefStranger.Fist of Azuras Star.common")
---@class bsAzuraSticky
local STICKY = {
    STEAL_CHANCE_MULTI = 0.40,
    DMG_DEAL_MULT = 0.85,
    DMG_DEAL_FATIGUE_MULT = 0.65,
    MAX_ATTEMPTS = 3,
}
local sticky = {}

---@param e damageEventData|damageHandToHandEventData
function sticky.onDmg(e)
    local temp = e.reference.tempData; temp.bsStickyCount = temp.bsStickyCount or 0
    local stealCount = e.reference.tempData.bsStickyCount
    local dmg = e.damage or e.fatigueDamage
    local target = e.mobile
    local isFatigue = e.fatigueDamage ~= nil
    local weapon = target.readiedWeapon and target.readiedWeapon.object
    local shield = target.readiedShield and target.readiedShield.object
    local roll = bs.roll()

    -- debug.log(bs.h2h:current() * STICKY.STEAL_CHANCE_MULTI)

    if e.reference.tempData.bsStickyCount < STICKY.MAX_ATTEMPTS then
        if roll < bs.h2h:current() * STICKY.STEAL_CHANCE_MULTI and #target.inventory > 0 then
            local randItem = target.inventory[math.random(#target.inventory)].object
            local count = (randItem.isGold and 25) or (randItem.isAmmo and 25) or 1

            -- debug.log(stealCount)
            -- debug.log(roll)
            if weapon == randItem or randItem == shield then
                if roll < 15 then
                    tes3.transferItem({ from = target, to = tes3.mobilePlayer, item = randItem, count = count })
                    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, math.min(1, randItem.value / 5 * count))
                    temp.bsStickyCount = temp.bsStickyCount + 1
                end
            else
                if not randItem.script then
                    tes3.transferItem({ from = target, to = tes3.mobilePlayer, item = randItem, count = count })
                    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, math.min(1, randItem.value / 5 * count))
                    temp.bsStickyCount = temp.bsStickyCount + 1
                end
            end
            -- bs.inspect(temp)
            -- debug.log(randItem)
        end
    end

    if isFatigue then
        dmg = dmg * STICKY.DMG_DEAL_FATIGUE_MULT
    else
        dmg = dmg * STICKY.DMG_DEAL_MULT
    end

    -- debug.log(dmg)
    return dmg
end

return sticky