
local soundbank = {


    -- fighters guild
    
        isInterior = true,
        affectingCells = {
			'Guild of Fighters',	
        },

        ambientLoopSounds = {
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\guid_fighters_lp.wav", 
					loop = true,	
					volume=1,
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\swords.wav", 
					loop = false,	
					volume=0.5,
					PlayChancePercent=15, 
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\swords2.wav", 
					loop = false,	
					volume=0.5,
					PlayChancePercent=15, 
				},
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\armor.wav", 
					loop = false,	
					volume=1,
					PlayChancePercent=10, 
				},	
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\weapon_wood.wav", 
					loop = false,	
					volume=1,
					PlayChancePercent=15, 
				},				
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\blacksmith_hammer_02.wav", 
					loop = false,	
					volume=0.2,
					PlayChancePercent=10, 
				},					
			
		},
		 objects = {        
		 
		}

    
}


return soundbank
