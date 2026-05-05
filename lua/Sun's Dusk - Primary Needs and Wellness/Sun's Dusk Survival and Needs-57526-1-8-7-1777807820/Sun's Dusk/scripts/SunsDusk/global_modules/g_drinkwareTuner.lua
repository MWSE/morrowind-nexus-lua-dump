do return end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Drinkware Tuner                                                      │
-- │ Tunes minOffset/minScale and maxOffset/maxScale for liquid visuals   │
-- │ MODE = 1 for minimum fill, MODE = 2 for maximum fill                 │
-- ╰──────────────────────────────────────────────────────────────────────╯

local WATER_STATIC_ID = "sd_food_water1"

-- MODE: 1 = min fill level, 2 = max fill level
local MODE = 1

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Paste your generated vesselOffsets here                              │
-- ╰──────────────────────────────────────────────────────────────────────╯
local done = {
	["t_he_greenceladonpot_01"] = true,
	["t_he_greenceladonteapot_01"] = true,
	["misc_com_bucket_01"] = true,
	["misc_com_pitcher_metal_01"] = true,
	["misc_com_tankard_01"] = true,
	["misc_com_wood_cup_01"] = true,
	["misc_com_wood_cup_02"] = true,
	["misc_com_bottle_01"] = true,
	["misc_com_bottle_02"] = true,
	["misc_com_bottle_03"] = true,
	["misc_com_bottle_04"] = true,
	["misc_com_bottle_05"] = true,
	["misc_com_metal_goblet_01"] = true,
	["misc_com_metal_goblet_02"] = true,
	["misc_com_bottle_06"] = true,
	["misc_com_bottle_07"] = true,
	["misc_com_bottle_08"] = true,
	["misc_com_bottle_09"] = true,
	["misc_com_bottle_10"] = true,
	["misc_com_bottle_11"] = true,
	["misc_com_bottle_12"] = true,
	["misc_com_bottle_13"] = true,
	["misc_com_bottle_14"] = true,
	["misc_com_bottle_15"] = true,
	["misc_de_goblet_01"] = true,
	["misc_de_goblet_02"] = true,
	["misc_de_goblet_03"] = true,
	["misc_de_goblet_04"] = true,
	["misc_de_goblet_05"] = true,
	["misc_de_goblet_06"] = true,
	["misc_de_goblet_07"] = true,
	["misc_de_goblet_08"] = true,
	["misc_de_goblet_09"] = true,
	["misc_de_pitcher_01"] = true,
	["misc_de_tankard_01"] = true,
	["misc_de_pot_redware_01"] = true,
	["misc_de_glass_green_01"] = true,
	["misc_de_glass_yellow_01"] = true,
	["misc_de_pot_glass_peach_01"] = true,
	["misc_de_pot_glass_peach_02"] = true,
	["misc_de_pot_redware_02"] = true,
	["misc_de_pot_redware_03"] = true,
	["misc_de_pot_green_01"] = true,
	["misc_de_pot_blue_01"] = true,
	["misc_de_pot_blue_02"] = true,
	["misc_de_pot_mottled_01"] = true,
	["misc_de_pot_redware_04"] = true,
	["misc_com_redware_cup"] = true,
	["misc_com_redware_flask"] = true,
	["misc_com_redware_pitcher"] = true,
	["misc_com_redware_vase"] = true,
	["misc_imp_silverware_cup_01"] = true,
	["misc_imp_silverware_cup"] = true,
	["misc_imp_silverware_pitcher"] = true,
	["misc_dwrv_goblet00"] = true,
	["misc_dwrv_goblet10"] = true,
	["misc_dwrv_mug00"] = true,
	["misc_dwrv_pitcher00"] = true,
	["misc_de_goblet_01_redas"] = true,
	["misc_beaker_01"] = true,
	["misc_flask_01"] = true,
	["misc_flask_02"] = true,
	["misc_flask_03"] = true,
	["misc_flask_04"] = true,
	["misc_de_goblet_04_dagoth"] = true,
	["misc_skooma_vial"] = true,
	["misc_dwrv_goblet10_tgcp"] = true,
	["misc_lw_cup"] = true,
	["misc_lw_flask"] = true,
	["misc_com_bucket_boe_uni"] = true,
	["misc_com_bucket_metal"] = true,
	["misc_goblet_dagoth"] = true,
	["misc_com_bucket_boe_unia"] = true,
	["misc_com_bucket_boe_unib"] = true,
	["misc_potion_cheap_01"] = true,
	["misc_flask_grease"] = true,
	["misc_imp_silverware_pitcher_uni"] = true,
	["misc_de_pot_redware_04_uni"] = true,
	["misc_dwrv_goblet00_uni"] = true,
	["misc_dwrv_goblet10_uni"] = true,
	["misc_dwrv_mug00_uni"] = true,
	["misc_dwrv_pitcher00_uni"] = true,
	["t_arg_ceramicbottle_01"] = true,
	["t_arg_ceramicbottle_02"] = true,
	["t_arg_ceramicflask_01"] = true,
	["t_arg_ceramicflask_02"] = true,
	["t_arg_ceramicflask_03"] = true,
	["t_arg_ceramicpitcher_02"] = true,
	["t_arg_woodenflask_01"] = true,
	["t_arg_woodenpitcher_01"] = true,
	["t_arg_woodenpot_01"] = true,
	["t_ayl_claypot_01"] = true,
	["t_ayl_claypot_02"] = true,
	["t_bre_bottle_01"] = true,
	["t_bre_bottle_02"] = true,
	["t_bre_bottle_03"] = true,
	["t_bre_bottle_04"] = true,
	["t_bre_bottle_05"] = true,
	["t_bre_bottle_06"] = true,
	["t_bre_bottle_07"] = true,
	["t_bre_bottle_08"] = true,
	["t_bre_bottle_09"] = true,
	["t_bre_bottle_10"] = true,
	["t_bre_bottle_11"] = true,
	["t_bre_bottle_12"] = true,
	["t_bre_bottle_13"] = true,
	["t_bre_bottle_14"] = true,
	["t_bre_bottle_15"] = true,
	["t_bre_bottle_16"] = true,
	["t_bre_greenglassflask_01"] = true,
	["t_bre_greenglassvase_01"] = true,
	["t_bre_pewterpot_01"] = true,
	["t_bre_pewterpot_02"] = true,
	["t_bre_pewterteapot_01"] = true,
	["t_bre_pewtervase_01"] = true,
	["t_bre_silverpitcher_01"] = true,
	["t_bre_silverpot_01"] = true,
	["t_bre_stonewareflask_01"] = true,
	["t_bre_stonewareteapot_01"] = true,
	["t_com_bottlered_01"] = true,
	["t_com_bottlered_02"] = true,
	["t_com_bottlered_03"] = true,
	["t_com_bottlered_04"] = true,
	["t_com_bottlered_05"] = true,
	["t_com_coppetteapot_01"] = true,
	["t_com_impcanteen"] = true,
	["t_com_potionbottle_01"] = true,
	["t_com_potionbottle_02"] = true,
	["t_com_potionbottle_03"] = true,
	["t_com_potionbottle_04"] = true,
	["t_de_bluewareflask02"] = true,
	["t_de_ebony_largeflask_01"] = true,
	["t_de_greydust_vial"] = true,
	["t_de_orangegreenpot_01"] = true,
	["t_de_purpleglassflask_01"] = true,
	["t_de_purpleglasspot_01"] = true,
	["t_de_purpleglasspot_02"] = true,
	["t_de_stonewarepot_01"] = true,
	["t_de_stonewarepot_02"] = true,
	["t_de_stonewarepot_03"] = true,
	["t_de_waterskin_01"] = true,
	["t_de_yellowglasspot01"] = true,
	["t_he_blueceladonpot_01"] = true,
	["t_he_blueceladonteapot_01"] = true,
	["t_he_bluewarepitcher_01"] = true,
	["t_he_bluewarepot_01"] = true,
	["t_he_bottle_01"] = true,
	["t_he_bottle_02"] = true,
	["t_he_bottle_03"] = true,
	["t_he_bottle_04"] = true,
	["t_he_bottle_05"] = true,
	["t_he_bottle_06"] = true,
	["t_he_bottle_07"] = true,
	["t_he_bottle_08"] = true,
	["t_he_bottle_09"] = true,
	["t_he_bottle_10"] = true,
	["t_he_bottle_11"] = true,
	["t_he_bottle_12"] = true,
	["t_he_bottle_13"] = true,
	["t_he_bottle_14"] = true,
	["t_he_bottle_15"] = true,
	["t_he_claypot_01"] = true,
	["t_he_direnniflask_01a"] = true,
	["t_he_direnniflask_02a"] = true,
	["t_he_direnniflask_03a"] = true,
	["t_he_direnniflask_04a"] = true,
	["t_he_direnniflask_05a"] = true,
	["t_he_direnniflask_06a"] = true,
	["t_he_direnniflask_07a"] = true,
	["t_he_direnniflask_07b"] = true,
	["t_imp_colbarrowbloodvial_01"] = true,
	["t_imp_colclaypot_01"] = true,
	["t_imp_silverwarepot_02"] = true,
	["t_ned_mw_pot"] = true,
	["t_nor_coppertankard"] = true,
	["t_nor_cordedpot_02"] = true,
	["t_nor_drinkinghorn_01"] = true,
	["t_nor_drinkinghorn_02"] = true,
	["t_nor_drinkinghorn_03"] = true,
	["t_nor_finewooddrinkinghorn_01"] = true,
	["t_nor_flaskblue_01"] = true,
	["t_nor_flaskblue_02"] = true,
	["t_nor_flaskblue_03"] = true,
	["t_nor_flaskblue_04"] = true,
	["t_nor_flaskgreen_01"] = true,
	["t_nor_flaskgreen_02"] = true,
	["t_nor_flaskgreen_03"] = true,
	["t_nor_flaskgreen_04"] = true,
	["t_nor_flaskred_01"] = true,
	["t_nor_flaskred_02"] = true,
	["t_nor_flaskred_03"] = true,
	["t_nor_flaskred_04"] = true,
	["t_nor_ironwoodvase_02"] = true,
	["t_nor_potionbagemptypoor_01"] = true,
	["t_nor_stonewareflask_01"] = true,
	["t_orc_ungorthbottle_01"] = true,
	["t_qyc_shellwarepitcher"] = true,
	["t_qy_bottle_01a"] = true,
	["t_qy_bottle_01b"] = true,
	["t_qy_bottle_01c"] = true,
	["t_qy_bottle_01d"] = true,
	["t_qy_bottle_02a"] = true,
	["t_qy_bottle_02b"] = true,
	["t_qy_bottle_02c"] = true,
	["t_qy_bottle_02d"] = true,
	["t_rga_bottle_01"] = true,
	["t_rga_bottle_02"] = true,
	["t_rga_bottle_03"] = true,
	["t_rga_bottle_04"] = true,
	["t_rga_bottle_05"] = true,
	["t_rga_bottle_06"] = true,
	["t_rga_bottle_07"] = true,
	["t_rga_bottle_08"] = true,
	["t_rga_bottle_09"] = true,
	["t_rga_bottle_10"] = true,
	["t_rga_bottle_11"] = true,
	["t_rga_bottle_12"] = true,
	["t_rga_bottle_13"] = true,
	["t_rga_bottle_14"] = true,
	["t_rga_bottle_15"] = true,
	["t_rga_bottle_16"] = true,
	["t_rga_bottle_17"] = true,
	["t_rga_bottle_18"] = true,
	["t_rga_bottle_19"] = true,
	["t_rga_bottle_20"] = true,
	["t_rga_claypot_01"] = true,
	["t_rga_flask_01"] = true,
	["t_rga_pitcher_01"] = true,
	["t_rga_porcelainpitcher_02"] = true,
	["t_rga_porcelainvase_03"] = true,
	["t_rga_pot_01"] = true,
	["t_rga_redwaretagine_01"] = true,
	["t_we_bonewarebottle_01"] = true,
	["t_we_bonewareflask_01"] = true,
	["t_yne_bottle_01a"] = true,
	["t_yne_bottle_01b"] = true,
	["t_yne_bottle_01c"] = true,
	["t_yne_bottle_01d"] = true,
	["t_yne_bottle_02a"] = true,
	["t_yne_bottle_02b"] = true,
	["t_yne_bottle_02c"] = true,
	["t_yne_bottle_02d"] = true,
	["t_yne_clayteapot"] = true,
	["t_yne_stoneteapot"] = true,
	["t_yne_stonevase_02"] = true,
	["t_yne_woodenteapot_01"] = true,
	["ab_misc_ceramicteapot01"] = true,
	["ab_misc_combottler01"] = true,
	["ab_misc_combottler02"] = true,
	["ab_misc_combottler03"] = true,
	["ab_misc_combottler04"] = true,
	["ab_misc_combottler05"] = true,
	["ab_misc_combottler06"] = true,
	["ab_misc_combottle_01"] = true,
	["ab_misc_combottle_02"] = true,
	["ab_misc_combottle_03"] = true,
	["ab_misc_compewterpot_01"] = true,
	["ab_misc_comredwareteapot"] = true,
	["ab_misc_comsilverpot_01"] = true,
	["ab_misc_comsilverteapot"] = true,
	["ab_misc_debugteapot"] = true,
	["ab_misc_deceramicpot_01"] = true,
	["ab_misc_declayflask_02"] = true,
	["ab_misc_decrglasspot_01"] = true,
	["ab_misc_deredglasspot_01"] = true,
	["ab_misc_deyelglasspot_01"] = true,
	["ab_misc_drinkcyrobrandy"] = true,
	["ab_misc_drinkflin"] = true,
	["ab_misc_impcanteen"] = true,
	["ab_misc_inkvial"] = true,
	["ab_misc_kettleceremonial"] = true,
	["ab_misc_pottersclaypot01"] = true,
	["ab_misc_pottersclaypot02"] = true,
	["ab_misc_waterskin"] = true,
	["tr_m2_q_9_pot_uni"] = true,
	["tr_m3_blood_i1-453-aun"] = true,
	["tr_m3_essempty_i3-128-ind"] = true,
	["tr_m3_voicebottle10"] = true,
	["tr_m3_voicebottle13"] = true,
	["tr_m3_voicebottle14"] = true,
	["tr_m3_voicebottle15"] = true,
	["tr_m3_voicebottle17"] = true,
	["tr_m3_voicebottle18"] = true,
	["tr_m3_voicebottle19"] = true,
	["tr_m3_voicebottle20"] = true,
	["tr_m3_voicebottle21"] = true,
	["tr_m3_voicebottle22"] = true,
	["tr_m3_voicebottle23"] = true,
	["tr_m3_voicebottle24"] = true,
	["tr_m3_voicebottle7"] = true,
	["tr_m3_voicebottle8"] = true,
	["tr_m3_voicebottle9"] = true,
	["tr_m4_savrethiemptygreef"] = true,
	["tr_m4_q_mg_sorusflask"] = true,
	["tr_m7_la_flinbottle"] = true,
	["tr_m7_ns_tt_chavana1_potion"] = true,
	["tr_m7_shishail3_waterskin_01"] = true,
	["tr_m3_voicebottle16"] = true,
	["sd_teapot_red"] = true,
	["sd_waterbottle"] = true,
	["sky_qre_dse3_weedkillerempty"] = true,
	["sky_qre_kwtg5_potion"] = true,
}

