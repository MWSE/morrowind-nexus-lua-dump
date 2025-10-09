--daedric shrines

local soundBank = {
    isInterior = true,
    affectingCells = {
		'Ashunartes',
		'Ashurnibibi',
		'Assurdirapal',
		'Dushariran',
		'Ibishammus',
		'Kaushtarari',
		'Shashpilamat',
		'Zergonipal',
		'Valenvaryon',
		'Sheogorad Region',
		'Ald Sotha',
		'Ashalmimilkala',
		'Assarnatamat',
		'Assernerairan',
		'Assurnabitashpi',
		'Ebernanit',
		'Ularradallaku',
		'Yasammidan',
		'Ashalmawia',
		'Bal Ur',
		'Esutanamus',
		'Kushtashpi',
		'Ramimilk',
		'Tusenend',
		'Yansirramus',
		'Addadshashanammu',
		'Ald Daedroth',
		'Almurbalarammi',
		'Assalkushalit',
		'Bal Fell',
		'Ihinipalit',
		'Maelkashishi',
		'Onnissiralis',
		'Zaintiraris',
		'Anudnabia',
		'Khartag Point',
		'Magas Volar',
		'Shrine of Azura',
		'Shrine of Boethiah',
		'Magas Volar',
		'Shrine of Azura',
		'Shrine of Boethiah',

		--TR 
		'Adadpaliki',
		'Adursaranit',
		'Ald Balaal',
		'Ald Khan',
		'Ald Mirathi',
		'Ald Niripal',
		'Ald Uman',
		'Ald Uran',
		'Alta Vathor',
		'Anashbibi',
		'Andarannipal',
		'Ashinanibibi',
		'Ashishibishi',
		'Ashurbalipal',
		'Ashushushi',
		'Ashpibishal',
		'Assukilunend',
		'Baelkashpitu',
		'Bessarnamidan',
		'Boethian Deeps',
		'Bushipananit',
		'Ebamasharisus',
		'Ebamusharisus',
		'Ebunammidan',
		'Emmurbalpitu',
		'Essarnartes',
		'Essurnashpi',
		'Esuranamit',
		'Hadrumnibibi',
		'Hummurushtapi',
		'Ibiammusashan',
		'Ikinammassu',
		'Kalkusara',
		'Kaushirimilk',
		'Malkamalit',
		'Manishtashut',
		'Mashadananit',
		'Naemunbatashpi',
		'Narasnabad',
		'Nunalabbi',
		'Onimushili',
		'Ossurnashalit',
		'Rasdamassilu',
		'Shambalu',
		'Shumalkashudanit',
		'Sirsadrorran',
		'Teknilashashulpi',
		'Ulanababia',
		'Varashimmus',
		'Veranzaris',
		'Vounoura',
		'Yabananit',
		'Yamandalkal',
		'Yamuninisharn',
		'Yanishanabi',
		'Yashazmus',
		'Bapatipi',
				
		-- The Wake of Hanin
		'Hanin\'s Gateway',
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\amb_dungeon_howl_a_2dlp.wav",
            loop = true
        }
    },

    objects = {
        {
            "in_dae_door",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric01.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric02.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric03.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric04.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric05.wav",
                    loop = false
                },
            }
        },
        {
            "light_dae_censer",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric06.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric07.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric08.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric09.wav",
                    loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\daedric\\daedric10.wav",
                    loop = false
                },
            }
        },
        {
            "in_dae_hall",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\amb_dustdrop_debris_01.wav",
                    loop = false,
                    PlayChancePercent = 5
                },
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\amb_dustdrop_debris_02.wav",
                    loop = false,
                    PlayChancePercent = 5
                },
                {
                    soundPath = "sounds\\DynamicSounds\\natural\\amb_dustdrop_debris_03.wav",
                    loop = false,
                    PlayChancePercent = 5
                },
            }
        },
        {
            "bs_oblivion_cube",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\qst_soul_cairn_portal_open_lp.wav",
                    loop = true,
                    volume = 0.5
                },
            }
        },
        {
            "bs_furn_dae_fount_blood",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\qst_soul_cairn_portal_open_lp.wav",
                    loop = true,
                    volume = 0.5
                },
            }
        },		
        {
            "bs_furn_dae_fount_mag",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\qst_soul_cairn_portal_open_lp.wav",
                    loop = true,
                    volume = 0.5
                },
            }
        },			
		
        {
            "bs_light_mb_DAE",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\amb_firecrater_01_lp.wav",
                    loop = true
                },
            }
        },
        {
            "AB_Furn_DaeForge_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\fire\\fire_low.wav", 
					volume=0.8,
					loop=true,   
                },
            }
        },
        {
            "bs_In_mb_crystal_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\magic\\crystal5.wav", 
					loop = true,
					volume=0.5,   
                },
            }
        },		
    },


}

return soundBank