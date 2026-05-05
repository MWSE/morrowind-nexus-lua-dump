-- regional supply/demand pricing database and lookup
-- atm data is ported from buying game but holy fuck it is bad
-- uses sun's dusk API for interior cell region detection
 
local self = require('openmw.self')
local I    = require('openmw.interfaces')
local types = require('openmw.types')
 
local Regions = {}
local CATEGORIES = {}
 
CATEGORIES.spelltome = {}
 
for _, rec in pairs(types.Book.records) do
	local id = rec.id:lower()
	if id:find('^spelltome_') or id:find('^spellbook_') then
		CATEGORIES.spelltome[id] = true
	end
end
 
-- from buying game
CATEGORIES.kwama = {
	['food_kwama_egg_01']				= true,
	['food_kwama_egg_02']				= true,
	['ingred_scrib_jelly_01']			= true,
	['ingred_scrib_jerky_01']			= true,
	['ab_ingcrea_kwamapoison']			= true,
	['ab_ingcrea_scribshell_01']		= true,
	['ab_ingfood_kwamaloaf']			= true,
	['t_ingfood_meatkwama_01']			= true,
	['t_ingfood_scribpie_01']			= true,
	['t_ingcrea_kwamachitin_01']		= true,
}
 
-- from buying game
CATEGORIES.daedra = {
	['ingred_daedra_skin_01']			= true,
	['ingred_daedras_heart_01']			= true,
	['ingred_fire_salts_01']			= true,
	['ingred_frost_salts_01']			= true,
	['ingred_void_salts_01']			= true,
	['ingred_scamp_skin_01']			= true,
	
	-- OAAB
	['ab_ingcrea_clannclaw_01']			= true,
	['ab_ingcrea_twilightmembrane']		= true,
	['ab_ingcrea_daeteeth_01']			= true,
}
 
-- from buying game
CATEGORIES.dwemer = {
	['ab_misc_dwgyro00']				= true,
	['misc_dwrv_coin00']				= true,
}
 
-- from buying game
CATEGORIES.sea = {
	['ingred_pearl_01']					= true,
	['ingred_dreugh_wax_01']			= true,
	['ingred_crab_meat_01']				= true,
	['ingred_scales_01']				= true,
	['ab_ingcrea_dreughshell_01']		= true,
	['ab_ingcrea_sfmeat_01']			= true,
	['t_ingcrea_shellmolecrab_02']		= true,
	['t_ingcrea_shellmolecrab_01']		= true,
	['t_ingcrea_cephalopodshell_01']	= true,
	['t_ingfood_eggmolecrab_01']		= true,
	['t_ingfood_meatornada_01']			= true,
	['t_ingfood_eggornada_01']			= true,
}
 
-- from buying game
CATEGORIES.undead = {
	['ingred_bonemeal_01']				= true,
	['ingred_ectoplasm_01']				= true,
}
 
-- from buying game
CATEGORIES.chitin = {
	['chitin arrow']					= true,
	['chitin club']						= true,
	['chitin dagger']					= true,
	['chitin short bow']				= true,
	['chitin shortsword']				= true,
	['chitin spear']					= true,
	['chitin throwing star']			= true,
	['chitin war axe']					= true,
	['chitin boots']					= true,
	['chitin cuirass']					= true,
	['chitin greaves']					= true,
	['chitin guantlet - left']			= true,
	['chitin guantlet - right']			= true,
	['chitin helm']						= true,
	['chitin pauldron - left']			= true,
	['chitin pauldron - right']			= true,
	['chitin_shield']					= true,
	['chitin_towershield']				= true,
	
	-- TR
	['t_de_chitin_helmopen_01']			= true,
	['t_de_chitin_pauldrl_01']			= true,
	['t_de_chitin_pauldrr_01']			= true,
	
	-- OAAB
}
 
-- from buying game
CATEGORIES.netch = {
	['netch_leather_boiled_cuirass']	= true,
	['netch_leather_boiled_helm']		= true,
	['netch_leather_boots']				= true,
	['netch_leather_cuirass']			= true,
	['netch_leather_gauntlet_left']		= true,
	['netch_leather_gauntlet_right']	= true,
	['netch_leather_greaves']			= true,
	['netch_leather_helm']				= true,
	['netch_leather_pauldron_left']		= true,
	['netch_leather_pauldron_right']	= true,
	['netch_leather_shield']			= true,
	['netch_leather_towershield']		= true,
	['ab_a_netchboilpldleft']			= true,
	['ab_a_netchboilpldright']			= true,
	['t_de_netch_cuirass_01']			= true,
	['t_de_netch_cuirass_02']			= true,
	['t_de_netch_cuirass_03']			= true,
	['t_de_netch_helm_01']				= true,
	['t_de_netch_helm_02']				= true,
	['t_de_netchrogue_cuirass_01']		= true,
	['t_de_netchrogue_helm_01']			= true,
	['t_de_netchrogue_helm_02']			= true,
}
 
-- from buying game
CATEGORIES.ashlander = {
	['ab_misc_ashlflute']				= true,
	['ab_w_ashlbonearrow']				= true,
	['ab_w_bonearrow']					= true,
	['ab_a_bugblueboots']				= true,
	['ab_a_bugbluecuirass']				= true,
	['ab_a_bugbluegntleft']				= true,
	['ab_a_bugbluegntright']			= true,
	['ab_a_bugbluegreaves']				= true,
	['ab_a_bugbluehelm']				= true,
	['ab_a_bugbluepldleft']				= true,
	['ab_a_bugbluepldright']			= true,
	['ab_a_bugblueshield']				= true,
	['ab_a_buggreenboots']				= true,
	['ab_a_buggreencuirass']			= true,
	['ab_a_buggreengntleft']			= true,
	['ab_a_buggreengntright']			= true,
	['ab_a_buggreengreaves']			= true,
	['ab_a_buggreenhelm']				= true,
	['ab_a_buggreenpldleft']			= true,
	['ab_a_buggreenpldright']			= true,
	['ab_a_buggreenshield']				= true,
}
 
