--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk					                                       │
│  Bathing and Cleanliness                     						   │
╰──────────────────────────────────────────────────────────────────────╯
]]
-- IDS ARE LOWER CASE IN OPENMW
require('scripts.SunsDusk.settings.clean_settings')

-- Uncomment for debugmode:
local function log() end

-- Add tooltip entries for bathing buffs
-- Special soap buffs
-- add pattern for modded soaps
tooltips["sd_c_sp_soap_01"] 		= "Lux Soap: +5 Personality, Reflect 5%"
tooltips["sd_c_sp_soap_02"] 		= "Lux Soap: +5 Personality, Sanctuary 5"
tooltips["sd_c_sp_soap_03"] 		= "Lux Soap: +5 Personality, Chameleon 10"
tooltips["sd_c_sp_soap_04"] 		= "Lux Soap: +5 Personality, Resist Frost 15%"
tooltips["sd_c_sp_soap_05"] 		= "Lux Soap: +5 Personality, Night Eye 15"
tooltips["sd_c_sp_soap_06"] 		= "Lux Soap: +5 Personality, Water Walking"
tooltips["sd_c_sp_soap_07"] 		= "Lux Soap: +5 Personality, Water Breathing"
tooltips["sd_c_sp_soap_08"] 		= "Lux Soap: +5 Personality, Resist Frost 15%"
	
-- House bath buffs	
tooltips["sd_c_sp_bath_h"] 			= "Hlaalu Bath: +5 Agility"
tooltips["sd_c_sp_bath_r"] 			= "Redoran Bath: +5 Strength"
tooltips["sd_c_sp_bath_t"] 			= "Telvanni Bath: +5 Intelligence, Resist Magicka 10%"
tooltips["sd_c_sp_bath_tt"] 		= "Temple Bath: +5 Personality"
tooltips["sd_c_sp_bath_om"] 		= "Mud Bath: +5 Endurance, Resist Common Disease 15%"
tooltips["sd_c_sp_bath_i"] 			= "Indoril Bath: +3 Agility, +3 Strength"
tooltips["sd_c_sp_bath_imp"] 		= "Imperial Bath: +2 Agility, +2 Intelligence, +3 Luck"
tooltips["sd_c_sp_bath_n"] 			= "Nord Bath: +3 Strength, +3 Willpower"

-- Bug musk buff
tooltips["sd_c_sp_bath_t_bug_musk"] = "Telvanni Bug Musk: +10 Personality, Fortify Speechcraft 10pts"

--[[local locationDirtModifiers = {
	isCave 			= 1.25, -- Caves are dusty
	isMine 			= 1.5,  -- Mines are dirty
	isTomb 			= 1.25, -- Tombs are dusty
	isSewer 		= 2.5,  -- Sewers/Underworks are the worst
	isTemple 		= 0.5,  -- Temples are clean, reduce dirt rate
	isDaedric 		= 1.25, -- Daedric shrines are somewhat dirty
	isDwemer 		= 1.5,  -- Dwemer ruins are old and dusty
}

-- Weather types that increase dirtiness
local dirtyWeatherTypes = { -- dirtyWeatherTypes // locationDirtModifiers
	["ash"] 		= 3.0, -- Ash storms
	["ashstorm"] 	= 3.0, -- Ash storms
	["blight"] 		= 4.0, -- Blight storms (also disease risk)
	["blizzard"] 	= 1.4, -- Blizzards (snow/ice)
	["snow"] 		= 1.25, -- Snow doesn't really dirty you
}]]
-- interior dirt modifier tooltips
tooltips["isCave"] 				= "25% increase while in a cave"
tooltips["isMine"] 				= "50% increase while in a mine"
tooltips["isTomb"] 				= "25% increase while in a tomb"
tooltips["isSewer"] 			= "150% increase while in Sewers and Underworks"
tooltips["isTemple"] 			= "50% decrease while in a Temple"
tooltips["isDaedric"] 			= "25% increase while in Daedric Ruins"
tooltips["isDwemer"] 			= "50% increase while in Dwemer Ruins"

-- weather modifier tooltips
tooltips["ash"]				= "300% increase while in an ash storm"
tooltips["ashstorm"]		= "300% increase while in an ash storm"
tooltips["blight"] 			= "400% increase while in a blight storm"
tooltips["blizzard"]		= "40% increase while in a blizzard"
tooltips["snow"]			= "25% increase while in snow"
 	
------------------------------------------------------------------------------------------------------------------------------------------------------

-- covered helms
-- bonemold, cephalopod, chitin, daedric_helm, dust, ebony_closed_helm, iron_helmet, mole_crab_helm, morag_tong_helm, netch_leather, orcish_helm, steel_helm_arg, watchman_helm
local CONST_CLEAN_STAGES = 6

BUGMUSK_CHARGES = 3
TOWEL_CHARGES = 8
CLOTH_CHARGES = 3
SOAP_CHARGES = 5
BATHPRODUCT_CHARGES = 3

local function getMaxCharges(productType, itemId)
	if productType == "towel" then
		if itemId and itemId:find("towel") then
			return TOWEL_CHARGES
		else
			return CLOTH_CHARGES
		end
	end
	return _G[productType:upper().."_CHARGES"] or 1
end

-- All soap items (can be interacted with in overworld)
-- Includes ingredient types and misc types
local allSoapItems = {
	["ingred_sload_soap_01"] = true,
	-- TD soaps (have their own spells)
	["t_com_soap_01"]  					= true,
	["t_com_soap_02"]  					= true,
	["t_com_soap_03"]  					= true,
	["t_com_soap_04"]  					= true,
	["t_com_soap_05"]  					= true,
	["ab_misc_soap01"] 					= true, -- OAAB
	-- S3 soaps					
	["s3_soap"]		   					= true,
	["s3_soapinv_01"]  					= true,
	["s3_soapinv_02"]  					= true,
	["s3_soapinv_03"]  					= true,
	["s3_soapinv_04"]  					= true,
	["s3_soapinv_05"]  					= true,
	["s3_soapinv_06"]  					= true,
	["s3_soapinv_07"]  					= true,
	["s3_soapinv_08"]  					= true,
	-- Beautiful Haunts plain soap
	["bh_ko_soap_plain_01_s"] = true,
	--["ab_furn_barrel01water"] = true,
	-- korona's Soap
	["ko_00_herbal_soap"] 				= true,
	["ko_00_herbal_soap_b"] 			= true,
	["ko_00_herbal_soap_p"] 			= true,
	["ko_00_herbal_soap_r"] 			= true,
	["ko_00_herbal_soap_y"] 			= true,
	["ko_golden_bath_powder"] 			= true,
	["ko_round_soap_cammomile"] 		= true,
	["ko_round_soap_cherub"] 			= true,
	["ko_round_soap_d_blue"] 			= true,
	["ko_round_soap_d_green"] 			= true,
	["ko_round_soap_d_beige"] 			= true,
	["ko_round_soap_d_orange"] 			= true,
	["ko_round_soap_d_pink"] 			= true,
	["ko_round_soap_d_purple"] 			= true,
	["ko_round_soap_d_white"] 			= true,
	["ko_round_soap_d_yellow"] 			= true,
	["ko_round_soap_galley_01"] 		= true,
	["ko_round_soap_galley_02"] 		= true,
	["ko_round_soap_lavender"] 			= true,
	["ko_round_soap_shave"] 			= true,
	["ko_round_soap_shave_col1"] 		= true,
	["ko_round_soap_shave_col3"] 		= true,
	["ko_round_soap_shave_rose"] 		= true,
	["ko_round_soap_celestial"] 		= true,
	["ko_round_soap_complexion"] 		= true,
	["ko_round_soap_gardeners"] 		= true,
	["ko_round_soap_loofa"] 			= true,
	["ko_round_soap_shave_col2"] 		= true,
	["ko_round_soap_mint"] 				= true,
	["ko_round_soap_moon"] 				= true,
	["ko_round_soap_oatmeal"] 			= true,
	["ko_round_soap_peach"] 			= true,
	["ko_round_soap_rose"] 				= true,
	["ko_round_soap_shell"] 			= true,
	["ko_skull_Powder"] 				= true,
	["ko_soap_ hers"] 					= true,
	["ko_soap_ his"] 					= true,
	["ko_soap_champs"] 					= true,
	["ko_soap_cherry"] 					= true,
	["ko_soap_domestic"] 				= true,
	["ko_soap_flower_01"] 				= true,
	["ko_soap_flower_02"] 				= true,
	["ko_soap_j_cinnamon"] 				= true,
	["ko_soap_j_garden"] 				= true,
	["ko_soap_j_island"] 				= true,
	["ko_soap_j_magnolia"] 				= true,
	["ko_soap_j_melon"] 				= true,
	["ko_soap_j_serenity"] 				= true,
	["ko_soap_J_willow"] 				= true,
	["ko_soap_lav_01"] 					= true,
	["ko_soap_lav_02"] 					= true,
	["ko_soap_peony"] 					= true,
	["ko_soap_roses"] 					= true,
	["ko_soap_sea"] 					= true,
	["ko_soap_tea_rose"] 				= true,
	["ko_soap_veg_pink"] 				= true,
	["ko_soap_verv"] 					= true,
	["ko_soap_almond"] 					= true,
	["ko_soap_angel"] 					= true,
	["ko_soap_apples"] 					= true,
	["ko_soap_bebe"] 					= true,
	["ko_soap_belle_01"] 				= true,
	["ko_soap_belle_02"] 				= true,
	["ko_soap_belle_03"] 				= true,
	["ko_soap_bfly"] 					= true,
	["ko_soap_casewellmasey"] 			= true,
	["ko_soap_ecc"] 					= true,
	["ko_soap_eiffel"] 					= true,
	["ko_soap_g_01"] 					= true,
	["ko_soap_ginger"] 					= true,
	["ko_soap_grape_01"] 				= true,
	["ko_soap_grape_02"] 				= true,
	["ko_soap_grapefruit"] 				= true,
	["ko_soap_greentea"] 				= true,
	["ko_soap_hemp"] 					= true,
	["ko_soap_kiwi"] 					= true,
	["ko_soap_lavande_01"] 				= true,
	["ko_soap_lavande_02"] 				= true,
	["ko_soap_lavande_03"] 				= true,
	["ko_soap_leblanc_01"] 				= true,
	["ko_soap_leblanc_02"] 				= true,
	["ko_soap_leblanc_03"] 				= true,
	["ko_soap_lemon"] 					= true,
	["ko_soap_lilac"] 					= true,
	["ko_soap_mar"] 					= true,
	["ko_soap_martin"] 					= true,
	["ko_soap_plain_01"] 				= true,
	["ko_soap_plain_02"] 				= true,
	["ko_soap_plain_03"] 				= true,
	["ko_soap_plain_04"] 				= true,
	["ko_soap_plain_05"] 				= true,
	["ko_soap_pre"] 					= true,
	["ko_soap_prose"] 					= true,
	["ko_soap_province_01"] 			= true,
	["ko_soap_province_02"] 			= true,
	["ko_soap_province_03"] 			= true,
	["ko_soap_rotager_lavender"] 		= true,
	["ko_soap_rotager_lilac"] 			= true,
	["ko_soap_rotager_rosemary"] 		= true,
	["ko_soap_savon"] 					= true,
---- ["KO_GROSS_soap_blood"]            = true,
---- ["KO_GROSS_soap_bone_1"]           = true,
---- ["KO_GROSS_soap_bone_2"]           = true,
---- ["KO_GROSS_soap_brain"]            = true,
---- ["KO_GROSS_soap_eye Eye"]          = true,
---- ["KO_GROSS_soap_flesh"]            = true,
---- ["KO_GROSS_soap_hand"]             = true,
---- ["KO_GROSS_soap_liver"]            = true,
---- ["KO_GROSS_soap_rib"]              = true,
---- ["KO_GROSS_soap_rotten"]           = true,
---- ["KO_GROSS_soap_teeth"]            = true,
---- ["KO_GROSS_soap_vein"]             = true,
	
}

