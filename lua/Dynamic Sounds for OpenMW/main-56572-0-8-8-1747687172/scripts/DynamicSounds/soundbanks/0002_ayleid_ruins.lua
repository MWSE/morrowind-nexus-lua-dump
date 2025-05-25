--ayleid ruins

local soundbank = {

    isInterior = true,
    affectingCells = {
        --Anvil 
        'Lindasael',
        'Gulaida',
        'Salinen',
        'Beldaburo',
        'Garlas Malatar',
        'Gulaide',
        'Garlas Agea',
        'Valsar',
        'Wormusoel',
        'Nagaiarelle',
        'Vabriasel',
        --bloodmoon 
        'Heliasel',
        'Neselia',
        --TR 
        'Mala Tor',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ayleid_loop.wav", 
        	loop = true
        },
        {        
            soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_spooky_gust_04.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_crumble_a_01.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\dlc1_ambt_dark_dungeon_cave_crumble_a_02.wav",
            loop = false
        },        
    },

    objects = {

        {
            "_WelkyndStnW_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\crystal2.wav", 
                	loop = true, 
                	volume = 0.2
                },
            }
        },
        {
            "_welkydstnw",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\crystal2.wav", 
                	loop = true, 
                	volume = 0.2
                },
            }
        },



    },





}


return soundbank