CATEGORIES.gems = {
	['ingred_diamond_01']				= true,
	['ingred_ruby_01']					= true,
	['ingred_emerald_01']				= true,
	['ingred_pearl_01']					= true,
	
	-- TR
	['t_ingmine_alexandrite_01']		= true,
	['t_ingmine_amethyst_01']			= true,
	['t_ingmine_aquamarine_01']			= true,
	['t_ingmine_garnet_01']				= true,
	['t_ingmine_khajiiteye_01']			= true,
	['t_ingmine_moonstone_01']			= true,
	['t_ingmine_pearlblack_01']			= true,
	['t_ingmine_pearlkardesh_01']		= true,
	['t_ingmine_sapphire_01']			= true,
	['t_ingmine_topaz_01']				= true,
	['t_ingmine_turquoise_01']			= true,
	["t_ingmine_agate_01"]				= true,
	["t_ingmine_agate_02"]				= true,
	["t_ingmine_agate_03"]				= true,
	["t_ingmine_agate_04"]				= true,
	["t_ingmine_amber_01"]				= true,
	["t_ingmine_amethyst_01"]			= true,	
	["t_ingmine_ametrine_01"]			= true,	
	["t_ingmine_antimony_01"]           = true,
	["t_ingmine_arsenic_01"]            = true,
	["t_ingmine_bloodstone_01"]         = true,
	["t_ingmine_caputmortuum_01"]       = true,
--	["t_ingmine_chalk_01"]              = true,
--	["t_ingmine_charcoal_01"]           = true,
	["t_ingmine_citrine_01"]            = true,
--	["t_ingmine_coal_01"]               = true,
	["t_ingmine_diamondblue_01"]        = true,
	["t_ingmine_diamondred_01"]         = true,
	["t_ingmine_fireopal_01"]           = true,
	["t_ingmine_flashgrit_01"]          = true,
	["t_ingmine_foolsgold_01"]          = true,
	["t_ingmine_icecrystal_01"]         = true,
	["t_ingmine_jade_01"]               = true,
	["t_ingmine_jet_01"]                = true,
	["t_ingmine_lapislazuli_01"]        = true,
	["t_ingmine_lodestone_01"]          = true,
	["t_ingmine_lunarcaustic_01"]       = true,
	["t_ingmine_malouchite_01"]         = true,
	["t_ingmine_onyx_01"]               = true,
	["t_ingmine_opal_01"]               = true,
	["t_ingmine_rosequartz_01"]         = true,
--	["t_ingmine_salt_01"]               = true,
	["t_ingmine_smokyquartz_01"]        = true,
	["t_ingmine_spellstone_01"]         = true,
	["t_ingmine_spinel_01"]             = true,
	["t_ingmine_tektite_01"]            = true,
	["t_ingmine_topazblue_01"]          = true,
	
	["t_ingmine_orebitterstone_01"]     = true,
	["t_ingmine_orebrass_01"]           = true,
	["t_ingmine_orecobalt_01"]          = true,
	["t_ingmine_orecopper_01"]          = true,
	["t_ingmine_oregold_01"]            = true,
	["t_ingmine_oreiron_01"]            = true,
	["t_ingmine_orelead_01"]            = true,
	["t_ingmine_oremercury_01"]         = true,
	["t_ingmine_oreorichalcum_01"]      = true,
	["t_ingmine_oreorichalcum_02"]      = true,
	["t_ingmine_oreplatinum_01"]        = true,
	["t_ingmine_orequicksilver_01"]     = true,
	["t_ingmine_oresilver_01"]          = true,
	["t_ingmine_oresulfur_01"]          = true,
	["t_ingmine_oretin_01"]             = true,
	["t_ingmine_orezinc_01"]            = true,
	["t_ingmine_pearlblack_01"]         = true,
	["t_ingmine_pearlblue_01"]          = true,
	["t_ingmine_pearlkardesh_01"]       = true,
	["t_ingmine_pearlpink_01"]          = true,
	["t_ingmine_peridot_01"]            = true,
	["t_ingmine_realgar_01"]            = true,
	["t_ingmine_rockcrystal_01"]        = true,
	
	-- OAAB
	['ab_ingmine_amethyst_01']			= true,
	['ab_ingmine_blackpearl_01']		= true,
	['ab_ingmine_blacktourmaline_01']	= true,
	['ab_ingmine_diopside_01']			= true,
	['ab_ingmine_firejade_01']			= true,
	['ab_ingmine_garnet_01']			= true,
	['ab_ingmine_goldpearl_01']			= true,
	['ab_ingmine_sapphire_01']			= true,
	['ab_ingmine_topaz_01']				= true,
	['ab_ingmine_tourmaline_01']		= true,
    ["ab_ingmine_bluediamond"]			= true,
    ["ab_ingmine_reddiamond"]			= true,
    ["ab_ingmine_peridot_01"]			= true,
    ["ab_ingmine_lodestone"]			= true,
	
	-- cursed gems
	['ingred_dae_cursed_diamond_01']	= true,
	['ingred_dae_cursed_emerald_01']	= true,
	['ingred_dae_cursed_pearl_01']		= true,
	['ingred_dae_cursed_ruby_01']		= true,
	['t_ingmine_emeralddetomb_01']		= true,
	['t_ingmine_diamonddetomb_01']		= true,	
	['t_ingmine_alexandritedae_01']		= true,
	['t_ingmine_amethystdae_01']		= true,
	['t_ingmine_aquamarinedae_01']		= true,
	['t_ingmine_garnetdae_01']			= true,
	['t_ingmine_khajiiteyedae_01']		= true,
	['t_ingmine_moonstonedae_01']		= true,
	['t_ingmine_pearlblackdae_01']		= true,
	['t_ingmine_pearldetomb_01']		= true,
	['t_ingmine_rubydetomb_01']			= true,
	['t_ingmine_sapphiredae_01']		= true,
	['t_ingmine_topazdae_01']			= true,
	['t_ingmine_turquoisedae_01']		= true,
}
 
