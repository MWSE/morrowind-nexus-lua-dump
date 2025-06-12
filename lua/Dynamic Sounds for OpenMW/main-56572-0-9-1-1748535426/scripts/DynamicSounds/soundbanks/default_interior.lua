--this soundbank will be used on any interior cell

local soundbank = {

    isInterior = true,
    affectingCells = {
        'DEFAULT'
    },

    ambientLoopSounds = {
        
        -- ambient interior weather effects 
        
        {
            soundPath = "sounds\\DynamicSounds\\weather\\amb_weather_rain_interior_lp.wav", 
			loop = true, 
			volume = 1.5, 
			weather = {4,5}, 
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
            soundPath = "sounds\\DynamicSounds\\weather\\in_tent_rain01.wav",
            loop = true,
            weather = {4,5}, 
            volume = 0.7,
            ifCellContainsObjects = "in_de_shack,_tent_interior,ashl_tent",
            -- Improved Inns Expanded adds an 'ashl_tent' object inside Arrille\'s Tradehouse
            exceptInCells = {'Arrille\'s Tradehouse'},
        },
        -- {
            -- soundPath = "sounds\\DynamicSounds\\cloth\\amb_bannerrockcairn_lp.wav",
            -- loop = true,
            -- weather = {6,7,9}, 
            -- ifCellContainsObjects = "in_de_shack,_tent_interior,ashl_tent"
        -- },		
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
            ifCellContainsObjects = "in_de_shack,_tent_interior,ashl_tent"
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
		
        
    },

}



return soundbank