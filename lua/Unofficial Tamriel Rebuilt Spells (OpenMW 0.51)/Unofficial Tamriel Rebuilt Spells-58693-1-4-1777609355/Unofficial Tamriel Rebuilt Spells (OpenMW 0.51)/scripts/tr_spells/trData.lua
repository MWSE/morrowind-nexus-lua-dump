local data = {}

data.FEET_TO_UNITS = 22.1

-- effect ID -> creature ID 
data.SUMMON_CREATURES = {
	["t_summon_devourer"]          = "t_dae_cre_devourer_01",
	["t_summon_dremarch"]          = "t_dae_cre_drem_arch_01",
	["t_summon_dremcast"]          = "t_dae_cre_drem_cast_01",
	["t_summon_guardian"]          = "t_dae_cre_guardian_01",
	["t_summon_lesserclfr"]        = "t_dae_cre_lesserclfr_01",
	["t_summon_ogrim"]             = "ogrim",
	["t_summon_seducer"]           = "t_dae_cre_seduc_01",
	["t_summon_seducerdark"]       = "t_dae_cre_seducdark_02",
	["t_summon_vermai"]            = "t_dae_cre_verm_01",
	["t_summon_atrostormmon"]      = "t_dae_cre_monarchst_01",
	["t_summon_icewraith"]         = "t_sky_cre_icewr_01",
	["t_summon_dwespectre"]        = "dwarven ghost",
	["t_summon_steamcent"]         = "centurion_steam",
	["t_summon_spidercent"]        = "centurion_spider",
	["t_summon_welkyndspirit"]     = "t_ayl_cre_welkspr_01",
	["t_summon_auroran"]           = "t_dae_cre_auroran_01",
	["t_summon_herne"]             = "t_dae_cre_herne_01",
	["t_summon_morphoid"]          = "t_dae_cre_morphoid_01",
	["t_summon_draugr"]            = "t_sky_und_drgr_01",
	["t_summon_spriggan"]          = "t_sky_cre_spriggan_01",
	["t_summon_boneldgr"]          = "t_mw_und_boneldgr_01",
	["t_summon_ghost"]             = "t_cyr_und_ghst_01",
	["t_summon_wraith"]            = "t_cyr_und_wrth_01",
	["t_summon_barrowguard"]       = "t_cyr_und_mum_01",
	["t_summon_minobarrowguard"]   = "t_cyr_und_minobarrow_01",
	["t_summon_skeletonchampion"]  = "t_glb_und_skelcmpgls_01",
	["t_summon_atrofrostmon"]      = "t_dae_cre_monarchfr_01",
	["t_summon_spiderdaedra"]      = "t_dae_cre_spiderdae_01",
}

-- spell ID -> magic effect
data.SUMMON_EFFECTS = {
	["t_com_cnj_summondevourer"]          = "t_summon_devourer",
	["t_com_cnj_summondremoraarcher"]     = "t_summon_dremarch",
	["t_com_cnj_summondremoracaster"]     = "t_summon_dremcast",
	["t_com_cnj_summonguardian"]          = "t_summon_guardian",
	["t_com_cnj_summonlesserclannfear"]   = "t_summon_lesserclfr",
	["t_com_cnj_summonogrim"]             = "t_summon_ogrim",
	["t_com_cnj_summonseducer"]           = "t_summon_seducer",
	["t_com_cnj_summonseducerdark"]       = "t_summon_seducerdark",
	["t_com_cnj_summonvermai"]            = "t_summon_vermai",
	["t_com_cnj_summonstormmonarch"]      = "t_summon_atrostormmon",
	["t_nor_cnj_summonicewraith"]         = "t_summon_icewraith",
	["t_dwe_cnj_uni_summondwespectre"]    = "t_summon_dwespectre",
	["t_dwe_cnj_uni_summonsteamcent"]     = "t_summon_steamcent",
	["t_dwe_cnj_uni_summonspidercent"]    = "t_summon_spidercent",
	["t_ayl_cnj_summonwelkyndspirit"]     = "t_summon_welkyndspirit",
	["t_com_cnj_summonauroran"]           = "t_summon_auroran",
	["t_com_cnj_summonherne"]             = "t_summon_herne",
	["t_com_cnj_summonmorphoid"]          = "t_summon_morphoid",
	["t_nor_cnj_summondraugr"]            = "t_summon_draugr",
	["t_nor_cnj_summonspriggan"]          = "t_summon_spriggan",
	["t_de_cnj_summongreaterbonelord"]    = "t_summon_boneldgr",
	["t_cyr_cnj_summonghost"]             = "t_summon_ghost",
	["t_cyr_cnj_summonwraith"]            = "t_summon_wraith",
	["t_cyr_cnj_summonbarrowguard"]       = "t_summon_barrowguard",
	["t_cyr_cnj_summonminobarrowguard"]   = "t_summon_minobarrowguard",
	["t_com_cnj_summonskeletonchamp"]     = "t_summon_skeletonchampion",
	["t_com_cnj_summonfrostmonarch"]      = "t_summon_atrofrostmon",
	["t_com_cnj_summonspiderdaedra"]      = "t_summon_spiderdaedra",
	-- NPC only
	["t_cr_cnj_aylsorcksummon1"]          = "t_summon_auroran",
	["t_cr_cnj_aylsorcksummon3"]          = "t_summon_welkyndspirit",
}

