local bs = require("BeefStranger.Fist of Azuras Star.common")

bs.perkDesc.sanctifier =
[[Sanctifier:
    +5% Chance to Knockdown Undead/Corprus
    +Stacking Sanctified Flame effect on Undead[0.5]/Corprus[1.25]
    +Absorb Undead/Corprus Soul / 4 as Magicka on Kill
    +Deal 15% More Damage to Members of the Temple
    +Deal 25% More Damage to Members of the Sixth House
    -Deal 15% Less Damage to the Dunmeri
    -Deal 25% Less Damage to Ashlanders]]

local sanctify = {}

---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function applySanctifyEffect(target)
    local max = bs.SANCTIFY.FLAME_UNDEAD_MAG
    local duration = bs.SANCTIFY.FLAME_UNDEAD_DUR
    if bs.isCorprus(target) then
        max = bs.SANCTIFY.FLAME_CORPRUS
        duration = bs.SANCTIFY.FLAME_CORPRUS_DUR
    end
    if bs.isTribunal(target.reference) then
        max = bs.SANCTIFY.FLAME_TRIBUNAL
        duration = bs.SANCTIFY.FLAME_TRIBUNAL_DUR
    end

    tes3.applyMagicSource {
        reference = tes3.mobilePlayer,
        target = target,
        name = "Sanctifying_Flame",
        effects = {
            {
                id = tes3.effect.fireDamage,
                duration = duration,
                min = 0.5,
                max = max,
                rangeType = tes3.effectRange.touch,
            },
            {
                id = tes3.effect.turnUndead,
                duration = 5,
                min = 10,
                max = 10,
                rangeType = tes3.effectRange.touch
            }
        },
    }
end

---@param e damageEventData|damageHandToHandEventData
---@param dmg number
---@param absorbAmount number
---@return number dmg
---@return number absorbAmount
function sanctify.onDmg(e, dmg, absorbAmount)
    if bs.isUndead(e.mobile) or bs.isDaedra(e.mobile) or bs.isTribunal(e.reference) then
        applySanctifyEffect(e.mobile)
        if bs.roll() <= bs.SANCTIFY.KNOCKDOWN_CHANCE then e.mobile:hitStun({knockDown = true}) end
    end
    if bs.isDunmer(e.mobile) then dmg = dmg * bs.SANCTIFY.DMG_DUNMER end
    if bs.isAshlander(e.mobile) then dmg = dmg * bs.SANCTIFY.DMG_ASHLANDER end
    if bs.isTemple(e.mobile) then dmg = dmg * bs.SANCTIFY.DMG_TEMPLE end
    if bs.isSixthHouse(e.mobile) then dmg = dmg * bs.SANCTIFY.DMG_SIXTH end
    if bs.isTribunal(e.reference) then
        absorbAmount = absorbAmount * 3
        tes3.playSound{sound = "ghostgate sound"}
    end
    return dmg, absorbAmount
end

--- @param e damagedEventData
function sanctify.onKill(e)
    if (bs.isUndead(e.mobile) or bs.isDaedra(e.mobile)) then
        if e.source == tes3.damageSource.attack then
            tes3.modStatistic{reference = tes3.mobilePlayer, name = "magicka", limitToBase = true, current = e.mobile.object.soul / bs.SANCTIFY.SOUL_ABSORB_MOD }
            tes3.createVisualEffect({ lifespan = 3, object = bs.vfx.soulTrap, reference = e.mobile.reference, scale = 0.15, verticalOffset = 100 })
        end
    end
end



---comment
---@param e damageEventData|damageHandToHandEventData
---@param dmg number
---@return number dmg
function sanctify.playerDmg(e, dmg)
    if bs.isTribunal(e.reference) then
        dmg = dmg * bs.SANCTIFY.DMG_TAKE_TRIBUNAL
    end
    return dmg
end

return sanctify
