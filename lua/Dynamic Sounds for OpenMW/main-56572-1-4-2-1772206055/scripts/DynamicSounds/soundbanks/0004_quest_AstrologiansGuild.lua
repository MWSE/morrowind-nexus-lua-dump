-- Astrologian's Guild interiors

local soundbank = {
   
        isInterior = true,
        affectingCells = {
            "Sealock Charter",
            "Twilight"
        },

        ambientLoopSounds = {
        
        
		},
        
        objects = {
            { "AG_Door_Portal", {
                { soundPath = "sounds\\DynamicSounds\\magic\\amb_wayshrine_portal_lp.wav", loop = true },            	
            } },
            { "AG_CyberFire", {
                { soundPath = "sounds\\DynamicSounds\\fire\\amb_firecrater_01_lp.wav", loop = true },            	
            } },            

            
        
        },

    


        
    
    
}


return soundbank
