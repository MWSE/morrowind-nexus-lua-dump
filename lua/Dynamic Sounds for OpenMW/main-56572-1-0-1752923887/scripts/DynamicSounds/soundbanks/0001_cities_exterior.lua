local soundbank = {

    isInterior = false,
    affectingCells = {
		'Ald%-ruhn',
		'Balmora',
		'Sadrith Mora',
		'Vivec',
		'Ghostgate',
		'Gnisis',
		'Maar Gan',
		'Molag Mar',
		'Suran',
		'Tel Aruhn',
		'Tel Branora',
		'Tel Mora',
		'Ald Velothi',
		'Dagon Fel',
		'Gnaar Mok',
		'Hla Oad',
		'Khuul',
		'Seyda Neen',
		'Tel Fyr',
		'Tel Vos',
		'Vos',
		'Indarys Manor',
		'Rethan Manor',
		'Tel Uvirith',
		'Caldera',
		'Ebonheart',
		'Pelagiad',			
		-- shotn
		'Dragonstar',
		'Karthwasten',
		'Karthgad',
		-- Solstheim 
		'Raven Rock',
		'Skaal Village',
		'Thirsk' ,	
		-- TR
		'Firewatch',
		'Narsis',
		'Old Ebonheart',
		'Bal Foyen',
		'Necrom',
		'Akamora',
		'Almas Thirr',
		'Hlan Oek',
		'Port Telvannis',
		-- TR towns T%-4
		'Darvonis',
		'Helnim',
		'Dondril',
		'Llothanis',
		'Ranyon%-ruhn',
		'Roa Dyr',
		'Sailen',
		'Vhul',
		-- cyrodiil 
		'Anvil',
		'Charach',
		'Brina Cross',
		'Goldstone' ,

    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\cities\\npc_human_blacksmith_hammerdistant_02.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_hammer_01.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_hammer_03.wav",
            loop = false,
            PlayChancePercent = 40
        },        
        {
            soundPath = "sounds\\DynamicSounds\\cities\\npc_human_chiselhammer_distant_02.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\npc_human_chiselhammer_distant_03.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_door_01.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_door_05.wav",
            loop = false,
            PlayChancePercent = 40
        },
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_bell_01.wav", 
			loop = false, 
			PlayChancePercent = 40
        },        
        {
            soundPath = "sounds\\DynamicSounds\\cities\\ambr_city_bell_02.wav",
            loop = false,
            PlayChancePercent = 40
        },

    },

    objects = {
        {
            "ex_common_door_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
                            
                            'Shenk\'s Shovel',
                            'The End of the World',
                            'Six Fishes',
                            'Tower of Dusk',
                            'The Pilgrim\'s Rest',
                            'Fara\'s Hole in the Wall',
                            'Desele\'s House of Earthly Delights',
                            'Plot and Plaster',
                            'The Covenant',
                            'The Flowers of Gold',
                            'The Lizard\'s Head',
                                                       
                            -- TR
                            'The Grey Lodge',
                            'The Laughing Goblin',
                            'Underground Bazaar',
                            'Hostel of the Crossing',
                            'Limping Scrib',
                            'The Pious Pirate',
                            'The Dancing Cup',
                            'The Guar With No Name',
                            'Lucky Shalaasa\'s Caravanserai',
                            'The Nest',
                            'The Gentle Velk',
                            'The Howling Noose',
                            'The Queen\'s Cutlass',
                            'Silver Serpent',
                            'Unnamed Legion Bar',
                            'Mjornir\'s Meadhouse',
                            'The Red Drake',
                            'The Leaking Spore',
                            'The Swallow\'s Nest',
                            'The Golden Glade',
                            'Pilgrim\'s Respite',
                            'The Empress Katariah',
                            'Legion Boarding House',
                            'The Moth and Tiger',
                            'The Salty Futtocks',
                            'The Avenue',
                            'The Dancing Jug',
                            'The Strider\'s Wake',
                            'The Toiling Guar',
                            'The Cliff Racer\'s Rest',
                            'The Glass Goblet',
                            'The Note In Your Eye',
                            'The Magic Mudcrab',
                            'Twisted Root',
                            'The Howling Hound',

                            --SHotN
                            'Dancing Saber',
                         
                        }
                },
            
            },
			

        },
		
		{
			"hlaalu_loaddoor",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
                            
                            'Eight Plates',
							'Lucky Lockup',
							'House of Earthly Delights',
							
                                                       
                            -- TR
                            'The Grey Lodge',
                            'The Laughing Goblin',
                            'Underground Bazaar',
                            'Hostel of the Crossing',
                            'Limping Scrib',
                            'The Pious Pirate',
                            'The Dancing Cup',
                            'The Guar With No Name',
                            'Lucky Shalaasa\'s Caravanserai',
                            'The Nest',
                            'The Gentle Velk',
                            'The Howling Noose',
                            'The Queen\'s Cutlass',
                            'Silver Serpent',
                            'Unnamed Legion Bar',
                            'Mjornir\'s Meadhouse',
                            'The Red Drake',
                            'The Leaking Spore',
                            'The Swallow\'s Nest',
                            'The Golden Glade',
                            'Pilgrim\'s Respite',
                            'The Empress Katariah',
                            'Legion Boarding House',
                            'The Moth and Tiger',
                            'The Salty Futtocks',
                            'The Avenue',
                            'The Dancing Jug',
                            'The Strider\'s Wake',
                            'The Toiling Guar',
                            'The Cliff Racer\'s Rest',
                            'The Glass Goblet',
                            'The Note In Your Eye',
                            'The Magic Mudcrab',
                            'Twisted Root',
                            'The Howling Hound',                         
                        }
                },
            
            },		
		},
		
		{
			"velothi_loaddoor",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
                                                       
                            -- TR
                            'The Grey Lodge',
                            'The Laughing Goblin',
                            'Underground Bazaar',
                            'Hostel of the Crossing',
                            'Limping Scrib',
                            'The Pious Pirate',
                            'The Dancing Cup',
                            'The Guar With No Name',
                            'Lucky Shalaasa\'s Caravanserai',
                            'The Nest',
                            'The Gentle Velk',
                            'The Howling Noose',
                            'The Queen\'s Cutlass',
                            'Silver Serpent',
                            'Unnamed Legion Bar',
                            'Mjornir\'s Meadhouse',
                            'The Red Drake',
                            'The Leaking Spore',
                            'The Swallow\'s Nest',
                            'The Golden Glade',
                            'Pilgrim\'s Respite',
                            'The Empress Katariah',
                            'Legion Boarding House',
                            'The Moth and Tiger',
                            'The Salty Futtocks',
                            'The Avenue',
                            'The Dancing Jug',
                            'The Strider\'s Wake',
                            'The Toiling Guar',
                            'The Cliff Racer\'s Rest',
                            'The Glass Goblet',
                            'The Note In Your Eye',
                            'The Magic Mudcrab',
                            'Twisted Root',
                            'The Howling Hound',                         
                        }
                },
            
            },		
		},		
		
		{
			"Ex_redoran_hut_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
                            
                            'The Rat In The Pot',
                                                       
                            -- TR
                            'The Grey Lodge',
                            'The Laughing Goblin',
                            'Underground Bazaar',
                            'Hostel of the Crossing',
                            'Limping Scrib',
                            'The Pious Pirate',
                            'The Dancing Cup',
                            'The Guar With No Name',
                            'Lucky Shalaasa\'s Caravanserai',
                            'The Nest',
                            'The Gentle Velk',
                            'The Howling Noose',
                            'The Queen\'s Cutlass',
                            'Silver Serpent',
                            'Unnamed Legion Bar',
                            'Mjornir\'s Meadhouse',
                            'The Red Drake',
                            'The Leaking Spore',
                            'The Swallow\'s Nest',
                            'The Golden Glade',
                            'Pilgrim\'s Respite',
                            'The Empress Katariah',
                            'Legion Boarding House',
                            'The Moth and Tiger',
                            'The Salty Futtocks',
                            'The Avenue',
                            'The Dancing Jug',
                            'The Strider\'s Wake',
                            'The Toiling Guar',
                            'The Cliff Racer\'s Rest',
                            'The Glass Goblet',
                            'The Note In Your Eye',
                            'The Magic Mudcrab',
                            'Twisted Root',
                            'The Howling Hound',                         
                        }
                },
            
            },		
		},		
		
		{
			"ex_t_door_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
							
							'Fara\'s Hole in the Wall',
							'Plot and Plaster',
							'The Covenant',
                                                       
                            -- TR
                            'The Grey Lodge',
                            'The Laughing Goblin',
                            'Underground Bazaar',
                            'Hostel of the Crossing',
                            'Limping Scrib',
                            'The Pious Pirate',
                            'The Dancing Cup',
                            'The Guar With No Name',
                            'Lucky Shalaasa\'s Caravanserai',
                            'The Nest',
                            'The Gentle Velk',
                            'The Howling Noose',
                            'The Queen\'s Cutlass',
                            'Silver Serpent',
                            'Unnamed Legion Bar',
                            'Mjornir\'s Meadhouse',
                            'The Red Drake',
                            'The Leaking Spore',
                            'The Swallow\'s Nest',
                            'The Golden Glade',
                            'Pilgrim\'s Respite',
                            'The Empress Katariah',
                            'Legion Boarding House',
                            'The Moth and Tiger',
                            'The Salty Futtocks',
                            'The Avenue',
                            'The Dancing Jug',
                            'The Strider\'s Wake',
                            'The Toiling Guar',
                            'The Cliff Racer\'s Rest',
                            'The Glass Goblet',
                            'The Note In Your Eye',
                            'The Magic Mudcrab',
                            'Twisted Root',
                            'The Howling Hound',                         
                        }
                },
            
            },		
		},		
		
        {
            "T_Imp_SetAnv_Door",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\taverns\\amb_tavernexterior_01_lp.wav", 
					volume = 1.5, 
					loop = true, 
					ifDestinationCellsAre = {
                            'Tradehouse',
                            'Inn',
                            'Club',
                            'Cornerclub',
                            'Tavern',
                            'Hostel',
                            'Alehouse',
                            'Bar',
                            'Pub',
                            
                            --Cyrodiil--
                            'The Sload\'s Tale',
                            'The Abecette',
                            'Caravan Stop',
                            'Sailor\'s Fulke',
                            'Anchor\'s Rest',
                            'The Blind Watchtower',
                            'Plaza Taverna',
                            'Sunset Hotel',

                         
                        }
                },
            
            },
			

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
	

    },






}


return soundbank