local vesselOffsets = {
	["t_he_greenceladonpot_01"] = false,
	["t_he_greenceladonteapot_01"] = false,
	["t_bre_bottle_15"] = false,
	["t_he_bottle_10"] = false,
	["ab_misc_drinkcyrobrandy"] = false,
	["ab_misc_deyelglasspot_01"] = false,
	["t_yne_stonevase_02"] = false,
	["t_yne_bottle_02d"] = false,
	["t_yne_bottle_02b"] = false,
	["t_yne_bottle_02a"] = false,
	["t_yne_bottle_01c"] = false,
	["t_yne_bottle_01b"] = false,
	["t_yne_bottle_01a"] = false,
	["t_we_bonewarebottle_01"] = false,
	["t_rga_redwaretagine_01"] = false,
	["t_rga_pot_01"] = false,
	["t_rga_porcelainvase_03"] = false,
	["tr_m3_essempty_i3-128-ind"] = false,
	["tr_m3_blood_i1-453-aun"] = false,
	["tr_m4_q_mg_sorusflask"] = false,
	["t_imp_colbarrowbloodvial_01"] = false,
	["t_rga_pitcher_01"] = false,
	["t_rga_flask_01"] = false,
	["tr_m7_ns_tt_chavana1_potion"] = false,
	["t_rga_bottle_20"] = false,
	["t_rga_bottle_19"] = false,
	["t_rga_bottle_16"] = false,
	["t_rga_bottle_15"] = false,
	["t_rga_bottle_14"] = false,
	["t_rga_bottle_13"] = false,
	["t_rga_bottle_12"] = false,
	["t_rga_bottle_11"] = false,
	["t_rga_bottle_10"] = false,
	["t_rga_bottle_09"] = false,
	["t_rga_bottle_07"] = false,
	["t_rga_bottle_06"] = false,
	["t_rga_bottle_04"] = false,
	["t_rga_bottle_03"] = false,
	["tr_m3_voicebottle21"] = false,
	["t_rga_bottle_18"] = false,
	["tr_m3_voicebottle22"] = false,
	["tr_m3_voicebottle23"] = false,
	["ab_misc_compewterpot_01"] = false,
	["ab_misc_comsilverpot_01"] = false,
	["tr_m3_voicebottle7"] = false,
	["tr_m3_voicebottle8"] = false,
	["tr_m3_voicebottle9"] = false,
	["ab_misc_combottler06"] = false,
	["ab_misc_deceramicpot_01"] = false,
	["ab_misc_declayflask_02"] = false,
	["t_nor_drinkinghorn_03"] = false,
	["ab_misc_decrglasspot_01"] = false,
	["t_nor_flaskblue_02"] = false,
	["t_rga_claypot_01"] = false,
	["t_nor_ironwoodvase_02"] = false,
	["t_he_blueceladonpot_01"] = false,
	["t_nor_potionbagemptypoor_01"] = false,
	["t_nor_flaskred_02"] = false,
	["t_nor_flaskgreen_04"] = false,
	["t_nor_flaskgreen_02"] = false,
	["t_nor_flaskgreen_01"] = false,
	["t_nor_flaskblue_03"] = false,
	["t_nor_finewooddrinkinghorn_01"] = false,
	["t_nor_drinkinghorn_02"] = false,
	["t_nor_drinkinghorn_01"] = false,
	["t_nor_coppertankard"] = false,
	["t_de_waterskin_01"] = false,
	["t_qy_bottle_02a"] = false,
	["t_he_bottle_11"] = false,
	["t_de_yellowglasspot01"] = false,
	["t_qy_bottle_01d"] = false,
	["t_qy_bottle_02d"] = false,
	["t_bre_pewterpot_01"] = false,
	["t_he_direnniflask_07a"] = false,
	["t_de_stonewarepot_03"] = false,
	["t_de_stonewarepot_01"] = false,
	["t_he_direnniflask_07b"] = false,
	["t_de_purpleglasspot_02"] = false,
	["t_he_bottle_14"] = false,
	["t_bre_greenglassvase_01"] = false,
	["tr_m3_voicebottle19"] = false,
	["tr_m3_voicebottle18"] = false,
	["ab_misc_combottle_01"] = false,
	["ab_misc_pottersclaypot01"] = false,
	["ab_misc_pottersclaypot02"] = false,
	["ab_misc_combottle_02"] = false,
	["ab_misc_combottler04"] = false,
	["ab_misc_combottler02"] = false,
	["ab_misc_inkvial"] = false,
	["ab_misc_impcanteen"] = false,
	["tr_m7_la_flinbottle"] = false,
	["ab_misc_drinkflin"] = false,
	["t_he_bottle_05"] = false,
	["t_he_bottle_01"] = false,
	["t_bre_silverpitcher_01"] = false,
	["t_nor_flaskblue_01"] = false,
	["t_imp_silverwarepot_02"] = false,
	["t_he_direnniflask_02a"] = false,
	["t_he_direnniflask_03a"] = false,
	["sd_teapot_red"] = false,
	["t_ayl_claypot_01"] = false,
	["misc_com_bottle_04"] = false,
	["t_bre_bottle_14"] = false,
	["ab_misc_comsilverteapot"] = false,
	["ab_misc_combottler03"] = false,
	["t_he_bottle_03"] = false,
	["t_de_bluewareflask02"] = false,
	["t_com_potionbottle_04"] = false,
	["t_com_potionbottle_03"] = false,
	["ab_misc_combottle_03"] = false,
	["t_qyc_shellwarepitcher"] = false,
	["tr_m2_q_9_pot_uni"] = false,
	["t_rga_bottle_02"] = false,
	["t_rga_bottle_01"] = false,
	["t_orc_ungorthbottle_01"] = false,
	["tr_m3_voicebottle16"] = false,
	["t_he_claypot_01"] = false,
	["t_nor_flaskred_03"] = false,
	["t_he_bottle_09"] = false,
	["t_nor_flaskgreen_03"] = false,
	["t_nor_flaskblue_04"] = false,
	["t_de_orangegreenpot_01"] = false,
	["t_com_impcanteen"] = false,
	["t_he_bottle_04"] = false,
	["t_he_bluewarepot_01"] = false,
	["t_de_stonewarepot_02"] = false,
	["t_he_bluewarepitcher_01"] = false,
	["t_he_bottle_12"] = false,
	["t_bre_greenglassflask_01"] = false,
	["tr_m3_voicebottle20"] = false,
	["sky_qre_kwtg5_potion"] = false,
	["tr_m3_voicebottle10"] = false,
	["tr_m3_voicebottle14"] = false,
	["tr_m3_voicebottle13"] = false,
	["t_com_bottlered_04"] = false,
	["t_com_bottlered_05"] = false,
	["t_he_bottle_02"] = false,
	["tr_m7_shishail3_waterskin_01"] = false,
	["tr_m3_voicebottle15"] = false,
	["tr_m3_voicebottle17"] = false,
	["t_com_bottlered_03"] = false,
	["t_bre_bottle_03"] = false,
	["t_rga_bottle_08"] = false,
	["t_rga_porcelainpitcher_02"] = false,
	["t_we_bonewareflask_01"] = false,
	["t_yne_bottle_02c"] = false,
	["t_qy_bottle_01c"] = false,
	["t_de_greydust_vial"] = false,
	["ab_misc_comredwareteapot"] = false,
	["t_com_coppetteapot_01"] = false,
	["ab_misc_kettleceremonial"] = false,
	["ab_misc_debugteapot"] = false,
	["ab_misc_ceramicteapot01"] = false,
	["t_nor_flaskred_04"] = false,
	["t_rga_bottle_17"] = false,
	["tr_m3_voicebottle24"] = false,
	["t_he_blueceladonteapot_01"] = false,
	["t_yne_clayteapot"] = false,
	["t_yne_stoneteapot"] = false,
	["t_yne_woodenteapot_01"] = false,
	["t_bre_pewterteapot_01"] = false,
	["t_bre_stonewareteapot_01"] = false,
	["t_com_bottlered_02"] = false,
	["t_com_bottlered_01"] = false,
	["t_bre_stonewareflask_01"] = false,
	["t_bre_silverpot_01"] = false,
	["t_bre_pewtervase_01"] = false,
	["t_imp_colclaypot_01"] = false,
	["t_qy_bottle_01b"] = false,
	["t_qy_bottle_01a"] = false,
	["t_arg_woodenflask_01"] = false,
	["t_arg_ceramicflask_03"] = false,
	["t_bre_bottle_08"] = false,
	["t_bre_bottle_13"] = false,
	["t_bre_bottle_10"] = false,
	["t_bre_bottle_04"] = false,
	["t_bre_bottle_09"] = false,
	["t_arg_woodenpitcher_01"] = false,
	["misc_com_redware_flask"] = false,
	["misc_de_pot_mottled_01"] = false,
	["misc_de_pot_blue_02"] = false,
	["misc_com_bottle_13"] = false,
	["misc_com_bottle_11"] = false,
	["misc_com_bottle_10"] = false,
	["misc_com_bottle_09"] = false,
	["misc_com_bottle_08"] = false,
	["misc_com_bottle_06"] = false,
	["misc_de_pot_green_01"] = false,
	["misc_com_bottle_01"] = false,
	["misc_de_pot_redware_04_uni"] = false,
	["t_bre_bottle_11"] = false,
	["misc_de_pot_glass_peach_02"] = false,
	["sd_waterbottle"] = false,
	["misc_flask_02"] = false,
	["misc_flask_04"] = false,
	["misc_skooma_vial"] = false,
	["misc_com_bottle_07"] = false,
	["misc_de_pot_blue_01"] = false,
	["misc_com_bottle_02"] = false,
	["misc_com_bottle_03"] = false,
	["misc_lw_flask"] = false,
	["misc_de_pot_redware_01"] = false,
	["misc_com_bottle_12"] = false,
	["misc_com_bottle_14"] = false,
	["misc_com_bottle_15"] = false,
	["misc_de_pot_redware_04"] = false,
	["misc_potion_cheap_01"] = false,
	["misc_flask_grease"] = false,
	["t_bre_bottle_12"] = false,
	["t_bre_bottle_07"] = false,
	["t_bre_bottle_06"] = false,
	["t_bre_bottle_05"] = false,
	["t_bre_bottle_02"] = false,
	["t_bre_bottle_01"] = false,
	["t_ayl_claypot_02"] = false,
	["t_arg_woodenpot_01"] = false,
	["t_arg_ceramicpitcher_02"] = false,
	["t_arg_ceramicflask_02"] = false,
	["t_arg_ceramicflask_01"] = false,
	["t_arg_ceramicbottle_02"] = false,
	["t_arg_ceramicbottle_01"] = false,
	["misc_de_pot_redware_02"] = false,
	["misc_com_bottle_05"] = false,
	["misc_de_pot_redware_03"] = false,
	["misc_flask_01"] = false,
	["t_nor_flaskred_01"] = false,
	["t_qy_bottle_02b"] = false,
	["t_bre_pewterpot_02"] = false,
	["ab_misc_deredglasspot_01"] = false,
	["ab_misc_combottler01"] = false,
	["ab_misc_combottler05"] = false,
	["ab_misc_waterskin"] = false,
	["tr_m4_savrethiemptygreef"] = false,
	["t_rga_bottle_05"] = false,
	["t_nor_stonewareflask_01"] = false,
	["sky_qre_dse3_weedkillerempty"] = false,
	["t_nor_cordedpot_02"] = false,
	["t_yne_bottle_01d"] = false,
	["misc_flask_03"] = false,
	["t_de_ebony_largeflask_01"] = false,
	["t_he_bottle_06"] = false,
	["t_he_bottle_07"] = false,
	["t_he_bottle_08"] = false,
	["t_he_bottle_13"] = false,
	["t_de_purpleglassflask_01"] = false,
	["t_he_bottle_15"] = false,
	["t_de_purpleglasspot_01"] = false,
	["t_he_direnniflask_01a"] = false,
	["t_he_direnniflask_05a"] = false,
	["t_he_direnniflask_06a"] = false,
	["t_com_potionbottle_01"] = false,
	["t_com_potionbottle_02"] = false,
	["t_ned_mw_pot"] = false,
	["t_he_direnniflask_04a"] = false,
	["t_qy_bottle_02c"] = false,
	["t_bre_bottle_16"] = false,
	["misc_com_metal_goblet_02"] = {
		minOffset = util.vector3(0.00, 0.00, 1.05),
		minScale = 0.527,
		maxOffset = util.vector3(0.00, 0.00, 3.89),
		maxScale = 0.527,
	},
	["misc_dwrv_goblet10_tgcp"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.651,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_dwrv_mug00"] = {
		minOffset = util.vector3(-1.94, 0.00, -2.22),
		minScale = 0.800,
		maxOffset = util.vector3(-0.94, 0.00, 4.45),
		maxScale = 0.630,
	},
	["misc_dwrv_pitcher00"] = {
		minOffset = util.vector3(-1.58, 0.00, -5.38),
		minScale = 1.012,
		maxOffset = util.vector3(-1.58, 0.00, 5.59),
		maxScale = 0.902,
	},
	["misc_lw_cup"] = {
		minOffset = util.vector3(0.00, 0.00, -1.09),
		minScale = 0.734,
		maxOffset = util.vector3(0.00, 0.00, 5.18),
		maxScale = 0.714,
	},
	["misc_com_redware_pitcher"] = {
		minOffset = util.vector3(0.00, 0.00, -4.59),
		minScale = 1.322,
		maxOffset = util.vector3(0.00, 0.00, 9.93),
		maxScale = 1.322,
	},
	["misc_com_redware_vase"] = {
		minOffset = util.vector3(-0.07, -0.06, 2.94),
		minScale = 1.324,
		maxOffset = util.vector3(-0.07, -0.06, 11.18),
		maxScale = 1.324,
	},
	["misc_imp_silverware_cup_01"] = {
		minOffset = util.vector3(0.00, 0.00, 0.97),
		minScale = 0.531,
		maxOffset = util.vector3(0.00, 0.00, 4.06),
		maxScale = 0.451,
	},
	["misc_imp_silverware_cup"] = {
		minOffset = util.vector3(0.00, 0.00, -1.60),
		minScale = 0.497,
		maxOffset = util.vector3(0.00, 0.00, 3.20),
		maxScale = 0.497,
	},
	["misc_goblet_dagoth"] = {
		minOffset = util.vector3(0.00, 0.00, 1.43),
		minScale = 0.858,
		maxOffset = util.vector3(0.00, 0.00, 6.14),
		maxScale = 1.138,
	},
	["misc_imp_silverware_pitcher"] = {
		minOffset = util.vector3(-0.57, 0.00, 4.33),
		minScale = 0.874,
		maxOffset = util.vector3(-0.57, 0.00, 9.33),
		maxScale = 0.864,
	},
	["misc_com_bucket_boe_unib"] = {
		minOffset = util.vector3(2.01, 0.01, -5.33),
		minScale = 2.209,
		maxOffset = util.vector3(-0.49, 0.01, 10.69),
		maxScale = 2.209,
	},
	["misc_imp_silverware_pitcher_uni"] = {
		minOffset = util.vector3(-0.57, 0.00, -1.17),
		minScale = 0.864,
		maxOffset = util.vector3(-0.57, 0.00, 9.33),
		maxScale = 0.864,
	},
	["misc_dwrv_goblet00_uni"] = {
		minOffset = util.vector3(0.00, 0.00, -5.58),
		minScale = 0.938,
		maxOffset = util.vector3(0.00, 0.00, -1.30),
		maxScale = 0.708,
	},
	["misc_dwrv_goblet10_uni"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.721,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_dwrv_mug00_uni"] = {
		minOffset = util.vector3(-1.94, 0.00, -2.22),
		minScale = 0.800,
		maxOffset = util.vector3(-0.94, 0.00, 4.45),
		maxScale = 0.630,
	},
	["misc_dwrv_pitcher00_uni"] = {
		minOffset = util.vector3(-1.58, 0.00, -1.88),
		minScale = 0.962,
		maxOffset = util.vector3(-1.58, 0.00, 5.59),
		maxScale = 0.902,
	},
	["misc_com_bucket_boe_uni"] = {
		minOffset = util.vector3(2.01, 0.01, -5.33),
		minScale = 2.209,
		maxOffset = util.vector3(-0.49, 0.01, 10.69),
		maxScale = 2.209,
	},
	["misc_com_redware_cup"] = {
		minOffset = util.vector3(0.00, -0.00, -2.00),
		minScale = 0.749,
		maxOffset = util.vector3(0.00, -0.00, 3.00),
		maxScale = 0.629,
	},
	["misc_beaker_01"] = {
		minOffset = util.vector3(-0.00, 0.00, 4.93),
		minScale = 0.869,
		maxOffset = util.vector3(-0.00, 0.00, 11.21),
		maxScale = 0.789,
	},
	["misc_dwrv_goblet00"] = {
		minOffset = util.vector3(0.00, 0.00, -5.58),
		minScale = 0.958,
		maxOffset = util.vector3(0.00, 0.00, -1.30),
		maxScale = 0.708,
	},
	["misc_com_bucket_01"] = {
		minOffset = util.vector3(2.51, 0.01, -5.33),
		minScale = 2.209,
		maxOffset = util.vector3(-0.49, 0.01, 10.69),
		maxScale = 2.209,
	},
	["misc_dwrv_goblet10"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.721,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_de_goblet_04"] = {
		minOffset = util.vector3(0.00, 0.00, 1.02),
		minScale = 0.738,
		maxOffset = util.vector3(0.00, 0.00, 3.95),
		maxScale = 0.558,
	},
	["misc_com_pitcher_metal_01"] = {
		minOffset = util.vector3(0.20, -0.51, -4.19),
		minScale = 1.044,
		maxOffset = util.vector3(0.20, -0.51, 8.38),
		maxScale = 1.024,
	},
	["misc_de_goblet_01"] = {
		minOffset = util.vector3(0.00, 0.00, 1.02),
		minScale = 0.708,
		maxOffset = util.vector3(0.00, 0.00, 3.95),
		maxScale = 0.558,
	},
	["misc_de_goblet_02"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.701,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_de_goblet_03"] = {
		minOffset = util.vector3(0.00, 0.00, 1.07),
		minScale = 0.698,
		maxOffset = util.vector3(0.00, 0.00, 3.85),
		maxScale = 0.578,
	},
	["misc_de_goblet_06"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.721,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_de_goblet_07"] = {
		minOffset = util.vector3(0.00, 0.00, 1.65),
		minScale = 0.681,
		maxOffset = util.vector3(0.00, 0.00, 3.69),
		maxScale = 0.561,
	},
	["misc_de_goblet_08"] = {
		minOffset = util.vector3(0.00, 0.00, 1.08),
		minScale = 0.748,
		maxOffset = util.vector3(0.00, 0.00, 3.84),
		maxScale = 0.578,
	},
	["misc_de_goblet_09"] = {
		minOffset = util.vector3(0.00, 0.00, 1.07),
		minScale = 0.738,
		maxOffset = util.vector3(0.00, 0.00, 3.85),
		maxScale = 0.578,
	},
	["misc_com_tankard_01"] = {
		minOffset = util.vector3(0.00, 0.00, -4.63),
		minScale = 0.821,
		maxOffset = util.vector3(0.00, 0.00, 4.26),
		maxScale = 0.671,
	},
	["misc_de_tankard_01"] = {
		minOffset = util.vector3(-0.50, 0.00, -2.22),
		minScale = 0.820,
		maxOffset = util.vector3(0.00, 0.00, 4.45),
		maxScale = 0.630,
	},
	["misc_com_bucket_boe_unia"] = {
		minOffset = util.vector3(2.51, 0.01, -5.33),
		minScale = 2.209,
		maxOffset = util.vector3(-0.49, 0.01, 10.69),
		maxScale = 2.209,
	},
	["misc_com_bucket_metal"] = {
		minOffset = util.vector3(0.00, 0.00, -13.49),
		minScale = 2.252,
		maxOffset = util.vector3(0.00, 0.00, 10.99),
		maxScale = 1.702,
	},
	["misc_com_metal_goblet_01"] = {
		minOffset = util.vector3(0.00, 0.00, 2.03),
		minScale = 0.527,
		maxOffset = util.vector3(0.00, 0.00, 3.94),
		maxScale = 0.527,
	},
	["misc_de_pitcher_01"] = {
		minOffset = util.vector3(0.00, 0.00, -3.17),
		minScale = 0.942,
		maxOffset = util.vector3(0.00, 0.00, 8.35),
		maxScale = 0.902,
	},
	["misc_de_goblet_05"] = {
		minOffset = util.vector3(0.00, 0.00, 1.02),
		minScale = 0.658,
		maxOffset = util.vector3(0.00, 0.00, 3.95),
		maxScale = 0.558,
	},
	["misc_de_glass_green_01"] = {
		minOffset = util.vector3(0.00, -0.00, 11.26),
		minScale = 0.657,
		maxOffset = util.vector3(0.00, -0.00, 15.83),
		maxScale = 0.617,
	},
	["misc_de_goblet_01_redas"] = {
		minOffset = util.vector3(0.00, 0.00, 1.02),
		minScale = 0.718,
		maxOffset = util.vector3(0.00, 0.00, 3.95),
		maxScale = 0.558,
	},
	["misc_com_wood_cup_01"] = {
		minOffset = util.vector3(0.00, 0.00, 1.52),
		minScale = 0.668,
		maxOffset = util.vector3(0.00, 0.00, 3.96),
		maxScale = 0.568,
	},
	["misc_de_glass_yellow_01"] = {
		minOffset = util.vector3(0.00, -0.00, 5.64),
		minScale = 0.807,
		maxOffset = util.vector3(0.00, -0.00, 15.03),
		maxScale = 0.617,
	},
	["misc_com_wood_cup_02"] = {
		minOffset = util.vector3(0.00, 0.00, -1.80),
		minScale = 0.573,
		maxOffset = util.vector3(0.00, 0.00, 3.60),
		maxScale = 0.503,
	},
	["misc_de_goblet_04_dagoth"] = {
		minOffset = util.vector3(0.00, 0.00, -1.59),
		minScale = 0.714,
		maxOffset = util.vector3(0.00, 0.00, 5.18),
		maxScale = 0.714,
	},
	["misc_de_pot_glass_peach_01"] = {
		minOffset = util.vector3(0.00, 0.00, 3.25),
		minScale = 0.801,
		maxOffset = util.vector3(0.00, 0.00, 7.82),
		maxScale = 0.671,
	},
}
local offsetTracker = {}      -- [vesselId] = { minOffset, minScale, maxOffset, maxScale, waterObj }
local vesselObjToId = {}      -- [vesselObj.id] = vesselId
local waterObjToId = {}       -- [waterObj.id] = vesselId
local blacklist = {}          -- [vesselId] = true

