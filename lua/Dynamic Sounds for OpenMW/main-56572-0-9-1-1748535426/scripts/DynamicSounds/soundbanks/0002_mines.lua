local soundbank = {

    isInterior = true,
    affectingCells = {
        'Mine',
        'Eggmine',
        'Mausur Caverns',
        'Vassir-Didanat Cave',
        'Dunirai Caverns',
        'Massama Cave',
        
        --SHotN Mines 
        'Mineworks',

        -- TR     
        'Palisnabat',
        'Anbarsud',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\cave\\cavewind.wav", 
			loop = true
        },
        {
            soundPath = "sounds\\DynamicSounds\\wood\\ambr_interior_woodrattle_01.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\wood\\ambr_interior_woodrattle_02.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\wood\\ambr_interior_woodrattle_03.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\mine\\obj_sawmill_forkpush_lpm.wav",
            loop = false
        },	
        {
            soundPath = "sounds\\DynamicSounds\\mine\\obj_sawmill_forkreturn_lpm.wav",
            loop = false
        },	
        {
            soundPath = "sounds\\DynamicSounds\\cave\\obj_rotating_stone_pillar_release_02.wav",
            loop = false
        },	
        {
            soundPath = "sounds\\DynamicSounds\\cities\\npc_human_chiselhammer_distant_02.wav",
            loop = false
        },	
        {
            soundPath = "sounds\\DynamicSounds\\cities\\npc_human_chiselhammer_distant_03.wav",
            loop = false
        },                                        
    },

    objects = {

        {
            "in_py_rock",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\cave\\cavedrip01.wav", 
					loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\cave\\cavedrip02.wav",
                    loop = false
                },
            }
        },
        {
            "in_ar_0",
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
            "ex_common_plat_end",
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
            "door_cavern_doors",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\ambt_dungeon_catacombs_semiexterior_lp.wav", 
					loop = true
                },
            }
        },	
        -- {
            -- "Act_Crystal_",
            -- {
                -- {
                    -- soundPath = "sounds\\DynamicSounds\\magic\\crystal3.wav", 
					-- loop = true
                -- },
            -- }
        -- },			

    },

}



return soundbank