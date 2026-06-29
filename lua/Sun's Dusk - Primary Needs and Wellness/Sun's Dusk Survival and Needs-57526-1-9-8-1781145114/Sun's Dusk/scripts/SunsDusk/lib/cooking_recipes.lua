-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cooking Recipes - Dynamic Recipe Definitions                         │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- add resin, dreugh wax, daedra heart to spreadsheet

-- Ingredient class matchers
-- These check if an ingredient belongs to a particular category
-- The ingredient data has a .class field set by the consumables database

local function matchClass(ingredient, className)
	if not ingredient or not ingredient.data then return false end
	return ingredient.data.ingredientClass == className
end

local function mushroom(ingredient)
	return matchClass(ingredient, "mushroom")
end

local function fish(ingredient)
	return matchClass(ingredient, "fish")
end

local function bread(ingredient)
	return matchClass(ingredient, "bread")
end

local function meat(ingredient)
	return matchClass(ingredient, "meat")
end

local function greens(ingredient)
	return matchClass(ingredient, "greens")
end

local function fruit(ingredient)
	return matchClass(ingredient, "fruit")
end

local function spice(ingredient)
	return matchClass(ingredient, "spices")
end

local function salt(ingredient)
	return matchClass(ingredient, "salts")
end

local function egg(ingredient)
	return matchClass(ingredient, "egg")
end

local function herb(ingredient)
	return matchClass(ingredient, "herb")
end

local function crab(ingredient)
	return matchClass(ingredient, "crab")
end

--[[ Affa's Wildcards (old format - preserved for reference)
local function aff_ar_ash(ingredient)
	if ingredient.recordId:find[ "ingred_ash_salts_01", "ingred_gravedust_01", "ingred_bonemeal_01" ] then
		return true
	end
end

local function aff_cs_3(ingredient)
	if ingredient.recordId:find[ "ingred_hound_meat_01", "ingred_willow_anther_01", "ingred_coprinus_01", "ingred_trama_root_01", "food_kwama_egg_01", "food_kwama_egg_02", "ingred_bc_spore_pod"] then
		return true
	end
end

local function resin(ingredient) -- TD included, "Bettle Resin", "Yeth Resin"
	if ingredient.recordId:find[ "ingred_shalk_resin_01" ] then
		return true
	end
end

local function aff_other(ingredient)
	if ingredient.recordId:find[ "ingred_russula_01", "ingred_coprinus_01", "ingred_scuttle_01", "ingred_shalk_resin_01" ] then
		return true
	end
end

local function aff_greens(ingredient)
	if ingredient.recordId:find[ "ingred_roobrush_01", "ingred_wickwheat_01", "ingred_shalk_resin_01", "ingred_corkbulb_root_01", "ingred_scrib_jelly_01" ] then
		return true
	end
end]]

-- Wildcard matcher factory: returns a function that matches any of the given IDs
local function anyOf(...)
	local ids = {...}
	return function(ingredient)
		if not ingredient then return false end
		for _, id in ipairs(ids) do
			if ingredient.recordId == id then
				return true
			end
		end
		return false
	end
end

-- Specific ID matcher factory
local function exactId(id)
	return function(ingredient)
		return ingredient and ingredient.recordId == id
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Recipe Definitions                                                   │
-- ╰──────────────────────────────────────────────────────────────────────╯
-- Each recipe has:
--   name: Display name for the cooked food
--   matchers: Table of {count, match} pairs where match is a function
--   itemId: Record ID for the created item
--   mesh: 3D model path for the cooked food (also used for steam VFX)
--   icon: Icon path for the inventory
--   description: Flavor text (optional)
--   isSoup: Routes to soup container/preset
--   minLevel: Cooking skill required to discover the recipe
--   book: Recipe-book id; mods only apply once the book is read
--   mods: Table of bonuses applied when the recipe is known. keys ending
--         in "Mult" multiply, "Mod" keys add (both onto statMods);
--         any other key is assigned straight onto the meal stats -
--         e.g. isToxic = true, consumeCategory = "Hearty Meal",
--         warmthValue = -10, isGreenPact = false.