local function getVesselId(obj)
	if not obj then return nil end
	return vesselObjToId[obj.id] or waterObjToId[obj.id]
end

local scaleStep = 0.04
local teleportStep = 0.5

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Detection (mirrored from g_liquids.lua)                       │
-- ╰──────────────────────────────────────────────────────────────────────╯

local BLACKLIST_SUBSTRINGS = { 'broken', 't_com_paintpot' }
local SUBSTRINGS = { 
	'flask', 'beaker', 'cup', 'goblet', 'pitcher', 'tankard', 
	'misc_de_glass', 'drinkinghorn', 't_com_potionbottle_', 'vial', 'mug',
}
local INVENTORY_SUBSTRINGS = { 'bottle', 'canteen', 'misc_flask_03', 'waterskin' }
local ZERO_CHANCE_SUBSTRINGS = { 'bucket' }
local LOW_CHANCE_SUBSTRINGS = { 'vase', 'pot' }
local BLACKLIST = {
	["t_he_direnniflask_07c"] = true,
	["t_he_direnniflask_06f"] = true,
	["tr_m1_ito_fw_keyapothecary"] = true,
	["tr_m2_key_smugeler_ln"] = true,
	["t_com_inkvial_01"] = true,
}

local function hasKeyword(hay, kw)
	if not hay then return false end
	return string.find(hay, kw, 1, true) ~= nil
