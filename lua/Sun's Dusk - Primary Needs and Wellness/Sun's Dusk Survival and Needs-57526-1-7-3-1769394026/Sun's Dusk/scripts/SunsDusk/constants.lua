-- Colors
G_morrowindGold 	= getColorFromGameSettings("fontColor_color_normal")
G_morrowindLight 	= getColorFromGameSettings("fontColor_color_normal_over")
G_morrowindPressed 	= getColorFromGameSettings("FontColor_color_normal_pressed")
G_goldenMix 		= mixColors(G_morrowindGold, G_morrowindLight)
G_goldenMix2 		= mixColors(G_morrowindLight, G_morrowindGold, 0.3)
G_lightText 		= util.color.rgb(G_morrowindLight.r^0.5,G_morrowindLight.g^0.5,G_morrowindLight.b^0.5)
G_morrowindBlue 	= getColorFromGameSettings("fontColor_color_journal_link")
G_morrowindBlue2 	= getColorFromGameSettings("fontColor_color_journal_link_over")
G_morrowindBlue3 	= getColorFromGameSettings("fontColor_color_journal_link_pressed")


presetColors = {
    "d4edfc", -- thirst
    "bfd4bc", -- hunger
    "cfbddb", -- sleep
    "81cded", -- fav color of blue
    "caa560", -- fontColor_color_normal
    "d4b77f", -- goldenMix
    "dfc99f", -- FontColor_color_normal_over
    "eee2c9", -- lightText
    "253170", -- fontColor_color_journal_link
    "3a4daf", -- fontColor_color_journal_link_over
    "707ecf", -- fontColor_color_journal_link_pressed
}

burningLogs = {
    ["sd_wood_1_lit"] = true,
    ["sd_wood_2_lit"] = true,
    ["sd_wood_3_lit"] = true,
    ["sd_wood_4_lit"] = true,
    ["sd_wood_5_lit"] = true,
}

