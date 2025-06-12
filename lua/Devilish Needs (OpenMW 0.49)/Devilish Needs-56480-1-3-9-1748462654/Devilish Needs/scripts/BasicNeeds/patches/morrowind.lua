-- -----------------------------------------------------------------------------
-- Item data for vanilla Morrowind (All values multiplied by 5)
-- -----------------------------------------------------------------------------
return {
   consumables = {
      -- Drinks                         Th   Hu   Ex
      ["p_vintagecomberrybrandy1"]  = { -1250, 0, 0 },
      ["potion_ancient_brandy"]     = { -1250, 0, 0 },
      ["potion_comberry_brandy_01"] = { -1250, 0, 0 },    -- Greef
      ["potion_comberry_wine_01"]   = { -1500, 0, 0 },   -- Shein
      ["potion_cyro_brandy_01"]     = { -1250, 0, 0 },    -- Cyrodiilic Brandy
      ["potion_cyro_whiskey_01"]    = { -1250, 0, 0 },    -- Flin
      ["potion_local_brew_01"]      = { -1500, 0, 0 },   -- Mazte
      ["potion_local_liquor_01"]    = { -1250, 0, 0 },    -- Sujamma
      ["potion_skooma_01"]          = { -1250, 0, -750 }, -- Skooma
      ["detd_codasoup_1"]           = { -1250, -750, 0 },
      -- Foods                          Th   Hu   Ex
      ["ingred_ash_yam_01"]         = { 0, -150, 0 },    -- Ash Yam
      ["ingred_bread_01"]           = { 0, -750, 0 },   -- Bread
      ["ingred_comberry_01"]        = { 0, -150, 0 },    -- Comberry
      ["ingred_crab_meat_01"]       = { 0, -250, 0 },   -- Crab Meat
      ["ingred_hackle-lo_leaf_01"]  = { 0, -100, -250 }, -- Hackle-Lo Leaf
      ["ingred_hound_meat_01"]      = { 0, -250, 0 },
      ["food_kwama_egg_01"]         = { 0, -300, 0 },
      ["food_kwama_egg_02"]         = { 0, -350, 0 },
      ["ingred_marshmerrow_01"]     = { 0, -250, 0 },
      ["ingred_rat_meat_01"]        = { 0, -250, 0 },
      ["ingred_saltrice_01"]        = { 0, -250, 0 },
      ["ingred_scrib_jelly_01"]     = { 0, -200, 0 },
      ["ingred_scrib_jerky_01"]     = { 0, -250, 0 },
      ["ingred_scuttle_01"]         = { 0, -1000, 0 },
      ["ingred_wickwheat_01"]       = { 0, -150, 0 },
      -- Other                          Th   Hu   Ex
      ["ingred_moon_sugar_01"]      = { 0, 0, -500 }
   },
   containers = {
      "misc_com_bottle_01",
      "misc_com_bottle_02",
      "misc_com_bottle_03",
      "misc_com_bottle_04",
      "misc_com_bottle_05",
      "misc_com_bottle_06",
      "misc_com_bottle_07",
      "misc_com_bottle_08",
      "misc_com_bottle_09",
      "misc_com_bottle_10",
      "misc_com_bottle_11",
      "misc_com_bottle_12",
      "misc_com_bottle_13",
      "misc_com_bottle_14",
      "misc_com_bottle_15",
      "misc_com_redware_flask",
      "misc_flask_01",
      "misc_flask_02",
      "misc_flask_03",
      "misc_flask_04",
   },
   toxicsubstances = {						
	-- Ingrendient								Identifier, Disease Chance
	-- debug entry: ["ingred_scuttle_01"] 			     = {"raw meat", 100 },
	  ["ingred_crab_meat_01"] 			     = {"raw meat", 100 },
	  ["ingred_ghoul_heart_01"]			     = {"raw meat", 100 },
	  ["ingred_guar_hide_01"] 			     = {"raw meat", 100 },
	  ["ingred_hound_meat_01"] 			     = {"raw meat", 100 },
	  ["ingred_kagouti_hide_01"]		     = {"raw meat", 100 },
	  ["ingred_kwama_cuttle_01"]		     = {"raw meat", 100 },
	  ["ingred_netch_leather_01"]		     = {"raw meat", 100 },
	  ["ingred_rat_meat_01"]			     = {"raw meat", 100 },
	  ["ingred_scrib_jelly_01"]			     = {"raw meat", 100 },
	  ["ingred_human_meat_01"]			     = {"raw meat", 100 },
	},
}