end

local function isQualifyingVessel(rec)
	if not rec then return false end
	
	local id = rec.id
	
	if id:sub(1,3) == "Gen" then print(id) return false end
	local name = (rec.name or ''):lower()
	
	if rec.mwscript then return false end
	if BLACKLIST[id] then return false end
	
	for _, sub in ipairs(BLACKLIST_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return false
		end
	end
	
	-- Check all vessel types
	for _, sub in ipairs(SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(ZERO_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	
	return false
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Offset Calculation (fallback from bounding box)                      │
-- ╰──────────────────────────────────────────────────────────────────────╯

local defaultParams = {
	minZFraction = 0.35,
	maxZFraction = 0.80,
	baseScaleMult = 0.043,
}

local function calculateDefaultOffset(vesselObj, mode)
	local bbox = vesselObj:getBoundingBox()
	local shortestSide = math.min(bbox.halfSize.x * 2, bbox.halfSize.y * 2)
	local baseScale = shortestSide * 1.414 * defaultParams.baseScaleMult
	
	local zFraction = mode == 1 and defaultParams.minZFraction or defaultParams.maxZFraction
	local z = bbox.halfSize.z * 2 * zFraction
	local offset = bbox.center - vesselObj.position + util.vector3(0, 0, z - bbox.halfSize.z)
	
	return offset, baseScale
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Print Functions                                                      │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function printOffset(obj)
	local vesselId = getVesselId(obj)
	if not vesselId then
		print("ERROR: Object not tracked")
		return
	end
	
	local data = offsetTracker[vesselId]
	local modeStr = MODE == 1 and "MIN" or "MAX"
	local offset = MODE == 1 and data.minOffset or data.maxOffset
	local scale = MODE == 1 and data.minScale or data.maxScale
	
	print(string.format("Vessel: %s [%s fill]", vesselId, modeStr))
	print(string.format("  offset = util.vector3(%.2f, %.2f, %.2f)", offset.x, offset.y, offset.z))
	print(string.format("  scale = %.3f", scale))
end

local function printAllOffsets()
	local modeStr = MODE == 1 and "MIN" or "MAX"
	print(string.format("=== Vessel Offsets [%s fill mode] ===", modeStr))
	print("-- Paste into vesselOffsets table in g_liquids.lua")
	print("")
	print("vesselOffsets = {")
	
	local count = 0
	local blacklistCount = 0
	
	-- Collect all vessel IDs from both tracker and presets
	local allVesselIds = {}
	for vesselId in pairs(offsetTracker) do
		allVesselIds[vesselId] = true
	end
	for vesselId in pairs(vesselOffsets) do
		allVesselIds[vesselId] = true
	end
	
	-- Print all vessels
	for vesselId in pairs(allVesselIds) do
		if not done[vesselId] then
			if blacklist[vesselId] then
				blacklistCount = blacklistCount + 1
				print(string.format('	["%s"] = false,', vesselId))
			else
				local data = offsetTracker[vesselId]
				if data then
					count = count + 1
					print(string.format('	["%s"] = {', vesselId))
					print(string.format('		minOffset = util.vector3(%.2f, %.2f, %.2f),', data.minOffset.x, data.minOffset.y, data.minOffset.z))
					print(string.format('		minScale = %.3f,', data.minScale))
					print(string.format('		maxOffset = util.vector3(%.2f, %.2f, %.2f),', data.maxOffset.x, data.maxOffset.y, data.maxOffset.z))
					print(string.format('		maxScale = %.3f,', data.maxScale))
					print("	},")
				else
					-- Use preset data for vessels not spawned this session
					local preset = vesselOffsets[vesselId]
					if preset and preset ~= false then
						count = count + 1
						print(string.format('	["%s"] = {', vesselId))
						if preset.minOffset then
							print(string.format('		minOffset = util.vector3(%.2f, %.2f, %.2f),', preset.minOffset.x, preset.minOffset.y, preset.minOffset.z))
						end
						if preset.minScale then
							print(string.format('		minScale = %.3f,', preset.minScale))
						end
						if preset.maxOffset then
							print(string.format('		maxOffset = util.vector3(%.2f, %.2f, %.2f),', preset.maxOffset.x, preset.maxOffset.y, preset.maxOffset.z))
						end
						if preset.maxScale then
							print(string.format('		maxScale = %.3f,', preset.maxScale))
						end
						print("	},")
					elseif preset == false then
						blacklistCount = blacklistCount + 1
						print(string.format('	["%s"] = false,', vesselId))
					end
				end
			end
		end
	end
	
	print("}")
	print(string.format("-- Total: %d vessel(s), %d blacklisted", count, blacklistCount))
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Tuning Functions                                                     │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function scaleUp(obj, amount)
	amount = amount or scaleStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local newScale = (waterObj.scale or 1.0) + amount
	waterObj:setScale(newScale)
	
	if MODE == 1 then
		data.minScale = newScale
	else
		data.maxScale = newScale
	end
	
	print(string.format("Scaled up to %.3f (+%.3f)", newScale, amount))
	printOffset(obj)
end

local function scaleDown(obj, amount)
	amount = amount or scaleStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local newScale = math.max(0.01, (waterObj.scale or 1.0) - amount)
	waterObj:setScale(newScale)
	
	if MODE == 1 then
		data.minScale = newScale
	else
		data.maxScale = newScale
	end
	
	print(string.format("Scaled down to %.3f (-%.3f)", newScale, amount))
	printOffset(obj)
end

local function moveUp(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y, pos.z + amount), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y, data.minOffset.z + amount)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y, data.maxOffset.z + amount)
	end
	
	print(string.format("Moved up by %.2f", amount))
	printOffset(obj)
end

local function moveDown(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y, pos.z - amount), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y, data.minOffset.z - amount)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y, data.maxOffset.z - amount)
	end
	
	print(string.format("Moved down by %.2f", amount))
	printOffset(obj)