logItems = {
    ["sd_wood_1"] = 1,
    ["sd_wood_2"] = 2,
	["sd_wood_3"] = 3,
	["sd_wood_4"] = 4,
	["sd_wood_5"] = 5,
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Log Levels															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

DEBUG_LEVEL = 5  --  { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
local _raw_print = print 
function log(level, ...)
	if level <= DEBUG_LEVEL then
		_raw_print(...)
	end
end


-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Foodware Detection                                                   │
-- ╰──────────────────────────────────────────────────────────────────────╯

local BOWL_WHITELIST = { "_bowl", "bowl_" }
local BOWL_BLACKLIST = { "bowler", "bowling" }

local PLATE_WHITELIST = { "_plate", "plate_", "_platter", "platter_" }
local PLATE_BLACKLIST = { "template", "armor", "bonemold" }

-- Returns "bowl", "plate", or nil
-- Accepts item object (with recordId and record access)
function getFoodwareType(item)
	if not item then return nil end
	local rec = types.Miscellaneous.record(item)
	if not rec then return nil end
	
	local id = rec.id:lower()
	local name = (rec.name or ""):lower()
	
	-- Check bowl blacklist first
	for _, pattern in ipairs(BOWL_BLACKLIST) do
		if id:find(pattern, 1, true) or name:find(pattern, 1, true) then
			goto checkPlate
		end
	end
	-- Check bowl whitelist
	for _, pattern in ipairs(BOWL_WHITELIST) do
		if id:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "bowl"
		end
	end
	
	::checkPlate::
	-- Check plate blacklist
	for _, pattern in ipairs(PLATE_BLACKLIST) do
		if id:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return nil
		end
	end
	-- Check plate whitelist
	for _, pattern in ipairs(PLATE_WHITELIST) do
		if id:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "plate"
		end
	end
	
	return nil
end

foodOffsets = {
	["sd_food_meat_salt"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_m_fish"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_aff_sr"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_aff_hs"] = {
		offset = util.vector3(1.00, 0.00, 0.00),
		scale = 0.10
	},
	["sd_food_m_g"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.37
	},
	["sd_food_aff_ar"] = {
		offset = util.vector3(0.20, 0.10, 0.00),
		scale = 1.39
	},
	["sd_food_aff_ms"] = {
		offset = util.vector3(0.00, 0.50, 0.00),
		scale = 0.10
	},
	["sd_food_aff_yc"] = {
		offset = util.vector3(1.00, -1.00, 0.00),
		scale = 0.45
	},
	["sd_food_aff_cms"] = {
		offset = util.vector3(0.70, -1.30, 0.00),
		scale = 0.62
	},
	["sd_food_g"] = {
		offset = util.vector3(0.30, 0.00, 0.00),
		scale = 0.72
	},
	["sd_food_aff_ssss"] = {
		offset = util.vector3(-0.10, 0.10, 0.00),
		scale = 0.74
	},
	["sd_food_aff_cr"] = {
		offset = util.vector3(0.70, -1.20, 0.00),
		scale = 0.63
	},
	["sd_food_aff_ss"] = {
		offset = util.vector3(0.70, -1.20, 0.00),
		scale = 0.62
	},
	["sd_food_g_salt"] = {
		offset = util.vector3(-0.20, 0.10, 0.00),
		scale = 0.74
	},
	["sd_food_aff_ps"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.63
	},
	["sd_food_aff_my"] = {
		offset = util.vector3(0.70, -0.50, 0.00),
		scale = 0.57
	},
	["sd_food_aff_m"] = {
		offset = util.vector3(0.70, -1.10, 0.00),
		scale = 0.63
	},
	["sd_food_aff_ks"] = {
		offset = util.vector3(0.00, 3.00, 0.00),
		scale = 0.15
	},
	["sd_food_aff_gdm"] = {
		offset = util.vector3(0.70, -1.30, 0.00),
		scale = 0.62
	},
	["sd_food_aff_cs"] = {
		offset = util.vector3(0.80, -1.20, 0.00),
		scale = 0.62
	},
	["sd_food_aff_sfst"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.57
	},
	["sd_food_aff_hls"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_f"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 1.05
	},
	["sd_food_m_fruit"] = {
		offset = util.vector3(-0.10, 0.00, 0.00),
		scale = 0.74
	},
	["sd_food_f_greens_herb"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.54
	},
	["sd_food_f_crab_spice"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_f_salt"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.57
	},
	["sd_food_f_greens_salt"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.65
	},
	["sd_food_meat"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.70
	},
	["sd_food_m_spice"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_m_greens_salt"] = {
		offset = util.vector3(-0.10, 0.00, 0.00),
		scale = 0.54
	},
	["sd_food_g_spice"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.92
	},
	["sd_food_meat_spice"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_meat_salt_greens"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_fruit_greens_herb"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.65
	},
	["sd_food_e"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_fruit"] = {
		offset = util.vector3(-0.10, 0.10, 0.00),
		scale = 1.03
	},
	["sd_food_meat_greens_herb"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.70
	},
	["sd_food_e_greens_salt"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.65
	},
	["sd_food_aff_har"] = {
		offset = util.vector3(0.70, -1.20, 0.00),
		scale = 0.61
	},
	["sd_food_m_meat"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.50
	},
	["sd_food_meat_fish"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.65
	},
	["sd_food_aff_rs"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.60
	},
	["sd_food_m"] = {
		offset = util.vector3(-0.50, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_m_salt"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.40
	},
	["sd_food_e_meat"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.55
	},
	["sd_food_def_mixed"] = {
		offset = util.vector3(-0.10, 0.20, 0.00),
		scale = 1.15
	},
	["sd_food_def_meatsoup"] = {
		offset = util.vector3(-0.10, 0.10, 0.00),
		scale = 1.13
	},
	["sd_food_def_meat"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.65
	},
	["sd_food_def_vegan"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 0.58
	},
	["sd_food_aff_sicksoup"] = {
		offset = util.vector3(0.00, 0.00, 0.00),
		scale = 1.05
	},
}

foodwareOffsets = {
    ["misc_imp_silverware_bowl"] = {
        offset = util.vector3(0.0, 0.00, -1.30),
        scale = 0.87
    },
	["t_qyc_shellwarebowl_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.42
	},
	["t_qyc_shellwarebowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.53
	},
	["t_rga_porcelainbowl_01"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.26
	},
	["t_qyc_shellwarebowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.11
	},
	["t_bre_clayplatter_01"] = {
			offset = util.vector3(0,0,1),
			scale = 2.386
	},
	["t_nor_finewoodbowl_01"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.79
	},
	["t_bre_clayplate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.467
	},
	["t_nor_decorativebowl_03"] = {
			offset = util.vector3(0,0,1),
			scale = 1.79
	},
	["t_bre_claybowl_02"] = {
			offset = util.vector3(0,0,2),
			scale = 1.05
	},
	["t_bre_claybowl_01"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.16
	},
	["t_rga_glasswareplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.3
	},
	["t_rga_glasswarebowl_01"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.21
	},
	["t_nor_woodenplate_03b"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.789
	},
	["t_nor_woodenplate_03a"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.849
	},
	["t_nor_woodenplate_02b"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.575
	},
	["t_nor_woodenplate_02a"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.515
	},
	["t_nor_woodenplate_01b"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_nor_cordedbowl_02"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.47
	},
	["t_nor_woodenplate_01a"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_nor_cordedbowl_01"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.58
	},
	["t_de_bluewareplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["t_he_dirennibowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.21
	},
	["t_rga_clayplatter_01"] = {
			offset = util.vector3(0,0,2),
			scale = 1.252
	},
	["t_rga_clayplate_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.515
	},
	["t_rga_clayplate_01"] = {
			offset = util.vector3(0,0,2),
			scale = 1.515
	},
	["t_com_coconutplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.026
	},
	["t_he_clayplatter_02"] = {
			offset = util.vector3(0,0,1),
			scale = 2.171
	},
	["t_he_clayplatter_01"] = {
			offset = util.vector3(0,0,1),
			scale = 2.386
	},
	["t_imp_ebonplate_02"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.682
	},
	["t_de_blueglassbowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 2.32
	},
	["t_nor_ceramicbowl_03"] = {
			offset = util.vector3(0,0,1),
			scale = 1.74
	},
	["t_nor_ceramicbowl_02"] = {
			offset = util.vector3(0,0,-3),
			scale = 1.84
	},
	["t_com_coconutbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.11
	},
	["t_nor_ceramicbowl_01"] = {
			offset = util.vector3(0,0,-8.5),
			scale = 2.21
	},
	["t_he_claybowl_02"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.11
	},
	["t_he_claybowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.11
	},
	["t_rga_claybowl_03"] = {
			offset = util.vector3(0,0,5.5),
			scale = 1.26
	},
	["t_rga_claybowl_02"] = {
			offset = util.vector3(0,0,5.5),
			scale = 1.16
	},
	["t_rga_claybowl_01"] = {
			offset = util.vector3(0,0,6),
			scale = 1.16
	},
	["t_ned_mw_bowl"] = {
			offset = util.vector3(0,0,-1.5),
			scale = 1.58
	},
	["t_ayl_plate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.3
	},
	["t_he_bluewareplatter_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 2.219
	},
	["t_imp_colbarrowclayplatter_01"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.73
	},
	["t_he_bluewareplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.575
	},
	["t_imp_colbarrowclayplate_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.789
	},
	["t_bre_silverplate_04"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_silverplate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_silverplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_arg_woodenbowl_03"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.37
	},
	["misc_de_bowl_orange_green_01"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 1.63
	},
	["t_de_stonewareplate_02"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.515
	},
	["t_he_clayplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.515
	},
	["t_imp_carvedwoodbowl_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.11
	},
	["misc_dwrv_bowl00_uni"] = {
			offset = util.vector3(0,0,-2),
			scale = 1.79
	},
	["t_he_greenceladonbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.47
	},
	["t_he_greenceladonplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_stonewarebowl_02"] = {
			offset = util.vector3(0,0,2),
			scale = 2.58
	},
	["t_bre_silverplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_stonewarebowl_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.47
	},
	["t_com_woodplate_a01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_bre_silverbowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.21
	},
	["t_nor_stonewarebowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.32
	},
	["t_he_greenceladonplatter_01"] = {
			offset = util.vector3(0,0,-1),
			scale = 2.112
	},
	["t_com_woodplatter_c01"] = {
			offset = util.vector3(0,0,-2),
			scale = 2.386
	},
	["t_imp_ebonplatter_01"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.73
	},
	["t_bre_silverplatter_02"] = {
			offset = util.vector3(0,0,2),
			scale = 2.708
	},
	["t_bre_woodplatter_02"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.622
	},
	["t_ayl_claybowl_01"] = {
			offset = util.vector3(0,0,4),
			scale = 3.32
	},
	["t_bre_silverplate_05"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_silverplate_06"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_silverplate_07"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_imp_goldplate_03"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.682
	},
	["t_imp_goldplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.622
	},
	["t_imp_goldplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.849
	},
	["ab_misc_declaybowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2.26
	},
	["t_qy_palmwoodbowl_03"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 2
	},
	["t_qy_palmwoodbowl_02"] = {
			offset = util.vector3(0,0,-2.5),
			scale = 1.74
	},
	["t_qy_palmwoodbowl_01"] = {
			offset = util.vector3(0,0,2),
			scale = 1.05
	},
	["ab_misc_deblueplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.575
	},
	["t_de_ebony_bowl_02"] = {
			offset = util.vector3(0,0,3),
			scale = 1.21
	},
	["t_de_ebony_bowl_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.05
	},
	["t_imp_goldbowl_04"] = {
			offset = util.vector3(0,0,2),
			scale = 1.37
	},
	["t_imp_goldbowl_03"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.21
	},
	["t_imp_goldbowl_02"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.26
	},
	["t_qy_bronzeplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.73
	},
	["t_imp_goldbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.05
	},
	["t_nor_woodenbowl_04b"] = {
			offset = util.vector3(0,0,0.5),
			scale = 0.84
	},
	["t_qy_bronzeplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["t_nor_woodenbowl_03b"] = {
			offset = util.vector3(0,0,-3),
			scale = 1.37
	},
	["t_nor_woodenbowl_03a"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 1.37
	},
	["t_nor_woodenbowl_02b"] = {
			offset = util.vector3(0,0,0),
			scale = 1.05
	},
	["t_nor_woodenbowl_02a"] = {
			offset = util.vector3(0,0,0),
			scale = 1.05
	},
	["t_nor_woodenbowl_01b"] = {
			offset = util.vector3(0,0,-1.5),
			scale = 1.42
	},
	["t_nor_woodenbowl_01a"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.42
	},
	["ab_misc_deyelglassplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_nor_stonewareplatter_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.575
	},
	["t_nor_stonewareplate_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.3
	},
	["t_qy_bronzebowl_03"] = {
			offset = util.vector3(0,0,-3),
			scale = 1.95
	},
	["t_qy_bronzebowl_02"] = {
			offset = util.vector3(0,0,-1.5),
			scale = 1.47
	},
	["misc_lw_bowl_chapel"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 2.95
	},
	["misc_lw_bowl"] = {
			offset = util.vector3(0,0,-4.5),
			scale = 3.42
	},
	["t_rga_woodplate_02"] = {
			offset = util.vector3(0,0,5.5),
			scale = 1.575
	},
	["t_rga_woodplate_01"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.467
	},
	["t_qy_redglassplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.252
	},
	["t_bre_silverbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.16
	},
	["t_imp_colclaybowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.32
	},
	["t_com_woodplate_c01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.515
	},
	["t_qy_bronzebowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.26
	},
	["t_rga_blackwarebowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 1.05
	},
	["t_com_woodplatter_d01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.849
	},
	["t_he_shellplatter_02"] = {
			offset = util.vector3(0,0,-1.5),
			scale = 1.73
	},
	["t_nor_ironwoodplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.682
	},
	["t_yne_stoneplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_he_bluewarebowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.32
	},
	["t_qy_redglassplate_02"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.682
	},
	["t_yne_stonebowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.26
	},
	["t_com_coconutbowl_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.37
	},
	["t_qy_redglassbowl_02"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.21
	},
	["t_imp_colbarrowclaybowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.42
	},
	["t_yne_woodenplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.622
	},
	["ab_misc_deredglassbowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2.05
	},
	["t_nor_silverplate_03"] = {
			offset = util.vector3(0,0,1),
			scale = 1.515
	},
	["t_de_purpleglassbowl_02"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 2.53
	},
	["t_nor_silverplate_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.408
	},
	["t_yne_woodenbowl_03"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.74
	},
	["t_nor_silverbowl_02"] = {
			offset = util.vector3(0,0,4),
			scale = 1.11
	},
	["t_rga_woodbowl_02"] = {
			offset = util.vector3(0,0,4),
			scale = 1.58
	},
	["t_nor_silverbowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 1.32
	},
	["t_qyk_ceramicplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.682
	},
	["t_rga_redwareplate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.515
	},
	["t_nor_woodenbowl_04a"] = {
			offset = util.vector3(0,0,1),
			scale = 0.84
	},
	["t_imp_ebonplate_01"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.467
	},
	["t_de_stonewarebowl_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 2.11
	},
	["misc_imp_silverware_plate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["t_yne_clayplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.622
	},
	["t_qyk_ceramicbowl_03"] = {
			offset = util.vector3(0,0,-4),
			scale = 2.11
	},
	["t_qyk_ceramicbowl_02"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.84
	},
	["t_qyk_ceramicbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.47
	},
	["t_rga_porcelainplatter_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 2.219
	},
	["t_rga_porcelainplate_03"] = {
			offset = util.vector3(0,0,1),
			scale = 1.849
	},
	["t_imp_silverwareplate_04"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["misc_com_redware_platter"] = {
			offset = util.vector3(0,0,-2),
			scale = 2.219
	},
	["t_nor_ironwoodbowl_01"] = {
			offset = util.vector3(0,0,4),
			scale = 1.11
	},
	["t_bre_greenglassplatter_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.957
	},
	["t_yne_claybowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.42
	},
	["t_qyc_shellwareplate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_qyc_shellwareplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["misc_com_redware_bowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.21
	},
	["misc_com_redware_bowl"] = {
			offset = util.vector3(0,0,0),
			scale = 1.95
	},
	["t_qyc_shellwareplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["misc_imp_silverware_plate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_arg_woodenbowl_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.21
	},
	["t_imp_ebonbowl_02"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 2.37
	},
	["t_bre_stonewareplatter_01"] = {
			offset = util.vector3(0,0,1),
			scale = 2.708
	},
	["t_arg_woodenbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.16
	},
	["t_imp_ebonbowl_01"] = {
			offset = util.vector3(0,0,-3),
			scale = 1.68
	},
	["t_nor_decorativebowl_02"] = {
			offset = util.vector3(0,0,-3),
			scale = 1.84
	},
	["t_arg_woodenplatter_02"] = {
			offset = util.vector3(0,0,2),
			scale = 1.73
	},
	["t_bre_woodbowl_04"] = {
			offset = util.vector3(0,0,0),
			scale = 2
	},
	["t_arg_ceramicplate_02"] = {
			offset = util.vector3(0,0,2),
			scale = 1.682
	},
	["misc_de_bowl_redware_02"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.89
	},
	["misc_imp_silverware_plate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["t_bre_woodplatter_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 2.553
	},
	["t_com_coconutbowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.32
	},
	["t_com_woodbowl_c03"] = {
			offset = util.vector3(0,0,0),
			scale = 2.05
	},
	["t_imp_colclayplatter_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 2.494
	},
	["t_imp_colclayplate_02"] = {
			offset = util.vector3(0,0,2),
			scale = 1.3
	},
	["t_imp_colclayplate_01"] = {
			offset = util.vector3(0,0,3),
			scale = 1.575
	},
	["t_qy_redglassbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.05
	},
	["t_imp_colbarrowplatter_01"] = {
			offset = util.vector3(0,0,6.5),
			scale = 2.601
	},
	["misc_de_bowl_glass_yellow_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2.74
	},
	["t_rga_redwarebowl_01"] = {
			offset = util.vector3(0,0,4),
			scale = 1.47
	},
	["t_rga_clayplate_03"] = {
			offset = util.vector3(0,0,2),
			scale = 1.467
	},
	["misc_de_bowl_glass_peach_01"] = {
			offset = util.vector3(0,0,6),
			scale = 2.84
	},
	["t_he_shellplatter_03"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.622
	},
	["t_nor_decorativebowl_01"] = {
			offset = util.vector3(0,0,-8.5),
			scale = 2.21
	},
	["misc_de_bowl_bugdesign_01"] = {
			offset = util.vector3(0,0,5.5),
			scale = 2.79
	},
	["misc_de_bowl_redware_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2.21
	},
	["t_bre_redglassplatter_01"] = {
			offset = util.vector3(0,0,-2.5),
			scale = 1.682
	},
	["t_he_shellbowl_02"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 0.79
	},
	["t_rga_glasswarebowl_02"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.11
	},
	["t_bre_redglassplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.682
	},
	["t_he_shellbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 0.84
	},
	["t_rga_porcelainbowl_02"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.21
	},
	["t_rga_porcelainbowl_03"] = {
			offset = util.vector3(0,0,4),
			scale = 1.53
	},
	["t_rga_porcelainplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.682
	},
	["t_rga_porcelainplate_02"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.789
	},
	["t_rga_redwareplate_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.408
	},
	["t_rga_woodbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.42
	},
	["t_rga_woodbowl_03"] = {
			offset = util.vector3(0,0,4),
			scale = 1.53
	},
	["t_rga_woodplate_03"] = {
			offset = util.vector3(0,0,5),
			scale = 1.575
	},
	["t_rga_woodplatter_03"] = {
			offset = util.vector3(0,0,2),
			scale = 1.3
	},
	["t_yne_claybowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.58
	},
	["misc_de_bowl_redware_03"] = {
			offset = util.vector3(0,0,5.5),
			scale = 0.89
	},
	["t_yne_claybowl_03"] = {
			offset = util.vector3(-1,-3,0),
			scale = 2.21
	},
	["t_yne_clayplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_yne_stonebowl_02"] = {
			offset = util.vector3(0,0,-2.5),
			scale = 1.53
	},
	["t_yne_stonebowl_03"] = {
			offset = util.vector3(0,0,-4.5),
			scale = 1.79
	},
	["t_yne_stoneplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.085
	},
	["t_bre_redglassbowl_02"] = {
			offset = util.vector3(0,0,1),
			scale = 2.16
	},
	["t_yne_woodenbowl_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.26
	},
	["t_yne_woodenbowl_02"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.58
	},
	["t_bre_redglassbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.26
	},
	["t_yne_woodenplate_02"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.849
	},
	["t_yne_woodenplatter_01"] = {
			offset = util.vector3(0,0,-1),
			scale = 2.004
	},
	["ab_misc_deblueglassbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 2.21
	},
	["ab_misc_deceramicplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.575
	},
	["t_de_stonewareplatter_01"] = {
			offset = util.vector3(0,0,-2.5),
			scale = 1.849
	},
	["t_de_stonewareplate_05"] = {
			offset = util.vector3(0,0,0),
			scale = 1.252
	},
	["t_he_nacreplate_02"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.085
	},
	["t_de_stonewareplate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["misc_de_bowl_01"] = {
			offset = util.vector3(0,0,-2),
			scale = 1.79
	},
	["t_he_nacreplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["ab_misc_decrglassbowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2
	},
	["ab_misc_deredglassplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.682
	},
	["ab_misc_deyelglassbowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2.11
	},
	["t_bre_pewterplatter_01"] = {
			offset = util.vector3(0,0,1),
			scale = 2.326
	},
	["t_bre_pewterplate_04"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.957
	},
	["t_bre_pewterplate_03"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.575
	},
	["t_bre_pewterplate_02"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.575
	},
	["tr_m2_q_22_lw_platter"] = {
			offset = util.vector3(0,0,-1),
			scale = 2.601
	},
	["t_de_stonewarebowl_03"] = {
			offset = util.vector3(0,0,2),
			scale = 1.21
	},
	["t_bre_pewterplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 2.219
	},
	["t_imp_silverwareplate_06"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_imp_silverwareplate_05"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["t_he_nacrebowl_02"] = {
			offset = util.vector3(0,0,2),
			scale = 1.37
	},
	["t_imp_silverwareplate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.682
	},
	["t_imp_silverwareplate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.73
	},
	["t_he_nacrebowl_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.05
	},
	["t_imp_silverwareplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.73
	},
	["tr_m7_nva6_stonewareplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.897
	},
	["tr_m7_nva8_de_stonewareplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.849
	},
	["sky_qre_kwfg3_bowl1"] = {
			offset = util.vector3(0,0,-6.5),
			scale = 2.89
	},
	["sky_qre_kwfg3_bowl2"] = {
			offset = util.vector3(0,0,-7),
			scale = 1.89
	},
	["t_de_redwareplatter_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.957
	},
	["t_de_purpleglassplatter_01"] = {
			offset = util.vector3(0,0,-2),
			scale = 2.004
	},
	["t_de_purpleglassplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.575
	},
	["misc_com_wood_bowl_05"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.95
	},
	["misc_com_wood_bowl_04"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 2
	},
	["misc_com_wood_bowl_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.21
	},
	["misc_com_wood_bowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.26
	},
	["misc_com_metal_plate_03_uni"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.73
	},
	["misc_com_wood_bowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.26
	},
	["misc_com_plate_06"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["misc_com_metal_plate_03"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.682
	},
	["misc_com_plate_04"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["misc_com_plate_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["misc_com_plate_02"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["misc_com_metal_plate_07"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.73
	},
	["misc_com_metal_plate_05"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.813
	},
	["misc_com_metal_plate_04"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.682
	},
	["misc_com_plate_05"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_qy_palmwoodplate_02"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.849
	},
	["t_qy_palmwoodplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_bre_pewterbowl_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.16
	},
	["t_bre_pewterbowl_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.21
	},
	["ab_misc_degreenglassbowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 2
	},
	["ab_misc_deebonyplatter_01"] = {
			offset = util.vector3(0,0,-2),
			scale = 2.326
	},
	["tr_m2_q_22_lw_platter2"] = {
			offset = util.vector3(0,0,-1),
			scale = 2.768
	},
	["ab_misc_deebonyplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["t_we_bonewareplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 0.811
	},
	["t_de_greenglassplatter_01"] = {
			offset = util.vector3(0,0,0),
			scale = 2.004
	},
	["t_de_greenglassplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.789
	},
	["t_we_bonewarebowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 0.84
	},
	["ab_misc_deebonybowl_01"] = {
			offset = util.vector3(0,0,3),
			scale = 1.95
	},
	["t_de_greenglassbowl_02"] = {
			offset = util.vector3(0,0,0),
			scale = 2.42
	},
	["t_de_greenglassbowl_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.11
	},
	["sky_ire_kw_bowl_float"] = {
			offset = util.vector3(0,0,-3.5),
			scale = 1.53
	},
	["ab_misc_decrglassplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.622
	},
	["t_imp_goldplate_06"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["t_imp_goldplate_05"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_imp_goldplate_04"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.622
	},
	["t_bre_silverplate_08"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.515
	},
	["t_bre_silverplate_09"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_silverplatter_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.849
	},
	["t_he_shellplatter_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["misc_com_metal_plate_07_uni2"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.145
	},
	["misc_com_metal_plate_07_uni1"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.193
	},
	["t_bre_woodplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.73
	},
	["t_com_woodplatter_b01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 2.326
	},
	["t_com_woodplate_b01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.467
	},
	["t_imp_colbarrowbowl_01"] = {
			offset = util.vector3(0,0,5),
			scale = 1.74
	},
	["t_he_blueceladonplatter_01"] = {
			offset = util.vector3(0,0,-1),
			scale = 1.849
	},
	["misc_lw_platter"] = {
			offset = util.vector3(0,0,0),
			scale = 1.622
	},
	["t_bre_silverbowl_03"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.74
	},
	["t_he_blueceladonplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.515
	},
	["t_bre_woodbowl_03"] = {
			offset = util.vector3(0,0,0),
			scale = 1.32
	},
	["t_bre_woodbowl_02"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.58
	},
	["t_de_purpleglassbowl_03"] = {
			offset = util.vector3(0,0,1.5),
			scale = 0.71
	},
	["t_he_direnniplate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.515
	},
	["t_he_clayplate_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.515
	},
	["t_he_blueceladonbowl_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.53
	},
	["t_ayl_claybowl_03"] = {
			offset = util.vector3(0,0,2.5),
			scale = 2.05
	},
	["t_ayl_claybowl_02"] = {
			offset = util.vector3(0,0,4.5),
			scale = 2
	},
	["misc_dwrv_bowl00"] = {
			offset = util.vector3(0,0,-1.5),
			scale = 1.84
	},
	["t_com_woodbowl_c02"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.63
	},
	["t_com_woodbowl_c01"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.79
	},
	["t_com_woodbowl_b02"] = {
			offset = util.vector3(0,0,3),
			scale = 1.53
	},
	["t_com_woodbowl_b01"] = {
			offset = util.vector3(0,0,4.5),
			scale = 1.84
	},
	["t_com_woodbowl_a02"] = {
			offset = util.vector3(0,0,3.5),
			scale = 1.58
	},
	["t_com_woodbowl_a01"] = {
			offset = util.vector3(0,0,3),
			scale = 1.79
	},
	["t_arg_woodenplatter_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.73
	},
	["t_bre_stonewareplate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.73
	},
	["t_de_ebony_platter_01"] = {
			offset = util.vector3(0,0,-2),
			scale = 1.957
	},
	["misc_com_plate_07"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["t_qyk_ceramicplate_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.3
	},
	["t_bre_greenglassplate_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.622
	},
	["t_de_stonewareplate_04"] = {
			offset = util.vector3(0,0,0),
			scale = 1.36
	},
	["misc_com_redware_plate"] = {
			offset = util.vector3(0,0,0),
			scale = 1.408
	},
	["t_arg_ceramicplate_01"] = {
			offset = util.vector3(0,0,7.5),
			scale = 1.467
	},
	["t_bre_woodbowl_01"] = {
			offset = util.vector3(0,0,5),
			scale = 1.95
	},
	["t_de_stonewarebowl_02"] = {
			offset = util.vector3(0,0,3),
			scale = 2.05
	},
	["t_imp_carvedwoodplate_01"] = {
			offset = util.vector3(0,0,1),
			scale = 1.73
	},
	["t_de_ebony_plate_01"] = {
			offset = util.vector3(0,0,1.5),
			scale = 1.897
	},
	["t_de_stonewareplate_01"] = {
			offset = util.vector3(0,0,-0.5),
			scale = 1.682
	},
	["t_arg_woodenplate_01"] = {
			offset = util.vector3(0,0,2.5),
			scale = 1.515
	},
	["t_de_purpleglassbowl_01"] = {
			offset = util.vector3(0,0,0),
			scale = 1.63
	},
	["t_nor_silverplate_02"] = {
			offset = util.vector3(0,0,1),
			scale = 1.467
	},
	["misc_de_bowl_white_01"] = {
			offset = util.vector3(0,0,-3),
			scale = 3.95
	},
	["t_bre_greenglassbowl_01"] = {
			offset = util.vector3(0,0,0.5),
			scale = 1.47
	},
	["t_qy_redglassbowl_03"] = {
			offset = util.vector3(0,0,-2.5),
			scale = 1.37
	},
}

--soupFoodwareOffsets = {}
soupFoodwareOffsets = {
    ["t_de_purpleglassbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 1.40),
        scale = 3.36
    },
    ["t_qyc_shellwarebowl_03"] = {
        offset = util.vector3(0.00, -2.80, 1.00),
        scale = 2.05
    },
    ["t_qyc_shellwarebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 1.30),
        scale = 1.67
    },
    ["t_rga_porcelainbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.50),
        scale = 1.40
    },
    ["t_qyc_shellwarebowl_01"] = {
        offset = util.vector3(0.00, 0.50, 1.00),
        scale = 1.33
    },
    ["t_bre_clayplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 2.51
    },
    ["t_nor_finewoodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 12.40),
        scale = 2.19
    },
    ["t_bre_clayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.52
    },
    ["t_nor_decorativebowl_03"] = {
        offset = util.vector3(0.00, 0.00, 6.90),
        scale = 1.81
    },
    ["t_bre_claybowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 1.09
    },
    ["t_bre_claybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 1.38
    },
    ["t_rga_glasswareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.30),
        scale = 1.46
    },
    ["t_rga_glasswarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 6.10),
        scale = 1.45
    },
    ["t_nor_woodenplate_03b"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.77
    },
    ["t_nor_woodenplate_03a"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.82
    },
    ["t_nor_woodenplate_02b"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.60
    },
    ["t_nor_woodenplate_02a"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.44
    },
    ["t_nor_woodenplate_01b"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.90
    },
    ["t_nor_cordedbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 18.20),
        scale = 1.64
    },
    ["t_nor_woodenplate_01a"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.93
    },
    ["t_nor_cordedbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.60),
        scale = 1.79
    },
    ["t_de_bluewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.63
    },
    ["t_he_dirennibowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.41
    },
    ["t_rga_clayplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 1.25
    },
    ["t_rga_clayplate_02"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.63
    },
    ["t_rga_clayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.30),
        scale = 1.67
    },
    ["t_com_coconutplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.03
    },
    ["t_he_clayplatter_02"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 2.27
    },
    ["t_he_clayplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 2.56
    },
    ["t_imp_ebonplate_02"] = {
        offset = util.vector3(0.00, 0.00, -0.20),
        scale = 1.77
    },
    ["t_de_blueglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.40),
        scale = 2.73
    },
    ["t_nor_ceramicbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 7.90),
        scale = 1.80
    },
    ["t_nor_ceramicbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.73
    },
    ["t_com_coconutbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.31
    },
    ["t_nor_ceramicbowl_01"] = {
        offset = util.vector3(0.00, 0.00, -3.70),
        scale = 2.82
    },
    ["t_he_claybowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.20
    },
    ["t_he_claybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 1.24
    },
    ["t_rga_claybowl_03"] = {
        offset = util.vector3(0.00, 0.00, 9.50),
        scale = 1.62
    },
    ["t_rga_claybowl_02"] = {
        offset = util.vector3(0.00, 0.00, 8.10),
        scale = 1.30
    },
    ["t_rga_claybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.50),
        scale = 1.42
    },
    ["t_ned_mw_bowl"] = {
        offset = util.vector3(0.00, 0.00, 1.40),
        scale = 1.86
    },
    ["t_ayl_plate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 1.56
    },
    ["t_he_bluewareplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 2.43
    },
    ["t_imp_colbarrowclayplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 1.92
    },
    ["t_he_bluewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.57
    },
    ["t_imp_colbarrowclayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.86
    },
    ["t_bre_silverplate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.51
    },
    ["t_bre_silverplate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.53
    },
    ["t_bre_silverplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.51
    },
    ["t_arg_woodenbowl_03"] = {
        offset = util.vector3(0.00, 1.00, 6.00),
        scale = 1.37
    },
    ["t_de_stonewareplate_02"] = {
        offset = util.vector3(0.00, 0.00, -0.20),
        scale = 1.58
    },
    ["t_he_clayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.53
    },
    ["t_imp_carvedwoodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.11
    },
    ["misc_dwrv_bowl00_uni"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 2.20
    },
    ["t_he_greenceladonbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.95
    },
    ["t_he_greenceladonplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.63
    },
    ["t_bre_stonewarebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 5.80),
        scale = 2.86
    },
    ["t_bre_silverplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.49
    },
    ["t_bre_stonewarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.56
    },
    ["t_com_woodplate_a01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.62
    },
    ["t_bre_silverbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 3.00),
        scale = 1.60
    },
    ["t_nor_stonewarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 6.00),
        scale = 1.49
    },
    ["t_he_greenceladonplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 2.20
    },
    ["t_com_woodplatter_c01"] = {
        offset = util.vector3(0.00, 0.00, -0.10),
        scale = 3.32
    },
    ["t_imp_ebonplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 1.73
    },
    ["t_bre_silverplatter_02"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.78
    },
    ["t_bre_woodplatter_02"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 2.56
    },
    ["t_ayl_claybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 3.84
    },
    ["t_bre_silverplate_05"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.51
    },
    ["t_bre_silverplate_06"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.51
    },
    ["t_bre_silverplate_07"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.78
    },
    ["t_imp_goldplate_03"] = {
        offset = util.vector3(0.00, 0.00, -0.30),
        scale = 1.59
    },
    ["t_imp_goldplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.50
    },
    ["t_imp_goldplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.76
    },
    ["ab_misc_declaybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 10.50),
        scale = 2.82
    },
    ["t_qy_palmwoodbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 2.70
    },
    ["t_qy_palmwoodbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.66
    },
    ["t_qy_palmwoodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.05
    },
    ["ab_misc_deblueplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.55
    },
    ["t_de_ebony_bowl_02"] = {
        offset = util.vector3(0.00, 0.00, 5.00),
        scale = 1.24
    },
    ["t_de_ebony_bowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.15
    },
    ["t_imp_goldbowl_04"] = {
        offset = util.vector3(0.00, 0.00, 3.30),
        scale = 1.42
    },
    ["t_imp_goldbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 1.39
    },
    ["t_imp_goldbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.56
    },
    ["t_qy_bronzeplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.70
    },
    ["t_imp_goldbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.90),
        scale = 1.14
    },
    ["t_nor_woodenbowl_04b"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 0.87
    },
    ["t_qy_bronzeplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.24
    },
    ["t_nor_woodenbowl_03b"] = {
        offset = util.vector3(0.00, 0.00, -2.00),
        scale = 1.47
    },
    ["t_nor_woodenbowl_03a"] = {
        offset = util.vector3(0.00, 0.00, -2.00),
        scale = 1.45
    },
    ["t_nor_woodenbowl_02b"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.03
    },
    ["t_nor_woodenbowl_02a"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.07
    },
    ["t_nor_woodenbowl_01b"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.59
    },
    ["t_nor_woodenbowl_01a"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.58
    },
    ["ab_misc_deyelglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.33
    },
    ["t_nor_stonewareplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 1.67
    },
    ["t_nor_stonewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.35
    },
    ["t_qy_bronzebowl_03"] = {
        offset = util.vector3(0.00, 0.00, 2.40),
        scale = 2.47
    },
    ["t_qy_bronzebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 2.20),
        scale = 1.52
    },
    ["misc_lw_bowl_chapel"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 3.32
    },
    ["misc_lw_bowl"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 3.27
    },
    ["t_rga_woodplate_02"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 1.80
    },
    ["t_rga_woodplate_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.63
    },
    ["t_qy_redglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.27
    },
    ["t_bre_silverbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.47
    },
    ["t_imp_colclaybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 1.65
    },
    ["t_com_woodplate_c01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.56
    },
    ["t_qy_bronzebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 1.37
    },
    ["t_rga_blackwarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.10
    },
    ["t_com_woodplatter_d01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.85
    },
    ["t_he_shellplatter_02"] = {
        offset = util.vector3(0.30, 0.60, -1.50),
        scale = 1.97
    },
    ["t_nor_ironwoodplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.59
    },
    ["t_yne_stoneplate_02"] = {
        offset = util.vector3(0.30, -0.30, 0.00),
        scale = 1.33
    },
    ["t_he_bluewarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.60),
        scale = 1.39
    },
    ["t_qy_redglassplate_02"] = {
        offset = util.vector3(0.00, 0.00, -0.70),
        scale = 1.82
    },
    ["t_yne_stonebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 0.80),
        scale = 1.33
    },
    ["t_com_coconutbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.58
    },
    ["t_qy_redglassbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.47
    },
    ["t_imp_colbarrowclaybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.59
    },
    ["t_yne_woodenplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.90
    },
    ["ab_misc_deredglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 2.29
    },
    ["t_nor_silverplate_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.53
    },
    ["t_nor_silverplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.20),
        scale = 1.78
    },
    ["t_yne_woodenbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 1.83
    },
    ["t_nor_silverbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 7.00),
        scale = 1.25
    },
    ["t_rga_woodbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 10.50),
        scale = 1.79
    },
    ["t_nor_silverbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 7.60),
        scale = 1.62
    },
    ["t_qyk_ceramicplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.80
    },
    ["t_rga_redwareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.53
    },
    ["t_nor_woodenbowl_04a"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 0.89
    },
    ["t_imp_ebonplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.65
    },
    ["t_de_stonewarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.80),
        scale = 2.74
    },
    ["misc_imp_silverware_plate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.60
    },
    ["t_yne_clayplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.62
    },
    ["t_qyk_ceramicbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.75
    },
    ["t_qyk_ceramicbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.90
    },
    ["t_qyk_ceramicbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 1.84
    },
    ["t_rga_porcelainplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 2.97
    },
    ["t_rga_porcelainplate_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.85
    },
    ["t_imp_silverwareplate_04"] = {
        offset = util.vector3(0.30, -0.30, 0.00),
        scale = 1.67
    },
    ["misc_com_redware_platter"] = {
        offset = util.vector3(0.00, 0.00, -2.00),
        scale = 2.43
    },
    ["t_nor_ironwoodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 1.16
    },
    ["t_bre_greenglassplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 2.66
    },
    ["t_yne_claybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.54
    },
    ["t_qyc_shellwareplate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.59
    },
    ["t_qyc_shellwareplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.59
    },
    ["misc_com_redware_bowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.38
    },
    ["misc_com_redware_bowl"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.17
    },
    ["t_qyc_shellwareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.59
    },
    ["misc_imp_silverware_plate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.62
    },
    ["t_arg_woodenbowl_02"] = {
        offset = util.vector3(0.00, 0.60, 1.50),
        scale = 1.41
    },
    ["t_imp_ebonbowl_02"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 2.47
    },
    ["t_bre_stonewareplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 2.20),
        scale = 2.94
    },
    ["t_arg_woodenbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.28
    },
    ["t_imp_ebonbowl_01"] = {
        offset = util.vector3(0.00, 0.00, -1.20),
        scale = 1.82
    },
    ["t_nor_decorativebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.70
    },
    ["t_arg_woodenplatter_02"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 2.91
    },
    ["t_bre_woodbowl_04"] = {
        offset = util.vector3(0.00, 0.00, 4.10),
        scale = 2.59
    },
    ["t_arg_ceramicplate_02"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.44
    },
    ["misc_de_bowl_redware_02"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 1.98
    },
    ["misc_imp_silverware_plate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.79
    },
    ["t_bre_woodplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 4.60),
        scale = 3.41
    },
    ["t_com_coconutbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 3.00),
        scale = 1.52
    },
    ["t_com_woodbowl_c03"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.37
    },
    ["t_imp_colclayplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.91
    },
    ["t_imp_colclayplate_02"] = {
        offset = util.vector3(0.60, -0.30, 2.50),
        scale = 1.56
    },
    ["t_imp_colclayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.77
    },
    ["t_qy_redglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.30),
        scale = 1.27
    },
    ["t_imp_colbarrowplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 7.50),
        scale = 2.76
    },
    ["misc_de_bowl_glass_yellow_01"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 2.83
    },
    ["t_rga_redwarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 7.00),
        scale = 1.87
    },
    ["t_rga_clayplate_03"] = {
        offset = util.vector3(0.00, 0.00, 2.30),
        scale = 1.49
    },
    ["misc_de_bowl_glass_peach_01"] = {
        offset = util.vector3(0.00, 0.00, 13.50),
        scale = 3.19
    },
    ["t_he_shellplatter_03"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.79
    },
    ["t_nor_decorativebowl_01"] = {
        offset = util.vector3(0.00, 0.00, -3.20),
        scale = 3.11
    },
    ["misc_de_bowl_bugdesign_01"] = {
        offset = util.vector3(0.00, 0.00, 10.50),
        scale = 2.92
    },
    ["misc_de_bowl_redware_01"] = {
        offset = util.vector3(0.00, 0.00, 5.00),
        scale = 2.56
    },
    ["t_bre_redglassplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -2.50),
        scale = 2.34
    },
    ["t_he_shellbowl_02"] = {
        offset = util.vector3(1.00, -0.30, 0.50),
        scale = 1.03
    },
    ["t_rga_glasswarebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 5.80),
        scale = 1.26
    },
    ["t_bre_redglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.10),
        scale = 1.75
    },
    ["t_he_shellbowl_01"] = {
        offset = util.vector3(1.00, -0.50, 0.50),
        scale = 1.07
    },
    ["t_rga_porcelainbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 7.50),
        scale = 1.46
    },
    ["t_rga_porcelainbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 9.00),
        scale = 1.72
    },
    ["t_rga_porcelainplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.87
    },
    ["t_rga_porcelainplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.81
    },
    ["t_rga_redwareplate_02"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.53
    },
    ["t_rga_woodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.10),
        scale = 1.96
    },
    ["t_rga_woodbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 10.50),
        scale = 1.50
    },
    ["t_rga_woodplate_03"] = {
        offset = util.vector3(0.00, 0.00, 5.30),
        scale = 1.67
    },
    ["t_rga_woodplatter_03"] = {
        offset = util.vector3(0.00, -0.30, 2.00),
        scale = 1.47
    },
    ["t_yne_claybowl_02"] = {
        offset = util.vector3(0.00, 0.00, 3.10),
        scale = 1.79
    },
    ["misc_de_bowl_redware_03"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 0.89
    },
    ["t_yne_claybowl_03"] = {
        offset = util.vector3(0.00, 0.50, 4.40),
        scale = 2.37
    },
    ["t_yne_clayplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.41
    },
    ["t_yne_stonebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 0.80),
        scale = 1.63
    },
    ["t_yne_stonebowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.96
    },
    ["t_yne_stoneplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.08
    },
    ["t_bre_redglassbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 2.73
    },
    ["t_yne_woodenbowl_01"] = {
        offset = util.vector3(0.00, -0.30, 1.80),
        scale = 1.42
    },
    ["t_yne_woodenbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 5.20),
        scale = 1.75
    },
    ["t_bre_redglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 1.42
    },
    ["t_yne_woodenplate_02"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 2.02
    },
    ["t_yne_woodenplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 2.10
    },
    ["ab_misc_deblueglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.50),
        scale = 2.81
    },
    ["ab_misc_deceramicplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.57
    },
    ["t_de_stonewareplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -2.50),
        scale = 1.85
    },
    ["t_de_stonewareplate_05"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.34
    },
    ["t_he_nacreplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.13
    },
    ["t_de_stonewareplate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.47
    },
    ["misc_de_bowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.00),
        scale = 2.17
    },
    ["t_he_nacreplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.53
    },
    ["ab_misc_decrglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 5.60),
        scale = 2.25
    },
    ["ab_misc_deredglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.49
    },
    ["ab_misc_deyelglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 7.10),
        scale = 2.79
    },
    ["t_bre_pewterplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 2.38
    },
    ["t_bre_pewterplate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 2.13
    },
    ["t_bre_pewterplate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.57
    },
    ["t_bre_pewterplate_02"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.59
    },
    ["tr_m2_q_22_lw_platter"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 2.60
    },
    ["t_de_stonewarebowl_03"] = {
        offset = util.vector3(0.00, 0.00, 4.80),
        scale = 1.34
    },
    ["t_bre_pewterplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 2.39
    },
    ["t_imp_silverwareplate_06"] = {
        offset = util.vector3(0.00, -0.30, 0.00),
        scale = 1.62
    },
    ["t_imp_silverwareplate_05"] = {
        offset = util.vector3(0.30, -0.30, 0.00),
        scale = 1.62
    },
    ["t_he_nacrebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 1.51
    },
    ["t_imp_silverwareplate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.71
    },
    ["t_imp_silverwareplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.70
    },
    ["t_he_nacrebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 1.30
    },
    ["t_imp_silverwareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.68
    },
    ["tr_m7_nva6_stonewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.20),
        scale = 1.88
    },
    ["tr_m7_nva8_de_stonewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.20),
        scale = 1.88
    },
    ["sky_qre_kwfg3_bowl1"] = {
        offset = util.vector3(0.00, 0.00, -3.40),
        scale = 3.08
    },
    ["sky_qre_kwfg3_bowl2"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.71
    },
    ["t_de_redwareplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 2.50),
        scale = 2.60
    },
    ["t_de_purpleglassplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -1.70),
        scale = 2.96
    },
    ["t_de_purpleglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.57
    },
    ["misc_com_wood_bowl_05"] = {
        offset = util.vector3(0.00, 0.00, 3.00),
        scale = 2.33
    },
    ["misc_com_wood_bowl_04"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 2.38
    },
    ["misc_com_wood_bowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.34
    },
    ["misc_com_wood_bowl_02"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.43
    },
    ["misc_com_metal_plate_03_uni"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.86
    },
    ["misc_com_wood_bowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.43
    },
    ["misc_com_plate_06"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.47
    },
    ["misc_com_metal_plate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.86
    },
    ["misc_com_plate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.36
    },
    ["misc_com_plate_03"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.41
    },
    ["misc_com_plate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.36
    },
    ["misc_com_metal_plate_07"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.82
    },
    ["misc_com_metal_plate_05"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.90
    },
    ["misc_com_metal_plate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.81
    },
    ["misc_com_plate_05"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.57
    },
    ["t_qy_palmwoodplate_02"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.92
    },
    ["t_qy_palmwoodplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.43
    },
    ["t_bre_pewterbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 5.00),
        scale = 1.40
    },
    ["t_bre_pewterbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 1.41
    },
    ["ab_misc_degreenglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 7.00),
        scale = 2.45
    },
    ["ab_misc_deebonyplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -2.00),
        scale = 2.54
    },
    ["tr_m2_q_22_lw_platter2"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 2.80
    },
    ["ab_misc_deebonyplate_01"] = {
        offset = util.vector3(0.60, 0.60, 0.00),
        scale = 1.52
    },
    ["t_we_bonewareplate_01"] = {
        offset = util.vector3(-1.20, -1.20, 0.20),
        scale = 0.88
    },
    ["t_de_greenglassplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 2.05
    },
    ["t_de_greenglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.68
    },
    ["t_we_bonewarebowl_01"] = {
        offset = util.vector3(0.00, 0.00, 1.30),
        scale = 0.94
    },
    ["ab_misc_deebonybowl_01"] = {
        offset = util.vector3(0.00, 0.00, 7.90),
        scale = 2.30
    },
    ["t_de_greenglassbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 4.50),
        scale = 3.18
    },
    ["t_de_greenglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.00),
        scale = 1.20
    },
    ["sky_ire_kw_bowl_float"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 1.45
    },
    ["ab_misc_decrglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.55
    },
    ["t_imp_goldplate_06"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.50
    },
    ["t_imp_goldplate_05"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.44
    },
    ["t_imp_goldplate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.20),
        scale = 1.46
    },
    ["t_bre_silverplate_08"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.70
    },
    ["t_bre_silverplate_09"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.51
    },
    ["t_bre_silverplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 2.72
    },
    ["t_he_shellplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.68
    },
    ["misc_com_metal_plate_07_uni2"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.88
    },
    ["misc_com_metal_plate_07_uni1"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.88
    },
    ["t_bre_woodplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.80),
        scale = 1.75
    },
    ["t_com_woodplatter_b01"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 2.94
    },
    ["t_com_woodplate_b01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.61
    },
    ["t_imp_colbarrowbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 8.00),
        scale = 2.02
    },
    ["t_he_blueceladonplatter_01"] = {
        offset = util.vector3(0.00, 0.00, -1.00),
        scale = 1.95
    },
    ["misc_lw_platter"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 2.86
    },
    ["t_bre_silverbowl_03"] = {
        offset = util.vector3(0.00, 0.00, -0.50),
        scale = 1.74
    },
    ["t_he_blueceladonplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.30),
        scale = 1.67
    },
    ["t_bre_woodbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.49
    },
    ["t_bre_woodbowl_02"] = {
        offset = util.vector3(0.00, 0.00, 6.00),
        scale = 1.81
    },
    ["t_he_direnniplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.80),
        scale = 1.56
    },
    ["t_he_clayplate_02"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.51
    },
    ["t_he_blueceladonbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 2.00
    },
    ["t_ayl_claybowl_02"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 3.11
    },
    ["misc_dwrv_bowl00"] = {
        offset = util.vector3(0.00, 0.00, 2.00),
        scale = 2.01
    },
    ["t_com_woodbowl_c02"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 1.72
    },
    ["t_com_woodbowl_b02"] = {
        offset = util.vector3(0.00, 0.00, 6.00),
        scale = 1.89
    },
    ["t_com_woodbowl_b01"] = {
        offset = util.vector3(0.00, 0.00, 9.50),
        scale = 2.24
    },
    ["t_com_woodbowl_a02"] = {
        offset = util.vector3(0.00, 0.00, 6.50),
        scale = 1.77
    },
    ["t_com_woodbowl_a01"] = {
        offset = util.vector3(0.00, 0.00, 9.00),
        scale = 2.21
    },
    ["t_arg_woodenplatter_01"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.82
    },
    ["t_bre_stonewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, 2.30),
        scale = 1.72
    },
    ["t_de_ebony_platter_01"] = {
        offset = util.vector3(0.00, 0.00, -2.00),
        scale = 2.46
    },
    ["misc_com_plate_07"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.36
    },
    ["t_qyk_ceramicplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.46
    },
    ["t_bre_greenglassplate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.71
    },
    ["t_de_stonewareplate_04"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.39
    },
    ["misc_com_redware_plate"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.53
    },
    ["t_arg_ceramicplate_01"] = {
        offset = util.vector3(0.00, 0.00, 8.00),
        scale = 2.27
    },
    ["t_bre_woodbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 9.40),
        scale = 2.23
    },
    ["t_de_stonewarebowl_02"] = {
        offset = util.vector3(0.00, 0.00, 8.00),
        scale = 2.66
    },
    ["t_imp_carvedwoodplate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.49
    },
    ["t_de_ebony_plate_01"] = {
        offset = util.vector3(0.00, 0.00, 1.80),
        scale = 1.97
    },
    ["t_de_stonewareplate_01"] = {
        offset = util.vector3(0.00, 0.00, -0.20),
        scale = 1.73
    },
    ["t_arg_woodenplate_01"] = {
        offset = util.vector3(0.00, 1.20, 2.50),
        scale = 1.60
    },
    ["t_nor_silverplate_02"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.49
    },
    ["misc_de_bowl_white_01"] = {
        offset = util.vector3(0.00, 0.00, 3.50),
        scale = 4.08
    },
    ["t_bre_greenglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.73
    },
    ["t_qy_redglassbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.80),
        scale = 2.00
    },
    ["misc_imp_silverware_bowl"] = {
        offset = util.vector3(0.00, 0.00, 1.00),
        scale = 1.02
    },
    ["misc_beluelle_silver_bowl"] = {
        offset = util.vector3(0.00, 0.00, 1.50),
        scale = 1.0
    },
    ["misc_com_plate_08"] = {
        offset = util.vector3(0.00, 0.00, 0.50),
        scale = 1.53
    },
    ["misc_com_plate_01"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.35
    },
    ["misc_com_plate_06_tgrc"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.35
    },
    ["misc_com_plate_02_tgrc"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.35
    },
    ["t_de_purpleglassbowl_03"] = {
        offset = util.vector3(0.00, 0.00, 1.80),
        scale = 0.80
    },
    ["misc_de_bowl_orange_green_01"] = {
        offset = util.vector3(0.00, 0.00, 4.00),
        scale = 1.92
    },
    ["t_ayl_claybowl_03"] = {
        offset = util.vector3(0.00, 0.00, 5.50),
        scale = 2.92
    },
    ["t_com_coconutplate_02"] = {
        offset = util.vector3(0.00, 0.00, 0.00),
        scale = 1.38
    },
    ["t_de_purpleglassbowl_01"] = {
        offset = util.vector3(0.00, 0.00, 3.70),
        scale = 1.78
    },
    ["t_com_woodbowl_c01"] = {
        offset = util.vector3(0.00, 0.00, 8.50),
        scale = 2.22
    },
}
--print("soupFoodwareOffsets = {")
--for a,b in pairs(soupFoodwareOffsets) do
--	print("\t[\""..a.."\"] = {")
--	local newOffset = b.offset
--	print('\t\toffset = util.vector3('..newOffset.x..','..newOffset.y..','..newOffset.z..'),')
--	local foodwareType = getFoodwareType(a)
--	local newScale = b.scale
--	if foodwareType == "plate" then
--		--print(a.." is plate")
--		newScale = newScale/0.838
--	else
--		--print(a.." is bowl")
--	end
--	print('\t\tscale = '..math.floor(newScale*1000)/1000)
--	print("\t},")
--end
--print("}")