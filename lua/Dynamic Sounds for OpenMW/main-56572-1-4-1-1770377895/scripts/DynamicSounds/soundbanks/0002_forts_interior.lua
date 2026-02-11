-- imperial forts interior

local soundbank = {

    isInterior = true,
    affectingCells = {
		'Buckmoth Legion Fort',
		'Fort Darius',
		'Fort Firemoth',   
		'Fort Pelagiad',
		'Hawkmoth Legion Garrison',
		'Moonmoth Legion Fort',
		'Wolverine Hall',           
		'Grand Council Chambers',
		'Fort Frostmoth',
		'LoKKen Castle',
		'Greathall',
		'Ebonheart, Imperial',
		'Ebonheart, Grand Council Chambers',

		--TR 
		'Fort Ancylis',
		'Fort Umbermoth',
		'Windmoth Legion Fort',

		--Cyrodiil  
		'Fort Heath',
		'Fort Telodrach',
		'Goldstone',

		-- SHOTN
		'Taurus Hall',
		'Castle Dragonstar',


    },

    ambientLoopSounds = {
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\fort_ambiance.wav", 
        	loop = true,
			volume = 1.5
        }, 
        {
            soundPath = "sounds\\DynamicSounds\\dungeon\\dungeon_door.wav", 
        	loop = false,
			volume = 0.5,
			PlayChancePercent = 10,
        }, 	
        {
            soundPath = "sounds\\DynamicSounds\\human\\legion_march.wav", 
        	loop = false,
			volume = 0.5,
			PlayChancePercent = 10,
        }, 		
        
    },

    objects = {

    },





}


return soundbank