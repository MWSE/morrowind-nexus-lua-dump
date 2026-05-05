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
}

G_teaIngredients = {
	tea_H  = "ingred_heather_01",
	tea_SF = "ingred_stoneflower_petals_01",
}

G_CUPS_PER_BREW = 2
G_WATER_PER_CUP = 250  -- ml per cup; total = G_CUPS_PER_BREW * G_WATER_PER_CUP
G_BREW_DELAY_SECONDS = 2

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Log Levels                                                           │
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