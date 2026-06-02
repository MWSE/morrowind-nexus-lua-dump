-- Colors
G_morrowindGold     = getColorFromGameSettings("fontColor_color_normal")
G_morrowindLight    = getColorFromGameSettings("fontColor_color_normal_over")
G_morrowindPressed  = getColorFromGameSettings("FontColor_color_normal_pressed")
G_goldenMix         = mixColors(G_morrowindGold, G_morrowindLight)
G_goldenMix2        = mixColors(G_morrowindLight, G_morrowindGold, 0.3)
G_lightText         = util.color.rgb(G_morrowindLight.r^0.5,G_morrowindLight.g^0.5,G_morrowindLight.b^0.5)
G_morrowindBlue     = getColorFromGameSettings("fontColor_color_journal_link")
G_morrowindBlue2    = getColorFromGameSettings("fontColor_color_journal_link_over")
G_morrowindBlue3    = getColorFromGameSettings("fontColor_color_journal_link_pressed")


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

-- ╭──────────────────────────────────────────────────────────────────────────────╮
-- │ Tent Building Constants                                                      │
-- ╰──────────────────────────────────────────────────────────────────────────────╯
G_tentStages = {
	["sd_campingitem_sticks"] = 0,
	["sd_campingitem_rope"]   = 0,
	["sd_campingitem_tarp"]   = 0,
	["sd_tent_1"]  = 1,  -- Stakes
	["sd_tent_2"]  = 2,  -- Stakes + Rope
	["sd_tent_2b"] = 2,  -- Stakes + Tarp (alternate)
	["sd_tent_3"]  = 3,  -- Stakes + Rope + Tarp
	["sd_tent_4"]  = 4,  -- Complete tent
}

G_tentUpgrades = {
	["sd_campingitem_sticks"] = {
		{ component = nil,                      result = "sd_tent_1",  label = "Build Tent" },
	},
	["sd_campingitem_rope"] = {
		{ component = "sd_campingitem_sticks",  result = "sd_tent_2",  label = "Build Tent (Add sticks)" },
	},
	["sd_campingitem_tarp"] = {
		{ component = "sd_campingitem_sticks",  result = "sd_tent_2b", label = "Build Tent (Add sticks)" },
	},
	["sd_tent_1"] = {
		{ component = "sd_campingitem_rope",    result = "sd_tent_2",  label = "Add Rope" },
	},
	["sd_tent_2"] = {
		{ component = "sd_campingitem_tarp",    result = "sd_tent_3",  label = "Add Tarp" },
	},
	["sd_tent_2b"] = {
		{ component = "sd_campingitem_rope",    result = "sd_tent_3",  label = "Add Rope" },
	},
	["sd_tent_3"] = {
		{ component = "sd_campingitem_bedroll", result = "sd_tent_4",  label = "Add Bedroll" },
	},
}

G_tentDowngrades = {
	["sd_tent_4"]  = { result = "sd_tent_3",  breakChance = 0.02, returns = "sd_campingitem_bedroll" },
	["sd_tent_3"]  = { result = "sd_tent_2",  breakChance = 0.05, returns = "sd_campingitem_tarp" },
	["sd_tent_2"]  = { result = "sd_tent_1",  breakChance = 0.15, returns = "sd_campingitem_rope" },
	["sd_tent_2b"] = { result = "sd_tent_1",  breakChance = 0.05, returns = "sd_campingitem_tarp" },
	["sd_tent_1"]  = { result = false,         breakChance = 0.10, returns = "sd_campingitem_sticks" },
}

-- ------------------------------ crafting stations ------------------------------

G_campingBreakdown = {
	["sd_campingobject_tanningrack"] = "sd_campingitem_tanningrack",
	["sd_campingobject_workbench"]   = "sd_campingitem_workbench",
}

