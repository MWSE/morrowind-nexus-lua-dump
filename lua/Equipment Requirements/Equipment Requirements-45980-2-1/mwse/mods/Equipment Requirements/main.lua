--[[
    Equipment Requirements
--]]

local config = json.loadfile("config/rem_requirements_config")
if (not config) then
	config = {
		alternateMode = false,

	}
end


local armorReqTable = {
["daedric_cuirass"] = 80,
["daedric_pauldron_left"] = 80,
["daedric_pauldron_right"] = 80,
["daedric_gauntlet_left"] = 80,
["daedric_gauntlet_right"] = 80,
["daedric_greaves"] = 80,
["daedric_boots"] = 80,
["daedric_shield"] = 80,
["daedric_fountain_helm"] = 75,
["daedric_terrifying_helm"] = 80,
["daedric_god_helm"] = 85,
["daedric_towershield"] = 85,
["azura's servant"] = 85,
["daedric_cuirass_htab"] = 85,
["daedric_greaves_htab"] = 85,
["iron_helmet"] = 10,
["iron_cuirass"] = 10,
["iron_pauldron_left"] = 10,
["iron_pauldron_right"] = 10,
["iron_bracer_left"] = 10,
["iron_bracer_right"] = 10,
["iron_greaves"] = 10,
["iron boots"] = 10,
["iron_shield"] = 10,
["iron_gauntlet_left"] = 10,
["iron_gauntlet_right"] = 10,
["iron_towershield"] = 15,
["chitin cuirass"] = 40,
["chitin cuirass ash"] = 40,
["chitin cuirass ba"] = 45,
["chitin cuirass n"] = 40,
["chitin cuirass r"] = 40,
["chitin cuirass s"] = 40,
["chitin helm"] = 40,
["chitin_mask_helm"] = 40,
["chitin pauldron - left"] = 40,
["chitin pauldron - right"] = 40,
["chitin pauldron - left ash"] = 40,
["chitin pauldron - right ash"] = 40,
["chitin pauldron - left ba"] = 45,
["chitin pauldron - right ba"] = 45,
["chitin pauldron - left r"] = 40,
["chitin pauldron - right r"] = 40,
["chitin guantlet - left"] = 40,
["chitin guantlet - right"] = 40,
["chitin bracer - left"] = 40,
["chitin bracer - right"] = 40,
["chitin greaves"] = 40,
["chitin boots"] = 40,
["chitin boots n"] = 40,
["chitin_shield"] = 40,
["chitin_towershield"] = 45,
["chitin_watchman_helm"] = 45,
["cephalopod_helm"] = 35,
["md_vos_ceph_pauldron_left"] = 35,
["md_vos_ceph_pauldron_right"] = 35,
["md_vos_cephalopod_helm_open"] = 35,
["dust_adept_helm"] = 25,
["mole_crab_helm"] = 30,
["chest of fire"] = 45,
["the_chiding_cuirass"] = 45,
["left gauntlet of the horny fist"] = 45,
["right gauntlet of the horny fist"] = 45,
["demon cephalopod"] = 40,
["demon helm"] = 30,
["demon mole crab"] = 35,
["devil cephalopod helm"] = 50,
["devil helm"] = 45,
["devil mole crab helm"] = 40,
["fiend helm"] = 50,
["merisan helm"] = 45,
["velothian_helm"] = 45,
["velothian shield"] = 45,
["veloths_shield"] = 45,
["bonedancer gauntlet"] = 50,
["boneweave gauntlet"] = 50,
["cephalopod_helm_htnk"] = 60,
["shield of the undaunted"] = 50,
["bonemold_helm"] = 30,
["bonemold_cuirass"] = 30,
["bonemold_pauldron_l"] = 30,
["bonemold_pauldron_r"] = 30,
["bonemold_bracer_left"] = 30,
["bonemold_bracer_right"] = 30,
["bonemold_greaves"] = 30,
["bonemold_boots"] = 30,
["bonemold_shield"] = 30,
["bonemold_armun-an_helm"] = 30,
["bonemold_armun-an_cuirass"] = 30,
["bonemold_armun-an_pauldron_l"] = 30,
["bonemold_armun-an_pauldron_r"] = 30,
["bonemold_gah-julan_cuirass"] = 30,
["bonemold_gah-julan_helm"] = 30,
["bonemold_gah-julan_pauldron_l"] = 30,
["bonemold_gah-julan_pauldron_r"] = 30,
["bonemold_chuzei_helm"] = 30,
["bonemold_founders_helm"] = 30,
["redoran_master_helm"] = 50,
["bonemold_towershield"] = 35,
["bonemold_tshield_hlaaluguard"] = 35,
["bonemold_tshield_redoranguard"] = 35,
["bonemold_tshield_telvanniguard"] = 35,
["bonemold_gah-julan_hhda"] = 30,
["bonemold_tshield_hrlb"] = 30,
["heart wall"] = 35,
["lbonemold brace of horny fist"] = 30,
["rbonemold brace of horny fist"] = 30,
["storm helm"] = 30,
["holy_shield"] = 35,
["holy_tower_shield"] = 40,
["erur_dan_cuirass_unique"] = 40,
["mountain_spirit"] = 45,
["dreugh_cuirass"] = 50,
["dreugh_helm"] = 50,
["dreugh_shield"] = 50,
["dreugh_boots"] = 50,
["dreugh_bracer_l"] = 50,
["dreugh_bracer_r"] = 50,
["dreugh_greaves"] = 50,
["dreugh_pauldron_l"] = 50,
["dreugh_pauldron_r"] = 50,
["helm of holy fire"] = 50,
["dreugh_cuirass_ttrm"] = 50,
["dwemer_cuirass"] = 35,
["dwemer_helm"] = 35,
["dwemer_pauldron_left"] = 35,
["dwemer_pauldron_right"] = 35,
["dwemer_bracer_left"] = 35,
["dwemer_bracer_right"] = 35,
["dwemer_greaves"] = 35,
["dwemer_boots"] = 35,
["dwemer_shield"] = 35,
["dwemer_shield_battle_unique"] = 35,
["helm of wounding"] = 35,
["shield of wounds"] = 35,
["dwemer_boots of flying"] = 45,
["shadow_shield"] = 50,
["ebony_cuirass"] = 60,
["ebony_closed_helm"] = 60,
["ebony_pauldron_left"] = 60,
["ebony_pauldron_right"] = 60,
["ebony_bracer_left"] = 60,
["ebony_bracer_right"] = 60,
["ebony_greaves"] = 60,
["ebony_boots"] = 60,
["ebony_shield"] = 60,
["ebony_towershield"] = 65,
["saint's shield"] = 65,
["ebony_closed_helm_fghl"] = 60,
["ebony_cuirass_soscean"] = 75,
["glass_cuirass"] = 70,
["glass_helm"] = 70,
["glass_pauldron_left"] = 70,
["glass_pauldron_right"] = 70,
["glass_bracer_left"] = 70,
["glass_bracer_right"] = 70,
["glass_greaves"] = 70,
["glass_boots"] = 70,
["glass_shield"] = 70,
["glass_towershield"] = 75,
["silver_helm"] = 25,
["silver_helm_uvenim"] = 35,
["silver_cuirass"] = 25,
["silver_dukesguard_cuirass"] = 25,
["templar_helmet_armor"] = 25,
["templar_cuirass"] = 25,
["templar_pauldron_left"] = 25,
["templar_pauldron_right"] = 25,
["templar bracer left"] = 25,
["templar bracer right"] = 25,
["templar_greaves"] = 25,
["templar boots"] = 25,
["imperial helmet armor"] = 20,
["imperial helmet armor_dae_curse"] = 20,
["imperial cuirass_armor"] = 20,
["imperial left pauldron"] = 20,
["imperial right pauldron"] = 20,
["imperial left gauntlet"] = 20,
["imperial right gauntlet"] = 20,
["imperial_greaves"] = 20,
["imperial boots"] = 20,
["imperial shield"] = 20,
["imperial_chain_pauldron_left"] = 20,
["imperial_chain_pauldron_right"] = 20,
["imperial_chain_gauntlet_left"] = 20,
["imperial_chain_gauntlet_right"] = 20,
["imperial_chain_greaves"] = 20,
["imperial_chain_boots"] = 20,
["imperial_chain_coif_helm"] = 10,
["imperial_chain_cuirass"] = 10,
["dragonscale_helm"] = 20,
["dragonscale_cuirass"] = 20,
["dragonscale_towershield"] = 20,
["imperial_studded_cuirass"] = 10,
["imperial_studded_boots"] = 10,
["imperial_studded_greaves"] = 10,
["imperial_studded_gauntlet_r"] = 10,
["imperial_studded_gauntlet_l"] = 10,
["imperial_studded_pauldron_r"] = 10,
["imperial_studded_pauldron_l"] = 10,
["newtscale_cuirass"] = 10,
["newtscale_boots"] = 10,
["newtscale_greaves"] = 10,
["newtscale_gauntlet_l"] = 10,
["newtscale_gauntlet_r"] = 10,
["newtscale_pauldron_l"] = 10,
["newtscale_pauldron_r"] = 10,
["feather_shield"] = 25,
["shield_of_light"] = 25,
["velothis_shield"] = 20,
["imperial_helm_fral_unique"] = 35,
["steel_helm"] = 20,
["steel_cuirass"] = 20,
["steel_pauldron_left"] = 20,
["steel_pauldron_right"] = 20,
["steel_gauntlet_left"] = 20,
["steel_gauntlet_right"] = 20,
["steel_greaves"] = 20,
["steel_boots"] = 20,
["steel_shield"] = 20,
["steel_towershield"] = 25,
["steel_helm_ancient"] = 20,
["steel_cuirass_ancient"] = 20,
["steel_pauldron_left_ancient"] = 20,
["steel_pauldron_right_ancient"] = 20,
["steel_gauntlet_left_ancient"] = 20,
["steel_gauntlet_right_ancient"] = 20,
["steel_greaves_ancient"] = 20,
["steel_boots_ancient"] = 20,
["steel_towershield_ancient"] = 25,
["blessed_tower_shield"] = 30,
["blood_feast_shield"] = 60,
["indoril cuirass"] = 50,
["indoril pauldron left"] = 50,
["indoril pauldron right"] = 50,
["indoril left gauntlet"] = 50,
["indoril right gauntlet"] = 50,
["indoril boots"] = 50,
["indoril shield"] = 50,
["indoril helmet"] = 50,
["spirit of indoril"] = 60,
["succour of indoril"] = 55,
["slave_bracer_left"] = 5,
["slave_bracer_right"] = 5,
["orcish_helm"] = 50,
["orcish_cuirass"] = 50,
["orcish_pauldron_left"] = 50,
["orcish_pauldron_right"] = 50,
["orcish_bracer_left"] = 50,
["orcish_bracer_right"] = 50,
["orcish_greaves"] = 50,
["orcish_boots"] = 50,
["orcish_towershield"] = 50,
["netch_leather_helm"] = 10,
["netch_leather_cuirass"] = 10,
["netch_leather_cuirass_q"] = 10,
["netch_leather_pauldron_left"] = 10,
["netch_leather_pauldron_right"] = 10,
["netch_leather_pauldron_left_q"] = 10,
["netch_leather_pauldron_right_q"] = 10,
["netch_leather_gauntlet_left"] = 10,
["netch_leather_gauntlet_right"] = 10,
["netch_leather_greaves"] = 10,
["netch_leather_greaves_q"] = 10,
["netch_leather_boots"] = 10,
["netch_leather_boots_q"] = 10,
["netch_leather_shield"] = 10,
["netch_leather_towershield"] = 15,
["netch_leather_boiled_helm"] = 15,
["netch_leather_boiled_cuirass"] = 15,
["merisan_cuirass"] = 25,
["left_horny_fist_gauntlet"] = 15,
["right horny fist gauntlet"] = 15,
["left cloth horny fist bracer"] = 10,
["right cloth horny fist bracer"] = 10,
["veloths_tower_shield"] = 20,
["boots of blinding speed[unique]"] = 65,
["gauntlet_horny_fist_l"] = 15,
["gauntlet_horny_fist_r"] = 15,
["fur_helm"] = 10,
["fur_cuirass"] = 10,
["fur_pauldron_left"] = 10,
["fur_pauldron_right"] = 10,
["fur_gauntlet_left"] = 10,
["fur_gauntlet_right"] = 10,
["fur_bracer_left"] = 10,
["fur_bracer_right"] = 10,
["fur_greaves"] = 10,
["fur_boots"] = 10,
["nordic_leather_shield"] = 10,
["fur_bearskin_cuirass"] = 10,
["nordic_ringmail_cuirass"] = 10,
["nordic_iron_helm"] = 15,
["nordic_iron_cuirass"] = 15,
["trollbone_helm"] = 15,
["trollbone_cuirass"] = 15,
["trollbone_shield"] = 15,
["trollbone_boots"] = 15,
["trollbone_greaves"] = 15,
["trollbone_bracer_l"] = 15,
["trollbone_bracer_r"] = 15,
["trollbone_pauldron_l"] = 15,
["trollbone_pauldron_r"] = 15,
["Gauntlet_of_Glory_left"] = 20,
["Gauntlet_of_Glory_right"] = 20,
["bloodworm_helm_unique"] = 50,
["icecap_unique"] = 35,
["cloth bracer left"] = 10,
["cloth bracer right"] = 10,
["fur_colovian_helm"] = 10,
["fur_colovian_helm_red"] = 10,
["fur_colovian_helm_white"] = 10,
["left leather bracer"] = 10,
["right leather bracer"] = 10,
["heavy_leather_boots"] = 60,
["conoon_chodala_boots_unique"] = 65,
["adamantium_helm"] = 60,
["addamantium_helm"] = 60,
["helm_tohan_unique"] = 80,
["adamantium_cuirass"] = 60,
["adamantium_pauldron_left"] = 60,
["adamantium_pauldron_right"] = 60,
["adamantium_greaves"] = 60,
["adamantium_boots"] = 60,
["adamantium_bracer_left"] = 60,
["adamantium_bracer_right"] = 60,
["helsethguard_helmet"] = 60,
["helsethguard_cuirass"] = 60,
["helsethguard_pauldron_left"] = 60,
["helsethguard_pauldron_right"] = 60,
["helsethguard_greaves"] = 60,
["helsethguard_boots"] = 60,
["helsethguard_gauntlet_left"] = 60,
["helsethguard_gauntlet_right"] = 60,
["indoril_mh_guard_helmet"] = 75,
["indoril_mh_guard_cuirass"] = 75,
["indoril_mh_guard_pauldron_l"] = 75,
["indoril_mh_guard_pauldron_r"] = 75,
["indoril_mh_guard_greaves"] = 75,
["indoril_mh_guard_boots"] = 75,
["indoril_mh_guard_gauntlet_l"] = 75,
["indoril_mh_guard_gauntlet_r"] = 75,
["goblin_shield"] = 20,
["boots_apostle_unique"] = 75,
["tenpaceboots"] = 75,
["cuirass_savior_unique"] = 80,
["dragonbone_cuirass_unique"] = 80,
["ebon_plate_cuirass_unique"] = 85,
["lords_cuirass_unique"] = 80,
["gauntlet_fists_l_unique"] = 80,
["ggauntlet_fists_r_unique"] = 80,
["helm_bearclaw_unique"] = 85,
["daedric_helm_clavicusvile"] = 80,
["ebony_shield_auriel"] = 65,
["towershield_eleidon_unique"] = 85,
["spell_breaker_unique"] = 80,
["bm wolf boots"] = 20,
["bm wolf cuirass"] = 20,
["bm wolf greaves"] = 20,
["bm wolf helmet"] = 20,
["bm wolf left gauntlet"] = 20,
["bm wolf right gauntlet"] = 20,
["bm wolf left pauldron"] = 20,
["bm wolf right pauldron"] = 20,
["bm wolf shield"] = 20,
["bm_ice minion_shield1"] = 15,
["bm bear boots"] = 20,
["bm bear cuirass"] = 20,
["bm bear greaves"] = 20,
["bm bear helmet"] = 20,
["bm bear left gauntlet"] = 20,
["bm bear right gauntlet"] = 20,
["bm bear left pauldron"] = 20,
["bm bear right pauldron"] = 20,
["bm bear shield"] = 20,
["bm_ice_boots"] = 65,
["bm_ice_cuirass"] = 65,
["bm_ice_greaves"] = 65,
["bm_ice_helmet"] = 65,
["bm_ice_shield"] = 65,
["bm_ice_gauntletl"] = 65,
["bm_ice_gauntletr"] = 65,
["bm_ice_pauldronl"] = 65,
["bm_ice_pauldronr"] = 65,
["bm_nordicmail_boots"] = 65,
["bm_nordicmail_cuirass"] = 65,
["bm_nordicmail_greaves"] = 65,
["bm_nordicmail_helmet"] = 65,
["bm_nordicmail_shield"] = 65,
["bm_nordicmail_gauntletl"] = 65,
["bm_nordicmail_gauntletr"] = 65,
["bm_nordicmail_pauldronl"] = 65,
["bm_nordicmail_pauldronr"] = 65,
["aaa_attrebus_greaves"] = 65,
["wolfwalkers"] = 30,
["bm bear helmet_ber"] = 55,
["bm bear helmet eddard"] = 55,
["bm wolf helmet_heartfang"] = 35,
["bm_bear_boots_snow"] = 40,
["bm_bear_cuirass_snow"] = 40,
["bm_bear_greaves_snow"] = 40,
["bm_bear_helmet_snow"] = 40,
["bm_bear_left_gauntlet_snow"] = 40,
["bm_bear_right_gauntlet_snow"] = 40,
["bm_bear_left_pauldron_snow"] = 40,
["bm_bear_right_pauldron_snow"] = 40,
["bm_wolf_boots_snow"] = 40,
["bm_wolf_cuirass_snow"] = 40,
["bm_wolf_greaves_snow"] = 40,
["bm_wolf_helmet_snow"] = 40,
["bm_wolf_left_gauntlet_snow"] = 40,
["bm_wolf_right_gauntlet_snow"] = 40,
["bm_wolf_left_pauldron_snow"] = 40,
["bm_wolf_right_pauldron_snow"] = 40,
["domina_cuirass"] = 20,
["domina_helm"] = 20,
["domina_pauldron_l"] = 20,
["domina_pauldron_r"] = 20,
["domina_boots"] = 20,
["domina_greaves"] = 20,
["domina_gauntlet_l"] = 20,
["domina_gauntlet_r"] = 20,
["gold1_armor_cuirass"] = 60,
["gold1_armor_helm"] = 60,
["gold1_armor_pauldron_l"] = 60,
["gold1_armor_pauldron_r"] = 60,
["ward of akavir"] = 45,
["morag_tong_helm"] = 15,
["mg_a_miner_helm"] = 50,
["mg_a_miner_helm_gorluck"] = 50,
["barkwoven_boots"] = 50,
["barkwoven_bracer_left"] = 50,
["barkwoven_bracer_right"] = 50,
["barkwoven_cuirass"] = 50,
["barkwoven_greaves"] = 50,
["barkwoven_helm"] = 50,
["barkwoven_pauldron_left"] = 50,
["barkwoven_pauldron_right"] = 50,
["barkwoven_shield"] = 50,
["crabshell_boots"] = 35,
["crabshell_bracer_left"] = 35,
["crabshell_bracer_right"] = 35,
["crabshell_cuirass"] = 35,
["crabshell_greaves"] = 35,
["crabshell_helm"] = 35,
["crabshell_pauldron_left"] = 35,
["crabshell_pauldron_right"] = 35,
["crabshell_shield"] = 35,
["fishscale_boots"] = 10,
["fishscale_bracer_left"] = 10,
["fishscale_bracer_right"] = 10,
["fishscale_cuirass"] = 10,
["fishscale_greaves"] = 10,
["fishscale_helm"] = 10,
["fishscale_pauldron_left"] = 10,
["fishscale_pauldron_right"] = 10,
["leafweave_boots"] = 30,
["leafweave_bracer_left"] = 30,
["leafweave_bracer_right"] = 30,
["leafweave_cuirass"] = 30,
["leafweave_greaves"] = 30,
["leafweave_helm"] = 30,
["leafweave_pauldron_left"] = 30,
["leafweave_pauldron_right"] = 30,
["leafweave_shield"] = 30,
["q_fur_colovian_gauntlet_left"] = 10,
["q_fur_colovian_gauntlet_left_r"] = 10,
["q_fur_colovian_gauntlet_right"] = 10,
["q_fur_colovian_gauntlet_right_r"] = 10,
["q_fur_colovian_gauntlet_left_w"] = 10,
["q_fur_colovian_gauntlet_right_w"] = 10,
["bound_boots"] = 5,
["bound_cuirass"] = 5,
["bound_gauntlet_left"] = 5,
["bound_gauntlet_right"] = 5,
["bound_helm"] = 5,
["bound_shield"] = 5,
["darkbrotherhood helm"] = 55,
["darkbrotherhood cuirass"] = 55,
["darkbrotherhood pauldron_l"] = 55,
["darkbrotherhood pauldron_r"] = 55,
["darkbrotherhood greaves"] = 55,
["darkbrotherhood boots"] = 55,
["darkbrotherhood gauntlet_l"] = 55,
["darkbrotherhood gauntlet_r"] = 55,


}

