local this = {}

this.contraband = {
	["moonsugar"] = {
		["Race"] = {"Khajiit"},
		["Faction"] = {"Thieves Guild", "Camonna Tong"},
		["Items"] = {"ingred_moon_sugar_01"}
	},

	["skooma"] = {
		["Race"] = {"Khajiit"},
		["Faction"] = {"Thieves Guild", "Camonna Tong"},
		["Items"] = {"potion_skooma_01"}
	},

	["dwemer artifacts"] = {
		["Faction"] = {"Thieves Guild", "Camonna Tong", "Telvanni"},
		["Items"] = {"misc_dwrv_ark_cube00",
		"misc_dwrv_artifact00",
		"misc_dwrv_artifact10",
		"misc_dwrv_artifact20",
		"misc_dwrv_artifact30",
		"misc_dwrv_artifact40",
		"misc_dwrv_artifact50",
		"misc_dwrv_artifact60",
		"misc_dwrv_artifact70",
		"misc_dwrv_artifact80",
		"misc_dwrv_artifact_ils",
		"misc_dwrv_bowl00",
		"misc_dwrv_bowl00_uni",
		"misc_dwrv_coin00",
		"misc_dwrv_cursed_coin00",
		"misc_dwrv_gear00",
		"misc_dwrv_goblet00",
		"misc_dwrv_goblet00_uni",
		"misc_dwrv_goblet10",
		"misc_dwrv_goblet10_tgcp",
		"misc_dwrv_goblet10_uni",
		"misc_dwrv_mug_00",
		"misc_dwrv_mug_00_uni",
		"misc_dwrv_pitcher_00",
		"misc_dwrv_pitcher_00_uni",
		"misc_dwrv_weather",
		"misc_dwrv_weather2",
		"dwemer_boots",
		"dwemer_boots_of_flying",
		"dwemer_bracer_left",
		"dwemer_bracer_right",
		"dwemer_cuirass",
		"dwemer_greaves",
		"dwemer_helm",
		"dwemer_pauldron_left",
		"dwemer_pauldron_right",
		"dwemer_shield",
		"dwemer_shield_battle_unique",
		"dwarven axe_soultrap",
		"dwarven battle axe",
		"dwarven claymore",
		"dwarven crossbow",
		"dwarven halberd",
		"dwarven halberd_soultrap",
		"dwarven mace",
		"dwarven mace_salandas",
		"dwarven shortsword",
		"dwarven spear",
		"dwarven war axe",
		"dwarven war axe_redas",
		"dwarven warhammer",
		"dwarven_hammer_volendrung",
		"dwe_jinksword_curse_Unique"}
	},

	["raw ebony"] = {
		["Faction"] = {"Thieves Guild", "Camonna Tong"},
		["Items"] = {"ingred_Dae_cursed_raw_ebony_01", "ingred_raw_ebony_01"}
	},

	["raw glass"] = {
		["Faction"] = {"Thieves Guild", "Camonna Tong"},
		["Items"] = {"ingred_raw_glass_01",	"ingred_raw_glass_tinos"}
	}

}

this.trade = {
	["Apothecary Service"] = {tes3.objectType.ingredient},
	["Alchemist Service"] = {tes3.objectType.ingredient, tes3.objectType.apparatus},
	["Enchanter Service"] = {tes3.objectType.armor, tes3.objectType.clothing, tes3.objectType.weapon},
	["Publican"] = {tes3.objectType.npc},
	["Smith"] = {tes3.objectType.npc},
}

return this