-- for tooltip
G_tentComponentNames = {
	["sd_campingitem_rope"]    = "rope",
	["sd_campingitem_tarp"]    = "a tarp",
	["sd_campingitem_sticks"]  = "sticks",
	["sd_campingitem_bedroll"] = "a bedroll",
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Tea Constants                                                        │
-- ╰──────────────────────────────────────────────────────────────────────╯

G_teacupIds = {
	["misc_com_redware_cup"]        = true,
	["misc_de_pot_redware_03"]      = true,
	["ab_misc_deceramiccup_01"]     = true,
	["ab_misc_deceramiccup_02"]     = true,
	["ab_misc_deceramicflask_01"]   = true,
	["teamod_teacup_q2"]	        = true,
	["teamod_teacup_q6"]	        = true,
	["teamod_teacup_q7"]	        = true,
	["teamod_teacup_qg"]	        = true,
	["teamod_teacup_st01"]	        = true,
	["teamod_teacup_st02"]	        = true,
	["teamod_teacup_st03"]	        = true,
	["teamod_teacup_st04"]	        = true,
	["teamod_teacup_st05"]	        = true,
	["teamod_teacup_st06"]	        = true,
	["teamod_teacup_st07"]	        = true,
	["teamod_teacup_st08"]	        = true,
	["teamod_teacup_st09"]	        = true,
	["teamod_teacup_st10"]	        = true,
	["teamod_teacup_st11"]	        = true,
	["teamod_teacup_st12"]	        = true,
	["teamod_teacup_cali_red"]	    = true,
	["teamod_teacup_cali_silv"]     = true,
	["teamod_teacup_kb02"]          = true,
}

G_teacupSimple = {

}

-- brewing-capable teapots and kettles. consumed by p_tea (mesh check for world interaction),
-- tea_recipes (teakettle station check), and g_liquids (vfx blacklist).
G_teapotIds = {
	["t_com_copperkettle_01"]       = true,
	["ab_misc_pewterkettle"]       = true,
	["ab_misc_comredwareteapot"]    = true,
	["t_com_coppetteapot_01"]       = true,
	["ab_misc_kettleceremonial"]    = true,
	["ab_misc_debugteapot"]         = true,
	["ab_misc_ceramicteapot01"]     = true,
	["ab_misc_ceramicteapot01hang"] = true,
	["ab_misc_comcopperkettle01"]   = true,
	["sd_teapot_red"]               = true,
	["t_de_punavitkettle_01"]       = true,
	["t_he_blueceladonteapot_01"]   = true,
	["t_he_greenceladonteapot_01"]  = true,
	["t_yne_clayteapot"]            = true,
	["t_yne_stoneteapot"]           = true,
	["t_yne_woodenteapot_01"]       = true,
	["t_bre_pewterteapot_01"]       = true,
	["t_bre_stonewareteapot_01"]    = true,
	["tm_kettle_bar_01"]            = true,
	["tm_kettle_bar_02"]            = true,
	["teamod_kettle_st01"]          = true,
	["teamod_kettle_st02"]          = true,
	["teamod_teapot_q2"]            = true,
	["teamod_teapot_q6"]            = true,
	["teamod_teapot_q7"]            = true,
	["teamod_teapot_qg"]            = true,
	["teamod_teapot_qgl"]           = true,
	["teamod_teapot_st01"]          = true,
	["teamod_teapot_st02"]          = true,
	["teamod_teapot_st03"]          = true,
	["teamod_teapot_st04"]          = true,
	["teamod_teapot_st05"]          = true,
	["teamod_teapot_st06"]          = true,
	["teamod_teapot_st07"]          = true,
	["teamod_teapot_st08"]          = true,
	["teamod_teapot_st09"]          = true,
	["teamod_teapot_st10"]          = true,
	["teamod_teapot_st11"]          = true,
	["teamod_teapot_st12"]          = true,
}

-- coffee pots; same consumers as G_teapotIds plus the coffeepot station + world interaction.
G_coffeePotIds = {
	["teamod_coffeepot_q2"]   = true,
	["teamod_coffeepot_q6"]   = true,
	["teamod_coffeepot_q7"]   = true,
	["teamod_coffeepot_qg"]   = true,
	["teamod_coffeepot_st01"] = true,
	["teamod_coffeepot_st02"] = true,
	["teamod_coffeepot_st03"] = true,
	["teamod_coffeepot_st04"] = true,
	["teamod_coffeepot_st05"] = true,
	["teamod_coffeepot_st06"] = true,
}

G_teaIngredients = {
	tea_H  = "ingred_heather_01",
	tea_SF = "ingred_stoneflower_petals_01",
}

-- mesh substitutes for (origId, liquidKey) potion records.
-- when present, ensurePotionFor uses this mesh on the new potion record
-- and the liquid/steam vfx pass is skipped (the mesh itself shows the contents).
-- placeholders: tea_H and tea_SF currently share a filled mesh per cup.
G_potionMeshSubstitutes = {
	["teamod_teacup_q2"] = {
		tea_H  = "meshes/teamod/q_teacup_02r.nif",
		tea_SF = "meshes/teamod/q_teacup_02r.nif",
	},
	["teamod_teacup_q6"] = {
		tea_H  = "meshes/teamod/q_teacup_06g.nif",
		tea_SF = "meshes/teamod/q_teacup_06g.nif",
	},
	["teamod_teacup_q7"] = {
		tea_H  = "meshes/teamod/q_teacup_07t.nif",
		tea_SF = "meshes/teamod/q_teacup_07t.nif",
	},
	["teamod_teacup_qg"] = {
		tea_H  = "meshes/teamod/q_teacup_gg.nif",
		tea_SF = "meshes/teamod/q_teacup_gg.nif",
	},
	["teamod_teacup_st01"] = {
		tea_H  = "meshes/teamod/st_teacup_01g.nif",
		tea_SF = "meshes/teamod/st_teacup_01g.nif",
	},
	["teamod_teacup_st02"] = {
		tea_H  = "meshes/teamod/st_teacup_02g.nif",
		tea_SF = "meshes/teamod/st_teacup_02g.nif",
	},
	["teamod_teacup_st03"] = {
		tea_H  = "meshes/teamod/st_teacup_03g.nif",
		tea_SF = "meshes/teamod/st_teacup_03g.nif",
	},
	["teamod_teacup_st04"] = {
		tea_H  = "meshes/teamod/st_teacup_04g.nif",
		tea_SF = "meshes/teamod/st_teacup_04g.nif",
	},
	["teamod_teacup_st05"] = {
		tea_H  = "meshes/teamod/st_teacup_05g.nif",
		tea_SF = "meshes/teamod/st_teacup_05g.nif",
	},
	["teamod_teacup_st06"] = {
		tea_H  = "meshes/teamod/st_teacup_06r.nif",
		tea_SF = "meshes/teamod/st_teacup_06r.nif",
	},
	["teamod_teacup_st07"] = {
		tea_H  = "meshes/teamod/st_teacup_07r.nif",
		tea_SF = "meshes/teamod/st_teacup_07r.nif",
	},
	["teamod_teacup_st08"] = {
		tea_H  = "meshes/teamod/st_teacup_08g.nif",
		tea_SF = "meshes/teamod/st_teacup_08g.nif",
	},
	["teamod_teacup_st09"] = {
		tea_H  = "meshes/teamod/st_teacup_09g.nif",
		tea_SF = "meshes/teamod/st_teacup_09g.nif",
	},
	["teamod_teacup_st10"] = {
		tea_H  = "meshes/teamod/st_teacup_10g.nif",
		tea_SF = "meshes/teamod/st_teacup_10g.nif",
	},
	["teamod_teacup_st11"] = {
		tea_H  = "meshes/teamod/st_teacup_11g.nif",
		tea_SF = "meshes/teamod/st_teacup_11g.nif",
	},
	["teamod_teacup_st12"] = {
		tea_H  = "meshes/teamod/st_teacup_12t.nif",
		tea_SF = "meshes/teamod/st_teacup_12t.nif",
	},
	["teamod_teacup_cali_red"] = {
		tea_H  = "meshes/teamod/st_teacup_redware_t.nif",
		tea_SF = "meshes/teamod/st_teacup_redware_t.nif",
	},
	["teamod_teacup_cali_silv"] = {
		tea_H  = "meshes/teamod/st_teacup_silver_g.nif",
		tea_SF = "meshes/teamod/st_teacup_silver_g.nif",
	},
	["teamod_teacup_kb02"] = {
		tea_H  = "meshes/kb/kb_silver_teacup_02g.nif",
		tea_SF = "meshes/kb/kb_silver_teacup_02g.nif",
	},
}

G_CUPS_PER_BREW = 2
G_WATER_PER_CUP = 250  -- ml per cup; total = G_CUPS_PER_BREW * G_WATER_PER_CUP
G_BREW_DELAY_SECONDS = 2

------------------------------ Blood Items ------------------------------
-- non-vampires get reduced food/drink restore from these
-- (recordIds are always lowercase per openmw)
G_bloodItemIds = {
	-- blood potions
	["potion_blood_dd"]                = true,
	["bs_potion_bs_bottled_heal2b"]    = true, -- daedric blood potion
	["t_com_potion_dragonblood"]       = true, -- dragon's blood
	["tr_m1_q66_ra2_rat_blood"]        = true, -- plague rat blood
	["tr_m3_q_11_blood"]               = true, -- blood of merihayan
	["tr_m4_bal_bloodvial"]            = true, -- vial of blood
	["tr_m7_da_nam_traitorbloodvial"]  = true, -- traitor's blood vial
	-- creature blood vials (heart of the beast)
	["hb_alitblood"]                   = true,
	["hb_alphynblood"]                 = true,
	["hb_animalblood"]                 = true,
	["hb_aspisblood"]                  = true,
	["hb_bearblood"]                   = true,
	["hb_boarblood"]                   = true,
	["hb_cervidblood"]                 = true, -- venison blood
	["hb_dreughblood"]                 = true,
	["hb_frogblood"]                   = true,
	["hb_goatblood"]                   = true,
	["hb_grahlblood"]                  = true,
	["hb_guarblood"]                   = true,
	["hb_horkerblood"]                 = true,
	["hb_horseblood"]                  = true,
	["hb_kagoutiblood"]                = true,
	["hb_mooncrabblod"]                = true, -- mudcrab blood (mod recordId typo)
	["hb_mudcrabblood"]                = true,
	["hb_muskratblood"]                = true,
	["hb_nixhoundblood"]               = true,
	["hb_racerblood"]                  = true, -- cliff racer blood
	["hb_ratblood"]                    = true,
	["hb_scribblood"]                  = true,
	["hb_stridentblood"]               = true, -- strident runner blood
	["hb_tanthablood"]                 = true, -- gold tantha blood
	["hb_trollblood"]                  = true,
	["hb_wolfblood"]                   = true,
	["hb_wormmouthblood"]              = true,
	-- ingredient blood
	["ingred_blood_innocent_unique"]   = true, -- blood of an innocent
	["t_ingcrea_orcblood_01"]          = true, -- orc's blood
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Log Levels                                                           │
-- ╰──────────────────────────────────────────────────────────────────────╯

DEBUG_LEVEL = 6  --  { "Silent", "Quiet", "Chatty", "Deep", "Trace", "Spammy" }
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

local PLATE_WHITELIST = { "_plate", "plate_" }
local PLATE_BLACKLIST = { "template", "armor", "bonemold" }

local ADDITIONAL_PLATES = {
	["t_nor_stonewareplatter_01"] = true,
	["t_imp_colbarrowplatter_01"] = true,
	["t_com_woodplatter_b01"] = true,
	["t_bre_woodplatter_01"] = true,
	["t_arg_woodenplatter_02"] = true,
	["t_imp_colclayplatter_01"] = true,
	["t_rga_porcelainplatter_01"] = true,
	["t_com_woodplatter_c01"] = true,
	["t_he_shellplatter_01"] = true,
	["t_he_shellplatter_02"] = true,
	["t_he_shellplatter_03"] = true,
	["t_bre_greenglassplatter_01"] = true,
	["t_bre_silverplatter_01"] = true,
}
	
-- Returns "bowl", "plate", or nil
function getFoodwareType(item)
	if not item then return nil end
	local rec = types.Miscellaneous.record(item)
	if not rec then return nil end
	
	local recordId = rec.id
	
	if ADDITIONAL_PLATES[recordId] then return "plate" end
	
	local name = (rec.name or ""):lower()
	
	-- Check bowl blacklist first
	for _, pattern in ipairs(BOWL_BLACKLIST) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			goto checkPlate
		end
	end
	-- Check bowl whitelist
	for _, pattern in ipairs(BOWL_WHITELIST) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "bowl"
		end
	end
	
	::checkPlate::
	-- Check plate blacklist
	for _, pattern in ipairs(PLATE_BLACKLIST) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return nil
		end
	end
	-- Check plate whitelist
	for _, pattern in ipairs(PLATE_WHITELIST) do
		if recordId:find(pattern, 1, true) or name:find(pattern, 1, true) then
			return "plate"
		end
	end
	
	return nil
end