local weaponReqTable = {
["daedric shortsword"] = 70,
["daedric halberd"] = 70,
["daedric staff"] = 70,
["daedric claymore"] = 70,
["daedric club"] = 70,
["daedric dagger"] = 70,
["daedric dai-katana"] = 70,
["daedric dart"] = 70,
["daedric katana"] = 70,
["daedric long bow"] = 70,
["daedric longsword"] = 70,
["daedric mace"] = 70,
["daedric shortsword"] = 70,
["daedric spear"] = 70,
["daedric tanto"] = 70,
["daedric wakizashi"] = 70,
["daedric war axe"] = 70,
["daedric battle axe"] = 70,
["daedric warhammer"] = 70,
["mephala's teacher"] = 75,
["boethia's walking stick"] = 75,
["daedric warhammer_ttgd"] = 75,
["daedric dagger_mtas"] = 75,
["daedric dagger_soultrap"] = 75,
["daedric wakizashi_hhst"] = 70,
["daedric_club_tgdc"] = 75,
["Gravedigger"] = 75,
["king's_oath_pc"] = 75,
["iron battle axe"] = 10,
["iron club"] = 10,
["iron broadsword"] = 10,
["iron claymore"] = 10,
["iron dagger"] = 10,
["iron fork"] = 10,
["iron halberd"] = 10,
["iron longsword"] = 10,
["iron mace"] = 10,
["iron saber"] = 10,
["iron shortsword"] = 10,
["iron spear"] = 10,
["iron tanto"] = 10,
["iron long spear"] = 10,
["iron throwing knife"] = 10,
["iron wakizashi"] = 10,
["iron war axe"] = 10,
["iron warhammer"] = 10,
["long bow"] = 10,
["iron flamemace"] = 10,
["iron shardmace"] = 10,
["iron sparkmace"] = 10,
["iron flamemauler"] = 10,
["iron shardmauler"] = 10,
["iron sparkmauler"] = 10,
["iron vipermauler"] = 10,
["iron flamesword"] = 10,
["iron shardsword"] = 10,
["iron sparksword"] = 10,
["iron vipersword"] = 10,
["iron sparkaxe"] = 10,
["iron viperaxe"] = 10,
["iron shardaxe"] = 10,
["spiderbite"] = 15,
["stormblade"] = 15,
["iron flameslayer"] = 10,
["iron shardslayer"] = 10,
["iron sparkslayer"] = 10,
["iron viperslayer"] = 10,
["iron flameblade"] = 10,
["iron shardblade"] = 10,
["iron sparkblade"] = 10,
["iron spider dagger"] = 15,
["iron viperblade"] = 10,
["iron flamecleaver"] = 10,
["iron flameskewer"] = 10,
["iron shardcleaver"] = 10,
["iron shardskewer"] = 10,
["iron sparkcleaver"] = 10,
["iron sparkskewer"] = 10,
["iron vipercleaver"] = 10,
["iron viperskewer"] = 10,
["flying viper"] = 20,
["short bow"] = 10,
["lightofday_unique"] = 50,
["banhammer_unique"] = 10,
["we_temreki"] = 40,
["rusty_dagger_unique"] = 10,
["fork_horripilation_unique"] = 10,
["chitin club"] = 5,
["chitin dagger"] = 5,
["chitin short bow"] = 5,
["chitin shortsword"] = 5,
["chitin spear"] = 5,
["chitin throwing star"] = 5,
["chitin war axe"] = 5,
["chitin firebite star"] = 10,
["firebite war axe"] = 5,
["firebite club"] = 5,
["firebite dagger"] = 5,
["firebite sword"] = 5,
["water spear"] = 15,
["dagoth dagger"] = 35,
["karpal's friend"] = 30,
["wind of ahaz"] = 25,
["bonebiter_bow_unique"] = 20,
["dagger of judgement"] = 20,
["racerbeak"] = 25,
["airan_ahhe's_spirit_spear_uniq"] = 30,
["bm_saber_seasplitter"] = 30,
["bonemold long bow"] = 30,
["dreugh club"] = 20,
["dreugh staff"] = 20,
["merisan club"] = 30,
["light staff"] = 25,
["bonemold longbow"] = 40,
["dwarven battle axe"] = 30,
["dwarven claymore"] = 30,
["foeburner"] = 30,
["dwarven crossbow"] = 35,
["dwarven halberd"] = 30,
["dwarven mace"] = 30,
["dwarven shortsword"] = 30,
["dwarven spear"] = 30,
["dwarven war axe"] = 30,
["dwarven warhammer"] = 30,
["centurion_projectile_dart_shock"] = 75,
["centurion_projectile_dart"] = 65,
["dwarven mace_salandas"] = 35,
["war axe of wounds"] = 35,
["last rites"] = 40,
["snowy crown"] = 40,
["warhammer of wounds"] = 55,
["dwemer jinksword"] = 40,
["last wish"] = 40,
["wild flamesword"] = 35,
["wild shardsword"] = 35,
["wild sparksword"] = 35,
["wild vipersword"] = 35,
["gavel of the ordinator"] = 55,
["dwarven axe_soultrap"] = 35,
["ane_teria_mace_unique"] = 40,
["clutterbane"] = 30,
["shortbow of sanguine sureflight"] = 25,
["dwe_jinksword_curse_unique"] = 40,
["dwarven halberd_soultrap"] = 35,
["we_illkurok"] = 40,
["we_stormforge"] = 55,
["ebony broadsword"] = 50,
["ebony broadsword_dae_cursed"] = 50,
["ebony dart"] = 50,
["ebony longsword"] = 50,
["ebony mace"] = 50,
["ebony shortsword"] = 50,
["ebony shorsword"] = 50,
["ebony spear"] = 50,
["ebony staff"] = 50,
["ebony throwing star"] = 50,
["ebony war axe"] = 50,
["ebony dart_db_unique"] = 50,
["ebony scimitar"] = 50,
["ebony scimitar_her"] = 65,
["ebony shortsword_soscean"] = 55,
["ebony spear_blessed_unique"] = 65,
["bm_ebony_staff_necro"] = 55,
["ebony war axe_elanande"] = 50,
["bm_ebonylongsword_s"] = 75,
["daunting mace"] = 50,
["demon mace"] = 55,
["sword of white woe"] = 65,
["ebony wizard's staff"] = 40,
["spirit-eater"] = 55,
["saint's black sword"] = 55,
["we_hellfirestaff"] = 60,
["ebony_staff_tges"] = 55,
["ebony_dagger_mehrunes"] = 50,
["we_shimsil"] = 50,
["ebony spear_hrce_unique"] = 55,
["ebony staff caper"] = 55,
["glass claymore"] = 45,
["glass dagger"] = 45,
["glass halberd"] = 45,
["glass dagger_Dae_cursed"] = 45,
["glass longsword"] = 45,
["glass staff"] = 45,
["mg_w_glass_staff_uni"] = 55,
["glass throwing knife"] = 45,
["glass throwing star"] = 45,
["glass war axe"] = 45,
["glass dagger_symmachus_unique"] = 75,
["glass firesword"] = 50,
["glass frostsword"] = 50,
["glass poisonsword"] = 50,
["glass stormsword"] = 50,
["glass jinkblade"] = 50,
["glass netch dagger"] = 50,
["glass stormblade"] = 50,
["wild flameblade"] = 50,
["wild shardblade"] = 50,
["wild sparkblade"] = 50,
["wild viperblade"] = 50,
["conoon_chodala_axe_unique"] = 55,
["war_axe_airan_ammu"] = 55,
["glass claymore_magebane"] = 55,
["glass_dagger_enamor"] = 45,
["imperial shortsword"] = 20,
["imperial shortsword severio"] = 35,
["imperial broadsword"] = 20,
["imperial netch blade"] = 30,
["steel axe"] = 20,
["steel battle axe"] = 20,
["steel broadsword"] = 20,
["steel claymore"] = 20,
["steel club"] = 20,
["steel crossbow"] = 20,
["steel dagger"] = 20,
["steel dai-katana"] = 20,
["steel dart"] = 20,
["steel halberd"] = 20,
["steel katana"] = 20,
["steel longbow"] = 25,
["steel longbow_carnius"] = 25,
["steel longsword"] = 20,
["steel mace"] = 20,
["steel saber"] = 20,
["steel saber_elberoth"] = 20,
["steel shortsword"] = 20,
["steel spear"] = 20,
["steel staff"] = 20,
["steel tanto"] = 20,
["steel throwing knife"] = 20,
["steel throwing star"] = 20,
["steel wakizashi"] = 20,
["steel war axe"] = 20,
["steel warhammer"] = 20,
["flamestar"] = 25,
["shardstar"] = 25,
["viperstar"] = 25,
["sparkstar"] = 25,
["throwing knife of sureflight"] = 20,
["steel flameaxe"] = 25,
["steel shardaxe"] = 25,
["steel sparkaxe"] = 25,
["steel viperaxe"] = 25,
["steel war axe of deep biting"] = 30,
["fiend battle axe"] = 40,
["shockbite battle axe"] = 25,
["icebreaker"] = 30,
["shockbite mace"] = 25,
["steel flamemace"] = 25,
["steel shardmace"] = 25,
["steel sparkmace"] = 25,
["steel vipermace"] = 25,
["shockbite warhammer"] = 25,
["steel flamemauler"] = 25,
["steel shardmauler"] = 25,
["steel sparkmauler"] = 25,
["steel vipermauler"] = 25,
["steel warhammer of smiting"] = 30,
["steel staff of chastening"] = 25,
["steel staff of divine judgement"] = 25,
["steel staff of peace"] = 35,
["steel staff of shaming"] = 25,
["steel staff of the ancestors"] = 40,
["steel staff of war"] = 35,
["demon longbow"] = 45,
["devil longbow"] = 50,
["fiend longbow"] = 50,
["demon katana"] = 45,
["devil katana"] = 50,
["fiend katana"] = 50,
["steel broadsword of hewing"] = 30,
["steel firesword"] = 25,
["steel flamesword"] = 25,
["steel frostword"] = 25,
["steel poisonsword"] = 25,
["steel shardsword"] = 25,
["steel sparksword"] = 25,
["steel stormsword"] = 25,
["steel vipersword"] = 25,
["steel claymore of hewing"] = 30,
["steel flamescythe"] = 25,
["steel shardscythe"] = 25,
["steel sparkscythe"] = 25,
["steel sparkslayer"] = 25,
["steel viperscythe"] = 25,
["steel viperslayer"] = 25,
["steel shardslayer"] = 25,
["steel flameslayer"] = 25,
["cruel flameblade"] = 25,
["cruel flamesword"] = 25,
["cruel shardblade"] = 25,
["cruel shardsword"] = 25,
["cruel sparkblade"] = 25,
["cruel sparksword"] = 25,
["cruel viperblade"] = 25,
["cruel vipersword"] = 25,
["demon tanto"] = 45,
["devil tanto"] = 50,
["fiend tanto"] = 50,
["dire flamesword"] = 25,
["dire flameblade"] = 25,
["dire shardsword"] = 25,
["dire shardblade"] = 25,
["dire sparksword"] = 25,
["dire sparkblade"] = 25,
["dire vipersword"] = 25,
["dire viperblade"] = 25,
["fireblade"] = 30,
["steel blade of heaven"] = 45,
["steel dagger of swiftblade"] = 30,
["steel flameblade"] = 25,
["steel jinkblade"] = 35,
["steel jinkblade of the aegis"] = 45,
["steel jinksword"] = 35,
["steel shardblade"] = 25,
["steel sparkblade"] = 25,
["steel viperblade"] = 25,
["steel spider blade"] = 25,
["devil spear"] = 50,
["fiend spear"] = 50,
["fiend spear_Dae_cursed"] = 50,
["shockbite halberd"] = 25,
["spear of light"] = 30,
["steel flamecleaver"] = 25,
["steel flameskewer"] = 25,
["steel shardcleaver"] = 25,
["steel shardskewer"] = 25,
["steel sparkcleaver"] = 25,
["steel sparkskewer"] = 25,
["steel vipercleaver"] = 25,
["steel viperskewer"] = 25,
["steel spear of impaling thrust"] = 30,
["cloudcleaver_unique"] = 30,
["steelstaffancestors_ttsa"] = 50,
["ebony_staff_trebonius"] = 40,
["dwarven war_axe_redas"] = 25,
["lugrub's axe"] = 20,
["devil_tanto_tgamg"] = 50,
["black dart"] = 70,
["bleeder dart"] = 70,
["carmine dart"] = 75,
["fine black dart"] = 75,
["fine bleeder dart"] = 75,
["fine carmine dart"] = 80,
["her dart"] = 60,
["warhammer_rammekald_unique"] = 35,
["steel spear snow prince"] = 50,
["orcish battle axe"] = 40,
["orcish warhammer"] = 40,
["nordic battle axe"] = 20,
["nordic broadsword"] = 20,
["nordic claymore"] = 20,
["stormkiss"] = 30,
["widowmaker_unique"] = 60,
["claymore_Agustas"] = 30,
["solvistapp"] = 25,
["bm reaver battle axe"] = 35,
["silver claymore"] = 30,
["silver dagger"] = 30,
["silver dagger_droth_unique"] = 30,
["silver dagger_droth_unique_a"] = 30,
["silver dagger_iryon_unique"] = 30,
["silver dagger_othril_unique"] = 30,
["silver dagger_rathalas_unique"] = 30,
["silver dart"] = 30,
["silver longsword"] = 30,
["silver shortsword"] = 30,
["silver shortsword_thelas"] = 40,
["silver spear"] = 30,
["silver spear_uvenim"] = 40,
["silver staff"] = 30,
["silver throwing star"] = 30,
["silver war axe"] = 30,
["spite_dart"] = 15,
["spring dart"] = 80,
["fine spring dart"] = 15,
["silver sword of paralysis"] = 60,
["silver axe of paralysis"] = 60,
["silver staff of paralysis"] = 60,
["lucky_break"] = 45,
["cruel flamestar"] = 35,
["cruel shardstar"] = 35,
["cruel sparkstar"] = 35,
["cruel viperstar"] = 35,
["silver flameaxe"] = 35,
["silver shardaxe"] = 35,
["silver sparkaxe"] = 35,
["silver viperaxe"] = 35,
["peacemaker"] = 40,
["silver staff of chastening"] = 35,
["herder_crook"] = 35,
["silver staff of peace"] = 40,
["silver staff of reckoning"] = 45,
["silver staff of shaming"] = 35,
["silver staff of war"] = 45,
["icicle"] = 35,
["silver flamesword"] = 35,
["silver sparksword"] = 35,
["silver shardsword"] = 35,
["silver viperblade"] = 35,
["silver flameslayer"] = 35,
["silver shardslayer"] = 35,
["silver sparkslayer"] = 35,
["silver viperslayer"] = 35,
["silver flameblade"] = 35,
["silver sparkblade"] = 35,
["silver shardblade"] = 35,
["silver viperblade"] = 35,
["silver flameskewer"] = 35,
["silver shardskewer"] = 35,
["silver sparkskewer"] = 35,
["silver viperskewer"] = 35,
["silver dagger_hanin cursed"] = 50,
["staff_of_llevule"] = 15,
["fury"] = 40,
["greed"] = 50,
["wooden staff"] = 10,
["wooden staff of chastening"] = 15,
["wooden staff of judgement"] = 15,
["wooden staff of peace"] = 20,
["wooden staff of shaming"] = 15,
["wooden staff of war"] = 15,
["staff of the forefathers"] = 60,
["adamantium_axe"] = 60,
["adamantium_claymore"] = 60,
["adamantium_mace"] = 60,
["adamantium_shortsword"] = 60,
["adamantium_spear"] = 60,
["goblin_sword"] = 60,
["goblin_club"] = 60,
["adamantium_shortsword_db"] = 65,
["mace of slurring"] = 40,
["stendar_hammer_unique"] = 100,
["sword of almalexia"] = 80,
["nerevarblade_01"] = 80,
["nerevarblade_01_flame"] = 80,
["bipolar blade"] = 70,
["cleaverstfelms"] = 50,
["axe_queen_of_bats_unique"] = 60,
["mace of molag bal_unique"] = 60,
["daedric_scourge_unique"] = 55,
["warhammer_crusher_unique"] = 70,
["crosierstllothis"] = 45,
["staff_hasedoki_unique"] = 45,
["staff_magnus_unique"] = 55,
["dwarven_hammer_volendrun"] = 55,
["longbow_shadows_unique"] = 65,
["katana_goldbrand_unique"] = 80,
["katana_bluebrand_unique"] = 80,
["claymore_chrysamere_unique"] = 80,
["daedric_crescent_unique"] = 55,
["claymore_iceblade_unique"] = 75,
["longsword_umbra_unique"] = 70,
["dagger_fang_unique"] = 70,
["mehrunes'_razor_unique"] = 65,
["spear_mercy_unique"] = 70,
["bm_mace_aevar_uni"] = 85,
["bm nordic pick"] = 20,
["bm silver dagger wolfender"] = 20,
["bm_dagger_wolfgiver"] = 20,
["bm huntsman axe"] = 25,
["bm huntsman war axe"] = 35,
["bm huntsman longsword"] = 35,
["bm riekling sword"] = 35,
["bm riekling sword_rusted"] = 25,
["bm riekling lance"] = 25,
["bm_ice_minion_lance"] = 25,
["bm huntsman spear"] = 35,
["bm huntsman crossbow"] = 35,
["bm nordic silver axe"] = 40,
["bm nordic silver battleaxe"] = 40,
["bm nordic silver mace"] = 40,
["bm nordic silver longsword"] = 40,
["bm nordic silver claymore"] = 40,
["bm nordic silver dagger"] = 40,
["bm nordic silver shortsword"] = 40,
["aaa_daedric longspear"] = 70,
["aaa_dwrv_longspear"] = 35,
["aaa_nordic spear"] = 40,
["aaa_stalhrim spear"] = 60,
["aaa_stalhrim_shortsword"] = 60,
["aaa_wood_crossbow"] = 10,
["bm ice war axe"] = 60,
["bm ice mace"] = 60,
["bm ice longsword"] = 60,
["bm ice dagger"] = 60,
["bm nordic silver axe_ber"] = 45,
["bm nordic silver battleaxe_ber"] = 45,
["bm nordic silver longsword_ber"] = 45,
["bm winterwound dagger"] = 45,
["bm_axe_heartfang_unique"] = 75,
["bm_hunter_battleaxe_unique"] = 55,
["bm nord leg"] = 10,
["bm_nordic_silver_lgswd_bloodska"] = 50,
["bm nordic silver longsword_cft"] = 50,
["bm nordic_longsword_tracker"] = 40,
["bm ice longsword_fg_unique"] = 70,
["bm frostgore"] = 50,
["nordic claymore_stormfang"] = 40,
["cruel_firestorm_dart"] = 35,
["cruel_firestorm_star"] = 35,
["dire_firestorm_dart"] = 35,
["dire_firestorm_star"] = 35,
["cruel_frostbloom_dart"] = 35,
["cruel_frostbloom_star"] = 35,
["dire_frostbloom_dart"] = 35,
["dire_frostbloom_star"] = 35,
["cruel_poisonbloom_dart"] = 35,
["cruel_poisonbloom_star"] = 35,
["dire_poisonbloom_dart"] = 35,
["dire_poisonbloom_star"] = 35,
["cruel_shockbloom_dart"] = 35,
["cruel_shockbloom_star"] = 35,
["dire_shockbloom_dart"] = 35,
["dire_shockbloom_star"] = 35,
["spiked club"] = 5,
["miner's pick"] = 10,
["mg_w_miner_pick"] = 10,
["mg_w_miner_pick_fake"] = 10,
["leafweave_dagger"] = 15,
["leafweave_dart"] = 15,
["leafweave_shortbow"] = 15,
["leafweave_shortsword"] = 15,
["leafweave_spear"] = 15,
["bound_battle_axe"] = 5,
["bound_dagger"] = 5,
["bound_longbow"] = 5,
["bound_longsword"] = 5,
["bound_mace"] = 5,
["bound_spear"] = 5,



}