-- spell ID -> bound
data.BOUND_ITEMS = {
	["t_bound_greaves"] = {
		spellId   = "t_com_cnj_boundgreaves",
		items     = { "t_com_bound_greaves_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.Greaves },
	},
	["t_bound_waraxe"] = {
		spellId   = "t_com_cnj_boundwaraxe",
		items     = { "t_com_bound_waraxe_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_warhammer"] = {
		spellId   = "t_com_cnj_boundwarhammer",
		items     = { "t_com_bound_warhammer_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_pauldrons"] = {
		spellId   = "t_com_cnj_boundpauldron",
		items     = { "t_com_bound_pauldronl_01", "t_com_bound_pauldronr_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.LeftPauldron, types and types.Actor.EQUIPMENT_SLOT.RightPauldron },
	},
	["t_bound_greatsword"] = {
		spellId   = "t_com_cnj_boundgreatsword",
		items     = { "t_com_bound_greatsword_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	-- NPC-only bound
	["t_bound_hammerresdayn"] = {
		spellId   = "t_de_cnj_uni_boundhammerresdayn",
		items     = { "t_com_bound_warhammer_01" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_razorresdayn"] = {
		spellId   = "t_de_cnj_uni_boundrazororesdayn",
		items     = { "bound_dagger" },
		slots     = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	-- vanilla
	["t_bound_battleaxe"] = {
		items = { "bound_battleaxe" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_boots"] = {
		items = { "bound_boots" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.Boots },
	},
	["t_bound_cuirass"] = {
		items = { "bound_cuirass" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.Cuirass },
	},
	["t_bound_dagger"] = {
		items = { "bound_dagger" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_gloves"] = {
		items = { "bound_lefgauntlet", "bound_rigauntlet" },
		slots = {
			types and types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
			types and types.Actor.EQUIPMENT_SLOT.RightGauntlet,
		},
	},
	["t_bound_helm"] = {
		items = { "bound_helm" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.Helmet },
	},
	["t_bound_longbow"] = {
		items = { "bound_longbow" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_longsword"] = {
		items = { "bound_longsword" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_mace"] = {
		items = { "bound_mace" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
	["t_bound_shield"] = {
		items = { "bound_shield" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedLeft },
	},
	["t_bound_spear"] = {
		items = { "bound_spear" },
		slots = { types and types.Actor.EQUIPMENT_SLOT.CarriedRight },
	},
}

data.BOUND_BASE_WEIGHTS = {
	-- TR
	["t_com_bound_greaves_01"]    = 54,
	["t_com_bound_waraxe_01"]     = 72,
	["t_com_bound_warhammer_01"]  = 96,
	["t_com_bound_pauldronl_01"]  = 30,
	["t_com_bound_pauldronr_01"]  = 30,
	["t_com_bound_greatsword_01"] = 81,
	-- Vanilla
	["bound_battleaxe"]  = 90,
	["bound_boots"]      = 60,
	["bound_cuirass"]    = 90,
	["bound_dagger"]     = 9,
	["bound_lefgauntlet"]= 15,
	["bound_rigauntlet"] = 15,
	["bound_helm"]       = 15,
	["bound_longbow"]    = 24,
	["bound_longsword"]  = 60,
	["bound_mace"]       = 45,
	["bound_shield"]     = 45,
	["bound_spear"]      = 42,
}
-- missing:
-- Daedric Shortsword
-- Daedric Tanto
-- Daedric Wakizashi
-- Daedric Katana
-- Daedric Dai-katana
-- Daedric Staff
-- Daedric Club
-- Daedric Tower Shield

data.KYNE_MARKER_ID = "t_aid_kyneinterventionmarker"

data.KYNE_MARKERS = {
	['TR_Mainland.esm'] = {
		{
			x = -101,
			y = 11,
			position = { -820175.44, 94423.58, 775.2521 },
			rotation = 5.5833084,--2.4417157,
		},
	}
}

data.PASSWALL_FORBIDDEN_DOORS = { "trap", "cell", "tent", "grate", "bearskin", "mystical", "skyrender", "vault", }

data.PASSWALL_FORBIDDEN_MODELS = {
	"force", "gg_", "water", "blight", "_grille_", "field",
	"editormarker", "barrier", "_portcullis_", "bm_ice_wall",
	"_mist", "_web", "_cryst", "collision", "grate", "shield",
	"smoke", "ex_colony_ouside_tend01", "akula", "act_sotha_green",
	"act_sotha_red", "lava", "bug", "clearbox",
}

-- Spell tomes
data.TOME_DEFS = {
	{
		tomeId = "spelltome_tr_conj_bound",
		message = "You have learned several Bound Weapons and Armor spells from this tome.",
		spells = {
			"t_com_cnj_boundgreaves",
			"t_com_cnj_boundwaraxe",
			"t_com_cnj_boundwarhammer",
			--"t_de_cnj_uni_boundhammerresdayn",
			--"t_de_cnj_uni_boundrazororesdayn",
			"t_com_cnj_boundpauldron",
			"t_com_cnj_boundgreatsword",
		},
	},
	{
		tomeId = "spelltome_tr_conj_summon",
		message = "You have learned several Summon spells from this tome.",
		spells = {
			"t_com_cnj_summondevourer",
			"t_com_cnj_summondremoraarcher",
			"t_com_cnj_summondremoracaster",
			"t_com_cnj_summonguardian",
			"t_com_cnj_summonlesserclannfear",
			"t_com_cnj_summonogrim",
			"t_com_cnj_summonseducer",
			"t_com_cnj_summonseducerdark",
			"t_com_cnj_summonvermai",
			"t_com_cnj_summonstormmonarch",
			"t_nor_cnj_summonicewraith",
			--"t_dwe_cnj_uni_summondwespectre",
			--"t_dwe_cnj_uni_summonsteamcent",
			--"t_dwe_cnj_uni_summonspidercent",
			"t_ayl_cnj_summonwelkyndspirit",
			"t_com_cnj_summonauroran",
			"t_com_cnj_summonherne",
			"t_com_cnj_summonmorphoid",
			"t_nor_cnj_summondraugr",
			"t_nor_cnj_summonspriggan",
			"t_de_cnj_summongreaterbonelord",
			"t_cyr_cnj_summonghost",
			"t_cyr_cnj_summonwraith",
			"t_cyr_cnj_summonbarrowguard",
			"t_cyr_cnj_summonminobarrowguard",
			"t_com_cnj_summonskeletonchamp",
			"t_com_cnj_summonfrostmonarch",
			"t_com_cnj_summonspiderdaedra",
			-- "t_dae_cnj_uni_corruptionsummon",
		},
	},
	{
		tomeId = "spelltome_tr_myst",
		message = "You have learned several Mysticism spells from this tome.",
		spells = {
			"t_nor_mys_kynesintervention",
			"t_com_mys_blink",
			"t_com_mys_uni_passwall",
			"t_com_mys_reflectdamage",
			"t_com_mys_banishdaedra",
			"t_com_mys_insight",
			-- "t_com_mys_detecthumanoid",
			-- "t_com_mys_detectenemy",
			-- "t_com_mys_detectinvisibility",
			-- "t_arg_mys_bloodmagic",
			-- "t_com_mys_detectvaluables",
			-- "t_com_mys_magickaward",
		},
	},
	{
		tomeId = "spelltome_tr_rest",
		message = "You have learned several Restoration spells from this tome.",
		spells = {
			"t_com_res_weaponresartus",
			"t_com_res_armorresartus",
		},
	},
	--{
	--	tomeId = "spelltome_tr_alt",
	--	message = "You have learned several Alteration spells from this tome.",
	--	spells = {
	--		"t_ayl_alt_radiantshield",
	--		--"t_cr_alt_auroranshield",
	--		"t_cr_alt_aylsorcklightshield",
	--	},
	--},
	{
		tomeId = "spelltome_tr_ilu",
		message = "You have learned several Illusion spells from this tome.",
		spells = {
			"t_com_ilu_distractcreature",
			"t_com_ilu_distracthumanoid",
		},
	},
}

return data