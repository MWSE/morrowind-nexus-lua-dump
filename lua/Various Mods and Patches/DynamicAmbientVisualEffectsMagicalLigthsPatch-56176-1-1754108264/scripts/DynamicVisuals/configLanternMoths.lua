local v3 = common.openmw.util.vector3

local vectors = {

	["ex_mh_streetlamp_01.nif"] = v3(0, 0, 177),
	["light_ashl_lantern_01.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_02.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_03.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_04.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_05.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_06.nif"] = v3(0, 0, 0),
	["light_ashl_lantern_07.nif"] = v3(0, 0, 0),
	["light_com_lantern_01.nif"] = v3(-2.4, 0, -17),
	["light_com_lantern_02.nif"] = v3(-2.4, 0, -17),
	["light_common_01.nif"] = v3(-0.3, -13.5, -7),
	["light_de_lantern_01.nif"] = v3(-3.4, 0, -21),
	["light_de_lantern_03.nif"] = v3(3.6, 0, -19),
	["light_de_lantern_04.nif"] = v3(3.6, 0, -20),
	["light_de_lantern_05.nif"] = v3(-3.6, 0, -23.1),
	["light_de_lantern_07.nif"] = v3(-3.4, 0, -20),
	["light_de_lantern_08.nif"] = v3(-3.7, 0, -17.9),
	["light_de_lantern_09.nif"] = v3(3.6, 0, -20),
	["light_de_lantern_10.nif"] = v3(-3.5, 0, -23.4),
	["light_de_lantern_11.nif"] = v3(-3.4, 0, -19.5),
	["light_de_lantern_12.nif"] = v3(3.6, 0, -18),
	["light_de_lantern_13.nif"] = v3(3.6, 0, -19),
	["light_de_lantern_14.nif"] = v3(-3.6, 0, -25.3),
	["light_de_streetlight_01.nif"] = v3(0, 0, -23),
	["light_mh_rope_lantern.nif"] = v3(-1.8, 0, -212),
	["light_mh_streetlamp_01.nif"] = v3(0, 0, 177),
	["light_mh_streetlight_01.nif"] = v3(0, 0, 175),
	["light_paper_lantern_01.nif"] = v3(0, 0, -5),
	["light_paper_lantern_02.nif"] = v3(0, 0, -5),

	-- TR
	["tr_l_de_lantern_15.nif"] = v3(3.66, 0, -17.9),
	["tr_l_de_lantern_blu_01.nif"] = v3(-3.4, 0, -21),
	["tr_l_de_lantern_blu_02.nif"] = v3(3.6, 0, -19.4),
	["tr_l_de_lantern_blu_03.nif"] = v3(3.6, 0, -20.5),
	["tr_l_de_lantern_blu_04.nif"] = v3(-3.6, 0, -21.1),
	["tr_l_de_lantern_grn_01.nif"] = v3(-3.4, 0, -21),
	["tr_l_de_lantern_grn_02.nif"] = v3(3.6, 0, -19.4),
	["tr_l_de_lantern_grn_03.nif"] = v3(3.6, 0, -20.5),
	["tr_l_de_lantern_grn_04.nif"] = v3(-3.6, 0, -21.1),
	["tr_l_de_lantern_prp_01.nif"] = v3(-3.4, 0, -21),
	["tr_l_de_lantern_prp_02.nif"] = v3(3.6, 0, -19.4),
	["tr_l_de_lantern_prp_03.nif"] = v3(3.6, 0, -20.5),
	["tr_l_de_lantern_prp_04.nif"] = v3(-3.6, 0, -21.1),
	["tr_l_de_lantern_ylw_01.nif"] = v3(-3.4, 0, -21),
	["tr_l_de_lantern_ylw_02.nif"] = v3(3.6, 0, -19.4),
	["tr_l_de_lantern_ylw_03.nif"] = v3(3.6, 0, -20.5),
	["tr_l_de_lantern_ylw_04.nif"] = v3(-3.6, 0, -21.1),
	["tr_l_de_lantgl_grn01.nif"] = v3(-3.4, 0, -11.5),
	["tr_l_de_lantgl_red01.nif"] = v3(-3.4, 0, -11.5),
	["tr_l_de_lantgl_yel01.nif"] = v3(-3.4, 0, -11.5),
	["tr_l_de_paplant_blu_01.nif"] = v3(0, 0, -5),
	["tr_l_de_paplant_grn_01.nif"] = v3(0, 0, -5),
	["tr_l_de_paplant_prp_01.nif"] = v3(0, 0, -5),
	["tr_l_de_paplant_red_01.nif"] = v3(0, 0, -5),
	["tr_l_de_paplant_whi_01.nif"] = v3(0, 0, -5),
	["tr_l_de_paplant_ylw_01.nif"] = v3(0, 0, -5),

	-- SHOTN
	["sky_lgt_red_01.nif"] = v3(-0.34, -0.17, -1),
	["sky_lgt_red_02.nif"] = v3(-0.34, -0.17, -1),

	-- PC
	["pc_col_lantern_02.nif"] = v3(-2.4, 0, -16.9),
	["pc_col_lantern_03.nif"] = v3(-2.4, 0, -16.9),
	["pc_col_lantern_04.nif"] = v3(-2.4, 0, -16.9),
	["pc_col_lantern_05.nif"] = v3(-2.4, 0, -16.9),
	["pc_col_streetlamp_01.nif"] = v3(0, 0, -22.9),

	-- Magical lights for Telvanni
	["uvi_crystal_bulb_blu.nif"] =v3(0, 0, -35),
	["uvi_crystal_bulb_wrm.nif"] =v3(0, 0, -35),

}

return vectors

