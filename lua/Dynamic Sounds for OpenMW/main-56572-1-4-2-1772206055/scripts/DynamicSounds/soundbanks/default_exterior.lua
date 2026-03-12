--this soundbank will be used on any exterior cell 

local soundbank = {
    
    isInterior = false,
    affectingCells = {
        'DEFAULT'
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\fauna\\ambr_crickets_forest_night_c_lp.wav",
            dayCycle = "night",
            loop = true,
            weather = {0,1,2,3},
            volume = 0.5
        },
        {
            soundPath = "sounds\\dynamicsounds\\snow\\amb_wind_snowblowing_c_01_lp.wav",
            loop = true,
            weather = {9},
            volume = 1.5
        },
        {
            soundPath = "sounds\\DynamicSounds\\snow\\amb_weather_snow_light_2dlp.wav",
            loop = true,
            weather = {8},
            volume = 0.5
        },
        {
            soundPath = "sounds\\DynamicSounds\\wind\\sand2_lp.wav",
            loop = true,
            weather = {6},
            volume = 1
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\blight_whispers_lp.wav",
            loop = true,
            weather = {7},
            volume = 1
        },

    },

    objects = {
        {
            "active_sign_c",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\wooden_sign_creak.wav",
                    loop = true
                },
            }
        },
        {
            "_sign_LoKKen_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\wooden_sign_creak.wav",
                    loop = true
                },
            }
        },	
        {
            "furn_sign_inn_stendarr",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\wooden_sign_creak.wav",
                    loop = true
                },
            }
        },			
        {
            "furn_banner",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },
        {
            "RP_slave_market_suran",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },
        {
            "BannerTavern",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },	
        {
            "Act_banner_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },	
        {
            "ex_ashl_u_banner_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },	
        {
            "ex_ashl_e_banner_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },
        {
            "ex_ashl_z_banner",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\flag04.wav",
                    loop = true
                },
            }
        },        
		
		
        {
            "in_c_plain_room_side",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak04.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak05.wav",
                    loop = false
                },
            }
        },
        {
            "flora_emp_parasol",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird01.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird02.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird03.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird04.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird05.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird06.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird07.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird08.wav",
                    loop = false,
                    dayCycle = "day"
                },
            }
        },
        {
            "flora_tree_wg",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird01.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird02.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird03.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird04.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird05.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird06.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird07.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird08.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_b_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_b_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_b_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_07.wav",
                    loop = false
                },                                
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl01.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl02.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl03.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl05.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl06.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl04.wav",
                    loop = false,
                    dayCycle = "night"
                },
                                
            }
        },
        {
            "flora_tree_gl",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_01.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_02.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_03.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_04.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_05.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_06.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_07.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_plains_bird_08.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_a_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_tundra_wind_gust_a_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_07.wav",
                    loop = false
                },                 
            }
        },
        {
            "act_flora_tree_MH",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird01.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird02.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird03.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird04.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird05.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird06.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird07.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\bird08.wav",
                    loop = false,
                    dayCycle = "day"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl01.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl02.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl03.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl05.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl06.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl04.wav",
                    loop = false,
                    dayCycle = "night"
                },
                                
            }
        },        
        {
            "flora_emp_parasol",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl01.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl02.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl03.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl05.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl06.wav",
                    loop = false,
                    dayCycle = "night"
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\owl04.wav",
                    loop = false,
                    dayCycle = "night"
                },
            }
        },
        {
            "terrain_rock_ma",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\amb_dustdrop_debris_01.wav",
                    PlayChancePercent = 10,
                    loop = false
                },
            }
        },
        {
            "SP_Bm_Flora_Tree",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_a_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_a_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_a_04.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_a_05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_c_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_kw_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_kw_b_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_kw_c_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_kw_d_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_wind_forestfall_gust_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_wind_forestfall_gust_a_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_wind_forestfall_gust_a_03.wav",
                    loop = false
                },
            }
        },
        {
            "Flora_tree_BM_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_c_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_d_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_d_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_g_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_g_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_h_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_h_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_i_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_i_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_k_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forestpine_k_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_a_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_a_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_b_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_b_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_forestfall_gust_b_03.wav",
                    loop = false
                },
            }
        },
        {
            "flora_tree_ac",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_117.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_118.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_119.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_122.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_123.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_birds_forest_124.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wind\\ambr_forest_windgust_07.wav",
                    loop = false
                },                 
            }
        },
        {
            "_icechunk_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_01.wav",
                    loop = false,
                    PlayChancePercent = 20
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_02.wav",
                    loop = false,
                    PlayChancePercent = 20
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_03.wav",
                    loop = false,
                    PlayChancePercent = 20
                },
            }
        },
        {
            "_icelayer_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_01.wav",
                    loop = false,
                    PlayChancePercent = 20
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_02.wav",
                    loop = false,
                    PlayChancePercent = 20
                },
            }
        },
        {
            "_snow_log_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_a_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_b_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_b_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_c_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_c_02.wav",
                    loop = false
                },
            }
        },
        {
            "_snowstump_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_d_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_d_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_f_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_f_02.wav",
                    loop = false
                },
            }
        },
        {
            "ex_de_ship",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\amb_ship_deckcreak_03_2dlp.wav",
                    loop = true,
                    volume = 0.2
                },
            }
        },
        {
            "Ex_DeShip",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\amb_ship_deckcreak_03_2dlp.wav",
                    loop = true,
                    volume = 0.2
                },
            }
        },				
        {
            "Ex_BM_tomb_door",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_spooky_gust_02.wav",
                    loop = false,
                    volume = 1,
                    PlayChancePercent = 5
                },
            }
        },        
        {
            "Flora_BM_holly",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_g_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_g_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_h_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_insect_solstheim_h_02.wav",
                    loop = false
                },
            },
        },
		
		{
            "in_ar_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak01.wav", 
					loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak03.wav",
                    loop = false
                },
            }
        },  

		{
            "Ash_altar",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\fx_fire_giant_campfire_01_lp.wav", 
					loop = true,
					volume=0.3,
                },
            }
        },  		
        {
            "AB_Fx_AshMire_",
            {
                {
					soundPath = "sounds\\DynamicSounds\\water\\magma_lp.wav", 
					loop = true, 
					volume = 1,  					
				},             
            },

        },	
		{
            "AB_Furn_DaeForge",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\fire_low2.wav", 
					loop = true,
					volume=0.3,
                },
            }
        },

		-- RP_fireflies / Kogoruhn mod
		{
            "_Fauna_Glowbug",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\firefly_lp.wav", 
					loop = true,
					volume=0.6,
                },
            }
        },  

		{
            "a_siltstrider",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\silt_breath.wav", 
					loop = false,
					PlayChancePercent = 10,
					volume=2,
                },
            }
        },  	
        
		{   
            "T_Glb_TerrWater_Waterfall",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\waterfall_lp.wav", 
                    loop = true,
                },
            }
        },   
        
		{   
            "VEHK_flame_2",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\magic_fire_lp.wav", 
                    loop = true,
                    volume=2,
                },
            }
        },        
 		
		
		-- =======================================================================================================
		-- exterior weather on objects
		-- =======================================================================================================

        {
            "_velothi_hilltent_",
            {
                {
					soundPath = "sounds\\DynamicSounds\\weather\\in_tent_rain01.wav", 
					loop = true, 
					volume = 1.5, 
					weather = {4,5},   					
				},
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\amb_bannerrockcairn_lp.wav",
                    loop = true,
					volume = 1.5, 
					weather = {6},   					
				}                
            },

        },	
        {
            "ashl_tent",
            {
                {
					soundPath = "sounds\\DynamicSounds\\weather\\in_tent_rain01.wav", 
					loop = true, 
					volume = 1.5, 
					weather = {4,5},   					
				},
                {
                    soundPath = "sounds\\DynamicSounds\\cloth\\amb_bannerrockcairn_lp.wav",
                    loop = true,
					volume = 1.5, 
					weather = {6},   					
				}                
            },

        },			
		
		
    },
	
	
	


}



return soundbank

