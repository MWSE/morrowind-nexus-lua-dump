local v3 = require("openmw.util").vector3

local vectors = {

	offset = v3(0, 0, -2),

	["light_6th_candle_01.nif"] = { V = v3(0, 0, -5.7) },
	["light_6th_candle_02.nif"] = { V = v3(0, 0, -8.1) },
	["light_6th_candle_03.nif"] = { V = v3(0, 0, -8.8) },
	["light_6th_candle_04.nif"] = { V = v3(0, 0, -5.9) },
	["light_6th_candle_05.nif"] = { V = v3(0, 0, -4.9) },
	["light_6th_candle_06.nif"] = { V = v3(0, 0, -5.8) },

	["light_com_candle_01.nif"] = { V = v3(0, 0, 19.8) },
	["light_com_candle_02.nif"] = { V = v3(0, 0, 26.2) },
	["light_com_candle_03.nif"] = { V = v3(0, 0, 28.1) },	--silverware
	["light_com_candle_04.nif"] = {
		mV = { v3(4.3, 7.4, -3.2), v3(1.5, -5.9, -7.6), v3(-6.5, 1.3, -9.7) }
		},
	["light_com_candle_05.nif"] = { V = v3(0, 0, 19.6) },
	["light_com_candle_06.nif"] = {
		mV = { v3(4.4, 7.5, -2.6), v3(1.5, -5.8, -7.6), v3(-6.4, 1.3, -9.8) }
		},
	["light_com_candle_07.nif"] = {
		mV = { v3(3.6, 6.1, -2.1), v3(1.5, -5.8, -7.1), v3(-6.5, 1.3, -9.3) }
		},
	["light_com_candle_08.nif"] = { V = v3(0, 0, 28.1) },	--silverware
	["light_com_candle_09.nif"] = {
		mV = { v3(7.1, -7, 23.7), v3(0, 0, 27.5), v3(-7.1, 7.1, 22.6) },
		},
	["light_com_candle_10.nif"] = {				--silverware
		mV = { v3(7.1, -7, 23.7), v3(0, 0.1, 27.5), v3(-7, 7.1, 22.6) },
		},
	["light_com_candle_11.nif"] = {
		mV = { v3(4.3, 7.4, -3.4), v3(1.5, -5.9, -7.5), v3(-6.5, 1.3, -9.9) }
		},
	["light_com_candle_12.nif"] = { V = v3(0, 0, 19.6) },
	["light_com_candle_13.nif"] = {
		mV = { v3(4.3, 7.5, -2.7), v3(1.5, -5.8, -7.6), v3(-6.5, 1.3, -9.8) }
		},
	["light_com_candle_14.nif"] = { V = v3(0, 0, 28.1) },	--silverware
	["light_com_candle_15.nif"] = { V = v3(0, 0, 28.1) },	--silverware
	["light_com_candle_16.nif"] = {				--silverware
		mV = { v3(7.1, -7, 23.7), v3(0, 0.1, 27.5), v3(-7, 7.1, 22.6) },
		},
	["light_com_sconce_01.nif"] = { V = v3(0, 0, -5.4) },
	["light_com_sconce_02.nif"] = {
		mV = { v3(9.8, -1.65, -7.3), v3(0, 2.6, -5), v3(-9.9, -1.7, -8.1) }
		},
	["light_com_lamp_01.nif"] = { V = v3(0, 0, -18.7) },
	["light_com_lamp_02.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) }
		},
	["light_de_candle_01.nif"] = { V = v3(0, 0, -3.1) },
	["light_de_candle_02.nif"] = { V = v3(0, 0, -3.6) },
	["light_de_candle_03.nif"] = { V = v3(-3.63, 0, 11.7) },
	["light_de_candle_04.nif"] = { V = v3(0.1, 0, -3) },
	["light_de_candle_05.nif"] = { V = v3(-12.2, 0.1, -0.4) },
	["light_de_candle_06.nif"] = { V = v3(0, 0, 16) },
	["light_de_candle_07.nif"] = { V = v3(0, 0, -3.3) },
	["light_de_candle_08.nif"] = { V = v3(0, 0, -3.1) },
	["light_de_candle_09.nif"] = { V = v3(0, 0, -3.9) },
	["light_de_candle_10.nif"] = { V = v3(-3.5, 0, 11.5) },
	["light_de_candle_11.nif"] = { V = v3(-3.5, 0, 11.5) },
	["light_de_candle_12.nif"] = { V = v3(-3.4, 0, 11.5) },
	["light_de_candle_13.nif"] = { V = v3(-3.4, 0, 11.4) },
	["light_de_candle_14.nif"] = { V = v3(-3.5, 0, 11.5) },
	["light_de_candle_15.nif"] = { V = v3(0, 0, 16.4) },
	["light_de_candle_16.nif"] = { V = v3(0, 0, 16.3) },
	["light_de_candle_17.nif"] = { V = v3(0, 0, 16.3) },
	["light_de_candle_18.nif"] = { V = v3(-12.3, 0.1, -0.5) },
	["light_de_candle_19.nif"] = { V = v3(-12.3, 0.1, -0.5) },
	["light_de_candle_20.nif"] = { V = v3(-3.5, 0, 11.6) },
	["light_de_candle_21.nif"] = { V = v3(-3.5, 0, 11.4) },
	["light_de_candle_22.nif"] = { V = v3(-3.5, 0, 11.6) },
	["light_de_candle_23.nif"] = { V = v3(0, 0, 16.5) },
	["light_de_candle_24.nif"] = { V = v3(0, 0, 16.3) },
	["light_de_candle_25.nif"] = { V = v3(-12.3, 0.1, -0.5) },
	["light_de_candle_26.nif"] = { V = v3(-12.3, 0.1, -0.5) },
	["light_de_candle_blue_01.nif"] = { V = v3(0, 0, 14.4) },
	["light_de_candle_blue_02.nif"] = { V = v3(0, 0, 14.3) },
	["light_de_candle_green_01.nif"] = { V = v3(0, 0, 24.2) },
	["light_de_candle_ivory_01.nif"] = { V = v3(0, 0, 19.3) },
	["light_de_candle_red_01.nif"] = { V = v3(0, 0, 22.9) },
	["light_de_candle_red_02.nif"] = { V = v3(0, 0, 22.9) },
	["light_de_lamp_01.nif"] = { V = v3(0, 0, -9.8) },
	["light_de_lamp_02.nif"] = { V = v3(0, 0, -13) },
	["light_de_lamp_03.nif"] = { V = v3(0, 0, -15.3) },
	["light_de_lamp_04.nif"] = { V = v3(0, 0, -16.1) },
	["light_de_lamp_05.nif"] = { V = v3(0, 0, -15.6) },
	["light_de_lamp_06.nif"] = { V = v3(0, 0, -17.6) },
	["light_de_lamp_07.nif"] = { V = v3(0, 0, -13) },
	["light_de_lamp_08.nif"] = { V = v3(0, 0, -15.3) },
	["light_de_lamp_09.nif"] = { V = v3(0, 0, -17.6) },
	["light_de_lantern_02.nif"] = { V = v3(-3.3, 0.1, -13.8) },
	["light_de_lantern_06.nif"] = { V = v3(-3.2, 0.1, -13.7) },
	["light_redware_lamp.nif"] = { V = v3(-24.2, 0, 0.5) },
	["light_spear_skull00.nif"] = { V = v3(0, 0, 126.2) },

	---- Tamriel Rebuilt
	["tr_dreughcandle_01.nif"] = { V = v3(0, 0, -3) },
	["tr_dreughcandle_02.nif"] = { V = v3(0, 0, -3) },
	["tr_dreughcandle_03.nif"] = { V = v3(0, 0, -3) },
	["tr_dreughcandle_04.nif"] = { V = v3(0, 0, -3) },
	["tr_l_de_g_candleblue.nif"] = { V = v3(0, 0, 16.5) },
	["tr_l_de_g_candleblueb.nif"] = { V = v3(0, 0, 16.5) },
	["tr_l_de_g_candlepurple.nif"] = { V = v3(0, 0, 16.5) },
	["tr_l_de_g_candlered.nif"] = { V = v3(0, 0, 16.5) },
	["tr_l_de_g_candlewhite.nif"] = { V = v3(0, 0, 16.5) },

	---- SHOTN
	["sky_lgt_nord_scnb_01.nif"] = { V = v3(0, 0, 44.1) },
	["sky_lgt_nord_scnb_02.nif"] = { V = v3(0, 0, 44.1) },
	["sky_light_nord_lat_03.nif"] = { V = v3(-3.3, 0, -13.7) },
	["sky_light_nord_lat_04.nif"] = { V = v3(-3.3, 0, -13.7) },
	["sky_lgt_nord_cdst_01.nif"] = {
		mV = { v3(-0.5, 21, 57.5), v3(-17.6, 0, 57.5), v3(0, -22, 57.5) }
		},
	["sky_lgt_nord_csdc01.nif"] = {
		mV = { v3(-5, 14.1, -4), v3(14, 5.4, -4), v3(5.7, -15, -4), v3(-14, -5.1, -4) }
		},

	---- Project Cyrodiil
	["hr_l_gglass_cnd_01gre.nif"] = { V = v3(0, 0, 36.2) },
	["hr_l_gglass_cnd_01pur.nif"] = { V = v3(0, 0, 36.2) },
	["hr_l_gglass_cnd_01purp.nif"] = { V = v3(0, 0, 36.2) },
	["hr_l_gglass_cnd_01whi.nif"] = { V = v3(0, 0, 36.2) },
	["hr_l_gglass_cnd_01blu.nif"] = { V = v3(0, 0, 36.2) },
	["hr_l_gglass_cnd_01blub.nif"] = { V = v3(0, 0, 36.2) },

	["pc_candle_blck01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blck02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blck03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blck04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckblf01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckblf02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckblf03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckblf04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckrfl01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckrfl02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckrfl03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blckrfl04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blue01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blue02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blue03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blue04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blueblf01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blueblf02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blueblf03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_blueblf04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_green01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_green02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_green03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_green04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_purpl01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_purpl02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_purpl03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_purpl04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_red01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_red02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_red03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_red04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_redrfl01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_redrfl02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_redrfl03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_redrfl04.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_white01.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_white02.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_white03.nif"] = { V = v3(0, 0, -3) },
	["pc_candle_white04.nif"] = { V = v3(0, 0, -3) },
	["pc_com_lamp_01_blackb.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_01_blackr.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_01_blue.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_01_blueb.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_01_red.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_01_redr.nif"] = { V = v3(0, 0, -18.7) },
	["pc_com_lamp_02_blackb.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_com_lamp_02_blackr.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_com_lamp_02_blue.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_com_lamp_02_blueb.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_com_lamp_02_red.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_com_lamp_02_redr.nif"] = {
		mV = { v3(11.6, 4.4, -14.4), v3(0.1, -15.6, -17.2), v3(-11.2, 4.4, -15.2) },
		},
	["pc_l_gld_cndl1_w01.nif"] = { V = v3(0, 0, 28.1) },
	["pc_l_gld_cndl2_w01.nif"] = {
		mV = { v3(4.7, -4.7, 26.7), v3(0, 0.1, 28.1), v3(-4.7, 4.7, 25.4) },
		},
	["pc_rga_brlamp_01.nif"] = { V = v3(-12, -0.2, 5.8) },
	["pc_rga_burner_01.nif"] = { V = v3(-2.4, 0, -18.7) },
	["pc_rga_burner_02.nif"] = { V = v3(-2.4, 0, -18.7) },
	["pc_rga_burner_w_01.nif"] = { V = v3(0.5, -4.5, 14.8) },
	["pc_rga_burner_w_02.nif"] = { V = v3(0.5, -4.5, 14.8) },

	["pi_l_coco_lanternred.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanternredr.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanternwhi.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanternyel.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanternblu.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanternblub.nif"] = { V = v3(0, 0, -9.4) },
	["pi_l_coco_lanterngre.nif"] = { V = v3(0, 0, -9.4) },

	---- OAAB
	["meshes/oaab/l/pc_candle_blck03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_blckblf03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_blckrfl03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_blue03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_blueblf03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_green03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_purpl03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_red03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_redrfl03.nif"] = { V = v3(0, 0, -2) },
	["meshes/oaab/l/pc_candle_white03.nif"] = { V = v3(0, 0, -2) },
	["skull_candle_blk_bf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_blk_rf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_blk_wf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_blu_bf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_blu_wf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_grn_wf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_prp_wf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_red_rf.nif"] = { V = v3(0, 0, 17.5) },
	["skull_candle_red_wf.nif"] = { V = v3(0, 0, 17.5) },

	---- The Devil's Doorstep
	["ko_gold_candle.nif"] = {
		mV = { v3(7.1, -7, 23.7), v3(0, 0.1, 27.5), v3(-7, 7.1, 22.6) },
		},

}

--[[


--]]

return vectors

