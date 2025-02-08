local framework = require("OperatorJack.MagickaExpanded")
local leech = require("chantox.LeechFx.leech")

local this = { id = 902 }
tes3.claimSpellEffectId("fatigueLeech", this.id)

local function addFatigueLeechEffect()
    framework.effects.mysticism.createBasicEffect {
        -- Base information
        id = tes3.effect.fatigueLeech,
        name = "Fatigue Leech",
        description = "Applies fatigue leech to the subject, restoring their fatigue for a percentage of the attack damage they deal.",

        -- Basic dials
        baseCost = 1,

        -- Flags
        allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        canCastTouch = true,
        canCastTarget = true,

        -- Graphics
        icon = "s\\tx_s_fatigue_leech.tga",

        -- Required callbacks.
        onTick = function(e) e:trigger() end,
    }
end
event.register("magicEffectsResolved", addFatigueLeechEffect)

---Create dev spell for testing
local function registerSpells()
    framework.spells.createBasicSpell {
        id = "LEF_Leech",
        name = "Fatigue Leech",
        effect = tes3.effect.fatigueLeech,
        rangeType = tes3.effectRange.self,
        min = 100,
        max = 100,
        duration = 60,
        magickaCost = 10
    }
end
event.register("MagickaExpanded:Register", registerSpells)

---Fatigue leech on weapon damage
---@param e damageEventData
local function onDamage(e)
    leech {
        effect = tes3.effect.fatigueLeech,
        source = e.source,
        attacker = e.attacker,
        damage = e.damage,
        mobile = e.mobile,
        statistic = "fatigue"
    }
end
event.register(tes3.event.damage, onDamage)

---Fatigue leech on hand to hand damage
---@param e damageHandToHandEventData
local function onDamageHandtoHand(e)
    leech {
        effect = tes3.effect.fatigueLeech,
        attacker = e.attacker,
        damage = e.fatigueDamage,
        mobile = e.mobile,
        statistic = "fatigue"
    }
end
event.register(tes3.event.damageHandToHand, onDamageHandtoHand)

return this