end

local function moveRight(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x + amount, pos.y, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x + amount, data.minOffset.y, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x + amount, data.maxOffset.y, data.maxOffset.z)
	end
	
	print(string.format("Moved right by %.2f", amount))
	printOffset(obj)
end

local function moveLeft(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x - amount, pos.y, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x - amount, data.minOffset.y, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x - amount, data.maxOffset.y, data.maxOffset.z)
	end
	
	print(string.format("Moved left by %.2f", amount))
	printOffset(obj)
end

local function moveForward(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y + amount, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y + amount, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y + amount, data.maxOffset.z)
	end
	
	print(string.format("Moved forward by %.2f", amount))
	printOffset(obj)
end

local function moveBack(obj, amount)
	amount = amount or teleportStep
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y - amount, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y - amount, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y - amount, data.maxOffset.z)
	end
	
	print(string.format("Moved back by %.2f", amount))
	printOffset(obj)
end

local function blacklistVessel(obj)
	local vesselId = getVesselId(obj)
	if not vesselId then
		print("ERROR: Object not tracked")
		return
	end
	
	if blacklist[vesselId] then
		blacklist[vesselId] = nil
		print(string.format("REMOVED from blacklist: %s", vesselId))
	else
		blacklist[vesselId] = true
		print(string.format("ADDED to blacklist: %s", vesselId))
		local data = offsetTracker[vesselId]
		local waterObj = data.waterObj
		local vesselObj = data.vesselObj
		waterObj:remove()
		vesselObj:remove()
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Event Handlers                                                       │
-- ╰──────────────────────────────────────────────────────────────────────╯