local armorClassInfo = {
  [0] = {text = "Light Armor",  name = "lightArmor"},
  [1] = {text = "Medium Armor", name = "mediumArmor"},
  [2] = {text = "Heavy Armor",  name = "heavyArmor"},
}

local weaponTypeInfo = {
    ["ShortBladeOneHand"] = {text = "Short Blade",  name= "shortBlade"},
    ["LongBladeOneHand"]  = {text = "Long Blade",   name= "longBlade"},
    ["LongBladeTwoClose"] = {text = "Long Blade",   name= "longBlade"},
    ["BluntOneHand"]      = {text = "Blunt Weapon", name= "bluntWeapon"},
    ["BluntTwoClose"]     = {text = "Blunt Weapon", name= "bluntWeapon"},
    ["BluntTwoWide"]      = {text = "Blunt Weapon", name= "bluntWeapon"},
    ["SpearTwoWide"]      = {text = "Spear",        name= "spear"},
    ["AxeOneHand"]        = {text = "Axe",          name= "axe"},
    ["AxeTwoClose"]       = {text = "Axe",          name= "axe"},
    ["MarksmanBow"]       = {text = "Marksman",     name= "marksman"},
    ["MarksmanCrossbow"]  = {text = "Marksman",     name= "marksman"},
    ["MarksmanThrown"]    = {text = "Marksman",     name= "marksman"},
    ["Arrow"]             = {text = "Marksman",     name= "marksman"},
    ["Bolt"]              = {text = "Marksman",     name= "marksman"},
}

