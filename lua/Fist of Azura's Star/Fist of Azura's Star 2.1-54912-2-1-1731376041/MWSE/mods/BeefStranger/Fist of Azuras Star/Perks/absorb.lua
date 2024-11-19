local bs = require("BeefStranger.Fist of Azuras Star.common")

bs.perkDesc.healthAbsorb =
[[Siphon Health:
    +Absorb 10% of Damage Dealt as Magicka on Strike (Before Damage Reduction)
    +Absorb 10% of (Fatigue Damage / 5) as Magicka on Strike (Before Damage Reduction)
    -Deal 15% Less Damage

[Note: Damage Modifiers Stack with other Siphon Perks] ]]

bs.perkDesc.fatigueAbsorb =
[[Siphon Fatigue:
    +Absorb 20% of Damage Dealt as Fatigue on Strike (Before Damage Reduction)
    +Absorb 20% of (Fatigue Damage / 5) as Fatigue on Strike (Before Damage Reduction)
    -Deal 15% Less Damage

[Note: Damage Modifiers Stack with other Siphon Perks] ]]

bs.perkDesc.magickaAbsorb =
[[Siphon Magicka:
    +Absorb 20% of Damage Dealt as Magicka on Strike (Before Damage Reduction)
    +Absorb 20% of (Fatigue Damage / 5) as Magicka on Strike (Before Damage Reduction)
    -Deal 15% Less Damage

[Note: Damage Modifiers Stack with other Siphon Perks] ]]

local absorb = {}

---@param dmg number
---@param stat "health"|"magicka"|"fatigue"
---@param target tes3mobileNPC
---@return number dmg
function absorb.stat(dmg, stat, target)
    -- debug.log(dmg)
    if target[stat].current > 0 then
        local absorbModifier = {
            ["health"] = bs.ABSORB.HEALTH_MULT,
            ["magicka"] = bs.ABSORB.MAGICKA_MULT,
            ["fatigue"] = bs.ABSORB.FATIGUE_MULT,
        }
        local absorbAmount = dmg * absorbModifier[stat]

        tes3.modStatistic({ reference = target, current = -(absorbAmount), limitToBase = true, name = stat })
        tes3.modStatistic({ reference = tes3.mobilePlayer, current = absorbAmount, limitToBase = true, name = stat })
    end
    dmg = dmg * bs.ABSORB.DMG_DEAL_MULT
    return dmg
end

---@param e damageEventData|damageHandToHandEventData
function absorb.onDmg(e, dmg)

end

return absorb
