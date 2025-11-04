local soundbank = {


	-- taverns and inns

	isInterior = true,
	affectingCells = {
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
		'LoKKen Main Hall',
		'Rat In The Pot',

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

		--Cyrodiil--
		'The Sload\'s Tale',
		'The Abecette',
		'Caravan Stop',
		'Sailor\'s Fulke',
		'Anchor\'s Rest',
		'The Blind Watchtower',
		'Plaza Taverna',
		'Sunset Hotel',

		--SHotN
		'Dancing Saber',

		-- Brother Junipers Twin Lamps
		'Stendarr\'s Retreat',
	},

	ambientLoopSounds = {
		{ 
			soundPath = "sounds\\DynamicSounds\\taverns\\amb_inn_lp.wav", 
			loop = true 
		},
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_dishes_01.wav", 
			loop = false,	
			playchancepercent = 40,
		},
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_dishes_02.wav", 
			loop = false,	
			playchancepercent = 40,
		},
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_dishes_05.wav", 
			loop = false,	
			playchancepercent = 40,
		},
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_dishes_06.wav", 
			loop = false,	
			playchancepercent = 40,
		},
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_dishes_08.wav", 
			loop = false,	
			playchancepercent = 40,
		},	
		{
		   soundpath = "sounds\\dynamicsounds\\interior_general\\amb_os_chair_02.wav", 
			loop = false,	
			volume=0.8,
			playchancepercent = 40,
		},			
	},

	objects = {
		{ "furn_Com_RM_Bar", {
			{ soundPath = "sounds\\DynamicSounds\\taverns\\npc_human_bartenderwipe_01.wav", loop = false, PlayChancePercent = 1 },
			{ soundPath = "sounds\\DynamicSounds\\taverns\\npc_human_pour_mead_keg_01.wav", loop = false, PlayChancePercent = 1 },
			{ soundPath = "sounds\\DynamicSounds\\taverns\\npc_human_stir_pot_04.wav",      loop = false, PlayChancePercent = 1 },
		} },
		{ "furn_com_rm_table", {
			{ soundPath = "sounds\\DynamicSounds\\taverns\\npc_human_drink_01.wav", loop = false, PlayChancePercent = 1 },
			{ soundPath = "sounds\\DynamicSounds\\taverns\\npc_human_eat_03.wav",   loop = false, PlayChancePercent = 1 },

		} },
	},




}


return soundbank
