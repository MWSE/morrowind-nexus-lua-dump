--this soundbank will be used on any interior cell

local soundbank = {

    isInterior = true,
    affectingCells = {
        'DEFAULT'
    },

    ambientLoopSounds = {
        
        -- ambient interior weather effects 
        
        {
            soundPath = "sounds\\DynamicSounds\\weather\\amb_weather_rain_interior2_lp.wav", 
			loop = true, 
			weather = {4,5}, 
			volume = 1.5, 
			ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,in_c_rich_room",            
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\sand_interior_lp.wav", 
			loop = true, 
			volume = 1.5, 
			weather = {6}, 
			ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,in_c_rich_room",
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_wood_rain01.wav",
            loop = true,
            weather = {4,5}, 
            volume = 0.7,
            ifCellContainsObjects = "in_de_shack",
        },        
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_tent_rain01.wav",
            loop = true,
            weather = {4,5}, 
            volume = 0.7,
            ifCellContainsObjects = "_tent_interior,ashl_tent",
            -- Improved Inns Expanded add an 'ashl_tent' object inside Arrille\'s Tradehouse
			--  some daedric shrines have tents 
            exceptInCells = {'Arrille\'s Tradehouse','Assurdirapal'},
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_tent_wind01.wav",
            loop = true,
            weather = {6,7,9}, 
            ifCellContainsObjects = "_tent_interior,ashl_tent",
			exceptInCells = {'Arrille\'s Tradehouse','Assurdirapal'},
        },		
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_thunder01.wav",
            loop = false,
            weather = {5},
            volume = 0.6,
            PlayChancePercent = 30,
            ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,in_de_shack,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,_tent_interior,ashl_tent,in_c_rich_room"
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_thunder02.wav",
            loop = false,
            weather = {5},
            volume = 0.6,
            PlayChancePercent = 30,
            ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,in_de_shack,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,_tent_interior,ashl_tent,in_c_rich_room"
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_thunder03.wav",
            loop = false,
            weather = {5},
            volume = 0.6,
            PlayChancePercent = 30,
            ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,in_de_shack,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,_tent_interior,ashl_tent,in_c_rich_room"
        },
        {
            soundPath = "sounds\\DynamicSounds\\weather\\in_thunder04.wav",
            loop = false,
            weather = {5},
            volume = 0.6,
            PlayChancePercent = 30,
            ifCellContainsObjects = "in_nord_house,in_c_plain_room,in_hlaalu_roomt,in_de_shack,common_tower_thatch,MGRD_AR_I,in_redoran_,in_v_s_wall,in_hlaalu_room,_tent_interior,ashl_tent,in_c_rich_room"
        },
		
		-- day/night related
        {
            soundPath = "sounds\\DynamicSounds\\fauna\\ambr_crickets_forest_night_c_lp.wav",
            dayCycle = "night",
            loop = true,
            weather = {0,1,2,3},
            volume = 0.2,  
            ifCellContainsObjects = "in_de_shack,_tent_interior,ashl_tent",
			exceptInCells = {'Assurdirapal'},
        },		
		
    },

    objects = {
        
        -- ice and snow
       
        {
            "_icechunk_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_01.wav", 
					loop = false, 
					PlayChancePercent = 10
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_02.wav",
                    loop = false,
                    PlayChancePercent = 10
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_glaciers_a_03.wav",
                    loop = false,
                    PlayChancePercent = 10
                },
            }
        },
        {
            "_icelayer_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_01.wav", 
					loop = false, 
					PlayChancePercent = 10
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_02.wav",
                    loop = false,
                    PlayChancePercent = 10
                },
            }
        },
        {
            "bm_ic_rock",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_01.wav", 
					loop = false, 
					PlayChancePercent = 10
                },
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ambr_icewall_cracking_a_02.wav",
                    loop = false,
                    PlayChancePercent = 10
                },
            }
        },
        {
            "Nor_Set_Forge_01",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\fire_low.wav", 
					volume=0.8,
					loop=true,
                },			
            }
        },	
        {
            "furn_de_bellows",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\interior_general\\bellows2.wav", 
					volume=0.3,
					loop=true,
                },			
            }
        },			

		

         -- object interior weather effects 
        {
            "ex_nord_win",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5}, 
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9}, 
                },				
            }
        },	       
        {
            "ex_S_window",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5},
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9},
                },				
            }
        },       	        	
        {
            "in_colony_win",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5},
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9},
                },				
            }
        },
        {
            "ex_hlaalu_win",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5},
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9},
                },				
            }
        },
        {
            "ex_redoran_window",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5},
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9},
                },				
            }
        },
        {
            "in_c_plain_r_cwin_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\rain_on_window.wav", 
					loop = true, 
					volume=0.3,
                    weather = {4,5},
                },
                {
                    soundPath = "sounds\\DynamicSounds\\weather\\snow_on_window.wav", 
					loop = true, 
					volume=0.5,
                    weather = {8,9},
                },				
            }
        },
        {
            "furn_imp_altar_01",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\water_l.wav", 
					loop = true, 
					volume=0.3,
                },				
            }
        },
        {
            "Furn_BathHalfbarrel_02",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\water_l.wav", 
					loop = true, 
					volume=0.3,
                },				
            }
        },	
		{
            "Act_Crystal_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\crystal5.wav", 
					loop = true,
					volume=0.5,
                },
            }
        },
        {
            "In_TelCrystal",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\crystal5.wav", 
					loop = true,
					volume=0.5,
                },
            }
        },	
        {
            "ingred_fire_salts_01",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\amb_firecrater_01_lp.wav", 
					loop = true,
					volume=0.2,
                },
            }
        },	
        {
            "ingred_frost_salts_01",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\ice\\ice_cracking2.wav", 
					loop = false,
					volume=0.3,
					PlayChancePercent = 5,					
                },
            }
        },			
        {
            "furn_com_cauldron_02",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\boil_lp.wav", 
					loop = true,
					volume=0.5,
                },
            }
        },
        {
            "AB_Misc_6thAshStatue",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\whispers.wav", 
					loop = true,
					volume=0.2,
                },
            }
        },
        {
            "misc_6th_ash_statue",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\whispers.wav", 
					loop = true,
					volume=0.2,
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
					volume=0.3,
                },
            }
        },  		
        {
            "swingin_chair",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\interior_general\\rope_creak_lt_lp.wav", 
					loop = true,
					volume=0.4,
                },
            }
        },		
        {
            "AB_Door_PortalFire",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\amb_obliviongate_lp.wav", 
					loop = true,
					volume=2,
                },
            }
        },  
        {
            "AB_Ex_VelWellFountain",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\water_fountain_l_lp.wav", 
					loop = true,
					volume=0.5,
                },
            }
        },  
        {
            "GG_Ex_MH_Pav_Spout_small", -- Memento Mori Buried
            {
                {
                    soundPath = "sounds\\DynamicSounds\\water\\water_fountain2_lp.wav", 
					loop = true,
					volume=0.4,
                },
            }
        },  		
	
	
	
        
    },

}



return soundbank