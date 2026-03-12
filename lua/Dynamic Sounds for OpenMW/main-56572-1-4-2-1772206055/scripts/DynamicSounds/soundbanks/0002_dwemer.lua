local soundBank = {

    isInterior = true,
    affectingCells = {
		'Aleft',
		'Arkngthand',
		'Arkngthunch%-Sturdumz',
		'Bethamez',
		'Bthanchend',
		'Bthuand',
		'Bthungthumz',
		'Druscashti',
		'Galom Daeus',
		'Mudan',
		'Mzahnch',
		'Mzanchend',
		'Mzuleft',
		'Nchardahrk',
		'Nchardumz',
		'Nchuleft',
		'Nchuleftingth',
		'Nchurdamz',
		'Bamz%-Amschend',
		'Sotha Sil',
		'Sorkvild\'s Tower',
		'Endusal',
		'Tureynulal',
		'Odrosal',
		'Vemynal',
		'Dagoth Ur',

		-- TR 
		'Akuband',
		'Alencheth',
		'Amthuandz',
		'Archtumz',
		'Arkgnthleft',
		'Barzamthuand',
		'Bazak',
		'Bazhthum',
		'Bthalag%-Zturamz',
		'Bthangthamuzand',
		'Bthuangthuv',
		'Bthung',
		'Bthungtch',
		'Bthzundcheft',
		'Chunzefk',
		'Durthungz',
		'Hendor%-Stardumz',
		'Kemel%-Ze',
		'Khadumzunch',
		'Leftunch',
		'Manrizache',
		'Mvelthngth%-Schel',
		'Mzankh',
		'Mzungleft',
		'Nchal%-Marschend',
		'Nchazdrumn',
		'Nchulark',
		'Nchulegfth',
		'Ngelfltingth',
		'Ratharzak',
		'Rthungzark',
		'Yaztaramz',

		-- Cyrodiil
		'Acharamz',

		--Archaeologists guild 
		'Derin Bolus',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dwemer\\amb_lp.wav",
            loop = true,
			volume=0.7,
        }
    },

    objects = {

        {
            "door_dwrv",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\ambr_dwemer_dungeon_cracking_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\ambr_dwemer_dungeon_cracking_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\ambr_dwemer_dungeon_cracking_03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\ambr_dwemer_dungeon_rumble_01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\ambr_dwemer_dungeon_rumble_02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\amb_dungeon_dwemer_machinery_02_2dlp.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\amb_dungeon_dwemer_machinery_03_2dlp.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\amb_dungeon_dwemer_machinery_04_2dlp.wav",
                    loop = false
                },
            }
        },
        {
            "in_mud_rock_06",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\cave_rocks.wav",
                    loop = false
                },
            }
        },
        {
            "furn_dwrv_beltdrive",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\obj_dwemergearslarge_mono_01_lp.wav",
                    loop = true
                },
            }
        },
        {
            "in_dwrv_corr",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\dwrv_whisp1.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\dwrv_whisp2.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\dwrv_whisp3.wav",
                    loop = false
                },
            }
        },
        {
            "AB_Furn_DwrvMachPumpLrg",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\dwemer\\pump.wav",
                    loop = true
                },
            }
        },
        {
            "AG_DwemerPylonDerinBolus",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\qst_soul_cairn_portal_open_lp.wav",
                    loop = true,
                    volume = 0.5
                },
            }
        },
        { "Furn_DngChain",
			{
				{ 	soundPath = "sounds\\DynamicSounds\\metal\\chains4.wav",
					loop = false,
				},
			}
		},
        { "furn_dwrv_fitting10",
			{
				{ 	soundPath = "sounds\\DynamicSounds\\water\\steam_02_lp.wav",
					loop = true,
                    volume = 0.5,
				},
			}
		},
        { "ex_dwrv_pipe10",
			{
				{ 	soundPath = "sounds\\DynamicSounds\\water\\steam_02_lp.wav",
					loop = true,
                    volume = 0.8,
				},
			}
		},        
    },

}

return soundBank