-- from buying game: gold, silver, exquisite clothing
CATEGORIES.luxury = {
	['t_imp_goldbowl_01']				= true,
	['t_imp_goldgoblet_01']				= true,
	['t_imp_goldpitcher_01']			= true,
	['t_com_metalpiecegold_01']			= true,
	['t_com_metalpiecegold_02']			= true,
	['t_com_metalpiecegold_03']			= true,
	['t_com_metalpiecesilver_01']		= true,
	['t_com_metalpiecesilver_02']		= true,
	['t_com_metalpiecesilver_03']		= true,
	
	-- clothing	
	['exquisite_skirt_01']				= true,
	['exquisite_shoes_01']				= true,
	['exquisite_shirt_01']				= true,
	['exquisite_ring_02']				= true,
	['exquisite_ring_01']				= true,
	['exquisite_ring_processus']		= true,
	['exquisite_pants_01']				= true,
	['exquisite_belt_01']				= true,
	['exquisite_amulet_01']				= true,
	
	-- TR clothing
	["t_he_ex_amulet_01"]               = true,
	["t_imp_ex_amuletnib_01"]           = true,
	["t_imp_ex_amulet_01"]              = true,
	["t_imp_ex_amulet_dibellan"]        = true,
	["t_qyc_ex_amulet_01"]              = true,
	["t_nor_ex_belt_01"]                = true,
	["t_nor_ex_belt_01_wardice"]        = true,
	["t_nor_ex_belt_01_wardshock"]      = true,
	["t_nor_ex_belt_02"]                = true,
	["t_nor_ex_belt_02_greaterhealing"] = true,
	["t_nor_ex_belt_02_wardfire"]       = true,
	["t_de_ex_pantshla_03"]             = true,
	["t_de_ex_pantshla_04"]             = true,
	["t_de_ex_pantshla_05"]             = true,
	["t_de_ex_pantshla_06"]             = true,
	["t_de_ex_pantshla_07"]             = true,
	["t_de_ex_pantshla_08"]             = true,
	["t_de_ex_pants_01"]                = true,
	["t_de_ex_pants_02"]                = true,
	["t_de_ex_pants_03"]                = true,
	["t_de_ex_pants_04"]                = true,
	["t_de_ex_pants_05"]                = true,
	["t_de_ex_pants_06"]                = true,
	["t_de_ex_pants_07"]                = true,
	["t_de_ex_pants_08"]                = true,
	["t_de_uni_apostatering"]           = true,
	["t_de_ringhlaalusignet"]           = true,
	["t_de_uni_fallenstar_tr"]          = true,
	["t_ayl_ring_01"]                   = true,
	["t_ayl_ring_02"]                   = true,
	["t_bre_ex_ring_01"]                = true,
	["t_com_ex_ring_whispers"]          = true,
	["t_he_ex_ring_01"]                 = true,
	["t_imp_ex_ringnib_01"]             = true,
	["t_rga_eq_ring_01"]                = true,
	["t_de_uni_mantisflip_tr"]          = true,
	["t_nor_uni_ringmoon"]              = true,
	["t_de_ex_robehla_01"]              = true,
	["t_de_ex_robehla_02"]              = true,
	["t_de_ex_robetelv_01"]             = true,
	["t_de_ex_robe_01"]                 = true,
	["t_imp_ex_robenib_01"]             = true,
	["t_imp_ex_robenib_02"]             = true,
	["t_imp_ex_robeconsular_01"]        = true,
	["t_de_ex_shirthla_03"]             = true,
	["t_de_ex_shirthla_04"]             = true,
	["t_de_ex_shirthla_05"]             = true,
	["t_de_ex_shirthla_06"]             = true,
	["t_de_ex_shirthla_07"]             = true,
	["t_de_ex_shirthla_08"]             = true,
	["t_de_ex_shirt_01"]                = true,
	["t_de_ex_shirt_02"]                = true,
	["t_de_ex_shirt_03"]                = true,
	["t_de_ex_shirt_04"]                = true,
	["t_de_ex_shirt_05"]                = true,
	["t_de_ex_shirt_06"]                = true,
	["t_de_ex_shirt_07"]                = true,
	["t_de_ex_shirt_08"]                = true,
	["t_de_ex_shirt_08fff"]             = true,
	["t_de_uni_ex_shirt_08fff"]         = true,
	["t_com_ex_shirt_01"]               = true,
	["t_com_ex_shirt_02"]               = true,
	["t_com_ex_shirt_03"]               = true,
	["t_de_ex_shoeshla_08"]             = true,
	["t_de_ex_shoes_01"]                = true,
	["t_de_ex_shoes_08"]                = true,
	["t_de_ex_skirthla_03"]             = true,
	["t_de_ex_skirthla_04"]             = true,
	["t_de_ex_skirthla_05"]             = true,
	["t_de_ex_skirthla_06"]             = true,
	["t_de_ex_skirthla_07"]             = true,
	["t_de_ex_skirt_03"]                = true,
	["t_de_ex_skirt_04"]                = true,
	["t_de_ex_skirt_05"]                = true,
	["t_de_ex_skirt_06"]                = true,
	["t_de_ex_skirt_07"]                = true,
	["t_com_ex_skirt_01"]               = true,
	["t_com_ex_skirt_02"]               = true,
	["t_com_ex_skirt_03"]               = true,
 
	-- OAAB
	["ab_c_exquisiteamulet01"]          = true,
	["ab_c_exquisitering01"]            = true,
}
 
CATEGORIES.coins = {
	['misc_dwrv_coin00']				= true,
	['misc_dwrv_cursed_coin00']			= true,
	
	-- TR
	['t_ayl_coingold_01']				= true,
	['t_ayl_coinsquare_01']				= true,
	['t_ayl_coinbig_01']				= true,
	['t_he_dirennicoin_01']				= true,
	['t_imp_coinreman_01']				= true,
	['t_imp_coinalessian_01']			= true,
	['t_nor_coinbarrowcopper_01']		= true,
	['t_nor_coinbarrowiron_01']			= true,
	['t_nor_coinbarrowsilver_01']		= true,
	
	-- OAAB
	['ab_misc_cointriune']				= true,
}
 
