--ancentral tombs

local soundbank = {

    isInterior = true,
    affectingCells = {
		'Ancestral Tomb',
		'Ancestral Vaults',
		'Gedna Relvel\'s Tomb',
		'Abandoned Crypt',
		'Mugan Crypt',
		'Ashmelech',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambt_dungeon_catacombs_generic_2dlp.wav", 
            loop = true
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dungeon_catacombs_shaking_01.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dungeon_catacombs_shaking_02.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dungeon_catacombs_shaking_03.wav",
            loop = false
        },        
    },

    objects = {
        {
            "altar",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_spooky_gust_01.wav", 
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_spooky_gust_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_spooky_gust_03.wav",
                    loop = false
                },
            }
        },

    },





}


return soundbank