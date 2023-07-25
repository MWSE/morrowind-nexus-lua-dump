local this = {}

local logging = require("JosephMcKean.furnitureCatalogue.logging")
local log = logging.createLogger("furnConfig")

---@class furnitureCatalogue.furniture
---@field id string The id of the furniture
---@field newId string The new id of the furniture copy
---@field name string The name of the furniture
---@field category string
---@field cost number
---@field scale number?
---@field alwaysInStock boolean?
---@field notForSale boolean?
---@field base string?
---@field deprecated boolean?
---@field campfireId string

---@type table<string,furnitureCatalogue.furniture>
this.furniture = {
	-- Oldwood pack
	["001"] = { id = "active_de_p_bed_04", newId = "jsmk_fc_active_de_p_bed_04", name = "Single Bed, Olive", category = "Beds", cost = 60 }, -- MW
	["002"] = { id = "dr_asrt_p_f_bookcase_01", newId = "jsmk_fc_dr_asrt_p_f_bookcase_01", name = "Bookcase, Cheap", category = "Shelves", cost = 30 }, -- DR
	["003"] = { id = "de_p_closet_02", newId = "jsmk_fc_de_p_closet_02", name = "Closet, Cheap", category = "Containers", cost = 140 }, -- MW
	["004"] = { id = "furn_de_p_bench_03", newId = "jsmk_fc_furn_de_p_bench_03", name = "Bench, Cheap", category = "Seats", cost = 15 }, -- MW
	["005"] = { id = "furn_de_p_bookshelf_01", newId = "jsmk_fc_furn_de_p_bookshelf_01", name = "Bookshelf, Cheap", category = "Shelves", cost = 60, alwaysInStock = true }, -- MW
	["006"] = { id = "furn_de_p_chair_01", newId = "jsmk_fc_furn_de_p_chair_01", name = "Chair, Cheap", category = "Seats", cost = 15 }, -- MW
	["007"] = { id = "furn_de_p_chair_02", newId = "jsmk_fc_furn_de_p_chair_02", name = "Chair, Cheap", category = "Seats", cost = 15 }, -- MW
	["008"] = { id = "furn_de_p_shelf_02", newId = "jsmk_fc_furn_de_p_shelf_02", name = "Shelf, Cheap", category = "Shelves", cost = 10 }, -- MW
	["009"] = { id = "furn_de_p_stool_01", newId = "jsmk_fc_furn_de_p_stool_01", name = "Stool, Cheap", category = "Seats", cost = 10 }, -- MW
	["010"] = { id = "furn_de_p_stool_02", newId = "jsmk_fc_furn_de_p_stool_02", name = "Stool, Cheap", category = "Seats", cost = 10 }, -- MW
	["011"] = { id = "furn_de_p_table_01", newId = "jsmk_fc_furn_de_p_table_01", name = "Round Table, Cheap", category = "Tables", cost = 75 }, -- MW
	["012"] = { id = "furn_de_p_table_02", newId = "jsmk_fc_furn_de_p_table_02", name = "Small Telvanni Table, Cheap", category = "Tables", cost = 50 }, -- MW
	["013"] = { id = "furn_de_p_table_04", newId = "jsmk_fc_furn_de_p_table_04", name = "Large Table, Cheap", category = "Tables", cost = 100 }, -- MW
	["014"] = { id = "furn_de_p_table_05", newId = "jsmk_fc_furn_de_p_table_05", name = "End Table, Cheap", category = "Tables", cost = 40 }, -- MW
	["015"] = { id = "furn_de_p_table_06", newId = "jsmk_fc_furn_de_p_table_06", name = "Round Table, Stump", category = "Tables", cost = 150 }, -- MW
	["016"] = { id = "furn_de_rm_winerack", newId = "jsmk_fc_furn_de_rm_winerack", name = "Winerack, Cheap", category = "Shelves", cost = 150 }, -- MW
	["018"] = { id = "mwg_vivec_market_05", newId = "jsmk_fc_mwg_vivec_market_05", name = "Market Stand", category = "Shelves", cost = 30 }, -- MwG
	["019"] = { id = "de_p_desk_01", newId = "jsmk_fc_de_p_desk_01", name = "Desk, Cheap", category = "Containers", cost = 140 }, -- MW
	["020"] = { id = "de_drawers_02", newId = "jsmk_fc_de_drawers_02", name = "Chest of Drawers, Cheap", category = "Containers", cost = 140 }, -- MW
	["021"] = { id = "ab_o_deplntable01", newId = "jsmk_fc_ab_o_deplntable01", name = "End Table, Cheap", category = "Containers", cost = 130, deprecated = true }, -- OAAB
	["022"] = { id = "ab_furn_deplnscrollrack1", newId = "jsmk_fc_abfurn_deplnscrollrack1", name = "Scroll Rack, Cheap", category = "Shelves", cost = 175 }, -- OAAB
	["023"] = { id = "ab_furn_deplnscrollrack2", newId = "jsmk_fc_abfurn_deplnscrollrack2", name = "Scroll Rack, Cheap", category = "Shelves", cost = 175 }, -- OAAB

	-- Metal Iron Rusty pack
	["025"] = { id = "light_com_lamp_01", newId = "jsmk_fc_light_com_lamp_01", name = "Lamp, Iron", category = "Lights", cost = 20 }, -- MW
	["026"] = { id = "light_com_lamp_02", newId = "jsmk_fc_light_com_lamp_02", name = "Lamp, White", category = "Lights", cost = 20 }, -- MW
	["030"] = { id = "ab_furn_dnghook", newId = "jsmk_fc_ab_furn_dnghook", name = "Hook, Iron", category = "Other", cost = 10, scale = 0.5 }, -- OAAB

	-- Khaki Wood pack
	["031"] = { id = "active_com_bed_03", newId = "jsmk_fc_active_com_bed_03", name = "Single Bed, Khaki Red", category = "Beds", cost = 60 }, -- MW
	["032"] = { id = "furn_com_p_bench_01", newId = "jsmk_fc_furn_com_p_bench_01", name = "Bench, Khaki", category = "Seats", cost = 15 }, -- MW
	["033"] = { id = "active_com_bunk_02", newId = "jsmk_fc_active_com_bunk_02", name = "Bunk Bed, Grey", category = "Beds", cost = 120 }, -- MW
	["034"] = { id = "furn_com_p_shelf_03", newId = "jsmk_fc_furn_com_p_shelf_03", name = "Shelf, Khaki", category = "Shelves", cost = 10 }, -- MW
	["035"] = { id = "furn_com_p_table_01", newId = "jsmk_fc_furn_com_p_table_01", name = "Table, Khaki", category = "Tables", cost = 120 }, -- MW
	["036"] = { id = "light_com_chandelier_01", newId = "jsmk_fc_light_com_chandelier_01", name = "Chandelier, Khaki", category = "Lights", cost = 60 }, -- MW
	["037"] = { id = "t_imp_furnp_rack_02", newId = "jsmk_fc_t_imp_furnp_rack_02", name = "Rack, Khaki", category = "Shelves", cost = 120 }, -- PC
	["038"] = { id = "t_imp_furnp_wallscreen_01", newId = "jsmk_fc_timpfurnp_wallscreen_01", name = "Wallscreen, Khaki", category = "Other", cost = 60 }, -- PC
	["039"] = { id = "t_cyrimp_furnp_st1empty", newId = "jsmk_fc_t_cyrimp_furnp_st1empty", name = "Side Table, Khaki", category = "Containers", cost = 60 }, -- PC
	["040"] = { id = "t_com_furn_ladder_01", newId = "jsmk_fc_t_com_furn_ladder_01", name = "Ladder, Khaki", category = "Structures", cost = 60 }, -- TR

	-- Canvas Wrap pack
	["041"] = { id = "com_sack_01", newId = "jsmk_fc_com_sack_01", name = "Sack", category = "Containers", cost = 6 }, -- MW
	["042"] = { id = "com_sack_03", newId = "jsmk_fc_com_sack_03", name = "Sack, Vertical", category = "Containers", cost = 6 }, -- MW
	["043"] = { id = "furn_com_pm_chair_02", newId = "jsmk_fc_furn_com_pm_chair_02", name = "Chair, Foldable", category = "Seats", cost = 15 }, -- MW
	["044"] = { id = "furn_de_cushion_round_03", newId = "jsmk_fc_furnde_cushion_round_03", name = "Cushion, Round", category = "Cushions", cost = 30 }, -- MW
	["045"] = { id = "furn_de_practice_mat", newId = "jsmk_fc_furn_de_practice_mat", name = "Practice Mat", category = "Rugs", cost = 30 }, -- MW

	-- Skyrim Wood Furniture 01 pack
	["046"] = { id = "t_nor_furnp_bench_01", newId = "jsmk_fc_t_nor_furnp_bench_01", name = "Bench, Nordic", category = "Seats", cost = 30 }, -- SKY
	["047"] = { id = "t_nor_furnp_bookshelf_01", newId = "jsmk_fc_tnor_furnp_bookshelf_01", name = "Bookshelf, Nordic", category = "Shelves", cost = 180 }, -- SKY
	["048"] = { id = "t_nor_furnp_chair_01", newId = "jsmk_fc_t_nor_furnp_chair_01", name = "Chair, Nordic Cheap Armed", category = "Seats", cost = 60 }, -- SKY
	["049"] = { id = "t_nor_furnp_bar_01", newId = "jsmk_fc_t_nor_furnp_bar_01", name = "Counter, Nordic", category = "Shelves", cost = 1505 }, -- SKY
	["050"] = { id = "t_nor_furnp_shelf_01", newId = "jsmk_fc_t_nor_furnp_shelf_01", name = "Bookshelf, Nordic", category = "Shelves", cost = 450 }, -- SKY
	["051"] = { id = "t_nor_furnp_shelf_04", newId = "jsmk_fc_t_nor_furnp_shelf_04", name = "Bookshelf, Nordic", category = "Shelves", cost = 75 }, -- SKY
	["052"] = { id = "t_nor_furnp_stool_01", newId = "jsmk_fc_t_nor_furnp_stool_01", name = "Stool, Nordic", category = "Seats", cost = 30 }, -- SKY
	["053"] = { id = "t_nor_furnp_table_02", newId = "jsmk_fc_t_nor_furnp_table_02", name = "Table, Nordic Round Cheap", category = "Tables", cost = 150 }, -- SKY
	["054"] = { id = "t_skynor_furnp_cb1empty", newId = "jsmk_fc_t_skynor_furnp_cb1empty", name = "Cupboard, Nordic", category = "Containers", cost = 100 }, -- SKY
	["055"] = { id = "t_skynor_furnp_cl1empty", newId = "jsmk_fc_t_skynor_furnp_cl1empty", name = "Closet, Nordic", category = "Containers", cost = 400 }, -- SKY
	["056"] = { id = "t_skynor_furnp_dw1empty", newId = "jsmk_fc_t_skynor_furnp_dw1empty", name = "Drawers, Nordic", category = "Containers", cost = 200 }, -- SKY
	["057"] = { id = "t_skynor_furnp_ds1empty", newId = "jsmk_fc_t_skynor_furnp_ds1empty", name = "Desk, Nordic", category = "Containers", cost = 100 }, -- SKY

	-- Wood Brown pack
	["058"] = { id = "furn_com_rm_shelf_02", newId = "jsmk_fc_furn_com_rm_shelf_02", name = "Shelf", category = "Shelves", cost = 20 }, -- MW
	["059"] = { id = "com_chest_02_empty", newId = "jsmk_fc_com_chest_02_empty", name = "Chest, Cheap", category = "Containers", cost = 35 }, -- MW
	["060"] = { id = "com_chest_11_empty", newId = "jsmk_fc_com_chest_11_empty", name = "Chest, Brown Wood", category = "Containers", cost = 25 }, -- MW
	["061"] = { id = "crate_01_empty", newId = "jsmk_fc_crate_01_empty", name = "Crate", category = "Crates", cost = 6 }, -- MW
	["062"] = { id = "furn_com_rm_bookshelf_02", newId = "jsmk_fc_furncom_rm_bookshelf_02", name = "Bookshelf", category = "Shelves", cost = 500 }, -- MW
	["063"] = { id = "furn_com_rm_table_03", newId = "jsmk_fc_furn_com_rm_table_03", name = "Table, Round", category = "Tables", cost = 150 }, -- MW
	["064"] = { id = "furn_com_rm_table_04", newId = "jsmk_fc_furn_com_rm_table_04", name = "Table", category = "Tables", cost = 150 }, -- MW
	["065"] = { id = "furn_com_rm_table_05", newId = "jsmk_fc_furn_com_rm_table_05", name = "Small Table", category = "Tables", cost = 50, alwaysInStock = true }, -- MW
	["066"] = { id = "barrel_01_empty", newId = "jsmk_fc_barrel_01_empty", name = "Barrel", category = "Containers", cost = 30 }, -- MW
	["067"] = { id = "barrel_02", newId = "jsmk_fc_barrel_02", name = "Barrel", category = "Containers", cost = 40 }, -- MW
	["068"] = { id = "ab_furn_combucket02water", newId = "jsmk_fc_abfurn_combucket02water", name = "Bucket of Water", category = "Water", cost = 30 }, -- OAAB
	["069"] = { id = "ab_furn_weprackwall", newId = "jsmk_fc_ab_furn_weprackwall", name = "Weapon Rack, Wall", category = "Shelves", cost = 40 }, -- OAAB
	["070"] = { id = "ab_o_barrel01group", newId = "jsmk_fc_ab_o_barrel01group", name = "Stack of Barrels", category = "Containers", cost = 1500 }, -- OAAB
	["071"] = { id = "ab_o_comcrate01", newId = "jsmk_fc_ab_o_comcrate01", name = "Crate", category = "Crates", cost = 3 }, -- OAAB
	["072"] = { id = "t_imp_furnm_bookshelf_04", newId = "jsmk_fc_timp_furnm_bookshelf_04", name = "Bookshelf", category = "Shelves", cost = 250 }, -- PC

	-- Wood Wethered pack
	["073"] = { id = "furn_de_ex_bench_01", newId = "jsmk_fc_furn_de_ex_bench_01", name = "Bench, Wethered Wood", category = "Seats", cost = 25 }, -- MW
	["074"] = { id = "furn_de_ex_stool_02", newId = "jsmk_fc_furn_de_ex_stool_02", name = "Stool, Wethered Wood", category = "Seats", cost = 15 }, -- MW
	["075"] = { id = "furn_de_ex_table_02", newId = "jsmk_fc_furn_de_ex_table_02", name = "Table, Wethered Wood Small", category = "Tables", cost = 355 }, -- MW  
	["076"] = { id = "furn_de_ex_table_03", newId = "jsmk_fc_furn_de_ex_table_03", name = "Table, Wethered Wood Large", category = "Tables", cost = 50 }, -- MW
	["077"] = { id = "furn_de_lightpost_01", newId = "jsmk_fc_furn_de_lightpost_01", name = "Lightpost", category = "Other", cost = 25 }, -- MW
	["078"] = { id = "light_torch_01", newId = "jsmk_fc_light_torch_01", name = "Torch, Large", category = "Lights", cost = 12 }, -- MW
	["079"] = { id = "de_p_chest_02_empty", newId = "jsmk_fc_de_p_chest_02_empty", name = "Chest, Wethered Wood", category = "Containers", cost = 35 }, -- MW
	["080"] = { id = "ab_furn_deexdisplay01", newId = "jsmk_fc_ab_furn_deexdisplay01", name = "Display Shelf, Wethered Wood", category = "Shelves", cost = 50 }, -- OAAB
	["081"] = { id = "ab_furn_deexdisplay02", newId = "jsmk_fc_ab_furn_deexdisplay02", name = "Display Shelf, Wethered Wood", category = "Shelves", cost = 75 }, -- OAAB
	["082"] = { id = "ab_o_boxflour", newId = "jsmk_fc_ab_o_boxflour", name = "Box of Flour", category = "Containers", cost = 100 }, -- OAAB

	-- Rug pack
	["083"] = { id = "furn_de_rug_01", newId = "jsmk_fc_furn_de_rug_01", name = "Rug, Small Rectangular Blue", category = "Rugs", cost = 60 }, -- MW
	["084"] = { id = "furn_de_rug_02", newId = "jsmk_fc_furn_de_rug_02", name = "Rug, Small Rectangular Red", category = "Rugs", cost = 60 }, -- MW     
	["085"] = { id = "furn_de_rug_big_01", newId = "jsmk_fc_furn_de_rug_big_01", name = "Rug, Large Oval Purple", category = "Rugs", cost = 120 }, -- MW       
	["086"] = { id = "furn_de_rug_big_02", newId = "jsmk_fc_furn_de_rug_big_02", name = "Rug, Large Oval Red", category = "Rugs", cost = 120, scale = 0.8 }, -- MW
	["087"] = { id = "furn_de_rug_big_03", newId = "jsmk_fc_furn_de_rug_big_03", name = "Rug, Large Oval Green", category = "Rugs", cost = 120 }, -- MW       
	["088"] = { id = "furn_de_rug_big_05", newId = "jsmk_fc_furn_de_rug_big_05", name = "Rug, Large Rectangular Red", category = "Rugs", cost = 120 }, -- MW
	["089"] = { id = "furn_de_rug_big_06", newId = "jsmk_fc_furn_de_rug_big_06", name = "Rug, Large Rectangular Green", category = "Rugs", cost = 120, scale = 0.7 }, -- MW
	["090"] = { id = "furn_de_rug_big_07", newId = "jsmk_fc_furn_de_rug_big_07", name = "Rug, Large Rectangular Blue", category = "Rugs", cost = 120 }, -- MW
	["091"] = { id = "furn_de_rug_big_08", newId = "jsmk_fc_furn_de_rug_big_08", name = "Rug, Large Oval Blue", category = "Rugs", cost = 120 }, -- MW       
	["092"] = { id = "furn_de_rug_big_09", newId = "jsmk_fc_furn_de_rug_big_09", name = "Rug, Large Rectangular Blue", category = "Rugs", cost = 120 }, -- MW
	["093"] = { id = "furn_rug_whitewolf", newId = "jsmk_fc_furn_rug_whitewolf", name = "Rug, Faux White Wolf", category = "Rugs", cost = 120, scale = 1.2 }, -- MW
	["094"] = { id = "ab_furn_deplnrug00", newId = "jsmk_fc_ab_furn_deplnrug00", name = "Rug, Ruined Red", category = "Rugs", cost = 120 }, -- OAAB
	["095"] = { id = "ab_furn_deplnrug02", newId = "jsmk_fc_ab_furn_deplnrug02", name = "Rug, Ruined Green", category = "Rugs", cost = 120 }, -- OAAB
	["096"] = { id = "ab_furn_deplnrug03", newId = "jsmk_fc_ab_furn_deplnrug03", name = "Rug, Ruined Brown", category = "Rugs", cost = 120 }, -- OAAB
	["097"] = { id = "ab_furn_deplnrug06", newId = "jsmk_fc_ab_furn_deplnrug06", name = "Rug, Small Round", category = "Rugs", cost = 120, scale = 1.22 }, -- OAAB
	["098"] = { id = "ab_furn_deplnrug07", newId = "jsmk_fc_ab_furn_deplnrug07", name = "Rug, Ruined Blue", category = "Rugs", cost = 120 }, -- OAAB

	-- Tapestry pack
	["099"] = { id = "furn_de_tapestry_02", newId = "jsmk_fc_furn_de_tapestry_02", name = "Tapestry, Tribunal", category = "Tapestries", cost = 120 }, -- MW
	["100"] = { id = "furn_de_tapestry_07", newId = "jsmk_fc_furn_de_tapestry_07", name = "Tapestry, Red", category = "Tapestries", cost = 120 }, -- MW
	["101"] = { id = "furn_de_tapestry_09", newId = "jsmk_fc_furn_de_tapestry_09", name = "Tapestry, Blue", category = "Tapestries", cost = 120 }, -- MW
	["102"] = { id = "furn_de_tapestry_10", newId = "jsmk_fc_furn_de_tapestry_10", name = "Tapestry, Green", category = "Tapestries", cost = 120 }, -- MW
	["103"] = { id = "furn_de_tapestry_11", newId = "jsmk_fc_furn_de_tapestry_11", name = "Tapestry, Purple", category = "Tapestries", cost = 120 }, -- MW
	["104"] = { id = "furn_com_tapestry_01", newId = "jsmk_fc_furn_com_tapestry_01", name = "Tapestry, Forest", category = "Tapestries", cost = 120 }, -- MW
	["105"] = { id = "furn_com_tapestry_02", newId = "jsmk_fc_furn_com_tapestry_02", name = "Tapestry, Blossom", category = "Tapestries", cost = 120 }, -- MW
	["106"] = { id = "furn_com_tapestry_03", newId = "jsmk_fc_furn_com_tapestry_03", name = "Tapestry, Compton", category = "Tapestries", cost = 120 }, -- MW
	["107"] = { id = "furn_com_tapestry_04", newId = "jsmk_fc_furn_com_tapestry_04", name = "Tapestry, Imperial", category = "Tapestries", cost = 120 }, -- MW
	["108"] = { id = "mwg_vivec_market_08", newId = "jsmk_fc_mwg_vivec_market_08", name = "Banners", category = "Tapestries", cost = 120 }, -- MwG
	["109"] = { id = "ab_furn_detapestrymini02", newId = "jsmk_fc_abfurn_detapestrymini02", name = "Tapestry Mini, Tribunal", category = "Tapestries", cost = 120 }, -- OAAB
	["110"] = { id = "ab_furn_detapestrymini06", newId = "jsmk_fc_abfurn_detapestrymini06", name = "Tapestry Mini, Red", category = "Tapestries", cost = 120 }, -- OAAB
	["111"] = { id = "ab_furn_detapestrymini10", newId = "jsmk_fc_abfurn_detapestrymini10", name = "Tapestry Mini, Blue", category = "Tapestries", cost = 120 }, -- OAAB
	["112"] = { id = "ab_furn_detapestrymini13", newId = "jsmk_fc_abfurn_detapestrymini13", name = "Tapestry Mini, Purple", category = "Tapestries", cost = 120 }, -- OAAB
	["113"] = { id = "t_imp_furn_tapestry_04", newId = "jsmk_fc_t_imp_furn_tapestry_04", name = "Tapestry, Leaves", category = "Tapestries", cost = 120 }, -- PC
	["114"] = { id = "t_imp_furn_tapestry_05", newId = "jsmk_fc_t_imp_furn_tapestry_05", name = "Tapestry, Grove", category = "Tapestries", cost = 120 }, -- PC
	["115"] = { id = "t_imp_furn_tapestrybastlarge_10", newId = "jsmktimpfurntapestrybastlarge10", name = "Tapestry, Fern", category = "Tapestries", cost = 120 }, -- SKY
	["116"] = { id = "t_imp_furn_tapestrywoollarge_02", newId = "jsmktimpfurntapestrywoollarge02", name = "Tapestry, Trellis", category = "Tapestries", cost = 120 }, -- SKY
	["117"] = { id = "t_imp_furn_tapestrywoollarge_06", newId = "jsmktimpfurntapestrywoollarge06", name = "Tapestry, Wildflower", category = "Tapestries", cost = 120 }, -- SKY
	["118"] = { id = "t_imp_furn_tapestry_18", newId = "jsmk_fc_t_imp_furn_tapestry_18", name = "Tapestry, Golden", category = "Tapestries", cost = 120 }, -- TR
	["119"] = { id = "t_imp_furn_tapestry_28", newId = "jsmk_fc_t_imp_furn_tapestry_28", name = "Tapestry, Morning", category = "Tapestries", cost = 120 }, -- TR
	["120"] = { id = "t_imp_furn_tapestry_29", newId = "jsmk_fc_t_imp_furn_tapestry_29", name = "Tapestry, Indigo", category = "Tapestries", cost = 120 }, -- TR

	-- Cushion pack: All Cushion needs to be named exactly "Cushion"
	["121"] = { id = "furn_de_cushion_round_01", newId = "jsmk_fc_furnde_cushion_round_01", name = "Cushion, Round", category = "Cushions", cost = 30, scale = 0.9 }, -- MW
	["122"] = { id = "furn_de_cushion_round_02", newId = "jsmk_fc_furnde_cushion_round_02", name = "Cushion, Round", category = "Cushions", cost = 30 }, -- MW
	["123"] = { id = "furn_de_cushion_round_04", newId = "jsmk_fc_furnde_cushion_round_04", name = "Cushion, Round", category = "Cushions", cost = 30, scale = 0.9 }, -- MW
	["124"] = { id = "furn_de_cushion_round_07", newId = "jsmk_fc_furnde_cushion_round_07", name = "Cushion, Round", category = "Cushions", cost = 30, scale = 0.89 }, -- MW
	["125"] = { id = "furn_de_cushion_square_01", newId = "jsmk_fc_furndecushion_square_01", name = "Cushion, Square", category = "Cushions", cost = 30 }, -- MW       
	["126"] = { id = "furn_de_cushion_square_02", newId = "jsmk_fc_furndecushion_square_02", name = "Cushion, Square", category = "Cushions", cost = 30, scale = 0.667 }, -- MW
	["127"] = { id = "furn_de_cushion_square_05", newId = "jsmk_fc_furndecushion_square_05", name = "Cushion, Square", category = "Cushions", cost = 30 }, -- MW       
	["128"] = { id = "furn_de_cushion_square_06", newId = "jsmk_fc_furndecushion_square_06", name = "Cushion, Square", category = "Cushions", cost = 30 }, -- MW

	-- TR Wood Dunmer rm
	["129"] = { id = "ab_furn_demidbench", newId = "jsmk_fc_ab_furn_demidbench", name = "Bench", category = "Seats", cost = 50 }, -- OAAB
	["130"] = { id = "ab_furn_demidscrollrack", newId = "jsmk_fc_ab_furn_demidscrollrack", name = "Scroll Rack", category = "Shelves", cost = 300 }, -- OAAB
	["131"] = { id = "ab_furn_demidshelf", newId = "jsmk_fc_ab_furn_demidshelf", name = "Shelf, Expensive", category = "Shelves", cost = 50 }, -- OAAB
	["132"] = { id = "ab_furn_demidtable01", newId = "jsmk_fc_ab_furn_demidtable01", name = "Large Table", category = "Tables", cost = 100 }, -- OAAB
	["133"] = { id = "t_de_furnm_bed_b_01", newId = "jsmk_fc_t_de_furnm_bed_b_01", name = "Bunk Bed, Green", category = "Beds", cost = 300 }, -- TR
	["134"] = { id = "t_de_furnm_bed_d_02", newId = "jsmk_fc_t_de_furnm_bed_d_02", name = "Double Bed, Brown", category = "Beds", cost = 300 }, -- TR
	["135"] = { id = "t_de_furnm_bed_s_03", newId = "jsmk_fc_t_de_furnm_bed_s_03", name = "Single Bed, Brown", category = "Beds", cost = 150 }, -- TR
	["136"] = { id = "t_de_furnm_bookshelf_01", newId = "jsmk_fc_t_de_furnm_bookshelf_01", name = "Bookshelf", category = "Shelves", cost = 600 }, -- TR
	["137"] = { id = "t_de_furnm_chair_01", newId = "jsmk_fc_t_de_furnm_chair_01", name = "Chair, Expensive", category = "Seats", cost = 60 }, -- TR
	["138"] = { id = "t_de_furnm_bench_01", newId = "jsmk_fc_t_de_furnm_bench_01", name = "Bench", category = "Seats", cost = 50 }, -- TR
	["139"] = { id = "t_de_furnm_table_01", newId = "jsmk_fc_t_de_furnm_table_01", name = "Table", category = "Tables", cost = 100 }, -- TR
	["140"] = { id = "t_de_furnm_table_03", newId = "jsmk_fc_t_de_furnm_table_03", name = "Table", category = "Tables", cost = 50 }, -- TR

	-- Skyrim Wood pack
	["141"] = { id = "t_nor_furnm_bar_04", newId = "jsmk_fc_t_nor_furnm_bar_04", name = "Bar", category = "Tables", cost = 100 }, -- SKY
	["142"] = { id = "t_imp_furnsky_bench_01a", newId = "jsmk_fc_t_imp_furnsky_bench_01a", name = "Bench, Nordic", category = "Seats", cost = 50 }, -- SKY
	["143"] = { id = "t_nor_furnm_bookshelf_01", newId = "jsmk_fc_tnor_furnm_bookshelf_01", name = "Bookshelf", category = "Shelves", cost = 150 }, -- SKY
	["144"] = { id = "t_nor_furnm_chair_01", newId = "jsmk_fc_t_nor_furnm_chair_01", name = "Chair, Nordic", category = "Seats", cost = 25 }, -- SKY
	["145"] = { id = "t_nor_furnm_table_01", newId = "jsmk_fc_t_nor_furnm_table_01", name = "Table", category = "Tables", cost = 100 }, -- SKY
	["146"] = { id = "t_imp_furnsky_table_01", newId = "jsmk_fc_t_imp_furnsky_table_01", name = "Table", category = "Tables", cost = 100 }, -- SKY
	["147"] = { id = "t_imp_furnsky_table_03", newId = "jsmk_fc_t_imp_furnsky_table_03", name = "Table", category = "Tables", cost = 100 }, -- SKY
	["148"] = { id = "t_skycom_var_cr6empty", newId = "jsmk_fc_t_skycom_var_cr6empty", name = "Crate, Nordic Large", category = "Crates", cost = 10 }, -- SKY
	["149"] = { id = "t_skynor_furnm_cb1empty", newId = "jsmk_fc_t_skynor_furnm_cb1empty", name = "Cupboard", category = "Containers", cost = 100 }, -- SKY
	["150"] = { id = "t_skynor_furnm_cl1empty", newId = "jsmk_fc_t_skynor_furnm_cl1empty", name = "Closet", category = "Containers", cost = 400 }, -- SKY

	-- Metal Silver pack
	["154"] = { id = "ab_light_comsconsilvblu_128", newId = "jsmk_fcablightcomsconsilvblu128", name = "Silver Sconce, Blue Candles", category = "Lights", cost = 12 }, -- OAAB
	["155"] = { id = "ab_light_comsconsilvwht_128", newId = "jsmk_fcablightcomsconsilvwht128", name = "Silver Sconce, White Candles", category = "Lights", cost = 12 }, -- OAAB        
	["156"] = { id = "t_imp_furn_incense_02_16", newId = "jsmk_fc_timp_furn_incense_02_16", name = "Silver Incense", category = "Lights", cost = 12 }, -- PC

	-- More Lights pack
	["157"] = { id = "light_com_candle_07", newId = "jsmk_fc_light_com_candle_07", name = "Candles, Orange", category = "Lights", cost = 12 }, -- MW    
	["158"] = { id = "light_com_candle_11", newId = "jsmk_fc_light_com_candle_11", name = "Candles Three Blue, Blue Flame", category = "Lights", cost = 12 }, -- MW
	["159"] = { id = "light_com_candle_13", newId = "jsmk_fc_light_com_candle_13", name = "Candles, Red", category = "Lights", cost = 12 }, -- MW
	["163"] = { id = "light_de_lantern_04", newId = "jsmk_fc_light_de_lantern_04", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- MW
	["166"] = { id = "light_de_streetlight_01", newId = "jsmk_fc_light_de_streetlight_01", name = "Street Light, Orange", category = "Lights", cost = 12 }, -- MW
	["167"] = { id = "ab_light_delantpapergrn00_256", newId = "jsmk_ablightdelantpapergrn00256", name = "Paper Lantern, Green", category = "Lights", cost = 12 }, -- OAAB
	["168"] = { id = "ab_light_delantglassblu01_256", newId = "jsmk_ablightdelantglassblu01256", name = "Glass Lantern, Blue", category = "Lights", cost = 12 }, -- OAAB

	-- Swirlwood pack
	["170"] = { id = "active_de_r_bed_01", newId = "jsmk_fc_active_de_r_bed_01", name = "Single Bed, Aqua", category = "Beds", cost = 150 }, -- MW
	["171"] = { id = "furn_de_r_bench_01", newId = "jsmk_fc_furn_de_r_bench_01", name = "Bench, Swirlwood Large", category = "Seats", cost = 55 }, -- MW
	["172"] = { id = "furn_de_r_bookshelf_02", newId = "jsmk_fc_furn_de_r_bookshelf_02", name = "Bookshelf, Swirlwood", category = "Shelves", cost = 120 }, -- MW
	["173"] = { id = "furn_de_r_table_03", newId = "jsmk_fc_furn_de_r_table_03", name = "Table, Swirlwood Oval", category = "Tables", cost = 150 }, -- MW
	["174"] = { id = "furn_de_r_table_07", newId = "jsmk_fc_furn_de_r_table_07", name = "Table, Swirlwood Large Rectangular", category = "Tables", cost = 140 }, -- MW
	["175"] = { id = "furn_de_r_table_09", newId = "jsmk_fc_furn_de_r_table_09", name = "Table, Swirlwood Small Rectangular", category = "Tables", cost = 70 }, -- MW
	["176"] = { id = "de_r_drawers_01_empty", newId = "jsmk_fc_de_r_drawers_01_empty", name = "Drawers, Swirlwood", category = "Containers", cost = 180 }, -- MW
	["177"] = { id = "ab_furn_derchbookshelftall", newId = "jsmk_fcabfurnderchbookshelftall", name = "Bookshelf, Swirlwood", category = "Shelves", cost = 200 }, -- OAAB
	["178"] = { id = "t_de_furnr_bookstand_01", newId = "jsmk_fc_t_de_furnr_bookstand_01", name = "Bookstand, Swirlwood", category = "Other", cost = 100 }, -- TR
	["179"] = { id = "t_de_furnr_chair_01", newId = "jsmk_fc_t_de_furnr_chair_01", name = "Chair, Swirlwood", category = "Seats", cost = 50 }, -- TR
	["180"] = { id = "t_mwde_furnr_ds1empty", newId = "jsmk_fc_t_mwde_furnr_ds1empty", name = "Desk, Swirlwood", category = "Containers", cost = 200 }, -- TR

	-- Cherry Wood pack
	["181"] = { id = "active_com_bed_01", newId = "jsmk_fc_active_com_bed_01", name = "Single Bed, Blue", category = "Beds", cost = 225 }, -- MW
	["182"] = { id = "furn_com_r_bookshelf_01", newId = "jsmk_fc_furn_com_r_bookshelf_01", name = "Bookshelf, Cherry Wood", category = "Shelves", cost = 100 }, -- MW
	["183"] = { id = "furn_com_r_chair_01", newId = "jsmk_fc_furn_com_r_chair_01", name = "Chair, Cherry Wood", category = "Seats", cost = 60 }, -- MW
	["184"] = { id = "furn_com_r_table_01", newId = "jsmk_fc_furn_com_r_table_01", name = "Table, Cherry Wood", category = "Tables", cost = 100 }, -- MW
	["185"] = { id = "com_drawers_01", newId = "jsmk_fc_com_drawers_01", name = "Chest of Drawers, Cherry Wood", category = "Containers", cost = 120 }, -- MW
	["186"] = { id = "ab_o_comrchfootlckempty", newId = "jsmk_fc_ab_o_comrchfootlckempty", name = "Footlocker, Cherry Wood", category = "Containers", cost = 6 }, -- OAAB
	["187"] = { id = "ab_o_comrchdesk2empty", newId = "jsmk_fc_ab_o_comrchdesk2empty", name = "Desk, Cherry Wood", category = "Containers", cost = 200 }, -- OAAB
	["188"] = { id = "t_imp_furnr_shelf_01", newId = "jsmk_fc_t_imp_furnr_shelf_01", name = "Shelf, Cherry Wood", category = "Shelves", cost = 60 }, -- PC
	["189"] = { id = "t_cyrimp_furnr_display1", newId = "jsmk_fc_t_cyrimp_furnr_display1", name = "Display Case", category = "Containers", cost = 360 }, -- PC
	["190"] = { id = "t_cyrimp_furnr_ht1empty", newId = "jsmk_fc_t_cyrimp_furnr_ht1empty", name = "Hutch", category = "Containers", cost = 360 }, -- PC
	["191"] = { id = "t_cyrimp_furnr_lc1empty", newId = "jsmk_fc_t_cyrimp_furnr_lc1empty", name = "Lecturn", category = "Containers", cost = 120 }, -- PC

	-- Urn pack
	["192"] = { id = "furn_planter_01", newId = "jsmk_fc_furn_planter_01", name = "Planter Small, AI Soil", category = "Planters", cost = 40 }, -- MW
	["193"] = { id = "furn_planter_02", newId = "jsmk_fc_furn_planter_02", name = "Planter Med, AI Soil", category = "Planters", cost = 80, scale = 0.64 }, -- MW
	["194"] = { id = "furn_planter_04", newId = "jsmk_fc_furn_planter_04", name = "Planter Large", category = "Planters", cost = 120, scale = 0.76 }, -- MW
	["195"] = { id = "urn_01", newId = "jsmk_fc_urn_01", name = "Urn", category = "Containers", cost = 30 }, -- MW
	["196"] = { id = "urn_02", newId = "jsmk_fc_urn_02", name = "Urn", category = "Containers", cost = 120, scale = 0.7 }, -- MW
	["197"] = { id = "ab_furn_deflagon_01", newId = "jsmk_fc_ab_furn_deflagon_01", name = "Flagon", category = "Other", cost = 20, scale = 0.66 }, -- OAAB
	["198"] = { id = "ab_furn_deplanter01ash", newId = "jsmk_fc_ab_furn_deplanter01ash", name = "Planter, Ashland Soil", category = "Planters", cost = 40, scale = 0.5 }, -- OAAB     
	["199"] = { id = "ab_furn_deplanterbonsai", newId = "jsmk_fc_ab_furn_deplanterbonsai", name = "Planter, Bonsai", category = "Planters", cost = 50, scale = 0.5 }, -- OAAB
	["200"] = { id = "ab_o_urnash_01", newId = "jsmk_fc_ab_o_urnash_01", name = "Urn", category = "Containers", cost = 100 }, -- OAAB
	["201"] = { id = "t_de_furn_urnopen_01", newId = "jsmk_fc_t_de_furn_urnopen_01", name = "Urn, Open", category = "Other", cost = 30 }, -- TR
	["203"] = { id = "t_mwde_furn_urntapempty", newId = "jsmk_fc_t_mwde_furn_urntapempty", name = "Urn, with Tapestry", category = "Containers", cost = 40 }, -- TR

	--- Plant pack
	["204"] = { id = "flora_bc_fern_03", newId = "jsmk_fc_flora_bc_fern_03", name = "Fern", category = "Plants", cost = 10, scale = 0.5 }, -- MW
	["205"] = { id = "flora_bc_mushroom_01", newId = "jsmk_fc_flora_bc_mushroom_01", name = "Luminous Russula", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["206"] = { id = "flora_bc_mushroom_06", newId = "jsmk_fc_flora_bc_mushroom_06", name = "Violet Coprinus", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["207"] = { id = "flora_grass_01", newId = "jsmk_fc_flora_grass_01", name = "Grass", category = "Plants", cost = 10, scale = 1.43 }, -- MW
	["208"] = { id = "flora_ivy_01", newId = "jsmk_fc_flora_ivy_01", name = "Ivy", category = "Plants", cost = 10 }, -- MW
	["209"] = { id = "ab_f_bluekanet_01", newId = "jsmk_fc_ab_f_bluekanet_01", name = "Blue Kanet", category = "Plants", cost = 100 }, -- OAAB
	["210"] = { id = "ab_f_harrada_01", newId = "jsmk_fc_ab_f_harrada_01", name = "Harrada", category = "Plants", cost = 100 }, -- OAAB

	-- Unorganized
	["211"] = { id = "chest_small_02", newId = "jsmk_fc_chest_small_02", name = "Chest, Small", category = "Containers", cost = 30 }, -- MW
	["212"] = { id = "com_chest_01", newId = "jsmk_fc_com_chest_01", name = "Chest, Wooden", category = "Containers", cost = 15 }, -- MW
	["213"] = { id = "furn_com_coatofarms_01", newId = "jsmk_fc_furn_com_coatofarms_01", name = "Coat of Arms, Eagles", category = "Other", cost = 200 }, -- MW
	["214"] = { id = "furn_com_coatofarms_02", newId = "jsmk_fc_furn_com_coatofarms_02", name = "Coat of Arms, Beasts", category = "Other", cost = 200 }, -- MW
	["215"] = { id = "furn_com_lantern_hook_02", newId = "jsmk_fc_furncom_lantern_hook_02", name = "Lantern Hook", category = "Other", cost = 10 }, -- MW
	["216"] = { id = "furn_com_pm_stool_02", newId = "jsmk_fc_furn_com_pm_stool_02", name = "Stool, Cheap", category = "Seats", cost = 20 }, -- MW
	["217"] = { id = "ab_furn_comincense01", newId = "jsmk_fc_ab_furn_comincense01", name = "Incense", category = "Other", cost = 100 }, -- OAAB
	["218"] = { id = "ab_furn_lwbowlwater", newId = "jsmk_fc_ab_furn_lwbowlwater", name = "Limeware Bowl of Water", category = "Water", cost = 200 }, -- OAAB
	["219"] = { id = "ab_furn_pracmarkstarget02", newId = "jsmk_fc_abfurnpracmarkstarget02", name = "Marksman Pratice Target", category = "Other", cost = 200 }, -- OAAB
	["220"] = { id = "active_de_p_bed_28", newId = "jsmk_fc_active_de_p_bed_28", name = "Hammock", category = "Beds", cost = 50 }, -- MW
	["221"] = { id = "furn_de_rope_03", newId = "jsmk_fc_furn_de_rope_03", name = "Rope", category = "Ropes", cost = 10 }, -- MW
	["222"] = { id = "furn_de_shack_basket_01", newId = "jsmk_fc_furn_de_shack_basket_01", name = "Basket, Large", category = "Other", cost = 20 }, -- MW
	["223"] = { id = "furn_de_shack_basket_02", newId = "jsmk_fc_furn_de_shack_basket_02", name = "Basket, Small", category = "Other", cost = 20 }, -- MW
	["224"] = { id = "furn_de_shack_hook", newId = "jsmk_fc_furn_de_shack_hook", name = "Hook, Iron", category = "Other", cost = 10 }, -- MW
	["225"] = { id = "light_de_candle_07", newId = "jsmk_fc_light_de_candle_07", name = "Candle, Orange", category = "Lights", cost = 12 }, -- MW
	["226"] = { id = "t_nor_furnp_table_01", newId = "jsmk_fc_t_nor_furnp_table_01", name = "Table, Nordic", category = "Tables", cost = 1205 }, -- SKY
	["227"] = { id = "furn_rug_bearskin", newId = "jsmk_fc_furn_rug_bearskin", name = "Rug, Bearskin", category = "Rugs", cost = 100, scale = 1.5 }, -- MW
	["228"] = { id = "t_nor_furn_chandelier01_256", newId = "jsmk_fc_tnorfurnchandelier01256", name = "Chandelier, Nordic", category = "Lights", cost = 120 }, -- SKY
	["229"] = { id = "ex_siltstrider_02", newId = "jsmk_fc_ex_siltstrider_02", name = "Silt Strider Shell", category = "Other", cost = 1205, scale = 0.82 }, -- MW
	["230"] = { id = "flora_ash_grass_r_01", newId = "jsmk_fc_flora_ash_grass_r_01", name = "Grass, Ashland", category = "Plants", cost = 10, scale = 0.9 }, -- MW
	["231"] = { id = "active_de_bedroll", newId = "jsmk_fc_active_de_bedroll", name = "Bedroll", category = "Beds", cost = 50 }, -- MW
	["232"] = { id = "light_ashl_lantern_03", newId = "jsmk_fc_light_ashl_lantern_03", name = "Lantern, Ashlanders Red", category = "Lights", cost = 12 }, -- MW   
	["233"] = { id = "com_basket_01_empty", newId = "jsmk_fc_com_basket_01_empty", name = "Basket, Tall", category = "Containers", cost = 20 }, -- MW
	["234"] = { id = "furn_de_basket_01", newId = "jsmk_fc_furn_de_basket_01", name = "Basket", category = "Other", cost = 20 }, -- MW
	["235"] = { id = "in_ashl_tent_banner_02", newId = "jsmk_fc_in_ashl_tent_banner_02", name = "Banner, Ashlanders", category = "Tapestries", cost = 120 }, -- MW
	["236"] = { id = "in_ashl_tent_banner_08", newId = "jsmk_fc_in_ashl_tent_banner_08", name = "Banner, Ashlanders", category = "Tapestries", cost = 120 }, -- MW
	["237"] = { id = "in_ashl_tent_banner_12", newId = "jsmk_fc_in_ashl_tent_banner_12", name = "Banner, Ashlanders", category = "Tapestries", cost = 120 }, -- MW
	["238"] = { id = "t_de_var_guarskin_01", newId = "jsmk_fc_t_de_var_guarskin_01", name = "Guar Skin", category = "Tapestries", cost = 120 }, -- TR     
	["239"] = { id = "furn_de_cushion_square_03", newId = "jsmk_fc_furndecushion_square_03", name = "Cushion", category = "Cushions", cost = 30 }, -- MW       
	["240"] = { id = "in_ashl_tent_banner_09", newId = "jsmk_fc_in_ashl_tent_banner_09", name = "Banner, Ashlanders", category = "Tapestries", cost = 120 }, -- MW
	["241"] = { id = "light_ashl_lantern_02", newId = "jsmk_fc_light_ashl_lantern_02", name = "Lantern, Ashlanders Orange", category = "Lights", cost = 12 }, -- MW   
	["242"] = { id = "light_de_candle_02", newId = "jsmk_fc_light_de_candle_02", name = "Candle, White", category = "Lights", cost = 12 }, -- MW
	["243"] = { id = "t_mwde_furn_vs1empty", newId = "jsmk_fc_t_mwde_furn_vs1empty", name = "Vase", category = "Containers", cost = 60, scale = 0.8 }, -- TR
	["244"] = { id = "t_mwde_furn_vs2empty", newId = "jsmk_fc_t_mwde_furn_vs2empty", name = "Vase", category = "Containers", cost = 60, scale = 0.7 }, -- TR
	["245"] = { id = "t_mwde_furn_vs3empty", newId = "jsmk_fc_t_mwde_furn_vs3empty", name = "Vase", category = "Containers", cost = 60, scale = 0.5 }, -- TR
	["246"] = { id = "urn_03", newId = "jsmk_fc_urn_03", name = "Urn", category = "Containers", cost = 30 }, -- MW
	["247"] = { id = "urn_05", newId = "jsmk_fc_urn_05", name = "Urn", category = "Containers", cost = 30, scale = 0.5 }, -- MW
	["248"] = { id = "furn_de_cushion_round_06", newId = "jsmk_fc_furnde_cushion_round_06", name = "Cushion", category = "Cushions", cost = 30, scale = 0.8 }, -- MW
	["249"] = { id = "furn_de_p_bench_04", newId = "jsmk_fc_furn_de_p_bench_04", name = "Bench", category = "Seats", cost = 30 }, -- MW
	["250"] = { id = "light_de_candle_08", newId = "jsmk_fc_light_de_candle_08", name = "Candle, White", category = "Lights", cost = 12 }, -- MW
	["252"] = { id = "t_mwcom_var_bss1empty", newId = "jsmk_fc_t_mwcom_var_bss1empty", name = "Basket, Short", category = "Containers", cost = 20 }, -- TR       
	["253"] = { id = "t_mwde_furn_vs4food", newId = "jsmk_fc_t_mwde_furn_vs4food", name = "Vase", category = "Containers", cost = 60, scale = 0.6 }, -- TR
	["254"] = { id = "ab_furn_ashlincense", newId = "jsmk_fc_ab_furn_ashlincense", name = "Incense, Ashlanders", category = "Other", cost = 100 }, -- OAAB   
	["255"] = { id = "ab_furn_ashlskull_02", newId = "jsmk_fc_ab_furn_ashlskull_02", name = "Skulls, Ashlanders", category = "Other", cost = 100 }, -- OAAB   
	["256"] = { id = "furn_de_rope_07", newId = "jsmk_fc_furn_de_rope_07", name = "Rope", category = "Ropes", cost = 10 }, -- MW
	["257"] = { id = "ab_furn_ashlskull_03", newId = "jsmk_fc_ab_furn_ashlskull_03", name = "Skulls, Ashlanders", category = "Other", cost = 150 }, -- OAAB   
	["258"] = { id = "furn_de_cushion_square_08", newId = "jsmk_fc_furndecushion_square_08", name = "Cushion", category = "Cushions", cost = 30, scale = 0.8 }, -- MW
	["259"] = { id = "furn_de_rope_05", newId = "jsmk_fc_furn_de_rope_05", name = "Rope", category = "Ropes", cost = 10, scale = 1.08 }, -- MW      
	["260"] = { id = "light_de_candle_01", newId = "jsmk_fc_light_de_candle_01", name = "Candle, White", category = "Lights", cost = 12 }, -- MW
	["261"] = { id = "t_rga_furn_mat_02", newId = "jsmk_fc_t_rga_furn_mat_02", name = "Mat, Red", category = "Rugs", cost = 120 }, -- PC
	["262"] = { id = "light_ashl_lantern_01", newId = "jsmk_fc_light_ashl_lantern_01", name = "Lantern, Ashlanders Blue", category = "Lights", cost = 12 }, -- MW   
	["263"] = { id = "light_ashl_lantern_07", newId = "jsmk_fc_light_ashl_lantern_07", name = "Lantern, Ashlanders Indigo", category = "Lights", cost = 12 }, -- MW 
	["265"] = { id = "t_de_furn_rug_06", newId = "jsmk_fc_t_de_furn_rug_06", name = "Rug, Red", category = "Rugs", cost = 120, scale = 0.5 }, -- TR
	["266"] = { id = "furn_ashl_bugbowl", newId = "jsmk_fc_furn_ashl_bugbowl", name = "Bug Bowl, Ashlanders Orange", category = "Other", cost = 40 }, -- MW       
	["267"] = { id = "ab_furn_debasket_01", newId = "jsmk_fc_ab_furn_debasket_01", name = "Basket", category = "Other", cost = 20 }, -- OAAB
	["268"] = { id = "ab_o_ashltrinketbox", newId = "jsmk_fc_ab_o_ashltrinketbox", name = "Trinket Box", category = "Containers", cost = 340, scale = 0.6 }, -- OAAB
	["269"] = { id = "flora_wickwheat_01", newId = "jsmk_fc_flora_wickwheat_01", name = "Wickwheat", category = "Plants", cost = 100, scale = 0.6 }, -- MW
	["270"] = { id = "furn_ashl_bugbowl_02", newId = "jsmk_fc_furn_ashl_bugbowl_02", name = "Bug Bowl, Ashlanders Green", category = "Other", cost = 40 }, -- MW
	["272"] = { id = "t_de_furn_rugsmall_01", newId = "jsmk_fc_t_de_furn_rugsmall_01", name = "Rug, Ropes", category = "Rugs", cost = 60, scale = 0.5 }, -- TR
	["273"] = { id = "ab_furn_barrel01water", newId = "jsmk_fc_ab_furn_barrel01water", name = "Barrel of Water", category = "Water", cost = 40 }, -- OAAB
	["274"] = { id = "ab_furn_ropecoilhang", newId = "jsmk_fc_ab_furn_ropecoilhang", name = "Coil of Rope", category = "Ropes", cost = 30 }, -- OAAB
	["275"] = { id = "ab_furn_deplnbookshelf01", newId = "jsmk_fc_abfurn_deplnbookshelf01", name = "Bookshelf, Cheap", category = "Shelves", cost = 60, notForSale = true }, -- OAAB, dupe for furn_de_p_bookshelf_01
	["276"] = { id = "ab_furn_deplntable04", newId = "jsmk_fc_ab_furn_deplntable04", name = "Large Table, Cheap", category = "Tables", cost = 100, notForSale = true }, -- OAAB, dupe for furn_de_p_table_04
	["277"] = { id = "ab_furn_ropehang01", newId = "jsmk_fc_ab_furn_ropehang01", name = "Rope", category = "Ropes", cost = 10 }, -- OAAB   
	["278"] = { id = "ab_furn_velincense01", newId = "jsmk_fc_ab_furn_velincense01", name = "Incense, Velothi", category = "Other", cost = 100 }, -- OAAB
	["279"] = { id = "ab_light_delantpaperblu01_256", newId = "jsmk_ablightdelantpaperblu01256", name = "Paper Lantern, Blue", category = "Lights", cost = 12 }, -- OAAB
	["280"] = { id = "ab_o_satchelingbasic", newId = "jsmk_fc_ab_o_satchelingbasic", name = "Satchel, Alchemist's", category = "Containers", cost = 50 }, -- OAAB
	["281"] = { id = "active_de_bed_30", newId = "jsmk_fc_active_de_bed_30", name = "Hammock", category = "Beds", cost = 50 }, -- MW
	["282"] = { id = "chest_small_01_empty", newId = "jsmk_fc_chest_small_01_empty", name = "Chest, Small", category = "Containers", cost = 30 }, -- MW
	["283"] = { id = "furn_de_ex_stool_01", newId = "jsmk_fc_furn_de_ex_stool_01", name = "Stool, Cheap", category = "Seats", cost = 10 }, -- MW
	["284"] = { id = "furn_de_r_chair_03", newId = "jsmk_fc_furn_de_r_chair_03", name = "Chair, Swirlwood", category = "Seats", cost = 50 }, -- MW
	["285"] = { id = "aatl_furn_com_haypile", newId = "jsmk_fc_aatl_furn_com_haypile", name = "Hay Pile", category = "Other", cost = 10, scale = 1.56 }, -- AATL
	["286"] = { id = "aatl_furn_redoranaltar", newId = "jsmk_fc_aatl_furn_redoranaltar", name = "Redoran Altar", category = "Other", cost = 10 }, -- AATL
	["287"] = { id = "ab_ex_derack02", newId = "jsmk_fc_ab_ex_derack02", name = "Rack, Wooden", category = "Other", cost = 20 }, -- OAAB
	["288"] = { id = "ab_ex_velchimney", newId = "jsmk_fc_ab_ex_velchimney", name = "Chimney, Velothi", category = "Structures", cost = 20 }, -- OAAB
	["289"] = { id = "ab_f_dustcap_04", newId = "jsmk_fc_ab_f_dustcap_04", name = "Dustcap", category = "Plants", cost = 100, scale = 0.78, deprecated = true }, -- OAAB
	["291"] = { id = "ab_f_glowingmuscaria_02", newId = "jsmk_fc_ab_f_glowingmuscaria_02", name = "Glowing Chanterelle", category = "Plants", cost = 100, scale = 0.87, deprecated = true }, -- OAAB
	["292"] = { id = "ab_f_hacklelo3_o", newId = "jsmk_fc_ab_f_hacklelo3_o", name = "Hackle-lo", category = "Plants", cost = 100, scale = 0.54 }, -- OAAB
	["293"] = { id = "ab_f_urnula_03", newId = "jsmk_fc_ab_f_urnula_03", name = "Veiled Urnula", category = "Plants", cost = 100, deprecated = true }, -- OAAB
	["294"] = { id = "ab_f_viciousmuscaria_02", newId = "jsmk_fc_ab_f_viciousmuscaria_02", name = "Vicious Chanterelle", category = "Plants", cost = 100, deprecated = true }, -- OAAB
	["295"] = { id = "ab_flora_ashknee_01", newId = "jsmk_fc_ab_flora_ashknee_01", name = "Ash Knee", category = "Plants", cost = 10 }, -- OAAB
	["296"] = { id = "ab_furn_comarmorstandiron01", newId = "jsmk_fabfurncomarmorstandiron01", name = "Armor Stand, Iron", category = "Other", cost = 400 }, -- OAAB
	["297"] = { id = "ab_furn_combucket02hang", newId = "jsmk_fc_ab_furn_combucket02hang", name = "Bucket", category = "Other", cost = 20 }, -- OAAB
	["298"] = { id = "ab_furn_demidchair", newId = "jsmk_fc_ab_furn_demidchair", name = "Chair, Expensive", category = "Seats", cost = 60 }, -- OAAB
	["299"] = { id = "ab_furn_demidwallscreen", newId = "jsmk_fc_ab_furn_demidwallscreen", name = "Wallscreen, Middle Class", category = "Other", cost = 100 }, -- OAAB
	["300"] = { id = "ab_furn_deplnloom04", newId = "jsmk_fc_ab_furn_deplnloom04", name = "Loom", category = "Other", cost = 200 }, -- OAAB
	["301"] = { id = "ab_furn_deplntable05", newId = "jsmk_fc_ab_furn_deplntable05", name = "Small Table, Cheap", category = "Tables", cost = 50, notForSale = true }, -- OAAB, dupe for furn_de_p_table_05
	["302"] = { id = "ab_furn_derchwallscreen", newId = "jsmk_fc_ab_furn_derchwallscreen", name = "Wallscreen, Rich", category = "Other", cost = 200 }, -- OAAB
	["303"] = { id = "ab_o_alchjarbgslime", newId = "jsmk_fc_ab_o_alchjarbgslime", name = "Jar of Bittergreen Slime", category = "Containers", cost = 50 }, -- OAAB
	["304"] = { id = "ab_o_alchjardreughwax", newId = "jsmk_fc_ab_o_alchjardreughwax", name = "Jar of Dreugh Wax", category = "Containers", cost = 50 }, -- OAAB
	["305"] = { id = "ab_o_alchjarresin", newId = "jsmk_fc_ab_o_alchjarresin", name = "Jar of Resin", category = "Containers", cost = 50 }, -- OAAB
	["306"] = { id = "ab_o_ashlscathecraw", newId = "jsmk_fc_ab_o_ashlscathecraw", name = "Scathecraw Bundle", category = "Plants", cost = 50 }, -- OAAB
	["307"] = { id = "ab_o_comclosetthin", newId = "jsmk_fc_ab_o_comclosetthin", name = "Closet", category = "Containers", cost = 100 }, -- OAAB
	["309"] = { id = "ab_o_velothicoffer_01", newId = "jsmk_fc_ab_o_velothicoffer_01", name = "Coffer, Velothi", category = "Containers", cost = 100 }, -- OAAB
	["312"] = { id = "active_de_r_bed_20", newId = "jsmk_fc_active_de_r_bed_20", name = "Double Bed, Red", category = "Beds", cost = 300 }, -- MW
	["313"] = { id = "flora_bc_shelffungus_03", newId = "jsmk_fc_flora_bc_shelffungus_03", name = "Hypha Facia", category = "Plants", cost = 100, scale = 0.55 }, -- MW
	["314"] = { id = "flora_black_lichen_02", newId = "jsmk_fc_flora_black_lichen_02", name = "Black Lichen", category = "Plants", cost = 100, deprecated = true }, -- MW
	["315"] = { id = "flora_gold_kanet_01", newId = "jsmk_fc_flora_gold_kanet_01", name = "Gold Kanet Flower", category = "Plants", cost = 100 }, -- MW
	["316"] = { id = "flora_heather_01", newId = "jsmk_fc_flora_heather_01", name = "Heather", category = "Plants", cost = 100, deprecated = true }, -- MW
	["317"] = { id = "furn_com_planter", newId = "jsmk_fc_furn_com_planter", name = "Planter, Redware", category = "Planters", cost = 40 }, -- MW
	["318"] = { id = "furn_de_tapestry_05", newId = "jsmk_fc_furn_de_tapestry_05", name = "Tapestry, Red", category = "Tapestries", cost = 120 }, -- MW
	["319"] = { id = "furn_de_tapestry_08", newId = "jsmk_fc_furn_de_tapestry_08", name = "Tapestry, Checker", category = "Tapestries", cost = 120 }, -- MW
	["320"] = { id = "furn_de_tray_01", newId = "jsmk_fc_furn_de_tray_01", name = "Tray", category = "Other", cost = 20 }, -- MW
	["322"] = { id = "light_de_lamp_03", newId = "jsmk_fc_light_de_lamp_03", name = "Lamp, Red", category = "Lights", cost = 20 }, -- MW
	["323"] = { id = "light_de_paper_lantern_01", newId = "jsmk_fc_lightdepaper_lantern_01", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- MW
	["324"] = { id = "ab_ex_ashlawning_03", newId = "jsmk_fc_ab_ex_ashlawning_03", name = "Awning", category = "Structures", cost = 50 }, -- OAAB
	["325"] = { id = "ab_ex_descaffold01", newId = "jsmk_fc_ab_ex_descaffold01", name = "Scaffold", category = "Structures", cost = 50 }, -- OAAB
	["326"] = { id = "ab_furn_crate03open", newId = "jsmk_fc_ab_furn_crate03open", name = "Crate, Open", category = "Crates", cost = 20 }, -- OAAB
	["327"] = { id = "ab_furn_detapestrymini04", newId = "jsmk_fc_abfurn_detapestrymini04", name = "Tapestry Mini, Red", category = "Tapestries", cost = 120 }, -- OAAB
	["328"] = { id = "ab_light_delantpaper01_256", newId = "jsmk_fc_ablightdelantpaper01256", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- OAAB
	["329"] = { id = "ab_furn_barrel01open", newId = "jsmk_fc_ab_furn_barrel01open", name = "Barrel, Open", category = "Other", cost = 30 }, -- OAAB
	["330"] = { id = "ab_furn_cartwheel", newId = "jsmk_fc_ab_furn_cartwheel", name = "Cart Wheel", category = "Other", cost = 30 }, -- OAAB
	["331"] = { id = "ab_furn_sackgrain01", newId = "jsmk_fc_ab_furn_sackgrain01", name = "Sack of Grain", category = "Other", cost = 50 }, -- OAAB
	["332"] = { id = "ab_o_crate03", newId = "jsmk_fc_ab_o_crate03", name = "Crate", category = "Crates", cost = 10 }, -- OAAB
	["333"] = { id = "ab_o_deshkbasket01", newId = "jsmk_fc_ab_o_deshkbasket01", name = "Wicker Basket", category = "Containers", cost = 10 }, -- OAAB
	["334"] = { id = "ab_o_deshkbasket02", newId = "jsmk_fc_ab_o_deshkbasket02", name = "Wicker Basket", category = "Containers", cost = 10 }, -- OAAB
	["335"] = { id = "furn_com_p_shelf_04", newId = "jsmk_fc_furn_com_p_shelf_04", name = "Shelf, Khaki", category = "Shelves", cost = 20 }, -- MW
	["336"] = { id = "furn_com_torch_ring_01", newId = "jsmk_fc_furn_com_torch_ring_01", name = "Torch Ring", category = "Other", cost = 10 }, -- MW
	["338"] = { id = "flora_ashtree_03", newId = "jsmk_fc_flora_ashtree_03", name = "Tree, Ashland", category = "Plants", cost = 100, scale = 1.15 }, -- MW
	["340"] = { id = "ab_light_delantpaper03_256", newId = "jsmk_fc_ablightdelantpaper03256", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- OAAB
	["341"] = { id = "furn_de_rope1_01", newId = "jsmk_fc_furn_de_rope1_01", name = "Rope", category = "Ropes", cost = 10 }, -- MW
	["342"] = { id = "furn_de_bannerpost_01", newId = "jsmk_fc_furn_de_bannerpost_01", name = "Banner Post", category = "Other", cost = 10 }, -- MW
	["343"] = { id = "furn_banner_temple_01_indoors", newId = "jsmk_ffurnbannertemple01indoors", name = "Banner, Tribunal", category = "Tapestries", cost = 100 }, -- MW
	["344"] = { id = "furn_banner_temple_02_indoors", newId = "jsmk_ffurnbannertemple02indoors", name = "Banner, Tribunal", category = "Tapestries", cost = 100 }, -- MW
	["345"] = { id = "furn_banner_temple_03_indoors", newId = "jsmk_ffurnbannertemple03indoors", name = "Banner, Tribunal", category = "Tapestries", cost = 100 }, -- MW
	["346"] = { id = "furn_de_screen_guar_01", newId = "jsmk_fc_furn_de_screen_guar_01", name = "Wallscreen, Guar Skin", category = "Other", cost = 100 }, -- MW
	["347"] = { id = "furn_de_tapestry_12", newId = "jsmk_fc_furn_de_tapestry_12", name = "Tapestry, Red", category = "Tapestries", cost = 120 }, -- MW
	["348"] = { id = "furn_de_tapestry_13", newId = "jsmk_fc_furn_de_tapestry_13", name = "Tapestry, Red", category = "Tapestries", cost = 120 }, -- MW
	["349"] = { id = "light_com_candle_06", newId = "jsmk_fc_light_com_candle_06", name = "Candles, Red", category = "Lights", cost = 3 }, -- MW
	["350"] = { id = "active_de_p_bed_03", newId = "jsmk_fc_active_de_p_bed_03", name = "Bunk Bed, Olive", category = "Beds", cost = 120 }, -- MW
	["351"] = { id = "furn_de_rope_04", newId = "jsmk_fc_furn_de_rope_04", name = "Rope", category = "Ropes", cost = 10 }, -- MW
	["352"] = { id = "furn_de_tapestry_01", newId = "jsmk_fc_furn_de_tapestry_01", name = "Tapestry, Purple", category = "Tapestries", cost = 120 }, -- MW
	["353"] = { id = "light_sconce10", newId = "jsmk_fc_light_sconce10", name = "Sconce, Rusty", category = "Lights", cost = 10 }, -- MW
	["354"] = { id = "flora_stoneflower_01", newId = "jsmk_fc_flora_stoneflower_01", name = "Stoneflower", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["355"] = { id = "flora_willow_flower_01", newId = "jsmk_fc_flora_willow_flower_01", name = "Willow flower", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["356"] = { id = "light_com_candle_04", newId = "jsmk_fc_light_com_candle_04", name = "Candles Three Blue, Orange Flame", category = "Lights", cost = 3 }, -- MW
	["357"] = { id = "ab_furn_deeggcrateopen", newId = "jsmk_fc_ab_furn_deeggcrateopen", name = "Kwama Egg Crate, Open", category = "Crates", cost = 20 }, -- MW
	["358"] = { id = "ab_furn_ropeverticallong", newId = "jsmk_fc_abfurn_ropeverticallong", name = "Rope, Extremely Long", category = "Ropes", cost = 20 }, -- MW
	["359"] = { id = "ab_light_delantpapergrn03_256", newId = "jsmk_ablightdelantpapergrn03256", name = "Paper Lantern, Green", category = "Lights", cost = 12 }, -- OAAB
	["360"] = { id = "ab_o_barrel02group", newId = "jsmk_fc_ab_o_barrel02group", name = "Stack of Barrels", category = "Containers", cost = 1500 }, -- OAAB
	["361"] = { id = "flora_fire_fern_02", newId = "jsmk_fc_flora_fire_fern_02", name = "Fire Fern", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["362"] = { id = "nm_red_banner_s", newId = "jsmk_fc_nm_red_banner_s", name = "Banner, Redoran", category = "Tapestries", cost = 100 }, -- N'Wah and Mushroom Team
	["363"] = { id = "ab_furn_comcandlered02", newId = "jsmk_fc_ab_furn_comcandlered02", name = "Candle, Red", category = "Lights", cost = 12 }, -- OAAB
	["364"] = { id = "com_sack_02", newId = "jsmk_fc_com_sack_02", name = "Sack, Round", category = "Containers", cost = 6 }, -- MW
	["365"] = { id = "flora_black_anther_01", newId = "jsmk_fc_flora_black_anther_01", name = "Black Anther", category = "Plants", cost = 100 }, -- MW
	["366"] = { id = "flora_muckspunge_01", newId = "jsmk_fc_flora_muckspunge_01", name = "Muckspunge", category = "Plants", cost = 100, scale = 0.5 }, -- MW
	["367"] = { id = "furn_com_cauldron_02", newId = "jsmk_fc_furn_com_cauldron_02", name = "Cauldron", category = "Other", cost = 100 }, -- MW
	["368"] = { id = "t_mw_flora_bluefoot02", newId = "jsmk_fc_t_mw_flora_bluefoot02", name = "Bluefoot", category = "Plants", cost = 100, deprecated = true }, -- TR
	["369"] = { id = "t_mw_flora_munzur_01", newId = "jsmk_fc_t_mw_flora_munzur_01", name = "Munzur", category = "Plants", cost = 100 }, -- TR
	["371"] = { id = "t_mw_flora_terrastree_02", newId = "jsmk_fc_tmw_flora_terrastree_02", name = "Terras Tree", category = "Plants", cost = 100, scale = 1.4 }, -- TR
	["372"] = { id = "t_mw_flora_treecine_05", newId = "jsmk_fc_t_mw_flora_treecine_05", name = "Cine Tree", category = "Plants", cost = 100, scale = 1.4 }, -- TR
	["373"] = { id = "ex_de_railing_01", newId = "jsmk_fc_ex_de_railing_01", name = "Railing", category = "Ropes", cost = 10 }, -- MW
	["374"] = { id = "ex_de_railing_03", newId = "jsmk_fc_ex_de_railing_03", name = "Railing Pole", category = "Ropes", cost = 10 }, -- MW
	["375"] = { id = "ex_hlaalu_pole_01", newId = "jsmk_fc_ex_hlaalu_pole_01", name = "Pole, Horizontal", category = "Structures", cost = 10 }, -- MW
	["376"] = { id = "ex_hlaalu_pole_02", newId = "jsmk_fc_ex_hlaalu_pole_02", name = "Pole, Vertical", category = "Structures", cost = 10 }, -- MW
	["377"] = { id = "flora_emp_parasol_03", newId = "jsmk_fc_flora_emp_parasol_03", name = "Emperpr Parasol", category = "Plants", cost = 100 }, -- MW
	["379"] = { id = "t_com_setfarm_box_01", newId = "jsmk_fc_t_com_setfarm_box_01", name = "Box, Farmer's", category = "Other", cost = 5 }, -- PC
	["380"] = { id = "t_com_var_cauldron_02", newId = "jsmk_fc_t_com_var_cauldron_02", name = "Cauldron", category = "Other", cost = 100 }, -- SKY
	["381"] = { id = "t_com_var_nail_01", newId = "jsmk_fc_t_com_var_nail_01", name = "Nail", category = "Other", cost = 1, scale = 1.35 }, -- TR
	["382"] = { id = "t_cyr_flora_aloevera02", newId = "jsmk_fc_t_cyr_flora_aloevera02", name = "Aloe Vera", category = "Plants", cost = 100 }, -- PC
	["383"] = { id = "t_de_set_cart_01", newId = "jsmk_fc_t_de_set_cart_01", name = "Cart", category = "Other", cost = 100 }, -- TR
	["384"] = { id = "flora_plant_04", newId = "jsmk_fc_flora_plant_04", name = "Meadow Rye", category = "Plants", cost = 100, scale = 0.7 }, -- MW
	["385"] = { id = "furn_de_pathspear_04", newId = "jsmk_fc_furn_de_pathspear_04", name = "Pathspear", category = "Ropes", cost = 10 }, -- MW
	["386"] = { id = "light_de_lantern_03", newId = "jsmk_fc_light_de_lantern_03", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- MW
	["387"] = { id = "t_com_var_souppot_01", newId = "jsmk_fc_t_com_var_souppot_01", name = "Soup Pot", category = "Other", cost = 100 }, -- MW
	["388"] = { id = "t_de_furn_tapestry_08", newId = "jsmk_fc_t_de_furn_tapestry_08", name = "Tapestry", category = "Tapestries", cost = 120 }, -- TR
	["389"] = { id = "t_de_furn_tapestry_05", newId = "jsmk_fc_t_de_furn_tapestry_05", name = "Tapestry", category = "Tapestries", cost = 120 }, -- TR
	["390"] = { id = "t_de_furn_tapestry_21", newId = "jsmk_fc_t_de_furn_tapestry_21", name = "Tapestry", category = "Tapestries", cost = 120 }, -- TR
	["391"] = { id = "t_mw_flora_blackrose02", newId = "jsmk_fc_t_mw_flora_blackrose02", name = "Black Rose", category = "Plants", cost = 100 }, -- TR
	["392"] = { id = "t_mw_flora_hornlilly01", newId = "jsmk_fc_t_mw_flora_hornlilly01", name = "Horn Lily", category = "Plants", cost = 100, deprecated = true }, -- TR
	["393"] = { id = "t_mw_flora_nirthfly01", newId = "jsmk_fc_t_mw_flora_nirthfly01", name = "Nirthfly Stalks", category = "Plants", cost = 100, deprecated = true }, -- TR
	["394"] = { id = "de_r_chest_01", newId = "jsmk_fc_de_r_chest_01", name = "Chest, Expensive", category = "Containers", cost = 200 }, -- MW
	["395"] = { id = "ab_o_comchestironempty", newId = "jsmk_fc_ab_o_comchestironempty", name = "Small Iron Box", category = "Containers", cost = 100 }, -- OAAB
	["399"] = { id = "ab_light_delantpaperred03_256", newId = "jsmk_ablightdelantpaperred03256", name = "Paper Lantern, Red", category = "Lights", cost = 12 }, -- OAAB
	["400"] = { id = "ab_light_delantpaperblu03_256", newId = "jsmk_ablightdelantpaperblu03256", name = "Paper Lantern, Blue", category = "Lights", cost = 12 }, -- OAAB
	["401"] = { id = "ab_light_comcandlebluebf01_128", newId = "jsmkablightcomcandlebluebf01128", name = "Candle Blue, Blue Flame", category = "Lights", cost = 12 }, -- OAAB
	["402"] = { id = "ab_light_comcandleblue02_128", newId = "jsmk_fablightcomcandleblue02128", name = "Candle Blue, Orange Flame", category = "Lights", cost = 12 }, -- OAAB
	["403"] = { id = "ab_ex_depalisadegateframe", newId = "jsmk_fc_abexdepalisadegateframe", name = "Palisade Gate Frame", category = "Structures", cost = 100 }, -- OAAB
	["404"] = { id = "ab_furn_candlewaxblue02", newId = "jsmk_fc_ab_furn_candlewaxblue02", name = "Candle Wax, Blue", category = "Lights", cost = 6 }, -- OAAB
	["405"] = { id = "ab_furn_candlewaxblue03", newId = "jsmk_fc_ab_furn_candlewaxblue03", name = "Candle Wax, Blue", category = "Lights", cost = 6 }, -- OAAB
	["406"] = { id = "ab_ex_depalisadepole03", newId = "jsmk_fc_ab_ex_depalisadepole03", name = "Palisade Pole", category = "Structures", cost = 20 }, -- OAAB
	["407"] = { id = "ab_furn_ropebase", newId = "jsmk_fc_ab_furn_ropebase", name = "Rope", category = "Ropes", cost = 10 }, -- OAAB
	["408"] = { id = "ab_furn_ropecoil", newId = "jsmk_fc_ab_furn_ropecoil", name = "Coil of Rope", category = "Ropes", cost = 30 }, -- OAAB   
	["409"] = { id = "ab_furn_ropetiesmall", newId = "jsmk_fc_ab_furn_ropetiesmall", name = "Rope Tie", category = "Ropes", cost = 10, scale = 0.75 }, -- OAAB   
	["410"] = { id = "ex_coiled_rope", newId = "jsmk_fc_ex_coiled_rope", name = "Coiled Rope", category = "Ropes", cost = 5 }, -- MW
	["411"] = { id = "t_de_set_bannersaintvivec_02", newId = "jsmk_fctdesetbannersaintvivec02", name = "Banner, Saint Vivec", category = "Tapestries", cost = 100, scale = 2 }, -- TR
	["412"] = { id = "@nb_red_flag", newId = "jsmk_fc_@nb_red_flag", name = "Flag, Red", category = "Tapestries", cost = 10 }, -- BCOM, We will go to mount Assarnibibi
	["413"] = { id = "@nb_yel_flag", newId = "jsmk_fc_@nb_yel_flag", name = "Flag, Yellow", category = "Tapestries", cost = 10 }, -- BCOM, We will go to mount Assarnibibi
	["414"] = { id = "@nb_blue_flag", newId = "jsmk_fc_@nb_blue_flag", name = "Flag, Blue", category = "Tapestries", cost = 10 }, -- BCOM, We will go to mount Assarnibibi
	["396"] = { id = "kal_red_flag", newId = "jsmk_fc_kal_red_flag", name = "Flag, Red", category = "Tapestries", cost = 10, base = "@nb_red_flag" }, -- The Mountain of Fear
	["397"] = { id = "kal_yel_flag", newId = "jsmk_fc_kal_yel_flag", name = "Flag, Yellow", category = "Tapestries", cost = 10, base = "@nb_yel_flag" }, -- The Mountain of Fear
	["398"] = { id = "kal_blue_flag", newId = "jsmk_fc_kal_blue_flag", name = "Flag, Blue", category = "Tapestries", cost = 10, base = "@nb_blue_flag" }, -- The Mountain of Fear
	["415"] = { id = "ab_furn_ropewashsusp01", newId = "jsmk_fc_ab_furn_ropewashsusp01", name = "Clothes Line", category = "Ropes", cost = 50 }, -- OAAB
	["416"] = { id = "ab_ex_deshackladder", newId = "jsmk_fc_ab_ex_deshackladder", name = "Ladder", category = "Structures", cost = 60 }, -- OAAB
	["417"] = { id = "ex_de_docks_center", newId = "jsmk_fc_ex_de_docks_center", name = "Docks, Center", category = "Structures", cost = 60 }, -- MW
	["418"] = { id = "ex_de_docks_end", newId = "jsmk_fc_ex_de_docks_end", name = "Docks, End", category = "Structures", cost = 60 }, -- MW
	["419"] = { id = "ex_de_oar", newId = "jsmk_fc_ex_de_oar", name = "Oar", category = "Other", cost = 10 }, -- MW
	["420"] = { id = "ex_de_rowboat", newId = "jsmk_fc_ex_de_rowboat", name = "Rowboat", category = "Other", cost = 100 }, -- MW
	["421"] = { id = "ex_ship_plank", newId = "jsmk_fc_ex_ship_plank", name = "Ship Plank", category = "Structures", cost = 10 }, -- MW
	["422"] = { id = "flora_bc_tree_01", newId = "jsmk_fc_flora_bc_tree_01", name = "Tree, Bitter Coast", category = "Plants", cost = 200 }, -- MW
	["423"] = { id = "ab_o_cratehlaalu", newId = "jsmk_fc_ab_o_cratehlaalu", name = "Crate, Hlaalu", category = "Crates", cost = 100 }, -- OAAB
	["424"] = { id = "ab_o_cratefg", newId = "jsmk_fc_ab_o_cratefg", name = "Crate, Fighters' Guild", category = "Crates", cost = 100 }, -- OAAB
	["425"] = { id = "ab_light_delantpaper02_256", newId = "jsmk_fc_ablightdelantpaper02256", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- OAAB
	["427"] = { id = "ab_furn_deplnrug01", newId = "jsmk_fc_ab_furn_deplnrug01", name = "Rug, Yellow Ruined", category = "Rugs", cost = 30 }, -- OAAB
	["428"] = { id = "ab_light_telexballlamp01_256", newId = "jsmk_fablighttelexballlamp01256", name = "Lamp, Telvanni Ball", category = "Lights", cost = 100 }, -- OAAB
	["429"] = { id = "ab_light_telexballspike_300", newId = "jsmk_fcablighttelexballspike300", name = "Lamp, Telvanni Ball Spike", category = "Lights", cost = 100 }, -- OAAB
	["430"] = { id = "ab_light_delantpaperblu02_256", newId = "jsmk_ablightdelantpaperblu02256", name = "Paper Lantern, Blue", category = "Lights", cost = 12 }, -- OAAB
	["431"] = { id = "ab_flora_telshroom01", newId = "jsmk_fc_ab_flora_telshroom01", name = "Telvanni Mushroom", category = "Structures", cost = 100 }, -- OAAB
	["432"] = { id = "flora_t_mushroom_01", newId = "jsmk_fc_flora_t_mushroom_01", name = "Telvanni Mushroom", category = "Structures", cost = 100 }, -- MW
	["433"] = { id = "flora_t_shelffungus_01", newId = "jsmk_fc_flora_t_shelffungus_01", name = "Telvanni Mushroom", category = "Structures", cost = 100 }, -- MW
	["434"] = { id = "ab_ex_telplatformroundflat", newId = "jsmk_fcabextelplatformroundflat", name = "Telvanni Platform", category = "Structures", cost = 100 }, -- MW
	["435"] = { id = "ab_ex_telplanter", newId = "jsmk_fc_ab_ex_telplanter", name = "Telvanni Planter", category = "Planters", cost = 100 }, -- OAAB
	["436"] = { id = "flora_t_mushroom_02", newId = "jsmk_fc_flora_t_mushroom_02", name = "Telvanni Mushroom", category = "Structures", cost = 100 }, -- MW
	["437"] = { id = "ex_t_hook", newId = "jsmk_fc_ex_t_hook", name = "Telvanni Hook", category = "Structures", cost = 100 }, -- MW
	["438"] = { id = "ab_ex_telrootbranchsmall", newId = "jsmk_fc_abex_telrootbranchsmall", name = "Telvanni Root", category = "Structures", cost = 100 }, -- OAAB
	["439"] = { id = "ab_f_comberryhbundle", newId = "jsmk_fc_ab_f_comberryhbundle", name = "Comberry Hanging Bundle", category = "Plants", cost = 100 }, -- OAAB
	["440"] = { id = "ab_light_telinballlamp01_256", newId = "jsmk_fablighttelinballlamp01256", name = "Lamp, Telvanni Ball", category = "Lights", cost = 100 }, -- OAAB
	["442"] = { id = "furn_uni_weaponrack_01", newId = "jsmk_fc_furn_uni_weaponrack_01", name = "Weapon Rack", category = "Other", cost = 100 }, -- MW
	["443"] = { id = "rpnr_ashl_weapon_rack", newId = "jsmk_fc_rpnr_ashl_weapon_rack", name = "Weapon Rack, Ashlander", category = "Other", cost = 100 }, -- BCOM
	["444"] = { id = "rpnr_dr_asrt_p_f_bookcase_02", newId = "jsmk_fc_rpnrdrasrtpfbookcase_02", name = "Shelves", category = "Other", cost = 100 }, -- BCOM
	["445"] = { id = "t_imp_furnm_weaponrack_01", newId = "jsmk_fc_timpfurnm_weaponrack_01", name = "Weapon Rack", category = "Other", cost = 100 }, -- TR
	["446"] = { id = "ab_o_comrchdeskempty", newId = "jsmk_fc_ab_o_comrchdeskempty", name = "Desk, Cherry Wood", category = "Containers", cost = 2005 }, -- OAAB
	["447"] = { id = "active_de_r_bed_19", newId = "jsmk_fc_active_de_r_bed_19", name = "Single Bed, Swirlwood Red", category = "Beds", cost = 150 }, -- MW
	["448"] = { id = "furn_de_r_shelf_01", newId = "jsmk_fc_furn_de_r_shelf_01", name = "Shelf, Cherry Wood", category = "Shelves", cost = 60 }, -- MW
	["449"] = { id = "furn_de_r_wallscreen_01", newId = "jsmk_fc_furn_de_r_wallscreen_01", name = "Wallscreen, Oldwood", category = "Other", cost = 100 }, -- MW
	["450"] = { id = "furn_hook_01", newId = "jsmk_fc_furn_hook_01", name = "Hook, Iron", category = "Other", cost = 10 }, -- MW
	["451"] = { id = "light_de_candle_09", newId = "jsmk_fc_light_de_candle_09", name = "Candle, White", category = "Lights", cost = 12 }, -- MW
	["452"] = { id = "light_de_lamp_01", newId = "jsmk_fc_light_de_lamp_01", name = "Lamp, White", category = "Lights", cost = 20 }, -- MW
	["453"] = { id = "light_de_lantern_05_s", newId = "jsmk_fc_light_de_lantern_05_s", name = "Paper Lantern, Orange", category = "Lights", cost = 12 }, -- MW
	["454"] = { id = "nb_hla_01_big", newId = "jsmk_fc_nb_hla_01_big", name = "Rug, Hlaalu Big", category = "Rugs", cost = 60, scale = 1.3 }, -- BCOM
	["455"] = { id = "nb_hla_03_sm", newId = "jsmk_fc_nb_hla_03_sm", name = "Rug, Hlaalu Small", category = "Rugs", cost = 60 }, -- BCOM
	["456"] = { id = "t_de_furn_rugsmall_06", newId = "jsmk_fc_t_de_furn_rugsmall_06", name = "Rug, Bug", category = "Rugs", cost = 60 }, -- TR
	["457"] = { id = "t_com_furn_bedstraw_01", newId = "jsmk_fc_t_com_furn_bedstraw_01", name = "Straw Bed, Nordic", category = "Beds", cost = 100 }, -- SKY
	["458"] = { id = "t_skycom_var_cr7empty", newId = "jsmk_fc_t_skycom_var_cr7empty", name = "Crate, Nordic Small", category = "Crates", cost = 10 }, -- SKY
	["459"] = { id = "t_skycom_var_cr2empty", newId = "jsmk_fc_t_skycom_var_cr2empty", name = "Crate, Nordic Large", category = "Crates", cost = 10 }, -- SKY
	["460"] = { id = "t_skyrea_furn_ch1empty", newId = "jsmk_fc_t_skyrea_furn_ch1empty", name = "Chest, Wicher Reachman", category = "Containers", cost = 50 }, -- SKY
	["461"] = { id = "t_skycom_var_sk3empty", newId = "jsmk_fc_t_skycom_var_sk3empty", name = "Sack, Nordic Round", category = "Containers", cost = 6 }, -- SKY
	["462"] = { id = "t_skycom_var_sk2empty", newId = "jsmk_fc_t_skycom_var_sk2empty", name = "Sack, Nordic", category = "Containers", cost = 6 }, -- SKY
	["463"] = { id = "t_skycom_var_sk4empty", newId = "jsmk_fc_t_skycom_var_sk4empty", name = "Sack, Nordic Vertical", category = "Containers", cost = 6 }, -- SKY
	["464"] = { id = "t_com_furn_peltbristleback_01", newId = "jsmk_ftcomfurnpeltbristleback01", name = "Pelt, Faux Bristleback", category = "Tapestries", cost = 120 }, -- SKY
	["465"] = { id = "t_rea_set_i_ladder_01", newId = "jsmk_fc_t_rea_set_i_ladder_01", name = "Ladder, Reachman", category = "Structures", cost = 100, scale = 0.98 }, -- SKY
	["466"] = { id = "t_rea_set_i_planks_01", newId = "jsmk_fc_t_rea_set_i_planks_01", name = "Planks, Reachman", category = "Structures", cost = 100 }, -- SKY
	["467"] = { id = "t_rea_furn_rug_01", newId = "jsmk_fc_t_rea_furn_rug_01", name = "Rug, Ropes Long", category = "Rugs", cost = 60 }, -- SKY
	["468"] = { id = "t_rea_furn_rugwormmouth_01", newId = "jsmk_fc_t_reafurnrugwormmouth01", name = "Rug, Faux Wormmouth", category = "Rugs", cost = 60 }, -- SKY
	["469"] = { id = "t_rea_set_f_rope_01", newId = "jsmk_fc_t_rea_set_f_rope_01", name = "Rope, Reachman", category = "Ropes", cost = 10 }, -- SKY
	["470"] = { id = "t_rea_set_x_ropedpole_02", newId = "jsmk_fc_t_rea_set_x_ropedpole02", name = "Roped Pole", category = "Ropes", cost = 50 }, -- SKY
	["471"] = { id = "t_rea_set_x_fence_02", newId = "jsmk_fc_t_rea_set_x_fence_02", name = "Fence", category = "Structures", cost = 50 }, -- SKY
	["472"] = { id = "t_nor_furn_dreamcatcher_06", newId = "jsmk_fc_t_norfurndreamcatcher06", name = "Dreamcatcher, Nordic", category = "Other", cost = 50 }, -- SKY
	["473"] = { id = "t_nor_var_traywooden_03", newId = "jsmk_fc_t_nor_var_traywooden_03", name = "Wooden Tray, Nordic", category = "Other", cost = 10 }, -- SKY
	["474"] = { id = "t_com_furn_peltgoat_01", newId = "jsmk_ftcomfurnpeltgoat01", name = "Pelt, Faux Goat", category = "Tapestries", cost = 120 }, -- SKY
	["475"] = { id = "t_com_furn_peltcowtattered_01", newId = "jsmk_ftcomfurnpeltcowtattered01", name = "Pelt, Faux Cow", category = "Tapestries", cost = 120 }, -- SKY
	["476"] = { id = "t_rea_set_x_basketmagic_01", newId = "jsmk_fc_t_rea_setxbasketmagic01", name = "Magic Basket, Reachman", category = "Other", cost = 100 }, -- SKY
	["477"] = { id = "t_nor_var_woodhook_01", newId = "jsmk_fc_t_nor_var_woodhook_01", name = "Hook, Wooden", category = "Other", cost = 10 }, -- SKY
	["478"] = { id = "t_nor_var_basket_02", newId = "jsmk_fc_t_nor_var_basket_02", name = "Basket, Nordic Wicker Small", category = "Other", cost = 60 }, -- SKY
	["479"] = { id = "t_glb_var_skeletoncattlebone_02", newId = "jsmktglbvarskeletoncattlebone02", name = "Bone, Cattle", category = "Other", cost = 10 }, -- SKY
	["480"] = { id = "t_glb_var_skeletoncattleskul_01", newId = "jsmktglbvarskeletoncattleskul01", name = "Skull, Cattle", category = "Other", cost = 100 }, -- SKY
	["481"] = { id = "t_nor_var_basket_03", newId = "jsmk_fc_t_nor_var_basket_03", name = "Basket, Nordic Wicker Large", category = "Other", cost = 80 }, -- SKY
	["482"] = { id = "t_nor_var_basketwood_01", newId = "jsmk_fc_t_nor_var_basketwood_01", name = "Basket, Nordic Wooden", category = "Other", cost = 80 }, -- SKY
	["483"] = { id = "t_rea_furn_tapestry_01", newId = "jsmk_fc_t_rea_furn_tapestry_01", name = "Tapestry, Reachman Blue", category = "Tapestries", cost = 120 }, -- SKY
	["484"] = { id = "t_rea_furn_tapestry_02", newId = "jsmk_fc_t_rea_furn_tapestry_02", name = "Tapestry, Reachman Red", category = "Tapestries", cost = 120 }, -- SKY
	["485"] = { id = "t_mwde_furnm_ch1empty", newId = "jsmk_fc_t_mwde_furnm_ch1empty", name = "Chest, Expensive", category = "Containers", cost = 15 }, -- TR
	["486"] = { id = "t_de_furnm_shelf_01", newId = "jsmk_fc_t_de_furnm_shelf_01", name = "Shelf, Expensive", category = "Shelves", cost = 60 }, -- TR
	["487"] = { id = "t_de_furn_rug_18", newId = "jsmk_fc_t_de_furn_rug_18", name = "Rug, Large Oval Red", category = "Rugs", cost = 120 }, -- MW
	["488"] = { id = "pot_01", newId = "jsmk_fc_pot_01", name = "Pot", category = "Containers", cost = 60 }, -- MW
	["489"] = { id = "t_de_furn_bed_10", newId = "jsmk_fc_t_de_furn_bed_10", name = "Double Bed, Aqua", category = "Beds", cost = 300 }, -- TR
	["490"] = { id = "de_r_closet_01", newId = "jsmk_fc_de_r_closet_01", name = "Closet, Swirlwood", category = "Containers", cost = 400 }, -- MW
	["491"] = { id = "flora_plant_03", newId = "jsmk_fc_flora_plant_03", name = "Timsa-Come-By Flowers", category = "Plants", cost = 100, scale = 0.63 }, -- MW
	["492"] = { id = "flora_sedge_02", newId = "jsmk_fc_flora_sedge_02", name = "Noble Sedge", category = "Plants", cost = 100 }, -- MW
	["493"] = { id = "furn_de_tapestry_04", newId = "jsmk_fc_furn_de_tapestry_04", name = "Tapestry, Red", category = "Tapestries", cost = 120 }, -- MW
	["494"] = { id = "light_ashl_lantern_04", newId = "jsmk_fc_light_ashl_lantern_04", name = "Lantern, Ashlanders Purple", category = "Lights", cost = 12 }, -- MW 
	["495"] = { id = "furn_ashl_bugbowl_01", newId = "jsmk_fc_furn_ashl_bugbowl_01", name = "Bug Bowl, Ashlanders Blue", category = "Other", cost = 40 }, -- MW
	["496"] = { id = "st_bed_p05", newId = "jsmk_fc_st_bed_p05", name = "Single Bed, Oldwood Baige", category = "Beds", cost = 200 }, -- Pillow Mage Manor 
	["497"] = { id = "active_de_r_bed_17", newId = "jsmk_fc_active_de_r_bed_17", name = "Single Bed, Swirlwood Blue", category = "Beds", cost = 150 }, -- MW
	["498"] = { id = "furn_com_kegstand", newId = "jsmk_fc_furn_com_kegstand", name = "Kegstand", category = "Water", cost = 100 }, -- MW
	["499"] = { id = "furn_de_r_bench_02", newId = "jsmk_fc_furn_de_r_bench_02", name = "Bench, Swirlwood Small", category = "Seats", cost = 35 }, -- MW
	["500"] = { id = "st_furn_de_r_chair_02", newId = "jsmk_fc_st_furn_de_r_chair_02", name = "Chair, Swirlwood", category = "Seats", cost = 120 }, -- Pillow Mage Manor
	["501"] = { id = "st_waterbarrel_half", newId = "jsmk_fc_st_waterbarrel_half", name = "Basin", category = "Water", cost = 40 }, -- Pillow Mage Manor, PlaySound "FootWaterRight"
	["502"] = { id = "de_p_table_01", newId = "jsmk_fc_de_p_table_01", name = "End Table, Cheap", category = "Containers", cost = 75 }, -- MW
	["503"] = { id = "st_ac_de_r_sideboard", newId = "jsmk_fc_st_ac_de_r_sideboard", name = "Sideboard, Swirlwood", category = "Containers", cost = 240 }, -- MW
	["504"] = { id = "com_hutch_01_placemats", newId = "jsmk_fc_com_hutch_01_placemats", name = "Hutch, Cheap", category = "Containers", cost = 240 }, -- MW 
	["505"] = { id = "com_cupboard_01", newId = "jsmk_fc_com_cupboard_01", name = "Cupboard", category = "Containers", cost = 120 }, -- MW 
	["506"] = { id = "st_ac_kb_sewtable_de_p", newId = "jsmk_fc_st_ac_kb_sewtable_de_p", name = "Sewing Table", category = "Containers", cost = 300 }, -- Pillow Mage Manor 
	["507"] = { id = "light_com_chandelier_03", newId = "jsmk_fc_light_com_chandelier_03", name = "Chandelier, Brown Wood", category = "Lights", cost = 100 }, -- MW
	["508"] = { id = "light_de_candle_04", newId = "jsmk_fc_light_de_candle_04", name = "Candle, White", category = "Lights", cost = 12 }, -- MW
	["509"] = { id = "light_de_lamp_02", newId = "jsmk_fc_light_de_lamp_02", name = "Lamp, Blue", category = "Lights", cost = 20 }, -- MW
	["510"] = { id = "light_de_lantern_08", newId = "jsmk_fc_light_de_lantern_08", name = "Paper Lantern, Blue", category = "Lights", cost = 12 }, -- MW
	["511"] = { id = "furn_com_rm_bench_02", newId = "jsmk_fc_furn_com_rm_bench_02", name = "Bench", category = "Seats", cost = 40 }, -- MW
	["512"] = { id = "furn_de_r_table_08", newId = "jsmk_fc_furn_de_r_table_08", name = "Table, Swirlwood Round", category = "Tables", cost = 140 }, -- MW
	["513"] = { id = "furn_de_r_winerack", newId = "jsmk_fc_furn_de_r_winerack", name = "Winerack, Swirlwood", category = "Shelves", cost = 300 }, -- MW
	["514"] = { id = "st_cushion_rnd_01_stat", newId = "jsmk_fc_st_cushion_rnd_01_stat", name = "Cushion, Tan Quilted Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["515"] = { id = "st_cushion_rnd_02_stat", newId = "jsmk_fc_st_cushion_rnd_02_stat", name = "Cushion, Green Damask Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["516"] = { id = "st_cushion_rnd_03_stat", newId = "jsmk_fc_st_cushion_rnd_03_stat", name = "Cushion, Red Brocade Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["517"] = { id = "st_cushion_rnd_04_stat", newId = "jsmk_fc_st_cushion_rnd_04_stat", name = "Cushion, Red Ghiordes Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["518"] = { id = "st_cushion_rnd_05_stat", newId = "jsmk_fc_st_cushion_rnd_05_stat", name = "Cushion, Teal Damask Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["519"] = { id = "st_cushion_rnd_06_stat", newId = "jsmk_fc_st_cushion_rnd_06_stat", name = "Cushion, Tan Diamond Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["520"] = { id = "st_cushion_rnd_07_stat", newId = "jsmk_fc_st_cushion_rnd_07_stat", name = "Cushion, Tan Medallion Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["521"] = { id = "st_cushion_rnd_08_stat", newId = "jsmk_fc_st_cushion_rnd_08_stat", name = "Cushion, Blue Shell Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["522"] = { id = "st_cushion_rnd_09_stat", newId = "jsmk_fc_st_cushion_rnd_09_stat", name = "Cushion, Blue Floral Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["523"] = { id = "st_cushion_rnd_10_stat", newId = "jsmk_fc_st_cushion_rnd_10_stat", name = "Cushion, Red Suzani Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["524"] = { id = "st_cushion_rnd_11_stat", newId = "jsmk_fc_st_cushion_rnd_11_stat", name = "Cushion, Green Nrocade Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["525"] = { id = "st_cushion_rnd_12_stat", newId = "jsmk_fc_st_cushion_rnd_12_stat", name = "Cushion, Brown Quilted Round", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["526"] = { id = "st_cushion_sq_01_stat", newId = "jsmk_fc_st_cushion_sq_01_stat", name = "Cushion, Tan Quilted Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["527"] = { id = "st_cushion_sq_02_stat", newId = "jsmk_fc_st_cushion_sq_02_stat", name = "Cushion, Green Damask Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["528"] = { id = "st_cushion_sq_03_stat", newId = "jsmk_fc_st_cushion_sq_03_stat", name = "Cushion, Red Brocade Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["529"] = { id = "st_cushion_sq_04_stat", newId = "jsmk_fc_st_cushion_sq_04_stat", name = "Cushion, Red Ghiordes Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["530"] = { id = "st_cushion_sq_05_stat", newId = "jsmk_fc_st_cushion_sq_05_stat", name = "Cushion, Teal Damask Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["531"] = { id = "st_cushion_sq_06_stat", newId = "jsmk_fc_st_cushion_sq_06_stat", name = "Cushion, Tan Diamond Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["532"] = { id = "st_cushion_sq_07_stat", newId = "jsmk_fc_st_cushion_sq_07_stat", name = "Cushion, Tan Medallion Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["533"] = { id = "st_cushion_sq_08_stat", newId = "jsmk_fc_st_cushion_sq_08_stat", name = "Cushion, Blue Shell Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["534"] = { id = "st_cushion_sq_09_stat", newId = "jsmk_fc_st_cushion_sq_09_stat", name = "Cushion, Blue Floral Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["535"] = { id = "st_cushion_sq_10_stat", newId = "jsmk_fc_st_cushion_sq_10_stat", name = "Cushion, Red Suzani Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["536"] = { id = "st_cushion_sq_11_stat", newId = "jsmk_fc_st_cushion_sq_11_stat", name = "Cushion, Green Nrocade Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["537"] = { id = "st_cushion_sq_12_stat", newId = "jsmk_fc_st_cushion_sq_12_stat", name = "Cushion, Brown Quilted Square", category = "Cushions", cost = 30 }, -- Pillow Mage Manor
	["538"] = { id = "st_furn_de_r_barstool", newId = "jsmk_fc_st_furn_de_r_barstool", name = "Barstool, Swirlwood", category = "Seats", cost = 60 }, -- Pillow Mage Manor
	["539"] = { id = "st_furn_de_r_stool_02", newId = "jsmk_fc_st_furn_de_r_stool_02", name = "Stool, Swirlwood", category = "Seats", cost = 50 }, -- Pillow Mage Manor
	["540"] = { id = "st_furn_de_r_table_02", newId = "jsmk_fc_st_furn_de_r_table_02", name = "End Table, Swirlwood", category = "Tables", cost = 70 }, -- Pillow Mage Manor
	["541"] = { id = "st_pillow_r08_stat", newId = "jsmk_fc_st_pillow_r08_stat", name = "Pillow, Green", category = "Pillows", cost = 30 }, -- Pillow Mage Manor
	["542"] = { id = "st_pillow_r09_stat", newId = "jsmk_fc_st_pillow_r09_stat", name = "Pillow, Tan", category = "Pillows", cost = 30 }, -- Pillow Mage Manor
	["543"] = { id = "st_pillow_r10_stat", newId = "jsmk_fc_st_pillow_r10_stat", name = "Pillow, Green", category = "Pillows", cost = 30 }, -- Pillow Mage Manor
	["544"] = { id = "st_pillow_r11_stat", newId = "jsmk_fc_st_pillow_r11_stat", name = "Pillow, Red", category = "Pillows", cost = 30 }, -- Pillow Mage Manor
	["545"] = { id = "st_pillow_r12_stat", newId = "jsmk_fc_st_pillow_r12_stat", name = "Pillow, Blue", category = "Pillows", cost = 30 }, -- Pillow Mage Manor
	["546"] = { id = "st_rug_02_stat", newId = "jsmk_fc_st_rug_02_stat", name = "Rug, Green Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["547"] = { id = "st_rug_04_stat", newId = "jsmk_fc_st_rug_04_stat", name = "Rug, Blue Shell", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["548"] = { id = "st_rug_05_stat", newId = "jsmk_fc_st_rug_05_stat", name = "Rug, Blue Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["549"] = { id = "st_rug_08_stat", newId = "jsmk_fc_st_rug_08_stat", name = "Rug, Grey Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["550"] = { id = "st_rug_07_stat", newId = "jsmk_fc_st_rug_07_stat", name = "Rug, Gold Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["551"] = { id = "st_rug_13_stat", newId = "jsmk_fc_st_rug_13_stat", name = "Rug, Gold Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["552"] = { id = "st_rug_14_stat", newId = "jsmk_fc_st_rug_14_stat", name = "Rug, Blue Floral", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["553"] = { id = "st_rug_18_stat", newId = "jsmk_fc_st_rug_18_stat", name = "Rug, Gold Brocade", category = "Rugs", cost = 60 }, -- Pillow Mage Manor
	["554"] = { id = "st_tapestry_01", newId = "jsmk_fc_st_tapestry_01", name = "Tapestry, Tan Quilted", category = "Tapestries", cost = 120 }, -- Pillow Mage Manor
	["555"] = { id = "st_tapestry_04", newId = "jsmk_fc_st_tapestry_04", name = "Tapestry, Blue Floral", category = "Tapestries", cost = 120 }, -- Pillow Mage Manor
	["556"] = { id = "st_tapestry_10", newId = "jsmk_fc_st_tapestry_10", name = "Tapestry, Red Floral", category = "Tapestries", cost = 120 }, -- Pillow Mage Manor
	["557"] = { id = "st_tapestry_11", newId = "jsmk_fc_st_tapestry_11", name = "Tapestry, Green Floral", category = "Tapestries", cost = 120 }, -- Pillow Mage Manor
	["558"] = { id = "st_tapestry_15", newId = "jsmk_fc_st_tapestry_15", name = "Tapestry, Gold Floral", category = "Tapestries", cost = 120 }, -- Pillow Mage Manor

	["559"] = { id = "t_nor_furnp_bed_01", newId = "jsmk_fc_t_nor_furnp_bed_01", name = "Single Bed, Nordic Blue", category = "Beds", cost = 60 }, -- SKY
	["560"] = { id = "contain_bm_belladonna_0", newId = "jsmk_fc_contain_bm_belladonna_0", name = "Belladonna Hanging Bundle", category = "Plants", cost = 100 }, -- MW
	["561"] = { id = "flora_bm_belladonna_03", newId = "jsmk_fc_flora_bm_belladonna_03", name = "Ripened Belladonna", category = "Plants", cost = 100 }, -- MW
	["562"] = { id = "flora_comberry_01", newId = "jsmk_fc_flora_comberry_01", name = "Comberry", category = "Plants", cost = 100 }, -- MW
	["563"] = { id = "t_cyr_flora_greenstcp01", newId = "jsmk_fc_t_cyr_flora_greenstcp01", name = "Green Stain Cup", category = "Plants", cost = 100 }, -- PC
	["564"] = { id = "t_sky_flora_carlineth01", newId = "jsmk_fc_t_sky_flora_carlineth01", name = "Carline Thistle", category = "Plants", cost = 100, scale = 1.17 }, -- SKY
	["565"] = { id = "t_sky_flora_hellebore01", newId = "jsmk_fc_t_sky_flora_hellebore01", name = "Hellebore", category = "Plants", cost = 100, scale = 0.83 }, -- SKY
	["566"] = { id = "t_sky_flora_woadfl01", newId = "jsmk_fc_t_sky_flora_woadfl01", name = "Woad Flower", category = "Plants", cost = 100, scale = 0.88 }, -- SKY
	["567"] = { id = "t_skynor_dngbarr_u1empty", newId = "jsmk_fc_t_skynor_dngbarru1empty", name = "Urn, Old Clay Nordic", category = "Containers", cost = 120 }, -- MW
	["568"] = { id = "t_skynor_furn_box1empty", newId = "jsmk_fc_t_skynor_furn_box1empty", name = "Box, Wooden Nordic", category = "Containers", cost = 100 }, -- SKY
	["569"] = { id = "t_skynor_furn_ch1empty", newId = "jsmk_fc_t_skynor_furn_ch1empty", name = "Chest, Nordic", category = "Containers", cost = 60 }, -- SKY
	["570"] = { id = "t_skynor_var_bs1empty", newId = "jsmk_fc_t_skynor_var_bs1empty", name = "Basket, Nordic Wicker Large", category = "Containers", cost = 90 }, -- SKY
	["571"] = { id = "t_skynor_var_bs2empty", newId = "jsmk_fc_t_skynor_var_bs2empty", name = "Basket, Nordic Wicker Small", category = "Containers", cost = 45 }, -- SKY
	["572"] = { id = "ab_light_comcandlebluebf02_128", newId = "jsmkablightcomcandlebluebf02128", name = "Candle Blue Short, Blue Flame", category = "Lights", cost = 12 }, -- OAAB
	["573"] = { id = "ab_light_comcandlebluebf04_128", newId = "jsmkablightcomcandlebluebf04128", name = "Candle Blue Slim, Blue Flame", category = "Lights", cost = 12 }, -- OAAB
	["574"] = { id = "light_com_rm_chandelier_05_l", newId = "jsmk_fc_lightcomrmchandelier05l", name = "Chandelier, Iron", category = "Lights", cost = 150 }, -- MW
	["575"] = { id = "light_com_sconce_01", newId = "jsmk_fc_light_com_sconce_01", name = "Sconce", category = "Lights", cost = 10 }, -- MW
	["576"] = { id = "light_de_lamp_06", newId = "jsmk_fc_light_de_lamp_06", name = "Lamp, Black", category = "Lights", cost = 20 }, -- MW
	["577"] = { id = "t_nor_furn_sconce01_128", newId = "jsmk_fc_t_nor_furn_sconce01_128", name = "Sconce, Nordic Horn L", category = "Lights", cost = 20 }, -- SKY
	["578"] = { id = "t_nor_furn_sconce02_128", newId = "jsmk_fc_t_nor_furn_sconce02_128", name = "Sconce, Nordic Horn R", category = "Lights", cost = 20 }, -- SKY
	["579"] = { id = "ab_furn_deplanterhang01", newId = "jsmk_fc_ab_furn_deplanterhang01", name = "Planter, Ceiling Hanging", category = "Planters", cost = 50 }, -- OAAB
	["580"] = { id = "ex_de_shack_plank_01", newId = "jsmk_fc_ex_de_shack_plank_01", name = "Plank, Shack", category = "Structures", cost = 10, scale = 2.0 }, -- MW
	["581"] = { id = "ex_de_shack_plank_04", newId = "jsmk_fc_ex_de_shack_plank_04", name = "Plank, Shack Long", category = "Structures", cost = 20, scale = 2.0 }, -- MW
	["582"] = { id = "furn_c_t_julianos_01", newId = "jsmk_fc_furn_c_t_julianos_01", name = "Tapestry, Julianos", category = "Tapestries", cost = 120 }, -- MW
	["583"] = { id = "furn_colony_stonetable01", newId = "jsmk_fc_furn_colonystonetable01", name = "Stone Table", category = "Tables", cost = 120 }, -- MW
	["584"] = { id = "furn_de_lecturn", newId = "jsmk_fc_furn_de_lecturn", name = "Lecturn", category = "Shelves", cost = 150 }, -- MW
	["585"] = { id = "furn_de_railing_04", newId = "jsmk_fc_furn_de_railing_04", name = "Railing", category = "Ropes", cost = 50 }, -- MW
	["586"] = { id = "furn_de_railing_06", newId = "jsmk_fc_furn_de_railing_06", name = "Railing Pole", category = "Ropes", cost = 50 }, -- MW
	["587"] = { id = "furn_pottedplant", newId = "jsmk_fc_furn_pottedplant", name = "Potted Plant", category = "Plants", cost = 50 }, --  MW
	["588"] = { id = "furn_rug_redwolf", newId = "jsmk_fc_furn_rug_redwolf", name = "Rug, Red Wolf", category = "Rugs", cost = 100, scale = 1.22 }, -- MW
	["589"] = { id = "furn_s_tapestry", newId = "jsmk_fc_furn_s_tapestry", name = "Tapestry, Skaal", category = "Tapestries", cost = 120 }, -- MW
	["590"] = { id = "furn_s_tapestry02", newId = "jsmk_fc_furn_s_tapestry02", name = "Tapestry, Skaal", category = "Tapestries", cost = 120 }, -- MW
	["591"] = { id = "furn_s_tapestry03", newId = "jsmk_fc_furn_s_tapestry03", name = "Tapestry, Skaal", category = "Tapestries", cost = 120 }, -- MW
	["593"] = { id = "t_com_furn_fireplacestand_01", newId = "jsmk_fctcomfurnfireplacestand01", name = "Fireplace Stand", category = "Other", cost = 10 }, -- TR
	["594"] = { id = "t_com_set_planterhanging_01", newId = "jsmk_fc_tcomsetplanterhanging01", name = "Planter, Wall Hanging", category = "Planters", cost = 50 }, -- PC
	["595"] = { id = "t_nor_furn_planter_01", newId = "jsmk_fc_t_nor_furn_planter_01", name = "Planter, Nordic", category = "Planters", cost = 50 }, -- MW
	["596"] = { id = "t_nor_furn_rugbig_04", newId = "jsmk_fc_t_nor_furn_rugbig_04", name = "Rug, Nordic White", category = "Rugs", cost = 60 }, -- SKY
	["597"] = { id = "t_nor_furn_rugbig_10", newId = "jsmk_fc_t_nor_furn_rugbig_10", name = "Rug, Nordic Black", category = "Rugs", cost = 60, scale = 0.77 }, -- SKY
	["598"] = { id = "t_nor_furn_rugbig_13", newId = "jsmk_fc_t_nor_furn_rugbig_13", name = "Rug, Nordic Red", category = "Rugs", cost = 60 }, -- SKY
	["599"] = { id = "t_nor_furnm_bench_01", newId = "jsmk_fc_t_nor_furnm_bench_01", name = "Bench, Nordic", category = "Seats", cost = 30 }, -- SKY
	["600"] = { id = "t_nor_furnm_bookshelf_01", newId = "jsmk_fc_t_nor_furnm_bookshelf01", name = "Bookshelf, Nordic", category = "Shelves", cost = 120 }, -- SKY
	["601"] = { id = "t_nor_furnm_chair_03", newId = "jsmk_fc_t_nor_furnm_chair_03", name = "Chair, Nordic Fur", category = "Seats", cost = 60 }, -- SKY
	["602"] = { id = "t_nor_furnp_chair_02", newId = "jsmk_fc_t_nor_furnp_chair_02", name = "Chair, Nordic Cheap", category = "Seats", cost = 50 }, -- SKY
	["603"] = { id = "t_nor_furnp_stoolstem_01a", newId = "jsmk_fct_nor_furnp_stoolstem01a", name = "Stool, Nordic Stem", category = "Seats", cost = 10 }, -- SKY
	["604"] = { id = "t_nor_furnp_stoolstem_02a", newId = "jsmk_fct_nor_furnp_stoolstem02a", name = "Stool, Nordic Stem", category = "Seats", cost = 10 }, -- SKY
	["605"] = { id = "t_nor_furnp_stoolstem_03a", newId = "jsmk_fct_nor_furnp_stoolstem03a", name = "Stool, Nordic Stem", category = "Seats", cost = 10 }, -- SKY
	["606"] = { id = "t_nor_furnp_table_08", newId = "jsmk_fc_t_nor_furnp_table_08", name = "Table, Nordic Square Cheap", category = "Tables", cost = 100 }, -- SKY
	["607"] = { id = "t_nor_furnr_bookshelf_01", newId = "jsmk_fc_t_nor_furnr_bookshelf01", name = "Bookshelf, Nordic Expensive Large", category = "Shelves", cost = 300 }, -- SKY
	["608"] = { id = "t_nor_furnr_bookshelf_02", newId = "jsmk_fc_t_nor_furnr_bookshelf02", name = "Bookshelf, Nordic Expensive Medium", category = "Shelves", cost = 200 }, -- SKY
	["609"] = { id = "t_nor_furnr_bookshelf_03", newId = "jsmk_fc_t_nor_furnr_bookshelf03", name = "Bookshelf, Nordic Expensive Small", category = "Shelves", cost = 100 }, -- SKY
	["610"] = { id = "t_nor_furnr_chair_01", newId = "jsmk_fc_t_nor_furnr_chair_01", name = "Chair, Nordic Expensive Armed", category = "Seats", cost = 120 }, -- SKY
	["611"] = { id = "t_nor_furnr_chair_02", newId = "jsmk_fc_t_nor_furnr_chair_02", name = "Chair, Nordic Expensive", category = "Seats", cost = 120 }, -- SKY
	["612"] = { id = "t_nor_furnr_endtable_04", newId = "jsmk_fc_t_nor_furnr_endtable_04", name = "End Table, Nordic Expensive", category = "Tables", cost = 120 }, -- SKY
	["613"] = { id = "t_nor_furnr_tableround_01", newId = "jsmk_fct_nor_furnr_tableround01", name = "Table, Nordic Expensive Round", category = "Tables", cost = 240 }, -- SKY
	["614"] = { id = "t_nor_furnr_wallscreen_01", newId = "jsmk_fct_nor_furnr_wallscreen01", name = "Wallscreen, Nordic Expensive", category = "Other", cost = 150 }, -- SKY
	["615"] = { id = "ab_light_comcandleblckbf04_128", newId = "jsmkablightcomcandleblckbf04128", name = "Candle Black Slim, Blue Flame", category = "Lights", cost = 12 }, -- OAAB
	["592"] = { id = "in_nord_fireplace_01", newId = "jsmk_fc_in_nord_fireplace_01", name = "Fireplace, Nordic", campfireId = "ashfall_nordfireplace_01", category = "Fireplaces", cost = 120 }, -- MW
	-- ["616"] = { id = "furn_de_firepit_f_01", newId = "jsmk_fc_furn_de_firepit_f_01", name = "Campfire", campfireId = "ashfall_campfire", category = "Fireplaces", cost = 30 }, -- MW
	["617"] = { id = "furn_redoran_hearth_02", newId = "jsmk_fc_furn_redoran_hearth_02", name = "Hearth, Redoran", campfireId = "ashfall_redhearth_02", category = "Fireplaces", cost = 120 }, -- MW
	["618"] = { id = "furn_fireplace10", newId = "jsmk_fc_furn_fireplace10", name = "Fireplace", campfireId = "ashfall_fireplace10", category = "Fireplaces", cost = 120 }, -- MW
	["619"] = { id = "in_imp_fireplace_grand", newId = "jsmk_fc_in_imp_fireplace_grand", name = "Fireplace, Imperial", campfireId = "ashfall_impfireplace_01", category = "Fireplaces", cost = 240 }, -- MW
	["620"] = { id = "t_imp_setsky_i_fireplace_01", newId = "jsmk_fc_t_impsetskyifireplace01", name = "Fireplace, Nordic", campfireId = "ashfall_skyfp_01", category = "Fireplaces", cost = 120 }, -- SKY
	["621"] = { id = "t_imp_setsky_i_fireplace_02", newId = "jsmk_fc_t_impsetskyifireplace02", name = "Fireplace, Nordic", campfireId = "ashfall_skyfp_02", category = "Fireplaces", cost = 120 }, -- SKY
	["622"] = { id = "ab_in_velhearthsmall", newId = "jsmk_fc_ab_in_velhearthsmall", name = "Hearth, Velothi", campfireId = "ashfall_ab_hearth_sml", category = "Fireplaces", cost = 120 }, -- OAAB
	["623"] = { id = "furn_dwrv_stove00", newId = "jsmk_fc_furn_dwrv_stove00", name = "Stove, Dwemer", campfireId = "ashfall_stove_01", category = "Fireplaces", cost = 360 }, -- MW
	["624"] = { id = "active_de_p_bed_11", newId = "jsmk_fc_active_de_p_bed_11", name = "Single Bed, Oldwood Blue", category = "Beds", cost = 200 }, -- MW
	["625"] = { id = "t_mwde_setind_cul2empty", newId = "jsmk_fc_t_mwde_setind_cul2empty", name = "Culdem", category = "Containers", cost = 200 }, -- TR
	["626"] = { id = "t_mwde_setind_cul1empty", newId = "jsmk_fc_t_mwde_setind_cul1empty", name = "Culdem", category = "Containers", cost = 200 }, -- TR
	["627"] = { id = "t_mw_floratv_weepveil02", newId = "jsmk_fc_t_mw_floratv_weepveil02", name = "Weeping Veil", category = "Plants", cost = 100, scale = 0.91 }, -- TR
	["628"] = { id = "t_mw_flora_redfireflw01", newId = "jsmk_fc_t_mw_flora_redfireflw01", name = "Duskbell", category = "Plants", cost = 100, scale = 0.90 }, -- TR
	-- ["629"] = { id = "ex_velothi_window_01", newId = "jsmk_fc_ex_velothi_window_01", name = "Window, Velothi", category = "Windows", cost = 200 }, -- MW
	["629"] = { id = "furn_coalpile00", newId = "jsmk_fc_furn_coalpile00", name = "Coal Pile", category = "Other", cost = 10 }, -- MW
	["630"] = { id = "furn_coals_hot", newId = "jsmk_fc_furn_coals_hot", name = "Coals, Hot", category = "Other", cost = 10 }, -- MW
	["631"] = { id = "furn_crate_open_01", newId = "jsmk_fc_furn_crate_open_01", name = "Crate, Open", category = "Crates", cost = 10 }, -- MW
	["632"] = { id = "furn_crate_lid_01", newId = "jsmk_fc_furn_crate_lid_01", name = "Crate Lid", category = "Crates", cost = 10 }, -- MW
	["633"] = { id = "furn_de_shack_post", newId = "jsmk_fc_furn_de_shack_post", name = "Post, Shack", category = "Structures", cost = 10 }, -- MW
	["634"] = { id = "furn_scrapwood01", newId = "jsmk_fc_furn_scrapwood01", name = "Scrapwood", category = "Structures", cost = 10 }, -- MW
}

---@type string[]
this.validFurniture = {}

local nonCarryableObjectType = { [tes3.objectType.static] = true, [tes3.objectType.container] = true, [tes3.objectType.activator] = true, [tes3.objectType.light] = true }

function this.getValidFurniture()
	for index, furniture in pairs(this.furniture) do
		if not (furniture.notForSale or furniture.deprecated) then
			local valid = true
			furniture.id = furniture.id:lower()
			local furnitureObj = tes3.getObject(furniture.id)
			if furnitureObj then
				if nonCarryableObjectType[furnitureObj.objectType] then
					if furnitureObj.objectType == tes3.objectType.light and furnitureObj.canCarry then
						if not furniture.deprecated then
							valid = false
							log:error("Can Carry: %s %s", index, furniture.id)
						end
					end
				elseif not furniture.deprecated then
					valid = false
					log:error("Can Carry: %s %s", index, furniture.id)
				end
			else
				valid = false
				log:info("Not Found: %s %s", index, furniture.id)
			end
			if valid then table.insert(this.validFurniture, furniture.id) end
		end
	end
	log:info("Registered %s recipes", table.size(this.validFurniture))
end

return this

--[[
	deprecated plants:
	Flora_plant_01
	T_Mw_Flora_Hornlilly01
	Temple Dome
	Bluefoot
]]