-- All towel items (can be interacted with in overworld for drying off)
-- Works similarly to soap but doesn't require water
local allTowelItems = {
	["comtowel"] = true,
	["s3_towel"] = true,
}

-- Pattern matching for towel items (for Tamriel Data and other mods)
local towelPatterns = {
	"misc_de_foldedcloth", -- Vanilla folded cloth (misc_de_foldedcloth00, etc.)
	"misc_decloth",
	"misc_de_cloth",
	"t_com_cloth",      -- Tamriel Data common cloths
	"t_com_towel",      -- Tamriel Data towels
	"comtowel",			-- OAAB
	"ko_bath_f_towel",  -- KO bath towels
	"ko_bath_towel",    -- KO bath towels
	"_towelwrap_",
	"ko_towel_",
	"washcloth",
}

-- Check if an item is a towel (either direct match or pattern match)
local function isTowelItem(recordId)
	if not recordId then
		return false
	end
	if not CLEAN_ENABLE_TOWELS then
		return false
	end
	-- Direct match
	if allTowelItems[recordId] then
		--log(3, "[SunsDusk:Clean] isTowelItem: MATCH (direct lower):", recordId)
		return true
	end
	-- Pattern match
	for _, pattern in ipairs(towelPatterns) do
		if recordId:find(pattern, 1, true) then
			--log(3, "[SunsDusk:Clean] isTowelItem: MATCH (pattern):", pattern)
			return true
		end
	end
	--log(3, "[SunsDusk:Clean] isTowelItem: NO MATCH for", recordId)
	return false
end


local function isSoapItem(recordId)
	if CLEAN_SOAP_SLOAD and recordId == "ingred_sload_soap_01" then
		return false
	end
	return allSoapItems[recordId]
end

-- TD and OAAB soap spells 
-- add buffs when player is "glowing" (state 0), meaning they have just bathed
local soapBuffs = {
	-- TD soap
	["t_com_soap_01"]  				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["t_com_soap_02"]  				= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["t_com_soap_03"]  				= "sd_c_sp_soap_03", 	-- purple soap ; Fortify Personality 5, Chameleon
	["t_com_soap_04"]  				= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["t_com_soap_05"]  				= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	-- OAAB soap		
	["AB_Misc_Soap01"] 				= "sd_c_sp_soap_07", 	-- red soap ; +5 Personality, WaterBreathing
	
	-- baths of vvardenfell buffs:
	["s3_soapinv_01"]  				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire	
	["s3_soapinv_02"]  				= "sd_c_sp_soap_04",	-- purple soap ; +5 Personality, +15% Resist Frost	
	["s3_soapinv_03"]  				= "sd_c_sp_soap_05",	-- yellow/brown soap ; +5 Personality, Night Eye
	["s3_soapinv_04"]  				= "sd_c_sp_soap_06",	-- blue soap ; +5 Personality, WaterWalking
	["s3_soapinv_05"]  				= "sd_c_sp_soap_02",	-- blue soap ; +5 Personality, Sanctuary
	["s3_soapinv_06"]  				= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["s3_soapinv_07"]  				= "sd_c_sp_soap_03", 	-- yellow/brown soap ; +5 Personality, Chameleon
	["s3_soapinv_08"]  				= "sd_c_sp_soap_01",	-- blue soap ; +5 Personality, Reflect
	
	--korona soap
	["ko_00_herbal_soap"]			= "sd_c_sp_soap_03", 	-- idk soap ; Fortify Personality 5, Chameleon
	["ko_00_herbal_soap_b"] 		= "sd_c_sp_soap_06",	-- blue soap ; +5 Personality, WaterWalking
	["ko_00_herbal_soap_p"] 		= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_00_herbal_soap_r"] 		= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_00_herbal_soap_y"] 		= "sd_c_sp_soap_05",	-- yellow/brown soap ; +5 Personality, Night Eye
 -- ["ko_golden_bath_powder"] 		=
	["ko_round_soap_cammomile"] 	= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_round_soap_cherub"] 		= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_round_soap_d_blue"] 		= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["ko_round_soap_d_beige"] 		= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_round_soap_d_orange"] 		= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_round_soap_d_pink"] 		= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_round_soap_d_green"]		= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_round_soap_d_purple"]		= "sd_c_sp_soap_03", 	-- purple soap ; Fortify Personality 5, Chameleon
	["ko_round_soap_d_white"] 		= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_round_soap_d_yellow"] 		= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_round_soap_galley_01"] 	= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_round_soap_galley_02"] 	= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_round_soap_lavender"] 		= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_round_soap_shave"] 		= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire	
	["ko_round_soap_shave_col1"] 	= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire	
	["ko_round_soap_shave_col3"] 	= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_round_soap_shave_rose"] 	= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_round_soap_celestial"] 	= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_round_soap_complexion"] 	= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["ko_round_soap_gardeners"] 	= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_round_soap_loofa"] 		= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_round_soap_shave_col2"] 	= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_round_soap_mint"] 			= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_round_soap_moon"] 			= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_round_soap_oatmeal"] 		= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_round_soap_peach"] 		= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_round_soap_rose"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_round_soap_shell"] 		= "sd_c_sp_soap_06",	-- blue soap ; +5 Personality, WaterWalking
--	["ko_skull_Powder"] 			= 
	["ko_soap_ hers"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_ his"] 				= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_champs"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_cherry"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_domestic"] 			= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_soap_flower_01"] 			= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_flower_02"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_j_cinnamon"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_j_garden"] 			= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_j_island"] 			= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["ko_soap_j_magnolia"] 			= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_j_melon"] 			= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_j_serenity"] 			= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_J_willow"] 			= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_lav_01"] 				= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_lav_02"] 				= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_peony"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_roses"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_sea"] 				= "sd_c_sp_soap_06",	-- blue soap ; +5 Personality, WaterWalking
	["ko_soap_tea_rose"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_veg_pink"] 			= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_verv"] 				= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_almond"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_angel"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_apples"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_bebe"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_belle_01"] 			= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_belle_02"] 			= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_belle_03"] 			= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["ko_soap_bfly"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_casewellmasey"] 		= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_ecc"] 				= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_eiffel"] 				= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_soap_g_01"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_ginger"] 				= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_grape_01"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_grape_02"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_grapefruit"] 			= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_soap_greentea"] 			= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_hemp"] 				= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_kiwi"] 				= "sd_c_sp_soap_03", 	-- green soap ; Fortify Personality 5, Chameleon
	["ko_soap_lavande_01"] 			= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_lavande_02"] 			= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_lavande_03"] 			= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_leblanc_01"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_leblanc_02"] 			= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_leblanc_03"] 			= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_lemon"] 				= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_soap_lilac"] 				= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_mar"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_martin"] 				= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_plain_01"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_plain_02"] 			= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_plain_03"] 			= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_plain_04"] 			= "sd_c_sp_soap_05",	-- yellow soap ; Fortify Personality 5, Night Eye
	["ko_soap_plain_05"] 			= "sd_c_sp_soap_07",	-- blue soap ; +5 Personality, WaterBreathing
	["ko_soap_pre"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
	["ko_soap_prose"] 				= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_province_01"] 		= "sd_c_sp_soap_02",	-- orange soap ; Fortify Personality 5, Sanctuary
	["ko_soap_province_02"] 		= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_province_03"] 		= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_rotager_lavender"] 	= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_rotager_lilac"] 		= "sd_c_sp_soap_04",	-- red soap ; Fortify Personality 5, Resist Frost
	["ko_soap_rotager_rosemary"] 	= "sd_c_sp_soap_08", 	-- orange soap ; +5 Personality, +15% Resist Fire
	["ko_soap_savon"] 				= "sd_c_sp_soap_01",	-- white soap ; Fortify Personality 5, Reflect 
}

-- Plain soaps - these remove any existing special soap buff when used
local plainSoaps = {
	["ingred_sload_soap_01"] = true,
	["s3_soap"] = true,
	["bh_ko_soap_plain_01_s"] = true,
}

-- Bug musk - enhances the bath significantly
local bugMuskId = { 
	["potion_t_bug_musk_01"] 		= true,	-- spell is sd_c_sp_bath_t_bug_mus]k