local function getItemSkillInfo(item)
  	local skillReq, skillInfo, meleeReq, rangedReq, armorReq, chopMax, slashMax, thrustMax, attackMax, speed, reach, armorRate, enchCapacity

  	if item.objectType == tes3.objectType.weapon then
    	skillReq = weaponReqTable[item.id:lower()]
		skillInfo = weaponTypeInfo[item.typeName]
	elseif item.objectType == tes3.objectType.armor then
		skillReq = armorReqTable[item.id:lower()]
    	skillInfo = armorClassInfo[item.weightClass]
end

    if (skillReq == nil) and item.isMelee then
        chopMax = item.chopMax
        slashMax = item.slashMax
        thrustMax = item.thrustMax
        speed = item.speed
        reach = item.reach
        meleeReq = ((((chopMax + slashMax + thrustMax) / 3) * 0.25) * ((speed * 2.15) * (reach * 1.85)) * 1.15)
		meleeReq = math.clamp(meleeReq, 5, 100)
        skillReq = meleeReq
        skillInfo = weaponTypeInfo[item.typeName]

	elseif (skillReq == nil) and item.isRanged then
		attackMax = item.chopMax
		rangedReq = attackMax * 1.4
		rangedReq = math.clamp(rangedReq, 5, 100)
		skillReq = rangedReq
		skillInfo = weaponTypeInfo[item.typeName]

	elseif (skillReq == nil) and item.objectType == tes3.objectType.armor then
		enchCapacity = item.enchantCapacity
		armorRate = ((item.armorRating * 0.70 + (enchCapacity / 120))* 1.4)
		armorRate = math.clamp(armorRate, 5, 100)
		skillReq = armorRate
    	skillInfo = armorClassInfo[item.weightClass]
    end


