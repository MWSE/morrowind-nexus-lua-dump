local framework = require("OperatorJack.MagickaExpanded")

local this = {}

tes3.claimSpellEffectId("ave_BloodMagic", 3401)

local function add_effects()
	framework.effects.alteration.createBasicEffect({
		id = tes3.effect.ave_BloodMagic,
		name = "Blood Magic",
		description = "Pay health equal to magnitude in addition to the Magicka cost. Presence of this effect tends to make spells less expensive.",
		baseCost = 34,
        allowSpellmaking = true,
        allowEnchanting = false,
        hasNoDuration = true,
        nonRecastable = false,
        canCastTarget = false,
        canCastTouch = false,
        canCastSelf = true
	})
    print(string.format("[Vengyre] Magicka of the Third Era has created custom effects!"))
end

local spell_ids = {
    BloodMagic = "ave_blood_magic"
}

local function register_spells()
    framework.spells.createBasicSpell({
        id = spell_ids.BloodMagic,
        name = "Bloody Hell",
        effect = tes3.effect.ave_BloodMagic,
        rangeType = tes3.effectRange.self,
        min = 10,
        max = 10
    })
    print(string.format("[Vengyre] Magicka of the Third Era has registered spells!"))
end

function this.check_blood_magic(spell)
    local blood_magic = 0
    for i, effect in ipairs(spell.effects) do
       if effect.id == 3401 then
            blood_magic = blood_magic + effect.max
       end
    end
    if blood_magic > 0 then
        print(string.format("BM found!"))
    end
    return blood_magic
end


event.register("magicEffectsResolved", add_effects)
event.register("MagickaExpanded:Register", register_spells)

return this