--	["ko_blood musk"]               = true,
--	["ko_body_lotion"]              = true,
--	["ko_cologne"]                  = true,
--	["ko_cologne_2"]                = true,
--	["ko_darkpassion"]              = true,
--	["ko_eveninghaze"]              = true,
--	["ko_moonlust"]                 = true,
--	["ko_shampoo"]                  = true,
--	["ko_aftershave"]               = true,
--	["ko_parfuem"]                  = true,
--	["ko_parfuem_pink"]             = true,
--	["ko_parrfuem_red"]             = true,
--	["luce_dim_de_perfume_bug"]     = true,
--	["luce_dim_de_perfume_cm"]      = true,
--	["luce_dim_de_perfume_ex1"]     = true,
--	["luce_dim_de_perfume_ex2"]     = true,
--	["luce_dim_perfume_bl"]         = true,
--	["luce_dim_perfume_bll"]        = true,
--	["luce_dim_perfume_g"]          = true,
--	["luce_dim_perfume_gg"]         = true,
--	["luce_dim_perfume_ph"]         = true,
--	["luce_dim_perfume_ph_uni"]     = true,
--	["luce_dim_perfume_r"]          = true,
--	["luce_dim_perfume_r_uni"]      = true,
--	["luce_dim_perfume_rw"]         = true,
--	["luce_dim_perfume_y"]          = true,
--	["luce_rw_aftershave"]          = true,
--	["ko_bath_salts"]		        = true,
--	["luce_bath_salts"]		        = true,
--	["ko_bath_oil"]		            = true,
--	["ko_bath_oil_gtea"]		    = true,
--	["ko_bath_oil_lavender"]	    = true,
--	["ko_bath_oil_vanilla "]	    = true,
--	["ko_bubblebath"]		        = true,
-- bath powder ["ko_golden_bath_powder"]
}

