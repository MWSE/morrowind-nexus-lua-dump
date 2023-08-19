local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("flawedSummonDaedroth", 7800)



local function getDescription(creatureName)
    return "This effect supposedly summons a ".. creatureName .." from Oblivion."..
    " It should appear six feet in front of the caster and attack any entity that attacks the caster until"..
    " the effect ends or the summoning is killed. At death, or when the effect ends, the summoning"..
    " disappears, returning to Oblivion. But the enchantment appears to be flawed somehow..."
end
local function addSummoningEffects()
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.flawedSummonDaedroth,
		name = "Flawed Summon Daedroth",
		description = getDescription("Daedroth"),
		baseCost = 36,
		creatureId = "ABtv_Dae_Daedrat",
		icon = "OAAB\\e\\smn_daedrothFlawed.dds"
	})
end

event.register("magicEffectsResolved", addSummoningEffects)