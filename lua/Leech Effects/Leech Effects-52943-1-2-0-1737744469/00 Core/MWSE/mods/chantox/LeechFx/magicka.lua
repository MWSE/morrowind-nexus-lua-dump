local framework = require("OperatorJack.MagickaExpanded")
local leech = require("chantox.LeechFx.leech")

local this = { id = 901 }
tes3.claimSpellEffectId("magickaLeech", this.id)

local function addMagickaLeechEffect()
    framework.effects.mysticism.createBasicEffect {
        -- Base information
        id = tes3.effect.magickaLeech,
        name = "Magicka Leech",
        description = "Applies magicka leech to the subject, restoring their magicka for a percentage of the attack damage they deal.",

        -- Basic dials
        baseCost = 5,

        -- Flags
        canCastSelf = true,
        canCastTouch = true,
        canCastTarget = true,

        -- Graphics
        icon = "s\\tx_s_magicka_leech.tga",

        -- Required callbacks.
        onTick = function(e) e:trigger() end,
    }
end
event.register("magicEffectsResolved", addMagickaLeechEffect)

---Create dev spell for testing
local function registerSpells()
    framework.spells.createBasicSpell {
        id = "LEM_Leech",
        name = "Mana Leech",
        effect = tes3.effect.magickaLeech,
        rangeType = tes3.effectRange.self,
        min = 100,
        max = 100,
        duration = 60,
        magickaCost = 10
    }
end
event.register("MagickaExpanded:Register", registerSpells)

---Magicka leech on weapon damage
---@param e damageEventData
local function onDamage(e)
    leech {
        effect = tes3.effect.magickaLeech,
        source = e.source,
        attacker = e.attacker,
        damage = e.damage,
        mobile = e.mobile,
        statistic = "magicka"
    }
end
event.register(tes3.event.damage, onDamage)

---Magicka leech on hand to hand damage
---@param e damageHandToHandEventData
local function onDamageHandtoHand(e)
    leech {
        effect = tes3.effect.magickaLeech,
        attacker = e.attacker,
        damage = e.fatigueDamage,
        mobile = e.mobile,
        statistic = "magicka"
    }
end
event.register(tes3.event.damageHandToHand, onDamageHandtoHand)

return this