local bathProducts = {
	-- Bath salts
	salts = {
		patterns 	= { "bath_salts" }, -- ko_bath_salts ; luce_bath_salts
		buff 		= "sd_c_sp_bath_salt",
		message 	= "The bath salts invigorate your body.",
		tooltipMessage 	= "Use bath salts",
	},
	-- Bath oil (KO)
	oil = {
		patterns 	= { "bath.*oil" }, -- ko_bath_oil ; ko_bath_oil_gtea	; ko_bath_oil_lavender ; ko_bath_oil_vanilla
		buff 		= "sd_c_sp_bath_oil",
		message 	= "The bath oil soothes and protects your skin from the elements.",
		tooltipMessage 	= "Use bath oil",
	},
	-- Bubble bath (KO)
	bubbles = {
		patterns 	= { "bubblebath" }, -- ko_bubblebath
		buff 		= "sd_c_sp_bath_bubb",
		message 	= "The bubble bath is relaxing.",
		tooltipMessage 	= "Use bubble bath",
	},
	-- Perfume (Luciana's)
	perfume = {
		patterns 	= { "perfume", "parfeum" }, -- luce_dim_perfume, etc.
		buff		= "sd_c_sp_bath_perf",
		message 	= "You smell absolutely divine.",
		tooltipMessage 	= "Infuse bath",
		
	},
	-- Cologne (KO)
	cologne = {
		patterns 	= { "cologne", "aftershave" }, -- KO_Cologne 
		buff 		= "sd_c_sp_bath_col",
		message 	= "Your cologne will make a strong impression.",
		tooltipMessage 	= "Infuse bath",
	},
	lotion = {
		patterns 	= { "body_lotion" }, -- KO_Body_lotion
		buff 		= "sd_c_sp_bath_lot",
		message 	= "The lotion eases the tension in your body.",
		tooltipMessage 	= "Use body lotion",
	},	
	-- Towels (KO)
	-- towel = {
	-- 	patterns 	= { "ko_bath_f_towel", "ko_bath_towel_mens", "S3_towel", "comtowel" }, -- add other modded towels here
	-- 	buff 		= "sd_c_sp_bath_tow",
	-- 	message 	= "You dry yourself thoroughly with the towel.",
	-- },
}


-- House-specific bath buffs ; abilities
local houseBathBuffs = {
	hlaalu 			= "sd_c_sp_bath_h", -- Fortify Agility 5
	redoran 		= "sd_c_sp_bath_r", -- Fortify Strength 5
	telvanni 		= "sd_c_sp_bath_t", -- Fortify Int 5, Resist Magicka 10
	temple  		= "sd_c_sp_bath_tt", -- +5 Personality
	mudbath 		= "sd_c_sp_bath_om", -- +5 Endurance, 15% Resist Common Disease
	indoril			= "sd_c_sp_bath_i", -- +3 agility, +3 str
	imperial		= "sd_c_sp_bath_imp", -- +2 agility, +2 int, +3 luck
	nord			= "sd_c_sp_bath_n", -- +3 str, +3 willpower
}

-- sand planet / ash storm ability
local duneBuff = {
	sandPlanet 		= "sd_c_sp_dune",
}

-- Disease list
local commonDiseaseOnBathing = {
	-- from hunger module
	"ataxia",
	"dampworm",
	"greenspore",
	"helljoint",
	"rattles",
	"rockjoint",
	"rust chancre",
	"witbane",
	"wither",
	"yellow tick",
	-- other common diseases
	"brown rot",
	"chills",
	"collywobbles",
	"droops",
	"swamp fever",
}

-- Location modifiers for dirtiness rate
-- Multiplier applied to base dirtiness accumulation
local locationDirtModifiers = {
	isCave 			= 1.25, -- Caves are dusty
	isMine 			= 1.5,  -- Mines are dirty
	isTomb 			= 1.25, -- Tombs are dusty
	isSewer 		= 2.5,  -- Sewers/Underworks are the worst
	isTemple 		= 0.5,  -- Temples are clean, reduce dirt rate
	isDaedric 		= 1.25, -- Daedric shrines are somewhat dirty
	isDwemer 		= 1.5,  -- Dwemer ruins are old and dusty
}

-- Weather types that increase dirtiness
local dirtyWeatherTypes = {
	["ash"] 		= 3.0, -- Ash storms
	["ashstorm"] 	= 3.0, -- Ash storms
	["blight"] 		= 4.0, -- Blight storms (also disease risk)
	["blizzard"] 	= 1.4, -- Blizzards (snow/ice)
	["snow"] 		= 1.25, -- Snow doesn't really dirty you
}

local cleanData
local cleanTooltip 	= nil

-- Widget element references
local cleanIcon 	= nil
local cleanBackground = nil
local cleanWidget 	= nil

-- State tracking
local lastTextureLevel = nil
local lastDirtValue = nil
local lastAlpha 	= nil
local lastIconSize = nil
local lastTooltipStr = nil

-- Cache for cell info
local cachedCellInfo = nil
local lastCellName = nil

-- Remove current bathing buff
local function removeBuffs()
	if not cleanData then return end
	-- Remove main cleanliness buff
	if cleanData.currentCleanBuff then
		local buff = cleanData.currentCleanBuff
		if core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
		else
			log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
		end
		cleanData.currentCleanBuff = nil
	end
	
	-- Remove house bath buff
	if cleanData.currentHouseBuff then
		local buff = cleanData.currentHouseBuff
		if core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
		end
		cleanData.currentHouseBuff = nil
	end	
end
table.insert(G_removeAbilitiesJobs, removeBuffs)

-- Get dirt level (0-5) from dirt value
-- 0 = Glowing (cleanest), 5 = Filthy (dirtiest)
local function getDirtLevel(dirt)
	-- dirt is 0-1, where 0 = just bathed, 1 = maximum filth
	local level = math.floor(dirt * CONST_CLEAN_STAGES)
	return math.min(CONST_CLEAN_STAGES - 1, math.max(0, level))
end

-- Check if an item matches a bath product
local function matchesBathProduct(recordId)
	for productType, productData in pairs(bathProducts) do
		-- Multiple patterns
		for _, pattern in ipairs(productData.patterns) do
			if recordId:find(pattern) then
				return productType, productData
			end
		end
	end
	return nil, nil
end

-- Apply appropriate bathing buff based on dirt value (0-1 scale)
-- Called per hour and on consume - only updates the dirt level buff here
-- Bathing product buffs are applied in performBathing, removed here when too dirty
local function applyCleanBuff()
	log(4, "[SunsDusk:Clean] applyCleanBuff called, NEEDS_CLEAN:", NEEDS_CLEAN, "cleanData:", cleanData ~= nil)
	if not NEEDS_CLEAN then return end
	if not cleanData then return end
	
	local dirt = cleanData.dirt
	local level = getDirtLevel(dirt)
	local buffId = "sd_clean_" .. level
	
	log(3, "[SunsDusk:Clean] Applying buff:", buffId, "for dirt value:", dirt, "level:", level)
	
	if buffId ~= cleanData.currentCleanBuff then
		local buff = cleanData.currentCleanBuff
		if buff and core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
			cleanData.currentCleanBuff = nil
		end
		if not G_preventAddingAnyBuffs then
			typesActorSpellsSelf:add(buffId)
			cleanData.currentCleanBuff = buffId
			log(3, "[SunsDusk:Clean] Applied bathing buff:", buffId)
		end
	end
	
	-- When too dirty (level >= 3), remove house buff, soap buff, and temporary bathing product buffs
	if level >= 3 then
		-- Remove house buff (ability)
		if cleanData.currentHouseBuff then
			if core.magic.spells.records[cleanData.currentHouseBuff] then
				typesActorSpellsSelf:remove(cleanData.currentHouseBuff)
			end
			cleanData.currentHouseBuff = nil
			log(3, "[SunsDusk:Clean] Removed house buff due to high dirt level")
		end
		
		-- Remove temporary bathing product buffs (those with duration)
		-- This includes soap buffs, bug musk, and bath products (salt, oil, perfume, etc.)
		local active = types.Actor.activeSpells(self)
		for _, s in pairs(active) do
			local spellId = s.id
			if s.temporary and(spellId:find("^sd_c_sp_soap_") or spellId:find("^sd_c_sp_bath_")) then
				log(3, "[SunsDusk:Clean] Removing buff due to high dirt level:", spellId)
				active:remove(s.activeSpellId)
			end
		end
		
		-- Clear tracked buffs
		cleanData.currentSoapBuff = nil
		cleanData.currentBugMuskBuff = nil
		if cleanData.activeProductBuffs then
			cleanData.activeProductBuffs = {}
		end
	end
end

-- Apply a bath product buff (timed spell)
-- productType is the category key (salts, oil, perfume)
-- productData contains buff, message, pattern(s)
local function applyBathProductBuff(productType, productData)
	if not cleanData then return false end
	if not productData or not productData.buff then return false end
	
	local buffId = productData.buff
	
	-- Check if spell exists
	if not core.magic.spells.records[buffId] then
		log(2, "[SunsDusk:Clean] WARNING: bath product buff not found:", buffId)
		return false
	end
	
	-- Initialize activeProductBuffs if needed
	if not cleanData.activeProductBuffs then
		cleanData.activeProductBuffs = {}
	end
	
	local active = types.Actor.activeSpells(self)
	
	-- Remove old buff of same category if exists
	local oldBuffId = cleanData.activeProductBuffs[productType]
	if oldBuffId then
		for _, s in pairs(active) do
			if s.id == oldBuffId then
				active:remove(s.activeSpellId)
				log(3, "[SunsDusk:Clean] Removed old bath product buff:", oldBuffId)
				break
			end
		end
	end
	local indexes = {}
    local spell = core.magic.spells.records[buffId]
    for i in pairs(spell.effects) do
		table.insert(indexes, i-1)
    end
	-- Apply new buff
	active:add({
		id = buffId,
		effects = indexes,
		ignoreResistances = true,
		ignoreSpellAbsorption = true,
		ignoreReflect = true
	})
	
	cleanData.activeProductBuffs[productType] = buffId
	messageBox(3, productData.message)
	log(3, "[SunsDusk:Clean] Applied bath product buff:", buffId, "for category:", productType)
	return true
end

-- Does not affect dirt value
local function applyBugMuskBuff()
	if not cleanData then return false end
	
	local buffId = "sd_c_sp_bath_t_bug_musk"
	if not core.magic.spells.records[buffId] then
		log(2, "[SunsDusk:Clean] WARNING: bug musk buff not found:", buffId)
		return false
	end
	
	local active = types.Actor.activeSpells(self)
	
	-- Remove old bug musk buff first
	if cleanData.currentBugMuskBuff then
		for _, s in pairs(active) do
			if s.id == cleanData.currentBugMuskBuff then
				active:remove(s.activeSpellId)
				break
			end
		end
	end
	
	local indexes = {}
    local spell = core.magic.spells.records[buffId]
    for i in pairs(spell.effects) do
		table.insert(indexes, i-1)
    end
	active:add({
		id = buffId,
		effects = indexes,
		ignoreResistances = true,
		ignoreSpellAbsorption = true,
		ignoreReflect = true
	})
	
	cleanData.currentBugMuskBuff = buffId
	messageBox(3, "The Telvanni bug musk enhances your bath!")
	log(3, "[SunsDusk:Clean] Applied bug musk buff:", buffId)
	return true
end

-- Check if player is wearing appropriate clothing for bathing
local function isWearingBathingClothing()
	if not CLEAN_NEKKI then
		return true -- Setting disabled, always allow
	end
	
	-- Check for shirt, pants, skirt, or robe (excluding helm and feet)
	for slot, item in pairs(types.Actor.getEquipment(self)) do
		if types.Armor.objectIsInstance(item) then
			if slot == types.Actor.EQUIPMENT_SLOT.Helmet or slot == types.Actor.EQUIPMENT_SLOT.Boots then
				-- Boots and Helmets are fine
			else
				return false
			end
		end
	end
	
	return true
end

-- Get the current Great House type based on cell
local function getCurrentHouseType()
	-- Check G_cellInfo flags first
	if G_cellInfo.isMushroom then return "telvanni" end
	if G_cellInfo.isHlaalu then return "hlaalu" end
	if G_cellInfo.isRedoran then return "redoran" end
	if G_cellInfo.isTemple then return "temple" end
	
	-- Check cell name for additional house types
	if self.cell and self.cell.name then
		local cellName = self.cell.id
		if cellName:find("mudbath") then return "mudbath" end
		if cellName:find("indoril") then return "indoril" end
		if cellName:find("imperial") and G_cellInfo.isBath then return "imperial" end
		if cellName:find("nord") and G_cellInfo.isBath then return "nord" end
	end
	
	-- No house type detected
	return nil
end

-- Calculate current dirtiness modifier based on location and weather
local function getDirtinessModifier(onlyLocationDirtModifier)
	local locationModifier = 1.0
	local weatherModifier = 1.0
	
	-- Location modifier
	if CLEAN_LOCATION_MODIFIER and G_cellInfo then
		if G_cellInfo.isSewer then
			locationModifier = locationModifier * (locationDirtModifiers.isSewer or 2.5)
			cleanData.currentLocationDirtModifier = "isSewer"
		elseif G_cellInfo.isTemple then
			locationModifier = locationModifier * (locationDirtModifiers.isTemple or 0.5)
			cleanData.currentLocationDirtModifier = "isTemple"
		elseif G_cellInfo.isMine then
			locationModifier = locationModifier * (locationDirtModifiers.isMine or 2.0)
			cleanData.currentLocationDirtModifier = "isMine"
		elseif G_cellInfo.isTomb then
			locationModifier = locationModifier * (locationDirtModifiers.isTomb or 1.75)
			cleanData.currentLocationDirtModifier = "isTomb"
		elseif G_cellInfo.isCave then
			locationModifier = locationModifier * (locationDirtModifiers.isCave or 1.5)
			cleanData.currentLocationDirtModifier = "isCave"
		elseif G_cellInfo.isDwemer then
			locationModifier = locationModifier * (locationDirtModifiers.isDwemer or 1.4)
			cleanData.currentLocationDirtModifier = "isDwemer"
		elseif G_cellInfo.isDaedric then
			locationModifier = locationModifier * (locationDirtModifiers.isDaedric or 1.25)
			cleanData.currentLocationDirtModifier = "isDaedric"
		else
			cleanData.currentLocationDirtModifier = nil
		end
	else
		cleanData.currentLocationDirtModifier = nil
	end
	-- Weather modifier (only in exterior cells)
	cleanData.currentWeatherDirtModifier = nil
	if CLEAN_WEATHER_MODIFIER and saveData.weatherInfo and G_cellInfo.isExterior then
		local weatherName = saveData.weatherInfo.weatherName
		if weatherName then
			weatherName = weatherName:lower()
			for weatherType, weatherMod in pairs(dirtyWeatherTypes) do
				if weatherName:find(weatherType) then
					weatherModifier = weatherModifier * weatherMod
					cleanData.currentWeatherDirtModifier = weatherType
					break
				end
			end
		end
	end
	if onlyLocationDirtModifier then
		return locationModifier
	end
	
	return weatherModifier * locationModifier
end

local function updateWidget()
	log(5, "[SunsDusk:Clean] updateWidget called, NEEDS_CLEAN:", NEEDS_CLEAN, "cleanData:", cleanData ~= nil)
	if not NEEDS_CLEAN then return end
	if not cleanData then return end
	-- Calculate current values
	local skinData = iconPacks.clean[C_SKIN or "Velothi (Transparent)"]
	local textureLevel =  math.max(0, math.floor(cleanData.dirt * skinData.stages - 0.00001)) 
	-- Higher dirt value = dirtier = more visible icon (same as hunger/thirst)
	local currentAlpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(cleanData.dirt)
	local bgAlpha = C_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or currentAlpha^2) or 0.5
	
	-- Determine texture (supports up to 6 stages if available)
	local cleanTexture
	if skinData.stages > 1 then
		-- Clamp to available stages in the skin
		
		cleanTexture = getTexture(skinData.base.."clean_"..textureLevel..skinData.extension)
	else
		cleanTexture = getTexture(skinData.base.."clean"..skinData.extension)
	end
	
	-- Initialize widget if it doesn't exist
	if not cleanWidget then
		-- Create sub-elements
		cleanBackground = C_BACKGROUND ~= "No Background" and {
			name = "clean_background",
			type = ui.TYPE.Image,
			props = {
				resource = C_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or cleanTexture,
				color = C_BACKGROUND == "Classic" and C_BACKGROUND_COLOR or util.color.rgb(0,0,0),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				relativePosition = C_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
				alpha = bgAlpha,
			}
		} or {}
		
		cleanIcon = {
			name = "clean_icon",
			type = ui.TYPE.Image,
			props = {
				resource = cleanTexture,
				color = C_COLOR,
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = currentAlpha,
			}
		}
		
		-- Create main widget
		cleanWidget = ui.create{
			name = "m_clean",
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
			},
			order = "needs-clean",
			content = ui.content {
				cleanBackground,
				cleanIcon,
			}
		}
		
		-- Store in G_columnWidgets
		if not G_columnWidgets then
			G_columnWidgets = {}
		end
		G_columnWidgets.m_clean = cleanWidget
		
		-- Initialize tracking variables
		lastTextureLevel = textureLevel
		lastDirtValue = cleanData.dirt
		lastAlpha = currentAlpha
		lastIconSize = HUD_ICON_SIZE
		
		G_columnsNeedUpdate = true
	end
	
	-- Check if we need to update
	local needsUpdate = false
	
	-- Update widget size if icon size changed
	if lastIconSize ~= HUD_ICON_SIZE then
		cleanWidget.layout.props.size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE)
		lastIconSize = HUD_ICON_SIZE
		needsUpdate = true
		G_columnsNeedUpdate = true
	end
	
	-- Update icon texture if clean level changed
	if lastTextureLevel ~= textureLevel then
		cleanIcon.props.resource = cleanTexture
		lastTextureLevel = textureLevel
		needsUpdate = true
		
		-- Update background texture if not using Classic style
		if C_BACKGROUND ~= "No Background" and C_BACKGROUND ~= "Classic" and cleanBackground then
			cleanBackground.props.resource = cleanTexture
		end
	end
	
	-- Update alpha if it changed
	if lastAlpha ~= currentAlpha then
		cleanIcon.props.alpha = currentAlpha
		lastAlpha = currentAlpha
		needsUpdate = true
		
		-- Update background alpha if using Classic style
		if C_BACKGROUND == "Classic" and cleanBackground then
			cleanBackground.props.alpha = HUD_ALPHA == "Static" and 1 or currentAlpha^2
		end
	end
	
	-- Build tooltip string
	local tooltipStr = math.floor(cleanData.dirt * 100).."%\n"
	tooltipStr = tooltipStr..(not cleanData.currentCleanBuff and "" or tooltips[cleanData.currentCleanBuff] or "ERROR: "..tostring(cleanData.currentCleanBuff))
	
	-- Add soap buff info to tooltip
	if cleanData.currentSoapBuff then
		tooltipStr = tooltipStr.."\n"..( tooltips[cleanData.currentSoapBuff] or cleanData.currentSoapBuff)
	end
	
	-- Add bug musk buff info
	if cleanData.currentBugMuskBuff then
		tooltipStr = tooltipStr.."\n"..(tooltips[cleanData.currentBugMuskBuff] or cleanData.currentBugMuskBuff)
	end
	
	-- Add house buff info
	if cleanData.currentHouseBuff then
		tooltipStr = tooltipStr.."\n"..(tooltips[cleanData.currentHouseBuff] or cleanData.currentHouseBuff)
	end
	
	-- Add active product buffs
	if cleanData.activeProductBuffs and #cleanData.activeProductBuffs > 0 then
		for _, buff in pairs(cleanData.activeProductBuffs) do
			tooltipStr = tooltipStr.."\n"..(tooltips[buff] or buff)
		end
	end
	
	-- Add location modifier info
	if cleanData.currentLocationDirtModifier then
		tooltipStr = tooltipStr.."\n"..(tooltips[cleanData.currentLocationDirtModifier] or cleanData.currentLocationDirtModifier)
	end

	-- Add storm modifier info
	if cleanData.currentWeatherDirtModifier then
		tooltipStr = tooltipStr.."\n"..(tooltips[cleanData.currentWeatherDirtModifier] or cleanData.currentWeatherDirtModifier)
	end
	
	if lastTooltipStr ~= tooltipStr then
		lastTooltipStr = tooltipStr
		addTooltip(cleanWidget.layout, tooltipStr)
		needsUpdate = true
	end
	
	-- Only call update if something actually changed
	if needsUpdate then
		cleanWidget:update()
	end
