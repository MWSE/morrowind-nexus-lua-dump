local defaultConfig = {
    enabled = true,
    guardsOnly = false,
    contrabandDwemer = true,
    contrabandDwemerNoGear = true,
    contrabandEbony = true,
    contrabandGlass = true,
    contrabandList = {
		potion_skooma_01 = true,
		PC_m1_K1_RP5_Skooma = true,
		TR_m2_q_14_NalethSkooma = true,
		T_De_Drink_PunavitResin_01 = true,
		T_De_Drink_PunavitJug = true,
		apparatus_a_spipe_01 = true,
		apparatus_a_spipe_tsiya = true,
		T_Com_SkoomaPipe_01 = true,
		ingred_moon_sugar_01 = true,
		AB_Misc_SoulGemBlack = true,
		bk_ArkayTheEnemy = true,
		bk_NGastaKvataKvakis_c = true,
		bk_NGastaKvataKvakis_o = true,
		bk_progressoftruth = true,
		bk_vampiresofvvardenfell1 = true,
		bk_vampiresofvvardenfell2 = true,
		bk_vivec_murders = true,
		T_Bk_SakaPunikaTR = true,
	},
    notContrabandList = {

    },
	smugglerList = {

	}
}

local mwseConfig = mwse.loadConfig("dropcrime", defaultConfig)

return mwseConfig;