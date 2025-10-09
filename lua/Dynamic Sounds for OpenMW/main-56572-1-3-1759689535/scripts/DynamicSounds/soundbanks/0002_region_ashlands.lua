local soundbank = {
  affectingRegions = {
		"ashlands region",
		"armun ashlands region",
		"grey meadows region",
  },
  ambientLoopSounds = {
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_a_01.wav", 
                loop = false,
                PlayChancePercent=10,
            },
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_a_02.wav", 
                loop = false,
                PlayChancePercent=10,
            },	
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_a_03.wav", 
                loop = false,
                PlayChancePercent=10,
            },		
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_b_01.wav", 
                loop = false,
                PlayChancePercent=10,
            },		
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_b_02.wav", 
                loop = false,
                PlayChancePercent=10,
            },		
            {
                soundPath = "sounds\\DynamicSounds\\wind\\ambr_wind_ashlands_gust_b_03.wav", 
                loop = false,
                PlayChancePercent=10,
            },	
			{
				soundPath = "sounds\\DynamicSounds\\fauna\\npc_siltstrider_call_stereo_01.wav", 
				loop = false,
				PlayChancePercent=2,
			},	
			{
				soundPath = "sounds\\DynamicSounds\\fauna\\npc_siltstrider_call_stereo_02.wav", 
				loop = false,
				PlayChancePercent=2,
			},				
            {
                soundPath = "sounds\\DynamicSounds\\fauna\\amb_os_crow_006.wav",
                PlayChancePercent=40,
                loop = false,
            }, 
            {
                soundPath = "sounds\\DynamicSounds\\fauna\\amb_os_crow_007.wav",
                PlayChancePercent=40,
                loop = false,
            },             
					
  },
  
  objects = {
    {
        "gg_fence_s_main",
        {
            {
                soundPath = "sounds\\DynamicSounds\\magic\\ghost_gate_2d_lp.wav", 
                loop = true,
                volume=10,
            },
        },
        {
            "ashland_rock",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\ambr_tundravolcanic_rumble_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\ambr_tundravolcanic_rumble_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\ambr_tundravolcanic_rumblerocks_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\ambr_tundravolcanic_rumblerocks_02.wav",
                    loop = false
                },
            }
        },
        {
            "terrain_ashland_rock",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\amb_dustdrop_debris_01.wav",
                    loop = false
                },
            }
        },
        {
            "flora_ashtree",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_04.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_05.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_06.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\fauna\\ambr_ashlands_howl_2d_07.wav",
                    loop = false
                },
            }
        },	

    },

},
                   
}
return soundbank


