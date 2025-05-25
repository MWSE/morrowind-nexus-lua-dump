    --Nordic Barrows

local soundbank = {

    isInterior = true,
    affectingCells = {
        'Barrow',
        'Burial',
        --SHotN Barrows 
        -- 'Asvirsang Barrow',
        -- 'Bathmvall Barrow',
        -- 'Bergarojh Barrow',
        -- 'Bruaram Barrow',
        'Gurmshal',
        -- 'Herlundsval Barrow',
        -- 'Kjorgnir Barrow',
        'Kyrdhaj',
        -- 'Ragnvald Barrow',
        -- 'Skorunde Barrow',
        -- 'Tuskengryd Barrow',
        --bloodmoon 
        -- 'Bloodskal Barrow',
        -- 'Connorflenge Barrow',
        -- 'Eddard Barrow',
        -- 'Frosselmane Barrow',
        'Glenschul\'s Tomb',
        -- 'Gyldenhul Barrow',
        -- 'Himmelhost Barrow',
        -- 'Hrothmund\'s Barrow',
        -- 'Jolgeirr Barrow',
        -- 'Kelsedolk Barrow',
        -- 'Kolbjorn Barrow',
        -- 'Lukesturm Barrow',
        -- 'Skogsdrake Barrow',
        -- 'Stormpfund Barrow',
        'Tombs of Skaalara',
        -- 'Valbrandr Barrow',
		
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambt_dungeon_catacombs_generic_2dlp.wav", 
            loop = true
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dwemer_dungeon_rumble_01.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dwemer_dungeon_rumble_02.wav",
            loop = false
        },
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dungeon_catacombs_cracking_01.wav",
            loop = false
        },  
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\ambr_dungeon_catacombs_shaking_01.wav",
            loop = false
        },                
    },

    objects = {

        {
            "Furn_BM_T_torchstand",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\fx_fire_giant_campfire_01_lp.wav", loop = true, volume = 0.5
                },
            },

        },
        {
            "Ex_BM_tomb_door",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dungeon\\ambt_dungeon_catacombs_semiexterior_lp.wav",
                    loop = true,
                    volume = 0.5,
                },
            }
        }, 




    },





}


return soundbank