return skillReq, skillInfo, meleeReq, rangedReq, armorReq, chopMax, slashMax, thrustMax, attackMax, speed, reach, armorRate, enchCapacity
end


local function reqTooltip(e)
	local skillReq, skillInfo = getItemSkillInfo(e.object)

	if skillReq then
        local text = string.format("Requires %s : %u", skillInfo.text, skillReq)

        local block = e.tooltip:createBlock()
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 6
        local label = block:createLabel{text = text}
        label.color = (
            tes3.mobilePlayer[skillInfo.name].current < skillReq
            and tes3ui.getPalette("health_color")
            or tes3ui.getPalette("fatigue_color")
        )
        label.wrapText = true
    end
end

local function onEquip(e)
  	if e.reference == tes3.player then
        local skillReq, skillInfo = getItemSkillInfo(e.item)

        if skillReq and not config.alternateMode then
            if tes3.mobilePlayer[skillInfo.name].current < skillReq then
                tes3.messageBox("Your %s skill is too low to equip %s.", skillInfo.text, e.item.name)
                return false
				end
            end
        end
    end

local armorPen = 0
local weaponPen = 0

local function updatePenalty(e)
    if e.reference ~= tes3.player then
    	return
  	elseif not config.alternateMode then
    	return
    end

	armorPen = 0
	weaponPen = 0
  	--
  	for itemStack in tes3.iterate(tes3.player.object.equipment) do
    	local object = itemStack.object
    	local skillReq, skillInfo = getItemSkillInfo(object)


        if skillReq then
            if tes3.mobilePlayer[skillInfo.name].current < skillReq then
        		if object.objectType == tes3.objectType.weapon then
        			weaponPen = weaponPen + 1
        		elseif object.objectType == tes3.objectType.armor then
                    armorPen = armorPen + 1
                end
            end
        end
    end