end

table.insert(G_refreshWidgetJobs, updateWidget)

-- Check if player is eligible to bathe
local function canBathe()
	log(4, "[SunsDusk:Clean] canBathe check - G_isInWater:", G_isInWater)
	
	-- Check clothing requirement
	if not isWearingBathingClothing() then
		log(4, "[SunsDusk:Clean] canBathe: NO (not wearing appropriate clothing)")
		return false, "clothing"
	end
	
	-- Check if in water
	if G_isInWater >= 0.5 or saveData.m_temp.water.wetness >= 0.5 then
		log(4, "[SunsDusk:Clean] canBathe: YES (in water)")
		return true
	end
	
	-- Starwind enjoyers only need to be slightly wet (either from drinking or spamming a well)
	if G_STARWIND_INSTALLED and saveData.m_temp and saveData.m_temp.water and saveData.m_temp.water.wetness >= 0.3 then
		log(4, "[SunsDusk:Clean] canBathe: YES (wetness:", saveData.m_temp.water.wetness, ")")
		return true
	end
	
	-- Check if in a cell with "Bath" in the name
	if G_cellInfo.isBath and (G_isInWater > 0 or not self.cell or not self.cell.hasWater) then
		log(4, "[SunsDusk:Clean] canBathe: YES (in bath cell:", self.cell.name, ")")
		return true
	end
	
	local playerPos = self.position
	for _, activator in pairs(nearby.activators) do
		if activator.recordId:find("_bath_", 1, true) and (activator.position-playerPos):length() < 200 then
			return true
		end
	end
 -- Armor doesn't degrade ; special armor is immune to degradation ; all armor degrades
	log(4, "[SunsDusk:Clean] canBathe: NO")
	return false
end
 
-- Destroy UI elements (for cleanup/reset)
function G_destroyCleanUi()
	cleanIcon = nil
	cleanBackground = nil
	if cleanWidget then
		cleanWidget:destroy()
		cleanWidget = nil
	end
	if G_columnWidgets and G_columnWidgets.m_clean then
		G_columnWidgets.m_clean:destroy()
		G_columnWidgets.m_clean = nil
	end
	lastTextureLevel = nil
	lastDirtValue = nil
	lastAlpha = nil
	lastIconSize = nil
	lastTooltipStr = nil
	G_columnsNeedUpdate = true
end

table.insert(G_destroyHudJobs, G_destroyCleanUi)

-- Perform bathing action (resets dirt, applies soap/bugmusk/house buffs)
-- Item usage tracking is handled by the caller
local function performBathing(usedSoap, soapItem, hasBugMusk)
	if not cleanData then return end
	
	-- Reset dirt to 0 (Glowing/just bathed - cleanest state)
	cleanData.dirt = 0
	cleanData.daysSinceLastBath = 0
	
	local active = types.Actor.activeSpells(self)
	log(3, "[SunsDusk:Clean] Bathing...:",usedSoap,soapItem,hasBugMusk)
	
	-- Handle soap buff logic
	if usedSoap and soapItem then
		local soapId = soapItem.recordId
		
		-- Always remove old soap buff first
		if cleanData.currentSoapBuff then
			for _, s in pairs(active) do
				if s.id == cleanData.currentSoapBuff then
					active:remove(s.activeSpellId)
					log(3, "[SunsDusk:Clean] Removed old soap buff:", cleanData.currentSoapBuff)
					break
				end
			end
			cleanData.currentSoapBuff = nil
		end
		
		-- Check if this is a plain soap (removes buff without applying new one)
		local isPlainSoap = plainSoaps[soapId] or plainSoaps[soapId]
		
		if isPlainSoap then
			log(3, "[SunsDusk:Clean] Used plain soap, no special buff applied")
		else
			-- Apply soap-specific buff if applicable
			local buffId = soapBuffs[soapId] or soapBuffs[soapId]
			if buffId and core.magic.spells.records[buffId] then
				active:add({
					id = buffId,
					effects = { 0, 1 },
					ignoreResistances = true,
					ignoreSpellAbsorption = true,
					ignoreReflect = true
				})
				cleanData.currentSoapBuff = buffId
				log(3, "[SunsDusk:Clean] Applied soap buff:", buffId)
			end
		end
	end
	
	-- Apply bug musk buff
	if hasBugMusk then
		applyBugMuskBuff()
	end
	
	-- Apply house-specific buff (ability)
	-- Always remove old house buff first - bathing replaces any previous house buff
	if cleanData.currentHouseBuff and core.magic.spells.records[cleanData.currentHouseBuff] then
		typesActorSpellsSelf:remove(cleanData.currentHouseBuff)
		cleanData.currentHouseBuff = nil
		log(3, "[SunsDusk:Clean] Removed old house bath buff")
	end
	
	-- Apply new house buff if in a qualifying location
	local houseType = getCurrentHouseType()
	if houseType and houseBathBuffs[houseType] then
		local buffId = houseBathBuffs[houseType]
		if core.magic.spells.records[buffId] then
			G_addSpellWhenAwake(buffId)
			cleanData.currentHouseBuff = buffId
			log(3, "[SunsDusk:Clean] Applied house bath buff:", buffId, "for house:", houseType)
			messageBox(3, "The "..houseType:sub(1,1):upper()..houseType:sub(2).." bath invigorates you!")
		end
	end
	
	applyCleanBuff()
	ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
	ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
	messageBox(4, "You feel clean and refreshed.")
	updateWidget()
end

-- Find bug musk in player's inventory
local function findBugMuskInInventory()
	local inventory = types.Container.inventory(self)
	for _, item in pairs(inventory:getAll()) do
		if bugMuskId[item.recordId] then
			return item
		end
	end
	return nil
end

-- Increment uses for an item, returns true if item is now depleted (uses >= 5)
local function incrementItemUses(itemId, productType)
	if not cleanData.itemUses then
		cleanData.itemUses = {}
	end
	cleanData.itemUses[itemId] = (cleanData.itemUses[itemId] or 0) + 1
	log(3, "[SunsDusk:Clean] Item uses for", itemId, ":", cleanData.itemUses[itemId])
	return cleanData.itemUses[itemId] >= getMaxCharges(productType, itemId)
end

-- Reset uses for an item (when depleted and removed)
local function resetItemUses(itemId)
	if cleanData.itemUses then
		cleanData.itemUses[itemId] = nil
	end
end

-- Handle item uses tracking and respawn/removal
-- wasConsumed: true = respawn if not depleted (auto-consumed), false = remove if depleted
local function handleItemTracking(item, wasConsumed, productType)
	local itemId = item.recordId
	local depleted = incrementItemUses(itemId, productType)
	if wasConsumed then
		if not depleted then
			async:newUnsavableSimulationTimer(0.1, function()
				core.sendGlobalEvent("SunsDusk_addItem", {self, itemId, 1})
			end)
		else
			resetItemUses(itemId)
		end
	else
		if depleted then
			core.sendGlobalEvent("SunsDusk_removeItem", {self, item, 1})
			resetItemUses(itemId)
		end
	end
	return depleted
end

