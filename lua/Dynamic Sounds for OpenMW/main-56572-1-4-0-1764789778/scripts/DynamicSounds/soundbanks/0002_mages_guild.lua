
local soundbank = {


    -- mages guild
    
        isInterior = true,
        affectingCells = {
			'Mages Guild',  
			'Guild of Mages',	
        },

        ambientLoopSounds = {
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\ambient2_lp.wav", 
					loop = true,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\book1.wav", 
					loop = false,	
					volume=0.1,
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\book2.wav", 
					loop = false,	
					volume=0.1,
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\writing.wav", 
					loop = false,	
					volume=0.3,
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\alchemy.wav", 
					loop = false,	
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_book_shuffle_os_03.wav", 
					loop = false,	
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_book_shuffle_os_04.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_chair_creak_os_01.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_chair_creak_os_02.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_paper_os_05.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\amb_library_paper_os_09.wav", 
					loop = false,	
				},
		},
		 objects = {        
		 
		}

    
}


return soundbank
