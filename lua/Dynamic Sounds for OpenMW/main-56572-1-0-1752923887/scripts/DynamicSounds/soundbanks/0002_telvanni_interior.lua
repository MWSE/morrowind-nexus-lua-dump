-- telvanni interior

local soundbank = {

    isInterior = true,
    affectingCells = {
        'Tel Aruhn',
        'Tel Branora',
        'Tel Mora',   
        'Tel Fyr',
        'Tel Vos',
        'Tel Uvirith',           
      
        --TR 
        'Tel Aranyon',
        'Tel Darys',
        'Tel Drevis',
        'Tel Gilan',
        'Tel Onoria',
        'Tel Oren',
        'Tel Ouada',
        'Tel Sadas',
        'Tel Thenim',
        'Tel Vaerin',
        'Tower of Tel Mothrivra',
    },

    ambientLoopSounds = {
        -- {        
            -- soundPath = "sounds\\DynamicSounds\\wood\\woodcreak03.wav",
            -- loop = false,
            -- volume=0.4
        -- },
        -- {
            -- soundPath = "sounds\\DynamicSounds\\wood\\woodcreak02.wav",
            -- loop = false,
            -- volume=0.4
        -- },
        
    },

    objects = {
        {
            "_housepod_pole_",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak08.wav", 
					loop = false
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak09.wav", 
					loop = false
                },				
            },
			
        },
		
		{
            "in_t_s_pillar",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak08.wav", 
					loop = false,
					PlayChancePercent=10,  
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak09.wav", 
					loop = false,
					PlayChancePercent=10,  
                },				
            },		
		},
		
		{			
            "in_t_housepod_pole",
            {
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak08.wav", 
					loop = false,
					PlayChancePercent=10,  
                },
                {
                    soundPath = "sounds\\DynamicSounds\\wood\\woodcreak09.wav", 
					loop = false,
					PlayChancePercent=10,  
                },				
            },		
		},
    },





}


return soundbank