G_eventHandlers.scaleUp = scaleUp
G_eventHandlers.scaleDown = scaleDown
G_eventHandlers.moveUp = moveUp
G_eventHandlers.moveDown = moveDown
G_eventHandlers.moveLeft = moveLeft
G_eventHandlers.moveRight = moveRight
G_eventHandlers.moveForward = moveForward
G_eventHandlers.moveBack = moveBack
G_eventHandlers.toggleBlacklist = blacklistVessel
G_eventHandlers.printAllOffsets = printAllOffsets

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Collection & Spawning                                         │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function collectAllVessels()
	local vessels = {}
	for _, rec in ipairs(types.Miscellaneous.records) do
		if isQualifyingVessel(rec) and not done[rec.id] then
			--print("["..rec.id.."] = true,")
			table.insert(vessels, {
				id = rec.id,
				name = rec.name or rec.id,
			})
		end
	end
	return vessels
end

local vesselList = collectAllVessels()
local NUM_ROWS = 15
local SPACING_X = 35
local SPACING_Z = 35
local OFFSET_Y = 0

print(string.format("[DrinkwareTuner] Found %d qualifying vessels (MODE=%d: %s fill)", #vesselList, MODE, MODE == 1 and "MIN" or "MAX"))

local function spawnVesselGrid(actor)
	local actorPos = actor.position
	local actorRot = actor.rotation
	
	local forward = actorRot * util.vector3(0, 1, 0)
	local right = actorRot * util.vector3(1, 0, 0)
	
	local itemsPerRow = math.ceil(#vesselList / NUM_ROWS)
	local currentIndex = 1
	local modeStr = MODE == 1 and "MIN" or "MAX"
	
	for row = 0, NUM_ROWS - 1 do
		local itemsInThisRow = math.min(itemsPerRow, #vesselList - currentIndex + 1)
		local rowStartOffset = -(itemsInThisRow - 1) * SPACING_X / 2
		
		for col = 0, itemsInThisRow - 1 do
			if currentIndex > #vesselList then break end
			
			local vessel = vesselList[currentIndex]
			local localX = rowStartOffset + (col * SPACING_X)
			local localZ = (row * SPACING_Z) + 100
			local spawnPos = actorPos + (forward * localZ) + (right * localX) + util.vector3(0, 0, OFFSET_Y)
			
			-- Spawn vessel
			local vesselObj = world.createObject(vessel.id)
			vesselObj:teleport(actor.cell, spawnPos, {onGround = false})
			
			-- Calculate defaults first
			local defMinOffset, defMinScale = calculateDefaultOffset(vesselObj, 1)
			local defMaxOffset, defMaxScale = calculateDefaultOffset(vesselObj, 2)
			
			-- Use existing vesselOffsets if available, otherwise use defaults
			local preset = vesselOffsets[vessel.id]
			local minOffset = (preset and preset.minOffset) or defMinOffset
			local minScale = (preset and preset.minScale) or defMinScale
			local maxOffset = (preset and preset.maxOffset) or defMaxOffset
			local maxScale = (preset and preset.maxScale) or defMaxScale
			
			-- Spawn water static at current mode's fill position
			local spawnOffset = MODE == 1 and minOffset or maxOffset
			local spawnScale = MODE == 1 and minScale or maxScale
			
			local waterObj = world.createObject(WATER_STATIC_ID)
			waterObj:teleport(actor.cell, spawnPos + spawnOffset, {onGround = false})
			waterObj:setScale(spawnScale)
			
			-- Track for tuning (both vessel and water obj point to same vesselId)
			vesselObjToId[vesselObj.id] = vessel.id
			waterObjToId[waterObj.id] = vessel.id
			offsetTracker[vessel.id] = {
				minOffset = minOffset,
				minScale = minScale,
				maxOffset = maxOffset,
				maxScale = maxScale,
				waterObj = waterObj,
				vesselObj = vesselObj,
			}
			
			currentIndex = currentIndex + 1
		end
	end
	
	return string.format("%d vessels spawned in %d rows [%s fill mode]", #vesselList, NUM_ROWS, modeStr)
end

-- Trigger spawning by using any Miscellaneous item
I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
	local result = spawnVesselGrid(actor)
	print("[DrinkwareTuner] " .. result)
end)

--[[
HOTKEY REFERENCE (add to player script's onKeyPress):

if key.symbol == "1" then
	core.sendGlobalEvent("scaleUp", G_raycastResult.hitObject)
elseif key.symbol == "2" then
	core.sendGlobalEvent("scaleDown", G_raycastResult.hitObject)
elseif key.symbol == "3" then
	core.sendGlobalEvent("moveUp", G_raycastResult.hitObject)
elseif key.symbol == "4" then
	core.sendGlobalEvent("moveDown", G_raycastResult.hitObject)
elseif key.code == input.KEY.LeftArrow then
	core.sendGlobalEvent("moveLeft", G_raycastResult.hitObject)
elseif key.code == input.KEY.RightArrow then
	core.sendGlobalEvent("moveRight", G_raycastResult.hitObject)
elseif key.code == input.KEY.UpArrow then
	core.sendGlobalEvent("moveForward", G_raycastResult.hitObject)
elseif key.code == input.KEY.DownArrow then
	core.sendGlobalEvent("moveBack", G_raycastResult.hitObject)
elseif key.symbol == "9" then
	core.sendGlobalEvent("toggleBlacklist", G_raycastResult.hitObject)
elseif key.symbol == "0" then
	core.sendGlobalEvent("printAllOffsets")
end
]]