-- Unified handler for all bathing items (soap, bug musk, bath products)
-- wasConsumed: true = respawn if not depleted, false = remove if depleted
local function handleBathingItemUse(item, wasConsumed)
	log(3, "[SunsDusk:Clean] handleBathingItemUse ENTRY - item:", item and item.recordId or "nil", "wasConsumed:", wasConsumed)
	if not cleanData then 
		log(3, "[SunsDusk:Clean] handleBathingItemUse - cleanData is nil, returning")
		return 
	end
	
	local itemId = item.recordId
	log(3, "[SunsDusk:Clean] handleBathingItemUse - itemId:", itemId)
	log(3, "[SunsDusk:Clean] handleBathingItemUse - checking if soap:", isSoapItem(itemId))
	log(3, "[SunsDusk:Clean] handleBathingItemUse - checking if towel:", isTowelItem(itemId))
	
	local eligible = canBathe()
	local dirtLevel = getDirtLevel(cleanData.dirt)
	log(3, "[SunsDusk:Clean] handleBathingItemUse - eligible:", eligible, "dirtLevel:", dirtLevel)
	
	-- Soap - requires canBathe, resets dirt
	if isSoapItem(itemId) then
		local _, reason = canBathe()
		if not eligible then
			if reason == "clothing" then
				messageBox(2, "You need to remove armor to bathe (helmet and boots are fine).")
			else
				if G_STARWIND_INSTALLED then
					messageBox(2, "You need to be wet, in water or in a bath to use soap.")
				else
					messageBox(2, "You need to be in water or in a bath to use soap.")
				end
			end
			if wasConsumed then
				async:newUnsavableSimulationTimer(0.1, function()
					core.sendGlobalEvent("SunsDusk_addItem", {self, itemId, 1})
				end)
			end
			return false
		end
		
		local bugMusk = findBugMuskInInventory()
		local hasBugMusk = bugMusk ~= nil
		
		performBathing(true, item, hasBugMusk)
		handleItemTracking(item, wasConsumed, "soap")
		
		-- Track bug musk uses if used during bathing
		if hasBugMusk then
			handleItemTracking(bugMusk, false, "bugMusk")
		end
		return true
	end
	
	-- Towel - does NOT require water, resets dirt (drying off)
	if isTowelItem(itemId) then
		log(3, "[SunsDusk:Clean] TOWEL DETECTED - itemId:", itemId, "wasConsumed:", wasConsumed)
		-- Only check clothing, not water requirement
		if not isWearingBathingClothing() then
			log(3, "[SunsDusk:Clean] Towel use blocked - improper clothing")
			messageBox(2, "You need to remove armor to dry off (helmet and boots are fine).")
			if wasConsumed then
				async:newUnsavableSimulationTimer(0.1, function()
					core.sendGlobalEvent("SunsDusk_addItem", {self, itemId, 1})
				end)
			end
			return false
		end
		
		log(3, "[SunsDusk:Clean] Towel use - clothing check passed, performing drying")
		-- Perform drying (similar to bathing but without soap/bugmusk buffs)
		
		-- Reduce wetness from temperature module if it exists
		log(3, "[SunsDusk:Clean] Checking saveData.m_temp:", saveData.m_temp ~= nil)
		if saveData.m_temp then
			log(3, "[SunsDusk:Clean] Checking saveData.m_temp.water:", saveData.m_temp.water ~= nil)
		end
		if saveData.m_temp and saveData.m_temp.water then
			local oldWetness = saveData.m_temp.water.wetness or 0
			-- Towel removes most wetness (30%), leaving you slightly damp
			saveData.m_temp.water.wetness = math.max(0, oldWetness * 0.7)
			log(3, "[SunsDusk:Clean] Towel reduced wetness:", oldWetness, "->", saveData.m_temp.water.wetness)
			updateTemperatureWidget()
		end
		
		applyCleanBuff()
		ambient.playSoundFile("sound/sunsdusk/towel.ogg", {volume = 1.0})
		updateWidget()
		
		-- Track towel uses (10 uses before depleted)
		-- For inventory items: respawn if not depleted (engine may auto-consume misc items)
		-- For world items: remove when depleted
		
		handleItemTracking(item, false, "towel")
		
		
		--local depleted = incrementItemUses(itemId)
		--local usesRemaining = 3 - (cleanData.itemUses[itemId] or 0)
		--log(3, "[SunsDusk:Clean] Towel uses:", cleanData.itemUses[itemId], "depleted:", depleted, "remaining:", usesRemaining)
		--
		--if depleted then
		--	messageBox(4, "The towel is too worn to use again.")
		--	resetItemUses(itemId)
		--	-- Remove world item if depleted
		--	if not wasConsumed then
		--		core.sendGlobalEvent("SunsDusk_removeItem", {self, item, 1})
		--	end
		--else
		--	messageBox(4, "You dry yourself thoroughly with the towel. (" .. usesRemaining .. " uses remaining)")
		--	-- Respawn inventory item if it was consumed
		--	if wasConsumed then
		--		async:newUnsavableSimulationTimer(0.1, function()
		--			core.sendGlobalEvent("SunsDusk_addItem", {self, itemId, 1})
		--		end)
		--	end
		--end
		--
		--log(3, "[SunsDusk:Clean] Towel use complete")
		return true
	end
	
	-- Bug musk used separately - requires canBathe and dirtLevel <= 2, doesn't reset dirt
	if bugMuskId[itemId] then
		if not eligible then
			local _, reason = canBathe()
			if reason == "clothing" then
				messageBox(2, "You need to remove armor to infuse the bath (helmet and boots are fine).")
			else
				if G_STARWIND_INSTALLED then
					messageBox(2, "You need to be wet, in water or in a bath to use bug musk.")
				else
					messageBox(2, "You need to be in water or in a bath to use bug musk.")
				end
			end
			log(3, "[SunsDusk:Clean] Bug musk used but not eligible (canBathe failed)")
			return false
		end
		if dirtLevel > 2 then
			messageBox(2, "You are too dirty for bug musk to cover your stench ...")
			log(3, "[SunsDusk:Clean] Bug musk used but too dirty (dirtLevel > 2)")
			return false
		end
		applyBugMuskBuff()
		handleItemTracking(item, wasConsumed, "bugMusk")
		return true
	end
	
	-- Bath products - requires canBathe and dirtLevel <= 2, doesn't reset dirt
	local productType, productData = matchesBathProduct(itemId)
	if productType and productData then
		if not eligible or dirtLevel > 2 then
			log(3, "[SunsDusk:Clean] Bath product used but not eligible")
			--if wasConsumed then
			--	async:newUnsavableSimulationTimer(0.1, function()
			--		core.sendGlobalEvent("SunsDusk_addItem", {self, itemId, 1})
			--	end)
			--end
			return false
		end
		applyBathProductBuff(productType, productData, "bathProduct")
		handleItemTracking(item, wasConsumed, "bathproduct")
		return true
	end
end

-- calculating anchor based on offset from center
local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)
	else
		return 0.5 + (t * 0.5)
	end
end

local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