CATEGORIES.soulgem = {
	['misc_soulgem_petty']				= true,
	['misc_soulgem_lesser']				= true,
	['misc_soulgem_common']				= true,
	['misc_soulgem_greater']			= true,
	['misc_soulgem_grand']				= true,
	['misc_soulgem_azura']				= true,
	
	-- OAAB
	['ab_misc_soulgemblack']			= true,
}
 
-- use sun's dusk food and alcohol instead because this is ridiculous lmfao
CATEGORIES.food = {
	['ingred_hound_meat_01']			= true,
	['food_kwama_egg_01']				= true,
	['food_kwama_egg_02']				= true,
	['ingred_scrib_jelly_01']			= true,
	['ingred_scrib_jerky_01']			= true,
	['ingred_ash_yam_01']				= true,
	['ingred_bread_01']					= true,
	['ingred_crab_meat_01']				= true,
	['ingred_durzog_meat_01']			= true,
	['ingred_saltrice_01']				= true,
	['ingred_scuttle_01']				= true,
	['ab_ingcrea_guarmeat_01']			= true,
	['ab_ingcrea_horsemeat01']			= true,
	['ab_ingcrea_sfmeat_01']			= true,
	['t_ingcrea_meatdark_01']			= true,
	['t_ingcrea_velknectarsack_01']		= true,
	['t_ingflor_cabbage_01']			= true,
	['potion_ancient_brandy']			= true,
	['potion_comberry_brandy_01']		= true,
	['potion_comberry_wine_01']			= true,
	['potion_cyro_brandy_01']			= true,
	['potion_cyro_whiskey_01']			= true,
	['potion_local_brew_01']			= true,
	['potion_local_liquor_01']			= true,
	['potion_nord_mead']				= true,
}
 
-- export = abundant here. import = scarce here.
local db = {}
 
local function ensure(key)
	key = key:lower()
	if not db[key] then db[key] = { export = {}, import = {} } end
	return db[key]
end
 
local function addCatExport(catName, locations)
	local cat = CATEGORIES[catName]
	if not cat then return end
	for _, loc in ipairs(locations) do
		local entry = ensure(loc)
		for item in pairs(cat) do
			if not entry.import[item] then entry.export[item] = true
			else entry.import[item] = nil end
		end
	end
end
 
local function addCatImport(catName, locations)
	local cat = CATEGORIES[catName]
	if not cat then return end
	for _, loc in ipairs(locations) do
		local entry = ensure(loc)
		for item in pairs(cat) do
			if not entry.export[item] then entry.import[item] = true
			else entry.export[item] = nil end
		end
	end
end
 
local function addRegionGoods(region, towns)
	local src = db[region:lower()]
	if not src then return end
	for _, town in ipairs(towns) do
		local dst = ensure(town)
		for item in pairs(src.export) do
			if dst.export[item] ~= false then dst.export[item] = true end
		end
		for item in pairs(src.import) do
			if dst.import[item] ~= false then dst.import[item] = true end
		end
	end
end
 
-- VVARDENFELL REGIONS
 
