local bs = require("BeefStranger.Fist of Azuras Star.common")

---@type bsAzuraStealth
local STEALTH = bs.STEALTH

---@class bs_Azura_Stealth
local this = {}
local stealthEffect
local stealthAbility

function this.abilityCreate()
    stealthAbility = tes3.createObject({ id = "AzuraStealthPerk", objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(stealthAbility)
    stealthAbility.name = "STEALTH PERK TEST"
    stealthAbility.castType = tes3.spellType.ability

    stealthEffect = stealthAbility.effects[1]
    stealthEffect.rangeType = tes3.effectRange.self
    stealthEffect.id = tes3.effect.chameleon
end
event.register(tes3.event.initialized, this.abilityCreate)


function this.chameleon()
    if tes3.mobilePlayer.isSneaking and bs.fistsRaised() then
        local mag = bs.h2h:base() * STEALTH.HIDE_H2H_MULT + tes3.mobilePlayer.sneak.base * STEALTH.HIDE_SNEAK_MULT
        stealthEffect.min = mag
        stealthEffect.max = mag
        tes3.addSpell{spell = stealthAbility, mobile = tes3.mobilePlayer}
    else
        tes3.removeSpell({spell = stealthAbility, mobile = tes3.mobilePlayer})
    end
end

---comments
---@return number
function this.moveSpeed(speed)
    if not bs.fistsRaised() then return speed end
        if tes3.mobilePlayer.isSneaking and bs.isKeyDown(tes3.scanCode.lShift) then
            speed = speed * STEALTH.MOVE_MULT
            tes3.modStatistic{name = "fatigue", reference = tes3.mobilePlayer, current = -0.05, limitToBase = true}
        end
    return speed
end


---@param e damageEventData|damageHandToHandEventData
function this.playerDmg(e, dmg)

    if e.mobile.isPlayerHidden then
        debug.log(e.mobile.isPlayerHidden)
        debug.log(e.fatigueDamage)
        if e.fatigueDamage then
            e.mobile:applyDamage({damage = dmg * STEALTH.DMG_HEALTH_MULT, playerAttack = true})
            e.mobile:hitStun({knockDown = true})

            dmg = 0
        else
            dmg = dmg * 3
        end
    end
    if e.mobile.isPlayerDetected then
        debug.log(e.mobile.isPlayerDetected)
        dmg = dmg * STEALTH.DMG_DETECTED_MULT
    end
    debug.log(dmg)
    return dmg
end


return this