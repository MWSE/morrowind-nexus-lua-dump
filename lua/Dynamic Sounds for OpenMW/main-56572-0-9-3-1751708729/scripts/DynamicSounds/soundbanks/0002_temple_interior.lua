-- temple interior

local soundbank = {

    isInterior = true,
    affectingCells = {
		'Temple',
		'Ancestral Refuge',
		'Holamayan',


    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\temple\\temple-loop.wav", 
        	loop = true,
			volume = 1
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\temple\\whispers1.wav", 
        	loop = false,
			volume = 2
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\temple\\whispers2.wav", 
        	loop = false,
			volume = 2
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\temple\\whispers3.wav", 
        	loop = false,
			volume = 2
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\temple\\whispers4.wav", 
        	loop = false,
			volume = 2
        }, 		
		
        
    },

    objects = {

    },





}


return soundbank