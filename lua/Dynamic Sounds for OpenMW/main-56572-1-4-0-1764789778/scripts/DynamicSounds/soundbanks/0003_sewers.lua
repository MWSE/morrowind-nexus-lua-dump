local soundbank = {

    isInterior = true,
    affectingCells = {
		"Sewers",
		"Underworks",
    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\water\\Sewerage_lp.wav", 
			loop = true,
        },
        {
            soundPath = "sounds\\DynamicSounds\\fauna\\rat_running.wav", 
            PlayChancePercent=10,
            loop = false            
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\fauna\\rat_running2.wav", 
            PlayChancePercent=10,
            loop = false            
        },         
    },
    objects = {        		 
	}

   

}


return soundbank