-- from buying game
ensure('grazelands region').export = {
	['ingred_hound_meat_01']			= true,
	['ingred_alit_hide_01']				= true,
	['ingred_kagouti_hide_01']			= true,
	['ingred_raw_glass_01']				= true,
	['ingred_hackle-lo_leaf_01']		= true,
	['ingred_stoneflower_01']			= true,
	['ingred_wickwheat_01']				= true,
	['ingred_shalk_resin_01']			= true,
	['ingred_scuttle_01']				= true,
	['ingred_guar_hide_01']				= true,
	
	-- OAAB
	['ab_ingfood_scuttlepie']			= true,
	['ab_ingflor_telvanniresin']		= true,
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('grazelands region').import = {
	['sc_paper plain']					= true,
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	-- OAAB
	['ab_sc_blank']						= true,
	['ab_sc_blankbargain']				= true,
	['ab_sc_blankcheap']				= true,
	['ab_sc_blankexclusive']			= true,
	['ab_sc_blankquality']				= true,
}
 
-- from buying game
ensure('west gash region').export = {
	['ingred_hound_meat_01']			= true,
	['ingred_alit_hide_01']				= true,
	['ingred_kagouti_hide_01']			= true,
	['ingred_raw_ebony_01']				= true,
	['ingred_bittergreen_01']			= true,
	['ingred_chokeweed_01']				= true,
	['ingred_green_lichen_01']			= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_roobrush_01']				= true,
	['ingred_muck_01']					= true,
	['ingred_stoneflower_01']			= true,
	['potion_local_liquor_01']			= true, -- sujamma
	
	-- OAAB
	['ab_ingflor_bgslime_01']			= true,
}
 
-- from buying game
ensure('west gash region').import = {
	
	-- OAAB
	['ab_w_eggminerhook']				= true,
	['ab_a_eggminerhelm']				= true,
}
 
-- from buying game
ensure('ashlands region').export = {
	['ingred_hound_meat_01']			= true,
	['ingred_raw_glass_01']				= true,
	['ingred_raw_ebony_01']				= true,
	['ingred_diamond_01']				= true,
	['ingred_fire_fern_01']				= true,
	['ingred_red_lichen_01']			= true,
	['ingred_scathecraw_01']			= true,
	['ingred_trama_root_01']			= true,
	['ingred_shalk_resin_01']			= true,
	['ingred_scuttle_01']				= true,
	['ingred_ash_salts_01']				= true,	
	['ingred_guar_hide_01']				= true,
	
	-- OAAB
	['ab_ingfood_scuttlepie']			= true,
	['ab_ingcrea_guarmeat_01']			= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
-- use "bread" category from SD database
ensure('ashlands region').import = {
	['ingred_bread_01']					= true,
	['p_cure_blight_s']					= true,
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	-- OAAB
	['ab_w_eggminerhook']				= true,
	['ab_a_eggminerhelm']				= true,
}
 
-- from buying game
ensure('red mountain region').export = {
	['ingred_raw_glass_01']				= true,
	['ingred_raw_ebony_01']				= true,
	['ingred_diamond_01']				= true,
	['ingred_fire_fern_01']				= true,
	['ingred_red_lichen_01']			= true,
	['ingred_scathecraw_01']			= true,
	['ingred_trama_root_01']			= true,
	['ingred_shalk_resin_01']			= true,
	['ingred_scuttle_01']				= true,
	['ingred_ash_salts_01']				= true,
	['ingred_guar_hide_01']				= true,
	
	-- OAAB
	['ab_ingfood_scuttlepie']			= true,	
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
-- use "bread" category from SD database
ensure('red mountain region').import = {
	['ingred_bread_01']					= true,
	['p_cure_blight_s']					= true,
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('bitter coast region').export = {
	['ingred_netch_leather_01']			= true,
	['ingred_bungler_bane_01']			= true,
	['ingred_draggle_tail_01']			= true,
	['ingred_hypha_facia']				= true,
	['ingred_luminous_russula_01']		= true,
	['ingred_slough_fern_01']			= true,
	['ingred_violet_coprinus_01']		= true,
	['ingred_hound_meat_01']			= true,
	['ingred_crab_meat_01']             = true,
	
	-- sun's dusk
	["sd_pouch"]                        = true,
	["sd_backpack"]                     = true,
	["sd_backpack_traveler"]            = true,
	["sd_backpack_adventurer"]          = true,
	["sd_backpack_velvetblue"]          = true,
	["sd_backpack_satchelbrown"]        = true,
	["sd_backpack_adventurerbl"]        = true,
	["sd_backpack_adventurergr"]        = true,
	["sd_backpack_velvetbrown"]         = true,
	["sd_backpack_velvetgreen"]         = true,
	["sd_backpack_velvetpink"]          = true,
	["sd_backpack_satchelblue"]         = true,
	["sd_backpack_satchelblack"]        = true,
	["sd_backpack_satchelgreen"]        = true,
}
 
-- from buying game
ensure('bitter coast region').import = {
	['p_cure_common_s']					= true,
	
	-- TR
	['t_rga_fishingspear_01']			= true,
	
	-- OAAB
	['ab_w_toolfishingnet']				= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('ascadian isles region').export = {
	['ingred_hound_meat_01']			= true,
	['ingred_kagouti_hide_01']			= true,
	['ingred_netch_leather_01']			= true,
	['ingred_ash_yam_01']				= true,
	['ingred_black_anther_01']			= true,
	['ingred_comberry_01']				= true,
	['ingred_corkbulb_01']				= true,
	['ingred_gold_canet_01']			= true,
	['ingred_heather_01']				= true,
	['ingred_marshmerrow_01']			= true,
	['ingred_saltrice_01']				= true,
	['ingred_willow_flower_01']			= true,
	['ingred_guar_hide_01']				= true,	
	['potion_local_brew_01']			= true,	
	['potion_comberry_brandy_01']		= true,
	['potion_comberry_wine_01']			= true,	
	
	-- sun's dusk
	["sd_pouch"]                        = true,
	["sd_backpack"]                     = true,
	["sd_backpack_traveler"]            = true,
	["sd_backpack_adventurer"]          = true,
	["sd_backpack_velvetblue"]          = true,
	["sd_backpack_satchelbrown"]        = true,
	["sd_backpack_adventurerbl"]        = true,
	["sd_backpack_adventurergr"]        = true,
	["sd_backpack_velvetbrown"]         = true,
	["sd_backpack_velvetgreen"]         = true,
	["sd_backpack_velvetpink"]          = true,
	["sd_backpack_satchelblue"]         = true,
	["sd_backpack_satchelblack"]        = true,
	["sd_backpack_satchelgreen"]        = true,	
	
	-- OAAB
	['ab_ingcrea_guarmeat_01']			= true,
	['ab_ingfood_saltricebread']		= true,
}
 
-- from buying game
ensure('ascadian isles region').import = {
	-- OAAB
	['ab_w_toolhandscythe00']			= true,
	['ab_w_toolhandscythe01']			= true,
	['ab_w_toolscythe']					= true,
}
 
-- from buying game
ensure('molag amur region').export = {
	['ingred_fire_fern_01']				= true,
	['food_kwama_egg_01']				= true,
	['food_kwama_egg_02']				= true,
	['ingred_scathecraw_01']			= true,
	['ingred_trama_root_01']			= true,
	['ingred_shalk_resin_01']			= true,
	['ingred_scuttle_01']				= true,
	['ingred_racer_plumes_01']			= true,
	
	-- OAAB
	['ab_ingfood_scuttlepie']			= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
-- use sun's dusk "bread" category
ensure('molag amur region').import = {
	['ingred_bread_01']					= true,
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	-- OAAB
	['ab_w_eggminerhook']				= true,
	['ab_a_eggminerhelm']				= true,
}
 
-- from buying game
ensure("azura's coast region").export = {
	['ingred_alit_hide_01']				= true,
	['ingred_black_anther_01']			= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_marshmerrow_01']			= true,
	['ingred_muck_01']					= true,
	['ingred_saltrice_01']				= true,
	['ingred_racer_plumes_01']			= true,
	['potion_local_brew_01']			= true,
	
	-- OAAB
	['ab_ingfood_saltricebread']		= true,
	['ab_ingflor_telvanniresin']		= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure("azura's coast region").import = {
	['sc_paper plain']					= true,
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	-- OAAB
	['ab_sc_blank']						= true,
	['ab_sc_blankbargain']				= true,
	['ab_sc_blankcheap']				= true,
	['ab_sc_blankexclusive']			= true,
	['ab_sc_blankquality']				= true,
}
 
-- from buying game
ensure('sheogorad region').export = {
	['ingred_black_anther_01']			= true,
	['ingred_gold_canet_01']			= true,
	['ingred_green_lichen_01']			= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_racer_plumes_01']			= true,
}
 
-- from buying game
ensure('sheogorad region').import = {
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
}
 
-- SOLSTHEIM
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('solstheim').export = {
	['ingred_raw_ebony_01']				= true,
	['ingred_bear_pelt']				= true,
	['ingred_boar_leather']				= true,
	['ingred_belladonna_01']			= true,
	['ingred_belladonna_02']			= true,
	['ingred_holly_01']					= true,
	['ingred_horker_tusk_01']			= true,
	['potion_nord_mead']				= true,	
	
	-- sun's dusk
	["sd_pouch"]                        = true,
	["sd_backpack"]                     = true,
	["sd_backpack_traveler"]            = true,
	["sd_backpack_adventurer"]          = true,
	["sd_backpack_velvetblue"]          = true,
	["sd_backpack_satchelbrown"]        = true,
	["sd_backpack_adventurerbl"]        = true,
	["sd_backpack_adventurergr"]        = true,
	["sd_backpack_velvetbrown"]         = true,
	["sd_backpack_velvetgreen"]         = true,
	["sd_backpack_velvetpink"]          = true,
	["sd_backpack_satchelblue"]         = true,
	["sd_backpack_satchelblack"]        = true,
	["sd_backpack_satchelgreen"]        = true,	
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	-- TR
	['t_ingfood_meathorker_01']			= true,
}
 
-- from buying game
ensure('solstheim').import = {
	['potion_cyro_brandy_01']			= true,
	['potion_cyro_whiskey_01']			= true,
}
 
-- TOWNS
-- from buying game
ensure('ald-ruhn').export = {
	['bonemold_gah-julan_cuirass']		= true,
	['bonemold_gah-julan_helm']			= true,
	['bonemold_gah-julan_pauldron_l']	= true,
	['bonemold_gah-julan_pauldron_r']	= true,
	['bonemold_tshield_redoranguard']	= true,
}
 
-- from buying game
ensure('balmora').export = {
	['bonemold_armun-an_cuirass']		= true,
	['bonemold_armun-an_helm']			= true,
	['bonemold_armun-an_pauldron_l']	= true,
	['bonemold_armun-an_pauldron_r']	= true,
	['bonemold_tshield_hlaaluguard']	= true,
	['potion_skooma_01']				= true,
}
 
-- from buying game
ensure('balmora').import = {
	['t_he_direnniscales_01']			= true,
	['t_imp_silverscales_01']			= true,
	['t_imp_silverscales_02']			= true,
}
 
-- from buying game
ensure('suran').export = {
	['bonemold_armun-an_cuirass']		= true,
	['bonemold_armun-an_helm']			= true,
	['bonemold_armun-an_pauldron_l']	= true,
	['bonemold_armun-an_pauldron_r']	= true,
	['bonemold_tshield_hlaaluguard']	= true,
	['potion_skooma_01']				= true,
}
 
-- from buying game
ensure('suran').import = {
	-- TR
	['t_he_direnniscales_01']			= true,
	['t_imp_silverscales_01']			= true,
	['t_imp_silverscales_02']			= true,
}
 
-- from buying game
ensure('khuul').import = {
	['p_cure_common_s']					= true,
	
	-- TR
	['ab_w_toolfishingnet']				= true,
	['t_rga_fishingspear_01']			= true,
}
 
ensure('ald velothi').import = ensure('khuul').import
 
-- from buying game
ensure('tel branora').export = {
	['bonemold_tshield_telvanniguard']	= true,
	['cephalopod_helm']					= true,
	['dust_adept_helm']					= true,
	['mole_crab_helm']					= true,
	['potion_t_bug_musk_01']			= true,
	
	-- OAAB
	['ab_a_cephhelmopen']				= true,	
}
 
-- from buying game
ensure('tel branora').import = {
	['food_kwama_egg_01']				= true,
	['food_kwama_egg_02']				= true,
}
 
ensure('tel aruhn').export = ensure('tel branora').export
 
-- from buying game
ensure('tel aruhn').import = {
	['6th bell hammer']					= true,
	['misc_goblet_dagoth']				= true,
	['potion_ancient_brandy']			= true,
	['ingred_corprus_weepings_01']		= true,
	['ingred_ghoul_heart_01']			= true,
}
 
ensure('sadrith mora').export = ensure('tel branora').export
 
-- from buying game
ensure('vhuul').export = {
	-- TR
	['t_de_drink_punavitjug']			= true,
	['t_de_drink_punavitresin_01']		= true,
}
 
-- from buying game
ensure('vhuul').import = {
	-- TR
	['t_ingcrea_velknectarsack_01']		= true,
}
 
-- TAMRIEL REBUILT REGIONS
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('aanthirin region').export = {
	['ingred_netch_leather_01']			= true,
	['ingred_ash_yam_01']				= true,
	['ingred_black_anther_01']			= true,
	['ingred_comberry_01']				= true,
	['ingred_corkbulb_01']				= true,
	['ingred_gold_canet_01']			= true,
	['ingred_heather_01']				= true,
	['ingred_marshmerrow_01']			= true,
	['ingred_saltrice_01']				= true,
	['ingred_willow_flower_01']			= true,	
	['ingred_guar_hide_01']				= true,
	['ingred_hackle-lo_leaf_01']		= true,
	['ingred_scrib_cabbage_01']			= true,
	['ingred_muck_01']					= true,
	['ingred_stoneflower_01']			= true,	
	['potion_comberry_brandy_01']		= true,
	['potion_comberry_wine_01']			= true,
	['potion_local_brew_01']			= true,
	
	-- sun's dusk
	["sd_pouch"]                        = true,
	["sd_backpack"]                     = true,
	["sd_backpack_traveler"]            = true,
	["sd_backpack_adventurer"]          = true,
	["sd_backpack_velvetblue"]          = true,
	["sd_backpack_satchelbrown"]        = true,
	["sd_backpack_adventurerbl"]        = true,
	["sd_backpack_adventurergr"]        = true,
	["sd_backpack_velvetbrown"]         = true,
	["sd_backpack_velvetgreen"]         = true,
	["sd_backpack_velvetpink"]          = true,
	["sd_backpack_satchelblue"]         = true,
	["sd_backpack_satchelblack"]        = true,
	["sd_backpack_satchelgreen"]        = true,	
	
	-- OAAB
	['ab_ingfood_saltricebread']		= true,	
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- from buying game
ensure('aanthirin region').import = {
	['ab_w_toolhandscythe00']			= true,
	['ab_w_toolhandscythe01']			= true,
	['ab_w_toolscythe']					= true,
}
 
-- from buying game
ensure('alt orethan region').export = {
	['ingred_nirthfly_stalks_01']		= true,
	['ingred_meadow_rye_01']			= true,
	['ingred_bittergreen_01']			= true,
	['ingred_chokeweed_01']				= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_roobrush_01']				= true,
	['ingred_stoneflower_01']			= true,
	['ingred_gold_canet_01']			= true,
	['ingred_black_anther_01']			= true,
	['ingred_willow_flower_01']			= true,
}
 
-- from buying game
ensure('ascadian bluffs region').export = {
	['ingred_black_anther_01']			= true,
	['ingred_comberry_01']				= true,
	['ingred_corkbulb_01']				= true,
	['ingred_willow_flower_01']			= true,
}
 
-- from buying game
ensure('ascadian bluffs region').import = {
	-- TR
	['t_rga_fishingspear_01']			= true,
	
	-- OAAB
	['ab_w_toolfishingnet']				= true,	
}
 
-- from buying game
ensure("boethiah's spine region").export = {
	['ingred_wickwheat_01']				= true,
	['ingred_kresh_fiber_01']			= true,
}
 
-- from buying game
ensure('helnim fields region').export = {
	['ingred_hackle-lo_leaf_01']		= true,
	['ingred_wickwheat_01']				= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('lan orethan region').export = {
	['ingred_corkbulb_01']				= true,
	['ingred_nirthfly_stalks_01']		= true,
	['ingred_meadow_rye_01']			= true,
	['ingred_chokeweed_01']				= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_roobrush_01']				= true,
	['ingred_comberry_01']				= true,
	['ingred_stoneflower_01']			= true,
	['ingred_gold_canet_01']			= true,
	['ingred_black_anther_01']			= true,
	['ingred_willow_flower_01']			= true,	
	
	-- Sun's Dusk wood from publicans and from player inventory
	['sd_wood_publican']				= true,
	['sd_wood_1']						= true,
	
	--TR
	['t_ingmine_oregold_01']			= true,
}
 
-- from buying game
ensure('mephalan vales region').export = {
	['ingred_hound_meat_01']			= true,
	['ingred_guar_hide_01']				= true,
	['ingred_alit_hide_01']				= true,
	['ingred_kagouti_hide_01']			= true,
	['ingred_racer_plumes_01']			= true,
}
 
-- from buying game
ensure('molagreahd region').export = {
	['ingred_hackle-lo_leaf_01']		= true,
	['ingred_wickwheat_01']				= true,
	['ingred_marshmerrow_01']			= true,
	['ingred_guar_hide_01']				= true,
	['ingred_alit_hide_01']				= true,
	['ingred_hound_meat_01']			= true,
	
	-- OAAB
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- from buying game
ensure('nedothril region').export = {
	['ingred_nirthfly_stalks_01']		= true,
	['ingred_meadow_rye_01']			= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_corkbulb_01']				= true,
	['ingred_stoneflower_01']			= true,
}
 
-- from buying game except sun's dusk stuff which replaced the ashfall things
ensure('sundered scar region').export = {
	['ingred_netch_leather_01']			= true,
	['ingred_bungler_bane_01']			= true,
	['ingred_draggle_tail_01']			= true,
	['ingred_hypha_facia']				= true,
	['ingred_luminous_russula_01']		= true,
	['ingred_slough_fern_01']			= true,
	['ingred_violet_coprinus_01']		= true,
	['ingred_raw_glass_01']				= true,
	['ingred_hound_meat_01']			= true,
	
	-- sun's dusk
	["sd_pouch"]                        = true,
	["sd_backpack"]                     = true,
	["sd_backpack_traveler"]            = true,
	["sd_backpack_adventurer"]          = true,
	["sd_backpack_velvetblue"]          = true,
	["sd_backpack_satchelbrown"]        = true,
	["sd_backpack_adventurerbl"]        = true,
	["sd_backpack_adventurergr"]        = true,
	["sd_backpack_velvetbrown"]         = true,
	["sd_backpack_velvetgreen"]         = true,
	["sd_backpack_velvetpink"]          = true,
	["sd_backpack_satchelblue"]         = true,
	["sd_backpack_satchelblack"]        = true,
	["sd_backpack_satchelgreen"]        = true,	
}
 
-- from buying game
ensure('sundered scar region').import = {
	['p_cure_common_s']					= true,
	
	-- TR
	['t_rga_fishingspear_01']			= true,
	
	-- OAAB
	['ab_w_toolfishingnet']				= true,	
}
 
-- from buying game
ensure('telvanni isles region').export = {
	['ingred_kresh_fiber_01']			= true,
	['ingred_muck_01']					= true,
	['ingred_netch_leather_01']			= true,
}
 
-- from buying game
ensure('roth roryn region').export = {
	['ingred_guar_hide_01']				= true,
	['ingred_alit_hide_01']				= true,
	['ingred_kagouti_hide_01']			= true,
	['ingred_hound_meat_01']			= true,
	['ingred_netch_leather_01']			= true,
	['ingred_muck_01']					= true,
	['ingred_wickwheat_01']				= true,
	['ingred_ash_yam_01']				= true,
	['ingred_corkbulb_01']				= true,
	['ingred_hackle-lo_leaf_01']		= true,
	
	-- OAAB
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- from buying game
ensure('sacred lands region').export = {
	['ingred_wickwheat_01']				= true,
	['ingred_chokeweed_01']				= true,
	['ingred_kresh_fiber_01']			= true,
	['ingred_roobrush_01']				= true,
	['ingred_muck_01']					= true,
	['ingred_stoneflower_01']			= true,
	['ingred_guar_hide_01']				= true,
	['ingred_hound_meat_01']			= true,
	
	-- OAAB
	['ab_ingcrea_guarmeat_01']			= true,	
}
 
-- Category expansions from buying game
addCatExport('kwama', { 'Molag Amur Region', 'West Gash Region', 'Ashlands Region', 'Sacred Lands Region', "Boethiah's Spine Region", 'Mephalan Vales Region', 'Aanthirin Region', })
addCatExport('daedra', { 'Grazelands Region', "Azura's Coast Region", 'Molag Amur Region', "Boethiah's Spine Region", 'Mephalan Vales Region', 'Armun Ashlands Region', })
addCatExport('dwemer', { 'Molag Amur Region', "Boethiah's Spine Region", 'Sheogorad Region', })
addCatExport('sea', { 'Bitter Coast Region', "Azura's Coast Region", 'Sheogorad Region','Padomaic Ocean Region', 'Sea of Ghosts Region','Ascadian Bluffs Region', 'Telvanni Isles Region', })
addCatExport('undead', { 'Sacred Lands Region', 'Aranyon Pass Region' })
 
-- region->town
addRegionGoods('West Gash Region', { 'Balmora', 'Caldera', 'Gnisis', 'Khuul', 'Ald Velothi' })
addRegionGoods('Bitter Coast Region', { 'Seyda Neen', 'Gnaar Mok', 'Hla Oad' })
addRegionGoods('Ascadian Isles Region', { 'Suran', 'Pelagiad', 'Ebonheart' })
addRegionGoods('Molag Amur Region', { 'Molag Mar', 'Erabenimsun Camp' })
addRegionGoods("Azura's Coast Region", { 'Tel Branora', 'Tel Aruhn', 'Sadrith Mora', 'Tel Mora' })
addRegionGoods('Grazelands Region', { 'Vos', 'Tel Vos', 'Ahemmusa Camp' })
addRegionGoods('Sheogorad Region', { 'Dagon Fel' })
addRegionGoods('Ashlands Region', { 'Ald-ruhn', 'Maar Gan', 'Urshilaku Camp' })
addRegionGoods('Red Mountain Region', { 'Ghostgate' })
addRegionGoods('Solstheim', { 'Felsaad Coast', 'Hirstaang Forest', 'Isinfier Plains', 'Moesring Mountains', 'Skaal Village', 'Thirsk', 'Raven Rock', 'Fort Frostmoth', })
 
-- Town category expansions
addCatExport('netch', { 'Balmora', 'Suran' })
addCatExport('chitin', { 'Ald-ruhn', 'Urshilaku Camp', 'Erabenimsun Camp', 'Ahemmusa Camp', 'Zainab Camp',})
addCatExport('ashlander', { 'Urshilaku Camp', 'Erabenimsun Camp', 'Ahemmusa Camp', 'Zainab Camp',})
addCatImport('gems', { 'Balmora', 'Suran' })
addCatImport('luxury', { 'Balmora', 'Suran' })
addCatImport('coins', { 'Balmora', 'Suran' })
addCatImport('soulgem', { 'Tel Branora', 'Tel Aruhn', 'Sadrith Mora', 'Tel Mora', 'Vos', 'Tel Vos', })
addCatImport('spelltome', { 'Tel Branora', 'Tel Aruhn', 'Sadrith Mora', 'Tel Mora', 'Vos', 'Tel Vos', }) -- add telvanni isle here
addCatImport('food', { 'Ald-ruhn', 'Maar Gan', 'Ghostgate' })
 
local townKeys = {}
for key in pairs(db) do
	if not key:find(' region$') and key ~= 'solstheim' then
		townKeys[key] = true
	end
end
 
local function getCellPrefix(cell)
	if not cell or cell.isExterior then return nil end
	return (cell.id:match('^([^,]+)') or ''):lower()
end
 
local function getRegionId()
	local cell = self.cell
	if not cell then return nil end
	if cell.isExterior then return cell.region end
	if I.SunsDusk then
		local ci = I.SunsDusk.getCellInfo()
		if ci and ci.nextExterior then return ci.nextExterior.region end
	end
	return nil
end
 
local function getCurrentEntry()
	local cell = self.cell
	if not cell then return nil end
	-- town prefix
	local prefix = getCellPrefix(cell)
	if prefix and prefix ~= '' and townKeys[prefix] then
		return db[prefix]
	end
	-- region
	local rid = getRegionId()
	if rid then return db[rid:lower()] end
	return nil
end
 
-- because i don't feel like doing interior cell regions 3x
function Regions.hasSunsDusk()
	return I.SunsDusk ~= nil
end
 
function Regions.isExport(recordId)
	local e = getCurrentEntry()
	return e and e.export[recordId:lower()] or false
end
 
function Regions.isImport(recordId)
	local e = getCurrentEntry()
	return e and e.import[recordId:lower()] or false
end
 
-- buying = player is buying from merchant
-- knowsExport = playerMerc >= export knowledge threshold
function Regions.getRegionalMultiplier(recordId, buying, modifier, knowsExport)
	if not modifier or modifier <= 0 then return 1 end
	local id = recordId:lower()
	local e = getCurrentEntry()
	if not e then return 1 end
	local f = modifier / 100
	if buying then
		if e.import[id] then return 1 + f end
		if e.export[id] and knowsExport then return 1 - f end
	else
		if e.export[id] then return 1 - f end
		if e.import[id] and knowsExport then return 1 + f end
	end
	return 1
end
 
function Regions.getItemStatus(recordId)
	local e = getCurrentEntry()
	if not e then return nil end
	local id = recordId:lower()
	if e.export[id] then return 'export' end
	if e.import[id] then return 'import' end
	return nil
end
 
return Regions
