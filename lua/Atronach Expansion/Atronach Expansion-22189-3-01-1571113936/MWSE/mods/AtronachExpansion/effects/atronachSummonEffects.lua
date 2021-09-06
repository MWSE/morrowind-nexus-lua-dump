local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("summonAshGolem", 7700)
tes3.claimSpellEffectId("summonBoneGolem", 7701)
tes3.claimSpellEffectId("summonCrystalGolem", 7702)
tes3.claimSpellEffectId("summonFleshAtronach", 7703)
tes3.claimSpellEffectId("summonIronGolem", 7704)
tes3.claimSpellEffectId("summonSwampMyconid", 7705)
tes3.claimSpellEffectId("summonTelvanniMyconid", 7706)



local function getDescription(creatureName)
    return "This effect summons a ".. creatureName .." from Oblivion."..
    " It appears six feet in front of the caster and attacks any entity that attacks the caster until"..
    " the effect ends or the summoning is killed. At death, or when the effect ends, the summoning"..
    " disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight."
end
local function addSummoningEffects()
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonAshGolem,
		name = "Summon Ash Golem",
		description = getDescription("Ash Golem"),
		baseCost = 18,
		creatureId = "md_ash_golem_sm",
		icon = "mdAE\\tx_s_smmn_ashglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonBoneGolem,
		name = "Summon Bone Golem",
		description = getDescription("Bone Golem"),
		baseCost = 16,
		creatureId = "md_Bone_Golem_sm",
		icon = "mdAE\\tx_s_smmn_bneglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCrystalGolem,
		name = "Summon Crystal Golem",
		description = getDescription("Crystal Golem"),
		baseCost = 42,
		creatureId = "md_crystal_atronach_sm",
		icon = "mdAE\\tx_s_smmn_crstlglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonFleshAtronach,
		name = "Summon Flesh Atronach",
		description = getDescription("Flesh Atronach"),
		baseCost = 36,
		creatureId = "md_flesh_atronach_sm",
		icon = "mdAE\\tx_s_smmn_flhatrnh.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonIronGolem,
		name = "Summon Iron Golem",
		description = getDescription("Iron Golem"),
		baseCost = 24,
		creatureId = "md_iron_atronach_sm",
		icon = "mdAE\\tx_s_smmn_irnatrnh.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonSwampMyconid,
		name = "Summon Swamp Myconid",
		description = getDescription("Swamp Myconid"),
		baseCost = 12,
		creatureId = "md_swamp_atronach_sm",
		icon = "mdAE\\tx_s_smmn_swpmycnd.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonTelvanniMyconid,
		name = "Summon Telvanni Myconid",
		description = getDescription("Telvanni Myconid"),
		baseCost = 50,
		creatureId = "md_telvanni_atronach_sm",
		icon = "mdAE\\tx_s_smmn_telmycnd.dds"
	})
end

event.register("magicEffectsResolved", addSummoningEffects)