-- Raycast change handler for tooltip (shows when hovering over soap, towel, or bug musk in world)
local function raycastChanged()
	log(3, "[SunsDusk:Clean] raycastChanged called, NEEDS_CLEAN:", NEEDS_CLEAN)
	if not NEEDS_CLEAN then return end
	if not G_raycastResultType or not G_raycastResult.hitObject or saveData.playerInfo.isInWerewolfForm then
		if cleanTooltip then
			-- Not looking at soap/towel anymore, destroy tooltip and restore controls
			log(4, "[SunsDusk:Clean] No longer looking at clean item, destroying tooltip")
			cleanTooltip:destroy()
			cleanTooltip = nil
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
		end
		return
	end
	-- Debug: Log raycast state
	log(3, "[SunsDusk:Clean] G_raycastResult exists, hitObject:", G_raycastResult.hitObject)
	if G_raycastResult.hitObject then
		log(3, "[SunsDusk:Clean] hitObject.recordId:", G_raycastResult.hitObject.recordId)
		log(3, "[SunsDusk:Clean] G_raycastResultType:", G_raycastResultType)
		log(3, "[SunsDusk:Clean] hitObject.type:", G_raycastResult.hitObject.type)
	end
	
	-- Check if looking at a soap or towel item in the world
	local hitRecordId = G_raycastResult.hitObject.recordId
	log(3, "[SunsDusk:Clean] hitRecordId:", hitRecordId)
	
	local isLookingAtSoap = hitRecordId and isSoapItem(hitRecordId)
	log(3, "[SunsDusk:Clean] isLookingAtSoap:", isLookingAtSoap)
	
	local isLookingAtTowel = false
	if hitRecordId and G_raycastResultType == "Miscellaneous" then
		log(3, "[SunsDusk:Clean] About to call isTowelItem with:", hitRecordId)
		isLookingAtTowel = isTowelItem(hitRecordId)
		log(3, "[SunsDusk:Clean] Towel check result - recordId:", hitRecordId, "isTowel:", isLookingAtTowel)
	end
	
	local isLookingAtBugMusk = bugMuskId[hitRecordId]
	log(3, "[SunsDusk:Clean] isLookingAtBugMusk:", isLookingAtBugMusk)
	
	local bathProductType, bathProductData = matchesBathProduct(hitRecordId)
	local isLookingAtBathProduct = bathProductType
	log(3, "[SunsDusk:Clean] isLookingAtBathProduct:", isLookingAtBathProduct)
	
	local isLookingAtCleanItem = isLookingAtSoap or isLookingAtTowel or isLookingAtBugMusk or isLookingAtBathProduct
	log(3, "[SunsDusk:Clean] isLookingAtCleanItem:", isLookingAtCleanItem)
	
	if isLookingAtCleanItem then
		log(3, "[SunsDusk:Clean] Looking at clean item:", hitRecordId, "soap:", isLookingAtSoap, "towel:", isLookingAtTowel, "bugMusk:", isLookingAtBugMusk)
		
		-- Destroy existing tooltip to rebuild it
		if cleanTooltip then
			cleanTooltip:destroy()
			cleanTooltip = nil
		end
		
		local hudVisible = I.UI.isHudVisible()
		log(5, "[SunsDusk:Clean] HUD visible:", hudVisible)
		
		if hudVisible then
			-- Disable combat controls while showing tooltip
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			
			local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
			
			-- Calculate colors based on whether bathing is possible
			local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			validIconHsv[2] = validIconHsv[2]*0.6
			validIconHsv[3] = math.min(1,validIconHsv[3]*1.8)
			local validIconRgb = util.color.rgb(hsvToRgb(validIconHsv[1],validIconHsv[2],validIconHsv[3]))
			
			local invalidIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			invalidIconHsv[2] = invalidIconHsv[2]*0.3
			invalidIconHsv[3] = math.min(1,invalidIconHsv[3]*0.4)
			local invalidIconRgb = util.color.rgb(hsvToRgb(invalidIconHsv[1],invalidIconHsv[2],invalidIconHsv[3]))
			
			local eligible, reason = canBathe()
			log(4, "[SunsDusk:Clean] canBathe:", eligible, "reason:", reason)
			
			-- Calculate dirt level for bug musk check
			local dirtLevel = getDirtLevel(cleanData.dirt)
			
			-- For towels, only clothing check matters (no water requirement)
			local towelEligible = isWearingBathingClothing()
			-- Bug musk requires canBathe() AND dirtLevel <= 2
			local bugMuskEligible = eligible and dirtLevel <= 2
			local actualEligible
			if isLookingAtTowel then
				actualEligible = towelEligible
			elseif isLookingAtBugMusk then
				actualEligible = bugMuskEligible
			elseif isLookingAtBathProduct then
				actualEligible = bugMuskEligible --same as bugmusk
			else
				-- Soap requires canBathe()
				actualEligible = eligible
			end
			local iconColor = actualEligible and validIconRgb or invalidIconRgb
			local textColor = actualEligible and WORLD_TOOLTIP_FONT_COLOR or invalidIconRgb
			
			local cleanText
			if isLookingAtTowel then
				cleanText = "Dry off"
				if not towelEligible then
					cleanText = "Dry off (improper clothing)"
				end
			elseif isLookingAtBugMusk then
				cleanText = "Infuse bath"
				if not eligible then
					if reason == "clothing" then
						cleanText = "Infuse bath (improper clothing)"
					else
						cleanText = "Infuse bath (need water/bath)"
					end
				elseif dirtLevel > 2 then
					cleanText = "Infuse bath (bathe first)"
				end
			elseif isLookingAtBathProduct then
				cleanText = bathProductData.tooltipMessage
				if not eligible then
					if reason == "clothing" then
						cleanText = bathProductData.tooltipMessage .. " (improper clothing)"
					else
						cleanText = bathProductData.tooltipMessage .. " (need water/bath)"
					end
				elseif dirtLevel > 2 then
					cleanText = bathProductData.tooltipMessage .. " (bathe first)"
				end
			else
				cleanText = "Clean"
				if not eligible then
					if reason == "clothing" then
						cleanText = "Clean (improper clothing)"
					else
						cleanText = "Clean (need water/bath)"
					end
				end
			end
			
			-- Calculate remaining uses/charges for the item
			local currentUses = cleanData.itemUses and cleanData.itemUses[hitRecordId] or 0
			local productType = "soap"
			if isLookingAtBugMusk then
				productType = "bugMusk"
			elseif isLookingAtTowel then
				productType = "towel"
			elseif isLookingAtBathProduct then
				productType = "bathproduct"
			end
			local maxUses = getMaxCharges(productType, hitRecordId)
			local remainingUses = maxUses - currentUses
			local chargesText = " (" .. remainingUses .. "/"..maxUses..")"
			
			-- Create the tooltip UI
			log(3, "[SunsDusk:Clean] Creating cleanTooltip UI")
			cleanTooltip = ui.create({
				layer = 'Scene',
				name = "cleanTooltip",
				type = ui.TYPE.Flex,
				props = {
					relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
					anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100)),
					horizontal = false,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			})
			
			local line1 = {
				layer = 'Scene',
				name = "cleanTooltipLine",
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			}
			cleanTooltip.layout.content:add(line1)
			
			-- F key icon
			line1.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
					tileH = false,
					tileV = false,
					size  = v2(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_ICON_SIZE),
					alpha = 0.6,
					color = iconColor,
				}
			}
			-- "Clean" text
			line1.content:add{
				type = ui.TYPE.Text,
				props = {
					text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "")..cleanText,
					textColor = textColor,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
			-- Charges text
			line1.content:add{
				type = ui.TYPE.Text,
				props = {
					text = chargesText,
					textColor = validIconRgb,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
			log(3, "[SunsDusk:Clean] cleanTooltip created successfully")
		end
	elseif cleanTooltip then
		-- Not looking at soap/towel anymore, destroy tooltip and restore controls
		log(4, "[SunsDusk:Clean] No longer looking at clean item, destroying tooltip")
		cleanTooltip:destroy()
		cleanTooltip = nil
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	end
end

-- F key handler for bathing/drying (when looking at soap or towel in world)
input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	log(3, "[SunsDusk:Clean] F key pressed - NEEDS_CLEAN:", NEEDS_CLEAN, "cleanData:", cleanData ~= nil, "cleanTooltip:", cleanTooltip ~= nil)
	if not NEEDS_CLEAN then return end
	if not cleanData then return end
	-- Check if we're showing the clean tooltip and looking at a soap or towel item
	if cleanTooltip and G_raycastResultType and G_raycastResult.hitObject then
		local hitRecordId = G_raycastResult.hitObject.recordId
		log(3, "[SunsDusk:Clean] F key - checking hitRecordId:", hitRecordId)
		local isSoap = isSoapItem(hitRecordId)
		local isTowel = isTowelItem(hitRecordId)
		local isBugMusk = bugMuskId[hitRecordId]
		local isBathProduct = matchesBathProduct(hitRecordId)
		log(3, "[SunsDusk:Clean] F key - isSoap:", isSoap, "isTowel:", isTowel, "isBugMusk:", isBugMusk)
		if isSoap or isTowel or isBugMusk or isBathProduct then
			log(3, "[SunsDusk:Clean] F key pressed while looking at clean item:", hitRecordId)
			handleBathingItemUse(G_raycastResult.hitObject, false) -- world item = misc (not auto-consumed)
			cleanTooltip:destroy()
			cleanTooltip = nil
			raycastChanged()
		end
	else
		log(3, "[SunsDusk:Clean] F key - tooltip not showing or no hit object")
	end
end))

-- Handle consuming ingredient items (soap, bug musk, bath products)
-- Ingredients are auto-consumed, so we respawn if uses < 10
local function onConsume(item)
	if not NEEDS_CLEAN then return end
	if not cleanData then return end
	local gotBuff = handleBathingItemUse(item, true) -- ingredient = auto-consumed
	if gotBuff then
		-- remove the ingredient/potion's effects
		local active = types.Actor.activeSpells(self)
		for _, s in pairs(active) do
			local spellId = s.id
			if spellId == item.recordId then
				active:remove(s.activeSpellId)
			end
		end
	end
end

-- Handle using miscellaneous items (soap, bug musk, bath products)
-- Misc items are NOT auto-consumed, so we remove when uses >= 10
local function onUsedMisc(item)
	log(3, "[SunsDusk:Clean] onUsedMisc called - item:", item and item.recordId or "nil")
	if not NEEDS_CLEAN then 
		log(3, "[SunsDusk:Clean] onUsedMisc - NEEDS_CLEAN is false, returning")
		return 
	end
	if not cleanData then 
		log(3, "[SunsDusk:Clean] onUsedMisc - cleanData is nil, returning")
		return 
	end
	log(3, "[SunsDusk:Clean] onUsedMisc - calling handleBathingItemUse")
	handleBathingItemUse(item, false) -- misc = not auto-consumed
end

-- Register the misc item usage handler
G_eventHandlers.SunsDusk_usedMisc = onUsedMisc

local function updateDirt()
	-- Check if buff needs to change
	if not cleanData then return end
	local currentLevel = getDirtLevel(cleanData.dirt)
	local buffLevel = nil
	if cleanData.currentCleanBuff then
		if cleanData.currentCleanBuff == "sd_clean_0" then buffLevel = 0
		elseif cleanData.currentCleanBuff == "sd_clean_1" then buffLevel = 1
		elseif cleanData.currentCleanBuff == "sd_clean_2" then buffLevel = 2
		end
	end
	
	applyCleanBuff() 
	if buffLevel ~= currentLevel then
		-- Show message when becoming dirty (transitioning to level 2)
		if currentLevel == 2 and (buffLevel == 0 or buffLevel == 1 or buffLevel == nil) then
			messageBox(3, "You are feeling dirty and need to bathe.")
		end
	end
	
	-- Apply disease if too long without bathing (10 days)
	if cleanData.daysSinceLastBath >= CLEAN_DISEASE_DAYS and not cleanData.diseaseApplied then
		typesActorSpellsSelf:add(commonDiseaseOnBathing[math.random(1, #commonDiseaseOnBathing)])
		cleanData.diseaseApplied = true
		messageBox(2, "Your poor hygiene has made you sick!")
		log(3, "[SunsDusk] Applied disease due to poor hygiene")
	end
	
	-- Reset disease flag if bathed recently
	if cleanData.daysSinceLastBath < CLEAN_DISEASE_DAYS then
		cleanData.diseaseApplied = false
	end
	
	updateWidget()
end
table.insert(G_postSleepJobs, updateDirt)

-- Initialize on load
local function onLoad(originalData)
	log(3, "[SunsDusk:Clean] onLoad called, NEEDS_CLEAN:", NEEDS_CLEAN)
	if not NEEDS_CLEAN then return end
	if not saveData.m_clean then
		log(3, "[SunsDusk:Clean] Creating new m_clean saveData")
		saveData.m_clean = {
			dirt = 0.1, -- Start slightly dirty (in "Glowing" range)
			daysSinceLastBath = 0,
			currentCleanBuff = nil,
			currentSoapBuff = nil,
			currentBugMuskBuff = nil,
			currentHouseBuff = nil,
			activeProductBuffs = {},
			itemUses = {}, -- tracks uses per recordId, counting up to 10
			diseaseApplied = false,
		}
	end
	cleanData = saveData.m_clean
	log(3, "[SunsDusk:Clean] cleanData initialized, dirt value:", cleanData.dirt)
	
	-- Ensure fields exist (migration)
	if cleanData.dirt == nil then
		cleanData.dirt = 0.1
	end
	if cleanData.itemUses == nil then
		cleanData.itemUses = {}
	end
	if cleanData.activeProductBuffs == nil then
		cleanData.activeProductBuffs = {}
	end
	if not cleanData.equipmentDamage then
		cleanData.equipmentDamage = {}
	end
	
	if cleanData.washSaturation == nil then
		cleanData.washSaturation = {
			feet  = 0,
			legs  = 0,
			torso = 0,
			head  = 0,
		}
	end
	
	-- Apply initial buff
	applyCleanBuff()
	log(3, "[SunsDusk:Clean] onLoad complete, current buff:", cleanData.currentCleanBuff)
end

-- Settings changed handler
local function settingsChanged(sectionName, setting, oldValue)
	log(4, "[SunsDusk:Clean] settingsChanged:", setting, "old:", oldValue, "new:", _G[setting])
	if setting == "NEEDS_CLEAN" then
		if oldValue == false then
			onLoad()
		else
			removeBuffs()
			saveData.m_clean = nil
			G_destroyCleanUi()
		end
	end
	-- elseif setting == "C_BACKGROUND" then
	-- 	G_destroyCleanUi()
	-- end
end

local bodyParts = {
    feet  = { dirtShare = 0.15, minDepth = 0.0, maxDepth = 0.2 },
    legs  = { dirtShare = 0.20, minDepth = 0.2, maxDepth = 0.5 },
    torso = { dirtShare = 0.35, minDepth = 0.5, maxDepth = 0.8 },
    head  = { dirtShare = 0.30, minDepth = 0.8, maxDepth = 1.0 },
}

local WASH_RATE = 0.05
local SWAMP_DIRTY_RATE = 0.01
local SATURATION_RATE = 0.25
local SATURATION_DECAY = 0.05
local SWIM_CLEAN_FLOOR = 0.2
local SWIM_SLOWDOWN_START = 0.4

local armorSubmersionThreshold = {
	[types.Armor.TYPE.Boots]      = 0.1,
	[types.Armor.TYPE.Greaves]    = 0.25,
	[types.Armor.TYPE.Shield]     = 0.4,
	[types.Armor.TYPE.LGauntlet]  = 0.45,
	[types.Armor.TYPE.RGauntlet]  = 0.45,
	[types.Armor.TYPE.LBracer]    = 0.45,
	[types.Armor.TYPE.RBracer]    = 0.45,
	[types.Armor.TYPE.Cuirass]    = 0.55,
	[types.Armor.TYPE.LPauldron]  = 0.7,
	[types.Armor.TYPE.RPauldron]  = 0.7,
	[types.Armor.TYPE.Helmet]     = 0.9,
}

local iterSlot
local function module_clean_minute(clockHour, minute, minutesPassed)
	if G_isInWater > 0 then
		local equipment = types.Actor.getEquipment(self)
		
		local dirtinessMult =(getDirtinessModifier(true)-1)/2 + 0.5
		if G_cellInfo.waterType == "susWater" then
			dirtinessMult = dirtinessMult + 0.4
		elseif G_cellInfo.waterType == "saltWater" then
			dirtinessMult = dirtinessMult + 0.8
		end
		
		-- Accumulate damage for submerged pieces
		for slot, item in pairs(equipment) do
			if item and item.type == types.Armor then
				local record = types.Armor.record(item)
				local threshold = armorSubmersionThreshold[record.type]
				if threshold and G_isInWater >= threshold then
					cleanData.equipmentDamage[slot] = (cleanData.equipmentDamage[slot] or 0) + WATER_DURABILITY_DAMAGE * minutesPassed * dirtinessMult
				end
			end
		end
		
		-- Send damage events
		if minutesPassed >= 59 then
			for slot, damage in pairs(cleanData.equipmentDamage) do
				core.sendGlobalEvent("ModifyItemCondition", {actor = self.object, item = equipment[slot], amount = -damage})
				cleanData.equipmentDamage[slot] = nil
			end
			nextDamageSlot = nil
		else
			iterSlot = next(cleanData.equipmentDamage, iterSlot)
			if not iterSlot then iterSlot = next(cleanData.equipmentDamage) end
			if iterSlot then
				if equipment[iterSlot] then
					local totalDurability = equipment[iterSlot].type.record(equipment[iterSlot]).health
					core.sendGlobalEvent("ModifyItemCondition", {actor = self.object, item = equipment[iterSlot], amount = totalDurability/100*-cleanData.equipmentDamage[iterSlot]})
				end
				
				cleanData.equipmentDamage[iterSlot] = nil
				nextDamageSlot = iterSlot
			end
		end
	end
	if not NEEDS_CLEAN then return end
    if not cleanData then return end
    if not saveData.chargenFinished then return end
	-- Increase dirt value over time (getting dirtier)
    -- Total time from clean to dirty = hours per stage × number of stages
    local totalHoursToMaxDirt = CLEAN_HOURS_PER_STAGE * CONST_CLEAN_STAGES
    local increase = (1 / totalHoursToMaxDirt / 60) * getDirtinessModifier() * minutesPassed
    local oldDirt = cleanData.dirt
    cleanData.dirt = math.min(1, cleanData.dirt + increase)
    cleanData.daysSinceLastBath = cleanData.daysSinceLastBath + (minutesPassed / 24 / 60)
    log(5, "[SunsDusk:Clean] dirt value changed:", oldDirt, "->", cleanData.dirt)
    
    updateDirt()
end


--[[
local function module_clean_minute(clockHour, minute, minutesPassed)
    if not NEEDS_CLEAN then return end
    
	
    if not G_isInWater or G_isInWater <= 0 then
        for part in pairs(bodyParts) do
            if cleanData.washSaturation[part] > 0 then
                cleanData.washSaturation[part] = math.max(0, cleanData.washSaturation[part] - SATURATION_DECAY * minutesPassed)
            end
        end
        return
    end
    
    local isSwamp = G_waterObject and (G_waterObject:find("scum") or G_waterObject:find("lilypad"))
    local totalDirtChange = 0
    
    for part, data in pairs(bodyParts) do
        if G_isInWater > data.minDepth then
            local submersion = G_isInWater >= data.maxDepth and 1 or (G_isInWater - data.minDepth) / (data.maxDepth - data.minDepth)
            
            if isSwamp then
                totalDirtChange = totalDirtChange + SWAMP_DIRTY_RATE * submersion * minutesPassed * data.dirtShare
            else
                local effectiveness = (1 - cleanData.washSaturation[part]) * submersion
                if effectiveness > 0.01 then
                    local floorFactor = 1
                    if cleanData.dirt < SWIM_SLOWDOWN_START then
                        floorFactor = (cleanData.dirt - SWIM_CLEAN_FLOOR) / (SWIM_SLOWDOWN_START - SWIM_CLEAN_FLOOR)
                        floorFactor = math.max(0, floorFactor * floorFactor)
                    end
                    
                    totalDirtChange = totalDirtChange - WASH_RATE * effectiveness * floorFactor * minutesPassed * data.dirtShare
                    cleanData.washSaturation[part] = math.min(1, cleanData.washSaturation[part] + SATURATION_RATE * submersion * minutesPassed)
                end
            end
        elseif cleanData.washSaturation[part] > 0 then
            cleanData.washSaturation[part] = math.max(0, cleanData.washSaturation[part] - SATURATION_DECAY * minutesPassed)
        end
    end
    
    if math.abs(totalDirtChange) > 0.001 then
        local newDirt = cleanData.dirt + totalDirtChange
        
        if totalDirtChange < 0 then
            newDirt = math.max(SWIM_CLEAN_FLOOR, newDirt)
        end
        
        cleanData.dirt = math.min(1, math.max(0, newDirt))
        updateDirt()
    end
end
]]

--spammed when in swamp water
G_module_clean_swampFunction = function()
    if not NEEDS_CLEAN then return end
    if not G_waterObject then return end
    if not (G_waterObject:find("scum") or G_waterObject:find("lilypad")) then return end
    
    local dirtBefore = cleanData.dirt
    cleanData.dirt = math.min(1, math.max(cleanData.dirt, G_isInWater * 1.2))
    
    if cleanData.dirt > dirtBefore + 0.001 then
        updateDirt()
    end
    
    -- Reset wash saturation for submerged parts
    for part, data in pairs(bodyParts) do
        if G_isInWater > data.minDepth then
            cleanData.washSaturation[part] = 0
        end
    end
end

-- Register jobs
log(3, "[SunsDusk:Clean] Registering module jobs...")
table.insert(G_onLoadJobs, onLoad)
table.insert(G_onLoadJobs, updateWidget) --after all onload jobs, also update widget
table.insert(G_perMinuteJobs, module_clean_minute)
table.insert(G_onConsumeJobs, onConsume)
table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)
table.insert(G_settingsChangedJobs, settingsChanged)

log(3, "[SunsDusk:Clean] Bathing module loaded successfully")
log(3, "[SunsDusk:Clean] allSoapItems table contents:")
for soapId, _ in pairs(allSoapItems) do
	log(3, "[SunsDusk:Clean]   -", soapId)
end
log(3, "[SunsDusk:Clean] allTowelItems table contents:")
for towelId, _ in pairs(allTowelItems) do
	log(3, "[SunsDusk:Clean]   -", towelId)
end
log(3, "[SunsDusk:Clean] towelPatterns:")
for _, pattern in ipairs(towelPatterns) do
	log(3, "[SunsDusk:Clean]   -", pattern)
end

local function lootedItem(container, numItems)
	if not NEEDS_CLEAN then return end
	if not CLEAN_QUICKLOOT then return end
	if not types.Container.objectIsInstance(container) then return end
	local numItemsMult = 1 + 0.2*numItems
	local dirtinessMult =(getDirtinessModifier(true)-1)/2 + 0.5
	cleanData.dirt = math.min(1, cleanData.dirt + 0.003*dirtinessMult*numItemsMult)
end

G_eventHandlers.OwnlysQuickLoot_lootedItem = function(data)
   lootedItem(data[1],1)
end

G_eventHandlers.OwnlysQuickLoot_lootedItems = function(data)
   lootedItem(data[1],#data[2])
end