end


local function onSpellCast(e)
	if (e.caster == tes3.player) and armorPen > 0 and config.alternateMode then
	if e.castChance > 100 then
		e.castChance = 100
			e.castChance = (e.castChance - ((e.castChance / 20) * armorPen))
		end
	end
end

local function onCalcMoveSpeed(e)
    if (e.reference == tes3.player) and armorPen > 0 and config.alternateMode then
		e.speed = e.speed - ((e.speed / 15) * armorPen)
			if tes3.mobilePlayer.isRunning then
				tes3.mobilePlayer.fatigue.current = tes3.mobilePlayer.fatigue.current - ((tes3.mobilePlayer.fatigue.current / 22525) * (armorPen / 0.2))
		end
	end
end

local attackMalus = 0

local function onAttack(e)
	if (e.reference == tes3.player) and weaponPen > 0 and config.alternateMode then
		attackMalus = 1
			tes3.mobilePlayer.fatigue.current = tes3.mobilePlayer.fatigue.current - (tes3.mobilePlayer.fatigue.current / 6)

	else attackMalus = 0
	end
end

local function onDamage(e)
	if (e.reference ~= tes3.player) and weaponPen > 0 and attackMalus == 1 and config.alternateMode then
		e.damage = e.damage / 1.5
	end
end


