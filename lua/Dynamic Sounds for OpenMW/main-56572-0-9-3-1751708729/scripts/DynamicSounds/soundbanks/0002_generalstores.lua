
local soundbank = {
    
        isInterior = true,
        affectingCells = {
			'Pawnbroker',
			'Trader',
			'Merchant',
        },

        ambientLoopSounds = {
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\openclosecabinet.wav", 
					loop = false,	
					PlayChancePercent = 50,
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\openclosecabinet2.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\opencabinet.wav", 
					loop = false,	
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\clean.wav", 
					loop = false,	
				},					
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\glass.wav", 
					loop = false,	
					PlayChancePercent = 50,
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\glass2.wav", 
					loop = false,	
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\glass2.wav", 
					loop = false,	
				},				
		},
		 objects = {        
		 
		}


}


return soundbank
