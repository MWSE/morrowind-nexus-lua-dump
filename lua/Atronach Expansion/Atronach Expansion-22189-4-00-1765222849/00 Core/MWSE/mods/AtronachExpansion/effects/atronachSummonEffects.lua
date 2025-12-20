local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("summonAshGolem", 7700)
tes3.claimSpellEffectId("summonBoneGolem", 7701)
tes3.claimSpellEffectId("summonCrystalGolem", 7702)
tes3.claimSpellEffectId("summonFleshAtronach", 7703)
tes3.claimSpellEffectId("summonIronAtronach", 7704)
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
		creatureId = "mdAE_Cre_AshGolem_S",
		icon = "mdAE\\tx_s_smmn_ashglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonBoneGolem,
		name = "Summon Bone Golem",
		description = getDescription("Bone Golem"),
		baseCost = 16,
		creatureId = "mdAE_Und_BoneGolem_S",
		icon = "mdAE\\tx_s_smmn_bneglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCrystalGolem,
		name = "Summon Crystal Golem",
		description = getDescription("Crystal Golem"),
		baseCost = 42,
		creatureId = "mdAE_Cre_CrystalGolem_S",
		icon = "mdAE\\tx_s_smmn_crstlglm.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonFleshAtronach,
		name = "Summon Flesh Atronach",
		description = getDescription("Flesh Atronach"),
		baseCost = 36,
		creatureId = "mdAE_Dae_FleshAtro_S",
		icon = "mdAE\\tx_s_smmn_flhatrnh.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonIronAtronach,
		name = "Summon Iron Atronach",
		description = getDescription("Iron Atronach"),
		baseCost = 24,
		creatureId = "mdAE_Dae_IronAtronach_S",
		icon = "mdAE\\tx_s_smmn_irnatrnh.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonSwampMyconid,
		name = "Summon Swamp Myconid",
		description = getDescription("Swamp Myconid"),
		baseCost = 12,
		creatureId = "mdAE_Cre_SwampMyconid_S",
		icon = "mdAE\\tx_s_smmn_swpmycnd.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonTelvanniMyconid,
		name = "Summon Telvanni Myconid",
		description = getDescription("Telvanni Myconid"),
		baseCost = 50,
		creatureId = "mdAE_Cre_TelMyconid_S",
		icon = "mdAE\\tx_s_smmn_telmycnd.dds"
	})
end

event.register("magicEffectsResolved", addSummoningEffects)