local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local log = require("chantox.LeechFx.log")
local leech = require("chantox.LeechFx.leech")

-- Check Magicka Expanded framework.
if (framework == nil) then
    log:error("Magicka Expanded framework is not installed!")
    return nil
end

local this = {id = 900}
tes3.claimSpellEffectId("healthLeech", this.id)

local function addHealthLeechEffect()
    framework.effects.mysticism.createBasicEffect{
        -- Base information
        id = tes3.effect.healthLeech,
        name = "Health Leech",
        description = "Applies health leech to the subject, healing them for a percentage of the attack damage they deal.",

        -- Basic dials
        baseCost = 2,

        -- Flags
        allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        canCastTouch = true,
        canCastTarget = true,

        -- Graphics
        icon = "s\\tx_s_health_leech.tga",

        -- Required callbacks.
		onTick = function(e) e:trigger() end,
    }
end
event.register("magicEffectsResolved", addHealthLeechEffect)

---Create dev spell for testing
local function registerSpells()
    framework.spells.createBasicSpell{
        id = "LE_Leech",
        name = "Health Leech",
        effect = tes3.effect.healthLeech,
        range = tes3.effectRange.self,
        min = 100,
        max = 100,
        duration = 60,
        magickaCost = 10
    }
end
event.register("MagickaExpanded:Register", registerSpells)

---Health leech on weapon damage
---@param e damageEventData
local function onDamage(e)
    leech{
        effect = tes3.effect.healthLeech,
        source = e.source,
        attacker = e.attacker,
        damage = e.damage,
        mobile = e.mobile,
        statistic = "health"
    }
end
event.register(tes3.event.damage, onDamage)

---Health leech on hand to hand damage
---@param e damageHandToHandEventData
local function onDamageHandtoHand(e)
    leech{
        effect = tes3.effect.healthLeech,
        attacker = e.attacker,
        damage = e.fatigueDamage,
        mobile = e.mobile,
        statistic = "health"
    }
end
event.register(tes3.event.damageHandToHand, onDamageHandtoHand)

return this
