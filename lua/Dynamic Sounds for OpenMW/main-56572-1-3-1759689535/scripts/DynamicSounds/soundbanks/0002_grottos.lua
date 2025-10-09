local soundbank = {

    isInterior = true,
    affectingCells = {
        'Grotto',
        'Koal Cave',

        --TR 
        'Beranus Cavern',
        'Kitanga',
        'Malarnubi',
        'Manupillat',
        'Marsud',

        --Cyrodiil 
        'Mormolycea',
        'Norinia',


    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\amb_dungeon_howl_a_2dlp.wav",
        	loop = true
        },
        {
            soundPath = "sounds\\DynamicSounds\\cave\\amb_dungeon_cave_drips_b_2dlp.wav",
            loop = true,
        },
        {
            soundPath = "sounds\\DynamicSounds\\cave\\cave13.wav",
            loop = false,
            PlayChancePercent = 5
        },
        {
            soundPath = "sounds\\DynamicSounds\\cave\\cave02.wav",
            loop = false,
        },
        {
            soundPath = "sounds\\DynamicSounds\\cave\\phy_water_m_01.wav",
            loop = false,
            volume=0.3
        },
    },

    objects = {


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



    },







}


return soundbank