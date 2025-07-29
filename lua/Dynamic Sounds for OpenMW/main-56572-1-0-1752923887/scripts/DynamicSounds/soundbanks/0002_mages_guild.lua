
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
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\alchemy.wav", 
					loop = false,	
				},					
		},
		 objects = {        
		 
		}

    
}


return soundbank
