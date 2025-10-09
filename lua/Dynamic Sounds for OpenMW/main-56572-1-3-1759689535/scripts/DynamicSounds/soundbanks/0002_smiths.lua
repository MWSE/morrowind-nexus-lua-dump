
local soundbank = {
    
        isInterior = true,
        affectingCells = {
			'Armorer',
			'Smith',
        },

        ambientLoopSounds = {
				{
					soundPath = "sounds\\DynamicSounds\\interior_general\\blacksmith_lp.wav", 
					loop = true,	
				},
				-- {
					-- soundPath = "sounds\\DynamicSounds\\interior_general\\blacksmith_hammer_02.wav", 
					-- loop = false,	
					-- volume=0.4,
					-- PlayChancePercent = 50,
				-- },
				-- {
					-- soundPath = "sounds\\DynamicSounds\\interior_general\\blacksmith_forge_quench_01.wav", 
					-- loop = false,	
					-- volume=0.4,
					-- PlayChancePercent = 50,
				-- },	
				-- {
					-- soundPath = "sounds\\DynamicSounds\\interior_general\\bladegrind_pedal.wav", 
					-- loop = false,	
					-- volume=0.4,
				-- },					
		},
		 objects = {        
		 
		}

    
}


return soundbank