local COOKING_RECIPES = {
-- ══════════════════════════════════════════════════════════════════════
-- MUSHROOM RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_m = {
		name = "Cooked Mushrooms",
		book = "sd_book_cook_food_m",
		matchers = {
			{count = 2, match = mushroom},
		},
		mesh = "meshes/SunsDusk/food/o_bkdtruffl.nif",
		icon = "icons/exploot/food/o_bkdtruffl.tga",
		description = "This simple mushroom-packed dish has its tasteful presentation to thank for its appeal.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_g = {
		name = "Cooked Mushrooms and Veggies",
		book = "sd_book_cook_food_m_g",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = greens},
		},
		mesh = "meshes/SunsDusk/food/o_ml_lumisoup.nif",
		icon = "icons/exploot/food/o_ml_lumisoup.tga",
		description = "A healthy vegetable dish achieved by steaming mushrooms in plant leaves.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_meat = {
		name = "Cooked Mushrooms and Meat",
		book = "sd_book_cook_food_m_meat",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = meat},
		},
		mesh = "meshes/SunsDusk/food/o_shrmratstw.nif",
		icon = "icons/exploot/food/o_shrmratstw.tga",
		description = "A filling dish made by grilling various mountain ingredients with meat.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_salt = {
		name = "Cooked Salted Mushrooms",
		book = "sd_book_cook_food_m_salt",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_shrmsoup.nif",
		icon = "icons/exploot/food/o_shrmsoup.tga",
		description = "A basic mushroom dish made by lightly salting mushrooms and grilling them.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_spice = {
		name = "Cooked Spiced Mushrooms",
		book = "sd_book_cook_food_m_spice",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = spice},
		},
		mesh = "meshes/SunsDusk/food/o_templedom.nif",
		icon = "icons/exploot/food/o_templedom.tga",
		description = "A fragrant mixture of herbs and spices. It's easily recognized by its unique aroma.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_fruit = {
		name = "Cooked Shrooms and Fruit",
		book = "sd_book_cook_food_m_fruit",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = fruit},
		},
		mesh = "meshes/SunsDusk/food/o_bowl_comb2.nif",
		icon = "icons/exploot/food/o_templedom.tga",
		description = "This dish contrasts the sweetness of fruit with the savoriness of mushrooms.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_fish = {
		name = "Cooked Mushrooms and Fish",
		book = "sd_book_cook_food_m_f",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = fish},
		},
		mesh = "meshes/SunsDusk/food/o_templedom.nif",
		icon = "icons/exploot/food/o_templedom.tga",
		description = "A simple dish made by cooking skewered fresh fish alongside fragrant mushrooms.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_m_greens_salt = {
		name = "Cream of Mushroom Soup",
		book = "sd_book_cook_food_m_soup",
		matchers = {
			{count = 1, match = mushroom},
			{count = 1, match = greens},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_ml_bo_soup.nif",
		icon = "icons/exploot/food/o_soup_mush.tga",
		description = "This creamy mushroom-and-vegetable soup is thick and flavorful.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},

-- ══════════════════════════════════════════════════════════════════════
-- GREENS RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_g = {
		name = "Cooked Greens",
		book = "sd_book_cook_food_g",
		matchers = {
			{count = 2, match = greens},
		},
		mesh = "meshes/SunsDusk/food/o_mmash_yamrd.nif",
		icon = "icons/exploot/food/o_bkdtruffl.tga",
		description = "A basic vegetable dish made by sauteing fresh wild plants.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_g_salt = {
		name = "Cooked Salted Greens",
		book = "sd_book_cook_food_g_salt",
		matchers = {
			{count = 1, match = greens},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_ml_sb_herbs.nif",
		icon = "icons/exploot/food/o_salad.tga",
		description = "A health-boosting dish made with leafy greens and a touch of salt.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_g_spice = {
		name = "Cooked Spiced Greens",
		book = "sd_book_cook_food_g_spice",
		matchers = {
			{count = 1, match = greens},
			{count = 1, match = spice},
		},
		mesh = "meshes/SunsDusk/food/o_bwl_cabag.nif",
		icon = "icons/exploot/food/o_salad.tga",
		description = "The fragrant aroma of this sauteed spice and vegetable dish makes your mouth water.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},

-- ══════════════════════════════════════════════════════════════════════
-- FISH RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_f = {
		name = "Cooked Fish",
		book = "sd_book_cook_food_f",
		matchers = {
			{count = 2, match = fish},
		},
		mesh = "meshes/SunsDusk/food/o_fish_soup.nif",
		icon = "icons/exploot/food/o_fishsoup_sml.tga",
		description = "A simple dish made by cooking chunks of fresh fish on a skewer.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_f_greens_herb = {
		name = "Cooked Steamed Fish",
		book = "sd_book_cook_food_f_g_h",
		matchers = {
			{count = 1, match = fish},
			{count = 1, match = greens},
			{count = 1, match = herb},
		},
		mesh = "meshes/SunsDusk/food/o_ml_bo_soup.nif",
		icon = "icons/exploot/food/o_soup_mush.tga",
		description = "A refined dish made by wrapping a fresh fish in fragrant wild greens and cooking it.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_f_crab_spice = {
		name = "Spiced Crab Cakes",
		matchers = {
			{count = 1, match = crab},
			{count = 1, match = fish},
			{count = 1, match = spice},
		},
		mesh = "meshes/SunsDusk/food/o_crabcake_wd.nif",
		icon = "icons/exploot/food/o_crabcake_wd.tga",
		description = "The spice used in preparing this crab pairs perfectly with the flavor of its meat.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_f_salt = {
		name = "Cooked Salted Fish",
		book = "sd_book_cook_food_f_salt",
		matchers = {
			{count = 1, match = fish},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_ml_fshstewg.nif",
		icon = "icons/exploot/food/o_ml_fshstwg.tga",
		description = "A simple dish made by rolling a whole fish in natural rock salt before grilling it.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_f_greens_salt = {
		name = "Roasted Fish with Greens",
		book = "sd_book_cook_food_f_g_salt",
		matchers = {
			{count = 1, match = fish},
			{count = 1, match = greens},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_ml_fishrice.nif",
		icon = "icons/exploot/food/o_ml_fshstwg.tga",
		description = "Thick-cut chunks of seafood and stock provide a satisfying savoriness.",
		mods = {
			magnitudeMult = 1.1,
		},
	},

-- ══════════════════════════════════════════════════════════════════════
-- MEAT RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_meat = {
		name = "Cooked Meat",
		book = "sd_book_cook_food_meat",
		matchers = {
			{count = 2, match = meat},
		},
		mesh = "meshes/SunsDusk/food/o_roastmeat.nif",
		icon = "icons/exploot/food/o_meatroast.tga",
		description = "A juicy, filling snack made by grilling small chunks of meat on a skewer.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_meat_spice = {
		name = "Cooked Spiced Meat",
		book = "sd_book_cook_food_meat_spice",
		matchers = {
			{count = 1, match = meat},
			{count = 1, match = spice},
		},
		mesh = "meshes/SunsDusk/food/o_kogo_fern.nif",
		icon = "icons/exploot/food/o_kogo_fern.tga",
		description = "A special spice covers up the scent of the meat, allowing its flavor to shine.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_meat_greens_herb = {
		name = "Steamed Seasoned Meat",
		book = "sd_book_cook_food_meat_g_h",
		matchers = {
			{count = 1, match = meat},
			{count = 1, match = greens},
			{count = 1, match = herb},
		},
		mesh = "meshes/SunsDusk/food/o_ml_anthmeat.nif",
		icon = "icons/exploot/food/o_kogo_fern.tga",
		description = "This meat dish has been wrapped in fragrant leaves and steamed to preserve its moisture.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_meat_fish = {
		name = "Meat and Seafood Fry",
		matchers = {
			{count = 1, match = meat},
			{count = 1, match = fish},
		},
		mesh = "meshes/SunsDusk/food/o_vermrice.nif",
		icon = "icons/exploot/food/o_vermrice.tga",
		description = "A filling dish made by cooking fresh seafood and meat together.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_meat_salt = {
		name = "Salt-Grilled Meat",
		book = "sd_book_cook_food_meat_salt",
		matchers = {
			{count = 1, match = meat},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_kogo_fern.nif",
		icon = "icons/exploot/food/o_kogo_fern.tga",
		description = "Short on ingredients? Just rub some meat in salt and cook it for a simple, tasty dish.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_meat_salt_greens = {
		name = "Cream of Meat Soup",
		book = "sd_book_cook_food_meat_soup",
		matchers = {
			{count = 1, match = meat},
			{count = 1, match = salt},
			{count = 1, match = greens},
		},
		mesh = "meshes/SunsDusk/food/o_ml_m_gulash.nif",
		icon = "icons/exploot/food/o_ml_mmeatsc.tga",
		description = "This nutritious soup contains serious portions of lightly braised meat and many vegetables.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},

-- ══════════════════════════════════════════════════════════════════════
-- FRUIT RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_fruit_greens_herb = {
		name = "Steamed Fruit",
		book = "sd_book_cook_food_fruit_g_h",
		matchers = {
			{count = 1, match = fruit},
			{count = 1, match = greens},
			{count = 1, match = herb},
		},
		mesh = "meshes/SunsDusk/food/o_ml_fruit_i.nif",
		icon = "icons/exploot/food/o_ml_fruit_i.tga",
		description = "A regional dish made by steaming near-ripened fruits in the leaves of fragrant plants.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_fruit = {
		name = "Simmered Fruit",
		book = "sd_book_cook_food_fruit",
		matchers = {
			{count = 2, match = fruit},
		},
		mesh = "meshes/SunsDusk/food/o_hony_porrids.nif",
		icon = "icons/exploot/food/o_hony_porrids.tga",
		description = "This sweet dish is made by heaping tasty fruits into a pan and simmering until tender.",
		isSoup = true,
		mods = {
			magnitudeMult = 1.1,
		},
	},
	
-- ══════════════════════════════════════════════════════════════════════
-- EGG RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_e = {
		name = "Omelet",
		book = "sd_book_cook_food_egg",
		matchers = {
			{count = 2, match = egg},
		},
		mesh = "meshes/SunsDusk/food/o_ml_m_egg.nif",
		icon = "icons/exploot/food/o_ml_megg.tga",
		description = "This simple dish is common all over. Simply fry egg until it's nice and plump.",
		mods = {
			magnitudeMult = 1.1,
		},
	},
	sd_food_e_meat = {
		name = "Sunny Side Up",
		matchers = {
			{count = 1, match = egg},
			{count = 1, match = meat},
		},
		mesh = "meshes/SunsDusk/food/o_alit_egg_m.nif",
		icon = "icons/exploot/food/o_alit_egg_m.tga",
		description = "Dippy eggs and roasted meat makes for an excellent way to begin the day.",
		mods = {
			magnitudeMult = 1.5,
		},
	},
	sd_food_e_greens_salt = {
		name = "Vegetable Omelet",
		book = "sd_book_cook_food_egg_g",
		matchers = {
			{count = 1, match = egg},
			{count = 1, match = greens},
			{count = 1, match = salt},
		},
		mesh = "meshes/SunsDusk/food/o_omlettewd.nif",
		icon = "icons/exploot/food/o_omlettewd.tga",
		description = "The fluffy texture of this omelet is one of the great joys of this dish, as well as life.",
		mods = {
			magnitudeMult = 1.1,
		},
	},

-- ══════════════════════════════════════════════════════════════════════
-- AFFA'S RECIPES
-- ══════════════════════════════════════════════════════════════════════
	sd_food_aff_ar = {
		name = "Ancestor's Rest",
		book = "af_rec_ancestorsrest",
		matchers = {
			-- Hard requirement: one of the ash/bone ingredients
			{count = 1, match = anyOf("ingred_ash_salts_01", "ingred_gravedust_01", "ingred_bonemeal_01")},
			-- Wildcard: any two of these complementary ingredients
			{count = 2, match = anyOf("ingred_wickwheat_01", "ingred_comberry_01", "ingred_bc_hypha_facia", "ingred_marshmerrow_01")},
		},
		mesh = "meshes/SunsDusk/food/o_bonemealstw.nif",
		icon = "icons/exploot/food/o_bonemealstw.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_cs = {
		name = "Coda Soup",
		book = "af_rec_codasoup",
		matchers = {
			-- Hard requirement: coda flower is the key ingredient
			{count = 1, match = exactId("ingred_bc_coda_flower")},
			-- Wildcard: any two of these telvanni ingredients
			{count = 2, match = anyOf("ingred_bc_ampoule_pod", "ingred_bc_hypha_facia", "ingred_marshmerrow_01", "ingred_hound_meat_01", "ingred_willow_anther_01", "ingred_coprinus_01", "ingred_trama_root_01", "food_kwama_egg_01", "food_kwama_egg_02", "ingred_bc_spore_pod")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_coda.nif",
		icon = "icons/exploot/food/o_ml_lumisoup.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_gdm = {
		name = "Girls Daily Meal",
		book = "af_rec_girlsdaily",
		matchers = {
			-- Hard requirements: ash yam and egg are core
			{count = 1, match = exactId("ingred_ash_yam_01")},
			{count = 1, match = egg},
			-- Wildcard: resin for binding
			{count = 1, match = anyOf("ingred_shalk_resin_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_grls.nif", -- detd_cauld_nds_wat_lavafoot.nif
		icon = "icons/exploot/food/o_sndw_egg_s.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	--	sd_food_aff_gpd = {
	--		name = "Graht-Planked Dreugh",
	--		matchers = { "Dreugh Wax", egg, "daedra heart", "fire salt" },
	--		minQuantity = 3,
	--		mesh = "",
	--		icon = "",
	--		description = "",
	--		isSoup = idk,
	--		mods = {
	--			magnitudeMult = 1.2,
	--		},
	--	},
	
	sd_food_aff_hls = {
		name = "Hackle-lo Salad",
		book = "af_rec_hacklesalad",
		matchers = {
			-- Hard requirement: hackle-lo is the namesake
			{count = 1, match = exactId("ingred_hackle-lo_leaf_01")},
			-- Wildcard: any two salad ingredients
			{count = 2, match = anyOf("ingred_willow_anther_01", "ingred_scathecraw_01", "ingred_wickwheat_01", "ingred_russula_01", "ingred_coprinus_01")},
		},
		mesh = "meshes/SunsDusk/food/o_ml_mcrbstw.nif",
		icon = "icons/exploot/food/o_ml_mcrab.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},	
	},
	
	--	sd_food_aff_hf = {
	--		name = "Hero's Feast",
	--		matchers = { "ingred_hackle-lo_leaf_01", "sload soap", "ingred_moon_sugar_01", egg, aff_greens },
	--		minQuantity = 3,
	--		mesh = "",
	--		icon = "",
	--		description = "",
	--		isSoup = idk,
	--		mods = {
	--			magnitudeMult = 1.2,
	--		},
	--	},
	
	sd_food_aff_hs = {
		name = "Hound Sticks",
		book = "af_rec_houndsticks",
		matchers = {
			-- Hard requirement: hound meat is essential
			{count = 1, match = exactId("ingred_hound_meat_01")},
			-- Wildcard: any two garnish ingredients
			{count = 2, match = anyOf("ingred_hackle-lo_leaf_01", "ingred_russula_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_houndsticks.nif",
		icon = "icons/exploot/food/o_bowldrmst.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_ks = {
		name = "Kagouti Steak",
		book = "af_rec_kagoutisteak",
		matchers = {
			-- Hard requirement: kagouti meat
			{count = 1, match = exactId("t_ingfood_meatkagouti_01")},
			-- Hard requirement: salt for seasoning
			{count = 1, match = salt},
			-- Wildcard: garnish
			{count = 1, match = anyOf("ingred_bc_hypha_facia", "ingred_scathecraw_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_Kagoutisteaks.nif",
		icon = "icons/exploot/food/o_ml_mmeatsc.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_m = {
		name = "Marshwater",
		book = "af_rec_marshwater",
		matchers = {
			-- Hard requirements: the three core marsh ingredients
			{count = 1, match = exactId("ingred_saltrice_01")},
			{count = 1, match = salt},
			{count = 1, match = exactId("ingred_marshmerrow_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_mrshwat.nif",
		icon = "icons/exploot/food/o_tannapordg.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_my = {
		name = "Merrowed Yams",
		book = "af_rec_merrowedyams",
		matchers = {
			-- Hard requirements: ash yam and marshmerrow
			{count = 1, match = exactId("ingred_ash_yam_01")},
			{count = 1, match = exactId("ingred_marshmerrow_01")},
			-- Wildcard: salt or roobrush for seasoning
			{count = 1, match = anyOf("ingred_salt_01", "ingred_void_salts_01", "ingred_frost_salts_01", "ingred_fire_salts_01", "ingred_roobrush_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_mwyam.nif",
		icon = "icons/exploot/food/o_ml_mmtash.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_ms = {
		name = "Mudcrab in the Shell",
		book = "af_rec_mudcrabshell",
		matchers = {
			-- Hard requirements: crab meat and salt
			{count = 1, match = exactId("ingred_crab_meat_01")},
			{count = 1, match = salt},
			-- Wildcard: any garnish
			{count = 1, match = anyOf("ingred_kresh_fiber_01", "ingred_russula_01", "ingred_saltrice_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_crabinshell.nif",
		icon = "icons/exploot/food/o_ml_brncpoor.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_ps = {
		name = "Pucker and Squeak",
		book = "af_rec_puckersqueek",
		matchers = {
			-- Hard requirement: marshmerrow base
			{count = 1, match = exactId("ingred_marshmerrow_01")},
			-- Wildcard: any two of these squishy/tangy ingredients
			{count = 2, match = anyOf("ingred_scrib_jelly_01", "ingred_scuttle_01", "ingred_scathecraw_01", "food_kwama_egg_01", "food_kwama_egg_02")},
		},
		mesh = "meshes/SunsDusk/food/o_ml_scutsup.nif",
		icon = "icons/exploot/food/o_ml_scutsp.tga", 
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_cr = {
		name = "Crispy Rat",
		book = "af_rec_rats", -- also covers sd_food_aff_rs
		matchers = {
			-- Hard requirements: rat meat and greens
			{count = 1, match = exactId("ingred_rat_meat_01")},
			{count = 1, match = greens},
			-- Wildcard: crispy coating ingredient
			{count = 1, match = anyOf("ingred_ash_salts_01", "ingred_scuttle_01", "ingred_scathecraw_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_richrat.nif",
		icon = "icons/exploot/food/o_shrmratstw.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_rs = {
		name = "Rat Soup",
		book = "af_rec_rats", -- also covers sd_food_aff_cr
		matchers = {
			-- Hard requirements: rat meat and ash yam (core soup ingredients)
			{count = 1, match = exactId("ingred_rat_meat_01")},
			{count = 1, match = exactId("ingred_ash_yam_01")},
			-- Wildcard: any soup herb/green
			{count = 1, match = anyOf("ingred_wickwheat_01", "ingred_hackle-lo_leaf_01", "ingred_ash_salts_01", "ingred_bittergreen_petals_01")},
		},
		mesh = "meshes/SunsDusk/food/o_shrmratstw.nif",
		icon = "icons/exploot/food/o_shrmratstw.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_ss = {
		name = "Scurryscales",
		book = "af_rec_scurryfish",
		matchers = {
			-- Hard requirement: scales
			{count = 1, match = exactId("ingred_scales_01")},
			-- Wildcard: any two complementary ingredients
			{count = 2, match = anyOf("ingred_scathecraw_01", "ingred_bittergreen_petals_01", "ingred_scrib_jelly_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_fish.nif",
		icon = "icons/exploot/food/o_ml_fshyamg.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_sr = {
		name = "Scuttlerice",
		book = "af_rec_scuttlerice",
		matchers = {
			-- Hard requirements: scuttle and saltrice
			{count = 1, match = exactId("ingred_scuttle_01")},
			{count = 1, match = exactId("ingred_saltrice_01")},
			-- Wildcard: garnish
			{count = 1, match = anyOf("t_ingfood_olives_01", "t_ingspice_pepper_01", "food_kwama_egg_01", "food_kwama_egg_02")},
		},
		mesh = "meshes/SunsDusk/food/o_kogo_fern.nif",
		icon = "icons/exploot/food/o_kogo_fern.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_sfst = {
		name = "Slaughterfish Steak",
		book = "af_rec_sfsteak",
		matchers = {
			-- Hard requirements: scales and fish
			{count = 1, match = exactId("ingred_scales_01")},
			{count = 1, match = fish},
			-- Wildcard: herb garnish
			{count = 1, match = anyOf("ingred_chokeweed_01", "ingred_green_lichen_01", "ingred_heather_01")},
		},
		mesh = "meshes/SunsDusk/food/o_ml_fshstewg.nif",
		icon = "icons/exploot/food/o_ml_fshstwg.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_sicksoup = {
		name = "Sick Soup",
		book = "af_rec_sicksoup",
		matchers = {
			-- Hard requirement: chokeweed (medicinal)
			{count = 1, match = exactId("ingred_chokeweed_01")},
			-- Hard requirement: salt
			{count = 1, match = salt},
			-- Wildcard: any healing/bitter ingredient
			{count = 1, match = anyOf("ingred_muck_01", "ingred_comberry_01", "ingred_trama_root_01", "ingred_hound_meat_01", "ingred_red_lichen_01")},
		},
		mesh = "meshes/SunsDusk/food/o_fish_soup.nif",
		icon = "icons/exploot/food/o_fishsoup_sml.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_ssss = {
		name = "Sweet, Sweet Shalk Stalks",
		book = "af_rec_sweetshalk",
		matchers = {
			-- Hard requirements: moon sugar and shalk resin (the sweet combo)
			{count = 1, match = exactId("ingred_moon_sugar_01")},
			{count = 1, match = exactId("ingred_shalk_resin_01")},
			-- Wildcard: stalk/grain base
			{count = 1, match = anyOf("ingred_wickwheat_01", "ingred_marshmerrow_01")},
		},
		mesh = "meshes/SunsDusk/food/o_wick_gruel2.nif",
		icon = "icons/exploot/food/o_wick_gruel2.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_yc = {
		name = "Yam Chips",
		book = "af_rec_yamchips",
		matchers = {
			-- Hard requirements: ash yam and egg (for batter)
			{count = 1, match = exactId("ingred_ash_yam_01")},
			{count = 1, match = egg},
			-- Wildcard: any flavoring
			{count = 1, match = anyOf("ingred_hound_meat_01", "ingred_hackle-lo_leaf_01", "ingred_kwama_cuttle_01", "ingred_roobrush_01", "ingred_bittergreen_petals_01", "ingred_scathecraw_01")},
		},
		mesh = "meshes/SunsDusk/food/o_yammeat.nif",
		icon = "icons/exploot/food/o_ashmeat.tga",
		description = "",
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_cms = {
		name = "Crab and Scuttle Medley",
		matchers = {
			-- Hard requirements: scuttle and crab meat
			{count = 1, match = exactId("ingred_scuttle_01")},
			{count = 1, match = exactId("ingred_crab_meat_01")},
			-- Wildcard: any binding/grain ingredient
			{count = 1, match = anyOf("ingred_wickwheat_01", "ingred_bittergreen_petals_01", "food_kwama_egg_01", "food_kwama_egg_02")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_crabsctl.nif",
		icon = "icons/exploot/food/o_ml_scutsp.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_yattle = {
		name = "Yattle",
		book = "af_rec_yattle",
		matchers = {
			-- Hard requirements: ash yam and egg
			{count = 1, match = exactId("ingred_ash_yam_01")},
			{count = 1, match = egg},
			-- Wildcard: any protein/grain
			{count = 1, match = anyOf("ingred_wickwheat_01", "ingred_scuttle_01", "ingred_scrib_jerky_01", "ingred_hound_meat_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_yttle.nif",
		icon = "icons/exploot/food/o_ml_scutash.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	sd_food_aff_har = {
		name = "The Hound and the Rat",
		matchers = {
			-- Hard requirements: the two namesake meats
			{count = 1, match = exactId("ingred_rat_meat_01")},
			{count = 1, match = exactId("ingred_hound_meat_01")},
			-- Wildcard: any complementary ingredient
			{count = 1, match = anyOf("ingred_ash_salts_01", "food_kwama_egg_01", "food_kwama_egg_02", "ingred_scuttle_01", "ingred_saltrice_01")},
		},
		mesh = "meshes/SunsDusk/food/detd_cauld_nds_wat_houndrat.nif",
		icon = "icons/exploot/food/o_ml_meatric.tga",
		description = "",
		isSoup = true,
		mods = {
			magnitudeMult = 1.2,
		},
	},
	
	-- gonna use either meat or meatsoup, idk yet
	
	-- Meat (ribs)
	sd_food_def_meat = {
		name = "Stew",
		matchers = {},
		fallback = true,
		mesh = "meshes/SunsDusk/food/o_roastribs.nif",
		icon = "icons/exploot/food/o_ribroast.tga",
		description = "",
		mods = {},
	},
	
	-- Meat (soup)
	sd_food_def_meatsoup = {
		name = "Stew",
		matchers = {},
		fallback = true,
		mesh = "meshes/SunsDusk/food/o_bw_meat.nif",
		icon = "icons/exploot/food/o_smsoupb.tga",
		description = "",
		isSoup = true,
		mods = {},
	},
	
	-- Mixed Bowl
	sd_food_def_vegan = {
		name = "Stew",
		matchers = {},
		fallback = true,
		mesh = "meshes/SunsDusk/food/o_cact_soup.nif",
		icon = "icons/exploot/food/o_cact_soup.tga",
		description = "",
		isSoup = true,
		mods = {},
	},
	
	-- Very green soup with green slices on top
	sd_food_def_mixed = {
		name = "Stew",
		matchers = {},
		fallback = true,
		mesh = "meshes/SunsDusk/food/o_bw_soup_a.nif",
		icon = "icons/exploot/food/o_smsoupa.tga",
		description = "",
		isSoup = true,
		mods = {},
	},

-- ══════════════════════════════════════════════════════════════════════
-- DAEDRIC RECIPE (Vaermina's Kitchen quest)
-- ══════════════════════════════════════════════════════════════════════
	sd_food_vaermina = {
		name = "Vaermina's Broth",
		minLevel = 100,
		matchers = {
			{count = 1, match = anyOf("ingred_belladonna_01", "ingred_belladonna_02")},
			{count = 1, match = exactId("ingred_bc_bungler's_bane")},
			{count = 1, match = exactId("ingred_lloramor_spines_01")},
		},
		mesh = "meshes/SunsDusk/food/vaermina.nif",
		icon = "icons/SunsDusk/vaermina.tga",
		description = "Smells kinda sweet but stings in your nose",
		isSoup = true,
		mods = {isToxic = true},
	},
	sd_food_daedric = {
		name = "Daedric Stew",
		minLevel = 200,
		matchers = {
			{count = 1, match = exactId("ingred_daedras_heart_01")},
			{count = 1, match = exactId("ingred_ghoul_heart_01")},
			{count = 1, match = exactId("t_ingcrea_humanheart")},
			{count = 1, match = exactId("t_ingcrea_mummyheart_01")},
		},
		mesh = "meshes/SunsDusk/food/daedric.nif",
		icon = "icons/SunsDusk/daedric.tga",
		description = "Looks and smells awful. Are you sure you want to eat this?",
		isSoup = true,
		mods = {isToxic = true},
	},
}

for id, data in pairs(COOKING_RECIPES) do
	data.id = id
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Recipe Matching Logic                                                │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Match ingredients against a single recipe
-- Returns true if all matchers have enough matching ingredients
-- Each matcher specifies {count, match} where count ingredients must satisfy match
-- Each ingredient can only satisfy ONE matcher (no double-counting)
local function matchRecipe(recipe, ingredients)
	local totalRequired = 0
	for _, matcher in ipairs(recipe.matchers) do
		totalRequired = totalRequired + matcher.count
	end
	
	if #ingredients < totalRequired then
		return false
	end
	
	-- Try to assign ingredients to matchers
	-- Since ingredient order matters for greedy matching, we try all permutations
	-- (n=4 -> 24 attempts; vaerminaPerk allows up to 4 ingredients)
	local function tryMatch(ingredientOrder)
		local used = {}
		for _, matcher in ipairs(recipe.matchers) do
			local matchCount = 0
			for _, i in ipairs(ingredientOrder) do
				if not used[i] and matcher.match(ingredients[i]) then
					used[i] = true
					matchCount = matchCount + 1
					if matchCount >= matcher.count then
						break
					end
				end
			end
			if matchCount < matcher.count then
				return false
			end
		end
		return true
	end

	local n = #ingredients
	if n == 0 then return totalRequired == 0 end

	-- Heap's algorithm: enumerate permutations of indices 1..n in place
	local order = {}
	for i = 1, n do order[i] = i end
	local c = {}
	for i = 1, n do c[i] = 0 end

	if tryMatch(order) then return true end
	local i = 1
	while i <= n do
		if c[i] < i then
			if i % 2 == 1 then
				order[1], order[i] = order[i], order[1]
			else
				order[c[i]+1], order[i] = order[i], order[c[i]+1]
			end
			if tryMatch(order) then return true end
			c[i] = c[i] + 1
			i = 1
		else
			c[i] = 0
			i = i + 1
		end
	end
	return false
end

-- Calculate total matcher count for recipe specificity
local function getMatcherWeight(recipe)
	local weight = 0
	for _, matcher in ipairs(recipe.matchers) do
		weight = weight + matcher.count
	end
	-- Bonus weight for having more distinct matchers (more specific recipes)
	weight = weight + (#recipe.matchers * 0.1)
	return weight
end

-- Find the best matching recipe for a set of ingredients
-- Prefers recipes with higher matcher weight (more specific)
-- Falls back to appropriate default based on ingredient green pact status
local function findMatchingRecipe(ingredients, greenPact, playerLevel)
	local bestRecipe = nil
	local bestWeight = 0
	
	for _, recipe in pairs(COOKING_RECIPES) do
		local levelOk = not recipe.minLevel or (playerLevel and playerLevel >= recipe.minLevel)
		if levelOk and not recipe.fallback and matchRecipe(recipe, ingredients) then
			local weight = getMatcherWeight(recipe)
			if weight > bestWeight then
				bestRecipe = recipe
				bestWeight = weight
			end
		end
	end
	
	if bestRecipe then
		log(4, bestRecipe.id)
		return bestRecipe
	end
	
	-- No specific recipe matched - determine fallback from ingredient data
	local hasGreenPact = false
	local hasNonGreenPact = false
	
	for _, ing in ipairs(ingredients) do
		if ing.data then
			if ing.data.isGreenPact then
				hasGreenPact = true
			else
				hasNonGreenPact = true
			end
		end
	end
	
	local fallback
	if hasGreenPact and not hasNonGreenPact then
		fallback = COOKING_RECIPES.sd_food_def_meat
	elseif hasNonGreenPact and not hasGreenPact then
		fallback = COOKING_RECIPES.sd_food_def_vegan
	else
		fallback = COOKING_RECIPES.sd_food_def_mixed
	end
	
	log(4, fallback and fallback.id or "no fallback")
	return fallback
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Exports                                                              │
-- ╰──────────────────────────────────────────────────────────────────────╯

return  {
	recipes = COOKING_RECIPES,
	findMatchingRecipe = findMatchingRecipe,
	matchRecipe = matchRecipe,
	
	-- Export individual matchers for use in module_cooking.lua
	matchers = {
		mushroom = mushroom,
		fish = fish,
		bread = bread,
		meat = meat,
		greens = greens,
		fruit = fruit,
		spice = spice,
		salt = salt,
		egg = egg,
		herb = herb,
		crab = crab,
	},
	
	-- Export matcher factories for custom recipes
	anyOf = anyOf,
	exactId = exactId,
}