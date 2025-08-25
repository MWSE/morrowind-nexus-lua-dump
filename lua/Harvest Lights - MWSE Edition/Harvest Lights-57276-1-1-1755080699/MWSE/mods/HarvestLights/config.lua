local this = {}

this.defaultConfig = {
	enabled = true,
	singleDistance = 160,
	debug = false,
	containerLights =
[["flora_bc_mushroom" "T_Mw_Flora_Bluefoot", "T_Glb_Flora_Nirnroot", "T_Mw_FloraTV_Weepveil", "flora_bc_podplant_03", "Flora_BC_podplant_04"; "bc mushroom 64", "bc mushroom 128", "bc mushroom 177", "bc mushroom 256", "blue_256_ci_01"

"cavern_spore00", "T_Mw_Flora_Bloatspore01"; "T_Mw_Light_Bloatspore_128", "T_Mw_Light_Bloatspore_512", "TR_m2_bloatspore_128", "TR_m2_bloatspore_512"

"egg_kwama00", "AB_r_KwamaEggBlighted"; "eggsack_glow_256", "AB_light@_Eggsack128", "AB_light@_Eggsack256", "AB_light@_Eggsack512"

"rock_ebony", "AB_m_EbonyKwama"; "ebony light"

"rock_glass"; "green light_128", "green light_256", "green light_256_2", "green light_256_3", "green light_400"

"rock_adam", "T_Cyr_Mine_OreCHAdam", "T_Cyr_Mine_OreGCAdam01", "T_Mw_Mine_OreOMAdam"; "adamantium"

"T_Mw_FloraOW_Glwshrm"; "T_Mw_Light_Glowshrooms_128", "T_Mw_Light_Glowshrooms_256", "T_Mw_Light_Glowshrooms_512", "blue_128_pulse"

"T_Mw_Flora_SheggShelf"; "Green_SPulse_64", "Green_SPulse_128", "Green_SPulse_256"
	
"T_Mw_Flora_TempleDom"; "T_Mw_Light_AanthirinMushroom"
	
"T_Sky_Flora_LichenCav", "Rust Russula"; "Flame Light_64", "orange_128_01_d", "orange light_test"
	
"T_Sky_Flora_BksporeCp"; "yellow_128_01"
	
"T_Mw_Mine_OreSapphire", "T_Mw_Mine_OreSHSaph", "T_Pi_Mine_OreYNSaphire"; "T_Mw_Light_Sapphire_128"
	
"T_Mw_Flora_YamOrb"; "T_Glb_Light_Plant_64", "T_Glb_Light_Plant_128", "T_Glb_Light_Plant_256", "T_Glb_Light_Plant_512"
	
"flora_black_lichen", "flora_green_lichen", "flora_red_lichen", "T_Mw_Flora_Lichen"; "glowing lichen light", "glowing lichen light 256", "glowing lichen light 512"

"T_Cyr_Flora_CairnBol"; "T_Glb_Light_Shroom1_128", "T_Glb_Light_Shroom2_128", "T_Glb_Light_Shroom3_128", "T_Glb_Light_Shroom4_128"
	
"T_Glb_Mine_Spellstone"; "T_Glb_Light_Spellstone_256", "blue light"

"AB_f_GlowingMuscaria"; "AB_light@_ChanterelleGlow064", "AB_light@_ChanterelleGlow128"]]
}

this.settings = mwse.loadConfig("HarvestLights", this.defaultConfig)

return this