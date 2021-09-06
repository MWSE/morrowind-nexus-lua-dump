local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("summonGoblinGrunt", 223)
tes3.claimSpellEffectId("summonGoblinOfficer", 224)
tes3.claimSpellEffectId("summonHulkingFabricant", 225)
tes3.claimSpellEffectId("summonAscendedSleeper", 226)
tes3.claimSpellEffectId("summonDraugr", 227)
tes3.claimSpellEffectId("summonLich", 228)

tes3.claimSpellEffectId("summonOgrim", 252)
tes3.claimSpellEffectId("summonWarDurzog", 253)
tes3.claimSpellEffectId("summonSpriggan", 254)
tes3.claimSpellEffectId("summonCenturionSteam", 255)
tes3.claimSpellEffectId("summonCenturionProjectile", 256)
tes3.claimSpellEffectId("summonAshGhoul", 257)
tes3.claimSpellEffectId("summonAshZombie", 258)
tes3.claimSpellEffectId("summonAshSlave", 259)
tes3.claimSpellEffectId("summonCenturionSpider", 260)
tes3.claimSpellEffectId("summonImperfect", 261)
tes3.claimSpellEffectId("summonGoblinWarchief", 262)

tes3.claimSpellEffectId("callWerewolf", 326)

local function getCallDescription(creatureName)
	return "This effect calls a " .. creatureName .. " from nature."..
    " It appears six feet in front of the caster and attacks any entity that attacks the caster until"..
    " the effect ends or the summoning is killed. At death, or when the effect ends, the summoning"..
    " disappears, returning to nature."
end

local function getDescription(creatureName)
    return "This effect summons a ".. creatureName .." from Oblivion."..
    " It appears six feet in front of the caster and attacks any entity that attacks the caster until"..
    " the effect ends or the summoning is killed. At death, or when the effect ends, the summoning"..
    " disappears, returning to Oblivion. If summoned in town, the guards will attack you and the summoning on sight."
end

local function addSummoningEffects()
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.callWerewolf,
		name = "Call Werewolf",
		description = getCallDescription("Werewolf"),
		baseCost = 30,
		creatureId = "OJ_ME_Werewolf",
		icon = "RFD\\RFD_sm_wwolf.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonGoblinGrunt,
		name = "Summon Goblin",
		description = getDescription("Goblin"),
		baseCost = 8,
		creatureId = "goblin_grunt",
		icon = "RFD\\RFD_gbl_common.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonGoblinOfficer,
		name = "Summon Goblin Officer",
		description = getDescription("Goblin Officer"),
		baseCost = 50,
		creatureId = "goblin_officer",
		icon = "RFD\\RFD_gbl_officer.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonGoblinWarchief,
		name = "Summon Goblin Warchief",
		description = getDescription("Goblin Warchief"),
		baseCost = 65,
		creatureId = "OJ_ME_GoblinWarchief",
		icon = "RFD\\RFD_gbl_warchief.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonHulkingFabricant,
		name = "Summon Hulking Fabricant",
		description = getDescription("Hulking Fabricant"),
		baseCost = 65,
		creatureId = "fabricant_hulking",
		icon = "RFD\\RFD_cc_hulking.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonImperfect,
		name = "Summon Imperfect",
		description = getDescription("Imperfect"),
		baseCost = 400,
		creatureId = "imperfect",
		icon = "RFD\\RFD_cc_imperfect.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonAscendedSleeper,
		name = "Summon Ascended Sleeper",
		description = getDescription("Ascended Sleeper"),
		baseCost = 60,
		creatureId = "ascended_sleeper",
		icon = "RFD\\RFD_6h_ascslp.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonDraugr,
		name = "Summon Draugr",
		description = getDescription("Draugr"),
		baseCost = 15,
		creatureId = "draugr",
		icon = "RFD\\RFD_un_draugr.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonLich,
		name = "Summon Lich",
		description = getDescription("Lich"),
		baseCost = 47,
		creatureId = "lich",
		icon = "RFD\\RFD_un_lich.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonOgrim,
		name = "Summon Ogrim",
		description = getDescription("Ogrim"),
		baseCost = 20,
		creatureId = "ogrim",
		icon = "RFD\\RFD_sm_ogrim.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonWarDurzog,
		name = "Summon War Durzog",
		description = getDescription("War Durzog"),
		baseCost = 25,
		creatureId = "durzog_war",
		icon = "RFD\\RFD_gbl_durzog.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonSpriggan,
		name = "Summon Spriggan",
		description = getDescription("Spriggan"),
		baseCost = 30,
		creatureId = "bm_spriggan",
		icon = "RFD\\RFD_sm_spriggan.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCenturionSteam,
		name = "Summon Steam Centurion",
		description = getDescription("Steam Centurion"),
		baseCost = 25,
		creatureId = "centurion_steam",
		icon = "RFD\\RFD_dw_steam.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCenturionProjectile,
		name = "Summon Centurion Archer",
		description = getDescription("Centurion Archer"),
		baseCost = 19,
		creatureId = "centurion_projectile",
		icon = "RFD\\RFD_dw_archer.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonCenturionSpider,
		name = "Summon Centurion Spider",
		description = getDescription("Centurion Spider"),
		baseCost = 6,
		creatureId = "centurion_spider",
		icon = "RFD\\RFD_dw_spider.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonAshGhoul,
		name = "Summon Ash Ghoul",
		description = getDescription("Ash Ghoul"),
		baseCost = 25,
		creatureId = "ash_ghoul",
		icon = "RFD\\RFD_6h_ghoul.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonAshZombie,
		name = "Summon Ash Zombie",
		description = getDescription("Ash Zombie"),
		baseCost = 10,
		creatureId = "ash_zombie",
		icon = "RFD\\RFD_6h_zombie.dds"
	})
	framework.effects.conjuration.createBasicSummoningEffect({
		id = tes3.effect.summonAshSlave,
		name = "Summon Ash Slave",
		description = getDescription("Ash Slave"),
		baseCost = 7,
		creatureId = "ash_slave",
		icon = "RFD\\RFD_6h_slave.dds"
	})
end

event.register("magicEffectsResolved", addSummoningEffects)