local function initialized(e)
  	event.register("spellCast", onSpellCast)
	event.register("calcMoveSpeed", onCalcMoveSpeed)
	event.register("attack", onAttack)
	event.register("damage", onDamage)
    event.register("uiObjectTooltip", reqTooltip)
	event.register("equip", onEquip)
	event.register("equipped", updatePenalty)
	event.register("skillRaised", function ()
	 	updatePenalty{reference=tes3.player}
	end)
	event.register("unequipped", function ()
		updatePenalty{reference=tes3.player}
	end)
	event.register("loaded", function ()
		updatePenalty{reference=tes3.player}
	end)
	print("Initialized EquipmentRequirements v0.00")

end
event.register("initialized", initialized)


--[[MOD CONFIG MENU]]--

local modConfig = {}
function modConfig.onCreate(container)

	local descriptionLabel = {}--global scope so we can update the description in click events

	local function getYesNoText (b)
		return b and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value
	end

	local function toggleAlternateMode(e)
		config.alternateMode = not config.alternateMode
		local button = e.source
		button.text = getYesNoText(config.alternateMode)
		descriptionLabel.text = config.alternateMode and
			"Alternative, penalty-based system."
			or
			"Normal system. Prevents you from equipping an item altogether."
	end


	do
		local optionBlock = container:createThinBorder({})
		optionBlock.layoutWidthFraction = 1.0
		optionBlock.flowDirection = "top_to_bottom"
		optionBlock.autoHeight = true
		optionBlock.paddingAllSides = 10


		local function makeButton(parentBlock, labelText, buttonText, callBack)
			local buttonBlock
			buttonBlock = parentBlock:createBlock({})
			buttonBlock.flowDirection = "left_to_right"
			buttonBlock.layoutWidthFraction = 1.0
			buttonBlock.autoHeight = true

			local label = buttonBlock:createLabel({ text = labelText })
			label.layoutOriginFractionX = 0.0

			local button = buttonBlock:createButton({ text = buttonText })
			button.layoutOriginFractionX = 1.0
			button.paddingTop = 3
			button:register("mouseClick", callBack)
		end
		local buttonText = getYesNoText(config.alternateMode)
		makeButton(optionBlock, "Enable alternate mode?", buttonText, toggleAlternateMode)


		--Description pane
		local descriptionBlock = container:createThinBorder({})
		descriptionBlock.layoutWidthFraction = 1.0
		descriptionBlock.paddingAllSides = 10
		descriptionBlock.layoutHeightFraction = 1.0
		descriptionBlock.flowDirection = "top_to_bottom"

		--Do description first so it can be updated by buttons
		descriptionLabel = descriptionBlock:createLabel({ text =
			"Equipment Requirements adds requirements to equip a certain item. " ..
			"If you do not meet the requirements you can either not equip the item at all or receive penalties. "
		})
		descriptionLabel.layoutWidthFraction = 1.0
		descriptionLabel.wrapText = true

	end
end

function modConfig.onClose(container)
	json.savefile("config/rem_requirements_config", config, { indent = true })
end

-- When the mod config menu is ready to start accepting registrations, register this mod.
local function registerModConfig()
	mwse.registerModConfig("Equipment Requirements", modConfig)
	end
event.register("modConfigReady", registerModConfig)

