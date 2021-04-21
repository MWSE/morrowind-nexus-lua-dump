local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("summonCreeper", 420)

local function getDescription(creatureName)
    return "This effect summons forth the ".. creatureName ..", a Daedric"..
    " merchant from the planes of Oblivion."
end

local function addSummoningEffects()
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCreeper,
		name = "Summon Creeper",
		description = "This effect summons forth Creeper, a daedric merchant from the planes of Oblivion.",
		baseCost = 175, -- this is how much mana the spell will cost
		creatureId = "scamp_creeper_summon",
		icon = "s\\tx_s_smmn_scamp.tga",
		allowEnchanting = false,
		allowSpellmaking = false,
	})
end

event.register("magicEffectsResolved", addSummoningEffects)